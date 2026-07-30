import 'planner_entity.dart';

enum PlannerHabitSuccessType { all, count, percent }

class PlannerHabitChecklistResult {
  const PlannerHabitChecklistResult({
    required this.isSuccessful,
    required this.checkedCount,
    required this.totalCount,
    required this.requiredCount,
  });

  final bool isSuccessful;
  final int checkedCount;
  final int totalCount;
  final int requiredCount;

  int get progressPercent => totalCount == 0
      ? 0
      : ((checkedCount * 100) / totalCount).round().clamp(0, 100).toInt();
}

/// Pure evaluator for checklist-tracked habits.
///
/// The canonical payload lives under `tracking.checklist`, while the old
/// top-level `checklist` field remains readable for backward compatibility.
/// A success condition is `{type: all|count|percent, value: number}`.
abstract final class PlannerHabitTrackingEngine {
  static PlannerHabitChecklistResult evaluateChecklist({
    required PlannerEntity entity,
    Set<String> checkedItemIds = const <String>{},
  }) {
    if (entity.kind != PlannerEntityKind.habit) {
      throw ArgumentError.value(
        entity.kind,
        'entity',
        'Checklist tracking is only valid for a habit.',
      );
    }
    final tracking = entity.tracking;
    final method = safeJsonString(
      tracking[PlannerHabitTrackingKeys.method],
      fallback: 'check',
    );
    if (method != 'checklist') {
      throw StateError('This habit does not use checklist tracking.');
    }

    final rawItems =
        tracking[PlannerHabitTrackingKeys.checklist] ??
        entity.payload[PlannerHabitTrackingKeys.checklist];
    final parsed = <_ChecklistItem>[];
    if (rawItems is Iterable) {
      var index = 0;
      for (final raw in rawItems) {
        index++;
        final item = safeJsonMap(raw);
        if (item.isEmpty) continue;
        final id = safeJsonString(
          item[PlannerHabitTrackingKeys.itemId],
          fallback: 'item-$index',
        );
        parsed.add(
          _ChecklistItem(
            id: id,
            required: item[PlannerHabitTrackingKeys.itemRequired] != false,
            checked:
                checkedItemIds.contains(id) ||
                item[PlannerHabitTrackingKeys.itemChecked] == true,
          ),
        );
      }
    }

    final requiredItems = parsed.where((item) => item.required).toList();
    final measured = requiredItems.isEmpty ? parsed : requiredItems;
    final total = measured.length;
    final checked = measured.where((item) => item.checked).length;
    final conditionValue = tracking[PlannerHabitTrackingKeys.successCondition];
    final condition = safeJsonMap(conditionValue);
    final rawType = condition.isNotEmpty
        ? condition[PlannerHabitTrackingKeys.successType]
        : conditionValue;
    final type = _successType(rawType);
    final required = switch (type) {
      PlannerHabitSuccessType.all => total,
      PlannerHabitSuccessType.count => safeJsonInt(
        condition[PlannerHabitTrackingKeys.successValue],
        fallback: total,
      ).clamp(1, total == 0 ? 1 : total).toInt(),
      PlannerHabitSuccessType.percent =>
        (total *
                    safeJsonInt(
                      condition[PlannerHabitTrackingKeys.successValue],
                      fallback: 100,
                    ).clamp(1, 100) +
                99) ~/
            100,
    };
    return PlannerHabitChecklistResult(
      isSuccessful: total > 0 && checked >= required,
      checkedCount: checked,
      totalCount: total,
      requiredCount: total == 0 ? 0 : required,
    );
  }

  static PlannerHabitSuccessType _successType(Object? value) {
    final normalized = safeJsonString(value, fallback: 'all').toLowerCase();
    return switch (normalized) {
      'count' || 'custom' || 'at_least' => PlannerHabitSuccessType.count,
      'percent' || 'percentage' => PlannerHabitSuccessType.percent,
      _ => PlannerHabitSuccessType.all,
    };
  }
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.id,
    required this.required,
    required this.checked,
  });

  final String id;
  final bool required;
  final bool checked;
}
