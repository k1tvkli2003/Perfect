import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:perfect/widgets/perfect_today_widget_projector.dart';

void main() {
  test(
    'Today projection applies recurrence and recovery, not anchor dates',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final store = PlannerLocalStore(database);
      final bridge = _RecordingBridge();
      addTearDown(store.close);
      final today = DateTime(2026, 7, 28, 9);
      final anchor = DateTime(2026, 7, 26, 8);

      final entities = <PlannerEntity>[
        _entity(
          id: 'daily',
          title: 'Anchored daily task',
          kind: PlannerEntityKind.recurringTask,
          createdAt: anchor,
          scheduledAt: anchor,
          recurrence: const <String, dynamic>{'rule': 'daily'},
        ),
        _entity(
          id: 'paused',
          title: 'Paused daily task',
          kind: PlannerEntityKind.recurringTask,
          createdAt: anchor,
          scheduledAt: anchor,
          recurrence: const <String, dynamic>{'rule': 'daily', 'paused': true},
        ),
        _entity(
          id: 'off-day',
          title: 'Weekly off-day task',
          kind: PlannerEntityKind.recurringTask,
          createdAt: anchor,
          scheduledAt: anchor,
          recurrence: <String, dynamic>{
            'rule': 'weekly',
            'weekdays': <int>[today.add(const Duration(days: 1)).weekday],
          },
        ),
        _entity(
          id: 'carried',
          title: 'Carried one-off',
          kind: PlannerEntityKind.oneOffTask,
          createdAt: anchor,
          scheduledAt: anchor,
          recovery: const <String, dynamic>{
            'on_miss': 'pending',
            'carry_cap': 7,
          },
        ),
        _entity(
          id: 'missed',
          title: 'Resolved as missed',
          kind: PlannerEntityKind.oneOffTask,
          createdAt: anchor,
          scheduledAt: anchor,
          recovery: const <String, dynamic>{'on_miss': 'miss_then_next'},
        ),
        _entity(
          id: 'future',
          title: 'Future one-off',
          kind: PlannerEntityKind.oneOffTask,
          createdAt: today,
          scheduledAt: today.add(const Duration(days: 1)),
        ),
      ];

      await PerfectTodayWidgetProjector(
        store,
        ownerId: 'private-owner',
        bridge: bridge,
        now: () => today,
      ).publish(
        entities: entities,
        settings: const PerfectTodayWidgetSettings(
          isAvailable: true,
          showTaskTitles: true,
        ),
      );

      expect(
        bridge.items.map((item) => item.entityId),
        unorderedEquals(<String>['carried', 'daily']),
      );
    },
  );

  test(
    'a completed flexible weekly quota disappears from every Today surface',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final store = PlannerLocalStore(database);
      final bridge = _RecordingBridge();
      addTearDown(store.close);
      final today = DateTime(2026, 7, 28, 9);
      final flexible = _entity(
        id: 'flexible-weekly',
        title: 'Exercise once this week',
        kind: PlannerEntityKind.recurringTask,
        createdAt: today.subtract(const Duration(days: 2)),
        recurrence: const <String, dynamic>{
          'rule': 'flexible',
          'frequency': <String, dynamic>{'count': 1, 'period': 'week'},
        },
      );
      await store.upsertEntity(entity: flexible);
      await store.appendOccurrence(
        ownerId: 'private-owner',
        entityId: flexible.id,
        occurrenceId: 'completed-flexible-occurrence',
        plannedFor: today.subtract(const Duration(hours: 1)),
        status: 'completed',
        now: today,
      );

      await PerfectTodayWidgetProjector(
        store,
        ownerId: 'private-owner',
        bridge: bridge,
        now: () => today,
      ).publish(
        entities: <PlannerEntity>[flexible],
        settings: const PerfectTodayWidgetSettings(
          isAvailable: true,
          showTaskTitles: true,
        ),
      );

      expect(bridge.items, isEmpty);
    },
  );
}

PlannerEntity _entity({
  required String id,
  required String title,
  required PlannerEntityKind kind,
  required DateTime createdAt,
  DateTime? scheduledAt,
  Map<String, dynamic> recurrence = const <String, dynamic>{},
  Map<String, dynamic> recovery = const <String, dynamic>{},
}) {
  return PlannerEntity(
    id: id,
    ownerId: 'private-owner',
    kind: kind,
    payload: <String, dynamic>{
      ...defaultPlannerPayload(title: title),
      PlannerPayloadKeys.timing: <String, dynamic>{
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      },
      PlannerPayloadKeys.recurrence: recurrence,
      PlannerPayloadKeys.recovery: recovery,
    },
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class _RecordingBridge extends PerfectTodayWidgetBridge {
  List<PerfectTodayWidgetItem> items = const <PerfectTodayWidgetItem>[];

  @override
  Future<void> publish({
    required String ownerId,
    required DateTime now,
    required Iterable<PerfectTodayWidgetItem> items,
    required bool showTaskTitles,
  }) async {
    this.items = items.toList(growable: false);
  }
}
