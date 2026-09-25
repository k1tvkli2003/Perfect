import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_task_selection.dart';

/// RED tracer 7 — Stage 36: stable-ID selection contract.
///
/// Selection is keyed by stable entity ID, never list index: range selection
/// walks the query's ordered ID list, and every result change prunes
/// now-ineligible IDs with an announced summary instead of silently keeping
/// stale rows.
void main() {
  const orderedIds = <String>['task-a', 'task-b', 'task-c', 'task-d'];

  test('toggle and clear keep stable IDs', () {
    var selection = const PlannerTaskSelection.empty().toggle('task-a');
    expect(selection.ids, <String>{'task-a'});

    selection = selection.toggle('task-a');
    expect(selection.ids, isEmpty);
  });

  test('selectAll and selectVisible scope to eligible IDs only', () {
    const eligible = {'task-a', 'task-c'};

    final all = const PlannerTaskSelection.empty().selectAll(
      orderedIds,
      isEligible: eligible.contains,
    );
    expect(all.ids, <String>{'task-a', 'task-c'});

    final visible = const PlannerTaskSelection.empty().selectVisible(const [
      'task-b',
      'task-c',
      'task-d',
    ], isEligible: eligible.contains);
    expect(visible.ids, <String>{'task-c'});
  });

  test('range selection walks ordered IDs, not indices', () {
    const selection = PlannerTaskSelection.empty();

    final forward = selection.selectRange(
      orderedIds,
      fromId: 'task-b',
      toId: 'task-d',
      isEligible: (_) => true,
    );
    expect(forward.ids, <String>{'task-b', 'task-c', 'task-d'});

    final reversed = selection.selectRange(
      orderedIds,
      fromId: 'task-d',
      toId: 'task-b',
      isEligible: (_) => true,
    );
    expect(reversed.ids, forward.ids);

    final anchored = selection.selectRange(
      orderedIds,
      fromId: 'task-b',
      toId: 'task-d',
      isEligible: (id) => id != 'task-c',
    );
    expect(anchored.ids, <String>{'task-b', 'task-d'});
  });

  test('prune drops ineligible IDs and reports what changed', () {
    const selection = PlannerTaskSelection(
      ids: {'task-a', 'task-b', 'task-archived'},
    );

    final pruned = selection.prune(
      orderedIds,
      isEligible: (id) => id != 'task-archived' && id != 'task-b',
    );

    expect(pruned.selection.ids, <String>{'task-a'});
    expect(pruned.removedIds, <String>{'task-b', 'task-archived'});
    expect(pruned.summary, contains('2'));
  });

  test('bulk preview counts eligible vs skipped without mutating', () {
    const selection = PlannerTaskSelection(ids: {'task-a', 'task-b'});

    final preview = selection.previewBulk(const [
      'task-a',
      'task-b',
      'task-c',
    ], isEligible: (id) => id != 'task-b');

    expect(preview.eligibleIds, <String>['task-a']);
    expect(preview.skippedIds, <String>['task-b']);
    expect(selection.ids, <String>{'task-a', 'task-b'});
  });
}
