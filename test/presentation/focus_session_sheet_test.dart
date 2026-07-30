import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/focus_session_sheet.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Windows focus uses a bounded dialog and honors the task preset',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(1280, 800);
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
          ownerId: 'focus-owner',
          deviceId: '11111111-1111-4111-8111-111111111111',
          retryTimerFactory: (_, _) => _NoopTimer(),
        ),
        ownerId: 'focus-owner',
        todayWidgetBridge: _UnavailableTodayWidgetBridge(),
      );
      addTearDown(controller.disposeAsync);
      await controller.start();
      await controller.saveEntity(
        kind: PlannerEntityKind.oneOffTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Windows deep work'),
          'focus': const <String, dynamic>{
            'enabled': true,
            'mode': 'countdown',
            'minutes': 45,
            PlannerFocusPresetKeys.breakPolicy: 'pomodoro_cycle',
            PlannerFocusPresetKeys.shortBreakMinutes: 7,
            PlannerFocusPresetKeys.longBreakMinutes: 20,
            PlannerFocusPresetKeys.longBreakAfterCycles: 3,
          },
        },
      );
      final task = (await local.readActiveEntities('focus-owner')).single;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => FocusSessionSheet.show(
                  context,
                  controller: controller,
                  entity: task,
                ),
                child: const Text('Open focus'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('Countdown'), findsOneWidget);
      expect(
        find.text('7 min short · 20 min after 3 sessions'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Dialog), findsNothing);
      controller.requestShutdown();
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}

class _NoopTimer implements Timer {
  @override
  bool get isActive => false;

  @override
  int get tick => 0;

  @override
  void cancel() {}
}

class _UnavailableTodayWidgetBridge extends PerfectTodayWidgetBridge {
  @override
  Future<PerfectTodayWidgetSettings> readSettings() async =>
      const PerfectTodayWidgetSettings(
        isAvailable: false,
        showTaskTitles: true,
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
