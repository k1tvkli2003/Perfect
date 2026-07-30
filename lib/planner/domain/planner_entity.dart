import 'dart:convert';

/// The stable kinds understood by Perfect's planner. New planner capabilities
/// should be expressed in [PlannerEntity.payload] before introducing a new
/// top-level kind, so that sync stays generic and forward compatible.
enum PlannerEntityKind {
  oneOffTask('one_off_task'),
  recurringTask('recurring_task'),
  habit('habit'),
  project('project'),
  area('area');

  const PlannerEntityKind(this.wireValue);

  final String wireValue;

  static PlannerEntityKind fromWire(Object? value) =>
      PlannerEntityKind.values.firstWhere(
        (kind) => kind.wireValue == value,
        orElse: () => PlannerEntityKind.oneOffTask,
      );
}

enum PlannerEntityStatus {
  active('active'),
  completed('completed'),
  archived('archived'),
  cancelled('cancelled');

  const PlannerEntityStatus(this.wireValue);

  final String wireValue;

  static PlannerEntityStatus fromWire(Object? value) =>
      PlannerEntityStatus.values.firstWhere(
        (status) => status.wireValue == value,
        orElse: () => PlannerEntityStatus.active,
      );
}

/// Canonical JSON field names shared by local storage and the future sync RPC.
///
/// The payload deliberately owns planner-specific data. Database columns only
/// contain identity, ownership, lifecycle, and server revision facts.
abstract final class PlannerPayloadKeys {
  static const title = 'title';
  static const note = 'note';
  static const status = 'status';
  static const timing = 'timing';
  static const recurrence = 'recurrence';
  static const tracking = 'tracking';
  static const recovery = 'recovery';
  static const properties = 'properties';
  static const relations = 'relations';

  /// Canonical task outcome for the four-state completion control. This is
  /// deliberately separate from lifecycle (archive/cancel) and from a habit
  /// measurement, so an incomplete task can still remain editable and visible.
  static const taskProgressState = 'task_progress_state';
  static const taskProgressPercent = 'task_progress_percent';
}

/// Stable payload keys for the planner options shared by the editor, Today
/// projection, and sync clients.
///
/// These fields intentionally remain inside the generic payload. Older clients
/// preserve them even when they do not render the newer controls.
abstract final class PlannerTaskMetadataKeys {
  static const labels = 'labels';
  static const estimateMinutes = 'estimate_minutes';
  static const energy = 'energy';
  static const icon = 'icon';
  static const color = 'color';
  static const timeBlockEndAt = 'end_at';
}

/// Stable keys for a task-linked focus preset.
abstract final class PlannerFocusPresetKeys {
  static const enabled = 'enabled';
  static const mode = 'mode';
  static const minutes = 'minutes';
  static const breakPolicy = 'break_policy';
  static const shortBreakMinutes = 'short_break_minutes';
  static const longBreakMinutes = 'long_break_minutes';
  static const longBreakAfterCycles = 'long_break_after_cycles';
}

abstract final class PlannerReminderKeys {
  static const enabled = 'enabled';
  static const leadMinutes = 'lead_minutes';
  static const snoozeMinutes = 'snooze_minutes';
  static const respectQuietHours = 'respect_quiet_hours';
}

/// Backward-compatible keys for the advanced recurrence JSON contract.
///
/// Existing `rule`/`interval`/`weekdays` payloads remain valid. The additional
/// keys cover multiple calendar dates and flexible "N times per period" rules
/// without requiring a storage migration.
abstract final class PlannerRecurrenceKeys {
  static const rule = 'rule';
  static const interval = 'interval';
  static const weekdays = 'weekdays';
  static const monthDays = 'month_days';
  static const lastDayOfMonth = 'last_day_of_month';
  static const annualDates = 'annual_dates';
  static const frequency = 'frequency';
  static const frequencyCount = 'count';
  static const frequencyPeriod = 'period';
  static const exceptions = 'exceptions';
  static const endAt = 'end_at';
  static const occurrenceLimit = 'occurrence_limit';
  static const paused = 'paused';
}

/// Keys for habits whose outcome is computed from a checklist.
abstract final class PlannerHabitTrackingKeys {
  static const method = 'method';
  static const checklist = 'checklist';
  static const itemId = 'id';
  static const itemRequired = 'required';
  static const itemChecked = 'checked';
  static const successCondition = 'success_condition';
  static const successType = 'type';
  static const successValue = 'value';
}

abstract final class PlannerRecoveryKeys {
  static const onMiss = 'on_miss';
  static const carryCap = 'carry_cap';
  static const carryCount = 'carry_count';
  static const resolution = 'resolution';
  static const disposition = 'disposition';
  static const resolvedFor = 'resolved_for';
  static const resolvedAt = 'resolved_at';
}

/// A generic, owner-scoped planner record.
///
/// [revision], [serverCreatedAt], and [serverUpdatedAt] are server authority
/// placeholders. Local writes must never advance [revision] themselves.
class PlannerEntity {
  PlannerEntity({
    required this.id,
    required this.ownerId,
    required this.kind,
    required Map<String, dynamic> payload,
    required this.createdAt,
    required this.updatedAt,
    this.revision = 0,
    this.serverCreatedAt,
    this.serverUpdatedAt,
    this.deletedAt,
  }) : payload = normalizePlannerPayload(payload);

  final String id;
  final String ownerId;
  final PlannerEntityKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final DateTime? serverCreatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  String get title =>
      safeJsonString(payload[PlannerPayloadKeys.title], fallback: 'Untitled');

  String? get note => safeNullableJsonString(payload[PlannerPayloadKeys.note]);

  PlannerEntityStatus get status =>
      PlannerEntityStatus.fromWire(payload[PlannerPayloadKeys.status]);

  Map<String, dynamic> get timing =>
      safeJsonMap(payload[PlannerPayloadKeys.timing]);

  Map<String, dynamic> get recurrence =>
      safeJsonMap(payload[PlannerPayloadKeys.recurrence]);

  Map<String, dynamic> get tracking =>
      safeJsonMap(payload[PlannerPayloadKeys.tracking]);

  Map<String, dynamic> get recovery =>
      safeJsonMap(payload[PlannerPayloadKeys.recovery]);

  Map<String, dynamic> get customProperties =>
      safeJsonMap(payload[PlannerPayloadKeys.properties]);

  List<Map<String, dynamic>> get relations =>
      safeJsonMapList(payload[PlannerPayloadKeys.relations]);

  DateTime? get scheduledAt => safeJsonDateTime(timing['scheduled_at']);

  DateTime? get dueAt => safeJsonDateTime(timing['due_at']);

  PlannerEntity copyWith({
    PlannerEntityKind? kind,
    Map<String, dynamic>? payload,
    DateTime? updatedAt,
    int? revision,
    DateTime? serverCreatedAt,
    DateTime? serverUpdatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => PlannerEntity(
    id: id,
    ownerId: ownerId,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
    serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'owner_id': ownerId,
    'kind': kind.wireValue,
    'payload': payload,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'revision': revision,
    'server_created_at': serverCreatedAt?.toUtc().toIso8601String(),
    'server_updated_at': serverUpdatedAt?.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  factory PlannerEntity.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    final id = safeJsonString(json['id'], fallback: 'invalid-entity');
    final ownerId = safeJsonString(json['owner_id'], fallback: 'unknown-owner');
    final createdAt = safeJsonDateTime(json['created_at']) ?? now;
    return PlannerEntity(
      id: id,
      ownerId: ownerId,
      kind: PlannerEntityKind.fromWire(json['kind']),
      payload: safeJsonMap(json['payload']),
      createdAt: createdAt,
      updatedAt: safeJsonDateTime(json['updated_at']) ?? createdAt,
      revision: safeJsonInt(json['revision'], fallback: 0).clamp(0, 1 << 53),
      serverCreatedAt: safeJsonDateTime(json['server_created_at']),
      serverUpdatedAt: safeJsonDateTime(json['server_updated_at']),
      deletedAt: safeJsonDateTime(json['deleted_at']),
    );
  }
}

Map<String, dynamic> defaultPlannerPayload({required String title}) =>
    normalizePlannerPayload(<String, dynamic>{PlannerPayloadKeys.title: title});

/// Converts arbitrary decoded JSON into a predictable, JSON-safe payload while
/// preserving unknown fields for forward compatibility.
Map<String, dynamic> normalizePlannerPayload(Map<String, dynamic> source) {
  final canonical = safeJsonMap(source);
  final result = <String, dynamic>{
    PlannerPayloadKeys.title: safeJsonString(
      canonical[PlannerPayloadKeys.title],
      fallback: 'Untitled',
    ),
    PlannerPayloadKeys.note:
        safeNullableJsonString(canonical[PlannerPayloadKeys.note]) ?? '',
    PlannerPayloadKeys.status: PlannerEntityStatus.fromWire(
      canonical[PlannerPayloadKeys.status],
    ).wireValue,
    PlannerPayloadKeys.timing: safeJsonMap(
      canonical[PlannerPayloadKeys.timing],
    ),
    PlannerPayloadKeys.recurrence: safeJsonMap(
      canonical[PlannerPayloadKeys.recurrence],
    ),
    PlannerPayloadKeys.tracking: safeJsonMap(
      canonical[PlannerPayloadKeys.tracking],
    ),
    PlannerPayloadKeys.recovery: safeJsonMap(
      canonical[PlannerPayloadKeys.recovery],
    ),
    PlannerPayloadKeys.properties: safeJsonMap(
      canonical[PlannerPayloadKeys.properties],
    ),
    PlannerPayloadKeys.relations: safeJsonMapList(
      canonical[PlannerPayloadKeys.relations],
    ),
    ...canonical,
  };

  result[PlannerPayloadKeys.title] = safeJsonString(
    result[PlannerPayloadKeys.title],
    fallback: 'Untitled',
  );
  result[PlannerPayloadKeys.note] =
      safeNullableJsonString(result[PlannerPayloadKeys.note]) ?? '';
  result[PlannerPayloadKeys.status] = PlannerEntityStatus.fromWire(
    result[PlannerPayloadKeys.status],
  ).wireValue;
  result[PlannerPayloadKeys.timing] = safeJsonMap(
    result[PlannerPayloadKeys.timing],
  );
  result[PlannerPayloadKeys.recurrence] = safeJsonMap(
    result[PlannerPayloadKeys.recurrence],
  );
  result[PlannerPayloadKeys.tracking] = safeJsonMap(
    result[PlannerPayloadKeys.tracking],
  );
  result[PlannerPayloadKeys.recovery] = safeJsonMap(
    result[PlannerPayloadKeys.recovery],
  );
  result[PlannerPayloadKeys.properties] = safeJsonMap(
    result[PlannerPayloadKeys.properties],
  );
  result[PlannerPayloadKeys.relations] = safeJsonMapList(
    result[PlannerPayloadKeys.relations],
  );
  return Map<String, dynamic>.unmodifiable(result);
}

Map<String, dynamic> safeJsonMap(Object? value) {
  if (value is String) {
    try {
      return safeJsonMap(jsonDecode(value));
    } on FormatException {
      return const <String, dynamic>{};
    }
  }
  if (value is! Map) return const <String, dynamic>{};

  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    final key = entry.key?.toString().trim();
    if (key == null || key.isEmpty) continue;
    result[key] = _canonicalJsonValue(entry.value);
  }
  return Map<String, dynamic>.unmodifiable(result);
}

List<Map<String, dynamic>> safeJsonMapList(Object? value) {
  if (value is! Iterable) return const <Map<String, dynamic>>[];
  return List<Map<String, dynamic>>.unmodifiable(
    value.map(safeJsonMap).where((entry) => entry.isNotEmpty),
  );
}

String safeJsonString(Object? value, {required String fallback}) {
  if (value is! String) return fallback;
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String? safeNullableJsonString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int safeJsonInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? safeJsonDateTime(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toUtc();
}

dynamic _canonicalJsonValue(Object? value) {
  if (value == null || value is String || value is bool) return value;
  if (value is num) return value.isFinite ? value : null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Map) return safeJsonMap(value);
  if (value is Iterable) {
    return List<dynamic>.unmodifiable(value.map(_canonicalJsonValue));
  }
  return value.toString();
}
