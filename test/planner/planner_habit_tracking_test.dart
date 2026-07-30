import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_tracking.dart';

void main() {
  PlannerEntity habit({
    required Object successCondition,
    bool legacyTopLevelChecklist = false,
  }) {
    final checklist = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'water', 'required': true},
      <String, dynamic>{'id': 'walk', 'required': true},
      <String, dynamic>{'id': 'journal', 'required': true},
      <String, dynamic>{'id': 'bonus', 'required': false},
    ];
    return PlannerEntity(
      id: '11111111-1111-4111-8111-111111111111',
      ownerId: 'owner',
      kind: PlannerEntityKind.habit,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Morning routine'),
        PlannerPayloadKeys.tracking: <String, dynamic>{
          PlannerHabitTrackingKeys.method: 'checklist',
          if (!legacyTopLevelChecklist)
            PlannerHabitTrackingKeys.checklist: checklist,
          PlannerHabitTrackingKeys.successCondition: successCondition,
        },
        if (legacyTopLevelChecklist)
          PlannerHabitTrackingKeys.checklist: checklist,
      },
      createdAt: DateTime.utc(2026, 7, 27, 8),
      updatedAt: DateTime.utc(2026, 7, 27, 8),
    );
  }

  test('all means every required checklist item, not optional extras', () {
    final result = PlannerHabitTrackingEngine.evaluateChecklist(
      entity: habit(successCondition: 'all'),
      checkedItemIds: const <String>{'water', 'walk', 'journal'},
    );

    expect(result.isSuccessful, isTrue);
    expect(result.checkedCount, 3);
    expect(result.totalCount, 3);
    expect(result.requiredCount, 3);
  });

  test('custom count succeeds only after the configured threshold', () {
    final trackedHabit = habit(
      successCondition: const <String, dynamic>{'type': 'custom', 'value': 2},
    );

    expect(
      PlannerHabitTrackingEngine.evaluateChecklist(
        entity: trackedHabit,
        checkedItemIds: const <String>{'water'},
      ).isSuccessful,
      isFalse,
    );
    expect(
      PlannerHabitTrackingEngine.evaluateChecklist(
        entity: trackedHabit,
        checkedItemIds: const <String>{'water', 'walk'},
      ).isSuccessful,
      isTrue,
    );
  });

  test('legacy top-level checklist remains readable with percent success', () {
    final result = PlannerHabitTrackingEngine.evaluateChecklist(
      entity: habit(
        successCondition: const <String, dynamic>{
          'type': 'percent',
          'value': 66,
        },
        legacyTopLevelChecklist: true,
      ),
      checkedItemIds: const <String>{'water', 'walk'},
    );

    expect(result.requiredCount, 2);
    expect(result.progressPercent, 67);
    expect(result.isSuccessful, isTrue);
  });
}
