import 'planner_entity.dart';
import 'planner_habit_tracking.dart';
import 'planner_operation.dart';

enum PlannerHabitDayState { pending, partial, completed, missed }

/// The single, user-visible result of a habit for one local calendar day.
///
/// A measured habit may be edited several times and older app versions could
/// have written more than one observation. This projection deliberately turns
/// those records into one daily result so flexible quotas, Today, insights,
/// and reminders all agree on what "one completion" means.
class PlannerHabitDaySummary {
  const PlannerHabitDaySummary({
    required this.state,
    required this.method,
    required this.hasLog,
    required this.amount,
    required this.target,
    required this.progressPercent,
    required this.checkedItemIds,
    required this.checkedCount,
    required this.requiredCount,
    required this.totalChecklistItems,
    required this.occurrences,
    this.latestOccurrence,
    this.note,
    this.outcome,
  });

  const PlannerHabitDaySummary.pending({String method = 'check'})
    : this(
        state: PlannerHabitDayState.pending,
        method: method,
        hasLog: false,
        amount: 0,
        target: 1,
        progressPercent: 0,
        checkedItemIds: const <String>{},
        checkedCount: 0,
        requiredCount: 0,
        totalChecklistItems: 0,
        occurrences: const <PlannerOccurrence>[],
      );

  final PlannerHabitDayState state;
  final String method;
  final bool hasLog;
  final double amount;
  final double target;
  final int progressPercent;
  final Set<String> checkedItemIds;
  final int checkedCount;
  final int requiredCount;
  final int totalChecklistItems;
  final List<PlannerOccurrence> occurrences;
  final PlannerOccurrence? latestOccurrence;
  final String? note;
  final String? outcome;

  bool get isSuccessful => state == PlannerHabitDayState.completed;
  bool get isPending => state == PlannerHabitDayState.pending;

  String get occurrenceStatus => switch (state) {
    PlannerHabitDayState.pending => 'pending',
    PlannerHabitDayState.partial => 'partial',
    PlannerHabitDayState.completed => 'completed',
    PlannerHabitDayState.missed => 'missed',
  };
}

abstract final class PlannerHabitDayEngine {
  static PlannerHabitDaySummary evaluate({
    required PlannerEntity habit,
    required Iterable<PlannerOccurrence> occurrences,
  }) {
    if (habit.kind != PlannerEntityKind.habit) {
      throw ArgumentError.value(
        habit.kind,
        'habit',
        'A daily habit summary requires a habit entity.',
      );
    }
    final matching =
        occurrences
            .where(
              (entry) =>
                  !entry.isDeleted &&
                  entry.entityId == habit.id &&
                  !safeJsonString(
                    entry.value['source'],
                    fallback: '',
                  ).endsWith('_undo'),
            )
            .toList(growable: false)
          ..sort((first, second) {
            final updated = second.updatedAt.compareTo(first.updatedAt);
            return updated == 0 ? second.id.compareTo(first.id) : updated;
          });
    final method = safeJsonString(
      habit.tracking[PlannerHabitTrackingKeys.method],
      fallback: 'check',
    );
    if (matching.isEmpty) {
      return PlannerHabitDaySummary.pending(method: method);
    }

    // New clients store one canonical daily summary. Prefer it over legacy
    // per-observation records so a post-upgrade edit does not double-count.
    final canonical = matching
        .where((entry) => entry.value['record_type'] == 'daily_summary')
        .toList(growable: false);
    final effective = canonical.isEmpty
        ? matching
        : <PlannerOccurrence>[canonical.first];
    final latest = effective.first;
    final note = safeNullableJsonString(latest.value['note']);
    final outcome = safeNullableJsonString(latest.value['outcome']);
    final explicitlyMissed =
        latest.status == 'missed' ||
        outcome == 'missed' ||
        outcome == 'slipped';

    if (method == 'count' || method == 'duration') {
      final amount = effective.fold<double>(
        0,
        (sum, entry) => sum + _number(entry.value['amount']),
      );
      final target = _positiveNumber(habit.tracking['target'], fallback: 1);
      final direction = safeJsonString(
        habit.tracking['goal'],
        fallback: 'at_least',
      );
      final goalState = direction == 'at_most'
          ? amount <= target
                ? PlannerHabitDayState.completed
                : PlannerHabitDayState.missed
          : amount >= target
          ? PlannerHabitDayState.completed
          : amount > 0
          ? PlannerHabitDayState.partial
          : PlannerHabitDayState.pending;
      final state = explicitlyMissed ? PlannerHabitDayState.missed : goalState;
      final percent = direction == 'at_most'
          ? amount <= target
                ? 100
                : ((target / amount) * 100).round().clamp(0, 99).toInt()
          : ((amount / target) * 100).round().clamp(0, 100).toInt();
      return PlannerHabitDaySummary(
        state: state,
        method: method,
        hasLog: true,
        amount: amount,
        target: target,
        progressPercent: percent,
        checkedItemIds: const <String>{},
        checkedCount: 0,
        requiredCount: 0,
        totalChecklistItems: 0,
        occurrences: matching,
        latestOccurrence: latest,
        note: note,
        outcome: outcome,
      );
    }

    if (method == 'checklist') {
      final checkedIds = _stringSet(latest.value['checked_item_ids']);
      final checklist = PlannerHabitTrackingEngine.evaluateChecklist(
        entity: habit,
        checkedItemIds: checkedIds,
      );
      final goalState = checklist.isSuccessful
          ? PlannerHabitDayState.completed
          : checklist.checkedCount > 0
          ? PlannerHabitDayState.partial
          : PlannerHabitDayState.pending;
      final state = explicitlyMissed ? PlannerHabitDayState.missed : goalState;
      return PlannerHabitDaySummary(
        state: state,
        method: method,
        hasLog: true,
        amount: checklist.checkedCount.toDouble(),
        target: checklist.requiredCount.toDouble(),
        progressPercent: checklist.progressPercent,
        checkedItemIds: checkedIds,
        checkedCount: checklist.checkedCount,
        requiredCount: checklist.requiredCount,
        totalChecklistItems: checklist.totalCount,
        occurrences: matching,
        latestOccurrence: latest,
        note: note,
        outcome: outcome,
      );
    }

    final state = latest.status == 'missed' || outcome == 'slipped'
        ? PlannerHabitDayState.missed
        : latest.status == 'partial'
        ? PlannerHabitDayState.partial
        : latest.status == 'completed'
        ? PlannerHabitDayState.completed
        : PlannerHabitDayState.pending;
    return PlannerHabitDaySummary(
      state: state,
      method: method,
      hasLog: latest.status != 'pending',
      amount: state == PlannerHabitDayState.completed ? 1 : 0,
      target: 1,
      progressPercent: state == PlannerHabitDayState.completed ? 100 : 0,
      checkedItemIds: const <String>{},
      checkedCount: 0,
      requiredCount: 0,
      totalChecklistItems: 0,
      occurrences: matching,
      latestOccurrence: latest,
      note: note,
      outcome: outcome,
    );
  }
}

double _number(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

double _positiveNumber(Object? value, {required double fallback}) {
  final parsed = _number(value);
  return parsed > 0 ? parsed : fallback;
}

Set<String> _stringSet(Object? value) {
  if (value is! Iterable || value is String) return const <String>{};
  return Set<String>.unmodifiable(
    value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty),
  );
}
