import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect/feedback/src/feedback_config.dart';
import 'package:perfect/feedback/src/feedback_models.dart';
import 'package:perfect/feedback/src/feedback_redactor.dart';
import 'package:perfect/feedback/src/feedback_repository.dart';
import 'package:share_plus/share_plus.dart';

enum ReadyFeedbackExportStatus { saved, shared, cancelled }

class ReadyFeedbackExportResult {
  const ReadyFeedbackExportResult({required this.status, this.path});

  final ReadyFeedbackExportStatus status;
  final String? path;
}

abstract interface class ReadyFeedbackDelivery {
  Future<ReadyFeedbackExportResult> deliver({
    required Uint8List bytes,
    required String fileName,
  });
}

abstract interface class ReadyFeedbackPreparedDelivery {
  Future<ReadyFeedbackExportResult> complete();
}

class ReadyFeedbackDeliveryPreparation {
  ReadyFeedbackDeliveryPreparation({this.token, this.immediateResult});

  final Object? token;
  final ReadyFeedbackExportResult? immediateResult;
  bool _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() => _cancelled = true;
}

abstract interface class ReadyFeedbackTransactionalDelivery {
  Future<ReadyFeedbackDeliveryPreparation> prepare({required String fileName});

  Future<ReadyFeedbackPreparedDelivery> commit({
    required ReadyFeedbackDeliveryPreparation preparation,
    required Uint8List bytes,
    required String fileName,
  });
}

abstract interface class ReadyFeedbackManagedExportPurger {
  Future<void> purgeManagedTemporaryExports();
}

class ReadyFeedbackManagedExportBoundaryException implements Exception {
  const ReadyFeedbackManagedExportBoundaryException(
    this.message, {
    required this.path,
    this.cause,
  });

  final String message;
  final String path;
  final Object? cause;

  @override
  String toString() =>
      'ReadyFeedbackManagedExportBoundaryException: $message ($path)';
}

class ReadyFeedbackExportChangedException implements Exception {
  const ReadyFeedbackExportChangedException();

  @override
  String toString() =>
      'ReadyFeedbackExportChangedException: Feedback changed after review.';
}

typedef ReadyFeedbackTemporaryDirectoryResolver = Future<Directory> Function();
typedef ReadyFeedbackShareInvoker =
    Future<ShareResult> Function(ShareParams params);
typedef ReadyFeedbackSaveLocationResolver =
    Future<String?> Function(String fileName);
typedef ReadyFeedbackFileSaver =
    Future<void> Function({
      required Uint8List bytes,
      required String fileName,
      required String path,
    });

class ReadyFeedbackPlatformDelivery
    implements
        ReadyFeedbackDelivery,
        ReadyFeedbackTransactionalDelivery,
        ReadyFeedbackManagedExportPurger {
  ReadyFeedbackPlatformDelivery({
    ReadyFeedbackTemporaryDirectoryResolver? temporaryDirectoryResolver,
    ReadyFeedbackShareInvoker? shareInvoker,
    ReadyFeedbackSaveLocationResolver? saveLocationResolver,
    ReadyFeedbackFileSaver? fileSaver,
    DateTime Function()? clock,
    bool? isWindows,
    this.maximumManagedExports = 8,
  }) : assert(maximumManagedExports > 0),
       _temporaryDirectoryResolver =
           temporaryDirectoryResolver ?? getTemporaryDirectory,
       _shareInvoker = shareInvoker ?? SharePlus.instance.share,
       _saveLocationResolver =
           saveLocationResolver ?? _defaultSaveLocationResolver,
       _fileSaver = fileSaver ?? _defaultFileSaver,
       _clock = clock ?? DateTime.now,
       _isWindows = isWindows ?? Platform.isWindows;

  static const managedDirectoryName = 'ready-feedback-managed-exports-v1';
  static const managedFilePrefix = 'ready-feedback-managed-';
  static const _windowsCommitMarkerSuffix = '.commit-active';
  static const _maximumManagedAge = Duration(days: 7);
  static final Set<String> _activeWindowsCommitMarkers = <String>{};

  final ReadyFeedbackTemporaryDirectoryResolver _temporaryDirectoryResolver;
  final ReadyFeedbackShareInvoker _shareInvoker;
  final ReadyFeedbackSaveLocationResolver _saveLocationResolver;
  final ReadyFeedbackFileSaver _fileSaver;
  final DateTime Function() _clock;
  final bool _isWindows;
  final int maximumManagedExports;

  @override
  Future<ReadyFeedbackExportResult> deliver({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final preparation = await prepare(fileName: fileName);
    final immediateResult = preparation.immediateResult;
    if (immediateResult != null) return immediateResult;
    return (await commit(
      preparation: preparation,
      bytes: bytes,
      fileName: fileName,
    )).complete();
  }

  @override
  Future<ReadyFeedbackDeliveryPreparation> prepare({
    required String fileName,
  }) async {
    if (_isWindows) {
      final path = await _saveLocationResolver(fileName);
      if (path == null) {
        return ReadyFeedbackDeliveryPreparation(
          immediateResult: const ReadyFeedbackExportResult(
            status: ReadyFeedbackExportStatus.cancelled,
          ),
        );
      }
      final destinationType = await FileSystemEntity.type(
        path,
        followLinks: false,
      );
      if (destinationType != FileSystemEntityType.notFound &&
          destinationType != FileSystemEntityType.file) {
        throw FileSystemException(
          'Selected feedback export destination is not a regular file.',
          path,
        );
      }
      final managedDirectory = (await _managedDirectory(create: true))!;
      final nonce = _clock().toUtc().microsecondsSinceEpoch;
      final stagingPath =
          '${managedDirectory.path}${Platform.pathSeparator}'
          '$managedFilePrefix$nonce.windows.partial';
      final backupPath = '$stagingPath.backup';
      final markerPath = '$stagingPath$_windowsCommitMarkerSuffix';
      for (final privatePath in <String>[stagingPath, backupPath, markerPath]) {
        if (await FileSystemEntity.type(privatePath, followLinks: false) !=
            FileSystemEntityType.notFound) {
          throw FileSystemException(
            'Private feedback export staging path already exists.',
            privatePath,
          );
        }
      }
      return ReadyFeedbackDeliveryPreparation(
        token: _ReadyFeedbackWindowsDestination(
          path: path,
          stagingPath: stagingPath,
          backupPath: backupPath,
          markerPath: markerPath,
          existedBefore: destinationType == FileSystemEntityType.file,
        ),
      );
    }
    return ReadyFeedbackDeliveryPreparation();
  }

  @override
  Future<ReadyFeedbackPreparedDelivery> commit({
    required ReadyFeedbackDeliveryPreparation preparation,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_isWindows) {
      _requireActivePreparation(preparation);
      final destination = preparation.token;
      if (destination is! _ReadyFeedbackWindowsDestination) {
        throw StateError('Windows export destination was not prepared.');
      }
      await _beginWindowsCommit(destination);
      try {
        await _fileSaver(
          bytes: bytes,
          fileName: fileName,
          path: destination.stagingPath,
        );
        _requireActivePreparation(preparation);
        await _commitWindowsDestination(preparation, destination);
      } finally {
        await _finishWindowsCommit(destination);
      }
      return _ReadyFeedbackPreparedDelivery(
        () async => ReadyFeedbackExportResult(
          status: ReadyFeedbackExportStatus.saved,
          path: destination.path,
        ),
      );
    }

    final file = await _stageManagedAndroidExport(
      preparation: preparation,
      bytes: bytes,
      fileName: fileName,
    );
    return _ReadyFeedbackPreparedDelivery(() async {
      final managedDirectory = await _managedDirectory(create: false);
      if (managedDirectory == null) {
        throw FileSystemException(
          'The managed feedback ZIP was cleared before sharing.',
          file.path,
        );
      }
      await _requireRegularContainedFile(managedDirectory, file);
      final result = await _shareInvoker(
        ShareParams(
          title: 'Private feedback bundle',
          subject: 'Private feedback bundle',
          text: 'Local feedback export from the app.',
          files: <XFile>[XFile(file.path, mimeType: 'application/zip')],
          fileNameOverrides: <String>[fileName],
        ),
      );
      return ReadyFeedbackExportResult(
        status: result.status == ShareResultStatus.dismissed
            ? ReadyFeedbackExportStatus.cancelled
            : ReadyFeedbackExportStatus.shared,
        path: file.path,
      );
    });
  }

  static Future<String?> _defaultSaveLocationResolver(String fileName) async {
    const archiveType = XTypeGroup(
      label: 'ZIP archive',
      extensions: <String>['zip'],
    );
    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: const <XTypeGroup>[archiveType],
    );
    return location?.path;
  }

  static Future<void> _defaultFileSaver({
    required Uint8List bytes,
    required String fileName,
    required String path,
  }) => XFile.fromData(
    bytes,
    mimeType: 'application/zip',
    name: fileName,
  ).saveTo(path);

  Future<File> _stageManagedAndroidExport({
    required ReadyFeedbackDeliveryPreparation preparation,
    required Uint8List bytes,
    required String fileName,
  }) async {
    _requireActivePreparation(preparation);
    final managedDirectory = (await _managedDirectory(create: true))!;
    _requireActivePreparation(preparation);
    await _pruneManagedExports(managedDirectory);
    _requireActivePreparation(preparation);
    final managedName = '$managedFilePrefix${_safeFileName(fileName)}';
    final file = File(
      '${managedDirectory.path}${Platform.pathSeparator}$managedName',
    );
    final partial = File('${file.path}.partial');
    _requireLexicallyContained(managedDirectory, file);
    for (final candidate in <File>[file, partial]) {
      final type = await FileSystemEntity.type(
        candidate.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.notFound) {
        throw ReadyFeedbackManagedExportBoundaryException(
          'Managed feedback export target already exists or is interrupted.',
          path: candidate.path,
        );
      }
    }
    await partial.writeAsBytes(bytes, flush: true);
    if (preparation.cancelled) {
      await _deleteFileIfPresent(partial);
      _requireActivePreparation(preparation);
    }
    await _requireRegularContainedFile(managedDirectory, partial);
    await partial.rename(file.path);
    if (preparation.cancelled) {
      await _deleteFileIfPresent(file);
      _requireActivePreparation(preparation);
    }
    await _requireRegularContainedFile(managedDirectory, file);
    await _pruneManagedExports(managedDirectory, preserve: file);
    return file;
  }

  void _requireActivePreparation(ReadyFeedbackDeliveryPreparation preparation) {
    if (preparation.cancelled) {
      throw StateError('Feedback export commit exceeded its safe deadline.');
    }
  }

  Future<void> _deleteFileIfPresent(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.file) await file.delete();
  }

  Future<void> _commitWindowsDestination(
    ReadyFeedbackDeliveryPreparation preparation,
    _ReadyFeedbackWindowsDestination destination,
  ) async {
    final staging = File(destination.stagingPath);
    final output = File(destination.path);
    final backup = File(destination.backupPath);
    var backupCreated = false;
    var outputCommitted = false;
    try {
      if (destination.existedBefore) {
        await output.copy(backup.path);
        backupCreated = true;
        if (preparation.cancelled) {
          await backup.copy(output.path);
          _requireActivePreparation(preparation);
        }
      }
      await staging.copy(output.path);
      outputCommitted = true;
      if (preparation.cancelled) {
        await _deleteFileIfPresent(output);
        outputCommitted = false;
        if (backupCreated) {
          await backup.copy(output.path);
        }
        _requireActivePreparation(preparation);
      }
      if (backupCreated) {
        await backup.delete();
        backupCreated = false;
      }
    } on Object {
      if (outputCommitted && backupCreated) {
        await _deleteFileIfPresent(output);
        await backup.copy(output.path);
      } else if (!outputCommitted && backupCreated) {
        await backup.copy(output.path);
      }
      rethrow;
    }
  }

  Future<void> _beginWindowsCommit(
    _ReadyFeedbackWindowsDestination destination,
  ) async {
    final directory = (await _managedDirectory(create: true))!;
    for (final path in <String>[
      destination.stagingPath,
      destination.backupPath,
      destination.markerPath,
    ]) {
      if (!_isPathInside(directory, path)) {
        throw ReadyFeedbackManagedExportBoundaryException(
          'Windows feedback export staging escaped managed storage.',
          path: path,
        );
      }
    }
    await File(destination.markerPath).writeAsString(
      'active managed Windows feedback export commit',
      flush: true,
    );
    _activeWindowsCommitMarkers.add(_normalizedPath(destination.markerPath));
  }

  Future<void> _finishWindowsCommit(
    _ReadyFeedbackWindowsDestination destination,
  ) async {
    try {
      for (final path in <String>[
        destination.stagingPath,
        destination.backupPath,
        destination.markerPath,
      ]) {
        await _deleteFileIfPresent(File(path));
      }
      final directory = await _managedDirectory(create: false);
      if (directory != null &&
          await directory.list(followLinks: false).isEmpty) {
        await directory.delete();
      }
    } finally {
      _activeWindowsCommitMarkers.remove(
        _normalizedPath(destination.markerPath),
      );
    }
  }

  bool _isPathInside(Directory directory, String path) {
    final root = _normalizedPath(directory.absolute.path);
    final candidate = _normalizedPath(File(path).absolute.path);
    return candidate.startsWith('$root${Platform.pathSeparator}');
  }

  @override
  Future<void> purgeManagedTemporaryExports() async {
    final directory = await _managedDirectory(create: false);
    if (directory == null) return;
    final activeMarkers = _activeWindowsCommitMarkers.where(
      (path) => _isPathInside(directory, path),
    );
    if (activeMarkers.isNotEmpty) {
      throw FileSystemException(
        'A Windows feedback export commit is still active. Managed cleanup '
        'cannot complete yet.',
        activeMarkers.first,
      );
    }
    final failures = <Object>[];
    await for (final entity in directory.list(followLinks: false)) {
      try {
        await _deleteManagedEntity(directory, entity);
      } on Object catch (error) {
        failures.add(error);
      }
    }
    try {
      await directory.delete();
    } on Object catch (error) {
      failures.add(error);
    }
    final remainingType = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (remainingType != FileSystemEntityType.notFound) {
      failures.add(
        FileSystemException(
          'Perfect-managed export directory remained after cleanup.',
          directory.path,
        ),
      );
    }
    if (failures.isNotEmpty) {
      throw FileSystemException(
        'Perfect-managed temporary feedback exports could not be completely '
        'deleted.',
        directory.path,
      );
    }
  }

  Future<Directory?> _managedDirectory({required bool create}) async {
    final declaredTemporary = await _temporaryDirectoryResolver();
    final temporary = await _canonicalLinkFreeDirectory(
      declaredTemporary,
      description: 'temporary directory',
    );
    final directory = Directory(
      '${temporary.path}${Platform.pathSeparator}$managedDirectoryName',
    );
    _requireLexicallyContained(temporary, directory);
    final type = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) {
      if (!create) return null;
      await directory.create(recursive: true);
    } else if (type != FileSystemEntityType.directory) {
      throw ReadyFeedbackManagedExportBoundaryException(
        'Managed feedback export location is not a directory.',
        path: directory.path,
      );
    }
    final canonicalDirectory = await _canonicalLinkFreeDirectory(
      directory,
      description: 'managed export directory',
    );
    await _requireCanonicallyContained(temporary, canonicalDirectory);
    return canonicalDirectory;
  }

  Future<void> _pruneManagedExports(
    Directory directory, {
    File? preserve,
  }) async {
    final candidates = <_ReadyFeedbackManagedExportCandidate>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (!_isManagedZip(directory, entity)) {
        throw ReadyFeedbackManagedExportBoundaryException(
          'Managed export directory contains an unexpected or interrupted '
          'artifact. Clear private feedback before exporting again.',
          path: entity.path,
        );
      }
      final file = entity as File;
      try {
        await _requireRegularContainedFile(directory, file);
        candidates.add(
          _ReadyFeedbackManagedExportCandidate(
            file,
            (await file.stat()).modified,
          ),
        );
      } on ReadyFeedbackManagedExportBoundaryException {
        rethrow;
      } on Object catch (error) {
        throw ReadyFeedbackManagedExportBoundaryException(
          'Managed export artifact could not be verified.',
          path: file.path,
          cause: error,
        );
      }
    }
    candidates.sort((left, right) {
      if (preserve != null) {
        if (_samePath(left.file, preserve)) return -1;
        if (_samePath(right.file, preserve)) return 1;
      }
      return right.modified.compareTo(left.modified);
    });
    final cutoff = _clock().subtract(_maximumManagedAge);
    var retained = 0;
    for (final candidate in candidates) {
      final file = candidate.file;
      if (preserve != null && _samePath(file, preserve)) {
        retained++;
        continue;
      }
      try {
        if (candidate.modified.isBefore(cutoff) ||
            retained >= maximumManagedExports) {
          await file.delete();
        } else {
          retained++;
        }
      } on Object {
        // Retention is best-effort during export. Explicit Clear reports any
        // managed-cache deletion failure to the owner.
      }
    }
  }

  bool _isManagedZip(Directory directory, FileSystemEntity entity) {
    if (entity is! File) return false;
    _requireLexicallyContained(directory, entity);
    final name = entity.path.split(RegExp(r'[/\\]')).last;
    return name.startsWith(managedFilePrefix) && name.endsWith('.zip');
  }

  String _safeFileName(String value) {
    final basename = value.split(RegExp(r'[/\\]')).last;
    final safe = basename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
    return safe.toLowerCase().endsWith('.zip') ? safe : '$safe.zip';
  }

  Future<Directory> _canonicalLinkFreeDirectory(
    Directory directory, {
    required String description,
  }) async {
    final absolute = directory.absolute;
    var current = absolute;
    while (true) {
      final type = await FileSystemEntity.type(
        current.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.link) {
        throw ReadyFeedbackManagedExportBoundaryException(
          '$description or one of its ancestors is a link or junction.',
          path: current.path,
        );
      }
      if (type != FileSystemEntityType.directory) {
        throw ReadyFeedbackManagedExportBoundaryException(
          '$description or one of its ancestors is not a directory.',
          path: current.path,
        );
      }
      final parent = current.parent;
      if (_sameDirectoryPath(parent, current)) break;
      current = parent;
    }
    try {
      final resolved = Directory(await absolute.resolveSymbolicLinks());
      if (!_sameDirectoryPath(resolved, absolute)) {
        throw ReadyFeedbackManagedExportBoundaryException(
          '$description did not resolve to its declared canonical path.',
          path: absolute.path,
        );
      }
      return resolved;
    } on ReadyFeedbackManagedExportBoundaryException {
      rethrow;
    } on Object catch (error) {
      throw ReadyFeedbackManagedExportBoundaryException(
        '$description could not be resolved safely.',
        path: absolute.path,
        cause: error,
      );
    }
  }

  Future<void> _requireCanonicallyContained(
    Directory root,
    Directory directory,
  ) async {
    final canonicalRoot = Directory(await root.resolveSymbolicLinks());
    final canonicalDirectory = Directory(
      await directory.resolveSymbolicLinks(),
    );
    _requireLexicallyContained(canonicalRoot, canonicalDirectory);
  }

  Future<void> _requireRegularContainedFile(Directory root, File file) async {
    _requireLexicallyContained(root, file);
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw ReadyFeedbackManagedExportBoundaryException(
        'Managed feedback export is not a regular file.',
        path: file.path,
      );
    }
    final canonical = File(await file.resolveSymbolicLinks());
    _requireLexicallyContained(root, canonical);
  }

  Future<void> _deleteManagedEntity(
    Directory root,
    FileSystemEntity entity,
  ) async {
    _requireLexicallyContained(root, entity);
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    switch (type) {
      case FileSystemEntityType.file:
        await File(entity.path).delete();
        return;
      case FileSystemEntityType.link:
        await Link(entity.path).delete();
        return;
      case FileSystemEntityType.directory:
        final directory = await _canonicalLinkFreeDirectory(
          Directory(entity.path),
          description: 'managed export subdirectory',
        );
        await _requireCanonicallyContained(root, directory);
        await for (final child in directory.list(followLinks: false)) {
          await _deleteManagedEntity(root, child);
        }
        await directory.delete();
        return;
      case FileSystemEntityType.notFound:
        return;
      default:
        throw ReadyFeedbackManagedExportBoundaryException(
          'Managed export directory contains an unsupported entity.',
          path: entity.path,
        );
    }
  }

  void _requireLexicallyContained(Directory root, FileSystemEntity entity) {
    final separator = Platform.pathSeparator;
    final rootPath = _normalizedPath(root.absolute.path);
    final entityPath = _normalizedPath(entity.absolute.path);
    if (!entityPath.startsWith('$rootPath$separator')) {
      throw ReadyFeedbackManagedExportBoundaryException(
        'Managed feedback export escaped its private cache directory.',
        path: entity.path,
      );
    }
  }

  bool _samePath(File left, File right) =>
      _normalizedPath(left.absolute.path) ==
      _normalizedPath(right.absolute.path);

  bool _sameDirectoryPath(Directory left, Directory right) =>
      _normalizedPath(left.absolute.path) ==
      _normalizedPath(right.absolute.path);

  String _normalizedPath(String value) =>
      Platform.isWindows ? value.toLowerCase() : value;
}

class _ReadyFeedbackManagedExportCandidate {
  const _ReadyFeedbackManagedExportCandidate(this.file, this.modified);

  final File file;
  final DateTime modified;
}

class _ReadyFeedbackWindowsDestination {
  const _ReadyFeedbackWindowsDestination({
    required this.path,
    required this.stagingPath,
    required this.backupPath,
    required this.markerPath,
    required this.existedBefore,
  });

  final String path;
  final String stagingPath;
  final String backupPath;
  final String markerPath;
  final bool existedBefore;
}

class _ReadyFeedbackPreparedDelivery implements ReadyFeedbackPreparedDelivery {
  const _ReadyFeedbackPreparedDelivery(this._complete);

  final Future<ReadyFeedbackExportResult> Function() _complete;

  @override
  Future<ReadyFeedbackExportResult> complete() => _complete();
}

class ReadyFeedbackExporter {
  ReadyFeedbackExporter({
    required this.config,
    required this.repository,
    ReadyFeedbackDelivery? delivery,
    Future<PackageInfo> Function()? packageInfoResolver,
    DateTime Function()? clock,
    Duration commitTimeout = const Duration(seconds: 15),
  }) : _delivery = delivery ?? ReadyFeedbackPlatformDelivery(),
       _packageInfoResolver = packageInfoResolver ?? PackageInfo.fromPlatform,
       _clock = clock ?? DateTime.now,
       assert(commitTimeout > Duration.zero),
       _commitTimeout = commitTimeout;

  final ReadyFeedbackConfig config;
  final ReadyFeedbackRepository repository;
  final ReadyFeedbackDelivery _delivery;
  final Future<PackageInfo> Function() _packageInfoResolver;
  final DateTime Function() _clock;
  final Duration _commitTimeout;

  Future<ReadyFeedbackExportResult> export() => _export();

  Future<ReadyFeedbackExportResult> exportApprovedSnapshot(
    ReadyFeedbackRepositorySnapshot approvedSnapshot,
  ) => _export(approvedSnapshot: approvedSnapshot);

  Future<ReadyFeedbackExportResult> _export({
    ReadyFeedbackRepositorySnapshot? approvedSnapshot,
  }) async {
    final now = _clock().toUtc();
    final stamp = now.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final slug = config.applicationName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final fileName = '${slug.isEmpty ? 'app' : slug}-feedback-$stamp.zip';
    final delivery = _delivery;
    final ReadyFeedbackTransactionalDelivery? transactionalDelivery =
        delivery is ReadyFeedbackTransactionalDelivery
        ? delivery as ReadyFeedbackTransactionalDelivery
        : null;
    ReadyFeedbackDeliveryPreparation? preparation;
    if (transactionalDelivery != null) {
      final prepared = await transactionalDelivery.prepare(fileName: fileName);
      preparation = prepared;
      final immediateResult = prepared.immediateResult;
      if (immediateResult != null) return immediateResult;
    }
    final packageInfo = await _resolvePackageInfo();
    ReadyFeedbackPreparedDelivery? preparedDelivery;
    late Uint8List archiveBytes;
    await repository.withStoreLease((lease) async {
      final currentSnapshot = await lease.createExportSnapshot();
      if (approvedSnapshot != null &&
          !_sameSnapshot(currentSnapshot, approvedSnapshot)) {
        throw const ReadyFeedbackExportChangedException();
      }
      final snapshot = approvedSnapshot ?? currentSnapshot;
      final bytes = _buildArchiveFromSnapshot(
        snapshot,
        packageInfo: packageInfo,
      );
      if (transactionalDelivery != null) {
        try {
          preparedDelivery = await transactionalDelivery
              .commit(
                preparation: preparation!,
                bytes: bytes,
                fileName: fileName,
              )
              .timeout(_commitTimeout);
        } on TimeoutException {
          preparation!.cancel();
          rethrow;
        }
      } else {
        // A generic delivery has no app-managed stage to race with Clear.
        // Native/custom UI therefore runs after the store lease is released.
        archiveBytes = bytes;
      }
    });
    if (preparedDelivery != null) return preparedDelivery!.complete();
    return delivery.deliver(bytes: archiveBytes, fileName: fileName);
  }

  Future<void> purgeManagedTemporaryExports() async {
    final delivery = _delivery;
    final ReadyFeedbackManagedExportPurger? managedExportPurger =
        delivery is ReadyFeedbackManagedExportPurger
        ? delivery as ReadyFeedbackManagedExportPurger
        : null;
    if (managedExportPurger != null) {
      await managedExportPurger.purgeManagedTemporaryExports();
    }
  }

  Future<Uint8List> buildArchive() async {
    final snapshot = await repository.createExportSnapshot();
    return _buildArchiveFromSnapshot(
      snapshot,
      packageInfo: await _resolvePackageInfo(),
    );
  }

  Future<PackageInfo?> _resolvePackageInfo() async {
    try {
      return await _packageInfoResolver();
    } on Object {
      // Package metadata is helpful, not required for a valid report.
      return null;
    }
  }

  Uint8List _buildArchiveFromSnapshot(
    ReadyFeedbackRepositorySnapshot snapshot, {
    required PackageInfo? packageInfo,
  }) {
    final entries = snapshot.entries;
    final logs = snapshot.logs;
    final generatedAt = _clock().toUtc();

    final archive = Archive();
    final report = utf8.encode(
      _buildReport(
        entries: entries,
        logs: logs,
        packageInfo: packageInfo,
        generatedAt: generatedAt,
      ),
    );
    archive.addFile(ArchiveFile('report.md', report.length, report));

    final manifest = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schemaVersion': 1,
        'generatedAt': generatedAt.toIso8601String(),
        'application': config.applicationName,
        'appVersion': packageInfo?.version,
        'buildNumber': packageInfo?.buildNumber,
        'platform': Platform.operatingSystem,
        'entryCount': entries.length,
        'logCount': logs.length,
        'screenshotsIncluded': snapshot.screenshots.length,
        'screenshotPixelsRedacted': false,
        'entries': entries.map((entry) => entry.toJson()).toList(),
      }),
    );
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));

    for (final entry in entries) {
      final fileName = entry.screenshotFileName;
      if (fileName == null) continue;
      final screenshot = snapshot.screenshots[fileName];
      if (screenshot == null) continue;
      archive.addFile(
        ArchiveFile('screenshots/$fileName', screenshot.length, screenshot),
      );
    }

    final logText = logs
        .map(
          (log) => jsonEncode(<String, Object?>{
            ...log.toJson(),
            'message': ReadyFeedbackRedactor.redact(log.message),
            'stackTrace': log.stackTrace == null
                ? null
                : ReadyFeedbackRedactor.redact(log.stackTrace!),
          }),
        )
        .join('\n');
    final logBytes = utf8.encode(logText);
    archive.addFile(
      ArchiveFile('logs/recent.jsonl', logBytes.length, logBytes),
    );

    return ZipEncoder().encodeBytes(archive);
  }

  bool _sameSnapshot(
    ReadyFeedbackRepositorySnapshot left,
    ReadyFeedbackRepositorySnapshot right,
  ) {
    if (jsonEncode(left.entries.map((entry) => entry.toJson()).toList()) !=
        jsonEncode(right.entries.map((entry) => entry.toJson()).toList())) {
      return false;
    }
    if (jsonEncode(left.logs.map((log) => log.toJson()).toList()) !=
        jsonEncode(right.logs.map((log) => log.toJson()).toList())) {
      return false;
    }
    if (left.screenshots.length != right.screenshots.length) return false;
    for (final entry in left.screenshots.entries) {
      final other = right.screenshots[entry.key];
      if (other == null || !_sameBytes(entry.value, other)) return false;
    }
    return true;
  }

  bool _sameBytes(Uint8List left, Uint8List right) {
    if (left.lengthInBytes != right.lengthInBytes) return false;
    for (var index = 0; index < left.lengthInBytes; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  String _buildReport({
    required List<ReadyFeedbackEntry> entries,
    required List<ReadyFeedbackLogRecord> logs,
    required PackageInfo? packageInfo,
    required DateTime generatedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('# ${config.applicationName} private feedback report')
      ..writeln()
      ..writeln('Generated: ${generatedAt.toIso8601String()}')
      ..writeln('Platform: ${Platform.operatingSystem}')
      ..writeln(
        'OS: ${ReadyFeedbackRedactor.redact(Platform.operatingSystemVersion)}',
      )
      ..writeln('Locale: ${Platform.localeName}')
      ..writeln(
        'App version: ${packageInfo?.version ?? 'unknown'} '
        '(${packageInfo?.buildNumber ?? 'unknown'})',
      )
      ..writeln('Entries: ${entries.length}')
      ..writeln('Recent logs: ${logs.length}')
      ..writeln()
      ..writeln(
        '> Credentials and common token formats are redacted. Notes are '
        'owner-authored and should still be reviewed before sharing.',
      )
      ..writeln(
        '> Screenshot pixels are included exactly as captured and are not '
        'redacted. Review every image before sharing this ZIP.',
      )
      ..writeln();

    for (final entry in entries) {
      buffer
        ..writeln(
          '## ${entry.kind.label} — ${entry.createdAt.toIso8601String()}',
        )
        ..writeln()
        ..writeln(
          '- Route: ${_markdown(ReadyFeedbackRedactor.redact(entry.route))}',
        )
        ..writeln(
          '- Screenshot: ${entry.screenshotFileName == null ? 'none' : 'screenshots/${entry.screenshotFileName}'}',
        )
        ..writeln('- Screenshot metadata: ${_screenshotMetadata(entry)}')
        ..writeln()
        ..writeln(_markdown(ReadyFeedbackRedactor.redact(entry.note)))
        ..writeln();
    }
    return buffer.toString();
  }

  String _markdown(String value) => value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'^>', multiLine: true), r'\>');

  String _screenshotMetadata(ReadyFeedbackEntry entry) {
    if (!entry.hasScreenshot) return 'none';
    final size =
        entry.screenshotWidthPx == null || entry.screenshotHeightPx == null
        ? 'unknown dimensions'
        : '${entry.screenshotWidthPx}x${entry.screenshotHeightPx}px';
    final bytes = entry.screenshotByteLength == null
        ? 'unknown bytes'
        : '${entry.screenshotByteLength} bytes';
    final ratio = entry.screenshotPixelRatio == null
        ? 'unknown pixel ratio'
        : '${entry.screenshotPixelRatio}x pixel ratio';
    return '$size, $bytes, $ratio';
  }
}
