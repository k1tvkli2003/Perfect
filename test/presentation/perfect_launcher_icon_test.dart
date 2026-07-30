import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selected Perfect mark is the generated launcher source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: const Scaffold(
          body: RepaintBoundary(
            key: ValueKey<String>('perfect-launcher-artwork'),
            child: ColoredBox(
              color: PerfectColors.cream,
              child: Center(child: PerfectMark(size: 860)),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey<String>('perfect-launcher-artwork')),
      matchesGoldenFile('../../assets/brand/perfect-launcher.png'),
    );
  });
}
