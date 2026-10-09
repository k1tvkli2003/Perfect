import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_tasks_copy.dart';

/// RED tracer 9 — Stage 36: pg-tasks Copy fidelity receipt.
///
/// The accepted `pg-tasks-default` composition (copy.json, 8 live entries)
/// is the exact runtime contract for the workspace crown. The widget must
/// render these verbatim strings — no paraphrase, no second copy.
void main() {
  test('default crown matches accepted pg-tasks-default live copy', () {
    expect(PlannerTasksCopy.defaultTitle, 'Tasks');
    expect(
      PlannerTasksCopy.defaultSubtitle,
      'Search, filter and act without losing the working context.',
    );
  });

  test('bulk/search/dense/filtered titles match their accepted pages', () {
    expect(PlannerTasksCopy.titleFor('pg-tasks-search'), 'Search tasks');
    expect(PlannerTasksCopy.titleFor('pg-tasks-filtered'), 'Filtered tasks');
    expect(PlannerTasksCopy.titleFor('pg-tasks-dense'), 'Dense task workspace');
    expect(PlannerTasksCopy.titleFor('pg-tasks-bulk'), 'Bulk task actions');
  });

  test('unknown page falls back to the default crown, never empty', () {
    expect(PlannerTasksCopy.titleFor('pg-tasks-unknown'), 'Tasks');
  });
}
