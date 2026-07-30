import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:perfect/widgets/perfect_today_widget_background.dart';

void main() {
  test(
    'durable replay preserves tap order when the wall clock moves backwards',
    () async {
      const ownerId = 'private-owner';
      final database = PlannerDatabase(NativeDatabase.memory());
      final store = PlannerLocalStore(database);
      addTearDown(store.close);
      final day = DateTime(2026, 7, 28);
      final entity = PlannerEntity(
        id: 'clock-safe-widget-task',
        ownerId: ownerId,
        kind: PlannerEntityKind.recurringTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Clock-safe replay'),
          PlannerPayloadKeys.recurrence: const <String, dynamic>{
            'rule': 'daily',
          },
        },
        createdAt: DateTime.utc(2026, 7, 28, 8),
        updatedAt: DateTime.utc(2026, 7, 28, 8),
      );
      await store.upsertEntity(entity: entity);
      final firstTap = PlannerWidgetTaskAction(
        id: '11111111-aaaa-4bbb-8ccc-111111111111',
        ownerId: ownerId,
        entityId: entity.id,
        kind: entity.kind,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
        localDay: day,
        occurredAt: DateTime.utc(2026, 7, 28, 12, 30),
        queueSequence: 91,
      );
      final finalTap = PlannerWidgetTaskAction(
        id: '22222222-aaaa-4bbb-8ccc-222222222222',
        ownerId: ownerId,
        entityId: entity.id,
        kind: entity.kind,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.missed,
          percent: 0,
        ),
        localDay: day,
        occurredAt: DateTime.utc(2026, 7, 28, 11, 30),
        queueSequence: 92,
      );

      await replayPerfectTodayWidgetActions(
        store: store,
        ownerId: ownerId,
        actions: <PlannerWidgetTaskAction>[finalTap, firstTap],
      );

      final occurrence = await store.readOccurrence(
        ownerId: ownerId,
        occurrenceId: PlannerTaskProgressService.recurringOccurrenceId(
          entity,
          day,
        ),
      );
      expect(PlannerTaskProgress.fromOccurrence(occurrence).isMissed, isTrue);
    },
  );

  test('quick add replay is scheduled, local-first, and idempotent', () async {
    const ownerId = 'private-owner';
    final database = PlannerDatabase(NativeDatabase.memory());
    final store = PlannerLocalStore(database);
    addTearDown(store.close);
    final request = PerfectTodayWidgetQuickAdd(
      id: 'abababab-abab-4bab-8bab-abababababab',
      ownerId: ownerId,
      title: 'Review the release notes',
      occurredAt: DateTime.utc(2026, 7, 30, 8),
      scheduledAt: DateTime.utc(2026, 7, 30, 16, 30),
    );

    await replayPerfectTodayWidgetQuickAdds(
      store: store,
      ownerId: ownerId,
      requests: <PerfectTodayWidgetQuickAdd>[request, request],
    );
    await replayPerfectTodayWidgetQuickAdds(
      store: store,
      ownerId: ownerId,
      requests: <PerfectTodayWidgetQuickAdd>[request],
    );

    final entities = await store.readActiveEntities(ownerId);
    expect(entities, hasLength(1));
    expect(entities.single.kind, PlannerEntityKind.oneOffTask);
    expect(entities.single.title, 'Review the release notes');
    expect(entities.single.scheduledAt, DateTime.utc(2026, 7, 30, 16, 30));
    expect(await store.listPendingOperations(ownerId), hasLength(1));
  });
}
