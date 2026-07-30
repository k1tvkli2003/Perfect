import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// Live Flutter reconstruction of the selected lower-right board icon: a
/// dark center, three pastel orbital fragments, and an assertive check.
class PerfectMark extends StatelessWidget {
  const PerfectMark({super.key, this.size = 44, this.label = 'Perfect!'})
    : assert(size > 0);

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _PerfectMarkPainter(dark: dark)),
        ),
      ),
    );
  }
}

class PerfectWordmark extends StatelessWidget {
  const PerfectWordmark({
    super.key,
    this.fontSize = 34,
    this.includeMark = false,
  }) : assert(fontSize > 0);

  final double fontSize;
  final bool includeMark;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final scaledFontSize =
        (MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling).scale(
          fontSize,
        );
    final baseStyle = TextStyle(
      color: ink,
      fontFamily: 'PlusJakarta',
      fontFamilyFallback: const <String>['Vazirmatn'],
      fontSize: fontSize,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -fontSize * .032,
    );
    return Semantics(
      label: 'Perfect!',
      header: true,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Directionality(
            // Product marks never mirror with the surrounding locale.
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (includeMark) ...[
                  PerfectMark(size: scaledFontSize * .98),
                  const SizedBox(width: PerfectSpace.xs),
                ],
                Text.rich(
                  TextSpan(
                    text: 'Perfect',
                    style: baseStyle,
                    children: <InlineSpan>[
                      TextSpan(
                        text: '!',
                        style: baseStyle.copyWith(
                          color: PerfectColors.lilac,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerfectMarkPainter extends CustomPainter {
  const _PerfectMarkPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final scale = shortest / 100;
    final center = Offset(size.width / 2, size.height / 2);
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(28 * scale),
    );
    final tilePaint = Paint()
      ..color = dark ? const Color(0xff2d3041) : PerfectColors.creamElevated;
    canvas.drawRRect(tile, tilePaint);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11 * scale
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: 31 * scale);
    ringPaint.color = PerfectColors.apricot;
    canvas.drawArc(rect, -2.75, .92, false, ringPaint);
    ringPaint.color = PerfectColors.mint;
    canvas.drawArc(rect, 1.65, .86, false, ringPaint);
    ringPaint.color = PerfectColors.lilac;
    canvas.drawArc(rect, .52, .9, false, ringPaint);
    canvas.drawCircle(
      center,
      10.5 * scale,
      Paint()..color = dark ? const Color(0xfffcf8f2) : PerfectColors.ink,
    );
    final check = Path()
      ..moveTo(61 * scale, 42 * scale)
      ..lineTo(68 * scale, 49 * scale)
      ..lineTo(83 * scale, 33 * scale);
    canvas.drawPath(
      check,
      Paint()
        ..color = dark ? const Color(0xfffcf8f2) : PerfectColors.ink
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 8 * scale,
    );
  }

  @override
  bool shouldRepaint(covariant _PerfectMarkPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
