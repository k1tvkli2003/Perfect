import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/presentation/perfect_pictogram.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  test('pictogram names normalize without exposing an asset path', () {
    expect(PerfectPictogram.normalizeName('Personal'), 'compass');
    expect(PerfectPictogram.normalizeName('DEFAULT'), 'compass');
    expect(PerfectPictogram.normalizeName('Finance'), 'finance');
    expect(PerfectPictogram.normalizeName('custom user category'), 'label');
  });

  testWidgets('standalone pictogram exposes one deliberate semantic label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: const Scaffold(
          body: PerfectPictogram(
            name: 'habit',
            size: 32,
            semanticLabel: 'Habit',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Habit'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('framed pictogram renders in both Perfect themes', (
    tester,
  ) async {
    for (final theme in <ThemeData>[
      PerfectTheme.light(),
      PerfectTheme.dark(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Center(
              child: PerfectPictogram(name: 'study', size: 24, framed: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
