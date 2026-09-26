import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_task_bulk.dart';
import 'package:perfect/planner/domain/planner_task_bulk_scope.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

/// RED tracer 14 — Stage 36: controller executes a bulk receipt local-first.
///
/// The controller takes a frozen [PlannerTasksBulkReceipt], applies it only
/// to the previewed eligible IDs through the existing local-first mutation
/// paths (per-entity idempotency keys, no second hidden predicate), then
/// re-projects. Gone rows are skipped with the reason kept on the report.
void main() {
  test(
    'bulk complete applies to eligible rows and keeps skip reasons',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'bulk-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'bulk-owner',
        now: () => DateTime.utc(2026, 9, 26, 9),
      );
      addTearDown(controller.disposeAsync);
      await controller.start();

      Future<String> createTask(String title) async {
        final created = await local.createQuickTask(
          ownerId: 'bulk-owner',
          title: title,
          now: DateTime.utc(2026, 9, 26, 8),
        );
        return created.entity!.id;
      }

      final firstId = await createTask('First bulk task');
      final secondId = await createTask('Second bulk task');
      await controller.refresh();

      final receipt = planTasksBulk(
        orderedIds: [firstId, secondId, 'gone-id'],
        selectedIds: {firstId, secondId, 'gone-id'},
        isEligible: (id) => id != 'gone-id',
        skipReason: (_) => 'Task is no longer available locally.',
      ).execute(action: PlannerTasksBulkAction.complete);

      final report = await controller.applyBulkReceipt(receipt);

      expect(report.batchId, receipt.batchId);
      expect(report.appliedIds, [firstId, secondId]);
      expect(report.skippedIds, ['gone-id']);
      expect(report.skippedReasons['gone-id'], contains('no longer available'));
      expect(report.undoEligible, isTrue);

      for (final id in [firstId, secondId]) {
        final entity = await local.readEntity(
          ownerId: 'bulk-owner',
          entityId: id,
        );
        expect(entity, isNotNull);
        expect(
          PlannerTaskProgress.fromEntity(entity!).isComplete,
          isTrue,
          reason: 'Bulk complete must flow through the progress mutation path.',
        );
      }
    },
  );

  test('bulk archive tombstones previewed rows and re-projects', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'bulk-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'bulk-owner',
      now: () => DateTime.utc(2026, 9, 26, 9),
    );
    addTearDown(controller.disposeAsync);
    await controller.start();

    final created = await local.createQuickTask(
      ownerId: 'bulk-owner',
      title: 'Archive me in bulk',
      now: DateTime.utc(2026, 9, 26, 8),
    );
    final id = created.entity!.id;
    await controller.refresh();

    final receipt = planTasksBulk(
      orderedIds: [id],
      selectedIds: {id},
      isEligible: (_) => true,
      skipReason: (_) => '',
    ).execute(action: PlannerTasksBulkAction.archive);

    final report = await controller.applyBulkReceipt(receipt);

    expect(report.appliedIds, [id]);
    expect(
      await local.readEntity(ownerId: 'bulk-owner', entityId: id),
      isNull,
      reason: 'Archived rows leave the active projection.',
    );
    expect(await local.readArchivedEntities('bulk-owner'), hasLength(1));
  });

  // RED tracer 17: Undo must restore the exact prior outcome only while the
  // bulk write is still authoritative; a newer tap expires it.
  test(
    'bulk complete undo restores prior progress then expires on newer tap',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'bulk-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'bulk-owner',
        now: () => DateTime.utc(2026, 9, 26, 9),
      );
      addTearDown(controller.disposeAsync);
      await controller.start();

      final created = await local.createQuickTask(
        ownerId: 'bulk-owner',
        title: 'Undoable bulk task',
        now: DateTime.utc(2026, 9, 26, 8),
      );
      final taskId = created.entity!.id;
      await controller.refresh();

      final receipt = planVisibleTasksBulk(
        orderedIds: [taskId],
        selectedIds: {taskId},
        action: PlannerTasksBulkAction.complete,
        entityById: controller.entityById,
      ).execute(action: PlannerTasksBulkAction.complete);
      final report = await controller.applyBulkReceipt(receipt);
      expect(report.undoEligible, isTrue);

      var entity = (await local.readEntity(
        ownerId: 'bulk-owner',
        entityId: taskId,
      ))!;
      expect(PlannerTaskProgress.fromEntity(entity).isComplete, isTrue);

      final restored = await controller.undoBulkReceipt(report);
      expect(restored, isTrue);
      entity = (await local.readEntity(
        ownerId: 'bulk-owner',
        entityId: taskId,
      ))!;
      expect(PlannerTaskProgress.fromEntity(entity).isComplete, isFalse);

      // A newer single-row tap after a fresh bulk write expires that bulk Undo.
      final receipt2 = planVisibleTasksBulk(
        orderedIds: [taskId],
        selectedIds: {taskId},
        action: PlannerTasksBulkAction.complete,
        entityById: controller.entityById,
      ).execute(action: PlannerTasksBulkAction.complete);
      final report2 = await controller.applyBulkReceipt(receipt2);
      final stored = (await local.readEntity(
        ownerId: 'bulk-owner',
        entityId: taskId,
      ))!;
      await controller.cycleTaskProgressWithReceipt(stored);
      expect(await controller.undoBulkReceipt(report2), isFalse);
    },
  );
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
