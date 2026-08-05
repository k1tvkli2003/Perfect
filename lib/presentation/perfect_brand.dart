import 'package:flutter/material.dart';
import 'package:perfect/presentation/perfect_pictogram.dart';
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
            frameBuilder: (context, child, frame, loadedSynchronously) {
              if (loadedSynchronously || frame != null) return child;
              return PerfectPictogram(name: 'compass', size: size);
            },
            errorBuilder: (context, error, stackTrace) =>
                PerfectPictogram(name: 'compass', size: size),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final wordmark = SizedBox(
      key: const ValueKey<String>('perfect-wordmark-visual'),
      height: scaledFontSize * 1.16,
      child: Image.asset(
        dark
            ? 'assets/brand/perfect-wordmark-dark.png'
            : 'assets/brand/perfect-wordmark.png',
        fit: BoxFit.contain,
        alignment: AlignmentDirectional.centerStart,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
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
                  PerfectMark(size: scaledFontSize * .98),
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
