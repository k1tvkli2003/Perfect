import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Perfect brand fidelity', () {
    testWidgets('wordmark never mirrors in an RTL host', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: PerfectWordmark(fontSize: 40, includeMark: true),
                ),
              ),
            ),
          ),
        ),
      );

      final markRect = tester.getRect(find.byType(PerfectMark));
      final wordRect = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-wordmark-visual')),
      );
      expect(markRect.right, lessThan(wordRect.left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('wordmark remains bounded at 200 percent text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 180));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  key: ValueKey<String>('wordmark-frame'),
                  width: 240,
                  child: PerfectWordmark(fontSize: 42, includeMark: true),
                ),
              ),
            ),
          ),
        ),
      );

      final frame = tester.getRect(
        find.byKey(const ValueKey<String>('wordmark-frame')),
      );
      final mark = tester.getRect(find.byType(PerfectMark));
      final word = tester.getRect(
        find.byKey(const ValueKey<String>('perfect-wordmark-visual')),
      );
      expect(mark.left, greaterThanOrEqualTo(frame.left));
      expect(word.right, lessThanOrEqualTo(frame.right));
      expect(mark.height / word.height, inInclusiveRange(.9, 1.02));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mark and wordmark expose concise non-duplicated semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.dark(),
          home: const Scaffold(
            body: PerfectWordmark(fontSize: 34, includeMark: true),
          ),
        ),
      );

      final finder = find.bySemanticsLabel('Perfect!');
      expect(finder, findsOneWidget);
      final node = tester.getSemantics(finder);
      expect(node.flagsCollection.isHeader, isTrue);
      expect(node.label, 'Perfect!');
      semantics.dispose();
    });

    testWidgets('standalone mark is exposed as an image', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: const Scaffold(body: PerfectMark()),
        ),
      );

      final node = tester.getSemantics(find.bySemanticsLabel('Perfect!'));
      expect(node.flagsCollection.isImage, isTrue);
      semantics.dispose();
    });

    testWidgets('dark and high-contrast surfaces select dedicated artwork', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.dark(),
          home: const MediaQuery(
            data: MediaQueryData(highContrast: true),
            child: Scaffold(
              body: PerfectWordmark(fontSize: 34, includeMark: true),
            ),
          ),
        ),
      );

      final mark = tester.widget<Image>(find.byType(Image));
      final markProvider = mark.image as ResizeImage;
      final markAsset = markProvider.imageProvider as AssetImage;
      expect(
        markAsset.assetName,
        'assets/brand/perfect-mark-high-contrast-dark.png',
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('perfect-wordmark-visual')),
          matching: find.byType(SvgPicture),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('mark decodes at its rendered physical size', (tester) async {
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: const Scaffold(body: PerfectMark(size: 40)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as ResizeImage;
      expect(provider.width, 100);
      expect(provider.height, 100);
      expect(image.filterQuality, FilterQuality.high);
    });

    testWidgets('mark decode never upscales beyond its 512px source', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: const Scaffold(body: PerfectMark(size: 240)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as ResizeImage;
      expect(provider.width, 512);
      expect(provider.height, 512);
    });
  });

  group('Perfect theme accessibility contract', () {
    for (final entry in <MapEntry<String, ThemeData>>[
      MapEntry<String, ThemeData>('light', PerfectTheme.light()),
      MapEntry<String, ThemeData>('dark', PerfectTheme.dark()),
      MapEntry<String, ThemeData>(
        'high contrast light',
        PerfectTheme.highContrastLight(),
      ),
      MapEntry<String, ThemeData>(
        'high contrast dark',
        PerfectTheme.highContrastDark(),
      ),
    ]) {
      test('${entry.key} semantic foreground pairs meet text contrast', () {
        final scheme = entry.value.colorScheme;
        expect(
          _contrast(scheme.primary, scheme.onPrimary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.secondary, scheme.onSecondary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.tertiary, scheme.onTertiary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.error, scheme.onError),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.surface, scheme.onSurface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('${entry.key} input boundary has non-text contrast', () {
        final inputTheme = entry.value.inputDecorationTheme;
        final border = inputTheme.enabledBorder! as OutlineInputBorder;
        final focusedBorder = inputTheme.focusedBorder! as OutlineInputBorder;
        expect(
          _contrast(inputTheme.fillColor!, border.borderSide.color),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(inputTheme.fillColor!, focusedBorder.borderSide.color),
          greaterThanOrEqualTo(3),
        );
      });

      test('${entry.key} text actions remain readable on the surface', () {
        final foreground = entry.value.textButtonTheme.style?.foregroundColor
            ?.resolve(const <WidgetState>{});
        expect(foreground, isNotNull);
        expect(
          _contrast(entry.value.colorScheme.surface, foreground!),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    test('theme uses real mixed-script fallback without negative tracking', () {
      final theme = PerfectTheme.light();
      expect(theme.textTheme.bodyMedium?.fontFamily, 'PlusJakarta');
      expect(
        theme.textTheme.bodyMedium?.fontFamilyFallback,
        contains('Vazirmatn'),
      );
      expect(theme.textTheme.bodyMedium?.letterSpacing, 0);
      expect(theme.textTheme.headlineMedium?.letterSpacing, 0);
      expect(theme.textTheme.bodyMedium?.height, greaterThanOrEqualTo(1.4));
    });

    test('theme exposes one interpolatable surface language', () {
      final light = PerfectTheme.light();
      final dark = PerfectTheme.dark();
      final lightSurfaces = light.extension<PerfectSurfaceTheme>();
      final darkSurfaces = dark.extension<PerfectSurfaceTheme>();

      expect(lightSurfaces, PerfectSurfaceTheme.light);
      expect(darkSurfaces, PerfectSurfaceTheme.dark);
      expect(lightSurfaces!.glass.a, lessThan(1));
      expect(darkSurfaces!.glass.a, lessThan(1));
      expect(lightSurfaces.glassBlur, lessThan(lightSurfaces.glassBlurStrong));
      expect(darkSurfaces.glassBlur, lessThan(darkSurfaces.glassBlurStrong));

      final midpoint = lightSurfaces.lerp(darkSurfaces, .5);
      expect(midpoint.canvas, isNot(lightSurfaces.canvas));
      expect(midpoint.canvas, isNot(darkSurfaces.canvas));
      expect(midpoint.glassBlur, lightSurfaces.glassBlur);
    });

    test('contrast themes are structural authored modes, not dark aliases', () {
      final light = PerfectTheme.light();
      final dark = PerfectTheme.dark();
      final clarityLight = PerfectTheme.highContrastLight();
      final clarityDark = PerfectTheme.highContrastDark();
      final clarityLightSemantics = clarityLight
          .extension<PerfectSemanticTheme>()!;
      final clarityDarkSemantics = clarityDark
          .extension<PerfectSemanticTheme>()!;
      final clarityLightSurfaces = clarityLight
          .extension<PerfectSurfaceTheme>()!;
      final clarityDarkSurfaces = clarityDark.extension<PerfectSurfaceTheme>()!;

      expect(clarityLightSemantics.id, 'theme-hc-light-clarity');
      expect(clarityDarkSemantics.id, 'theme-hc-dark-clarity');
      expect(clarityLightSemantics.highContrast, isTrue);
      expect(clarityDarkSemantics.highContrast, isTrue);
      expect(
        clarityLight.colorScheme.surface,
        isNot(light.colorScheme.surface),
      );
      expect(clarityDark.colorScheme.surface, isNot(dark.colorScheme.surface));
      expect(clarityLightSurfaces.glassBlur, 0);
      expect(clarityDarkSurfaces.glassBlur, 0);
      expect(clarityLightSurfaces.glassBlurStrong, 0);
      expect(clarityDarkSurfaces.glassBlurStrong, 0);
      final lightFocusBorder =
          clarityLight.inputDecorationTheme.focusedBorder!
              as OutlineInputBorder;
      final darkFocusBorder =
          clarityDark.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
      expect(lightFocusBorder.borderSide.width, greaterThanOrEqualTo(2));
      expect(darkFocusBorder.borderSide.width, greaterThanOrEqualTo(2));
      expect(
        _contrast(clarityLightSemantics.canvas, clarityLightSemantics.ink),
        greaterThanOrEqualTo(7),
      );
      expect(
        _contrast(clarityDarkSemantics.canvas, clarityDarkSemantics.ink),
        greaterThanOrEqualTo(7),
      );
    });

    test('control themes share motion and perceivable pointer states', () {
      final theme = PerfectTheme.light();
      final filled = theme.filledButtonTheme.style!;
      final icon = theme.iconButtonTheme.style!;
      const rest = <WidgetState>{};
      const hover = <WidgetState>{WidgetState.hovered};
      const focus = <WidgetState>{WidgetState.focused};
      const press = <WidgetState>{WidgetState.pressed};
      const selected = <WidgetState>{WidgetState.selected};

      expect(filled.animationDuration, PerfectMotion.standard);
      expect(icon.animationDuration, PerfectMotion.quick);
      expect(
        filled.overlayColor!.resolve(hover),
        isNot(filled.overlayColor!.resolve(rest)),
      );
      expect(
        filled.overlayColor!.resolve(press),
        isNot(filled.overlayColor!.resolve(hover)),
      );
      expect(
        filled.side!.resolve(focus)!.color,
        PerfectSurfaceTheme.light.focusRing,
      );
      expect(
        icon.backgroundColor!.resolve(selected),
        theme.colorScheme.primaryContainer,
      );
    });

    test('Android and Windows routes use the Perfect transition system', () {
      final transitions = PerfectTheme.light().pageTransitionsTheme.builders;
      final android = transitions[TargetPlatform.android];
      final windows = transitions[TargetPlatform.windows];

      expect(android, isA<PerfectPageTransitionsBuilder>());
      expect(windows, isA<PerfectPageTransitionsBuilder>());
      expect((android! as PerfectPageTransitionsBuilder).axis, Axis.vertical);
      expect((windows! as PerfectPageTransitionsBuilder).axis, Axis.horizontal);
    });

    test('all global button families retain at least a 48dp target', () {
      final theme = PerfectTheme.light();
      expect(
        theme.filledButtonTheme.style?.minimumSize?.resolve(
          const <WidgetState>{},
        ),
        const Size(48, 48),
      );
      expect(
        theme.outlinedButtonTheme.style?.minimumSize?.resolve(
          const <WidgetState>{},
        ),
        const Size(48, 48),
      );
      expect(
        theme.textButtonTheme.style?.minimumSize?.resolve(
          const <WidgetState>{},
        ),
        const Size(48, 48),
      );
      expect(
        theme.iconButtonTheme.style?.minimumSize?.resolve(
          const <WidgetState>{},
        ),
        const Size.square(48),
      );
    });

    test('theme keeps intentional soft and strong outline roles separate', () {
      for (final theme in <ThemeData>[
        PerfectTheme.light(),
        PerfectTheme.dark(),
        PerfectTheme.highContrastLight(),
        PerfectTheme.highContrastDark(),
      ]) {
        expect(
          theme.colorScheme.outline,
          isNot(theme.colorScheme.outlineVariant),
        );
        expect(
          _contrast(
            theme.inputDecorationTheme.fillColor!,
            theme.colorScheme.outline,
          ),
          greaterThanOrEqualTo(3),
        );
        final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(cardShape.side.color, theme.colorScheme.outlineVariant);
      }
    });
  });
}

double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() >= b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + .05) / (darker.computeLuminance() + .05);
}
