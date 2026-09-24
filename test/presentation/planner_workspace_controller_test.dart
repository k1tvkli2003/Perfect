import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/notifications/planner_reminder_scheduler.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';

void main() {
  test('a yes/no habit keeps one editable daily occurrence', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final reminders = _RecordingReminderScheduler();
    final now = DateTime.utc(2026, 7, 27, 9);
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'controller-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'controller-owner',
      now: () => now,
      reminderScheduler: reminders,
    );
    addTearDown(controller.disposeAsync);
    await controller.start();

    await controller.saveEntity(
      kind: PlannerEntityKind.habit,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Drink water'),
        PlannerPayloadKeys.tracking: const <String, dynamic>{'method': 'check'},
      },
    );
    final habit = (await local.readActiveEntities('controller-owner')).single;
    await controller.logHabit(habit);
    await controller.logHabit(habit);

    final occurrences = await database
        .select(database.plannerOccurrences)
        .get();
    expect(occurrences, hasLength(1));
    expect(occurrences.single.status, 'completed');

    await controller.logHabit(habit, outcome: 'missed');
    await controller.logHabit(habit, note: 'Back on track');
    final corrected = await controller.habitDaySummary(habit);
    expect(corrected.isSuccessful, isTrue);
    expect(corrected.note, 'Back on track');
    expect(
      await database.select(database.plannerOccurrences).get(),
      hasLength(1),
      reason: 'checked → missed → checked edits one stable calendar-day row.',
    );
    expect(
      (await local.listPendingOperations(
        'controller-owner',
      )).where((operation) => operation.entityId == habit.id),
      hasLength(5),
      reason:
          'Create plus four semantic daily edits each have a unique mutation.',
    );
    expect(reminders.syncs, greaterThanOrEqualTo(2));

    expect(
      await controller.enableReminders(),
      PlannerReminderActivation.enabled,
    );
    expect(reminders.enableCalls, 1);
  });

  test(
    'measured habits aggregate to one goal-aware daily result and can undo',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => DateTime.utc(2026, 7, 27, 9),
      );
      addTearDown(controller.disposeAsync);
      await controller.start();

      await controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Read'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'count',
            'target': 10,
            'goal': 'at_least',
            'unit': 'pages',
          },
        },
      );
      final habit = (await local.readActiveEntities('controller-owner')).single;

      final partial = await controller.logHabit(habit, value: 2);
      expect(partial.state.name, 'partial');
      expect(partial.progressPercent, 20);
      expect(partial.amount, 2);

      final complete = await controller.logHabit(
        habit,
        value: 12,
        note: 'Chapter one',
      );
      expect(complete.isSuccessful, isTrue);
      expect(complete.amount, 12);
      expect(complete.note, 'Chapter one');
      expect(
        await database.select(database.plannerOccurrences).get(),
        hasLength(1),
        reason: 'Today has one quota-bearing completion, not two log slots.',
      );

      await controller.markTodayMissed(habit);
      final missed = await controller.habitDaySummary(habit);
      expect(missed.state.name, 'missed');
      expect(
        missed.amount,
        12,
        reason: 'Manual miss preserves the measurement.',
      );

      final undone = await controller.undoHabitDay(habit);
      expect(undone.isPending, isTrue);
      expect(
        (await database.select(database.plannerOccurrences).get())
            .single
            .status,
        'pending',
      );
    },
  );

  test('checklist habit uses its custom success condition', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'controller-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'controller-owner',
      now: () => DateTime.utc(2026, 7, 27, 9),
    );
    addTearDown(controller.disposeAsync);
    await controller.start();

    await controller.saveEntity(
      kind: PlannerEntityKind.habit,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Morning routine'),
        PlannerPayloadKeys.tracking: const <String, dynamic>{
          'method': 'checklist',
          'checklist': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'water', 'label': 'Water'},
            <String, dynamic>{'id': 'stretch', 'label': 'Stretch'},
            <String, dynamic>{'id': 'journal', 'label': 'Journal'},
          ],
          'success_condition': <String, dynamic>{'type': 'count', 'value': 2},
        },
      },
    );
    final habit = (await local.readActiveEntities('controller-owner')).single;

    final partial = await controller.logHabit(
      habit,
      checkedItemIds: const <String>{'water'},
    );
    expect(partial.state.name, 'partial');
    expect(partial.checkedCount, 1);
    expect(partial.requiredCount, 2);

    final complete = await controller.logHabit(
      habit,
      checkedItemIds: const <String>{'water', 'stretch'},
    );
    expect(complete.isSuccessful, isTrue);
    expect(complete.progressPercent, 67);
    await controller.markTodayMissed(habit);
    final missed = await controller.habitDaySummary(habit);
    expect(missed.state.name, 'missed');
    expect(missed.checkedItemIds, containsAll(<String>['water', 'stretch']));
    expect(
      await database.select(database.plannerOccurrences).get(),
      hasLength(1),
    );
  });

  test(
    'avoid habit records clear days and slips as opposite outcomes',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => DateTime.utc(2026, 7, 27, 9),
      );
      addTearDown(controller.disposeAsync);
      await controller.start();

      await controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'No soda'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'avoid',
          },
        },
      );
      final habit = (await local.readActiveEntities('controller-owner')).single;

      expect(
        (await controller.logHabit(habit, outcome: 'avoided')).state.name,
        'completed',
      );
      expect(
        (await controller.logHabit(habit, outcome: 'slipped')).state.name,
        'missed',
      );
      expect(
        (await controller.logHabit(habit, outcome: 'avoided')).state.name,
        'completed',
        reason: 'avoided → slipped → avoided must not reuse a stale mutation.',
      );
      expect(
        await database.select(database.plannerOccurrences).get(),
        hasLength(1),
      );
    },
  );

  test(
    'habit backfill keeps one dated row, records correction provenance, and rejects future logs',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final now = DateTime.utc(2026, 7, 27, 9);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => now,
      );
      addTearDown(controller.disposeAsync);
      await controller.start();
      await controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Journal'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'check',
          },
        },
      );
      final habit = (await local.readActiveEntities('controller-owner')).single;
      final backfillDay = DateTime(2026, 7, 25);

      await controller.logHabit(
        habit,
        localDay: backfillDay,
        note: 'Remembered later',
      );
      var rows = await local.readOccurrences(
        'controller-owner',
        entityId: habit.id,
      );
      expect(rows, hasLength(1));
      expect(rows.single.value['source'], 'manual_backfill');
      expect(rows.single.value['note'], 'Remembered later');

      await controller.logHabit(
        habit,
        localDay: backfillDay,
        outcome: 'missed',
        note: 'Corrected after review',
      );
      rows = await local.readOccurrences(
        'controller-owner',
        entityId: habit.id,
      );
      expect(rows, hasLength(1));
      expect(rows.single.value['source'], 'manual_correction');
      expect(rows.single.value['note'], 'Corrected after review');

      final pending = await controller.undoHabitDay(
        habit,
        localDay: backfillDay,
      );
      expect(pending.isPending, isTrue);
      rows = await local.readOccurrences(
        'controller-owner',
        entityId: habit.id,
      );
      expect(rows.single.value['source'], 'manual_backfill_undo');

      await expectLater(
        controller.logHabit(habit, localDay: DateTime(2026, 7, 28)),
        throwsArgumentError,
      );
    },
  );

  test(
    'duplicate gets a fresh identity and configuration without progress or history',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final now = DateTime.utc(2026, 7, 27, 9);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => now,
      );
      addTearDown(controller.disposeAsync);
      await controller.start();
      await controller.saveEntity(
        kind: PlannerEntityKind.oneOffTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Reusable deep work'),
          PlannerPayloadKeys.status: PlannerEntityStatus.completed.wireValue,
          PlannerPayloadKeys.taskProgressState:
              PlannerTaskProgressState.completed.wireValue,
          PlannerPayloadKeys.taskProgressPercent: 100,
          PlannerPayloadKeys.recovery: const <String, dynamic>{
            PlannerRecoveryKeys.onMiss: 'carry',
            PlannerRecoveryKeys.carryCap: 3,
            PlannerRecoveryKeys.carryCount: 2,
            PlannerRecoveryKeys.resolution: 'carried',
          },
          PlannerTaskMetadataKeys.labels: const <String>['Work', 'Deep'],
          PlannerTaskMetadataKeys.estimateMinutes: 45,
          'checklist': const <Map<String, dynamic>>[
            <String, dynamic>{'title': 'Outline', 'is_done': true},
          ],
        },
      );
      final source = (await local.readActiveEntities(
        'controller-owner',
      )).single;
      await local.appendOccurrence(
        ownerId: 'controller-owner',
        entityId: source.id,
        plannedFor: now,
        status: 'completed',
      );

      final duplicate = await controller.duplicateEntity(source);

      expect(duplicate.id, isNot(source.id));
      expect(duplicate.createdAt, now);
      expect(duplicate.status, PlannerEntityStatus.active);
      expect(
        PlannerTaskProgress.fromEntity(duplicate),
        const PlannerTaskProgress.pending(),
      );
      expect(duplicate.payload[PlannerTaskMetadataKeys.labels], const <String>[
        'Work',
        'Deep',
      ]);
      expect(duplicate.payload[PlannerTaskMetadataKeys.estimateMinutes], 45);
      expect(
        safeJsonMapList(duplicate.payload['checklist']).single['is_done'],
        isFalse,
      );
      expect(duplicate.recovery[PlannerRecoveryKeys.onMiss], 'carry');
      expect(
        duplicate.recovery.containsKey(PlannerRecoveryKeys.carryCount),
        isFalse,
      );
      expect(
        await local.readOccurrences('controller-owner', entityId: duplicate.id),
        isEmpty,
      );
      expect(
        await local.readOccurrences('controller-owner', entityId: source.id),
        hasLength(1),
      );
    },
  );

  test('focus start is restart-safe and reuses one active session', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'controller-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'controller-owner',
      now: () => DateTime.utc(2026, 7, 27, 9),
    );
    addTearDown(controller.disposeAsync);
    await controller.start();

    await controller.saveEntity(
      kind: PlannerEntityKind.oneOffTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Deep work'),
        'focus': const <String, dynamic>{
          PlannerFocusPresetKeys.breakPolicy: 'pomodoro_cycle',
          PlannerFocusPresetKeys.shortBreakMinutes: 7,
          PlannerFocusPresetKeys.longBreakMinutes: 20,
          PlannerFocusPresetKeys.longBreakAfterCycles: 3,
        },
      },
    );
    final task = (await local.readActiveEntities('controller-owner')).single;

    final first = await controller.beginFocus(
      entity: task,
      mode: 'countdown',
      plannedMinutes: 45,
    );
    final reopened = await controller.beginFocus(
      entity: task,
      mode: 'pomodoro',
      plannedMinutes: 25,
    );

    expect(reopened.id, first.id);
    expect(reopened.mode, 'countdown');
    expect(reopened.payload['planned_duration_minutes'], 45);
    expect(
      reopened.payload[PlannerFocusPresetKeys.breakPolicy],
      'pomodoro_cycle',
    );
    expect(reopened.payload[PlannerFocusPresetKeys.shortBreakMinutes], 7);
    expect(reopened.payload[PlannerFocusPresetKeys.longBreakMinutes], 20);
    expect(reopened.payload[PlannerFocusPresetKeys.longBreakAfterCycles], 3);
    expect(
      await database.select(database.plannerFocusSessions).get(),
      hasLength(1),
    );

    await controller.completeFocus(
      reopened,
      elapsed: const Duration(minutes: 12),
    );
    expect(await controller.activeFocusSession(), isNull);

    final next = await controller.beginFocus(
      entity: task,
      mode: 'pomodoro',
      plannedMinutes: 35,
    );
    expect(next.id, isNot(first.id));
    expect(next.payload['planned_duration_minutes'], 35);
  });

  test(
    'recurring task completion is a daily occurrence, never a completed series',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final now = DateTime.utc(2026, 7, 27, 9);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => now,
      );
      addTearDown(controller.disposeAsync);
      await controller.start();

      await controller.saveEntity(
        kind: PlannerEntityKind.recurringTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Daily review'),
          PlannerPayloadKeys.recurrence: const <String, dynamic>{
            'rule': 'daily',
          },
        },
      );
      final task = (await local.readActiveEntities('controller-owner')).single;

      await controller.toggleCompletion(task);
      final recorded = await controller.recurringOccurrenceForDay(task, now);
      final series = await local.readEntity(
        ownerId: 'controller-owner',
        entityId: task.id,
      );
      expect(recorded!.status, 'completed');
      expect(series!.status, PlannerEntityStatus.active);

      await controller.toggleCompletion(task);
      final reopened = await controller.recurringOccurrenceForDay(task, now);
      expect(reopened!.status, 'pending');
      expect(reopened.completedAt, isNull);
    },
  );

  test('rapid task taps retain every four-state transition in order', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'controller-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'controller-owner',
      now: () => DateTime.utc(2026, 7, 27, 9),
    );
    addTearDown(controller.disposeAsync);
    await controller.start();

    await controller.saveEntity(
      kind: PlannerEntityKind.oneOffTask,
      payload: defaultPlannerPayload(title: 'Cycle without losing taps'),
    );
    final task = (await local.readActiveEntities('controller-owner')).single;

    final outcomes = await Future.wait(
      List<Future<PlannerTaskProgress>>.generate(
        4,
        (_) => controller.cycleTaskProgress(task),
      ),
    );

    expect(outcomes.map((outcome) => outcome.state), <PlannerTaskProgressState>[
      PlannerTaskProgressState.completed,
      PlannerTaskProgressState.missed,
      PlannerTaskProgressState.partial,
      PlannerTaskProgressState.pending,
    ]);
    final saved = await local.readEntity(
      ownerId: 'controller-owner',
      entityId: task.id,
    );
    expect(
      PlannerTaskProgress.fromEntity(saved!),
      const PlannerTaskProgress.pending(),
    );
    expect(
      (await local.listPendingOperations(
        'controller-owner',
      )).where((operation) => operation.entityId == task.id),
      hasLength(5),
      reason: 'The create plus each of the four taps stays durable for sync.',
    );
  });

  test(
    'task outcome receipts preserve each prior state under rapid taps',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => DateTime.utc(2026, 7, 27, 9),
      );
      addTearDown(controller.disposeAsync);
      await controller.start();
      await controller.saveEntity(
        kind: PlannerEntityKind.oneOffTask,
        payload: defaultPlannerPayload(title: 'Receipt for Undo'),
      );
      final task = (await local.readActiveEntities('controller-owner')).single;
      final first = await controller.cycleTaskProgressWithReceipt(task);
      expect(first.previous, const PlannerTaskProgress.pending());
      expect(first.current.state, PlannerTaskProgressState.completed);
      final second = await controller.cycleTaskProgressWithReceipt(task);
      expect(second.previous, first.current);
      expect(second.current.state, PlannerTaskProgressState.missed);
      expect(await controller.undoTaskProgress(first), isFalse);
      final unchanged = await controller.taskProgressForDay(task);
      expect(unchanged.state, PlannerTaskProgressState.missed);
      expect(unchanged.percent, second.current.percent);
      expect(await controller.undoTaskProgress(second), isTrue);
      final restored = await controller.taskProgressForDay(task);
      expect(restored.state, PlannerTaskProgressState.completed);
      expect(restored.percent, second.previous.percent);
      expect(await controller.undoTaskProgress(second), isFalse);
      final concurrent = await Future.wait([
        controller.cycleTaskProgressWithReceipt(task),
        controller.cycleTaskProgressWithReceipt(task),
      ]);
      final states =
          concurrent
              .map((change) => change.current.state)
              .toList(growable: false)
            ..sort((a, b) => a.index.compareTo(b.index));
      expect(states, <PlannerTaskProgressState>[
        PlannerTaskProgressState.missed,
        PlannerTaskProgressState.partial,
      ]);
      expect(concurrent[0].previous, concurrent[0].previous.normalized);
      expect(concurrent[1].previous, concurrent[1].previous.normalized);
    },
  );

  test('an exact-value edit invalidates an older Undo receipt', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'controller-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'controller-owner',
      now: () => DateTime.utc(2026, 7, 27, 9),
    );
    addTearDown(controller.disposeAsync);
    await controller.start();
    await controller.saveEntity(
      kind: PlannerEntityKind.oneOffTask,
      payload: defaultPlannerPayload(title: 'Exact edit'),
    );
    final task = (await local.readActiveEntities('controller-owner')).single;
    final receipt = await controller.cycleTaskProgressWithReceipt(task);
    await controller.setTaskProgress(
      task,
      progress: receipt.current,
      source: 'app_exact_percent',
    );
    expect(await controller.undoTaskProgress(receipt), isFalse);
    expect(
      (await controller.taskProgressForDay(task)).state,
      PlannerTaskProgressState.completed,
    );
  });

  test(
    'a recurring outcome immediately republishes the widget projection',
    () async {
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final widgetBridge = _RecordingTodayWidgetBridge();
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'controller-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'controller-owner',
        now: () => DateTime.utc(2026, 7, 27, 9),
        todayWidgetBridge: widgetBridge,
      );
      addTearDown(controller.disposeAsync);
      await controller.start();

      await controller.saveEntity(
        kind: PlannerEntityKind.recurringTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Daily widget review'),
          PlannerPayloadKeys.recurrence: const <String, dynamic>{
            'rule': 'daily',
          },
        },
      );
      final task = (await local.readActiveEntities('controller-owner')).single;
      final projectionRevision = controller.todayProjectionRevision;

      await controller.cycleTaskProgress(task);

      expect(
        controller.todayProjectionRevision,
        greaterThan(projectionRevision),
      );
      expect(widgetBridge.lastItems, hasLength(1));
      expect(widgetBridge.lastItems.single.entityId, task.id);
      expect(widgetBridge.lastItems.single.progress.isComplete, isTrue);
    },
  );

  test('shutdown during startup cannot publish an old-owner widget', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final widgetBridge = _DelayedTodayWidgetBridge();
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'old-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'old-owner',
      todayWidgetBridge: widgetBridge,
    );

    final starting = controller.start();
    controller.requestShutdown();
    widgetBridge.completeSettings();
    await starting;

    expect(controller.isReady, isFalse);
    expect(widgetBridge.publishCalls, 0);
    await controller.disposeAsync();
  });

  test('resume performs a full remote sync before refreshing today', () async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final remote = _CountingGateway();
    final controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        remote,
        ownerId: 'resume-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'resume-owner',
    );
    addTearDown(controller.disposeAsync);
    await controller.start();
    await controller.refresh();
    final pullsBeforeResume = remote.pullCalls;
    final projectionBeforeResume = controller.todayProjectionRevision;

    await controller.resume();

    expect(
      remote.pullCalls,
      pullsBeforeResume + 2,
      reason:
          'A complete sync pulls once before and once after pending pushes.',
    );
    expect(
      controller.todayProjectionRevision,
      greaterThan(projectionBeforeResume),
    );
  });
}

class _RecordingReminderScheduler implements PlannerReminderScheduler {
  int enableCalls = 0;
  int syncs = 0;
  PlannerReminderSettings _settings = const PlannerReminderSettings();

  @override
  Future<void> dispose() async {}

  @override
  Future<PlannerReminderActivation> enable({
    bool requestExactTiming = false,
  }) async {
    enableCalls++;
    _settings = _settings.copyWith(
      enabled: true,
      exactTiming: requestExactTiming,
    );
    return PlannerReminderActivation.enabled;
  }

  @override
  Future<PlannerReminderSettings> readSettings() async => _settings;

  @override
  Future<void> saveSettings(PlannerReminderSettings settings) async {
    _settings = settings;
  }

  @override
  Future<PlannerReminderScheduleSummary> sync(
    Iterable<PlannerEntity> entities,
  ) async {
    syncs++;
    return PlannerReminderScheduleSummary(
      scheduled: _settings.enabled ? entities.length : 0,
      disabled: !_settings.enabled,
    );
  }
}

class _DisconnectedGateway implements PlannerRemoteGateway {
  @override
  Future<PlannerRemoteMutationResult> apply(PlannerRemoteMutation mutation) =>
      Future<PlannerRemoteMutationResult>.error(StateError('offline for test'));

  @override
  Future<void> dispose() async {}

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async => PlannerRemoteChangePage(
    changes: const <PlannerRemoteChange>[],
    requestedLimit: limit,
  );

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<void> subscribe(void Function() onChangeHint) async {}
}

class _CountingGateway implements PlannerRemoteGateway {
  int pullCalls = 0;

  @override
  Future<PlannerRemoteMutationResult> apply(PlannerRemoteMutation mutation) =>
      throw StateError('No mutation was expected.');

  @override
  Future<void> dispose() async {}

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async {
    pullCalls++;
    return PlannerRemoteChangePage(
      changes: const <PlannerRemoteChange>[],
      requestedLimit: limit,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<void> subscribe(void Function() onChangeHint) async {}
}

class _RecordingTodayWidgetBridge extends PerfectTodayWidgetBridge {
  List<PerfectTodayWidgetItem> lastItems = const <PerfectTodayWidgetItem>[];

  @override
  Future<PerfectTodayWidgetSettings> readSettings() async =>
      const PerfectTodayWidgetSettings(isAvailable: true, showTaskTitles: true);

  @override
  Future<List<PlannerWidgetTaskAction>> pendingActions() async =>
      const <PlannerWidgetTaskAction>[];

  @override
  Future<void> publish({
    required String ownerId,
    required DateTime now,
    required Iterable<PerfectTodayWidgetItem> items,
    required bool showTaskTitles,
  }) async {
    lastItems = items.toList(growable: false);
  }
}

class _DelayedTodayWidgetBridge extends PerfectTodayWidgetBridge {
  final Completer<PerfectTodayWidgetSettings> _settings =
      Completer<PerfectTodayWidgetSettings>();
  int publishCalls = 0;

  void completeSettings() {
    _settings.complete(
      const PerfectTodayWidgetSettings(isAvailable: true, showTaskTitles: true),
    );
  }

  @override
  Future<PerfectTodayWidgetSettings> readSettings() => _settings.future;

  @override
  Future<void> publish({
    required String ownerId,
    required DateTime now,
    required Iterable<PerfectTodayWidgetItem> items,
    required bool showTaskTitles,
  }) async {
    publishCalls++;
  }
}
