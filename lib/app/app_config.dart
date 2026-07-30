import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppConfig {
  static const _compiledSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _compiledSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _compiledAuthRedirectUri = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URI',
    defaultValue: 'perfect://login-callback',
  );
  static const _urlPreferenceKey = 'perfect.supabase_url.v1';
  static const _publishableKeyPreferenceKey =
      'perfect.supabase_publishable_key.v1';
  static const _connectionPreferenceKey = 'perfect.supabase_connection.v2';
  static const _deviceOverridePreferenceKey =
      'perfect.supabase_device_override.v1';

  static String _supabaseUrl = _compiledSupabaseUrl.trim();
  static String _supabasePublishableKey = _compiledSupabasePublishableKey
      .trim();

  static String get supabaseUrl => _supabaseUrl;
  static String get supabasePublishableKey => _supabasePublishableKey;
  static String get authRedirectUri => _compiledAuthRedirectUri;
  static bool get isConfigured =>
      validate(
        supabaseUrl: _supabaseUrl,
        publishableKey: _supabasePublishableKey,
      ) ==
      null;

  /// A complete, valid build-time pair wins. Otherwise each private
  /// installation can connect itself without baking a public client key into
  /// Git. An explicit device override wins even for a preconfigured private
  /// build, so a mistyped CI value can always be recovered without clearing
  /// the app's local planner database.
  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedConnection = _readSavedConnection(preferences);
    final savedUrl = savedConnection?.$1 ?? '';
    final savedKey = savedConnection?.$2 ?? '';
    final savedPairIsValid =
        validate(supabaseUrl: savedUrl, publishableKey: savedKey) == null;
    if ((preferences.getBool(_deviceOverridePreferenceKey) ?? false) &&
        savedPairIsValid) {
      _supabaseUrl = savedUrl;
      _supabasePublishableKey = savedKey;
      return;
    }

    // Treat build-time configuration as a pair. A CI job with only one define
    // must not shadow a valid device configuration on every restart.
    if (validate(
          supabaseUrl: _compiledSupabaseUrl,
          publishableKey: _compiledSupabasePublishableKey,
        ) ==
        null) {
      _supabaseUrl = _compiledSupabaseUrl.trim();
      _supabasePublishableKey = _compiledSupabasePublishableKey.trim();
      return;
    }
    _supabaseUrl = savedPairIsValid ? savedUrl : '';
    _supabasePublishableKey = savedPairIsValid ? savedKey : '';
  }

  static Future<void> configureDevice({
    required String supabaseUrl,
    required String publishableKey,
  }) async {
    final normalizedUrl = supabaseUrl.trim();
    final normalizedKey = publishableKey.trim();
    final validation = validate(
      supabaseUrl: normalizedUrl,
      publishableKey: normalizedKey,
    );
    if (validation != null) throw FormatException(validation);
    final preferences = await SharedPreferences.getInstance();
    // Store the pair as one value. Two independent SharedPreferences writes
    // can leave a valid-looking URL joined to an old project's key if the
    // process or storage fails between them.
    final connectionSaved = await preferences.setString(
      _connectionPreferenceKey,
      jsonEncode(<String, String>{
        'url': normalizedUrl,
        'publishable_key': normalizedKey,
      }),
    );
    // Commit the override marker last. A failed marker never makes a device
    // value outrank a known-good build-time connection.
    final overrideSaved =
        connectionSaved &&
        await preferences.setBool(_deviceOverridePreferenceKey, true);
    if (!overrideSaved) {
      if (connectionSaved) {
        await preferences.remove(_connectionPreferenceKey);
      }
      throw StateError(
        'This device could not persist the Supabase connection settings.',
      );
    }
    // The v1 split keys are read only for migration. Removing them after the
    // atomic v2 pair succeeds prevents stale values from becoming a fallback.
    await preferences.remove(_urlPreferenceKey);
    await preferences.remove(_publishableKeyPreferenceKey);
    _supabaseUrl = normalizedUrl;
    _supabasePublishableKey = normalizedKey;
  }

  static (String, String)? _readSavedConnection(SharedPreferences preferences) {
    final encoded = preferences.getString(_connectionPreferenceKey);
    if (encoded != null) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map) {
          final url = '${decoded['url'] ?? ''}'.trim();
          final key = '${decoded['publishable_key'] ?? ''}'.trim();
          if (validate(supabaseUrl: url, publishableKey: key) == null) {
            return (url, key);
          }
        }
      } on Object {
        // Fall through to the v1 migration pair.
      }
    }
    final legacyUrl = preferences.getString(_urlPreferenceKey)?.trim() ?? '';
    final legacyKey =
        preferences.getString(_publishableKeyPreferenceKey)?.trim() ?? '';
    return validate(supabaseUrl: legacyUrl, publishableKey: legacyKey) == null
        ? (legacyUrl, legacyKey)
        : null;
  }

  static String? validate({
    required String supabaseUrl,
    required String publishableKey,
  }) {
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                (uri.host == 'localhost' || uri.host == '127.0.0.1')))) {
      return 'Enter an HTTPS Supabase project URL.';
    }
    final key = publishableKey.trim();
    if (key.length < 20) {
      return 'Enter the project publishable (anon) key.';
    }
    if (_looksPrivileged(key)) {
      return 'A service-role or secret key must never be stored in Perfect.';
    }
    return null;
  }

  static bool _looksPrivileged(String key) {
    final lower = key.toLowerCase();
    if (lower.startsWith('sb_secret_') || lower.contains('service_role')) {
      return true;
    }
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map &&
          '${decoded['role']}'.toLowerCase() == 'service_role';
    } on Object {
      return false;
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _supabaseUrl = '';
    _supabasePublishableKey = '';
  }
}
