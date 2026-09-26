import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/ai/perfect_ai_client.dart';
import 'package:perfect/ai/perfect_ai_contract.dart';
import 'package:perfect/ai/perfect_voice_recorder.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_workspace_page.dart';
import 'package:perfect/presentation/planner_editor.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:perfect/presentation/today_pulse.dart';
import 'package:shared_preferences/shared_preferences.dart';

late PlannerWorkspaceController _controller;
final _previewNow = DateTime(2026, 7, 27, 9);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final latin = FontLoader('PlusJakarta')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    final persian = FontLoader('Vazirmatn')
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Variable.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait<void>(<Future<void>>[
      latin.load(),
      persian.load(),
      icons.load(),
    ]);
  });

  late PlannerDatabase database;

  setUp(() async {
    // Keep raster-brand sampling deterministic when tests switch repeatedly
    // between compact, tablet, and desktop mark sizes.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final sync = PlannerSyncRepository(
      local,
      _PreviewGateway(),
      ownerId: 'preview-owner',
      deviceId: '11111111-1111-4111-8111-111111111111',
    );
    _controller = _ProjectionFailureController(
      local,
      sync,
      ownerId: 'preview-owner',
      now: () => _previewNow,
    );
    await _controller.start();
    await _controller.saveEntity(
      kind: PlannerEntityKind.oneOffTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Focus Deep Work'),
        PlannerPayloadKeys.timing: <String, dynamic>{
          'scheduled_at': _previewNow.toUtc().toIso8601String(),
        },
        'priority': 'high',
      },
    );
    await _controller.saveEntity(
      kind: PlannerEntityKind.habit,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: 'Water plants'),
        PlannerPayloadKeys.tracking: <String, dynamic>{'method': 'check'},
      },
    );
    await _controller.refresh();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    await _controller.disposeAsync();
  });

  testWidgets(
    'compact Today Pulse keeps navigation and quick capture reachable',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester);

      expect(
        MediaQuery.sizeOf(tester.element(find.text('Good morning'))),
        const Size(390, 844),
      );
      expect(
        tester.getSize(find.byType(PerfectWorkspacePage)),
        const Size(390, 844),
      );

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
        findsOneWidget,
      );
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_compact.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'theme and contrast switches preserve page identity, draft, focus, scroll and destination',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        for (var index = 0; index < 8; index++) {
          await _controller.saveEntity(
            kind: PlannerEntityKind.oneOffTask,
            payload: <String, dynamic>{
              ...defaultPlannerPayload(title: 'Theme continuity $index'),
              PlannerPayloadKeys.timing: <String, dynamic>{
                'scheduled_at': _previewNow
                    .add(Duration(minutes: index + 1))
                    .toUtc()
                    .toIso8601String(),
              },
            },
          );
        }
        await _controller.refresh();
      });
      final harnessKey = GlobalKey<_ThemeContrastHarnessState>();
      await tester.pumpWidget(
        _ThemeContrastHarness(key: harnessKey, controller: _controller),
      );
      await tester.pumpAndSettle();

      final workspaceBefore = tester.state(find.byType(PerfectWorkspacePage));
      final todayScrollable = find
          .descendant(
            of: find.byKey(
              const PageStorageKey<String>('perfect-today-scroll'),
            ),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(todayScrollable, const Offset(0, -260));
      await tester.pumpAndSettle();
      final offsetBefore = tester
          .state<ScrollableState>(todayScrollable)
          .position
          .pixels;
      expect(offsetBefore, greaterThan(0));

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();
      final capture = find.byKey(
        const ValueKey<String>('perfect_quick_capture'),
      );
      await tester.tap(capture);
      await tester.enterText(capture, 'Keep this private draft');
      await tester.pump();
      expect(tester.widget<TextField>(capture).focusNode?.hasFocus, isTrue);

      harnessKey.currentState!.setContrast(PerfectContrastMode.high);
      await tester.pumpAndSettle();

      expect(
        tester.state(find.byType(PerfectWorkspacePage)),
        same(workspaceBefore),
      );
      expect(
        tester.widget<TextField>(capture).controller?.text,
        'Keep this private draft',
      );
      expect(tester.widget<TextField>(capture).focusNode?.hasFocus, isTrue);
      expect(
        tester.state<ScrollableState>(todayScrollable).position.pixels,
        closeTo(offsetBefore, .5),
      );
      expect(
        PerfectSemanticTheme.of(tester.element(capture)).id,
        'theme-hc-light-clarity',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-collapse')),
      );
      await tester.pumpAndSettle();
      await tester.tap(_footerDestination('tasks'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-tasks-scroll')),
        findsOneWidget,
      );

      harnessKey.currentState!.setTheme(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(PerfectWorkspacePage)),
        same(workspaceBefore),
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-tasks-scroll')),
        findsOneWidget,
      );
      expect(
        PerfectSemanticTheme.of(
          tester.element(
            find.byKey(const ValueKey<String>('perfect-tasks-scroll')),
          ),
        ).id,
        'theme-hc-dark-clarity',
      );

      await tester.tap(_footerDestination('today'));
      await tester.pumpAndSettle();
      final collapsedCapture = find.byKey(
        const ValueKey<String>('perfect-quick-capture-toggle'),
      );
      if (collapsedCapture.evaluate().isNotEmpty) {
        await tester.tap(collapsedCapture);
        await tester.pumpAndSettle();
      }
      expect(
        tester.widget<TextField>(capture).controller?.text,
        'Keep this private draft',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Stage 10 authored theme matrix stays composed on phone tablet and Windows',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final harnessKey = GlobalKey<_ThemeContrastHarnessState>();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _ThemeContrastHarness(key: harnessKey, controller: _controller),
      );
      await tester.pumpAndSettle();

      Future<void> capture({
        required Size size,
        required ThemeMode themeMode,
        required PerfectContrastMode contrastMode,
        required String expectedThemeId,
        required String golden,
      }) async {
        await tester.binding.setSurfaceSize(size);
        harnessKey.currentState!
          ..setTheme(themeMode)
          ..setContrast(contrastMode);
        await tester.pumpAndSettle();
        final workspace = find.byType(PerfectWorkspacePage);
        expect(workspace, findsOneWidget);
        expect(
          PerfectSemanticTheme.of(tester.element(workspace)).id,
          expectedThemeId,
        );
        expect(tester.takeException(), isNull);
        await expectLater(workspace, matchesGoldenFile(golden));
      }

      await capture(
        size: const Size(390, 844),
        themeMode: ThemeMode.dark,
        contrastMode: PerfectContrastMode.system,
        expectedThemeId: 'theme-dark-midnight-command',
        golden: '../goldens/perfect_stage10_phone_dark.png',
      );
      await capture(
        size: const Size(390, 844),
        themeMode: ThemeMode.light,
        contrastMode: PerfectContrastMode.high,
        expectedThemeId: 'theme-hc-light-clarity',
        golden: '../goldens/perfect_stage10_phone_clarity_light.png',
      );
      await capture(
        size: const Size(900, 1200),
        themeMode: ThemeMode.dark,
        contrastMode: PerfectContrastMode.system,
        expectedThemeId: 'theme-dark-midnight-command',
        golden: '../goldens/perfect_stage10_tablet_dark.png',
      );
      await capture(
        size: const Size(1600, 900),
        themeMode: ThemeMode.dark,
        contrastMode: PerfectContrastMode.system,
        expectedThemeId: 'theme-dark-midnight-command',
        golden: '../goldens/perfect_stage10_windows_dark.png',
      );
      await capture(
        size: const Size(1600, 900),
        themeMode: ThemeMode.dark,
        contrastMode: PerfectContrastMode.high,
        expectedThemeId: 'theme-hc-dark-clarity',
        golden: '../goldens/perfect_stage10_windows_clarity_dark.png',
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'compact AI toggle lives inside quick capture and opens above it',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester, aiClient: _WorkspaceAiClient());

      expect(
        MediaQuery.sizeOf(tester.element(find.text('Good morning'))),
        const Size(390, 844),
      );
      expect(
        tester.getSize(find.byType(PerfectWorkspacePage)),
        const Size(390, 844),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('perfect_quick_capture')),
            )
            .focusNode
            ?.hasFocus,
        isFalse,
        reason: 'Opening the composer must not summon the keyboard.',
      );
      final actionShelfFinder = find.byKey(
        const ValueKey<String>('perfect-capture-action-shelf'),
      );
      expect(
        find.descendant(of: actionShelfFinder, matching: find.text('Plan')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: actionShelfFinder,
          matching: find.text('Perfect AI'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: actionShelfFinder, matching: find.text('Voice')),
        findsOneWidget,
      );

      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      final actionShelf = tester.getRect(actionShelfFinder);
      final planToggle = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-capture-plan')),
      );
      final aiToggle = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-toggle')),
      );
      final voiceToggle = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-voice-toggle')),
      );
      expect(
        capture.contains(aiToggle.center),
        isTrue,
        reason: 'AI is one command inside the quick capture composer.',
      );
      expect(actionShelf.contains(planToggle.center), isTrue);
      expect(actionShelf.contains(aiToggle.center), isTrue);
      expect(actionShelf.contains(voiceToggle.center), isTrue);
      expect(planToggle.width, closeTo(aiToggle.width, 1));
      expect(aiToggle.width, closeTo(voiceToggle.width, 1));
      expect(planToggle.height, greaterThanOrEqualTo(48));
      expect(aiToggle.height, greaterThanOrEqualTo(48));
      expect(voiceToggle.height, greaterThanOrEqualTo(48));
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-surface')),
        findsNothing,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      final navigation = find.byType(NavigationBar);
      final navigationRect = tester.getRect(navigation);
      expect(navigationRect.bottom, lessThanOrEqualTo(844));
      expect(capture.bottom, lessThanOrEqualTo(navigationRect.top));
      expect(
        tester.widget<NavigationBar>(navigation).labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );
      for (final destination in <String>[
        'today',
        'tasks',
        'plan',
        'habits',
        'more',
      ]) {
        final footerAction = _footerDestination(destination);
        final actionRect = tester.getRect(footerAction);
        expect(actionRect.top, greaterThanOrEqualTo(navigationRect.top));
        expect(actionRect.bottom, lessThanOrEqualTo(navigationRect.bottom));
      }
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_compact_ai_closed.png'),
      );

      await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-surface')),
        findsOneWidget,
      );
      final openAi = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-surface')),
      );
      final openCapture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      expect(openAi.left, greaterThanOrEqualTo(0));
      expect(openAi.right, lessThanOrEqualTo(390));
      expect(openAi.bottom, lessThanOrEqualTo(openCapture.top));
      expect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_compact_ai_open.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'Today AI open close preserves capture draft independently of goldens',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester, aiClient: _WorkspaceAiClient());
      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();

      final captureInput = find.byKey(
        const ValueKey<String>('perfect_quick_capture'),
      );
      const draft = 'Keep this Today draft';
      await tester.enterText(captureInput, draft);
      final ai = find.byKey(const ValueKey<String>('perfect-ai-surface'));
      final toggle = find.byKey(const ValueKey<String>('perfect-ai-toggle'));
      expect(ai, findsNothing);

      for (var cycle = 0; cycle < 2; cycle++) {
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(ai, findsOneWidget);
        final aiRect = tester.getRect(ai);
        final captureRect = tester.getRect(
          find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
        );
        expect(aiRect.left, greaterThanOrEqualTo(0));
        expect(aiRect.right, lessThanOrEqualTo(390));
        expect(aiRect.bottom, lessThanOrEqualTo(captureRect.top));
        expect(tester.widget<TextField>(captureInput).controller!.text, draft);
        expect(find.byType(NavigationBar), findsOneWidget);

        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(ai, findsNothing);
        expect(tester.widget<TextField>(captureInput).controller!.text, draft);
        expect(tester.takeException(), isNull);
      }
      expect(_controller.tasks, hasLength(1));
      expect(_controller.tasks.single.title, 'Focus Deep Work');
    },
  );

  testWidgets(
    'compact footer replaces the stock oval with one prismatic tile',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester);

      final navigationTheme = tester.widget<NavigationBarTheme>(
        find.byKey(const ValueKey<String>('perfect-compact-navigation-theme')),
      );
      expect(navigationTheme.data.indicatorColor, Colors.transparent);
      expect(
        navigationTheme.data.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-footer-selected-today')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-footer-selected-tasks')),
        findsNothing,
      );

      await tester.tap(_footerDestination('tasks'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('perfect-footer-selected-today')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-footer-selected-tasks')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact shell keeps a bounded glass header and two floating glass docks',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, aiClient: _WorkspaceAiClient());

      final sync = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-sync-surface')),
      );
      final glassHeader = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-workspace-glass-header')),
      );
      final heading = tester.getRect(find.text('Good morning'));
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      final navigation = tester.getRect(find.byType(NavigationBar));
      final wordmark = tester.getRect(find.byType(PerfectWordmark));

      expect(sync.height, greaterThanOrEqualTo(48));
      expect(glassHeader.height, lessThanOrEqualTo(76));
      expect(sync.top, greaterThanOrEqualTo(glassHeader.top));
      expect(sync.bottom, lessThanOrEqualTo(glassHeader.bottom));
      expect(wordmark.top, greaterThanOrEqualTo(glassHeader.top));
      expect(wordmark.bottom, lessThanOrEqualTo(glassHeader.bottom));
      expect(wordmark.height, greaterThan(18));
      expect(wordmark.width, greaterThan(100));
      expect(heading.top, greaterThanOrEqualTo(glassHeader.bottom));
      expect(heading.top - glassHeader.bottom, lessThanOrEqualTo(32));
      expect(
        find.byKey(const ValueKey<String>('today-pulse-time')),
        findsOneWidget,
      );
      expect(find.text('9:00 AM'), findsWidgets);
      expect(find.text('Monday, July 27'), findsOneWidget);
      expect(find.text('۵ مرداد ۱۴۰۵'), findsOneWidget);
      expect(capture.left, greaterThan(0));
      expect(capture.right, lessThan(390));
      expect(
        capture.bottom,
        lessThanOrEqualTo(navigation.top),
        reason:
            'The capture launcher reserves its own transparent slot above the footer instead of covering Today rows.',
      );
      expect(navigation.left, greaterThan(0));
      expect(navigation.right, lessThan(390));
      expect(
        find.ancestor(
          of: find.byKey(
            const ValueKey<String>('perfect-quick-capture-surface'),
          ),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
        reason:
            'The animated capture dock uses authored glass tint without re-blurring the full Today surface on low-end Android GPUs.',
      );
      expect(
        find.ancestor(
          of: find.byType(NavigationBar),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android tablet defaults narrow and expands without overlap',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      final aiClient = _WorkspaceAiClient();
      await _pump(tester, aiClient: aiClient);

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
      expect(find.byKey(const ValueKey<String>('rail-mark')), findsOneWidget);
      expect(find.byType(PerfectWordmark), findsNothing);
      expect(find.byTooltip('Expand navigation'), findsOneWidget);
      final railLayout = find.byKey(
        const ValueKey<String>('perfect-navigation-rail-layout'),
      );
      final railRect = tester.getRect(railLayout);
      expect(railRect.top, greaterThanOrEqualTo(10));
      expect(railRect.bottom, lessThanOrEqualTo(1190));
      expect(
        find.descendant(of: railLayout, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      final pulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      final aiToggle = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-toggle')),
      );
      expect(pulse.bottom, lessThan(stream.top));
      expect(pulse.left, closeTo(stream.left, 1));
      expect(pulse.right, closeTo(stream.right, 1));
      expect(
        pulse.height,
        inInclusiveRange(140, 320),
        reason: 'Compact command bar stays content-led without clipping.',
      );
      expect(capture.contains(aiToggle.center), isTrue);
      expect(stream.bottom, lessThanOrEqualTo(capture.top));
      final habit = _controller.habits.singleWhere(
        (item) => item.title == 'Water plants',
      );
      final habitRow = find.byKey(
        ValueKey<String>('entity-context-${habit.id}'),
      );
      expect(habitRow, findsOneWidget);
      expect(
        tester.getBottomRight(habitRow).dy,
        lessThanOrEqualTo(stream.bottom),
        reason:
            'Visible habit card must not be clipped by the stream viewport.',
      );
      await _pump(tester, aiClient: aiClient);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_tablet_rail_compact.png'),
      );

      await _pump(tester, aiClient: aiClient);
      await tester.tap(find.byTooltip('Expand navigation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final animatedWidth = tester
          .getSize(
            find.byKey(
              const ValueKey<String>('perfect-navigation-rail-layout'),
            ),
          )
          .width;
      expect(animatedWidth, inExclusiveRange(76, 224));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
      expect(find.byKey(const ValueKey<String>('rail-mark')), findsNothing);
      expect(find.byType(PerfectWordmark), findsOneWidget);
      final expandedPulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final expandedStream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(expandedPulse.bottom, lessThan(expandedStream.top));
      expect(expandedPulse.left, closeTo(expandedStream.left, 1));
      expect(expandedPulse.right, closeTo(expandedStream.right, 1));
      expect(expandedPulse.width, greaterThan(500));
      expect(tester.takeException(), isNull);
      await _pump(tester, aiClient: aiClient);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_tablet_rail_expanded.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'medium Today Pulse reflows at 768 800 900 and 1024dp without splitting the day',
    (tester) async {
      Future<(Rect, Rect)> layoutAt(double width) async {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        await _pump(tester);
        expect(tester.takeException(), isNull);
        return (
          tester.getRect(find.byKey(const ValueKey<String>('today-pulse'))),
          tester.getRect(
            find.byKey(const ValueKey<String>('day-stream-panel')),
          ),
        );
      }

      final narrow = await layoutAt(768);
      expect(narrow.$1.bottom, lessThan(narrow.$2.top));
      expect(
        find.byKey(const ValueKey<String>('today-pulse-compact')),
        findsOneWidget,
      );

      final portraitTablet = await layoutAt(800);
      expect(portraitTablet.$1.bottom, lessThan(portraitTablet.$2.top));
      expect(portraitTablet.$1.height, lessThan(320));

      final standard = await layoutAt(900);
      expect(standard.$1.bottom, lessThan(standard.$2.top));
      expect(
        find.byKey(const ValueKey<String>('today-pulse-wide')),
        findsOneWidget,
      );

      final roomy = await layoutAt(1024);
      expect(roomy.$1.bottom, lessThan(roomy.$2.top));
      expect(roomy.$1.width, greaterThan(standard.$1.width));
    },
  );

  testWidgets(
    'wide Android tablet keeps a compact rail until the owner expands it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await _pump(tester, platform: TargetPlatform.android);

      expect(
        find.byKey(const ValueKey<String>('perfect-shell-expanded')),
        findsOneWidget,
      );
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
      expect(find.byTooltip('Expand navigation'), findsOneWidget);

      await tester.tap(find.byTooltip('Expand navigation'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shell changes composition only when useful content earns the next tier',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(670, 900));
      await _pump(tester);
      expect(
        find.byKey(const ValueKey<String>('perfect-shell-compact')),
        findsOneWidget,
      );
      await _sendControlShortcut(tester, LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      expect(
        find.text('Search, filter and act without losing the working context.'),
        findsOneWidget,
      );

      await tester.binding.setSurfaceSize(const Size(700, 900));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-shell-medium')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );

      await tester.binding.setSurfaceSize(const Size(1220, 900));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-shell-medium')),
        findsOneWidget,
      );
      await tester.binding.setSurfaceSize(const Size(1230, 900));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-shell-expanded')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );
      expect(
        find.text('Search, filter and act without losing the working context.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android tablet landscape keeps Today Pulse and stream continuously usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await _pump(tester, aiClient: _WorkspaceAiClient());

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();

      final pulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      final aiToggle = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-toggle')),
      );

      expect(pulse.bottom, lessThan(stream.top));
      expect(pulse.left, closeTo(stream.left, 1));
      expect(pulse.right, closeTo(stream.right, 1));
      expect(pulse.height, lessThan(260));
      expect(stream.bottom, lessThanOrEqualTo(capture.top));
      expect(capture.contains(aiToggle.center), isTrue);
      final habit = _controller.habits.singleWhere(
        (item) => item.title == 'Water plants',
      );
      final habitRow = find.byKey(
        ValueKey<String>('entity-context-${habit.id}'),
      );
      expect(habitRow, findsOneWidget);
      expect(
        tester.getBottomRight(habitRow).dy,
        lessThanOrEqualTo(stream.bottom),
        reason:
            'Visible habit card must not be clipped by the stream viewport.',
      );
      expect(capture.bottom, lessThanOrEqualTo(800));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_tablet_landscape.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'tablet Today Pulse at 200 percent text remains one readable column',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      await _pump(tester, textScaler: const TextScaler.linear(2));

      final pulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(pulse.bottom, lessThan(stream.top));
      expect(
        find.byKey(const ValueKey<String>('today-pulse-compact')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('rail-mark')), findsOneWidget);
      expect(find.byType(PerfectWordmark), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Windows rail collapse choice survives a workspace remount', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    await _pump(tester, platform: TargetPlatform.windows);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );

    await tester.tap(find.byTooltip('Collapse navigation'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(PerfectPreferences.navigationRailExtendedKey),
      isFalse,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
    expect(find.byTooltip('Expand navigation'), findsOneWidget);
  });

  testWidgets(
    '320dp quick capture stays uncluttered with 200 percent text and 48dp actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await _pump(tester, textScaler: const TextScaler.linear(2));

      expect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('New task…'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final navigation = find.byType(NavigationBar);
      expect(
        tester.widget<NavigationBar>(navigation).labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );
      for (final destination in <String>[
        'today',
        'tasks',
        'plan',
        'habits',
        'more',
      ]) {
        expect(_footerDestination(destination), findsOneWidget);
      }

      for (final key in <String>[
        'perfect-quick-capture-collapse',
        'perfect-capture-plan',
      ]) {
        final size = tester.getSize(find.byKey(ValueKey<String>(key)));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    },
  );

  testWidgets(
    'quick capture follows ambient RTL until the first strong letter',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, textDirection: TextDirection.rtl);
      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();

      TextField capture() => tester.widget<TextField>(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
      );

      expect(capture().textDirection, TextDirection.rtl);
      await tester.enterText(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
        'Plan جلسه',
      );
      await tester.pump();
      expect(capture().textDirection, TextDirection.ltr);

      await tester.enterText(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
        'جلسه Plan',
      );
      await tester.pump();
      expect(capture().textDirection, TextDirection.rtl);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact quick capture commits one task then reopens with an empty draft',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();

      const captureField = ValueKey<String>('perfect_quick_capture');
      await tester.enterText(find.byKey(captureField), 'Stage12 runtime echo');
      await tester.pump();

      final countBefore = _controller.entities.length;
      expect(
        tester
            .getRect(
              find.byKey(
                const ValueKey<String>('perfect-quick-capture-surface'),
              ),
            )
            .height,
        greaterThan(0),
        reason: 'Expanded composer is on screen before commit.',
      );

      await tester.runAsync(() async {
        await tester.testTextInput.receiveAction(TextInputAction.done);
        for (var attempt = 0; attempt < 100; attempt++) {
          if (_controller.entities.length == countBefore + 1) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });

      await tester.runAsync(() => _controller.refresh());
      await tester.pumpAndSettle();
      expect(_controller.entities.length, countBefore + 1);
      expect(
        _controller.entities.where((e) => e.title == 'Stage12 runtime echo'),
        hasLength(1),
      );
      expect(find.text('Captured locally. Sync will follow.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
        findsNothing,
        reason: 'Composer collapses after a successful commit.',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byKey(captureField)).controller!.text,
        isEmpty,
      );
      expect(
        _controller.entities.where((e) => e.title == 'Stage12 runtime echo'),
        hasLength(1),
      );
      expect(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact quick capture rejects empty and whitespace-only drafts without dialog',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();

      const captureField = ValueKey<String>('perfect_quick_capture');
      final countBefore = _controller.entities.length;
      for (final draft in <String>['', '   ']) {
        await tester.enterText(find.byKey(captureField), draft);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byKey(captureField)).controller!.text,
          draft,
        );
        expect(_controller.entities.length, countBefore);
        expect(find.text('Captured locally. Sync will follow.'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '320dp Habit wizard keeps every primary step and action usable at 200 percent text',
    (tester) async {
      const size = Size(320, 700);
      await tester.binding.setSurfaceSize(size);
      await _pumpNewEditor(
        tester,
        initialKind: PlannerEntityKind.habit,
        textScaler: const TextScaler.linear(2),
        textDirection: TextDirection.rtl,
        disableAnimations: true,
      );

      const steps = <String, String>{
        'type': 'What are you shaping?',
        'category': 'Where does it belong?',
        'evaluate': 'How will progress count?',
        'define': 'Define it clearly',
        'frequency': 'How often should it return?',
        'plan': 'When should it meet your day?',
        'review': 'Ready when you are',
      };
      final taskTile = tester.getRect(
        find.byKey(const ValueKey<String>('planner-kind-oneOffTask')),
      );
      final recurringTile = tester.getRect(
        find.byKey(const ValueKey<String>('planner-kind-recurringTask')),
      );
      expect(taskTile.bottom, lessThanOrEqualTo(recurringTile.top));

      for (final entry in steps.entries) {
        expect(
          find.byKey(ValueKey<String>('planner-editor-${entry.key}')),
          findsOneWidget,
        );
        _expectWizardStageQuality(tester, entry.key, entry.value, size);
        if (entry.key == 'define') {
          await tester.enterText(
            find.byKey(const ValueKey<String>('planner-editor-title')),
            'Hydrate gently',
          );
        }
        if (entry.key != 'review') {
          await tester.tap(
            find.byKey(const ValueKey<String>('planner-editor-next')),
          );
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'short landscape recurring wizard preserves mixed RTL copy through every step',
    (tester) async {
      const size = Size(600, 360);
      await tester.binding.setSurfaceSize(size);
      await _pumpNewEditor(
        tester,
        initialKind: PlannerEntityKind.recurringTask,
        textScaler: const TextScaler.linear(1.4),
        textDirection: TextDirection.rtl,
        disableAnimations: true,
      );

      const steps = <String, String>{
        'type': 'What are you shaping?',
        'category': 'Where does it belong?',
        'define': 'Define it clearly',
        'frequency': 'How often should it return?',
        'plan': 'Place it in your day',
        'details': 'Give it the right working context',
        'review': 'Ready when you are',
      };
      for (final entry in steps.entries) {
        expect(
          find.byKey(ValueKey<String>('planner-editor-${entry.key}')),
          findsOneWidget,
        );
        _expectWizardStageQuality(tester, entry.key, entry.value, size);
        if (entry.key == 'define') {
          await tester.enterText(
            find.byKey(const ValueKey<String>('planner-editor-title')),
            'مرور برنامه Cardiology برای فردا',
          );
        }
        if (entry.key != 'review') {
          await tester.tap(
            find.byKey(const ValueKey<String>('planner-editor-next')),
          );
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RTL at 200 percent text mirrors navigation and removes spatial page motion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(
        tester,
        textScaler: const TextScaler.linear(2),
        textDirection: TextDirection.rtl,
        disableAnimations: true,
      );

      final today = _footerDestination('today');
      final more = _footerDestination('more');
      expect(
        tester.getCenter(today).dx,
        greaterThan(tester.getCenter(more).dx),
      );

      expect(
        find.byKey(
          const ValueKey<String>('perfect-persistent-destination-host'),
        ),
        findsOneWidget,
      );

      await tester.tap(_footerDestination('tasks'));
      await tester.pump();
      expect(find.text('Good morning'), findsNothing);
      expect(
        find.text('Good morning', skipOffstage: false),
        findsOneWidget,
        reason: 'Reduced motion swaps pages immediately but retains state.',
      );
      expect(
        find.text('Search, filter and act without losing the working context.'),
        findsOneWidget,
      );
      expect(find.text('Open · All · Due date'), findsOneWidget);
      expect(find.textContaining('result'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the final Today task scrolls fully above collapsed and expanded capture',
    (tester) async {
      const finalTitle = 'Water plants';
      final finalTask = _controller.habits.singleWhere(
        (item) => item.title == finalTitle,
      );

      await tester.binding.setSurfaceSize(const Size(320, 700));
      await _pump(tester);
      await tester.scrollUntilVisible(
        find.text(finalTitle),
        280,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey<String>('perfect-today-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      final finalRow = find.byKey(
        ValueKey<String>('entity-context-${finalTask.id}'),
      );
      final dock = find.byKey(
        const ValueKey<String>('perfect-quick-capture-surface'),
      );
      expect(find.text(finalTitle), findsOneWidget);
      expect(
        tester.getBottomRight(finalRow).dy,
        lessThanOrEqualTo(tester.getTopLeft(dock).dy),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(finalTitle),
        280,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey<String>('perfect-today-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getBottomRight(finalRow).dy,
        lessThanOrEqualTo(tester.getTopLeft(dock).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('agenda percentage copy keeps an optical safe area inside ring', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester, textScaler: const TextScaler.linear(2));

    final cores = find.byKey(
      const ValueKey<String>('perfect-agenda-progress-safe-core'),
    );
    final todayScroll = find.descendant(
      of: find.byKey(const PageStorageKey<String>('perfect-today-scroll')),
      matching: find.byType(Scrollable),
    );
    for (var attempt = 0; attempt < 8 && cores.evaluate().isEmpty; attempt++) {
      await tester.drag(todayScroll, const Offset(0, -240));
      await tester.pumpAndSettle();
    }
    expect(cores, findsWidgets);
    for (final element in cores.evaluate()) {
      final core = find.byWidget(element.widget);
      final percentage = find.descendant(
        of: core,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.trim().endsWith('%') ?? false),
        ),
      );
      expect(percentage, findsOneWidget);
      final safeCore = tester.getRect(core).deflate(5);
      final percentageRect = tester.getRect(percentage);
      expect(
        safeCore.contains(percentageRect.topLeft),
        isTrue,
        reason: 'percentage $percentageRect must start inside $safeCore',
      );
      expect(
        safeCore.contains(percentageRect.bottomRight),
        isTrue,
        reason: 'percentage $percentageRect must end inside $safeCore',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact task details open the existing editor', (tester) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    final task = _controller.tasks.singleWhere(
      (item) => item.title == 'Focus Deep Work',
    );
    await tester.tap(find.byKey(ValueKey<String>('entity-context-${task.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Edit details'), findsOneWidget);
    expect(find.textContaining('Type is fixed after creation'), findsOneWidget);
  });

  testWidgets(
    'expanded Windows keeps Today Pulse above one dominant day stream',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      await _pump(tester, platform: TargetPlatform.windows);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Inspector'), findsNothing);
      final pulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(pulse.bottom, lessThan(stream.top));
      expect(pulse.left, closeTo(stream.left, 1));
      expect(pulse.right, closeTo(stream.right, 1));
      expect(pulse.height, lessThan(260));
      expect(find.text('Focus Deep Work'), findsWidgets);
      final habit = _controller.habits.singleWhere(
        (item) => item.title == 'Water plants',
      );
      final habitRow = find.byKey(
        ValueKey<String>('entity-context-${habit.id}'),
      );
      expect(
        tester.getBottomRight(habitRow).dy,
        lessThanOrEqualTo(stream.bottom),
        reason: 'Expanded default stream must show the complete final card.',
      );
      final source = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );
      await tester.tap(
        find.byKey(ValueKey<String>('entity-context-${source.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inspector'), findsOneWidget);
      final stage = tester.getRect(
        find.byKey(const ValueKey<String>('expanded-day-deck-stage')),
      );
      expect(
        find.byKey(const ValueKey<String>('expanded-focus-panel')),
        findsNothing,
        reason: 'Desktop has enough width for an attached inspector.',
      );
      final inspector = tester.getRect(
        find.byKey(ValueKey<String>('expanded-inspector-${source.id}')),
      );
      final streamAfterSelection = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(streamAfterSelection.right, lessThan(inspector.left));
      expect(inspector.top, closeTo(stage.top, 1));
      expect(inspector.bottom, closeTo(stage.bottom, 1));
      expect(inspector.right, closeTo(stage.right, 1));
      expect(
        find.bySemanticsLabel('Close inspector and return to Today'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_expanded.png'),
      );
      await tester.tap(find.byTooltip('Close inspector'));
      await tester.pumpAndSettle();
      expect(find.text('Inspector'), findsNothing);
    },
    tags: 'windows-golden',
  );

  testWidgets('sparse wide Today keeps the selected inspector content-led', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await _pump(tester, platform: TargetPlatform.windows);
    final source = _controller.tasks.singleWhere(
      (item) => item.title == 'Focus Deep Work',
    );
    await tester.tap(
      find.byKey(ValueKey<String>('entity-context-${source.id}')),
    );
    await tester.pumpAndSettle();

    final stage = tester.getRect(
      find.byKey(const ValueKey<String>('expanded-day-deck-stage')),
    );
    final stream = tester.getRect(
      find.byKey(const ValueKey<String>('day-stream-panel')),
    );
    final inspector = tester.getRect(
      find.byKey(ValueKey<String>('expanded-inspector-${source.id}')),
    );
    expect(
      stage.height,
      lessThan(420),
      reason: 'Sparse agenda, not a 600dp inspector floor, owns stage height.',
    );
    expect(stage.height, greaterThanOrEqualTo(300));
    expect(inspector.height, closeTo(stage.height, 1));
    expect(stream.height, closeTo(stage.height, 1));
    final focusPrompt = find.text('Shape the next block');
    await tester.scrollUntilVisible(
      focusPrompt,
      100,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey<String>('perfect-inspector-detail-scroll'),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(focusPrompt, findsOneWidget);
    expect(inspector.contains(tester.getCenter(focusPrompt)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide Windows Day Deck promotes selected detail to a true third pane',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await _pump(tester, platform: TargetPlatform.windows);
      final source = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );

      await tester.tap(
        find.byKey(ValueKey<String>('entity-context-${source.id}')),
      );
      await tester.pumpAndSettle();

      final pulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      final inspector = tester.getRect(
        find.byKey(ValueKey<String>('expanded-inspector-${source.id}')),
      );
      expect(
        find.byKey(const ValueKey<String>('expanded-focus-panel')),
        findsNothing,
      );
      expect(stream.right, lessThan(inspector.left));
      expect(stream.top, closeTo(inspector.top, 1));
      expect(stream.bottom, closeTo(inspector.bottom, 1));
      expect(pulse.bottom, lessThan(stream.top));
      final focusPrompt = find.text('Shape the next block');
      await tester.scrollUntilVisible(
        focusPrompt,
        100,
        scrollable: find.descendant(
          of: find.byKey(
            const PageStorageKey<String>('perfect-inspector-detail-scroll'),
          ),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        focusPrompt,
        findsOneWidget,
        reason: 'Wide inspector must keep actionable context reachable.',
      );
      expect(inspector.contains(tester.getCenter(focusPrompt)), isTrue);
      final stage = tester.getRect(
        find.byKey(const ValueKey<String>('expanded-day-deck-stage')),
      );
      expect(
        stage.height,
        lessThanOrEqualTo(520),
        reason:
            'Persistent detail must follow agenda content instead of inflating the workbench.',
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_windows_wide_inspector.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'short Windows landscape keeps a full-scale deck in a scrollable stage',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 600));
      await _pump(tester, platform: TargetPlatform.windows);

      final pulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(pulse.bottom, lessThan(stream.top));
      expect(pulse.height, lessThan(240));
      expect(
        find.byKey(
          const PageStorageKey<String>('perfect-expanded-today-scroll'),
        ),
        findsOneWidget,
      );
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      expect(capture.top, greaterThanOrEqualTo(0));
      expect(
        capture.bottom,
        lessThanOrEqualTo(600),
        reason: 'Short Windows must keep the full capture control in view.',
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_windows_short.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'expanded Windows at 200 percent text keeps Pulse and stream readable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      await _pump(tester, textScaler: const TextScaler.linear(2));

      final pulse = tester.getRect(
        find.byKey(const ValueKey<String>('today-pulse')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(pulse.bottom, lessThan(stream.top));
      expect(
        find.byKey(const ValueKey<String>('today-pulse-compact')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Windows Day Deck remains proportionate through intermediate resizes',
    (tester) async {
      for (final width in <double>[1280, 1366, 1600]) {
        await tester.binding.setSurfaceSize(Size(width, 820));
        await _pump(tester);

        final pulse = tester.getRect(
          find.byKey(const ValueKey<String>('today-pulse')),
        );
        final stream = tester.getRect(
          find.byKey(const ValueKey<String>('day-stream-panel')),
        );
        final deck = tester.getRect(
          find.byKey(const ValueKey<String>('expanded-day-deck-stage')),
        );
        expect(pulse.bottom, lessThan(stream.top), reason: 'width $width');
        expect(
          pulse.width / deck.width,
          closeTo(1, .02),
          reason: 'width $width',
        );
        expect(stream.width, greaterThan(500), reason: 'width $width');
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    },
  );

  testWidgets('desktop inspector duplicates and selects an independent item', (
    tester,
  ) async {
    final navigation = PerfectWorkspaceNavigationController();
    addTearDown(navigation.dispose);
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    await _pump(tester, navigationController: navigation);
    final source = _controller.tasks.singleWhere(
      (item) => item.title == 'Focus Deep Work',
    );

    navigation.showEntity(source.id);
    await tester.pumpAndSettle();
    expect(find.text('Inspector'), findsOneWidget);
    final duplicateAction = find.text('Duplicate', skipOffstage: false);
    await tester.tap(duplicateAction);
    await _pumpUntil(
      tester,
      () =>
          _controller.tasks
              .where((item) => item.title == 'Focus Deep Work')
              .length ==
          2,
    );
    await _pumpUntil(
      tester,
      () => _controller.syncStatus.phase != PlannerSyncPhase.syncing,
    );

    final matching = _controller.tasks
        .where((item) => item.title == 'Focus Deep Work')
        .toList(growable: false);
    expect(matching, hasLength(2));
    final duplicate = matching.singleWhere((item) => item.id != source.id);
    expect(duplicate.id, isNot(source.id));
    expect(
      PlannerTaskProgress.fromEntity(duplicate).state,
      PlannerTaskProgressState.pending,
    );
    expect(find.text('Inspector'), findsOneWidget);
    expect(
      find.text('Duplicated “Focus Deep Work”. Progress starts fresh.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'desktop inspector divider supports drag keyboard and a useful main pane',
    (tester) async {
      final navigation = PerfectWorkspaceNavigationController();
      addTearDown(navigation.dispose);
      await tester.binding.setSurfaceSize(const Size(1366, 820));
      await _pump(
        tester,
        navigationController: navigation,
        platform: TargetPlatform.windows,
      );
      final source = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );

      navigation.showEntity(source.id);
      await tester.pumpAndSettle();
      final divider = find.byKey(
        const ValueKey<String>('perfect-inspector-divider'),
      );
      final pane = find.byKey(const ValueKey<String>('perfect-inspector-pane'));
      expect(divider, findsOneWidget);
      final initialWidth = tester.getSize(pane).width;
      expect(tester.getSize(divider).width, 48);

      await tester.drag(divider, const Offset(-52, 0));
      await tester.pumpAndSettle();
      final draggedWidth = tester.getSize(pane).width;
      expect(draggedWidth, greaterThan(initialWidth));

      await tester.tap(divider);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.getSize(pane).width, lessThan(draggedWidth));
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('perfect-tasks-scroll')))
            .width,
        greaterThanOrEqualTo(680),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact item menu duplicates and opens the duplicate editor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);
    final source = _controller.tasks.singleWhere(
      (item) => item.title == 'Focus Deep Work',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${source.id}'));
    await _keepTodayTargetClear(tester, row);

    await tester.longPress(row);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await _pumpUntil(
      tester,
      () =>
          _controller.tasks
              .where((item) => item.title == 'Focus Deep Work')
              .length ==
          2,
    );
    await _pumpUntil(
      tester,
      () => _controller.syncStatus.phase != PlannerSyncPhase.syncing,
    );

    expect(
      _controller.tasks.where((item) => item.title == 'Focus Deep Work'),
      hasLength(2),
    );
    expect(find.text('Edit details'), findsOneWidget);
    await _openEditorStep(tester, 'define');
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey<String>('planner-editor-title')),
          )
          .controller
          ?.text,
      'Focus Deep Work',
    );
  });

  testWidgets(
    'Today expands anchored recurrence and respects pause, weekday, exception, and limit rules',
    (tester) async {
      await _saveRecurring(
        tester: tester,
        title: 'Daily anchor',
        scheduledAt: _previewNow.subtract(const Duration(days: 3)),
        recurrence: const <String, dynamic>{'rule': 'daily'},
      );
      await _saveRecurring(
        tester: tester,
        title: 'Weekly match',
        scheduledAt: _previewNow.subtract(const Duration(days: 7)),
        recurrence: <String, dynamic>{
          'rule': 'weekly',
          'weekdays': <int>[_previewNow.weekday],
        },
      );
      await _saveRecurring(
        tester: tester,
        title: 'Wrong weekday',
        scheduledAt: _previewNow.subtract(const Duration(days: 6)),
        recurrence: <String, dynamic>{
          'rule': 'weekly',
          'weekdays': <int>[
            _previewNow.weekday == DateTime.sunday
                ? DateTime.monday
                : _previewNow.weekday + 1,
          ],
        },
      );
      await _saveRecurring(
        tester: tester,
        title: 'Paused daily',
        scheduledAt: _previewNow.subtract(const Duration(days: 2)),
        recurrence: const <String, dynamic>{'rule': 'daily', 'paused': true},
      );
      await _saveRecurring(
        tester: tester,
        title: 'Except today',
        scheduledAt: _previewNow.subtract(const Duration(days: 2)),
        recurrence: <String, dynamic>{
          'rule': 'daily',
          'exceptions': <String>[_previewNow.toUtc().toIso8601String()],
        },
      );
      await _saveRecurring(
        tester: tester,
        title: 'Limit exhausted',
        scheduledAt: _previewNow.subtract(const Duration(days: 2)),
        recurrence: const <String, dynamic>{
          'rule': 'daily',
          'occurrence_limit': 2,
        },
      );
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester);

      expect(find.text('Daily anchor'), findsOneWidget);
      expect(find.text('Weekly match'), findsOneWidget);
      expect(find.text('Wrong weekday'), findsNothing);
      expect(find.text('Paused daily'), findsNothing);
      expect(find.text('Except today'), findsNothing);
      expect(find.text('Limit exhausted'), findsNothing);
    },
  );

  testWidgets('Today orders recurring work by this day’s occurrence time', (
    tester,
  ) async {
    await _saveRecurring(
      tester: tester,
      title: 'Late daily',
      scheduledAt: _previewNow
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 14)),
      recurrence: const <String, dynamic>{'rule': 'daily'},
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    final morning = find.text('Focus Deep Work').first;
    final evening = find.text('Late daily').first;
    expect(morning, findsOneWidget);
    expect(evening, findsOneWidget);
    expect(
      tester.getTopLeft(morning).dy,
      lessThan(tester.getTopLeft(evening).dy),
    );
  });

  testWidgets('Today shows honest capture invitation for a clean owner', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    final original = _controller as _ProjectionFailureController;
    final replacementDatabase = PlannerDatabase(NativeDatabase.memory());
    final replacementStore = PlannerLocalStore(replacementDatabase);
    final replacement = _ProjectionFailureController(
      replacementStore,
      PlannerSyncRepository(
        replacementStore,
        _PreviewGateway(),
        ownerId: 'empty-owner',
        deviceId: '22222222-2222-4222-8222-222222222222',
      ),
      ownerId: 'empty-owner',
      now: () => _previewNow,
    );
    addTearDown(() async {
      await original.disposeAsync();
      await replacement.disposeAsync();
    });
    await tester.runAsync(() async {
      await replacement.start();
      await replacement.refresh();
      await Future<void>.delayed(Duration.zero);
    });
    _controller = replacement;
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: PerfectWorkspacePage(
          controller: replacement,
          themeMode: ThemeMode.light,
          onThemeModeChanged: (_) {},
          onSignOut: () async {},
          now: () => _previewNow,
        ),
      ),
    );
    expect(find.text('Focus Deep Work'), findsNothing);
    expect(find.text('Water plants'), findsNothing);
    await tester.pumpAndSettle();
    final settled = tester.widget<TodayPulse>(find.byType(TodayPulse));
    expect(settled.snapshot.state, TodayPulseState.empty);
    expect(find.text('Your day has room.'), findsOneWidget);
    expect(find.text('Add a task'), findsOneWidget);
    expect(find.text('Focus Deep Work'), findsNothing);
    expect(find.text('Water plants'), findsNothing);
    await tester.tap(find.text('Add a task'));
    await tester.pumpAndSettle();
    expect(find.text('Make it yours'), findsOneWidget);
    expect(replacement.entities, isEmpty);
  });

  testWidgets('collapsed capture is only a 64dp circle above the footer', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    final launcher = find.byKey(
      const ValueKey<String>('perfect-quick-capture-toggle'),
    );
    final surface = find.byKey(
      const ValueKey<String>('perfect-quick-capture-surface'),
    );
    final navigation = find.byType(NavigationBar);
    expect(launcher, findsOneWidget);
    expect(surface, findsOneWidget);
    expect(navigation, findsOneWidget);

    final launcherRect = tester.getRect(launcher);
    final surfaceRect = tester.getRect(surface);
    final navigationRect = tester.getRect(navigation);
    expect(launcherRect.width, closeTo(64, 1));
    expect(launcherRect.height, closeTo(64, 1));
    expect(surfaceRect.width, closeTo(64, 1));
    expect(surfaceRect.height, closeTo(64, 1));
    expect(surfaceRect.bottom, lessThanOrEqualTo(navigationRect.top));
    expect(
      launcherRect.left,
      greaterThan(navigationRect.left),
      reason: 'The orb floats clear of the left edge, not full-width.',
    );
    expect(
      launcherRect.right,
      lessThan(navigationRect.right),
      reason: 'The orb floats clear of the right edge, not full-width.',
    );
  });

  testWidgets('Plan mode preserves task draft and routes exact habit kind', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
    );
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey<String>('perfect_quick_capture'))
          .evaluate()
          .isNotEmpty,
    );
    const draft = 'Plan this after lunch';
    await tester.enterText(
      find.byKey(const ValueKey<String>('perfect_quick_capture')),
      draft,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-capture-plan')),
    );
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey<String>('perfect-plan-mode'))
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.byKey(const ValueKey<String>('perfect_quick_capture')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('perfect-plan-kind-task')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('perfect-plan-kind-recurring')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('perfect-plan-kind-habit')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('perfect-plan-back')));
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey<String>('perfect_quick_capture'))
          .evaluate()
          .isNotEmpty,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('perfect_quick_capture')),
          )
          .controller
          ?.text,
      draft,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-capture-plan')),
    );
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey<String>('perfect-plan-mode'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-plan-kind-habit')),
    );
    await tester.pumpAndSettle();
    expect(find.text('What are you shaping?'), findsOneWidget);
    expect(find.byType(PlannerEditor), findsOneWidget);
  });

  testWidgets('quick capture failure keeps the draft with local recovery', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    const failingDraft = 'Keep this failing draft';
    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
    );
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey<String>('perfect_quick_capture'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('perfect_quick_capture')),
      failingDraft,
    );
    await _pumpUntil(
      tester,
      () => find.byTooltip('Save quick capture').evaluate().isNotEmpty,
    );
    final before = _controller.tasks.length;
    (_controller as _ProjectionFailureController).failQuickCapture = true;
    await tester.tap(find.byTooltip('Save quick capture'));
    await _pumpUntil(
      tester,
      () => find
          .text('Could not save this task locally. Try again.')
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.text('Could not save this task locally. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Captured locally. Sync will follow.'), findsNothing);
    expect(_controller.tasks.length, before);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('perfect_quick_capture')),
          )
          .controller
          ?.text,
      failingDraft,
    );
  });

  testWidgets('quick capture writes exactly one local task with undo', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    final before = _controller.tasks.length;
    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
    );
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey<String>('perfect_quick_capture'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('perfect_quick_capture')),
      'Buy oat milk  ',
    );
    await _pumpUntil(
      tester,
      () => find.byTooltip('Save quick capture').evaluate().isNotEmpty,
    );
    await tester.tap(find.byTooltip('Save quick capture'));
    await _pumpUntil(
      tester,
      () => find
          .text('Captured locally. Sync will follow.')
          .evaluate()
          .isNotEmpty,
    );
    expect(find.text('Captured locally. Sync will follow.'), findsOneWidget);
    final pendingId = _controller.tasks
        .firstWhere((item) => item.title == 'Buy oat milk')
        .id;
    expect(_controller.tasks.length, before + 1);
    final captured = _controller.tasks.firstWhere(
      (item) => item.id == pendingId,
    );
    expect(captured.title, 'Buy oat milk');
    expect(
      _controller.tasks
          .where((item) => item.title == 'Buy oat milk')
          .toList(growable: false),
      hasLength(1),
      reason: 'One quick save writes exactly one local task.',
    );
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await _pumpUntil(
      tester,
      () => _controller.tasks
          .where((item) => item.title == 'Buy oat milk')
          .isEmpty,
    );
    expect(
      _controller.tasks.where((item) => item.title == 'Buy oat milk'),
      isEmpty,
    );
  });

  testWidgets('Today local-source retries without destructive reset', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    final original = _controller as _ProjectionFailureController;
    original.failLocalWatchOnce();
    original.failTaskReads = false;
    original.invalidateProjection();
    await tester.pumpAndSettle();
    expect(find.textContaining('Today could not refresh'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry today'), findsOneWidget);
    original.allowLocalWatch();
    await tester.tap(find.widgetWithText(TextButton, 'Retry today'));
    await tester.pumpAndSettle();
    expect(find.text('Today could not refresh'), findsNothing);
    expect(find.text('Focus Deep Work'), findsOneWidget);
    expect(find.text('Water plants'), findsOneWidget);
    expect(original.localError, isNull);
  });

  testWidgets(
    'Today projection failure offers local retry without hiding rows',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester);
      final controller = _controller as _ProjectionFailureController;
      expect(find.text('Focus Deep Work'), findsOneWidget);
      controller.failTaskReads = true;
      controller.invalidateProjection();
      await tester.pumpAndSettle();

      expect(find.text('Focus Deep Work'), findsOneWidget);
      expect(find.textContaining('Today could not refresh'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Retry today'), findsOneWidget);
      final failedReads = controller.failedReads;
      await tester.pump();
      expect(controller.failedReads, failedReads);

      controller.failTaskReads = false;
      await tester.tap(find.widgetWithText(TextButton, 'Retry today'));
      await tester.pumpAndSettle();
      expect(find.text('Today could not refresh'), findsNothing);
      expect(find.text('Focus Deep Work'), findsOneWidget);
    },
  );

  testWidgets(
    'Today preserves daily outcomes after a projection read failure',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      final task = _controller.tasks.single;
      await _runControllerMutation(
        tester,
        () => _controller.setTaskProgress(
          task,
          progress: const PlannerTaskProgress(
            state: PlannerTaskProgressState.partial,
            percent: 40,
          ),
          localDay: _previewNow,
        ),
      );
      await _pump(tester);
      TodayPulseSnapshot snapshot() =>
          tester.widget<TodayPulse>(find.byType(TodayPulse)).snapshot;
      expect(snapshot().partial, 1);
      final controller = _controller as _ProjectionFailureController;
      controller.failTaskReads = true;
      controller.invalidateProjection();
      await tester.pumpAndSettle();
      expect(controller.failedReads, greaterThan(0));
      expect(snapshot().state, TodayPulseState.resolving);
      expect(snapshot().partial, 1);
      // Even when canonical data changes, a failed read must not publish an
      // invented snapshot. Recovery must then publish the new stored outcome.
      await _runControllerMutation(
        tester,
        () => _controller.setTaskProgress(
          _controller.tasks.single,
          progress: const PlannerTaskProgress(
            state: PlannerTaskProgressState.completed,
            percent: 100,
          ),
          localDay: _previewNow,
        ),
      );
      await tester.pumpAndSettle();
      expect(snapshot().state, TodayPulseState.resolving);
      expect(snapshot().partial, 1);
      expect(snapshot().completed, 0);
      final failedReads = controller.failedReads;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(controller.failedReads, failedReads);
      controller.failTaskReads = false;
      controller.invalidateProjection();
      await tester.pumpAndSettle();
      expect(snapshot().state, isNot(TodayPulseState.resolving));
      expect(snapshot().partial, 0);
      expect(snapshot().completed, 1);
    },
  );

  testWidgets('Today cancels suspended reads when controller owner changes', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    final original = _controller as _ProjectionFailureController;
    final gate = Completer<void>();
    original.eligibilityGate = gate.future;
    await _pump(tester);
    expect(original.suspendedEligibilityReads, greaterThan(0));
    final previousState = tester.state(find.byType(PerfectWorkspacePage));

    final replacementDatabase = PlannerDatabase(NativeDatabase.memory());
    final replacementStore = PlannerLocalStore(replacementDatabase);
    final replacement = _ProjectionFailureController(
      replacementStore,
      PlannerSyncRepository(
        replacementStore,
        _PreviewGateway(),
        ownerId: 'replacement-owner',
        deviceId: '22222222-2222-4222-8222-222222222222',
      ),
      ownerId: 'replacement-owner',
      now: () => _previewNow,
    );
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await original.disposeAsync();
    });
    await tester.runAsync(() async {
      await replacement.start();
      await replacement.refresh();
      await Future<void>.delayed(Duration.zero);
    });
    expect(replacement.isReady, isTrue);
    _controller = replacement;
    await _pump(tester);
    expect(
      tester.state(find.byType(PerfectWorkspacePage)),
      same(previousState),
    );
    expect(find.text('Focus Deep Work'), findsNothing);
    expect(find.text('Water plants'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(replacement.foreignOutcomeReads, 0);
    expect(find.text('Focus Deep Work'), findsNothing);
    expect(find.text('Water plants'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today stops suspended outcome reads after page disposal', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    final controller = _controller as _ProjectionFailureController;
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    controller.eligibilityGate = gate.future;
    await _pump(tester);
    expect(controller.suspendedEligibilityReads, greaterThan(0));
    final readsBeforeDisposal = controller.outcomeReads;

    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    await tester.pumpAndSettle();

    expect(controller.outcomeReads, readsBeforeDisposal);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Today keeps visible row anchored when earlier task is inserted',
    (tester) async {
      await _setTestViewSize(tester, const Size(390, 844));
      await _runControllerMutation(tester, () async {
        for (var i = 0; i < 18; i++) {
          await _controller.saveEntity(
            kind: PlannerEntityKind.oneOffTask,
            payload: <String, dynamic>{
              ...defaultPlannerPayload(title: 'Anchor task $i'),
              PlannerPayloadKeys.timing: <String, dynamic>{
                'scheduled_at': _previewNow
                    .add(Duration(minutes: i + 1))
                    .toUtc()
                    .toIso8601String(),
              },
            },
          );
        }
      });
      await _pump(tester);
      final today = find.byKey(
        const PageStorageKey<String>('perfect-today-scroll'),
      );
      final anchor = find.text('Anchor task 8');
      await tester.scrollUntilVisible(
        anchor,
        180,
        scrollable: find
            .descendant(of: today, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(anchor).dy;
      expect(before, greaterThanOrEqualTo(tester.getTopLeft(today).dy));
      await _runControllerMutation(
        tester,
        () => _controller.saveEntity(
          kind: PlannerEntityKind.oneOffTask,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Inserted before visible anchor'),
            PlannerPayloadKeys.timing: <String, dynamic>{
              'scheduled_at': _previewNow
                  .subtract(const Duration(minutes: 1))
                  .toUtc()
                  .toIso8601String(),
            },
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(anchor).dy, closeTo(before, 1));
      expect(tester.takeException(), isNull);
    },
  );

  for (final complete in [false, true]) {
    testWidgets(
      'Today preserves neighbor when visible anchor is ${complete ? 'completed' : 'removed'}',
      (tester) async {
        await _setTestViewSize(tester, const Size(390, 844));
        await _runControllerMutation(tester, () async {
          for (var i = 0; i < 18; i++) {
            await _controller.saveEntity(
              kind: PlannerEntityKind.oneOffTask,
              payload: <String, dynamic>{
                ...defaultPlannerPayload(title: 'Neighbor task $i'),
                PlannerPayloadKeys.timing: <String, dynamic>{
                  'scheduled_at': _previewNow
                      .add(Duration(minutes: i + 1))
                      .toUtc()
                      .toIso8601String(),
                },
              },
            );
          }
        });
        await _pump(tester);
        final today = find.byKey(
          const PageStorageKey<String>('perfect-today-scroll'),
        );
        await tester.scrollUntilVisible(
          find.text('Neighbor task 8'),
          180,
          scrollable: find
              .descendant(of: today, matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
        final neighbor = find.text('Neighbor task 9');
        final before = tester.getTopLeft(neighbor).dy;
        final entity = _controller.tasks.singleWhere(
          (task) => task.title == 'Neighbor task 8',
        );
        await _runControllerMutation(
          tester,
          () => complete
              ? _controller.setTaskProgress(
                  entity,
                  progress: const PlannerTaskProgress(
                    state: PlannerTaskProgressState.completed,
                    percent: 100,
                  ),
                  localDay: _previewNow,
                )
              : _controller.deleteEntity(entity),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(neighbor).dy, closeTo(before, 1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Today exposes scheduled and habit groups around real rows', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    final today = find.byKey(
      const PageStorageKey<String>('perfect-today-scroll'),
    );
    final task = find.descendant(
      of: today,
      matching: find.text('Focus Deep Work'),
    );
    final habit = find.descendant(
      of: today,
      matching: find.text('Water plants'),
    );
    // First prove the persisted fixture reached the actual Today renderer.
    // A missing group is then a presentation-contract failure, not empty data.
    expect(task, findsOneWidget);
    expect(habit, findsOneWidget);
    final scheduled = find.descendant(
      of: today,
      matching: find.text('Scheduled'),
    );
    final habits = find.descendant(of: today, matching: find.text('Habits'));
    expect(scheduled, findsOneWidget);
    expect(habits, findsOneWidget);
    expect(
      tester.getTopLeft(scheduled).dy,
      lessThan(tester.getTopLeft(task).dy),
    );
    expect(tester.getTopLeft(task).dy, lessThan(tester.getTopLeft(habits).dy));
    expect(tester.getTopLeft(habits).dy, lessThan(tester.getTopLeft(habit).dy));
  });

  for (final viewport in <Size>[
    const Size(390, 844),
    const Size(800, 1000),
    const Size(1366, 768),
  ]) {
    testWidgets(
      'Today section lifecycle follows stored outcomes at ${viewport.width.toInt()}dp',
      (tester) async {
        await _setTestViewSize(tester, viewport);
        await _pump(tester);

        Finder stream() => viewport.width < 600
            ? find.byKey(const PageStorageKey<String>('perfect-today-scroll'))
            : find.byKey(const ValueKey<String>('day-stream-panel'));
        Finder heading(String section) => find.descendant(
          of: stream(),
          matching: find.byKey(ValueKey<String>('day-section-$section')),
        );
        Finder title(String text) =>
            find.descendant(of: stream(), matching: find.text(text));

        expect(stream(), findsOneWidget);
        expect(heading('scheduled'), findsOneWidget);
        expect(heading('habits'), findsOneWidget);
        for (final section in <String>['decision', 'flexible', 'settled']) {
          expect(heading(section), findsNothing);
        }
        expect(title('Focus Deep Work'), findsOneWidget);
        expect(title('Water plants'), findsOneWidget);

        final taskId = _controller.tasks.single.id;
        await _runControllerMutation(
          tester,
          () => _controller.setTaskProgress(
            _controller.tasks.singleWhere((task) => task.id == taskId),
            progress: const PlannerTaskProgress(
              state: PlannerTaskProgressState.completed,
              percent: 100,
            ),
            localDay: _previewNow,
          ),
        );
        await tester.pumpAndSettle();

        expect(heading('scheduled'), findsNothing);
        expect(heading('settled'), findsOneWidget);
        expect(title('Focus Deep Work'), findsOneWidget);
        expect(title('Water plants'), findsOneWidget);
        expect(
          tester.getTopLeft(title('Water plants')).dy,
          lessThan(tester.getTopLeft(heading('settled')).dy),
        );
        expect(
          tester.getTopLeft(heading('settled')).dy,
          lessThan(tester.getTopLeft(title('Focus Deep Work')).dy),
        );

        // Exercise persisted correction, not a UI-only optimistic reset.
        // This is not proof of the separate user-facing Undo affordance.
        await _runControllerMutation(
          tester,
          () => _controller.setTaskProgress(
            _controller.tasks.singleWhere((task) => task.id == taskId),
            progress: const PlannerTaskProgress.pending(),
            localDay: _previewNow,
          ),
        );
        await tester.pumpAndSettle();

        expect(heading('settled'), findsNothing);
        expect(heading('scheduled'), findsOneWidget);
        expect(title('Focus Deep Work'), findsOneWidget);
        expect(
          tester.getTopLeft(heading('scheduled')).dy,
          lessThan(tester.getTopLeft(title('Focus Deep Work')).dy),
        );
        expect(
          tester.getTopLeft(title('Focus Deep Work')).dy,
          lessThan(tester.getTopLeft(heading('habits')).dy),
        );
        expect(_controller.tasks.single.id, taskId);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('status tap offers Undo that restores stored task outcome', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    final taskId = _controller.tasks.single.id;
    final status = find.byKey(const ValueKey<String>('task-status-hit')).first;
    await tester.tap(status);
    await _pumpUntil(
      tester,
      () =>
          _controller.tasks.singleWhere((task) => task.id == taskId).status ==
          PlannerEntityStatus.completed,
    );
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await _pumpUntil(
      tester,
      () =>
          _controller.tasks.singleWhere((task) => task.id == taskId).status ==
          PlannerEntityStatus.active,
    );
    expect(
      PlannerTaskProgress.fromEntity(
        _controller.tasks.singleWhere((task) => task.id == taskId),
      ).state,
      PlannerTaskProgressState.pending,
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[390, 800, 1366]) {
    testWidgets(
      'Today next semantics follows stored completion at ${width.toInt()}dp',
      (tester) async {
        await _setTestViewSize(tester, Size(width, 1000));
        await _pump(tester);
        Finder nextLabel(String title) => find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  '$title. Next action. Item actions available.' &&
              widget.properties.header != true,
        );
        expect(
          find.descendant(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label != null &&
                  widget.properties.label!.endsWith(
                    '. Next action. Item actions available.',
                  ),
            ),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.header == true,
            ),
          ),
          findsNothing,
        );
        Finder emphasis(String title) => find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'day-row-next-emphasis-',
              ) &&
              find
                  .descendant(
                    of: find.byWidget(widget),
                    matching: find.text(title),
                  )
                  .evaluate()
                  .isNotEmpty,
        );
        expect(nextLabel('Focus Deep Work'), findsOneWidget);
        expect(nextLabel('Water plants'), findsNothing);
        expect(emphasis('Focus Deep Work'), findsOneWidget);
        expect(emphasis('Water plants'), findsNothing);
        final task = _controller.tasks.single;
        await _runControllerMutation(
          tester,
          () => _controller.setTaskProgress(
            task,
            progress: const PlannerTaskProgress(
              state: PlannerTaskProgressState.completed,
              percent: 100,
            ),
            localDay: _previewNow,
          ),
        );
        await tester.pumpAndSettle();
        expect(nextLabel('Focus Deep Work'), findsNothing);
        expect(nextLabel('Water plants'), findsOneWidget);
        expect(emphasis('Focus Deep Work'), findsNothing);
        expect(emphasis('Water plants'), findsOneWidget);
        await _runControllerMutation(
          tester,
          () => _controller.setTaskProgress(
            _controller.tasks.single,
            progress: const PlannerTaskProgress.pending(),
            localDay: _previewNow,
          ),
        );
        await tester.pumpAndSettle();
        expect(nextLabel('Focus Deep Work'), findsOneWidget);
        expect(nextLabel('Water plants'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Today hides a flexible item after its period quota is reached', (
    tester,
  ) async {
    await _saveRecurring(
      tester: tester,
      title: 'Three times this week',
      scheduledAt: _previewNow.subtract(const Duration(days: 7)),
      recurrence: const <String, dynamic>{
        'rule': 'flexible',
        'frequency': <String, dynamic>{'count': 1, 'period': 'week'},
      },
    );
    await tester.pump();
    final flexible = _controller.tasks.singleWhere(
      (item) => item.title == 'Three times this week',
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    expect(find.text('Three times this week'), findsOneWidget);

    await _runControllerMutation(
      tester,
      () => _controller.setTaskProgress(
        flexible,
        progress: const PlannerTaskProgress(
          state: PlannerTaskProgressState.completed,
          percent: 100,
        ),
        localDay: _previewNow,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Three times this week'), findsNothing);

    await tester.tap(_footerDestination('plan'));
    await tester.pumpAndSettle();
    expect(find.text('Three times this week'), findsNothing);
  });

  testWidgets('Today surfaces a carry-cap recovery decision', (tester) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.oneOffTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Overdue decision'),
          PlannerPayloadKeys.timing: <String, dynamic>{
            'scheduled_at': _previewNow
                .subtract(const Duration(days: 2))
                .toUtc()
                .toIso8601String(),
          },
          PlannerPayloadKeys.recovery: const <String, dynamic>{
            'on_miss': 'pending',
            'carry_cap': 1,
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    await _scrollTodayToText(tester, 'Overdue decision');
    expect(find.text('Overdue decision'), findsOneWidget);
    expect(
      MediaQuery.sizeOf(
        tester.element(find.byType(PerfectWorkspacePage)),
      ).width,
      390,
    );
    expect(find.text('Decision needed · tap to resolve'), findsOneWidget);
    await tester.tap(find.text('Decision needed · tap to resolve'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('perfect-recovery-surface')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Keep pending today'), findsOneWidget);
    expect(find.text('Carry into today'), findsOneWidget);
    await tester.tap(find.text('Mark not done'));
    await _pumpUntil(
      tester,
      () => _controller.tasks
          .where((item) => item.title == 'Overdue decision')
          .any((item) => PlannerTaskProgress.fromEntity(item).isMissed),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overdue decision'), findsNothing);
    expect(
      _controller.tasks.map((item) => item.title),
      contains('Overdue decision'),
    );
    final resolved = _controller.tasks.singleWhere(
      (item) => item.title == 'Overdue decision',
    );
    expect(PlannerTaskProgress.fromEntity(resolved).isMissed, isTrue);
  });

  testWidgets('desktop recovery decision uses a bounded dialog', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.oneOffTask,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Desktop overdue decision'),
          PlannerPayloadKeys.timing: <String, dynamic>{
            'scheduled_at': _previewNow
                .subtract(const Duration(days: 2))
                .toUtc()
                .toIso8601String(),
          },
          PlannerPayloadKeys.recovery: const <String, dynamic>{
            'on_miss': 'pending',
            'carry_cap': 1,
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(1280, 800));
    await _pump(tester);

    await tester.tap(find.text('Decision needed · tap to resolve').last);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Keep pending today'), findsOneWidget);
    final dialogSize = tester.getSize(
      find.byKey(const ValueKey<String>('perfect-recovery-dialog-surface')),
    );
    expect(dialogSize.width, lessThanOrEqualTo(620));
    expect(dialogSize.height, lessThanOrEqualTo(700));
    await tester.tap(find.byTooltip('Close recovery decision'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets(
    'short landscape keeps Today Pulse, navigation, and capture usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 360));
      await _pump(tester);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Good morning'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Capture a task, before it disappears…'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native widget navigation returns an already-running workspace to Today',
    (tester) async {
      final navigation = PerfectWorkspaceNavigationController();
      addTearDown(navigation.dispose);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, navigationController: navigation);

      await tester.tap(_footerDestination('more'));
      await tester.pumpAndSettle();
      expect(
        find.text('Private controls, not public settings.'),
        findsOneWidget,
      );

      navigation.showToday();
      await tester.pumpAndSettle();
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Private controls, not public settings.'), findsNothing);
    },
  );

  testWidgets('More exposes the persistent private feedback capture control', (
    tester,
  ) async {
    const config = ReadyFeedbackConfig(
      applicationName: 'Perfect!',
      storageNamespace: 'perfect-feedback-test',
      settingsKey: 'perfect.feedback_capture_enabled',
    );
    late final ReadyFeedbackLogger feedbackLogger;
    late final ReadyFeedbackController feedback;
    await tester.runAsync(() async {
      feedbackLogger = ReadyFeedbackLogger(
        memoryLimit: 20,
        retryDelays: const <Duration>[],
      );
      feedback = ReadyFeedbackController(
        config: config,
        repository: _WorkspaceFeedbackRepository(config: config),
        logger: feedbackLogger,
      );
      await feedback.initialize();
    });
    addTearDown(feedbackLogger.dispose);
    addTearDown(feedback.dispose);

    await tester.binding.setSurfaceSize(const Size(900, 1000));
    await _pump(tester, feedbackController: feedback);
    expect(find.byTooltip('Capture feedback'), findsNothing);
    await tester.tap(find.byTooltip('More (Ctrl+5)'));
    await tester.pumpAndSettle();
    expect(find.text('Capture feedback now'), findsOneWidget);
    await tester.tap(find.text('Capture feedback now'));
    await tester.pumpAndSettle();
    expect(find.text('Private feedback capture'), findsOneWidget);
    expect(
      find.text('Everything stays on this device until you export it.'),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('Feedback capture'), findsOneWidget);
    expect(find.text('Captured feedback & logs'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Private feedback and diagnostics settings'),
      findsOneWidget,
    );

    await tester.tap(find.text('Capture feedback now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Note only'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Keep the feedback route tied to the visible workspace section.',
    );
    await tester.tap(find.text('Save privately'));
    await tester.pump();
    await _pumpUntil(tester, () => !feedback.busy);
    await tester.pumpAndSettle();
    late final List<ReadyFeedbackEntry> saved;
    await tester.runAsync(() async {
      saved = await feedback.readEntries();
    });
    expect(saved, hasLength(1));
    expect(saved.single.route, 'More');
    expect(saved.single.kind, ReadyFeedbackKind.error);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(
      tester,
      feedbackController: feedback,
      textScaler: const TextScaler.linear(2),
    );
    expect(find.text('Capture feedback now'), findsOneWidget);
    expect(find.text('Feedback capture'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    expect(feedback.enabled, isFalse);
    expect(
      tester
          .widget<ListTile>(
            find.widgetWithText(ListTile, 'Capture feedback now'),
          )
          .onTap,
      isNull,
    );
    late final SharedPreferences preferences;
    await tester.runAsync(() async {
      preferences = await SharedPreferences.getInstance();
    });
    expect(preferences.getBool(config.settingsKey), isFalse);
  });

  testWidgets(
    'More groups commands into scan-friendly tracks and reflows for large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      await _pump(tester);
      await tester.tap(find.byTooltip('More (Ctrl+5)'));
      await tester.pumpAndSettle();

      for (final heading in <String>[
        'Appearance',
        'Workspace structure',
        'Focus and review',
        'Devices and resilience',
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
      final projects = tester.getRect(_cardContaining('Projects'));
      final areas = tester.getRect(_cardContaining('Areas'));
      expect(projects.top, closeTo(areas.top, 1));
      expect(projects.right, lessThan(areas.left));

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, textScaler: const TextScaler.linear(2));
      await tester.tap(_footerDestination('more'));
      await tester.pumpAndSettle();
      expect(find.text('Workspace structure'), findsOneWidget);
      expect(find.text('Focus and review'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Today deep link clears an inspector already open on Today', (
    tester,
  ) async {
    final navigation = PerfectWorkspaceNavigationController();
    addTearDown(navigation.dispose);
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    await _pump(tester, navigationController: navigation);

    final task = _controller.tasks.singleWhere(
      (item) => item.title == 'Focus Deep Work',
    );
    await tester.tap(find.byKey(ValueKey<String>('entity-context-${task.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Inspector'), findsOneWidget);

    navigation.showToday();
    await tester.pumpAndSettle();
    expect(find.text('Inspector'), findsNothing);
    expect(find.text('Today’s flow'), findsOneWidget);
  });

  testWidgets(
    'entity navigation opens the matching desktop destination and inspector',
    (tester) async {
      final navigation = PerfectWorkspaceNavigationController();
      addTearDown(navigation.dispose);
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      await _pump(
        tester,
        navigationController: navigation,
        platform: TargetPlatform.windows,
      );

      final task = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );
      navigation.showEntity(task.id);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
      expect(find.text('Inspector'), findsOneWidget);
      expect(find.text('Focus Deep Work'), findsWidgets);
    },
  );

  testWidgets(
    'a retained entity navigation opens compact details after cold mount',
    (tester) async {
      final navigation = PerfectWorkspaceNavigationController();
      addTearDown(navigation.dispose);
      final task = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );
      navigation.showEntity(task.id);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, navigationController: navigation);

      expect(find.text('Edit details'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('planner-editor-type')),
        findsOneWidget,
      );
      await _openEditorStep(tester, 'define');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey<String>('planner-editor-title')),
            )
            .controller
            ?.text,
        'Focus Deep Work',
      );
    },
  );

  testWidgets('a stale entity navigation is an explicit no-op', (tester) async {
    final navigation = PerfectWorkspaceNavigationController();
    addTearDown(navigation.dispose);
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    await _pump(tester, navigationController: navigation);
    await _sendControlShortcut(tester, LogicalKeyboardKey.digit5);
    await tester.pumpAndSettle();

    navigation.showEntity('entity-that-does-not-exist');
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      4,
    );
    expect(find.text('Private controls, not public settings.'), findsOneWidget);
    expect(find.text('Inspector'), findsNothing);
  });

  testWidgets('Plan browses days without mixing the unscheduled inbox', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('plan'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);
    expect(find.text('Water plants'), findsNothing);

    final localizations = MaterialLocalizations.of(
      tester.element(find.text('Plan').first),
    );
    for (var offset = -3; offset <= 3; offset++) {
      final day = _previewNow.add(Duration(days: offset));
      final label = localizations.formatFullDate(day);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.selected != null &&
              widget.properties.label == label,
        ),
        findsOneWidget,
        reason: 'The seven-day strip must expose $label as a direct target.',
      );
    }

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('No blocks yet.'), findsOneWidget);
    expect(find.text('Focus Deep Work'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('planner-back-to-today')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);
  });

  testWidgets(
    'Plan keeps its selected day through route changes and three shell tiers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      await _pump(tester);
      await _sendControlShortcut(tester, LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('planner-back-to-today')),
        findsOneWidget,
      );
      expect(find.text('No blocks yet.'), findsOneWidget);

      await _sendControlShortcut(tester, LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(1366, 820));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-shell-expanded')),
        findsOneWidget,
      );
      await _sendControlShortcut(tester, LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('planner-back-to-today')),
        findsOneWidget,
      );
      expect(find.text('No blocks yet.'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(650, 900));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-shell-compact')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('planner-back-to-today')),
        findsOneWidget,
      );
      expect(find.text('No blocks yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tasks separates single and recurring work without another page',
    (tester) async {
      await _saveRecurring(
        tester: tester,
        title: 'Weekly review',
        scheduledAt: _previewNow,
        recurrence: <String, dynamic>{
          'rule': 'weekly',
          'weekdays': <int>[_previewNow.weekday],
        },
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester);

      await tester.tap(_footerDestination('tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Focus Deep Work'), findsOneWidget);
      expect(find.text('TYPE'), findsNothing);
      expect(find.text('STATUS'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('task-filter-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Recurring'));
      await tester.pumpAndSettle();
      expect(find.text('Weekly review'), findsOneWidget);
      expect(find.text('Focus Deep Work'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Single'));
      await tester.pumpAndSettle();
      expect(find.text('Focus Deep Work'), findsOneWidget);
      expect(find.text('Weekly review'), findsNothing);
    },
  );

  testWidgets(
    'task search state survives destination changes and shell reflow',
    (tester) async {
      await _runControllerMutation(
        tester,
        () => _controller.saveEntity(
          kind: PlannerEntityKind.oneOffTask,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Read cardiology notes'),
            'note': 'Review the murmurs table',
            'category': 'Study',
          },
        ),
      );
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      await _pump(tester);
      await _sendControlShortcut(tester, LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.text('TYPE'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.textContaining('Open · All · Due date'), findsOneWidget);
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Find a task, note, or category…',
      );
      expect(search, findsOneWidget);
      final searchController = tester.widget<TextField>(search).controller;
      await tester.enterText(search, 'murmurs');
      await tester.pump();
      expect(find.text('Read cardiology notes'), findsOneWidget);
      expect(find.text('Focus Deep Work'), findsNothing);
      expect(find.text('1 result · Open · All · Due date'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpAndSettle();
      expect(find.text('Read cardiology notes'), findsOneWidget);
      expect(find.text('Open · All · Due date'), findsOneWidget);
      expect(find.text('TYPE'), findsNothing);
      expect(find.text('STATUS'), findsNothing);

      await tester.tap(_footerDestination('plan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Move across days without losing unfinished work.'),
        findsOneWidget,
      );
      await tester.tap(_footerDestination('tasks'));
      await tester.pumpAndSettle();

      final restoredSearch = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Find a task, note, or category…',
      );
      expect(
        tester.widget<TextField>(restoredSearch).controller,
        same(searchController),
      );
      expect(
        tester.widget<TextField>(restoredSearch).controller?.text,
        'murmurs',
      );
      expect(find.text('Read cardiology notes'), findsOneWidget);
      expect(find.text('Focus Deep Work'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact Tasks shows scheduled work first and discloses filters on demand',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester);

      await tester.tap(_footerDestination('tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Focus Deep Work'), findsOneWidget);
      expect(find.text('No open tasks.'), findsNothing);
      expect(find.text('Open · All · Due date'), findsOneWidget);
      expect(find.text('TYPE'), findsNothing);
      expect(find.text('STATUS'), findsNothing);

      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Find a task, note, or category…',
      );
      await tester.tap(search);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('task-filter-toggle')),
      );
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text('TYPE'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      final openChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey<String>('refine-status-Open')),
      );
      expect(openChip.selected, isTrue);
      expect(openChip.showCheckmark, isFalse);

      await tester.tap(
        find.byKey(const ValueKey<String>('refine-status-Inbox')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Focus Deep Work'), findsNothing);
      expect(find.text('Your inbox is clear.'), findsOneWidget);
    },
  );

  testWidgets('Tasks selection shows bulk bar and applies previewed complete', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('tasks-bulk-bar')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('task-select-off')).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('tasks-bulk-bar')),
      findsOneWidget,
    );
    expect(find.textContaining('1 selected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('tasks-bulk-preview')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('tasks-bulk-confirm')),
      findsOneWidget,
    );
    expect(find.text('Complete'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('tasks-bulk-confirm')));
    await _pumpUntil(
      tester,
      () =>
          find.textContaining('Bulk complete applied to').evaluate().isNotEmpty,
    );
    expect(find.textContaining('Bulk complete applied to'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('tasks-bulk-bar')), findsNothing);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await _pumpUntil(
      tester,
      () => find
          .text('Bulk change undone. Prior outcomes restored.')
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.text('Bulk change undone. Prior outcomes restored.'),
      findsOneWidget,
    );
  });

  testWidgets('Habits expose an honest seven-day schedule preview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('habits'));
    await tester.pumpAndSettle();
    expect(find.text('Water plants'), findsOneWidget);
    expect(find.text('Every day'), findsOneWidget);
    expect(find.text('Schedule this week'), findsOneWidget);
    expect(find.text('0 logged · 0 reached · 1 active'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Water plants',
    );
    await _runControllerMutation(tester, () => _controller.logHabit(habit));
    await tester.pumpAndSettle();
    expect(find.text('1 logged · 1 reached · 1 active'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('pending measured habit shows its real configured target', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Drink water'),
          PlannerPayloadKeys.tracking: <String, dynamic>{
            'method': 'count',
            'goal': 'at_least',
            'target': 8,
            'unit': 'glasses',
          },
        },
      ),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('habits'));
    await tester.pumpAndSettle();

    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('At least 8 glasses'), findsOneWidget);
    expect(find.text('Pending · 0 of 8 glasses · 0%'), findsOneWidget);
    expect(find.textContaining('of 1 glasses'), findsNothing);
  });

  testWidgets(
    'editing keeps entity type stable and preserves actionable checklist metadata',
    (tester) async {
      await _runControllerMutation(
        tester,
        () => _controller.saveEntity(
          kind: PlannerEntityKind.oneOffTask,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Checklist integrity'),
            PlannerPayloadKeys.timing: <String, dynamic>{
              'due_at': DateTime(2026, 7, 30, 23, 59).toUtc().toIso8601String(),
            },
            'focus': <String, dynamic>{
              'enabled': true,
              'mode': 'countdown',
              'minutes': 45,
            },
            'checklist': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'step-1',
                'title': 'Keep this state',
                'is_done': true,
                'owner_note': 'preserve me',
              },
            ],
          },
        ),
      );
      await tester.pump();
      final entity = _controller.tasks.singleWhere(
        (item) => item.title == 'Checklist integrity',
      );
      await _setTestViewSize(tester, const Size(800, 900));
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: Scaffold(
            body: PlannerEditor(controller: _controller, existing: entity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Type is fixed after creation'),
        findsOneWidget,
      );
      await _openEditorStep(tester, 'details');
      final chip = tester.widget<InputChip>(
        find.widgetWithText(InputChip, 'Keep this state'),
      );
      expect(chip.selected, isTrue);

      await _keepEditorTargetClear(
        tester,
        find.text('Keep this state'),
        stepId: 'details',
      );
      await tester.tap(find.text('Keep this state'));
      await tester.pump();
      expect(
        tester
            .widget<InputChip>(
              find.widgetWithText(InputChip, 'Keep this state'),
            )
            .selected,
        isFalse,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
      await _pumpUntil(tester, () {
        final matches = _controller.tasks.where(
          (item) => item.title == 'Checklist integrity',
        );
        if (matches.length != 1) return false;
        final savedChecklist = safeJsonMapList(
          matches.single.payload['checklist'],
        );
        return savedChecklist.length == 1 &&
            savedChecklist.single['is_done'] == false;
      });
      await tester.pumpAndSettle();

      final updated = _controller.tasks.singleWhere(
        (item) => item.title == 'Checklist integrity',
      );
      final checklist = safeJsonMapList(updated.payload['checklist']);
      expect(checklist.single['is_done'], isFalse);
      expect(checklist.single['id'], 'step-1');
      expect(checklist.single['owner_note'], 'preserve me');
      expect(updated.kind, PlannerEntityKind.oneOffTask);
      expect(updated.dueAt?.toLocal().day, 30);
      final focus = safeJsonMap(updated.payload['focus']);
      expect(focus['mode'], 'countdown');
      expect(focus['minutes'], 45);
    },
  );

  testWidgets('habit target accepts a precise typed value', (tester) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Read precisely'),
          PlannerPayloadKeys.tracking: <String, dynamic>{
            'method': 'count',
            'goal': 'at_least',
            'target': 1,
            'unit': 'pages',
          },
        },
      ),
    );
    await tester.pump();
    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Read precisely',
    );
    await _setTestViewSize(tester, const Size(800, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: Scaffold(
          body: PlannerEditor(controller: _controller, existing: habit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openEditorStep(tester, 'define');
    await _keepEditorTargetClear(
      tester,
      find.widgetWithText(TextFormField, 'Goal or limit'),
      stepId: 'define',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Goal or limit'),
      '12.5',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('planner-editor-quick-save')),
    );
    await _pumpUntil(
      tester,
      () => _controller.habits
          .where((item) => item.title == 'Read precisely')
          .any((item) => item.tracking['target'] == 12.5),
    );
    await tester.pumpAndSettle();

    final updated = _controller.habits.singleWhere(
      (item) => item.title == 'Read precisely',
    );
    expect(updated.tracking['target'], 12.5);
    expect(updated.tracking['unit'], 'pages');
  });

  testWidgets(
    'editor preserves and extends multi-date monthly and yearly schedules',
    (tester) async {
      await _saveRecurring(
        tester: tester,
        title: 'Monthly closing',
        scheduledAt: _previewNow,
        recurrence: const <String, dynamic>{
          'rule': 'monthly',
          'month_days': <int>[1, 15],
          'last_day_of_month': true,
        },
      );
      await tester.pump();
      final monthly = _controller.tasks.singleWhere(
        (item) => item.title == 'Monthly closing',
      );
      await _setTestViewSize(tester, const Size(800, 900));
      await _pumpEditor(tester, monthly);

      await _openEditorStep(tester, 'frequency');
      await tester.ensureVisible(find.widgetWithText(FilterChip, '15'));
      await tester.pump();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '1'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '15'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Last'))
            .selected,
        isTrue,
      );
      await tester.tap(find.widgetWithText(FilterChip, '2'));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
      await _pumpUntil(
        tester,
        () => _controller.tasks
            .where((item) => item.title == 'Monthly closing')
            .any(
              (item) =>
                  ((item.recurrence[PlannerRecurrenceKeys.monthDays]
                          as Iterable?)
                      ?.map((value) => value.toString())
                      .contains('2') ??
                  false),
            ),
      );
      await tester.pumpAndSettle();

      final updatedMonthly = _controller.tasks.singleWhere(
        (item) => item.title == 'Monthly closing',
      );
      expect(updatedMonthly.recurrence[PlannerRecurrenceKeys.monthDays], <int>[
        1,
        2,
        15,
      ]);
      expect(
        updatedMonthly.recurrence[PlannerRecurrenceKeys.lastDayOfMonth],
        isTrue,
      );

      await _saveRecurring(
        tester: tester,
        title: 'Annual anchors',
        scheduledAt: _previewNow,
        recurrence: const <String, dynamic>{
          'rule': 'yearly',
          'annual_dates': <Map<String, int>>[
            <String, int>{'month': 2, 'day': 29},
            <String, int>{'month': 12, 'day': 31},
          ],
        },
      );
      await tester.pump();
      final yearly = _controller.tasks.singleWhere(
        (item) => item.title == 'Annual anchors',
      );
      expect(
        safeJsonMapList(yearly.recurrence[PlannerRecurrenceKeys.annualDates]),
        hasLength(2),
      );
      final yearlyRevision = yearly.revision;
      await _setTestViewSize(tester, const Size(800, 900));
      await _pumpEditor(tester, yearly);
      await _openEditorStep(tester, 'frequency');
      await tester.ensureVisible(find.text('Feb 29'));
      await tester.pump();
      expect(find.text('Feb 29'), findsOneWidget);
      expect(find.text('Dec 31'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
      await _pumpUntil(
        tester,
        () => _controller.tasks
            .where((item) => item.title == 'Annual anchors')
            .any((item) => item.revision > yearlyRevision),
      );
      await tester.pumpAndSettle();

      final updatedYearly = _controller.tasks.singleWhere(
        (item) => item.title == 'Annual anchors',
      );
      expect(
        safeJsonMapList(
          updatedYearly.recurrence[PlannerRecurrenceKeys.annualDates],
        ),
        <Map<String, dynamic>>[
          <String, dynamic>{'month': 2, 'day': 29},
          <String, dynamic>{'month': 12, 'day': 31},
        ],
      );
    },
  );

  testWidgets(
    'editor creates and edits a validated flexible weekly or monthly quota',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      await _pumpNewEditor(
        tester,
        initialKind: PlannerEntityKind.recurringTask,
      );
      await _openEditorStep(tester, 'define');
      await tester.enterText(
        find.byKey(const ValueKey<String>('planner-editor-title')),
        'Flexible strength',
      );
      await _openEditorStep(tester, 'frequency');

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Every week'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flexible goal · N times per period').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Completions per period'),
        '3',
      );
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Week'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Month').last);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This caps the total lifetime occurrences, not the quota inside each week or month.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
      await _pumpUntil(
        tester,
        () =>
            _controller.tasks.any((item) => item.title == 'Flexible strength'),
      );
      await tester.pumpAndSettle();

      final created = _controller.tasks.singleWhere(
        (item) => item.title == 'Flexible strength',
      );
      expect(created.recurrence[PlannerRecurrenceKeys.rule], 'flexible');
      expect(
        safeJsonMap(created.recurrence[PlannerRecurrenceKeys.frequency]),
        <String, dynamic>{'count': 3, 'period': 'month'},
      );

      await _pumpEditor(tester, created);
      await _openEditorStep(tester, 'frequency');
      expect(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Flexible goal · N times per period',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Completions per period'),
            )
            .controller
            ?.text,
        '3',
      );
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Month'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Completions per period'),
        '8',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Choose 1–7'), findsAtLeastNWidgets(1));
      expect(
        _controller.tasks
            .singleWhere((item) => item.title == 'Flexible strength')
            .revision,
        created.revision,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Completions per period'),
        '5',
      );
      final previousRevision = created.revision;
      await tester.tap(
        find.byKey(const ValueKey<String>('planner-editor-quick-save')),
      );
      await _pumpUntil(
        tester,
        () => _controller.tasks
            .where((item) => item.title == 'Flexible strength')
            .any((item) => item.revision > previousRevision),
      );
      await tester.pumpAndSettle();
      final edited = _controller.tasks.singleWhere(
        (item) => item.title == 'Flexible strength',
      );
      expect(
        safeJsonMap(edited.recurrence[PlannerRecurrenceKeys.frequency]),
        <String, dynamic>{'count': 5, 'period': 'week'},
      );
    },
  );

  testWidgets('recurring task stores and renders an exact 63 percent', (
    tester,
  ) async {
    await _saveRecurring(
      tester: tester,
      title: 'Measured recurring work',
      scheduledAt: _previewNow,
      recurrence: <String, dynamic>{
        'rule': 'weekly',
        'weekdays': <int>[_previewNow.weekday],
      },
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    final task = _controller.tasks.singleWhere(
      (item) => item.title == 'Measured recurring work',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${task.id}'));
    await _keepTodayTargetClear(tester, row);
    await tester.longPress(row);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set today’s percentage'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('perfect-progress-surface')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Progress today (%)'),
      '63',
    );
    await tester.tap(find.text('Save partial progress'));
    await _pumpUntil(tester, () => find.text('63%').evaluate().isNotEmpty);
    await tester.pumpAndSettle();

    final progress = await _controller.taskProgressForDay(
      task,
      localDay: _previewNow,
    );
    expect(progress.state, PlannerTaskProgressState.partial);
    expect(progress.percent, 63);
    expect(find.text('63%'), findsOneWidget);
  });

  testWidgets('boolean habit primary tap toggles today without a sheet', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Water plants',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
    await _keepTodayTargetClear(tester, row);
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Mark habit done')),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('100%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
      findsNothing,
    );
    expect((await _controller.habitDaySummary(habit)).isSuccessful, isTrue);

    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Mark habit pending')),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('0%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect((await _controller.habitDaySummary(habit)).isPending, isTrue);
  });

  testWidgets('boolean habit primary tap offers one undo after toggling', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Water plants',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
    await _keepTodayTargetClear(tester, row);
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Mark habit done')),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('100%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.text('Habit done'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('0%'))
          .evaluate()
          .isNotEmpty,
    );
    expect((await _controller.habitDaySummary(habit)).isPending, isTrue);
    expect(find.descendant(of: row, matching: find.text('0%')), findsOneWidget);
  });

  testWidgets('habit result can be corrected and reset from Today', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Water plants',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
    await _keepTodayTargetClear(tester, row);
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Mark habit done')),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('100%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect((await _controller.habitDaySummary(habit)).isSuccessful, isTrue);

    final correctedRow = find.byKey(
      ValueKey<String>('entity-context-${habit.id}'),
    );
    await _keepTodayTargetClear(tester, correctedRow);
    await tester.longPress(correctedRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log or correct today'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Edit today · Water plants'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note (optional)'),
      'Recovered gently',
    );
    await tester.tap(find.text('Update today'));
    await _pumpUntil(tester, () => find.text('100%').evaluate().isNotEmpty);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: correctedRow, matching: find.text('100%')),
      findsOneWidget,
    );

    final editedRow = find.byKey(
      ValueKey<String>('entity-context-${habit.id}'),
    );
    await _keepTodayTargetClear(tester, editedRow);
    await tester.longPress(editedRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log or correct today'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Note (optional)'),
          )
          .controller
          ?.text,
      'Recovered gently',
    );
    await tester.tap(find.text('Reset today to pending'));
    await _pumpUntil(tester, () => find.text('Pending').evaluate().isNotEmpty);
    await tester.pumpAndSettle();
    expect(find.text('Pending'), findsOneWidget);
    await tester.tap(find.byTooltip('Close habit log'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('entity-context-${habit.id}')),
        matching: find.text('0%'),
      ),
      findsOneWidget,
    );
    expect(
      (await _controller.habitDaySummary(_controller.habits.first)).isPending,
      isTrue,
    );
  });

  testWidgets('numeric habit primary tap adds its step without a sheet', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Drink measured water'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'numeric',
            'target': 8,
            'goal': 'at_least',
            'step': 2,
            'unit': 'glasses',
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    await _scrollTodayToText(tester, 'Drink measured water');
    final numericHabit = _controller.habits.singleWhere(
      (item) => item.title == 'Drink measured water',
    );
    final numericRow = find.byKey(
      ValueKey<String>('entity-context-${numericHabit.id}'),
    );
    await _keepTodayTargetClear(tester, numericRow);
    await tester.tap(
      find.descendant(
        of: numericRow,
        matching: find.byTooltip('Add 2 glasses'),
      ),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: numericRow, matching: find.text('25%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
      findsNothing,
    );
    expect(
      find.descendant(of: numericRow, matching: find.text('25%')),
      findsOneWidget,
    );
    expect((await _controller.habitDaySummary(numericHabit)).amount, 2);
    await _keepTodayTargetClear(tester, numericRow);
    await tester.longPress(numericRow);
    await tester.pumpAndSettle();
    expect(find.text('Subtract 2 glasses'), findsOneWidget);
    await tester.tap(find.text('Subtract 2 glasses'));
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: numericRow, matching: find.text('0%'))
          .evaluate()
          .isNotEmpty,
    );
    expect((await _controller.habitDaySummary(numericHabit)).amount, 0);
  });

  testWidgets('count primary label stays +1 with a custom correction step', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Count with correction step'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'count',
            'target': 8,
            'step': 3,
            'unit': 'glasses',
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await _scrollTodayToText(tester, 'Count with correction step');
    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Count with correction step',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
    await _keepTodayTargetClear(tester, row);
    expect(
      find.descendant(of: row, matching: find.byTooltip('Add one')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Add one')),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('13%'))
          .evaluate()
          .isNotEmpty,
    );
    expect((await _controller.habitDaySummary(habit)).amount, 1);
  });

  testWidgets('count habit primary tap adds one unit without a sheet', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Read measured pages'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'count',
            'target': 10,
            'goal': 'at_least',
            'unit': 'pages',
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    await _scrollTodayToText(tester, 'Read measured pages');
    final measuredHabit = _controller.habits.singleWhere(
      (item) => item.title == 'Read measured pages',
    );
    final measuredRow = find.byKey(
      ValueKey<String>('entity-context-${measuredHabit.id}'),
    );
    await _keepTodayTargetClear(tester, measuredRow);
    await tester.tap(
      find.descendant(of: measuredRow, matching: find.byTooltip('Add one')),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: measuredRow, matching: find.text('10%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
      findsNothing,
    );
    expect(
      find.descendant(of: measuredRow, matching: find.text('10%')),
      findsOneWidget,
    );
    final summary = await _controller.habitDaySummary(measuredHabit);
    expect(summary.amount, 1);
    expect(summary.state, PlannerHabitDayState.partial);
  });

  testWidgets(
    'checklist habit primary tap completes next item without a sheet',
    (tester) async {
      await _runControllerMutation(
        tester,
        () => _controller.saveEntity(
          kind: PlannerEntityKind.habit,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Morning checklist inline'),
            PlannerPayloadKeys.tracking: const <String, dynamic>{
              'method': 'checklist',
              'checklist': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'water', 'label': 'Water'},
                <String, dynamic>{'id': 'stretch', 'label': 'Stretch'},
              ],
            },
          },
        ),
      );
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester);
      await _scrollTodayToText(tester, 'Morning checklist inline');
      final habit = _controller.habits.singleWhere(
        (item) => item.title == 'Morning checklist inline',
      );
      final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
      await _keepTodayTargetClear(tester, row);
      await tester.tap(
        find.descendant(of: row, matching: find.byTooltip('Complete Water')),
      );
      await _pumpUntil(
        tester,
        () => find
            .descendant(of: row, matching: find.byTooltip('Complete Stretch'))
            .evaluate()
            .isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
        findsNothing,
      );
      expect(
        (await _controller.habitDaySummary(habit)).checkedItemIds,
        <String>{'water'},
      );
    },
  );

  testWidgets('duration habit primary tap adds one step without a sheet', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Meditate minutes'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'duration',
            'target': 30,
            'unit': 'minutes',
            'step': 10,
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await _scrollTodayToText(tester, 'Meditate minutes');
    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Meditate minutes',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
    await _keepTodayTargetClear(tester, row);
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Add 10 minutes')),
    );
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('33%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
      findsNothing,
    );
    expect(
      find.descendant(of: row, matching: find.text('33%')),
      findsOneWidget,
    );
    expect((await _controller.habitDaySummary(habit)).amount, 10);
  });

  testWidgets('count habit correction subtracts one from row actions', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Count measured steps'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'count',
            'target': 10,
            'goal': 'at_least',
            'unit': 'steps',
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await _scrollTodayToText(tester, 'Count measured steps');
    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Count measured steps',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
    await _keepTodayTargetClear(tester, row);
    final add = find.descendant(of: row, matching: find.byTooltip('Add one'));
    await tester.tap(add);
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('10%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.tap(add);
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('20%'))
          .evaluate()
          .isNotEmpty,
    );
    await _keepTodayTargetClear(tester, row);
    await tester.longPress(row);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subtract one'));
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: row, matching: find.text('10%'))
          .evaluate()
          .isNotEmpty,
    );
    expect((await _controller.habitDaySummary(habit)).amount, 1);
    expect(
      find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
      findsNothing,
    );
  });

  testWidgets(
    'count habit correction can set exact and reset without full log sheet',
    (tester) async {
      await _runControllerMutation(
        tester,
        () => _controller.saveEntity(
          kind: PlannerEntityKind.habit,
          payload: <String, dynamic>{
            ...defaultPlannerPayload(title: 'Count correction surface'),
            PlannerPayloadKeys.tracking: const <String, dynamic>{
              'method': 'count',
              'target': 10,
              'goal': 'at_least',
              'unit': 'steps',
            },
          },
        ),
      );
      await _setTestViewSize(tester, const Size(390, 844));
      await _pump(tester);
      await _scrollTodayToText(tester, 'Count correction surface');
      final habit = _controller.habits.singleWhere(
        (item) => item.title == 'Count correction surface',
      );
      final row = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
      await _keepTodayTargetClear(tester, row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set exact'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('habit-correction-dialog')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('habit-correction-value')),
        '7',
      );
      await tester.tap(find.text('Save exact'));
      await _pumpUntil(
        tester,
        () => find
            .descendant(of: row, matching: find.text('70%'))
            .evaluate()
            .isNotEmpty,
      );
      expect((await _controller.habitDaySummary(habit)).amount, 7);
      expect(
        find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
        findsNothing,
      );

      await _keepTodayTargetClear(tester, row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset today'));
      await _pumpUntil(
        tester,
        () => find
            .descendant(of: row, matching: find.text('0%'))
            .evaluate()
            .isNotEmpty,
      );
      expect((await _controller.habitDaySummary(habit)).isPending, isTrue);
    },
  );

  testWidgets('measured habit edits one daily total from partial to complete', (
    tester,
  ) async {
    await _runControllerMutation(
      tester,
      () => _controller.saveEntity(
        kind: PlannerEntityKind.habit,
        payload: <String, dynamic>{
          ...defaultPlannerPayload(title: 'Read measured pages'),
          PlannerPayloadKeys.tracking: const <String, dynamic>{
            'method': 'count',
            'target': 10,
            'goal': 'at_least',
            'unit': 'pages',
          },
        },
      ),
    );
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    await _scrollTodayToText(tester, 'Read measured pages');
    final measuredHabit = _controller.habits.singleWhere(
      (item) => item.title == 'Read measured pages',
    );
    final measuredRow = find.byKey(
      ValueKey<String>('entity-context-${measuredHabit.id}'),
    );
    await _keepTodayTargetClear(tester, measuredRow);
    await tester.longPress(measuredRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log or correct today'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Measured total'),
      '2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note (optional)'),
      'First two',
    );
    await tester.tap(find.text('Save today'));
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: measuredRow, matching: find.text('20%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: measuredRow, matching: find.text('20%')),
      findsOneWidget,
    );
    await _scrollTodayToText(tester, 'Read measured pages');
    await tester.pumpAndSettle();

    await _keepTodayTargetClear(tester, measuredRow);
    await tester.longPress(measuredRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log or correct today'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Measured total'),
          )
          .controller
          ?.text,
      '2',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Note (optional)'),
          )
          .controller
          ?.text,
      'First two',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Measured total'),
      '12',
    );
    await tester.tap(find.text('Update today'));
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: measuredRow, matching: find.text('100%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: measuredRow, matching: find.text('100%')),
      findsOneWidget,
    );
    final summary = await _controller.habitDaySummary(
      _controller.habits.singleWhere(
        (habit) => habit.title == 'Read measured pages',
      ),
    );
    expect(summary.isSuccessful, isTrue);
    expect(summary.amount, 12);
  });

  testWidgets('checklist habit is created with stable items and logged', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    await _pumpNewEditor(tester, initialKind: PlannerEntityKind.habit);
    await _openEditorStep(tester, 'evaluate');
    await tester.tap(
      find.byKey(const ValueKey<String>('habit-evaluation-checklist')),
    );
    await tester.pumpAndSettle();
    await _openEditorStep(tester, 'define');
    await tester.enterText(
      find.byKey(const ValueKey<String>('planner-editor-title')),
      'Morning checklist',
    );

    await _keepEditorTargetClear(
      tester,
      find.widgetWithText(TextFormField, 'Checklist item'),
      stepId: 'define',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Checklist item'),
      'Water',
    );
    await tester.tap(find.byTooltip('Add habit checklist item'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Checklist item'),
      'Stretch',
    );
    await tester.tap(find.byTooltip('Add habit checklist item'));
    await tester.pump();
    final requiredChip = find.widgetWithText(FilterChip, 'Required').last;
    await _keepEditorTargetClear(tester, requiredChip, stepId: 'define');
    await tester.tap(requiredChip);
    final editStretch = find.byTooltip('Edit Stretch');
    await _keepEditorTargetClear(tester, editStretch, stepId: 'define');
    await tester.tap(editStretch);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Label'),
      'Movement',
    );
    await tester.tap(find.text('Save label'));
    await tester.pumpAndSettle();
    await _keepEditorTargetClear(
      tester,
      find.widgetWithText(
        DropdownButtonFormField<String>,
        'Complete all required',
      ),
      stepId: 'define',
    );
    await tester.tap(
      find.widgetWithText(
        DropdownButtonFormField<String>,
        'Complete all required',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete at least a count').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Required completed items'),
      '1',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('planner-editor-quick-save')),
    );
    await _pumpUntil(
      tester,
      () => _controller.habits.any((item) => item.title == 'Morning checklist'),
    );
    await tester.pumpAndSettle();

    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Morning checklist',
    );
    final tracking = habit.tracking;
    final items = safeJsonMapList(tracking[PlannerHabitTrackingKeys.checklist]);
    expect(items, hasLength(2));
    expect(items.map((item) => item['id']).toSet(), hasLength(2));
    expect(items.every((item) => '${item['id']}'.isNotEmpty), isTrue);
    expect(
      items.map((item) => item['label']),
      containsAll(<String>['Water', 'Movement']),
    );
    expect(
      items.singleWhere((item) => item['label'] == 'Movement')['required'],
      isFalse,
    );
    expect(
      safeJsonMap(tracking[PlannerHabitTrackingKeys.successCondition]),
      <String, dynamic>{'type': 'count', 'value': 1},
    );

    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await _scrollTodayToText(tester, 'Morning checklist');
    final checklistRow = find.byKey(
      ValueKey<String>('entity-context-${habit.id}'),
    );
    await _keepTodayTargetClear(tester, checklistRow);
    await tester.longPress(checklistRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log or correct today'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Water'));
    await tester.tap(find.text('Save today'));
    await _pumpUntil(
      tester,
      () => find
          .descendant(of: checklistRow, matching: find.text('100%'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: checklistRow, matching: find.text('100%')),
      findsOneWidget,
    );
    final summary = await _controller.habitDaySummary(habit);
    expect(summary.isSuccessful, isTrue);
    expect(summary.checkedCount, 1);
  });

  testWidgets('habit log uses a bounded dialog on Windows-sized layouts', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(1280, 800));
    await _pump(tester);
    final habit = _controller.habits.singleWhere(
      (item) => item.title == 'Water plants',
    );
    final habitRow = find.byKey(ValueKey<String>('entity-context-${habit.id}'));
    await _keepTodayTargetClear(tester, habitRow);
    await tester.longPress(habitRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log or correct today'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byTooltip('Close habit log'));
    await tester.pumpAndSettle();

    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await _keepTodayTargetClear(tester, habitRow);
    await tester.longPress(habitRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log or correct today'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('footer and rail support local arrow Home and End navigation', (
    tester,
  ) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('today'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );

    await _setTestViewSize(tester, const Size(900, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Today (Ctrl+1)').first);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop shortcuts navigate, preserve quick capture focus, and dismiss local context',
    (tester) async {
      await _setTestViewSize(tester, const Size(1280, 800));
      await _pump(tester);

      for (var index = 1; index < 5; index++) {
        await _sendControlShortcut(
          tester,
          <LogicalKeyboardKey>[
            LogicalKeyboardKey.digit1,
            LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3,
            LogicalKeyboardKey.digit4,
            LogicalKeyboardKey.digit5,
          ][index],
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationRail>(find.byType(NavigationRail))
              .selectedIndex,
          index,
        );
      }
      await _sendControlShortcut(tester, LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      await _sendControlShortcut(tester, LogicalKeyboardKey.keyK);
      await tester.pump();
      var quickCapture = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
      );
      expect(quickCapture.focusNode?.hasFocus, isTrue);
      await tester.enterText(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
        'Keep me through resize',
      );

      await _setTestViewSize(tester, const Size(800, 800));
      await tester.pumpAndSettle();
      quickCapture = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
      );
      expect(quickCapture.controller?.text, 'Keep me through resize');
      expect(quickCapture.focusNode?.hasFocus, isTrue);

      await _setTestViewSize(tester, const Size(1280, 800));
      await tester.pumpAndSettle();
      await _sendControlShortcut(tester, LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();
      expect(find.text('Make it yours'), findsOneWidget);
      await tester.tap(find.byTooltip('Close editor'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      quickCapture = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('perfect_quick_capture')),
      );
      expect(quickCapture.focusNode?.hasFocus, isTrue);

      await _sendControlShortcut(tester, LogicalKeyboardKey.keyF, shift: true);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Focus'), findsNothing);

      final task = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );
      await tester.tap(
        find.byKey(ValueKey<String>('entity-context-${task.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inspector'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Inspector'), findsNothing);

      await tester.tap(
        find.byKey(ValueKey<String>('entity-context-${task.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inspector'), findsOneWidget);
      await _sendControlShortcut(tester, LogicalKeyboardKey.digit4);
      await tester.pumpAndSettle();
      expect(find.text('Inspector'), findsNothing);
    },
  );

  testWidgets('Windows header omits the retired overflow command menu', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await _pump(tester);

    expect(find.byTooltip('Account and commands'), findsNothing);
    expect(find.text('Keyboard shortcuts'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsWidgets);
  });

  testWidgets(
    'desktop context menu is mouse and keyboard reachable with named archive confirmation',
    (tester) async {
      await _setTestViewSize(tester, const Size(1280, 800));
      await _pump(tester);
      final source = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );

      await _secondaryTap(
        tester,
        find.byKey(ValueKey<String>('entity-context-${source.id}')),
      );
      expect(find.text('Open details'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Start focus'), findsOneWidget);
      expect(find.text('Move to tomorrow'), findsOneWidget);
      expect(find.text('Archive…'), findsOneWidget);

      await tester.tap(find.text('Archive…'));
      await tester.pumpAndSettle();
      expect(find.text('Archive “Focus Deep Work”?'), findsOneWidget);
      expect(
        _controller.tasks.any((item) => item.title == 'Focus Deep Work'),
        isTrue,
      );
      await tester.tap(find.text('Keep item'));
      await tester.pumpAndSettle();
      expect(
        _controller.tasks.any((item) => item.title == 'Focus Deep Work'),
        isTrue,
      );

      await _sendShiftF10(tester);
      await tester.pumpAndSettle();
      expect(find.text('Archive…'), findsOneWidget);
      await tester.tap(find.text('Archive…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive item'));
      await _pumpUntil(
        tester,
        () => !_controller.tasks.any((item) => item.title == 'Focus Deep Work'),
      );
      await tester.pumpAndSettle();
      expect(
        _controller.tasks.any((item) => item.title == 'Focus Deep Work'),
        isFalse,
      );
    },
  );

  testWidgets(
    'desktop right-click exposes recurring controls in a bounded dialog',
    (tester) async {
      await _saveRecurring(
        tester: tester,
        title: 'Weekly progress review',
        scheduledAt: _previewNow,
        recurrence: const <String, dynamic>{'rule': 'daily'},
      );
      await _setTestViewSize(tester, const Size(1280, 800));
      await _pump(tester);
      await _sendControlShortcut(tester, LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('refine-status-Scheduled')),
      );
      await tester.pumpAndSettle();
      final recurring = _controller.tasks.singleWhere(
        (item) => item.title == 'Weekly progress review',
      );
      await tester.scrollUntilVisible(
        find.text('Weekly progress review'),
        220,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey<String>('perfect-tasks-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await _secondaryTap(
        tester,
        find.byKey(ValueKey<String>('entity-context-${recurring.id}')),
      );
      expect(find.text('Set today’s percentage'), findsOneWidget);
      expect(find.text('Mark miss today'), findsOneWidget);
      await tester.tap(find.text('Set today’s percentage'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Set today’s progress'), findsOneWidget);
      await tester.tap(find.byTooltip('Close progress editor'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    },
  );

  testWidgets('tracer 20: saved-view switcher applies built-in views', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('tasks'));
    await tester.pumpAndSettle();
    // Default active view is Open: its chip is selected, Focus Deep Work
    // (an active scheduled task) is visible.
    final openChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey<String>('saved-view-builtin:open')),
    );
    expect(openChip.selected, isTrue);
    expect(find.text('Focus Deep Work'), findsOneWidget);

    // Switch to Completed: the shared projection must resolve the completed
    // view — Focus Deep Work disappears and the empty state appears.
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('saved-view-builtin:completed')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('saved-view-builtin:completed')),
    );
    await tester.pumpAndSettle();
    final completedChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey<String>('saved-view-builtin:completed')),
    );
    expect(completedChip.selected, isTrue);
    expect(find.text('Focus Deep Work'), findsNothing);
    expect(find.text('No completed tasks yet.'), findsOneWidget);

    // Switch back to Open through the same switcher: the deck restores.
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('saved-view-builtin:open')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('saved-view-builtin:open')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);

    // A saved view is a complete query definition, not just a lifecycle tab.
    // Narrow the live query, then select Open again; search/kind scope must
    // reset to the saved definition and restore the task row.
    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Find a task, note, or category…',
    );
    await tester.enterText(search, 'does-not-match');
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('saved-view-builtin:open')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(find.text('Focus Deep Work'), findsOneWidget);

    // Refine lifecycle changes must move the selected built-in view as well.
    await tester.tap(find.byKey(const ValueKey<String>('task-filter-toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('refine-status-Inbox')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('refine-status-Inbox')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('saved-view-builtin:inbox')),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('tracer 21: active saved view persists across page rebuild', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('tasks'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('saved-view-builtin:completed')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('saved-view-builtin:completed')),
    );
    await tester.pumpAndSettle();
    expect(find.text('No completed tasks yet.'), findsOneWidget);

    // Unmount the workspace. A new page state must load the stored view ID.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester);
    await tester.tap(_footerDestination('tasks'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('saved-view-builtin:completed')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Focus Deep Work'), findsNothing);
  });

  testWidgets('tracer 19: GROUP chips render shared group sections', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);
    expect(find.text('None'), findsNothing);

    await tester.tap(find.text('Open · All · Due date'));
    await tester.pumpAndSettle();
    expect(find.text('None'), findsWidgets);
    expect(find.text('Schedule'), findsWidgets);

    // GROUP chips sit below the fold in the collapsible filter deck: bring
    // the Schedule chip into view before tapping (same pattern as the
    // recurring-controls test), otherwise the tap misses off-screen.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Schedule'));
    await tester.pumpAndSettle();
    // Schedule must be the selected GROUP chip after the tap settles.
    final scheduleChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Schedule'),
    );
    expect(scheduleChip.selected, isTrue);
    // Schedule groups by UTC calendar-day key (e.g. 2026-07-27), with
    // unscheduled rows under `Unassigned` — the header comes from the same
    // shared query projection, not a second predicate. Focus Deep Work is
    // scheduled at the frozen preview time, so the selected Schedule chip
    // and the shared group section must both appear.
    expect(find.text('Open · All · Due date · Schedule'), findsOneWidget);
    expect(find.text('Focus Deep Work'), findsOneWidget);
  });

  testWidgets('tracer 22: group header collapses and restores its section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(_footerDestination('tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);

    // Group by Schedule through the deck (chip sits below the fold).
    await tester.tap(find.text('Open · All · Due date'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);

    // The group header is a button: collapsing hides its rows, the header
    // stays and announces the collapsed state; expanding brings rows back.
    final header = find.byKey(const ValueKey<String>('task-group-header'));
    expect(header, findsWidgets);
    await tester.tap(header.first);
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsNothing);
    // Semantics announce collapse so screen-reader users get the state.
    final headerSemantics = tester.getSemantics(header.first);
    expect(headerSemantics.flagsCollection.isExpanded.toBoolOrNull(), isFalse);

    await tester.tap(header.first);
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);
    final expandedSemantics = tester.getSemantics(header.first);
    expect(expandedSemantics.flagsCollection.isExpanded.toBoolOrNull(), isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  PerfectWorkspaceNavigationController? navigationController,
  PerfectAiClient? aiClient,
  ReadyFeedbackController? feedbackController,
  TextScaler? textScaler,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  TargetPlatform? platform,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light().copyWith(platform: platform),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        var mediaQueryData = mediaQuery.copyWith(
          disableAnimations: disableAnimations,
        );
        if (textScaler != null) {
          mediaQueryData = mediaQueryData.copyWith(textScaler: textScaler);
        }
        return MediaQuery(
          data: mediaQueryData,
          child: Directionality(
            textDirection: textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: PerfectWorkspacePage(
        controller: _controller,
        themeMode: ThemeMode.light,
        onThemeModeChanged: (_) {},
        onSignOut: () async {},
        now: () => _previewNow,
        navigationController: navigationController,
        aiClient: aiClient,
        feedbackController: feedbackController,
        aiVoiceRecorder: aiClient == null ? null : _WorkspaceVoiceRecorder(),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/brand/perfect-launcher.png'),
      tester.element(find.byType(PerfectWorkspacePage)),
    ),
  );
  await tester.pumpAndSettle();
}

class _ThemeContrastHarness extends StatefulWidget {
  const _ThemeContrastHarness({super.key, required this.controller});

  final PlannerWorkspaceController controller;

  @override
  State<_ThemeContrastHarness> createState() => _ThemeContrastHarnessState();
}

class _ThemeContrastHarnessState extends State<_ThemeContrastHarness> {
  ThemeMode _themeMode = ThemeMode.light;
  PerfectContrastMode _contrastMode = PerfectContrastMode.system;

  void setTheme(ThemeMode value) => setState(() => _themeMode = value);

  void setContrast(PerfectContrastMode value) =>
      setState(() => _contrastMode = value);

  @override
  Widget build(BuildContext context) {
    final forceClarity = _contrastMode == PerfectContrastMode.high;
    return MaterialApp(
      theme: forceClarity
          ? PerfectTheme.highContrastLight()
          : PerfectTheme.light(),
      darkTheme: forceClarity
          ? PerfectTheme.highContrastDark()
          : PerfectTheme.dark(),
      highContrastTheme: PerfectTheme.highContrastLight(),
      highContrastDarkTheme: PerfectTheme.highContrastDark(),
      themeMode: _themeMode,
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
      home: PerfectWorkspacePage(
        controller: widget.controller,
        themeMode: _themeMode,
        contrastMode: _contrastMode,
        onThemeModeChanged: setTheme,
        onContrastModeChanged: setContrast,
        onSignOut: () async {},
        now: () => _previewNow,
      ),
    );
  }
}

class _WorkspaceFeedbackRepository extends ReadyFeedbackRepository {
  _WorkspaceFeedbackRepository({required super.config});

  final List<ReadyFeedbackEntry> _entries = <ReadyFeedbackEntry>[];

  @override
  Future<List<ReadyFeedbackEntry>> readEntries() async =>
      List<ReadyFeedbackEntry>.unmodifiable(_entries);

  @override
  Future<ReadyFeedbackEntry> addEntry(
    ReadyFeedbackEntry entry, {
    ReadyFeedbackScreenshotCapture? screenshot,
    Uint8List? screenshotBytes,
  }) async {
    _entries.add(entry);
    return entry;
  }

  @override
  Future<void> appendLog(ReadyFeedbackLogRecord record) async {}
}

class _WorkspaceAiClient implements PerfectAiClient {
  @override
  Future<PerfectAiApplyResult> applyProposal({
    required String operationId,
    required String? conversationId,
    required PerfectAiProposal proposal,
    PerfectAiCancellation? cancellation,
  }) => throw UnimplementedError();

  @override
  Future<PerfectAiTurnResult> chat(
    PerfectAiRequest request, {
    PerfectAiCancellation? cancellation,
  }) => throw UnimplementedError();
}

class _WorkspaceVoiceRecorder implements PerfectVoiceRecorder {
  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start() async {}

  @override
  Future<PerfectVoiceClip?> stop() async => null;
}

Finder _cardContaining(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Card)).first;

Future<void> _keepTodayTargetClear(
  WidgetTester tester,
  Finder target, {
  double clearance = 16,
}) async {
  final list = find.byKey(const PageStorageKey<String>('perfect-today-scroll'));
  if (list.evaluate().isNotEmpty) {
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(target, 220, scrollable: scrollable);
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
  final targetRect = tester.getRect(target);
  final dockRect = tester.getRect(
    find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
  );
  final coveredBy = targetRect.bottom - (dockRect.top - clearance);
  if (coveredBy <= 0) return;
  await tester.drag(list, Offset(0, -(coveredBy + clearance)));
  await tester.pumpAndSettle();
}

Future<void> _scrollTodayToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    220,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey<String>('perfect-today-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openEditorStep(WidgetTester tester, String stepId) async {
  final stage = find.byKey(ValueKey<String>('planner-editor-$stepId'));
  if (stage.evaluate().isNotEmpty) return;

  final railTarget = find.byKey(ValueKey<String>('planner-step-$stepId'));
  if (railTarget.evaluate().isNotEmpty) {
    await tester.ensureVisible(railTarget);
    await tester.tap(railTarget);
    await tester.pumpAndSettle();
    expect(stage, findsOneWidget);
    return;
  }

  for (var guard = 0; guard < 8; guard++) {
    if (stage.evaluate().isNotEmpty) return;
    final next = find.byKey(const ValueKey<String>('planner-editor-next'));
    expect(
      next,
      findsOneWidget,
      reason: 'Wizard could not reach the $stepId step.',
    );
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
  expect(stage, findsOneWidget);
}

void _expectWizardStageQuality(
  WidgetTester tester,
  String stepId,
  String title,
  Size viewport,
) {
  final stage = find.byKey(ValueKey<String>('planner-editor-$stepId'));
  final action = find.byKey(
    ValueKey<String>(
      stepId == 'review' ? 'planner-editor-save' : 'planner-editor-next',
    ),
  );
  final stageRect = tester.getRect(stage);
  final actionRect = tester.getRect(action);
  expect(stageRect.left, greaterThanOrEqualTo(0));
  expect(stageRect.right, lessThanOrEqualTo(viewport.width));
  expect(stageRect.top, greaterThanOrEqualTo(0));
  expect(stageRect.bottom, lessThanOrEqualTo(actionRect.top));
  expect(actionRect.left, greaterThanOrEqualTo(0));
  expect(actionRect.right, lessThanOrEqualTo(viewport.width));
  expect(actionRect.bottom, lessThanOrEqualTo(viewport.height));
  expect(actionRect.height, greaterThanOrEqualTo(48));

  final titleFinder = find.text(title);
  expect(titleFinder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(titleFinder);
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: '$stepId primary heading must wrap rather than truncate.',
  );
}

Finder _editorScrollable(String stepId) => find
    .descendant(
      of: find.byKey(ValueKey<String>('planner-editor-$stepId')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _keepEditorTargetClear(
  WidgetTester tester,
  Finder target, {
  required String stepId,
  double clearance = 24,
}) async {
  await tester.ensureVisible(target);
  await tester.pump();
  final viewport = tester.getRect(
    find.byKey(ValueKey<String>('planner-editor-$stepId')),
  );
  final targetRect = tester.getRect(target);
  final desiredTop = viewport.top + clearance;
  final offsetFromSafeTop = targetRect.top - desiredTop;
  if (offsetFromSafeTop.abs() > 1) {
    await tester.drag(_editorScrollable(stepId), Offset(0, -offsetFromSafeTop));
    await tester.pumpAndSettle();
  }
  final adjustedTargetRect = tester.getRect(target);
  final coveredBy = adjustedTargetRect.bottom - (viewport.bottom - clearance);
  if (coveredBy <= 0) return;
  await tester.drag(
    _editorScrollable(stepId),
    Offset(0, -(coveredBy + clearance)),
  );
  await tester.pumpAndSettle();
}

Future<void> _setTestViewSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(null);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyEvent(key);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

Future<void> _sendShiftF10(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.f10);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
}

Future<void> _secondaryTap(WidgetTester tester, Finder finder) async {
  final gesture = await tester.startGesture(
    tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _pumpEditor(WidgetTester tester, PlannerEntity entity) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
      home: Scaffold(
        body: PlannerEditor(
          key: ValueKey<String>('editor-${entity.id}'),
          controller: _controller,
          existing: entity,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _footerDestination(String destination) =>
    find.byKey(ValueKey<String>('perfect-footer-$destination'));

Future<void> _pumpNewEditor(
  WidgetTester tester, {
  required PlannerEntityKind initialKind,
  TextScaler? textScaler,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
      builder: (context, child) {
        var media = MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations);
        if (textScaler != null) {
          media = media.copyWith(textScaler: textScaler);
        }
        return MediaQuery(
          data: media,
          child: Directionality(
            textDirection: textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: Scaffold(
        body: PlannerEditor(controller: _controller, initialKind: initialKind),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _runControllerMutation(
  WidgetTester tester,
  Future<void> Function() mutation,
) async {
  await tester.runAsync(() async {
    await mutation();
    await _controller.refresh();
  });
}

Future<void> _saveRecurring({
  required WidgetTester tester,
  required String title,
  required DateTime scheduledAt,
  required Map<String, dynamic> recurrence,
}) async {
  await tester.runAsync(() async {
    await _controller.saveEntity(
      kind: PlannerEntityKind.recurringTask,
      payload: <String, dynamic>{
        ...defaultPlannerPayload(title: title),
        PlannerPayloadKeys.timing: <String, dynamic>{
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        },
        PlannerPayloadKeys.recurrence: recurrence,
      },
    );
    await _controller.refresh();
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  int maxPumps = 300,
}) async {
  for (var index = 0; index < maxPumps; index++) {
    if (predicate()) {
      for (var drain = 0; drain < 20; drain++) {
        await tester.pump(const Duration(milliseconds: 10));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      return;
    }
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  fail('Timed out waiting for the local UI mutation to settle.');
}

class _ProjectionFailureController extends PlannerWorkspaceController {
  _ProjectionFailureController(
    super.localStore,
    super.syncRepository, {
    required super.ownerId,
    super.now,
  });

  bool failTaskReads = false;
  bool failLocalWatch = false;
  bool failQuickCapture = false;

  @override
  Future<PlannerMutationReceipt> quickCapture(String title) {
    if (failQuickCapture) {
      return Future<PlannerMutationReceipt>.error(
        StateError('injected quick-save failure'),
      );
    }
    return super.quickCapture(title);
  }

  Future<void>? eligibilityGate;
  int suspendedEligibilityReads = 0;
  int foreignOutcomeReads = 0;
  int outcomeReads = 0;
  int failedReads = 0;
  int _invalidations = 0;

  void failLocalWatchOnce() => failLocalWatch = true;

  void allowLocalWatch() => failLocalWatch = false;

  @override
  Future<PlannerTodayEligibility> todayEligibilityForDay(
    PlannerEntity entity, {
    DateTime? localDay,
  }) async {
    if (failLocalWatch) {
      failedReads++;
      throw StateError('injected local read failure');
    }
    final result = await super.todayEligibilityForDay(
      entity,
      localDay: localDay,
    );
    final gate = eligibilityGate;
    if (gate != null) {
      suspendedEligibilityReads++;
      await gate;
    }
    return result;
  }

  @override
  int get todayProjectionRevision =>
      super.todayProjectionRevision + _invalidations;

  void invalidateProjection() {
    _invalidations++;
    notifyListeners();
  }

  @override
  Future<PlannerHabitDaySummary> habitDaySummary(
    PlannerEntity habit, {
    DateTime? localDay,
  }) {
    outcomeReads++;
    if (habit.ownerId != ownerId) foreignOutcomeReads++;
    return super.habitDaySummary(habit, localDay: localDay);
  }

  @override
  Future<PlannerTaskProgress> taskProgressForDay(
    PlannerEntity entity, {
    DateTime? localDay,
  }) async {
    outcomeReads++;
    if (entity.ownerId != ownerId) foreignOutcomeReads++;
    if (failTaskReads) {
      failedReads++;
      throw StateError('injected private read failure');
    }
    return super.taskProgressForDay(entity, localDay: localDay);
  }
}

class _PreviewGateway implements PlannerRemoteGateway {
  final Map<String, Map<String, dynamic>> _payloads =
      <String, Map<String, dynamic>>{};

  @override
  Future<PlannerRemoteMutationResult> apply(
    PlannerRemoteMutation mutation,
  ) async {
    final payload = _mergePreviewPayload(
      _payloads[mutation.entityId] ?? const <String, dynamic>{},
      safeJsonMap(mutation.patch['payload']),
    );
    final explicitTitle = mutation.patch['title']?.toString().trim();
    if (explicitTitle != null && explicitTitle.isNotEmpty) {
      payload[PlannerPayloadKeys.title] = explicitTitle;
    }
    _payloads[mutation.entityId] = payload;
    return PlannerRemoteMutationResult.fromJson(<String, dynamic>{
      'status': 'acknowledged',
      'entity': <String, dynamic>{
        'id': mutation.entityId,
        'owner_id': 'preview-owner',
        'kind': mutation.entityKind,
        'title': safeJsonString(
          payload[PlannerPayloadKeys.title],
          fallback: 'Preview',
        ),
        'lifecycle_state': mutation.operationType == 'soft_delete'
            ? 'archived'
            : mutation.patch['lifecycle_state']?.toString() ?? 'active',
        'payload': payload,
        'revision': mutation.baseRevision + 1,
        'created_at': _previewNow.toUtc().toIso8601String(),
        'updated_at': _previewNow.toUtc().toIso8601String(),
        'deleted_at': mutation.operationType == 'soft_delete'
            ? _previewNow.toUtc().toIso8601String()
            : null,
      },
    });
  }

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

Map<String, dynamic> _mergePreviewPayload(
  Map<String, dynamic> previous,
  Map<String, dynamic> patch,
) {
  final merged = <String, dynamic>{...previous};
  for (final entry in patch.entries) {
    final oldValue = merged[entry.key];
    final newValue = entry.value;
    merged[entry.key] = oldValue is Map && newValue is Map
        ? _mergePreviewPayload(safeJsonMap(oldValue), safeJsonMap(newValue))
        : newValue;
  }
  return merged;
}
