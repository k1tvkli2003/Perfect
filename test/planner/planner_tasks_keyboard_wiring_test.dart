import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_task_keyboard.dart';

/// RED tracer 11 — Stage 36: Tasks keyboard wiring contract.
///
/// The widget must feed the live Tasks surface into the pure keyboard machine
/// and apply the returned state. Esc clears search before it closes Refine or
/// selection. Select-all only applies while the work field has focus. Space
/// toggles the focused row. Shift+Arrow extends the stable range.
void main() {
  test('wiring applies escape by clearing search first', () {
    final ordered = <String>['a', 'b', 'c'];
    final applied = applyTasksKeyboardEvent(
      event: PlannerTaskKeyEvent.escape,
      searchText: 'bills',
      refineOpen: true,
      selectedIds: const {'a'},
      orderedIds: ordered,
    );

    expect(applied.searchText, isEmpty);
    expect(applied.refineOpen, isTrue);
    expect(applied.selectedIds, {'a'});
    expect(applied.consumed, isTrue);
  });

  test('wiring ignores select-all when the work field is unfocused', () {
    final applied = applyTasksKeyboardEvent(
      event: PlannerTaskKeyEvent.selectAll,
      searchText: '',
      refineOpen: false,
      selectedIds: const <String>{},
      orderedIds: const ['a', 'b'],
      workFieldFocused: false,
    );

    expect(applied.selectedIds, isEmpty);
    expect(applied.consumed, isFalse);
  });

  test('wiring selects every ordered id while the work field is focused', () {
    final applied = applyTasksKeyboardEvent(
      event: PlannerTaskKeyEvent.selectAll,
      searchText: '',
      refineOpen: false,
      selectedIds: const <String>{},
      orderedIds: const ['a', 'b'],
      workFieldFocused: true,
    );

    expect(applied.selectedIds, {'a', 'b'});
    expect(applied.consumed, isTrue);
  });
}
