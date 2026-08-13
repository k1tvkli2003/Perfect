import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';

enum PerfectSyncVisualState { current, flowing, error }

class PerfectSyncIndicator extends StatefulWidget {
  const PerfectSyncIndicator({
    super.key,
    required this.status,
    required this.onRetry,
    this.compact = false,
    this.now = DateTime.now,
  });

  final PlannerSyncStatus status;
  final Future<void> Function() onRetry;
  final bool compact;
  final DateTime Function() now;

  @override
  State<PerfectSyncIndicator> createState() => _PerfectSyncIndicatorState();
}

class _PerfectSyncIndicatorState extends State<PerfectSyncIndicator>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Perfect sync indicator');
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: PerfectMotion.calmLoop,
  );
  Timer? _countdownTimer;
  int? _retrySeconds;
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshCountdown();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _refreshCountdown();
    } else {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
    _updateFlow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFlow();
  }

  @override
  void didUpdateWidget(covariant PerfectSyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFlow();
    if (oldWidget.status.nextRetryAt != widget.status.nextRetryAt ||
        oldWidget.now != widget.now) {
      _refreshCountdown();
    }
  }

  void _updateFlow() {
    final shouldFlow =
        _visual.state == PerfectSyncVisualState.flowing &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        _foreground;
    if (shouldFlow && !_flow.isAnimating) {
      _flow.repeat();
    } else if (!shouldFlow && (_flow.isAnimating || _flow.value != 0)) {
      _flow
        ..stop()
        ..value = 0;
    }
  }

  void _refreshCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _readCountdown();
    if (widget.status.nextRetryAt != null && (_retrySeconds ?? 0) > 0) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _readCountdown(),
      );
    }
  }

  void _readCountdown() {
    final deadline = widget.status.nextRetryAt;
    final next = deadline == null
        ? null
        : math.max(
            0,
            deadline.toUtc().difference(widget.now().toUtc()).inSeconds,
          );
    if (_retrySeconds == next) return;
    if (mounted) {
      setState(() => _retrySeconds = next);
    } else {
      _retrySeconds = next;
    }
    if (next == 0) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _flow.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _SyncVisual get _visual => switch (widget.status.phase) {
    PlannerSyncPhase.idle => const _SyncVisual(
      state: PerfectSyncVisualState.current,
      label: 'Synced',
      detail:
          'All durable planner changes are synced across your Perfect devices.',
      color: PerfectColors.sync,
    ),
    PlannerSyncPhase.syncing => const _SyncVisual(
      state: PerfectSyncVisualState.flowing,
      label: 'Syncing',
      detail: 'Perfect is sending or receiving durable changes now.',
      color: PerfectColors.apricot,
    ),
    PlannerSyncPhase.offline => const _SyncVisual(
      state: PerfectSyncVisualState.flowing,
      label: 'Retrying',
      detail:
          'Changes are safe on this device. Automatic sync will retry with bounded backoff.',
      color: PerfectColors.apricot,
    ),
    PlannerSyncPhase.needsAttention => const _SyncVisual(
      state: PerfectSyncVisualState.error,
      label: 'Sync issue',
      detail:
          'The last sync did not finish. Local planning remains available while Perfect retries.',
      color: PerfectColors.danger,
    ),
  };

  String get _surfaceLabel {
    if (widget.status.phase != PlannerSyncPhase.offline ||
        _retrySeconds == null ||
        _retrySeconds! <= 0) {
      return _visual.label;
    }
    return 'Retry ${_retrySeconds}s';
  }

  String get _retryDetail {
    final seconds = _retrySeconds;
    if (seconds == null) return '';
    if (seconds <= 0) return 'Automatic retry is due now.';
    return 'Automatic retry in $seconds ${seconds == 1 ? 'second' : 'seconds'}.';
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final radius = BorderRadius.circular(19);
    final surfaceAlpha = highContrast
        ? .16
        : _pressed
        ? .14
        : _hovered
        ? .095
        : .055;
    final borderColor = _focused
        ? scheme.primary
        : visual.color.withValues(alpha: highContrast ? .82 : .32);
    final scale = reduceMotion || !_pressed ? 1.0 : .975;
    final semanticRetry = _retryDetail;
    return Tooltip(
      message:
          '${visual.label}\n${visual.detail}${semanticRetry.isEmpty ? '' : '\n$semanticRetry'}',
      child: Semantics(
        button: true,
        liveRegion: true,
        label:
            'Sync status: ${visual.label}. ${visual.detail}${semanticRetry.isEmpty ? '' : ' $semanticRetry'}',
        hint: 'Open sync details or start a safe retry.',
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: PerfectMotion.responsive(context, PerfectMotion.quick),
            curve: PerfectMotion.productive,
            tween: Tween<double>(end: scale),
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: AnimatedContainer(
              key: const ValueKey<String>('perfect-sync-surface'),
              duration: PerfectMotion.responsive(
                context,
                PerfectMotion.standard,
              ),
              curve: PerfectMotion.productive,
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: surfaceAlpha),
                borderRadius: radius,
                border: Border.all(
                  color: borderColor,
                  width: highContrast ? 2 : 1,
                ),
                boxShadow: _hovered && !reduceMotion
                    ? <BoxShadow>[
                        BoxShadow(
                          color: visual.color.withValues(alpha: .13),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const ValueKey<String>('perfect-sync-indicator'),
                  borderRadius: radius,
                  onTap: () => _showDetails(context),
                  mouseCursor: SystemMouseCursors.click,
                  canRequestFocus: true,
                  focusNode: _focusNode,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: visual.color.withValues(alpha: .14),
                  onHover: (value) => _setInteraction(hovered: value),
                  onFocusChange: (value) => _setInteraction(focused: value),
                  onHighlightChanged: (value) =>
                      _setInteraction(pressed: value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        widget.compact ? 8 : 10,
                        5,
                        widget.compact ? 9 : 12,
                        5,
                      ),
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SyncCloudMark(
                              phase: widget.status.phase,
                              visual: visual,
                              flow: _flow,
                              size: widget.compact ? 27 : 31,
                            ),
                            const SizedBox(width: 6),
                            AnimatedSwitcher(
                              duration: PerfectMotion.responsive(
                                context,
                                PerfectMotion.quick,
                              ),
                              switchInCurve: PerfectMotion.enter,
                              switchOutCurve: PerfectMotion.exit,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, .18),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                _surfaceLabel,
                                key: ValueKey<String>(_surfaceLabel),
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: visual.color,
                                      fontSize: widget.compact ? 11.5 : 12.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.1,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setInteraction({bool? hovered, bool? focused, bool? pressed}) {
    final nextHovered = hovered ?? _hovered;
    final nextFocused = focused ?? _focused;
    final nextPressed = pressed ?? _pressed;
    if (nextHovered == _hovered &&
        nextFocused == _focused &&
        nextPressed == _pressed) {
      return;
    }
    setState(() {
      _hovered = nextHovered;
      _focused = nextFocused;
      _pressed = nextPressed;
    });
  }

  Future<void> _showDetails(BuildContext context) async {
    final compactSheet = MediaQuery.sizeOf(context).width < 680;
    if (compactSheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        sheetAnimationStyle: PerfectMotion.modalSheetStyle(context),
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (sheetContext) => _SyncDetailsContent(
          status: widget.status,
          visual: _visual,
          flow: _flow,
          retryDetail: _retryDetail,
          onRetry: widget.onRetry,
          onClose: () => Navigator.pop(sheetContext),
        ),
      );
      return;
    }
    await showPerfectDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: _SyncDetailsContent(
            status: widget.status,
            visual: _visual,
            flow: _flow,
            retryDetail: _retryDetail,
            onRetry: widget.onRetry,
            onClose: () => Navigator.pop(dialogContext),
          ),
        ),
      ),
    );
  }
}

class _SyncDetailsContent extends StatefulWidget {
  const _SyncDetailsContent({
    required this.status,
    required this.visual,
    required this.flow,
    required this.retryDetail,
    required this.onRetry,
    required this.onClose,
  });

  final PlannerSyncStatus status;
  final _SyncVisual visual;
  final Animation<double> flow;
  final String retryDetail;
  final Future<void> Function() onRetry;
  final VoidCallback onClose;

  @override
  State<_SyncDetailsContent> createState() => _SyncDetailsContentState();
}

class _SyncDetailsContentState extends State<_SyncDetailsContent> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    final localFirstNotice = widget.status.phase != PlannerSyncPhase.idle;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PerfectSpace.lg,
        PerfectSpace.sm,
        PerfectSpace.lg,
        PerfectSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SyncCloudMark(
                phase: widget.status.phase,
                visual: widget.visual,
                flow: widget.flow,
                size: 44,
              ),
              const SizedBox(width: PerfectSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.visual.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Database confidence',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close sync details',
                onPressed: _retrying ? null : widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: PerfectSpace.md),
          Text(widget.visual.detail),
          if (widget.retryDetail.isNotEmpty) ...[
            const SizedBox(height: PerfectSpace.sm),
            Text(
              widget.retryDetail,
              key: const ValueKey<String>('perfect-sync-retry-countdown'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: widget.visual.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (widget.status.lastSuccessfulSyncAt case final syncedAt?) ...[
            const SizedBox(height: PerfectSpace.sm),
            Text(
              'Last completed: ${PerfectLocalTime.syncStamp(syncedAt)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (localFirstNotice) ...[
            const SizedBox(height: PerfectSpace.md),
            Container(
              padding: const EdgeInsets.all(PerfectSpace.sm),
              decoration: BoxDecoration(
                color: PerfectColors.mintSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PerfectColors.mint.withValues(alpha: .28),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_pin_rounded, size: 19),
                  SizedBox(width: PerfectSpace.xs),
                  Expanded(
                    child: Text(
                      'Local-first mode stays available and your queued changes remain durable.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: PerfectSpace.lg),
          FilledButton.icon(
            key: const ValueKey<String>('perfect-sync-retry-now'),
            onPressed: _retrying
                ? null
                : () async {
                    setState(() => _retrying = true);
                    await widget.onRetry();
                    if (mounted) widget.onClose();
                  },
            icon: _retrying
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(
              widget.visual.state == PerfectSyncVisualState.current
                  ? 'Sync now'
                  : 'Retry safely now',
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncVisual {
  const _SyncVisual({
    required this.state,
    required this.label,
    required this.detail,
    required this.color,
  });

  final PerfectSyncVisualState state;
  final String label;
  final String detail;
  final Color color;
}

class _SyncCloudMark extends StatelessWidget {
  const _SyncCloudMark({
    required this.phase,
    required this.visual,
    required this.flow,
    this.size = 36,
  });

  final PlannerSyncPhase phase;
  final _SyncVisual visual;
  final Animation<double> flow;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    key: ValueKey<String>('perfect-sync-mark-${phase.name}'),
    dimension: size,
    child: AnimatedBuilder(
      animation: flow,
      builder: (context, child) => CustomPaint(
        key: const ValueKey<String>('perfect-sync-cloud-artwork'),
        painter: _SyncCloudPainter(
          color: visual.color,
          state: visual.state,
          progress: flow.value,
          highContrast: MediaQuery.highContrastOf(context),
        ),
      ),
    ),
  );
}

class _SyncCloudPainter extends CustomPainter {
  const _SyncCloudPainter({
    required this.color,
    required this.state,
    required this.progress,
    required this.highContrast,
  });

  final Color color;
  final PerfectSyncVisualState state;
  final double progress;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(1.8, size.shortestSide * .07);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? stroke * 1.25 : stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final cloud = Path()
      ..moveTo(size.width * .26, size.height * .77)
      ..cubicTo(
        size.width * .11,
        size.height * .77,
        size.width * .08,
        size.height * .59,
        size.width * .18,
        size.height * .50,
      )
      ..cubicTo(
        size.width * .18,
        size.height * .31,
        size.width * .36,
        size.height * .19,
        size.width * .53,
        size.height * .28,
      )
      ..cubicTo(
        size.width * .66,
        size.height * .22,
        size.width * .82,
        size.height * .31,
        size.width * .83,
        size.height * .47,
      )
      ..cubicTo(
        size.width * .96,
        size.height * .52,
        size.width * .94,
        size.height * .75,
        size.width * .78,
        size.height * .77,
      )
      ..lineTo(size.width * .26, size.height * .77);
    canvas.drawPath(cloud, paint);

    switch (state) {
      case PerfectSyncVisualState.current:
        final check = Path()
          ..moveTo(size.width * .39, size.height * .56)
          ..lineTo(size.width * .49, size.height * .65)
          ..lineTo(size.width * .67, size.height * .46);
        canvas.drawPath(check, paint..strokeWidth = stroke * .9);
        break;
      case PerfectSyncVisualState.error:
        canvas.drawLine(
          Offset(size.width * .52, size.height * .44),
          Offset(size.width * .52, size.height * .61),
          paint..strokeWidth = stroke * .92,
        );
        canvas.drawCircle(
          Offset(size.width * .52, size.height * .69),
          stroke * .34,
          Paint()..color = color,
        );
        break;
      case PerfectSyncVisualState.flowing:
        final angle = (progress * math.pi * 2) - (math.pi / 2);
        final center = Offset(size.width * .77, size.height * .30);
        final radius = size.shortestSide * .13;
        final orbit = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * .48
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: .42);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -.35,
          math.pi * 1.4,
          false,
          orbit,
        );
        canvas.drawCircle(
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
          stroke * .58,
          Paint()..color = color,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SyncCloudPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.state != state ||
      oldDelegate.progress != progress ||
      oldDelegate.highContrast != highContrast;
}
