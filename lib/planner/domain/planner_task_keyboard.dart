/// Tasks keyboard/shortcut contract: Stage 36.
///
/// Pure state machine over the workspace keyboard surface. Esc consumes in
/// order: clear search, close Refine, exit selection, then defer to the
/// shell. Select-all applies only while the work field has focus.
/// Shift+Arrow extends the stable ID range. Space toggles the focused row.
enum PlannerTaskKeyEvent { escape, selectAll, shiftArrow, space }

enum PlannerTaskArrowDirection { up, down }

class PlannerTaskKeyboardState {
  const PlannerTaskKeyboardState({
    this.searchText = '',
    this.refineOpen = false,
    this.selectedIds = const <String>{},
    this.workFieldFocused = false,
    this.orderedIds = const <String>[],
    this.anchorId,
    this.focusedId,
    this.consumed = false,
  });

  final String searchText;
  final bool refineOpen;
  final Set<String> selectedIds;
  final bool workFieldFocused;
  final List<String> orderedIds;
  final String? anchorId;
  final String? focusedId;
  final bool consumed;

  PlannerTaskKeyboardState handle(
    PlannerTaskKeyEvent event, {
    PlannerTaskArrowDirection direction = PlannerTaskArrowDirection.down,
  }) {
    switch (event) {
      case PlannerTaskKeyEvent.escape:
        return _escape();
      case PlannerTaskKeyEvent.selectAll:
        return _selectAll();
      case PlannerTaskKeyEvent.shiftArrow:
        return _shiftArrow(direction);
      case PlannerTaskKeyEvent.space:
        return _space();
    }
  }

  PlannerTaskKeyboardState _escape() {
    if (searchText.isNotEmpty) {
      return _copy(searchText: '', consumed: true);
    }
    if (refineOpen) {
      return _copy(refineOpen: false, consumed: true);
    }
    if (selectedIds.isNotEmpty) {
      return _copy(selectedIds: const <String>{}, consumed: true);
    }
    return _copy(consumed: false);
  }

  PlannerTaskKeyboardState _selectAll() {
    if (!workFieldFocused) return _copy(consumed: false);
    return _copy(selectedIds: orderedIds.toSet(), consumed: true);
  }

  PlannerTaskKeyboardState _shiftArrow(PlannerTaskArrowDirection direction) {
    final anchor = anchorId;
    if (anchor == null) return _copy(consumed: false);
    final index = orderedIds.indexOf(anchor);
    if (index == -1) return _copy(consumed: false);
    final delta = direction == PlannerTaskArrowDirection.down ? 1 : -1;
    final nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= orderedIds.length) {
      return _copy(consumed: false);
    }
    final nextId = orderedIds[nextIndex];
    return _copy(
      selectedIds: {...selectedIds, nextId},
      anchorId: nextId,
      consumed: true,
    );
  }

  PlannerTaskKeyboardState _space() {
    final focused = focusedId;
    if (focused == null) return _copy(consumed: false);
    final next = Set<String>.from(selectedIds);
    if (next.contains(focused)) {
      next.remove(focused);
    } else {
      next.add(focused);
    }
    return _copy(selectedIds: next, consumed: true);
  }

  PlannerTaskKeyboardState _copy({
    String? searchText,
    bool? refineOpen,
    Set<String>? selectedIds,
    bool? workFieldFocused,
    List<String>? orderedIds,
    String? anchorId,
    String? focusedId,
    bool? consumed,
  }) => PlannerTaskKeyboardState(
    searchText: searchText ?? this.searchText,
    refineOpen: refineOpen ?? this.refineOpen,
    selectedIds: selectedIds ?? this.selectedIds,
    workFieldFocused: workFieldFocused ?? this.workFieldFocused,
    orderedIds: orderedIds ?? this.orderedIds,
    anchorId: anchorId ?? this.anchorId,
    focusedId: focusedId ?? this.focusedId,
    consumed: consumed ?? this.consumed,
  );
}
