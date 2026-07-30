import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/ai/perfect_ai_client.dart';
import 'package:perfect/ai/perfect_ai_contract.dart';
import 'package:perfect/ai/perfect_ai_dock.dart';
import 'package:perfect/ai/perfect_voice_recorder.dart';
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
    final toggle = tester.widget<InkWell>(
      find.byKey(const ValueKey<String>('perfect-ai-toggle')),
    );
    expect(toggle.mouseCursor, SystemMouseCursors.click);
    expect(toggle.canRequestFocus, isTrue);
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
      await _pumpDock(tester, client: _FakeAiClient(), desktop: true);

      final surface = find.byKey(const ValueKey<String>('perfect-ai-surface'));
      final closed = tester.getRect(surface);
      expect(closed.width, inInclusiveRange(256, 360));
      expect(closed.height, 52);
      expect(closed.right, closeTo(1376, 1));

      await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
      await tester.pumpAndSettle();

      final open = tester.getRect(surface);
      expect(open.width, greaterThan(1300));
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
      final zoneColors = <Color?>{
        for (final key in const <String>[
          'perfect-ai-starter-plan-zone',
          'perfect-ai-starter-habit-zone',
          'perfect-ai-starter-rebalance-zone',
        ])
          (tester
                      .widget<AnimatedContainer>(
                        find.byKey(ValueKey<String>(key)),
                      )
                      .decoration
                  as BoxDecoration)
              .color,
      };
      expect(zoneColors.length, 3);
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
      await _pumpDock(tester, client: _FakeAiClient(), desktop: true);

      final surface = find.byKey(const ValueKey<String>('perfect-ai-surface'));
      final layout = find.byKey(const ValueKey<String>('perfect-ai-layout'));
      final closed = tester.getRect(surface);
      expect(closed.width, inInclusiveRange(280, 310));
      expect(closed.height, 52);
      expect(closed.right, closeTo(876, 1));
      expect(closed.width, lessThan(900 * .4));

      await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final midway = tester.getRect(layout);
      expect(midway.width, greaterThan(closed.width));
      expect(midway.width, lessThan(852));
      expect(midway.bottom, closeTo(closed.bottom, 1));

      await tester.pumpAndSettle();
      final open = tester.getRect(surface);
      expect(open.width, closeTo(852, 1));
      expect(open.bottom, closeTo(closed.bottom, 1));
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

    final control = tester.widget<InkWell>(toggle);
    control.focusNode!.requestFocus();
    await tester.pump(PerfectMotion.quick);
    expect(control.focusNode!.hasFocus, isTrue);
    expect(tester.getSize(layout), initialSize);

    final press = await tester.startGesture(tester.getCenter(toggle));
    await tester.pump(kPressTimeout);
    final scale = tester.widget<AnimatedScale>(
      find.ancestor(of: toggle, matching: find.byType(AnimatedScale)).first,
    );
    expect(scale.scale, lessThan(1));
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

  testWidgets('voice note is consented, stopped, attached and submitted', (
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
    expect(find.text('Start a voice note?'), findsOne);

    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-ai-consent-start')),
    );
    await tester.pumpAndSettle();
    expect(recorder.started, isTrue);
    expect(find.byTooltip('Stop voice note'), findsOne);

    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-voice')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove voice note'), findsOne);

    await tester.tap(find.byKey(const ValueKey<String>('perfect-ai-send')));
    await tester.pumpAndSettle();

    expect(client.chatRequests.single.audio?.mimeType, 'audio/wav');
    expect(find.text('Voice transcript'), findsOne);
    expect(recorder.stopped, isTrue);
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

      expect(find.text('Continue this on my tablet'), findsOne);
      expect(find.text('Your synced plan is ready.'), findsOne);
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
}

Future<void> _pumpDock(
  WidgetTester tester, {
  required _FakeAiClient client,
  _FakeVoiceRecorder? recorder,
  bool desktop = false,
  bool disableAnimations = false,
  TextScaler? textScaler,
  EdgeInsets viewInsets = EdgeInsets.zero,
  Future<void> Function()? onApplied,
}) async {
  final logicalSurfaceSize =
      tester.binding.renderViews.single.constraints.biggest;
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            size: logicalSurfaceSize,
            textScaler: textScaler,
            viewInsets: viewInsets,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: Column(
          children: [
            const Expanded(child: SizedBox()),
            PerfectAiDock(
              client: client,
              voiceRecorder: recorder,
              desktop: desktop,
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
