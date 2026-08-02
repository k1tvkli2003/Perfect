/// The single private account exposed by Perfect's sign-in UI.
///
/// Supabase password authentication still requires an email address. Perfect
/// keeps that transport detail out of the UI and resolves the owner's chosen
/// username to an email supplied only to trusted builds.
class PrivateOwnerIdentity {
  const PrivateOwnerIdentity({required this.username, required this.email});

  const PrivateOwnerIdentity.compiled()
    : username = compiledUsername,
      email = compiledEmail;

  static const compiledUsername = 'keyvan';
  static const compiledEmail = String.fromEnvironment(
    'PERFECT_OWNER_AUTH_EMAIL',
  );

  final String username;
  final String email;

  bool recognizes(String candidate) =>
      candidate.trim().toLowerCase() == username.trim().toLowerCase();

  String? resolveEmail(String candidate) {
    if (!recognizes(candidate)) return null;
    final normalizedEmail = email.trim();
    return _looksLikeEmail(normalizedEmail) ? normalizedEmail : null;
  }

  bool get isConfigured => _looksLikeEmail(email.trim());

  static bool _looksLikeEmail(String value) {
    final separator = value.indexOf('@');
    return separator > 0 &&
        separator < value.length - 1 &&
        value.indexOf('.', separator) > separator + 1;
  }
}
