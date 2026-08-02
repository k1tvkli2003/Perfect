import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:perfect/feedback/src/feedback_config.dart';
import 'package:perfect/feedback/src/feedback_exporter.dart';
import 'package:perfect/feedback/src/feedback_logger.dart';
import 'package:perfect/feedback/src/feedback_models.dart';
import 'package:perfect/feedback/src/feedback_redactor.dart';
import 'package:perfect/feedback/src/feedback_repository.dart';
import 'package:perfect/feedback/src/feedback_settings.dart';

typedef ReadyFeedbackClock = DateTime Function();
typedef ReadyFeedbackIdFactory = String Function();

class ReadyFeedbackController extends ChangeNotifier {
  ReadyFeedbackController({
    required this.config,
    ReadyFeedbackRepository? repository,
    ReadyFeedbackSettingsStore? settingsStore,
    ReadyFeedbackLogger? logger,
    ReadyFeedbackClock? clock,
    ReadyFeedbackIdFactory? idFactory,
    ReadyFeedbackExporter? exporter,
  }) : repository = repository ?? ReadyFeedbackRepository(config: config),
       settingsStore =
           settingsStore ??
           SharedPreferencesReadyFeedbackSettingsStore(config.settingsKey),
       logger = logger ?? ReadyFeedbackLogger.instance,
       _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _defaultId,
       _providedExporter = exporter;

  final ReadyFeedbackConfig config;
  final ReadyFeedbackRepository repository;
  final ReadyFeedbackSettingsStore settingsStore;
  final ReadyFeedbackLogger logger;
  final ReadyFeedbackClock _clock;
  final ReadyFeedbackIdFactory _idFactory;
  final ReadyFeedbackExporter? _providedExporter;

  Future<void>? _initialization;
  bool _initialized = false;
  bool _enabled = false;
  bool _busy = false;
  bool _disposed = false;
  int _entryCount = 0;
  ReadyFeedbackExportPreview? _preparedExportPreview;
  ReadyFeedbackRepositorySnapshot? _preparedExportSnapshot;

  bool get initialized => _initialized;
  bool get enabled => _enabled;
  bool get busy => _busy;
  int get entryCount => _entryCount;

  Future<void> initialize() {
    _checkNotDisposed();
    if (_initialized) return Future<void>.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    var enabled = config.enabledByDefault;
    var count = 0;
    try {
      enabled = await settingsStore.readEnabled() ?? config.enabledByDefault;
    } on Object catch (error, stackTrace) {
      logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Reading feedback capture setting',
      );
    }
    try {
      count = (await repository.readEntries()).length;
    } on Object catch (error, stackTrace) {
      logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Reading feedback capture entries',
      );
    }
    if (_disposed) return;
    _enabled = enabled;
    _entryCount = count;
    logger.attachRepository(repository, owner: this);
    _initialized = true;
    _notifySafely();
  }

  Future<void> setEnabled(bool value) async {
    _checkNotDisposed();
    if (_enabled == value) return;
    final previous = _enabled;
    _enabled = value;
    _notifySafely();
    try {
      await settingsStore.writeEnabled(value);
    } on Object catch (error, stackTrace) {
      _enabled = previous;
      _notifySafely();
      logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Saving feedback capture setting',
      );
      rethrow;
    }
  }

  Future<ReadyFeedbackEntry> addEntry({
    required String route,
    required String note,
    required ReadyFeedbackKind kind,
    ReadyFeedbackScreenshotCapture? screenshot,
    Uint8List? screenshotBytes,
  }) => _withBusy(() async {
    final normalizedNote = note.trim();
    final hasScreenshot =
        (screenshot != null && screenshot.bytes.isNotEmpty) ||
        (screenshotBytes != null && screenshotBytes.isNotEmpty);
    if (normalizedNote.isEmpty && !hasScreenshot) {
      throw ArgumentError('A note or screenshot is required.');
    }
    final entry = await repository.addEntry(
      ReadyFeedbackEntry(
        id: _idFactory(),
        createdAt: _clock().toUtc(),
        route: ReadyFeedbackRedactor.redactAndLimit(
          route.trim().isEmpty ? 'Unknown' : route.trim(),
          config.maxRouteCharacters,
        ),
        note: ReadyFeedbackRedactor.redactAndLimit(
          normalizedNote,
          config.maxNoteCharacters,
        ),
        kind: kind,
      ),
      screenshot: screenshot,
      screenshotBytes: screenshotBytes,
    );
    _entryCount = (await repository.readEntries()).length;
    _discardPreparedExport();
    _notifySafely();
    return entry;
  });

  Future<List<ReadyFeedbackEntry>> readEntries() {
    _checkNotDisposed();
    return repository.readEntries();
  }

  Future<Uint8List?> readScreenshot(ReadyFeedbackEntry entry) {
    _checkNotDisposed();
    return repository.readScreenshot(entry);
  }

  Future<void> deleteEntry(String id) => _withBusy(() async {
    _discardPreparedExport();
    try {
      await repository.deleteEntry(id);
    } on ReadyFeedbackCleanupException catch (error) {
      if (error.recordsRemoved) {
        _entryCount = (await repository.readEntries()).length;
        _notifySafely();
      }
      rethrow;
    }
    _entryCount = (await repository.readEntries()).length;
    _notifySafely();
  });

  Future<void> clearAll() => _withBusy(() async {
    _discardPreparedExport();
    logger.detachRepository(repository, owner: this);
    logger.clearBuffer();
    Object? failure;
    StackTrace? failureStackTrace;
    var recordsRemoved = false;
    try {
      try {
        await repository.withStoreLease((lease) async {
          Object? leaseFailure;
          StackTrace? leaseFailureStackTrace;
          try {
            await lease.clearAll();
          } on Object catch (error, stackTrace) {
            leaseFailure = error;
            leaseFailureStackTrace = stackTrace;
          }
          try {
            await _exporter.purgeManagedTemporaryExports();
          } on Object catch (error, stackTrace) {
            if (leaseFailure == null) {
              leaseFailure = ReadyFeedbackCleanupException(
                'Private feedback records were removed, but one or more '
                'Perfect-managed temporary share ZIPs could not be deleted. '
                'Saved or shared copies outside Perfect are not controlled '
                'by the app.',
                cause: error,
              );
              leaseFailureStackTrace = stackTrace;
            }
          }
          if (leaseFailure != null) {
            Error.throwWithStackTrace(leaseFailure, leaseFailureStackTrace!);
          }
        });
        recordsRemoved = true;
      } on Object catch (error, stackTrace) {
        failure = error;
        failureStackTrace = stackTrace;
        recordsRemoved =
            error is ReadyFeedbackStorageException && error.recordsRemoved;
      }

      try {
        _entryCount = (await repository.readEntries()).length;
      } on Object catch (error, stackTrace) {
        if (recordsRemoved) _entryCount = 0;
        if (failure == null) {
          failure = error;
          failureStackTrace = stackTrace;
        }
      }
    } finally {
      // Logs captured before or during cleanup must not be persisted into the
      // freshly rebuilt store when the repository is attached again.
      logger.clearBuffer();
      if (!_disposed) logger.attachRepository(repository, owner: this);
      _notifySafely();
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure, failureStackTrace!);
    }
  });

  Future<ReadyFeedbackExportPreview> exportPreview() async {
    _checkNotDisposed();
    final snapshot = await repository.createExportSnapshot();
    final preview = ReadyFeedbackExportPreview(
      entryCount: snapshot.entries.length,
      screenshotCount: snapshot.screenshots.length,
      logCount: snapshot.logs.length,
    );
    _preparedExportPreview = preview;
    _preparedExportSnapshot = snapshot;
    return preview;
  }

  void discardExportPreview(ReadyFeedbackExportPreview preview) {
    _checkNotDisposed();
    if (identical(_preparedExportPreview, preview)) _discardPreparedExport();
  }

  Future<ReadyFeedbackRecoveryResult> recoverCorruptStore({
    required bool ownerConfirmed,
  }) => _withBusy(() async {
    _discardPreparedExport();
    logger.detachRepository(repository, owner: this);
    logger.clearBuffer();
    try {
      final result = await repository.recoverCorruptStore(
        ownerConfirmed: ownerConfirmed,
      );
      _entryCount = 0;
      _notifySafely();
      return result;
    } finally {
      logger.clearBuffer();
      if (!_disposed) logger.attachRepository(repository, owner: this);
    }
  });

  Future<ReadyFeedbackExportResult> export({
    ReadyFeedbackExportPreview? preview,
  }) => _withBusy(() {
    if (preview == null) return _exporter.export();
    if (!identical(preview, _preparedExportPreview) ||
        _preparedExportSnapshot == null) {
      throw const ReadyFeedbackExportChangedException();
    }
    final snapshot = _preparedExportSnapshot!;
    _discardPreparedExport();
    return _exporter.exportApprovedSnapshot(snapshot);
  });

  ReadyFeedbackExporter get _exporter =>
      _providedExporter ??
      ReadyFeedbackExporter(config: config, repository: repository);

  void _discardPreparedExport() {
    _preparedExportPreview = null;
    _preparedExportSnapshot = null;
  }

  Future<T> _withBusy<T>(Future<T> Function() operation) async {
    _checkNotDisposed();
    if (_busy) throw StateError('Feedback capture is already busy.');
    _busy = true;
    _notifySafely();
    try {
      return await operation();
    } finally {
      _busy = false;
      _notifySafely();
    }
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('Feedback controller is disposed.');
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _discardPreparedExport();
    logger.detachRepository(repository, owner: this);
    super.dispose();
  }

  static String _defaultId() {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$random';
  }
}
