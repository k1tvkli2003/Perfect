import 'package:flutter/material.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// The approved Perfect! mark, shared verbatim with Android and Windows.
class PerfectMark extends StatelessWidget {
  const PerfectMark({super.key, this.size = 44, this.label = 'Perfect!'})
    : assert(size > 0);

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final physicalPixels = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 512)
        .toInt();
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            'assets/brand/perfect-launcher.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            cacheWidth: physicalPixels,
            cacheHeight: physicalPixels,
          ),
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
