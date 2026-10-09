import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_task_selection.dart';

/// RED tracer 12 — Stage 36: visible Tasks selection surface.
///
/// The Tasks page must hold a stable-ID selection and expose it on the
/// result rows. Toggling a row changes only that ID. A second toggle clears
/// it. The surface never stores list indices.
void main() {
  test('surface toggle selects then clears one stable ID', () {
    var surface = const PlannerTasksSelectionSurface();

    surface = surface.toggle('task-b');
    expect(surface.selectedIds, {'task-b'});
    expect(surface.isSelected('task-b'), isTrue);
    expect(surface.isSelected('task-a'), isFalse);

    surface = surface.toggle('task-b');
    expect(surface.selectedIds, isEmpty);
    expect(surface.isSelected('task-b'), isFalse);
  });

  test('surface keeps selection across a result reorder', () {
    final surface = const PlannerTasksSelectionSurface().toggle('task-c');

    final afterReorder = surface.alignTo(const ['task-c', 'task-a', 'task-b']);

    expect(afterReorder.selectedIds, {'task-c'});
    expect(afterReorder.isSelected('task-c'), isTrue);
  });

  test('surface drops an ID that left the result set and reports it', () {
    final surface = const PlannerTasksSelectionSurface()
        .toggle('task-a')
        .toggle('task-gone');

    final aligned = surface.alignTo(const ['task-a', 'task-b']);

    expect(aligned.selectedIds, {'task-a'});
    expect(aligned.removedIds, {'task-gone'});
    expect(aligned.announcement, contains('1'));
  });
}
