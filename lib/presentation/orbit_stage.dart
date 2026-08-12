import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// The visual, time-first instrument at the centre of Perfect's Today page.
///
/// It is intentionally a living dial instead of a decorative completion ring:
/// the outer bands orient the day, the marker is the present moment, and the
/// centre names the next useful action. At enlarged text or genuinely cramped
/// constraints it becomes a readable linear summary rather than shrinking the
/// same information into an illegible circle.
class OrbitStage extends StatefulWidget {
  const OrbitStage({
    super.key,
    required this.items,
    this.compact = false,
    this.onTap,
    this.now,
    this.motionEnabled = true,
  });

  final List<PlannerEntity> items;
  final bool compact;
  final VoidCallback? onTap;

  /// Optional clock injection keeps previews, tests, and replayed planner
  /// states deterministic without pinning the production dial to a fake time.
  final DateTime? now;
  final bool motionEnabled;

  @override
  State<OrbitStage> createState() => _OrbitStageState();
}

class _OrbitStageState extends State<OrbitStage> with TickerProviderStateMixin {
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: PerfectMotion.modal,
  );
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  Timer? _pulseTimer;
  bool _motionStarted = false;
  bool _reduceMotion = false;
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = PerfectMotion.reduced(context);
    _syncMotion();
  }

  void _syncMotion() {
    final shouldAnimate =
        widget.motionEnabled &&
        !_reduceMotion &&
        TickerMode.valuesOf(context).enabled;
    if (!shouldAnimate) {
      _pulseTimer?.cancel();
      _pulseTimer = null;
      _revealController.value = 1;
      _pulseController
        ..stop()
        ..value = .5;
      return;
    }
    if (!_motionStarted) {
      _motionStarted = true;
      _revealController.forward();
    }
    if (!_pulseController.isAnimating && _pulseTimer == null) {
      _playPulseBurst();
    }
  }

  @override
  void didUpdateWidget(covariant OrbitStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motionEnabled != oldWidget.motionEnabled) {
      _syncMotion();
    }
    if (_itemSignature(widget.items) != _itemSignature(oldWidget.items) &&
        !_reduceMotion) {
      _revealController.forward(from: .34);
    }
    if (widget.onTap == null && oldWidget.onTap != null) {
      _hovered = false;
      _focused = false;
      _pressed = false;
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _playPulseBurst() {
    if (!mounted ||
        !widget.motionEnabled ||
        _reduceMotion ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    _pulseController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pulseController.value = .5;
      if (_reduceMotion) return;
      _pulseTimer = Timer(const Duration(milliseconds: 2100), () {
        _pulseTimer = null;
        _playPulseBurst();
      });
    });
  }

  void _updateInteraction({bool? hovered, bool? focused, bool? pressed}) {
    if (widget.onTap == null) return;
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

  @override
  Widget build(BuildContext context) {
    final now = (widget.now ?? DateTime.now()).toLocal();
    final plan = _OrbitPlan.resolve(items: widget.items, now: now);
    final textScaler = MediaQuery.textScalerOf(context);
    final textScale = textScaler.scale(16) / 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 360.0;
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : availableWidth;
        final minimumCircularSpace = 278 + math.max(0, textScale - 1) * 210;
        final useLinearSummary =
            textScale >= 1.42 ||
            availableWidth < minimumCircularSpace ||
            availableHeight < minimumCircularSpace;
        final visual = useLinearSummary
            ? _buildLinearSummary(context, plan, availableWidth)
            : _buildCircularStage(
                context,
                plan: plan,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
              );

        return Semantics(
          container: true,
          button: widget.onTap != null,
          enabled: widget.onTap != null,
          focusable: widget.onTap != null,
          label: 'Today in orbit',
          value: plan.semanticValue,
          hint: widget.onTap == null ? null : 'Open day plan',
          child: ExcludeSemantics(child: visual),
        );
      },
    );
  }

  Widget _buildCircularStage(
    BuildContext context, {
    required _OrbitPlan plan,
    required double availableWidth,
    required double availableHeight,
  }) {
    final maximumDiameter = widget.compact ? 520.0 : 660.0;
    final diameter = math
        .min(math.min(availableWidth, availableHeight), maximumDiameter)
        .toDouble();
    final theme = Theme.of(context);

    return Center(
      child: SizedBox.square(
        key: const ValueKey<String>('orbit-circular-stage'),
        dimension: diameter,
        child: _interactiveFrame(
          context,
          borderRadius: BorderRadius.circular(diameter / 2),
          shape: const CircleBorder(),
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _revealController,
              _pulseController,
            ]),
            builder: (context, child) {
              final reveal = CurvedAnimation(
                parent: _revealController,
                curve: PerfectMotion.modalEnter,
              ).value;
              final dark = theme.brightness == Brightness.dark;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey<String>('orbit-dial-backdrop'),
                      size: Size.square(diameter),
                      painter: _DayPulseDialPainter(
                        plan: plan,
                        dark: dark,
                        layer: _DayPulseDialLayer.backdrop,
                        pulse: _pulseController.value,
                        hovered: _hovered,
                        focused: _focused,
                      ),
                    ),
                  ),
                  _OrbitGraphicRing(
                    diameter: diameter,
                    dark: dark,
                    reveal: reveal,
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey<String>('orbit-dial-overlay'),
                      size: Size.square(diameter),
                      painter: _DayPulseDialPainter(
                        plan: plan,
                        dark: dark,
                        layer: _DayPulseDialLayer.overlay,
                        pulse: _pulseController.value,
                        hovered: _hovered,
                        focused: _focused,
                      ),
                    ),
                  ),
                  _OrbitCentre(
                    plan: plan,
                    diameter: diameter,
                    pulse: _pulseController.value,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLinearSummary(
    BuildContext context,
    _OrbitPlan plan,
    double availableWidth,
  ) => Align(
    alignment: Alignment.center,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: math.min(availableWidth, 640)),
      child: _interactiveFrame(
        context,
        borderRadius: BorderRadius.circular(26),
        child: _OrbitLinearSummary(
          plan: plan,
          actionable: widget.onTap != null,
        ),
      ),
    ),
  );

  Widget _interactiveFrame(
    BuildContext context, {
    required BorderRadius borderRadius,
    required Widget child,
    ShapeBorder? shape,
  }) {
    final theme = Theme.of(context);
    final interactive = widget.onTap != null;
    final duration = PerfectMotion.responsive(
      context,
      _pressed ? PerfectMotion.quick : PerfectMotion.standard,
    );
    final scale = _reduceMotion
        ? 1.0
        : _pressed
        ? .985
        : _hovered
        ? 1.012
        : 1.0;
    return AnimatedScale(
      key: const ValueKey<String>('orbit-interactive-scale'),
      scale: scale,
      duration: duration,
      curve: PerfectMotion.productive,
      child: AnimatedContainer(
        duration: duration,
        curve: PerfectMotion.productive,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: _hovered && interactive
              ? <BoxShadow>[
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: .10),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: _focused ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: shape ?? RoundedRectangleBorder(borderRadius: borderRadius),
          // Period and side-clock labels intentionally sit just outside the
          // hit surface. Clipping here made the 6 AM/PM labels look broken on
          // a phone even though the painter placed them correctly.
          clipBehavior: Clip.none,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: interactive,
            mouseCursor: interactive
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            borderRadius: shape == null ? borderRadius : null,
            customBorder: shape,
            splashFactory: _reduceMotion ? NoSplash.splashFactory : null,
            highlightColor: _reduceMotion ? Colors.transparent : null,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (!interactive) return Colors.transparent;
              if (states.contains(WidgetState.pressed)) {
                return PerfectColors.lilac.withValues(alpha: .10);
              }
              if (states.contains(WidgetState.hovered)) {
                return PerfectColors.lilac.withValues(alpha: .035);
              }
              return Colors.transparent;
            }),
            onHover: (value) => _updateInteraction(hovered: value),
            onFocusChange: (value) => _updateInteraction(focused: value),
            onHighlightChanged: (value) => _updateInteraction(pressed: value),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OrbitPlan {
  const _OrbitPlan({
    required this.now,
    required this.next,
    required this.openCount,
    required this.items,
  });

  final DateTime now;
  final PlannerEntity? next;
  final int openCount;
  final List<PlannerEntity> items;

  factory _OrbitPlan.resolve({
    required List<PlannerEntity> items,
    required DateTime now,
  }) {
    final open =
        items
            .where((item) => item.status != PlannerEntityStatus.completed)
            .toList(growable: false)
          ..sort((a, b) {
            final first = a.scheduledAt?.toLocal();
            final second = b.scheduledAt?.toLocal();
            if (first == null && second == null) return 0;
            if (first == null) return 1;
            if (second == null) return -1;
            return first.compareTo(second);
          });
    final next = open.firstWhere((item) {
      final scheduled = item.scheduledAt?.toLocal();
      return scheduled != null && !scheduled.isBefore(now);
    }, orElse: () => open.isEmpty ? _emptyOrbitEntity : open.first);
    return _OrbitPlan(
      now: now,
      next: identical(next, _emptyOrbitEntity) ? null : next,
      openCount: open.length,
      items: open,
    );
  }

  String get title => next?.title ?? 'A clear opening';

  String get semanticValue {
    if (openCount == 0) return 'No open items';
    final visibleTitles = items.take(3).map((item) => item.title).join(', ');
    final remainder = openCount - math.min(3, openCount);
    return '$openCount open items: $visibleTitles'
        '${remainder == 0 ? '' : ', and $remainder more'}';
  }
}

final _emptyOrbitEntity = PlannerEntity(
  id: '__perfect_empty_orbit__',
  ownerId: '__perfect__',
  kind: PlannerEntityKind.oneOffTask,
  payload: defaultPlannerPayload(title: ''),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
);

class _OrbitCentre extends StatelessWidget {
  const _OrbitCentre({
    required this.plan,
    required this.diameter,
    required this.pulse,
  });

  final _OrbitPlan plan;
  final double diameter;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final compact = diameter < 330;
    // The centre must name the next action without competing with the dial's
    // edge labels. These caps retain strong hierarchy on a tablet but leave
    // actual breathing room on a phone.
    final titleSize = (diameter * .052).clamp(17.0, 25.0);
    final timeSize = (diameter * .047).clamp(17.0, 22.0);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Transform.translate(
        offset: Offset(0, diameter * .004),
        child: SizedBox(
          width: diameter * .66,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatClock(plan.now),
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: PerfectColors.lilac,
                  fontSize: timeSize,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -timeSize * .01,
                ),
              ),
              SizedBox(height: diameter * .03),
              Text(
                plan.next == null ? 'Your day is clear' : 'Next up',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: (diameter * .035).clamp(12.0, 16.0),
                ),
              ),
              SizedBox(height: diameter * .018),
              Text(
                plan.title,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 2,
                overflow: TextOverflow.ellipsis,
                textDirection: _directionFor(plan.title),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: titleSize,
                  height: 1.04,
                  letterSpacing: -titleSize * .035,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: diameter * .028),
              _HeartbeatLine(
                amplitude: pulse,
                color: PerfectColors.lilac,
                width: (diameter * .22).clamp(64.0, 108.0),
              ),
              Text(
                plan.openCount == 0
                    ? 'Space for what matters'
                    : '${plan.openCount} ${plan.openCount == 1 ? 'task' : 'tasks'} remaining',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: (diameter * .033).clamp(11.0, 15.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartbeatLine extends StatelessWidget {
  const _HeartbeatLine({
    required this.amplitude,
    required this.color,
    required this.width,
  });

  final double amplitude;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * .28,
    child: CustomPaint(
      painter: _HeartbeatPainter(color: color, amplitude: amplitude),
    ),
  );
}

class _HeartbeatPainter extends CustomPainter {
  const _HeartbeatPainter({required this.color, required this.amplitude});

  final Color color;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final power = 1 + (amplitude - .5) * .28;
    final path = Path()
      ..moveTo(0, mid)
      ..lineTo(size.width * .22, mid)
      ..lineTo(size.width * .31, mid - size.height * .11 * power)
      ..lineTo(size.width * .40, mid + size.height * .34 * power)
      ..lineTo(size.width * .51, mid - size.height * .58 * power)
      ..lineTo(size.width * .61, mid + size.height * .15 * power)
      ..lineTo(size.width * .70, mid)
      ..lineTo(size.width, mid);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size.height * .105)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.amplitude != amplitude;
}

class _OrbitGraphicRing extends StatelessWidget {
  const _OrbitGraphicRing({
    required this.diameter,
    required this.dark,
    required this.reveal,
  });

  final double diameter;
  final bool dark;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final progress = reveal.clamp(0.0, 1.0).toDouble();
    return IgnorePointer(
      child: Opacity(
        opacity: progress,
        child: Transform.scale(
          // Reserve a real label gutter. The graphic remains visually large,
          // while the 6 AM / 6 PM anchors no longer fight the canvas edge.
          scale: .92625 + progress * .02375,
          child: SvgPicture.asset(
            dark
                ? 'assets/brand/orbit_period_ring_dark.svg'
                : 'assets/brand/orbit_period_ring_light.svg',
            width: diameter,
            height: diameter,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

enum _DayPulseDialLayer { backdrop, overlay }

class _DayPulseDialPainter extends CustomPainter {
  const _DayPulseDialPainter({
    required this.plan,
    required this.dark,
    required this.layer,
    required this.pulse,
    required this.hovered,
    required this.focused,
  });

  final _OrbitPlan plan;
  final bool dark;
  final _DayPulseDialLayer layer;
  final double pulse;
  final bool hovered;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final surface = dark
        ? const Color(0xff292c3d)
        : PerfectColors.creamElevated;
    final stroke = dark ? const Color(0xff494d61) : PerfectColors.creamStroke;
    // The authored ring is rendered at 95% so its live clock labels have a
    // deliberate gutter. These values are the asset's 440/70/395 geometry at
    // the same scale; the marker, arc copy and ticks therefore stay locked to
    // the artwork instead of drifting independently.
    final outerRadius = shortest * .418;
    final bandWidth = shortest * .0665;
    final innerTickRadius = shortest * .37525;

    if (layer == _DayPulseDialLayer.backdrop) {
      canvas.drawCircle(
        center,
        outerRadius + shortest * .024,
        Paint()
          ..color = surface
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortest * .028),
      );
      canvas.drawCircle(
        center,
        outerRadius + shortest * .016,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, shortest * .004)
          ..color = Colors.white.withValues(alpha: dark ? .10 : .84),
      );
      canvas.drawCircle(
        center,
        outerRadius + shortest * .009,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, shortest * .004)
          ..color = stroke.withValues(alpha: .76),
      );
      canvas.drawCircle(
        center,
        innerTickRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, shortest * .003)
          ..color = stroke.withValues(alpha: .72),
      );
      _drawTicks(
        canvas,
        center: center,
        radius: innerTickRadius,
        shortest: shortest,
        color: dark ? const Color(0xffa8a5b5) : const Color(0xffc7bcaf),
      );
      return;
    }

    _drawPeriodLabel(
      canvas,
      center: center,
      radius: outerRadius,
      bandWidth: bandWidth,
      shortest: shortest,
      angle: _clockAngle(8.85),
      title: 'MORNING',
      detail: '6AM - 12PM',
      color: dark ? const Color(0xffa9dfbb) : const Color(0xff267f80),
    );
    _drawPeriodLabel(
      canvas,
      center: center,
      radius: outerRadius,
      bandWidth: bandWidth,
      shortest: shortest,
      angle: _clockAngle(15.15),
      title: 'AFTERNOON',
      detail: '12PM - 6PM',
      color: dark ? const Color(0xffffbd7c) : const Color(0xff9f6430),
    );
    _drawPeriodLabel(
      canvas,
      center: center,
      radius: outerRadius,
      bandWidth: bandWidth,
      shortest: shortest,
      angle: _clockAngle(21.72),
      title: 'EVENING',
      detail: '6PM - 12AM',
      color: dark ? const Color(0xffcfc5ff) : const Color(0xff7662b5),
    );

    _drawClockLabel(
      canvas,
      center: center,
      radius: innerTickRadius - shortest * .05525,
      angle: _clockAngle(12),
      primary: '12',
      secondary: 'NOON',
      shortest: shortest,
      color: dark ? const Color(0xffd2ccbf) : const Color(0xffa99d90),
    );
    _drawClockLabel(
      canvas,
      center: center,
      // Side clocks share one explicit anchor radius. The 95% ring leaves
      // enough canvas for the complete two-line label on both sides.
      radius: outerRadius + bandWidth * .78,
      angle: _clockAngle(18),
      primary: '6',
      secondary: 'PM',
      shortest: shortest,
      color: dark ? const Color(0xffd2ccbf) : const Color(0xffa99d90),
    );
    _drawClockLabel(
      canvas,
      center: center,
      radius: innerTickRadius - shortest * .05525,
      angle: _clockAngle(24),
      primary: '12',
      secondary: 'MIDNIGHT',
      shortest: shortest,
      color: dark ? const Color(0xffd2ccbf) : const Color(0xffa99d90),
    );
    _drawClockLabel(
      canvas,
      center: center,
      // See the symmetric 6 PM label above.
      radius: outerRadius + bandWidth * .78,
      angle: _clockAngle(6),
      primary: '6',
      secondary: 'AM',
      shortest: shortest,
      color: dark ? const Color(0xffd2ccbf) : const Color(0xffa99d90),
    );

    _drawNowMarker(
      canvas,
      center: center,
      radius: outerRadius,
      shortest: shortest,
      hour: plan.now.hour + plan.now.minute / 60 + plan.now.second / 3600,
      pulse: pulse,
      surface: surface,
      color: PerfectColors.lilac,
    );
    if (hovered || focused) {
      canvas.drawCircle(
        center,
        outerRadius + shortest * .035,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = focused ? 2.2 : 1.4
          ..color = PerfectColors.lilac.withValues(alpha: focused ? .58 : .3),
      );
    }
  }

  void _drawTicks(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double shortest,
    required Color color,
  }) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: .72);
    for (var tick = 0; tick < 36; tick++) {
      final hour = tick / 36 * 24;
      final angle = _clockAngle(hour);
      final major = tick % 3 == 0;
      final start = _point(
        center,
        radius - shortest * (major ? .020 : .012),
        angle,
      );
      final end = _point(center, radius - shortest * .004, angle);
      paint.strokeWidth = shortest * (major ? .0046 : .0028);
      canvas.drawLine(start, end, paint);
    }
    for (var hour = 2; hour < 24; hour += 2) {
      final point = _point(
        center,
        radius - shortest * .042,
        _clockAngle(hour.toDouble()),
      );
      canvas.drawCircle(
        point,
        shortest * .0063,
        Paint()..color = color.withValues(alpha: .6),
      );
    }
  }

  void _drawPeriodLabel(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double bandWidth,
    required double shortest,
    required double angle,
    required String title,
    required String detail,
    required Color color,
  }) {
    final reverse = math.sin(angle) > 0;
    final titleStyle = TextStyle(
      color: color,
      fontFamily: 'PlusJakarta',
      fontWeight: FontWeight.w700,
      letterSpacing: shortest * .001,
      fontSize: (shortest * .0215).clamp(8.0, 11.2),
      height: 1,
    );
    final detailStyle = TextStyle(
      color: color.withValues(alpha: .86),
      fontFamily: 'PlusJakarta',
      fontWeight: FontWeight.w600,
      letterSpacing: shortest * .0006,
      fontSize: (shortest * .015).clamp(6.0, 7.9),
      height: 1,
    );

    // Centre the complete two-line text block inside the authored band using
    // actual font ascent/descent. Fixed baselines made the detail line graze
    // the inner rim, especially on compact phones. This leaves equal optical
    // breathing room at both radial edges and stays correct when fonts scale.
    final titleMetrics = _textPainter(title, titleStyle);
    final detailMetrics = _textPainter(detail, detailStyle);
    final titleAscent = titleMetrics.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final titleDescent = titleMetrics.height - titleAscent;
    final detailAscent = detailMetrics.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final detailDescent = detailMetrics.height - detailAscent;
    final lineGap = math.max(shortest * .0045, 1.5);
    final baselineGap = titleDescent + lineGap + detailAscent;
    final blockExtent = titleAscent + baselineGap + detailDescent;
    final safeExtent = math.max(0.0, bandWidth - shortest * .018);
    final centredExtent = math.min(blockExtent, safeExtent);
    final radialDirection = reverse ? -1.0 : 1.0;
    final titleRadius =
        radius + radialDirection * (centredExtent / 2 - titleAscent);
    final detailRadius = titleRadius - radialDirection * baselineGap;

    _drawTextOnArc(
      canvas,
      center: center,
      radius: titleRadius,
      centerAngle: angle,
      text: title,
      reverse: reverse,
      style: titleStyle,
    );
    _drawTextOnArc(
      canvas,
      center: center,
      radius: detailRadius,
      centerAngle: angle,
      text: detail,
      reverse: reverse,
      style: detailStyle,
    );
  }

  void _drawTextOnArc(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double centerAngle,
    required String text,
    required TextStyle style,
    required bool reverse,
  }) {
    final glyphs = text.runes
        .map((rune) => _textPainter(String.fromCharCode(rune), style))
        .toList(growable: false);
    if (glyphs.isEmpty || radius <= 0) return;
    final totalAdvance = glyphs.fold<double>(
      0,
      (sum, glyph) => sum + glyph.width,
    );
    final direction = reverse ? -1.0 : 1.0;
    final startAngle = centerAngle - direction * (totalAdvance / radius) / 2;
    var advance = 0.0;
    for (final glyph in glyphs) {
      final glyphAngle =
          startAngle + direction * ((advance + glyph.width / 2) / radius);
      final baseline = glyph.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      final point = _point(center, radius, glyphAngle);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(glyphAngle + direction * math.pi / 2);
      glyph.paint(canvas, Offset(-glyph.width / 2, -baseline));
      canvas.restore();
      advance += glyph.width;
    }
  }

  void _drawClockLabel(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double angle,
    required String primary,
    required String secondary,
    required double shortest,
    required Color color,
  }) {
    final point = _point(center, radius, angle);
    final primaryPainter = _textPainter(
      primary,
      TextStyle(
        color: color,
        fontFamily: 'PlusJakarta',
        fontWeight: FontWeight.w600,
        fontSize: (shortest * .045).clamp(14.0, 23.0),
        height: 1,
      ),
    );
    final secondaryPainter = _textPainter(
      secondary,
      TextStyle(
        color: color,
        fontFamily: 'PlusJakarta',
        fontWeight: FontWeight.w600,
        letterSpacing: shortest * .001,
        fontSize: (shortest * .021).clamp(7.0, 10.0),
        height: 1,
      ),
    );
    final total = primaryPainter.height + secondaryPainter.height + 2;
    primaryPainter.paint(
      canvas,
      Offset(point.dx - primaryPainter.width / 2, point.dy - total / 2),
    );
    secondaryPainter.paint(
      canvas,
      Offset(
        point.dx - secondaryPainter.width / 2,
        point.dy - total / 2 + primaryPainter.height + 2,
      ),
    );
  }

  void _drawNowMarker(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double shortest,
    required double hour,
    required double pulse,
    required Color surface,
    required Color color,
  }) {
    final angle = _clockAngle(hour);
    final point = _point(center, radius, angle);
    final haloRadius = shortest * (.049 + pulse * .014);
    canvas.drawCircle(
      point,
      haloRadius,
      Paint()
        ..color = color.withValues(alpha: .26)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortest * .025),
    );
    canvas.drawCircle(point, shortest * .032, Paint()..color = surface);
    canvas.drawCircle(
      point,
      shortest * .025,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, shortest * .008)
        ..color = color,
    );
    final outward = Offset(math.cos(angle), math.sin(angle));
    final tangent = Offset(-math.sin(angle), math.cos(angle));
    final start = point + tangent * (shortest * .03);
    final end = start + tangent * (shortest * .06);
    final wave = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(
        start.dx + (end.dx - start.dx) * .22,
        start.dy + (end.dy - start.dy) * .22,
      )
      ..lineTo(
        start.dx + (end.dx - start.dx) * .38 + outward.dx * shortest * .016,
        start.dy + (end.dy - start.dy) * .38 + outward.dy * shortest * .016,
      )
      ..lineTo(
        start.dx + (end.dx - start.dx) * .54 - outward.dx * shortest * .030,
        start.dy + (end.dy - start.dy) * .54 - outward.dy * shortest * .030,
      )
      ..lineTo(
        start.dx + (end.dx - start.dx) * .68 + outward.dx * shortest * .014,
        start.dy + (end.dy - start.dy) * .68 + outward.dy * shortest * .014,
      )
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, shortest * .0045)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: .94),
    );
  }

  @override
  bool shouldRepaint(covariant _DayPulseDialPainter oldDelegate) =>
      oldDelegate.plan.semanticValue != plan.semanticValue ||
      oldDelegate.plan.now != plan.now ||
      oldDelegate.dark != dark ||
      oldDelegate.layer != layer ||
      oldDelegate.pulse != pulse ||
      oldDelegate.hovered != hovered ||
      oldDelegate.focused != focused;
}

class _OrbitLinearSummary extends StatelessWidget {
  const _OrbitLinearSummary({required this.plan, required this.actionable});

  final _OrbitPlan plan;
  final bool actionable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final bodySize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final textScale =
        MediaQuery.textScalerOf(context).scale(bodySize) / bodySize;
    return DecoratedBox(
      key: const ValueKey<String>('orbit-linear-summary'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final reflow = textScale >= 1.45 || constraints.maxWidth < 300;
            final leading = Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: PerfectColors.lilacSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: PerfectColors.lilac,
              ),
            );
            final title = Text(
              'Today’s rhythm',
              key: const ValueKey<String>('orbit-linear-title'),
              maxLines: reflow ? 2 : 1,
              overflow: reflow ? null : TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            );
            final detail = Text(
              plan.next == null
                  ? 'A clear opening — capture the next thing that matters.'
                  : '${_formatClock(plan.now)} · Next: \u2068${plan.title}\u2069',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            );
            final count = Text(
              plan.openCount == 0
                  ? 'No open items'
                  : '${plan.openCount} open items',
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: PerfectColors.lilac,
                fontWeight: FontWeight.w800,
              ),
            );
            final action = actionable
                ? Icon(
                    Icons.arrow_forward_rounded,
                    color: scheme.onSurfaceVariant,
                  )
                : null;
            final content = reflow
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          leading,
                          const SizedBox(width: PerfectSpace.sm),
                          Expanded(child: title),
                          if (action != null) ...[
                            const SizedBox(width: PerfectSpace.xs),
                            action,
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      detail,
                      const SizedBox(height: 2),
                      count,
                    ],
                  )
                : Row(
                    children: [
                      leading,
                      const SizedBox(width: PerfectSpace.sm),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 2),
                            detail,
                            const SizedBox(height: 2),
                            count,
                          ],
                        ),
                      ),
                      ?action,
                    ],
                  );
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

double _clockAngle(double hour) => -math.pi / 2 + ((hour - 12) * math.pi / 12);

Offset _point(Offset center, double radius, double angle) => Offset(
  center.dx + math.cos(angle) * radius,
  center.dy + math.sin(angle) * radius,
);

TextPainter _textPainter(String text, TextStyle style) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
)..layout();

String _formatClock(DateTime value) {
  return PerfectLocalTime.clock(value);
}

TextDirection _directionFor(String value) {
  final rtl = RegExp(r'[\u0590-\u08FF]').hasMatch(value);
  return rtl ? TextDirection.rtl : TextDirection.ltr;
}

String _itemSignature(List<PlannerEntity> items) => items
    .map(
      (item) =>
          '${item.id}:${item.updatedAt.microsecondsSinceEpoch}:${item.title}',
    )
    .join('|');
