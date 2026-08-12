import 'package:flutter/material.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_sync_indicator.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// Compact, adaptive workspace chrome bound to the approved glass-header
/// preview family. Dynamic clock/date and sync values remain live Flutter
/// content; only the approved product wordmark is an authored brand asset.
class PerfectWorkspaceHeader extends StatelessWidget {
  const PerfectWorkspaceHeader({
    super.key,
    required this.destinationKey,
    required this.destinationLabel,
    required this.supportText,
    required this.status,
    required this.onSync,
    this.now = DateTime.now,
    this.compact = false,
    this.showWordmark = true,
    this.showContext = true,
  });

  final String destinationKey;
  final String destinationLabel;
  final String supportText;
  final PlannerSyncStatus status;
  final Future<void> Function() onSync;
  final PerfectNow now;
  final bool compact;
  final bool showWordmark;
  final bool showContext;

  bool get _phoneComposition => compact && showWordmark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.fromSTEB(
      compact ? PerfectSpace.md : PerfectSpace.xl,
      PerfectSpace.sm,
      compact ? PerfectSpace.md : PerfectSpace.xl,
      PerfectSpace.xs,
    ),
    child: PerfectGlassSurface(
      surfaceKey: const ValueKey<String>('perfect-workspace-glass-header'),
      strength: PerfectGlassStrength.soft,
      blur: 16,
      castShadow: false,
      borderRadius: BorderRadius.circular(22),
      padding: EdgeInsetsDirectional.fromSTEB(
        compact ? PerfectSpace.sm : PerfectSpace.md,
        PerfectSpace.xs,
        compact ? PerfectSpace.xs : PerfectSpace.sm,
        PerfectSpace.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => _phoneComposition
            ? _PhoneHeaderRow(status: status, onSync: onSync, now: now)
            : _ContextHeaderRow(
                constraints: constraints,
                destinationKey: destinationKey,
                destinationLabel: destinationLabel,
                supportText: supportText,
                status: status,
                onSync: onSync,
                now: now,
                compact: compact,
                showWordmark: showWordmark,
                showContext: showContext,
              ),
      ),
    ),
  );
}

class _PhoneHeaderRow extends StatelessWidget {
  const _PhoneHeaderRow({
    required this.status,
    required this.onSync,
    required this.now,
  });

  final PlannerSyncStatus status;
  final Future<void> Function() onSync;
  final PerfectNow now;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Row(
      key: const ValueKey<String>('perfect-header-phone-row'),
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: PerfectWordmark(fontSize: textScale >= 1.6 ? 22 : 25.5),
          ),
        ),
        const SizedBox(width: PerfectSpace.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: PerfectSyncIndicator(
            status: status,
            onRetry: onSync,
            compact: true,
            now: now,
          ),
        ),
      ],
    );
  }
}

class _ContextHeaderRow extends StatelessWidget {
  const _ContextHeaderRow({
    required this.constraints,
    required this.destinationKey,
    required this.destinationLabel,
    required this.supportText,
    required this.status,
    required this.onSync,
    required this.now,
    required this.compact,
    required this.showWordmark,
    required this.showContext,
  });

  final BoxConstraints constraints;
  final String destinationKey;
  final String destinationLabel;
  final String supportText;
  final PlannerSyncStatus status;
  final Future<void> Function() onSync;
  final PerfectNow now;
  final bool compact;
  final bool showWordmark;
  final bool showContext;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final stacked = constraints.maxWidth < 620 || textScale >= 1.55;
    final contextCluster = _HeaderContextCluster(
      destinationKey: destinationKey,
      destinationLabel: destinationLabel,
      supportText: supportText,
      showWordmark: showWordmark,
      showContext: showContext,
      compact: compact,
    );
    final clock = PerfectDualDateClock(now: now, compact: compact || stacked);
    final sync = PerfectSyncIndicator(
      status: status,
      onRetry: onSync,
      compact: compact,
      now: now,
    );
    if (stacked) {
      return Column(
        key: const ValueKey<String>('perfect-header-context-stacked'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: contextCluster),
              const SizedBox(width: PerfectSpace.sm),
              sync,
            ],
          ),
          const SizedBox(height: PerfectSpace.xs),
          clock,
        ],
      );
    }
    return Row(
      key: const ValueKey<String>('perfect-header-context-row'),
      children: [
        Expanded(flex: 5, child: contextCluster),
        const SizedBox(width: PerfectSpace.lg),
        Flexible(flex: 4, child: clock),
        const SizedBox(width: PerfectSpace.lg),
        sync,
      ],
    );
  }
}

class _HeaderContextCluster extends StatelessWidget {
  const _HeaderContextCluster({
    required this.destinationKey,
    required this.destinationLabel,
    required this.supportText,
    required this.showWordmark,
    required this.showContext,
    required this.compact,
  });

  final String destinationKey;
  final String destinationLabel;
  final String supportText;
  final bool showWordmark;
  final bool showContext;
  final bool compact;

  @override
  Widget build(BuildContext context) => PerfectMotionSwitcher(
    kind: PerfectTransitionKind.fade,
    duration: PerfectMotion.standard,
    reverseDuration: PerfectMotion.quick,
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[...previousChildren, ?currentChild],
    ),
    child: KeyedSubtree(
      key: ValueKey<String>('header-context-$destinationKey'),
      child: PerfectStagedEntrance(
        rise: 10,
        scaleBegin: .995,
        duration: PerfectMotion.standard,
        child: Row(
          children: [
            if (showWordmark) ...[
              PerfectMark(size: compact ? 28 : 32),
              const SizedBox(width: PerfectSpace.sm),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showContext || !showWordmark)
                    Text(
                      destinationLabel,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.25,
                      ),
                    )
                  else
                    const PerfectWordmark(fontSize: 24),
                  if (supportText.isNotEmpty &&
                      MediaQuery.textScalerOf(context).scale(14) / 14 <
                          1.45) ...[
                    const SizedBox(height: 1),
                    Text(
                      supportText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Live mixed-calendar clock cluster shared by the global header and Today.
class PerfectDualDateClock extends StatelessWidget {
  const PerfectDualDateClock({
    super.key,
    this.now = DateTime.now,
    this.compact = false,
    this.alignEnd = false,
  }) : value = null;

  const PerfectDualDateClock.value({
    super.key,
    required this.value,
    this.compact = false,
    this.alignEnd = false,
  }) : now = DateTime.now;

  final PerfectNow now;
  final DateTime? value;
  final bool compact;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final fixed = value;
    if (fixed != null) return _buildClock(context, fixed);
    return PerfectMinuteClockBuilder(now: now, builder: _buildClock);
  }

  Widget _buildClock(BuildContext context, DateTime current) {
    final clock = PerfectLocalTime.clock(current);
    final gregorian = PerfectLocalTime.gregorianLong(current);
    final jalali = PerfectLocalTime.jalaliLong(current);
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$clock. $gregorian. Solar Hijri $jalali.',
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey<String>('perfect-dual-date-clock'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Text(
              clock,
              key: const ValueKey<String>('perfect-live-clock'),
              maxLines: 1,
              style:
                  (compact
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.titleMedium)
                      ?.copyWith(
                        color: PerfectColors.lilac,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.25,
                      ),
            ),
            const SizedBox(height: 1),
            Wrap(
              key: const ValueKey<String>('perfect-dual-date-line'),
              alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              runSpacing: 1,
              children: [
                Text(
                  gregorian,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '·',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    jalali,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
