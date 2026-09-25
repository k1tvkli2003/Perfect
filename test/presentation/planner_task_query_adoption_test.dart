import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

/// RED tracer 2 — Stage 36: the controller adopts the shared typed query.
///
/// The controller must resolve Tasks workspace reads through the ONE shared
/// [PlannerTaskQuery] projection over its cached task snapshot instead of
/// exposing a raw list for widget-local predicates.
void main() {
  test(
    'controller.queryTasks resolves through the shared query contract',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _AdoptionDisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => DateTime.utc(2026, 7, 27, 9),
      );
      addTearDown(controller.disposeAsync);

      const ownerId = 'controller-owner';
      await local.upsertEntity(
        entity: PlannerEntity(
          id: 'task-one-off',
          ownerId: ownerId,
          kind: PlannerEntityKind.oneOffTask,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Buy milk'),
          },
          createdAt: DateTime.utc(2026, 7, 27, 8),
          updatedAt: DateTime.utc(2026, 7, 27, 8),
        ),
      );
      await local.upsertEntity(
        entity: PlannerEntity(
          id: 'task-recurring',
          ownerId: ownerId,
          kind: PlannerEntityKind.recurringTask,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Gym session'),
          },
          createdAt: DateTime.utc(2026, 7, 27, 9),
          updatedAt: DateTime.utc(2026, 7, 27, 9),
        ),
      );
      await local.upsertEntity(
        entity: PlannerEntity(
          id: 'habit-water',
          ownerId: ownerId,
          kind: PlannerEntityKind.habit,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Drink water'),
          },
          createdAt: DateTime.utc(2026, 7, 27, 9),
          updatedAt: DateTime.utc(2026, 7, 27, 9),
        ),
      );

      await controller.start();
      for (var i = 0; i < 100 && controller.tasks.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(controller.tasks.map((entity) => entity.id).toSet(), <String>{
        'task-one-off',
        'task-recurring',
      });

      const query = PlannerTaskQuery(
        viewId: PlannerTaskQuery.openViewId,
        kinds: {PlannerEntityKind.recurringTask},
      );
      final result = controller.queryTasks(query);
      expect(result.entityIds, <String>['task-recurring']);
      expect(result.totalCount, 1);
      expect(
        result.entityIds,
        query.applyTo(controller.tasks).entityIds,
        reason:
            'controller must delegate to the shared projection, '
            'not a second predicate.',
      );
      expect(controller.entityById('task-recurring')?.title, 'Gym session');
      expect(controller.entityById('missing'), isNull);
    },
  );
}

class _AdoptionDisconnectedGateway implements PlannerRemoteGateway {
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
