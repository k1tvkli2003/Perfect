/// A deliberately tiny, deterministic formula language for personal
/// properties. It supports numbers, property names, `[property names with
/// spaces]`, parentheses, `+ - * /`, and `min`, `max`, `round` functions.
///
/// There is no dynamic code execution, reflection, I/O, or function lookup.
/// A malformed formula remains data and returns a readable error instead of
/// ever affecting a task or sync operation.
class PlannerFormula {
  const PlannerFormula._();

  static PlannerFormulaResult evaluate(
    String expression,
    Map<String, dynamic> properties,
  ) {
    final source = expression.trim();
    if (source.isEmpty) {
      return const PlannerFormulaResult.error('Write a formula first.');
    }
    try {
      final parser = _PlannerFormulaParser(source, properties);
      final value = parser.parse();
      if (!value.isFinite) {
        return const PlannerFormulaResult.error('The result is not finite.');
      }
      return PlannerFormulaResult.value(value);
    } on FormatException catch (error) {
      return PlannerFormulaResult.error(error.message);
    }
  }
}

class PlannerFormulaResult {
  const PlannerFormulaResult.value(this.value) : error = null;

  const PlannerFormulaResult.error(this.error) : value = null;

  final num? value;
  final String? error;

  bool get isValid => value != null;

  String get displayValue {
    final current = value;
    if (current == null) return '—';
    return current % 1 == 0
        ? current.toInt().toString()
        : current.toStringAsFixed(2);
  }
}

class _PlannerFormulaParser {
  _PlannerFormulaParser(this.source, this.properties);

  final String source;
  final Map<String, dynamic> properties;
  int _index = 0;

  num parse() {
    final value = _expression();
    _skipWhitespace();
    if (_index != source.length) {
      throw FormatException('Unexpected “${source[_index]}” in the formula.');
    }
    return value;
  }

  num _expression() {
    var value = _term();
    while (true) {
      _skipWhitespace();
      if (_take('+')) {
        value += _term();
      } else if (_take('-')) {
        value -= _term();
      } else {
        return value;
      }
    }
  }

  num _term() {
    var value = _factor();
    while (true) {
      _skipWhitespace();
      if (_take('*')) {
        value *= _factor();
      } else if (_take('/')) {
        final divisor = _factor();
        if (divisor == 0) throw const FormatException('Cannot divide by zero.');
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  num _factor() {
    _skipWhitespace();
    if (_take('+')) {
      return _factor();
    }
    if (_take('-')) {
      return -_factor();
    }
    if (_take('(')) {
      final value = _expression();
      _skipWhitespace();
      if (!_take(')')) {
        throw const FormatException('A closing parenthesis is missing.');
      }
      return value;
    }
    if (_peek('[')) {
      return _property(_bracketedName());
    }
    if (_isDigit(_current) || _peek('.')) {
      return _number();
    }
    if (_isIdentifierStart(_current)) {
      final identifier = _identifier();
      _skipWhitespace();
      if (_take('(')) {
        return _function(identifier);
      }
      return _property(identifier);
    }
    throw const FormatException('Expected a number, property, or parenthesis.');
  }

  num _function(String identifier) {
    final arguments = <num>[];
    _skipWhitespace();
    if (!_take(')')) {
      while (true) {
        arguments.add(_expression());
        _skipWhitespace();
        if (_take(')')) {
          break;
        }
        if (!_take(',')) {
          throw const FormatException('Function arguments need commas.');
        }
      }
    }
    return switch (identifier.toLowerCase()) {
      'min' when arguments.length >= 2 => arguments.reduce(_min),
      'max' when arguments.length >= 2 => arguments.reduce(_max),
      'round' when arguments.length == 1 => arguments.single.round(),
      _ => throw FormatException('Use min(a, b), max(a, b), or round(value).'),
    };
  }

  num _property(String rawName) {
    final name = rawName.trim();
    MapEntry<String, dynamic>? entry;
    for (final candidate in properties.entries) {
      if (candidate.key.toLowerCase() == name.toLowerCase()) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      throw FormatException('“$name” has no numeric value.');
    }
    final descriptor = entry.value;
    final rawValue = descriptor is Map ? descriptor['value'] : descriptor;
    final value = switch (rawValue) {
      num value => value,
      bool value => value ? 1 : 0,
      String value => num.tryParse(value.trim()),
      _ => null,
    };
    if (value == null || !value.isFinite) {
      throw FormatException('“$name” needs a finite number.');
    }
    return value;
  }

  num _number() {
    final start = _index;
    while (_isDigit(_current) || _peek('.')) {
      _index++;
    }
    final value = num.tryParse(source.substring(start, _index));
    if (value == null) {
      throw const FormatException('That number is not valid.');
    }
    return value;
  }

  String _identifier() {
    final start = _index;
    _index++;
    while (_isIdentifierPart(_current)) {
      _index++;
    }
    return source.substring(start, _index);
  }

  String _bracketedName() {
    _index++; // Opening bracket.
    final start = _index;
    while (_index < source.length && source[_index] != ']') {
      _index++;
    }
    if (_index == source.length) {
      throw const FormatException(
        'A closing ] is missing from the property name.',
      );
    }
    final name = source.substring(start, _index).trim();
    _index++; // Closing bracket.
    if (name.isEmpty) {
      throw const FormatException('Property names cannot be empty.');
    }
    return name;
  }

  void _skipWhitespace() {
    while (_current != null && _current!.trim().isEmpty) {
      _index++;
    }
  }

  bool _take(String character) {
    if (!_peek(character)) {
      return false;
    }
    _index++;
    return true;
  }

  bool _peek(String character) => _current == character;

  String? get _current => _index < source.length ? source[_index] : null;
}

bool _isDigit(String? value) =>
    value != null && value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;

bool _isIdentifierStart(String? value) =>
    value != null &&
    ((value.codeUnitAt(0) >= 65 && value.codeUnitAt(0) <= 90) ||
        (value.codeUnitAt(0) >= 97 && value.codeUnitAt(0) <= 122) ||
        value == '_');

bool _isIdentifierPart(String? value) =>
    _isIdentifierStart(value) || _isDigit(value);

num _min(num left, num right) => left < right ? left : right;

num _max(num left, num right) => left > right ? left : right;
