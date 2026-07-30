import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:perfect/planner/notifications/planner_reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(PlannerReminderNavigation.resetForTesting);

  PlannerEntity flexibleTask({
    int frequencyCount = 3,
    int occurrenceLimit = 0,
  }) {
    final scheduledAt = DateTime(2026, 7, 27, 8);
    return PlannerEntity(
      id: 'dededede-dede-4ede-8ede-dededededede',
      ownerId: 'owner',
      kind: PlannerEntityKind.recurringTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Flexible reminder'),
        PlannerPayloadKeys.timing: <String, dynamic>{
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        },
        PlannerPayloadKeys.recurrence: <String, dynamic>{
          'rule': 'flexible',
          if (occurrenceLimit > 0)
            PlannerRecurrenceKeys.occurrenceLimit: occurrenceLimit,
          PlannerRecurrenceKeys.frequency: <String, dynamic>{
            PlannerRecurrenceKeys.frequencyCount: frequencyCount,
            PlannerRecurrenceKeys.frequencyPeriod: 'week',
          },
        },
      },
      createdAt: scheduledAt.toUtc(),
      updatedAt: scheduledAt.toUtc(),
    );
  }

  test('met flexible quota leaves no reminder in the current period', () {
    final occurrences = PlannerReminderOccurrenceProjector.futureOccurrences(
      flexibleTask(),
      from: DateTime(2026, 7, 29, 12),
      maximum: 2,
      history: const PlannerRecurrenceHistory(
        completedInPeriod: 3,
        totalCompleted: 3,
      ),
    );

    expect(occurrences, hasLength(2));
    expect(occurrences.first, DateTime(2026, 8, 3, 8).toUtc());
    expect(occurrences.last, DateTime(2026, 8, 4, 8).toUtc());
  });

  test('only the remaining flexible quota is projected in this period', () {
    final occurrences = PlannerReminderOccurrenceProjector.futureOccurrences(
      flexibleTask(),
      from: DateTime(2026, 7, 29, 12),
      maximum: 2,
      history: const PlannerRecurrenceHistory(
        completedInPeriod: 2,
        totalCompleted: 2,
      ),
    );

    expect(occurrences, hasLength(2));
    expect(occurrences.first, DateTime(2026, 7, 30, 8).toUtc());
    expect(occurrences.last, DateTime(2026, 8, 3, 8).toUtc());
  });

  test('met lifetime occurrence limit suppresses every future reminder', () {
    final occurrences = PlannerReminderOccurrenceProjector.futureOccurrences(
      flexibleTask(occurrenceLimit: 2),
      from: DateTime(2026, 7, 29, 12),
      maximum: 8,
      history: const PlannerRecurrenceHistory(
        completedInPeriod: 1,
        totalCompleted: 2,
      ),
    );

    expect(occurrences, isEmpty);
  });

  test(
    'notification payload supports cold and live entity navigation',
    () async {
      final liveTarget = PlannerReminderNavigation.entityIds.first;
      PlannerReminderNavigation.handlePayload('planner:entity-123');

      expect(await liveTarget, 'entity-123');
      expect(PlannerReminderNavigation.takePendingEntityId(), 'entity-123');
      expect(PlannerReminderNavigation.takePendingEntityId(), isNull);

      PlannerReminderNavigation.handlePayload('other:entity-456');
      PlannerReminderNavigation.handlePayload('planner:   ');
      expect(PlannerReminderNavigation.takePendingEntityId(), isNull);
    },
  );

  test('snooze action IDs are bounded and cross-platform stable', () {
    expect(PlannerReminderSnooze.actionId(10), 'perfect_snooze:10');
    expect(PlannerReminderSnooze.minutesFromActionId('perfect_snooze:90'), 90);
    expect(PlannerReminderSnooze.actionId(0), 'perfect_snooze:1');
    expect(PlannerReminderSnooze.actionId(9000), 'perfect_snooze:1440');
    expect(
      PlannerReminderSnooze.minutesFromActionId('perfect_snooze:0'),
      isNull,
    );
    expect(
      PlannerReminderSnooze.minutesFromActionId('perfect_snooze:1441'),
      isNull,
    );
    expect(PlannerReminderSnooze.minutesFromActionId('unrelated:10'), isNull);
  });

  test(
    'disabling reminders cancels and forgets every durable notification ID',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'perfect.reminders.enabled.v1': false,
        'perfect.reminders.scheduled_ids.v1': <String>['17', '29'],
      });
      final preferences = await SharedPreferences.getInstance();
      final backend = _RecordingNotificationBackend();
      final scheduler = DevicePlannerReminderScheduler(
        preferences: () async => preferences,
        platformSupportedOverride: true,
        cancelNotificationOverride: backend.cancel,
        skipPluginInitialization: true,
      );

      final summary = await scheduler.sync(const <PlannerEntity>[]);

      expect(summary.disabled, isTrue);
      expect(summary.scheduled, 0);
      expect(summary.failures, 0);
      expect(backend.cancelledIds, <int>[17, 29]);
      expect(
        preferences.getStringList('perfect.reminders.scheduled_ids.v1'),
        isNull,
      );
    },
  );

  test('failed disabled cancellations remain durable for retry', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'perfect.reminders.enabled.v1': false,
      'perfect.reminders.scheduled_ids.v1': <String>['17', '29'],
    });
    final preferences = await SharedPreferences.getInstance();
    final backend = _RecordingNotificationBackend(failId: 29);
    final scheduler = DevicePlannerReminderScheduler(
      preferences: () async => preferences,
      platformSupportedOverride: true,
      cancelNotificationOverride: backend.cancel,
      skipPluginInitialization: true,
    );

    final summary = await scheduler.sync(const <PlannerEntity>[]);

    expect(summary.disabled, isTrue);
    expect(summary.failures, 1);
    expect(
      preferences.getStringList('perfect.reminders.scheduled_ids.v1'),
      <String>['29'],
    );
  });

  test(
    'more than 96 reminders are chronological and explicitly truncated',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'perfect.reminders.enabled.v1': true,
      });
      final preferences = await SharedPreferences.getInstance();
      final backend = _RecordingNotificationBackend();
      final now = DateTime.utc(2026, 7, 27, 8);
      final entities = List<PlannerEntity>.generate(100, (index) {
        final scheduledAt = now.add(Duration(minutes: index + 2));
        return PlannerEntity(
          id: 'task-${index.toString().padLeft(3, '0')}',
          ownerId: 'owner',
          kind: PlannerEntityKind.oneOffTask,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Task $index'),
            PlannerPayloadKeys.timing: <String, dynamic>{
              'scheduled_at': scheduledAt.toIso8601String(),
            },
            'reminders': const <Map<String, dynamic>>[
              <String, dynamic>{
                PlannerReminderKeys.enabled: true,
                PlannerReminderKeys.leadMinutes: 0,
              },
            ],
          },
          createdAt: now,
          updatedAt: now,
        );
      }).reversed.toList(growable: false);
      final scheduler = DevicePlannerReminderScheduler(
        preferences: () async => preferences,
        now: () => now,
        platformSupportedOverride: true,
        cancelNotificationOverride: backend.cancel,
        scheduleNotificationOverride: backend.schedule,
        skipPluginInitialization: true,
      );

      final summary = await scheduler.sync(entities);

      expect(summary.scheduled, 96);
      expect(summary.truncated, 4);
      expect(summary.capacity, 96);
      expect(summary.isComplete, isFalse);
      expect(backend.scheduledPayloads, hasLength(96));
      expect(backend.scheduledPayloads.first, 'planner:task-000');
      expect(backend.scheduledPayloads.last, 'planner:task-095');
    },
  );
}

class _RecordingNotificationBackend {
  _RecordingNotificationBackend({this.failId});

  final int? failId;
  final List<int> cancelledIds = <int>[];
  final List<String?> scheduledPayloads = <String?>[];

  Future<void> cancel(int id) async {
    cancelledIds.add(id);
    if (id == failId) throw StateError('synthetic cancellation failure');
  }

  Future<void> schedule({
    required int id,
    required String payload,
    required DateTime alertAt,
  }) async {
    scheduledPayloads.add(payload);
  }
}
