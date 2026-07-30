import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/presentation/perfect_theme.dart';

class OrbitStage extends StatelessWidget {
  const OrbitStage({
    super.key,
    required this.items,
    this.compact = false,
    this.onTap,
  });

  final List<PlannerEntity> items;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
        final circularMinimum = 230 + math.max(0, textScale - 1) * 220;
        if (textScale >= 1.45 ||
            availableWidth < circularMinimum ||
            availableHeight < circularMinimum) {
          return _OrbitLinearSummary(items: items, onTap: onTap);
        }
        final availableDiameter = math.min(availableWidth, availableHeight);
        final diameter = compact
            ? math.min(availableDiameter, 360.0)
            : availableDiameter;
        final segments = _segmentsFor(items);
        final reducedMotion = MediaQuery.disableAnimationsOf(context);
        return Semantics(
          container: true,
          button: onTap != null,
          label: 'Today in orbit',
          value: _orbitSemanticValue(items),
          hint: onTap == null ? null : 'Open day plan',
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(diameter / 2),
                splashFactory: reducedMotion ? NoSplash.splashFactory : null,
                highlightColor: reducedMotion ? Colors.transparent : null,
                onTap: onTap,
                child: Center(
                  child: SizedBox.square(
                    dimension: diameter,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.center,
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            size: Size.square(diameter),
                            painter: _OrbitPainter(
                              dark:
                                  Theme.of(context).brightness ==
                                  Brightness.dark,
                              segments: segments,
                            ),
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                color: PerfectColors.apricot,
                                size: diameter * .1,
                              ),
                              SizedBox(height: diameter * .02),
                              Text(
                                'Your day,\nin orbit.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.18,
                                    ),
                              ),
                              SizedBox(height: diameter * .025),
                              Text(
                                '${items.length} open',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        _OrbitLabel(
                          alignment: const Alignment(0, -.9),
                          primary: '12:00',
                          secondary: 'PM',
                          diameter: diameter,
                        ),
                        _OrbitLabel(
                          alignment: const Alignment(.9, 0),
                          primary: '3:00',
                          secondary: 'PM',
                          diameter: diameter,
                        ),
                        _OrbitLabel(
                          alignment: const Alignment(0, .91),
                          primary: '6:00',
                          secondary: 'PM',
                          diameter: diameter,
                        ),
                        _OrbitLabel(
                          alignment: const Alignment(-.91, 0),
                          primary: '9:00',
                          secondary: 'AM',
                          diameter: diameter,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrbitLabel extends StatelessWidget {
  const _OrbitLabel({
    required this.alignment,
    required this.primary,
    required this.secondary,
    required this.diameter,
  });

  final Alignment alignment;
  final String primary;
  final String secondary;
  final double diameter;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            primary,
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: math.max(10, diameter * .048),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            secondary,
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: math.max(9, diameter * .038),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrbitLinearSummary extends StatelessWidget {
  const _OrbitLinearSummary({required this.items, this.onTap});

  final List<PlannerEntity> items;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      button: onTap != null,
      label: 'Today in orbit',
      value: _orbitSemanticValue(items),
      hint: onTap == null ? null : 'Open day plan',
      child: ExcludeSemantics(
        child: Align(
          alignment: Alignment.center,
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              splashFactory: reducedMotion ? NoSplash.splashFactory : null,
              highlightColor: reducedMotion ? Colors.transparent : null,
              onTap: onTap,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(16) / 16;
                  // Short landscape gives the orbit a deliberately narrow,
                  // shallow pane. Preserve the useful summary instead of
                  // forcing the decorative icon/arrow stack to overflow.
                  final minimalSummary =
                      constraints.maxHeight < 200 ||
                      (textScale >= 1.75 && constraints.maxHeight < 260);
                  final stacked =
                      constraints.maxWidth < 320 || textScale >= 1.75;
                  final icon = Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primaryContainer
                          : PerfectColors.apricotSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wb_sunny_outlined,
                      color: PerfectColors.apricot,
                    ),
                  );
                  final summary = _OrbitSummaryCopy(
                    items: items,
                    showNextTitle: !minimalSummary,
                  );
                  return Padding(
                    padding: const EdgeInsets.all(PerfectSpace.md),
                    child: minimalSummary
                        ? summary
                        : stacked
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              icon,
                              const SizedBox(height: PerfectSpace.sm),
                              summary,
                              if (onTap != null) ...[
                                const SizedBox(height: PerfectSpace.xs),
                                const Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Icon(Icons.arrow_forward_rounded),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              icon,
                              const SizedBox(width: PerfectSpace.sm),
                              Expanded(child: summary),
                              if (onTap != null) ...[
                                const SizedBox(width: PerfectSpace.xs),
                                const Icon(Icons.arrow_forward_rounded),
                              ],
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitSummaryCopy extends StatelessWidget {
  const _OrbitSummaryCopy({required this.items, required this.showNextTitle});

  final List<PlannerEntity> items;
  final bool showNextTitle;

  @override
  Widget build(BuildContext context) {
    final detail = items.isEmpty
        ? 'A calm slate. Capture the next thing that matters.'
        : showNextTitle
        ? '${items.length} open items · Next: \u2068${items.first.title}\u2069'
        : '${items.length} open items';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today, in orbit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.dark, required this.segments});

  final bool dark;
  final List<_OrbitSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = math.min(size.width, size.height);
    final radius = shortest * .345;
    final centerRadius = shortest * .225;
    final surface = dark ? const Color(0xff292c3d) : const Color(0xfffffdf9);
    final outline = dark ? const Color(0xff45495d) : PerfectColors.creamStroke;
    canvas.drawCircle(
      center,
      centerRadius,
      Paint()
        ..color = surface
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortest * .018),
    );
    canvas.drawCircle(center, centerRadius, Paint()..color = surface);
    canvas.drawCircle(
      center,
      centerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = outline,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * .044
      ..strokeCap = StrokeCap.round
      ..color = outline.withValues(alpha: .78);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    final gap = shortest * .012;
    for (final segment in segments) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * .046
        ..strokeCap = StrokeCap.round
        ..color = segment.color;
      canvas.drawArc(rect, segment.start, segment.sweep, false, paint);
      final point = Offset(
        center.dx + math.cos(segment.start + segment.sweep * .52) * radius,
        center.dy + math.sin(segment.start + segment.sweep * .52) * radius,
      );
      canvas.drawCircle(point, shortest * .042, Paint()..color = surface);
      canvas.drawCircle(point, shortest * .035, Paint()..color = segment.color);
      final number = TextPainter(
        text: TextSpan(
          text: '${segment.index + 1}',
          style: TextStyle(
            color: PerfectColors.ink,
            fontFamily: 'PlusJakarta',
            fontWeight: FontWeight.w800,
            fontSize: shortest * .037,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      number.paint(canvas, point - Offset(number.width / 2, number.height / 2));
      if (gap == 0) break;
    }
    final nowAngle = -math.pi / 2 + .18;
    final nowPoint = Offset(
      center.dx + math.cos(nowAngle) * radius,
      center.dy + math.sin(nowAngle) * radius,
    );
    canvas.drawCircle(nowPoint, shortest * .026, Paint()..color = surface);
    canvas.drawCircle(
      nowPoint,
      shortest * .02,
      Paint()..color = PerfectColors.apricot,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    if (oldDelegate.dark != dark ||
        oldDelegate.segments.length != segments.length) {
      return true;
    }
    for (var index = 0; index < segments.length; index++) {
      if (oldDelegate.segments[index] != segments[index]) return true;
    }
    return false;
  }
}

class _OrbitSegment {
  const _OrbitSegment({
    required this.index,
    required this.start,
    required this.sweep,
    required this.color,
  });

  final int index;
  final double start;
  final double sweep;
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OrbitSegment &&
          other.index == index &&
          other.start == start &&
          other.sweep == sweep &&
          other.color == color;

  @override
  int get hashCode => Object.hash(index, start, sweep, color);
}

List<_OrbitSegment> _segmentsFor(List<PlannerEntity> items) {
  const colors = <Color>[
    PerfectColors.apricot,
    PerfectColors.mint,
    PerfectColors.lilac,
  ];
  final count = items.isEmpty ? 0 : math.min(3, items.length);
  return List<_OrbitSegment>.generate(
    count,
    (index) => _OrbitSegment(
      index: index,
      start: -math.pi / 2 + index * 2.15,
      sweep: .95,
      color: colors[index],
    ),
    growable: false,
  );
}

String _orbitSemanticValue(List<PlannerEntity> items) {
  if (items.isEmpty) return 'No open items';
  final visibleTitles = items.take(3).map((item) => item.title).join(', ');
  final remainder = items.length - math.min(3, items.length);
  return '${items.length} open items: $visibleTitles'
      '${remainder == 0 ? '' : ', and $remainder more'}';
}
