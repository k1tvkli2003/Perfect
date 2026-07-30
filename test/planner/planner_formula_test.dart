import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_formula.dart';

void main() {
  test('evaluates a safe arithmetic formula from typed property values', () {
    final result = PlannerFormula.evaluate('amount / target * 100', {
      'amount': <String, dynamic>{'type': 'number', 'value': 8},
      'target': <String, dynamic>{'type': 'number', 'value': 16},
    });

    expect(result.isValid, isTrue);
    expect(result.value, 50);
    expect(result.displayValue, '50');
  });

  test('supports bracketed personal property names and bounded functions', () {
    final result = PlannerFormula.evaluate(
      'round(max([Energy level], 3) / 2)',
      {
        'Energy level': <String, dynamic>{'type': 'number', 'value': '7'},
      },
    );

    expect(result.isValid, isTrue);
    expect(result.value, 4);
  });

  test(
    'rejects missing values and arbitrary syntax without executing anything',
    () {
      final missing = PlannerFormula.evaluate('unknown + 1', const {});
      final malformed = PlannerFormula.evaluate('dart:io()', const {});

      expect(missing.isValid, isFalse);
      expect(missing.error, contains('unknown'));
      expect(malformed.isValid, isFalse);
    },
  );
}
