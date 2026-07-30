import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';

void main() {
  late PlannerDatabase database;
  late PlannerLocalStore store;

  setUp(() {
    database = PlannerDatabase(NativeDatabase.memory());
    store = PlannerLocalStore(database);
  });

  tearDown(() => store.close());

  test('v1 import is safe, preserves a tombstone, and is idempotent', () async {
    const ownerId = 'owner-a';
    final rawLegacyJson = jsonEncode(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'legacy-task-1',
        'title': 'Pay the electricity bill',
        'is_done': true,
        'created_at': '2026-07-01T08:00:00.000Z',
        'updated_at': '2026-07-02T08:00:00.000Z',
        'deleted_at': '2026-07-03T08:00:00.000Z',
      },
      <String, dynamic>{'id': 'missing-title'},
    ]);

    final first = await store.bootstrap(
      ownerId: ownerId,
      legacyPersonalItemsJson: rawLegacyJson,
      now: DateTime.utc(2026, 7, 10),
    );
    final second = await store.bootstrap(
      ownerId: ownerId,
      legacyPersonalItemsJson: rawLegacyJson,
      now: DateTime.utc(2026, 7, 11),
    );

    expect(first.imported, 1);
    expect(first.skipped, 1);
    expect(second.imported, 0);
    expect(second.alreadyImported, 1);

    final pending = await store.listPendingOperations(ownerId);
    expect(pending, hasLength(1));
    final imported = await store.readEntity(
      ownerId: ownerId,
      entityId: pending.single.targetId,
      includeDeleted: true,
    );
    expect(imported, isNotNull);
    expect(imported!.title, 'Pay the electricity bill');
    expect(imported.status, PlannerEntityStatus.completed);
    expect(imported.isDeleted, isTrue);
    expect(imported.payload['legacy_source_id'], 'legacy-task-1');

    expect(pending.single.type, PlannerOperationType.createEntity);
    expect(pending.single.entityKind, PlannerEntityKind.oneOffTask);
    expect(pending.single.patch.values, contains('/deleted_at'));
  });

  test(
    'create writes atomically and an exact mutation replay returns its receipt',
    () async {
      const ownerId = 'owner-a';
      const mutationId = '11111111-1111-4111-8111-111111111111';
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Write the persistence tests',
        mutationId: mutationId,
        now: DateTime.utc(2026, 7, 27, 10),
      );

      expect(created.entity, isNotNull);
      expect(created.operation.mutationId, mutationId);
      expect(created.operation.patch.values['/'], isA<Map<String, dynamic>>());
      expect(await store.readActiveEntities(ownerId), hasLength(1));
      expect(await store.listPendingOperations(ownerId), hasLength(1));

      final duplicate = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Write the persistence tests',
        mutationId: mutationId,
        now: DateTime.utc(2026, 7, 27, 11),
      );

      expect(duplicate.wasDuplicate, isTrue);
      expect(duplicate.entity!.id, created.entity!.id);
      expect(await store.listPendingOperations(ownerId), hasLength(1));
      final current = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(current!.title, 'Write the persistence tests');
    },
  );

  test('a mutation id cannot be reused for a different request', () async {
    const ownerId = 'owner-a';
    const mutationId = '12121212-1212-4212-8212-121212121212';
    final created = await store.createQuickTask(
      ownerId: ownerId,
      title: 'Original request',
      mutationId: mutationId,
      now: DateTime.utc(2026, 7, 27, 10),
    );
    final changedPayload = <String, dynamic>{
      ...created.entity!.payload,
      PlannerPayloadKeys.title: 'Different request',
    };

    await expectLater(
      store.upsertEntity(
        entity: created.entity!.copyWith(payload: changedPayload),
        mutationId: mutationId,
        now: DateTime.utc(2026, 7, 27, 11),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('different local request'),
        ),
      ),
    );

    expect(await store.listPendingOperations(ownerId), hasLength(1));
    expect(
      (await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      ))!.title,
      'Original request',
    );
  });

  test(
    'soft delete preserves an entity and queues a tombstone operation',
    () async {
      const ownerId = 'owner-a';
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Keep history',
        now: DateTime.utc(2026, 7, 27, 12),
      );

      final deleted = await store.softDeleteEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        now: DateTime.utc(2026, 7, 27, 13),
      );

      expect(deleted.entity!.isDeleted, isTrue);
      expect(await store.readActiveEntities(ownerId), isEmpty);
      final retained = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        includeDeleted: true,
      );
      expect(retained!.isDeleted, isTrue);
      expect(retained.title, 'Keep history');

      final pending = await store.listPendingOperations(ownerId);
      expect(pending, hasLength(2));
      expect(pending.last.type, PlannerOperationType.softDeleteEntity);
      expect(pending.last.patch.values, contains('/deleted_at'));
    },
  );

  test(
    'completion timestamp is part of the local projection immediately',
    () async {
      const ownerId = 'owner-a';
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Complete locally first',
      );
      final completedAt = DateTime.utc(2026, 7, 27, 12);

      await store.completeEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        now: completedAt,
      );

      final completed = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(completed!.status, PlannerEntityStatus.completed);
      expect(safeJsonDateTime(completed.payload['completed_at']), completedAt);
    },
  );

  test(
    'archive is recoverable without creating a second planner entity',
    () async {
      const ownerId = 'owner-a';
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Keep this for later',
        now: DateTime.utc(2026, 7, 27, 12),
      );

      await store.softDeleteEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        now: DateTime.utc(2026, 7, 27, 13),
      );
      expect(
        (await store.readArchivedEntities(ownerId)).single.id,
        created.entity!.id,
      );

      final restored = await store.restoreEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        now: DateTime.utc(2026, 7, 27, 14),
      );
      expect(restored.entity!.isDeleted, isFalse);
      expect(
        (await store.readActiveEntities(ownerId)).single.id,
        created.entity!.id,
      );
      expect(await store.readArchivedEntities(ownerId), isEmpty);
      expect(restored.operation.patch.values, <String, dynamic>{
        '/deleted_at': null,
      });
    },
  );

  test(
    'a repeated daily occurrence updates its record instead of duplicating it',
    () async {
      const ownerId = 'owner-a';
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Repeated daily work',
        now: DateTime.utc(2026, 7, 27, 8),
      );
      const occurrenceId = 'recurring-occurrence-day-1';
      final first = await store.appendOccurrence(
        ownerId: ownerId,
        entityId: created.entity!.id,
        occurrenceId: occurrenceId,
        status: 'completed',
        plannedFor: DateTime.utc(2026, 7, 27, 9),
        now: DateTime.utc(2026, 7, 27, 9, 5),
      );
      final reopened = await store.appendOccurrence(
        ownerId: ownerId,
        entityId: created.entity!.id,
        occurrenceId: occurrenceId,
        status: 'pending',
        plannedFor: DateTime.utc(2026, 7, 27, 9),
        value: const <String, dynamic>{'source': 'undo'},
        now: DateTime.utc(2026, 7, 27, 9, 6),
      );

      final occurrences = await store.readOccurrences(ownerId);
      expect(occurrences, hasLength(1));
      expect(occurrences.single.status, 'pending');
      expect(occurrences.single.completedAt, isNull);
      expect(occurrences.single.createdAt, first.occurrence!.createdAt);
      expect(reopened.occurrence!.createdAt, first.occurrence!.createdAt);
    },
  );

  test(
    'occurrence outcomes reject unknown server-incompatible states',
    () async {
      const ownerId = 'owner-a';
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Validated outcome',
      );

      await expectLater(
        store.appendOccurrence(
          ownerId: ownerId,
          entityId: created.entity!.id,
          plannedFor: DateTime.utc(2026, 7, 27, 9),
          status: 'archived',
        ),
        throwsArgumentError,
      );
      expect(await store.readOccurrences(ownerId), isEmpty);
    },
  );

  test(
    'flexible quota and lifetime limit use separate durable history counts',
    () async {
      const ownerId = 'owner-a';
      final monday = DateTime(2026, 7, 27, 8);
      final task = PlannerEntity(
        id: 'abababab-abab-4bab-8bab-abababababab',
        ownerId: ownerId,
        kind: PlannerEntityKind.recurringTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Two sessions this week'),
          PlannerPayloadKeys.timing: <String, dynamic>{
            'scheduled_at': monday.toUtc().toIso8601String(),
          },
          PlannerPayloadKeys.recurrence: <String, dynamic>{
            'rule': 'flexible',
            PlannerRecurrenceKeys.occurrenceLimit: 2,
            PlannerRecurrenceKeys.frequency: <String, dynamic>{
              PlannerRecurrenceKeys.frequencyCount: 3,
              PlannerRecurrenceKeys.frequencyPeriod: 'week',
            },
          },
        },
        createdAt: monday.toUtc(),
        updatedAt: monday.toUtc(),
      );
      await store.upsertEntity(
        entity: task,
        mutationId: 'abababab-1111-4111-8111-abababababab',
      );
      await store.appendOccurrence(
        ownerId: ownerId,
        entityId: task.id,
        plannedFor: DateTime(2026, 7, 20, 9),
        status: 'completed',
      );
      await store.appendOccurrence(
        ownerId: ownerId,
        entityId: task.id,
        plannedFor: DateTime(2026, 7, 27, 9),
        status: 'completed',
      );
      await store.appendOccurrence(
        ownerId: ownerId,
        entityId: task.id,
        plannedFor: DateTime(2026, 7, 29, 9),
        status: 'missed',
      );

      final history = await store.readRecurrenceHistory(
        ownerId: ownerId,
        entity: task,
        day: DateTime(2026, 7, 30),
      );

      expect(history.completedInPeriod, 1);
      expect(history.totalCompleted, 2);
      expect(
        await store.countCompletedOccurrencesInFlexiblePeriod(
          ownerId: ownerId,
          entity: task,
          day: DateTime(2026, 7, 30),
        ),
        1,
      );
      final decision = await store.evaluateTodayEligibility(
        ownerId: ownerId,
        entity: task,
        day: DateTime(2026, 7, 30),
      );
      expect(decision.isEligible, isFalse);
    },
  );

  test(
    'legacy completed habit rows on one local day consume one quota slot',
    () async {
      const ownerId = 'owner-a';
      final monday = DateTime(2026, 7, 27, 8);
      final habit = PlannerEntity(
        id: 'acacacac-acac-4cac-8cac-acacacacacac',
        ownerId: ownerId,
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'One durable daily habit result'),
          PlannerPayloadKeys.timing: <String, dynamic>{
            'scheduled_at': monday.toUtc().toIso8601String(),
          },
          PlannerPayloadKeys.recurrence: <String, dynamic>{
            'rule': 'flexible',
            PlannerRecurrenceKeys.occurrenceLimit: 2,
            PlannerRecurrenceKeys.frequency: <String, dynamic>{
              PlannerRecurrenceKeys.frequencyCount: 2,
              PlannerRecurrenceKeys.frequencyPeriod: 'week',
            },
          },
        },
        createdAt: monday.toUtc(),
        updatedAt: monday.toUtc(),
      );
      await store.upsertEntity(
        entity: habit,
        mutationId: 'acacacac-1111-4111-8111-acacacacacac',
      );
      await store.appendOccurrence(
        ownerId: ownerId,
        entityId: habit.id,
        plannedFor: DateTime(2026, 7, 27, 9),
        status: 'completed',
      );
      await store.appendOccurrence(
        ownerId: ownerId,
        entityId: habit.id,
        plannedFor: DateTime(2026, 7, 27, 18),
        status: 'completed',
      );

      final history = await store.readRecurrenceHistory(
        ownerId: ownerId,
        entity: habit,
        day: DateTime(2026, 7, 29),
      );

      expect(history.completedInPeriod, 1);
      expect(history.totalCompleted, 1);
      expect(
        (await store.evaluateTodayEligibility(
          ownerId: ownerId,
          entity: habit,
          day: DateTime(2026, 7, 29),
        )).isEligible,
        isTrue,
      );
    },
  );

  test('Mark not done durably resolves an overdue ask recovery', () async {
    const ownerId = 'owner-a';
    final scheduled = DateTime(2026, 7, 25, 9);
    final task = PlannerEntity(
      id: 'cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd',
      ownerId: ownerId,
      kind: PlannerEntityKind.oneOffTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Decide this overdue task'),
        PlannerPayloadKeys.timing: <String, dynamic>{
          'scheduled_at': scheduled.toUtc().toIso8601String(),
        },
        PlannerPayloadKeys.recovery: const <String, dynamic>{
          PlannerRecoveryKeys.onMiss: 'ask',
        },
      },
      createdAt: DateTime(2026, 7, 20).toUtc(),
      updatedAt: DateTime(2026, 7, 20).toUtc(),
    );
    await store.upsertEntity(
      entity: task,
      mutationId: 'cdcdcdcd-1111-4111-8111-cdcdcdcdcdcd',
    );
    expect(
      (await store.evaluateTodayEligibility(
        ownerId: ownerId,
        entity: task,
        day: DateTime(2026, 7, 27, 10),
      )).requiresDecision,
      isTrue,
    );

    final resolved = await store.resolveOneOffRecovery(
      ownerId: ownerId,
      entityId: task.id,
      disposition: PlannerRecoveryDisposition.missed,
      occurrenceAt: scheduled,
      now: DateTime(2026, 7, 27, 10),
      mutationId: 'cdcdcdcd-2222-4222-8222-cdcdcdcdcdcd',
    );
    final current = await store.readEntity(ownerId: ownerId, entityId: task.id);

    expect(current!.status, PlannerEntityStatus.active);
    expect(
      safeJsonMap(
        current.recovery[PlannerRecoveryKeys.resolution],
      )[PlannerRecoveryKeys.disposition],
      'missed',
    );
    expect(
      (await store.evaluateTodayEligibility(
        ownerId: ownerId,
        entity: current,
        day: DateTime(2026, 7, 28, 10),
      )).isEligible,
      isFalse,
    );
    expect(
      resolved.operation.patch.values,
      contains(
        '/${PlannerPayloadKeys.recovery}/${PlannerRecoveryKeys.resolution}',
      ),
    );
  });

  test('owner-scoped primary keys keep equal entity ids isolated', () async {
    const sharedEntityId = 'shared-entity-id';
    final when = DateTime.utc(2026, 7, 27, 14);
    final ownerA = PlannerEntity(
      id: sharedEntityId,
      ownerId: 'owner-a',
      kind: PlannerEntityKind.project,
      payload: defaultPlannerPayload(title: 'Owner A project'),
      createdAt: when,
      updatedAt: when,
    );
    final ownerB = PlannerEntity(
      id: sharedEntityId,
      ownerId: 'owner-b',
      kind: PlannerEntityKind.project,
      payload: defaultPlannerPayload(title: 'Owner B project'),
      createdAt: when,
      updatedAt: when,
    );

    await store.upsertEntity(
      entity: ownerA,
      mutationId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    );
    await store.upsertEntity(
      entity: ownerB,
      mutationId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );
    await store.softDeleteEntity(
      ownerId: 'owner-b',
      entityId: sharedEntityId,
      mutationId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      now: when.add(const Duration(minutes: 1)),
    );

    expect(
      (await store.readActiveEntities('owner-a')).single.title,
      'Owner A project',
    );
    expect(await store.readActiveEntities('owner-b'), isEmpty);
    expect(
      (await store.readEntity(
        ownerId: 'owner-a',
        entityId: sharedEntityId,
      ))!.isDeleted,
      isFalse,
    );
  });

  test(
    'pending operations transition through retry and acknowledgement',
    () async {
      const ownerId = 'owner-a';
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Recover from a network failure',
        mutationId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        now: DateTime.utc(2026, 7, 27, 15),
      );

      final retried = await store.markOperationRetry(
        ownerId: ownerId,
        mutationId: created.operation.mutationId,
        error: 'network unavailable',
        now: DateTime.utc(2026, 7, 27, 15, 1),
      );
      expect(retried!.state, PlannerOperationState.retrying);
      expect(retried.attemptCount, 1);
      expect(retried.lastError, 'network unavailable');
      expect(await store.listPendingOperations(ownerId), hasLength(1));

      final acknowledged = await store.markOperationAcknowledged(
        ownerId: ownerId,
        mutationId: created.operation.mutationId,
        now: DateTime.utc(2026, 7, 27, 15, 2),
      );
      expect(acknowledged!.state, PlannerOperationState.acknowledged);
      expect(acknowledged.acknowledgedAt, DateTime.utc(2026, 7, 27, 15, 2));
      expect(await store.listPendingOperations(ownerId), isEmpty);

      final ignoredRetry = await store.markOperationRetry(
        ownerId: ownerId,
        mutationId: created.operation.mutationId,
        error: 'must not reopen an acknowledged operation',
      );
      expect(ignoredRetry, isNull);
    },
  );

  test(
    'a real sync conflict remains reviewable and has an explicit outcome',
    () async {
      final conflict = PlannerSyncConflict(
        id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        ownerId: 'owner-a',
        targetType: PlannerOperationTarget.entity,
        targetId: '11111111-1111-4111-8111-111111111111',
        mutationId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        fieldPaths: const <String>['/title'],
        localValue: const <String, dynamic>{'/title': 'Local title'},
        remoteValue: const <String, dynamic>{'title': 'Server title'},
        baseRevision: 2,
        remoteRevision: 3,
        createdAt: DateTime.utc(2026, 7, 27, 16),
      );
      await store.recordConflict(conflict);

      expect(
        await store.listConflicts('owner-a', status: 'open'),
        hasLength(1),
      );
      await store.resolveConflict(
        ownerId: 'owner-a',
        conflictId: conflict.id,
        resolution: 'kept_server',
        now: DateTime.utc(2026, 7, 27, 16, 1),
      );

      final resolved = (await store.listConflicts('owner-a')).single;
      expect(resolved.status, 'kept_server');
      expect(resolved.resolvedAt, DateTime.utc(2026, 7, 27, 16, 1));
    },
  );
}
