import 'planner_entity.dart';

enum PlannerOperationType {
  createEntity('create_entity'),
  upsertEntity('upsert_entity'),
  completeEntity('complete_entity'),
  softDeleteEntity('soft_delete_entity'),
  appendOccurrence('append_occurrence'),
  completeOccurrence('complete_occurrence'),
  appendFocusSession('append_focus_session');

  const PlannerOperationType(this.wireValue);

  final String wireValue;

  static PlannerOperationType fromWire(Object? value) =>
      PlannerOperationType.values.firstWhere(
        (operation) => operation.wireValue == value,
        orElse: () => PlannerOperationType.upsertEntity,
      );
}

enum PlannerOperationState {
  pending('pending'),
  retrying('retrying'),
  acknowledged('acknowledged');

  const PlannerOperationState(this.wireValue);

  final String wireValue;

  static PlannerOperationState fromWire(Object? value) =>
      PlannerOperationState.values.firstWhere(
        (state) => state.wireValue == value,
        orElse: () => PlannerOperationState.pending,
      );
}

enum PlannerOperationTarget {
  entity('entity'),
  occurrence('occurrence'),
  focusSession('focus_session');

  const PlannerOperationTarget(this.wireValue);

  final String wireValue;

  static PlannerOperationTarget fromWire(Object? value) =>
      PlannerOperationTarget.values.firstWhere(
        (target) => target.wireValue == value,
        orElse: () => PlannerOperationTarget.entity,
      );
}

/// A JSON field-path patch. Paths are relative to the canonical target JSON;
/// for entities, `/title` refers to `PlannerEntity.payload.title`.
class PlannerFieldPatch {
  PlannerFieldPatch(Map<String, dynamic> values)
    : values = Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.fromEntries(
          values.entries.map((entry) {
            final path = _validateFieldPath(entry.key);
            return MapEntry<String, dynamic>(
              path,
              _canonicalPatchValue(entry.value),
            );
          }),
        ),
      );

  final Map<String, dynamic> values;

  factory PlannerFieldPatch.replacePayload(Map<String, dynamic> payload) =>
      PlannerFieldPatch(<String, dynamic>{
        '/': normalizePlannerPayload(payload),
      });

  bool get isEmpty => values.isEmpty;

  Map<String, dynamic> toJson() => values;

  static String _validateFieldPath(String value) {
    final path = value.trim();
    if (!path.startsWith('/') || path.contains('//')) {
      throw ArgumentError.value(
        value,
        'path',
        'must be an absolute JSON field path',
      );
    }
    return path;
  }
}

class PlannerOutboxOperation {
  const PlannerOutboxOperation({
    required this.localSequence,
    required this.mutationId,
    required this.ownerId,
    required this.target,
    required this.targetId,
    required this.type,
    required this.patch,
    required this.baseRevision,
    required this.createdAt,
    required this.state,
    this.entityId,
    this.entityKind,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
    this.acknowledgedAt,
  });

  final int localSequence;
  final String mutationId;
  final String ownerId;
  final PlannerOperationTarget target;
  final String targetId;
  final String? entityId;
  final PlannerEntityKind? entityKind;
  final PlannerOperationType type;
  final PlannerFieldPatch patch;
  final int baseRevision;
  final DateTime createdAt;
  final PlannerOperationState state;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final DateTime? acknowledgedAt;
}

class PlannerMutationReceipt {
  const PlannerMutationReceipt({
    required this.operation,
    this.entity,
    this.occurrence,
    this.focusSession,
    this.wasDuplicate = false,
  });

  final PlannerOutboxOperation operation;
  final PlannerEntity? entity;
  final PlannerOccurrence? occurrence;
  final PlannerFocusSession? focusSession;
  final bool wasDuplicate;
}

class PlannerOccurrence {
  PlannerOccurrence({
    required this.id,
    required this.ownerId,
    required this.entityId,
    required this.plannedFor,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'pending',
    Map<String, dynamic> value = const <String, dynamic>{},
    this.revision = 0,
    this.completedAt,
    this.missedAt,
    this.serverUpdatedAt,
    this.deletedAt,
  }) : value = safeJsonMap(value);

  final String id;
  final String ownerId;
  final String entityId;
  final DateTime plannedFor;
  final String status;
  final Map<String, dynamic> value;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? missedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  PlannerOccurrence copyWith({
    String? status,
    Map<String, dynamic>? value,
    int? revision,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? missedAt,
    DateTime? serverUpdatedAt,
    DateTime? deletedAt,
    bool clearCompletedAt = false,
    bool clearMissedAt = false,
    bool clearDeletedAt = false,
  }) => PlannerOccurrence(
    id: id,
    ownerId: ownerId,
    entityId: entityId,
    plannedFor: plannedFor,
    status: status ?? this.status,
    value: value ?? this.value,
    revision: revision ?? this.revision,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    missedAt: clearMissedAt ? null : missedAt ?? this.missedAt,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'owner_id': ownerId,
    'entity_id': entityId,
    'planned_for': plannedFor.toUtc().toIso8601String(),
    'status': status,
    'value': value,
    'revision': revision,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'missed_at': missedAt?.toUtc().toIso8601String(),
    'server_updated_at': serverUpdatedAt?.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

class PlannerFocusSession {
  PlannerFocusSession({
    required this.id,
    required this.ownerId,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
    this.entityId,
    this.mode = 'stopwatch',
    this.status = 'active',
    Map<String, dynamic> payload = const <String, dynamic>{},
    this.revision = 0,
    this.endedAt,
    this.serverUpdatedAt,
    this.deletedAt,
  }) : payload = safeJsonMap(payload);

  final String id;
  final String ownerId;
  final String? entityId;
  final String mode;
  final String status;
  final Map<String, dynamic> payload;
  final int revision;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  PlannerFocusSession copyWith({
    String? entityId,
    bool clearEntityId = false,
    String? mode,
    String? status,
    Map<String, dynamic>? payload,
    int? revision,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
    DateTime? deletedAt,
    bool clearEndedAt = false,
    bool clearDeletedAt = false,
  }) => PlannerFocusSession(
    id: id,
    ownerId: ownerId,
    entityId: clearEntityId ? null : entityId ?? this.entityId,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    revision: revision ?? this.revision,
    startedAt: startedAt ?? this.startedAt,
    endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'owner_id': ownerId,
    'entity_id': entityId,
    'mode': mode,
    'status': status,
    'payload': payload,
    'revision': revision,
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'server_updated_at': serverUpdatedAt?.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

class PlannerSyncConflict {
  PlannerSyncConflict({
    required this.id,
    required this.ownerId,
    required this.targetType,
    required this.targetId,
    required List<String> fieldPaths,
    required Map<String, dynamic> localValue,
    required Map<String, dynamic> remoteValue,
    required this.createdAt,
    this.mutationId,
    this.baseRevision,
    this.remoteRevision,
    this.status = 'open',
    this.resolvedAt,
  }) : fieldPaths = List<String>.unmodifiable(fieldPaths),
       localValue = safeJsonMap(localValue),
       remoteValue = safeJsonMap(remoteValue);

  final String id;
  final String ownerId;
  final PlannerOperationTarget targetType;
  final String targetId;
  final String? mutationId;
  final List<String> fieldPaths;
  final Map<String, dynamic> localValue;
  final Map<String, dynamic> remoteValue;
  final int? baseRevision;
  final int? remoteRevision;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
}

dynamic _canonicalPatchValue(Object? value) {
  if (value is Map) return safeJsonMap(value);
  if (value is Iterable && value is! String) {
    return List<dynamic>.unmodifiable(value.map(_canonicalPatchValue));
  }
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is num && !value.isFinite) return null;
  if (value == null || value is String || value is bool || value is num) {
    return value;
  }
  return value.toString();
}
