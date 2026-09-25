import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/notifications/planner_reminder_scheduler.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:perfect/widgets/perfect_today_widget_projector.dart';
import 'package:uuid/uuid.dart';

/// A thin presentation controller. It only observes the local Drift source of
/// truth; sync stays asynchronous and is never a prerequisite for rendering.
class PlannerWorkspaceController extends ChangeNotifier {
  PlannerWorkspaceController(
    this._localStore,
    this._syncRepository, {
    required this.ownerId,
    DateTime Function()? now,
    Uuid? uuid,
    PlannerReminderScheduler? reminderScheduler,
    PerfectTodayWidgetBridge? todayWidgetBridge,
  }) : _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid(),
       _reminderScheduler =
           reminderScheduler ?? const NoopPlannerReminderScheduler(),
       _todayWidgetBridge =
           todayWidgetBridge ?? const PerfectTodayWidgetBridge();

  final String ownerId;
  final PlannerLocalStore _localStore;
  final PlannerSyncRepository _syncRepository;
  final DateTime Function() _now;
  final Uuid _uuid;
  final PlannerReminderScheduler _reminderScheduler;
  final PerfectTodayWidgetBridge _todayWidgetBridge;
  StreamSubscription<List<PlannerEntity>>? _entitiesSubscription;
  Timer? _dayBoundaryTimer;
  late final VoidCallback _syncListener = _onSyncChanged;

  List<PlannerEntity> _entities = const <PlannerEntity>[];
  bool _isReady = false;
  Object? _localError;
  bool _disposed = false;
  bool _shutdownRequested = false;
  int _todayProjectionRevision = 0;
  Future<void> _taskProgressSerial = Future<void>.value();
  final Map<String, String> _latestTaskProgressMutation = <String, String>{};
  Future<void> _habitLogSerial = Future<void>.value();
  Future<void> _focusSerial = Future<void>.value();
  PerfectTodayWidgetSettings _todayWidgetSettings =
      const PerfectTodayWidgetSettings(
        isAvailable: false,
        showTaskTitles: true,
      );
  late final PlannerTaskProgressService _taskProgressService =
      PlannerTaskProgressService(
        _localStore,
        ownerId: ownerId,
        now: _now,
        uuid: _uuid,
      );
  late final PerfectTodayWidgetProjector _todayWidgetProjector =
      PerfectTodayWidgetProjector(
        _localStore,
        ownerId: ownerId,
        bridge: _todayWidgetBridge,
        taskProgressService: _taskProgressService,
        now: _now,
      );

  List<PlannerEntity> get entities => _entities;
  bool get isReady => _isReady;
  Object? get localError => _localError;
  PlannerSyncStatus get syncStatus => _syncRepository.syncStatus.value;
  DateTime get localNow => _now().toLocal();
  PerfectTodayWidgetSettings get todayWidgetSettings => _todayWidgetSettings;
  int get todayProjectionRevision => _todayProjectionRevision;

  List<PlannerEntity> get tasks => _entities
      .where(
        (entity) =>
            entity.kind == PlannerEntityKind.oneOffTask ||
            entity.kind == PlannerEntityKind.recurringTask,
      )
      .toList(growable: false);
  List<PlannerEntity> get habits => _entities
      .where((entity) => entity.kind == PlannerEntityKind.habit)
      .toList(growable: false);
  List<PlannerEntity> get projects => _entities
      .where((entity) => entity.kind == PlannerEntityKind.project)
      .toList(growable: false);
  List<PlannerEntity> get areas => _entities
      .where((entity) => entity.kind == PlannerEntityKind.area)
      .toList(growable: false);

  /// Stable lookup for query-resolved IDs; null when the ID is not cached.
  PlannerEntity? entityById(String id) {
    for (final entity in _entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  /// Stage 36 query contract: the ONE shared Tasks workspace read.
  ///
  /// Resolves [query] over the cached task-kind snapshot, so every Tasks
  /// consumer shares one typed projection and no caller adds a second hidden
  /// predicate after the result.
  PlannerTaskQueryResult queryTasks(PlannerTaskQuery query) =>
      query.applyTo(tasks);

  Future<void> start() async {
    if (_disposed || _shutdownRequested || _isReady) return;
    _todayWidgetSettings = await _todayWidgetBridge.readSettings();
    if (_disposed || _shutdownRequested) return;
    _entitiesSubscription = _localStore
        .watchActiveEntities(ownerId)
        .listen(
          (entities) {
            if (_disposed || _shutdownRequested) return;
            _entities = entities;
            _localError = null;
            unawaited(_publishTodayWidget());
            _notify();
          },
          onError: (Object error) {
            if (_disposed || _shutdownRequested) return;
            _localError = error;
            _notify();
          },
        );
    _syncRepository.syncStatus.addListener(_syncListener);
    try {
      await _syncRepository.start();
    } on Object catch (error) {
      if (_shutdownRequested) return;
      // Local usage stays available when remote subscription/bootstrap fails.
      _localError = error;
    }
    if (_disposed || _shutdownRequested) return;
    _isReady = true;
    _notify();
    unawaited(_refreshReminders());
    unawaited(reconcileTodayWidgetActions());
    unawaited(_publishTodayWidget());
    _scheduleNextLocalDayRefresh();
  }

  Future<void> refresh() => _syncRepository.syncNow();

  /// Reconciles native work first, then performs a real remote sync before
  /// rebuilding date-sensitive projections. Resuming therefore recovers from
  /// a missed realtime hint instead of only repainting stale local data.
  Future<void> resume() async {
    if (_disposed || _shutdownRequested) return;
    await reconcileTodayWidgetActions();
    if (_disposed || _shutdownRequested) return;
    await _syncRepository.syncNow();
    if (_disposed || _shutdownRequested) return;
    await refreshTodayProjection();
  }

  Future<PlannerMutationReceipt> quickCapture(String title) async {
    final receipt = await _localStore.createQuickTask(
      ownerId: ownerId,
      title: title,
    );
    unawaited(_syncRepository.syncNow());
    return receipt;
  }

  Future<void> saveEntity({
    required PlannerEntityKind kind,
    PlannerEntity? existing,
    required Map<String, dynamic> payload,
  }) async {
    final now = _now().toUtc();
    final entity = existing == null
        ? PlannerEntity(
            id: _uuid.v4(),
            ownerId: ownerId,
            kind: kind,
            payload: payload,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(kind: kind, payload: payload, updatedAt: now);
    await _localStore.upsertEntity(
      entity: entity,
      patch: PlannerFieldPatch.replacePayload(payload),
    );
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
  }

  /// Creates an independent planner item with the same configuration and a
  /// fresh identity. Runtime progress stays with the source record: occurrence
  /// and focus history are separate tables keyed by entity ID and are never
  /// copied.
  Future<PlannerEntity> duplicateEntity(PlannerEntity source) async {
    if (source.ownerId != ownerId) {
      throw StateError('Only an item in this workspace can be duplicated.');
    }
    final now = _now().toUtc();
    final payload = <String, dynamic>{...source.payload};
    payload[PlannerPayloadKeys.status] = PlannerEntityStatus.active.wireValue;
    payload[PlannerPayloadKeys.taskProgressState] =
        PlannerTaskProgressState.pending.wireValue;
    payload[PlannerPayloadKeys.taskProgressPercent] = 0;
    payload.remove('completed_at');
    payload.remove('cancelled_at');

    final recovery = <String, dynamic>{...source.recovery}
      ..remove(PlannerRecoveryKeys.carryCount)
      ..remove(PlannerRecoveryKeys.resolution)
      ..remove(PlannerRecoveryKeys.disposition)
      ..remove(PlannerRecoveryKeys.resolvedFor)
      ..remove(PlannerRecoveryKeys.resolvedAt);
    payload[PlannerPayloadKeys.recovery] = recovery;

    final checklist = payload['checklist'];
    if (checklist is Iterable && checklist is! String) {
      payload['checklist'] = checklist
          .map(
            (entry) => <String, dynamic>{
              ...safeJsonMap(entry),
              'is_done': false,
            },
          )
          .toList(growable: false);
    }

    final duplicate = PlannerEntity(
      id: _uuid.v4(),
      ownerId: ownerId,
      kind: source.kind,
      payload: payload,
      createdAt: now,
      updatedAt: now,
    );
    final receipt = await _localStore.upsertEntity(
      entity: duplicate,
      patch: PlannerFieldPatch.replacePayload(payload),
    );
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
    return receipt.entity ?? duplicate;
  }

  Future<void> toggleCompletion(PlannerEntity entity) async {
    if (entity.kind == PlannerEntityKind.habit) {
      // Habits are never completed as a whole. A tap records a dated check-in
      // instead, so tomorrow remains available and the series stays intact.
      await logHabit(entity);
      return;
    }
    if (entity.kind == PlannerEntityKind.recurringTask) {
      await _toggleRecurringOccurrence(entity);
      return;
    }
    await _setLegacyOneOffCompletion(entity);
    await _finalizeTaskProgressMutation();
  }

  /// The task check control is intentionally richer than a boolean checkbox:
  /// empty → done → not done → partial → empty. Calls are serialized so rapid
  /// taps cannot read the same stale state and collapse part of the cycle.
  /// Each mutation returns the prior/current outcome so the host can undo one
  /// exact step without guessing which tap finished last.
  Future<PlannerTaskProgress> cycleTaskProgress(PlannerEntity entity) async =>
      (await cycleTaskProgressWithReceipt(entity)).current;

  Future<PlannerTaskProgressChange> cycleTaskProgressWithReceipt(
    PlannerEntity entity,
  ) => _serializeTaskProgress(() async {
    final mutationId = _uuid.v4();
    final localDay = _dateOnly(_now().toLocal());
    final previous = await _taskProgressService.readEntityProgress(
      entityId: entity.id,
      localDay: localDay,
    );
    if (previous == null) {
      throw StateError('Task is no longer available locally.');
    }
    final current = await _taskProgressService.cycle(
      entity,
      mutationId: mutationId,
      localDay: localDay,
      source: 'app',
    );
    await _finalizeTaskProgressMutation();
    _latestTaskProgressMutation[entity.id] = mutationId;
    return PlannerTaskProgressChange(
      entityId: entity.id,
      mutationId: mutationId,
      previous: previous,
      current: current,
      localDay: localDay,
    );
  });

  /// Restores the exact prior outcome only when [change] is still the latest
  /// local state. A stale receipt is rejected so an Undo can never overwrite a
  /// newer tap, widget action, or remote convergence.
  Future<bool> undoTaskProgress(PlannerTaskProgressChange change) =>
      _serializeTaskProgress(() async {
        final current = await _taskProgressService.readEntityProgress(
          entityId: change.entityId,
          localDay: change.localDay,
        );
        if (current == null || current != change.current) return false;
        if (_latestTaskProgressMutation[change.entityId] != change.mutationId) {
          return false;
        }
        final undoMutationId = _uuid.v4();
        await _taskProgressService.setProgressById(
          entityId: change.entityId,
          progress: change.previous,
          mutationId: undoMutationId,
          localDay: change.localDay,
          source: 'task_undo',
        );
        _latestTaskProgressMutation[change.entityId] = undoMutationId;
        await _finalizeTaskProgressMutation();
        return true;
      });

  Future<PlannerTaskProgress> setTaskProgress(
    PlannerEntity entity, {
    required PlannerTaskProgress progress,
    String? mutationId,
    DateTime? localDay,
    String source = 'app',
  }) => _serializeTaskProgress(() async {
    final resolvedMutationId = mutationId ?? _uuid.v4();
    final result = await _taskProgressService.setProgress(
      entity,
      progress: progress,
      mutationId: resolvedMutationId,
      localDay: localDay,
      source: source,
    );
    _latestTaskProgressMutation[entity.id] = resolvedMutationId;
    await _finalizeTaskProgressMutation();
    return result;
  });

  Future<PlannerTaskProgress> taskProgressForDay(
    PlannerEntity entity, {
    DateTime? localDay,
  }) async =>
      await _taskProgressService.readEntityProgress(
        entityId: entity.id,
        localDay: localDay,
      ) ??
      (throw StateError('Task is no longer available locally.'));

  Future<PlannerTodayEligibility> todayEligibilityForDay(
    PlannerEntity entity, {
    DateTime? localDay,
  }) => _localStore.evaluateTodayEligibility(
    ownerId: ownerId,
    entity: entity,
    day: localDay ?? localNow,
  );

  Future<void> resolveOneOffRecovery(
    PlannerEntity entity, {
    required PlannerRecoveryDisposition disposition,
    int? carryCount,
  }) async {
    await _localStore.resolveOneOffRecovery(
      ownerId: ownerId,
      entityId: entity.id,
      disposition: disposition,
      occurrenceAt: entity.scheduledAt,
      now: _now(),
      carryCount: carryCount,
    );
    await _finalizeTaskProgressMutation();
  }

  Future<void> setTodayWidgetTitleVisibility(bool showTitles) async {
    _todayWidgetSettings = await _todayWidgetBridge.setShowTaskTitles(
      showTitles,
    );
    await _publishTodayWidget();
    _notify();
  }

  Future<bool> requestTodayWidgetPin() => _todayWidgetBridge.requestPin();

  Future<void> clearTodayWidgetForSignOut() =>
      _todayWidgetBridge.clearForSignOut();

  /// Stops startup callbacks from publishing data for a workspace whose auth
  /// scope has already disappeared. Final resource disposal remains serialized
  /// after any in-flight startup await.
  void requestShutdown() {
    _shutdownRequested = true;
    _dayBoundaryTimer?.cancel();
  }

  /// Recomputes every date-sensitive local surface. It is safe to call after
  /// resume even if no entity changed while the app was in the background.
  Future<void> refreshTodayProjection() async {
    if (_disposed || _shutdownRequested) return;
    _entities = await _localStore.readActiveEntities(ownerId);
    if (_disposed) return;
    _notify();
    unawaited(_refreshReminders());
    await _publishTodayWidget();
    _scheduleNextLocalDayRefresh();
  }

  /// Replays native widget outcomes and quick captures through the same local
  /// planner services used by Flutter. Native queues are retained until a
  /// separate acknowledgement: mutation IDs make every replay safe across
  /// worker retry, app restart, and a crash between write/ack.
  Future<void> reconcileTodayWidgetActions() async {
    if (_disposed || _shutdownRequested || !_todayWidgetSettings.isAvailable) {
      return;
    }
    final pending = await Future.wait<Object>(<Future<Object>>[
      _todayWidgetBridge.pendingActions(),
      _todayWidgetBridge.pendingQuickAdds(),
    ]);
    final actions = pending[0] as List<PlannerWidgetTaskAction>;
    final quickAdds = pending[1] as List<PerfectTodayWidgetQuickAdd>;
    if (actions.isEmpty && quickAdds.isEmpty) return;
    var sawCurrentOwnerAction = false;
    final acknowledgedQuickAddIds = <String>[];
    for (final request in quickAdds) {
      if (request.ownerId != ownerId) continue;
      try {
        await _localStore.createQuickTask(
          ownerId: ownerId,
          title: request.title,
          scheduledAt: request.scheduledAt,
          mutationId: request.id,
          now: request.occurredAt,
        );
        sawCurrentOwnerAction = true;
        acknowledgedQuickAddIds.add(request.id);
      } on StateError {
        // A conflicting/corrupt mutation ID remains queued for inspection
        // instead of silently creating a second task.
      }
    }
    await _todayWidgetBridge.acknowledgeQuickAdds(acknowledgedQuickAddIds);
    final acknowledgedActionIds = <String>[];
    for (final action in actions) {
      if (action.ownerId != ownerId) continue;
      try {
        await _serializeTaskProgress(
          () => _taskProgressService.applyWidgetAction(action),
        );
        sawCurrentOwnerAction = true;
        acknowledgedActionIds.add(action.id);
      } on StateError {
        // A task may have been archived or changed on another device. The next
        // local projection replaces the optimistic widget row safely.
        acknowledgedActionIds.add(action.id);
      }
    }
    await _todayWidgetBridge.acknowledgeActions(acknowledgedActionIds);
    if (!sawCurrentOwnerAction || _disposed) return;
    _entities = await _localStore.readActiveEntities(ownerId);
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
    await _publishTodayWidget();
    _notify();
  }

  Future<void> deleteEntity(PlannerEntity entity) =>
      deleteEntityById(entity.id);

  Future<void> deleteEntityById(String entityId) async {
    await _localStore.softDeleteEntity(ownerId: ownerId, entityId: entityId);
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
  }

  /// Kept as the compatibility name for existing callers. Archiving is a
  /// reversible local tombstone, not a destructive delete.
  Future<void> archiveEntity(PlannerEntity entity) => deleteEntity(entity);

  Future<void> restoreEntity(PlannerEntity entity) async {
    await _localStore.restoreEntity(ownerId: ownerId, entityId: entity.id);
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
  }

  Future<List<PlannerEntity>> archivedEntities() =>
      _localStore.readArchivedEntities(ownerId);

  Future<void> postponeToTomorrow(PlannerEntity entity) async {
    final now = _now().toLocal();
    final current = entity.scheduledAt?.toLocal();
    final next = DateTime(
      now.year,
      now.month,
      now.day + 1,
      current?.hour ?? 9,
      current?.minute ?? 0,
    );
    final payload = <String, dynamic>{
      ...entity.payload,
      PlannerPayloadKeys.timing: <String, dynamic>{
        ...entity.timing,
        'scheduled_at': next.toUtc().toIso8601String(),
      },
    };
    await _localStore.upsertEntity(
      entity: entity.copyWith(payload: payload, updatedAt: _now().toUtc()),
      patch: PlannerFieldPatch(<String, dynamic>{
        '/${PlannerPayloadKeys.timing}/scheduled_at': next
            .toUtc()
            .toIso8601String(),
      }),
    );
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
  }

  Future<void> markTodayMissed(PlannerEntity entity) async {
    if (entity.kind == PlannerEntityKind.oneOffTask ||
        entity.kind == PlannerEntityKind.project ||
        entity.kind == PlannerEntityKind.area) {
      throw UnsupportedError(
        'Only recurring tasks and habits have daily misses.',
      );
    }
    final localNow = _now().toLocal();
    if (entity.kind == PlannerEntityKind.recurringTask) {
      await setTaskProgress(
        entity,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.missed,
          percent: 0,
        ),
        localDay: localNow,
        source: 'manual_miss',
      );
      return;
    }
    if (entity.kind == PlannerEntityKind.habit) {
      final summary = await habitDaySummary(entity);
      await logHabit(
        entity,
        value:
            (summary.method == 'count' ||
                summary.method == 'numeric' ||
                summary.method == 'duration')
            ? summary.amount
            : null,
        note: summary.note,
        outcome: 'missed',
        checkedItemIds: summary.method == 'checklist'
            ? summary.checkedItemIds
            : null,
      );
      return;
    }
    final occurrenceId = PlannerTaskProgressService.recurringOccurrenceId(
      entity,
      localNow,
    );
    final existing = await _localStore.readOccurrence(
      ownerId: ownerId,
      occurrenceId: occurrenceId,
    );
    await _localStore.appendOccurrence(
      ownerId: ownerId,
      entityId: entity.id,
      plannedFor: _plannedTimeForDay(entity, localNow),
      status: 'missed',
      value: <String, dynamic>{...?existing?.value, 'source': 'manual_miss'},
      occurrenceId: occurrenceId,
    );
    unawaited(_syncRepository.syncNow());
    _notify();
  }

  /// A recurring task is represented by one durable occurrence per local day.
  /// Its series itself remains active, unlike a one-off task.
  Future<PlannerOccurrence?> recurringOccurrenceForDay(
    PlannerEntity entity,
    DateTime localDay,
  ) {
    if (entity.kind != PlannerEntityKind.recurringTask) return Future.value();
    return _localStore.readOccurrence(
      ownerId: ownerId,
      occurrenceId: PlannerTaskProgressService.recurringOccurrenceId(
        entity,
        localDay,
      ),
    );
  }

  Future<PlannerHabitDaySummary> logHabit(
    PlannerEntity habit, {
    num? value,
    String? note,
    String? outcome,
    Set<String>? checkedItemIds,
    DateTime? localDay,
  }) => _serializeHabitLog(
    () => _writeHabitLog(
      habit,
      value: value,
      note: note,
      outcome: outcome,
      checkedItemIds: checkedItemIds,
      localDay: localDay,
    ),
  );

  /// Primary count tap. Adds one onto today's stored total, as Stage 14
  /// requires for a `count` habit. `numeric` alone follows its configured
  /// step; duration has its own explicit tap below.
  Future<PlannerHabitDaySummary> incrementHabit(
    PlannerEntity habit, {
    DateTime? localDay,
  }) => _serializeHabitLog(() async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError('Only a habit owned by this workspace can be logged.');
    }
    final method = safeJsonString(habit.tracking['method'], fallback: 'check');
    if (method != 'count' && method != 'numeric') {
      throw UnsupportedError('Only a count habit accepts a +1 tap.');
    }
    final day = _requireLoggableHabitDay(localDay);
    final current = await habitDaySummary(habit, localDay: day);
    if (method == 'count') {
      return _writeHabitLog(habit, value: current.amount + 1, localDay: day);
    }
    final rawStep = habit.tracking['step'];
    final parsedStep = rawStep is num && rawStep.isFinite
        ? rawStep.toDouble()
        : double.tryParse('$rawStep') ?? 1;
    final step = parsedStep > 0 ? parsedStep : 1;
    return _writeHabitLog(habit, value: current.amount + step, localDay: day);
  });

  /// Primary checklist tap. Completes the first open item in declared order.
  /// When today is already complete, this is a confirmed no-op.
  Future<PlannerHabitDaySummary> completeNextChecklistItem(
    PlannerEntity habit, {
    DateTime? localDay,
  }) => _serializeHabitLog(() async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError('Only a habit owned by this workspace can be logged.');
    }
    final method = safeJsonString(habit.tracking['method'], fallback: 'check');
    if (method != 'checklist') {
      throw UnsupportedError('Only a checklist habit has a next open item.');
    }
    final day = _requireLoggableHabitDay(localDay);
    final current = await habitDaySummary(habit, localDay: day);
    final items = _orderedChecklistItemIds(habit);
    final outstanding = items
        .where((id) => !current.checkedItemIds.contains(id))
        .toList(growable: false);
    if (outstanding.isEmpty) return current;
    // Concurrent callers share the same serialized queue, but `_writeHabitLog`
    // may mutate before its summary completes. Reserve the earliest stable
    // outstanding slot for this call before writing.
    final reserved = {...current.checkedItemIds};
    for (final id in outstanding) {
      reserved.add(id);
      break;
    }
    return _writeHabitLog(
      habit,
      outcome: current.outcome ?? 'checked',
      note: current.note,
      checkedItemIds: reserved,
      localDay: day,
    );
  });

  List<String> _orderedChecklistItemIds(PlannerEntity habit) {
    final rawItems =
        habit.tracking[PlannerHabitTrackingKeys.checklist] ??
        habit.payload[PlannerHabitTrackingKeys.checklist];
    final ids = <String>[];
    if (rawItems is Iterable) {
      var index = 0;
      for (final raw in rawItems) {
        index++;
        final item = safeJsonMap(raw);
        if (item.isEmpty) continue;
        final id = safeJsonString(
          item[PlannerHabitTrackingKeys.itemId],
          fallback: 'item-$index',
        );
        if (!ids.contains(id)) ids.add(id);
      }
    }
    return ids;
  }

  Future<PlannerHabitDaySummary> decrementHabit(
    PlannerEntity habit, {
    DateTime? localDay,
  }) => adjustMeasuredHabit(habit, localDay: localDay, direction: -1);

  Future<PlannerHabitDaySummary> incrementDurationHabit(
    PlannerEntity habit, {
    DateTime? localDay,
  }) => adjustMeasuredHabit(habit, localDay: localDay, direction: 1);

  Future<PlannerHabitDaySummary> adjustMeasuredHabit(
    PlannerEntity habit, {
    DateTime? localDay,
    int direction = 1,
  }) => _serializeHabitLog(() async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError('Only a habit owned by this workspace can be logged.');
    }
    final method = safeJsonString(habit.tracking['method'], fallback: 'check');
    if (method != 'count' && method != 'numeric' && method != 'duration') {
      throw UnsupportedError(
        'Only a measured habit accepts a step correction.',
      );
    }
    if (direction != 1 && direction != -1) {
      throw ArgumentError.value(direction, 'direction', 'Use +1 or −1.');
    }
    final day = _requireLoggableHabitDay(localDay);
    final current = await habitDaySummary(habit, localDay: day);
    final rawStep = habit.tracking['step'];
    final parsedStep = rawStep is num && rawStep.isFinite
        ? rawStep.toDouble()
        : double.tryParse('$rawStep') ?? (method == 'duration' ? 5 : 1);
    final step = method == 'count'
        ? 1.0
        : parsedStep > 0
        ? parsedStep
        : (method == 'duration' ? 5.0 : 1.0);
    final corrected = (current.amount + direction * step).clamp(
      0,
      double.infinity,
    );
    return _writeHabitLog(
      habit,
      value: corrected,
      note: current.note,
      outcome: current.outcome ?? 'checked',
      checkedItemIds: current.checkedItemIds,
      localDay: day,
    );
  });

  Future<PlannerHabitDaySummary> toggleHabit(
    PlannerEntity habit, {
    DateTime? localDay,
  }) => _serializeHabitLog(() async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError('Only a habit owned by this workspace can be logged.');
    }
    final method = safeJsonString(habit.tracking['method'], fallback: 'check');
    if (method != 'check' && method != 'avoid') {
      throw UnsupportedError('Only a boolean habit can be toggled.');
    }
    final day = _requireLoggableHabitDay(localDay);
    final current = await habitDaySummary(habit, localDay: day);
    if (current.isSuccessful) {
      return _writeHabitLog(habit, outcome: 'pending', localDay: day);
    }
    return _writeHabitLog(
      habit,
      outcome: method == 'avoid' ? 'avoided' : 'checked',
      localDay: day,
    );
  });

  Future<PlannerHabitDaySummary> _writeHabitLog(
    PlannerEntity habit, {
    num? value,
    String? note,
    String? outcome,
    Set<String>? checkedItemIds,
    DateTime? localDay,
  }) async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError('Only a habit owned by this workspace can be logged.');
    }
    final day = _requireLoggableHabitDay(localDay);
    final now = _now().toUtc();
    final occurrenceId = _habitOccurrenceId(habit, day);
    final existing = await _localStore.readOccurrence(
      ownerId: ownerId,
      occurrenceId: occurrenceId,
    );
    final method = safeJsonString(habit.tracking['method'], fallback: 'check');
    if ((method == 'count' || method == 'numeric' || method == 'duration') &&
        value == null) {
      throw ArgumentError.value(
        value,
        'value',
        'A measured habit requires today’s total.',
      );
    }
    if (value != null && (!value.isFinite || value < 0)) {
      throw ArgumentError.value(
        value,
        'value',
        'A habit measurement must be a finite, non-negative number.',
      );
    }

    final normalizedOutcome =
        safeNullableJsonString(outcome)?.toLowerCase() ??
        (method == 'avoid' ? 'avoided' : 'checked');
    final normalizedChecked = checkedItemIds == null
        ? const <String>[]
        : (checkedItemIds.toList(growable: false)..sort());
    final today = _dateOnly(_now().toLocal());
    final source = existing != null
        ? 'manual_correction'
        : _dateOnly(day).isBefore(today)
        ? 'manual_backfill'
        : 'manual';
    final mutationId = _uuid.v4();
    final occurrenceValue = <String, dynamic>{
      'record_type': 'daily_summary',
      'tap_mutation_id': mutationId,
      'source': source,
      'outcome': normalizedOutcome,
      ...?value == null ? null : <String, dynamic>{'amount': value},
      if (method == 'checklist') 'checked_item_ids': normalizedChecked,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    final provisional = PlannerOccurrence(
      id: occurrenceId,
      ownerId: ownerId,
      entityId: habit.id,
      plannedFor: _plannedTimeForDay(habit, day),
      status: normalizedOutcome == 'missed' || normalizedOutcome == 'slipped'
          ? 'missed'
          : normalizedOutcome == 'pending'
          ? 'pending'
          : method == 'check' || method == 'avoid'
          ? 'completed'
          : 'pending',
      value: occurrenceValue,
      createdAt: now,
      updatedAt: now,
    );
    final evaluated = PlannerHabitDayEngine.evaluate(
      habit: habit,
      occurrences: <PlannerOccurrence>[provisional],
    );
    final status =
        normalizedOutcome == 'missed' || normalizedOutcome == 'slipped'
        ? 'missed'
        : evaluated.occurrenceStatus;
    await _localStore.appendOccurrence(
      ownerId: ownerId,
      entityId: habit.id,
      plannedFor: provisional.plannedFor,
      status: status,
      value: occurrenceValue,
      occurrenceId: occurrenceId,
      // The occurrence ID is stable for a day; its mutations must not be.
      // checked → missed → checked and same-outcome note edits are distinct
      // semantic writes and therefore receive fresh idempotency identities.
      mutationId: mutationId,
    );
    await _finalizeHabitMutation();
    return habitDaySummary(habit, localDay: day);
  }

  Future<PlannerHabitDaySummary> habitDaySummary(
    PlannerEntity habit, {
    DateTime? localDay,
  }) async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError(
        'Only a habit owned by this workspace has a daily summary.',
      );
    }
    final day = (localDay ?? _now().toLocal()).toLocal();
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final occurrences = await _localStore.readOccurrences(
      ownerId,
      entityId: habit.id,
      fromInclusive: start.toUtc(),
      untilExclusive: end.toUtc(),
    );
    return PlannerHabitDayEngine.evaluate(
      habit: habit,
      occurrences: occurrences,
    );
  }

  /// An old Snackbar cannot erase a newer tap, including an A→B→A cycle.
  Future<bool> undoHabitIfCurrent(
    PlannerEntity habit,
    PlannerHabitDaySummary change, {
    DateTime? localDay,
  }) => _serializeHabitLog(() async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError('Only a habit owned by this workspace can be undone.');
    }
    final day = _requireLoggableHabitDay(localDay);
    final expected = change.latestOccurrence;
    final mutationId = expected?.value['tap_mutation_id'];
    if (expected == null || mutationId is! String || mutationId.isEmpty) {
      return false;
    }
    final stored = await _localStore.readOccurrence(
      ownerId: ownerId,
      occurrenceId: _habitOccurrenceId(habit, day),
    );
    if (stored == null ||
        stored.id != expected.id ||
        stored.entityId != habit.id ||
        stored.value['tap_mutation_id'] != mutationId ||
        _dateOnly(stored.plannedFor.toLocal()) != day) {
      return false;
    }
    await _appendHabitUndo(habit, day);
    return true;
  });

  Future<void> _appendHabitUndo(PlannerEntity habit, DateTime day) async {
    final today = _dateOnly(_now().toLocal());
    await _localStore.appendOccurrence(
      ownerId: ownerId,
      entityId: habit.id,
      plannedFor: _plannedTimeForDay(habit, day),
      status: 'pending',
      value: <String, dynamic>{
        'record_type': 'daily_summary',
        'source': _dateOnly(day).isBefore(today)
            ? 'manual_backfill_undo'
            : 'manual_undo',
      },
      occurrenceId: _habitOccurrenceId(habit, day),
      mutationId: _uuid.v4(),
    );
    await _finalizeHabitMutation();
  }

  Future<PlannerHabitDaySummary> undoHabitDay(
    PlannerEntity habit, {
    DateTime? localDay,
  }) => _serializeHabitLog(() async {
    if (habit.kind != PlannerEntityKind.habit || habit.ownerId != ownerId) {
      throw StateError('Only a habit owned by this workspace can be undone.');
    }
    final day = _requireLoggableHabitDay(localDay);
    await _appendHabitUndo(habit, day);
    return habitDaySummary(habit, localDay: day);
  });

  Future<PlannerInsights> loadInsights({int days = 28}) async {
    final clampedDays = days.clamp(7, 365).toInt();
    final now = _now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: clampedDays - 1));
    final results = await Future.wait<Object>(<Future<Object>>[
      _localStore.readOccurrences(
        ownerId,
        fromInclusive: start.toUtc(),
        untilExclusive: today.add(const Duration(days: 1)).toUtc(),
      ),
      _localStore.readFocusSessions(ownerId, startedAfter: start.toUtc()),
      _localStore.readArchivedEntities(ownerId),
    ]);
    return PlannerInsights.fromRecords(
      entities: _entities,
      occurrences: results[0] as List<PlannerOccurrence>,
      focusSessions: results[1] as List<PlannerFocusSession>,
      archivedCount: (results[2] as List<PlannerEntity>).length,
      days: clampedDays,
    );
  }

  Future<PlannerFocusSession> beginFocus({
    PlannerEntity? entity,
    String mode = 'pomodoro',
    int? plannedMinutes,
    String? breakPolicy,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakAfterCycles,
  }) => _serializeFocus(() async {
    final existing = await activeFocusSession();
    if (existing != null) return existing;
    if (entity != null &&
        (entity.ownerId != ownerId ||
            !tasks.any((item) => item.id == entity.id))) {
      throw StateError('Focus can only attach to a task in this workspace.');
    }
    final normalizedMode = switch (mode) {
      'pomodoro' || 'countdown' || 'stopwatch' => mode,
      _ => 'pomodoro',
    };
    final preset = safeJsonMap(entity?.payload['focus']);
    final requestedBreakPolicy =
        breakPolicy ??
        safeJsonString(
          preset[PlannerFocusPresetKeys.breakPolicy],
          fallback: 'none',
        );
    final normalizedBreakPolicy = switch (requestedBreakPolicy) {
      'after_session' || 'pomodoro_cycle' => requestedBreakPolicy,
      _ => 'none',
    };
    final normalizedShortBreak =
        (shortBreakMinutes ??
                safeJsonInt(
                  preset[PlannerFocusPresetKeys.shortBreakMinutes],
                  fallback: 5,
                ))
            .clamp(1, 60)
            .toInt();
    final normalizedLongBreak =
        (longBreakMinutes ??
                safeJsonInt(
                  preset[PlannerFocusPresetKeys.longBreakMinutes],
                  fallback: 15,
                ))
            .clamp(1, 120)
            .toInt();
    final normalizedLongBreakAfterCycles =
        (longBreakAfterCycles ??
                safeJsonInt(
                  preset[PlannerFocusPresetKeys.longBreakAfterCycles],
                  fallback: 4,
                ))
            .clamp(2, 12)
            .toInt();
    final duration = normalizedMode == 'stopwatch'
        ? null
        : (plannedMinutes ?? (normalizedMode == 'pomodoro' ? 25 : 30))
              .clamp(1, 240)
              .toInt();
    final receipt = await _localStore.appendFocusSession(
      ownerId: ownerId,
      startedAt: _now().toUtc(),
      entityId: entity?.id,
      mode: normalizedMode,
      payload: <String, dynamic>{
        'source': 'perfect_focus',
        ...?duration == null
            ? null
            : <String, dynamic>{'planned_duration_minutes': duration},
        PlannerFocusPresetKeys.breakPolicy: normalizedBreakPolicy,
        PlannerFocusPresetKeys.shortBreakMinutes: normalizedShortBreak,
        PlannerFocusPresetKeys.longBreakMinutes: normalizedLongBreak,
        PlannerFocusPresetKeys.longBreakAfterCycles:
            normalizedLongBreakAfterCycles,
      },
    );
    unawaited(_syncRepository.syncNow());
    return receipt.focusSession!;
  });

  Future<PlannerFocusSession?> activeFocusSession() async {
    final sessions = await _localStore.readFocusSessions(ownerId);
    for (final session in sessions) {
      if (session.status == 'active') return session;
    }
    return null;
  }

  Future<void> completeFocus(
    PlannerFocusSession session, {
    required Duration elapsed,
    bool cancelled = false,
  }) async {
    await _localStore.completeFocusSession(
      ownerId: ownerId,
      sessionId: session.id,
      status: cancelled ? 'cancelled' : 'completed',
      payload: <String, dynamic>{
        ...session.payload,
        'elapsed_seconds': elapsed.inSeconds,
        'ended_reason': cancelled ? 'cancelled' : 'completed',
      },
    );
    unawaited(_syncRepository.syncNow());
  }

  Future<void> startFocus({
    PlannerEntity? entity,
    String mode = 'pomodoro',
    int? plannedMinutes,
    String? breakPolicy,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakAfterCycles,
  }) async {
    await beginFocus(
      entity: entity,
      mode: mode,
      plannedMinutes: plannedMinutes,
      breakPolicy: breakPolicy,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      longBreakAfterCycles: longBreakAfterCycles,
    );
  }

  Future<PlannerReminderSettings> reminderSettings() =>
      _reminderScheduler.readSettings();

  PlannerReminderScheduleSummary? _lastReminderScheduleSummary;

  PlannerReminderScheduleSummary? get lastReminderScheduleSummary =>
      _lastReminderScheduleSummary;

  Future<PlannerReminderActivation> enableReminders({
    bool requestExactTiming = false,
  }) async {
    final result = await _reminderScheduler.enable(
      requestExactTiming: requestExactTiming,
    );
    if (result == PlannerReminderActivation.enabled) {
      await _refreshReminders();
    }
    return result;
  }

  Future<PlannerReminderScheduleSummary> saveReminderSettings(
    PlannerReminderSettings settings,
  ) async {
    await _reminderScheduler.saveSettings(settings);
    return _refreshReminders();
  }

  Future<PlannerReminderScheduleSummary> _refreshReminders() async {
    final summary = await _reminderScheduler.sync(_entities);
    _lastReminderScheduleSummary = summary;
    return summary;
  }

  Future<List<PlannerSyncConflict>> openConflicts() =>
      _localStore.listConflicts(ownerId, status: 'open');

  Future<void> keepServerConflict(PlannerSyncConflict conflict) =>
      _localStore.resolveConflict(
        ownerId: ownerId,
        conflictId: conflict.id,
        resolution: 'kept_server',
        now: _now().toUtc(),
      );

  Future<void> keepLocalConflict(PlannerSyncConflict conflict) async {
    if (conflict.targetType != PlannerOperationTarget.entity) {
      throw UnsupportedError(
        'Occurrence and focus history are immutable once a real conflict exists.',
      );
    }
    final current = await _localStore.readEntity(
      ownerId: ownerId,
      entityId: conflict.targetId,
      includeDeleted: true,
    );
    if (current == null) {
      throw StateError('The conflicting item is no longer available locally.');
    }
    final restoredPayload = _payloadAfterConflict(current, conflict.localValue);
    await _localStore.upsertEntity(
      entity: current.copyWith(
        payload: restoredPayload,
        updatedAt: _now().toUtc(),
      ),
      patch: PlannerFieldPatch.replacePayload(restoredPayload),
    );
    await _localStore.resolveConflict(
      ownerId: ownerId,
      conflictId: conflict.id,
      resolution: 'kept_local',
      now: _now().toUtc(),
    );
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
  }

  Future<void> _toggleRecurringOccurrence(PlannerEntity entity) async {
    final current = await taskProgressForDay(entity);
    await _taskProgressService.setProgress(
      entity,
      progress: PlannerTaskProgress(
        state: current.isComplete
            ? PlannerTaskProgressState.pending
            : PlannerTaskProgressState.completed,
        percent: current.isComplete ? 0 : 100,
      ),
      source: 'legacy_toggle',
    );
    await _finalizeTaskProgressMutation();
  }

  Future<void> _setLegacyOneOffCompletion(PlannerEntity entity) async {
    if (entity.kind != PlannerEntityKind.oneOffTask) return;
    final current = await _localStore.readEntity(
      ownerId: ownerId,
      entityId: entity.id,
    );
    if (current == null) return;
    await _taskProgressService.setProgress(
      current,
      progress: current.status == PlannerEntityStatus.completed
          ? const PlannerTaskProgress.pending()
          : const PlannerTaskProgress(
              state: PlannerTaskProgressState.completed,
              percent: 100,
            ),
      source: 'legacy_toggle',
    );
  }

  Future<T> _serializeTaskProgress<T>(Future<T> Function() action) {
    final result = _taskProgressSerial.then<T>((_) => action());
    _taskProgressSerial = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<T> _serializeHabitLog<T>(Future<T> Function() action) {
    final result = _habitLogSerial.then<T>((_) => action());
    _habitLogSerial = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<T> _serializeFocus<T>(Future<T> Function() action) {
    final result = _focusSerial.then<T>((_) => action());
    _focusSerial = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  String _habitOccurrenceId(PlannerEntity habit, DateTime localDay) => _uuid.v5(
    Namespace.url.value,
    'perfect:habit-occurrence:$ownerId:${habit.id}:${_localDateKey(localDay)}',
  );

  DateTime _requireLoggableHabitDay(DateTime? requested) {
    final now = _now().toLocal();
    final today = _dateOnly(now);
    final requestedLocal = (requested ?? now).toLocal();
    final day = _dateOnly(requestedLocal);
    if (day.isAfter(today)) {
      throw ArgumentError.value(
        requested,
        'localDay',
        'Habit results cannot be recorded in the future.',
      );
    }
    return day;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _finalizeHabitMutation() async {
    // The occurrence write is already durable. Repaint it before any plugin or
    // remote I/O; the publisher uses the same owner-scoped entity projection.
    _notify();
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
    await _publishTodayWidget();
  }

  /// A progress write can live on the entity itself or on a dated recurring
  /// occurrence. The entity watcher sees only the first shape, so every path
  /// explicitly refreshes the local projection before notifying the app or
  /// publishing the Android widget. This also lets reminder reconciliation
  /// consume the just-written state instead of a stale in-memory entity.
  Future<void> _finalizeTaskProgressMutation() async {
    _entities = await _localStore.readActiveEntities(ownerId);
    if (_disposed) return;
    // Repaint the foreground UI before crossing the plugin boundary. Launcher
    // I/O may be slower than Drift, but it must not make the app control feel
    // delayed or hide the locally committed outcome.
    _notify();
    unawaited(_syncRepository.syncNow());
    unawaited(_refreshReminders());
    await _publishTodayWidget();
  }

  Future<void> _publishTodayWidget() async {
    if (_disposed || _shutdownRequested || !_todayWidgetSettings.isAvailable) {
      return;
    }
    await _todayWidgetProjector.publish(
      entities: _entities,
      settings: _todayWidgetSettings,
    );
  }

  void _scheduleNextLocalDayRefresh() {
    _dayBoundaryTimer?.cancel();
    if (_disposed || _shutdownRequested) return;
    final now = _now().toLocal();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final delay = nextDay.difference(now);
    _dayBoundaryTimer = Timer(
      delay.isNegative ? Duration.zero : delay + const Duration(seconds: 1),
      () => unawaited(refreshTodayProjection()),
    );
  }

  DateTime _plannedTimeForDay(PlannerEntity entity, DateTime localDay) {
    final scheduled = entity.scheduledAt?.toLocal();
    final localTime = scheduled == null
        ? DateTime(localDay.year, localDay.month, localDay.day, 12)
        : DateTime(
            localDay.year,
            localDay.month,
            localDay.day,
            scheduled.hour,
            scheduled.minute,
          );
    return localTime.toUtc();
  }

  Map<String, dynamic> _payloadAfterConflict(
    PlannerEntity current,
    Map<String, dynamic> localPatch,
  ) {
    final fullPayload = localPatch['/'];
    if (fullPayload is Map) return safeJsonMap(fullPayload);
    final payload = <String, dynamic>{...current.payload};
    for (final entry in localPatch.entries) {
      final key = entry.key;
      if (!key.startsWith('/') || key.length <= 1 || key.contains('/', 1)) {
        continue;
      }
      payload[key.substring(1)] = entry.value;
    }
    return payload;
  }

  void _onSyncChanged() => _notify();

  void _notify() {
    if (!_disposed && !_shutdownRequested) {
      _todayProjectionRevision++;
      notifyListeners();
    }
  }

  Future<void> disposeAsync() async {
    if (_disposed) return;
    requestShutdown();
    _disposed = true;
    _dayBoundaryTimer?.cancel();
    _syncRepository.syncStatus.removeListener(_syncListener);
    await _entitiesSubscription?.cancel();
    await _syncRepository.dispose();
    await _reminderScheduler.dispose();
    await _localStore.close();
    super.dispose();
  }
}

/// Small, local-only summary for the owner. It deliberately counts recorded
/// history rather than inferring guilt from a missing scheduled occurrence.
class PlannerInsights {
  const PlannerInsights({
    required this.days,
    required this.activeTaskCount,
    required this.completedTaskCount,
    required this.completedOccurrences,
    required this.missedOccurrences,
    required this.habitCheckIns,
    required this.focusDuration,
    required this.archivedCount,
  });

  final int days;
  final int activeTaskCount;
  final int completedTaskCount;
  final int completedOccurrences;
  final int missedOccurrences;
  final int habitCheckIns;
  final Duration focusDuration;
  final int archivedCount;

  factory PlannerInsights.fromRecords({
    required List<PlannerEntity> entities,
    required List<PlannerOccurrence> occurrences,
    required List<PlannerFocusSession> focusSessions,
    required int archivedCount,
    required int days,
  }) {
    final habitIds = entities
        .where((entity) => entity.kind == PlannerEntityKind.habit)
        .map((entity) => entity.id)
        .toSet();
    final focusSeconds = focusSessions
        .where((session) => session.status == 'completed')
        .fold<int>(0, (sum, session) {
          final seconds = safeJsonInt(
            session.payload['elapsed_seconds'],
            fallback: 0,
          );
          return sum + seconds.clamp(0, 24 * 60 * 60).toInt();
        });
    return PlannerInsights(
      days: days,
      activeTaskCount: entities
          .where(
            (entity) =>
                (entity.kind == PlannerEntityKind.oneOffTask ||
                    entity.kind == PlannerEntityKind.recurringTask) &&
                entity.status == PlannerEntityStatus.active,
          )
          .length,
      completedTaskCount: entities
          .where(
            (entity) =>
                entity.kind == PlannerEntityKind.oneOffTask &&
                entity.status == PlannerEntityStatus.completed,
          )
          .length,
      completedOccurrences: occurrences
          .where((occurrence) => occurrence.status == 'completed')
          .length,
      missedOccurrences: occurrences
          .where((occurrence) => occurrence.status == 'missed')
          .length,
      habitCheckIns: occurrences
          .where(
            (occurrence) =>
                habitIds.contains(occurrence.entityId) &&
                occurrence.status == 'completed',
          )
          .length,
      focusDuration: Duration(seconds: focusSeconds),
      archivedCount: archivedCount,
    );
  }
}

String _localDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
