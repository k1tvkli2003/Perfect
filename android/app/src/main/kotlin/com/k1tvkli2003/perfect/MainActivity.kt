package com.k1tvkli2003.perfect

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  companion object {
    private const val APPEARANCE_CHANNEL =
        "com.k1tvkli2003.perfect/system_appearance"
    private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
    private const val APPEARANCE_THEME_ID = "perfect_appearance_theme_id"
    private const val APPEARANCE_DARK = "perfect_appearance_dark"
    private const val APPEARANCE_HIGH_CONTRAST =
        "perfect_appearance_high_contrast"
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPEARANCE_CHANNEL)
        .setMethodCallHandler { call, result ->
          if (call.method != "apply") {
            result.notImplemented()
            return@setMethodCallHandler
          }
          val themeMode = call.argument<String>("themeMode") ?: "system"
          val themeId = call.argument<String>("themeId").orEmpty()
          val dark = call.argument<Boolean>("dark") ?: false
          val highContrast = call.argument<Boolean>("highContrast") ?: false

          getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
              .edit()
              .putString(APPEARANCE_THEME_ID, themeId)
              .putBoolean(APPEARANCE_DARK, dark)
              .putBoolean(APPEARANCE_HIGH_CONTRAST, highContrast)
              .apply()

          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val uiModeManager = getSystemService(UiModeManager::class.java)
            val nightMode = when (themeMode) {
              "dark" -> UiModeManager.MODE_NIGHT_YES
              "light" -> UiModeManager.MODE_NIGHT_NO
              else -> UiModeManager.MODE_NIGHT_AUTO
            }
            uiModeManager.setApplicationNightMode(nightMode)
          }
          PerfectTodayWidgetProvider.refresh(this)
          result.success(null)
        }
  }
}
