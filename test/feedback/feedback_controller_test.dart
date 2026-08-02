import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';

void main() {
  test(
    'default enablement, toggle, and entry count persist through adapters',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-controller-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-test',
        settingsKey: 'feedback.enabled',
      );
      final settings = _MemorySettings();
      final controller = ReadyFeedbackController(
        config: config,
        repository: ReadyFeedbackRepository(
          config: config,
          rootDirectoryResolver: () async => temporary,
        ),
        settingsStore: settings,
        clock: () => DateTime.utc(2026, 8, 2),
        idFactory: () => 'one',
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.enabled, isTrue);

      await controller.setEnabled(false);
      expect(settings.value, isFalse);

      await controller.addEntry(
        route: 'More',
        note: 'Improve this setting',
        kind: ReadyFeedbackKind.suggestion,
      );
      expect(controller.entryCount, 1);
    },
  );

  test(
    'dispose during initialization prevents a late logger attachment',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-controller-lifecycle-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-lifecycle-test',
        settingsKey: 'feedback.enabled',
      );
      final entries = Completer<List<ReadyFeedbackEntry>>();
      final logger = _SpyLogger();
      final controller = ReadyFeedbackController(
        config: config,
        repository: _DelayedRepository(
          config: config,
          temporary: temporary,
          entries: entries,
        ),
        settingsStore: _MemorySettings(),
        logger: logger,
      );

      final initialization = controller.initialize();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      entries.complete(const <ReadyFeedbackEntry>[]);
      await initialization;

      expect(logger.attachments, 0);
      expect(controller.initialized, isFalse);
      expect(controller.readEntries, throwsStateError);
    },
  );

  test(
    'committed cleanup failure still refreshes the visible entry count',
    () async {
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-cleanup-test',
        settingsKey: 'feedback.enabled',
      );
      final repository = _CommittedCleanupRepository(config: config);
      final logger = ReadyFeedbackLogger();
      addTearDown(logger.dispose);
      final controller = ReadyFeedbackController(
        config: config,
        repository: repository,
        settingsStore: _MemorySettings(),
        logger: logger,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.entryCount, 1);
      await expectLater(
        controller.deleteEntry('synthetic-entry'),
        throwsA(isA<ReadyFeedbackCleanupException>()),
      );
      expect(controller.entryCount, 0);
    },
  );

  test(
    'clear reports managed export purge failure after source data is removed',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-controller-purge-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-export-purge-test',
        settingsKey: 'feedback.enabled',
      );
      final repository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
      );
      await repository.addEntry(
        ReadyFeedbackEntry(
          id: 'managed-export-entry',
          createdAt: DateTime.utc(2026, 8, 2),
          route: 'Synthetic route',
          note: 'Synthetic note',
          kind: ReadyFeedbackKind.note,
        ),
      );
      final delivery = _FailingManagedDelivery();
      final logger = ReadyFeedbackLogger();
      addTearDown(logger.dispose);
      final controller = ReadyFeedbackController(
        config: config,
        repository: repository,
        settingsStore: _MemorySettings(),
        logger: logger,
        exporter: ReadyFeedbackExporter(
          config: config,
          repository: repository,
          delivery: delivery,
        ),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.entryCount, 1);
      await expectLater(
        controller.clearAll(),
        throwsA(
          isA<ReadyFeedbackCleanupException>()
              .having((error) => error.recordsRemoved, 'recordsRemoved', true)
              .having(
                (error) => error.message,
                'message',
                contains('temporary share ZIPs'),
              ),
        ),
      );

      expect(delivery.purgeCalls, 1);
      expect(controller.entryCount, 0);
    },
  );

  test(
    'partial clear failure cannot resurrect pending pre-clear logs',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-controller-pending-clear-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-pending-clear-test',
        settingsKey: 'feedback.enabled',
      );
      final cleanupCause = FileSystemException(
        'Synthetic partial cleanup failure.',
      );
      final repository = _PartialClearRepository(
        config: config,
        temporary: temporary,
        cleanupCause: cleanupCause,
      );
      await repository.addEntry(
        ReadyFeedbackEntry(
          id: 'pending-clear-entry',
          createdAt: DateTime.utc(2026, 8, 2),
          route: 'Synthetic route',
          note: 'Synthetic note',
          kind: ReadyFeedbackKind.note,
        ),
      );
      final root = await repository.rootDirectory;
      final logger = ReadyFeedbackLogger(
        retryDelays: const <Duration>[Duration(days: 1)],
      );
      addTearDown(logger.dispose);
      final controller = ReadyFeedbackController(
        config: config,
        repository: repository,
        settingsStore: _MemorySettings(),
        logger: logger,
        exporter: ReadyFeedbackExporter(
          config: config,
          repository: repository,
          delivery: _NoopDelivery(),
        ),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await File(
        '${root.path}${Platform.pathSeparator}synthetic-stuck-artifact',
      ).writeAsString('private synthetic artifact');
      logger.info('Synthetic pending log from before Clear all');
      while (repository.appendCalls == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(repository.appendCalls, 1);

      final expectation = expectLater(
        controller.clearAll(),
        throwsA(
          isA<ReadyFeedbackCleanupException>().having(
            (error) => identical(error.cause, cleanupCause),
            'original cleanup cause',
            isTrue,
          ),
        ),
      );
      await expectation;
      await Future<void>.delayed(Duration.zero);

      expect(controller.entryCount, 0);
      expect(logger.recent, isEmpty);
      expect(repository.appendCalls, 1);
    },
  );

  test(
    'approved export is rejected on drift and preserves reviewed counts',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-controller-approved-export-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-approved-export-test',
        settingsKey: 'feedback.enabled',
      );
      final repository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
      );
      await repository.addEntry(
        ReadyFeedbackEntry(
          id: 'reviewed-entry',
          createdAt: DateTime.utc(2026, 8, 2),
          route: 'Today',
          note: 'Reviewed private entry',
          kind: ReadyFeedbackKind.note,
        ),
      );
      final delivery = _RecordingDelivery();
      final logger = ReadyFeedbackLogger();
      addTearDown(logger.dispose);
      final controller = ReadyFeedbackController(
        config: config,
        repository: repository,
        settingsStore: _MemorySettings(),
        logger: logger,
        exporter: ReadyFeedbackExporter(
          config: config,
          repository: repository,
          delivery: delivery,
        ),
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      final stalePreview = await controller.exportPreview();
      expect(stalePreview.entryCount, 1);
      await repository.addEntry(
        ReadyFeedbackEntry(
          id: 'concurrent-entry',
          createdAt: DateTime.utc(2026, 8, 2, 0, 1),
          route: 'Today',
          note: 'Concurrent private entry',
          kind: ReadyFeedbackKind.note,
        ),
      );

      await expectLater(
        controller.export(preview: stalePreview),
        throwsA(isA<ReadyFeedbackExportChangedException>()),
      );
      expect(delivery.calls, 0);

      final currentPreview = await controller.exportPreview();
      expect(currentPreview.entryCount, 2);
      await controller.export(preview: currentPreview);
      expect(delivery.calls, 1);
      final archive = ZipDecoder().decodeBytes(delivery.bytes!);
      final manifest =
          jsonDecode(
                utf8.decode(
                  archive
                      .firstWhere((file) => file.name == 'manifest.json')
                      .readBytes()!,
                ),
              )
              as Map<String, Object?>;
      expect(manifest['entryCount'], currentPreview.entryCount);
    },
  );

  test(
    'partial recovery failure cannot resurrect pending pre-recovery logs',
    () async {
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-pending-recovery-test',
        settingsKey: 'feedback.enabled',
      );
      final repository = _PartialRecoveryRepository(config: config);
      final logger = ReadyFeedbackLogger(
        retryDelays: const <Duration>[Duration(days: 1)],
      );
      addTearDown(logger.dispose);
      final controller = ReadyFeedbackController(
        config: config,
        repository: repository,
        settingsStore: _MemorySettings(),
        logger: logger,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      logger.info('Synthetic pending log from before recovery');
      while (repository.appendCalls == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      await expectLater(
        controller.recoverCorruptStore(ownerConfirmed: true),
        throwsA(same(repository.recoveryFailure)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(logger.recent, isEmpty);
      expect(repository.appendCalls, 1);
    },
  );
}

class _MemorySettings implements ReadyFeedbackSettingsStore {
  bool? value;

  @override
  Future<bool?> readEnabled() async => value;

  @override
  Future<void> writeEnabled(bool value) async => this.value = value;
}

class _DelayedRepository extends ReadyFeedbackRepository {
  _DelayedRepository({
    required super.config,
    required Directory temporary,
    required this.entries,
  }) : super(rootDirectoryResolver: () async => temporary);

  final Completer<List<ReadyFeedbackEntry>> entries;

  @override
  Future<List<ReadyFeedbackEntry>> readEntries() => entries.future;
}

class _SpyLogger extends ReadyFeedbackLogger {
  int attachments = 0;

  @override
  void attachRepository(ReadyFeedbackRepository repository, {Object? owner}) {
    attachments++;
    super.attachRepository(repository, owner: owner);
  }
}

class _CommittedCleanupRepository extends ReadyFeedbackRepository {
  _CommittedCleanupRepository({required super.config});

  var _removed = false;

  @override
  Future<List<ReadyFeedbackEntry>> readEntries() async => _removed
      ? const <ReadyFeedbackEntry>[]
      : <ReadyFeedbackEntry>[
          ReadyFeedbackEntry(
            id: 'synthetic-entry',
            createdAt: DateTime.utc(2026, 8, 2),
            route: 'Synthetic route',
            note: 'Synthetic note',
            kind: ReadyFeedbackKind.note,
          ),
        ];

  @override
  Future<void> deleteEntry(String id) async {
    _removed = true;
    throw const ReadyFeedbackCleanupException(
      'Synthetic committed cleanup failure.',
    );
  }
}

class _FailingManagedDelivery
    implements ReadyFeedbackDelivery, ReadyFeedbackManagedExportPurger {
  int purgeCalls = 0;

  @override
  Future<ReadyFeedbackExportResult> deliver({
    required Uint8List bytes,
    required String fileName,
  }) async =>
      const ReadyFeedbackExportResult(status: ReadyFeedbackExportStatus.saved);

  @override
  Future<void> purgeManagedTemporaryExports() async {
    purgeCalls++;
    throw const FileSystemException('Synthetic managed export purge failure.');
  }
}

class _NoopDelivery implements ReadyFeedbackDelivery {
  @override
  Future<ReadyFeedbackExportResult> deliver({
    required Uint8List bytes,
    required String fileName,
  }) async =>
      const ReadyFeedbackExportResult(status: ReadyFeedbackExportStatus.saved);
}

class _RecordingDelivery implements ReadyFeedbackDelivery {
  int calls = 0;
  Uint8List? bytes;

  @override
  Future<ReadyFeedbackExportResult> deliver({
    required Uint8List bytes,
    required String fileName,
  }) async {
    calls++;
    this.bytes = bytes;
    return const ReadyFeedbackExportResult(
      status: ReadyFeedbackExportStatus.saved,
    );
  }
}

class _PartialClearRepository extends ReadyFeedbackRepository {
  _PartialClearRepository({
    required super.config,
    required Directory temporary,
    required Object cleanupCause,
  }) : super(
         rootDirectoryResolver: () async => temporary,
         entityDeleter: (entity, recursive) async {
           if (entity.path.endsWith('synthetic-stuck-artifact')) {
             throw cleanupCause;
           }
           await entity.delete(recursive: recursive);
         },
       );

  int appendCalls = 0;

  @override
  Future<void> appendLog(ReadyFeedbackLogRecord record) async {
    appendCalls++;
    throw const ReadyFeedbackStorageException(
      'Synthetic pending log persistence failure.',
    );
  }
}

class _PartialRecoveryRepository extends ReadyFeedbackRepository {
  _PartialRecoveryRepository({required super.config});

  final ReadyFeedbackStorageException recoveryFailure =
      const ReadyFeedbackStorageException(
        'Synthetic partial recovery rebuild failure.',
      );
  int appendCalls = 0;

  @override
  Future<List<ReadyFeedbackEntry>> readEntries() async =>
      const <ReadyFeedbackEntry>[];

  @override
  Future<void> appendLog(ReadyFeedbackLogRecord record) async {
    appendCalls++;
    throw const ReadyFeedbackStorageException(
      'Synthetic pending recovery log persistence failure.',
    );
  }

  @override
  Future<ReadyFeedbackRecoveryResult> recoverCorruptStore({
    required bool ownerConfirmed,
  }) async => throw recoveryFailure;
}
