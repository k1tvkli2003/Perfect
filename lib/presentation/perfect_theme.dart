import 'package:flutter/material.dart';

abstract final class PerfectColors {
  static const ink = Color(0xff1d2030);
  static const mutedInk = Color(0xff686579);
  static const cream = Color(0xfffffcf7);
  static const creamElevated = Color(0xffffffff);
  static const creamSurfaceLow = Color(0xfffffaf4);
  static const creamSurface = Color(0xfffbf6ef);
  static const creamSurfaceHigh = Color(0xfff7f2eb);
  static const creamSurfaceHighest = Color(0xfff1ebe4);
  static const creamStroke = Color(0xffece5dc);
  static const accessibleOutline = Color(0xff8a8493);
  static const apricot = Color(0xffffa34d);
  static const apricotAction = Color(0xffa4510e);
  static const apricotSoft = Color(0xffffead7);
  static const mint = Color(0xff7ec99b);
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
  static const night = Color(0xff171924);
  static const nightSurfaceLow = Color(0xff1d202c);
  static const nightSurface = Color(0xff232635);
  static const nightSurfaceHigh = Color(0xff292c3d);
  static const nightSurfaceHighest = Color(0xff303446);
  static const nightStroke = Color(0xff3a3e50);
  static const accessibleNightOutline = Color(0xff898698);
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
    canvas: PerfectColors.cream,
    canvasAccent: Color(0xfffff5ea),
    surface: PerfectColors.creamSurfaceLow,
    surfaceRaised: PerfectColors.creamElevated,
    glass: Color(0xd9ffffff),
    glassStrong: Color(0xf2ffffff),
    stroke: PerfectColors.creamStroke,
    strokeStrong: PerfectColors.accessibleOutline,
    focusRing: PerfectColors.apricotAction,
    hoverLayer: Color(0x14a4510e),
    focusLayer: Color(0x1fa4510e),
    pressedLayer: Color(0x29a4510e),
    selectedLayer: Color(0x33ffa34d),
    ambientShadow: Color(0x144b3d32),
    keyShadow: Color(0x1f4b3d32),
    glassBlur: 18,
    glassBlurStrong: 26,
    disabledOpacity: .46,
  );

  static const dark = PerfectSurfaceTheme(
    canvas: PerfectColors.night,
    canvasAccent: Color(0xff211f2e),
    surface: PerfectColors.nightSurfaceLow,
    surfaceRaised: PerfectColors.nightSurfaceHigh,
    glass: Color(0xd9232635),
    glassStrong: Color(0xf2292c3d),
    stroke: PerfectColors.nightStroke,
    strokeStrong: PerfectColors.accessibleNightOutline,
    focusRing: Color(0xffffbd7c),
    hoverLayer: Color(0x1fffbd7c),
    focusLayer: Color(0x2effbd7c),
    pressedLayer: Color(0x3dffbd7c),
    selectedLayer: Color(0x3dffbd7c),
    ambientShadow: Color(0x3d100f18),
    keyShadow: Color(0x66100f18),
    glassBlur: 18,
    glassBlurStrong: 26,
    disabledOpacity: .48,
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
  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark
        ? PerfectColors.nightSurface
        : PerfectColors.creamElevated;
    final background = dark ? PerfectColors.night : PerfectColors.cream;
    final foreground = dark ? const Color(0xfff7f4ff) : PerfectColors.ink;
    final muted = dark ? const Color(0xffc8c4d5) : PerfectColors.mutedInk;
    final primary = dark
        ? const Color(0xffffbd7c)
        : PerfectColors.apricotAction;
    final secondary = dark ? const Color(0xffa9dfbb) : PerfectColors.mint;
    final tertiary = dark ? const Color(0xffcfc5ff) : PerfectColors.lilac;
    final inputFill = dark ? const Color(0xff2a2d3e) : const Color(0xfffffdfb);
    final surfaces = dark
        ? PerfectSurfaceTheme.dark
        : PerfectSurfaceTheme.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: dark ? PerfectColors.ink : PerfectColors.cream,
      primaryContainer: dark
          ? const Color(0xff4a3527)
          : PerfectColors.apricotSoft,
      onPrimaryContainer: dark ? PerfectColors.apricotSoft : PerfectColors.ink,
      secondary: secondary,
      onSecondary: PerfectColors.ink,
      secondaryContainer: dark
          ? const Color(0xff253c31)
          : PerfectColors.mintSoft,
      onSecondaryContainer: dark ? PerfectColors.mintSoft : PerfectColors.ink,
      tertiary: tertiary,
      onTertiary: PerfectColors.ink,
      tertiaryContainer: dark
          ? const Color(0xff37334f)
          : PerfectColors.lilacSoft,
      onTertiaryContainer: dark ? PerfectColors.lilacSoft : PerfectColors.ink,
      error: dark ? const Color(0xffffaab0) : PerfectColors.danger,
      onError: dark ? PerfectColors.ink : PerfectColors.cream,
      errorContainer: dark ? const Color(0xff542c35) : PerfectColors.dangerSoft,
      onErrorContainer: dark
          ? const Color(0xffffd9dc)
          : PerfectColors.onDangerSoft,
      surface: surface,
      onSurface: foreground,
      surfaceDim: dark
          ? PerfectColors.night
          : PerfectColors.creamSurfaceHighest,
      surfaceBright: dark
          ? PerfectColors.nightSurfaceHigh
          : PerfectColors.creamElevated,
      surfaceContainerLowest: dark
          ? PerfectColors.night
          : PerfectColors.creamElevated,
      surfaceContainerLow: dark
          ? PerfectColors.nightSurfaceLow
          : PerfectColors.creamSurfaceLow,
      surfaceContainer: dark
          ? PerfectColors.nightSurface
          : PerfectColors.creamSurface,
      surfaceContainerHigh: dark
          ? PerfectColors.nightSurfaceHigh
          : PerfectColors.creamSurfaceHigh,
      surfaceContainerHighest: dark
          ? PerfectColors.nightSurfaceHighest
          : PerfectColors.creamSurfaceHighest,
      onSurfaceVariant: muted,
      outline: dark
          ? PerfectColors.accessibleNightOutline
          : PerfectColors.accessibleOutline,
      outlineVariant: dark
          ? PerfectColors.nightStroke
          : PerfectColors.creamStroke,
      shadow: dark ? const Color(0xff100f18) : const Color(0xff4b3d32),
      scrim: PerfectColors.ink.withValues(alpha: .52),
      inverseSurface: dark ? PerfectColors.cream : PerfectColors.ink,
      onInverseSurface: dark ? PerfectColors.ink : PerfectColors.cream,
      inversePrimary: dark ? PerfectColors.apricot : const Color(0xffffbd7c),
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
      return dark ? scheme.primary : PerfectColors.apricot;
    }

    Color? actionForeground(Set<WidgetState> states) =>
        states.contains(WidgetState.disabled)
        ? scheme.onSurface.withValues(alpha: surfaces.disabledOpacity)
        : PerfectColors.ink;

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
          width: 1.5,
        );
      }),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[surfaces],
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
            color: scheme.outlineVariant.withValues(alpha: dark ? .9 : 1),
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
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(color: scheme.outline),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: surfaces.disabledOpacity),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.control),
          borderSide: BorderSide(color: scheme.primary, width: 2),
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
              width: states.contains(WidgetState.focused) ? 2 : 1.25,
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
                ? BorderSide(color: surfaces.focusRing, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? scheme.primary : PerfectColors.apricot,
        foregroundColor: PerfectColors.ink,
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
              width: states.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: surfaces.keyShadow,
        elevation: 10,
        insetPadding: const EdgeInsets.all(PerfectSpace.xl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PerfectRadius.panel),
          side: BorderSide(color: scheme.outlineVariant),
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
        backgroundColor: dark ? const Color(0xfff7f4ff) : PerfectColors.ink,
        elevation: 6,
        insetPadding: const EdgeInsets.all(PerfectSpace.md),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: dark ? PerfectColors.ink : Colors.white,
        ),
        actionTextColor: dark
            ? PerfectColors.apricotAction
            : PerfectColors.apricot,
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
