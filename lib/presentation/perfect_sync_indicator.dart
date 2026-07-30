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
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePulse();
  }

  @override
  void didUpdateWidget(covariant PerfectSyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse();
  }

  void _updatePulse() {
    final shouldPulse =
        _visual.state == PerfectSyncVisualState.flowing &&
        !MediaQuery.disableAnimationsOf(context);
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _SyncVisual get _visual => switch (widget.status.phase) {
    PlannerSyncPhase.idle => const _SyncVisual(
      state: PerfectSyncVisualState.current,
      icon: Icons.cloud_done_rounded,
      label: 'Up to date',
      detail: 'All local changes are synced across your Perfect devices.',
      color: PerfectColors.mint,
    ),
    PlannerSyncPhase.syncing => const _SyncVisual(
      state: PerfectSyncVisualState.flowing,
      icon: Icons.cloud_sync_rounded,
      label: 'Syncing',
      detail: 'Perfect is sending or receiving changes now.',
      color: PerfectColors.apricot,
    ),
    PlannerSyncPhase.offline => const _SyncVisual(
      state: PerfectSyncVisualState.flowing,
      icon: Icons.cloud_queue_rounded,
      label: 'Retrying',
      detail:
          'Changes are safe on this device. Automatic sync will retry when the connection is ready.',
      color: PerfectColors.apricot,
    ),
    PlannerSyncPhase.needsAttention => const _SyncVisual(
      state: PerfectSyncVisualState.error,
      icon: Icons.cloud_off_rounded,
      label: 'Sync issue',
      detail:
          'The last sync did not finish. Local planning still works and your changes remain on this device.',
      color: PerfectColors.danger,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    final semanticLabel =
        '${visual.label}. ${visual.detail} Tap for sync details and retry.';
    return Tooltip(
      message: '${visual.label}\n${visual.detail}',
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('perfect-sync-indicator'),
            borderRadius: _borderRadius(visual.state),
            onTap: () => _showDetails(context),
            mouseCursor: SystemMouseCursors.click,
            canRequestFocus: true,
            focusNode: _focusNode,
            child: AnimatedContainer(
              duration: PerfectMotion.responsive(
                context,
                PerfectMotion.standard,
              ),
              curve: PerfectMotion.productive,
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? PerfectSpace.sm : PerfectSpace.md,
              ),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  visual.color.withValues(alpha: .13),
                  Theme.of(context).colorScheme.surface,
                ),
                borderRadius: _borderRadius(visual.state),
                border: Border.all(
                  color: visual.color,
                  width: visual.state == PerfectSyncVisualState.error ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: PerfectMotion.responsive(
                      context,
                      PerfectMotion.quick,
                    ),
                    child: AnimatedBuilder(
                      key: ValueKey<PlannerSyncPhase>(widget.status.phase),
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        scale: visual.state == PerfectSyncVisualState.flowing
                            ? 1 + (_pulse.value * .055)
                            : 1,
                        child: child,
                      ),
                      child: Icon(visual.icon, color: visual.color, size: 20),
                    ),
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(width: PerfectSpace.xs),
                    Text(
                      visual.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
              Icon(visual.icon, color: visual.color),
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
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  final PerfectSyncVisualState state;
  final IconData icon;
  final String label;
  final String detail;
  final Color color;
}

BorderRadius _borderRadius(PerfectSyncVisualState state) => switch (state) {
  PerfectSyncVisualState.current => BorderRadius.circular(99),
  PerfectSyncVisualState.flowing => BorderRadius.circular(16),
  PerfectSyncVisualState.error => const BorderRadius.only(
    topLeft: Radius.circular(6),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(6),
  ),
};

String _formatSyncTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute';
}
