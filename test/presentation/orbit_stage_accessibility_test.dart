import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/presentation/orbit_stage.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrbitStage adaptive geometry', () {
    testWidgets('keeps every clock label inside the circular stage', (
      tester,
    ) async {
      await _pumpOrbit(tester, size: const Size.square(360), items: _items());

      final frame = tester.getRect(
        find.byKey(const ValueKey<String>('orbit-test-frame')),
      );
      for (final label in <String>['12:00', '3:00', '6:00', '9:00']) {
        final labelRect = tester.getRect(find.text(label));
        expect(labelRect.left, greaterThanOrEqualTo(frame.left));
        expect(labelRect.top, greaterThanOrEqualTo(frame.top));
        expect(labelRect.right, lessThanOrEqualTo(frame.right));
        expect(labelRect.bottom, lessThanOrEqualTo(frame.bottom));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact orbit honors both width and parent height', (
      tester,
    ) async {
      await _pumpOrbit(
        tester,
        size: const Size(340, 240),
        items: _items(),
        compact: true,
      );

      expect(find.text('Your day,\nin orbit.'), findsOneWidget);
      final frame = tester.getRect(
        find.byKey(const ValueKey<String>('orbit-test-frame')),
      );
      final paintedStage = tester.getRect(
        find
            .descendant(
              of: find.byType(OrbitStage),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(paintedStage.width, lessThanOrEqualTo(frame.width));
      expect(paintedStage.height, lessThanOrEqualTo(frame.height));
      expect(paintedStage.width, closeTo(240, .01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('200 percent text uses a reflowed summary without overflow', (
      tester,
    ) async {
      await _pumpOrbit(
        tester,
        size: const Size(260, 220),
        items: _items(),
        textScaler: const TextScaler.linear(2),
      );

      expect(find.text('Your day,\nin orbit.'), findsNothing);
      expect(find.text('Today, in orbit'), findsOneWidget);
      expect(find.text('2 open items'), findsOneWidget);
      expect(
        tester
            .getRect(find.text('Today, in orbit'))
            .overlaps(tester.getRect(find.text('2 open items'))),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'mixed-direction titles stay isolated inside LTR summary copy',
      (tester) async {
        await _pumpOrbit(
          tester,
          size: const Size(300, 220),
          items: _items(),
          direction: TextDirection.rtl,
        );

        final detail = tester.widget<Text>(
          find.textContaining('برنامهٔ Deep Work'),
        );
        expect(detail.textDirection, TextDirection.ltr);
        expect(
          detail.data,
          contains('\u2068برنامهٔ Deep Work (Phase 2)\u2069'),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('OrbitStage accessibility', () {
    testWidgets('exposes one descriptive actionable semantic node', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await _pumpOrbit(
        tester,
        size: const Size.square(360),
        items: _items(),
        onTap: () => taps++,
      );

      final finder = find.bySemanticsLabel('Today in orbit');
      expect(finder, findsOneWidget);
      final node = tester.getSemantics(finder);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.value, contains('2 open items'));
      expect(node.value, contains('برنامهٔ Deep Work'));
      expect(node.hint, 'Open day plan');

      await tester.tap(finder);
      await tester.pump();
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('non-actionable summary has no false arrow or button role', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpOrbit(
        tester,
        size: const Size(280, 200),
        items: const <PlannerEntity>[],
      );

      final finder = find.bySemanticsLabel('Today in orbit');
      final node = tester.getSemantics(finder);
      expect(node.flagsCollection.isButton, isFalse);
      expect(node.value, 'No open items');
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      semantics.dispose();
    });

    testWidgets('reduced motion disables ink splash animation', (tester) async {
      await _pumpOrbit(
        tester,
        size: const Size.square(360),
        items: _items(),
        disableAnimations: true,
        onTap: () {},
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      expect(inkWell.splashFactory, same(NoSplash.splashFactory));
      expect(inkWell.highlightColor, Colors.transparent);
    });
  });
}

Future<void> _pumpOrbit(
  WidgetTester tester, {
  required Size size,
  required List<PlannerEntity> items,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
  bool compact = false,
  bool disableAnimations = false,
  VoidCallback? onTap,
}) async {
  await tester.binding.setSurfaceSize(const Size(520, 520));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(520, 520),
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(
              child: SizedBox.fromSize(
                key: const ValueKey<String>('orbit-test-frame'),
                size: size,
                child: OrbitStage(items: items, compact: compact, onTap: onTap),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

List<PlannerEntity> _items() {
  final now = DateTime.utc(2026, 7, 30, 9);
  return <PlannerEntity>[
    PlannerEntity(
      id: 'mixed',
      ownerId: 'owner',
      kind: PlannerEntityKind.oneOffTask,
      payload: defaultPlannerPayload(title: 'برنامهٔ Deep Work (Phase 2)'),
      createdAt: now,
      updatedAt: now,
    ),
    PlannerEntity(
      id: 'call',
      ownerId: 'owner',
      kind: PlannerEntityKind.oneOffTask,
      payload: defaultPlannerPayload(title: 'Client call'),
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
