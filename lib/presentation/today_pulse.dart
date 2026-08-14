import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:perfect/presentation/perfect_pictogram.dart';
import 'package:perfect/presentation/perfect_theme.dart';

enum TodayPulseState {
  resolving,
  empty,
  active,
  complete,
  missedOnly,
  habitsOnly,
  unscheduledOnly,
}

/// Immutable, daily projection consumed by [TodayPulse].
///
/// Titles and row mutations deliberately do not cross this boundary. The Pulse
/// owns orientation only: outcome counts, proportional progress and temporal
/// boundaries. This keeps it useful without duplicating the actionable stream.
@immutable
class TodayPulseSnapshot {
  TodayPulseSnapshot({
    required this.state,
    required this.total,
    required this.completed,
    required this.remaining,
    required this.missed,
    required this.partial,
    required double progress,
    required Iterable<DateTime> boundaries,
  }) : progress = progress.clamp(0, 1).toDouble(),
       boundaries = List<DateTime>.unmodifiable(
         boundaries.map(PerfectLocalTime.local).toList(growable: false)..sort(),
       );

  factory TodayPulseSnapshot.fromPlanner({
    required List<PlannerEntity> items,
    required Map<String, PlannerTaskProgress> taskProgressById,
    required Map<String, PlannerHabitDaySummary> habitSummaryById,
    required bool projectionResolved,
  }) {
    var completed = 0;
    var missed = 0;
    var partial = 0;
    var progressUnits = 0.0;
    var habits = 0;
    final boundaries = <DateTime>[];

    for (final item in items) {
      final scheduled = item.scheduledAt;
      final due = item.dueAt;
      final end = safeJsonDateTime(
        item.timing[PlannerTaskMetadataKeys.timeBlockEndAt],
      );
      if (scheduled != null) boundaries.add(scheduled);
      if (due != null) boundaries.add(due);
      if (end != null) boundaries.add(end);

      if (item.kind == PlannerEntityKind.habit) {
        habits++;
        final summary =
            habitSummaryById[item.id] ??
            PlannerHabitDaySummary.pending(
              method: safeJsonString(
                item.tracking[PlannerHabitTrackingKeys.method],
                fallback: 'check',
              ),
            );
        progressUnits += summary.progressPercent / 100;
        switch (summary.state) {
          case PlannerHabitDayState.completed:
            completed++;
          case PlannerHabitDayState.missed:
            missed++;
          case PlannerHabitDayState.partial:
            partial++;
          case PlannerHabitDayState.pending:
            break;
        }
        continue;
      }

      final progress =
          taskProgressById[item.id] ??
          (item.kind == PlannerEntityKind.recurringTask
              ? const PlannerTaskProgress.pending()
              : PlannerTaskProgress.fromEntity(item));
      progressUnits += progress.percent / 100;
      if (progress.isComplete) {
        completed++;
      } else if (progress.isMissed) {
        missed++;
      } else if (progress.isPartial) {
        partial++;
      }
    }

    final total = items.length;
    final remaining = math.max(0, total - completed - missed);
    final state = switch ((projectionResolved, total)) {
      (false, > 0) => TodayPulseState.resolving,
      (_, 0) => TodayPulseState.empty,
      _ when completed == total => TodayPulseState.complete,
      _ when missed == total => TodayPulseState.missedOnly,
      _ when habits == total => TodayPulseState.habitsOnly,
      _ when boundaries.isEmpty => TodayPulseState.unscheduledOnly,
      _ => TodayPulseState.active,
    };
    return TodayPulseSnapshot(
      state: state,
      total: total,
      completed: completed,
      remaining: remaining,
      missed: missed,
      partial: partial,
      progress: total == 0 ? 0 : progressUnits / total,
      boundaries: boundaries,
    );
  }

  final TodayPulseState state;
  final int total;
  final int completed;
  final int remaining;
  final int missed;
  final int partial;
  final double progress;
  final List<DateTime> boundaries;

  DateTime? nextBoundaryAfter(DateTime now) {
    final localNow = PerfectLocalTime.local(now);
    for (final boundary in boundaries) {
      if (boundary.isAfter(localNow)) return boundary;
    }
    return null;
  }

  String get outcomePrimary => switch (state) {
    TodayPulseState.resolving => 'Updating today…',
    TodayPulseState.empty => 'Nothing planned',
    TodayPulseState.complete => 'Everything complete',
    TodayPulseState.missedOnly =>
      '${_countPhrase(missed, 'needs', 'need')} a decision',
    TodayPulseState.habitsOnly =>
      '${remaining == 0 ? total : remaining} ${remaining == 1 ? 'habit' : 'habits'} remaining',
    TodayPulseState.unscheduledOnly =>
      '$remaining ${remaining == 1 ? 'flexible item' : 'flexible items'}',
    TodayPulseState.active => '$completed complete',
  };

  String get outcomeSecondary {
    if (state != TodayPulseState.active) return '';
    final remainingText = '$remaining remaining';
    if (missed == 0) return remainingText;
    return '$remainingText · $missed to review';
  }

  String boundaryLabel(DateTime now) {
    return switch (state) {
      TodayPulseState.resolving => 'Checking the next boundary',
      TodayPulseState.empty => 'Shape the day',
      TodayPulseState.complete => 'You made it yours',
      TodayPulseState.missedOnly => 'Review before tomorrow',
      _ => _formatBoundary(nextBoundaryAfter(now), now: now),
    };
  }

  String semanticsLabel(DateTime now) {
    final local = PerfectLocalTime.local(now);
    final secondary = outcomeSecondary;
    return 'Today pulse. ${PerfectLocalTime.clock(local)}. '
        '${PerfectLocalTime.gregorianLong(local)}. '
        'Solar Hijri ${PerfectLocalTime.jalaliLong(local)}. '
        '$outcomePrimary${secondary.isEmpty ? '' : ', $secondary'}. '
        'Next boundary: ${boundaryLabel(local)}.';
  }

  static String _countPhrase(int value, String singular, String plural) =>
      '$value ${value == 1 ? singular : plural}';

  static String _formatBoundary(DateTime? boundary, {required DateTime now}) {
    if (boundary == null) return 'No later boundary';
    final localBoundary = PerfectLocalTime.local(boundary);
    final localNow = PerfectLocalTime.local(now);
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final boundaryDay = DateTime(
      localBoundary.year,
      localBoundary.month,
      localBoundary.day,
    );
    final dayDelta = boundaryDay.difference(today).inDays;
    if (dayDelta == 0) return PerfectLocalTime.clock(localBoundary);
    if (dayDelta == 1) {
      return 'Tomorrow · ${PerfectLocalTime.clock(localBoundary)}';
    }
    return '${PerfectLocalTime.gregorianShort(localBoundary)} · '
        '${PerfectLocalTime.clock(localBoundary)}';
  }
}

class TodayPulse extends StatelessWidget {
  const TodayPulse({
    super.key,
    required this.snapshot,
    required this.onOpenPlan,
    this.now = DateTime.now,
    this.schedule = schedulePerfectMinuteTick,
    this.shortLandscape = false,
  });

  final TodayPulseSnapshot snapshot;
  final VoidCallback onOpenPlan;
  final PerfectNow now;
  final PerfectMinuteSchedule schedule;
  final bool shortLandscape;

  @override
  Widget build(BuildContext context) => PerfectMinuteClockBuilder(
    now: now,
    schedule: schedule,
    builder: (context, current) => LayoutBuilder(
      builder: (context, constraints) {
        final baseSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;
        final textScale =
            MediaQuery.textScalerOf(context).scale(baseSize) / baseSize;
        final wide =
            constraints.maxWidth >= 760 && textScale < 1.45 && !shortLandscape;
        final largeText = textScale >= 1.45 || constraints.maxWidth < 340;
        return Semantics(
          key: const ValueKey<String>('today-pulse'),
          container: true,
          liveRegion: true,
          label: snapshot.semanticsLabel(current),
          child: _TodayPulseFrame(
            snapshot: snapshot,
            current: current,
            onOpenPlan: onOpenPlan,
            wide: wide,
            largeText: largeText,
          ),
        );
      },
    ),
  );
}

class _TodayPulseFrame extends StatelessWidget {
  const _TodayPulseFrame({
    required this.snapshot,
    required this.current,
    required this.onOpenPlan,
    required this.wide,
    required this.largeText,
  });

  final TodayPulseSnapshot snapshot;
  final DateTime current;
  final VoidCallback onOpenPlan;
  final bool wide;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final semantic = PerfectSemanticTheme.of(context);
    final radius = BorderRadius.circular(PerfectRadius.panel);
    final content = wide
        ? _WidePulseContent(
            snapshot: snapshot,
            current: current,
            onOpenPlan: onOpenPlan,
          )
        : _CompactPulseContent(
            snapshot: snapshot,
            current: current,
            onOpenPlan: onOpenPlan,
            largeText: largeText,
          );
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: semantic.highContrast
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      semantic.secondaryContainer.withValues(alpha: .52),
                      semantic.surfaceLow,
                      semantic.tertiaryContainer.withValues(alpha: .52),
                    ],
                    stops: const <double>[0, .48, 1],
                  ),
            color: semantic.highContrast ? semantic.surfaceLowest : null,
            borderRadius: radius,
            border: Border.all(
              color: semantic.highContrast
                  ? semantic.outline
                  : semantic.outlineVariant,
              width: semantic.highContrast ? 2 : 1,
            ),
            boxShadow: semantic.highContrast
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: semantic.shadow.withValues(alpha: .11),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _TodayPulseFieldPainter(semantic: semantic),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? PerfectSpace.xl : PerfectSpace.lg,
                  wide ? PerfectSpace.lg : PerfectSpace.md,
                  wide ? PerfectSpace.xl : PerfectSpace.lg,
                  PerfectSpace.sm,
                ),
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactPulseContent extends StatelessWidget {
  const _CompactPulseContent({
    required this.snapshot,
    required this.current,
    required this.onOpenPlan,
    required this.largeText,
  });

  final TodayPulseSnapshot snapshot;
  final DateTime current;
  final VoidCallback onOpenPlan;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final clock = _ClockParts.from(current);
    final timeBlock = _PulseTimeBlock(
      clock: clock,
      compact: true,
      separateEyebrow: largeText,
    );
    return ExcludeSemantics(
      excluding: false,
      child: Column(
        key: const ValueKey<String>('today-pulse-compact'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (largeText) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _PulseEyebrow(label: 'NOW')),
                _PulsePlanButton(onPressed: onOpenPlan),
              ],
            ),
            const SizedBox(height: PerfectSpace.xs),
            timeBlock,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: timeBlock),
                const SizedBox(width: PerfectSpace.sm),
                _PulsePlanButton(onPressed: onOpenPlan),
              ],
            ),
          const SizedBox(height: PerfectSpace.xxs),
          _PulseDates(current: current, stack: largeText),
          SizedBox(height: largeText ? PerfectSpace.lg : PerfectSpace.md),
          _PulseOutcome(snapshot: snapshot, wide: false),
          const SizedBox(height: PerfectSpace.xs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _PulseBoundary(snapshot: snapshot, current: current),
          ),
          const SizedBox(height: PerfectSpace.xxs),
          _PulseDayline(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _WidePulseContent extends StatelessWidget {
  const _WidePulseContent({
    required this.snapshot,
    required this.current,
    required this.onOpenPlan,
  });

  final TodayPulseSnapshot snapshot;
  final DateTime current;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final divider = PerfectSemanticTheme.of(context).outlineVariant;
    return Column(
      key: const ValueKey<String>('today-pulse-wide'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PulseTimeBlock(
                      clock: _ClockParts.from(current),
                      compact: false,
                    ),
                    const SizedBox(height: PerfectSpace.xxs),
                    _PulseDates(current: current, stack: true),
                  ],
                ),
              ),
              VerticalDivider(color: divider, width: PerfectSpace.xxl),
              Expanded(
                flex: 31,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PulseEyebrow(label: 'DAY SO FAR'),
                    const SizedBox(height: PerfectSpace.sm),
                    _PulseOutcome(snapshot: snapshot, wide: true),
                  ],
                ),
              ),
              VerticalDivider(color: divider, width: PerfectSpace.xxl),
              Expanded(
                flex: 35,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PulseEyebrow(label: 'NEXT BOUNDARY'),
                    const SizedBox(height: PerfectSpace.sm),
                    _PulseBoundary(snapshot: snapshot, current: current),
                    const Spacer(),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _PulsePlanButton(onPressed: onOpenPlan),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PerfectSpace.sm),
        _PulseDayline(snapshot: snapshot),
      ],
    );
  }
}

class _PulseEyebrow extends StatelessWidget {
  const _PulseEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      label,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: PerfectSemanticTheme.of(context).muted,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.55,
      ),
    ),
  );
}

class _PulseTimeBlock extends StatelessWidget {
  const _PulseTimeBlock({
    required this.clock,
    required this.compact,
    this.separateEyebrow = false,
  });

  final _ClockParts clock;
  final bool compact;
  final bool separateEyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = PerfectSemanticTheme.of(context);
    return ExcludeSemantics(
      child: Column(
        key: const ValueKey<String>('today-pulse-time'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!separateEyebrow) const _PulseEyebrow(label: 'NOW'),
          if (!separateEyebrow) const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: clock.time,
                  style:
                      (compact
                              ? theme.textTheme.displaySmall
                              : theme.textTheme.headlineLarge)
                          ?.copyWith(
                            color: semantic.ink,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                            height: .98,
                          ),
                ),
                TextSpan(
                  text: '  ${clock.period}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: semantic.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _PulseDates extends StatelessWidget {
  const _PulseDates({required this.current, required this.stack});

  final DateTime current;
  final bool stack;

  @override
  Widget build(BuildContext context) {
    final semantic = PerfectSemanticTheme.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: semantic.muted,
      fontWeight: FontWeight.w600,
    );
    final gregorian = Text(
      PerfectLocalTime.gregorianLong(current),
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: style,
    );
    final jalali = Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        PerfectLocalTime.jalaliLong(current),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: style,
      ),
    );
    return ExcludeSemantics(
      child: stack
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [gregorian, const SizedBox(height: 2), jalali],
            )
          : Wrap(
              spacing: PerfectSpace.sm,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [gregorian, jalali],
            ),
    );
  }
}

class _PulseOutcome extends StatelessWidget {
  const _PulseOutcome({required this.snapshot, required this.wide});

  final TodayPulseSnapshot snapshot;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final semantic = PerfectSemanticTheme.of(context);
    final danger = snapshot.state == TodayPulseState.missedOnly;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.outcomePrimary,
            maxLines: 2,
            overflow: TextOverflow.fade,
            style:
                (wide
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                      color: danger ? semantic.danger : semantic.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.35,
                    ),
          ),
          if (snapshot.outcomeSecondary.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              snapshot.outcomeSecondary,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: semantic.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseBoundary extends StatelessWidget {
  const _PulseBoundary({required this.snapshot, required this.current});

  final TodayPulseSnapshot snapshot;
  final DateTime current;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      snapshot.boundaryLabel(current),
      key: const ValueKey<String>('today-pulse-boundary'),
      maxLines: 2,
      textAlign: TextAlign.start,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: PerfectSemanticTheme.of(context).ink,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PulsePlanButton extends StatelessWidget {
  const _PulsePlanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semantic = PerfectSemanticTheme.of(context);
    return Semantics(
      button: true,
      label: 'Open day plan',
      child: Tooltip(
        message: 'Open day plan',
        child: SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('today-pulse-plan'),
            onPressed: onPressed,
            icon: const PerfectPictogram(name: 'calendar', size: 20),
            label: const Text('Plan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: semantic.primary,
              backgroundColor: semantic.surfaceLowest.withValues(alpha: .78),
              side: BorderSide(color: semantic.outlineVariant),
              padding: const EdgeInsets.symmetric(horizontal: PerfectSpace.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PerfectRadius.control),
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDayline extends StatelessWidget {
  const _PulseDayline({required this.snapshot});

  final TodayPulseSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = PerfectMotion.reduced(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        key: const ValueKey<String>('today-pulse-dayline'),
        tween: Tween<double>(end: snapshot.progress),
        duration: reduceMotion ? Duration.zero : PerfectMotion.emphasized,
        curve: PerfectMotion.productive,
        builder: (context, value, _) => SizedBox(
          height: 24,
          width: double.infinity,
          child: CustomPaint(
            painter: _TodayPulseDaylinePainter(
              semantic: PerfectSemanticTheme.of(context),
              progress: value,
              needsReview: snapshot.missed > 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayPulseFieldPainter extends CustomPainter {
  const _TodayPulseFieldPainter({required this.semantic});

  final PerfectSemanticTheme semantic;

  @override
  void paint(Canvas canvas, Size size) {
    if (semantic.highContrast) return;
    final mint = Paint()
      ..color = semantic.secondaryVivid.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(22, size.shortestSide * .16)
      ..strokeCap = StrokeCap.round;
    final lilac = Paint()
      ..color = semantic.tertiaryVivid.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(28, size.shortestSide * .2)
      ..strokeCap = StrokeCap.round;
    final left = Path()
      ..moveTo(-size.width * .05, size.height * .14)
      ..cubicTo(
        size.width * .12,
        size.height * .26,
        size.width * .18,
        size.height * .52,
        size.width * .4,
        size.height * .48,
      );
    final right = Path()
      ..moveTo(size.width * .58, -size.height * .04)
      ..cubicTo(
        size.width * .7,
        size.height * .2,
        size.width * .82,
        size.height * .22,
        size.width * 1.05,
        size.height * .1,
      );
    canvas.drawPath(left, mint);
    canvas.drawPath(right, lilac);
  }

  @override
  bool shouldRepaint(covariant _TodayPulseFieldPainter oldDelegate) =>
      oldDelegate.semantic != semantic;
}

class _TodayPulseDaylinePainter extends CustomPainter {
  const _TodayPulseDaylinePainter({
    required this.semantic,
    required this.progress,
    required this.needsReview,
  });

  final PerfectSemanticTheme semantic;
  final double progress;
  final bool needsReview;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final start = Offset(5, y);
    final end = Offset(size.width - 5, y);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * .25,
        y - 3,
        size.width * .36,
        y + 3,
        size.width * .49,
        y,
      )
      ..cubicTo(
        size.width * .65,
        y - 3,
        size.width * .75,
        y + 3,
        end.dx,
        end.dy,
      );
    final strokeWidth = semantic.highContrast ? 8.0 : 7.0;
    final base = Paint()
      ..color = semantic.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, base);

    final metric = path.computeMetrics().first;
    final clamped = progress.clamp(0, 1).toDouble();
    if (clamped > 0) {
      final resolved = metric.extractPath(0, metric.length * clamped);
      final active = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            semantic.secondaryVivid,
            semantic.primaryVivid,
            semantic.tertiaryVivid,
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(resolved, active);
    }

    final marker = metric
        .getTangentForOffset(metric.length * clamped)
        ?.position;
    final endpoint = Paint()..color = semantic.outlineVariant;
    canvas.drawCircle(start, 4, Paint()..color = semantic.secondaryVivid);
    canvas.drawCircle(end, 4, endpoint);
    if (marker != null && clamped > 0 && clamped < 1) {
      final markerColor = needsReview
          ? semantic.danger
          : semantic.tertiaryVivid;
      canvas.drawCircle(
        marker,
        10,
        Paint()..color = markerColor.withValues(alpha: .14),
      );
      canvas.drawCircle(marker, 7, Paint()..color = semantic.surfaceLowest);
      canvas.drawCircle(
        marker,
        7,
        Paint()
          ..color = markerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(marker, 2.5, Paint()..color = markerColor);
    }
  }

  @override
  bool shouldRepaint(covariant _TodayPulseDaylinePainter oldDelegate) =>
      oldDelegate.semantic != semantic ||
      oldDelegate.progress != progress ||
      oldDelegate.needsReview != needsReview;
}

class _ClockParts {
  const _ClockParts({required this.time, required this.period});

  factory _ClockParts.from(DateTime value) {
    final local = PerfectLocalTime.local(value);
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    return _ClockParts(
      time: '$hour:${local.minute.toString().padLeft(2, '0')}',
      period: local.hour >= 12 ? 'PM' : 'AM',
    );
  }

  final String time;
  final String period;
}
