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
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_workspace_page.dart';
import 'package:perfect/presentation/planner_editor.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
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
    _controller = PlannerWorkspaceController(
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
    'compact Orbit Day keeps navigation and quick capture reachable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, freezeOrbitMotion: true);

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
    'compact AI toggle lives inside quick capture and opens above it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(
        tester,
        aiClient: _WorkspaceAiClient(),
        freezeOrbitMotion: true,
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
    'compact footer replaces the stock oval with one prismatic tile',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, freezeOrbitMotion: true);

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
      expect(heading.top - glassHeader.bottom, lessThan(24));
      expect(
        find.byKey(const ValueKey<String>('perfect-live-clock')),
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
      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      final orbit = tester.getRect(
        find.byKey(const ValueKey<String>('orbit-circular-stage')),
      );
      final signal = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-signal-zone')),
      );
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      final aiToggle = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-toggle')),
      );
      expect(compass.top, closeTo(stream.top, 1));
      expect(compass.bottom, lessThan(stream.bottom));
      expect(compass.right, lessThan(stream.left));
      expect(compass.height, greaterThan(500));
      expect(compass.height, lessThanOrEqualTo(compass.width + 170));
      expect(compass.contains(orbit.center), isTrue);
      expect(orbit.width, greaterThan(300));
      expect(orbit.height, greaterThan(300));
      expect(
        (orbit.center.dx - compass.center.dx).abs(),
        lessThanOrEqualTo(24),
      );
      expect(stream.bottom - signal.bottom, lessThanOrEqualTo(20));
      expect(signal.height, greaterThan(180));
      expect(capture.contains(aiToggle.center), isTrue);
      expect(compass.bottom, lessThanOrEqualTo(capture.top));
      await _pump(tester, aiClient: aiClient, freezeOrbitMotion: true);
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
      final expandedCompass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final expandedStream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(expandedCompass.bottom, lessThanOrEqualTo(expandedStream.top));
      expect(expandedCompass.left, closeTo(expandedStream.left, 1));
      expect(expandedCompass.right, closeTo(expandedStream.right, 1));
      expect(expandedCompass.width, greaterThan(500));
      expect(expandedCompass.height, greaterThan(expandedCompass.width * 0.68));
      expect(tester.takeException(), isNull);
      await _pump(tester, aiClient: aiClient, freezeOrbitMotion: true);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_tablet_rail_expanded.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'medium Day Deck uses content-driven reflow at 768 800 900 and 1024dp',
    (tester) async {
      Future<(Rect, Rect)> layoutAt(double width) async {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        await _pump(tester);
        expect(tester.takeException(), isNull);
        return (
          tester.getRect(
            find.byKey(const ValueKey<String>('day-compass-panel')),
          ),
          tester.getRect(
            find.byKey(const ValueKey<String>('day-stream-panel')),
          ),
        );
      }

      final narrow = await layoutAt(768);
      expect(narrow.$1.bottom, lessThan(narrow.$2.top));

      final portraitTablet = await layoutAt(800);
      expect(portraitTablet.$1.bottom, lessThan(portraitTablet.$2.top));
      expect(portraitTablet.$1.height, lessThan(560));

      final standard = await layoutAt(900);
      expect(standard.$1.right, lessThan(standard.$2.left));
      expect(standard.$1.height, greaterThan(500));

      final roomy = await layoutAt(1024);
      expect(roomy.$1.right, lessThan(roomy.$2.left));
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
        find.text('All open work first. Narrow only when you need to.'),
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
        find.text('All open work first. Narrow only when you need to.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android tablet landscape keeps the Day Deck and shell continuously usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await _pump(
        tester,
        aiClient: _WorkspaceAiClient(),
        freezeOrbitMotion: true,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-quick-capture-toggle')),
      );
      await tester.pumpAndSettle();

      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
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

      expect(compass.right, lessThan(stream.left));
      expect(compass.top, closeTo(stream.top, 1));
      expect(compass.bottom, closeTo(stream.bottom, 1));
      expect(compass.height, greaterThan(450));
      expect(compass.bottom, lessThanOrEqualTo(capture.top));
      expect(capture.contains(aiToggle.center), isTrue);
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
    'tablet Day Deck at 200 percent text becomes one readable column',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      await _pump(tester, textScaler: const TextScaler.linear(2));

      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(compass.bottom, lessThan(stream.top));
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
        find.text('All open work first. Narrow only when you need to.'),
        findsOneWidget,
      );
      expect(find.text('Open · All'), findsOneWidget);
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
          of: find.byKey(const ValueKey<String>('perfect-today-scroll')),
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
          of: find.byKey(const ValueKey<String>('perfect-today-scroll')),
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
      of: find.byKey(const ValueKey<String>('perfect-today-scroll')),
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
    'expanded Windows Day Deck keeps the compass and stream adjacent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      await _pump(
        tester,
        freezeOrbitMotion: true,
        platform: TargetPlatform.windows,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Inspector'), findsNothing);
      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(compass.right, lessThan(stream.left));
      expect(compass.top, closeTo(stream.top, 1));
      expect(compass.bottom, closeTo(stream.bottom, 1));
      expect(compass.height, greaterThanOrEqualTo(420));
      expect(find.text('Focus Deep Work'), findsWidgets);
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
      final focusPanel = tester.getRect(
        find.byKey(const ValueKey<String>('expanded-focus-panel')),
      );
      expect(focusPanel.top, closeTo(stage.top, 1));
      expect(focusPanel.bottom, closeTo(stage.bottom, 1));
      expect(focusPanel.right, closeTo(stage.right, 1));
      expect(
        find.bySemanticsLabel('Close inspector and return to Today'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_expanded.png'),
      );
      await tester.tapAt(Offset(stage.left + 12, stage.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Inspector'), findsNothing);
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'wide Windows Day Deck promotes selected detail to a true third pane',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await _pump(
        tester,
        freezeOrbitMotion: true,
        platform: TargetPlatform.windows,
      );
      final source = _controller.tasks.singleWhere(
        (item) => item.title == 'Focus Deep Work',
      );

      await tester.tap(
        find.byKey(ValueKey<String>('entity-context-${source.id}')),
      );
      await tester.pumpAndSettle();

      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
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
      expect(compass.right, lessThan(stream.left));
      expect(stream.right, lessThan(inspector.left));
      expect(compass.top, closeTo(stream.top, 1));
      expect(stream.top, closeTo(inspector.top, 1));
      expect(compass.bottom, closeTo(inspector.bottom, 1));
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
      await _pump(
        tester,
        freezeOrbitMotion: true,
        platform: TargetPlatform.windows,
      );

      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(compass.right, lessThan(stream.left));
      expect(compass.height, greaterThanOrEqualTo(420));
      expect(compass.bottom, greaterThan(500));
      expect(
        find.byKey(
          const PageStorageKey<String>('perfect-expanded-today-scroll'),
        ),
        findsOneWidget,
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
    'expanded Windows at 200 percent text becomes one readable column',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      await _pump(tester, textScaler: const TextScaler.linear(2));

      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(
        find.byKey(const ValueKey<String>('expanded-day-deck-stacked')),
        findsOneWidget,
      );
      expect(compass.bottom, lessThan(stream.top));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Windows Day Deck remains proportionate through intermediate resizes',
    (tester) async {
      for (final width in <double>[1280, 1366, 1600]) {
        await tester.binding.setSurfaceSize(Size(width, 820));
        await _pump(tester);

        final compass = tester.getRect(
          find.byKey(const ValueKey<String>('day-compass-panel')),
        );
        final stream = tester.getRect(
          find.byKey(const ValueKey<String>('day-stream-panel')),
        );
        final deck = tester.getRect(
          find.byKey(const ValueKey<String>('expanded-day-deck-stage')),
        );
        expect(compass.right, lessThan(stream.left), reason: 'width $width');
        expect(
          compass.width / deck.width,
          inInclusiveRange(.36, .47),
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

  testWidgets('short landscape keeps Orbit, navigation, and capture usable', (
    tester,
  ) async {
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
    expect(find.text('Capture a task, before it disappears…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
      expect(find.textContaining('Open · All'), findsOneWidget);
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
      expect(find.text('1 result · Open · All'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpAndSettle();
      expect(find.text('Read cardiology notes'), findsOneWidget);
      expect(find.text('Open · All'), findsOneWidget);
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
      expect(find.text('Open · All'), findsOneWidget);
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
        find.widgetWithText(ChoiceChip, 'Open'),
      );
      expect(openChip.selected, isTrue);
      expect(openChip.showCheckmark, isFalse);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Focus Deep Work'), findsNothing);
      expect(find.text('Your inbox is clear.'), findsOneWidget);
    },
  );

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
      find.descendant(of: row, matching: find.byTooltip('Log habit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not done'));
    await tester.tap(find.text('Save today'));
    await _pumpUntil(tester, () => find.text('MISSED').evaluate().isNotEmpty);
    await tester.pumpAndSettle();
    expect(find.text('MISSED'), findsOneWidget);
    expect(
      (await _controller.habitDaySummary(habit)).state,
      PlannerHabitDayState.missed,
    );

    final correctedRow = find.byKey(
      ValueKey<String>('entity-context-${habit.id}'),
    );
    await _keepTodayTargetClear(tester, correctedRow);
    await tester.tap(
      find.descendant(
        of: correctedRow,
        matching: find.byTooltip('Edit today’s habit result'),
      ),
    );
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

    await _keepTodayTargetClear(
      tester,
      find.byKey(ValueKey<String>('entity-context-${habit.id}')),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey<String>('entity-context-${habit.id}')),
        matching: find.byTooltip('Edit today’s habit result'),
      ),
    );
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
    await tester.tap(
      find.descendant(of: measuredRow, matching: find.byTooltip('Log habit')),
    );
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

    await _keepTodayTargetClear(tester, measuredRow);
    await tester.tap(
      find.descendant(
        of: measuredRow,
        matching: find.byTooltip('Edit today’s habit result'),
      ),
    );
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
    await tester.tap(
      find.descendant(of: checklistRow, matching: find.byTooltip('Log habit')),
    );
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
    await tester.tap(
      find.descendant(of: habitRow, matching: find.byTooltip('Log habit')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byTooltip('Close habit log'));
    await tester.pumpAndSettle();

    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await _keepTodayTargetClear(tester, habitRow);
    await tester.tap(
      find.descendant(of: habitRow, matching: find.byTooltip('Log habit')),
    );
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
      await tester.tap(find.text('Scheduled'));
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
}

Future<void> _pump(
  WidgetTester tester, {
  PerfectWorkspaceNavigationController? navigationController,
  PerfectAiClient? aiClient,
  ReadyFeedbackController? feedbackController,
  TextScaler? textScaler,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  bool freezeOrbitMotion = false,
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
        orbitMotionEnabled: !freezeOrbitMotion,
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
  final list = find.byKey(const ValueKey<String>('perfect-today-scroll'));
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
          of: find.byKey(const ValueKey<String>('perfect-today-scroll')),
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
