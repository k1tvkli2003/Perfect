// Defense-in-depth redaction for diagnostic text written to disk or exports.

abstract final class ReadyFeedbackRedactor {
  static const String _redacted = '[REDACTED]';

  static final String _credentialKey =
      r'(?:password|passwd|passcode|token|access[_-]?token|refresh[_-]?token|'
      r'id[_-]?token|api[_-]?key|client[_-]?secret|private[_-]?key|secret|'
      r'service[_-]?role|service[_-]?role[_-]?key|anon[_-]?key|session)';

  static final RegExp _authorization = RegExp(
    r'(authorization\s*[:=]\s*(?:bearer|basic)\s+)([^\s,;]+)',
    caseSensitive: false,
  );
  static final RegExp _quotedAssignment = RegExp(
    '(["\\\']?$_credentialKey["\\\']?\\s*[:=]\\s*["\\\'])'
    '([^"\\\'\\r\\n]*)'
    '(["\\\'])',
    caseSensitive: false,
  );
  static final RegExp _plainAssignment = RegExp(
    '($_credentialKey\\s*[:=]\\s*)([^\\s,;&"\\\']+)',
    caseSensitive: false,
  );
  static final RegExp _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );
  static final RegExp _uriCredentials = RegExp(
    r'([a-z][a-z0-9+.-]*://[^\s/:@]+:)([^\s/@]+)(@)',
    caseSensitive: false,
  );
  static final RegExp _privateKeyBlock = RegExp(
    r'-----BEGIN(?: [A-Z0-9]+)* PRIVATE KEY-----[\s\S]*?'
    r'-----END(?: [A-Z0-9]+)* PRIVATE KEY-----',
    caseSensitive: false,
  );

  static String redact(String input) {
    var value = input;
    value = value.replaceAllMapped(
      _privateKeyBlock,
      (_) => '-----PRIVATE KEY $_redacted-----',
    );
    value = value.replaceAllMapped(
      _authorization,
      (match) => '${match.group(1)}$_redacted',
    );
    value = value.replaceAllMapped(
      _quotedAssignment,
      (match) => '${match.group(1)}$_redacted${match.group(3)}',
    );
    value = value.replaceAllMapped(
      _plainAssignment,
      (match) => '${match.group(1)}$_redacted',
    );
    value = value.replaceAllMapped(
      _uriCredentials,
      (match) => '${match.group(1)}$_redacted${match.group(3)}',
    );
    return value.replaceAll(_jwt, '[REDACTED_JWT]');
  }

  static String redactAndLimit(String input, int maxCodePoints) {
    final redacted = redact(input);
    if (redacted.runes.length <= maxCodePoints) return redacted;
    final retained = String.fromCharCodes(redacted.runes.take(maxCodePoints));
    return '$retained\n[TRUNCATED]';
  }
}
