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
  static const mintSoft = Color(0xffe4f4e8);
  static const lilac = Color(0xffa79add);
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
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      focusColor: primary.withValues(alpha: .28),
      hoverColor: primary.withValues(alpha: .10),
      highlightColor: primary.withValues(alpha: .14),
    );
    final text = base.textTheme.apply(
      fontFamily: 'PlusJakarta',
      fontFamilyFallback: const <String>['Vazirmatn'],
      bodyColor: foreground,
      displayColor: foreground,
    );
    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.12,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.2,
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
        bodyLarge: text.bodyLarge?.copyWith(letterSpacing: 0, height: 1.45),
        bodyMedium: text.bodyMedium?.copyWith(letterSpacing: 0, height: 1.45),
        bodySmall: text.bodySmall?.copyWith(letterSpacing: 0, height: 1.4),
        labelLarge: text.labelLarge?.copyWith(letterSpacing: 0, height: 1.3),
        labelMedium: text.labelMedium?.copyWith(letterSpacing: 0, height: 1.3),
        labelSmall: text.labelSmall?.copyWith(letterSpacing: 0, height: 1.3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: foreground),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PerfectSpace.md,
          vertical: PerfectSpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark ? scheme.primary : PerfectColors.apricot,
          foregroundColor: PerfectColors.ink,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: PerfectSpace.lg,
            vertical: PerfectSpace.sm,
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: PerfectSpace.md,
            vertical: PerfectSpace.sm,
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: const Size.square(48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? scheme.primary : PerfectColors.apricot,
        foregroundColor: PerfectColors.ink,
        focusColor: scheme.primary.withValues(alpha: .24),
        hoverColor: scheme.primary.withValues(alpha: .12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: surface.withValues(alpha: .96),
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSurface),
        selectedLabelTextStyle: text.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xfff7f4ff) : PerfectColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: dark ? PerfectColors.ink : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: text.labelMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .30),
        selectionHandleColor: scheme.primary,
      ),
    );
  }
}
