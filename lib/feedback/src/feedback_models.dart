import 'package:flutter/foundation.dart';

// Persistent contract for private feedback entries and diagnostic logs.

enum ReadyFeedbackKind { error, suggestion, criticism, note }

extension ReadyFeedbackKindCopy on ReadyFeedbackKind {
  String get label => switch (this) {
    ReadyFeedbackKind.error => 'Error',
    ReadyFeedbackKind.suggestion => 'Suggestion',
    ReadyFeedbackKind.criticism => 'Criticism',
    ReadyFeedbackKind.note => 'Note',
  };
}

@immutable
class ReadyFeedbackEntry {
  const ReadyFeedbackEntry({
    required this.id,
    required this.createdAt,
    required this.route,
    required this.note,
    required this.kind,
    this.screenshotFileName,
    this.screenshotWidthPx,
    this.screenshotHeightPx,
    this.screenshotByteLength,
    this.screenshotPixelRatio,
  });

  factory ReadyFeedbackEntry.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String?;
    return ReadyFeedbackEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      route: json['route'] as String? ?? 'Unknown',
      note: json['note'] as String? ?? '',
      kind: ReadyFeedbackKind.values.firstWhere(
        (candidate) => candidate.name == kindName,
        orElse: () => ReadyFeedbackKind.note,
      ),
      screenshotFileName: json['screenshotFileName'] as String?,
      screenshotWidthPx: (json['screenshotWidthPx'] as num?)?.toInt(),
      screenshotHeightPx: (json['screenshotHeightPx'] as num?)?.toInt(),
      screenshotByteLength: (json['screenshotByteLength'] as num?)?.toInt(),
      screenshotPixelRatio: (json['screenshotPixelRatio'] as num?)?.toDouble(),
    );
  }

  final String id;
  final DateTime createdAt;
  final String route;
  final String note;
  final ReadyFeedbackKind kind;
  final String? screenshotFileName;
  final int? screenshotWidthPx;
  final int? screenshotHeightPx;
  final int? screenshotByteLength;
  final double? screenshotPixelRatio;

  bool get hasScreenshot => screenshotFileName?.isNotEmpty ?? false;

  ReadyFeedbackEntry copyWith({
    String? screenshotFileName,
    int? screenshotWidthPx,
    int? screenshotHeightPx,
    int? screenshotByteLength,
    double? screenshotPixelRatio,
    bool clearScreenshot = false,
  }) => ReadyFeedbackEntry(
    id: id,
    createdAt: createdAt,
    route: route,
    note: note,
    kind: kind,
    screenshotFileName: clearScreenshot
        ? null
        : screenshotFileName ?? this.screenshotFileName,
    screenshotWidthPx: clearScreenshot
        ? null
        : screenshotWidthPx ?? this.screenshotWidthPx,
    screenshotHeightPx: clearScreenshot
        ? null
        : screenshotHeightPx ?? this.screenshotHeightPx,
    screenshotByteLength: clearScreenshot
        ? null
        : screenshotByteLength ?? this.screenshotByteLength,
    screenshotPixelRatio: clearScreenshot
        ? null
        : screenshotPixelRatio ?? this.screenshotPixelRatio,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'route': route,
    'note': note,
    'kind': kind.name,
    'screenshotFileName': screenshotFileName,
    'screenshotWidthPx': screenshotWidthPx,
    'screenshotHeightPx': screenshotHeightPx,
    'screenshotByteLength': screenshotByteLength,
    'screenshotPixelRatio': screenshotPixelRatio,
  };
}

@immutable
class ReadyFeedbackScreenshotCapture {
  const ReadyFeedbackScreenshotCapture({
    required this.bytes,
    required this.pixelRatio,
  });

  final Uint8List bytes;
  final double pixelRatio;
}

enum ReadyFeedbackLogLevel { error, warning, info, debug }

@immutable
class ReadyFeedbackLogRecord {
  const ReadyFeedbackLogRecord({
    required this.createdAt,
    required this.level,
    required this.message,
    this.stackTrace,
  });

  factory ReadyFeedbackLogRecord.fromJson(Map<String, Object?> json) =>
      ReadyFeedbackLogRecord(
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
        level: ReadyFeedbackLogLevel.values.firstWhere(
          (candidate) => candidate.name == json['level'],
          orElse: () => ReadyFeedbackLogLevel.info,
        ),
        message: json['message'] as String? ?? '',
        stackTrace: json['stackTrace'] as String?,
      );

  final DateTime createdAt;
  final ReadyFeedbackLogLevel level;
  final String message;
  final String? stackTrace;

  Map<String, Object?> toJson() => <String, Object?>{
    'createdAt': createdAt.toUtc().toIso8601String(),
    'level': level.name,
    'message': message,
    'stackTrace': stackTrace,
  };
}

@immutable
class ReadyFeedbackExportPreview {
  const ReadyFeedbackExportPreview({
    required this.entryCount,
    required this.screenshotCount,
    required this.logCount,
  });

  final int entryCount;
  final int screenshotCount;
  final int logCount;
}
