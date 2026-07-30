import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_operation.dart';

void main() {
  test('legacy measured observations become one aggregate daily result', () {
    final habit = _habit(
      tracking: const <String, dynamic>{
        'method': 'duration',
        'target': 30,
        'goal': 'at_least',
      },
    );
    final summary = PlannerHabitDayEngine.evaluate(
      habit: habit,
      occurrences: <PlannerOccurrence>[
        _occurrence(habit, id: 'a', amount: 10),
        _occurrence(habit, id: 'b', amount: 12),
      ],
    );

    expect(summary.state, PlannerHabitDayState.partial);
    expect(summary.amount, 22);
    expect(summary.progressPercent, 73);
    expect(summary.occurrences, hasLength(2));
  });

  test('canonical daily summary supersedes old observation records', () {
    final habit = _habit(
      tracking: const <String, dynamic>{
        'method': 'count',
        'target': 10,
        'goal': 'at_least',
      },
    );
    final summary = PlannerHabitDayEngine.evaluate(
      habit: habit,
      occurrences: <PlannerOccurrence>[
        _occurrence(habit, id: 'legacy', amount: 4),
        _occurrence(
          habit,
          id: 'summary',
          amount: 10,
          recordType: 'daily_summary',
          updatedAt: DateTime.utc(2026, 7, 27, 10),
        ),
      ],
    );

    expect(summary.state, PlannerHabitDayState.completed);
    expect(summary.amount, 10);
    expect(summary.progressPercent, 100);
  });

  test('at-most measured goal becomes missed only above its ceiling', () {
    final habit = _habit(
      tracking: const <String, dynamic>{
        'method': 'count',
        'target': 2,
        'goal': 'at_most',
      },
    );

    expect(
      PlannerHabitDayEngine.evaluate(
        habit: habit,
        occurrences: <PlannerOccurrence>[
          _occurrence(habit, id: 'within', amount: 2),
        ],
      ).state,
      PlannerHabitDayState.completed,
    );
    expect(
      PlannerHabitDayEngine.evaluate(
        habit: habit,
        occurrences: <PlannerOccurrence>[
          _occurrence(habit, id: 'above', amount: 3),
        ],
      ).state,
      PlannerHabitDayState.missed,
    );
  });
}

PlannerEntity _habit({required Map<String, dynamic> tracking}) {
  final now = DateTime.utc(2026, 7, 27, 8);
  return PlannerEntity(
    id: 'habit',
    ownerId: 'owner',
    kind: PlannerEntityKind.habit,
    payload: <String, dynamic>{
      ...defaultPlannerPayload(title: 'Habit'),
      PlannerPayloadKeys.tracking: tracking,
    },
    createdAt: now,
    updatedAt: now,
  );
}

PlannerOccurrence _occurrence(
  PlannerEntity habit, {
  required String id,
  required num amount,
  String? recordType,
  DateTime? updatedAt,
}) {
  final createdAt = DateTime.utc(2026, 7, 27, 9);
  return PlannerOccurrence(
    id: id,
    ownerId: habit.ownerId,
    entityId: habit.id,
    plannedFor: createdAt,
    status: 'completed',
    value: <String, dynamic>{
      'amount': amount,
      ...?recordType == null
          ? null
          : <String, dynamic>{'record_type': recordType},
    },
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
  );
}
