import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';

void main() {
  group('Perfect Today widget protocol', () {
    test(
      'parses a versioned partial task action without losing its percent',
      () {
        final uri = Uri(
          scheme: 'perfect',
          host: 'widget-action',
          queryParameters: <String, String>{
            'id': '99999999-9999-4999-8999-999999999999',
            'owner_id': 'private-owner',
            'entity_id': 'daily-review',
            'kind': PlannerEntityKind.recurringTask.wireValue,
            'state': PlannerTaskProgressState.partial.wireValue,
            'progress_percent': '63',
            'local_day': '2026-07-28',
            'occurred_at': '2026-07-28T08:30:00.000Z',
            'queue_sequence': '42',
          },
        );

        final action = PerfectTodayWidgetBridge.actionFromBackgroundUri(uri);

        expect(action, isNotNull);
        expect(action!.ownerId, 'private-owner');
        expect(action.entityId, 'daily-review');
        expect(action.kind, PlannerEntityKind.recurringTask);
        expect(
          action.progress,
          const PlannerTaskProgress(
            state: PlannerTaskProgressState.partial,
            percent: 63,
          ),
        );
        expect(localDateKey(action.localDay), '2026-07-28');
        expect(action.queueSequence, 42);
      },
    );

    test('equal-timestamp rapid taps retain their native queue order', () {
      final sameInstant = DateTime.utc(2026, 7, 28, 8, 30);
      final earlierTap = PlannerWidgetTaskAction(
        id: '11111111-1111-4111-8111-111111111111',
        ownerId: 'private-owner',
        entityId: 'daily-review',
        kind: PlannerEntityKind.oneOffTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
        localDay: DateTime(2026, 7, 28),
        occurredAt: sameInstant,
        queueSequence: 17,
      );
      final laterTap = PlannerWidgetTaskAction(
        id: '22222222-2222-4222-8222-222222222222',
        ownerId: 'private-owner',
        entityId: 'daily-review',
        kind: PlannerEntityKind.oneOffTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.missed,
          percent: 0,
        ),
        localDay: DateTime(2026, 7, 28),
        occurredAt: sameInstant,
        queueSequence: 18,
      );
      final actions = <PlannerWidgetTaskAction>[laterTap, earlierTap]
        ..sort((first, second) => first.compareReplayOrder(second));

      expect(actions, <PlannerWidgetTaskAction>[earlierTap, laterTap]);
      expect(laterTap.toJson()['queue_sequence'], 18);
    });

    test(
      'rejects malformed actions and recognizes only the Today deep link',
      () {
        expect(
          PerfectTodayWidgetBridge.actionFromBackgroundUri(
            Uri.parse('perfect://widget-action?id=not-a-uuid'),
          ),
          isNull,
        );
        expect(
          PerfectTodayWidgetBridge.isTodayLaunchUri(
            Uri.parse('perfect://planner/today'),
          ),
          isTrue,
        );
        expect(
          PerfectTodayWidgetBridge.isTodayLaunchUri(
            Uri.parse('perfect://planner/tasks'),
          ),
          isFalse,
        );
        expect(
          PerfectTodayWidgetBridge.isTodayLaunchUri(
            Uri.parse('https://planner/today'),
          ),
          isFalse,
        );
      },
    );

    test('accepts only a scoped day-refresh request', () {
      final request = PerfectTodayWidgetBridge.refreshRequestFromBackgroundUri(
        Uri.parse(
          'perfect://widget-refresh?owner_id=private-owner&token=opaque',
        ),
      );

      expect(request?.ownerId, 'private-owner');
      expect(
        PerfectTodayWidgetBridge.refreshRequestFromBackgroundUri(
          Uri.parse('perfect://widget-refresh?token=opaque'),
        ),
        isNull,
      );
      expect(
        PerfectTodayWidgetBridge.refreshRequestFromBackgroundUri(
          Uri.parse('https://widget-refresh?owner_id=private-owner'),
        ),
        isNull,
      );
    });

    test(
      'token comparison is exact and does not short-circuit by character',
      () {
        expect(
          PerfectTodayWidgetBridge.secretsMatch('orbit-123', 'orbit-123'),
          isTrue,
        );
        expect(
          PerfectTodayWidgetBridge.secretsMatch('orbit-123', 'orbit-124'),
          isFalse,
        );
        expect(
          PerfectTodayWidgetBridge.secretsMatch('orbit-123', 'orbit-12'),
          isFalse,
        );
      },
    );

    test(
      'a hidden-title projection never serializes the private task title',
      () {
        const item = PerfectTodayWidgetItem(
          entityId: 'private-task',
          kind: PlannerEntityKind.oneOffTask,
          title: 'Private medical appointment',
          timeLabel: '2:00 PM',
          progress: PlannerTaskProgress.pending(),
          accent: 'apricot',
        );

        final hidden = item.toJson(title: 'Task 1');

        expect(hidden['title'], 'Task 1');
        expect(hidden.values, isNot(contains('Private medical appointment')));
      },
    );
  });
}
