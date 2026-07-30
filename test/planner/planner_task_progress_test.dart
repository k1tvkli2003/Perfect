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
      final service = PlannerTaskProgressService(store, ownerId: ownerId);

      // The newer worker drains the ordered native queue.
      await service.applyWidgetAction(completed);
      await service.applyWidgetAction(missed);
      // An older overlapping worker finishes late with the first mutation ID.
      await service.applyWidgetAction(completed);

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
}
