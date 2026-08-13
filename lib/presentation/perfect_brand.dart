import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// The approved Perfect! mark, shared verbatim with Android and Windows.
class PerfectMark extends StatelessWidget {
  const PerfectMark({super.key, this.size = 44, this.label = 'Perfect!'})
    : assert(size > 0);

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final highContrast = PerfectContrast.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = highContrast
        ? dark
              ? 'assets/brand/perfect-mark-high-contrast-dark.png'
              : 'assets/brand/perfect-mark-high-contrast-light.png'
        : dark
        ? 'assets/brand/perfect-mark-dark.png'
        : 'assets/brand/perfect-launcher.png';
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
            asset,
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
    final scaledFontSize =
        (MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling).scale(
          fontSize,
        );
    final highContrast = PerfectContrast.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = highContrast
        ? dark
              ? 'assets/brand/perfect-wordmark-high-contrast-dark.svg'
              : 'assets/brand/perfect-wordmark-high-contrast-light.svg'
        : dark
        ? 'assets/brand/perfect-wordmark-dark.svg'
        : 'assets/brand/perfect-wordmark.svg';
    final wordmark = SizedBox(
      key: const ValueKey<String>('perfect-wordmark-visual'),
      height: scaledFontSize * 1.16,
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        alignment: AlignmentDirectional.centerStart,
        excludeFromSemantics: true,
      ),
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
                  PerfectMark(size: scaledFontSize * 1.12),
                  const SizedBox(width: PerfectSpace.xs),
                ],
                wordmark,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
