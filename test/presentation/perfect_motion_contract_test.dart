import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  test('motion tokens keep the intended interaction hierarchy', () {
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
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(disabled, Duration.zero);
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
                onTap: () => taps += 1,
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
      expect(tester.getSize(surface), initialSize);

      focusNode.requestFocus();
      await tester.pump();
      expect(states.value, contains(WidgetState.focused));
      expect(tester.getSize(surface), initialSize);

      final gesture = await tester.startGesture(tester.getCenter(surface));
      await tester.pump(kPressTimeout);
      expect(states.value, contains(WidgetState.pressed));
      expect(tester.getSize(surface), initialSize);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2);
    },
  );

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
