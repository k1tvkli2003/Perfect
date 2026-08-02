import 'package:flutter/foundation.dart';

// Product-neutral configuration retained from the reusable component.

@immutable
class ReadyFeedbackConfig {
  const ReadyFeedbackConfig({
    required this.applicationName,
    required this.storageNamespace,
    required this.settingsKey,
    this.enabledByDefault = true,
    this.maxEntries = 250,
    this.maxLogs = 300,
    this.maxScreenshotPixelRatio = 2.5,
    this.maxScreenshotBytes = 16 * 1024 * 1024,
    this.maxScreenshotStorageBytes = 256 * 1024 * 1024,
    this.maxScreenshotDimensionPx = 16384,
    this.maxNoteCharacters = 40000,
    this.maxRouteCharacters = 2000,
    this.maxLogMessageCharacters = 8000,
    this.maxStackTraceCharacters = 32000,
  }) : assert(maxEntries > 0),
       assert(maxLogs > 0),
       assert(maxScreenshotPixelRatio >= 1),
       assert(maxScreenshotBytes >= 24),
       assert(maxScreenshotStorageBytes >= maxScreenshotBytes),
       assert(maxScreenshotDimensionPx > 0),
       assert(maxNoteCharacters > 0),
       assert(maxRouteCharacters > 0),
       assert(maxLogMessageCharacters > 0),
       assert(maxStackTraceCharacters > 0);

  final String applicationName;
  final String storageNamespace;
  final String settingsKey;
  final bool enabledByDefault;
  final int maxEntries;
  final int maxLogs;
  final double maxScreenshotPixelRatio;
  final int maxScreenshotBytes;
  final int maxScreenshotStorageBytes;
  final int maxScreenshotDimensionPx;
  final int maxNoteCharacters;
  final int maxRouteCharacters;
  final int maxLogMessageCharacters;
  final int maxStackTraceCharacters;
}
