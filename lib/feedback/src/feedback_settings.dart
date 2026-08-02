import 'package:shared_preferences/shared_preferences.dart';

// Kept injectable so tests and future host projects can own preferences.

abstract interface class ReadyFeedbackSettingsStore {
  Future<bool?> readEnabled();

  Future<void> writeEnabled(bool value);
}

class SharedPreferencesReadyFeedbackSettingsStore
    implements ReadyFeedbackSettingsStore {
  const SharedPreferencesReadyFeedbackSettingsStore(this.key);

  final String key;

  @override
  Future<bool?> readEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey(key)) return null;
    return preferences.getBool(key);
  }

  @override
  Future<void> writeEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }
}
