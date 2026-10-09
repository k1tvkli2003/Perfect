/// Stable-ID task selection for the Tasks workspace: Stage 36 contract.
///
/// Selection is keyed by stable entity ID, never list index. Range selection
/// walks the query's ordered ID list between two anchor IDs (either
/// direction). [prune] drops IDs that are no longer in the result or no
/// longer eligible and reports what changed so the UI can announce a
/// summary. [previewBulk] splits the current selection into eligible vs
/// skipped rows for the bulk confirmation surface without mutating the
/// selection itself.
class PlannerTaskSelection {
  const PlannerTaskSelection({this.ids = const <String>{}});

  const PlannerTaskSelection.empty() : ids = const <String>{};

  /// Selected stable entity IDs.
  final Set<String> ids;

  bool get isEmpty => ids.isEmpty;

  int get length => ids.length;

  /// Toggles one stable ID. Unknown IDs are accepted here — eligibility is
  /// enforced by [prune]/[selectAll]/[selectRange], not by the toggle — but
  /// this tracer keeps the pure contract strict: toggling the same ID twice
  /// returns to empty.
  PlannerTaskSelection toggle(String id) {
    final next = Set<String>.from(ids);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return PlannerTaskSelection(ids: next);
  }

  /// Replaces the selection with every eligible ID in [orderedIds].
  PlannerTaskSelection selectAll(
    List<String> orderedIds, {
    required bool Function(String id) isEligible,
  }) => PlannerTaskSelection(
    ids: {
      for (final id in orderedIds)
        if (isEligible(id)) id,
    },
  );

  /// Replaces the selection with the eligible IDs among [visibleIds]
  /// (e.g. one group's rows).
  PlannerTaskSelection selectVisible(
    List<String> visibleIds, {
    required bool Function(String id) isEligible,
  }) => PlannerTaskSelection(
    ids: {
      for (final id in visibleIds)
        if (isEligible(id)) id,
    },
  );

  /// Adds the eligible IDs between [fromId] and [toId] (inclusive, either
  /// direction) along [orderedIds] to the current selection. Unknown anchor
  /// IDs yield the current selection unchanged: no index math, no guessing.
  PlannerTaskSelection selectRange(
    List<String> orderedIds, {
    required String fromId,
    required String toId,
    required bool Function(String id) isEligible,
  }) {
    final from = orderedIds.indexOf(fromId);
    final to = orderedIds.indexOf(toId);
    if (from == -1 || to == -1) return this;
    final start = from < to ? from : to;
    final end = from < to ? to : from;
    final next = Set<String>.from(ids);
    for (var i = start; i <= end; i++) {
      final id = orderedIds[i];
      if (isEligible(id)) next.add(id);
    }
    return PlannerTaskSelection(ids: next);
  }

  /// Drops selected IDs that left [orderedIds] or fail [isEligible], and
  /// reports the removed IDs plus a human-readable summary for the
  /// announcement surface.
  PlannerSelectionPrune prune(
    List<String> orderedIds, {
    required bool Function(String id) isEligible,
  }) {
    final current = Set<String>.from(orderedIds);
    final removed = <String>{};
    final kept = <String>{};
    for (final id in ids) {
      if (current.contains(id) && isEligible(id)) {
        kept.add(id);
      } else {
        removed.add(id);
      }
    }
    return PlannerSelectionPrune(
      selection: PlannerTaskSelection(ids: kept),
      removedIds: removed,
    );
  }

  /// Splits the current selection into eligible vs skipped rows for the
  /// bulk confirmation surface. Pure: the selection itself is unchanged.
  PlannerBulkPreview previewBulk(
    List<String> orderedIds, {
    required bool Function(String id) isEligible,
  }) {
    final eligible = <String>[];
    final skipped = <String>[];
    for (final id in orderedIds) {
      if (!ids.contains(id)) continue;
      if (isEligible(id)) {
        eligible.add(id);
      } else {
        skipped.add(id);
      }
    }
    return PlannerBulkPreview(
      eligibleIds: List<String>.unmodifiable(eligible),
      skippedIds: List<String>.unmodifiable(skipped),
    );
  }
}

/// The result of [PlannerTaskSelection.prune]: the kept selection, the
/// removed IDs, and a summary string for the announcement surface.
class PlannerSelectionPrune {
  const PlannerSelectionPrune({
    required this.selection,
    required this.removedIds,
  });

  final PlannerTaskSelection selection;
  final Set<String> removedIds;

  String get summary => switch (removedIds.length) {
    0 => 'Selection unchanged.',
    1 => '1 selected item is no longer available and was removed.',
    _ =>
      '${removedIds.length} selected items are no longer available '
          'and were removed.',
  };
}

/// The result of [PlannerTaskSelection.previewBulk]: eligible vs skipped
/// stable IDs for the bulk confirmation surface.
class PlannerBulkPreview {
  const PlannerBulkPreview({
    required this.eligibleIds,
    required this.skippedIds,
  });

  final List<String> eligibleIds;
  final List<String> skippedIds;

  int get eligibleCount => eligibleIds.length;
  int get skippedCount => skippedIds.length;
}

/// Visible-selection state for the Tasks result rows (tracer 12).
///
/// The page keeps exactly one of these. Row taps toggle one stable ID;
/// [alignTo] keeps the selection keyed by ID across reorders and drops IDs
/// that left the current result set, reporting what changed for the
/// announcement surface. No list index is ever stored.
class PlannerTasksSelectionSurface {
  const PlannerTasksSelectionSurface({
    this.selectedIds = const <String>{},
    this.removedIds = const <String>{},
  });

  final Set<String> selectedIds;
  final Set<String> removedIds;

  bool isSelected(String id) => selectedIds.contains(id);

  PlannerTasksSelectionSurface toggle(String id) {
    final next = Set<String>.from(selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return PlannerTasksSelectionSurface(selectedIds: next);
  }

  PlannerTasksSelectionSurface alignTo(List<String> orderedIds) {
    final current = Set<String>.from(orderedIds);
    final kept = <String>{};
    final removed = <String>{};
    for (final id in selectedIds) {
      if (current.contains(id)) {
        kept.add(id);
      } else {
        removed.add(id);
      }
    }
    return PlannerTasksSelectionSurface(selectedIds: kept, removedIds: removed);
  }

  String get announcement => switch (removedIds.length) {
    0 => 'Selection unchanged.',
    1 => '1 selected item is no longer available and was removed.',
    _ =>
      '${removedIds.length} selected items are no longer available '
          'and were removed.',
  };
}
