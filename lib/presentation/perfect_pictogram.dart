import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// Project-owned vector pictograms for concepts that would otherwise drift
/// toward keyboard emoji or unrelated icon families.
///
/// The artwork uses the approved Day Compass palette and one optical system:
/// a 24×24 view box, rounded 1.35–2.25 strokes, and simple silhouettes that
/// remain legible on Android, Windows, and high-density tablet displays.
class PerfectPictogram extends StatelessWidget {
  const PerfectPictogram({
    super.key,
    required this.name,
    this.size = 24,
    this.semanticLabel,
    this.framed = false,
  }) : assert(size > 0);

  final String name;
  final double size;
  final String? semanticLabel;
  final bool framed;

  static const supportedNames = <String>{
    'compass',
    'task',
    'habit',
    'work',
    'study',
    'health',
    'home',
    'idea',
    'star',
    'ai',
    'voice',
    'send',
    'capture',
    'calendar',
    'finance',
    'label',
  };

  static String normalizeName(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'default' || normalized == 'personal') return 'compass';
    return supportedNames.contains(normalized) ? normalized : 'label';
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeName(name);
    final picture = SvgPicture.asset(
      'assets/icons/perfect/$normalized.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    final artwork = framed
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? PerfectColors.creamSurfaceHigh
                  : PerfectColors.creamSurfaceLow,
              borderRadius: BorderRadius.circular(size * .36),
              border: Border.all(
                color: PerfectColors.creamStroke.withValues(alpha: .82),
              ),
            ),
            child: Padding(padding: EdgeInsets.all(size * .16), child: picture),
          )
        : picture;

    if (semanticLabel case final String label) {
      return Semantics(
        image: true,
        label: label,
        child: ExcludeSemantics(child: artwork),
      );
    }
    return ExcludeSemantics(child: artwork);
  }
}
