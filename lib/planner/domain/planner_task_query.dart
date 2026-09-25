import 'package:perfect/planner/domain/planner_entity.dart';

/// A typed Tasks workspace query: one shared projection contract.
///
/// The widget-local `_TaskFilter` path filters an in-memory controller list
/// inside `build()`. This contract replaces that path: one typed query object
/// resolves views plus normalized search over a supplied entity snapshot, so
/// no consumer applies a second hidden predicate after the result.
///
/// Scope of this tracer: the four built-in lifecycle views (`inbox`, `open`,
/// `scheduled`, `completed`) plus Unicode-aware search over the same three
/// fields the old widget path searched (title, note, category). Sort, group,
/// saved views, selection and bulk actions arrive in later tracers.
class PlannerTaskQuery {
  const PlannerTaskQuery({
    required this.viewId,
    this.text = '',
    this.kinds = const <PlannerEntityKind>{},
  });

  static const String inboxViewId = 'inbox';
  static const String openViewId = 'open';
  static const String scheduledViewId = 'scheduled';
  static const String completedViewId = 'completed';

  static const Set<String> builtInViewIds = <String>{
    inboxViewId,
    openViewId,
    scheduledViewId,
    completedViewId,
  };

  /// The built-in lifecycle view this query resolves.
  final String viewId;

  /// Raw user search text. Normalization happens inside [applyTo].
  final String text;

  /// Optional kind scope. Empty means no kind predicate; the caller supplies
  /// the right snapshot (the controller passes its task-kind snapshot, so the
  /// query stays a pure projection over whatever it receives).
  final Set<PlannerEntityKind> kinds;

  /// The built-in query for a lifecycle view with no search text.
  factory PlannerTaskQuery.builtIn(String viewId) {
    if (!builtInViewIds.contains(viewId)) {
      throw ArgumentError.value(viewId, 'viewId', 'unknown built-in view');
    }
    return PlannerTaskQuery(viewId: viewId);
  }

  /// Resolves the query over an entity snapshot into ordered stable IDs.
  ///
  /// Pure projection: no store access, no mutation. Ordering is deterministic
  /// (scheduled first by `scheduled_at`, then case-insensitive title, then
  /// stable ID tie-break), so any input order settles to the same result.
  PlannerTaskQueryResult applyTo(List<PlannerEntity> entities) {
    final normalizedNeedle = _normalizeSearch(text);
    final matched = <PlannerEntity>[];
    final facets = <String, int>{
      for (final viewId in builtInViewIds) viewId: 0,
    };
    for (final entity in entities) {
      if (kinds.isNotEmpty && !kinds.contains(entity.kind)) continue;
      if (normalizedNeedle.isNotEmpty &&
          !_matchesSearch(entity, normalizedNeedle)) {
        continue;
      }
      for (final viewId in builtInViewIds) {
        if (_matchesViewId(viewId, entity)) {
          facets[viewId] = facets[viewId]! + 1;
        }
      }
      if (!_matchesView(entity)) continue;
      matched.add(entity);
    }
    matched.sort(_compareDeterministic);
    final ids = <String>[for (final entity in matched) entity.id];
    return PlannerTaskQueryResult(
      entityIds: List<String>.unmodifiable(ids),
      totalCount: ids.length,
      facetCounts: Map<String, int>.unmodifiable(facets),
    );
  }

  /// Deterministic ordering: scheduled rows first (earliest `scheduled_at`),
  /// then case-insensitive title, then stable ID. Unscheduled rows sort after
  /// every scheduled row regardless of title.
  static int _compareDeterministic(PlannerEntity a, PlannerEntity b) {
    final aScheduled = a.scheduledAt;
    final bScheduled = b.scheduledAt;
    if (aScheduled != null || bScheduled != null) {
      if (aScheduled == null) return 1;
      if (bScheduled == null) return -1;
      final scheduled = aScheduled.compareTo(bScheduled);
      if (scheduled != 0) return scheduled;
    }
    final title = _normalizeSearch(
      a.title,
    ).compareTo(_normalizeSearch(b.title));
    if (title != 0) return title;
    return a.id.compareTo(b.id);
  }

  bool _matchesView(PlannerEntity entity) => _matchesViewId(viewId, entity);

  static bool _matchesViewId(
    String viewId,
    PlannerEntity entity,
  ) => switch (viewId) {
    inboxViewId =>
      entity.status == PlannerEntityStatus.active && entity.scheduledAt == null,
    openViewId => entity.status == PlannerEntityStatus.active,
    scheduledViewId =>
      entity.status == PlannerEntityStatus.active && entity.scheduledAt != null,
    completedViewId => entity.status == PlannerEntityStatus.completed,
    _ => throw StateError('unknown built-in view: $viewId'),
  };

  bool _matchesSearch(PlannerEntity entity, String normalizedNeedle) {
    final haystack = _normalizeSearch(
      '${entity.title} ${entity.note ?? ''} '
      '${safeNullableJsonString(entity.payload['category']) ?? ''}',
    );
    return haystack.contains(normalizedNeedle);
  }

  /// Unicode-aware, case-insensitive normalization.
  ///
  /// Persian text is preserved as-is (no transliteration, no stripping);
  /// `toLowerCase` handles Latin case folding and leaves Persian/Arabic
  /// script untouched, so both scripts match without a second code path.
  static String _normalizeSearch(String value) => value.trim().toLowerCase();
}

/// The resolved result of a [PlannerTaskQuery].
///
/// Later tracers add group descriptors, source revision and continuation
/// cursors. This tracer carries ordered stable IDs plus the total count and
/// per-view facet counts (computed under the same kind/text scope), which
/// lets the workspace crown show result counts for every view from ONE
/// shared projection instead of re-filtering per tab.
class PlannerTaskQueryResult {
  const PlannerTaskQueryResult({
    required this.entityIds,
    required this.totalCount,
    required this.facetCounts,
  });

  /// Ordered stable entity IDs matching the query.
  final List<String> entityIds;

  /// Total matches before any pagination (no pagination yet).
  final int totalCount;

  /// Per built-in view ID: matches under the same kind/text scope.
  final Map<String, int> facetCounts;
}
