import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  test('light semantic theme is the Paper Ledger system', () {
    expect(PerfectSemanticTheme.light.id, 'theme-light-paper-ledger');
    expect(PerfectSemanticTheme.light.primary.toARGB32(), 0xff175cd3);
    expect(PerfectSemanticTheme.light.canvas.toARGB32(), 0xfff7f7f5);
    expect(PerfectSemanticTheme.light.surfaceLowest.toARGB32(), 0xffffffff);
  });

  test('dark semantic theme is the Midnight Command system', () {
    expect(PerfectSemanticTheme.dark.id, 'theme-dark-midnight-command');
    expect(PerfectSemanticTheme.dark.canvas.toARGB32(), 0xff07111f);
    expect(PerfectSemanticTheme.dark.surface.toARGB32(), 0xff11243a);
    expect(PerfectSemanticTheme.dark.primary.toARGB32(), 0xff8ab4ff);
  });

  test('semantic accents keep action completion and urgency distinct', () {
    expect(
      PerfectSemanticTheme.light.primary,
      isNot(PerfectSemanticTheme.light.secondary),
    );
    expect(
      PerfectSemanticTheme.light.secondary,
      isNot(PerfectSemanticTheme.light.danger),
    );
    expect(
      PerfectSemanticTheme.dark.primary,
      isNot(PerfectSemanticTheme.dark.secondary),
    );
    expect(
      PerfectSemanticTheme.dark.secondary,
      isNot(PerfectSemanticTheme.dark.danger),
    );
  });
}
