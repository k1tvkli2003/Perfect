import 'package:perfect/planner/domain/planner_entity.dart';

/// A typed Tasks workspace query: one shared projection contract.
///
/// The widget-local `_TaskFilter` path filters an in-memory controller list
/// inside `build()`. This contract replaces that path: one typed query object
/// resolves views plus normalized search over a supplied entity snapshot, so
/// no consumer applies a second hidden predicate after the result.
///
/// Stable grouping for the Tasks work field: None, Schedule, Project, Area,
/// Category, Priority and Status. Empty groups are omitted from results; an
/// explicit `Unassigned` group carries rows with no value rather than an
/// empty-string heading.
enum PlannerTaskGroup {
  none('none'),
  schedule('schedule'),
  project('project'),
  area('area'),
  category('category'),
  priority('priority'),
  status('status');

  const PlannerTaskGroup(this.wireValue);

  final String wireValue;

  /// Unknown wire values fall back to [none]: grouping must never silently
  /// scatter rows into an unexpected layout.
  static PlannerTaskGroup fromWire(Object? value) =>
      PlannerTaskGroup.values.firstWhere(
        (group) => group.wireValue == value,
        orElse: () => PlannerTaskGroup.none,
      );
}

/// Sort mode for the Tasks work field: which deterministic ordering the
/// shared projection applies. Membership is untouched — the mode only
/// reorders the SAME resolved rows, so sort can never act as a second
/// hidden predicate.
enum PlannerTaskSortMode {
  scheduled('scheduled'),
  title('title'),
  recent('recent');

  const PlannerTaskSortMode(this.wireValue);

  final String wireValue;

  /// Unknown wire values fall back to [scheduled] (the long-standing
  /// default): sort must never throw on a newer client's value.
  static PlannerTaskSortMode fromWire(Object? value) =>
      PlannerTaskSortMode.values.firstWhere(
        (mode) => mode.wireValue == value,
        orElse: () => PlannerTaskSortMode.scheduled,
      );
}

/// A typed Tasks workspace query: one shared projection contract.
///
/// The widget-local `_TaskFilter` path filters an in-memory controller list
/// inside `build()`. This contract replaces that path: one typed query object
/// resolves views plus normalized search over a supplied entity snapshot, so
/// no consumer applies a second hidden predicate after the result.
///
/// Scope of this tracer: the four built-in lifecycle views (`inbox`, `open`,
/// `scheduled`, `completed`) plus Unicode-aware search over the same three
/// fields the old widget path searched (title, note, category), deterministic
/// ordering, per-view facet counts and stable grouping. Selection and bulk
/// actions arrive in later tracers.
class PlannerTaskQuery {
  const PlannerTaskQuery({
    required this.viewId,
    this.text = '',
    this.kinds = const <PlannerEntityKind>{},
    this.groupBy = PlannerTaskGroup.none,
    this.sortMode = PlannerTaskSortMode.scheduled,
    this.unknownFields = const <String, dynamic>{},
  });

  static const String inboxViewId = 'inbox';
  static const String openViewId = 'open';
  static const String scheduledViewId = 'scheduled';
  static const String recurringViewId = 'recurring';
  static const String completedViewId = 'completed';

  static const Set<String> builtInViewIds = <String>{
    inboxViewId,
    openViewId,
    scheduledViewId,
    recurringViewId,
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

  /// Stable grouping for the result. [PlannerTaskGroup.none] keeps the flat
  /// ordered ID list; any other value also emits [PlannerTaskQueryResult]
  /// group descriptors in display order (empty groups omitted).
  final PlannerTaskGroup groupBy;

  /// Which deterministic ordering the shared projection applies. Reorders
  /// the SAME resolved rows; membership is untouched.
  final PlannerTaskSortMode sortMode;

  /// Forward-compatible fields a newer client may have written; preserved
  /// verbatim through [toJson] so older clients never drop newer data.
  final Map<String, dynamic> unknownFields;

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
    matched.sort(_compareDeterministic(sortMode));
    final ids = <String>[for (final entity in matched) entity.id];
    final groups = _groupMatched(matched);
    return PlannerTaskQueryResult(
      entityIds: List<String>.unmodifiable(ids),
      totalCount: ids.length,
      facetCounts: Map<String, int>.unmodifiable(facets),
      groups: List<PlannerTaskGroupResult>.unmodifiable(groups),
    );
  }

  /// Emits group descriptors in display order for [groupBy]. [none] yields
  /// no groups. Empty groups are omitted; rows without a value land in an
  /// explicit `Unassigned` group. Members keep the same deterministic
  /// ordering as the flat result.
  List<PlannerTaskGroupResult> _groupMatched(List<PlannerEntity> matched) {
    if (groupBy == PlannerTaskGroup.none || matched.isEmpty) {
      return const <PlannerTaskGroupResult>[];
    }
    final memberIds = <String, List<String>>{};
    final titles = <String, String>{};
    for (final entity in matched) {
      final slot = _groupSlot(entity);
      (memberIds[slot.key] ??= <String>[]).add(entity.id);
      titles.putIfAbsent(slot.key, () => slot.title);
    }
    final order = _groupDisplayOrder(
      memberIds.keys.toList(growable: false),
      titles,
    );
    return <PlannerTaskGroupResult>[
      for (final key in order)
        PlannerTaskGroupResult(
          group: groupBy,
          groupId: key,
          title: titles[key]!,
          entityIds: List<String>.unmodifiable(memberIds[key]!),
        ),
    ];
  }

  /// Display order for groups: `Unassigned` always last, everything else in
  /// case-insensitive title order with stable key tie-break.
  static List<String> _groupDisplayOrder(
    List<String> keys,
    Map<String, String> titles,
  ) {
    const unassigned = 'unassigned';
    final named = keys.where((key) => key != unassigned).toList();
    named.sort((a, b) {
      final titleOrder = _normalizeSearch(
        titles[a]!,
      ).compareTo(_normalizeSearch(titles[b]!));
      if (titleOrder != 0) return titleOrder;
      return a.compareTo(b);
    });
    if (keys.contains(unassigned)) named.add(unassigned);
    return named;
  }

  /// Groups a matched entity into a stable key plus display title.
  ///
  /// Project/area read the first typed relation; category reads the legacy
  /// `category` payload (falls back to kind label when absent); priority
  /// reads the legacy `priority` payload (falls back to `normal`).
  /// Schedule groups by calendar day of `scheduled_at` (UTC date key), with
  /// unscheduled rows in `Unassigned`. Status groups by lifecycle wire value.
  _GroupSlot _groupSlot(PlannerEntity entity) {
    switch (groupBy) {
      case PlannerTaskGroup.none:
        return const _GroupSlot('none', 'None');
      case PlannerTaskGroup.schedule:
        final scheduled = entity.scheduledAt;
        if (scheduled == null) {
          return const _GroupSlot('unassigned', 'Unassigned');
        }
        final day = DateTime.utc(
          scheduled.year,
          scheduled.month,
          scheduled.day,
        );
        final key =
            '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';
        return _GroupSlot(key, key);
      case PlannerTaskGroup.project:
      case PlannerTaskGroup.area:
        final want = groupBy == PlannerTaskGroup.project ? 'project' : 'area';
        for (final relation in entity.relations) {
          final type = relation['type']?.toString();
          final target = relation['id']?.toString();
          if (type == want && target != null && target.isNotEmpty) {
            return _GroupSlot('relation:$target', target);
          }
        }
        return const _GroupSlot('unassigned', 'Unassigned');
      case PlannerTaskGroup.category:
        final raw = safeNullableJsonString(entity.payload['category'])?.trim();
        if (raw == null || raw.isEmpty) {
          return _GroupSlot('unassigned', 'Unassigned');
        }
        return _GroupSlot('category:${raw.toLowerCase()}', raw);
      case PlannerTaskGroup.priority:
        final raw = safeJsonString(
          entity.payload['priority'],
          fallback: 'normal',
        ).trim().toLowerCase();
        final value = raw.isEmpty ? 'normal' : raw;
        return _GroupSlot('priority:$value', value);
      case PlannerTaskGroup.status:
        return _GroupSlot(
          'status:${entity.status.wireValue}',
          entity.status.wireValue,
        );
    }
  }

  /// Deterministic ordering per [mode]: `scheduled` keeps the long-standing
  /// default (scheduled rows first, earliest `scheduled_at`, then
  /// case-insensitive title, then stable ID; unscheduled sort after every
  /// scheduled row regardless of title). `title` ignores schedule and orders
  /// by normalized title then ID. `recent` orders by `updatedAt` newest
  /// first, then ID. Members keep the chosen ordering in groups as well.
  static int Function(PlannerEntity, PlannerEntity) _compareDeterministic(
    PlannerTaskSortMode mode,
  ) => (a, b) {
    if (mode == PlannerTaskSortMode.title) {
      final title = _normalizeSearch(
        a.title,
      ).compareTo(_normalizeSearch(b.title));
      if (title != 0) return title;
      return a.id.compareTo(b.id);
    }
    if (mode == PlannerTaskSortMode.recent) {
      final recent = b.updatedAt.compareTo(a.updatedAt);
      if (recent != 0) return recent;
      return a.id.compareTo(b.id);
    }
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
  };

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
    recurringViewId =>
      entity.status == PlannerEntityStatus.active &&
          entity.kind == PlannerEntityKind.recurringTask,
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

  /// Copies this query with an overridden sort mode. Membership is untouched
  /// by definition: the mode only reorders the SAME shared projection.
  PlannerTaskQuery withSortMode(PlannerTaskSortMode mode) => PlannerTaskQuery(
    viewId: viewId,
    text: text,
    kinds: kinds,
    groupBy: groupBy,
    sortMode: mode,
    unknownFields: unknownFields,
  );

  /// Human-readable summary for the lens/Refine surface.
  ///
  /// Derived from this SAME typed query: one token per non-default
  /// constraint (kind scope, search text, grouping, non-default sort).
  /// The default Open query yields no tokens. Persian search text is
  /// preserved verbatim.
  PlannerTaskQuerySummary summary() {
    final viewLabel = switch (viewId) {
      inboxViewId => 'Inbox',
      scheduledViewId => 'Scheduled',
      recurringViewId => 'Recurring',
      completedViewId => 'Completed',
      _ => 'Open',
    };
    final tokens = <String>[];
    if (kinds.length == 1 && kinds.contains(PlannerEntityKind.oneOffTask)) {
      tokens.add('One-off only');
    } else if (kinds.length == 1 &&
        kinds.contains(PlannerEntityKind.recurringTask)) {
      tokens.add('Recurring only');
    } else if (kinds.isNotEmpty) {
      tokens.add('Filtered by type');
    }
    final trimmedText = text.trim();
    if (trimmedText.isNotEmpty) tokens.add('“$trimmedText”');
    if (groupBy != PlannerTaskGroup.none) {
      final groupLabel = switch (groupBy) {
        PlannerTaskGroup.schedule => 'Schedule',
        PlannerTaskGroup.project => 'Project',
        PlannerTaskGroup.area => 'Area',
        PlannerTaskGroup.category => 'Category',
        PlannerTaskGroup.priority => 'Priority',
        PlannerTaskGroup.status => 'Status',
        PlannerTaskGroup.none => '',
      };
      tokens.add('Grouped by $groupLabel');
    }
    if (sortMode != PlannerTaskSortMode.scheduled) {
      final sortLabel = switch (sortMode) {
        PlannerTaskSortMode.title => 'Title',
        PlannerTaskSortMode.recent => 'Recent',
        PlannerTaskSortMode.scheduled => '',
      };
      if (sortLabel.isNotEmpty) tokens.add('Sorted by $sortLabel');
    }
    return PlannerTaskQuerySummary(viewLabel: viewLabel, tokens: tokens);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'view_id': viewId,
    'text': text,
    'kinds': <String>[for (final kind in kinds) kind.wireValue],
    'group_by': groupBy.wireValue,
    'sort_mode': sortMode.wireValue,
    ...unknownFields,
  };

  factory PlannerTaskQuery.fromJson(Map<String, dynamic> json) {
    final kinds = <PlannerEntityKind>{};
    final rawKinds = json['kinds'];
    if (rawKinds is Iterable) {
      for (final raw in rawKinds) {
        final match = PlannerEntityKind.values.where(
          (kind) => kind.wireValue == raw,
        );
        if (match.isNotEmpty) kinds.add(match.first);
      }
    }
    const knownKeys = <String>{
      'view_id',
      'text',
      'kinds',
      'group_by',
      'sort_mode',
    };
    final unknown = <String, dynamic>{};
    for (final entry in json.entries) {
      final key = entry.key.toString();
      if (!knownKeys.contains(key)) unknown[key] = entry.value;
    }
    final rawViewId = json['view_id'];
    final viewId = rawViewId is String && builtInViewIds.contains(rawViewId)
        ? rawViewId
        : openViewId;
    final rawText = json['text'];
    return PlannerTaskQuery(
      viewId: viewId,
      text: rawText is String ? rawText : '',
      kinds: kinds,
      groupBy: PlannerTaskGroup.fromWire(json['group_by']),
      sortMode: PlannerTaskSortMode.fromWire(json['sort_mode']),
      unknownFields: unknown,
    );
  }
}

/// Human-readable summary of a [PlannerTaskQuery] for the lens/Refine
/// surface: the active view label plus one removable token per non-default
/// constraint. `isDefault` is true only for the plain Open query.
class PlannerTaskQuerySummary {
  const PlannerTaskQuerySummary({
    required this.viewLabel,
    required this.tokens,
  });

  final String viewLabel;
  final List<String> tokens;

  bool get isDefault => tokens.isEmpty;
}

/// One stable group descriptor in display order: the group key, its ordered
/// stable entity IDs (same deterministic ordering as the flat list) and the
/// row count. Empty groups never appear; rows without a value land in the
/// explicit `Unassigned` group (`groupId == 'unassigned'`).
class PlannerTaskGroupResult {
  const PlannerTaskGroupResult({
    required this.group,
    required this.groupId,
    required this.title,
    required this.entityIds,
  });

  final PlannerTaskGroup group;
  final String groupId;
  final String title;
  final List<String> entityIds;

  int get count => entityIds.length;
}

/// The resolved result of a [PlannerTaskQuery].
///
/// Later tracers add source revision and continuation cursors. This tracer
/// carries ordered stable IDs plus the total count, per-view facet counts
/// (computed under the same kind/text scope) and stable group descriptors
/// for [PlannerTaskQuery.groupBy] (empty when grouping is `none`).
class PlannerTaskQueryResult {
  const PlannerTaskQueryResult({
    required this.entityIds,
    required this.totalCount,
    required this.facetCounts,
    this.groups = const <PlannerTaskGroupResult>[],
  });

  /// Ordered stable entity IDs matching the query.
  final List<String> entityIds;

  /// Total matches before any pagination (no pagination yet).
  final int totalCount;

  /// Per built-in view ID: matches under the same kind/text scope.
  final Map<String, int> facetCounts;

  /// Group descriptors in display order; empty when grouping is `none`.
  final List<PlannerTaskGroupResult> groups;
}

/// Internal stable group slot: lookup key plus display title.
class _GroupSlot {
  const _GroupSlot(this.key, this.title);

  final String key;
  final String title;
}
