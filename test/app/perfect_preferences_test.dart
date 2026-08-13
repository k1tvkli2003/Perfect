import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('theme mode survives a fresh preferences read', () async {
    expect(await PerfectPreferences.readThemeMode(), ThemeMode.system);

    await PerfectPreferences.saveThemeMode(ThemeMode.dark);
    expect(await PerfectPreferences.readThemeMode(), ThemeMode.dark);

    await PerfectPreferences.saveThemeMode(ThemeMode.light);
    expect(await PerfectPreferences.readThemeMode(), ThemeMode.light);
  });

  test('unknown stored theme fails safely to the system setting', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PerfectPreferences.themeModeKey: 'future-theme',
    });
    expect(await PerfectPreferences.readThemeMode(), ThemeMode.system);
  });

  test(
    'contrast mode survives reads and unknown values fail to system',
    () async {
      expect(
        await PerfectPreferences.readContrastMode(),
        PerfectContrastMode.system,
      );

      await PerfectPreferences.saveContrastMode(PerfectContrastMode.high);
      expect(
        await PerfectPreferences.readContrastMode(),
        PerfectContrastMode.high,
      );

      SharedPreferences.setMockInitialValues(<String, Object>{
        PerfectPreferences.contrastModeKey: 'future-contrast',
      });
      expect(
        await PerfectPreferences.readContrastMode(),
        PerfectContrastMode.system,
      );
    },
  );
}
