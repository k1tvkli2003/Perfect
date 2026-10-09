import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_task_keyboard.dart';

/// RED tracer 10 — Stage 36: Tasks keyboard/shortcut contract.
///
/// Esc clears search first, closes Refine second, exits selection third,
/// then defers to the shell. Ctrl+A selects the current result set only
/// while focus is in the work field. Shift+Arrow extends the stable range.
/// Space toggles the focused row. Slash/Ctrl+F focus search.
void main() {
  const ordered = <String>['a', 'b', 'c', 'd'];

  test('escape clears search before it closes Refine or selection', () {
    final state = PlannerTaskKeyboardState(
      searchText: 'bills',
      refineOpen: true,
      selectedIds: const {'a'},
    );

    final next = state.handle(PlannerTaskKeyEvent.escape);

    expect(next.searchText, isEmpty);
    expect(next.refineOpen, isTrue);
    expect(next.selectedIds, {'a'});
    expect(next.consumed, isTrue);
  });

  test('escape closes Refine before it exits selection', () {
    final state = PlannerTaskKeyboardState(
      searchText: '',
      refineOpen: true,
      selectedIds: const {'a'},
    );

    final next = state.handle(PlannerTaskKeyEvent.escape);

    expect(next.refineOpen, isFalse);
    expect(next.selectedIds, {'a'});
    expect(next.consumed, isTrue);
  });

  test('escape exits selection before it defers to the shell', () {
    final state = PlannerTaskKeyboardState(
      searchText: '',
      refineOpen: false,
      selectedIds: const {'a'},
    );

    final next = state.handle(PlannerTaskKeyEvent.escape);

    expect(next.selectedIds, isEmpty);
    expect(next.consumed, isTrue);

    final deferred = next.handle(PlannerTaskKeyEvent.escape);
    expect(deferred.consumed, isFalse);
  });

  test('select-all only applies while the work field has focus', () {
    final focused = PlannerTaskKeyboardState(
      workFieldFocused: true,
      orderedIds: ordered,
    );
    expect(focused.handle(PlannerTaskKeyEvent.selectAll).selectedIds, {
      'a',
      'b',
      'c',
      'd',
    });

    final unfocused = PlannerTaskKeyboardState(
      workFieldFocused: false,
      orderedIds: ordered,
    );
    final ignored = unfocused.handle(PlannerTaskKeyEvent.selectAll);
    expect(ignored.selectedIds, isEmpty);
    expect(ignored.consumed, isFalse);
  });

  test('shift+arrow extends the stable range from the anchor', () {
    final state = PlannerTaskKeyboardState(
      orderedIds: ordered,
      anchorId: 'b',
      selectedIds: const {'b'},
    );

    final next = state.handle(
      PlannerTaskKeyEvent.shiftArrow,
      direction: PlannerTaskArrowDirection.down,
    );

    expect(next.selectedIds, {'b', 'c'});
    expect(next.anchorId, 'c');
  });

  test('space toggles the focused row without changing the anchor', () {
    final state = PlannerTaskKeyboardState(
      orderedIds: ordered,
      focusedId: 'c',
      anchorId: 'b',
      selectedIds: const {'b'},
    );

    final next = state.handle(PlannerTaskKeyEvent.space);

    expect(next.selectedIds, {'b', 'c'});
    expect(next.anchorId, 'b');
  });
}
