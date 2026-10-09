import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';

/// RED tracer 8 — Stage 36: typed query summary for the lens/Refine surface.
///
/// The Refine surface must show an exact human-readable summary of the
/// active query before Apply. The summary is derived from the SAME typed
/// query object (never a second widget-local description), as removable
/// semantic tokens: one token per non-default constraint.
void main() {
  test('default open query summarizes as the view alone', () {
    final summary = PlannerTaskQuery(
      viewId: PlannerTaskQuery.openViewId,
    ).summary();

    expect(summary.viewLabel, 'Open');
    expect(summary.tokens, isEmpty);
    expect(summary.isDefault, isTrue);
  });

  test('non-default constraints become one token each', () {
    final summary = PlannerTaskQuery(
      viewId: PlannerTaskQuery.scheduledViewId,
      text: 'bills',
      kinds: const {PlannerEntityKind.recurringTask},
      groupBy: PlannerTaskGroup.project,
    ).summary();

    expect(summary.viewLabel, 'Scheduled');
    expect(summary.tokens, <String>[
      'Recurring only',
      '“bills”',
      'Grouped by Project',
    ]);
    expect(summary.isDefault, isFalse);
  });

  test('inbox/completed views label correctly with search token', () {
    final inbox = PlannerTaskQuery(
      viewId: PlannerTaskQuery.inboxViewId,
      text: 'کتاب',
    ).summary();
    expect(inbox.viewLabel, 'Inbox');
    expect(inbox.tokens, <String>['“کتاب”']);

    final completed = PlannerTaskQuery(
      viewId: PlannerTaskQuery.completedViewId,
    ).summary();
    expect(completed.viewLabel, 'Completed');
    expect(completed.tokens, isEmpty);
  });
}
