import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';

void main() {
  late Directory temporary;
  late ReadyFeedbackConfig config;
  late ReadyFeedbackRepository repository;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('ready-feedback-test-');
    config = const ReadyFeedbackConfig(
      applicationName: 'Test App',
      storageNamespace: 'feedback-test',
      settingsKey: 'feedback.enabled',
      maxEntries: 2,
      maxLogs: 2,
    );
    repository = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
    );
  });

  tearDown(() async {
    if (await temporary.exists()) await temporary.delete(recursive: true);
  });

  test('persists entries and screenshots while enforcing retention', () async {
    for (var index = 0; index < 3; index++) {
      await repository.addEntry(
        ReadyFeedbackEntry(
          id: 'entry-$index',
          createdAt: DateTime.utc(2026, 8, 2, 12, index),
          route: 'Today',
          note: 'Note $index',
          kind: ReadyFeedbackKind.note,
        ),
        screenshotBytes: _png(),
      );
    }

    final entries = await repository.readEntries();
    expect(entries.map((entry) => entry.id), <String>['entry-2', 'entry-1']);
    expect(await repository.readScreenshot(entries.first), isNotNull);

    final root = await repository.rootDirectory;
    expect(
      File(
        '${root.path}${Platform.pathSeparator}shots'
        '${Platform.pathSeparator}entry-0.png',
      ),
      isNot(exists),
    );
  });

  test(
    'two repositories serialize clear and mutation through the store lock',
    () async {
      await repository.addEntry(
        ReadyFeedbackEntry(
          id: 'before-clear',
          createdAt: DateTime.utc(2026, 8, 2, 11),
          route: 'Synthetic route',
          note: 'Must not survive clear',
          kind: ReadyFeedbackKind.note,
        ),
      );

      final deletionStarted = Completer<void>();
      final allowDeletion = Completer<void>();
      final secondResolvedRoot = Completer<void>();
      var heldOneDeletion = false;
      final clearing = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
        entityDeleter: (entity, recursive) async {
          if (!heldOneDeletion) {
            heldOneDeletion = true;
            deletionStarted.complete();
            await allowDeletion.future;
          }
          await entity.delete(recursive: recursive);
        },
      );
      final mutating = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async {
          if (!secondResolvedRoot.isCompleted) secondResolvedRoot.complete();
          return temporary;
        },
      );

      final clearFuture = clearing.clearAll();
      await deletionStarted.future;
      var mutationCompleted = false;
      final mutationFuture = mutating
          .addEntry(
            ReadyFeedbackEntry(
              id: 'after-clear',
              createdAt: DateTime.utc(2026, 8, 2, 11, 1),
              route: 'Synthetic route',
              note: 'Must be committed after clear',
              kind: ReadyFeedbackKind.note,
            ),
          )
          .whenComplete(() => mutationCompleted = true);
      await secondResolvedRoot.future;
      await Future<void>.delayed(Duration.zero);
      expect(mutationCompleted, isFalse);

      allowDeletion.complete();
      await clearFuture;
      await mutationFuture;

      expect((await mutating.readEntries()).map((entry) => entry.id), <String>[
        'after-clear',
      ]);
    },
  );

  test('store lease holds exclusion across an outer async operation', () async {
    await repository.addEntry(
      ReadyFeedbackEntry(
        id: 'leased-export',
        createdAt: DateTime.utc(2026, 8, 2, 11, 15),
        route: 'Synthetic route',
        note: 'Synthetic leased payload',
        kind: ReadyFeedbackKind.note,
      ),
    );
    final outerOperationStarted = Completer<void>();
    final releaseOuterOperation = Completer<void>();
    final competingRootResolved = Completer<void>();
    late ReadyFeedbackStoreLease expiredLease;
    final leasedOperation = repository.withStoreLease((lease) async {
      expiredLease = lease;
      final snapshot = await lease.createExportSnapshot();
      expect(snapshot.entries.single.id, 'leased-export');
      outerOperationStarted.complete();
      await releaseOuterOperation.future;
    });
    await outerOperationStarted.future;

    final competing = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async {
        competingRootResolved.complete();
        return temporary;
      },
    );
    var clearCompleted = false;
    final clearFuture = competing.clearAll().whenComplete(
      () => clearCompleted = true,
    );
    await competingRootResolved.future;
    await Future<void>.delayed(Duration.zero);
    expect(clearCompleted, isFalse);

    releaseOuterOperation.complete();
    await leasedOperation;
    await clearFuture;
    expect(expiredLease.createExportSnapshot, throwsA(isA<StateError>()));
  });

  test(
    'unawaited lease methods drain under the lock and remain serialized',
    () async {
      await repository.addEntry(
        ReadyFeedbackEntry(
          id: 'lease-drain',
          createdAt: DateTime.utc(2026, 8, 2, 11, 20),
          route: 'Synthetic route',
          note: 'Must be cleared before the queued snapshot',
          kind: ReadyFeedbackKind.note,
        ),
      );
      final deletionStarted = Completer<void>();
      final allowDeletion = Completer<void>();
      var heldOneDeletion = false;
      final leasing = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
        entityDeleter: (entity, recursive) async {
          if (!heldOneDeletion) {
            heldOneDeletion = true;
            deletionStarted.complete();
            await allowDeletion.future;
          }
          await entity.delete(recursive: recursive);
        },
      );
      late Future<void> escapedClear;
      late Future<ReadyFeedbackRepositorySnapshot> queuedSnapshot;
      final leasedOperation = leasing.withStoreLease((lease) async {
        escapedClear = lease.clearAll();
        queuedSnapshot = lease.createExportSnapshot();
        // Deliberately return without awaiting either issued lease operation.
      });
      await deletionStarted.future;

      final competing = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
      );
      var mutationCompleted = false;
      final mutation = competing
          .addEntry(
            ReadyFeedbackEntry(
              id: 'after-drained-lease',
              createdAt: DateTime.utc(2026, 8, 2, 11, 21),
              route: 'Synthetic route',
              note: 'Must wait for every issued lease operation',
              kind: ReadyFeedbackKind.note,
            ),
          )
          .whenComplete(() => mutationCompleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(mutationCompleted, isFalse);

      allowDeletion.complete();
      await leasedOperation;
      await escapedClear;
      expect((await queuedSnapshot).entries, isEmpty);
      await mutation;
      expect((await competing.readEntries()).single.id, 'after-drained-lease');
    },
  );

  test(
    'public repository re-entry inside a lease fails without deadlock',
    () async {
      await repository.withStoreLease((lease) async {
        await expectLater(repository.readEntries(), throwsA(isA<StateError>()));
        expect((await lease.createExportSnapshot()).entries, isEmpty);
      });
      expect(await repository.readEntries(), isEmpty);
    },
  );

  test('same-isolate queue wait is bounded and heals after timeout', () async {
    final leaseStarted = Completer<void>();
    final releaseLease = Completer<void>();
    final held = repository.withStoreLease((lease) async {
      leaseStarted.complete();
      await releaseLease.future;
    });
    await leaseStarted.future;

    final impatient = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
      storeLockTimeout: const Duration(milliseconds: 60),
      storeLockRetryDelay: const Duration(milliseconds: 5),
    );
    await expectLater(
      impatient.readEntries(),
      throwsA(isA<ReadyFeedbackLockTimeoutException>()),
    );

    releaseLease.complete();
    await held;
    expect(await impatient.readEntries(), isEmpty);
  });

  test('a linked storage base is rejected before namespace access', () async {
    final realBase = await Directory.systemTemp.createTemp(
      'ready-feedback-real-base-',
    );
    final linkedBase = Link(
      '${temporary.path}${Platform.pathSeparator}linked-base',
    );
    if (!await _createDirectoryLinkOrSkip(linkedBase, realBase)) {
      await realBase.delete(recursive: true);
      return;
    }
    try {
      final linkedRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => Directory(linkedBase.path),
      );
      await expectLater(
        linkedRepository.readEntries(),
        throwsA(isA<ReadyFeedbackStorageException>()),
      );
      expect(
        await Directory(
          '${realBase.path}${Platform.pathSeparator}${config.storageNamespace}',
        ).exists(),
        isFalse,
      );
    } finally {
      await _deleteDirectoryLinkIfPresent(linkedBase.path);
      await realBase.delete(recursive: true);
    }
  });

  test('a linked storage ancestor is rejected before base creation', () async {
    final realParent = await Directory.systemTemp.createTemp(
      'ready-feedback-real-parent-',
    );
    final linkedParent = Link(
      '${temporary.path}${Platform.pathSeparator}linked-parent',
    );
    if (!await _createDirectoryLinkOrSkip(linkedParent, realParent)) {
      await realParent.delete(recursive: true);
      return;
    }
    final nestedBase = Directory(
      '${linkedParent.path}${Platform.pathSeparator}nested-base',
    );
    try {
      final linkedRepository = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => nestedBase,
      );
      await expectLater(
        linkedRepository.readEntries(),
        throwsA(isA<ReadyFeedbackStorageException>()),
      );
      expect(
        await Directory(
          '${realParent.path}${Platform.pathSeparator}nested-base',
        ).exists(),
        isFalse,
      );
    } finally {
      await _deleteDirectoryLinkIfPresent(linkedParent.path);
      await realParent.delete(recursive: true);
    }
  });

  test('Windows external-process lock contention times out safely', () async {
    if (!Platform.isWindows) {
      markTestSkipped('Windows byte-range lock semantics only.');
      return;
    }
    final root = await repository.rootDirectory;
    final lock = File(
      '${root.path}${Platform.pathSeparator}.feedback-store.lock',
    );
    final helper = File(
      '${temporary.path}${Platform.pathSeparator}hold_feedback_lock.dart',
    );
    await helper.writeAsString(r'''
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final handle = await File(arguments.single).open(mode: FileMode.append);
  await handle.lock(FileLock.exclusive);
  stdout.writeln('LOCKED');
  await stdin.first;
  await handle.unlock();
  await handle.close();
}
''');
    Process? holder;
    try {
      holder = await Process.start('dart', <String>[
        helper.path,
        lock.path,
      ], runInShell: true);
      final ready = await holder.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 10));
      expect(ready, 'LOCKED');

      final competing = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
        storeLockTimeout: const Duration(milliseconds: 150),
        storeLockRetryDelay: const Duration(milliseconds: 10),
      );
      await expectLater(
        competing.readEntries(),
        throwsA(isA<ReadyFeedbackLockTimeoutException>()),
      );
      holder.stdin.writeln('release');
      await holder.stdin.close();
      await holder.exitCode.timeout(const Duration(seconds: 10));
      holder = null;
      expect(await competing.readEntries(), isEmpty);
    } finally {
      holder?.stdin.writeln('release');
      await holder?.stdin.close();
      if (holder != null) {
        try {
          await holder.exitCode.timeout(const Duration(seconds: 10));
        } on TimeoutException {
          holder.kill();
        }
      }
    }
  });

  test('feedback root links are rejected before store access', () async {
    final root = await repository.rootDirectory;
    final outside = await Directory.systemTemp.createTemp(
      'ready-feedback-outside-',
    );
    final sentinel = File(
      '${outside.path}${Platform.pathSeparator}outside-private.txt',
    );
    await sentinel.writeAsString('must remain untouched');
    await root.delete(recursive: true);
    final rootLink = Link(root.path);
    if (!await _createDirectoryLinkOrSkip(rootLink, outside)) {
      await outside.delete(recursive: true);
      return;
    }
    try {
      await expectLater(
        repository.readEntries(),
        throwsA(isA<ReadyFeedbackStorageException>()),
      );
      await expectLater(
        repository.clearAll(),
        throwsA(isA<ReadyFeedbackStorageException>()),
      );
      expect(await sentinel.readAsString(), 'must remain untouched');
    } finally {
      await _deleteDirectoryLinkIfPresent(rootLink.path);
      await outside.delete(recursive: true);
    }
  });

  test('critical index links are rejected and clear unlinks them', () async {
    final root = await repository.rootDirectory;
    final outside = await Directory.systemTemp.createTemp(
      'ready-feedback-outside-',
    );
    final outsideIndex = File(
      '${outside.path}${Platform.pathSeparator}outside-index.json',
    );
    await outsideIndex.writeAsString('[{"private":"outside"}]');
    final entries = File('${root.path}${Platform.pathSeparator}entries.json');
    await entries.delete();
    final indexLink = Link(entries.path);
    if (!await _createFileLinkOrSkip(indexLink, outsideIndex)) {
      await outside.delete(recursive: true);
      return;
    }
    try {
      final reopened = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
      );
      await expectLater(
        reopened.readEntries(),
        throwsA(isA<ReadyFeedbackStorageException>()),
      );
      await reopened.clearAll();
      expect(await outsideIndex.readAsString(), '[{"private":"outside"}]');
      expect(
        await FileSystemEntity.type(entries.path, followLinks: false),
        FileSystemEntityType.file,
      );
    } finally {
      await outside.delete(recursive: true);
    }
  });

  test(
    'critical screenshot directory links are rejected and safely cleared',
    () async {
      final root = await repository.rootDirectory;
      final outside = await Directory.systemTemp.createTemp(
        'ready-feedback-outside-',
      );
      final sentinel = File(
        '${outside.path}${Platform.pathSeparator}outside-shot.png',
      );
      await sentinel.writeAsBytes(_png());
      final shots = Directory('${root.path}${Platform.pathSeparator}shots');
      await shots.delete();
      final shotsLink = Link(shots.path);
      if (!await _createDirectoryLinkOrSkip(shotsLink, outside)) {
        await outside.delete(recursive: true);
        return;
      }
      try {
        final reopened = ReadyFeedbackRepository(
          config: config,
          rootDirectoryResolver: () async => temporary,
        );
        await expectLater(
          reopened.readEntries(),
          throwsA(isA<ReadyFeedbackStorageException>()),
        );
        await reopened.clearAll();
        expect(await sentinel.readAsBytes(), orderedEquals(_png()));
        expect(
          await _typeWithoutFollowingLinks(shots.path),
          FileSystemEntityType.directory,
        );
      } finally {
        await outside.delete(recursive: true);
      }
    },
  );

  test(
    'clear removes nested links non-recursively within the namespace',
    () async {
      final root = await repository.rootDirectory;
      final outside = await Directory.systemTemp.createTemp(
        'ready-feedback-outside-',
      );
      final sentinel = File(
        '${outside.path}${Platform.pathSeparator}outside-private.txt',
      );
      await sentinel.writeAsString('must remain untouched');
      final privateDirectory = Directory(
        '${root.path}${Platform.pathSeparator}private-leftover',
      );
      await privateDirectory.create();
      final nestedLink = Link(
        '${privateDirectory.path}${Platform.pathSeparator}outside-link',
      );
      if (!await _createDirectoryLinkOrSkip(nestedLink, outside)) {
        await outside.delete(recursive: true);
        return;
      }
      final deleted =
          <({String path, bool recursive, FileSystemEntityType type})>[];
      final clearing = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
        entityDeleter: (entity, recursive) async {
          deleted.add((
            path: entity.path,
            recursive: recursive,
            type: await _typeWithoutFollowingLinks(entity.path),
          ));
          await entity.delete(recursive: recursive);
        },
      );
      try {
        await clearing.clearAll();
        expect(await sentinel.readAsString(), 'must remain untouched');
        expect(
          deleted.where((item) => item.type == FileSystemEntityType.link),
          isNotEmpty,
        );
        expect(
          deleted
              .where((item) => item.type == FileSystemEntityType.link)
              .every((item) => !item.recursive),
          isTrue,
        );
        final rootPrefix = '${root.absolute.path}${Platform.pathSeparator}'
            .toLowerCase();
        expect(
          deleted.every(
            (item) => item.path.toLowerCase().startsWith(rootPrefix),
          ),
          isTrue,
        );
      } finally {
        await outside.delete(recursive: true);
      }
    },
  );

  test('clear reports records retained by partial reconstruction', () async {
    final stored = await repository.addEntry(
      ReadyFeedbackEntry(
        id: 'partial-clear',
        createdAt: DateTime.utc(2026, 8, 2, 11, 30),
        route: 'Synthetic route',
        note: 'Synthetic partial clear payload',
        kind: ReadyFeedbackKind.error,
      ),
      screenshotBytes: _png(),
    );
    var failScreenshotDelete = true;
    final clearing = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
      entityDeleter: (entity, recursive) async {
        if (failScreenshotDelete &&
            entity.path.endsWith(stored.screenshotFileName!)) {
          failScreenshotDelete = false;
          throw FileSystemException(
            'Synthetic screenshot cleanup failure',
            entity.path,
          );
        }
        await entity.delete(recursive: recursive);
      },
    );

    await expectLater(
      clearing.clearAll(),
      throwsA(
        isA<ReadyFeedbackCleanupException>().having(
          (error) => error.recordsRemoved,
          'recordsRemoved',
          isFalse,
        ),
      ),
    );
    await clearing.clearAll();
  });

  test('successful clear leaves only the lock and fresh empty store', () async {
    final root = await repository.rootDirectory;
    await File(
      '${root.path}${Platform.pathSeparator}private-leftover.tmp',
    ).writeAsString('private');
    await repository.clearAll();

    final inventory = await root
        .list(followLinks: false)
        .map((entity) => entity.path.split(Platform.pathSeparator).last)
        .toSet();
    expect(inventory, <String>{
      '.feedback-store.lock',
      'entries.json',
      'logs.json',
      'shots',
    });
    expect(
      await Directory(
        '${root.path}${Platform.pathSeparator}shots',
      ).list(followLinks: false).isEmpty,
      isTrue,
    );
    expect(
      jsonDecode(
        await File(
          '${root.path}${Platform.pathSeparator}entries.json',
        ).readAsString(),
      ),
      isEmpty,
    );
    expect(
      jsonDecode(
        await File(
          '${root.path}${Platform.pathSeparator}logs.json',
        ).readAsString(),
      ),
      isEmpty,
    );
  });

  test(
    'corrupt index generations preserve screenshots and surface recovery',
    () async {
      final root = await repository.rootDirectory;
      final entriesFile = File(
        '${root.path}${Platform.pathSeparator}entries.json',
      );
      await entriesFile.writeAsString('{broken');
      await File('${entriesFile.path}.bak').writeAsString('[also broken');
      await File('${entriesFile.path}.tmp').writeAsString('not json');
      final shot = File(
        '${root.path}${Platform.pathSeparator}shots'
        '${Platform.pathSeparator}orphan.png',
      );
      await shot.writeAsBytes(<int>[1, 2, 3]);

      final reopened = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
        recoveryClock: () => DateTime.utc(2026, 8, 2, 15),
      );
      await expectLater(
        reopened.readEntries(),
        throwsA(isA<ReadyFeedbackIndexRecoveryException>()),
      );
      await expectLater(
        reopened.addEntry(
          ReadyFeedbackEntry(
            id: 'blocked-before-recovery',
            createdAt: DateTime.utc(2026, 8, 2, 15),
            route: 'Synthetic blocked route',
            note: 'Synthetic blocked mutation',
            kind: ReadyFeedbackKind.note,
          ),
        ),
        throwsA(isA<ReadyFeedbackIndexRecoveryException>()),
      );
      expect(await shot.exists(), isTrue);

      await expectLater(
        reopened.recoverCorruptStore(ownerConfirmed: false),
        throwsA(isA<ArgumentError>()),
      );
      final recovery = await reopened.recoverCorruptStore(ownerConfirmed: true);
      final raw = Directory(
        '${recovery.directory.path}${Platform.pathSeparator}raw',
      );
      expect(File('${raw.path}${Platform.pathSeparator}entries.json'), exists);
      expect(
        File('${raw.path}${Platform.pathSeparator}entries.json.bak'),
        exists,
      );
      expect(
        File('${raw.path}${Platform.pathSeparator}entries.json.tmp'),
        exists,
      );
      expect(File('${raw.path}${Platform.pathSeparator}logs.json'), exists);
      expect(
        File(
          '${raw.path}${Platform.pathSeparator}shots'
          '${Platform.pathSeparator}orphan.png',
        ),
        exists,
      );
      expect(recovery.screenshotCount, 1);
      expect(await shot.exists(), isFalse);
      expect(await reopened.readEntries(), isEmpty);
      await reopened.addEntry(
        ReadyFeedbackEntry(
          id: 'after-recovery',
          createdAt: DateTime.utc(2026, 8, 2, 15, 1),
          route: 'Synthetic recovered route',
          note: 'Synthetic recovered note',
          kind: ReadyFeedbackKind.note,
        ),
      );
      expect(await reopened.readEntries(), hasLength(1));

      await reopened.clearAll();
      expect(await recovery.directory.exists(), isFalse);
      expect(await reopened.readEntries(), isEmpty);
      expect(await reopened.readLogs(), isEmpty);
      final clearedRoot = await reopened.rootDirectory;
      for (final staleName in const <String>[
        'entries.json.bak',
        'entries.json.tmp',
        'logs.json.bak',
        'logs.json.tmp',
      ]) {
        expect(
          File('${clearedRoot.path}${Platform.pathSeparator}$staleName'),
          isNot(exists),
        );
      }
    },
  );

  test(
    'clear surfaces recovery-copy deletion failure and succeeds on retry',
    () async {
      final root = await repository.rootDirectory;
      final entriesFile = File(
        '${root.path}${Platform.pathSeparator}entries.json',
      );
      await entriesFile.writeAsString('{broken');
      await File('${entriesFile.path}.bak').writeAsString('[also broken');
      final shot = File(
        '${root.path}${Platform.pathSeparator}shots'
        '${Platform.pathSeparator}private-recovery.png',
      );
      await shot.writeAsBytes(_png());
      final recovery = await repository.recoverCorruptStore(
        ownerConfirmed: true,
      );

      var failRecoveryDelete = true;
      final clearing = ReadyFeedbackRepository(
        config: config,
        rootDirectoryResolver: () async => temporary,
        entityDeleter: (entity, recursive) async {
          if (failRecoveryDelete &&
              entity.path.endsWith('${Platform.pathSeparator}recovery')) {
            failRecoveryDelete = false;
            throw FileSystemException(
              'Synthetic recovery cleanup failure',
              entity.path,
            );
          }
          await entity.delete(recursive: recursive);
        },
      );

      await expectLater(
        clearing.clearAll(),
        throwsA(
          isA<ReadyFeedbackCleanupException>().having(
            (error) => error.recordsRemoved,
            'recordsRemoved',
            isTrue,
          ),
        ),
      );
      expect(await recovery.directory.exists(), isTrue);
      expect(await clearing.readEntries(), isEmpty);

      await clearing.clearAll();
      expect(await recovery.directory.exists(), isFalse);
      expect(await clearing.readEntries(), isEmpty);
      expect(await clearing.readLogs(), isEmpty);
    },
  );

  test('first root creates authoritative empty indexes', () async {
    final root = await repository.rootDirectory;
    expect(File('${root.path}${Platform.pathSeparator}entries.json'), exists);
    expect(File('${root.path}${Platform.pathSeparator}logs.json'), exists);
    await expectLater(
      repository.recoverCorruptStore(ownerConfirmed: true),
      throwsA(isA<StateError>()),
    );
  });

  test('log-only index corruption can also be quarantined', () async {
    final root = await repository.rootDirectory;
    final logsFile = File('${root.path}${Platform.pathSeparator}logs.json');
    await logsFile.writeAsString('{broken');
    await File('${logsFile.path}.bak').writeAsString('[also broken');
    await File('${logsFile.path}.tmp').writeAsString('not json');

    await expectLater(
      repository.readLogs(),
      throwsA(isA<ReadyFeedbackIndexRecoveryException>()),
    );
    final recovery = await repository.recoverCorruptStore(ownerConfirmed: true);
    final raw = Directory(
      '${recovery.directory.path}${Platform.pathSeparator}raw',
    );
    expect(File('${raw.path}${Platform.pathSeparator}logs.json'), exists);
    expect(File('${raw.path}${Platform.pathSeparator}logs.json.bak'), exists);
    expect(await repository.readEntries(), isEmpty);
    expect(await repository.readLogs(), isEmpty);
  });

  test('authoritative empty index sweeps a crash orphan', () async {
    final root = await repository.rootDirectory;
    final shot = File(
      '${root.path}${Platform.pathSeparator}shots'
      '${Platform.pathSeparator}crash-orphan.png',
    );
    await shot.writeAsBytes(_png());

    final reopened = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
    );
    expect(await reopened.readEntries(), isEmpty);
    expect(await shot.exists(), isFalse);
  });

  test('missing index with existing screenshot requires recovery', () async {
    final stored = await repository.addEntry(
      ReadyFeedbackEntry(
        id: 'missing-index',
        createdAt: DateTime.utc(2026, 8, 2, 12, 30),
        route: 'Synthetic route',
        note: 'Synthetic missing index',
        kind: ReadyFeedbackKind.error,
      ),
      screenshotBytes: _png(),
    );
    final root = await repository.rootDirectory;
    for (final suffix in const <String>['', '.bak', '.tmp']) {
      final file = File(
        '${root.path}${Platform.pathSeparator}entries.json$suffix',
      );
      if (await file.exists()) await file.delete();
    }
    final screenshot = File(
      '${root.path}${Platform.pathSeparator}shots'
      '${Platform.pathSeparator}${stored.screenshotFileName}',
    );

    final reopened = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
    );
    await expectLater(
      reopened.readEntries(),
      throwsA(isA<ReadyFeedbackIndexRecoveryException>()),
    );
    expect(await screenshot.exists(), isTrue);
  });

  test('a failed index write removes the newly written screenshot', () async {
    final root = await repository.rootDirectory;
    expect(await repository.readEntries(), isEmpty);
    final entriesPath = '${root.path}${Platform.pathSeparator}entries.json';
    await File(entriesPath).delete();
    await Directory(entriesPath).create();

    await expectLater(
      repository.addEntry(
        ReadyFeedbackEntry(
          id: 'write-failure',
          createdAt: DateTime.utc(2026, 8, 2, 13),
          route: 'Today',
          note: 'Clearly synthetic failure fixture',
          kind: ReadyFeedbackKind.error,
        ),
        screenshotBytes: _png(),
      ),
      throwsA(isA<ReadyFeedbackStorageException>()),
    );

    final screenshot = File(
      '${root.path}${Platform.pathSeparator}shots'
      '${Platform.pathSeparator}write-failure.png',
    );
    expect(await screenshot.exists(), isFalse);
  });

  test('a failed root lookup is not cached and can be retried', () async {
    var resolutions = 0;
    final retrying = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async {
        resolutions++;
        if (resolutions == 1) {
          throw FileSystemException(
            'Synthetic root failure',
            'X:/not-a-real-path',
          );
        }
        return temporary;
      },
    );

    await expectLater(
      retrying.readEntries(),
      throwsA(isA<ReadyFeedbackStorageException>()),
    );
    expect(await retrying.readEntries(), isEmpty);
    expect(resolutions, 2);
  });

  test('persistent logs are bounded newest first', () async {
    for (var index = 0; index < 3; index++) {
      await repository.appendLog(
        ReadyFeedbackLogRecord(
          createdAt: DateTime.utc(2026, 8, 2, 12, index),
          level: ReadyFeedbackLogLevel.info,
          message: 'log-$index',
        ),
      );
    }
    expect((await repository.readLogs()).map((log) => log.message), <String>[
      'log-2',
      'log-1',
    ]);
  });

  test('delete cleanup failure is surfaced and startup retries it', () async {
    var injectedFailure = false;
    final failingDelete = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
      entityDeleter: (entity, recursive) async {
        if (!injectedFailure && entity.path.endsWith('delete-retry.png')) {
          injectedFailure = true;
          throw FileSystemException('Synthetic delete failure', entity.path);
        }
        await entity.delete(recursive: recursive);
      },
    );
    final stored = await failingDelete.addEntry(
      ReadyFeedbackEntry(
        id: 'delete-retry',
        createdAt: DateTime.utc(2026, 8, 2, 13, 30),
        route: 'Synthetic route',
        note: 'Synthetic cleanup retry',
        kind: ReadyFeedbackKind.error,
      ),
      screenshotBytes: _png(),
    );
    final screenshot = File(
      '${(await failingDelete.rootDirectory).path}${Platform.pathSeparator}'
      'shots${Platform.pathSeparator}${stored.screenshotFileName}',
    );

    await expectLater(
      failingDelete.deleteEntry(stored.id),
      throwsA(isA<ReadyFeedbackCleanupException>()),
    );
    expect(await screenshot.exists(), isTrue);

    final reopened = ReadyFeedbackRepository(
      config: config,
      rootDirectoryResolver: () async => temporary,
    );
    expect(await reopened.readEntries(), isEmpty);
    expect(await screenshot.exists(), isFalse);
  });

  test(
    'rejects header-only, truncated, and malformed PNG structures',
    () async {
      Future<void> expectRejected(String id, Uint8List bytes) => expectLater(
        repository.addEntry(
          ReadyFeedbackEntry(
            id: id,
            createdAt: DateTime.utc(2026, 8, 2, 14),
            route: 'Synthetic route',
            note: 'Synthetic malformed image',
            kind: ReadyFeedbackKind.error,
          ),
          screenshotBytes: bytes,
        ),
        throwsA(isA<FormatException>()),
      );

      final valid = _png();
      await expectRejected('header-only', Uint8List.sublistView(valid, 0, 24));
      await expectRejected(
        'truncated-end',
        Uint8List.sublistView(valid, 0, valid.length - 1),
      );
      final noImageData = Uint8List(45)
        ..setRange(0, 33, valid)
        ..setRange(33, 45, valid, valid.length - 12);
      await expectRejected('missing-image-data', noImageData);
      final malformedHeader = Uint8List.fromList(valid);
      malformedHeader[24] = 7;
      _repairChunkCrc(malformedHeader, 8);
      await expectRejected('bad-header-encoding', malformedHeader);
      final corruptCrc = Uint8List.fromList(valid);
      corruptCrc[32] ^= 0xff;
      await expectRejected('bad-checksum', corruptCrc);
    },
  );
}

Matcher get exists =>
    predicate<File>((file) => file.existsSync(), 'file exists');

Future<bool> _createDirectoryLinkOrSkip(Link link, Directory target) async {
  try {
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
          'Could not create a Windows junction: ${result.stderr}',
          link.path,
        );
      }
    } else {
      await link.create(target.path);
    }
    return true;
  } on FileSystemException catch (error) {
    markTestSkipped(
      'Directory links are unavailable on this platform: ${error.message}',
    );
    return false;
  }
}

Future<void> _deleteDirectoryLinkIfPresent(String path) async {
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  if (Platform.isWindows) {
    await Directory(path).delete();
  } else {
    await Link(path).delete();
  }
}

Future<bool> _createFileLinkOrSkip(Link link, File target) async {
  try {
    await link.create(target.path);
    return true;
  } on FileSystemException catch (error) {
    markTestSkipped(
      'File links are unavailable on this platform: ${error.message}',
    );
    return false;
  }
}

Future<FileSystemEntityType> _typeWithoutFollowingLinks(String path) async {
  if (await FileSystemEntity.isLink(path)) return FileSystemEntityType.link;
  return FileSystemEntity.type(path, followLinks: false);
}

Uint8List _png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
  'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

void _repairChunkCrc(Uint8List bytes, int offset) {
  final data = ByteData.sublistView(bytes);
  final length = data.getUint32(offset);
  data.setUint32(offset + 8 + length, _crc32(bytes, offset + 4, length + 4));
}

int _crc32(Uint8List bytes, int start, int length) {
  var crc = 0xffffffff;
  for (var index = start; index < start + length; index++) {
    crc ^= bytes[index];
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
