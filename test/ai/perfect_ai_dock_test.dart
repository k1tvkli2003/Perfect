import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/ai/perfect_ai_client.dart';
import 'package:perfect/ai/perfect_ai_contract.dart';
import 'package:perfect/ai/perfect_ai_dock.dart';
import 'package:perfect/ai/perfect_voice_recorder.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact dock opens above the footer without using an overlay', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _FakeAiClient();
    await _pumpDock(tester, client: client);

    expect(find.byKey(const ValueKey<String>('perfect-ai-toggle')), findsOne);
    expect(
      find.byKey(const ValueKey<String>('perfect-ai-composer')),
      findsNothing,
    );
    expect(find.text('Footer stays visible'), findsOne);
    final closedSurface = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-ai-surface')),
    );
    expect(closedSurface.width, closeTo(358, 1));
    expect(closedSurface.height, 58);
    final toggle = tester.widget<PerfectInteractiveSurface>(
      find.byKey(const ValueKey<String>('perfect-ai-toggle')),
    );
    expect(toggle.tone, PerfectInteractiveTone.tertiary);
    final toggleInk = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('perfect-ai-toggle')),
        matching: find.byType(InkWell),
      ),
    );
    expect(toggleInk.mouseCursor, SystemMouseCursors.click);
    expect(toggleInk.canRequestFocus, isTrue);
    final brandImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('perfect-ai-toggle')),
        matching: find.byType(Image),
      ),
    );
    expect(brandImage.frameBuilder, isNotNull);
    expect(brandImage.errorBuilder, isNotNull);
    toggle.focusNode!.requestFocus();
    await tester.pump();
    expect(toggle.focusNode!.hasFocus, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('perfect-ai-composer')), findsOne);
    expect(find.text('Plan my day'), findsOne);
    expect(find.text('Create a habit'), findsOne);
    final openSurface = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-ai-surface')),
    );
    for (final key in const <String>[
      'perfect-ai-starter-plan',
      'perfect-ai-starter-habit',
      'perfect-ai-starter-rebalance',
    ]) {
      final path = find.byKey(ValueKey<String>(key), skipOffstage: false);
      expect(path, findsOne);
      final pathRect = tester.getRect(path);
      expect(pathRect.top, greaterThanOrEqualTo(openSurface.top));
      expect(pathRect.bottom, lessThanOrEqualTo(openSurface.bottom));
    }
    expect(find.text('Private planning context'), findsNothing);
    expect(find.text('Footer stays visible'), findsOne);

    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-ai-starter-plan')),
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('perfect-ai-composer')),
          )
          .controller
          ?.text,
      'Plan my day around the commitments already in Perfect.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide command pill expands from the shell edge into a full AI workspace',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpDock(
        tester,
        client: _FakeAiClient(),
        desktop: true,
        platform: TargetPlatform.windows,
      );

      final surface = find.byKey(const ValueKey<String>('perfect-ai-surface'));
      final closed = tester.getRect(surface);
      expect(closed.width, inInclusiveRange(256, 360));
      expect(closed.height, 52);
      expect(closed.width, lessThan(1400 * .3));

      await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
      await tester.pumpAndSettle();

      final open = tester.getRect(surface);
      expect(open.width, inInclusiveRange(880, 1120));
      expect(open.bottom, closeTo(closed.bottom, 1));
      expect(find.text('Private planning context'), findsOne);
      expect(find.text('Schedule-aware'), findsOne);
      expect(find.text('Review first'), findsOne);
      expect(find.text('Owner-only'), findsOne);
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-starter-plan')),
        findsOne,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-starter-habit')),
        findsOne,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-starter-rebalance')),
        findsOne,
      );
      final zoneTones = <PerfectInteractiveTone>{
        for (final key in const <String>[
          'perfect-ai-starter-plan',
          'perfect-ai-starter-habit',
          'perfect-ai-starter-rebalance',
        ])
          tester
              .widget<PerfectInteractiveSurface>(
                find.byKey(ValueKey<String>(key)),
              )
              .tone,
      };
      expect(zoneTones.length, 3);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('perfect-ai-composer')),
            )
            .focusNode
            ?.hasFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tablet uses an attached compact command pill and stable bottom anchor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpDock(
        tester,
        client: _FakeAiClient(),
        desktop: true,
        platform: TargetPlatform.android,
      );

      final surface = find.byKey(const ValueKey<String>('perfect-ai-surface'));
      final layout = find.byKey(const ValueKey<String>('perfect-ai-layout'));
      final closed = tester.getRect(surface);
      expect(closed.width, inInclusiveRange(280, 310));
      expect(closed.height, 52);
      expect(closed.width, lessThan(900 * .4));

      await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final midway = tester.getRect(layout);
      expect(midway.width, greaterThan(closed.width));
      expect(midway.width, lessThan(852));
      expect(midway.bottom, closeTo(closed.bottom, 6));

      await tester.pumpAndSettle();
      final open = tester.getRect(surface);
      expect(open.width, closeTo(852, 1));
      expect(open.bottom, closeTo(closed.bottom, 1));
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-context-strip')),
        findsOne,
      );
      expect(find.text('Private planning context'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('perfect-ai-composer')),
            )
            .focusNode
            ?.hasFocus,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pointer hover focus and press preserve compact pill geometry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDock(tester, client: _FakeAiClient(), desktop: true);

    final layout = find.byKey(const ValueKey<String>('perfect-ai-layout'));
    final toggle = find.byKey(const ValueKey<String>('perfect-ai-toggle'));
    final initialSize = tester.getSize(layout);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(toggle));
    await tester.pump(PerfectMotion.quick);
    expect(tester.getSize(layout), initialSize);

    final control = tester.widget<PerfectInteractiveSurface>(toggle);
    control.focusNode!.requestFocus();
    await tester.pump(PerfectMotion.quick);
    expect(control.focusNode!.hasFocus, isTrue);
    expect(tester.getSize(layout), initialSize);

    final press = await tester.startGesture(tester.getCenter(toggle));
    await tester.pump(kPressTimeout);
    await tester.pump(PerfectMotion.quick);
    expect(
      find.descendant(
        of: toggle,
        matching: find.byKey(
          const ValueKey<String>('perfect-interaction-scale'),
        ),
      ),
      findsOne,
    );
    expect(tester.getSize(layout), initialSize);
    await press.cancel();
    await tester.pumpAndSettle();
    expect(tester.getSize(layout), initialSize);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock resizes smoothly and honors reduced motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDock(tester, client: _FakeAiClient());

    final layout = find.byKey(const ValueKey<String>('perfect-ai-layout'));
    final closedHeight = tester.getSize(layout).height;
    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    final midwayHeight = tester.getSize(layout).height;
    expect(midwayHeight, greaterThan(closedHeight));
    expect(midwayHeight, lessThan(390));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    final openHeight = tester.getSize(layout).height;

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpDock(tester, client: _FakeAiClient(), disableAnimations: true);
    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
    await tester.pump();
    await tester.pump(const Duration(microseconds: 1));
    expect(tester.getSize(layout).height, closeTo(openHeight, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact dock remains usable at 200 percent text scaling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDock(
      tester,
      client: _FakeAiClient(),
      textScaler: const TextScaler.linear(2),
    );
    expect(tester.takeException(), isNull);
    await _open(tester);

    expect(find.byKey(const ValueKey<String>('perfect-ai-composer')), findsOne);
    expect(
      MediaQuery.textScalerOf(
        tester.element(
          find.byKey(const ValueKey<String>('perfect-ai-composer')),
        ),
      ).scale(1),
      2,
    );
    final voiceSize = tester.getSize(
      find.byKey(const ValueKey<String>('perfect-ai-voice')),
    );
    expect(voiceSize.width, greaterThanOrEqualTo(48));
    expect(voiceSize.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet dock honors 200 percent text without losing actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDock(
      tester,
      client: _FakeAiClient(),
      desktop: true,
      textScaler: const TextScaler.linear(2),
    );

    final closed = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-ai-surface')),
    );
    expect(closed.width, lessThan(900 * .4));
    expect(closed.height, 52);
    expect(tester.takeException(), isNull);

    await _open(tester);
    final composer = find.byKey(const ValueKey<String>('perfect-ai-composer'));
    expect(MediaQuery.textScalerOf(tester.element(composer)).scale(1), 2);
    expect(composer, findsOne);
    expect(
      find.byKey(const ValueKey<String>('perfect-ai-starter-plan')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey<String>('perfect-ai-starter-habit')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey<String>('perfect-ai-starter-rebalance')),
      findsOne,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('perfect-ai-send'))),
      const Size(48, 48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('short IME layout keeps voice composer and send reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const keyboardInset = 160.0;
    await _pumpDock(
      tester,
      client: _FakeAiClient(),
      textScaler: const TextScaler.linear(2),
      viewInsets: const EdgeInsets.only(bottom: keyboardInset),
    );
    await _open(tester);

    for (final key in const <String>[
      'perfect-ai-voice',
      'perfect-ai-composer',
      'perfect-ai-send',
    ]) {
      final control = find.byKey(ValueKey<String>(key));
      expect(control, findsOne);
      expect(control.hitTestable(), findsOne);
      expect(
        tester.getRect(control).bottom,
        lessThanOrEqualTo(480 - keyboardInset),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'external launcher mode occupies zero space and opens through its controller',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final dockKey = GlobalKey<PerfectAiDockState>();
      final openChanges = <bool>[];
      await _pumpDock(
        tester,
        client: _FakeAiClient(),
        dockKey: dockKey,
        showCollapsedLauncher: false,
        onOpenChanged: openChanges.add,
      );

      expect(
        tester.getSize(find.byKey(const ValueKey<String>('perfect-ai-layout'))),
        Size.zero,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-surface')),
        findsNothing,
      );

      dockKey.currentState!.open();
      await tester.pumpAndSettle();
      expect(dockKey.currentState!.isOpen, isTrue);
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-composer')),
        findsOne,
      );
      expect(openChanges, <bool>[true]);

      dockKey.currentState!.close();
      await tester.pumpAndSettle();
      expect(dockKey.currentState!.isOpen, isFalse);
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('perfect-ai-layout'))),
        Size.zero,
      );
      expect(openChanges, <bool>[true, false]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '320px RTL at 200 percent reflows without clipping required actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpDock(
        tester,
        client: _FakeAiClient(),
        textScaler: const TextScaler.linear(2),
        textDirection: TextDirection.rtl,
      );
      await _open(tester);
      await tester.enterText(
        find.byKey(const ValueKey<String>('perfect-ai-composer')),
        'Plan امروز را آرام‌تر کن',
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('perfect-ai-composer-stacked')),
        findsOne,
      );
      for (final key in const <String>[
        'perfect-ai-close',
        'perfect-ai-voice',
        'perfect-ai-send',
      ]) {
        final action = find.byKey(ValueKey<String>(key));
        expect(action, findsOne);
        expect(action.hitTestable(), findsOne);
        final rect = tester.getRect(action);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(rect.bottom, lessThanOrEqualTo(700));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('high contrast dock uses an opaque two-pixel glass boundary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDock(
      tester,
      client: _FakeAiClient(),
      desktop: true,
      highContrast: true,
    );
    await _open(tester);

    expect(find.byType(BackdropFilter), findsNothing);
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey<String>('perfect-ai-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect((decoration.border! as Border).top.width, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape closes the Windows dock and restores prior focus', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dockKey = GlobalKey<PerfectAiDockState>();
    final outsideFocus = FocusNode(debugLabel: 'outside AI dock');
    addTearDown(outsideFocus.dispose);
    await _pumpDock(
      tester,
      client: _FakeAiClient(),
      desktop: true,
      platform: TargetPlatform.windows,
      dockKey: dockKey,
      showCollapsedLauncher: false,
      outsideFocus: outsideFocus,
    );
    outsideFocus.requestFocus();
    await tester.pump();

    dockKey.currentState!.open();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('perfect-ai-composer')),
          )
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(dockKey.currentState!.isOpen, isFalse);
    expect(outsideFocus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text answer becomes history and a proposal requires Apply', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var refreshes = 0;
    final client = _FakeAiClient(proposal: _proposal);
    await _pumpDock(tester, client: client, onApplied: () async => refreshes++);
    await _open(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('perfect-ai-composer')),
      'Build a calmer morning',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('perfect-ai-send')).hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('perfect-ai-send')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-send')));
    await tester.pumpAndSettle();

    expect(client.chatRequests.single.message, 'Build a calmer morning');
    expect(find.byKey(const ValueKey<String>('perfect-ai-proposal')), findsOne);
    expect(refreshes, 0);

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('perfect-ai-apply-proposal')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-ai-apply-proposal')),
    );
    await tester.pumpAndSettle();

    expect(client.applyCalls, 1);
    expect(refreshes, 1);
    expect(
      find.byKey(const ValueKey<String>('perfect-ai-proposal')),
      findsNothing,
    );
  });

  testWidgets(
    'large proposal reveals every change and still requires explicit approval',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = _FakeAiClient(proposal: _largeProposal);
      await _pumpDock(
        tester,
        client: client,
        textScaler: const TextScaler.linear(2),
      );
      await _open(tester);
      await tester.enterText(
        find.byKey(const ValueKey<String>('perfect-ai-composer')),
        'Prepare a complete week',
      );
      await tester.pump();
      final send = find.byKey(const ValueKey<String>('perfect-ai-send'));
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(send).onPressed, isNotNull);
      expect(send.hitTestable(), findsOne);
      await tester.tap(send);
      await tester.pumpAndSettle();

      expect(client.applyCalls, 0);
      expect(find.text('Evening reflection'), findsNothing);
      final reviewAll = find.byKey(
        const ValueKey<String>('perfect-ai-review-all'),
      );
      expect(reviewAll, findsOne);
      final history = find.byKey(const ValueKey<String>('perfect-ai-history'));
      await _bringIntoView(tester, target: reviewAll, scrollable: history);
      expect(reviewAll.hitTestable(), findsOne);
      await tester.tap(reviewAll);
      await tester.pumpAndSettle();

      expect(find.text('Evening reflection', skipOffstage: false), findsOne);
      expect(client.applyCalls, 0);
      final apply = find.byKey(
        const ValueKey<String>('perfect-ai-apply-proposal'),
      );
      await _bringIntoView(tester, target: apply, scrollable: history);
      expect(apply.hitTestable(), findsOne);
      expect(find.text('Apply 6 changes'), findsOne);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(client.applyCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('retryable failure preserves the draft and can recover', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _FakeAiClient(failuresBeforeSuccess: 1);
    await _pumpDock(tester, client: client);
    await _open(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('perfect-ai-composer')),
      'Do not lose this draft',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-send')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('perfect-ai-error')), findsOne);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('perfect-ai-composer')),
          )
          .controller
          ?.text,
      'Do not lose this draft',
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('I can help with that.'), findsOne);
    expect(
      find.byKey(const ValueKey<String>('perfect-ai-error')),
      findsNothing,
    );
  });

  testWidgets('voice notes wait for the local transcription boundary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final recorder = _FakeVoiceRecorder();
    final client = _FakeAiClient();
    await _pumpDock(tester, client: client, recorder: recorder);
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-voice')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Voice notes need the local transcription boundary first. Type your message for now.',
      ),
      findsOne,
    );
    expect(recorder.started, isFalse);
    expect(client.chatRequests, isEmpty);
  });

  testWidgets('cancel returns control without clearing the draft', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _FakeAiClient(blockChat: true);
    await _pumpDock(tester, client: client);
    await _open(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('perfect-ai-composer')),
      'Keep me',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-send')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('perfect-ai-cancel')), findsOne);

    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('perfect-ai-send')), findsOne);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('perfect-ai-composer')),
          )
          .controller
          ?.text,
      'Keep me',
    );
  });

  testWidgets(
    'hydrates the latest synced conversation and restores a safe pending proposal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = _FakeAiClient(
        history: PerfectAiConversationSnapshot(
          conversationId: '22222222-2222-4222-8222-222222222222',
          messages: <PerfectAiMessage>[
            PerfectAiMessage(
              id: '77777777-7777-4777-8777-777777777777',
              role: PerfectAiRole.user,
              text: 'Continue this on my tablet',
              createdAt: DateTime.utc(2026, 7, 30, 8),
            ),
            PerfectAiMessage(
              id: '88888888-8888-4888-8888-888888888888',
              role: PerfectAiRole.assistant,
              text: 'Your synced plan is ready.',
              createdAt: DateTime.utc(2026, 7, 30, 8, 1),
            ),
          ],
          pendingProposal: _proposal,
        ),
      );
      await _pumpDock(tester, client: client);
      await _open(tester);

      expect(
        find.text('Continue this on my tablet', skipOffstage: false),
        findsOne,
      );
      expect(
        find.text('Your synced plan is ready.', skipOffstage: false),
        findsOne,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-proposal')),
        findsOne,
      );
      expect(client.historyLoads, 2);
    },
  );

  testWidgets('history failure is honest, retryable and never blocks chat', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _FakeAiClient(historyFailuresBeforeSuccess: 2);
    await _pumpDock(tester, client: client);
    await _open(tester);

    expect(
      find.byKey(const ValueKey<String>('perfect-ai-history-error')),
      findsOne,
    );
    expect(find.byKey(const ValueKey<String>('perfect-ai-composer')), findsOne);

    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-ai-history-retry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('perfect-ai-history-error')),
      findsNothing,
    );
    expect(find.text('Plan my day'), findsOne);
    expect(client.historyLoads, 3);
  });

  testWidgets(
    'history retry and error dismissal remain reachable at 320px and 200 percent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final historyClient = _FakeAiClient(historyFailuresBeforeSuccess: 2);
      await _pumpDock(
        tester,
        client: historyClient,
        textScaler: const TextScaler.linear(2),
      );
      await _open(tester);

      final history = find.byKey(const ValueKey<String>('perfect-ai-history'));
      final historyRetry = find.byKey(
        const ValueKey<String>('perfect-ai-history-retry'),
      );
      await _bringIntoView(tester, target: historyRetry, scrollable: history);
      expect(historyRetry.hitTestable(), findsOne);
      await tester.tap(historyRetry);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-history-error')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      final failingClient = _FakeAiClient(failuresBeforeSuccess: 1);
      await _pumpDock(
        tester,
        client: failingClient,
        textScaler: const TextScaler.linear(2),
      );
      await _open(tester);
      await tester.enterText(
        find.byKey(const ValueKey<String>('perfect-ai-composer')),
        'Keep this draft visible',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-send')));
      await tester.pumpAndSettle();

      final errorHistory = find.byKey(
        const ValueKey<String>('perfect-ai-history'),
      );
      final errorDismiss = find.byKey(
        const ValueKey<String>('perfect-ai-error-dismiss'),
      );
      await _bringIntoView(
        tester,
        target: errorDismiss,
        scrollable: errorHistory,
      );
      expect(
        find
            .byKey(const ValueKey<String>('perfect-ai-error-retry'))
            .hitTestable(),
        findsOne,
      );
      expect(errorDismiss.hitTestable(), findsOne);
      await tester.tap(errorDismiss);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('perfect-ai-error')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('voice boundary message stays readable at 200 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDock(
      tester,
      client: _FakeAiClient(),
      recorder: _FakeVoiceRecorder(),
      textScaler: const TextScaler.linear(2),
    );
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-voice')));
    await tester.pumpAndSettle();

    final message = find.text(
      'Voice notes need the local transcription boundary first. Type your message for now.',
      skipOffstage: false,
    );
    expect(message, findsOne);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDock(
  WidgetTester tester, {
  required _FakeAiClient client,
  _FakeVoiceRecorder? recorder,
  bool desktop = false,
  bool disableAnimations = false,
  bool highContrast = false,
  bool showCollapsedLauncher = true,
  TextScaler? textScaler,
  TextDirection textDirection = TextDirection.ltr,
  TargetPlatform? platform,
  EdgeInsets viewInsets = EdgeInsets.zero,
  GlobalKey<PerfectAiDockState>? dockKey,
  ValueChanged<bool>? onOpenChanged,
  FocusNode? outsideFocus,
  Future<void> Function()? onApplied,
}) async {
  if (viewInsets != EdgeInsets.zero) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: viewInsets.bottom * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
  }
  final logicalSurfaceSize =
      tester.binding.renderViews.single.constraints.biggest;
  final effectivePlatform =
      platform ?? (desktop ? TargetPlatform.windows : TargetPlatform.android);
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light().copyWith(platform: effectivePlatform),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: media.copyWith(
              disableAnimations: disableAnimations,
              highContrast: highContrast,
              size: logicalSurfaceSize,
              textScaler: textScaler,
              viewInsets: viewInsets,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: outsideFocus == null
                  ? const SizedBox()
                  : Align(
                      alignment: Alignment.topLeft,
                      child: TextButton(
                        key: const ValueKey<String>('outside-ai-focus'),
                        focusNode: outsideFocus,
                        onPressed: () {},
                        child: const Text('Outside AI'),
                      ),
                    ),
            ),
            PerfectAiDock(
              key: dockKey,
              client: client,
              voiceRecorder: recorder,
              desktop: desktop,
              showCollapsedLauncher: showCollapsedLauncher,
              onOpenChanged: onOpenChanged,
              onProposalApplied: onApplied ?? () async {},
            ),
            const SizedBox(
              height: 64,
              child: Center(child: Text('Footer stays visible')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
  await tester.pumpAndSettle();
}

Future<void> _bringIntoView(
  WidgetTester tester, {
  required Finder target,
  required Finder scrollable,
}) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final targetRect = tester.getRect(target);
    final viewport = tester.getRect(scrollable);
    if (targetRect.top >= viewport.top + PerfectSpace.xs &&
        targetRect.bottom <= viewport.bottom - PerfectSpace.xs) {
      return;
    }
    final move = targetRect.top < viewport.top
        ? PerfectSpace.giant
        : -PerfectSpace.giant;
    await tester.drag(scrollable, Offset(0, move));
    await tester.pumpAndSettle();
  }
}

final _proposal = PerfectAiProposal(
  submissionId: '44444444-4444-4444-8444-444444444444',
  title: 'Calm morning',
  summary: 'Two small changes.',
  requiresConfirmation: true,
  items: const <PerfectAiProposalItem>[
    PerfectAiProposalItem(
      id: '55555555-5555-4555-8555-555555555555',
      kind: 'habit',
      title: 'Drink water',
      payload: <String, dynamic>{'category': 'health'},
    ),
    PerfectAiProposalItem(
      id: '66666666-6666-4666-8666-666666666666',
      kind: 'one_off_task',
      title: 'Review priorities',
      payload: <String, dynamic>{'category': 'work'},
    ),
  ],
);

final _largeProposal = PerfectAiProposal(
  submissionId: '99999999-9999-4999-8999-999999999999',
  title: 'A complete but calm week',
  summary:
      'Six deliberate changes with enough detail to verify wrapping at narrow widths.',
  requiresConfirmation: true,
  items: const <PerfectAiProposalItem>[
    PerfectAiProposalItem(
      id: '10000000-0000-4000-8000-000000000001',
      kind: 'one_off_task',
      title: 'Review the most important priorities before starting deep work',
      payload: <String, dynamic>{'category': 'work'},
    ),
    PerfectAiProposalItem(
      id: '10000000-0000-4000-8000-000000000002',
      kind: 'habit',
      title: 'Drink water after waking up',
      payload: <String, dynamic>{'category': 'health'},
    ),
    PerfectAiProposalItem(
      id: '10000000-0000-4000-8000-000000000003',
      kind: 'habit',
      title: 'Take a short afternoon walk',
      payload: <String, dynamic>{'category': 'health'},
    ),
    PerfectAiProposalItem(
      id: '10000000-0000-4000-8000-000000000004',
      kind: 'one_off_task',
      title: 'Prepare tomorrow before dinner',
      payload: <String, dynamic>{'category': 'personal'},
    ),
    PerfectAiProposalItem(
      id: '10000000-0000-4000-8000-000000000005',
      kind: 'one_off_task',
      title: 'Call family without rushing',
      payload: <String, dynamic>{'category': 'personal'},
    ),
    PerfectAiProposalItem(
      id: '10000000-0000-4000-8000-000000000006',
      kind: 'habit',
      title: 'Evening reflection',
      payload: <String, dynamic>{'category': 'personal'},
    ),
  ],
);

class _FakeAiClient implements PerfectAiClient, PerfectAiHistoryClient {
  _FakeAiClient({
    this.proposal,
    this.history,
    this.failuresBeforeSuccess = 0,
    this.historyFailuresBeforeSuccess = 0,
    this.blockChat = false,
  });

  final PerfectAiProposal? proposal;
  final PerfectAiConversationSnapshot? history;
  int failuresBeforeSuccess;
  int historyFailuresBeforeSuccess;
  final bool blockChat;
  final List<PerfectAiRequest> chatRequests = <PerfectAiRequest>[];
  int applyCalls = 0;
  int historyLoads = 0;

  @override
  Future<PerfectAiConversationSnapshot?> loadLatestConversation({
    PerfectAiCancellation? cancellation,
  }) async {
    historyLoads++;
    if (historyFailuresBeforeSuccess > 0) {
      historyFailuresBeforeSuccess--;
      throw const PerfectAiException(
        code: PerfectAiErrorCode.unavailable,
        message: 'History is temporarily unavailable.',
        retryable: true,
      );
    }
    return history;
  }

  @override
  Future<PerfectAiTurnResult> chat(
    PerfectAiRequest request, {
    PerfectAiCancellation? cancellation,
  }) async {
    chatRequests.add(request);
    if (blockChat) {
      while (cancellation?.isCancelled != true) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      throw const PerfectAiException(
        code: PerfectAiErrorCode.cancelled,
        message: 'Cancelled.',
        retryable: true,
      );
    }
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw const PerfectAiException(
        code: PerfectAiErrorCode.unavailable,
        message: 'Temporary failure.',
        retryable: true,
      );
    }
    return PerfectAiTurnResult(
      operationId: request.operationId,
      conversationId: '22222222-2222-4222-8222-222222222222',
      transcribedText: request.audio == null ? null : 'Voice transcript',
      message: PerfectAiMessage(
        id: '33333333-3333-4333-8333-333333333333',
        role: PerfectAiRole.assistant,
        text: proposal == null
            ? 'I can help with that.'
            : 'I prepared a calm plan.',
        createdAt: DateTime.utc(2026, 7, 30),
      ),
      proposal: proposal,
    );
  }

  @override
  Future<PerfectAiApplyResult> applyProposal({
    required String operationId,
    required String? conversationId,
    required PerfectAiProposal proposal,
    PerfectAiCancellation? cancellation,
  }) async {
    applyCalls++;
    return PerfectAiApplyResult(
      operationId: operationId,
      conversationId: conversationId ?? '22222222-2222-4222-8222-222222222222',
      appliedCount: proposal.items.length,
      message: null,
    );
  }
}

class _FakeVoiceRecorder implements PerfectVoiceRecorder {
  bool started = false;
  bool stopped = false;

  @override
  Future<void> cancel() async => started = false;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start() async => started = true;

  @override
  Future<PerfectVoiceClip?> stop() async {
    stopped = true;
    started = false;
    return PerfectVoiceClip(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      mimeType: 'audio/wav',
      duration: const Duration(seconds: 2),
    );
  }
}
