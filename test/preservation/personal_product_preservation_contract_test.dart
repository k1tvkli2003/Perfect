import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const ownerId = 'preservation-owner';
  const deviceId = '10000000-0000-4000-8000-000000000001';
  final now = DateTime.utc(2026, 8, 9, 8, 30);

  group('immutable private-product boundary', () {
    test(
      'production entrypoint cannot import or seed the preview workspace',
      () async {
        final mainSource = await File('lib/main.dart').readAsString();
        final previewSource = await File(
          'lib/dev/perfect_live_preview.dart',
        ).readAsString();
        final androidBuild = await File(
          'android/app/build.gradle.kts',
        ).readAsString();

        expect(previewSource, contains('_seedPreview'));
        expect(mainSource, isNot(contains('perfect_live_preview.dart')));
        expect(mainSource, isNot(contains('_seedPreview')));
        expect(
          androidBuild,
          contains('applicationIdSuffix = ".preview"'),
          reason:
              'The seeded visual harness must remain a sibling package and never '
              'share production storage, session, widgets, or signing lineage.',
        );
      },
    );

    test('sign-out clears only the widget projection before auth', () async {
      final source = await File('lib/main.dart').readAsString();
      final match = RegExp(
        r'Future<void> _signOut\(\) async \{([\s\S]*?)\n  \}',
      ).firstMatch(source);
      expect(
        match,
        isNotNull,
        reason: 'The owner sign-out path must stay explicit.',
      );
      final body = match!.group(1)!;

      expect(body, contains('_controller?.clearTodayWidgetForSignOut()'));
      expect(body, contains('Supabase.instance.client.auth.signOut()'));
      expect(
        body.indexOf('clearTodayWidgetForSignOut'),
        lessThan(body.indexOf('auth.signOut')),
        reason:
            'Private widget content must disappear before auth scope closes.',
      );
      for (final forbidden in <String>[
        'PlannerDatabase',
        'PlannerLocalStore',
        'SharedPreferences',
        '.clear()',
        'deleteDatabase',
        'deleteAll',
        'resetForTesting',
      ]) {
        expect(
          body,
          isNot(contains(forbidden)),
          reason:
              'Sign-out must never use destructive durable-storage API $forbidden.',
        );
      }
    });

    test('Android and Windows update identities remain pinned', () async {
      final pubspec = await File('pubspec.yaml').readAsString();
      final androidBuild = await File(
        'android/app/build.gradle.kts',
      ).readAsString();
      final androidManifest = await File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsString();
      final windowsRunner = await File(
        'windows/runner/main.cpp',
      ).readAsString();
      final windowsResources = await File(
        'windows/runner/Runner.rc',
      ).readAsString();

      expect(
        androidBuild,
        contains('applicationId = "com.k1tvkli2003.perfect"'),
      );
      expect(androidBuild, contains('namespace = "com.k1tvkli2003.perfect"'));
      expect(androidManifest, contains('android:allowBackup="false"'));
      expect(pubspec, contains('identity_name: com.k1tvkli2003.perfect'));
      expect(pubspec, contains('publisher: CN=K1 Perfect Private'));
      expect(pubspec, contains('protocol_activation: perfect'));
      expect(windowsRunner, contains('L"Perfect!"'));
      expect(windowsResources, contains('"OriginalFilename", "perfect.exe"'));
    });

    test(
      'artifact scanner detects a protected value without printing it',
      () async {
        const environmentName = 'PERFECT_ARTIFACT_SECRET_TEST';
        const protectedValue = 'private-fixture-value-7f34ab19';
        final tempDirectory = await Directory.systemTemp.createTemp(
          'perfect-artifact-secret-scan-',
        );
        final artifact = File(
          '${tempDirectory.path}${Platform.pathSeparator}fixture.bin',
        );
        final python = Platform.isWindows ? 'python' : 'python3';
        final environment = <String, String>{
          ...Platform.environment,
          environmentName: protectedValue,
        };

        try {
          await artifact.writeAsString('safe release payload');
          final safe = await Process.run(python, <String>[
            'tool/verify_artifact_secret_absence.py',
            '--artifact',
            artifact.path,
            '--secret-env',
            environmentName,
          ], environment: environment);
          expect(safe.exitCode, 0, reason: '${safe.stdout}\n${safe.stderr}');

          await artifact.writeAsString('prefix:$protectedValue:suffix');
          final rejected = await Process.run(python, <String>[
            'tool/verify_artifact_secret_absence.py',
            '--artifact',
            artifact.path,
            '--secret-env',
            environmentName,
          ], environment: environment);
          expect(rejected.exitCode, 1);
          final output = '${rejected.stdout}\n${rejected.stderr}';
          expect(output, contains(environmentName));
          expect(output, isNot(contains(protectedValue)));
        } finally {
          await tempDirectory.delete(recursive: true);
        }
      },
    );
  });

  test(
    'sign-out/session disposal preserves task, habit history, settings and outbox',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PerfectPreferences.themeModeKey: 'dark',
        PerfectPreferences.navigationRailExtendedKey: true,
        'perfect.test.auth_session_marker': 'session-survives-normal-upgrade',
      });
      final tempDirectory = await Directory.systemTemp.createTemp(
        'perfect-preservation-signout-',
      );
      final databaseFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}perfect_planner.sqlite',
      );
      final database = PlannerDatabase(
        NativeDatabase.createInBackground(databaseFile),
      );
      final local = PlannerLocalStore(database);
      var controllerClosed = false;

      try {
        final task = (await local.createQuickTask(
          ownerId: ownerId,
          title: 'Preserve this local task',
          now: now,
          mutationId: '10000000-0000-4000-8000-000000000010',
        )).entity!;
        final habit = PlannerEntity(
          id: '10000000-0000-4000-8000-000000000020',
          ownerId: ownerId,
          kind: PlannerEntityKind.habit,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Preserve this habit'),
            PlannerPayloadKeys.tracking: const <String, dynamic>{
              PlannerHabitTrackingKeys.method: 'check',
            },
          },
          createdAt: now,
          updatedAt: now,
        );
        await local.upsertEntity(
          entity: habit,
          mutationId: '10000000-0000-4000-8000-000000000021',
          now: now,
        );
        final occurrence = (await local.appendOccurrence(
          ownerId: ownerId,
          entityId: habit.id,
          plannedFor: now,
          status: 'completed',
          value: const <String, dynamic>{'source': 'preservation-fixture'},
          now: now,
          occurrenceId: '10000000-0000-4000-8000-000000000030',
          mutationId: '10000000-0000-4000-8000-000000000031',
        )).occurrence!;
        final pendingBefore = await local.listPendingOperations(ownerId);
        expect(pendingBefore, hasLength(3));

        final widgetBridge = _RecordingWidgetBridge();
        final controller = PlannerWorkspaceController(
          local,
          PlannerSyncRepository(
            local,
            _DisconnectedGateway(),
            ownerId: ownerId,
            deviceId: deviceId,
          ),
          ownerId: ownerId,
          now: () => now,
          todayWidgetBridge: widgetBridge,
        );

        // This mirrors explicit sign-out followed by auth-scoped widget
        // disposal. The controller owns and closes the database connection.
        await controller.clearTodayWidgetForSignOut();
        expect(widgetBridge.clearCalls, 1);
        await controller.disposeAsync();
        controllerClosed = true;

        final reopened = PlannerLocalStore(
          PlannerDatabase(NativeDatabase.createInBackground(databaseFile)),
        );
        try {
          final entities = await reopened.readActiveEntities(ownerId);
          expect(
            entities.map((entity) => entity.id),
            containsAll(<String>[task.id, habit.id]),
          );
          final occurrences = await reopened.readOccurrences(ownerId);
          expect(occurrences, hasLength(1));
          expect(occurrences.single.id, occurrence.id);
          expect(occurrences.single.entityId, habit.id);
          expect(occurrences.single.status, 'completed');
          expect(occurrences.single.value, const <String, dynamic>{
            'source': 'preservation-fixture',
          });
          final pendingAfter = await reopened.listPendingOperations(ownerId);
          expect(
            pendingAfter.map((operation) => operation.mutationId),
            unorderedEquals(
              pendingBefore.map((operation) => operation.mutationId),
            ),
          );
          expect(await reopened.readActiveEntities('another-owner'), isEmpty);
        } finally {
          await reopened.close();
        }

        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getString(PerfectPreferences.themeModeKey), 'dark');
        expect(
          preferences.getBool(PerfectPreferences.navigationRailExtendedKey),
          isTrue,
        );
        expect(
          preferences.getString('perfect.test.auth_session_marker'),
          'session-survives-normal-upgrade',
        );
      } finally {
        if (!controllerClosed) await local.close();
        await tempDirectory.delete(recursive: true);
      }
    },
  );

  test(
    'failed v1 to v2 migration rolls back and remains recoverable',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final tempDirectory = await Directory.systemTemp.createTemp(
        'perfect-preservation-failed-migration-',
      );
      final databaseFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}perfect_planner.sqlite',
      );
      final originalDatabase = PlannerDatabase(
        NativeDatabase.createInBackground(databaseFile),
      );
      final originalStore = PlannerLocalStore(originalDatabase);
      var originalClosed = false;

      try {
        final task = (await originalStore.createQuickTask(
          ownerId: ownerId,
          title: 'Recover me after a failed migration',
          now: now,
          mutationId: '20000000-0000-4000-8000-000000000010',
        )).entity!;
        final pendingBefore = await originalStore.listPendingOperations(
          ownerId,
        );
        await originalDatabase.customStatement(
          'DROP TABLE planner_widget_action_sequences',
        );
        await originalDatabase.customStatement(
          'ALTER TABLE planner_sync_metadata DROP COLUMN saved_view_cursor',
        );
        await originalDatabase.customStatement('PRAGMA user_version = 1');
        await originalStore.close();
        originalClosed = true;

        final failingDatabase = _FailingMigrationDatabase(
          NativeDatabase.createInBackground(databaseFile),
        );
        Object? migrationFailure;
        try {
          await failingDatabase.customSelect('SELECT 1').get();
        } on Object catch (error) {
          migrationFailure = error;
        } finally {
          await failingDatabase.close();
        }
        expect(migrationFailure, isNotNull);

        final recoveredStore = PlannerLocalStore(
          PlannerDatabase(NativeDatabase.createInBackground(databaseFile)),
        );
        try {
          expect(
            await recoveredStore.readEntity(
              ownerId: ownerId,
              entityId: task.id,
            ),
            isNotNull,
          );
          expect(
            (await recoveredStore.listPendingOperations(
              ownerId,
            )).map((operation) => operation.mutationId),
            unorderedEquals(
              pendingBefore.map((operation) => operation.mutationId),
            ),
          );
        } finally {
          await recoveredStore.close();
        }
      } finally {
        if (!originalClosed) await originalStore.close();
        await tempDirectory.delete(recursive: true);
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting;
      }
    },
  );
}

class _RecordingWidgetBridge extends PerfectTodayWidgetBridge {
  int clearCalls = 0;

  @override
  Future<void> clearForSignOut() async {
    clearCalls++;
  }
}

class _DisconnectedGateway implements PlannerRemoteGateway {
  @override
  Future<PlannerRemoteMutationResult> apply(PlannerRemoteMutation mutation) =>
      Future<PlannerRemoteMutationResult>.error(StateError('offline for test'));

  @override
  Future<void> dispose() async {}

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async => PlannerRemoteChangePage(
    changes: const <PlannerRemoteChange>[],
    requestedLimit: limit,
  );

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<void> subscribe(void Function() onChangeHint) async {}
}

class _FailingMigrationDatabase extends PlannerDatabase {
  _FailingMigrationDatabase(super.executor);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(plannerWidgetActionSequences);
        throw StateError('Simulated interruption after migration DDL.');
      }
    },
  );
}
