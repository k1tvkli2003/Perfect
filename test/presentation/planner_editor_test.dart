import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/planner_editor.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'sectioned editor exposes advanced capability without a wizard',
    (tester) async {
      final controller = _RecordingPlannerController();
      addTearDown(controller.disposeAsync);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () =>
                      PlannerEditor.show(context, controller: controller),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      // The sheet deliberately owns long-lived input/scroll affordances. A
      // bounded transition pump proves the editor is visible without coupling
      // this contract test to every ambient Material animation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Make it yours'), findsOneWidget);
      expect(find.text('Organization'), findsOneWidget);
      expect(find.text('Save to Perfect'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'A complete but calm task',
      );
      final editorScrolls = find.descendant(
        of: find.byType(PlannerEditor),
        matching: find.byType(Scrollable),
      );
      expect(editorScrolls, findsWidgets);
      final editorScroll = editorScrolls.first;
      await tester.scrollUntilVisible(
        find.text('Repeat & recovery'),
        260,
        scrollable: editorScroll,
      );
      expect(find.text('Repeat & recovery'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Custom properties'),
        260,
        scrollable: editorScroll,
      );
      expect(find.text('Custom properties'), findsOneWidget);
      await tester.tap(find.text('Save to Perfect'));
      await tester.pumpAndSettle(const Duration(milliseconds: 20));
      expect(
        controller.savedPayload?[PlannerPayloadKeys.title],
        'A complete but calm task',
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  testWidgets(
    'task identity, planning context, time block, and break policy round-trip',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _RecordingPlannerController();
      addTearDown(controller.disposeAsync);
      final start = DateTime.utc(2026, 7, 27, 9);
      final end = DateTime.utc(2026, 7, 27, 10, 30);
      final existing = PlannerEntity(
        id: '11111111-2222-4333-8444-555555555555',
        ownerId: 'editor-owner',
        kind: PlannerEntityKind.oneOffTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Detailed task'),
          PlannerPayloadKeys.timing: <String, dynamic>{
            'scheduled_at': start.toIso8601String(),
            PlannerTaskMetadataKeys.timeBlockEndAt: end.toIso8601String(),
          },
          PlannerTaskMetadataKeys.labels: const <String>['Work', 'Deep'],
          PlannerTaskMetadataKeys.icon: 'study',
          PlannerTaskMetadataKeys.color: 'mint',
          PlannerTaskMetadataKeys.estimateMinutes: 90,
          PlannerTaskMetadataKeys.energy: 'high',
          'category': 'Health',
          'focus': const <String, dynamic>{
            PlannerFocusPresetKeys.enabled: true,
            PlannerFocusPresetKeys.mode: 'pomodoro',
            PlannerFocusPresetKeys.minutes: 50,
            PlannerFocusPresetKeys.breakPolicy: 'pomodoro_cycle',
            PlannerFocusPresetKeys.shortBreakMinutes: 7,
            PlannerFocusPresetKeys.longBreakMinutes: 20,
            PlannerFocusPresetKeys.longBreakAfterCycles: 3,
          },
          'reminders': const <Map<String, dynamic>>[
            <String, dynamic>{
              'enabled': true,
              'lead_minutes': 15,
              'snooze_minutes': 20,
              'respect_quiet_hours': true,
            },
            <String, dynamic>{
              'enabled': true,
              'lead_minutes': 60,
              'snooze_minutes': 35,
              'respect_quiet_hours': true,
            },
            <String, dynamic>{
              'enabled': true,
              'lead_minutes': 30,
              'snooze_minutes': 2000,
              'respect_quiet_hours': true,
            },
          ],
        },
        createdAt: start,
        updatedAt: start,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlannerEditor(controller: controller, existing: existing),
          ),
        ),
      );

      final editorScroll = find
          .descendant(
            of: find.byType(PlannerEditor),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Category & identity'),
        220,
        scrollable: editorScroll,
      );
      await tester.tap(find.text('Category & identity'));
      await tester.pumpAndSettle();
      final categoryField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Category (optional)',
      );
      expect(
        tester.widget<TextField>(categoryField).controller?.text,
        'Health',
      );
      expect(find.widgetWithText(InputChip, 'Work'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Deep'), findsOneWidget);
      final labelsField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Labels',
      );
      await tester.enterText(labelsField, 'Laptop');
      await tester.tap(find.byTooltip('Add label'));
      await tester.pump();
      expect(find.widgetWithText(InputChip, 'Laptop'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Task context'),
        260,
        scrollable: editorScroll,
      );
      await tester.tap(find.text('Task context'));
      await tester.pumpAndSettle();
      expect(find.text('High energy'), findsOneWidget);
      expect(find.text('Short breaks + a long cycle break'), findsOneWidget);
      final estimateField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Estimate (minutes, optional)',
      );
      expect(tester.widget<TextField>(estimateField).controller?.text, '90');

      await tester.scrollUntilVisible(
        find.text('Reminders'),
        260,
        scrollable: editorScroll,
      );
      await tester.tap(find.text('Reminders'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Increase snooze for 15 min before'),
        160,
        scrollable: editorScroll,
      );
      await tester.drag(editorScroll, const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase snooze for 15 min before'));
      await tester.pump();
      expect(find.text('25 min'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('35 min'),
        180,
        scrollable: editorScroll,
      );
      expect(find.text('35 min'), findsOneWidget);

      await tester.tap(find.text('Save to Perfect'));
      await tester.pump();

      final payload = controller.savedPayload!;
      expect(payload[PlannerTaskMetadataKeys.labels], const <String>[
        'Work',
        'Deep',
        'Laptop',
      ]);
      expect(payload[PlannerTaskMetadataKeys.icon], 'study');
      expect(payload[PlannerTaskMetadataKeys.color], 'mint');
      expect(payload[PlannerTaskMetadataKeys.estimateMinutes], 90);
      expect(payload[PlannerTaskMetadataKeys.energy], 'high');
      expect(
        safeJsonMap(
          payload[PlannerPayloadKeys.timing],
        )[PlannerTaskMetadataKeys.timeBlockEndAt],
        end.toIso8601String(),
      );
      final focus = safeJsonMap(payload['focus']);
      expect(focus[PlannerFocusPresetKeys.breakPolicy], 'pomodoro_cycle');
      expect(focus[PlannerFocusPresetKeys.shortBreakMinutes], 7);
      expect(focus[PlannerFocusPresetKeys.longBreakMinutes], 20);
      expect(focus[PlannerFocusPresetKeys.longBreakAfterCycles], 3);
      final reminders = safeJsonMapList(payload['reminders']);
      expect(reminders, hasLength(3));
      expect(
        reminders.singleWhere(
          (reminder) => reminder['lead_minutes'] == 15,
        )['snooze_minutes'],
        25,
      );
      expect(
        reminders.singleWhere(
          (reminder) => reminder['lead_minutes'] == 60,
        )['snooze_minutes'],
        35,
      );
      expect(
        reminders.singleWhere(
          (reminder) => reminder['lead_minutes'] == 30,
        )['snooze_minutes'],
        1440,
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  testWidgets('time-block end must be after start', (tester) async {
    final controller = _RecordingPlannerController();
    addTearDown(controller.disposeAsync);
    final start = DateTime.utc(2026, 7, 27, 10);
    final existing = PlannerEntity(
      id: '21111111-2222-4333-8444-555555555555',
      ownerId: 'editor-owner',
      kind: PlannerEntityKind.oneOffTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Invalid block'),
        PlannerPayloadKeys.timing: <String, dynamic>{
          'scheduled_at': start.toIso8601String(),
          PlannerTaskMetadataKeys.timeBlockEndAt: start
              .subtract(const Duration(minutes: 30))
              .toIso8601String(),
        },
      },
      createdAt: start,
      updatedAt: start,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlannerEditor(controller: controller, existing: existing),
        ),
      ),
    );
    await tester.tap(find.text('Save to Perfect'));
    await tester.pump();

    expect(controller.savedPayload, isNull);
    expect(
      find.text('Time-block end must be after its start.'),
      findsOneWidget,
    );
  });
}

class _RecordingPlannerController extends PlannerWorkspaceController {
  factory _RecordingPlannerController() {
    final local = PlannerLocalStore(PlannerDatabase(NativeDatabase.memory()));
    return _RecordingPlannerController._(
      local,
      PlannerSyncRepository(
        local,
        _NoopGateway(),
        ownerId: 'editor-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
    );
  }

  _RecordingPlannerController._(super.local, super.sync)
    : super(ownerId: 'editor-owner');

  Map<String, dynamic>? savedPayload;

  @override
  Future<void> saveEntity({
    required PlannerEntityKind kind,
    PlannerEntity? existing,
    required Map<String, dynamic> payload,
  }) async {
    savedPayload = Map<String, dynamic>.unmodifiable(payload);
  }
}

class _NoopGateway implements PlannerRemoteGateway {
  @override
  Future<PlannerRemoteMutationResult> apply(PlannerRemoteMutation mutation) =>
      Future<PlannerRemoteMutationResult>.value(
        PlannerRemoteMutationResult.fromJson(<String, dynamic>{
          'status': 'acknowledged',
          'entity': <String, dynamic>{
            'id': mutation.entityId,
            'owner_id': 'editor-owner',
            'kind': mutation.entityKind,
            'title': mutation.patch['title'] ?? 'Task',
            'lifecycle_state': 'active',
            'payload': mutation.patch['payload'] ?? <String, dynamic>{},
            'revision': 1,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        }),
      );

  @override
  Future<void> dispose() => Future<void>.value();

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) => Future<PlannerRemoteChangePage>.value(
    PlannerRemoteChangePage(
      changes: const <PlannerRemoteChange>[],
      requestedLimit: limit,
    ),
  );

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() =>
      Future<List<Map<String, dynamic>>>.value(const <Map<String, dynamic>>[]);

  @override
  Future<void> subscribe(void Function() onChangeHint) => Future<void>.value();
}
