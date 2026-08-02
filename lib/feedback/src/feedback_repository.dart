import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:perfect/feedback/src/feedback_config.dart';
import 'package:perfect/feedback/src/feedback_models.dart';
import 'package:perfect/feedback/src/feedback_redactor.dart';

typedef ReadyFeedbackRootDirectoryResolver = Future<Directory> Function();
typedef ReadyFeedbackEntityDeleter =
    Future<void> Function(FileSystemEntity entity, bool recursive);
typedef ReadyFeedbackRecoveryClock = DateTime Function();

class ReadyFeedbackRecoveryResult {
  const ReadyFeedbackRecoveryResult({
    required this.directory,
    required this.artifactCount,
    required this.screenshotCount,
  });

  final Directory directory;
  final int artifactCount;
  final int screenshotCount;
}

class ReadyFeedbackStorageException implements Exception {
  const ReadyFeedbackStorageException(
    this.message, {
    this.cause,
    this.recordsRemoved = false,
  });

  final String message;
  final Object? cause;
  final bool recordsRemoved;

  @override
  String toString() => 'ReadyFeedbackStorageException: $message';
}

class ReadyFeedbackCleanupException extends ReadyFeedbackStorageException {
  const ReadyFeedbackCleanupException(
    super.message, {
    super.cause,
    super.recordsRemoved = true,
  });
}

class ReadyFeedbackIndexRecoveryException
    extends ReadyFeedbackStorageException {
  const ReadyFeedbackIndexRecoveryException(super.message, {super.cause});
}

class ReadyFeedbackLockTimeoutException extends ReadyFeedbackStorageException {
  const ReadyFeedbackLockTimeoutException(super.message, {super.cause});
}

class ReadyFeedbackRepositorySnapshot {
  ReadyFeedbackRepositorySnapshot({
    required List<ReadyFeedbackEntry> entries,
    required List<ReadyFeedbackLogRecord> logs,
    required Map<String, Uint8List> screenshots,
  }) : entries = List<ReadyFeedbackEntry>.unmodifiable(entries),
       logs = List<ReadyFeedbackLogRecord>.unmodifiable(logs),
       screenshots = Map<String, Uint8List>.unmodifiable(screenshots);

  final List<ReadyFeedbackEntry> entries;
  final List<ReadyFeedbackLogRecord> logs;
  final Map<String, Uint8List> screenshots;
}

/// A short-lived exclusive store session supplied by
/// [ReadyFeedbackRepository.withStoreLease].
///
/// Use these explicit methods instead of re-entering the repository's public
/// operations while the lease callback is active.
class ReadyFeedbackStoreLease {
  ReadyFeedbackStoreLease._(this._repository);

  final ReadyFeedbackRepository _repository;
  bool _active = true;
  Future<void> _operationTail = Future<void>.value();

  Future<ReadyFeedbackRepositorySnapshot> createExportSnapshot() =>
      _run(_repository._createExportSnapshotNow);

  Future<void> clearAll() => _run(_repository._clearAllNow);

  Future<T> _run<T>(Future<T> Function() operation) {
    _requireActive();
    final completer = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _requireActive() {
    if (!_active) {
      throw StateError(
        'This feedback store lease expired when its callback completed.',
      );
    }
  }

  Future<void> _closeAndDrain() async {
    _active = false;
    await _operationTail;
  }
}

class ReadyFeedbackRepository {
  static const String _lockFileName = '.feedback-store.lock';
  static final Object _leaseZoneKey = Object();
  static final Object _heldStoreIdentityZoneKey = Object();
  static final Map<String, Future<void>> _processStoreTails =
      <String, Future<void>>{};

  ReadyFeedbackRepository({
    required this.config,
    ReadyFeedbackRootDirectoryResolver? rootDirectoryResolver,
    ReadyFeedbackEntityDeleter? entityDeleter,
    ReadyFeedbackRecoveryClock? recoveryClock,
    Duration storeLockTimeout = const Duration(seconds: 5),
    Duration storeLockRetryDelay = const Duration(milliseconds: 25),
  }) : _rootDirectoryResolver =
           rootDirectoryResolver ?? getApplicationSupportDirectory,
       _entityDeleter = entityDeleter ?? _deleteEntity,
       _recoveryClock = recoveryClock ?? DateTime.now,
       _storeLockTimeout = storeLockTimeout,
       _storeLockRetryDelay = storeLockRetryDelay {
    if (storeLockTimeout <= Duration.zero) {
      throw ArgumentError.value(
        storeLockTimeout,
        'storeLockTimeout',
        'Use a positive bounded lock timeout.',
      );
    }
    if (storeLockRetryDelay <= Duration.zero) {
      throw ArgumentError.value(
        storeLockRetryDelay,
        'storeLockRetryDelay',
        'Use a positive lock retry delay.',
      );
    }
  }

  final ReadyFeedbackConfig config;
  final ReadyFeedbackRootDirectoryResolver _rootDirectoryResolver;
  final ReadyFeedbackEntityDeleter _entityDeleter;
  final ReadyFeedbackRecoveryClock _recoveryClock;
  final Duration _storeLockTimeout;
  final Duration _storeLockRetryDelay;
  Future<void> _mutationChain = Future<void>.value();
  Future<Directory>? _rootFuture;

  Future<Directory> get rootDirectory => _serialize(_ensureRoot);

  Future<List<ReadyFeedbackEntry>> readEntries() => _serialize(_readEntriesNow);

  Future<List<ReadyFeedbackLogRecord>> readLogs() => _serialize(_readLogsNow);

  /// Holds instance, in-process, and operating-system exclusion until the
  /// awaited callback finishes. The supplied lease expires on callback exit.
  Future<T> withStoreLease<T>(
    Future<T> Function(ReadyFeedbackStoreLease lease) operation,
  ) => _serialize(() async {
    final lease = ReadyFeedbackStoreLease._(this);
    try {
      return await runZoned(
        () => operation(lease),
        zoneValues: <Object, Object>{
          _leaseZoneKey: const _ReadyFeedbackLeaseZoneToken(),
        },
      );
    } finally {
      await lease._closeAndDrain();
    }
  });

  Future<ReadyFeedbackEntry> addEntry(
    ReadyFeedbackEntry entry, {
    ReadyFeedbackScreenshotCapture? screenshot,
    Uint8List? screenshotBytes,
  }) => _serialize(() async {
    if (screenshot != null && screenshotBytes != null) {
      throw ArgumentError(
        'Provide screenshot or screenshotBytes, but not both.',
      );
    }
    final capture =
        screenshot ??
        (screenshotBytes == null
            ? null
            : ReadyFeedbackScreenshotCapture(
                bytes: screenshotBytes,
                pixelRatio: 1,
              ));
    final normalized = _normalizeNewEntry(entry);
    if (normalized.note.trim().isEmpty &&
        (capture == null || capture.bytes.isEmpty)) {
      throw ArgumentError('A note or screenshot is required.');
    }

    final root = await _ensureRoot();
    final entries = await _readEntriesNow();
    if (entries.any((candidate) => candidate.id == normalized.id)) {
      throw StateError('A feedback entry with this id already exists.');
    }

    ReadyFeedbackEntry stored = normalized;
    File? newScreenshot;
    if (capture != null && capture.bytes.isNotEmpty) {
      final metadata = _validateScreenshot(capture);
      final fileName = '${normalized.id}.png';
      newScreenshot = File(_screenshotPath(root, fileName));
      await _requireExistingDirectoryAncestors(root, newScreenshot.path);
      await _requireDirectory(
        newScreenshot.parent,
        description: 'feedback screenshot directory',
      );
      await _requireRegularFileOrMissing(
        newScreenshot,
        description: 'feedback screenshot',
      );
      await newScreenshot.writeAsBytes(capture.bytes, flush: true);
      stored = normalized.copyWith(
        screenshotFileName: fileName,
        screenshotWidthPx: metadata.width,
        screenshotHeightPx: metadata.height,
        screenshotByteLength: capture.bytes.lengthInBytes,
        screenshotPixelRatio: capture.pixelRatio,
      );
    }

    entries.add(stored);
    entries.sort(_compareEntriesNewestFirst);
    final evicted = <ReadyFeedbackEntry>[];
    var retainedScreenshotBytes = entries.fold<int>(
      0,
      (sum, item) => sum + (item.screenshotByteLength ?? 0),
    );
    while (entries.length > config.maxEntries ||
        retainedScreenshotBytes > config.maxScreenshotStorageBytes) {
      final removed = entries.removeLast();
      retainedScreenshotBytes -= removed.screenshotByteLength ?? 0;
      evicted.add(removed);
    }

    try {
      await _writeEntries(root, entries);
    } on Object {
      if (newScreenshot != null) await _deleteFileBestEffort(newScreenshot);
      rethrow;
    }
    for (final old in evicted) {
      await _deleteScreenshotBestEffort(root, old.screenshotFileName);
    }
    return stored;
  });

  Future<void> deleteEntry(String id) => _serialize(() async {
    final root = await _ensureRoot();
    final entries = await _readEntriesNow();
    ReadyFeedbackEntry? removed;
    final retained = <ReadyFeedbackEntry>[];
    for (final entry in entries) {
      if (entry.id == id) {
        removed ??= entry;
      } else {
        retained.add(entry);
      }
    }
    if (removed == null) return;
    await _writeEntries(root, retained);
    await _deleteScreenshotOrThrow(root, removed.screenshotFileName);
  });

  Future<void> clearAll() => _serialize(_clearAllNow);

  Future<void> _clearAllNow() async {
    final root = await _lockedRoot(initializeStore: false);
    final cleanupErrors = <Object>[];

    await _revalidateHeldStoreIdentity(root);

    // Clear means every private feedback artifact, including atomic index
    // generations and owner-preserved recovery copies. Deleting only the
    // active JSON files would leave notes, logs, or screenshots recoverable
    // from `.bak`, `.tmp`, or `recovery/<stamp>/raw`.
    await for (final entity in root.list(followLinks: false)) {
      if (_leafName(entity.path) == _lockFileName) continue;
      try {
        await _deleteTreeWithoutFollowingLinks(root, entity);
      } on Object catch (error) {
        cleanupErrors.add(error);
      }
    }

    try {
      await _createDirectoryIfMissing(
        Directory('${root.path}${Platform.pathSeparator}shots'),
        description: 'feedback screenshot directory',
      );
      await _atomicWriteJson(
        File('${root.path}${Platform.pathSeparator}entries.json'),
        const <Object?>[],
      );
      await _atomicWriteJson(
        File('${root.path}${Platform.pathSeparator}logs.json'),
        const <Object?>[],
      );
    } on Object catch (error) {
      cleanupErrors.add(error);
    }

    // A failed first deletion may have caused the atomic writer to rotate a
    // private generation into a backup. Make one explicit post-write pass so
    // success never leaves historical note/log payloads behind.
    for (final name in const <String>[
      'entries.json.bak',
      'entries.json.tmp',
      'logs.json.bak',
      'logs.json.tmp',
    ]) {
      final stale = File('${root.path}${Platform.pathSeparator}$name');
      try {
        if (await _typeWithoutFollowingLinks(stale.path) !=
            FileSystemEntityType.notFound) {
          await _deleteTreeWithoutFollowingLinks(root, stale);
        }
      } on Object catch (error) {
        cleanupErrors.add(error);
      }
    }

    final finalState = await _inspectClearedStore(root);
    await _refreshHeldStoreIdentity(root);
    final recordsRemoved = finalState.recordsRemoved;
    if (cleanupErrors.isNotEmpty || !finalState.cleanInventory) {
      throw ReadyFeedbackCleanupException(
        recordsRemoved
            ? 'Active records were removed, but one or more private feedback '
                  'artifacts or recovery copies could not be deleted. Run '
                  'Clear all again to retry.'
            : 'Private feedback cleanup could not rebuild a safe empty store. '
                  'Existing artifacts were preserved where deletion failed.',
        cause: cleanupErrors.isNotEmpty
            ? cleanupErrors.first
            : finalState.problem,
        recordsRemoved: recordsRemoved,
      );
    }
  }

  Future<ReadyFeedbackRecoveryResult> recoverCorruptStore({
    required bool ownerConfirmed,
  }) => _serialize(() async {
    if (!ownerConfirmed) {
      throw ArgumentError(
        'Explicit owner confirmation is required before recovery.',
      );
    }
    final root = await _ensureRoot();
    final entriesFile = File(
      '${root.path}${Platform.pathSeparator}entries.json',
    );
    final index = await _readJsonArrayState(entriesFile);
    final logIndex = await _readJsonArrayState(
      File('${root.path}${Platform.pathSeparator}logs.json'),
    );
    final shots = Directory('${root.path}${Platform.pathSeparator}shots');
    final hasScreenshots = await _directoryHasEntries(shots);
    final entriesNeedRecovery =
        !index.authoritative || (!index.generationFound && hasScreenshots);
    final logsNeedRecovery = !logIndex.authoritative;
    if (!entriesNeedRecovery && !logsNeedRecovery) {
      throw StateError('The feedback store does not require recovery.');
    }

    final recoveryDirectory = await _newRecoveryDirectory(root);
    final rawDirectory = Directory(
      '${recoveryDirectory.path}${Platform.pathSeparator}raw',
    );
    await _requireExistingDirectoryAncestors(root, rawDirectory.path);
    await rawDirectory.create();
    await _requireDirectory(
      rawDirectory,
      description: 'feedback raw recovery directory',
    );
    final screenshotCount = await _countScreenshotFiles(shots);
    final moved = <_MovedRecoveryArtifact>[];
    try {
      await _refreshHeldStoreIdentity(root);
      await _revalidateHeldStoreIdentity(root);
      final artifacts = await root.list(followLinks: false).where((entity) {
        final name = _leafName(entity.path);
        return name != 'recovery' && name != _lockFileName;
      }).toList();
      for (final entity in artifacts) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final originalPath = entity.path;
        final destination =
            '${rawDirectory.path}${Platform.pathSeparator}$name';
        await _renameEntity(entity, destination);
        moved.add(
          _MovedRecoveryArtifact(
            quarantinedPath: destination,
            originalPath: originalPath,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      await _rollbackRecoveryMoves(moved);
      Error.throwWithStackTrace(
        ReadyFeedbackStorageException(
          'Could not quarantine the corrupt feedback store safely.',
          cause: error,
        ),
        stackTrace,
      );
    }

    try {
      await _createDirectoryIfMissing(
        Directory('${root.path}${Platform.pathSeparator}shots'),
        description: 'feedback screenshot directory',
      );
      await _atomicWriteJson(entriesFile, const <Object?>[]);
      await _atomicWriteJson(
        File('${root.path}${Platform.pathSeparator}logs.json'),
        const <Object?>[],
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ReadyFeedbackStorageException(
          'The recovery copy is safe, but the fresh feedback store could not '
          'be initialized yet.',
          cause: error,
        ),
        stackTrace,
      );
    }
    return ReadyFeedbackRecoveryResult(
      directory: recoveryDirectory,
      artifactCount: moved.length,
      screenshotCount: screenshotCount,
    );
  });

  Future<void> appendLog(ReadyFeedbackLogRecord record) => _serialize(() async {
    final root = await _ensureRoot();
    final logs = await _readLogsNow();
    logs.add(_normalizeLog(record));
    logs.sort(_compareLogsNewestFirst);
    final retained = logs.take(config.maxLogs).toList(growable: false);
    await _atomicWriteJson(
      File('${root.path}${Platform.pathSeparator}logs.json'),
      retained.map((item) => item.toJson()).toList(growable: false),
    );
  });

  Future<Uint8List?> readScreenshot(ReadyFeedbackEntry entry) =>
      _serialize(() => _readScreenshotNow(entry));

  Future<ReadyFeedbackRepositorySnapshot> createExportSnapshot() =>
      _serialize(_createExportSnapshotNow);

  Future<ReadyFeedbackRepositorySnapshot> _createExportSnapshotNow() async {
    final entries = await _readEntriesNow();
    final logs = await _readLogsNow();
    final screenshots = <String, Uint8List>{};
    for (final entry in entries) {
      final fileName = entry.screenshotFileName;
      if (fileName == null) continue;
      final bytes = await _readScreenshotNow(entry);
      if (bytes != null) screenshots[fileName] = bytes;
    }
    return ReadyFeedbackRepositorySnapshot(
      entries: entries,
      logs: logs,
      screenshots: screenshots,
    );
  }

  Future<List<ReadyFeedbackEntry>> _readEntriesNow() async {
    final root = await _ensureRoot();
    await _ensureScreenshotIntegrity(root);
    final values = await _readJsonArray(
      File('${root.path}${Platform.pathSeparator}entries.json'),
    );
    final entries = <ReadyFeedbackEntry>[];
    for (final value in values) {
      try {
        entries.add(_normalizeLoadedEntry(ReadyFeedbackEntry.fromJson(value)));
      } on Object {
        // Preserve the rest of a partially damaged local report index.
      }
    }
    entries.sort(_compareEntriesNewestFirst);
    return entries;
  }

  Future<List<ReadyFeedbackLogRecord>> _readLogsNow() async {
    final root = await _ensureRoot();
    final values = await _readJsonArray(
      File('${root.path}${Platform.pathSeparator}logs.json'),
    );
    final logs = <ReadyFeedbackLogRecord>[];
    for (final value in values) {
      try {
        logs.add(_normalizeLog(ReadyFeedbackLogRecord.fromJson(value)));
      } on Object {
        // Preserve usable records if a single record was damaged.
      }
    }
    logs.sort(_compareLogsNewestFirst);
    return logs;
  }

  Future<Uint8List?> _readScreenshotNow(ReadyFeedbackEntry entry) async {
    final fileName = entry.screenshotFileName;
    if (fileName == null || !_isSafeScreenshotName(fileName)) return null;
    final root = await _ensureRoot();
    final file = File(_screenshotPath(root, fileName));
    await _requireExistingDirectoryAncestors(root, file.path);
    final type = await _typeWithoutFollowingLinks(file.path);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw FileSystemException(
        'Feedback screenshot must be a regular file.',
        file.path,
      );
    }
    final stat = await file.stat();
    if (stat.size > config.maxScreenshotBytes) return null;
    final bytes = await file.readAsBytes();
    try {
      _parsePng(bytes);
      return bytes;
    } on Object {
      return null;
    }
  }

  ReadyFeedbackEntry _normalizeNewEntry(ReadyFeedbackEntry entry) {
    if (!_isSafeLeafName(entry.id) || entry.id.length > 128) {
      throw ArgumentError.value(
        entry.id,
        'entry.id',
        'Use a short portable identifier without path separators.',
      );
    }
    return ReadyFeedbackEntry(
      id: entry.id,
      createdAt: entry.createdAt.toUtc(),
      route: ReadyFeedbackRedactor.redactAndLimit(
        entry.route.trim().isEmpty ? 'Unknown' : entry.route.trim(),
        config.maxRouteCharacters,
      ),
      note: ReadyFeedbackRedactor.redactAndLimit(
        entry.note.trim(),
        config.maxNoteCharacters,
      ),
      kind: entry.kind,
    );
  }

  ReadyFeedbackEntry _normalizeLoadedEntry(ReadyFeedbackEntry entry) {
    if (!_isSafeLeafName(entry.id) || entry.id.length > 128) {
      throw const FormatException('Unsafe feedback entry id.');
    }
    final fileName = entry.screenshotFileName;
    final keepScreenshot = fileName != null && _isSafeScreenshotName(fileName);
    return ReadyFeedbackEntry(
      id: entry.id,
      createdAt: entry.createdAt.toUtc(),
      route: ReadyFeedbackRedactor.redactAndLimit(
        entry.route.trim().isEmpty ? 'Unknown' : entry.route,
        config.maxRouteCharacters,
      ),
      note: ReadyFeedbackRedactor.redactAndLimit(
        entry.note,
        config.maxNoteCharacters,
      ),
      kind: entry.kind,
      screenshotFileName: keepScreenshot ? fileName : null,
      screenshotWidthPx:
          keepScreenshot &&
              (entry.screenshotWidthPx ?? 0) > 0 &&
              entry.screenshotWidthPx! <= config.maxScreenshotDimensionPx
          ? entry.screenshotWidthPx
          : null,
      screenshotHeightPx:
          keepScreenshot &&
              (entry.screenshotHeightPx ?? 0) > 0 &&
              entry.screenshotHeightPx! <= config.maxScreenshotDimensionPx
          ? entry.screenshotHeightPx
          : null,
      screenshotByteLength:
          keepScreenshot &&
              (entry.screenshotByteLength ?? 0) > 0 &&
              entry.screenshotByteLength! <= config.maxScreenshotBytes
          ? entry.screenshotByteLength
          : null,
      screenshotPixelRatio:
          keepScreenshot &&
              (entry.screenshotPixelRatio ?? 0).isFinite &&
              (entry.screenshotPixelRatio ?? 0) > 0
          ? entry.screenshotPixelRatio
          : null,
    );
  }

  ReadyFeedbackLogRecord _normalizeLog(ReadyFeedbackLogRecord record) =>
      ReadyFeedbackLogRecord(
        createdAt: record.createdAt.toUtc(),
        level: record.level,
        message: ReadyFeedbackRedactor.redactAndLimit(
          record.message,
          config.maxLogMessageCharacters,
        ),
        stackTrace: record.stackTrace == null
            ? null
            : ReadyFeedbackRedactor.redactAndLimit(
                record.stackTrace!,
                config.maxStackTraceCharacters,
              ),
      );

  _PngMetadata _validateScreenshot(ReadyFeedbackScreenshotCapture capture) {
    if (!capture.pixelRatio.isFinite ||
        capture.pixelRatio < 1 ||
        capture.pixelRatio > config.maxScreenshotPixelRatio) {
      throw ArgumentError.value(
        capture.pixelRatio,
        'screenshot.pixelRatio',
        'Pixel ratio is outside the configured capture range.',
      );
    }
    if (capture.bytes.lengthInBytes > config.maxScreenshotBytes) {
      throw ArgumentError.value(
        capture.bytes.lengthInBytes,
        'screenshot.bytes',
        'Screenshot exceeds the configured byte limit.',
      );
    }
    final metadata = _parsePng(capture.bytes);
    if (metadata.width > config.maxScreenshotDimensionPx ||
        metadata.height > config.maxScreenshotDimensionPx) {
      throw ArgumentError(
        'Screenshot dimensions exceed the configured pixel limit.',
      );
    }
    return metadata;
  }

  _PngMetadata _parsePng(Uint8List bytes) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.lengthInBytes < 45) {
      throw const FormatException('PNG file is incomplete.');
    }
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        throw const FormatException('Screenshot is not a PNG.');
      }
    }
    final data = ByteData.sublistView(bytes);
    var offset = 8;
    var sawHeader = false;
    var sawEnd = false;
    var imageDataBytes = 0;
    var width = 0;
    var height = 0;
    while (offset < bytes.lengthInBytes) {
      if (bytes.lengthInBytes - offset < 12) {
        throw const FormatException('PNG chunk boundary is truncated.');
      }
      final chunkLength = data.getUint32(offset);
      if (chunkLength > bytes.lengthInBytes - offset - 12) {
        throw const FormatException('PNG chunk data is truncated.');
      }
      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      if (!RegExp(r'^[A-Za-z]{4}$').hasMatch(type)) {
        throw const FormatException('PNG chunk type is invalid.');
      }
      final expectedCrc = data.getUint32(offset + 8 + chunkLength);
      final actualCrc = _pngCrc(bytes, offset + 4, chunkLength + 4);
      if (actualCrc != expectedCrc) {
        throw FormatException('PNG $type chunk checksum is invalid.');
      }
      if (!sawHeader) {
        if (type != 'IHDR' || chunkLength != 13) {
          throw const FormatException(
            'PNG must begin with one complete IHDR chunk.',
          );
        }
        width = data.getUint32(offset + 8);
        height = data.getUint32(offset + 12);
        if (width == 0 || height == 0) {
          throw const FormatException('PNG dimensions are invalid.');
        }
        _validatePngHeaderEncoding(bytes, offset + 8);
        sawHeader = true;
      } else if (type == 'IHDR') {
        throw const FormatException('PNG contains multiple IHDR chunks.');
      }
      if (type == 'IDAT') imageDataBytes += chunkLength;
      offset += 12 + chunkLength;
      if (type == 'IEND') {
        if (chunkLength != 0 || offset != bytes.lengthInBytes) {
          throw const FormatException('PNG IEND chunk is invalid.');
        }
        if (imageDataBytes == 0) {
          throw const FormatException('PNG contains no image data.');
        }
        sawEnd = true;
        break;
      }
    }
    if (!sawHeader || !sawEnd) {
      throw const FormatException('PNG is missing a complete IEND chunk.');
    }
    return _PngMetadata(width: width, height: height);
  }

  void _validatePngHeaderEncoding(Uint8List bytes, int dataOffset) {
    final bitDepth = bytes[dataOffset + 8];
    final colorType = bytes[dataOffset + 9];
    final compression = bytes[dataOffset + 10];
    final filter = bytes[dataOffset + 11];
    final interlace = bytes[dataOffset + 12];
    final validDepth = switch (colorType) {
      0 => const <int>{1, 2, 4, 8, 16}.contains(bitDepth),
      2 => const <int>{8, 16}.contains(bitDepth),
      3 => const <int>{1, 2, 4, 8}.contains(bitDepth),
      4 || 6 => const <int>{8, 16}.contains(bitDepth),
      _ => false,
    };
    if (!validDepth ||
        compression != 0 ||
        filter != 0 ||
        (interlace != 0 && interlace != 1)) {
      throw const FormatException('PNG IHDR encoding fields are invalid.');
    }
  }

  int _pngCrc(Uint8List bytes, int start, int length) {
    var crc = 0xffffffff;
    for (var index = start; index < start + length; index++) {
      crc ^= bytes[index];
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  Future<Directory> _resolveRootDirectory() {
    final existing = _rootFuture;
    if (existing != null) return existing;
    late final Future<Directory> future;
    future = (() async {
      try {
        final namespace = config.storageNamespace.trim();
        if (!_isSafeLeafName(namespace)) {
          throw ArgumentError.value(
            config.storageNamespace,
            'storageNamespace',
            'Use one portable directory name without path separators.',
          );
        }
        final suppliedBase = await _rootDirectoryResolver();
        final base = await _prepareTrustedBaseDirectory(suppliedBase);
        final root = Directory(
          '${base.path}${Platform.pathSeparator}$namespace',
        );
        final type = await _typeWithoutFollowingLinks(root.path);
        if (type == FileSystemEntityType.notFound) {
          await root.create();
        } else if (type != FileSystemEntityType.directory) {
          throw FileSystemException(
            'Feedback root must be a real directory, not a link or reparse '
            'point.',
            root.path,
          );
        }
        await _requireDirectory(root, description: 'feedback root');
        return root;
      } on Object {
        if (identical(_rootFuture, future)) _rootFuture = null;
        rethrow;
      }
    })();
    _rootFuture = future;
    return future;
  }

  Future<Directory> _ensureRoot() => _lockedRoot(initializeStore: true);

  Future<Directory> _lockedRoot({required bool initializeStore}) async {
    final root = await _resolveRootDirectory();
    await _revalidateHeldStoreIdentity(root);
    await _requireDirectory(root, description: 'feedback root');
    await _requireRegularFile(
      File('${root.path}${Platform.pathSeparator}$_lockFileName'),
      description: 'feedback store lock',
    );
    if (!initializeStore) {
      await _refreshHeldStoreIdentity(root);
      return root;
    }

    final shots = Directory('${root.path}${Platform.pathSeparator}shots');
    await _createDirectoryIfMissing(
      shots,
      description: 'feedback screenshot directory',
    );
    await _requireDirectoryOrMissing(
      Directory('${root.path}${Platform.pathSeparator}recovery'),
      description: 'feedback recovery directory',
    );
    await _validateIndexGenerations(root, 'entries.json');
    await _validateIndexGenerations(root, 'logs.json');
    await _validateScreenshotEntities(root, shots);

    final entriesFile = File(
      '${root.path}${Platform.pathSeparator}entries.json',
    );
    if (!await _anyIndexGenerationExists(entriesFile) &&
        !await _directoryHasEntries(shots)) {
      await _atomicWriteJson(entriesFile, const <Object?>[]);
    }
    final logsFile = File('${root.path}${Platform.pathSeparator}logs.json');
    if (!await _anyIndexGenerationExists(logsFile)) {
      await _atomicWriteJson(logsFile, const <Object?>[]);
    }
    await _refreshHeldStoreIdentity(root);
    return root;
  }

  Future<void> _ensureScreenshotIntegrity(Directory root) async {
    final entriesFile = File(
      '${root.path}${Platform.pathSeparator}entries.json',
    );
    final index = await _readJsonArrayState(entriesFile);
    if (!index.authoritative) {
      throw const ReadyFeedbackIndexRecoveryException(
        'All feedback entry indexes are unreadable. Private screenshots were '
        'preserved so the store can be recovered without data loss.',
      );
    }
    final shots = Directory('${root.path}${Platform.pathSeparator}shots');
    if (!index.generationFound) {
      if (await _directoryHasEntries(shots)) {
        throw const ReadyFeedbackIndexRecoveryException(
          'The feedback entry index is missing while private screenshots '
          'still exist. The screenshots were preserved for safe recovery.',
        );
      }
      await _atomicWriteJson(entriesFile, const <Object?>[]);
    }
    final referenced = <String>{};
    for (final value in index.values) {
      final fileName = value['screenshotFileName'];
      if (fileName is String && _isSafeScreenshotName(fileName)) {
        referenced.add(fileName);
      }
    }
    await for (final entity in shots.list(followLinks: false)) {
      final fileName = entity.path.split(Platform.pathSeparator).last;
      if (_isSafeScreenshotName(fileName) && !referenced.contains(fileName)) {
        await _deleteEntityBestEffort(entity);
      }
    }
  }

  Future<bool> _directoryHasEntries(Directory directory) async {
    final type = await _typeWithoutFollowingLinks(directory.path);
    if (type == FileSystemEntityType.notFound) return false;
    if (type != FileSystemEntityType.directory) {
      throw FileSystemException(
        'Feedback directory must not be a link or reparse point.',
        directory.path,
      );
    }
    return !(await directory.list(followLinks: false).isEmpty);
  }

  Future<int> _countScreenshotFiles(Directory directory) async {
    final type = await _typeWithoutFollowingLinks(directory.path);
    if (type == FileSystemEntityType.notFound) return 0;
    if (type != FileSystemEntityType.directory) {
      throw FileSystemException(
        'Feedback screenshot directory must not be a link or reparse point.',
        directory.path,
      );
    }
    var count = 0;
    await for (final entity in directory.list(followLinks: false)) {
      final entityType = await _typeWithoutFollowingLinks(entity.path);
      if (entityType != FileSystemEntityType.file) {
        throw FileSystemException(
          'Feedback screenshots must be regular files.',
          entity.path,
        );
      }
      if (_isSafeScreenshotName(_leafName(entity.path))) {
        count++;
      }
    }
    return count;
  }

  Future<Directory> _newRecoveryDirectory(Directory root) async {
    await _revalidateHeldStoreIdentity(root);
    final recoveryRoot = Directory(
      '${root.path}${Platform.pathSeparator}recovery',
    );
    await _requireExistingDirectoryAncestors(root, recoveryRoot.path);
    await _createDirectoryIfMissing(
      recoveryRoot,
      description: 'feedback recovery directory',
    );
    final stamp = _recoveryClock().toUtc().microsecondsSinceEpoch;
    var suffix = 0;
    while (true) {
      final name = suffix == 0 ? '$stamp' : '$stamp-$suffix';
      final candidate = Directory(
        '${recoveryRoot.path}${Platform.pathSeparator}$name',
      );
      await _requireExistingDirectoryAncestors(root, candidate.path);
      final type = await _typeWithoutFollowingLinks(candidate.path);
      if (type == FileSystemEntityType.notFound) {
        await candidate.create();
        await _requireDirectory(
          candidate,
          description: 'feedback recovery generation',
        );
        return candidate;
      }
      if (type != FileSystemEntityType.directory) {
        throw FileSystemException(
          'Feedback recovery generations must be real directories.',
          candidate.path,
        );
      }
      suffix++;
    }
  }

  Future<void> _rollbackRecoveryMoves(
    List<_MovedRecoveryArtifact> moved,
  ) async {
    for (final artifact in moved.reversed) {
      try {
        final type = await _typeWithoutFollowingLinks(artifact.quarantinedPath);
        if (type == FileSystemEntityType.notFound) continue;
        await _renameEntity(
          _entityForType(type, artifact.quarantinedPath),
          artifact.originalPath,
        );
      } on Object {
        // Preserve the remaining recovery copy rather than deleting evidence.
      }
    }
  }

  Future<void> _renameEntity(
    FileSystemEntity entity,
    String destination,
  ) async {
    switch (entity) {
      case File file:
        await file.rename(destination);
        return;
      case Directory directory:
        await directory.rename(destination);
        return;
      case Link link:
        await link.rename(destination);
        return;
      default:
        throw FileSystemException(
          'Unsupported recovery artifact.',
          entity.path,
        );
    }
  }

  FileSystemEntity _entityForType(FileSystemEntityType type, String path) =>
      switch (type) {
        FileSystemEntityType.file => File(path),
        FileSystemEntityType.directory => Directory(path),
        FileSystemEntityType.link => Link(path),
        _ => throw FileSystemException('Unsupported recovery artifact.', path),
      };

  Future<List<Map<String, Object?>>> _readJsonArray(File file) async {
    final result = await _readJsonArrayState(file);
    if (!result.authoritative) {
      throw ReadyFeedbackIndexRecoveryException(
        'Every available generation of ${file.uri.pathSegments.last} is '
        'unreadable. Private screenshots were preserved for recovery.',
      );
    }
    return result.values;
  }

  Future<_JsonArrayReadResult> _readJsonArrayState(File file) async {
    Future<List<Map<String, Object?>>> decode(File candidate) async {
      final decoded = jsonDecode(await candidate.readAsString());
      if (decoded is! List<Object?>) {
        throw const FormatException('Expected a JSON array.');
      }
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (map) => map.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    }

    final candidates = <File>[
      file,
      File('${file.path}.bak'),
      File('${file.path}.tmp'),
    ];
    var foundCandidate = false;
    for (final candidate in candidates) {
      final type = await _typeWithoutFollowingLinks(candidate.path);
      if (type == FileSystemEntityType.notFound) continue;
      if (type != FileSystemEntityType.file) {
        throw FileSystemException(
          'Feedback index generations must be regular files.',
          candidate.path,
        );
      }
      foundCandidate = true;
      try {
        return _JsonArrayReadResult(
          values: await decode(candidate),
          authoritative: true,
          generationFound: true,
        );
      } on Object {
        // Try the prior atomic generation before failing closed.
      }
    }
    return _JsonArrayReadResult(
      values: const <Map<String, Object?>>[],
      authoritative: !foundCandidate,
      generationFound: foundCandidate,
    );
  }

  Future<void> _writeEntries(
    Directory root,
    List<ReadyFeedbackEntry> entries,
  ) => _atomicWriteJson(
    File('${root.path}${Platform.pathSeparator}entries.json'),
    entries.map((entry) => entry.toJson()).toList(growable: false),
  );

  Future<void> _atomicWriteJson(File target, Object value) async {
    await _requireDirectory(
      target.parent,
      description: 'feedback index directory',
    );
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    await _requireRegularFileOrMissing(
      target,
      description: 'feedback active index',
    );
    await _requireRegularFileOrMissing(
      temporary,
      description: 'feedback temporary index',
    );
    await _requireRegularFileOrMissing(
      backup,
      description: 'feedback backup index',
    );
    if (await _typeWithoutFollowingLinks(temporary.path) ==
        FileSystemEntityType.file) {
      await temporary.delete();
    }
    await temporary.writeAsString(jsonEncode(value), flush: true);
    if (await _typeWithoutFollowingLinks(target.path) ==
        FileSystemEntityType.file) {
      if (await _typeWithoutFollowingLinks(backup.path) ==
          FileSystemEntityType.file) {
        await backup.delete();
      }
      await target.rename(backup.path);
    }
    try {
      await temporary.rename(target.path);
      // Keep one prior generation so later corruption remains recoverable.
    } on Object {
      if (await _typeWithoutFollowingLinks(target.path) ==
          FileSystemEntityType.file) {
        await target.delete();
      }
      if (await _typeWithoutFollowingLinks(backup.path) ==
          FileSystemEntityType.file) {
        await backup.rename(target.path);
      }
      rethrow;
    } finally {
      if (await _typeWithoutFollowingLinks(temporary.path) ==
          FileSystemEntityType.file) {
        await temporary.delete();
      }
    }
  }

  Future<void> _deleteScreenshotBestEffort(
    Directory root,
    String? fileName,
  ) async {
    if (fileName == null || !_isSafeScreenshotName(fileName)) return;
    await _deleteEntityAtPathBestEffort(_screenshotPath(root, fileName));
  }

  Future<void> _deleteScreenshotOrThrow(
    Directory root,
    String? fileName,
  ) async {
    if (fileName == null || !_isSafeScreenshotName(fileName)) return;
    final path = _screenshotPath(root, fileName);
    try {
      final type = await _typeWithoutFollowingLinks(path);
      switch (type) {
        case FileSystemEntityType.notFound:
          return;
        case FileSystemEntityType.file:
          await _entityDeleter(File(path), false);
          return;
        case FileSystemEntityType.directory:
          await _entityDeleter(Directory(path), true);
          return;
        case FileSystemEntityType.link:
          await _entityDeleter(Link(path), false);
          return;
        default:
          throw FileSystemException('Unsupported screenshot entity.', path);
      }
    } on Object catch (error) {
      throw ReadyFeedbackCleanupException(
        'The feedback record was removed, but its private screenshot could '
        'not be deleted. Cleanup will be retried when the store opens again.',
        cause: error,
      );
    }
  }

  Future<void> _deleteFileBestEffort(File file) async {
    await _deleteEntityAtPathBestEffort(file.path);
  }

  Future<void> _deleteEntityAtPathBestEffort(String path) async {
    try {
      final type = await _typeWithoutFollowingLinks(path);
      switch (type) {
        case FileSystemEntityType.notFound:
          return;
        case FileSystemEntityType.file:
          await _entityDeleter(File(path), false);
          return;
        case FileSystemEntityType.link:
          await _entityDeleter(Link(path), false);
          return;
        case FileSystemEntityType.directory:
          return;
        default:
          return;
      }
    } on Object {
      // The JSON index is authoritative; ignore an inaccessible orphan.
    }
  }

  Future<void> _deleteEntityBestEffort(FileSystemEntity entity) async {
    try {
      final type = await _typeWithoutFollowingLinks(entity.path);
      switch (type) {
        case FileSystemEntityType.notFound:
          return;
        case FileSystemEntityType.file:
          await _entityDeleter(File(entity.path), false);
          return;
        case FileSystemEntityType.link:
          await _entityDeleter(Link(entity.path), false);
          return;
        case FileSystemEntityType.directory:
          return;
        default:
          return;
      }
    } on Object {
      // Startup cleanup is retryable on the next store open.
    }
  }

  static Future<void> _deleteEntity(FileSystemEntity entity, bool recursive) =>
      entity.delete(recursive: recursive);

  Future<FileSystemEntityType> _typeWithoutFollowingLinks(String path) async {
    if (await FileSystemEntity.isLink(path)) return FileSystemEntityType.link;
    return FileSystemEntity.type(path, followLinks: false);
  }

  Future<Directory> _prepareTrustedBaseDirectory(Directory suppliedBase) async {
    final normalizedPath = suppliedBase.absolute.uri.normalizePath().toFilePath(
      windows: Platform.isWindows,
    );
    final requestedBase = Directory(normalizedPath);
    final missing = <Directory>[];
    var current = requestedBase;

    while (true) {
      final type = await _typeWithoutFollowingLinks(current.path);
      if (type == FileSystemEntityType.notFound) {
        missing.add(current);
      } else if (type != FileSystemEntityType.directory) {
        throw FileSystemException(
          'Feedback storage ancestors must be real directories, not links, '
          'junctions, or reparse points.',
          current.path,
        );
      }

      final parent = current.parent;
      if (_comparisonPath(parent.path) == _comparisonPath(current.path)) break;
      current = parent;
    }

    // Create a missing resolver base one component at a time. Revalidating the
    // parent and the newly created component on every step both supports normal
    // temp/test roots and rejects a link or junction inserted into the path.
    for (final directory in missing.reversed) {
      await _requireDirectory(
        directory.parent,
        description: 'feedback storage ancestor',
      );
      final type = await _typeWithoutFollowingLinks(directory.path);
      if (type == FileSystemEntityType.notFound) {
        await directory.create();
      } else if (type != FileSystemEntityType.directory) {
        throw FileSystemException(
          'Feedback storage ancestors must remain real directories.',
          directory.path,
        );
      }
      await _requireDirectory(
        directory,
        description: 'feedback storage ancestor',
      );
    }

    await _requireDirectory(
      requestedBase,
      description: 'feedback storage base',
    );
    final resolved = Directory(await requestedBase.resolveSymbolicLinks());
    await _requireDirectory(
      resolved,
      description: 'resolved feedback storage base',
    );
    return resolved;
  }

  Future<void> _requireDirectory(
    Directory directory, {
    required String description,
  }) async {
    final type = await _typeWithoutFollowingLinks(directory.path);
    if (type != FileSystemEntityType.directory) {
      throw FileSystemException(
        '$description must be a real directory, not a link, junction, or '
        'reparse point.',
        directory.path,
      );
    }
  }

  Future<void> _requireDirectoryOrMissing(
    Directory directory, {
    required String description,
  }) async {
    final type = await _typeWithoutFollowingLinks(directory.path);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.directory) {
      throw FileSystemException(
        '$description must be a real directory, not a link, junction, or '
        'reparse point.',
        directory.path,
      );
    }
  }

  Future<void> _createDirectoryIfMissing(
    Directory directory, {
    required String description,
  }) async {
    final type = await _typeWithoutFollowingLinks(directory.path);
    if (type == FileSystemEntityType.notFound) {
      await directory.create();
    } else if (type != FileSystemEntityType.directory) {
      throw FileSystemException(
        '$description must be a real directory, not a link, junction, or '
        'reparse point.',
        directory.path,
      );
    }
    await _requireDirectory(directory, description: description);
  }

  Future<void> _requireRegularFile(
    File file, {
    required String description,
  }) async {
    final type = await _typeWithoutFollowingLinks(file.path);
    if (type != FileSystemEntityType.file) {
      throw FileSystemException(
        '$description must be a regular file, not a link, junction, or '
        'reparse point.',
        file.path,
      );
    }
  }

  Future<void> _requireRegularFileOrMissing(
    File file, {
    required String description,
  }) async {
    final type = await _typeWithoutFollowingLinks(file.path);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw FileSystemException(
        '$description must be a regular file, not a link, junction, or '
        'reparse point.',
        file.path,
      );
    }
  }

  Future<void> _validateIndexGenerations(Directory root, String name) async {
    for (final suffix in const <String>['', '.bak', '.tmp']) {
      final candidate = File(
        '${root.path}${Platform.pathSeparator}$name$suffix',
      );
      await _requireExistingDirectoryAncestors(root, candidate.path);
      await _requireRegularFileOrMissing(
        candidate,
        description: 'feedback index generation $name$suffix',
      );
    }
  }

  Future<bool> _anyIndexGenerationExists(File file) async {
    for (final suffix in const <String>['', '.bak', '.tmp']) {
      final candidate = File('${file.path}$suffix');
      final type = await _typeWithoutFollowingLinks(candidate.path);
      if (type == FileSystemEntityType.file) return true;
      if (type != FileSystemEntityType.notFound) {
        throw FileSystemException(
          'Feedback index generations must be regular files.',
          candidate.path,
        );
      }
    }
    return false;
  }

  Future<void> _validateScreenshotEntities(
    Directory root,
    Directory shots,
  ) async {
    await _requireExistingDirectoryAncestors(root, shots.path);
    await for (final entity in shots.list(followLinks: false)) {
      await _requireExistingDirectoryAncestors(root, entity.path);
      final type = await _typeWithoutFollowingLinks(entity.path);
      if (type != FileSystemEntityType.file) {
        throw FileSystemException(
          'Feedback screenshots must be regular files inside the private '
          'screenshot directory.',
          entity.path,
        );
      }
    }
  }

  Future<void> _deleteTreeWithoutFollowingLinks(
    Directory root,
    FileSystemEntity entity,
  ) async {
    _requireContainedPath(root, entity.path);
    await _requireExistingDirectoryAncestors(root, entity.path);
    final type = await _typeWithoutFollowingLinks(entity.path);
    switch (type) {
      case FileSystemEntityType.notFound:
        return;
      case FileSystemEntityType.link:
        await _entityDeleter(Link(entity.path), false);
        return;
      case FileSystemEntityType.file:
        await _entityDeleter(File(entity.path), false);
        return;
      case FileSystemEntityType.directory:
        final directory = Directory(entity.path);
        try {
          // This fast path also lets an injected/platform deletion refusal
          // surface before any children are partially removed. A normal
          // non-empty-directory error carries an OS error and falls through
          // to the explicit non-following walk below.
          await _entityDeleter(directory, false);
          return;
        } on FileSystemException catch (error) {
          if (error.osError == null) rethrow;
        }
        await for (final child in directory.list(followLinks: false)) {
          await _deleteTreeWithoutFollowingLinks(root, child);
        }
        await _entityDeleter(directory, false);
        return;
      default:
        throw FileSystemException(
          'Unsupported private feedback artifact type.',
          entity.path,
        );
    }
  }

  void _requireContainedPath(Directory root, String candidatePath) {
    final rootPath = _comparisonPath(root.path);
    final candidate = _comparisonPath(candidatePath);
    if (candidate == rootPath ||
        !candidate.startsWith('$rootPath${Platform.pathSeparator}')) {
      throw FileSystemException(
        'Refusing to access an artifact outside the feedback namespace.',
        candidatePath,
      );
    }
  }

  Future<void> _requireExistingDirectoryAncestors(
    Directory root,
    String candidatePath,
  ) async {
    _requireContainedPath(root, candidatePath);
    await _requireDirectory(root, description: 'feedback root');
    var current = File(candidatePath).parent;
    final rootPath = _comparisonPath(root.path);
    while (_comparisonPath(current.path) != rootPath) {
      _requireContainedPath(root, current.path);
      await _requireDirectory(current, description: 'feedback path ancestor');
      final parent = current.parent;
      if (_comparisonPath(parent.path) == _comparisonPath(current.path)) {
        throw FileSystemException(
          'Feedback path did not resolve beneath its trusted root.',
          candidatePath,
        );
      }
      current = parent;
    }
  }

  String _comparisonPath(String path) {
    var normalized = File(
      path,
    ).absolute.uri.normalizePath().toFilePath(windows: Platform.isWindows);
    while (normalized.length > 1 &&
        normalized.endsWith(Platform.pathSeparator)) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  String _leafName(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isEmpty ? path : parts.last;
  }

  Future<_ClearedStoreInspection> _inspectClearedStore(Directory root) async {
    try {
      await _requireDirectory(root, description: 'feedback root');
      final lock = File('${root.path}${Platform.pathSeparator}$_lockFileName');
      final entries = File('${root.path}${Platform.pathSeparator}entries.json');
      final logs = File('${root.path}${Platform.pathSeparator}logs.json');
      final shots = Directory('${root.path}${Platform.pathSeparator}shots');
      final entriesEmpty = await _isEmptyActiveIndex(entries);
      final logsEmpty = await _isEmptyActiveIndex(logs);
      final shotsEmpty = await _isEmptyDirectory(shots);
      final recordsRemoved = entriesEmpty && logsEmpty && shotsEmpty;

      final names = <String>{};
      await for (final entity in root.list(followLinks: false)) {
        names.add(_leafName(entity.path));
      }
      const expectedNames = <String>{
        _lockFileName,
        'entries.json',
        'logs.json',
        'shots',
      };
      final cleanInventory =
          recordsRemoved &&
          names.length == expectedNames.length &&
          names.containsAll(expectedNames) &&
          await _typeWithoutFollowingLinks(lock.path) ==
              FileSystemEntityType.file &&
          await _typeWithoutFollowingLinks(entries.path) ==
              FileSystemEntityType.file &&
          await _typeWithoutFollowingLinks(logs.path) ==
              FileSystemEntityType.file &&
          await _typeWithoutFollowingLinks(shots.path) ==
              FileSystemEntityType.directory;
      return _ClearedStoreInspection(
        recordsRemoved: recordsRemoved,
        cleanInventory: cleanInventory,
        problem: cleanInventory
            ? null
            : FileSystemException(
                'Feedback clear left an incomplete or non-empty inventory.',
                root.path,
              ),
      );
    } on Object catch (error) {
      return _ClearedStoreInspection(
        recordsRemoved: false,
        cleanInventory: false,
        problem: error,
      );
    }
  }

  Future<bool> _isEmptyActiveIndex(File file) async {
    if (await _typeWithoutFollowingLinks(file.path) !=
        FileSystemEntityType.file) {
      return false;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is List<Object?> && decoded.isEmpty;
    } on Object {
      return false;
    }
  }

  Future<bool> _isEmptyDirectory(Directory directory) async {
    if (await _typeWithoutFollowingLinks(directory.path) !=
        FileSystemEntityType.directory) {
      return false;
    }
    return await directory.list(followLinks: false).isEmpty;
  }

  String _screenshotPath(Directory root, String fileName) =>
      '${root.path}${Platform.pathSeparator}shots'
      '${Platform.pathSeparator}$fileName';

  bool _isSafeScreenshotName(String value) =>
      _isSafeLeafName(value) && value.toLowerCase().endsWith('.png');

  bool _isSafeLeafName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed != value || value == '.' || value == '..') {
      return false;
    }
    if (value.contains('/') ||
        value.contains(r'\') ||
        value.contains(':') ||
        value.endsWith('.') ||
        value.endsWith(' ')) {
      return false;
    }
    final stem = value.split('.').first.toUpperCase();
    const reserved = <String>{
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    };
    return !reserved.contains(stem);
  }

  int _compareEntriesNewestFirst(
    ReadyFeedbackEntry left,
    ReadyFeedbackEntry right,
  ) {
    final byTime = right.createdAt.compareTo(left.createdAt);
    return byTime != 0 ? byTime : right.id.compareTo(left.id);
  }

  int _compareLogsNewestFirst(
    ReadyFeedbackLogRecord left,
    ReadyFeedbackLogRecord right,
  ) {
    final byTime = right.createdAt.compareTo(left.createdAt);
    return byTime != 0 ? byTime : right.message.compareTo(left.message);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    if (Zone.current[_leaseZoneKey] is _ReadyFeedbackLeaseZoneToken) {
      return Future<T>.error(
        StateError(
          'Public feedback repository operations cannot be started from a '
          'store lease callback. Use the supplied lease methods instead.',
        ),
      );
    }
    final completer = Completer<T>();
    _mutationChain = _mutationChain.then((_) async {
      try {
        completer.complete(await _withStoreLock(operation));
      } on Object catch (error, stackTrace) {
        if (error is ReadyFeedbackStorageException) {
          completer.completeError(error, stackTrace);
        } else if (error is FileSystemException) {
          completer.completeError(
            ReadyFeedbackStorageException(
              'Private feedback storage is temporarily unavailable.',
              cause: error,
            ),
            stackTrace,
          );
        } else {
          completer.completeError(error, stackTrace);
        }
      }
    });
    return completer.future;
  }

  Future<T> _withStoreLock<T>(Future<T> Function() operation) async {
    final root = await _resolveRootDirectory();
    final lockFile = File(
      '${root.path}${Platform.pathSeparator}$_lockFileName',
    );
    final storeKey = _comparisonPath(root.path);
    final prior = _processStoreTails[storeKey] ?? Future<void>.value();
    final processTurn = Completer<void>();
    _processStoreTails[storeKey] = processTurn.future;

    RandomAccessFile? handle;
    var osLockHeld = false;
    var processTurnReached = false;
    try {
      try {
        await prior.timeout(_storeLockTimeout);
        processTurnReached = true;
      } on TimeoutException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          ReadyFeedbackLockTimeoutException(
            'Timed out waiting for another feedback operation in this app '
            'isolate. The earlier operation keeps its place and local data '
            'was not changed by this request.',
            cause: error,
          ),
          stackTrace,
        );
      }
      await _requireDirectory(root, description: 'feedback root');
      await _requireRegularFileOrMissing(
        lockFile,
        description: 'feedback store lock',
      );
      final lockTypeBeforeOpen = await _typeWithoutFollowingLinks(
        lockFile.path,
      );
      final lockBeforeOpen = lockTypeBeforeOpen == FileSystemEntityType.file
          ? await _capturePathFingerprint(lockFile.path)
          : null;
      handle = await lockFile.open(mode: FileMode.append);
      final lockBeforeLock = await _capturePathFingerprint(lockFile.path);
      if (lockBeforeOpen != null && lockBeforeOpen != lockBeforeLock) {
        throw FileSystemException(
          'The feedback lock identity changed while it was being opened.',
          lockFile.path,
        );
      }
      await _acquireOperatingSystemLock(handle);
      osLockHeld = true;
      // Revalidate path types after acquisition so a swapped root or lock
      // path is rejected before any private store access.
      await _requireDirectory(root, description: 'feedback root');
      await _requireRegularFile(lockFile, description: 'feedback store lock');
      final rootAfterLock = await _capturePathFingerprint(root.path);
      final lockAfterLock = await _capturePathFingerprint(lockFile.path);
      if (lockBeforeLock != lockAfterLock) {
        throw FileSystemException(
          'The feedback lock identity changed while exclusion was being '
          'acquired.',
          lockFile.path,
        );
      }
      final identity = _HeldStoreIdentity(
        rootFingerprint: rootAfterLock,
        lockFingerprint: lockAfterLock,
      );
      return await runZoned(
        operation,
        zoneValues: <Object, Object>{_heldStoreIdentityZoneKey: identity},
      );
    } finally {
      try {
        if (handle != null) {
          if (osLockHeld) {
            try {
              await handle.unlock();
            } on Object {
              // Closing the descriptor also releases the operating-system
              // lock.
            }
          }
          await handle.close();
        }
      } finally {
        void releaseProcessTurn() {
          if (!processTurn.isCompleted) processTurn.complete();
          if (identical(_processStoreTails[storeKey], processTurn.future)) {
            _processStoreTails.remove(storeKey);
          }
        }

        if (processTurnReached) {
          releaseProcessTurn();
        } else {
          // A caller timing out must not punch a hole in the FIFO while the
          // earlier operation is still active. Its abandoned turn drains only
          // after the predecessor completes, while the caller still receives
          // a bounded failure.
          unawaited(prior.whenComplete(releaseProcessTurn));
        }
      }
    }
  }

  Future<void> _acquireOperatingSystemLock(RandomAccessFile handle) async {
    // Dart's POSIX advisory locks are process-scoped: another isolate in the
    // same Android process may be allowed to acquire the same exclusive lock.
    // The static FIFO above deliberately closes the same-isolate gap, but Dart
    // offers no shared-memory primitive with which this repository can close
    // the remaining cross-isolate gap. Keep feedback storage on its owning
    // isolate; separate processes are still excluded by this file lock.
    final stopwatch = Stopwatch()..start();
    Object? lastContention;
    while (true) {
      try {
        await handle.lock(FileLock.exclusive);
        return;
      } on FileSystemException catch (error, stackTrace) {
        if (!_isLockContention(error)) rethrow;
        lastContention = error;
        if (stopwatch.elapsed >= _storeLockTimeout) {
          Error.throwWithStackTrace(
            ReadyFeedbackLockTimeoutException(
              'Timed out waiting for the feedback store lock. Another app '
              'process may still be using the private store; retry shortly.',
              cause: lastContention,
            ),
            stackTrace,
          );
        }
        final remaining = _storeLockTimeout - stopwatch.elapsed;
        await Future<void>.delayed(
          remaining < _storeLockRetryDelay ? remaining : _storeLockRetryDelay,
        );
      }
    }
  }

  bool _isLockContention(FileSystemException error) {
    final code = error.osError?.errorCode;
    if (Platform.isWindows) return code == 32 || code == 33;
    return code == 11 || code == 13;
  }

  Future<_PathFingerprint> _capturePathFingerprint(String path) async {
    final type = await _typeWithoutFollowingLinks(path);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.directory) {
      throw FileSystemException(
        'A stable regular file or directory identity was required.',
        path,
      );
    }
    final entity = type == FileSystemEntityType.directory
        ? Directory(path)
        : File(path);
    final stat = await entity.stat();
    final resolved = await entity.resolveSymbolicLinks();
    return _PathFingerprint(
      canonicalPath: _comparisonPath(resolved),
      type: type,
      mode: stat.mode,
      size: stat.size,
      modified: stat.modified,
      changed: stat.changed,
    );
  }

  Future<void> _revalidateHeldStoreIdentity(Directory root) async {
    final identity = Zone.current[_heldStoreIdentityZoneKey];
    if (identity is! _HeldStoreIdentity) return;
    final lock = File('${root.path}${Platform.pathSeparator}$_lockFileName');
    final currentRoot = await _capturePathFingerprint(root.path);
    final currentLock = await _capturePathFingerprint(lock.path);
    if (currentRoot != identity.rootFingerprint ||
        currentLock != identity.lockFingerprint) {
      throw FileSystemException(
        'The feedback store identity changed while its lock was held.',
        root.path,
      );
    }
  }

  Future<void> _refreshHeldStoreIdentity(Directory root) async {
    final identity = Zone.current[_heldStoreIdentityZoneKey];
    if (identity is! _HeldStoreIdentity) return;
    final lock = File('${root.path}${Platform.pathSeparator}$_lockFileName');
    identity
      ..rootFingerprint = await _capturePathFingerprint(root.path)
      ..lockFingerprint = await _capturePathFingerprint(lock.path);
  }
}

class _PngMetadata {
  const _PngMetadata({required this.width, required this.height});

  final int width;
  final int height;
}

class _JsonArrayReadResult {
  const _JsonArrayReadResult({
    required this.values,
    required this.authoritative,
    required this.generationFound,
  });

  final List<Map<String, Object?>> values;
  final bool authoritative;
  final bool generationFound;
}

class _MovedRecoveryArtifact {
  const _MovedRecoveryArtifact({
    required this.quarantinedPath,
    required this.originalPath,
  });

  final String quarantinedPath;
  final String originalPath;
}

class _ClearedStoreInspection {
  const _ClearedStoreInspection({
    required this.recordsRemoved,
    required this.cleanInventory,
    this.problem,
  });

  final bool recordsRemoved;
  final bool cleanInventory;
  final Object? problem;
}

class _ReadyFeedbackLeaseZoneToken {
  const _ReadyFeedbackLeaseZoneToken();
}

class _HeldStoreIdentity {
  _HeldStoreIdentity({
    required this.rootFingerprint,
    required this.lockFingerprint,
  });

  _PathFingerprint rootFingerprint;
  _PathFingerprint lockFingerprint;
}

class _PathFingerprint {
  const _PathFingerprint({
    required this.canonicalPath,
    required this.type,
    required this.mode,
    required this.size,
    required this.modified,
    required this.changed,
  });

  final String canonicalPath;
  final FileSystemEntityType type;
  final int mode;
  final int size;
  final DateTime modified;
  final DateTime changed;

  @override
  bool operator ==(Object other) =>
      other is _PathFingerprint &&
      canonicalPath == other.canonicalPath &&
      type == other.type &&
      mode == other.mode &&
      size == other.size &&
      modified == other.modified &&
      changed == other.changed;

  @override
  int get hashCode =>
      Object.hash(canonicalPath, type, mode, size, modified, changed);
}
