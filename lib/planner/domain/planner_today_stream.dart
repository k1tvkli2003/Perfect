import 'planner_entity.dart';
import 'planner_habit_day_summary.dart';
import 'planner_recovery_engine.dart';
import 'planner_task_progress.dart';

/// Semantic order for Today. Rendering, labels and collapsed review state
/// belong to the presentation layer, not to eligibility or persistence.
enum PlannerTodaySection { decision, scheduled, habits, flexible, settled }

class PlannerTodayStreamEntry {
  const PlannerTodayStreamEntry({
    required this.entity,
    required this.section,
    required this.eligibility,
    required this.scheduledAt,
    this.taskProgress,
    this.habitSummary,
  });

  final PlannerEntity entity;
  final PlannerTodaySection section;
  final PlannerTodayEligibility eligibility;

  /// The exact daily outcome used to classify this entry. Renderers must not
  /// resolve it again from the entity's lifetime state.
  final PlannerTaskProgress? taskProgress;
  final PlannerHabitDaySummary? habitSummary;

  /// Today's local occurrence time for recurrence, original time for a one-off.
  /// Null means flexible; callers must not invent a time-rail label.
  final DateTime? scheduledAt;

  bool get isSettled => section == PlannerTodaySection.settled;
}

/// One row per eligible entity, with deterministic semantic groups. Callers
/// provide owner-scoped entities and authoritative daily outcomes from storage.
///
/// This does not query storage, mutate outcomes, resolve recovery decisions or
/// infer today's recurring outcome from the source entity's lifecycle status.
class PlannerTodayStream {
  PlannerTodayStream._(this.day, List<PlannerTodayStreamEntry> entries)
    : entries = List.unmodifiable(entries);

  factory PlannerTodayStream.project({
    required Iterable<PlannerEntity> entities,
    required DateTime day,
    Map<String, PlannerTodayEligibility> eligibilityById = const {},
    Map<String, PlannerTaskProgress> taskProgressById = const {},
    Map<String, PlannerHabitDaySummary> habitSummaryById = const {},
  }) {
    final local = day.toLocal();
    final localDay = DateTime(local.year, local.month, local.day);
    final entries = <PlannerTodayStreamEntry>[];
    final seen = <String>{};
    for (final entity in entities) {
      if (!seen.add(entity.id)) {
        throw ArgumentError('Today requires unique entity IDs: ${entity.id}');
      }
      if (entity.isDeleted ||
          entity.status == PlannerEntityStatus.archived ||
          entity.status == PlannerEntityStatus.cancelled ||
          entity.kind == PlannerEntityKind.project ||
          entity.kind == PlannerEntityKind.area) {
        continue;
      }
      final eligibility =
          eligibilityById[entity.id] ??
          PlannerTodayEngine.evaluate(entity: entity, day: localDay);
      if (!eligibility.isEligible) continue;

      final scheduled = entity.scheduledAt?.toLocal();
      final occurrenceTime =
          scheduled == null || entity.kind == PlannerEntityKind.oneOffTask
          ? scheduled
          : DateTime(
              localDay.year,
              localDay.month,
              localDay.day,
              scheduled.hour,
              scheduled.minute,
              scheduled.second,
              scheduled.millisecond,
              scheduled.microsecond,
            );
      final bool settled;
      PlannerTaskProgress? taskProgress;
      PlannerHabitDaySummary? habitSummary;
      if (entity.kind == PlannerEntityKind.habit) {
        habitSummary = habitSummaryById[entity.id];
        final state = habitSummary?.state;
        settled =
            state == PlannerHabitDayState.completed ||
            state == PlannerHabitDayState.missed;
      } else {
        taskProgress =
            taskProgressById[entity.id] ??
            (entity.kind == PlannerEntityKind.recurringTask
                ? const PlannerTaskProgress.pending()
                : PlannerTaskProgress.fromEntity(entity));
        settled = taskProgress.isComplete || taskProgress.isMissed;
      }
      final section = settled
          ? PlannerTodaySection.settled
          : eligibility.requiresDecision
          ? PlannerTodaySection.decision
          : entity.kind == PlannerEntityKind.habit
          ? PlannerTodaySection.habits
          : occurrenceTime != null
          ? PlannerTodaySection.scheduled
          : PlannerTodaySection.flexible;
      entries.add(
        PlannerTodayStreamEntry(
          entity: entity,
          section: section,
          eligibility: eligibility,
          scheduledAt: occurrenceTime,
          taskProgress: taskProgress,
          habitSummary: habitSummary,
        ),
      );
    }
    entries.sort(_compare);
    return PlannerTodayStream._(localDay, entries);
  }

  /// Local calendar date shared by ordering, status and occurrence labels.
  final DateTime day;
  final List<PlannerTodayStreamEntry> entries;

  /// Contextual emphasis on the actual row, never a duplicate entity/card.
  String? get nextEntryId {
    for (final entry in entries) {
      if (!entry.isSettled) return entry.entity.id;
    }
    return null;
  }

  List<PlannerTodayStreamEntry> inSection(PlannerTodaySection section) =>
      List.unmodifiable(entries.where((entry) => entry.section == section));

  static int _compare(
    PlannerTodayStreamEntry first,
    PlannerTodayStreamEntry second,
  ) {
    final section = first.section.index.compareTo(second.section.index);
    if (section != 0) return section;
    final firstTime = first.scheduledAt;
    final secondTime = second.scheduledAt;
    if (firstTime != null && secondTime != null) {
      final time = firstTime.compareTo(secondTime);
      if (time != 0) return time;
    } else if (firstTime != null) {
      return -1;
    } else if (secondTime != null) {
      return 1;
    }
    // Sync and title/progress edits change updatedAt, not display order.
    final created = first.entity.createdAt.compareTo(second.entity.createdAt);
    return created != 0 ? created : first.entity.id.compareTo(second.entity.id);
  }
}
