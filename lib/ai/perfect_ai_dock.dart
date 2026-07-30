import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect/ai/perfect_ai_client.dart';
import 'package:perfect/ai/perfect_ai_contract.dart';
import 'package:perfect/ai/perfect_voice_recorder.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:uuid/uuid.dart';

class PerfectAiDock extends StatefulWidget {
  const PerfectAiDock({
    super.key,
    required this.client,
    required this.onProposalApplied,
    this.voiceRecorder,
    this.desktop = false,
  });

  final PerfectAiClient client;
  final PerfectVoiceRecorder? voiceRecorder;
  final Future<void> Function() onProposalApplied;
  final bool desktop;

  @override
  State<PerfectAiDock> createState() => PerfectAiDockState();
}

class PerfectAiDockState extends State<PerfectAiDock>
    with WidgetsBindingObserver {
  static const _uuid = Uuid();
  static const _maxVoiceDuration = Duration(seconds: 45);

  final TextEditingController _composer = TextEditingController();
  final ScrollController _historyScroll = ScrollController();
  final FocusNode _composerFocus = FocusNode(debugLabel: 'Perfect AI composer');
  final FocusNode _toggleFocus = FocusNode(debugLabel: 'Perfect AI toggle');
  final List<PerfectAiMessage> _messages = <PerfectAiMessage>[];

  late final PerfectVoiceRecorder _recorder =
      widget.voiceRecorder ?? NativePerfectVoiceRecorder();
  PerfectAiCancellation? _cancellation;
  PerfectAiCancellation? _historyCancellation;
  PerfectVoiceClip? _voiceClip;
  PerfectAiProposal? _proposal;
  PerfectAiException? _error;
  PerfectAiException? _historyError;
  String? _conversationId;
  String? _lastPrompt;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  int _conversationEpoch = 0;
  bool _open = false;
  bool _sending = false;
  bool _applying = false;
  bool _historyLoading = false;
  bool _historyAttempted = false;
  bool _historySuppressed = false;
  bool _recording = false;
  bool _toggleHovered = false;
  bool _toggleFocused = false;
  bool _togglePressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_hydrateLatestConversation());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _recording) {
      unawaited(_cancelRecording());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancellation?.cancel();
    _historyCancellation?.cancel();
    _recordingTimer?.cancel();
    _composer.dispose();
    _historyScroll.dispose();
    _composerFocus.dispose();
    _toggleFocus.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animationDuration = reduceMotion
        ? const Duration(microseconds: 1)
        : PerfectMotion.standard;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.desktop ? PerfectSpace.xl : PerfectSpace.md,
          PerfectSpace.xxs,
          widget.desktop ? PerfectSpace.xl : PerfectSpace.md,
          PerfectSpace.xxs,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final mediaUsableHeight =
                (media.size.height - media.viewInsets.bottom)
                    .clamp(0.0, double.infinity)
                    .toDouble();
            final usableViewportHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight.clamp(0.0, mediaUsableHeight).toDouble()
                : mediaUsableHeight;
            final openHeightFactor = usableViewportHeight < 560
                ? .46
                : widget.desktop
                ? .44
                : .46;
            final openHeight = usableViewportHeight * openHeightFactor;
            final targetHeight = _open
                ? openHeight
                : widget.desktop
                ? 52.0
                : 58.0;
            final compactCommandWidth = availableWidth <= 256
                ? availableWidth
                : (availableWidth * .34).clamp(256.0, 360.0);
            final targetWidth = _open || !widget.desktop
                ? availableWidth
                : compactCommandWidth;
            final denseOpenLayout = targetHeight < 48 * 5.25;
            final scheme = Theme.of(context).colorScheme;
            final closedInteractive = !_open;
            final borderColor = _open
                ? scheme.tertiary.withValues(alpha: .62)
                : _toggleFocused
                ? scheme.primary
                : _toggleHovered
                ? scheme.tertiary
                : scheme.outlineVariant;
            final surfaceTint = _toggleHovered && closedInteractive
                ? scheme.tertiaryContainer.withValues(alpha: .38)
                : Colors.transparent;

            return Align(
              alignment: widget.desktop
                  ? AlignmentDirectional.bottomEnd
                  : AlignmentDirectional.bottomCenter,
              child: AnimatedSize(
                key: const ValueKey<String>('perfect-ai-layout'),
                duration: animationDuration,
                curve: PerfectMotion.productive,
                alignment: widget.desktop
                    ? AlignmentDirectional.bottomEnd
                    : AlignmentDirectional.bottomCenter,
                clipBehavior: Clip.none,
                child: SizedBox(
                  width: targetWidth,
                  height: targetHeight,
                  child: AnimatedScale(
                    scale: closedInteractive && _togglePressed ? .985 : 1,
                    duration: PerfectMotion.responsive(
                      context,
                      PerfectMotion.quick,
                    ),
                    curve: PerfectMotion.productive,
                    child: AnimatedContainer(
                      key: const ValueKey<String>('perfect-ai-surface'),
                      duration: PerfectMotion.responsive(
                        context,
                        PerfectMotion.quick,
                      ),
                      curve: PerfectMotion.productive,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(surfaceTint, scheme.surface),
                        gradient: _open
                            ? LinearGradient(
                                begin: AlignmentDirectional.topStart,
                                end: AlignmentDirectional.bottomEnd,
                                colors: [
                                  scheme.surface,
                                  Color.alphaBlend(
                                    scheme.tertiary.withValues(alpha: .09),
                                    scheme.surface,
                                  ),
                                  Color.alphaBlend(
                                    scheme.secondary.withValues(alpha: .08),
                                    scheme.surface,
                                  ),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(_open ? 28 : 99),
                        border: Border.all(
                          color: borderColor,
                          width: _toggleFocused && closedInteractive ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_toggleHovered && closedInteractive
                                        ? scheme.tertiary
                                        : PerfectColors.lilac)
                                    .withValues(
                                      alpha: _toggleHovered ? .17 : .10,
                                    ),
                            blurRadius: _toggleHovered ? 24 : 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_open ? 27 : 99),
                        child: _open
                            ? _openDock(context, dense: denseOpenLayout)
                            : _closedToggle(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _closedToggle(BuildContext context) => Semantics(
    button: true,
    expanded: false,
    label: 'Open Perfect AI',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('perfect-ai-toggle'),
        onTap: _toggleOpen,
        onHover: (value) => setState(() => _toggleHovered = value),
        onFocusChange: (value) => setState(() => _toggleFocused = value),
        onHighlightChanged: (value) => setState(() => _togglePressed = value),
        borderRadius: BorderRadius.circular(99),
        mouseCursor: SystemMouseCursors.click,
        canRequestFocus: true,
        focusNode: _toggleFocus,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            widget.desktop ? 6 : 7,
            5,
            widget.desktop ? 12 : 14,
            5,
          ),
          child: Row(
            children: [
              _BrandPulse(
                active: _sending || _applying,
                compact: widget.desktop,
              ),
              SizedBox(
                width: widget.desktop ? PerfectSpace.xs : PerfectSpace.sm,
              ),
              Expanded(
                child:
                    widget.desktop ||
                        MediaQuery.textScalerOf(context).scale(1) >= 1.5
                    ? Text.rich(
                        TextSpan(
                          text: 'Perfect AI',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(
                              text:
                                  MediaQuery.textScalerOf(context).scale(1) >=
                                      1.5
                                  ? ''
                                  : _proposal == null
                                  ? '  ·  Ask or speak'
                                  : '  ·  Review ${_proposal!.items.length} changes',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perfect AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            _proposal == null
                                ? 'Ask, speak, or shape your plan'
                                : '${_proposal!.items.length} changes ready to review',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
              ),
              if (_proposal != null)
                Container(
                  key: const ValueKey<String>('perfect-ai-proposal-badge'),
                  margin: const EdgeInsetsDirectional.only(
                    end: PerfectSpace.xs,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: PerfectColors.mintSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${_proposal!.items.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PerfectColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Icon(
                widget.desktop
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.auto_awesome_rounded,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _openDock(BuildContext context, {required bool dense}) => Column(
    children: [
      _DockHeader(
        busy: _sending || _applying,
        onClose: _toggleOpen,
        onNewConversation: _sending || _applying ? null : _clearConversation,
      ),
      Expanded(
        child: widget.desktop
            ? Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: _conversation(context, dense: dense),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: PerfectSpace.sm,
                    ),
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(flex: 3, child: _contextRail(context)),
                ],
              )
            : _conversation(context, dense: dense),
      ),
      _composerBar(context),
    ],
  );

  Widget _conversation(BuildContext context, {bool dense = false}) => Column(
    children: [
      Expanded(
        child:
            _messages.isEmpty &&
                _proposal == null &&
                _error == null &&
                _historyError == null &&
                !_historyLoading &&
                !_sending
            ? _EmptyConversation(
                desktop: widget.desktop,
                dense: dense,
                onSelected: _selectSuggestion,
              )
            : ListView(
                key: const ValueKey<String>('perfect-ai-history'),
                controller: _historyScroll,
                padding: const EdgeInsets.fromLTRB(
                  PerfectSpace.md,
                  PerfectSpace.sm,
                  PerfectSpace.md,
                  PerfectSpace.sm,
                ),
                children: [
                  if (_historyLoading)
                    const _HistoryStatusBanner.loading()
                  else if (_historyError case final historyError?)
                    _HistoryStatusBanner.error(
                      retryable: historyError.retryable,
                      onRetry: historyError.retryable
                          ? () => unawaited(
                              _hydrateLatestConversation(force: true),
                            )
                          : null,
                    ),
                  for (final message in _messages)
                    _MessageBubble(message: message),
                  if (_sending) const _ThinkingBubble(),
                  if (_proposal case final proposal?)
                    _ProposalPreview(
                      proposal: proposal,
                      applying: _applying,
                      onApply: _applyProposal,
                      onDismiss: _applying ? null : _dismissProposal,
                    ),
                  if (_error case final error?)
                    _ErrorRibbon(
                      error: error,
                      onRetry: error.retryable && !_sending && !_applying
                          ? _retry
                          : null,
                      onDismiss: () => setState(() => _error = null),
                    ),
                ],
              ),
      ),
    ],
  );

  Widget _contextRail(BuildContext context) => ListView(
    padding: const EdgeInsets.all(PerfectSpace.md),
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Private planning context',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: PerfectSpace.xs),
          Text(
            'Perfect AI reads your owner-only synced plan on the server and returns a reviewable proposal.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PerfectSpace.md),
          const _ContextPromise(
            icon: Icons.calendar_view_day_rounded,
            title: 'Schedule-aware',
            detail: 'Uses existing tasks and habits',
          ),
          const _ContextPromise(
            icon: Icons.fact_check_outlined,
            title: 'Review first',
            detail: 'No planner write before Apply',
          ),
          const _ContextPromise(
            icon: Icons.lock_outline_rounded,
            title: 'Owner-only',
            detail: 'Private signed-in session',
          ),
        ],
      ),
    ],
  );

  Widget _composerBar(BuildContext context) {
    final hasInput =
        _composer.text.trim().isNotEmpty || _voiceClip != null || _recording;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        PerfectSpace.sm,
        PerfectSpace.xs,
        PerfectSpace.sm,
        PerfectSpace.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .90),
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: const ValueKey<String>('perfect-ai-voice'),
            tooltip: _recording
                ? 'Stop voice note'
                : _voiceClip == null
                ? 'Record a private voice note'
                : 'Remove voice note',
            style: IconButton.styleFrom(
              minimumSize: const Size.square(48),
              backgroundColor: _recording
                  ? Theme.of(context).colorScheme.errorContainer
                  : _voiceClip != null
                  ? PerfectColors.mintSoft
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              foregroundColor: _recording
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : PerfectColors.ink,
            ),
            onPressed: _sending || _applying
                ? null
                : _recording
                ? _stopRecording
                : _voiceClip != null
                ? _removeVoiceClip
                : _requestVoiceConsent,
            icon: Icon(
              _recording
                  ? Icons.stop_rounded
                  : _voiceClip != null
                  ? Icons.close_rounded
                  : Icons.mic_none_rounded,
            ),
          ),
          const SizedBox(width: PerfectSpace.xs),
          Expanded(
            child: TextField(
              key: const ValueKey<String>('perfect-ai-composer'),
              controller: _composer,
              focusNode: _composerFocus,
              minLines: 1,
              maxLines: widget.desktop ? 3 : 2,
              maxLength: 4000,
              enabled: !_sending && !_applying && !_recording,
              textInputAction: widget.desktop
                  ? TextInputAction.send
                  : TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              onSubmitted: widget.desktop ? (_) => _submit() : null,
              decoration: InputDecoration(
                counterText: '',
                hintMaxLines: 1,
                hintText: _recording
                    ? 'Listening… ${_formatDuration(_recordingDuration)}'
                    : _voiceClip != null
                    ? 'Voice note ready — add context if you want'
                    : largeText
                    ? 'Ask Perfect AI…'
                    : 'Ask Perfect AI to plan, explain, or reorganize…',
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: PerfectSpace.xs,
                  vertical: largeText ? 7 : 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: PerfectSpace.xs),
          if (_sending)
            IconButton(
              key: const ValueKey<String>('perfect-ai-cancel'),
              tooltip: 'Cancel answer',
              onPressed: _cancelRequest,
              icon: const Icon(Icons.stop_circle_outlined),
            )
          else
            IconButton.filled(
              key: const ValueKey<String>('perfect-ai-send'),
              tooltip: 'Send to Perfect AI',
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                backgroundColor: PerfectColors.apricot,
                foregroundColor: PerfectColors.ink,
              ),
              onPressed: !hasInput || _recording || _applying ? null : _submit,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
        ],
      ),
    );
  }

  void _toggleOpen() {
    setState(() {
      _open = !_open;
      _toggleHovered = false;
      _togglePressed = false;
    });
    if (_open) {
      if (!_historySuppressed) {
        unawaited(_hydrateLatestConversation(force: true));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.desktop) _composerFocus.requestFocus();
      });
    } else if (_recording) {
      unawaited(_cancelRecording());
    }
  }

  void _selectSuggestion(String value) {
    _composer.text = value;
    _composer.selection = TextSelection.collapsed(offset: value.length);
    setState(() {});
    _composerFocus.requestFocus();
  }

  Future<void> _submit() async {
    if (_sending || _applying || _recording) return;
    final text = _composer.text.trim();
    final clip = _voiceClip;
    if (text.isEmpty && clip == null) return;
    _lastPrompt = text;
    final operationId = _uuid.v4();
    final cancellation = PerfectAiCancellation();
    _cancellation = cancellation;
    _conversationEpoch++;
    _historySuppressed = false;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await widget.client.chat(
        PerfectAiRequest(
          operationId: operationId,
          conversationId: _conversationId,
          message: text,
          conversation: _messages.length <= 20
              ? List<PerfectAiMessage>.unmodifiable(_messages)
              : List<PerfectAiMessage>.unmodifiable(
                  _messages.sublist(_messages.length - 20),
                ),
          audio: clip,
        ),
        cancellation: cancellation,
      );
      if (!mounted || cancellation.isCancelled) return;
      final proposal = result.proposal;
      if (proposal != null && !proposal.requiresConfirmation) {
        throw const PerfectAiException(
          code: PerfectAiErrorCode.malformedResponse,
          message: 'Perfect AI returned an unsafe unconfirmed proposal.',
          retryable: true,
        );
      }
      final userText = text.isNotEmpty
          ? text
          : result.transcribedText?.trim().isNotEmpty == true
          ? result.transcribedText!.trim()
          : 'Voice note';
      setState(() {
        _conversationId = result.conversationId;
        _messages
          ..add(
            PerfectAiMessage(
              id: _derivedMessageId(operationId, 0xa0),
              role: PerfectAiRole.user,
              text: userText,
              createdAt: DateTime.now().toUtc(),
            ),
          )
          ..add(result.message);
        _proposal = proposal;
        _composer.clear();
        _voiceClip = null;
      });
      _scrollToLatest();
    } on PerfectAiException catch (error) {
      if (!mounted || error.code == PerfectAiErrorCode.cancelled) return;
      setState(() => _error = error);
      _scrollToLatest();
    } on Object {
      if (!mounted) return;
      setState(
        () => _error = const PerfectAiException(
          code: PerfectAiErrorCode.unknown,
          message: 'Perfect AI hit an unexpected problem.',
          retryable: true,
        ),
      );
      _scrollToLatest();
    } finally {
      if (mounted && identical(_cancellation, cancellation)) {
        setState(() {
          _sending = false;
          _cancellation = null;
        });
      }
    }
  }

  void _cancelRequest() {
    _cancellation?.cancel();
    setState(() {
      _sending = false;
      _cancellation = null;
      _error = null;
    });
  }

  void _retry() {
    final lastPrompt = _lastPrompt;
    if (_composer.text.trim().isEmpty && lastPrompt != null) {
      _composer.text = lastPrompt;
      _composer.selection = TextSelection.collapsed(offset: lastPrompt.length);
    }
    unawaited(_submit());
  }

  Future<void> _applyProposal() async {
    final proposal = _proposal;
    if (proposal == null || _applying || _sending) return;
    final cancellation = PerfectAiCancellation();
    _cancellation = cancellation;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      final result = await widget.client.applyProposal(
        operationId: _uuid.v4(),
        conversationId: _conversationId,
        proposal: proposal,
        cancellation: cancellation,
      );
      if (!mounted || cancellation.isCancelled) return;
      if (result.message != null) _messages.add(result.message!);
      setState(() => _proposal = null);
      await widget.onProposalApplied();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.appliedCount} planner change${result.appliedCount == 1 ? '' : 's'} added. Sync is refreshing.',
          ),
        ),
      );
      _scrollToLatest();
    } on PerfectAiException catch (error) {
      if (!mounted || error.code == PerfectAiErrorCode.cancelled) return;
      setState(() => _error = error);
    } on Object {
      if (!mounted) return;
      setState(
        () => _error = const PerfectAiException(
          code: PerfectAiErrorCode.unknown,
          message: 'The proposal is still safe. Applying it failed.',
          retryable: true,
        ),
      );
    } finally {
      if (mounted && identical(_cancellation, cancellation)) {
        setState(() {
          _applying = false;
          _cancellation = null;
        });
      }
    }
  }

  void _dismissProposal() => setState(() => _proposal = null);

  void _clearConversation() {
    _historyCancellation?.cancel();
    _historyCancellation = null;
    _conversationEpoch++;
    _historySuppressed = true;
    setState(() {
      _messages.clear();
      _proposal = null;
      _error = null;
      _conversationId = null;
      _lastPrompt = null;
      _composer.clear();
      _voiceClip = null;
      _historyLoading = false;
      _historyAttempted = true;
      _historyError = null;
    });
  }

  Future<void> _hydrateLatestConversation({bool force = false}) async {
    final historyClient = widget.client is PerfectAiHistoryClient
        ? widget.client as PerfectAiHistoryClient
        : null;
    if (historyClient == null) {
      _historyAttempted = true;
      return;
    }
    if (_historyLoading || (_historyAttempted && !force)) return;

    final cancellation = PerfectAiCancellation();
    final epoch = _conversationEpoch;
    _historyCancellation?.cancel();
    _historyCancellation = cancellation;
    if (mounted) {
      setState(() {
        _historyLoading = true;
        _historyAttempted = true;
        _historyError = null;
      });
    }
    try {
      final snapshot = await historyClient.loadLatestConversation(
        cancellation: cancellation,
      );
      if (!mounted || cancellation.isCancelled || epoch != _conversationEpoch) {
        return;
      }
      setState(() {
        if (snapshot != null &&
            (_conversationId == null ||
                _conversationId == snapshot.conversationId)) {
          _conversationId = snapshot.conversationId;
          _mergeHydratedMessages(snapshot.messages);
          if (_proposal == null && !_sending && !_applying) {
            _proposal = snapshot.pendingProposal;
          }
        }
        _historyError = null;
      });
      if (snapshot != null && snapshot.messages.isNotEmpty) {
        _scrollToLatest();
      }
    } on PerfectAiException catch (error) {
      if (!mounted ||
          cancellation.isCancelled ||
          error.code == PerfectAiErrorCode.cancelled ||
          epoch != _conversationEpoch) {
        return;
      }
      setState(() => _historyError = error);
    } on Object {
      if (!mounted || cancellation.isCancelled || epoch != _conversationEpoch) {
        return;
      }
      setState(
        () => _historyError = const PerfectAiException(
          code: PerfectAiErrorCode.unavailable,
          message: 'Perfect AI history is temporarily unavailable.',
          retryable: true,
        ),
      );
    } finally {
      if (mounted && identical(_historyCancellation, cancellation)) {
        setState(() {
          _historyLoading = false;
          _historyCancellation = null;
        });
      }
    }
  }

  void _mergeHydratedMessages(List<PerfectAiMessage> remote) {
    final merged = <String, PerfectAiMessage>{
      for (final message in _messages) message.id: message,
      for (final message in remote) message.id: message,
    };
    final ordered = merged.values.toList()..sort(_compareAiMessages);
    final remoteMessages = remote.toSet();
    final deduplicated = <PerfectAiMessage>[];
    for (final message in ordered) {
      final duplicateIndex = deduplicated.indexWhere(
        (existing) =>
            (message.id.startsWith('local-') ||
                existing.id.startsWith('local-')) &&
            existing.role == message.role &&
            existing.text == message.text &&
            existing.createdAt.difference(message.createdAt).abs() <=
                const Duration(minutes: 2),
      );
      if (duplicateIndex < 0) {
        deduplicated.add(message);
      } else if (remoteMessages.contains(message)) {
        deduplicated[duplicateIndex] = message;
      }
    }
    _messages
      ..clear()
      ..addAll(deduplicated);
  }

  Future<void> _requestVoiceConsent() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a voice note?'),
        content: const Text(
          'Perfect records only after you confirm. The temporary audio is sent through your private signed-in session, then removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            key: const ValueKey<String>('perfect-ai-consent-start'),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Start recording'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        throw const PerfectAiException(
          code: PerfectAiErrorCode.unauthorized,
          message: 'Microphone permission is needed for voice notes.',
          retryable: false,
        );
      }
      await _recorder.start();
      if (!mounted) {
        await _recorder.cancel();
        return;
      }
      _recordingTimer?.cancel();
      setState(() {
        _recording = true;
        _recordingDuration = Duration.zero;
        _error = null;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_recording) {
          timer.cancel();
          return;
        }
        final next = Duration(seconds: timer.tick);
        if (next >= _maxVoiceDuration) {
          unawaited(_stopRecording());
        } else {
          setState(() => _recordingDuration = next);
        }
      });
    } on PerfectAiException catch (error) {
      if (mounted) setState(() => _error = error);
    } on Object {
      if (mounted) {
        setState(
          () => _error = const PerfectAiException(
            code: PerfectAiErrorCode.unavailable,
            message: 'The microphone could not start on this device.',
            retryable: true,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() => _recording = false);
    try {
      final clip = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _voiceClip = clip;
        _recordingDuration = Duration.zero;
      });
    } on PerfectAiException catch (error) {
      if (mounted) setState(() => _error = error);
    } on Object {
      if (mounted) {
        setState(
          () => _error = const PerfectAiException(
            code: PerfectAiErrorCode.unavailable,
            message: 'The voice note could not be prepared.',
            retryable: true,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (mounted) {
      setState(() {
        _recording = false;
        _recordingDuration = Duration.zero;
      });
    }
    await _recorder.cancel();
  }

  void _removeVoiceClip() => setState(() => _voiceClip = null);

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_historyScroll.hasClients) return;
      _historyScroll.animateTo(
        _historyScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

int _compareAiMessages(PerfectAiMessage left, PerfectAiMessage right) {
  final timestamp = left.createdAt.compareTo(right.createdAt);
  return timestamp != 0 ? timestamp : left.id.compareTo(right.id);
}

String _derivedMessageId(String operationId, int discriminator) {
  final compact = operationId.replaceAll('-', '').toLowerCase();
  if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(compact)) {
    return 'local-$operationId';
  }
  final bytes = <int>[
    for (var index = 0; index < 16; index++)
      int.parse(compact.substring(index * 2, index * 2 + 2), radix: 16),
  ];
  bytes[15] ^= discriminator;
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

class _ContextPromise extends StatelessWidget {
  const _ContextPromise({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PerfectSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(width: PerfectSpace.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                detail,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DockHeader extends StatelessWidget {
  const _DockHeader({
    required this.busy,
    required this.onClose,
    required this.onNewConversation,
  });

  final bool busy;
  final VoidCallback onClose;
  final VoidCallback? onNewConversation;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 2),
      child: Row(
        children: [
          _BrandPulse(active: busy),
          const SizedBox(width: PerfectSpace.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfect AI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!largeText)
                  Text(
                    busy
                        ? 'Shaping your request…'
                        : 'Aware of your synced plan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'New AI conversation',
            onPressed: onNewConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            key: const ValueKey<String>('perfect-ai-close'),
            tooltip: 'Close Perfect AI',
            onPressed: onClose,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }
}

class _BrandPulse extends StatelessWidget {
  const _BrandPulse({required this.active, this.compact = false});

  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: PerfectMotion.responsive(context, PerfectMotion.standard),
    width: compact ? 40 : 46,
    height: compact ? 40 : 46,
    padding: EdgeInsets.all(compact ? 5 : 6),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: active ? PerfectColors.apricot : PerfectColors.lilac,
        width: active ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (active ? PerfectColors.apricot : PerfectColors.lilac)
              .withValues(alpha: .18),
          blurRadius: active ? 18 : 8,
        ),
      ],
    ),
    child: Semantics(
      image: true,
      label: 'Perfect Day Compass',
      child: const ExcludeSemantics(child: _BrandAsset()),
    ),
  );
}

class _BrandAsset extends StatelessWidget {
  const _BrandAsset();

  @override
  Widget build(BuildContext context) {
    final fallback = Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.explore_rounded,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: PerfectColors.apricot,
            ),
          ),
        ),
      ],
    );
    return Image.asset(
      'assets/brand/perfect-launcher.png',
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          wasSynchronouslyLoaded || frame != null ? child : fallback,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({
    required this.desktop,
    required this.dense,
    required this.onSelected,
  });

  final bool desktop;
  final bool dense;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compactHeight = dense || constraints.maxHeight < 260;
      final horizontalPaths =
          constraints.maxWidth >= 560 && constraints.maxHeight >= 150;
      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          compactHeight ? PerfectSpace.sm : PerfectSpace.md,
          compactHeight ? PerfectSpace.xxs : PerfectSpace.sm,
          compactHeight ? PerfectSpace.sm : PerfectSpace.md,
          compactHeight ? PerfectSpace.xxs : PerfectSpace.md,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!compactHeight) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BrandPulse(active: false, compact: true),
                  const SizedBox(width: PerfectSpace.sm),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose a starting path',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Perfect AI turns it into a reviewable plan.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PerfectSpace.sm),
            ],
            Flexible(
              child: _StarterPaths(
                horizontal: horizontalPaths,
                compact: compactHeight,
                desktop: desktop,
                onSelected: onSelected,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StarterPaths extends StatelessWidget {
  const _StarterPaths({
    required this.horizontal,
    required this.compact,
    required this.desktop,
    required this.onSelected,
  });

  final bool horizontal;
  final bool compact;
  final bool desktop;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return ListView.separated(
        key: const ValueKey<String>('perfect-ai-starter-paths'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _starterPaths.length,
        separatorBuilder: (_, _) => const SizedBox(width: PerfectSpace.xs),
        itemBuilder: (context, index) => SizedBox(
          width: desktop ? 190 : 152,
          child: _StarterPathTile(
            data: _starterPaths[index],
            compact: true,
            onSelected: onSelected,
          ),
        ),
      );
    }

    if (horizontal) {
      return Row(
        key: const ValueKey<String>('perfect-ai-starter-paths'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _starterPaths.length; index++) ...[
            Expanded(
              child: _StarterPathTile(
                data: _starterPaths[index],
                onSelected: onSelected,
              ),
            ),
            if (index != _starterPaths.length - 1)
              const SizedBox(width: PerfectSpace.xs),
          ],
        ],
      );
    }

    return Column(
      key: const ValueKey<String>('perfect-ai-starter-paths'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < _starterPaths.length; index++) ...[
          _StarterPathTile(
            data: _starterPaths[index],
            compact: true,
            onSelected: onSelected,
          ),
          if (index != _starterPaths.length - 1)
            const SizedBox(height: PerfectSpace.xs),
        ],
      ],
    );
  }
}

class _StarterPathTile extends StatefulWidget {
  const _StarterPathTile({
    required this.data,
    required this.onSelected,
    this.compact = false,
  });

  final _StarterPathData data;
  final ValueChanged<String> onSelected;
  final bool compact;

  @override
  State<_StarterPathTile> createState() => _StarterPathTileState();
}

class _StarterPathTileState extends State<_StarterPathTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = switch (widget.data.zone) {
      _StarterZone.plan => (
        fill: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        accent: scheme.primary,
      ),
      _StarterZone.habit => (
        fill: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        accent: scheme.secondary,
      ),
      _StarterZone.rebalance => (
        fill: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        accent: scheme.tertiary,
      ),
    };
    final duration = PerfectMotion.responsive(context, PerfectMotion.quick);
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: widget.compact ? 32 : 38,
          height: widget.compact ? 32 : 38,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: .17),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.data.icon,
            size: widget.compact ? 18 : 20,
            color: colors.foreground,
          ),
        ),
        const SizedBox(width: PerfectSpace.xs),
        Expanded(
          child: widget.compact
              ? Text(
                  widget.data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.data.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.foreground.withValues(alpha: .76),
                      ),
                    ),
                  ],
                ),
        ),
        Icon(Icons.arrow_forward_rounded, size: 17, color: colors.foreground),
      ],
    );

    return Semantics(
      button: true,
      label: '${widget.data.title}. ${widget.data.detail}',
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: duration,
        curve: PerfectMotion.productive,
        child: AnimatedContainer(
          key: ValueKey<String>('${widget.data.keyName}-zone'),
          duration: duration,
          curve: PerfectMotion.productive,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.surface.withValues(alpha: _hovered ? .12 : 0),
              colors.fill,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focused
                  ? colors.accent
                  : colors.accent.withValues(alpha: .26),
              width: _focused ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: .13),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey<String>(widget.data.keyName),
              onTap: () => widget.onSelected(widget.data.prompt),
              onHover: (value) => setState(() => _hovered = value),
              onFocusChange: (value) => setState(() => _focused = value),
              onHighlightChanged: (value) => setState(() => _pressed = value),
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: PerfectSpace.sm,
                  vertical: widget.compact ? PerfectSpace.xs : PerfectSpace.sm,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StarterZone { plan, habit, rebalance }

@immutable
class _StarterPathData {
  const _StarterPathData({
    required this.keyName,
    required this.zone,
    required this.icon,
    required this.prompt,
    required this.title,
    required this.detail,
  });

  final String keyName;
  final _StarterZone zone;
  final IconData icon;
  final String prompt;
  final String title;
  final String detail;
}

const _starterPaths = <_StarterPathData>[
  _StarterPathData(
    keyName: 'perfect-ai-starter-plan',
    zone: _StarterZone.plan,
    icon: Icons.wb_sunny_outlined,
    prompt: 'Plan my day around the commitments already in Perfect.',
    title: 'Plan my day',
    detail: 'Shape today around what already matters',
  ),
  _StarterPathData(
    keyName: 'perfect-ai-starter-habit',
    zone: _StarterZone.habit,
    icon: Icons.eco_outlined,
    prompt: 'Create a realistic habit for me and suggest a flexible schedule.',
    title: 'Create a habit',
    detail: 'Build a flexible rhythm I can keep',
  ),
  _StarterPathData(
    keyName: 'perfect-ai-starter-rebalance',
    zone: _StarterZone.rebalance,
    icon: Icons.tune_rounded,
    prompt: 'Rebalance this week without deleting any existing plans.',
    title: 'Rebalance my week',
    detail: 'Move pressure without losing commitments',
  ),
];

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final PerfectAiMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == PerfectAiRole.user;
    return Align(
      alignment: user
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.only(bottom: PerfectSpace.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: PerfectSpace.md,
          vertical: PerfectSpace.sm,
        ),
        decoration: BoxDecoration(
          color: user
              ? PerfectColors.apricotSoft
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(20),
            topEnd: const Radius.circular(20),
            bottomStart: Radius.circular(user ? 20 : 6),
            bottomEnd: Radius.circular(user ? 6 : 20),
          ),
        ),
        child: SelectableText(
          message.text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: PerfectColors.ink),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      key: const ValueKey<String>('perfect-ai-thinking'),
      margin: const EdgeInsets.only(bottom: PerfectSpace.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: PerfectSpace.md,
        vertical: PerfectSpace.sm,
      ),
      decoration: BoxDecoration(
        color: PerfectColors.lilacSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox(
        width: 54,
        child: LinearProgressIndicator(minHeight: 3),
      ),
    ),
  );
}

class _HistoryStatusBanner extends StatelessWidget {
  const _HistoryStatusBanner.loading()
    : loading = true,
      retryable = false,
      onRetry = null;

  const _HistoryStatusBanner.error({
    required this.retryable,
    required this.onRetry,
  }) : loading = false;

  final bool loading;
  final bool retryable;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey<String>(
        loading ? 'perfect-ai-history-loading' : 'perfect-ai-history-error',
      ),
      margin: const EdgeInsets.only(bottom: PerfectSpace.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: PerfectSpace.sm,
        vertical: PerfectSpace.xs,
      ),
      decoration: BoxDecoration(
        color: loading
            ? scheme.surfaceContainerHigh
            : scheme.errorContainer.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.cloud_off_rounded,
              size: 18,
              color: scheme.onErrorContainer,
            ),
          const SizedBox(width: PerfectSpace.sm),
          Expanded(
            child: Text(
              loading
                  ? 'Syncing your AI conversation…'
                  : 'Synced history is unavailable. You can still start a new chat.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: loading
                    ? scheme.onSurfaceVariant
                    : scheme.onErrorContainer,
              ),
            ),
          ),
          if (!loading && retryable)
            TextButton(
              key: const ValueKey<String>('perfect-ai-history-retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _ProposalPreview extends StatelessWidget {
  const _ProposalPreview({
    required this.proposal,
    required this.applying,
    required this.onApply,
    required this.onDismiss,
  });

  final PerfectAiProposal proposal;
  final bool applying;
  final VoidCallback onApply;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('perfect-ai-proposal'),
    margin: const EdgeInsets.only(top: PerfectSpace.xs),
    padding: const EdgeInsets.all(PerfectSpace.md),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          PerfectColors.mintSoft,
          PerfectColors.lilacSoft.withValues(alpha: .72),
        ],
      ),
      borderRadius: const BorderRadiusDirectional.only(
        topStart: Radius.circular(8),
        topEnd: Radius.circular(26),
        bottomStart: Radius.circular(26),
        bottomEnd: Radius.circular(26),
      ),
      border: Border.all(color: PerfectColors.mint.withValues(alpha: .7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fact_check_outlined, size: 20),
            const SizedBox(width: PerfectSpace.xs),
            Expanded(
              child: Text(
                proposal.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${proposal.items.length} changes',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        if (proposal.summary.isNotEmpty) ...[
          const SizedBox(height: PerfectSpace.xxs),
          Text(
            proposal.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: PerfectSpace.xs),
        for (final item in proposal.items.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: PerfectSpace.xxs),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded, size: 16),
                const SizedBox(width: PerfectSpace.xs),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Text(item.kind, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        if (proposal.items.length > 3)
          Text(
            '+ ${proposal.items.length - 3} more',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        const SizedBox(height: PerfectSpace.sm),
        Wrap(
          alignment: WrapAlignment.end,
          runAlignment: WrapAlignment.end,
          spacing: PerfectSpace.xs,
          runSpacing: PerfectSpace.xxs,
          children: [
            TextButton(
              key: const ValueKey<String>('perfect-ai-dismiss-proposal'),
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
            FilledButton.icon(
              key: const ValueKey<String>('perfect-ai-apply-proposal'),
              onPressed: applying ? null : onApply,
              icon: applying
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all_rounded),
              label: const Text('Apply to Perfect'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ErrorRibbon extends StatelessWidget {
  const _ErrorRibbon({
    required this.error,
    required this.onRetry,
    required this.onDismiss,
  });

  final PerfectAiException error;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('perfect-ai-error'),
    margin: const EdgeInsets.only(top: PerfectSpace.xs),
    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: PerfectSpace.xs),
        Expanded(
          child: Text(
            error.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        IconButton(
          tooltip: 'Dismiss error',
          onPressed: onDismiss,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${duration.inMinutes}:$seconds';
}
