import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      final wordRect = tester.getRect(find.text('Perfect!'));
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
      final word = tester.getRect(find.text('Perfect!'));
      expect(mark.left, greaterThanOrEqualTo(frame.left));
      expect(word.right, lessThanOrEqualTo(frame.right));
      expect(mark.height / word.height, closeTo(.98, .08));
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
  });

  group('Perfect theme accessibility contract', () {
    for (final entry in <MapEntry<String, ThemeData>>[
      MapEntry<String, ThemeData>('light', PerfectTheme.light()),
      MapEntry<String, ThemeData>('dark', PerfectTheme.dark()),
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
        expect(
          cardShape.side.color,
          theme.brightness == Brightness.dark
              ? theme.colorScheme.outlineVariant.withValues(alpha: .9)
              : theme.colorScheme.outlineVariant,
        );
      }
    });
  });
}

double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() >= b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + .05) / (darker.computeLuminance() + .05);
}
