import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';

/// RED tracer 1 — Stage 36: in-memory typed Tasks query projection.
///
/// This test defines the smallest complete vertical slice: Inbox/Open/
/// Scheduled/Completed views plus Unicode-aware search, all resolved from the
/// existing store rows through ONE shared projection (no widget-local second
/// predicate).
void main() {
  late PlannerDatabase database;
  late PlannerLocalStore store;

  setUp(() {
    database = PlannerDatabase(NativeDatabase.memory());
    store = PlannerLocalStore(database);
  });

  tearDown(() => store.close());

  Future<void> seedTasks() async {
    const ownerId = 'owner-a';
    final inbox = PlannerEntity(
      id: 'task-inbox',
      ownerId: ownerId,
      kind: PlannerEntityKind.oneOffTask,
      payload: <String, dynamic>{...defaultPlannerPayload(title: 'Buy milk')},
      createdAt: DateTime.utc(2026, 7, 27, 8),
      updatedAt: DateTime.utc(2026, 7, 27, 8),
    );
    final scheduled = PlannerEntity(
      id: 'task-scheduled',
      ownerId: ownerId,
      kind: PlannerEntityKind.oneOffTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'خرید کتاب فارسی'),
        PlannerPayloadKeys.timing: <String, dynamic>{
          'scheduled_at': '2026-07-28T09:00:00.000Z',
        },
        PlannerPayloadKeys.relations: <Map<String, dynamic>>[
          <String, dynamic>{'type': 'project', 'id': 'project-1'},
        ],
      },
      createdAt: DateTime.utc(2026, 7, 27, 9),
      updatedAt: DateTime.utc(2026, 7, 27, 9),
    );
    final done = PlannerEntity(
      id: 'task-done',
      ownerId: ownerId,
      kind: PlannerEntityKind.oneOffTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Pay the electricity bill'),
        PlannerPayloadKeys.status: PlannerEntityStatus.completed.wireValue,
        'category': 'Bills',
      },
      createdAt: DateTime.utc(2026, 7, 27, 10),
      updatedAt: DateTime.utc(2026, 7, 27, 10),
    );
    await store.upsertEntity(entity: inbox);
    await store.upsertEntity(entity: scheduled);
    await store.upsertEntity(entity: done);
  }

  test(
    'typed query projection resolves Inbox/Open/Scheduled without scans in build',
    () async {
      await seedTasks();
      final entities = await store.readActiveEntities('owner-a');

      final inbox = PlannerTaskQuery.builtIn(
        PlannerTaskQuery.inboxViewId,
      ).applyTo(entities);
      expect(inbox.entityIds, <String>['task-inbox']);

      final open = PlannerTaskQuery.builtIn(
        PlannerTaskQuery.openViewId,
      ).applyTo(entities);
      expect(open.entityIds.toSet(), <String>{'task-inbox', 'task-scheduled'});

      final scheduled = PlannerTaskQuery.builtIn(
        PlannerTaskQuery.scheduledViewId,
      ).applyTo(entities);
      expect(scheduled.entityIds, <String>['task-scheduled']);

      final completed = PlannerTaskQuery.builtIn(
        PlannerTaskQuery.completedViewId,
      ).applyTo(entities);
      expect(completed.entityIds, <String>['task-done']);
    },
  );

  test(
    'search is Unicode-aware and matches Persian, title, note, category',
    () async {
      await seedTasks();
      final entities = await store.readActiveEntities('owner-a');

      final persian = const PlannerTaskQuery(
        viewId: PlannerTaskQuery.openViewId,
        text: 'کتاب',
      ).applyTo(entities);
      expect(persian.entityIds, <String>['task-scheduled']);

      final noteOrTitle = const PlannerTaskQuery(
        viewId: PlannerTaskQuery.openViewId,
        text: 'MILK',
      ).applyTo(entities);
      expect(noteOrTitle.entityIds, <String>['task-inbox']);

      final category = const PlannerTaskQuery(
        viewId: PlannerTaskQuery.completedViewId,
        text: 'bills',
      ).applyTo(entities);
      expect(category.entityIds, <String>['task-done']);
    },
  );
}
