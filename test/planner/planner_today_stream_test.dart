import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/domain/planner_today_stream.dart';

void main() {
  final day = DateTime(2026, 9, 9, 12);
  PlannerEntity item(
    String id, {
    PlannerEntityKind kind = PlannerEntityKind.oneOffTask,
    PlannerEntityStatus status = PlannerEntityStatus.active,
    DateTime? scheduled,
    DateTime? updated,
    Map<String, dynamic> recovery = const {},
    Map<String, dynamic> recurrence = const {'rule': 'daily'},
  }) => PlannerEntity(
    id: id,
    ownerId: 'owner',
    kind: kind,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: updated ?? day,
    payload: {
      ...defaultPlannerPayload(title: id),
      'status': status.wireValue,
      'timing': {
        if (scheduled != null)
          'scheduled_at': scheduled.toUtc().toIso8601String(),
      },
      'recurrence': recurrence,
      'recovery': recovery,
    },
  );

  List<String> ids(PlannerTodayStream stream) =>
      stream.entries.map((entry) => entry.entity.id).toList();

  test('orders decision, scheduled, habits, flexible and settled once', () {
    final stream = PlannerTodayStream.project(
      day: day,
      entities: [
        item('flexible'),
        item('habit', kind: PlannerEntityKind.habit),
        item('later', scheduled: DateTime(2026, 9, 9, 16)),
        item('earlier', scheduled: DateTime(2026, 9, 9, 8)),
        item(
          'decision',
          scheduled: DateTime(2026, 9, 1, 9),
          recovery: {'on_miss': 'ask'},
        ),
        item('done', scheduled: DateTime(2026, 9, 9, 7)),
      ],
      taskProgressById: const {
        'done': PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
      },
    );
    expect(ids(stream), [
      'decision',
      'earlier',
      'later',
      'habit',
      'flexible',
      'done',
    ]);
    expect(stream.nextEntryId, 'decision');
    expect(stream.inSection(PlannerTodaySection.settled).length, 1);
  });

  test('recurring order uses this day time, not original anchor date', () {
    final stream = PlannerTodayStream.project(
      day: day,
      entities: [
        item(
          'late',
          kind: PlannerEntityKind.recurringTask,
          scheduled: DateTime(2026, 1, 1, 18),
        ),
        item(
          'early',
          kind: PlannerEntityKind.recurringTask,
          scheduled: DateTime(2026, 8, 1, 8),
        ),
      ],
    );
    expect(ids(stream), ['early', 'late']);
    expect(stream.entries.first.scheduledAt, DateTime(2026, 9, 9, 8));
  });

  test('ties remain stable across input order and sync/title update times', () {
    final first = item('a');
    final second = item('b');
    final before = PlannerTodayStream.project(
      day: day,
      entities: [second, first],
    );
    final after = PlannerTodayStream.project(
      day: day,
      entities: [
        first.copyWith(updatedAt: day.add(const Duration(days: 2))),
        second,
      ],
    );
    expect(ids(before), ['a', 'b']);
    expect(ids(after), ids(before));
  });

  test('authoritative quota/exception eligibility overrides fallback', () {
    final habit = item('quota', kind: PlannerEntityKind.habit);
    expect(
      PlannerTodayEngine.evaluate(entity: habit, day: day).isEligible,
      isTrue,
    );
    final stream = PlannerTodayStream.project(
      day: day,
      entities: [habit],
      eligibilityById: const {
        'quota': PlannerTodayEligibility(
          isEligible: false,
          reason: PlannerTodayEligibilityReason.notScheduledToday,
        ),
      },
    );
    expect(stream.entries, isEmpty);
    expect(stream.nextEntryId, isNull);
  });

  test(
    'inactive and non-actionable entities stay out even with stale eligibility',
    () {
      final entities = [
        item('archived', status: PlannerEntityStatus.archived),
        item('cancelled', status: PlannerEntityStatus.cancelled),
        item('project', kind: PlannerEntityKind.project),
        item('area', kind: PlannerEntityKind.area),
        item('deleted').copyWith(deletedAt: day),
      ];
      final stream = PlannerTodayStream.project(
        day: day,
        entities: entities,
        eligibilityById: {
          for (final entity in entities)
            entity.id: const PlannerTodayEligibility(
              isEligible: true,
              reason: PlannerTodayEligibilityReason.unscheduled,
            ),
        },
      );
      expect(stream.entries, isEmpty);
    },
  );

  test('recurring lifecycle cannot masquerade as daily completion', () {
    final stream = PlannerTodayStream.project(
      day: day,
      entities: [
        item(
          'recurring',
          kind: PlannerEntityKind.recurringTask,
          status: PlannerEntityStatus.completed,
        ),
      ],
      eligibilityById: const {
        'recurring': PlannerTodayEligibility(
          isEligible: true,
          reason: PlannerTodayEligibilityReason.recurringOccurrence,
        ),
      },
    );
    expect(stream.nextEntryId, 'recurring');
    expect(stream.entries.single.isSettled, isFalse);
  });

  test(
    'partial stays actionable while completed and missed stay reviewable',
    () {
      final stream = PlannerTodayStream.project(
        day: day,
        entities: [item('done'), item('missed'), item('partial')],
        taskProgressById: const {
          'done': PlannerTaskProgress(
            state: PlannerTaskProgressState.completed,
            percent: 100,
          ),
          'missed': PlannerTaskProgress(
            state: PlannerTaskProgressState.missed,
            percent: 0,
          ),
          'partial': PlannerTaskProgress(
            state: PlannerTaskProgressState.partial,
            percent: 40,
          ),
        },
      );
      expect(ids(stream), ['partial', 'done', 'missed']);
      expect(stream.nextEntryId, 'partial');
    },
  );

  test('daily habit summary owns completion, not source payload', () {
    final habit = item('habit', kind: PlannerEntityKind.habit);
    final summary = PlannerHabitDayEngine.evaluate(
      habit: habit,
      occurrences: [
        PlannerOccurrence(
          id: 'occurrence',
          ownerId: 'owner',
          entityId: habit.id,
          plannedFor: day,
          completedAt: day,
          status: 'completed',
          value: const {},
          createdAt: day,
          updatedAt: day,
        ),
      ],
    );
    final stream = PlannerTodayStream.project(
      day: day,
      entities: [habit],
      habitSummaryById: {'habit': summary},
    );
    expect(stream.entries.single.isSettled, isTrue);
    expect(stream.nextEntryId, isNull);
  });

  test('paused recurrence and future one-off are not shown', () {
    final stream = PlannerTodayStream.project(
      day: day,
      entities: [
        item(
          'paused',
          kind: PlannerEntityKind.habit,
          recurrence: {'rule': 'daily', 'paused': true},
        ),
        item('future', scheduled: DateTime(2026, 9, 10)),
      ],
    );
    expect(stream.entries, isEmpty);
  });

  test('unscheduled work has no artificial clock label', () {
    final stream = PlannerTodayStream.project(day: day, entities: [item('a')]);
    expect(stream.entries.single.scheduledAt, isNull);
    expect(stream.entries.single.section, PlannerTodaySection.flexible);
    expect(() => stream.entries.clear(), throwsUnsupportedError);
    expect(
      () => stream.inSection(PlannerTodaySection.flexible).clear(),
      throwsUnsupportedError,
    );
  });

  test('duplicates fail explicitly instead of duplicating controls', () {
    expect(
      () => PlannerTodayStream.project(
        day: day,
        entities: [item('a'), item('a')],
      ),
      throwsArgumentError,
    );
  });

  test('day rollover reprojects recurrence without mutating source', () {
    final habit = item(
      'habit',
      kind: PlannerEntityKind.habit,
      scheduled: DateTime(2026, 1, 1, 9),
    );
    final before = PlannerTodayStream.project(day: day, entities: [habit]);
    final after = PlannerTodayStream.project(
      day: DateTime(2026, 9, 10),
      entities: [habit],
    );
    expect(before.entries.single.scheduledAt, DateTime(2026, 9, 9, 9));
    expect(after.entries.single.scheduledAt, DateTime(2026, 9, 10, 9));
    expect(habit.scheduledAt?.toLocal(), DateTime(2026, 1, 1, 9));
  });
}
