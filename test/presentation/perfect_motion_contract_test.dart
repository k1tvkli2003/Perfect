import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  test('motion tokens keep the intended interaction hierarchy', () {
    expect(PerfectMotion.micro, lessThan(PerfectMotion.quick));
    expect(PerfectMotion.quick, lessThan(PerfectMotion.standard));
    expect(PerfectMotion.standard, lessThan(PerfectMotion.emphasized));
    expect(PerfectMotion.emphasized, lessThan(PerfectMotion.feedback));
    expect(PerfectMotion.productive, Curves.easeOutCubic);
    expect(PerfectMotion.enter, Curves.easeOutCubic);
    expect(PerfectMotion.exit, Curves.easeInCubic);
  });

  testWidgets('responsive motion honors the platform reduced-motion signal', (
    tester,
  ) async {
    Duration? enabled;
    Duration? disabled;
    Offset? disabledOffset;
    double? disabledScale;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            enabled = PerfectMotion.responsive(
              context,
              PerfectMotion.emphasized,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(enabled, PerfectMotion.emphasized);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Builder(
          builder: (context) {
            disabled = PerfectMotion.responsive(
              context,
              PerfectMotion.emphasized,
            );
            disabledOffset = PerfectMotion.responsiveOffset(
              context,
              const Offset(12, 8),
            );
            disabledScale = PerfectMotion.responsiveScale(context, .96);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(disabled, Duration.zero);
    expect(disabledOffset, Offset.zero);
    expect(disabledScale, 1);
  });

  testWidgets(
    'shared switcher uses one vocabulary and removes spatial motion',
    (tester) async {
      late StateSetter setState;
      var second = false;

      Widget host({required bool reduced}) => MaterialApp(
        theme: PerfectTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child ?? const SizedBox.shrink(),
        ),
        home: StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return PerfectMotionSwitcher(
              kind: PerfectTransitionKind.sharedAxisHorizontal,
              child: Text(
                second ? 'Second' : 'First',
                key: ValueKey<bool>(second),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(host(reduced: false));
      setState(() => second = true);
      await tester.pump();
      final animated = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(animated.duration, PerfectMotion.emphasized);
      expect(find.byType(SlideTransition), findsWidgets);

      await tester.pumpWidget(host(reduced: true));
      setState(() => second = false);
      await tester.pump();
      final reduced = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(reduced.duration, Duration.zero);
      expect(find.byType(SlideTransition), findsNothing);
    },
  );

  testWidgets('glass has a strong high-contrast fallback without blur', (
    tester,
  ) async {
    Widget host({required bool highContrast}) => MaterialApp(
      theme: PerfectTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: const PerfectGlassSurface(
          surfaceKey: ValueKey<String>('glass-material'),
          child: SizedBox(width: 240, height: 80),
        ),
      ),
    );

    await tester.pumpWidget(host(highContrast: false));
    expect(find.byType(BackdropFilter), findsOneWidget);
    var decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey<String>('glass-material')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.border!.top.width, 1);

    await tester.pumpWidget(host(highContrast: true));
    expect(find.byType(BackdropFilter), findsNothing);
    decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey<String>('glass-material')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, PerfectSurfaceTheme.light.surfaceRaised);
    expect(decoration.border!.top.width, 2);
    expect(
      decoration.border!.top.color,
      PerfectSurfaceTheme.light.strokeStrong,
    );
  });

  test('geometry mixes intrinsic bounds, fractions and semantic tokens', () {
    final compact = PerfectResponsiveGeometry.fromSize(
      const Size(390, 844),
      textScale: 1,
    );
    final tablet = PerfectResponsiveGeometry.fromSize(
      const Size(800, 1280),
      textScale: 1,
    );
    final desktop = PerfectResponsiveGeometry.fromSize(
      const Size(1440, 900),
      textScale: 1,
    );
    final desktopAtLargeText = PerfectResponsiveGeometry.fromSize(
      const Size(1040, 900),
      textScale: 2,
    );
    final shortLandscape = PerfectResponsiveGeometry.fromSize(
      const Size(960, 480),
      textScale: 1,
    );

    expect(compact.windowClass, PerfectWindowClass.compact);
    expect(tablet.windowClass, PerfectWindowClass.medium);
    expect(desktop.windowClass, PerfectWindowClass.expanded);
    expect(desktopAtLargeText.windowClass, PerfectWindowClass.medium);
    expect(shortLandscape.isShortLandscape, isTrue);
    expect(shortLandscape.verticalGutter, PerfectSpace.sm);

    expect(
      desktop.boundedPaneWidth(fraction: .62),
      inInclusiveRange(
        PerfectResponsiveGeometry.minReadablePane,
        PerfectResponsiveGeometry.maxReadableLine,
      ),
    );
    expect(
      compact.boundedPaneWidth(fraction: .62),
      inInclusiveRange(
        PerfectResponsiveGeometry.minReadablePane,
        compact.contentWidth,
      ),
    );
    expect(compact.columnsFor(minItemWidth: 280), 1);
    expect(desktop.columnsFor(minItemWidth: 280), greaterThan(1));
    expect(
      desktop.horizontalGutter,
      inInclusiveRange(
        PerfectResponsiveGeometry.minGutter,
        PerfectResponsiveGeometry.maxGutter,
      ),
    );
  });

  testWidgets(
    'interactive surface exposes hover focus press without geometry shift',
    (tester) async {
      final states = WidgetStatesController();
      addTearDown(states.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var taps = 0;
      final hoverChanges = <bool>[];
      final focusChanges = <bool>[];
      final pressChanges = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: Scaffold(
            body: Center(
              child: PerfectInteractiveSurface(
                semanticLabel: 'Open details',
                tooltip: 'Open details',
                focusNode: focusNode,
                statesController: states,
                tone: PerfectInteractiveTone.tertiary,
                selected: true,
                onTap: () => taps += 1,
                onHoverChanged: hoverChanges.add,
                onFocusChanged: focusChanges.add,
                onPressedChanged: pressChanges.add,
                child: const Text('Details'),
              ),
            ),
          ),
        ),
      );

      final surface = find.byKey(
        const ValueKey<String>('perfect-interaction-surface'),
      );
      final initialSize = tester.getSize(surface);
      expect(initialSize.width, greaterThanOrEqualTo(48));
      expect(initialSize.height, greaterThanOrEqualTo(48));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(surface));
      await tester.pump(PerfectMotion.standard);
      expect(states.value, contains(WidgetState.hovered));
      expect(hoverChanges, contains(true));
      expect(tester.getSize(surface), initialSize);

      focusNode.requestFocus();
      await tester.pump();
      expect(states.value, contains(WidgetState.focused));
      expect(focusChanges, contains(true));
      expect(tester.getSize(surface), initialSize);
      final focusedDecoration =
          tester.widget<AnimatedContainer>(surface).decoration as BoxDecoration;
      expect(
        focusedDecoration.border!.top.color,
        PerfectSurfaceTheme.light.focusRing,
      );
      expect(focusedDecoration.boxShadow, isNotEmpty);

      final gesture = await tester.startGesture(tester.getCenter(surface));
      await tester.pump(kPressTimeout);
      expect(states.value, contains(WidgetState.pressed));
      expect(pressChanges, contains(true));
      expect(tester.getSize(surface), initialSize);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2);
    },
  );

  testWidgets('interactive surface remains usable at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 220));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: PerfectInteractiveSurface(
                  autofocus: true,
                  onTap: () => taps += 1,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.auto_awesome_rounded),
                      SizedBox(width: 8),
                      Flexible(child: Text('Open the complete planner wizard')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('perfect-interaction-surface')),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('interactive surface removes spatial motion when requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: PerfectInteractiveSurface(
            onTap: () {},
            child: const Text('Reduced motion'),
          ),
        ),
      ),
    );

    final animated = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('perfect-interaction-surface')),
    );
    expect(animated.duration, Duration.zero);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Reduced motion')),
    );
    await tester.pump();
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('perfect-interaction-scale')),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.transform.getMaxScaleOnAxis(), 1);
    await gesture.up();
  });
}
