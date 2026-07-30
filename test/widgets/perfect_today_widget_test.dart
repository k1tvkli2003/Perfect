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
        ..sort(comparePerfectTodayWidgetReplayOrder);

      expect(actions, <PlannerWidgetTaskAction>[earlierTap, laterTap]);
      expect(laterTap.toJson()['queue_sequence'], 18);
    });

    test('native sequence survives a backwards wall-clock correction', () {
      final firstTap = PlannerWidgetTaskAction(
        id: '11111111-2222-4333-8444-555555555555',
        ownerId: 'private-owner',
        entityId: 'daily-review',
        kind: PlannerEntityKind.oneOffTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
        localDay: DateTime(2026, 7, 28),
        occurredAt: DateTime.utc(2026, 7, 28, 12, 30),
        queueSequence: 41,
      );
      final secondTapAfterClockRollback = PlannerWidgetTaskAction(
        id: '66666666-7777-4888-8999-aaaaaaaaaaaa',
        ownerId: 'private-owner',
        entityId: 'daily-review',
        kind: PlannerEntityKind.oneOffTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.missed,
          percent: 0,
        ),
        localDay: DateTime(2026, 7, 28),
        occurredAt: DateTime.utc(2026, 7, 28, 11, 30),
        queueSequence: 42,
      );
      final actions = <PlannerWidgetTaskAction>[
        secondTapAfterClockRollback,
        firstTap,
      ]..sort(comparePerfectTodayWidgetReplayOrder);

      expect(actions, <PlannerWidgetTaskAction>[
        firstTap,
        secondTapAfterClockRollback,
      ]);
    });

    test('legacy actions drain before newer sequenced outcomes', () {
      final legacy = PlannerWidgetTaskAction(
        id: 'bbbbbbbb-1111-4222-8333-444444444444',
        ownerId: 'private-owner',
        entityId: 'legacy-task',
        kind: PlannerEntityKind.oneOffTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
        localDay: DateTime(2026, 7, 28),
        occurredAt: DateTime.utc(2026, 7, 28, 13),
      );
      final sequenced = PlannerWidgetTaskAction(
        id: 'cccccccc-5555-4666-8777-888888888888',
        ownerId: 'private-owner',
        entityId: 'new-task',
        kind: PlannerEntityKind.oneOffTask,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.missed,
          percent: 0,
        ),
        localDay: DateTime(2026, 7, 28),
        occurredAt: DateTime.utc(2026, 7, 28, 12),
        queueSequence: 1,
      );
      final actions = <PlannerWidgetTaskAction>[sequenced, legacy]
        ..sort(comparePerfectTodayWidgetReplayOrder);

      expect(actions, <PlannerWidgetTaskAction>[legacy, sequenced]);
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

    test('parses a scoped, content-free quick-add wake request', () {
      final request = PerfectTodayWidgetBridge.quickAddRequestFromBackgroundUri(
        Uri(
          scheme: 'perfect',
          host: 'widget-quick-add',
          queryParameters: <String, String>{
            'id': 'abababab-abab-4bab-8bab-abababababab',
            'owner_id': 'private-owner',
          },
        ),
      );

      expect(request, isNotNull);
      expect(request!.ownerId, 'private-owner');
      expect(request.id, 'abababab-abab-4bab-8bab-abababababab');
    });

    test('quick-add wake request rejects malformed identity and scope', () {
      Uri requestUri({
        String id = 'abababab-abab-4bab-8bab-abababababab',
        String ownerId = 'private-owner',
      }) => Uri(
        scheme: 'perfect',
        host: 'widget-quick-add',
        queryParameters: <String, String>{'id': id, 'owner_id': ownerId},
      );

      expect(
        PerfectTodayWidgetBridge.quickAddRequestFromBackgroundUri(
          requestUri(id: 'not-a-uuid'),
        ),
        isNull,
      );
      expect(
        PerfectTodayWidgetBridge.quickAddRequestFromBackgroundUri(
          requestUri(ownerId: ' '),
        ),
        isNull,
      );
    });

    test('quick adds use stable chronological replay order', () {
      final later = PerfectTodayWidgetQuickAdd(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        ownerId: 'private-owner',
        title: 'Second',
        occurredAt: DateTime.utc(2026, 7, 30, 9),
      );
      final earlier = PerfectTodayWidgetQuickAdd(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        ownerId: 'private-owner',
        title: 'First',
        occurredAt: DateTime.utc(2026, 7, 30, 8),
      );
      final requests = <PerfectTodayWidgetQuickAdd>[later, earlier]
        ..sort(comparePerfectTodayWidgetQuickAddOrder);

      expect(requests, <PerfectTodayWidgetQuickAdd>[earlier, later]);
    });

    test('rejects non-canonical or internally inconsistent action rows', () {
      Uri actionUri({
        String state = 'partial',
        String percent = '50',
        String localDay = '2026-07-28',
        String sequence = '8',
      }) => Uri(
        scheme: 'perfect',
        host: 'widget-action',
        queryParameters: <String, String>{
          'id': 'dddddddd-1111-4222-8333-eeeeeeeeeeee',
          'owner_id': 'private-owner',
          'entity_id': 'daily-review',
          'kind': PlannerEntityKind.recurringTask.wireValue,
          'state': state,
          'progress_percent': percent,
          'local_day': localDay,
          'occurred_at': '2026-07-28T08:30:00.000Z',
          'queue_sequence': sequence,
        },
      );

      expect(
        PerfectTodayWidgetBridge.actionFromBackgroundUri(
          actionUri(localDay: '2026-02-31'),
        ),
        isNull,
      );
      expect(
        PerfectTodayWidgetBridge.actionFromBackgroundUri(
          actionUri(state: 'unknown'),
        ),
        isNull,
      );
      expect(
        PerfectTodayWidgetBridge.actionFromBackgroundUri(
          actionUri(state: 'completed', percent: '99'),
        ),
        isNull,
      );
      expect(
        PerfectTodayWidgetBridge.actionFromBackgroundUri(
          actionUri(sequence: '-1'),
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
