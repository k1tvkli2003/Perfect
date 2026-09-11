import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_editor.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final year in <int>[2020, 2070]) {
    for (final picker in <({String field, IconData icon})>[
      (field: 'scheduled_at', icon: Icons.calendar_today_outlined),
      (field: 'due_at', icon: Icons.flag_outlined),
      (field: 'end_at', icon: Icons.event_busy_outlined),
      (
        field: PlannerTaskMetadataKeys.timeBlockEndAt,
        icon: Icons.timelapse_rounded,
      ),
    ]) {
      testWidgets(
        '${picker.icon == Icons.timelapse_rounded ? 'block end' : picker.field} picker preserves existing date outside default range $year',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final now = DateTime(2030, 6, 12, 11, 25);
          final selected = DateTime(year, 3, 15, 9);
          final controller = _RecordingPlannerController(now: () => now);
          addTearDown(controller.disposeAsync);
          final isRecurrence = picker.icon == Icons.event_busy_outlined;
          final existing = PlannerEntity(
            id: '11111111-2222-4333-8444-555555555555',
            ownerId: 'editor-owner',
            kind: PlannerEntityKind.habit,
            payload: <String, dynamic>{
              ...defaultPlannerPayload(title: 'Preserved date'),
              PlannerPayloadKeys.timing: <String, dynamic>{
                if (!isRecurrence)
                  picker.field: selected.toUtc().toIso8601String(),
                if (picker.icon == Icons.timelapse_rounded)
                  'scheduled_at': DateTime(
                    year - 25,
                    3,
                    15,
                    8,
                  ).toUtc().toIso8601String(),
              },
              PlannerPayloadKeys.recurrence: <String, dynamic>{
                'rule': 'daily',
                if (isRecurrence) 'end_at': selected.toUtc().toIso8601String(),
              },
            },
            createdAt: now.toUtc(),
            updatedAt: now.toUtc(),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: PerfectTheme.light(),
              home: Scaffold(
                body: PlannerEditor(controller: controller, existing: existing),
              ),
            ),
          );
          await _tapStep(tester, isRecurrence ? 'frequency' : 'plan');
          final action = find.ancestor(
            of: find.byIcon(picker.icon),
            matching: find.byType(OutlinedButton),
          );
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final dialog = tester.widget<DatePickerDialog>(
            find.byType(DatePickerDialog),
          );
          expect(dialog.initialDate, DateUtils.dateOnly(selected));
          expect(dialog.firstDate.isAfter(dialog.initialDate!), isFalse);
          expect(dialog.lastDate.isBefore(dialog.initialDate!), isFalse);
          expect(dialog.currentDate, DateUtils.dateOnly(now));

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey<String>('planner-editor-quick-save')),
          );
          await tester.pumpAndSettle();
          final saved = safeJsonMap(
            controller.savedPayload![isRecurrence
                ? PlannerPayloadKeys.recurrence
                : PlannerPayloadKeys.timing],
          );
          expect(saved[picker.field], selected.toUtc().toIso8601String());
        },
      );
    }
  }

  for (final selectKindInEditor in <bool>[false, true]) {
    testWidgets(
      'weekly default follows controller local day when kind selected in editor: $selectKindInEditor',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = _RecordingPlannerController(
          now: () => DateTime(2030, 6, 12, 23, 59),
        );
        addTearDown(controller.disposeAsync);
        await tester.pumpWidget(
          MaterialApp(
            theme: PerfectTheme.light(),
            home: Scaffold(
              body: PlannerEditor(
                controller: controller,
                initialKind: selectKindInEditor
                    ? PlannerEntityKind.oneOffTask
                    : PlannerEntityKind.recurringTask,
              ),
            ),
          ),
        );
        if (selectKindInEditor) {
          await tester.tap(find.text('Recurring task'));
          await tester.pumpAndSettle();
        }
        await _tapStep(tester, 'frequency');
        final selectedWeekdays = tester
            .widgetList<FilterChip>(find.byType(FilterChip))
            .where((chip) => chip.selected)
            .map((chip) => (chip.label as Text).data)
            .toList();
        expect(selectedWeekdays, <String>['Wed']);
      },
    );
  }

  testWidgets('new date pickers use controller local today', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2030, 6, 12, 23, 59);
    final controller = _RecordingPlannerController(now: () => now);
    addTearDown(controller.disposeAsync);
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: Scaffold(
          body: PlannerEditor(
            controller: controller,
            initialKind: PlannerEntityKind.habit,
          ),
        ),
      ),
    );
    for (final entry in <({String step, String label})>[
      (step: 'plan', label: 'Choose date & time'),
      (step: 'plan', label: 'Add a deadline (optional)'),
      (step: 'frequency', label: 'No end date'),
      (step: 'frequency', label: 'Add exception date'),
    ]) {
      await _tapStep(tester, entry.step);
      await tester.ensureVisible(find.text(entry.label));
      await tester.tap(find.text(entry.label));
      await tester.pumpAndSettle();
      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.initialDate, DateUtils.dateOnly(now));
      expect(dialog.currentDate, DateUtils.dateOnly(now));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'creation is a full-screen multi-step wizard with a quick task path',
    (tester) async {
      tester.view.physicalSize = const Size(900, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _RecordingPlannerController();
      addTearDown(controller.disposeAsync);

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
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
      await tester.pumpAndSettle();

      expect(find.byType(PlannerEditor), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const ValueKey<String>('planner-step-type')), findsOne);
      expect(find.text('What are you shaping?'), findsOneWidget);

      await _tapStep(tester, 'category');
      expect(find.text('Where does it belong?'), findsOneWidget);
      await _tapStep(tester, 'define');
      await tester.enterText(
        find.byKey(const ValueKey<String>('planner-editor-title')),
        'A complete but calm task',
      );
      await _tapStep(tester, 'plan');
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-back')),
      );
      await tester.pumpAndSettle();
      expect(find.text('A complete but calm task'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
      await tester.pumpAndSettle();
      expect(
        controller.savedPayload?[PlannerPayloadKeys.title],
        'A complete but calm task',
      );
    },
  );

  testWidgets(
    'habit flow follows category evaluation definition frequency plan review',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _RecordingPlannerController();
      addTearDown(controller.disposeAsync);

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: Scaffold(
            body: PlannerEditor(
              controller: controller,
              initialKind: PlannerEntityKind.habit,
            ),
          ),
        ),
      );

      for (final id in <String>[
        'type',
        'category',
        'evaluate',
        'define',
        'frequency',
        'plan',
        'review',
      ]) {
        expect(
          find.byKey(ValueKey<String>('planner-step-$id')),
          findsOneWidget,
        );
      }

      await _tapStep(tester, 'evaluate');
      expect(find.byKey(const ValueKey('habit-evaluation-check')), findsOne);
      expect(find.byKey(const ValueKey('habit-evaluation-count')), findsOne);
      expect(find.byKey(const ValueKey('habit-evaluation-duration')), findsOne);
      expect(
        find.byKey(const ValueKey('habit-evaluation-checklist')),
        findsOne,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('habit-evaluation-checklist')),
      );
      await tester.pumpAndSettle();

      await _tapStep(tester, 'define');
      await tester.enterText(
        find.byKey(const ValueKey<String>('planner-editor-title')),
        'Morning reset',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Checklist item'),
        'Drink water',
      );
      await tester.tap(find.byTooltip('Add habit checklist item'));
      await tester.pump();
      expect(find.text('Drink water'), findsOneWidget);

      await _tapStep(tester, 'evaluate');
      await _tapStep(tester, 'define');
      expect(find.text('Morning reset'), findsWidgets);
      expect(find.text('Drink water'), findsOneWidget);

      await _tapStep(tester, 'frequency');
      expect(find.text('Every day'), findsOneWidget);
      expect(find.text('Flexible within the valid window'), findsOneWidget);
      await _tapStep(tester, 'plan');
      expect(find.text('Miss & recovery'), findsOneWidget);
      expect(find.text('Priority'), findsWidgets);
      await _tapStep(tester, 'review');
      expect(find.text('Your plan at a glance'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-save')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'type');

      final payload = controller.savedPayload!;
      expect(payload[PlannerPayloadKeys.title], 'Morning reset');
      final tracking = safeJsonMap(payload[PlannerPayloadKeys.tracking]);
      expect(tracking['method'], 'checklist');
      expect(
        safeJsonMapList(tracking[PlannerHabitTrackingKeys.checklist]),
        hasLength(1),
      );
      expect(
        safeJsonMap(payload[PlannerPayloadKeys.recurrence])['rule'],
        'daily',
      );
    },
  );

  testWidgets(
    'task identity timing reminders focus and labels survive wizard editing',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
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
          ],
        },
        createdAt: start,
        updatedAt: start,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: Scaffold(
            body: PlannerEditor(controller: controller, existing: existing),
          ),
        ),
      );

      expect(find.textContaining('Type is fixed after creation'), findsOne);
      await _tapStep(tester, 'category');
      final categoryField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Category (optional)',
      );
      expect(
        tester.widget<TextField>(categoryField).controller?.text,
        'Health',
      );
      final labelsField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Labels',
      );
      await tester.enterText(labelsField, 'Laptop');
      await tester.tap(find.byTooltip('Add label'));
      await tester.pump();

      await _tapStep(tester, 'details');
      expect(find.text('High energy'), findsOneWidget);
      expect(find.text('Short breaks + a long cycle break'), findsOneWidget);
      final estimateField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Estimate (minutes, optional)',
      );
      expect(tester.widget<TextField>(estimateField).controller?.text, '90');

      await _tapStep(tester, 'plan');
      expect(find.text('15 min before · snooze'), findsOneWidget);
      expect(find.text('35 min'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
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
      expect(safeJsonMapList(payload['reminders']), hasLength(2));
    },
  );

  testWidgets('invalid time block reveals the Plan step and keeps draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        theme: PerfectTheme.light(),
        home: Scaffold(
          body: PlannerEditor(controller: controller, existing: existing),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('planner-editor-quick-save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(controller.savedPayload, isNull);
    expect(find.text('Place it in your day'), findsOneWidget);
    expect(find.text('Time-block end must be after its start.'), findsWidgets);
    await _tapStep(tester, 'define');
    expect(find.text('Invalid block'), findsWidgets);
  });

  testWidgets(
    'wizard remains usable across phone tablet desktop and short landscape',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cases = <({Size size, double textScale, String name})>[
        (size: const Size(360, 780), textScale: 1, name: 'narrow phone'),
        (size: const Size(800, 1280), textScale: 1.3, name: 'portrait tablet'),
        (
          size: const Size(1024, 520),
          textScale: 1,
          name: 'short tablet landscape',
        ),
        (
          size: const Size(1280, 720),
          textScale: 2,
          name: 'desktop at 200% text',
        ),
      ];

      for (final testCase in cases) {
        await tester.binding.setSurfaceSize(testCase.size);
        final controller = _RecordingPlannerController();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: PerfectTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(testCase.textScale),
                  disableAnimations: true,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
              home: Scaffold(body: PlannerEditor(controller: controller)),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull, reason: testCase.name);
          expect(find.text('Make it yours'), findsOneWidget);
          expect(find.text('What are you shaping?'), findsOneWidget);
          expect(
            find.byKey(const ValueKey<String>('planner-editor-next')),
            findsOneWidget,
          );
          expect(
            tester
                .getRect(
                  find.byKey(const ValueKey<String>('planner-editor-next')),
                )
                .bottom,
            lessThanOrEqualTo(testCase.size.height),
            reason: testCase.name,
          );
          expect(
            find.byKey(const ValueKey<String>('planner-editor-type')),
            findsOneWidget,
          );
        } finally {
          await controller.disposeAsync();
        }
      }
    },
  );

  testWidgets(
    'compact 200 percent RTL habit flow keeps every action visible and hittable',
    (tester) async {
      final previousHitTestWarningPolicy =
          WidgetController.hitTestWarningShouldBeFatal;
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(
        () => WidgetController.hitTestWarningShouldBeFatal =
            previousHitTestWarningPolicy,
      );
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = _RecordingPlannerController();
      addTearDown(controller.disposeAsync);

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          home: Scaffold(
            body: PlannerEditor(
              controller: controller,
              initialKind: PlannerEntityKind.habit,
            ),
          ),
        ),
      );
      await tester.pump();

      Future<void> continueTo(String nextStep) async {
        final action = find.byKey(
          const ValueKey<String>('planner-editor-next'),
        );
        expect(action, findsOneWidget);
        expect(action.hitTestable(), findsOneWidget);
        final rect = tester.getRect(action);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(700));
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey<String>('planner-editor-$nextStep')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: nextStep);
      }

      await continueTo('category');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category (optional)'),
        'سلامت و آرامش ذهنی بلندمدت',
      );
      await continueTo('evaluate');
      final checklistEvaluation = find.byKey(
        const ValueKey<String>('habit-evaluation-checklist'),
      );
      await tester.ensureVisible(checklistEvaluation);
      await tester.pumpAndSettle();
      expect(checklistEvaluation.hitTestable(), findsOneWidget);
      await tester.tap(checklistEvaluation);
      await tester.pump();
      await continueTo('define');
      expect(
        find.widgetWithText(TextFormField, 'Checklist item'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('planner-editor-title')),
        'روتین آرام و کامل صبحگاهی برای روزهای خیلی شلوغ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (optional)'),
        'این توضیح عمداً بلند و فارسی است تا چینش راست‌به‌چپ و بزرگ‌نمایی متن بدون برش یا هم‌پوشانی بماند.',
      );
      final checklistField = find.widgetWithText(
        TextFormField,
        'Checklist item',
      );
      await tester.ensureVisible(checklistField);
      await tester.enterText(checklistField, 'نوشیدن یک لیوان آب');
      final addChecklist = find.byTooltip('Add habit checklist item');
      await tester.ensureVisible(addChecklist);
      await tester.tap(addChecklist);
      await tester.pump();
      expect(find.text('نوشیدن یک لیوان آب'), findsOneWidget);
      await continueTo('frequency');
      await continueTo('plan');
      await continueTo('review');

      final save = find.byKey(const ValueKey<String>('planner-editor-save'));
      expect(save, findsOneWidget);
      expect(save.hitTestable(), findsOneWidget);
      final saveRect = tester.getRect(save);
      expect(saveRect.right, lessThanOrEqualTo(320));
      expect(saveRect.bottom, lessThanOrEqualTo(700));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tapStep(WidgetTester tester, String id) async {
  final finder = find.byKey(ValueKey<String>('planner-step-$id'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _RecordingPlannerController extends PlannerWorkspaceController {
  factory _RecordingPlannerController({DateTime Function()? now}) {
    final local = PlannerLocalStore(PlannerDatabase(NativeDatabase.memory()));
    return _RecordingPlannerController._(
      local,
      PlannerSyncRepository(
        local,
        _NoopGateway(),
        ownerId: 'editor-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      now: now,
    );
  }

  _RecordingPlannerController._(super.local, super.sync, {super.now})
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
