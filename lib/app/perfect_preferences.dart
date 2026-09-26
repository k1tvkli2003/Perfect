import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PerfectContrastMode { system, high }

abstract final class PerfectPreferences {
  static const themeModeKey = 'perfect.theme_mode';
  static const contrastModeKey = 'perfect.contrast_mode';
  static const navigationRailExtendedKey =
      'perfect.windows_navigation_rail_extended';
  static const tasksActiveViewIdKey = 'perfect.tasks_active_view_id';

  static Future<String?> readTasksActiveViewId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(tasksActiveViewIdKey);
  }

  static Future<void> saveTasksActiveViewId(String viewId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(tasksActiveViewIdKey, viewId);
  }

  static Future<ThemeMode> readThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(themeModeKey, mode.name);
  }

  static Future<PerfectContrastMode> readContrastMode() async {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(contrastModeKey)) {
      'high' => PerfectContrastMode.high,
      _ => PerfectContrastMode.system,
    };
  }

  static Future<void> saveContrastMode(PerfectContrastMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(contrastModeKey, mode.name);
  }

  static Future<bool?> readNavigationRailExtended() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey(navigationRailExtendedKey)) return null;
    return preferences.getBool(navigationRailExtendedKey);
  }

  static Future<void> saveNavigationRailExtended(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(navigationRailExtendedKey, value);
  }
}
