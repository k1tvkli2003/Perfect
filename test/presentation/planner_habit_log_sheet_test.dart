import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/planner_habit_log_sheet.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

void main() {
  testWidgets(
    'habit log navigates to a past day and saves one backfill record',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = PlannerDatabase(NativeDatabase.memory());
      final local = PlannerLocalStore(database);
      final controller = PlannerWorkspaceController(
        local,
        PlannerSyncRepository(
          local,
          _DisconnectedGateway(),
          ownerId: 'habit-log-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
        ),
        ownerId: 'habit-log-owner',
        now: () => DateTime.utc(2026, 7, 27, 9),
      );
      addTearDown(controller.disposeAsync);
      await controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Read'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'check',
          },
        },
      );
      final habit = (await local.readActiveEntities('habit-log-owner')).single;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => PlannerHabitLogSheet.show(
                  context,
                  habit: habit,
                  controller: controller,
                ),
                child: const Text('Open log'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open log'));
      await tester.pumpAndSettle();
      expect(find.text('Today · Jul 27'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
      expect(find.text('Jul 26, 2026'), findsOneWidget);
      expect(find.text('Save Jul 26'), findsOneWidget);

      await tester.tap(find.text('Not done'));
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(find.text('Change date?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Jul 26, 2026'), findsOneWidget);

      await tester.tap(find.text('Save Jul 26'));
      await tester.pumpAndSettle();

      final occurrences = await local.readOccurrences(
        'habit-log-owner',
        entityId: habit.id,
      );
      expect(occurrences, hasLength(1));
      expect(occurrences.single.value['source'], 'manual_backfill');
      expect(occurrences.single.plannedFor.toLocal().day, 26);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
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
