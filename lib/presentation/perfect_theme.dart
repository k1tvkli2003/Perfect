import 'package:flutter/material.dart';

abstract final class PerfectColors {
  static const ink = Color(0xff122033);
  static const mutedInk = Color(0xff66758a);
  static const cream = Color(0xfff7f7f5);
  static const creamElevated = Color(0xffffffff);
  static const creamSurfaceLow = Color(0xfff1f4f7);
  static const creamSurface = Color(0xfffbfbfa);
  static const creamSurfaceHigh = Color(0xffe9eef4);
  static const creamSurfaceHighest = Color(0xffdfe7ef);
  static const creamStroke = Color(0xffd9e1ea);
  static const accessibleOutline = Color(0xff66758a);
  static const apricot = Color(0xff2778e8);
  static const apricotAction = Color(0xff175cd3);
  static const apricotSoft = Color(0xffe8f2ff);
  static const mint = Color(0xff2dbf73);
  // A clearer blue-green reserved for live sync. It stays distinguishable
  // from the softer mint used for habits and completion.
  static const sync = Color(0xff2e9b91);
  static const mintSoft = Color(0xffe4f4e8);
  static const lilac = Color(0xffa79add);
  static const lilacAction = Color(0xff7f68c9);
  static const lilacSoft = Color(0xffeeeafd);
  static const danger = Color(0xffc44b56);
  static const dangerSoft = Color(0xffffe3e5);
  static const onDangerSoft = Color(0xff751b28);
  static const night = Color(0xff07111f);
  static const nightSurfaceLow = Color(0xff0b192a);
  static const nightSurface = Color(0xff11243a);
  static const nightSurfaceHigh = Color(0xff172d47);
  static const nightSurfaceHighest = Color(0xff203a59);
  static const nightStroke = Color(0xff2b4768);
  static const accessibleNightOutline = Color(0xff91a8c4);
}

abstract final class PerfectSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 48.0;
  static const giant = 64.0;
}

/// Semantic corner radii shared by every Perfect! surface.
///
/// The scale intentionally has only a handful of stops. Components can choose
/// the stop that matches their role without inventing a new radius for every
/// screen.
abstract final class PerfectRadius {
  static const compact = 12.0;
  static const control = 16.0;
  static const card = 22.0;
  static const panel = 28.0;
  static const dock = 32.0;
  static const pill = 999.0;
}

/// The authored semantic color registry shared by Flutter surfaces, custom
/// painters, status affordances and native appearance projections.
///
/// Components consume roles from this extension instead of branching on
/// brightness or importing a light-only swatch. High contrast is an authored
/// product here: it has its own boundaries, status colors and focus role.
@immutable
class PerfectSemanticTheme extends ThemeExtension<PerfectSemanticTheme> {
  const PerfectSemanticTheme({
    required this.id,
    required this.brightness,
    required this.highContrast,
    required this.canvas,
    required this.surfaceLowest,
    required this.surfaceLow,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.primaryVivid,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryVivid,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryVivid,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.sync,
    required this.syncContainer,
    required this.onSyncContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.outline,
    required this.outlineVariant,
    required this.focus,
    required this.shadow,
  });

  final String id;
  final Brightness brightness;
  final bool highContrast;
  final Color canvas;
  final Color surfaceLowest;
  final Color surfaceLow;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color ink;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color primaryVivid;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryVivid;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryVivid;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color sync;
  final Color syncContainer;
  final Color onSyncContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color outline;
  final Color outlineVariant;
  final Color focus;
  final Color shadow;

  static PerfectSemanticTheme of(BuildContext context) =>
      Theme.of(context).extension<PerfectSemanticTheme>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  static const light = PerfectSemanticTheme(
    id: 'theme-light-paper-ledger',
    brightness: Brightness.light,
    highContrast: false,
    canvas: Color(0xfff7f7f5),
    surfaceLowest: Color(0xffffffff),
    surfaceLow: Color(0xfff1f4f7),
    surface: Color(0xfffbfbfa),
    surfaceHigh: Color(0xffe9eef4),
    surfaceHighest: Color(0xffdfe7ef),
    ink: Color(0xff122033),
    muted: Color(0xff53647a),
    primary: Color(0xff175cd3),
    onPrimary: Color(0xffffffff),
    primaryVivid: Color(0xff2778e8),
    primaryContainer: Color(0xffe8f2ff),
    onPrimaryContainer: Color(0xff0c3470),
    secondary: Color(0xff247a4d),
    onSecondary: Color(0xffffffff),
    secondaryVivid: Color(0xff2dbf73),
    secondaryContainer: Color(0xffe3f6eb),
    onSecondaryContainer: Color(0xff113f29),
    tertiary: Color(0xff486581),
    onTertiary: Color(0xffffffff),
    tertiaryVivid: Color(0xff6d8ca9),
    tertiaryContainer: Color(0xffe8eef4),
    onTertiaryContainer: Color(0xff263f57),
    sync: Color(0xff16796f),
    syncContainer: Color(0xffd8f3ef),
    onSyncContainer: Color(0xff073b37),
    warning: Color(0xff8a5a00),
    warningContainer: Color(0xffffefc6),
    onWarningContainer: Color(0xff422900),
    danger: Color(0xffc43c4e),
    dangerContainer: Color(0xffffe5e8),
    onDangerContainer: Color(0xff711426),
    outline: Color(0xff68778a),
    outlineVariant: Color(0xffd9e1ea),
    focus: Color(0xff175cd3),
    shadow: Color(0xff203047),
  );

  static const dark = PerfectSemanticTheme(
    id: 'theme-dark-midnight-command',
    brightness: Brightness.dark,
    highContrast: false,
    canvas: Color(0xff07111f),
    surfaceLowest: Color(0xff091624),
    surfaceLow: Color(0xff0b192a),
    surface: Color(0xff11243a),
    surfaceHigh: Color(0xff172d47),
    surfaceHighest: Color(0xff203a59),
    ink: Color(0xfff4f7fc),
    muted: Color(0xffb4c3d7),
    primary: Color(0xff8ab4ff),
    onPrimary: Color(0xff06172d),
    primaryVivid: Color(0xff4e8fff),
    primaryContainer: Color(0xff173b6e),
    onPrimaryContainer: Color(0xffdbe8ff),
    secondary: Color(0xff91e1b5),
    onSecondary: Color(0xff072317),
    secondaryVivid: Color(0xff46d68a),
    secondaryContainer: Color(0xff173e2c),
    onSecondaryContainer: Color(0xffd8f9e7),
    tertiary: Color(0xffbdd2ea),
    onTertiary: Color(0xff102238),
    tertiaryVivid: Color(0xff8fb0cf),
    tertiaryContainer: Color(0xff243b55),
    onTertiaryContainer: Color(0xffe0ecf8),
    sync: Color(0xff74d8cd),
    syncContainer: Color(0xff173d3a),
    onSyncContainer: Color(0xffcbfff8),
    warning: Color(0xffffcf77),
    warningContainer: Color(0xff4c360c),
    onWarningContainer: Color(0xfffff0c8),
    danger: Color(0xffff9da9),
    dangerContainer: Color(0xff552635),
    onDangerContainer: Color(0xffffe2e6),
    outline: Color(0xff91a8c4),
    outlineVariant: Color(0xff2b4768),
    focus: Color(0xffa9c7ff),
    shadow: Color(0xff02060c),
  );

  static const highContrastLight = PerfectSemanticTheme(
    id: 'theme-hc-light-clarity',
    brightness: Brightness.light,
    highContrast: true,
    canvas: Color(0xffffffff),
    surfaceLowest: Color(0xffffffff),
    surfaceLow: Color(0xfff7f7f9),
    surface: Color(0xffffffff),
    surfaceHigh: Color(0xffe8e8ec),
    surfaceHighest: Color(0xffd9d9df),
    ink: Color(0xff090a0f),
    muted: Color(0xff292b35),
    primary: Color(0xff6d2e00),
    onPrimary: Color(0xffffffff),
    primaryVivid: Color(0xff9b4300),
    primaryContainer: Color(0xfffff0e1),
    onPrimaryContainer: Color(0xff160900),
    secondary: Color(0xff145d34),
    onSecondary: Color(0xffffffff),
    secondaryVivid: Color(0xff207a47),
    secondaryContainer: Color(0xffe8f8ee),
    onSecondaryContainer: Color(0xff062012),
    tertiary: Color(0xff3e2a82),
    onTertiary: Color(0xffffffff),
    tertiaryVivid: Color(0xff5740a5),
    tertiaryContainer: Color(0xfff0ecff),
    onTertiaryContainer: Color(0xff10072e),
    sync: Color(0xff00564f),
    syncContainer: Color(0xffe1fffb),
    onSyncContainer: Color(0xff001f1c),
    warning: Color(0xff633d00),
    warningContainer: Color(0xfffff4cc),
    onWarningContainer: Color(0xff211300),
    danger: Color(0xff8c1025),
    dangerContainer: Color(0xffffe8eb),
    onDangerContainer: Color(0xff2f000a),
    outline: Color(0xff4a4b55),
    outlineVariant: Color(0xff70717d),
    focus: Color(0xff6d2e00),
    shadow: Color(0x00000000),
  );

  static const highContrastDark = PerfectSemanticTheme(
    id: 'theme-hc-dark-clarity',
    brightness: Brightness.dark,
    highContrast: true,
    canvas: Color(0xff000000),
    surfaceLowest: Color(0xff000000),
    surfaceLow: Color(0xff050609),
    surface: Color(0xff08090d),
    surfaceHigh: Color(0xff171922),
    surfaceHighest: Color(0xff242630),
    ink: Color(0xffffffff),
    muted: Color(0xfff0edf7),
    primary: Color(0xffffd1a3),
    onPrimary: Color(0xff100700),
    primaryVivid: Color(0xffffbd7c),
    primaryContainer: Color(0xff3b1d00),
    onPrimaryContainer: Color(0xfffff0df),
    secondary: Color(0xffaef2c4),
    onSecondary: Color(0xff001308),
    secondaryVivid: Color(0xff89e4a7),
    secondaryContainer: Color(0xff092b19),
    onSecondaryContainer: Color(0xffe2ffea),
    tertiary: Color(0xffded4ff),
    onTertiary: Color(0xff11092f),
    tertiaryVivid: Color(0xffc5b7ff),
    tertiaryContainer: Color(0xff21174f),
    onTertiaryContainer: Color(0xfff4f0ff),
    sync: Color(0xff99fff3),
    syncContainer: Color(0xff003d38),
    onSyncContainer: Color(0xffe0fffb),
    warning: Color(0xffffe59a),
    warningContainer: Color(0xff422c00),
    onWarningContainer: Color(0xfffff5d8),
    danger: Color(0xffffc2c8),
    dangerContainer: Color(0xff490716),
    onDangerContainer: Color(0xffffecef),
    outline: Color(0xffffffff),
    outlineVariant: Color(0xffa6a6b0),
    focus: Color(0xffffd1a3),
    shadow: Color(0x00000000),
  );

  @override
  PerfectSemanticTheme copyWith() => this;

  @override
  PerfectSemanticTheme lerp(
    covariant ThemeExtension<PerfectSemanticTheme>? other,
    double t,
  ) {
    if (other is! PerfectSemanticTheme) return this;
    Color blend(Color from, Color to) => Color.lerp(from, to, t)!;
    return PerfectSemanticTheme(
      id: t < .5 ? id : other.id,
      brightness: t < .5 ? brightness : other.brightness,
      highContrast: t < .5 ? highContrast : other.highContrast,
      canvas: blend(canvas, other.canvas),
      surfaceLowest: blend(surfaceLowest, other.surfaceLowest),
      surfaceLow: blend(surfaceLow, other.surfaceLow),
      surface: blend(surface, other.surface),
      surfaceHigh: blend(surfaceHigh, other.surfaceHigh),
      surfaceHighest: blend(surfaceHighest, other.surfaceHighest),
      ink: blend(ink, other.ink),
      muted: blend(muted, other.muted),
      primary: blend(primary, other.primary),
      onPrimary: blend(onPrimary, other.onPrimary),
      primaryVivid: blend(primaryVivid, other.primaryVivid),
      primaryContainer: blend(primaryContainer, other.primaryContainer),
      onPrimaryContainer: blend(onPrimaryContainer, other.onPrimaryContainer),
      secondary: blend(secondary, other.secondary),
      onSecondary: blend(onSecondary, other.onSecondary),
      secondaryVivid: blend(secondaryVivid, other.secondaryVivid),
      secondaryContainer: blend(secondaryContainer, other.secondaryContainer),
      onSecondaryContainer: blend(
        onSecondaryContainer,
        other.onSecondaryContainer,
      ),
      tertiary: blend(tertiary, other.tertiary),
      onTertiary: blend(onTertiary, other.onTertiary),
      tertiaryVivid: blend(tertiaryVivid, other.tertiaryVivid),
      tertiaryContainer: blend(tertiaryContainer, other.tertiaryContainer),
      onTertiaryContainer: blend(
        onTertiaryContainer,
        other.onTertiaryContainer,
      ),
      sync: blend(sync, other.sync),
      syncContainer: blend(syncContainer, other.syncContainer),
      onSyncContainer: blend(onSyncContainer, other.onSyncContainer),
      warning: blend(warning, other.warning),
      warningContainer: blend(warningContainer, other.warningContainer),
      onWarningContainer: blend(onWarningContainer, other.onWarningContainer),
      danger: blend(danger, other.danger),
      dangerContainer: blend(dangerContainer, other.dangerContainer),
      onDangerContainer: blend(onDangerContainer, other.onDangerContainer),
      outline: blend(outline, other.outline),
      outlineVariant: blend(outlineVariant, other.outlineVariant),
      focus: blend(focus, other.focus),
      shadow: blend(shadow, other.shadow),
    );
  }
}

abstract final class PerfectContrast {
  static bool of(BuildContext context) =>
      PerfectSemanticTheme.of(context).highContrast ||
      MediaQuery.maybeOf(context)?.highContrast == true;
}

/// Theme-level material and state-layer tokens for branded surfaces.
///
/// Keeping these values in a [ThemeExtension] lets custom Flutter surfaces use
/// the same light/dark interpolation as Material components instead of
/// hard-coding translucent whites, borders and shadows in individual widgets.
@immutable
class PerfectSurfaceTheme extends ThemeExtension<PerfectSurfaceTheme> {
  const PerfectSurfaceTheme({
    required this.canvas,
    required this.canvasAccent,
    required this.surface,
    required this.surfaceRaised,
    required this.glass,
    required this.glassStrong,
    required this.stroke,
    required this.strokeStrong,
    required this.focusRing,
    required this.hoverLayer,
    required this.focusLayer,
    required this.pressedLayer,
    required this.selectedLayer,
    required this.ambientShadow,
    required this.keyShadow,
    required this.glassBlur,
    required this.glassBlurStrong,
    required this.disabledOpacity,
  });

  final Color canvas;
  final Color canvasAccent;
  final Color surface;
  final Color surfaceRaised;
  final Color glass;
  final Color glassStrong;
  final Color stroke;
  final Color strokeStrong;
  final Color focusRing;
  final Color hoverLayer;
  final Color focusLayer;
  final Color pressedLayer;
  final Color selectedLayer;
  final Color ambientShadow;
  final Color keyShadow;
  final double glassBlur;
  final double glassBlurStrong;
  final double disabledOpacity;

  static PerfectSurfaceTheme of(BuildContext context) =>
      Theme.of(context).extension<PerfectSurfaceTheme>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  static const light = PerfectSurfaceTheme(
    canvas: Color(0xfffffcf7),
    canvasAccent: Color(0xfffff4e8),
    surface: Color(0xfffffaf4),
    surfaceRaised: Color(0xffffffff),
    glass: Color(0xf7ffffff),
    glassStrong: Color(0xfcffffff),
    stroke: Color(0xffddd4cb),
    strokeStrong: Color(0xff777280),
    focusRing: Color(0xff8e4208),
    hoverLayer: Color(0x149d4c0b),
    focusLayer: Color(0x1f9d4c0b),
    pressedLayer: Color(0x299d4c0b),
    selectedLayer: Color(0x33ffa34d),
    ambientShadow: Color(0x144b3d32),
    keyShadow: Color(0x1f4b3d32),
    glassBlur: 18,
    glassBlurStrong: 26,
    disabledOpacity: .46,
  );

  static const dark = PerfectSurfaceTheme(
    canvas: Color(0xff141620),
    canvasAccent: Color(0xff201e2b),
    surface: Color(0xff1a1d28),
    surfaceRaised: Color(0xff292d3d),
    glass: Color(0xe81e2230),
    glassStrong: Color(0xf5282c3c),
    stroke: Color(0xff5a5f72),
    strokeStrong: Color(0xff9b97aa),
    focusRing: Color(0xffffd0a2),
    hoverLayer: Color(0x1fffc184),
    focusLayer: Color(0x2effc184),
    pressedLayer: Color(0x3dffc184),
    selectedLayer: Color(0x3dffc184),
    ambientShadow: Color(0x3d080910),
    keyShadow: Color(0x66080910),
    glassBlur: 18,
    glassBlurStrong: 26,
    disabledOpacity: .48,
  );

  static const highContrastLight = PerfectSurfaceTheme(
    canvas: Color(0xffffffff),
    canvasAccent: Color(0xffffffff),
    surface: Color(0xfff7f7f9),
    surfaceRaised: Color(0xffffffff),
    glass: Color(0xffffffff),
    glassStrong: Color(0xffffffff),
    stroke: Color(0xff70717d),
    strokeStrong: Color(0xff4a4b55),
    focusRing: Color(0xff6d2e00),
    hoverLayer: Color(0x1f6d2e00),
    focusLayer: Color(0x336d2e00),
    pressedLayer: Color(0x476d2e00),
    selectedLayer: Color(0x339b4300),
    ambientShadow: Color(0x00000000),
    keyShadow: Color(0x00000000),
    glassBlur: 0,
    glassBlurStrong: 0,
    disabledOpacity: .58,
  );

  static const highContrastDark = PerfectSurfaceTheme(
    canvas: Color(0xff000000),
    canvasAccent: Color(0xff000000),
    surface: Color(0xff050609),
    surfaceRaised: Color(0xff171922),
    glass: Color(0xff08090d),
    glassStrong: Color(0xff08090d),
    stroke: Color(0xffa6a6b0),
    strokeStrong: Color(0xffffffff),
    focusRing: Color(0xffffd1a3),
    hoverLayer: Color(0x33ffd1a3),
    focusLayer: Color(0x47ffd1a3),
    pressedLayer: Color(0x5cffd1a3),
    selectedLayer: Color(0x47ffbd7c),
    ambientShadow: Color(0x00000000),
    keyShadow: Color(0x00000000),
    glassBlur: 0,
    glassBlurStrong: 0,
    disabledOpacity: .62,
  );

  @override
  PerfectSurfaceTheme copyWith({
    Color? canvas,
    Color? canvasAccent,
    Color? surface,
    Color? surfaceRaised,
    Color? glass,
    Color? glassStrong,
    Color? stroke,
    Color? strokeStrong,
    Color? focusRing,
    Color? hoverLayer,
    Color? focusLayer,
    Color? pressedLayer,
    Color? selectedLayer,
    Color? ambientShadow,
    Color? keyShadow,
    double? glassBlur,
    double? glassBlurStrong,
    double? disabledOpacity,
  }) => PerfectSurfaceTheme(
    canvas: canvas ?? this.canvas,
    canvasAccent: canvasAccent ?? this.canvasAccent,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    glass: glass ?? this.glass,
    glassStrong: glassStrong ?? this.glassStrong,
    stroke: stroke ?? this.stroke,
    strokeStrong: strokeStrong ?? this.strokeStrong,
    focusRing: focusRing ?? this.focusRing,
    hoverLayer: hoverLayer ?? this.hoverLayer,
    focusLayer: focusLayer ?? this.focusLayer,
    pressedLayer: pressedLayer ?? this.pressedLayer,
    selectedLayer: selectedLayer ?? this.selectedLayer,
    ambientShadow: ambientShadow ?? this.ambientShadow,
    keyShadow: keyShadow ?? this.keyShadow,
    glassBlur: glassBlur ?? this.glassBlur,
    glassBlurStrong: glassBlurStrong ?? this.glassBlurStrong,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  PerfectSurfaceTheme lerp(
    covariant ThemeExtension<PerfectSurfaceTheme>? other,
    double t,
  ) {
    if (other is! PerfectSurfaceTheme) return this;
    return PerfectSurfaceTheme(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      canvasAccent: Color.lerp(canvasAccent, other.canvasAccent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      stroke: Color.lerp(stroke, other.stroke, t)!,
      strokeStrong: Color.lerp(strokeStrong, other.strokeStrong, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      hoverLayer: Color.lerp(hoverLayer, other.hoverLayer, t)!,
      focusLayer: Color.lerp(focusLayer, other.focusLayer, t)!,
      pressedLayer: Color.lerp(pressedLayer, other.pressedLayer, t)!,
      selectedLayer: Color.lerp(selectedLayer, other.selectedLayer, t)!,
      ambientShadow: Color.lerp(ambientShadow, other.ambientShadow, t)!,
      keyShadow: Color.lerp(keyShadow, other.keyShadow, t)!,
      glassBlur: _lerpDouble(glassBlur, other.glassBlur, t),
      glassBlurStrong: _lerpDouble(glassBlurStrong, other.glassBlurStrong, t),
      disabledOpacity: _lerpDouble(disabledOpacity, other.disabledOpacity, t),
    );
  }
}

/// Semantic motion roles shared by routes, overlays and microinteractions.
///
/// Callers choose the relationship they need instead of inventing a duration.
/// The corresponding storyboard lives under the Stage 09 motion evidence.
enum PerfectMotionRole {
  micro,
  quick,
  standard,
  emphasized,
  modal,
  route,
  feedback,
}

@immutable
class PerfectMotionSpec {
  const PerfectMotionSpec({
    required this.duration,
    required this.reverseDuration,
    required this.curve,
    required this.reverseCurve,
  });

  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve reverseCurve;
}

abstract final class PerfectMotion {
  /// Pointer and keyboard acknowledgement. It should feel immediate.
  static const micro = Duration(milliseconds: 90);
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 240);
  static const emphasized = Duration(milliseconds: 320);

  /// Sheets and full-screen creation flows need enough travel to communicate
  /// a change of context without turning a planner action into theatre.
  static const modal = Duration(milliseconds: 360);
  static const route = Duration(milliseconds: 380);
  static const feedback = Duration(milliseconds: 600);
  static const stagedGap = Duration(milliseconds: 56);
  static const calmLoop = Duration(milliseconds: 1500);
  static const heartbeat = Duration(milliseconds: 1680);
  static const heartbeatRest = Duration(milliseconds: 2200);

  /// Optical travel is expressed in logical pixels when the relationship is
  /// local to one workspace. This keeps a phone and a wide Windows window
  /// equally calm instead of moving content by a viewport percentage.
  static const routeEnterTravel = 14.0;
  static const routeExitTravel = 8.0;
  static const routeVerticalTravel = 6.0;
  static const titleRise = 10.0;
  static const dialogRise = 12.0;
  static const dialogScaleBegin = .96;
  static const wizardTravel = 12.0;
  static const stagedScaleBegin = .985;

  static const Curve productive = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
  static const Curve modalEnter = Cubic(.22, 1, .36, 1);

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration responsive(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  static PerfectMotionSpec spec(PerfectMotionRole role) => switch (role) {
    PerfectMotionRole.micro => const PerfectMotionSpec(
      duration: micro,
      reverseDuration: micro,
      curve: productive,
      reverseCurve: exit,
    ),
    PerfectMotionRole.quick => const PerfectMotionSpec(
      duration: quick,
      reverseDuration: quick,
      curve: productive,
      reverseCurve: exit,
    ),
    PerfectMotionRole.standard => const PerfectMotionSpec(
      duration: standard,
      reverseDuration: quick,
      curve: productive,
      reverseCurve: exit,
    ),
    PerfectMotionRole.emphasized => const PerfectMotionSpec(
      duration: emphasized,
      reverseDuration: standard,
      curve: modalEnter,
      reverseCurve: exit,
    ),
    PerfectMotionRole.modal => const PerfectMotionSpec(
      duration: modal,
      reverseDuration: standard,
      curve: modalEnter,
      reverseCurve: exit,
    ),
    PerfectMotionRole.route => const PerfectMotionSpec(
      duration: route,
      reverseDuration: standard,
      curve: modalEnter,
      reverseCurve: exit,
    ),
    PerfectMotionRole.feedback => const PerfectMotionSpec(
      duration: feedback,
      reverseDuration: standard,
      curve: productive,
      reverseCurve: exit,
    ),
  };

  /// Removes spatial movement while preserving the destination geometry.
  static Offset responsiveOffset(BuildContext context, Offset offset) =>
      reduced(context) ? Offset.zero : offset;

  /// Removes press/enter scaling for reduced-motion users.
  static double responsiveScale(BuildContext context, double scale) =>
      reduced(context) ? 1 : scale;

  static AnimationStyle style(
    BuildContext context, {
    Duration duration = standard,
    Duration? reverseDuration,
    Curve curve = productive,
    Curve reverseCurve = exit,
  }) => AnimationStyle(
    duration: responsive(context, duration),
    reverseDuration: responsive(context, reverseDuration ?? duration),
    curve: curve,
    reverseCurve: reverseCurve,
  );

  static AnimationStyle roleStyle(
    BuildContext context,
    PerfectMotionRole role,
  ) {
    final motion = spec(role);
    return style(
      context,
      duration: motion.duration,
      reverseDuration: motion.reverseDuration,
      curve: motion.curve,
      reverseCurve: motion.reverseCurve,
    );
  }

  static AnimationStyle dialogStyle(BuildContext context) =>
      roleStyle(context, PerfectMotionRole.modal);

  static AnimationStyle menuStyle(BuildContext context) =>
      roleStyle(context, PerfectMotionRole.quick);

  /// The shared route style for bottom sheets. Keeping it here makes editor,
  /// log and focus surfaces feel related instead of inheriting a platform
  /// default that is too subtle for the Perfect interaction system.
  static AnimationStyle modalSheetStyle(BuildContext context) =>
      roleStyle(context, PerfectMotionRole.modal);
}

double _lerpDouble(double a, double b, double t) => a + ((b - a) * t);

abstract final class PerfectTheme {
  static ThemeData light() => _theme(PerfectSemanticTheme.light);
  static ThemeData dark() => _theme(PerfectSemanticTheme.dark);
  static ThemeData highContrastLight() =>
      _theme(PerfectSemanticTheme.highContrastLight);
  static ThemeData highContrastDark() =>
      _theme(PerfectSemanticTheme.highContrastDark);

  static ThemeData _theme(PerfectSemanticTheme semantic) {
    final brightness = semantic.brightness;
    final dark = brightness == Brightness.dark;
    final highContrast = semantic.highContrast;
    final surface = semantic.surface;
    final background = semantic.canvas;
    final foreground = semantic.ink;
    final muted = semantic.muted;
    final primary = semantic.primary;
    final secondary = semantic.secondary;
    final tertiary = semantic.tertiary;
    final inputFill = semantic.surfaceLowest;
    final surfaces = switch ((dark, highContrast)) {
      (false, false) => PerfectSurfaceTheme.light,
      (true, false) => PerfectSurfaceTheme.dark,
      (false, true) => PerfectSurfaceTheme.highContrastLight,
      (true, true) => PerfectSurfaceTheme.highContrastDark,
    };
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: semantic.onPrimary,
      primaryContainer: semantic.primaryContainer,
      onPrimaryContainer: semantic.onPrimaryContainer,
      secondary: secondary,
      onSecondary: semantic.onSecondary,
      secondaryContainer: semantic.secondaryContainer,
      onSecondaryContainer: semantic.onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: semantic.onTertiary,
      tertiaryContainer: semantic.tertiaryContainer,
      onTertiaryContainer: semantic.onTertiaryContainer,
      error: semantic.danger,
      onError: semantic.onPrimary,
      errorContainer: semantic.dangerContainer,
      onErrorContainer: semantic.onDangerContainer,
      surface: surface,
      onSurface: foreground,
      surfaceDim: dark ? semantic.canvas : semantic.surfaceHighest,
      surfaceBright: semantic.surfaceHigh,
      surfaceContainerLowest: semantic.surfaceLowest,
      surfaceContainerLow: semantic.surfaceLow,
      surfaceContainer: semantic.surface,
      surfaceContainerHigh: semantic.surfaceHigh,
      surfaceContainerHighest: semantic.surfaceHighest,
      onSurfaceVariant: muted,
      outline: semantic.outline,
      outlineVariant: semantic.outlineVariant,
      shadow: semantic.shadow,
      scrim: semantic.ink.withValues(alpha: highContrast ? .78 : .52),
      inverseSurface: semantic.ink,
      onInverseSurface: semantic.canvas,
      inversePrimary: semantic.primaryVivid,
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'PlusJakarta',
      // InkRipple is predictable on both Skia Android and Windows desktop.
      // The branded state layers below provide the visual character.
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: surfaces.focusLayer,
      hoverColor: surfaces.hoverLayer,
      highlightColor: surfaces.pressedLayer,
      disabledColor: scheme.onSurface.withValues(
        alpha: surfaces.disabledOpacity,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PerfectPageTransitionsBuilder(
            axis: Axis.vertical,
          ),
          TargetPlatform.windows: PerfectPageTransitionsBuilder(
            axis: Axis.horizontal,
          ),
        },
      ),
    );
    final text = base.textTheme.apply(
      fontFamily: 'PlusJakarta',
      fontFamilyFallback: const <String>['Vazirmatn'],
      bodyColor: foreground,
      displayColor: foreground,
    );
    final textTheme = text.copyWith(
      displayLarge: text.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.08,
      ),
      displayMedium: text.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.1,
      ),
      displaySmall: text.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.12,
      ),
      headlineLarge: text.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.16,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.2,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.22,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.25,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
      ),
      titleSmall: text.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.32,
      ),
      bodyLarge: text.bodyLarge?.copyWith(letterSpacing: 0, height: 1.45),
      bodyMedium: text.bodyMedium?.copyWith(letterSpacing: 0, height: 1.45),
      bodySmall: text.bodySmall?.copyWith(letterSpacing: 0, height: 1.4),
      labelLarge: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
      ),
      labelMedium: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
      ),
      labelSmall: text.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
      ),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PerfectRadius.control),
    );
    final controlPadding = const EdgeInsets.symmetric(
      horizontal: PerfectSpace.lg,
      vertical: PerfectSpace.sm,
    );
    final minimumControlSize = const WidgetStatePropertyAll<Size>(Size(48, 48));
    final buttonPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
      controlPadding,
    );
    final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(controlShape);
    final buttonTextStyle = WidgetStatePropertyAll<TextStyle?>(
      textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );
    Color? actionOverlay(Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) return surfaces.pressedLayer;
      if (states.contains(WidgetState.focused)) return surfaces.focusLayer;
      if (states.contains(WidgetState.hovered)) return surfaces.hoverLayer;
      return Colors.transparent;
    }

    Color? filledBackground(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.surfaceContainerHighest.withValues(alpha: .76);
      }
      return highContrast ? scheme.primary : semantic.primaryVivid;
    }

    Color? actionForeground(Set<WidgetState> states) =>
        states.contains(WidgetState.disabled)
        ? scheme.onSurface.withValues(alpha: surfaces.disabledOpacity)
        : (highContrast ? scheme.onPrimary : semantic.onPrimary);

    final filledButtonStyle = ButtonStyle(
      animationDuration: PerfectMotion.standard,
      minimumSize: minimumControlSize,
      padding: buttonPadding,
      shape: buttonShape,
      textStyle: buttonTextStyle,
      backgroundColor: WidgetStateProperty.resolveWith(filledBackground),
      foregroundColor: WidgetStateProperty.resolveWith(actionForeground),
      overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
      shadowColor: WidgetStatePropertyAll(surfaces.keyShadow),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        if (states.contains(WidgetState.pressed)) return 0;
        if (states.contains(WidgetState.hovered)) return 2;
        return 0;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final focused = states.contains(WidgetState.focused);
        return BorderSide(
          color: focused ? surfaces.focusRing : Colors.transparent,
          width: focused && highContrast ? 3 : 1.5,
        );
      }),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[semantic, surfaces],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: foreground, size: 22),
      primaryIconTheme: IconThemeData(color: foreground, size: 22),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Icons.arrow_back_rounded),
        closeButtonIconBuilder: (_) => const Icon(Icons.close_rounded),
        drawerButtonIconBuilder: (_) => const Icon(Icons.menu_rounded),
        endDrawerButtonIconBuilder: (_) => const Icon(Icons.menu_rounded),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: PerfectSpace.md,
        iconTheme: IconThemeData(color: foreground, size: 22),
        actionsIconTheme: IconThemeData(color: foreground, size: 22),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: foreground),
      ),
      cardTheme: CardThemeData(
        color: surfaces.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: surfaces.ambientShadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.card),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: dark ? 1 : 1),
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hoverColor: surfaces.hoverLayer,
        hintStyle: textTheme.bodyLarge?.copyWith(color: muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PerfectSpace.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(
            color: scheme.outline,
            width: highContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(
            color: scheme.outline,
            width: highContrast ? 2 : 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: surfaces.disabledOpacity),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(
            color: surfaces.focusRing,
            width: highContrast ? 3 : 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: filledButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: PerfectMotion.standard,
          minimumSize: minimumControlSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonTextStyle,
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(
                alpha: surfaces.disabledOpacity,
              );
            }
            return foreground;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.primaryContainer.withValues(alpha: .55);
            }
            if (states.contains(WidgetState.hovered)) {
              return surfaces.surfaceRaised;
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: scheme.outline.withValues(
                  alpha: surfaces.disabledOpacity,
                ),
              );
            }
            return BorderSide(
              color: states.contains(WidgetState.focused)
                  ? surfaces.focusRing
                  : scheme.outline,
              width: states.contains(WidgetState.focused)
                  ? (highContrast ? 3 : 2)
                  : (highContrast ? 2 : 1.25),
            );
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: PerfectMotion.standard,
          minimumSize: minimumControlSize,
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(
              horizontal: PerfectSpace.md,
              vertical: PerfectSpace.sm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PerfectRadius.control),
            ),
          ),
          textStyle: buttonTextStyle,
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(
                alpha: surfaces.disabledOpacity,
              );
            }
            return scheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: PerfectMotion.quick,
          minimumSize: const WidgetStatePropertyAll(Size.square(48)),
          iconSize: const WidgetStatePropertyAll(22),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PerfectRadius.control),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(
                alpha: surfaces.disabledOpacity,
              );
            }
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return foreground;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(
                    color: surfaces.focusRing,
                    width: highContrast ? 3 : 2,
                  )
                : BorderSide.none,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: highContrast ? scheme.primary : semantic.primaryVivid,
        foregroundColor: highContrast ? scheme.onPrimary : semantic.onPrimary,
        focusColor: surfaces.focusLayer,
        hoverColor: surfaces.hoverLayer,
        splashColor: surfaces.pressedLayer,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 5,
        highlightElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: surfaces.glassStrong,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
            size: states.contains(WidgetState.selected) ? 24 : 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        useIndicator: true,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(
          color: scheme.onPrimaryContainer,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: surfaces.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
        ),
        tileHeight: 52,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedColor: scheme.onPrimaryContainer,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: .72),
        minTileHeight: 48,
        minVerticalPadding: PerfectSpace.xs,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PerfectSpace.md,
          vertical: PerfectSpace.xxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaces.surface,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.secondaryContainer,
        disabledColor: scheme.surfaceContainerHighest.withValues(alpha: .68),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: PerfectSpace.xs),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: scheme.outline, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surfaceContainerHighest;
          }
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: surfaces.disabledOpacity);
          }
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline;
        }),
        overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: surfaces.disabledOpacity);
          }
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surfaceContainerHighest;
          }
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
        overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          animationDuration: PerfectMotion.standard,
          minimumSize: minimumControlSize,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: PerfectSpace.md),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : surfaces.surface,
          ),
          overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? surfaces.focusRing
                  : scheme.outlineVariant,
              width: states.contains(WidgetState.focused)
                  ? (highContrast ? 3 : 2)
                  : (highContrast ? 2 : 1),
            ),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.surfaceRaised,
        barrierColor: scheme.scrim,
        surfaceTintColor: Colors.transparent,
        shadowColor: surfaces.keyShadow,
        elevation: 10,
        insetPadding: const EdgeInsets.all(PerfectSpace.xl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.panel),
          side: BorderSide(
            color: highContrast ? scheme.outline : scheme.outlineVariant,
            width: highContrast ? 2 : 1,
          ),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaces.surfaceRaised,
        modalBackgroundColor: surfaces.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: surfaces.keyShadow,
        elevation: 10,
        modalElevation: 14,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PerfectRadius.panel),
          ),
        ),
        dragHandleColor: scheme.outline,
        dragHandleSize: const Size(40, 4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaces.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: surfaces.keyShadow,
        elevation: 8,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaces.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(surfaces.keyShadow),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PerfectRadius.control),
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.all(PerfectSpace.xs),
          ),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: surfaces.surface,
        collapsedBackgroundColor: surfaces.surface,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
        tilePadding: const EdgeInsets.symmetric(horizontal: PerfectSpace.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          PerfectSpace.md,
          0,
          PerfectSpace.md,
          PerfectSpace.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        elevation: 6,
        insetPadding: const EdgeInsets.all(PerfectSpace.md),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: dark
            ? PerfectSemanticTheme.light.primary
            : semantic.primaryVivid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 350),
        showDuration: const Duration(milliseconds: 2400),
        preferBelow: false,
        verticalOffset: PerfectSpace.sm,
        padding: const EdgeInsets.symmetric(
          horizontal: PerfectSpace.sm,
          vertical: PerfectSpace.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(PerfectRadius.compact),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        interactive: true,
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 9 : 6,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.dragged)
              ? scheme.primary.withValues(alpha: .72)
              : scheme.onSurfaceVariant.withValues(
                  alpha: states.contains(WidgetState.hovered) ? .48 : .30,
                ),
        ),
        trackColor: WidgetStatePropertyAll(
          scheme.surfaceContainerHighest.withValues(alpha: .56),
        ),
        radius: const Radius.circular(PerfectRadius.pill),
        crossAxisMargin: PerfectSpace.xxs,
        mainAxisMargin: PerfectSpace.xs,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        strokeWidth: 4,
        strokeCap: StrokeCap.round,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onPrimaryContainer,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: ShapeDecoration(
          color: scheme.primaryContainer,
          shape: const StadiumBorder(),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith(actionOverlay),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .30),
        selectionHandleColor: scheme.primary,
      ),
    );
  }
}

/// A restrained shared transition for the only two shipping platforms.
///
/// Android enters along the vertical reading flow, while Windows uses a short
/// horizontal hand-off that feels at home with keyboard and rail navigation.
/// Incoming and outgoing routes share the hand-off, so pop and interrupted
/// navigation continue from the current visual state instead of teleporting.
class PerfectPageTransitionsBuilder extends PageTransitionsBuilder {
  const PerfectPageTransitionsBuilder({required this.axis});

  final Axis axis;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (PerfectMotion.reduced(context)) return child;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final entering = PerfectMotion.enter.transform(animation.value);
        final yielding = PerfectMotion.productive.transform(
          secondaryAnimation.value,
        );
        final primaryTravel = (1 - entering) * PerfectMotion.routeEnterTravel;
        final counterTravel = yielding * PerfectMotion.routeExitTravel;
        final offset = axis == Axis.horizontal
            ? Offset(primaryTravel - counterTravel, 0)
            : Offset(0, primaryTravel - counterTravel);
        final opacity = (entering * (1 - yielding * .08)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: offset, child: child),
        );
      },
    );
  }
}
