import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_theme.dart';
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
      await _pump(tester);

      expect(find.text('Today’s flow'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Capture a task…'), findsOneWidget);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_compact.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'compact AI toggle participates in footer layout above capture',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, aiClient: _WorkspaceAiClient());

      final ai = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-surface')),
      );
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      expect(ai.bottom, lessThanOrEqualTo(capture.top));
      expect(find.byType(NavigationBar), findsOneWidget);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_compact_ai_closed.png'),
      );

      await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
      await tester.pumpAndSettle();
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
    'Android tablet defaults narrow and expands without overlap',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      await _pump(tester, aiClient: _WorkspaceAiClient());

      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
      expect(find.byKey(const ValueKey<String>('rail-mark')), findsOneWidget);
      expect(find.text('Perfect!'), findsNothing);
      expect(find.byTooltip('Expand navigation'), findsOneWidget);
      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      final runway = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-runway')),
      );
      final signal = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-signal-zone')),
      );
      final ai = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-surface')),
      );
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );
      expect(compass.top, closeTo(stream.top, 1));
      expect(compass.bottom, closeTo(stream.bottom, 1));
      expect(compass.right, lessThan(stream.left));
      expect(compass.height, greaterThan(500));
      expect(compass.bottom - runway.bottom, lessThanOrEqualTo(20));
      expect(stream.bottom - signal.bottom, lessThanOrEqualTo(20));
      expect(runway.height, greaterThan(260));
      expect(signal.height, greaterThan(180));
      expect(ai.top - compass.bottom, lessThan(120));
      expect(ai.bottom, lessThanOrEqualTo(capture.top));
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_tablet_rail_compact.png'),
      );

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
      expect(animatedWidth, inExclusiveRange(78, 212));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
      expect(find.byKey(const ValueKey<String>('rail-mark')), findsNothing);
      expect(find.text('Perfect!'), findsOneWidget);
      final expandedCompass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final expandedStream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      expect(expandedCompass.right, lessThan(expandedStream.left));
      expect(expandedCompass.height, greaterThan(500));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_tablet_rail_expanded.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'medium Day Deck uses content-driven reflow at 768 900 and 1024dp',
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

      final standard = await layoutAt(900);
      expect(standard.$1.right, lessThan(standard.$2.left));
      expect(standard.$1.height, greaterThan(500));

      final roomy = await layoutAt(1024);
      expect(roomy.$1.right, lessThan(roomy.$2.left));
      expect(roomy.$1.width, greaterThan(standard.$1.width));
    },
  );

  testWidgets(
    'Android tablet landscape keeps the Day Deck and shell continuously usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await _pump(tester, aiClient: _WorkspaceAiClient());

      final compass = tester.getRect(
        find.byKey(const ValueKey<String>('day-compass-panel')),
      );
      final stream = tester.getRect(
        find.byKey(const ValueKey<String>('day-stream-panel')),
      );
      final ai = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-ai-surface')),
      );
      final capture = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-quick-capture-surface')),
      );

      expect(compass.right, lessThan(stream.left));
      expect(compass.top, closeTo(stream.top, 1));
      expect(compass.bottom, closeTo(stream.bottom, 1));
      expect(compass.height, greaterThan(450));
      expect(compass.bottom, lessThanOrEqualTo(ai.top));
      expect(ai.bottom, lessThanOrEqualTo(capture.top));
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
      expect(find.text('Perfect!'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Windows rail collapse choice survives a workspace remount', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    await _pump(tester);
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

      expect(find.text('New task…'), findsOneWidget);
      expect(find.byTooltip('Plan in the full editor'), findsNothing);
      expect(tester.takeException(), isNull);

      for (final tooltip in <String>[
        'Open full editor',
        'Save quick capture',
      ]) {
        final size = tester.getSize(find.byTooltip(tooltip));
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

  testWidgets('the final Today task scrolls fully above the persistent dock', (
    tester,
  ) async {
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
  });

  testWidgets('compact task details open the existing editor', (tester) async {
    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);

    await tester.tap(find.text('Focus Deep Work'));
    await tester.pumpAndSettle();
    expect(find.text('Edit details'), findsOneWidget);
    expect(find.textContaining('Type is fixed after creation'), findsOneWidget);
  });

  testWidgets(
    'expanded Windows Day Deck keeps the compass and stream adjacent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      await _pump(tester);

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
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PerfectWorkspacePage),
        matchesGoldenFile('../goldens/perfect_expanded.png'),
      );
    },
    tags: 'windows-golden',
  );

  testWidgets(
    'wide Windows Day Deck promotes selected detail to a true third pane',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await _pump(tester);
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
      await _pump(tester);

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

  testWidgets('compact item menu duplicates and opens the duplicate editor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);
    final source = _controller.tasks.singleWhere(
      (item) => item.title == 'Focus Deep Work',
    );
    final row = find.byKey(ValueKey<String>('entity-context-${source.id}'));

    await tester.tap(
      find
          .descendant(of: row, matching: find.byType(PopupMenuButton<String>))
          .first,
    );
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
    expect(find.text('Focus Deep Work'), findsWidgets);
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

    await tester.tap(find.text('Plan').last);
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
    expect(find.text('Today’s flow'), findsOneWidget);
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

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(
        find.text('Private controls, not public settings.'),
        findsOneWidget,
      );

      navigation.showToday();
      await tester.pumpAndSettle();
      expect(find.text('Today’s flow'), findsOneWidget);
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
    expect(find.byTooltip('Capture feedback'), findsOneWidget);
    expect(find.bySemanticsLabel('Capture private feedback'), findsOneWidget);
    await tester.tap(find.byTooltip('Capture feedback'));
    await tester.pumpAndSettle();
    expect(find.text('Private feedback capture'), findsOneWidget);
    expect(
      find.text('Everything stays on this device until you export it.'),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More (Ctrl+5)'));
    await tester.pumpAndSettle();
    expect(find.text('Feedback capture button'), findsOneWidget);
    expect(find.text('Captured feedback & logs'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Private feedback and diagnostics settings'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Capture feedback'));
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
    expect(find.byTooltip('Capture feedback'), findsOneWidget);
    expect(find.text('Feedback capture button'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    expect(feedback.enabled, isFalse);
    expect(find.byTooltip('Capture feedback'), findsNothing);
    late final SharedPreferences preferences;
    await tester.runAsync(() async {
      preferences = await SharedPreferences.getInstance();
    });
    expect(preferences.getBool(config.settingsKey), isFalse);
  });

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
      await _pump(tester, navigationController: navigation);

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

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.text('Edit details'), findsOneWidget);
      expect(find.text('Focus Deep Work'), findsWidgets);
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

    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);
    expect(find.text('Water plants'), findsNothing);

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('No blocks yet.'), findsOneWidget);
    expect(find.text('Focus Deep Work'), findsNothing);

    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Deep Work'), findsOneWidget);
  });

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

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recurring'));
      await tester.pumpAndSettle();
      expect(find.text('Weekly review'), findsOneWidget);
      expect(find.text('Focus Deep Work'), findsNothing);

      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      expect(find.text('Focus Deep Work'), findsOneWidget);
      expect(find.text('Weekly review'), findsNothing);
    },
  );

  testWidgets('Habits expose an honest seven-day schedule preview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pump(tester);

    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    expect(find.text('Water plants'), findsOneWidget);
    expect(find.text('Every day'), findsOneWidget);
    expect(find.text('Schedule this week'), findsOneWidget);
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
      await tester.scrollUntilVisible(
        find.text('Task context'),
        300,
        scrollable: _editorScrollable(),
      );
      await _keepEditorTargetClear(tester, find.text('Task context'));
      await tester.tap(find.text('Task context'));
      await tester.pumpAndSettle();
      final chip = tester.widget<InputChip>(
        find.widgetWithText(InputChip, 'Keep this state'),
      );
      expect(chip.selected, isTrue);

      await _keepEditorTargetClear(tester, find.text('Keep this state'));
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
      await tester.tap(find.text('Save to Perfect'));
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

    await tester.scrollUntilVisible(
      find.text('Habit tracking'),
      300,
      scrollable: _editorScrollable(),
    );
    await _keepEditorTargetClear(tester, find.text('Habit tracking'));
    await tester.tap(find.text('Habit tracking'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Goal or limit'),
      '12.5',
    );
    await tester.tap(find.text('Save to Perfect'));
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

      await tester.scrollUntilVisible(
        find.text('Repeat & recovery'),
        300,
        scrollable: _editorScrollable(),
      );
      await _keepEditorTargetClear(tester, find.text('Repeat & recovery'));
      await tester.tap(find.text('Repeat & recovery'));
      await tester.pumpAndSettle();
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
      await tester.tap(find.text('Save to Perfect'));
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
      await tester.scrollUntilVisible(
        find.text('Repeat & recovery'),
        300,
        scrollable: _editorScrollable(),
      );
      await _keepEditorTargetClear(tester, find.text('Repeat & recovery'));
      await tester.tap(find.text('Repeat & recovery'));
      await tester.pumpAndSettle();
      expect(find.text('Feb 29'), findsOneWidget);
      expect(find.text('Dec 31'), findsOneWidget);
      await tester.tap(find.text('Save to Perfect'));
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
      await tester.enterText(
        find.widgetWithText(TextFormField, 'What matters?'),
        'Flexible strength',
      );
      await tester.scrollUntilVisible(
        find.text('Repeat & recovery'),
        300,
        scrollable: _editorScrollable(),
      );
      await _keepEditorTargetClear(tester, find.text('Repeat & recovery'));
      await tester.tap(find.text('Repeat & recovery'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Does not repeat'),
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
      await tester.tap(find.text('Save to Perfect'));
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
      await tester.scrollUntilVisible(
        find.text('Repeat & recovery'),
        300,
        scrollable: _editorScrollable(),
      );
      await _keepEditorTargetClear(tester, find.text('Repeat & recovery'));
      await tester.tap(find.text('Repeat & recovery'));
      await tester.pumpAndSettle();
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
      await tester.tap(find.text('Save to Perfect'));
      await tester.pump();
      expect(find.text('Choose 1–7.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Completions per period'),
        '5',
      );
      final previousRevision = created.revision;
      await tester.tap(find.text('Save to Perfect'));
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
    final row = find
        .ancestor(
          of: find.text('Measured recurring work'),
          matching: find.byType(Card),
        )
        .first;
    await _keepTodayTargetClear(tester, row);
    await tester.tap(
      find
          .descendant(of: row, matching: find.byType(PopupMenuButton<String>))
          .first,
    );
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

    final row = _cardContaining('Water plants');
    await _keepTodayTargetClear(tester, row);
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Log habit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not done'));
    await tester.tap(find.text('Save today'));
    await _pumpUntil(
      tester,
      () => find.text('Not done today').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.text('Not done today'), findsOneWidget);

    final correctedRow = _cardContaining('Water plants');
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
    await _pumpUntil(
      tester,
      () => find.text('Complete today').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.text('Complete today'), findsOneWidget);

    await _keepTodayTargetClear(tester, _cardContaining('Water plants'));
    await tester.tap(
      find.descendant(
        of: _cardContaining('Water plants'),
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
    expect(find.text('Pending today'), findsOneWidget);
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
    await _keepTodayTargetClear(tester, _cardContaining('Read measured pages'));
    await tester.tap(
      find.descendant(
        of: _cardContaining('Read measured pages'),
        matching: find.byTooltip('Log habit'),
      ),
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
          .textContaining('2 pages of 10 pages · 20%')
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2 pages of 10 pages · 20%'), findsOneWidget);

    await _keepTodayTargetClear(tester, _cardContaining('Read measured pages'));
    await tester.tap(
      find.descendant(
        of: _cardContaining('Read measured pages'),
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
          .textContaining('12 pages of 10 pages · 100%')
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('12 pages of 10 pages · 100%'), findsOneWidget);
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
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What matters?'),
      'Morning checklist',
    );
    await tester.scrollUntilVisible(
      find.text('Habit tracking'),
      300,
      scrollable: _editorScrollable(),
    );
    await _keepEditorTargetClear(tester, find.text('Habit tracking'));
    await tester.tap(find.text('Habit tracking'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'A simple check-in'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('A checklist with a success rule').last);
    await tester.pumpAndSettle();

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
    await _keepEditorTargetClear(tester, requiredChip);
    await tester.tap(requiredChip);
    final editStretch = find.byTooltip('Edit Stretch');
    await _keepEditorTargetClear(tester, editStretch);
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
    await tester.tap(find.text('Save to Perfect'));
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
    await _keepTodayTargetClear(tester, _cardContaining('Morning checklist'));
    await tester.tap(
      find.descendant(
        of: _cardContaining('Morning checklist'),
        matching: find.byTooltip('Log habit'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Water'));
    await tester.tap(find.text('Save today'));
    await _pumpUntil(
      tester,
      () => find
          .textContaining('1/2 checked · 1 needed · 100%')
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1/2 checked · 1 needed · 100%'),
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
    await _keepTodayTargetClear(tester, _cardContaining('Water plants'));
    await tester.tap(
      find.descendant(
        of: _cardContaining('Water plants'),
        matching: find.byTooltip('Log habit'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byTooltip('Close habit log'));
    await tester.pumpAndSettle();

    await _setTestViewSize(tester, const Size(390, 844));
    await _pump(tester);
    await _keepTodayTargetClear(tester, _cardContaining('Water plants'));
    await tester.tap(
      find.descendant(
        of: _cardContaining('Water plants'),
        matching: find.byTooltip('Log habit'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('perfect-habit-log-surface')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
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

  testWidgets('Windows command menu makes every global shortcut discoverable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await _pump(tester);

    await tester.tap(find.byTooltip('Account and commands'));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    await tester.tap(find.text('Keyboard shortcuts'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Ctrl + N'), findsOneWidget);
    expect(find.text('Ctrl + K'), findsOneWidget);
    expect(find.text('Ctrl + Shift + F'), findsOneWidget);
    expect(find.text('Menu or Shift + F10'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
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
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: textScaler == null
              ? mediaQuery
              : mediaQuery.copyWith(textScaler: textScaler),
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
  await tester.ensureVisible(target);
  await tester.pump();
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

Finder _editorScrollable() => find
    .descendant(
      of: find.byKey(const ValueKey<String>('planner-editor-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _keepEditorTargetClear(
  WidgetTester tester,
  Finder target, {
  double clearance = 24,
}) async {
  await tester.ensureVisible(target);
  await tester.pump();
  final viewport = tester.getRect(
    find.byKey(const ValueKey<String>('planner-editor-scroll')),
  );
  final targetRect = tester.getRect(target);
  final desiredTop = viewport.top + clearance;
  final offsetFromSafeTop = targetRect.top - desiredTop;
  if (offsetFromSafeTop.abs() > 1) {
    await tester.drag(
      find.byKey(const ValueKey<String>('planner-editor-scroll')),
      Offset(0, -offsetFromSafeTop),
    );
    await tester.pumpAndSettle();
  }
  final adjustedTargetRect = tester.getRect(target);
  final coveredBy = adjustedTargetRect.bottom - (viewport.bottom - clearance);
  if (coveredBy <= 0) return;
  await tester.drag(
    find.byKey(const ValueKey<String>('planner-editor-scroll')),
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

Future<void> _pumpNewEditor(
  WidgetTester tester, {
  required PlannerEntityKind initialKind,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
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
