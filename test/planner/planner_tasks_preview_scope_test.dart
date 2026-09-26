import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_bulk.dart';
import 'package:perfect/planner/domain/planner_task_bulk_scope.dart';

/// RED tracer 16 - Stage 36: eligibility-scoped bulk helper.
///
/// The Tasks page builds preview and bar counts from ONE
/// eligibility rule. This pins: the helper keeps ordered stable
/// IDs, splits eligible vs skipped with per-row reasons, issues no
/// keys, and execute freezes one UUID-v5 key per eligible row.
PlannerEntity _task(String id, PlannerEntityStatus status) {
  final now = DateTime.utc(2026, 9, 26, 8);
  return PlannerEntity(
    id: id,
    ownerId: 'scope-owner',
    kind: PlannerEntityKind.oneOffTask,
    payload: <String, dynamic>{
      ...defaultPlannerPayload(title: 'Task $id'),
      PlannerPayloadKeys.status: status.wireValue,
    },
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('preview keeps order and splits eligible vs skipped', () {
    final byId = <String, PlannerEntity>{
      'id-a': _task('id-a', PlannerEntityStatus.active),
      'id-b': _task('id-b', PlannerEntityStatus.active),
      'id-c': _task('id-c', PlannerEntityStatus.completed),
    };
    final plan = planVisibleTasksBulk(
      orderedIds: const <String>['id-b', 'id-a', 'id-c'],
      selectedIds: const <String>{'id-b', 'id-a', 'id-c'},
      action: PlannerTasksBulkAction.complete,
      entityById: (id) => byId[id],
    );
    expect(plan.eligibleIds, <String>['id-b', 'id-a']);
    expect(plan.skippedIds, <String>['id-c']);
    expect(plan.skippedReasons['id-c'], contains('Only open tasks'));
    expect(plan.issuedKeys, isEmpty);
    expect(plan.executed, isFalse);
  });

  test('execute freezes one key per eligible row only', () {
    final byId = <String, PlannerEntity>{
      'id-a': _task('id-a', PlannerEntityStatus.active),
      'id-b': _task('id-b', PlannerEntityStatus.active),
    };
    final receipt = planVisibleTasksBulk(
      orderedIds: const <String>['id-b', 'id-a'],
      selectedIds: const <String>{'id-b', 'id-a'},
      action: PlannerTasksBulkAction.complete,
      entityById: (id) => byId[id],
    ).execute(action: PlannerTasksBulkAction.complete);
    expect(receipt.appliedIds, <String>['id-b', 'id-a']);
    expect(receipt.perEntityKeys.keys.toSet(), <String>{'id-a', 'id-b'});
    expect(receipt.skippedIds, isEmpty);
    expect(receipt.undoEligible, isTrue);
  });

  test('gone rows stay skipped with a local reason', () {
    final byId = <String, PlannerEntity>{
      'id-a': _task('id-a', PlannerEntityStatus.active),
    };
    final plan = planVisibleTasksBulk(
      orderedIds: const <String>['id-a', 'gone-id'],
      selectedIds: const <String>{'id-a', 'gone-id'},
      action: PlannerTasksBulkAction.complete,
      entityById: (id) => byId[id],
    );
    expect(plan.eligibleIds, <String>['id-a']);
    expect(plan.skippedIds, <String>['gone-id']);
    expect(plan.skippedReasons['gone-id'], contains('no longer available'));
  });
}
