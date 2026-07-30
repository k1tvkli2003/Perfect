import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/notifications/planner_reminder_scheduler.dart';
import 'package:perfect/presentation/planner_reminder_settings_sheet.dart';

void main() {
  test('reminder capacity truncation is explicit in owner-facing copy', () {
    final message = reminderScheduleSummaryMessage(
      const PlannerReminderScheduleSummary(
        scheduled: 96,
        truncated: 4,
        capacity: 96,
      ),
    );

    expect(message, contains('next 96'));
    expect(message, contains('4 later'));
    expect(message, contains('96-notification safety limit'));
  });

  test('failed cancellation remains visible while reminders are off', () {
    final message = reminderScheduleSummaryMessage(
      const PlannerReminderScheduleSummary(
        scheduled: 0,
        failures: 2,
        disabled: true,
      ),
    );

    expect(message, contains('Reminders are off'));
    expect(message, contains('2 older notifications'));
    expect(message, contains('retry'));
  });
}
