import 'package:flutter/material.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_theme.dart';

enum PerfectSyncVisualState { current, flowing, error }

class PerfectSyncIndicator extends StatefulWidget {
  const PerfectSyncIndicator({
    super.key,
    required this.status,
    required this.onRetry,
    this.compact = false,
  });

  final PlannerSyncStatus status;
  final Future<void> Function() onRetry;
  final bool compact;

  @override
  State<PerfectSyncIndicator> createState() => _PerfectSyncIndicatorState();
}

class _PerfectSyncIndicatorState extends State<PerfectSyncIndicator>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Perfect sync indicator');
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFlow();
  }

  @override
  void didUpdateWidget(covariant PerfectSyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFlow();
  }

  void _updateFlow() {
    final shouldFlow =
        _visual.state == PerfectSyncVisualState.flowing &&
        !MediaQuery.disableAnimationsOf(context);
    if (shouldFlow && !_flow.isAnimating) {
      _flow.repeat();
    } else if (!shouldFlow && _flow.isAnimating) {
      _flow
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _SyncVisual get _visual => switch (widget.status.phase) {
    PlannerSyncPhase.idle => const _SyncVisual(
      state: PerfectSyncVisualState.current,
      statusIcon: Icons.check_rounded,
      label: 'Synced',
      detail: 'All local changes are synced across your Perfect devices.',
      color: PerfectColors.sync,
    ),
    PlannerSyncPhase.syncing => const _SyncVisual(
      state: PerfectSyncVisualState.flowing,
      statusIcon: Icons.sync_rounded,
      label: 'Syncing',
      detail: 'Perfect is sending or receiving changes now.',
      color: PerfectColors.apricot,
    ),
    PlannerSyncPhase.offline => const _SyncVisual(
      state: PerfectSyncVisualState.flowing,
      statusIcon: Icons.replay_rounded,
      label: 'Retrying',
      detail:
          'Changes are safe on this device. Automatic sync will retry when the connection is ready.',
      color: PerfectColors.apricot,
    ),
    PlannerSyncPhase.needsAttention => const _SyncVisual(
      state: PerfectSyncVisualState.error,
      statusIcon: Icons.priority_high_rounded,
      label: 'Sync issue',
      detail:
          'The last sync did not finish. Local planning still works and your changes remain on this device.',
      color: PerfectColors.danger,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(20);
    // The compact header reference is deliberately calm: status is a cloud
    // and a word, not a second pill competing with the product mark.
    final surface = _pressed
        ? visual.color.withValues(alpha: .12)
        : _hovered
        ? visual.color.withValues(alpha: .07)
        : Colors.transparent;
    final border = _focused ? scheme.primary : Colors.transparent;
    final scale = reduceMotion || !_pressed ? 1.0 : .975;
    return Tooltip(
      message: '${visual.label}\n${visual.detail}',
      child: Semantics(
        button: true,
        liveRegion: true,
        label: 'Sync status: ${visual.label}. ${visual.detail}',
        hint: 'Open sync details and retry.',
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
                color: surface,
                borderRadius: radius,
                border: Border.all(color: border, width: 1),
                boxShadow: _hovered && !reduceMotion
                    ? <BoxShadow>[
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: .09),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
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
                  splashColor: visual.color.withValues(alpha: .12),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 0 : PerfectSpace.xs,
                        vertical: PerfectSpace.xxs,
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
                              size: widget.compact ? 28 : 32,
                            ),
                            const SizedBox(width: PerfectSpace.xs),
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
                                    child: child,
                                  ),
                              child: Text(
                                visual.label,
                                key: ValueKey<PlannerSyncPhase>(
                                  widget.status.phase,
                                ),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: visual.color,
                                      fontSize: widget.compact ? 12 : null,
                                      fontWeight: FontWeight.w600,
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
    final visual = _visual;
    var retrying = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              _SyncCloudMark(
                phase: widget.status.phase,
                visual: visual,
                flow: _flow,
                size: 40,
              ),
              const SizedBox(width: PerfectSpace.sm),
              Expanded(child: Text(visual.label)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visual.detail),
                if (widget.status.lastSuccessfulSyncAt
                    case final syncedAt?) ...[
                  const SizedBox(height: PerfectSpace.md),
                  Text(
                    'Last completed sync: ${_formatSyncTime(syncedAt.toLocal())}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (visual.state == PerfectSyncVisualState.error) ...[
                  const SizedBox(height: PerfectSpace.md),
                  Container(
                    padding: const EdgeInsets.all(PerfectSpace.sm),
                    decoration: BoxDecoration(
                      color: PerfectColors.mintSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.offline_pin_rounded, size: 19),
                        SizedBox(width: PerfectSpace.xs),
                        Expanded(
                          child: Text(
                            'Local-first mode stays available while Perfect retries.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: retrying ? null : () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              key: const ValueKey<String>('perfect-sync-retry-now'),
              onPressed: retrying
                  ? null
                  : () async {
                      setDialogState(() => retrying = true);
                      await widget.onRetry();
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
              icon: retrying
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(
                visual.state == PerfectSyncVisualState.current
                    ? 'Sync now'
                    : 'Retry now',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncVisual {
  const _SyncVisual({
    required this.state,
    required this.statusIcon,
    required this.label,
    required this.detail,
    required this.color,
  });

  final PerfectSyncVisualState state;
  final IconData statusIcon;
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
  Widget build(BuildContext context) {
    final icon = switch (phase) {
      PlannerSyncPhase.idle => Icons.cloud_done_outlined,
      PlannerSyncPhase.syncing => Icons.cloud_sync_outlined,
      PlannerSyncPhase.offline => Icons.cloud_upload_outlined,
      PlannerSyncPhase.needsAttention => Icons.cloud_off_outlined,
    };
    return SizedBox.square(
      key: ValueKey<String>('perfect-sync-mark-${phase.name}'),
      dimension: size,
      child: Center(
        child: visual.state == PerfectSyncVisualState.flowing
            ? RotationTransition(
                turns: flow,
                child: Icon(icon, color: visual.color, size: size * .82),
              )
            : Icon(icon, color: visual.color, size: size * .82),
      ),
    );
  }
}

String _formatSyncTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute';
}
