import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_task_bulk.dart';

/// RED tracer 13 — Stage 36: bulk action receipt contract.
///
/// A bulk run must preview eligible vs skipped rows first, then execute only
/// the previewed eligible IDs with one idempotency key per entity, and return
/// a receipt with batchId, per-entity results, skipped reasons and Undo
/// eligibility. A batch that never executes returns a preview-only receipt
/// with no mutation keys issued.
void main() {
  test('preview splits eligible vs skipped without issuing keys', () {
    final plan = planTasksBulk(
      orderedIds: const ['a', 'b', 'c'],
      selectedIds: const {'a', 'b', 'c'},
      isEligible: (id) => id != 'c',
      skipReason: (id) => 'Archived on another device.',
    );

    expect(plan.eligibleIds, ['a', 'b']);
    expect(plan.skippedIds, ['c']);
    expect(plan.skippedReasons['c'], contains('Archived'));
    expect(plan.issuedKeys, isEmpty);
    expect(plan.executed, isFalse);
  });

  test('executing issues one idempotency key per eligible entity', () {
    final plan = planTasksBulk(
      orderedIds: const ['a', 'b', 'c'],
      selectedIds: const {'a', 'b', 'c'},
      isEligible: (id) => id != 'c',
      skipReason: (id) => 'Archived on another device.',
    );

    final run = plan.execute(action: PlannerTasksBulkAction.complete);

    expect(run.batchId, isNotEmpty);
    expect(run.action, PlannerTasksBulkAction.complete);
    expect(run.appliedIds, ['a', 'b']);
    expect(run.perEntityKeys.keys.toSet(), {'a', 'b'});
    expect(run.perEntityKeys.values.toSet(), hasLength(2));
    expect(run.eligibleCount, 2);
    expect(run.skippedCount, 1);
    expect(run.undoEligible, isTrue);
  });

  test('empty selection returns a no-op receipt with undo disabled', () {
    final run = planTasksBulk(
      orderedIds: const ['a'],
      selectedIds: const <String>{},
      isEligible: (_) => true,
      skipReason: (_) => '',
    ).execute(action: PlannerTasksBulkAction.archive);

    expect(run.appliedIds, isEmpty);
    expect(run.perEntityKeys, isEmpty);
    expect(run.undoEligible, isFalse);
  });
}
