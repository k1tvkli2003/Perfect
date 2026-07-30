import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';

void main() {
  PlannerEntity entity({
    PlannerEntityKind kind = PlannerEntityKind.oneOffTask,
    Map<String, dynamic> recovery = const <String, dynamic>{},
    Map<String, dynamic> recurrence = const <String, dynamic>{},
    DateTime? scheduledAt,
    PlannerEntityStatus status = PlannerEntityStatus.active,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    final now = DateTime.utc(2026, 7, 27, 8);
    return PlannerEntity(
      id: '11111111-1111-4111-8111-111111111111',
      ownerId: 'owner',
      kind: kind,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Recover safely'),
        PlannerPayloadKeys.status: status.wireValue,
        PlannerPayloadKeys.timing: <String, dynamic>{
          if (scheduledAt != null)
            'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        },
        PlannerPayloadKeys.recovery: recovery,
        PlannerPayloadKeys.recurrence: recurrence,
        if (completedAt != null)
          'completed_at': completedAt.toUtc().toIso8601String(),
      },
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
  }

  test('one-off task remains pending until the carry cap asks the owner', () {
    final task = entity(recovery: <String, dynamic>{'carry_cap': 2});
    final at = DateTime.utc(2026, 7, 27, 9);

    final first = PlannerRecoveryEngine.resolveMiss(
      entity: task,
      occurrenceAt: at,
      now: at.add(const Duration(hours: 1)),
      carryCount: 0,
    );
    final capped = PlannerRecoveryEngine.resolveMiss(
      entity: task,
      occurrenceAt: at,
      now: at.add(const Duration(days: 2)),
      carryCount: 2,
    );

    expect(first.disposition, PlannerRecoveryDisposition.carryForward);
    expect(first.carryCount, 1);
    expect(capped.disposition, PlannerRecoveryDisposition.ask);
  });

  test(
    'recurring task and habit record a miss then move to next eligible slot',
    () {
      final recurring = entity(
        kind: PlannerEntityKind.recurringTask,
        recurrence: <String, dynamic>{'rule': 'daily'},
      );
      final habit = entity(
        kind: PlannerEntityKind.habit,
        recurrence: <String, dynamic>{'rule': 'weekdays'},
      );
      final friday = DateTime.utc(2026, 7, 31, 8);

      final taskOutcome = PlannerRecoveryEngine.resolveMiss(
        entity: recurring,
        occurrenceAt: friday,
        now: friday.add(const Duration(hours: 2)),
      );
      final habitOutcome = PlannerRecoveryEngine.resolveMiss(
        entity: habit,
        occurrenceAt: friday,
        now: friday.add(const Duration(hours: 2)),
      );

      expect(taskOutcome.disposition, PlannerRecoveryDisposition.missed);
      expect(taskOutcome.nextEligibleAt, DateTime.utc(2026, 8, 1, 8));
      expect(habitOutcome.disposition, PlannerRecoveryDisposition.missed);
      expect(habitOutcome.nextEligibleAt, DateTime.utc(2026, 8, 3, 8));
    },
  );

  test(
    'weekly and monthly rules stay deterministic at calendar boundaries',
    () {
      final weekly = entity(
        kind: PlannerEntityKind.recurringTask,
        recurrence: <String, dynamic>{
          'rule': 'weekly',
          'weekdays': <int>[DateTime.monday, DateTime.thursday],
        },
      );
      final monthly = entity(
        kind: PlannerEntityKind.recurringTask,
        scheduledAt: DateTime.utc(2026, 1, 31, 8),
        recurrence: <String, dynamic>{'rule': 'monthly'},
      );

      expect(
        PlannerRecurrenceEngine.nextEligibleAt(
          entity: weekly,
          after: DateTime.utc(2026, 7, 27, 8), // Sunday
        ),
        DateTime.utc(2026, 7, 30, 8),
      );
      expect(
        PlannerRecurrenceEngine.nextEligibleAt(
          entity: monthly,
          after: DateTime.utc(2026, 1, 31, 8),
        ),
        DateTime.utc(2026, 2, 28, 8),
      );
      expect(
        PlannerRecurrenceEngine.nextEligibleAt(
          entity: monthly,
          after: DateTime.utc(2026, 2, 28, 8),
        ),
        DateTime.utc(2026, 3, 31, 8),
      );
    },
  );

  test('yearly leap-day recurrence always uses its original anchor', () {
    final leapDay = entity(
      kind: PlannerEntityKind.recurringTask,
      scheduledAt: DateTime.utc(2024, 2, 29, 8),
      recurrence: const <String, dynamic>{'rule': 'yearly'},
    );

    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: leapDay,
        after: DateTime.utc(2024, 2, 29, 8),
      ),
      DateTime.utc(2025, 2, 28, 8),
    );
    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: leapDay,
        after: DateTime.utc(2027, 2, 28, 8),
      ),
      DateTime.utc(2028, 2, 29, 8),
    );
  });

  test(
    'paused, bounded, and exception schedules never create a phantom slot',
    () {
      final paused = entity(
        kind: PlannerEntityKind.habit,
        recurrence: <String, dynamic>{'rule': 'daily', 'paused': true},
      );
      final exception = entity(
        kind: PlannerEntityKind.recurringTask,
        recurrence: <String, dynamic>{
          'rule': 'daily',
          'end_at': DateTime.utc(2026, 7, 30).toIso8601String(),
          'exceptions': <String>[DateTime.utc(2026, 7, 28).toIso8601String()],
        },
      );
      final bounded = entity(
        recurrence: <String, dynamic>{'rule': 'daily', 'occurrence_limit': 2},
      );

      expect(
        PlannerRecurrenceEngine.nextEligibleAt(
          entity: paused,
          after: DateTime.utc(2026, 7, 27, 8),
        ),
        isNull,
      );
      expect(
        PlannerRecurrenceEngine.nextEligibleAt(
          entity: exception,
          after: DateTime.utc(2026, 7, 27, 8),
        ),
        DateTime.utc(2026, 7, 29, 8),
      );
      expect(
        PlannerRecurrenceEngine.nextEligibleAt(
          entity: bounded,
          after: DateTime.utc(2026, 7, 27, 8),
          completedOccurrences: 2,
        ),
        isNull,
      );
    },
  );

  test('daily exception dates do not consume the occurrence limit', () {
    final task = entity(
      kind: PlannerEntityKind.recurringTask,
      scheduledAt: DateTime(2026, 7, 27, 8),
      recurrence: <String, dynamic>{
        'rule': 'daily',
        PlannerRecurrenceKeys.occurrenceLimit: 2,
        PlannerRecurrenceKeys.exceptions: <String>[
          DateTime(2026, 7, 27).toUtc().toIso8601String(),
        ],
      },
    );

    expect(
      PlannerRecurrenceEngine.occursOnDate(
        entity: task,
        date: DateTime(2026, 7, 27),
      ),
      isFalse,
    );
    expect(
      PlannerRecurrenceEngine.occursOnDate(
        entity: task,
        date: DateTime(2026, 7, 28),
      ),
      isTrue,
    );
    expect(
      PlannerRecurrenceEngine.occursOnDate(
        entity: task,
        date: DateTime(2026, 7, 29),
      ),
      isTrue,
    );
    expect(
      PlannerRecurrenceEngine.occursOnDate(
        entity: task,
        date: DateTime(2026, 7, 30),
      ),
      isFalse,
    );
  });

  test('weekly exception dates do not consume the occurrence limit', () {
    final task = entity(
      kind: PlannerEntityKind.recurringTask,
      scheduledAt: DateTime(2026, 7, 27, 8),
      recurrence: <String, dynamic>{
        'rule': 'weekly',
        'weekdays': <int>[DateTime.monday, DateTime.thursday],
        PlannerRecurrenceKeys.occurrenceLimit: 2,
        PlannerRecurrenceKeys.exceptions: <String>[
          DateTime(2026, 7, 27).toUtc().toIso8601String(),
        ],
      },
    );

    expect(
      PlannerRecurrenceEngine.occursOnDate(
        entity: task,
        date: DateTime(2026, 7, 30),
      ),
      isTrue,
    );
    expect(
      PlannerRecurrenceEngine.occursOnDate(
        entity: task,
        date: DateTime(2026, 8, 3),
      ),
      isTrue,
    );
    expect(
      PlannerRecurrenceEngine.occursOnDate(
        entity: task,
        date: DateTime(2026, 8, 6),
      ),
      isFalse,
    );
  });

  test(
    'Today keeps capped carry visible as a decision instead of silently moving it',
    () {
      final task = entity(
        scheduledAt: DateTime(2026, 7, 24, 9),
        recovery: <String, dynamic>{'on_miss': 'pending', 'carry_cap': 2},
      );

      final belowCap = PlannerTodayEngine.evaluate(
        entity: task,
        day: DateTime(2026, 7, 27, 10),
        carryCount: 1,
      );
      final capped = PlannerTodayEngine.evaluate(
        entity: task,
        day: DateTime(2026, 7, 27, 10),
        carryCount: 2,
      );

      expect(belowCap.isEligible, isTrue);
      expect(belowCap.reason, PlannerTodayEligibilityReason.carriedForward);
      expect(belowCap.requiresDecision, isFalse);
      expect(capped.isEligible, isTrue);
      expect(
        capped.reason,
        PlannerTodayEligibilityReason.awaitingRecoveryDecision,
      );
      expect(capped.requiresDecision, isTrue);
    },
  );

  test('Today honors explicit miss-then-next for an overdue one-off', () {
    final task = entity(
      scheduledAt: DateTime(2026, 7, 25, 9),
      recovery: const <String, dynamic>{'on_miss': 'miss_then_next'},
    );

    final decision = PlannerTodayEngine.evaluate(
      entity: task,
      day: DateTime(2026, 7, 27, 10),
    );

    expect(decision.isEligible, isFalse);
    expect(decision.reason, PlannerTodayEligibilityReason.recoveredAsMissed);
  });

  test(
    'Today and recurrence expansion agree on weekly dates and exceptions',
    () {
      final task = entity(
        kind: PlannerEntityKind.recurringTask,
        scheduledAt: DateTime(2026, 7, 27, 9),
        recurrence: <String, dynamic>{
          'rule': 'weekly',
          'weekdays': <int>[DateTime.monday, DateTime.thursday],
          'exceptions': <String>[
            DateTime(2026, 7, 30).toUtc().toIso8601String(),
          ],
        },
      );

      final monday = PlannerTodayEngine.evaluate(
        entity: task,
        day: DateTime(2026, 7, 27, 12),
      );
      final thursdayException = PlannerTodayEngine.evaluate(
        entity: task,
        day: DateTime(2026, 7, 30, 12),
      );

      expect(monday.isEligible, isTrue);
      expect(monday.reason, PlannerTodayEligibilityReason.recurringOccurrence);
      expect(thursdayException.isEligible, isFalse);
      expect(
        PlannerRecurrenceEngine.occursOnDate(
          entity: task,
          date: DateTime(2026, 7, 30),
        ),
        isFalse,
      );
    },
  );

  test('monthly rules support several dates and the real last day', () {
    final task = entity(
      kind: PlannerEntityKind.recurringTask,
      scheduledAt: DateTime.utc(2026, 1, 1, 8),
      recurrence: <String, dynamic>{
        'rule': 'monthly',
        PlannerRecurrenceKeys.monthDays: <Object>[1, 15, 'last'],
      },
    );

    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: task,
        after: DateTime.utc(2026, 1, 1, 8),
      ),
      DateTime.utc(2026, 1, 15, 8),
    );
    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: task,
        after: DateTime.utc(2026, 1, 15, 8),
      ),
      DateTime.utc(2026, 1, 31, 8),
    );
    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: task,
        after: DateTime.utc(2026, 2, 15, 8),
      ),
      DateTime.utc(2026, 2, 28, 8),
    );
  });

  test('editing an old completed task does not resurrect it in Today', () {
    final task = entity(
      scheduledAt: DateTime(2026, 7, 25, 9),
      status: PlannerEntityStatus.completed,
      completedAt: DateTime(2026, 7, 25, 10),
      updatedAt: DateTime(2026, 7, 27, 10),
    );

    final decision = PlannerTodayEngine.evaluate(
      entity: task,
      day: DateTime(2026, 7, 27, 12),
    );

    expect(decision.isEligible, isFalse);
    expect(decision.reason, PlannerTodayEligibilityReason.inactive);
  });

  test('yearly rules support multiple explicit calendar dates', () {
    final task = entity(
      kind: PlannerEntityKind.recurringTask,
      scheduledAt: DateTime.utc(2026, 1, 1, 8),
      recurrence: <String, dynamic>{
        'rule': 'yearly',
        PlannerRecurrenceKeys.annualDates: <Object>[
          '03-20',
          <String, int>{'month': 9, 'day': 1},
        ],
      },
    );

    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: task,
        after: DateTime.utc(2026, 1, 1, 8),
      ),
      DateTime.utc(2026, 3, 20, 8),
    );
    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: task,
        after: DateTime.utc(2026, 3, 20, 8),
      ),
      DateTime.utc(2026, 9, 1, 8),
    );
  });

  test('flexible N-per-period work stays in Today until its quota is met', () {
    final task = entity(
      kind: PlannerEntityKind.recurringTask,
      scheduledAt: DateTime(2026, 7, 27, 8),
      recurrence: <String, dynamic>{
        'rule': 'flexible',
        PlannerRecurrenceKeys.frequency: <String, dynamic>{
          PlannerRecurrenceKeys.frequencyCount: 3,
          PlannerRecurrenceKeys.frequencyPeriod: 'week',
        },
      },
    );

    final stillNeeded = PlannerTodayEngine.evaluate(
      entity: task,
      day: DateTime(2026, 7, 29, 12),
      completedOccurrencesInPeriod: 2,
    );
    final quotaMet = PlannerTodayEngine.evaluate(
      entity: task,
      day: DateTime(2026, 7, 29, 12),
      completedOccurrencesInPeriod: 3,
    );

    expect(stillNeeded.isEligible, isTrue);
    expect(quotaMet.isEligible, isFalse);
  });

  test('flexible occurrence limit uses lifetime completion history', () {
    final task = entity(
      kind: PlannerEntityKind.recurringTask,
      scheduledAt: DateTime(2026, 7, 27, 8),
      recurrence: <String, dynamic>{
        'rule': 'flexible',
        PlannerRecurrenceKeys.occurrenceLimit: 2,
        PlannerRecurrenceKeys.frequency: <String, dynamic>{
          PlannerRecurrenceKeys.frequencyCount: 3,
          PlannerRecurrenceKeys.frequencyPeriod: 'week',
        },
      },
    );

    final belowLifetimeLimit = PlannerTodayEngine.evaluate(
      entity: task,
      day: DateTime(2026, 7, 29, 12),
      completedOccurrencesInPeriod: 1,
      totalCompletedOccurrences: 1,
    );
    final lifetimeLimitMet = PlannerTodayEngine.evaluate(
      entity: task,
      day: DateTime(2026, 7, 29, 12),
      completedOccurrencesInPeriod: 1,
      totalCompletedOccurrences: 2,
    );

    expect(belowLifetimeLimit.isEligible, isTrue);
    expect(lifetimeLimitMet.isEligible, isFalse);
    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: task,
        after: DateTime(2026, 7, 29, 12),
        completedOccurrences: 2,
        completedOccurrencesInPeriod: 1,
      ),
      isNull,
    );
    expect(
      PlannerRecurrenceEngine.nextEligibleAt(
        entity: task,
        after: DateTime(2026, 7, 29, 12),
        completedOccurrences: 1,
        completedOccurrencesInPeriod: 3,
      ),
      DateTime(2026, 8, 3, 8).toUtc(),
    );
  });
}
