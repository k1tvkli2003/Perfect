import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/widgets/perfect_today_widget_background.dart';

void main() {
  const ownerId = 'owner-a';
  const firstActionId = '77777777-7777-4777-8777-777777777777';

  late PlannerDatabase database;
  late PlannerLocalStore store;

  setUp(() {
    database = PlannerDatabase(NativeDatabase.memory());
    store = PlannerLocalStore(database);
  });

  tearDown(() => store.close());

  test('the four-state task cycle is explicit and returns to empty', () {
    const pending = PlannerTaskProgress.pending();
    expect(pending.next.state, PlannerTaskProgressState.completed);
    expect(pending.next.percent, 100);
    expect(pending.next.next.state, PlannerTaskProgressState.missed);
    expect(pending.next.next.next.state, PlannerTaskProgressState.partial);
    expect(pending.next.next.next.percent, 50);
    expect(pending.next.next.next.next.state, PlannerTaskProgressState.pending);
  });

  test(
    'one-off tasks preserve partial and missed outcomes without archiving',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Write widget contract',
        now: DateTime.utc(2026, 7, 27, 8),
      );
      final service = PlannerTaskProgressService(
        store,
        ownerId: ownerId,
        now: () => DateTime.utc(2026, 7, 27, 9),
      );

      await service.setProgress(
        created.entity!,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.partial,
          percent: 63,
        ),
        mutationId: firstActionId,
      );

      final partial = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(partial!.status, PlannerEntityStatus.active);
      expect(
        PlannerTaskProgress.fromEntity(partial),
        const PlannerTaskProgress(
          state: PlannerTaskProgressState.partial,
          percent: 63,
        ),
      );
      expect(partial.isDeleted, isFalse);

      await service.setProgress(
        partial,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.missed,
          percent: 0,
        ),
        mutationId: '88888888-8888-4888-8888-888888888888',
      );
      final missed = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(PlannerTaskProgress.fromEntity(missed!).isMissed, isTrue);
      expect(missed.status, PlannerEntityStatus.active);
    },
  );

  test(
    'a recurring widget action is idempotent and never completes its series',
    () async {
      final created = PlannerEntity(
        id: 'task-recurring-widget',
        ownerId: ownerId,
        kind: PlannerEntityKind.recurringTask,
        payload: <String, dynamic>{
          PlannerPayloadKeys.title: 'Review day',
          PlannerPayloadKeys.timing: <String, dynamic>{
            'scheduled_at': '2026-07-27T12:00:00.000Z',
          },
        },
        createdAt: DateTime.utc(2026, 7, 27, 8),
        updatedAt: DateTime.utc(2026, 7, 27, 8),
      );
      await store.upsertEntity(entity: created);
      final action = PlannerWidgetTaskAction(
        id: '99999999-9999-4999-8999-999999999999',
        ownerId: ownerId,
        entityId: created.id,
        kind: PlannerEntityKind.recurringTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
        localDay: DateTime(2026, 7, 27),
        occurredAt: DateTime.utc(2026, 7, 27, 12, 5),
      );
      final service = PlannerTaskProgressService(
        store,
        ownerId: ownerId,
        now: () => action.occurredAt,
      );

      await service.applyWidgetAction(action);
      await service.applyWidgetAction(action);

      final series = await store.readEntity(
        ownerId: ownerId,
        entityId: created.id,
      );
      final occurrence = await store.readOccurrence(
        ownerId: ownerId,
        occurrenceId: PlannerTaskProgressService.recurringOccurrenceId(
          created,
          action.localDay,
        ),
      );
      expect(series!.status, PlannerEntityStatus.active);
      expect(PlannerTaskProgress.fromOccurrence(occurrence).isComplete, isTrue);
      expect(
        (await store.listPendingOperations(
          ownerId,
        )).where((operation) => operation.mutationId == action.id),
        hasLength(1),
      );
    },
  );

  test(
    'a late older widget worker cannot revert a newer queued outcome',
    () async {
      final created = PlannerEntity(
        id: 'task-overlapping-widget-workers',
        ownerId: ownerId,
        kind: PlannerEntityKind.recurringTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Converge widget queue'),
          PlannerPayloadKeys.recurrence: const <String, dynamic>{
            'rule': 'daily',
          },
        },
        createdAt: DateTime.utc(2026, 7, 27, 8),
        updatedAt: DateTime.utc(2026, 7, 27, 8),
      );
      await store.upsertEntity(entity: created);
      final completed = PlannerWidgetTaskAction(
        id: 'aaaaaaaa-9999-4999-8999-aaaaaaaaaaaa',
        ownerId: ownerId,
        entityId: created.id,
        kind: PlannerEntityKind.recurringTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
        localDay: DateTime(2026, 7, 27),
        occurredAt: DateTime.utc(2026, 7, 27, 12, 5),
      );
      final missed = PlannerWidgetTaskAction(
        id: 'bbbbbbbb-9999-4999-8999-bbbbbbbbbbbb',
        ownerId: ownerId,
        entityId: created.id,
        kind: PlannerEntityKind.recurringTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.missed,
          percent: 0,
        ),
        localDay: completed.localDay,
        occurredAt: DateTime.utc(2026, 7, 27, 12, 6),
      );
      final staleCompleted = PlannerWidgetTaskAction(
        id: 'eeeeeeee-9999-4999-8999-eeeeeeeeeeee',
        ownerId: ownerId,
        entityId: created.id,
        kind: PlannerEntityKind.recurringTask,
        progress: completed.progress,
        localDay: completed.localDay,
        occurredAt: completed.occurredAt,
      );
      final service = PlannerTaskProgressService(store, ownerId: ownerId);

      // The newer worker drains the ordered native queue.
      await service.applyWidgetAction(completed);
      await service.applyWidgetAction(missed);
      // An older overlapping legacy worker finishes late with a fresh
      // mutation ID, so outbox idempotency cannot be what protects the state.
      await service.applyWidgetAction(staleCompleted);

      final occurrence = await store.readOccurrence(
        ownerId: ownerId,
        occurrenceId: PlannerTaskProgressService.recurringOccurrenceId(
          created,
          completed.localDay,
        ),
      );
      expect(PlannerTaskProgress.fromOccurrence(occurrence).isMissed, isTrue);
    },
  );

  test('a stale queued widget row cannot block a newer valid action', () async {
    final created = PlannerEntity(
      id: 'task-after-stale-widget-row',
      ownerId: ownerId,
      kind: PlannerEntityKind.recurringTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Drain past stale row'),
        PlannerPayloadKeys.recurrence: const <String, dynamic>{'rule': 'daily'},
      },
      createdAt: DateTime.utc(2026, 7, 27, 8),
      updatedAt: DateTime.utc(2026, 7, 27, 8),
    );
    await store.upsertEntity(entity: created);
    final day = DateTime(2026, 7, 27);
    final stale = PlannerWidgetTaskAction(
      id: 'cccccccc-9999-4999-8999-cccccccccccc',
      ownerId: ownerId,
      entityId: 'already-archived',
      kind: PlannerEntityKind.recurringTask,
      progress: const PlannerTaskProgress(
        state: PlannerTaskProgressState.completed,
        percent: 100,
      ),
      localDay: day,
      occurredAt: DateTime.utc(2026, 7, 27, 12, 4),
    );
    final valid = PlannerWidgetTaskAction(
      id: 'dddddddd-9999-4999-8999-dddddddddddd',
      ownerId: ownerId,
      entityId: created.id,
      kind: PlannerEntityKind.recurringTask,
      progress: const PlannerTaskProgress(
        state: PlannerTaskProgressState.completed,
        percent: 100,
      ),
      localDay: day,
      occurredAt: DateTime.utc(2026, 7, 27, 12, 5),
    );

    await replayPerfectTodayWidgetActions(
      store: store,
      ownerId: ownerId,
      actions: <PlannerWidgetTaskAction>[valid, stale],
    );

    final occurrence = await store.readOccurrence(
      ownerId: ownerId,
      occurrenceId: PlannerTaskProgressService.recurringOccurrenceId(
        created,
        day,
      ),
    );
    expect(PlannerTaskProgress.fromOccurrence(occurrence).isComplete, isTrue);
  });

  test(
    'two SQLite connections converge one-off and recurring outcomes on the highest native sequence',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final tempDirectory = await Directory.systemTemp.createTemp(
        'perfect-widget-sequence-',
      );
      final databaseFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}planner.sqlite',
      );
      final firstDatabase = PlannerDatabase(
        NativeDatabase.createInBackground(databaseFile),
      );
      final firstStore = PlannerLocalStore(firstDatabase);
      PlannerLocalStore? secondStore;

      try {
        final oneOff = (await firstStore.createQuickTask(
          ownerId: ownerId,
          title: 'Guard the one-off outcome',
          now: DateTime.utc(2026, 7, 27, 8),
        )).entity!;
        final recurring = PlannerEntity(
          id: 'two-connection-recurring-task',
          ownerId: ownerId,
          kind: PlannerEntityKind.recurringTask,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Guard the daily outcome'),
            PlannerPayloadKeys.recurrence: const <String, dynamic>{
              'rule': 'daily',
            },
          },
          createdAt: DateTime.utc(2026, 7, 27, 8),
          updatedAt: DateTime.utc(2026, 7, 27, 8),
        );
        await firstStore.upsertEntity(entity: recurring);

        // Open a genuinely independent Drift/SQLite connection after the
        // first connection has created and seeded the shared file.
        secondStore = PlannerLocalStore(
          PlannerDatabase(NativeDatabase.createInBackground(databaseFile)),
        );
        final firstService = PlannerTaskProgressService(
          firstStore,
          ownerId: ownerId,
        );
        final secondService = PlannerTaskProgressService(
          secondStore,
          ownerId: ownerId,
        );
        final day = DateTime(2026, 7, 27);

        PlannerWidgetTaskAction action({
          required String id,
          required PlannerEntity entity,
          required int sequence,
          required PlannerTaskProgress progress,
          required DateTime occurredAt,
        }) => PlannerWidgetTaskAction(
          id: id,
          ownerId: ownerId,
          entityId: entity.id,
          kind: entity.kind,
          progress: progress,
          localDay: day,
          occurredAt: occurredAt,
          queueSequence: sequence,
        );

        final oneOffHigh = action(
          id: '10000000-0000-4000-8000-000000000090',
          entity: oneOff,
          sequence: 90,
          progress: const PlannerTaskProgress(
            state: PlannerTaskProgressState.missed,
            percent: 0,
          ),
          // The winning sequence intentionally has an older wall clock.
          occurredAt: DateTime.utc(2026, 7, 27, 9),
        );
        final oneOffLow = action(
          id: '10000000-0000-4000-8000-000000000080',
          entity: oneOff,
          sequence: 80,
          progress: const PlannerTaskProgress(
            state: PlannerTaskProgressState.completed,
            percent: 100,
          ),
          occurredAt: DateTime.utc(2026, 7, 27, 12),
        );
        final recurringHigh = action(
          id: '20000000-0000-4000-8000-000000000190',
          entity: recurring,
          sequence: 190,
          progress: const PlannerTaskProgress(
            state: PlannerTaskProgressState.partial,
            percent: 65,
          ),
          occurredAt: DateTime.utc(2026, 7, 27, 9),
        );
        final recurringLow = action(
          id: '20000000-0000-4000-8000-000000000180',
          entity: recurring,
          sequence: 180,
          progress: const PlannerTaskProgress(
            state: PlannerTaskProgressState.completed,
            percent: 100,
          ),
          occurredAt: DateTime.utc(2026, 7, 27, 12),
        );

        // These Futures enter separate database connections concurrently.
        await Future.wait(<Future<PlannerTaskProgress>>[
          firstService.applyWidgetAction(oneOffHigh),
          secondService.applyWidgetAction(oneOffLow),
          firstService.applyWidgetAction(recurringLow),
          secondService.applyWidgetAction(recurringHigh),
        ]);

        // Replay different stale mutation IDs after the concurrent pass. They
        // must be rejected by the durable sequence clock, not outbox
        // idempotency.
        await secondService.applyWidgetAction(
          action(
            id: '30000000-0000-4000-8000-000000000070',
            entity: oneOff,
            sequence: 70,
            progress: const PlannerTaskProgress(
              state: PlannerTaskProgressState.completed,
              percent: 100,
            ),
            occurredAt: DateTime.utc(2026, 7, 28),
          ),
        );
        await firstService.applyWidgetAction(
          action(
            id: '40000000-0000-4000-8000-000000000170',
            entity: recurring,
            sequence: 170,
            progress: const PlannerTaskProgress(
              state: PlannerTaskProgressState.missed,
              percent: 0,
            ),
            occurredAt: DateTime.utc(2026, 7, 28),
          ),
        );

        final storedOneOff = await secondStore.readEntity(
          ownerId: ownerId,
          entityId: oneOff.id,
        );
        final storedOccurrence = await secondStore.readOccurrence(
          ownerId: ownerId,
          occurrenceId: PlannerTaskProgressService.recurringOccurrenceId(
            recurring,
            day,
          ),
        );
        expect(PlannerTaskProgress.fromEntity(storedOneOff!).isMissed, isTrue);
        expect(
          PlannerTaskProgress.fromOccurrence(storedOccurrence),
          const PlannerTaskProgress(
            state: PlannerTaskProgressState.partial,
            percent: 65,
          ),
        );
      } finally {
        await secondStore?.close();
        await firstStore.close();
        await tempDirectory.delete(recursive: true);
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting;
      }
    },
  );

  test(
    'background SQLite wrapper retries a guarded outcome after its writer lock clears',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final tempDirectory = await Directory.systemTemp.createTemp(
        'perfect-widget-remote-busy-',
      );
      final databaseFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}planner.sqlite',
      );
      final lockDatabase = PlannerDatabase(NativeDatabase(databaseFile));
      final lockStore = PlannerLocalStore(lockDatabase);
      PlannerDatabase? backgroundDatabase;
      PlannerLocalStore? backgroundStore;
      final lockAcquired = Completer<void>();
      final releaseLock = Completer<void>();
      Future<void>? lockFuture;

      try {
        final entity = (await lockStore.createQuickTask(
          ownerId: ownerId,
          title: 'Retry the background outcome',
          now: DateTime.utc(2026, 7, 27, 8),
        )).entity!;
        backgroundDatabase = PlannerDatabase(
          NativeDatabase.createInBackground(databaseFile),
        );
        backgroundStore = PlannerLocalStore(backgroundDatabase);
        await backgroundDatabase.customStatement('PRAGMA busy_timeout = 0');

        lockFuture = lockDatabase.transaction(() async {
          await lockDatabase.customStatement(
            'UPDATE planner_entities SET updated_at = updated_at '
            'WHERE owner_id = ? AND id = ?',
            <Object?>[ownerId, entity.id],
          );
          lockAcquired.complete();
          await releaseLock.future;
        });
        await lockAcquired.future;

        // Prove this exact executor reports contention through Drift's remote
        // wrapper rather than as a direct SqliteException.
        Object? remoteBusy;
        try {
          await backgroundDatabase.transaction(() async {});
        } catch (error) {
          remoteBusy = error;
        }
        expect(remoteBusy, isA<DriftRemoteException>());
        final remoteCause = (remoteBusy! as DriftRemoteException).remoteCause;
        expect(remoteCause, isA<SqliteException>());
        expect((remoteCause as SqliteException).resultCode, 5);

        final service = PlannerTaskProgressService(
          backgroundStore,
          ownerId: ownerId,
        );
        final outcome = service.applyWidgetAction(
          PlannerWidgetTaskAction(
            id: '50000000-0000-4000-8000-000000000500',
            ownerId: ownerId,
            entityId: entity.id,
            kind: entity.kind,
            progress: const PlannerTaskProgress(
              state: PlannerTaskProgressState.missed,
              percent: 0,
            ),
            localDay: DateTime(2026, 7, 27),
            occurredAt: DateTime.utc(2026, 7, 27, 9),
            queueSequence: 500,
          ),
        );

        // The read is queued on the same remote executor after the failed
        // BEGIN. It is a scheduling barrier, not a timed sleep: once it
        // returns, the guarded call has observed BUSY and entered backoff.
        await backgroundDatabase.customSelect('SELECT 1').getSingle();
        releaseLock.complete();
        await lockFuture;

        expect((await outcome).isMissed, isTrue);
        final stored = await backgroundStore.readEntity(
          ownerId: ownerId,
          entityId: entity.id,
        );
        expect(PlannerTaskProgress.fromEntity(stored!).isMissed, isTrue);
      } finally {
        if (!releaseLock.isCompleted) releaseLock.complete();
        await lockFuture;
        await backgroundStore?.close();
        await lockStore.close();
        await tempDirectory.delete(recursive: true);
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting;
      }
    },
  );

  test(
    'schema v1 upgrades the local widget sequence guard without data loss',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final tempDirectory = await Directory.systemTemp.createTemp(
        'perfect-widget-migration-',
      );
      final databaseFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}planner.sqlite',
      );
      final originalDatabase = PlannerDatabase(
        NativeDatabase.createInBackground(databaseFile),
      );
      final originalStore = PlannerLocalStore(originalDatabase);
      var originalStoreClosed = false;

      try {
        final entity = (await originalStore.createQuickTask(
          ownerId: ownerId,
          title: 'Keep me through migration',
          now: DateTime.utc(2026, 7, 27, 8),
        )).entity!;
        await originalDatabase.customStatement(
          'DROP TABLE planner_widget_action_sequences',
        );
        await originalDatabase.customStatement(
          'ALTER TABLE planner_sync_metadata DROP COLUMN saved_view_cursor',
        );
        await originalDatabase.customStatement('PRAGMA user_version = 1');
        await originalStore.close();
        originalStoreClosed = true;

        final upgradedStore = PlannerLocalStore(
          PlannerDatabase(NativeDatabase.createInBackground(databaseFile)),
        );
        try {
          expect(
            await upgradedStore.readEntity(
              ownerId: ownerId,
              entityId: entity.id,
            ),
            isNotNull,
          );
          final action = PlannerWidgetTaskAction(
            id: '50000000-0000-4000-8000-000000000001',
            ownerId: ownerId,
            entityId: entity.id,
            kind: PlannerEntityKind.oneOffTask,
            progress: const PlannerTaskProgress(
              state: PlannerTaskProgressState.completed,
              percent: 100,
            ),
            localDay: DateTime(2026, 7, 27),
            occurredAt: DateTime.utc(2026, 7, 27, 9),
            queueSequence: 1,
          );
          await PlannerTaskProgressService(
            upgradedStore,
            ownerId: ownerId,
          ).applyWidgetAction(action);
          expect(
            PlannerTaskProgress.fromEntity(
              (await upgradedStore.readEntity(
                ownerId: ownerId,
                entityId: entity.id,
              ))!,
            ).isComplete,
            isTrue,
          );
        } finally {
          await upgradedStore.close();
        }
      } finally {
        if (!originalStoreClosed) await originalStore.close();
        await tempDirectory.delete(recursive: true);
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting;
      }
    },
  );
}
