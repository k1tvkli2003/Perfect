import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:uuid/uuid.dart';

/// Android-only bridge for the native, resizable Perfect Today widget.
///
/// The native widget is deliberately a projection: the Drift database remains
/// authoritative. A bounded native replay queue makes a direct widget tap
/// durable even while Flutter is not in memory; the background callback and
/// next foreground launch reconcile it through the same task service.
class PerfectTodayWidgetBridge {
  const PerfectTodayWidgetBridge();

  static const providerClassName =
      'com.k1tvkli2003.perfect.PerfectTodayWidgetProvider';
  static const snapshotKey = 'perfect_today_widget_snapshot_v1';
  static const pendingActionsKey = 'perfect_today_widget_actions_v1';
  static const acknowledgedActionsKey =
      'perfect_today_widget_acknowledged_actions_v1';
  static const pendingQuickAddsKey = 'perfect_today_widget_quick_adds_v1';
  static const acknowledgedQuickAddsKey =
      'perfect_today_widget_acknowledged_quick_adds_v1';
  static const interactionTokenKey = 'perfect_today_widget_token_v1';
  static const ownerIdKey = 'perfect_today_widget_owner_v1';
  static const showTitlesKey = 'perfect_today_widget_show_titles_v1';

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<PerfectTodayWidgetSettings> readSettings() async {
    if (!isSupported) {
      return const PerfectTodayWidgetSettings(
        isAvailable: false,
        showTaskTitles: false,
      );
    }
    try {
      return PerfectTodayWidgetSettings(
        isAvailable: true,
        // This is a private, single-owner app and the widget's core promise is
        // a scrollable agenda. The owner can hide titles instantly in More.
        showTaskTitles:
            await HomeWidget.getWidgetData<bool>(
              showTitlesKey,
              defaultValue: true,
            ) ??
            true,
      );
    } on Object catch (_) {
      return const PerfectTodayWidgetSettings(
        isAvailable: false,
        showTaskTitles: false,
      );
    }
  }

  Future<PerfectTodayWidgetSettings> setShowTaskTitles(bool value) async {
    if (!isSupported) {
      return const PerfectTodayWidgetSettings(
        isAvailable: false,
        showTaskTitles: false,
      );
    }
    try {
      await HomeWidget.saveWidgetData<bool>(showTitlesKey, value);
      return PerfectTodayWidgetSettings(
        isAvailable: true,
        showTaskTitles: value,
      );
    } on Object catch (_) {
      return PerfectTodayWidgetSettings(
        isAvailable: false,
        showTaskTitles: value,
      );
    }
  }

  Future<bool> requestPin() async {
    if (!isSupported) return false;
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) return false;
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: providerClassName,
      );
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  Future<void> publish({
    required String ownerId,
    required DateTime now,
    required Iterable<PerfectTodayWidgetItem> items,
    required bool showTaskTitles,
  }) async {
    if (!isSupported || ownerId.trim().isEmpty) return;
    try {
      final token = await _readOrCreateInteractionToken();
      final localNow = now.toLocal();
      final list = items.toList(growable: false);
      final snapshot = <String, dynamic>{
        'schema_version': 1,
        'owner_id': ownerId,
        'date_key': localDateKey(localNow),
        'date_label': _dateLabel(localNow),
        'show_task_titles': showTaskTitles,
        'updated_at_millis': DateTime.now().millisecondsSinceEpoch,
        'items': <Map<String, dynamic>>[
          for (var index = 0; index < list.length; index++)
            list[index].toJson(
              title: showTaskTitles ? list[index].title : 'Task ${index + 1}',
            ),
        ],
      };
      await Future.wait(<Future<bool?>>[
        HomeWidget.saveWidgetData<String>(snapshotKey, jsonEncode(snapshot)),
        HomeWidget.saveWidgetData<String>(ownerIdKey, ownerId),
        HomeWidget.saveWidgetData<String>(interactionTokenKey, token),
      ]);
      await HomeWidget.updateWidget(qualifiedAndroidName: providerClassName);
    } on Object catch (_) {
      // An unavailable launcher/plugin never blocks the local planner UI.
    }
  }

  Future<List<PlannerWidgetTaskAction>> pendingActions() async {
    if (!isSupported) return const <PlannerWidgetTaskAction>[];
    try {
      final values = await Future.wait<String?>(<Future<String?>>[
        HomeWidget.getWidgetData<String>(pendingActionsKey, defaultValue: '[]'),
        HomeWidget.getWidgetData<String>(
          acknowledgedActionsKey,
          defaultValue: '[]',
        ),
      ]);
      final decoded = jsonDecode(values[0] ?? '[]');
      if (decoded is! List) return const <PlannerWidgetTaskAction>[];
      final acknowledged = _stringSetFromJson(values[1]);
      final result = <PlannerWidgetTaskAction>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final action = _decodeTaskAction(Map<String, dynamic>.from(entry));
        if (action == null) {
          // Native stale/corrupt rows are intentionally skipped; the app's
          // authoritative projection will replace the widget snapshot.
          continue;
        }
        if (!acknowledged.contains(action.id)) result.add(action);
      }
      result.sort(comparePerfectTodayWidgetReplayOrder);
      return result;
    } on Object catch (_) {
      return const <PlannerWidgetTaskAction>[];
    }
  }

  /// Acknowledgments are a separate monotonic side channel. Dart never
  /// overwrites the native queue, so a launcher tap racing this write cannot be
  /// lost. Native compaction consumes these IDs atomically with its next tap.
  Future<void> acknowledgeActions(Iterable<String> actionIds) async {
    if (!isSupported) return;
    final normalized = actionIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) return;
    try {
      final prior = await HomeWidget.getWidgetData<String>(
        acknowledgedActionsKey,
        defaultValue: '[]',
      );
      normalized.addAll(_stringSetFromJson(prior));
      await HomeWidget.saveWidgetData<String>(
        acknowledgedActionsKey,
        jsonEncode(normalized.toList(growable: false)..sort()),
      );
    } on Object {
      // Replaying an already-applied absolute-state mutation is idempotent.
      // A failed acknowledgement therefore delays compaction, not correctness.
    }
  }

  Future<List<PerfectTodayWidgetQuickAdd>> pendingQuickAdds() async {
    if (!isSupported) return const <PerfectTodayWidgetQuickAdd>[];
    try {
      final values = await Future.wait<String?>(<Future<String?>>[
        HomeWidget.getWidgetData<String>(
          pendingQuickAddsKey,
          defaultValue: '[]',
        ),
        HomeWidget.getWidgetData<String>(
          acknowledgedQuickAddsKey,
          defaultValue: '[]',
        ),
      ]);
      final decoded = jsonDecode(values[0] ?? '[]');
      if (decoded is! List) return const <PerfectTodayWidgetQuickAdd>[];
      final acknowledged = _stringSetFromJson(values[1]);
      final requests = <PerfectTodayWidgetQuickAdd>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final request = _decodeQuickAdd(Map<String, dynamic>.from(entry));
        if (request != null && !acknowledged.contains(request.id)) {
          requests.add(request);
        }
      }
      requests.sort(comparePerfectTodayWidgetQuickAddOrder);
      return requests;
    } on Object catch (_) {
      return const <PerfectTodayWidgetQuickAdd>[];
    }
  }

  Future<void> acknowledgeQuickAdds(Iterable<String> requestIds) async {
    if (!isSupported) return;
    final normalized = requestIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) return;
    try {
      final prior = await HomeWidget.getWidgetData<String>(
        acknowledgedQuickAddsKey,
        defaultValue: '[]',
      );
      normalized.addAll(_stringSetFromJson(prior));
      await HomeWidget.saveWidgetData<String>(
        acknowledgedQuickAddsKey,
        jsonEncode(normalized.toList(growable: false)..sort()),
      );
    } on Object {
      // The request ID is also the local mutation ID, so delayed compaction is
      // safe: every replay converges on the same task.
    }
  }

  Future<PerfectTodayWidgetSecurityContext?> readSecurityContext() async {
    if (!isSupported) return null;
    try {
      final values = await Future.wait<Object?>(<Future<Object?>>[
        HomeWidget.getWidgetData<String>(interactionTokenKey),
        HomeWidget.getWidgetData<String>(ownerIdKey),
      ]);
      final token = values[0] as String?;
      final ownerId = values[1] as String?;
      if (token == null ||
          ownerId == null ||
          token.isEmpty ||
          ownerId.isEmpty) {
        return null;
      }
      return PerfectTodayWidgetSecurityContext(token: token, ownerId: ownerId);
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> clearForSignOut() async {
    if (!isSupported) return;
    try {
      await Future.wait(<Future<bool?>>[
        HomeWidget.saveWidgetData<String>(snapshotKey, null),
        HomeWidget.saveWidgetData<String>(pendingActionsKey, '[]'),
        HomeWidget.saveWidgetData<String>(acknowledgedActionsKey, '[]'),
        HomeWidget.saveWidgetData<String>(pendingQuickAddsKey, '[]'),
        HomeWidget.saveWidgetData<String>(acknowledgedQuickAddsKey, '[]'),
        HomeWidget.saveWidgetData<String>(ownerIdKey, null),
        HomeWidget.saveWidgetData<String>(interactionTokenKey, null),
      ]);
      await HomeWidget.updateWidget(qualifiedAndroidName: providerClassName);
    } on Object catch (_) {
      // Signing out remains available even if an Android launcher is absent.
    }
  }

  static Set<String> _stringSetFromJson(String? raw) {
    try {
      final decoded = jsonDecode(raw ?? '[]');
      if (decoded is! List) return <String>{};
      return decoded
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
    } on Object {
      return <String>{};
    }
  }

  /// Returns the URI that launched a cold Android app from the widget. An
  /// unavailable launcher/plugin is treated as no launch rather than a local
  /// planner startup failure.
  Future<Uri?> initiallyLaunchedUri() async {
    if (!isSupported) return null;
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } on Object catch (_) {
      return null;
    }
  }

  /// Emits widget launch URIs while the app process is already alive. The
  /// stream deliberately degrades to completion on plugin/channel failure so
  /// navigation cannot take down the private workspace.
  Stream<Uri?> widgetLaunchUris() async* {
    if (!isSupported) return;
    try {
      await for (final uri in HomeWidget.widgetClicked) {
        yield uri;
      }
    } on Object catch (_) {
      return;
    }
  }

  static bool isTodayLaunchUri(Uri? uri) =>
      uri != null &&
      uri.scheme == 'perfect' &&
      uri.host == 'planner' &&
      uri.pathSegments.length == 1 &&
      uri.pathSegments.single == 'today';

  static PerfectTodayWidgetRefreshRequest? refreshRequestFromBackgroundUri(
    Uri? uri,
  ) {
    if (uri == null ||
        uri.scheme != 'perfect' ||
        uri.host != 'widget-refresh') {
      return null;
    }
    final ownerId = uri.queryParameters['owner_id']?.trim();
    if (ownerId == null || ownerId.isEmpty) return null;
    return PerfectTodayWidgetRefreshRequest(ownerId: ownerId);
  }

  static PlannerWidgetTaskAction? actionFromBackgroundUri(Uri? uri) {
    if (uri == null || uri.scheme != 'perfect' || uri.host != 'widget-action') {
      return null;
    }
    final query = uri.queryParameters;
    return _decodeTaskAction(<String, dynamic>{
      'id': query['id'],
      'owner_id': query['owner_id'],
      'entity_id': query['entity_id'],
      'kind': query['kind'],
      'state': query['state'],
      'progress_percent': int.tryParse(query['progress_percent'] ?? ''),
      'local_day': query['local_day'],
      'occurred_at': query['occurred_at'],
      'queue_sequence': query.containsKey('queue_sequence')
          ? int.tryParse(query['queue_sequence'] ?? '')
          : null,
    });
  }

  static PerfectTodayWidgetQuickAddRequest? quickAddRequestFromBackgroundUri(
    Uri? uri,
  ) {
    if (uri == null ||
        uri.scheme != 'perfect' ||
        uri.host != 'widget-quick-add') {
      return null;
    }
    final id = uri.queryParameters['id']?.trim() ?? '';
    final ownerId = uri.queryParameters['owner_id']?.trim() ?? '';
    if (!Uuid.isValidUUID(fromString: id) || ownerId.isEmpty) return null;
    return PerfectTodayWidgetQuickAddRequest(
      id: id.toLowerCase(),
      ownerId: ownerId,
    );
  }

  static bool secretsMatch(String expected, String candidate) {
    if (expected.length != candidate.length) return false;
    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected.codeUnitAt(index) ^ candidate.codeUnitAt(index);
    }
    return difference == 0;
  }

  Future<String> _readOrCreateInteractionToken() async {
    final existing = await HomeWidget.getWidgetData<String>(
      interactionTokenKey,
    );
    if (existing != null && existing.trim().isNotEmpty) return existing;
    return const Uuid().v4();
  }

  static PlannerWidgetTaskAction? _decodeTaskAction(Map<String, dynamic> json) {
    if (!_hasValidWireContract(json)) return null;
    try {
      return PlannerWidgetTaskAction.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  static PerfectTodayWidgetQuickAdd? _decodeQuickAdd(
    Map<String, dynamic> json,
  ) {
    try {
      return PerfectTodayWidgetQuickAdd.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  static bool _hasValidWireContract(Map<String, dynamic> json) {
    final state = json['state'];
    if (state is! String ||
        !const <String>{
          'pending',
          'completed',
          'missed',
          'partial',
        }.contains(state)) {
      return false;
    }
    final kind = json['kind'];
    if (kind != PlannerEntityKind.oneOffTask.wireValue &&
        kind != PlannerEntityKind.recurringTask.wireValue) {
      return false;
    }
    if (!_isCanonicalLocalDay(json['local_day'])) return false;
    final sequence = json['queue_sequence'];
    if (sequence != null && (sequence is! int || sequence < 0)) return false;
    final percent = json['progress_percent'];
    if (percent is! int) return false;
    return switch (state) {
      'completed' => percent == 100,
      'partial' => percent >= 1 && percent <= 99,
      _ => percent == 0,
    };
  }

  static bool _isCanonicalLocalDay(Object? raw) {
    if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return false;
    }
    final parts = raw.split('-').map(int.tryParse).toList(growable: false);
    if (parts.any((part) => part == null)) return false;
    final year = parts[0]!;
    final month = parts[1]!;
    final day = parts[2]!;
    if (year < 1 || year > 9999) return false;
    final candidate = DateTime(year, month, day);
    return candidate.year == year &&
        candidate.month == month &&
        candidate.day == day;
  }
}

/// Native sequence is the authoritative tap order. Wall-clock timestamps can
/// move backwards after a manual clock correction, while this monotonic value
/// is persisted before every optimistic widget transition.
///
/// Legacy actions without a sequence drain first so any newer sequenced tap
/// remains the final absolute state.
int comparePerfectTodayWidgetReplayOrder(
  PlannerWidgetTaskAction first,
  PlannerWidgetTaskAction second,
) {
  final firstSequenced = first.queueSequence > 0;
  final secondSequenced = second.queueSequence > 0;
  if (firstSequenced != secondSequenced) return firstSequenced ? 1 : -1;
  if (firstSequenced) {
    final bySequence = first.queueSequence.compareTo(second.queueSequence);
    if (bySequence != 0) return bySequence;
  }
  final byTime = first.occurredAt.compareTo(second.occurredAt);
  if (byTime != 0) return byTime;
  return first.id.compareTo(second.id);
}

class PerfectTodayWidgetSettings {
  const PerfectTodayWidgetSettings({
    required this.isAvailable,
    required this.showTaskTitles,
  });

  final bool isAvailable;
  final bool showTaskTitles;
}

class PerfectTodayWidgetSecurityContext {
  const PerfectTodayWidgetSecurityContext({
    required this.token,
    required this.ownerId,
  });

  final String token;
  final String ownerId;
}

class PerfectTodayWidgetRefreshRequest {
  const PerfectTodayWidgetRefreshRequest({required this.ownerId});

  final String ownerId;
}

class PerfectTodayWidgetQuickAddRequest {
  const PerfectTodayWidgetQuickAddRequest({
    required this.id,
    required this.ownerId,
  });

  final String id;
  final String ownerId;
}

class PerfectTodayWidgetQuickAdd {
  const PerfectTodayWidgetQuickAdd({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.occurredAt,
    this.scheduledAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final DateTime occurredAt;
  final DateTime? scheduledAt;

  factory PerfectTodayWidgetQuickAdd.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final ownerId = json['owner_id']?.toString().trim() ?? '';
    final title = json['title']?.toString().trim() ?? '';
    final occurredAt = DateTime.tryParse(
      json['occurred_at']?.toString() ?? '',
    )?.toUtc();
    final scheduledRaw = json['scheduled_at']?.toString().trim();
    final scheduledAt = scheduledRaw == null || scheduledRaw.isEmpty
        ? null
        : DateTime.tryParse(scheduledRaw)?.toUtc();
    if (!Uuid.isValidUUID(fromString: id) ||
        ownerId.isEmpty ||
        title.isEmpty ||
        title.length > 160 ||
        occurredAt == null ||
        (scheduledRaw != null &&
            scheduledRaw.isNotEmpty &&
            scheduledAt == null)) {
      throw const FormatException('Invalid widget quick-add request.');
    }
    return PerfectTodayWidgetQuickAdd(
      id: id.toLowerCase(),
      ownerId: ownerId,
      title: title,
      occurredAt: occurredAt,
      scheduledAt: scheduledAt,
    );
  }
}

int comparePerfectTodayWidgetQuickAddOrder(
  PerfectTodayWidgetQuickAdd first,
  PerfectTodayWidgetQuickAdd second,
) {
  final byTime = first.occurredAt.compareTo(second.occurredAt);
  if (byTime != 0) return byTime;
  return first.id.compareTo(second.id);
}

class PerfectTodayWidgetItem {
  const PerfectTodayWidgetItem({
    required this.entityId,
    required this.kind,
    required this.title,
    required this.timeLabel,
    required this.progress,
    required this.accent,
  });

  final String entityId;
  final PlannerEntityKind kind;
  final String title;
  final String timeLabel;
  final PlannerTaskProgress progress;
  final String accent;

  Map<String, dynamic> toJson({required String title}) => <String, dynamic>{
    'id': entityId,
    'kind': kind.wireValue,
    'title': title,
    'time': timeLabel,
    'state': progress.state.wireValue,
    'progress_percent': progress.percent,
    'accent': accent,
  };
}

String _dateLabel(DateTime date) {
  return PerfectLocalTime.gregorianShort(date);
}
