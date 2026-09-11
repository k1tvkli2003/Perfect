import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  test('ZIP contains report, screenshot, logs, and redacts secrets', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'ready-feedback-export-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    const config = ReadyFeedbackConfig(
      applicationName: 'Perfect!',
      storageNamespace: 'feedback-test',
      settingsKey: 'feedback.enabled',
    );
    final repository = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
    );
    await repository.addEntry(
      ReadyFeedbackEntry(
        id: 'capture-1',
        createdAt: DateTime.utc(2026, 8, 2, 12),
        route: 'Today',
        note: 'token=not-a-real-assignment-token Improve the orbit spacing',
        kind: ReadyFeedbackKind.criticism,
      ),
      screenshotBytes: _png(),
    );
    await repository.appendLog(
      ReadyFeedbackLogRecord(
        createdAt: DateTime.utc(2026, 8, 2, 12, 1),
        level: ReadyFeedbackLogLevel.error,
        message: 'Authorization: Bearer not-a-real-bearer-log-token',
      ),
    );

    final bytes = await ReadyFeedbackExporter(
      config: config,
      repository: repository,
      delivery: _MemoryDelivery(),
      clock: () => DateTime.utc(2026, 8, 2, 12),
    ).buildArchive();
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(
      archive.map((file) => file.name),
      containsAll(<String>[
        'report.md',
        'screenshots/capture-1.png',
        'logs/recent.jsonl',
      ]),
    );

    final report = utf8.decode(
      archive.firstWhere((file) => file.name == 'report.md').readBytes()!,
    );
    final logs = utf8.decode(
      archive
          .firstWhere((file) => file.name == 'logs/recent.jsonl')
          .readBytes()!,
    );
    expect(report, contains('Improve the orbit spacing'));
    expect(report, contains('[REDACTED]'));
    expect(report, isNot(contains('not-a-real-assignment-token')));
    expect(logs, isNot(contains('not-a-real-bearer-log-token')));
  });

  test('redactor covers JSON, assignment, bearer, URI, and JWT patterns', () {
    const jwt = 'eyJnot-a-real-jwt-fixture.payload.signature';
    final redacted = ReadyFeedbackRedactor.redact(
      'password=not-a-real-password-123 '
      '"api_key":"not-a-real-json-key-fixture" '
      'Authorization: Bearer not-a-real-bearer-fixture '
      'https://example-user:not-a-real-url-password@example.invalid $jwt',
    );
    expect(redacted, isNot(contains('not-a-real-password-123')));
    expect(redacted, isNot(contains('not-a-real-json-key-fixture')));
    expect(redacted, isNot(contains('not-a-real-bearer-fixture')));
    expect(redacted, isNot(contains('not-a-real-url-password')));
    expect(redacted, isNot(contains(jwt)));
  });

  test(
    'Android export is staged in the managed cache and purge stays contained',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-managed-export-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-managed-export-test',
        settingsKey: 'feedback.enabled',
      );
      final repository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async =>
            Directory('${temporary.path}${Platform.pathSeparator}repository'),
      );
      final delivery = ReadyFeedbackPlatformDelivery(
        temporaryDirectoryResolver: () async => temporary,
        shareInvoker: (_) async =>
            const ShareResult('synthetic-share', ShareResultStatus.success),
        clock: () => DateTime.utc(2026, 8, 2, 12),
        isWindows: false,
      );
      final exporter = ReadyFeedbackExporter(
        config: config,
        repository: repository,
        delivery: delivery,
        clock: () => DateTime.utc(2026, 8, 2, 12),
      );
      final external = File(
        '${temporary.path}${Platform.pathSeparator}owner-saved-feedback.zip',
      );
      await external.writeAsBytes(const <int>[1, 2, 3]);

      final result = await exporter.export();
      final managedPath = result.path!;
      expect(result.status, ReadyFeedbackExportStatus.shared);
      expect(
        managedPath,
        contains(ReadyFeedbackPlatformDelivery.managedDirectoryName),
      );
      expect(
        managedPath.split(RegExp(r'[/\\]')).last,
        startsWith(ReadyFeedbackPlatformDelivery.managedFilePrefix),
      );
      expect(await File(managedPath).exists(), isTrue);

      await exporter.purgeManagedTemporaryExports();

      expect(await File(managedPath).exists(), isFalse);
      expect(await external.exists(), isTrue);
    },
  );

  test('managed export purge reports an invalid cache boundary', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'ready-feedback-managed-export-failure-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final invalidManagedDirectory = File(
      '${temporary.path}${Platform.pathSeparator}'
      '${ReadyFeedbackPlatformDelivery.managedDirectoryName}',
    );
    await invalidManagedDirectory.writeAsString('not a managed directory');
    final external = File(
      '${temporary.path}${Platform.pathSeparator}owner-saved-feedback.zip',
    );
    await external.writeAsBytes(const <int>[1, 2, 3]);
    final delivery = ReadyFeedbackPlatformDelivery(
      temporaryDirectoryResolver: () async => temporary,
      shareInvoker: (_) async =>
          const ShareResult('synthetic-share', ShareResultStatus.success),
      isWindows: false,
    );

    await expectLater(
      delivery.purgeManagedTemporaryExports(),
      throwsA(isA<ReadyFeedbackManagedExportBoundaryException>()),
    );

    expect(await invalidManagedDirectory.exists(), isTrue);
    expect(await external.exists(), isTrue);
  });

  test('managed export boundary rejects a linked temporary ancestor', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'ready-feedback-managed-export-linked-root-',
    );
    final realCache = Directory(
      '${temporary.path}${Platform.pathSeparator}real-cache',
    );
    final linkedCache = Link(
      '${temporary.path}${Platform.pathSeparator}linked-cache',
    );
    await realCache.create();
    final nestedCache = Directory(
      '${realCache.path}${Platform.pathSeparator}nested-cache',
    );
    await nestedCache.create();
    final sentinel = File(
      '${realCache.path}${Platform.pathSeparator}outside-sentinel.txt',
    );
    await sentinel.writeAsString('must survive');
    await _createDirectoryLink(linkedCache, realCache);
    addTearDown(() async {
      await _deleteDirectoryLinkIfPresent(linkedCache);
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final delivery = ReadyFeedbackPlatformDelivery(
      temporaryDirectoryResolver: () async =>
          Directory('${linkedCache.path}${Platform.pathSeparator}nested-cache'),
      shareInvoker: (_) async =>
          const ShareResult('synthetic-share', ShareResultStatus.success),
      isWindows: false,
    );

    await expectLater(
      delivery.purgeManagedTemporaryExports(),
      throwsA(
        isA<ReadyFeedbackManagedExportBoundaryException>().having(
          (error) => error.path,
          'path',
          startsWith(linkedCache.path),
        ),
      ),
    );

    expect(await sentinel.exists(), isTrue);
  });

  test('managed export boundary rejects a linked dedicated child', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'ready-feedback-managed-export-linked-child-',
    );
    final external = Directory(
      '${temporary.path}${Platform.pathSeparator}external-target',
    );
    final managedLink = Link(
      '${temporary.path}${Platform.pathSeparator}'
      '${ReadyFeedbackPlatformDelivery.managedDirectoryName}',
    );
    await external.create();
    final sentinel = File(
      '${external.path}${Platform.pathSeparator}outside-sentinel.txt',
    );
    await sentinel.writeAsString('must survive');
    await _createDirectoryLink(managedLink, external);
    addTearDown(() async {
      await _deleteDirectoryLinkIfPresent(managedLink);
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final delivery = ReadyFeedbackPlatformDelivery(
      temporaryDirectoryResolver: () async => temporary,
      shareInvoker: (_) async =>
          const ShareResult('synthetic-share', ShareResultStatus.success),
      isWindows: false,
    );

    await expectLater(
      delivery.purgeManagedTemporaryExports(),
      throwsA(
        isA<ReadyFeedbackManagedExportBoundaryException>().having(
          (error) => error.path,
          'path',
          managedLink.path,
        ),
      ),
    );

    expect(await sentinel.exists(), isTrue);
  });

  test(
    'purge removes every app-owned unknown entity without following links',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-managed-export-unknown-',
      );
      final managed = Directory(
        '${temporary.path}${Platform.pathSeparator}'
        '${ReadyFeedbackPlatformDelivery.managedDirectoryName}',
      );
      final external = Directory(
        '${temporary.path}${Platform.pathSeparator}external-target',
      );
      final linked = Link(
        '${managed.path}${Platform.pathSeparator}unexpected-link',
      );
      await managed.create();
      await external.create();
      final sentinel = File(
        '${external.path}${Platform.pathSeparator}outside-sentinel.txt',
      );
      await sentinel.writeAsString('must survive');
      await File(
        '${managed.path}${Platform.pathSeparator}interrupted.partial',
      ).writeAsString('partial private export');
      await File(
        '${managed.path}${Platform.pathSeparator}unknown.bin',
      ).writeAsBytes(const <int>[1, 2, 3]);
      final nested = Directory(
        '${managed.path}${Platform.pathSeparator}unexpected-subdirectory',
      );
      await nested.create();
      await File(
        '${nested.path}${Platform.pathSeparator}nested-private-data',
      ).writeAsString('private');
      await _createDirectoryLink(linked, external);
      addTearDown(() async {
        await _deleteDirectoryLinkIfPresent(linked);
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final delivery = ReadyFeedbackPlatformDelivery(
        temporaryDirectoryResolver: () async => temporary,
        shareInvoker: (_) async =>
            const ShareResult('synthetic-share', ShareResultStatus.success),
        isWindows: false,
      );

      await delivery.purgeManagedTemporaryExports();

      expect(await managed.exists(), isFalse);
      expect(await sentinel.exists(), isTrue);
    },
  );

  test('managed Android export retention is bounded', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'ready-feedback-managed-export-retention-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    const config = ReadyFeedbackConfig(
      applicationName: 'Perfect!',
      storageNamespace: 'feedback-managed-retention-test',
      settingsKey: 'feedback.enabled',
    );
    final repository = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async =>
          Directory('${temporary.path}${Platform.pathSeparator}repository'),
    );
    var tick = 0;
    DateTime clock() => DateTime.utc(2026, 8, 2, 12, 0, tick++);
    final exporter = ReadyFeedbackExporter(
      config: config,
      repository: repository,
      delivery: ReadyFeedbackPlatformDelivery(
        temporaryDirectoryResolver: () async => temporary,
        shareInvoker: (_) async =>
            const ShareResult('synthetic-share', ShareResultStatus.success),
        clock: clock,
        isWindows: false,
        maximumManagedExports: 2,
      ),
      clock: clock,
    );

    await exporter.export();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await exporter.export();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await exporter.export();

    final managedDirectory = Directory(
      '${temporary.path}${Platform.pathSeparator}'
      '${ReadyFeedbackPlatformDelivery.managedDirectoryName}',
    );
    final managedFiles = await managedDirectory
        .list(followLinks: false)
        .where(
          (entity) =>
              entity is File &&
              entity.path
                  .split(RegExp(r'[/\\]'))
                  .last
                  .startsWith(ReadyFeedbackPlatformDelivery.managedFilePrefix),
        )
        .toList();
    expect(managedFiles, hasLength(2));
  });

  test(
    'clear can purge a staged ZIP while the native share UI remains open',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-export-clear-lease-',
      );
      final store = Directory(
        '${temporary.path}${Platform.pathSeparator}store',
      );
      final cache = Directory(
        '${temporary.path}${Platform.pathSeparator}cache',
      );
      await cache.create();
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-export-clear-lease-test',
        settingsKey: 'feedback.enabled',
      );
      final exportingRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => store,
      );
      final clearingRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => store,
      );
      await exportingRepository.addEntry(
        ReadyFeedbackEntry(
          id: 'pre-clear-entry',
          createdAt: DateTime.utc(2026, 8, 2),
          route: 'Today',
          note: 'Snapshot must not reappear after clear.',
          kind: ReadyFeedbackKind.note,
        ),
      );
      final shareEntered = Completer<void>();
      final releaseShare = Completer<void>();
      final delivery = ReadyFeedbackPlatformDelivery(
        temporaryDirectoryResolver: () async => cache,
        shareInvoker: (_) async {
          shareEntered.complete();
          await releaseShare.future;
          return const ShareResult(
            'synthetic-share',
            ShareResultStatus.success,
          );
        },
        isWindows: false,
      );
      final exporter = ReadyFeedbackExporter(
        config: config,
        repository: exportingRepository,
        delivery: delivery,
        clock: () => DateTime.utc(2026, 8, 2, 12),
      );
      final logger = ReadyFeedbackLogger();
      addTearDown(logger.dispose);
      final clearingController = ReadyFeedbackController(
        config: config,
        repository: clearingRepository,
        settingsStore: _MemorySettings(),
        logger: logger,
        exporter: ReadyFeedbackExporter(
          config: config,
          repository: clearingRepository,
          delivery: delivery,
        ),
      );
      addTearDown(clearingController.dispose);
      await clearingController.initialize();

      final exportFuture = exporter.export();
      await shareEntered.future;
      var clearCompleted = false;
      final clearFuture = clearingController.clearAll().then((_) {
        clearCompleted = true;
      });
      await clearFuture.timeout(const Duration(seconds: 1));
      expect(clearCompleted, isTrue);

      releaseShare.complete();
      await exportFuture;

      expect(await clearingRepository.readEntries(), isEmpty);
      final managedDirectory = Directory(
        '${cache.path}${Platform.pathSeparator}'
        '${ReadyFeedbackPlatformDelivery.managedDirectoryName}',
      );
      expect(await managedDirectory.exists(), isFalse);
    },
  );

  test('a purged managed stage fails before invoking the share UI', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'ready-feedback-purged-stage-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    var shareCalls = 0;
    final delivery = ReadyFeedbackPlatformDelivery(
      temporaryDirectoryResolver: () async => temporary,
      shareInvoker: (_) async {
        shareCalls++;
        return const ShareResult('synthetic-share', ShareResultStatus.success);
      },
      isWindows: false,
    );
    final preparation = await delivery.prepare(fileName: 'feedback.zip');
    final prepared = await delivery.commit(
      preparation: preparation,
      bytes: Uint8List.fromList(const <int>[1, 2, 3]),
      fileName: 'feedback.zip',
    );
    await delivery.purgeManagedTemporaryExports();

    await expectLater(prepared.complete(), throwsA(isA<FileSystemException>()));
    expect(shareCalls, 0);
  });

  test(
    'Windows picker stays outside lease and clear invalidates reviewed bytes',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-windows-picker-race-',
      );
      final store = Directory(
        '${temporary.path}${Platform.pathSeparator}store',
      );
      final cache = Directory(
        '${temporary.path}${Platform.pathSeparator}cache',
      );
      await cache.create();
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-windows-picker-race-test',
        settingsKey: 'feedback.enabled',
      );
      final firstRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => store,
      );
      final clearingRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => store,
      );
      await firstRepository.addEntry(
        ReadyFeedbackEntry(
          id: 'reviewed-before-picker',
          createdAt: DateTime.utc(2026, 8, 2),
          route: 'Today',
          note: 'Must not save after Clear wins.',
          kind: ReadyFeedbackKind.note,
        ),
      );
      final approvedSnapshot = await firstRepository.createExportSnapshot();
      final pickerEntered = Completer<void>();
      final releasePicker = Completer<void>();
      var saveCalls = 0;
      final output = File(
        '${temporary.path}${Platform.pathSeparator}owner-selected.zip',
      );
      final exporter = ReadyFeedbackExporter(
        config: config,
        repository: firstRepository,
        delivery: ReadyFeedbackPlatformDelivery(
          temporaryDirectoryResolver: () async => cache,
          saveLocationResolver: (_) async {
            pickerEntered.complete();
            await releasePicker.future;
            return output.path;
          },
          fileSaver:
              ({
                required Uint8List bytes,
                required String fileName,
                required String path,
              }) async {
                saveCalls++;
                await File(path).writeAsBytes(bytes);
              },
          isWindows: true,
        ),
      );

      final exportFuture = exporter.exportApprovedSnapshot(approvedSnapshot);
      await pickerEntered.future;
      await clearingRepository.clearAll().timeout(const Duration(seconds: 1));
      releasePicker.complete();

      await expectLater(
        exportFuture,
        throwsA(isA<ReadyFeedbackExportChangedException>()),
      );
      expect(saveCalls, 0);
      expect(await output.exists(), isFalse);
    },
  );

  test(
    'a stalled transactional commit releases the store lease at deadline',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-commit-timeout-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-commit-timeout-test',
        settingsKey: 'feedback.enabled',
      );
      final firstRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
      );
      final competingRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
      );
      final delivery = _HangingTransactionalDelivery();
      addTearDown(delivery.release);
      final exporter = ReadyFeedbackExporter(
        config: config,
        repository: firstRepository,
        delivery: delivery,
        commitTimeout: const Duration(milliseconds: 25),
      );

      final exportOutcome = expectLater(
        exporter.export(),
        throwsA(isA<TimeoutException>()),
      );
      await delivery.commitEntered.future;
      final competingRead = competingRepository.readEntries();

      await exportOutcome;
      await expectLater(
        competingRead.timeout(const Duration(seconds: 1)),
        completes,
      );
    },
  );

  test(
    'stalled Windows staging makes Clear fail until managed cleanup settles',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'ready-feedback-windows-staging-timeout-',
      );
      final store = Directory(
        '${temporary.path}${Platform.pathSeparator}store',
      );
      final cache = Directory(
        '${temporary.path}${Platform.pathSeparator}cache',
      );
      final ownerDirectory = Directory(
        '${temporary.path}${Platform.pathSeparator}owner-selected',
      );
      await cache.create();
      await ownerDirectory.create();
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-windows-staging-timeout-test',
        settingsKey: 'feedback.enabled',
      );
      final exportingRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => store,
      );
      final clearingRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => store,
      );
      await exportingRepository.addEntry(
        ReadyFeedbackEntry(
          id: 'windows-staging-timeout-entry',
          createdAt: DateTime.utc(2026, 8, 2),
          route: 'Today',
          note: 'Private reviewed data',
          kind: ReadyFeedbackKind.note,
        ),
      );
      final output = File(
        '${ownerDirectory.path}${Platform.pathSeparator}feedback.zip',
      );
      await output.writeAsString('owner-original-content');
      final saverEntered = Completer<String>();
      final releaseSaver = Completer<void>();
      final saverReturned = Completer<void>();
      final delivery = ReadyFeedbackPlatformDelivery(
        temporaryDirectoryResolver: () async => cache,
        saveLocationResolver: (_) async => output.path,
        fileSaver:
            ({
              required Uint8List bytes,
              required String fileName,
              required String path,
            }) async {
              await File(path).writeAsBytes(bytes, flush: true);
              saverEntered.complete(path);
              await releaseSaver.future;
              saverReturned.complete();
            },
        isWindows: true,
      );
      final exporter = ReadyFeedbackExporter(
        config: config,
        repository: exportingRepository,
        delivery: delivery,
        commitTimeout: const Duration(milliseconds: 25),
      );
      final logger = ReadyFeedbackLogger();
      addTearDown(logger.dispose);
      final clearingController = ReadyFeedbackController(
        config: config,
        repository: clearingRepository,
        settingsStore: _MemorySettings(),
        logger: logger,
        exporter: ReadyFeedbackExporter(
          config: config,
          repository: clearingRepository,
          delivery: delivery,
        ),
      );
      addTearDown(clearingController.dispose);
      await clearingController.initialize();

      final exportOutcome = expectLater(
        exporter.export(),
        throwsA(isA<TimeoutException>()),
      );
      final stagingPath = await saverEntered.future;
      expect(
        stagingPath,
        contains(ReadyFeedbackPlatformDelivery.managedDirectoryName),
      );
      await exportOutcome;

      await expectLater(
        clearingController.clearAll(),
        throwsA(isA<ReadyFeedbackCleanupException>()),
      );
      expect(clearingController.entryCount, 0);
      expect(await File(stagingPath).exists(), isTrue);
      expect(await output.readAsString(), 'owner-original-content');

      releaseSaver.complete();
      await saverReturned.future;
      final managedDirectory = Directory(
        '${cache.path}${Platform.pathSeparator}'
        '${ReadyFeedbackPlatformDelivery.managedDirectoryName}',
      );
      await _waitFor(() async => !await managedDirectory.exists());

      await clearingController.clearAll();
      expect(await managedDirectory.exists(), isFalse);
      expect(await output.readAsString(), 'owner-original-content');
    },
  );
}

Uint8List _png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
  'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

class _MemoryDelivery implements ReadyFeedbackDelivery {
  @override
  Future<ReadyFeedbackExportResult> deliver({
    required Uint8List bytes,
    required String fileName,
  }) async =>
      const ReadyFeedbackExportResult(status: ReadyFeedbackExportStatus.saved);
}

class _MemorySettings implements ReadyFeedbackSettingsStore {
  @override
  Future<bool?> readEnabled() async => true;

  @override
  Future<void> writeEnabled(bool value) async {}
}

class _HangingTransactionalDelivery
    implements ReadyFeedbackDelivery, ReadyFeedbackTransactionalDelivery {
  final Completer<void> commitEntered = Completer<void>();
  final Completer<ReadyFeedbackPreparedDelivery> _commit =
      Completer<ReadyFeedbackPreparedDelivery>();

  @override
  Future<ReadyFeedbackDeliveryPreparation> prepare({
    required String fileName,
  }) async => ReadyFeedbackDeliveryPreparation();

  @override
  Future<ReadyFeedbackPreparedDelivery> commit({
    required ReadyFeedbackDeliveryPreparation preparation,
    required Uint8List bytes,
    required String fileName,
  }) {
    if (!commitEntered.isCompleted) commitEntered.complete();
    return _commit.future;
  }

  @override
  Future<ReadyFeedbackExportResult> deliver({
    required Uint8List bytes,
    required String fileName,
  }) => throw UnimplementedError();

  void release() {
    if (!_commit.isCompleted) {
      _commit.complete(
        _ReadyTestPreparedDelivery(
          const ReadyFeedbackExportResult(
            status: ReadyFeedbackExportStatus.saved,
          ),
        ),
      );
    }
  }
}

class _ReadyTestPreparedDelivery implements ReadyFeedbackPreparedDelivery {
  const _ReadyTestPreparedDelivery(this.result);

  final ReadyFeedbackExportResult result;

  @override
  Future<ReadyFeedbackExportResult> complete() async => result;
}

Future<void> _createDirectoryLink(Link link, Directory target) async {
  if (Platform.isWindows) {
    final result = await Process.run('cmd', <String>[
      '/c',
      'mklink',
      '/J',
      link.path,
      target.path,
    ]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Could not create a test junction: ${result.stderr}',
        link.path,
      );
    }
    return;
  }
  await link.create(target.path);
}

Future<void> _deleteDirectoryLinkIfPresent(Link link) async {
  final type = await FileSystemEntity.type(link.path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  if (Platform.isWindows) {
    await Directory(link.path).delete();
  } else {
    await link.delete();
  }
}

Future<void> _waitFor(Future<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for managed Windows export cleanup.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
