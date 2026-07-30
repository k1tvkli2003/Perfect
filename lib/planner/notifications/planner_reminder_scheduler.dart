import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Device-local reminder choices. They deliberately do not sync: a phone and
/// a desktop may need different quiet hours and permission posture.
class PlannerReminderSettings {
  const PlannerReminderSettings({
    this.enabled = false,
    this.exactTiming = false,
    this.quietHoursEnabled = true,
    this.quietStartMinutes = 22 * 60,
    this.quietEndMinutes = 7 * 60,
  });

  final bool enabled;
  final bool exactTiming;
  final bool quietHoursEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;

  PlannerReminderSettings copyWith({
    bool? enabled,
    bool? exactTiming,
    bool? quietHoursEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
  }) => PlannerReminderSettings(
    enabled: enabled ?? this.enabled,
    exactTiming: exactTiming ?? this.exactTiming,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
    quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
  );
}

enum PlannerReminderActivation { enabled, denied, unavailable }

class PlannerReminderScheduleSummary {
  const PlannerReminderScheduleSummary({
    required this.scheduled,
    this.skipped = 0,
    this.failures = 0,
    this.truncated = 0,
    this.capacity = 96,
    this.disabled = false,
  });

  final int scheduled;
  final int skipped;
  final int failures;
  final int truncated;
  final int capacity;
  final bool disabled;

  bool get isComplete => failures == 0 && truncated == 0;
}

/// Boundary around platform APIs so local planner tests and the app itself can
/// share the same orchestration without granting notification permission.
abstract class PlannerReminderScheduler {
  Future<PlannerReminderSettings> readSettings();

  Future<void> saveSettings(PlannerReminderSettings settings);

  Future<PlannerReminderActivation> enable({bool requestExactTiming = false});

  Future<PlannerReminderScheduleSummary> sync(Iterable<PlannerEntity> entities);

  Future<void> dispose();
}

typedef PlannerRecurrenceHistoryLoader =
    Future<PlannerRecurrenceHistory> Function(
      PlannerEntity entity,
      DateTime day,
    );

typedef PlannerReminderCancelOverride = Future<void> Function(int id);
typedef PlannerReminderScheduleOverride =
    Future<void> Function({
      required int id,
      required String payload,
      required DateTime alertAt,
    });

/// Process-local bridge from Android/Windows notification activation into the
/// mounted planner. A pending target is retained for cold starts; the stream
/// handles clicks while Perfect is already open.
abstract final class PlannerReminderNavigation {
  static final StreamController<String> _targets =
      StreamController<String>.broadcast(sync: true);
  static String? _pendingEntityId;

  static Stream<String> get entityIds => _targets.stream;

  static void handlePayload(String? payload) {
    final normalized = payload?.trim();
    if (normalized == null || !normalized.startsWith('planner:')) return;
    final entityId = normalized.substring('planner:'.length).trim();
    if (entityId.isEmpty) return;
    _pendingEntityId = entityId;
    _targets.add(entityId);
  }

  static String? takePendingEntityId() {
    final target = _pendingEntityId;
    _pendingEntityId = null;
    return target;
  }

  static void resetForTesting() {
    _pendingEntityId = null;
  }
}

/// Stable cross-platform action identifier for owner-requested snoozes.
/// Android and Windows return the same string through [NotificationResponse],
/// keeping the behavior independent of either platform's notification UI.
abstract final class PlannerReminderSnooze {
  static const _prefix = 'perfect_snooze:';

  static String actionId(int minutes) =>
      '$_prefix${minutes.clamp(1, 1440).toInt()}';

  static int? minutesFromActionId(String? actionId) {
    if (actionId == null || !actionId.startsWith(_prefix)) return null;
    final minutes = int.tryParse(actionId.substring(_prefix.length));
    if (minutes == null || minutes < 1 || minutes > 1440) return null;
    return minutes;
  }
}

/// Pure, history-aware projection shared by the device scheduler and focused
/// recurrence tests. It never reads storage or invokes a platform plugin.
abstract final class PlannerReminderOccurrenceProjector {
  static bool isFlexible(PlannerEntity entity) {
    final frequency = safeJsonMap(
      entity.recurrence[PlannerRecurrenceKeys.frequency],
    );
    return safeJsonString(
              entity.recurrence[PlannerRecurrenceKeys.rule],
              fallback: 'none',
            ) ==
            'flexible' ||
        frequency.isNotEmpty;
  }

  static List<DateTime> futureOccurrences(
    PlannerEntity entity, {
    required DateTime from,
    required int maximum,
    PlannerRecurrenceHistory history = const PlannerRecurrenceHistory(),
  }) {
    final first = entity.scheduledAt;
    if (first == null ||
        maximum <= 0 ||
        entity.recurrence[PlannerRecurrenceKeys.paused] == true) {
      return const <DateTime>[];
    }
    if (isFlexible(entity)) {
      return _futureFlexibleOccurrences(
        entity,
        from: from,
        maximum: maximum,
        history: history,
      );
    }

    final rule = safeJsonString(
      entity.recurrence[PlannerRecurrenceKeys.rule],
      fallback: 'none',
    );
    if (rule == 'none') {
      return first.isAfter(from)
          ? <DateTime>[first.toUtc()]
          : const <DateTime>[];
    }

    final results = <DateTime>[];
    var cursor = from;
    while (results.length < maximum) {
      final next = PlannerRecurrenceEngine.nextEligibleAt(
        entity: entity,
        after: cursor,
      );
      if (next == null || !next.isAfter(cursor)) break;
      results.add(next.toUtc());
      cursor = next;
    }
    return results;
  }

  static List<DateTime> _futureFlexibleOccurrences(
    PlannerEntity entity, {
    required DateTime from,
    required int maximum,
    required PlannerRecurrenceHistory history,
  }) {
    final anchor = entity.scheduledAt!.toLocal();
    final referenceWindow = PlannerRecurrenceEngine.flexiblePeriodWindow(
      entity: entity,
      date: from,
    );
    if (referenceWindow == null) return const <DateTime>[];

    final occurrenceLimit = safeJsonInt(
      entity.recurrence[PlannerRecurrenceKeys.occurrenceLimit],
      fallback: 0,
    );
    var projectedLifetime = history.totalCompleted.clamp(0, 1 << 31).toInt();
    if (occurrenceLimit > 0 && projectedLifetime >= occurrenceLimit) {
      return const <DateTime>[];
    }

    final completedByPeriod = <int, int>{
      referenceWindow.startInclusive.microsecondsSinceEpoch: history
          .completedInPeriod
          .clamp(0, 1 << 31)
          .toInt(),
    };
    final results = <DateTime>[];
    final fromUtc = from.toUtc();
    final localFrom = from.toLocal();
    final firstDate = DateTime(localFrom.year, localFrom.month, localFrom.day);
    final endAt = safeJsonDateTime(
      entity.recurrence[PlannerRecurrenceKeys.endAt],
    )?.toLocal();

    for (var offset = 0; offset <= 4096 && results.length < maximum; offset++) {
      final date = firstDate.add(Duration(days: offset));
      if (endAt != null &&
          DateTime(
            date.year,
            date.month,
            date.day,
          ).isAfter(DateTime(endAt.year, endAt.month, endAt.day))) {
        break;
      }
      final candidate = DateTime(
        date.year,
        date.month,
        date.day,
        anchor.hour,
        anchor.minute,
        anchor.second,
        anchor.millisecond,
        anchor.microsecond,
      );
      final candidateUtc = candidate.toUtc();
      if (!candidateUtc.isAfter(fromUtc)) continue;

      final window = PlannerRecurrenceEngine.flexiblePeriodWindow(
        entity: entity,
        date: candidate,
      );
      if (window == null) break;
      final periodKey = window.startInclusive.microsecondsSinceEpoch;
      final completedInPeriod = completedByPeriod[periodKey] ?? 0;
      final eligible = PlannerRecurrenceEngine.occursOnDate(
        entity: entity,
        date: candidate,
        completedOccurrencesInPeriod: completedInPeriod,
        totalCompletedOccurrences: projectedLifetime,
      );
      if (!eligible) continue;

      results.add(candidateUtc);
      completedByPeriod[periodKey] = completedInPeriod + 1;
      projectedLifetime++;
      if (occurrenceLimit > 0 && projectedLifetime >= occurrenceLimit) break;
    }
    return results;
  }
}

class NoopPlannerReminderScheduler implements PlannerReminderScheduler {
  const NoopPlannerReminderScheduler();

  @override
  Future<void> dispose() async {}

  @override
  Future<PlannerReminderActivation> enable({bool requestExactTiming = false}) =>
      Future<PlannerReminderActivation>.value(
        PlannerReminderActivation.unavailable,
      );

  @override
  Future<PlannerReminderSettings> readSettings() =>
      Future<PlannerReminderSettings>.value(const PlannerReminderSettings());

  @override
  Future<void> saveSettings(PlannerReminderSettings settings) async {}

  @override
  Future<PlannerReminderScheduleSummary> sync(
    Iterable<PlannerEntity> entities,
  ) => Future<PlannerReminderScheduleSummary>.value(
    const PlannerReminderScheduleSummary(scheduled: 0, disabled: true),
  );
}

/// Android + Windows local scheduler. It never waits for Supabase and it asks
/// for Android permission only after the owner explicitly enables reminders.
class DevicePlannerReminderScheduler implements PlannerReminderScheduler {
  DevicePlannerReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? now,
    this.platformSupportedOverride,
    this.cancelNotificationOverride,
    this.scheduleNotificationOverride,
    this.skipPluginInitialization = false,
    this._recurrenceHistory,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _preferences = preferences ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now;

  static const _enabledKey = 'perfect.reminders.enabled.v1';
  static const _exactTimingKey = 'perfect.reminders.exact_timing.v1';
  static const _quietEnabledKey = 'perfect.reminders.quiet_enabled.v1';
  static const _quietStartKey = 'perfect.reminders.quiet_start.v1';
  static const _quietEndKey = 'perfect.reminders.quiet_end.v1';
  static const _scheduledIdsKey = 'perfect.reminders.scheduled_ids.v1';
  static const _maxScheduledNotifications = 96;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _now;
  // Public constructor seams keep platform behavior deterministic in tests;
  // production callers leave all four overrides unset.
  final bool? platformSupportedOverride;
  final PlannerReminderCancelOverride? cancelNotificationOverride;
  final PlannerReminderScheduleOverride? scheduleNotificationOverride;
  final bool skipPluginInitialization;
  final PlannerRecurrenceHistoryLoader? _recurrenceHistory;
  bool _initialized = false;
  bool _disposed = false;

  bool get _supported =>
      platformSupportedOverride ?? (Platform.isAndroid || Platform.isWindows);

  @override
  Future<PlannerReminderSettings> readSettings() async {
    final prefs = await _preferences();
    return PlannerReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      exactTiming: prefs.getBool(_exactTimingKey) ?? false,
      quietHoursEnabled: prefs.getBool(_quietEnabledKey) ?? true,
      quietStartMinutes: _boundedMinutes(prefs.getInt(_quietStartKey) ?? 1320),
      quietEndMinutes: _boundedMinutes(prefs.getInt(_quietEndKey) ?? 420),
    );
  }

  @override
  Future<void> saveSettings(PlannerReminderSettings settings) async {
    final prefs = await _preferences();
    final writes = await Future.wait<bool>(<Future<bool>>[
      prefs.setBool(_enabledKey, settings.enabled),
      prefs.setBool(_exactTimingKey, settings.exactTiming),
      prefs.setBool(_quietEnabledKey, settings.quietHoursEnabled),
      prefs.setInt(_quietStartKey, _boundedMinutes(settings.quietStartMinutes)),
      prefs.setInt(_quietEndKey, _boundedMinutes(settings.quietEndMinutes)),
    ]);
    if (writes.any((saved) => !saved)) {
      throw StateError('Reminder settings could not be persisted.');
    }
  }

  @override
  Future<PlannerReminderActivation> enable({
    bool requestExactTiming = false,
  }) async {
    if (!_supported || _disposed) return PlannerReminderActivation.unavailable;
    await _initialize();
    var exactGranted = false;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notificationsGranted =
          await android?.requestNotificationsPermission() ?? false;
      if (!notificationsGranted) return PlannerReminderActivation.denied;
      if (requestExactTiming) {
        exactGranted = await android?.requestExactAlarmsPermission() ?? false;
      }
    }
    final current = await readSettings();
    await saveSettings(
      current.copyWith(enabled: true, exactTiming: exactGranted),
    );
    return PlannerReminderActivation.enabled;
  }

  @override
  Future<PlannerReminderScheduleSummary> sync(
    Iterable<PlannerEntity> entities,
  ) async {
    if (!_supported || _disposed) {
      return const PlannerReminderScheduleSummary(scheduled: 0, disabled: true);
    }
    await _initialize();
    final settings = await readSettings();
    final prefs = await _preferences();
    final priorIds =
        prefs
            .getStringList(_scheduledIdsKey)
            ?.map(int.tryParse)
            .whereType<int>()
            .toSet() ??
        <int>{};
    final failedCancellationIds = await _cancelScheduledIds(priorIds);
    if (!settings.enabled) {
      if (failedCancellationIds.isEmpty) {
        await prefs.remove(_scheduledIdsKey);
      } else {
        // Retain only failed IDs so every later disabled sync retries them.
        // We must not forget a notification merely because Windows package
        // identity or an Android host transiently rejected cancellation.
        await prefs.setStringList(
          _scheduledIdsKey,
          failedCancellationIds.map((id) => '$id').toList(growable: false),
        );
      }
      return PlannerReminderScheduleSummary(
        scheduled: 0,
        failures: failedCancellationIds.length,
        disabled: true,
      );
    }

    var skipped = 0;
    var failures = failedCancellationIds.length;
    final now = _now().toUtc();
    final candidates = <_ReminderCandidate>[];
    final activeEntities =
        entities
            .where(
              (entity) =>
                  !entity.isDeleted &&
                  entity.status == PlannerEntityStatus.active,
            )
            .toList(growable: false)
          ..sort((left, right) => left.id.compareTo(right.id));
    for (final entity in activeEntities) {
      final reminders = safeJsonMapList(
        entity.payload['reminders'],
      ).where((reminder) => reminder[PlannerReminderKeys.enabled] != false);
      final plannedFor = entity.scheduledAt;
      if (plannedFor == null || reminders.isEmpty) continue;
      var history = const PlannerRecurrenceHistory();
      if (PlannerReminderOccurrenceProjector.isFlexible(entity)) {
        final loadHistory = _recurrenceHistory;
        if (loadHistory == null) {
          // Flexible reminders cannot be projected safely without durable
          // period and lifetime completion history.
          skipped++;
          continue;
        }
        try {
          history = await loadHistory(entity, now);
        } on Object {
          failures++;
          continue;
        }
      }
      final occurrences = PlannerReminderOccurrenceProjector.futureOccurrences(
        entity,
        from: now,
        maximum: 32,
        history: history,
      );
      for (final occurrence in occurrences) {
        for (final reminder in reminders) {
          final leadMinutes = safeJsonInt(
            reminder[PlannerReminderKeys.leadMinutes],
            fallback: 0,
          ).clamp(0, 10080);
          final snoozeMinutes = safeJsonInt(
            reminder[PlannerReminderKeys.snoozeMinutes],
            fallback: 10,
          ).clamp(1, 1440).toInt();
          final snoozeActionId = PlannerReminderSnooze.actionId(snoozeMinutes);
          var alertAt = occurrence.subtract(Duration(minutes: leadMinutes));
          if (reminder[PlannerReminderKeys.respectQuietHours] == true) {
            final deferred = _deferForQuietHours(alertAt, settings);
            if (!deferred.isBefore(occurrence)) {
              skipped++;
              continue;
            }
            alertAt = deferred;
          }
          if (!alertAt.isAfter(now)) {
            skipped++;
            continue;
          }
          final id = _notificationId(
            '${entity.id}:${occurrence.toUtc().toIso8601String()}:$leadMinutes',
          );
          candidates.add(
            _ReminderCandidate(
              id: id,
              entity: entity,
              alertAt: alertAt,
              leadMinutes: leadMinutes,
              snoozeMinutes: snoozeMinutes,
              snoozeActionId: snoozeActionId,
            ),
          );
        }
      }
    }

    candidates.sort((left, right) {
      final byTime = left.alertAt.compareTo(right.alertAt);
      if (byTime != 0) return byTime;
      final byPriority = _priorityRank(
        right.entity,
      ).compareTo(_priorityRank(left.entity));
      if (byPriority != 0) return byPriority;
      final byEntity = left.entity.id.compareTo(right.entity.id);
      if (byEntity != 0) return byEntity;
      return left.id.compareTo(right.id);
    });
    final uniqueCandidates = <_ReminderCandidate>[];
    final candidateIds = <int>{};
    for (final candidate in candidates) {
      if (candidateIds.add(candidate.id)) {
        uniqueCandidates.add(candidate);
      } else {
        skipped++;
      }
    }

    var scheduled = 0;
    var truncated = 0;
    final scheduledIds = <int>{...failedCancellationIds};
    final availableCapacity = (_maxScheduledNotifications - scheduledIds.length)
        .clamp(0, _maxScheduledNotifications)
        .toInt();
    for (var index = 0; index < uniqueCandidates.length; index++) {
      if (scheduled >= availableCapacity) {
        truncated = uniqueCandidates.length - index;
        break;
      }
      final candidate = uniqueCandidates[index];
      try {
        final scheduleOverride = scheduleNotificationOverride;
        if (scheduleOverride != null) {
          await scheduleOverride(
            id: candidate.id,
            payload: 'planner:${candidate.entity.id}',
            alertAt: candidate.alertAt,
          );
        } else {
          await _plugin.zonedSchedule(
            id: candidate.id,
            title: candidate.entity.title,
            body: _reminderBody(candidate.leadMinutes),
            scheduledDate: tz.TZDateTime.from(candidate.alertAt, tz.local),
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'perfect_planner_reminders',
                'Planner reminders',
                channelDescription: 'Private Perfect task and habit reminders',
                icon: 'app_icon',
                importance: Importance.high,
                priority: Priority.high,
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    candidate.snoozeActionId,
                    _snoozeLabel(candidate.snoozeMinutes),
                    showsUserInterface: true,
                  ),
                ],
              ),
              windows: WindowsNotificationDetails(
                duration: WindowsNotificationDuration.long,
                actions: <WindowsAction>[
                  WindowsAction(
                    content: _snoozeLabel(candidate.snoozeMinutes),
                    arguments: candidate.snoozeActionId,
                  ),
                ],
              ),
            ),
            androidScheduleMode: settings.exactTiming
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'planner:${candidate.entity.id}',
          );
        }
        scheduledIds.add(candidate.id);
        scheduled++;
      } on Object {
        failures++;
      }
    }
    await prefs.setStringList(
      _scheduledIdsKey,
      scheduledIds.map((id) => '$id').toList(growable: false),
    );
    return PlannerReminderScheduleSummary(
      scheduled: scheduled,
      skipped: skipped,
      failures: failures,
      truncated: truncated,
      capacity: _maxScheduledNotifications,
    );
  }

  Future<Set<int>> _cancelScheduledIds(Set<int> ids) async {
    final failed = <int>{};
    for (final id in ids) {
      try {
        final cancelOverride = cancelNotificationOverride;
        if (cancelOverride != null) {
          await cancelOverride(id);
        } else {
          await _plugin.cancel(id: id);
        }
      } on Object {
        failed.add(id);
      }
    }
    return failed;
  }

  int _priorityRank(PlannerEntity entity) =>
      switch (safeJsonString(entity.payload['priority'], fallback: 'normal')) {
        'urgent' => 3,
        'high' => 2,
        'low' => 0,
        _ => 1,
      };

  @override
  Future<void> dispose() async {
    _disposed = true;
  }

  Future<void> _initialize() async {
    if (_initialized || _disposed) return;
    if (skipPluginInitialization) {
      _initialized = true;
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } on Object {
      // `tz.local` stays on the library default when an OS-specific identifier
      // is unavailable; UTC conversion below remains deterministic.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('app_icon'),
        windows: WindowsInitializationSettings(
          appName: 'Perfect!',
          appUserModelId: 'com.k1tvkli2003.perfect',
          guid: '108331c7-e6f0-489c-8b2d-bf974da97210',
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          unawaited(_handleNotificationResponse(response)),
    );
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if (response != null) await _handleNotificationResponse(response);
    } on Object {
      // Some unpackaged Windows hosts cannot expose launch details. Live
      // callbacks still work and packaging diagnostics retain the limitation.
    }
    _initialized = true;
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final snoozeMinutes = PlannerReminderSnooze.minutesFromActionId(
      response.actionId,
    );
    if (snoozeMinutes == null) {
      PlannerReminderNavigation.handlePayload(response.payload);
      return;
    }
    final payload = response.payload;
    if (payload == null || !payload.startsWith('planner:')) return;
    try {
      final settings = await readSettings();
      var alertAt = _now().toUtc().add(Duration(minutes: snoozeMinutes));
      alertAt = _deferForQuietHours(alertAt, settings);
      final actionId = PlannerReminderSnooze.actionId(snoozeMinutes);
      await _plugin.zonedSchedule(
        id: _notificationId(
          '$payload:snooze:${alertAt.toIso8601String()}:${response.id ?? 0}',
        ),
        title: 'Perfect! reminder',
        body: 'Snoozed for ${_snoozeDurationLabel(snoozeMinutes)}.',
        scheduledDate: tz.TZDateTime.from(alertAt, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'perfect_planner_reminders',
            'Planner reminders',
            channelDescription: 'Private Perfect task and habit reminders',
            icon: 'app_icon',
            importance: Importance.high,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                actionId,
                _snoozeLabel(snoozeMinutes),
                showsUserInterface: true,
              ),
            ],
          ),
          windows: WindowsNotificationDetails(
            duration: WindowsNotificationDuration.long,
            actions: <WindowsAction>[
              WindowsAction(
                content: _snoozeLabel(snoozeMinutes),
                arguments: actionId,
              ),
            ],
          ),
        ),
        androidScheduleMode: settings.exactTiming
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } on Object {
      // Never swallow the owner's intent when a device cannot reschedule:
      // opening the target is the safe fallback and keeps the task visible.
      PlannerReminderNavigation.handlePayload(payload);
    }
  }

  DateTime _deferForQuietHours(
    DateTime value,
    PlannerReminderSettings settings,
  ) {
    if (!settings.quietHoursEnabled ||
        settings.quietStartMinutes == settings.quietEndMinutes) {
      return value;
    }
    final local = value.toLocal();
    final minute = local.hour * 60 + local.minute;
    final start = settings.quietStartMinutes;
    final end = settings.quietEndMinutes;
    final inside = start < end
        ? minute >= start && minute < end
        : minute >= start || minute < end;
    if (!inside) return value;
    var deferred = DateTime(
      local.year,
      local.month,
      local.day,
      end ~/ 60,
      end % 60,
    );
    if (!deferred.isAfter(local)) {
      deferred = deferred.add(const Duration(days: 1));
    }
    return deferred.toUtc();
  }

  int _notificationId(String seed) {
    var hash = 17;
    for (final codeUnit in seed.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + codeUnit);
    }
    return hash == 0 ? 1 : hash;
  }

  int _boundedMinutes(int value) => value.clamp(0, 1439);
}

class _ReminderCandidate {
  const _ReminderCandidate({
    required this.id,
    required this.entity,
    required this.alertAt,
    required this.leadMinutes,
    required this.snoozeMinutes,
    required this.snoozeActionId,
  });

  final int id;
  final PlannerEntity entity;
  final DateTime alertAt;
  final int leadMinutes;
  final int snoozeMinutes;
  final String snoozeActionId;
}

String _reminderBody(int leadMinutes) => switch (leadMinutes) {
  0 => 'It is time for this in your Perfect plan.',
  1 => 'Starts in 1 minute.',
  _ when leadMinutes < 60 => 'Starts in $leadMinutes minutes.',
  60 => 'Starts in 1 hour.',
  _ => 'Starts in ${leadMinutes ~/ 60} hours.',
};

String _snoozeLabel(int minutes) => minutes < 60
    ? 'Snooze ${minutes}m'
    : minutes % 60 == 0
    ? 'Snooze ${minutes ~/ 60}h'
    : 'Snooze ${minutes ~/ 60}h ${minutes % 60}m';

String _snoozeDurationLabel(int minutes) => minutes < 60
    ? '$minutes ${minutes == 1 ? 'minute' : 'minutes'}'
    : minutes % 60 == 0
    ? '${minutes ~/ 60} ${minutes == 60 ? 'hour' : 'hours'}'
    : '${minutes ~/ 60}h ${minutes % 60}m';
