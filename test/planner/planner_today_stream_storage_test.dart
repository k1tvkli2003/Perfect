import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/domain/planner_today_stream.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:uuid/uuid.dart';

// Real Drift persistence + production controller reads. The only fake is the
// remote gateway: these assertions must work without a server or emulator.
void main() {
  const owner = 'stream-owner';
  late PlannerLocalStore store;
  late PlannerWorkspaceController controller;
  late DateTime clock;

  setUp(() {
    clock = DateTime(2026, 9, 10, 23, 59);
    store = PlannerLocalStore(PlannerDatabase(NativeDatabase.memory()));
    controller = PlannerWorkspaceController(
      store,
      PlannerSyncRepository(
        store,
        _OfflineGateway(),
        ownerId: owner,
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: owner,
      now: () => clock,
    );
  });

  tearDown(() => controller.disposeAsync());

  Future<PlannerEntity> create(
    String title, {
    String ownerId = owner,
    PlannerEntityKind kind = PlannerEntityKind.recurringTask,
    Map<String, dynamic> recurrence = const {'rule': 'daily'},
    Map<String, dynamic> tracking = const {'method': 'check'},
    Map<String, dynamic> recovery = const {},
    String? id,
  }) async {
    final entity = PlannerEntity(
      id: id ?? const Uuid().v4(),
      ownerId: ownerId,
      kind: kind,
      createdAt: DateTime(2026, 9, 1, 9).toUtc(),
      updatedAt: clock.toUtc(),
      payload: {
        ...defaultPlannerPayload(title: title),
        'timing': {
          'scheduled_at': DateTime(2026, 9, 1, 9).toUtc().toIso8601String(),
        },
        'recurrence': recurrence,
        'tracking': tracking,
        'recovery': recovery,
      },
    );
    await store.upsertEntity(entity: entity, mutationId: const Uuid().v4());
    return entity;
  }

  Future<PlannerTodayStream> project(DateTime day) async {
    final entities = await store.readActiveEntities(owner);
    final eligibility = <String, PlannerTodayEligibility>{};
    final tasks = <String, PlannerTaskProgress>{};
    final habits = <String, PlannerHabitDaySummary>{};
    for (final entity in entities) {
      eligibility[entity.id] = await controller.todayEligibilityForDay(
        entity,
        localDay: day,
      );
      if (entity.kind == PlannerEntityKind.habit) {
        habits[entity.id] = await controller.habitDaySummary(
          entity,
          localDay: day,
        );
      } else {
        tasks[entity.id] = await controller.taskProgressForDay(
          entity,
          localDay: day,
        );
      }
    }
    return PlannerTodayStream.project(
      entities: entities,
      day: day,
      eligibilityById: eligibility,
      taskProgressById: tasks,
      habitSummaryById: habits,
    );
  }

  test('persisted quota excludes work until the next local period', () async {
    final task = await create(
      'Weekly session',
      recurrence: {
        'rule': 'flexible',
        'frequency': {'count': 1, 'period': 'week'},
      },
    );
    await controller.setTaskProgress(
      task,
      localDay: DateTime(2026, 9, 9),
      progress: const PlannerTaskProgress(
        state: PlannerTaskProgressState.completed,
        percent: 100,
      ),
    );

    expect(
      PlannerTodayEngine.evaluate(entity: task, day: clock).isEligible,
      isTrue,
    );
    expect((await project(clock)).entries, isEmpty);
    expect((await project(DateTime(2026, 9, 14))).nextEntryId, task.id);
  });

  test(
    'one captured day owns task and habit outcomes across midnight',
    () async {
      final task = await create('Daily review');
      final habit = await create('Stretch', kind: PlannerEntityKind.habit);
      final selectedDay = clock;
      await controller.setTaskProgress(
        task,
        localDay: selectedDay,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
      );
      await controller.logHabit(habit, localDay: selectedDay);
      clock = DateTime(2026, 9, 11, 0, 1);

      final yesterday = await project(selectedDay);
      expect(yesterday.inSection(PlannerTodaySection.settled), hasLength(2));
      expect(yesterday.nextEntryId, isNull);
      final today = await project(clock);
      expect(today.inSection(PlannerTodaySection.settled), isEmpty);
      expect(today.nextEntryId, task.id);
      expect(
        today.entries.map((entry) => entry.scheduledAt),
        everyElement(DateTime(2026, 9, 11, 9)),
      );
    },
  );

  test('equal IDs from another owner cannot supply rows or outcomes', () async {
    final own = await create('Private task');
    final other = await create('Other task', id: own.id, ownerId: 'other');
    await store.appendOccurrence(
      ownerId: 'other',
      entityId: other.id,
      occurrenceId: PlannerTaskProgressService.recurringOccurrenceId(
        other,
        clock,
      ),
      plannedFor: DateTime(clock.year, clock.month, clock.day).toUtc(),
      status: 'completed',
    );
    await create('Other only', ownerId: 'other');

    final stream = await project(clock);
    expect(stream.entries, hasLength(1));
    expect(stream.entries.single.entity.title, 'Private task');
    expect(stream.entries.single.isSettled, isFalse);
    expect(stream.nextEntryId, own.id);
  });

  test(
    'measured habit uses persisted amount and undo reopens its row',
    () async {
      final habit = await create(
        'Water',
        kind: PlannerEntityKind.habit,
        tracking: {'method': 'count', 'target': 8, 'goal': 'at_least'},
      );
      await controller.logHabit(habit, value: 3);
      expect((await project(clock)).nextEntryId, habit.id);
      await controller.logHabit(habit, value: 8);
      expect((await project(clock)).entries.single.isSettled, isTrue);
      await controller.undoHabitDay(habit);
      expect((await project(clock)).nextEntryId, habit.id);
      expect(
        await store.readOccurrences(owner, entityId: habit.id),
        hasLength(1),
      );
    },
  );

  test(
    'stored exceptions and resolved recovery remove unavailable work',
    () async {
      await create(
        'Excluded today',
        recurrence: {
          'rule': 'daily',
          'exceptions': ['2026-09-10'],
        },
      );
      final overdue = await create(
        'Old decision',
        kind: PlannerEntityKind.oneOffTask,
        recovery: {'on_miss': 'ask'},
      );
      final before = await project(clock);
      expect(before.entries.single.section, PlannerTodaySection.decision);
      await controller.resolveOneOffRecovery(
        overdue,
        disposition: PlannerRecoveryDisposition.missed,
      );
      expect((await project(clock)).entries, isEmpty);
    },
  );

  test('projection reads neither seed data nor enqueue mutations', () async {
    expect((await project(clock)).entries, isEmpty);
    expect(await store.listPendingOperations(owner), isEmpty);
    await create('Existing');
    final before = await store.listPendingOperations(owner);
    await project(clock);
    await project(clock);
    expect(
      (await store.listPendingOperations(owner)).map((op) => op.mutationId),
      before.map((op) => op.mutationId),
    );
  });
}

class _OfflineGateway implements PlannerRemoteGateway {
  @override
  Future<PlannerRemoteMutationResult> apply(PlannerRemoteMutation mutation) =>
      Future.error(StateError('offline fixture'));

  @override
  Future<void> dispose() async {}

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async => PlannerRemoteChangePage(changes: const [], requestedLimit: limit);

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() async => const [];

  @override
  Future<void> subscribe(void Function() onChangeHint) async {}
}
