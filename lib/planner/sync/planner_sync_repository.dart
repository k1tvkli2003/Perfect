import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:perfect/app/personal_items_store.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

typedef PlannerSyncRetryTimerFactory =
    Timer Function(Duration delay, void Function() callback);

Timer _createPlannerSyncRetryTimer(Duration delay, void Function() callback) =>
    Timer(delay, callback);

/// UI-visible state for an asynchronous, local-first sync attempt. A page
/// reads its projection from Drift and never waits on this state to render.
enum PlannerSyncPhase { idle, syncing, offline, needsAttention }

class PlannerSyncStatus {
  const PlannerSyncStatus({
    required this.phase,
    this.message,
    this.lastSuccessfulSyncAt,
    this.nextRetryAt,
    this.retryAttempt = 0,
  });

  const PlannerSyncStatus.idle({DateTime? lastSuccessfulSyncAt})
    : this(
        phase: PlannerSyncPhase.idle,
        lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      );

  final PlannerSyncPhase phase;
  final String? message;
  final DateTime? lastSuccessfulSyncAt;

  /// Absolute UTC deadline for the repository's already-scheduled retry.
  final DateTime? nextRetryAt;
  final int retryAttempt;

  PlannerSyncStatus copyWith({
    PlannerSyncPhase? phase,
    String? message,
    DateTime? lastSuccessfulSyncAt,
    DateTime? nextRetryAt,
    int? retryAttempt,
    bool clearNextRetryAt = false,
  }) => PlannerSyncStatus(
    phase: phase ?? this.phase,
    message: message ?? this.message,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    nextRetryAt: clearNextRetryAt ? null : nextRetryAt ?? this.nextRetryAt,
    retryAttempt: retryAttempt ?? this.retryAttempt,
  );
}

/// An installation-specific UUID, deliberately independent of the private
/// account. The server records it only for idempotency/audit context.
class PlannerDeviceIdentity {
  const PlannerDeviceIdentity({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const _preferenceKey = 'perfect.planner.device_id.v2';

  final Uuid _uuid;

  Future<String> readOrCreate() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_preferenceKey)?.trim();
    if (existing != null && Uuid.isValidUUID(fromString: existing)) {
      return existing;
    }
    final created = _uuid.v4();
    await preferences.setString(_preferenceKey, created);
    return created;
  }
}

abstract interface class PlannerRemoteGateway {
  Future<PlannerRemoteMutationResult> apply(PlannerRemoteMutation mutation);

  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  });

  Future<List<Map<String, dynamic>>> readLegacyItems();

  Future<void> subscribe(void Function() onChangeHint);

  Future<void> dispose();
}

/// The Supabase adapter intentionally accesses v2 writes through RPC only.
/// `perfect_items` is read solely for one-time legacy projection.
class SupabasePlannerRemoteGateway implements PlannerRemoteGateway {
  SupabasePlannerRemoteGateway(this._client, {required this.ownerId});

  final SupabaseClient _client;
  final String ownerId;
  RealtimeChannel? _channel;

  @override
  Future<PlannerRemoteMutationResult> apply(
    PlannerRemoteMutation mutation,
  ) async {
    final raw = await _client.rpc(
      'apply_planner_mutation',
      params: mutation.toRpcParameters(),
    );
    return PlannerRemoteMutationResult.fromJson(safeJsonMap(raw));
  }

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async {
    final raw = await _client.rpc(
      'pull_planner_changes',
      params: <String, dynamic>{
        'p_after_change_id': afterChangeId,
        'p_limit': limit,
      },
    );
    final rows = raw is Iterable
        ? raw
              .map(safeJsonMap)
              .where((entry) => entry.isNotEmpty)
              .map(PlannerRemoteChange.fromJson)
              .toList(growable: false)
        : const <PlannerRemoteChange>[];
    return PlannerRemoteChangePage(changes: rows, requestedLimit: limit);
  }

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() async {
    final raw = await _client
        .from('perfect_items')
        .select('id,title,is_done,created_at,updated_at,deleted_at')
        .eq('owner_id', ownerId)
        .order('updated_at');
    return raw
        .map(safeJsonMap)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> subscribe(void Function() onChangeHint) async {
    if (_channel != null) return;
    _channel = _client
        .channel('perfect-planner-changes-$ownerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'planner_changes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: ownerId,
          ),
          callback: (_) => onChangeHint(),
        )
        .subscribe();
  }

  @override
  Future<void> dispose() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await _client.removeChannel(channel);
  }
}

class PlannerSyncRepository {
  PlannerSyncRepository(
    this._localStore,
    this._remote, {
    required this.ownerId,
    required this.deviceId,
    PersonalItemsStore? legacyStore,
    Duration retryBaseDelay = const Duration(seconds: 5),
    Duration retryMaxDelay = const Duration(minutes: 5),
    PlannerSyncRetryTimerFactory? retryTimerFactory,
    this.now = DateTime.now,
  }) : _legacyStore = legacyStore ?? PersonalItemsStore(),
       _retryBaseDelay = retryBaseDelay,
       _retryMaxDelay = retryMaxDelay,
       _retryTimerFactory = retryTimerFactory ?? _createPlannerSyncRetryTimer {
    if (retryBaseDelay <= Duration.zero || retryMaxDelay < retryBaseDelay) {
      throw ArgumentError(
        'Sync retry delays must be positive and max must not be below base.',
      );
    }
  }

  static const _pullPageSize = 200;

  final PlannerLocalStore _localStore;
  final PlannerRemoteGateway _remote;
  final PersonalItemsStore _legacyStore;
  final Duration _retryBaseDelay;
  final Duration _retryMaxDelay;
  final PlannerSyncRetryTimerFactory _retryTimerFactory;
  final DateTime Function() now;
  final String ownerId;
  final String deviceId;
  final ValueNotifier<PlannerSyncStatus> syncStatus =
      ValueNotifier<PlannerSyncStatus>(const PlannerSyncStatus.idle());

  Future<void>? _activeSync;
  Timer? _retryTimer;
  bool _syncRequested = false;
  int _consecutiveFailureCount = 0;
  bool _started = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    await _importLocalLegacy();
    await _remote.subscribe(() {
      if (!_disposed) unawaited(syncNow());
    });
    unawaited(syncNow());
  }

  Future<void> syncNow() {
    if (_disposed) return Future<void>.value();
    _retryTimer?.cancel();
    _retryTimer = null;
    _syncRequested = true;
    final active = _activeSync;
    if (active != null) return active;
    final sync = _drainSyncRequests();
    _activeSync = sync;
    unawaited(
      sync.whenComplete(() {
        if (identical(_activeSync, sync)) {
          _activeSync = null;
          // Close the tiny race between the drain's final condition check and
          // clearing its active future.
          if (_syncRequested && !_disposed) unawaited(syncNow());
        }
      }),
    );
    return sync;
  }

  Future<void> _drainSyncRequests() async {
    while (_syncRequested && !_disposed) {
      _syncRequested = false;
      await _synchronize();
    }
  }

  Future<void> _synchronize() async {
    if (_disposed) return;
    syncStatus.value = PlannerSyncStatus(
      phase: PlannerSyncPhase.syncing,
      lastSuccessfulSyncAt: syncStatus.value.lastSuccessfulSyncAt,
      retryAttempt: _consecutiveFailureCount,
    );
    try {
      await _importRemoteLegacy();
      await _pullAllChanges();
      await _pushPendingOperations();
      await _pullAllChanges();
      if (_disposed) return;
      final metadata = await _localStore.markSyncSuccess(ownerId: ownerId);
      _consecutiveFailureCount = 0;
      _retryTimer?.cancel();
      _retryTimer = null;
      syncStatus.value = PlannerSyncStatus.idle(
        lastSuccessfulSyncAt: metadata.lastSuccessfulSyncAt,
      );
    } on Object catch (error) {
      if (_disposed) return;
      final summary = _syncErrorSummary(error);
      await _localStore.markSyncFailure(ownerId: ownerId, error: summary);
      final connectivityFailure = _isConnectivityError(error);
      syncStatus.value = PlannerSyncStatus(
        phase: connectivityFailure
            ? PlannerSyncPhase.offline
            : PlannerSyncPhase.needsAttention,
        message: summary,
        lastSuccessfulSyncAt: syncStatus.value.lastSuccessfulSyncAt,
        retryAttempt: _consecutiveFailureCount + 1,
      );
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_disposed || _retryTimer?.isActive == true) return;
    _consecutiveFailureCount++;
    final exponent = (_consecutiveFailureCount - 1).clamp(0, 20).toInt();
    final multiplier = 1 << exponent;
    final calculated = _retryBaseDelay * multiplier;
    final delay = calculated > _retryMaxDelay ? _retryMaxDelay : calculated;
    syncStatus.value = syncStatus.value.copyWith(
      nextRetryAt: now().toUtc().add(delay),
      retryAttempt: _consecutiveFailureCount,
    );
    _retryTimer = _retryTimerFactory(delay, () {
      _retryTimer = null;
      if (!_disposed) unawaited(syncNow());
    });
  }

  Future<void> _importLocalLegacy() async {
    final raw = await _legacyStore.readRaw(ownerId);
    if (raw == null || raw.trim().isEmpty) return;
    await _localStore.bootstrap(ownerId: ownerId, legacyPersonalItemsJson: raw);
  }

  Future<void> _importRemoteLegacy() async {
    final items = await _remote.readLegacyItems();
    if (items.isEmpty) return;
    await _localStore.importLegacyPersonalItems(
      ownerId: ownerId,
      rawLegacyJson: jsonEncode(items),
      source: PlannerLocalStore.legacyRemoteV1Source,
    );
  }

  Future<void> _pullAllChanges() async {
    final metadata = await _localStore.readSyncMetadata(ownerId);
    var cursor = int.tryParse(metadata?.remoteCursor ?? '') ?? 0;
    while (true) {
      final page = await _remote.pull(
        afterChangeId: cursor,
        limit: _pullPageSize,
      );
      for (final change in page.changes) {
        if (change.changeId <= cursor) {
          throw const FormatException(
            'Remote planner changes must have a strictly increasing cursor.',
          );
        }
        if (change.snapshot.isEmpty) {
          throw const FormatException(
            'Remote planner change has no entity snapshot.',
          );
        }
        await _applyRemoteSnapshot(change.snapshot);
        cursor = change.changeId;
      }
      await _localStore.updateRemoteCursor(
        ownerId: ownerId,
        cursor: cursor == 0 ? null : '$cursor',
      );
      if (!page.hasMore) return;
    }
  }

  Future<void> _pushPendingOperations() async {
    while (true) {
      // Re-read after every acknowledgement. A successful predecessor rebases
      // later operations in Drift, so retaining a previously loaded batch
      // would send their stale base revision and conflict with our own write.
      final pending = await _localStore.listPendingOperations(
        ownerId,
        limit: 1,
      );
      if (pending.isEmpty) return;
      await _pushOperation(pending.single);
    }
  }

  Future<void> _pushOperation(PlannerOutboxOperation operation) async {
    if (operation.ownerId != ownerId) {
      throw StateError('The outbox operation belongs to another owner.');
    }
    final mutation = await _mutationForOperation(operation);
    try {
      final result = await _remote.apply(mutation);
      final projection = result.entity == null
          ? null
          : _projectionFromSnapshot(result.entity!, ownerId: ownerId);
      if (result.isConflict) {
        if (projection == null) {
          throw StateError('A conflict response did not include its snapshot.');
        }
        await _localStore.recordConflict(
          PlannerSyncConflict(
            id: result.conflictId ?? operation.mutationId,
            ownerId: ownerId,
            targetType: operation.target,
            targetId: operation.targetId,
            mutationId: operation.mutationId,
            fieldPaths: result.conflictingPaths,
            localValue: operation.patch.toJson(),
            remoteValue: result.entity!,
            baseRevision: operation.baseRevision,
            remoteRevision: result.currentRevision,
            createdAt: DateTime.now().toUtc(),
          ),
        );
        await _localStore.markOperationAcknowledged(
          ownerId: ownerId,
          mutationId: operation.mutationId,
        );
        // A true conflict must not silently rebase later local writes. Keeping
        // their stale base revision guarantees the next RPC also conflicts
        // until the owner explicitly resolves the divergent field history.
        await _applyProjection(projection, preservePendingLocal: true);
        return;
      }
      if (!result.isAcknowledged || projection == null) {
        throw StateError('Unexpected planner mutation response.');
      }
      await _localStore.markOperationAcknowledged(
        ownerId: ownerId,
        mutationId: operation.mutationId,
      );
      await _rebaseAndApply(operation: operation, projection: projection);
    } on Object catch (error) {
      await _localStore.markOperationRetry(
        ownerId: ownerId,
        mutationId: operation.mutationId,
        error: _syncErrorSummary(error),
      );
      rethrow;
    }
  }

  Future<void> _rebaseAndApply({
    required PlannerOutboxOperation operation,
    required _RemoteProjection projection,
  }) async {
    final rebased = await _localStore.rebasePendingOperationsForTarget(
      ownerId: ownerId,
      target: operation.target,
      targetId: operation.targetId,
      baseRevision: projection.revision,
      afterSequence: operation.localSequence,
    );
    if (rebased == 0) {
      await _applyProjection(projection, preservePendingLocal: false);
    }
  }

  Future<void> _applyRemoteSnapshot(Map<String, dynamic> snapshot) async {
    final projection = _projectionFromSnapshot(snapshot, ownerId: ownerId);
    await _applyProjection(projection, preservePendingLocal: true);
  }

  Future<void> _applyProjection(
    _RemoteProjection projection, {
    required bool preservePendingLocal,
  }) => switch (projection.target) {
    PlannerOperationTarget.entity => _localStore.applyRemoteEntity(
      projection.entity!,
      preservePendingLocal: preservePendingLocal,
    ),
    PlannerOperationTarget.occurrence => _localStore.applyRemoteOccurrence(
      projection.occurrence!,
      preservePendingLocal: preservePendingLocal,
    ),
    PlannerOperationTarget.focusSession => _localStore.applyRemoteFocusSession(
      projection.focusSession!,
      preservePendingLocal: preservePendingLocal,
    ),
  };

  Future<PlannerRemoteMutation> _mutationForOperation(
    PlannerOutboxOperation operation,
  ) async {
    if (operation.target == PlannerOperationTarget.entity) {
      final entity = await _localStore.readEntity(
        ownerId: ownerId,
        entityId: operation.targetId,
        includeDeleted: true,
      );
      if (entity == null) {
        throw StateError(
          'The local entity for an outbox operation is missing.',
        );
      }
      return PlannerRemoteMutation(
        mutationId: operation.mutationId,
        deviceId: deviceId,
        entityId: entity.id,
        entityKind: entity.kind.wireValue,
        baseRevision: operation.baseRevision,
        operationType: _remoteOperationType(operation),
        fieldPaths: operation.patch.values.keys.toList(growable: false),
        patch: _entityPatch(entity, operation),
      );
    }
    if (operation.target == PlannerOperationTarget.occurrence) {
      final occurrence = await _localStore.readOccurrence(
        ownerId: ownerId,
        occurrenceId: operation.targetId,
        includeDeleted: true,
      );
      if (occurrence == null) {
        throw StateError(
          'The local occurrence for an outbox operation is missing.',
        );
      }
      return PlannerRemoteMutation(
        mutationId: operation.mutationId,
        deviceId: deviceId,
        entityId: occurrence.id,
        entityKind: 'occurrence',
        baseRevision: operation.baseRevision,
        operationType: _remoteOperationType(operation),
        fieldPaths: operation.patch.values.keys.toList(growable: false),
        patch: <String, dynamic>{
          'payload': _payloadPatch(
            patch: operation.patch,
            source: _occurrencePayload(occurrence),
          ),
        },
      );
    }
    final session = await _localStore.readFocusSession(
      ownerId: ownerId,
      sessionId: operation.targetId,
      includeDeleted: true,
    );
    if (session == null) {
      throw StateError(
        'The local focus session for an outbox operation is missing.',
      );
    }
    return PlannerRemoteMutation(
      mutationId: operation.mutationId,
      deviceId: deviceId,
      entityId: session.id,
      entityKind: 'focus_session',
      baseRevision: operation.baseRevision,
      operationType: _remoteOperationType(operation),
      fieldPaths: operation.patch.values.keys.toList(growable: false),
      patch: <String, dynamic>{
        'payload': _payloadPatch(
          patch: operation.patch,
          source: _focusSessionPayload(session),
        ),
      },
    );
  }

  Map<String, dynamic> _entityPatch(
    PlannerEntity entity,
    PlannerOutboxOperation operation,
  ) {
    if (operation.type == PlannerOperationType.softDeleteEntity) {
      return const <String, dynamic>{};
    }
    final payloadPatch = _payloadPatch(
      patch: operation.patch,
      source: entity.payload,
    );
    final patch = <String, dynamic>{'payload': payloadPatch};
    final paths = operation.patch.values.keys.toSet();
    final isFullReplace = paths.contains('/');
    if (isFullReplace || paths.contains('/title')) {
      patch['title'] = safeJsonString(
        payloadPatch[PlannerPayloadKeys.title],
        fallback: entity.title,
      );
    }
    if (isFullReplace || paths.contains('/status')) {
      patch['lifecycle_state'] = _lifecycleFor(
        PlannerEntityStatus.fromWire(payloadPatch[PlannerPayloadKeys.status]),
      );
    }
    return patch;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _syncRequested = false;
    final active = _activeSync;
    if (active != null) await active;
    await _remote.dispose();
    syncStatus.dispose();
  }
}

class PlannerRemoteMutation {
  const PlannerRemoteMutation({
    required this.mutationId,
    required this.deviceId,
    required this.entityId,
    required this.entityKind,
    required this.baseRevision,
    required this.operationType,
    required this.fieldPaths,
    required this.patch,
  });

  final String mutationId;
  final String deviceId;
  final String entityId;
  final String entityKind;
  final int baseRevision;
  final String operationType;
  final List<String> fieldPaths;
  final Map<String, dynamic> patch;

  Map<String, dynamic> toRpcParameters() => <String, dynamic>{
    'p_mutation_id': mutationId,
    'p_device_id': deviceId,
    'p_entity_id': entityId,
    'p_entity_kind': entityKind,
    'p_base_revision': baseRevision,
    'p_operation_type': operationType,
    'p_field_paths': fieldPaths,
    'p_patch': patch,
  };
}

class PlannerRemoteMutationResult {
  PlannerRemoteMutationResult({
    required this.status,
    this.entity,
    this.conflictId,
    this.currentRevision,
    List<String>? conflictingPaths,
  }) : conflictingPaths = List<String>.unmodifiable(
         conflictingPaths ?? const [],
       );

  final String status;
  final Map<String, dynamic>? entity;
  final String? conflictId;
  final int? currentRevision;
  final List<String> conflictingPaths;

  bool get isAcknowledged => status == 'acknowledged';
  bool get isConflict => status == 'conflict';

  factory PlannerRemoteMutationResult.fromJson(Map<String, dynamic> json) {
    final paths = json['conflicting_paths'];
    return PlannerRemoteMutationResult(
      status: safeJsonString(json['status'], fallback: 'invalid'),
      entity: json['entity'] is Map ? safeJsonMap(json['entity']) : null,
      conflictId: safeNullableJsonString(json['conflict_id']),
      currentRevision: json['current_revision'] == null
          ? null
          : safeJsonInt(json['current_revision'], fallback: 0),
      conflictingPaths: paths is Iterable
          ? paths
                .whereType<String>()
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }
}

class PlannerRemoteChange {
  PlannerRemoteChange({required this.changeId, required this.snapshot});

  final int changeId;
  final Map<String, dynamic> snapshot;

  factory PlannerRemoteChange.fromJson(Map<String, dynamic> json) =>
      PlannerRemoteChange(
        changeId: safeJsonInt(json['change_id'], fallback: 0),
        snapshot: safeJsonMap(json['snapshot']),
      );
}

class PlannerRemoteChangePage {
  const PlannerRemoteChangePage({
    required this.changes,
    required this.requestedLimit,
  });

  final List<PlannerRemoteChange> changes;
  final int requestedLimit;

  bool get hasMore => changes.length >= requestedLimit;
}

class _RemoteProjection {
  const _RemoteProjection.entity(this.entity)
    : target = PlannerOperationTarget.entity,
      occurrence = null,
      focusSession = null;

  const _RemoteProjection.occurrence(this.occurrence)
    : target = PlannerOperationTarget.occurrence,
      entity = null,
      focusSession = null;

  const _RemoteProjection.focusSession(this.focusSession)
    : target = PlannerOperationTarget.focusSession,
      entity = null,
      occurrence = null;

  final PlannerOperationTarget target;
  final PlannerEntity? entity;
  final PlannerOccurrence? occurrence;
  final PlannerFocusSession? focusSession;

  int get revision =>
      entity?.revision ?? occurrence?.revision ?? focusSession?.revision ?? 0;
}

_RemoteProjection _projectionFromSnapshot(
  Map<String, dynamic> snapshot, {
  required String ownerId,
}) {
  final kind = safeNullableJsonString(snapshot['kind']);
  if (kind == null) {
    throw const FormatException('Remote planner snapshot has no kind.');
  }
  final id = safeJsonString(snapshot['id'], fallback: '');
  if (id.isEmpty) {
    throw const FormatException('Remote planner snapshot has no id.');
  }
  final resolvedOwner = safeNullableJsonString(snapshot['owner_id']);
  if (resolvedOwner == null) {
    throw const FormatException('Remote planner snapshot has no owner.');
  }
  if (resolvedOwner != ownerId) {
    throw const FormatException(
      'Remote planner snapshot belongs to another owner.',
    );
  }
  final payload = safeJsonMap(snapshot['payload']);
  final revision = safeJsonInt(snapshot['revision'], fallback: 0);
  if (revision < 1) {
    throw const FormatException(
      'Remote planner snapshot has an invalid revision.',
    );
  }
  final createdAt = safeJsonDateTime(snapshot['created_at']);
  final updatedAt = safeJsonDateTime(snapshot['updated_at']);
  if (createdAt == null || updatedAt == null) {
    throw const FormatException(
      'Remote planner snapshot has incomplete timestamps.',
    );
  }
  final deletedAt = safeJsonDateTime(snapshot['deleted_at']);

  if (kind == 'occurrence') {
    final entityId = safeNullableJsonString(payload['entity_id']);
    final plannedFor = safeJsonDateTime(payload['planned_for']);
    if (entityId == null || plannedFor == null) {
      throw const FormatException('Remote occurrence snapshot is incomplete.');
    }
    return _RemoteProjection.occurrence(
      PlannerOccurrence(
        id: id,
        ownerId: ownerId,
        entityId: entityId,
        plannedFor: plannedFor,
        status: safeJsonString(payload['status'], fallback: 'pending'),
        value: safeJsonMap(payload['value']),
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: safeJsonDateTime(payload['completed_at']),
        missedAt: safeJsonDateTime(payload['missed_at']),
        serverUpdatedAt: updatedAt,
        deletedAt: deletedAt,
      ),
    );
  }
  if (kind == 'focus_session') {
    final startedAt = safeJsonDateTime(payload['started_at']);
    if (startedAt == null) {
      throw const FormatException(
        'Remote focus-session snapshot is incomplete.',
      );
    }
    return _RemoteProjection.focusSession(
      PlannerFocusSession(
        id: id,
        ownerId: ownerId,
        entityId: safeNullableJsonString(payload['entity_id']),
        mode: safeJsonString(payload['mode'], fallback: 'stopwatch'),
        status: safeJsonString(payload['status'], fallback: 'active'),
        payload: safeJsonMap(payload['payload']),
        revision: revision,
        startedAt: startedAt,
        endedAt: safeJsonDateTime(payload['ended_at']),
        createdAt: createdAt,
        updatedAt: updatedAt,
        serverUpdatedAt: updatedAt,
        deletedAt: deletedAt,
      ),
    );
  }
  if (!PlannerEntityKind.values.any((entry) => entry.wireValue == kind)) {
    throw FormatException('Remote planner entity kind is unsupported: $kind');
  }
  final title = safeNullableJsonString(snapshot['title']);
  final lifecycle = safeNullableJsonString(snapshot['lifecycle_state']);
  final entityPayload = <String, dynamic>{
    ...payload,
    ...?(title == null
        ? null
        : <String, dynamic>{PlannerPayloadKeys.title: title}),
    ...?(lifecycle == null || payload.containsKey(PlannerPayloadKeys.status)
        ? null
        : <String, dynamic>{PlannerPayloadKeys.status: lifecycle}),
  };
  return _RemoteProjection.entity(
    PlannerEntity(
      id: id,
      ownerId: ownerId,
      kind: PlannerEntityKind.fromWire(kind),
      payload: entityPayload,
      revision: revision,
      createdAt: createdAt,
      updatedAt: updatedAt,
      serverCreatedAt: createdAt,
      serverUpdatedAt: updatedAt,
      deletedAt: deletedAt,
    ),
  );
}

Map<String, dynamic> _payloadPatch({
  required PlannerFieldPatch patch,
  required Map<String, dynamic> source,
}) {
  final root = patch.values['/'];
  if (root is Map) return safeJsonMap(root);
  if (root != null) return Map<String, dynamic>.from(source);
  final result = <String, dynamic>{};
  for (final entry in patch.values.entries) {
    final path = entry.key;
    if (path == '/deleted_at' || path.startsWith('/client_')) continue;
    _writeJsonPointer(result, path, entry.value);
  }
  return result;
}

void _writeJsonPointer(
  Map<String, dynamic> target,
  String path,
  dynamic value,
) {
  final segments = path
      .split('/')
      .skip(1)
      .map((segment) => segment.replaceAll('~1', '/').replaceAll('~0', '~'))
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.isEmpty) return;
  Map<String, dynamic> cursor = target;
  for (var index = 0; index < segments.length - 1; index++) {
    final segment = segments[index];
    final current = cursor[segment];
    if (current is Map<String, dynamic>) {
      cursor = current;
      continue;
    }
    final next = <String, dynamic>{};
    cursor[segment] = next;
    cursor = next;
  }
  cursor[segments.last] = value;
}

Map<String, dynamic> _occurrencePayload(PlannerOccurrence occurrence) =>
    <String, dynamic>{
      'entity_id': occurrence.entityId,
      'planned_for': occurrence.plannedFor.toUtc().toIso8601String(),
      'status': occurrence.status,
      'value': occurrence.value,
      'completed_at': occurrence.completedAt?.toUtc().toIso8601String(),
      'missed_at': occurrence.missedAt?.toUtc().toIso8601String(),
    };

Map<String, dynamic> _focusSessionPayload(PlannerFocusSession session) =>
    <String, dynamic>{
      'entity_id': session.entityId,
      'mode': session.mode,
      'status': session.status,
      'payload': session.payload,
      'started_at': session.startedAt.toUtc().toIso8601String(),
      'ended_at': session.endedAt?.toUtc().toIso8601String(),
    };

String _remoteOperationType(PlannerOutboxOperation operation) {
  if (operation.type == PlannerOperationType.softDeleteEntity) {
    return 'soft_delete';
  }
  // Restoring a tombstone must be explicit server-side: an ordinary upsert is
  // intentionally not allowed to resurrect an archived record by accident.
  if (operation.target == PlannerOperationTarget.entity &&
      operation.patch.values.containsKey('/deleted_at') &&
      operation.patch.values['/deleted_at'] == null) {
    return 'restore';
  }
  return 'upsert';
}

String _lifecycleFor(PlannerEntityStatus status) => switch (status) {
  PlannerEntityStatus.active => 'active',
  PlannerEntityStatus.completed => 'completed',
  PlannerEntityStatus.archived => 'archived',
  PlannerEntityStatus.cancelled => 'cancelled',
};

bool _isConnectivityError(Object error) {
  final value = error.toString().toLowerCase();
  return value.contains('socket') ||
      value.contains('network') ||
      value.contains('connection') ||
      value.contains('timeout') ||
      value.contains('unreachable');
}

String _syncErrorSummary(Object error) {
  final value = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (value.isEmpty) return 'Sync needs attention.';
  return value.length <= 280 ? value : '${value.substring(0, 277)}...';
}
