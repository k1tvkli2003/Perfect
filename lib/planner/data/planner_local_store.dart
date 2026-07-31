import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:uuid/uuid.dart';

/// The only local source of truth for planner state.
///
/// UI code writes through this store. Every durable planner mutation writes the
/// local projection and a server-ready outbox entry in the same Drift
/// transaction. No call in this class performs network I/O.
class PlannerLocalStore {
  PlannerLocalStore(this._database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  static const legacyV1Source = 'legacy_personal_items_v1';
  static const legacyRemoteV1Source = 'legacy_perfect_items_v1';

  final PlannerDatabase _database;
  final Uuid _uuid;

  Future<void> close() => _database.close();

  /// Safely imports the old SharedPreferences value when supplied by an
  /// application migration coordinator. The legacy string remains owned by the
  /// caller; this method never clears or writes SharedPreferences.
  Future<PlannerImportResult> bootstrap({
    required String ownerId,
    String? legacyPersonalItemsJson,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    if (legacyPersonalItemsJson == null ||
        legacyPersonalItemsJson.trim().isEmpty) {
      return const PlannerImportResult();
    }
    return importLegacyPersonalItems(
      ownerId: ownerId,
      rawLegacyJson: legacyPersonalItemsJson,
      now: now,
    );
  }

  Future<PlannerImportResult> importLegacyPersonalItems({
    required String ownerId,
    required String rawLegacyJson,
    String source = legacyV1Source,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    final normalizedSource = source.trim();
    if (normalizedSource.isEmpty) {
      throw ArgumentError.value(source, 'source', 'must not be empty');
    }
    final importedAt = _utc(now);
    final parsed = _parseLegacyItems(
      ownerId: ownerId,
      rawLegacyJson: rawLegacyJson,
      fallbackNow: importedAt,
      source: normalizedSource,
      uuid: _uuid,
    );
    var imported = 0;
    var alreadyImported = 0;

    await _database.transaction(() async {
      for (final candidate in parsed.items) {
        final marker = await _findImportMarker(
          ownerId: ownerId,
          source: normalizedSource,
          sourceId: candidate.sourceId,
        );
        if (marker != null) {
          alreadyImported++;
          continue;
        }

        final existingEntity = await _findEntityRow(
          ownerId,
          candidate.entity.id,
        );
        if (existingEntity == null) {
          final mutationId = _uuid.v5(
            Namespace.url.value,
            'perfect:$normalizedSource:$ownerId:${candidate.sourceId}',
          );
          await _persistEntityMutationInTransaction(
            entity: candidate.entity,
            operationType: PlannerOperationType.createEntity,
            patch: _createEntityPatch(candidate.entity),
            mutationId: mutationId,
            now: importedAt,
          );
          imported++;
        } else {
          // A newer v2 record wins. Recording the marker still makes a future
          // bootstrap safe and avoids replacing a locally edited v2 entity.
          alreadyImported++;
        }

        await _database
            .into(_database.plannerImportMarkers)
            .insert(
              PlannerImportMarkersCompanion.insert(
                ownerId: ownerId,
                source: normalizedSource,
                sourceId: candidate.sourceId,
                importedAt: importedAt,
                sourceFingerprint: Value('v1:${candidate.sourceId}'),
              ),
            );
      }
    });

    return PlannerImportResult(
      imported: imported,
      alreadyImported: alreadyImported,
      skipped: parsed.skipped,
      wasMalformedJson: parsed.wasMalformedJson,
    );
  }

  Stream<List<PlannerEntity>> watchActiveEntities(
    String ownerId, {
    Iterable<PlannerEntityKind>? kinds,
  }) {
    _requireOwnerId(ownerId);
    final query = _activeEntityQuery(ownerId, kinds: kinds);
    return query.watch().map(
      (rows) => rows.map(_entityFromRow).toList(growable: false),
    );
  }

  Future<List<PlannerEntity>> readActiveEntities(
    String ownerId, {
    Iterable<PlannerEntityKind>? kinds,
  }) async {
    _requireOwnerId(ownerId);
    final rows = await _activeEntityQuery(ownerId, kinds: kinds).get();
    return rows.map(_entityFromRow).toList(growable: false);
  }

  /// Archived records stay on-device and sync as tombstones so the owner can
  /// restore them. They are deliberately separate from the normal active
  /// stream, keeping everyday lists fast and calm.
  Future<List<PlannerEntity>> readArchivedEntities(String ownerId) async {
    _requireOwnerId(ownerId);
    final rows =
        await (_database.select(_database.plannerEntities)
              ..where(
                (row) =>
                    row.ownerId.equals(ownerId) & row.deletedAt.isNotNull(),
              )
              ..orderBy(<OrderingTerm Function(PlannerEntities)>[
                (row) => OrderingTerm(
                  expression: row.deletedAt,
                  mode: OrderingMode.desc,
                ),
                (row) => OrderingTerm(expression: row.id),
              ]))
            .get();
    return rows.map(_entityFromRow).toList(growable: false);
  }

  /// Reads durable occurrence history for insight, completion state, and
  /// recovery decisions. Callers can bound the range to avoid loading an
  /// unneeded lifetime history into a small surface.
  Future<List<PlannerOccurrence>> readOccurrences(
    String ownerId, {
    String? entityId,
    DateTime? fromInclusive,
    DateTime? untilExclusive,
  }) async {
    _requireOwnerId(ownerId);
    final query = _database.select(_database.plannerOccurrences)
      ..where((row) => row.ownerId.equals(ownerId) & row.deletedAt.isNull())
      ..orderBy(<OrderingTerm Function(PlannerOccurrences)>[
        (row) =>
            OrderingTerm(expression: row.plannedFor, mode: OrderingMode.desc),
        (row) => OrderingTerm(expression: row.id),
      ]);
    final normalizedEntityId = entityId?.trim();
    if (normalizedEntityId != null && normalizedEntityId.isNotEmpty) {
      query.where((row) => row.entityId.equals(normalizedEntityId));
    }
    if (fromInclusive != null) {
      query.where(
        (row) => row.plannedFor.isBiggerOrEqualValue(_utc(fromInclusive)),
      );
    }
    if (untilExclusive != null) {
      query.where(
        (row) => row.plannedFor.isSmallerThanValue(_utc(untilExclusive)),
      );
    }
    final rows = await query.get();
    return rows.map(_occurrenceFromRow).toList(growable: false);
  }

  Future<int> countCompletedOccurrencesInFlexiblePeriod({
    required String ownerId,
    required PlannerEntity entity,
    required DateTime day,
  }) async {
    final history = await readRecurrenceHistory(
      ownerId: ownerId,
      entity: entity,
      day: day,
    );
    return history.completedInPeriod;
  }

  /// Returns successful occurrence history used by flexible recurrence,
  /// Today projection, and device reminder projection.
  ///
  /// Habits are intentionally deduplicated by the device-owner's local
  /// calendar day. Older measured-habit builds could create several completed
  /// rows for one day; treating those rows as separate successes would consume
  /// both period quota and lifetime occurrence limits during migration.
  Future<PlannerRecurrenceHistory> readRecurrenceHistory({
    required String ownerId,
    required PlannerEntity entity,
    required DateTime day,
  }) async {
    _requireOwnerId(ownerId);
    if (entity.ownerId != ownerId) {
      throw StateError('The planner entity belongs to another owner.');
    }
    final occurrences = await readOccurrences(ownerId, entityId: entity.id);
    final completed = occurrences.where(
      (occurrence) => occurrence.status == 'completed',
    );
    final totalCompleted = _successfulOccurrenceCount(entity, completed);
    final window = PlannerRecurrenceEngine.flexiblePeriodWindow(
      entity: entity,
      date: day,
    );
    if (window == null) {
      return PlannerRecurrenceHistory(totalCompleted: totalCompleted);
    }
    final completedInPeriod = _successfulOccurrenceCount(
      entity,
      completed.where((occurrence) {
        final plannedFor = occurrence.plannedFor.toUtc();
        return !plannedFor.isBefore(window.startInclusive) &&
            plannedFor.isBefore(window.endExclusive);
      }),
    );
    return PlannerRecurrenceHistory(
      completedInPeriod: completedInPeriod,
      totalCompleted: totalCompleted,
    );
  }

  /// Counts successful occurrences in an optional planned-time range.
  ///
  /// The same habit migration guard as [readRecurrenceHistory] applies.
  Future<int> countCompletedOccurrences({
    required String ownerId,
    required PlannerEntity entity,
    DateTime? fromInclusive,
    DateTime? untilExclusive,
  }) async {
    _requireOwnerId(ownerId);
    if (entity.ownerId != ownerId) {
      throw StateError('The planner entity belongs to another owner.');
    }
    final occurrences = await readOccurrences(
      ownerId,
      entityId: entity.id,
      fromInclusive: fromInclusive,
      untilExclusive: untilExclusive,
    );
    return _successfulOccurrenceCount(
      entity,
      occurrences.where((occurrence) => occurrence.status == 'completed'),
    );
  }

  Future<PlannerTodayEligibility> evaluateTodayEligibility({
    required String ownerId,
    required PlannerEntity entity,
    required DateTime day,
    int? carryCount,
  }) async {
    final history = await readRecurrenceHistory(
      ownerId: ownerId,
      entity: entity,
      day: day,
    );
    return PlannerTodayEngine.evaluate(
      entity: entity,
      day: day,
      carryCount: carryCount,
      completedOccurrencesInPeriod: history.completedInPeriod,
      totalCompletedOccurrences: history.totalCompleted,
    );
  }

  Future<List<PlannerFocusSession>> readFocusSessions(
    String ownerId, {
    DateTime? startedAfter,
  }) async {
    _requireOwnerId(ownerId);
    final query = _database.select(_database.plannerFocusSessions)
      ..where((row) => row.ownerId.equals(ownerId) & row.deletedAt.isNull())
      ..orderBy(<OrderingTerm Function(PlannerFocusSessions)>[
        (row) =>
            OrderingTerm(expression: row.startedAt, mode: OrderingMode.desc),
        (row) => OrderingTerm(expression: row.id),
      ]);
    if (startedAfter != null) {
      query.where(
        (row) => row.startedAt.isBiggerOrEqualValue(_utc(startedAfter)),
      );
    }
    final rows = await query.get();
    return rows.map(_focusSessionFromRow).toList(growable: false);
  }

  Future<PlannerEntity?> readEntity({
    required String ownerId,
    required String entityId,
    bool includeDeleted = false,
  }) async {
    _requireOwnerId(ownerId);
    final row = await _findEntityRow(ownerId, entityId);
    if (row == null || (!includeDeleted && row.deletedAt != null)) return null;
    return _entityFromRow(row);
  }

  Future<PlannerOccurrence?> readOccurrence({
    required String ownerId,
    required String occurrenceId,
    bool includeDeleted = false,
  }) async {
    _requireOwnerId(ownerId);
    final row = await _findOccurrenceRow(ownerId, occurrenceId);
    if (row == null || (!includeDeleted && row.deletedAt != null)) return null;
    return _occurrenceFromRow(row);
  }

  Future<PlannerFocusSession?> readFocusSession({
    required String ownerId,
    required String sessionId,
    bool includeDeleted = false,
  }) async {
    _requireOwnerId(ownerId);
    final row = await _findFocusSessionRow(ownerId, sessionId);
    if (row == null || (!includeDeleted && row.deletedAt != null)) return null;
    return _focusSessionFromRow(row);
  }

  /// Applies a widget outcome only when its durable ordering tuple is newer.
  ///
  /// Android may run the widget callback and the foreground app in independent
  /// Flutter engines, each with its own [PlannerDatabase] connection. The
  /// conditional UPSERT is the first write in this transaction, so SQLite
  /// serializes those engines before [mutation] can touch planner state.
  ///
  /// Native actions (positive [queueSequence]) always sort after legacy
  /// actions. Legacy rows remain deterministic by `occurredAt + actionId`, so
  /// an old pre-sequence queue can still drain safely. Callers should use a
  /// stable day key for recurring outcomes and [oneOffWidgetSequenceScope] for
  /// one-off tasks, whose progress is not day-scoped.
  Future<T?> runGuardedWidgetOutcome<T>({
    required String ownerId,
    required String entityId,
    required String localDayKey,
    required int queueSequence,
    required DateTime occurredAt,
    required String actionId,
    required Future<T> Function() mutation,
  }) async {
    _requireOwnerId(ownerId);
    if (entityId.trim().isEmpty || localDayKey.trim().isEmpty) {
      throw ArgumentError('Widget outcome scope must not be empty.');
    }
    if (queueSequence < 0) {
      throw ArgumentError.value(
        queueSequence,
        'queueSequence',
        'must not be negative',
      );
    }
    final stableActionId = _requireMutationId(actionId);
    final occurredAtUtc = occurredAt.toUtc();
    final occurredAtMicros = occurredAtUtc.microsecondsSinceEpoch;
    if (occurredAtMicros < 0) {
      throw ArgumentError.value(
        occurredAt,
        'occurredAt',
        'must not be before the Unix epoch',
      );
    }

    var busyRetry = 0;
    while (true) {
      try {
        return await _database.transaction(() async {
          final accepted = await _claimWidgetOutcomeSequence(
            ownerId: ownerId,
            entityId: entityId,
            localDayKey: localDayKey,
            sequenceDomain: queueSequence > 0 ? 1 : 0,
            queueSequence: queueSequence,
            occurredAtMicros: occurredAtMicros,
            actionId: stableActionId,
            updatedAt: occurredAtUtc,
          );
          if (!accepted) return null;
          return mutation();
        });
      } on SqliteException catch (error) {
        if (!_isSqliteBusy(error) || busyRetry >= _maximumWidgetBusyRetries) {
          rethrow;
        }

        // `busy_timeout` handles ordinary short lock ownership inside SQLite.
        // A separate foreground/background connection can still return BUSY
        // while opening BEGIN IMMEDIATE (notably under Linux and some Android
        // VFS implementations). Retry only that transient result code. The
        // failed transaction has already rolled back, and the durable sequence
        // claim plus mutation id makes replay safe even if work began.
        final delay = _widgetBusyRetryDelay(
          retry: busyRetry,
          actionId: stableActionId,
        );
        busyRetry++;
        await Future<void>.delayed(delay);
      }
    }
  }

  static const oneOffWidgetSequenceScope = '*';
  static const _sqliteBusyResultCode = 5;
  static const _maximumWidgetBusyRetries = 4;

  static bool _isSqliteBusy(SqliteException error) =>
      error.resultCode == _sqliteBusyResultCode;

  static Duration _widgetBusyRetryDelay({
    required int retry,
    required String actionId,
  }) {
    // Deterministic per-action jitter prevents two widget engines from
    // repeatedly waking in lockstep while keeping the total retry window
    // bounded. The SQLite timeout remains the primary wait mechanism.
    final boundedRetry = retry.clamp(0, _maximumWidgetBusyRetries - 1);
    final exponentialMilliseconds = 16 << boundedRetry;
    final jitterMilliseconds =
        actionId.codeUnits.fold<int>(
          0,
          (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
        ) %
        17;
    return Duration(
      milliseconds: math.min(exponentialMilliseconds + jitterMilliseconds, 160),
    );
  }

  Future<PlannerMutationReceipt> createQuickTask({
    required String ownerId,
    required String title,
    DateTime? now,
    DateTime? scheduledAt,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final normalizedTitle = _requireTitle(title);
    final createdAt = _utc(now);
    final stableMutationId = _requireMutationId(mutationId ?? _uuid.v4());
    final payload = <String, dynamic>{
      ...defaultPlannerPayload(title: normalizedTitle),
      if (scheduledAt != null)
        PlannerPayloadKeys.timing: <String, dynamic>{
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        },
    };
    return _database.transaction(() async {
      final duplicate = await _findOperationByMutationId(stableMutationId);
      if (duplicate != null) {
        _ensureDuplicateOperationMatches(
          duplicate: duplicate,
          ownerId: ownerId,
          target: PlannerOperationTarget.entity,
          operationType: PlannerOperationType.createEntity,
          patch: PlannerFieldPatch(<String, dynamic>{'/': payload}),
        );
        final current = await _findEntityRow(ownerId, duplicate.targetId);
        return PlannerMutationReceipt(
          operation: _outboxFromRow(duplicate),
          entity: current == null ? null : _entityFromRow(current),
          wasDuplicate: true,
        );
      }

      final entity = PlannerEntity(
        id: _uuid.v4(),
        ownerId: ownerId,
        kind: PlannerEntityKind.oneOffTask,
        payload: payload,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      return _persistEntityMutationInTransaction(
        entity: entity,
        operationType: PlannerOperationType.createEntity,
        patch: _createEntityPatch(entity),
        mutationId: stableMutationId,
        now: createdAt,
      );
    });
  }

  Future<PlannerMutationReceipt> upsertEntity({
    required PlannerEntity entity,
    PlannerFieldPatch? patch,
    DateTime? now,
    String? mutationId,
  }) async {
    _requireOwnerId(entity.ownerId);
    if (entity.isDeleted) {
      throw ArgumentError.value(
        entity,
        'entity',
        'Use softDeleteEntity for deleted planner records.',
      );
    }
    _requireTitle(entity.title);
    final updatedAt = _utc(now);
    final effectivePatch =
        patch ?? PlannerFieldPatch.replacePayload(entity.payload);
    final patchedCompletedAt = effectivePatch.values['/completed_at'];
    final normalizedPayload = effectivePatch.values.containsKey('/completed_at')
        ? <String, dynamic>{
            ...entity.payload,
            'completed_at': patchedCompletedAt,
          }
        : entity.payload;
    final normalized = entity.copyWith(
      payload: normalizedPayload,
      updatedAt: updatedAt,
    );
    return _persistEntityMutation(
      entity: normalized,
      operationType: PlannerOperationType.upsertEntity,
      patch: effectivePatch,
      mutationId: mutationId ?? _uuid.v4(),
      now: updatedAt,
    );
  }

  Future<PlannerMutationReceipt> completeEntity({
    required String ownerId,
    required String entityId,
    DateTime? now,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final completedAt = _utc(now);
    return _database.transaction(() async {
      final entity = await _requireEntity(ownerId, entityId);
      final payload = <String, dynamic>{
        ...entity.payload,
        PlannerPayloadKeys.status: PlannerEntityStatus.completed.wireValue,
        'completed_at': completedAt.toIso8601String(),
      };
      return _persistEntityMutationInTransaction(
        entity: entity.copyWith(payload: payload, updatedAt: completedAt),
        operationType: PlannerOperationType.completeEntity,
        patch: PlannerFieldPatch(<String, dynamic>{
          '/${PlannerPayloadKeys.status}':
              PlannerEntityStatus.completed.wireValue,
          '/completed_at': completedAt.toIso8601String(),
        }),
        mutationId: mutationId ?? _uuid.v4(),
        now: completedAt,
      );
    });
  }

  Future<PlannerMutationReceipt> resolveOneOffRecovery({
    required String ownerId,
    required String entityId,
    required PlannerRecoveryDisposition disposition,
    DateTime? occurrenceAt,
    DateTime? now,
    int? carryCount,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    if (disposition == PlannerRecoveryDisposition.ask) {
      throw ArgumentError.value(
        disposition,
        'disposition',
        'Ask is a prompt, not a recovery resolution.',
      );
    }
    final resolvedAt = _utc(now);
    return _database.transaction(() async {
      final entity = await _requireEntity(ownerId, entityId);
      if (entity.kind != PlannerEntityKind.oneOffTask) {
        throw StateError('Only a one-off task has a durable miss resolution.');
      }
      final resolvedFor = _utc(occurrenceAt ?? entity.scheduledAt);
      final recovery = <String, dynamic>{
        ...entity.recovery,
        PlannerRecoveryKeys.resolution: <String, dynamic>{
          PlannerRecoveryKeys.disposition: disposition.wireValue,
          PlannerRecoveryKeys.resolvedFor: resolvedFor.toIso8601String(),
          PlannerRecoveryKeys.resolvedAt: resolvedAt.toIso8601String(),
          PlannerRecoveryKeys.carryCount:
              carryCount ??
              safeJsonInt(
                entity.recovery[PlannerRecoveryKeys.carryCount],
                fallback: 0,
              ),
        },
      };
      final progressState = disposition == PlannerRecoveryDisposition.missed
          ? 'missed'
          : 'pending';
      final payload = <String, dynamic>{
        ...entity.payload,
        PlannerPayloadKeys.recovery: recovery,
        PlannerPayloadKeys.taskProgressState: progressState,
        PlannerPayloadKeys.taskProgressPercent: 0,
        PlannerPayloadKeys.status: PlannerEntityStatus.active.wireValue,
        'completed_at': null,
      };
      return _persistEntityMutationInTransaction(
        entity: entity.copyWith(payload: payload, updatedAt: resolvedAt),
        operationType: PlannerOperationType.upsertEntity,
        patch: PlannerFieldPatch(<String, dynamic>{
          '/${PlannerPayloadKeys.recovery}/${PlannerRecoveryKeys.resolution}':
              recovery[PlannerRecoveryKeys.resolution],
          '/${PlannerPayloadKeys.taskProgressState}': progressState,
          '/${PlannerPayloadKeys.taskProgressPercent}': 0,
          '/${PlannerPayloadKeys.status}': PlannerEntityStatus.active.wireValue,
          '/completed_at': null,
        }),
        mutationId: mutationId ?? _uuid.v4(),
        now: resolvedAt,
      );
    });
  }

  Future<PlannerMutationReceipt> softDeleteEntity({
    required String ownerId,
    required String entityId,
    DateTime? now,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final deletedAt = _utc(now);
    return _database.transaction(() async {
      final entity = await _requireEntity(
        ownerId,
        entityId,
        includeDeleted: true,
      );
      return _persistEntityMutationInTransaction(
        entity: entity.copyWith(updatedAt: deletedAt, deletedAt: deletedAt),
        operationType: PlannerOperationType.softDeleteEntity,
        patch: PlannerFieldPatch(<String, dynamic>{
          '/deleted_at': deletedAt.toIso8601String(),
        }),
        mutationId: mutationId ?? _uuid.v4(),
        now: deletedAt,
      );
    });
  }

  /// Restores an archived entity without treating it as a fresh record. The
  /// explicit `/deleted_at` patch maps to the server's `restore` operation,
  /// preserving identity and the conflict trail across devices.
  Future<PlannerMutationReceipt> restoreEntity({
    required String ownerId,
    required String entityId,
    DateTime? now,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final restoredAt = _utc(now);
    return _database.transaction(() async {
      final entity = await _requireEntity(
        ownerId,
        entityId,
        includeDeleted: true,
      );
      if (!entity.isDeleted) {
        throw StateError('Only archived planner records can be restored.');
      }
      return _persistEntityMutationInTransaction(
        entity: entity.copyWith(updatedAt: restoredAt, clearDeletedAt: true),
        operationType: PlannerOperationType.upsertEntity,
        patch: PlannerFieldPatch(<String, dynamic>{'/deleted_at': null}),
        mutationId: mutationId ?? _uuid.v4(),
        now: restoredAt,
      );
    });
  }

  Future<PlannerMutationReceipt> appendOccurrence({
    required String ownerId,
    required String entityId,
    required DateTime plannedFor,
    String status = 'pending',
    Map<String, dynamic> value = const <String, dynamic>{},
    DateTime? now,
    String? occurrenceId,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final createdAt = _utc(now);
    return _database.transaction(() async {
      final entity = await _requireEntity(ownerId, entityId);
      final normalizedStatus = _requireOccurrenceStatus(status);
      final stableOccurrenceId = occurrenceId ?? _uuid.v4();
      final existing = await _findOccurrenceRow(ownerId, stableOccurrenceId);
      if (existing != null && existing.entityId != entity.id) {
        throw StateError('An occurrence ID cannot move between planner items.');
      }
      final occurrence = existing == null
          ? PlannerOccurrence(
              id: stableOccurrenceId,
              ownerId: ownerId,
              entityId: entity.id,
              plannedFor: _utc(plannedFor),
              status: normalizedStatus,
              value: value,
              createdAt: createdAt,
              updatedAt: createdAt,
              completedAt: normalizedStatus == 'completed' ? createdAt : null,
              missedAt: normalizedStatus == 'missed' ? createdAt : null,
            )
          : _occurrenceFromRow(existing).copyWith(
              status: normalizedStatus,
              value: value,
              updatedAt: createdAt,
              completedAt: normalizedStatus == 'completed' ? createdAt : null,
              missedAt: normalizedStatus == 'missed' ? createdAt : null,
              clearCompletedAt: normalizedStatus != 'completed',
              clearMissedAt: normalizedStatus != 'missed',
              clearDeletedAt: true,
            );
      return _persistOccurrenceMutationInTransaction(
        occurrence: occurrence,
        operationType: PlannerOperationType.appendOccurrence,
        patch: PlannerFieldPatch(<String, dynamic>{'/': occurrence.toJson()}),
        mutationId: mutationId ?? _uuid.v4(),
        now: createdAt,
        entityKind: entity.kind,
      );
    });
  }

  Future<PlannerMutationReceipt> completeOccurrence({
    required String ownerId,
    required String occurrenceId,
    DateTime? now,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final completedAt = _utc(now);
    return _database.transaction(() async {
      final occurrence = await _requireOccurrence(ownerId, occurrenceId);
      final entity = await _findEntityRow(ownerId, occurrence.entityId);
      final completed = occurrence.copyWith(
        status: 'completed',
        completedAt: completedAt,
        updatedAt: completedAt,
        clearMissedAt: true,
      );
      return _persistOccurrenceMutationInTransaction(
        occurrence: completed,
        operationType: PlannerOperationType.completeOccurrence,
        patch: PlannerFieldPatch(<String, dynamic>{
          '/status': 'completed',
          '/completed_at': completedAt.toIso8601String(),
        }),
        mutationId: mutationId ?? _uuid.v4(),
        now: completedAt,
        entityKind: entity == null
            ? null
            : PlannerEntityKind.fromWire(entity.kind),
      );
    });
  }

  Future<PlannerMutationReceipt> appendFocusSession({
    required String ownerId,
    required DateTime startedAt,
    String? entityId,
    String mode = 'stopwatch',
    String status = 'active',
    Map<String, dynamic> payload = const <String, dynamic>{},
    DateTime? now,
    String? sessionId,
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final createdAt = _utc(now);
    return _database.transaction(() async {
      final entity = entityId == null
          ? null
          : await _requireEntity(ownerId, entityId);
      final session = PlannerFocusSession(
        id: sessionId ?? _uuid.v4(),
        ownerId: ownerId,
        entityId: entityId,
        startedAt: _utc(startedAt),
        mode: mode.trim().isEmpty ? 'stopwatch' : mode.trim(),
        status: status.trim().isEmpty ? 'active' : status.trim(),
        payload: payload,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      return _persistFocusSessionMutationInTransaction(
        session: session,
        operationType: PlannerOperationType.appendFocusSession,
        patch: PlannerFieldPatch(<String, dynamic>{'/': session.toJson()}),
        mutationId: mutationId ?? _uuid.v4(),
        now: createdAt,
        entityKind: entity?.kind,
      );
    });
  }

  Future<PlannerMutationReceipt> completeFocusSession({
    required String ownerId,
    required String sessionId,
    DateTime? endedAt,
    Map<String, dynamic>? payload,
    String status = 'completed',
    String? mutationId,
  }) async {
    _requireOwnerId(ownerId);
    final completedAt = _utc(endedAt);
    return _database.transaction(() async {
      final current = await _findFocusSessionRow(ownerId, sessionId);
      if (current == null || current.deletedAt != null) {
        throw StateError('Focus session is not available for this owner.');
      }
      final session = _focusSessionFromRow(current);
      final completed = session.copyWith(
        status: status.trim().isEmpty ? 'completed' : status.trim(),
        payload: payload ?? session.payload,
        endedAt: completedAt,
        updatedAt: completedAt,
      );
      final entity = session.entityId == null
          ? null
          : await _findEntityRow(ownerId, session.entityId!);
      return _persistFocusSessionMutationInTransaction(
        session: completed,
        operationType: PlannerOperationType.appendFocusSession,
        patch: PlannerFieldPatch(<String, dynamic>{
          '/status': completed.status,
          '/ended_at': completedAt.toIso8601String(),
          ...?(payload == null ? null : <String, dynamic>{'/payload': payload}),
        }),
        mutationId: mutationId ?? _uuid.v4(),
        now: completedAt,
        entityKind: entity == null
            ? null
            : PlannerEntityKind.fromWire(entity.kind),
      );
    });
  }

  Future<List<PlannerOutboxOperation>> listPendingOperations(
    String ownerId, {
    int? limit,
  }) async {
    _requireOwnerId(ownerId);
    final query = _database.select(_database.plannerOutboxOperations)
      ..where(
        (row) =>
            row.ownerId.equals(ownerId) &
            row.state.isIn(<String>[
              PlannerOperationState.pending.wireValue,
              PlannerOperationState.retrying.wireValue,
            ]),
      )
      ..orderBy(<OrderingTerm Function(PlannerOutboxOperations)>[
        (row) => OrderingTerm(expression: row.localSequence),
      ]);
    if (limit != null) query.limit(limit.clamp(1, 1000));
    final rows = await query.get();
    return rows.map(_outboxFromRow).toList(growable: false);
  }

  Future<PlannerOutboxOperation?> markOperationRetry({
    required String ownerId,
    required String mutationId,
    required String error,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    final attemptedAt = _utc(now);
    return _database.transaction(() async {
      final row = await _findOperation(ownerId, mutationId);
      if (row == null || row.acknowledgedAt != null) return null;
      final attempts = row.attemptCount + 1;
      await (_database.update(_database.plannerOutboxOperations)..where(
            (operation) =>
                operation.ownerId.equals(ownerId) &
                operation.mutationId.equals(mutationId),
          ))
          .write(
            PlannerOutboxOperationsCompanion(
              state: Value(PlannerOperationState.retrying.wireValue),
              attemptCount: Value(attempts),
              lastAttemptAt: Value(attemptedAt),
              lastError: Value(_truncateError(error)),
            ),
          );
      return _findOperation(ownerId, mutationId).then(_outboxFromNullableRow);
    });
  }

  Future<PlannerOutboxOperation?> markOperationAcknowledged({
    required String ownerId,
    required String mutationId,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    final acknowledgedAt = _utc(now);
    return _database.transaction(() async {
      final row = await _findOperation(ownerId, mutationId);
      if (row == null) return null;
      if (row.acknowledgedAt != null) return _outboxFromRow(row);
      await (_database.update(_database.plannerOutboxOperations)..where(
            (operation) =>
                operation.ownerId.equals(ownerId) &
                operation.mutationId.equals(mutationId),
          ))
          .write(
            PlannerOutboxOperationsCompanion(
              state: Value(PlannerOperationState.acknowledged.wireValue),
              acknowledgedAt: Value(acknowledgedAt),
              lastAttemptAt: Value(acknowledgedAt),
              lastError: const Value(null),
            ),
          );
      return _findOperation(ownerId, mutationId).then(_outboxFromNullableRow);
    });
  }

  Future<PlannerSyncMetadataValue> updateRemoteCursor({
    required String ownerId,
    required String? cursor,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    final syncedAt = _utc(now);
    final existing = await readSyncMetadata(ownerId);
    final metadata = PlannerSyncMetadataCompanion(
      ownerId: Value(ownerId),
      remoteCursor: Value(
        cursor?.trim().isEmpty ?? true ? null : cursor!.trim(),
      ),
      lastSyncAt: Value(syncedAt),
      lastSuccessfulSyncAt: Value(existing?.lastSuccessfulSyncAt),
      lastError: Value(existing?.lastError),
    );
    await _database
        .into(_database.plannerSyncMetadata)
        .insertOnConflictUpdate(metadata);
    final row = await (_database.select(
      _database.plannerSyncMetadata,
    )..where((entry) => entry.ownerId.equals(ownerId))).getSingle();
    return _syncMetadataFromRow(row);
  }

  Future<PlannerSyncMetadataValue> markSyncSuccess({
    required String ownerId,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    final syncedAt = _utc(now);
    final existing = await readSyncMetadata(ownerId);
    await _database
        .into(_database.plannerSyncMetadata)
        .insertOnConflictUpdate(
          PlannerSyncMetadataCompanion(
            ownerId: Value(ownerId),
            remoteCursor: Value(existing?.remoteCursor),
            lastSyncAt: Value(syncedAt),
            lastSuccessfulSyncAt: Value(syncedAt),
            lastError: const Value(null),
          ),
        );
    final row = await (_database.select(
      _database.plannerSyncMetadata,
    )..where((entry) => entry.ownerId.equals(ownerId))).getSingle();
    return _syncMetadataFromRow(row);
  }

  Future<PlannerSyncMetadataValue?> readSyncMetadata(String ownerId) async {
    _requireOwnerId(ownerId);
    final row = await (_database.select(
      _database.plannerSyncMetadata,
    )..where((entry) => entry.ownerId.equals(ownerId))).getSingleOrNull();
    return row == null ? null : _syncMetadataFromRow(row);
  }

  Future<PlannerSyncConflict> recordConflict(
    PlannerSyncConflict conflict,
  ) async {
    _requireOwnerId(conflict.ownerId);
    await _database
        .into(_database.plannerConflicts)
        .insertOnConflictUpdate(
          PlannerConflictsCompanion(
            id: Value(conflict.id),
            ownerId: Value(conflict.ownerId),
            targetType: Value(conflict.targetType.wireValue),
            targetId: Value(conflict.targetId),
            mutationId: Value(conflict.mutationId),
            fieldPathsJson: Value(jsonEncode(conflict.fieldPaths)),
            localValueJson: Value(jsonEncode(conflict.localValue)),
            remoteValueJson: Value(jsonEncode(conflict.remoteValue)),
            baseRevision: Value(conflict.baseRevision),
            remoteRevision: Value(conflict.remoteRevision),
            status: Value(conflict.status),
            createdAt: Value(_utc(conflict.createdAt)),
            resolvedAt: Value(
              conflict.resolvedAt == null ? null : _utc(conflict.resolvedAt!),
            ),
          ),
        );
    return conflict;
  }

  Future<List<PlannerSyncConflict>> listConflicts(
    String ownerId, {
    String? status,
  }) async {
    _requireOwnerId(ownerId);
    final query = _database.select(_database.plannerConflicts)
      ..where((row) => row.ownerId.equals(ownerId));
    if (status != null) query.where((row) => row.status.equals(status));
    query.orderBy(<OrderingTerm Function(PlannerConflicts)>[
      (row) => OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
    ]);
    final rows = await query.get();
    return rows.map(_conflictFromRow).toList(growable: false);
  }

  Future<void> resolveConflict({
    required String ownerId,
    required String conflictId,
    required String resolution,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    const allowed = <String>{'kept_local', 'kept_server', 'merged'};
    if (!allowed.contains(resolution)) {
      throw ArgumentError.value(resolution, 'resolution', 'is not supported');
    }
    await (_database.update(_database.plannerConflicts)..where(
          (row) => row.ownerId.equals(ownerId) & row.id.equals(conflictId),
        ))
        .write(
          PlannerConflictsCompanion(
            status: Value(resolution),
            resolvedAt: Value(_utc(now)),
          ),
        );
  }

  /// Projects an authoritative v2 entity snapshot locally. Remote changes
  /// never overwrite an entity that still has a local outbox mutation; that
  /// mutation is deliberately sent through the revision-aware RPC instead.
  Future<bool> applyRemoteEntity(
    PlannerEntity entity, {
    bool preservePendingLocal = true,
  }) async {
    _requireOwnerId(entity.ownerId);
    return _database.transaction(() async {
      if (preservePendingLocal &&
          await _hasPendingTarget(
            ownerId: entity.ownerId,
            target: PlannerOperationTarget.entity,
            targetId: entity.id,
          )) {
        return false;
      }
      final local = await _findEntityRow(entity.ownerId, entity.id);
      if (local != null && local.revision > entity.revision) return false;
      await _database
          .into(_database.plannerEntities)
          .insertOnConflictUpdate(_entityCompanion(entity));
      return true;
    });
  }

  Future<bool> applyRemoteOccurrence(
    PlannerOccurrence occurrence, {
    bool preservePendingLocal = true,
  }) async {
    _requireOwnerId(occurrence.ownerId);
    return _database.transaction(() async {
      if (preservePendingLocal &&
          await _hasPendingTarget(
            ownerId: occurrence.ownerId,
            target: PlannerOperationTarget.occurrence,
            targetId: occurrence.id,
          )) {
        return false;
      }
      final local = await _findOccurrenceRow(occurrence.ownerId, occurrence.id);
      if (local != null && local.revision > occurrence.revision) return false;
      await _database
          .into(_database.plannerOccurrences)
          .insertOnConflictUpdate(_occurrenceCompanion(occurrence));
      return true;
    });
  }

  Future<bool> applyRemoteFocusSession(
    PlannerFocusSession session, {
    bool preservePendingLocal = true,
  }) async {
    _requireOwnerId(session.ownerId);
    return _database.transaction(() async {
      if (preservePendingLocal &&
          await _hasPendingTarget(
            ownerId: session.ownerId,
            target: PlannerOperationTarget.focusSession,
            targetId: session.id,
          )) {
        return false;
      }
      final local = await _findFocusSessionRow(session.ownerId, session.id);
      if (local != null && local.revision > session.revision) return false;
      await _database
          .into(_database.plannerFocusSessions)
          .insertOnConflictUpdate(_focusSessionCompanion(session));
      return true;
    });
  }

  /// Moves queued mutations after a confirmed predecessor onto the latest
  /// server revision. This prevents a user's own quick sequence of edits from
  /// being falsely reported as a conflict merely because it was created while
  /// the first write was still offline.
  Future<int> rebasePendingOperationsForTarget({
    required String ownerId,
    required PlannerOperationTarget target,
    required String targetId,
    required int baseRevision,
    required int afterSequence,
  }) async {
    _requireOwnerId(ownerId);
    if (baseRevision < 0 || afterSequence < 0) {
      throw ArgumentError('Revision and sequence must not be negative.');
    }
    return (_database.update(_database.plannerOutboxOperations)..where(
          (operation) =>
              operation.ownerId.equals(ownerId) &
              operation.targetType.equals(target.wireValue) &
              operation.targetId.equals(targetId) &
              operation.localSequence.isBiggerThanValue(afterSequence) &
              operation.state.isIn(<String>[
                PlannerOperationState.pending.wireValue,
                PlannerOperationState.retrying.wireValue,
              ]),
        ))
        .write(
          PlannerOutboxOperationsCompanion(
            baseRevision: Value(baseRevision),
            state: Value(PlannerOperationState.pending.wireValue),
            lastError: const Value(null),
          ),
        );
  }

  Future<void> markSyncFailure({
    required String ownerId,
    required String error,
    DateTime? now,
  }) async {
    _requireOwnerId(ownerId);
    final attemptedAt = _utc(now);
    final existing = await readSyncMetadata(ownerId);
    await _database
        .into(_database.plannerSyncMetadata)
        .insertOnConflictUpdate(
          PlannerSyncMetadataCompanion(
            ownerId: Value(ownerId),
            remoteCursor: Value(existing?.remoteCursor),
            lastSyncAt: Value(attemptedAt),
            lastSuccessfulSyncAt: Value(existing?.lastSuccessfulSyncAt),
            lastError: Value(_truncateError(error)),
          ),
        );
  }

  SimpleSelectStatement<PlannerEntities, PlannerEntityRow> _activeEntityQuery(
    String ownerId, {
    Iterable<PlannerEntityKind>? kinds,
  }) {
    final query = _database.select(_database.plannerEntities)
      ..where((row) => row.ownerId.equals(ownerId) & row.deletedAt.isNull())
      ..orderBy(<OrderingTerm Function(PlannerEntities)>[
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
        (row) => OrderingTerm(expression: row.id),
      ]);
    final wireValues = kinds?.map((kind) => kind.wireValue).toSet();
    if (wireValues != null && wireValues.isNotEmpty) {
      query.where((row) => row.kind.isIn(wireValues));
    }
    return query;
  }

  Future<PlannerMutationReceipt> _persistEntityMutation({
    required PlannerEntity entity,
    required PlannerOperationType operationType,
    required PlannerFieldPatch patch,
    required String mutationId,
    required DateTime now,
  }) => _database.transaction(
    () => _persistEntityMutationInTransaction(
      entity: entity,
      operationType: operationType,
      patch: patch,
      mutationId: mutationId,
      now: now,
    ),
  );

  Future<bool> _claimWidgetOutcomeSequence({
    required String ownerId,
    required String entityId,
    required String localDayKey,
    required int sequenceDomain,
    required int queueSequence,
    required int occurredAtMicros,
    required String actionId,
    required DateTime updatedAt,
  }) async {
    final claimed = await _database
        .customSelect(
          '''
INSERT INTO planner_widget_action_sequences (
  owner_id,
  entity_id,
  local_day,
  sequence_domain,
  queue_sequence,
  occurred_at_micros,
  action_id,
  updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(owner_id, entity_id, local_day) DO UPDATE SET
  sequence_domain = excluded.sequence_domain,
  queue_sequence = excluded.queue_sequence,
  occurred_at_micros = excluded.occurred_at_micros,
  action_id = excluded.action_id,
  updated_at = excluded.updated_at
WHERE
  excluded.sequence_domain >
    planner_widget_action_sequences.sequence_domain
  OR (
    excluded.sequence_domain =
      planner_widget_action_sequences.sequence_domain
    AND excluded.queue_sequence >
      planner_widget_action_sequences.queue_sequence
  )
  OR (
    excluded.sequence_domain =
      planner_widget_action_sequences.sequence_domain
    AND excluded.queue_sequence =
      planner_widget_action_sequences.queue_sequence
    AND excluded.occurred_at_micros >
      planner_widget_action_sequences.occurred_at_micros
  )
  OR (
    excluded.sequence_domain =
      planner_widget_action_sequences.sequence_domain
    AND excluded.queue_sequence =
      planner_widget_action_sequences.queue_sequence
    AND excluded.occurred_at_micros =
      planner_widget_action_sequences.occurred_at_micros
    AND excluded.action_id >
      planner_widget_action_sequences.action_id
  )
RETURNING action_id
''',
          variables: <Variable<Object>>[
            Variable<String>(ownerId),
            Variable<String>(entityId),
            Variable<String>(localDayKey),
            Variable<int>(sequenceDomain),
            Variable<int>(queueSequence),
            Variable<int>(occurredAtMicros),
            Variable<String>(actionId),
            Variable<DateTime>(updatedAt),
          ],
          readsFrom: <ResultSetImplementation>{
            _database.plannerWidgetActionSequences,
          },
        )
        .getSingleOrNull();
    return claimed != null;
  }

  Future<PlannerMutationReceipt> _persistEntityMutationInTransaction({
    required PlannerEntity entity,
    required PlannerOperationType operationType,
    required PlannerFieldPatch patch,
    required String mutationId,
    required DateTime now,
  }) async {
    final stableMutationId = _requireMutationId(mutationId);
    final duplicate = await _findOperationByMutationId(stableMutationId);
    if (duplicate != null) {
      _ensureDuplicateOperationMatches(
        duplicate: duplicate,
        ownerId: entity.ownerId,
        target: PlannerOperationTarget.entity,
        targetId: entity.id,
        operationType: operationType,
        patch: patch,
      );
      final current =
          PlannerOperationTarget.fromWire(duplicate.targetType) ==
              PlannerOperationTarget.entity
          ? await _findEntityRow(entity.ownerId, duplicate.targetId)
          : null;
      return PlannerMutationReceipt(
        operation: _outboxFromRow(duplicate),
        entity: current == null ? null : _entityFromRow(current),
        wasDuplicate: true,
      );
    }

    await _database
        .into(_database.plannerEntities)
        .insertOnConflictUpdate(_entityCompanion(entity));
    final operation = await _insertOutboxOperation(
      mutationId: stableMutationId,
      ownerId: entity.ownerId,
      target: PlannerOperationTarget.entity,
      targetId: entity.id,
      entityId: entity.id,
      entityKind: entity.kind,
      type: operationType,
      patch: patch,
      baseRevision: entity.revision,
      createdAt: now,
    );
    return PlannerMutationReceipt(operation: operation, entity: entity);
  }

  Future<PlannerMutationReceipt> _persistOccurrenceMutationInTransaction({
    required PlannerOccurrence occurrence,
    required PlannerOperationType operationType,
    required PlannerFieldPatch patch,
    required String mutationId,
    required DateTime now,
    PlannerEntityKind? entityKind,
  }) async {
    final stableMutationId = _requireMutationId(mutationId);
    final duplicate = await _findOperationByMutationId(stableMutationId);
    if (duplicate != null) {
      _ensureDuplicateOperationMatches(
        duplicate: duplicate,
        ownerId: occurrence.ownerId,
        target: PlannerOperationTarget.occurrence,
        targetId: occurrence.id,
        operationType: operationType,
        patch: patch,
      );
      final current =
          PlannerOperationTarget.fromWire(duplicate.targetType) ==
              PlannerOperationTarget.occurrence
          ? await _findOccurrenceRow(occurrence.ownerId, duplicate.targetId)
          : null;
      return PlannerMutationReceipt(
        operation: _outboxFromRow(duplicate),
        occurrence: current == null ? null : _occurrenceFromRow(current),
        wasDuplicate: true,
      );
    }

    await _database
        .into(_database.plannerOccurrences)
        .insertOnConflictUpdate(_occurrenceCompanion(occurrence));
    final operation = await _insertOutboxOperation(
      mutationId: stableMutationId,
      ownerId: occurrence.ownerId,
      target: PlannerOperationTarget.occurrence,
      targetId: occurrence.id,
      entityId: occurrence.entityId,
      entityKind: entityKind,
      type: operationType,
      patch: patch,
      baseRevision: occurrence.revision,
      createdAt: now,
    );
    return PlannerMutationReceipt(operation: operation, occurrence: occurrence);
  }

  Future<PlannerMutationReceipt> _persistFocusSessionMutationInTransaction({
    required PlannerFocusSession session,
    required PlannerOperationType operationType,
    required PlannerFieldPatch patch,
    required String mutationId,
    required DateTime now,
    PlannerEntityKind? entityKind,
  }) async {
    final stableMutationId = _requireMutationId(mutationId);
    final duplicate = await _findOperationByMutationId(stableMutationId);
    if (duplicate != null) {
      _ensureDuplicateOperationMatches(
        duplicate: duplicate,
        ownerId: session.ownerId,
        target: PlannerOperationTarget.focusSession,
        targetId: session.id,
        operationType: operationType,
        patch: patch,
      );
      final current =
          PlannerOperationTarget.fromWire(duplicate.targetType) ==
              PlannerOperationTarget.focusSession
          ? await _findFocusSessionRow(session.ownerId, duplicate.targetId)
          : null;
      return PlannerMutationReceipt(
        operation: _outboxFromRow(duplicate),
        focusSession: current == null ? null : _focusSessionFromRow(current),
        wasDuplicate: true,
      );
    }

    await _database
        .into(_database.plannerFocusSessions)
        .insertOnConflictUpdate(_focusSessionCompanion(session));
    final operation = await _insertOutboxOperation(
      mutationId: stableMutationId,
      ownerId: session.ownerId,
      target: PlannerOperationTarget.focusSession,
      targetId: session.id,
      entityId: session.entityId,
      entityKind: entityKind,
      type: operationType,
      patch: patch,
      baseRevision: session.revision,
      createdAt: now,
    );
    return PlannerMutationReceipt(operation: operation, focusSession: session);
  }

  void _ensureDuplicateOperationMatches({
    required PlannerOutboxOperationRow duplicate,
    required String ownerId,
    required PlannerOperationTarget target,
    required PlannerOperationType operationType,
    required PlannerFieldPatch patch,
    String? targetId,
  }) {
    final sameOwner = duplicate.ownerId == ownerId;
    final sameTarget = duplicate.targetType == target.wireValue;
    final sameTargetId = targetId == null || duplicate.targetId == targetId;
    final sameOperation = duplicate.operationType == operationType.wireValue;
    final existingPatch = _semanticPatch(
      safeJsonMap(duplicate.fieldPatchJson),
      target: target,
    );
    final requestedPatch = _semanticPatch(patch.toJson(), target: target);
    final samePatch =
        _canonicalJson(existingPatch) == _canonicalJson(requestedPatch);
    if (!sameOwner ||
        !sameTarget ||
        !sameTargetId ||
        !sameOperation ||
        !samePatch) {
      throw StateError(
        'A mutation id cannot be reused for a different local request.',
      );
    }
  }

  Future<PlannerOutboxOperation> _insertOutboxOperation({
    required String mutationId,
    required String ownerId,
    required PlannerOperationTarget target,
    required String targetId,
    required String? entityId,
    required PlannerEntityKind? entityKind,
    required PlannerOperationType type,
    required PlannerFieldPatch patch,
    required int baseRevision,
    required DateTime createdAt,
  }) async {
    final sequence = await _database
        .into(_database.plannerOutboxOperations)
        .insert(
          PlannerOutboxOperationsCompanion.insert(
            mutationId: mutationId,
            ownerId: ownerId,
            targetType: target.wireValue,
            targetId: targetId,
            entityId: Value(entityId),
            entityKind: Value(entityKind?.wireValue),
            operationType: type.wireValue,
            fieldPatchJson: jsonEncode(patch.toJson()),
            baseRevision: Value(baseRevision),
            createdAt: _utc(createdAt),
          ),
        );
    final row =
        await (_database.select(_database.plannerOutboxOperations)
              ..where((operation) => operation.localSequence.equals(sequence)))
            .getSingle();
    return _outboxFromRow(row);
  }

  Future<PlannerEntity> _requireEntity(
    String ownerId,
    String entityId, {
    bool includeDeleted = false,
  }) async {
    final row = await _findEntityRow(ownerId, entityId);
    if (row == null || (!includeDeleted && row.deletedAt != null)) {
      throw StateError('Planner entity is not available for this owner.');
    }
    return _entityFromRow(row);
  }

  int _successfulOccurrenceCount(
    PlannerEntity entity,
    Iterable<PlannerOccurrence> completed,
  ) {
    if (entity.kind != PlannerEntityKind.habit) return completed.length;
    return completed
        .map((occurrence) {
          final local = occurrence.plannedFor.toLocal();
          return (local.year, local.month, local.day);
        })
        .toSet()
        .length;
  }

  Future<PlannerOccurrence> _requireOccurrence(
    String ownerId,
    String occurrenceId,
  ) async {
    final row = await _findOccurrenceRow(ownerId, occurrenceId);
    if (row == null || row.deletedAt != null) {
      throw StateError('Planner occurrence is not available for this owner.');
    }
    return _occurrenceFromRow(row);
  }

  Future<PlannerEntityRow?> _findEntityRow(String ownerId, String entityId) =>
      (_database.select(_database.plannerEntities)..where(
            (row) => row.ownerId.equals(ownerId) & row.id.equals(entityId),
          ))
          .getSingleOrNull();

  Future<PlannerOccurrenceRow?> _findOccurrenceRow(
    String ownerId,
    String occurrenceId,
  ) =>
      (_database.select(_database.plannerOccurrences)..where(
            (row) => row.ownerId.equals(ownerId) & row.id.equals(occurrenceId),
          ))
          .getSingleOrNull();

  Future<PlannerFocusSessionRow?> _findFocusSessionRow(
    String ownerId,
    String sessionId,
  ) =>
      (_database.select(_database.plannerFocusSessions)..where(
            (row) => row.ownerId.equals(ownerId) & row.id.equals(sessionId),
          ))
          .getSingleOrNull();

  Future<bool> _hasPendingTarget({
    required String ownerId,
    required PlannerOperationTarget target,
    required String targetId,
  }) async {
    final row =
        await (_database.select(_database.plannerOutboxOperations)
              ..where(
                (operation) =>
                    operation.ownerId.equals(ownerId) &
                    operation.targetType.equals(target.wireValue) &
                    operation.targetId.equals(targetId) &
                    operation.state.isIn(<String>[
                      PlannerOperationState.pending.wireValue,
                      PlannerOperationState.retrying.wireValue,
                    ]),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<PlannerOutboxOperationRow?> _findOperation(
    String ownerId,
    String mutationId,
  ) =>
      (_database.select(_database.plannerOutboxOperations)..where(
            (row) =>
                row.ownerId.equals(ownerId) & row.mutationId.equals(mutationId),
          ))
          .getSingleOrNull();

  Future<PlannerOutboxOperationRow?> _findOperationByMutationId(
    String mutationId,
  ) => (_database.select(
    _database.plannerOutboxOperations,
  )..where((row) => row.mutationId.equals(mutationId))).getSingleOrNull();

  Future<PlannerImportMarkerRow?> _findImportMarker({
    required String ownerId,
    required String source,
    required String sourceId,
  }) =>
      (_database.select(_database.plannerImportMarkers)..where(
            (row) =>
                row.ownerId.equals(ownerId) &
                row.source.equals(source) &
                row.sourceId.equals(sourceId),
          ))
          .getSingleOrNull();

  PlannerEntitiesCompanion _entityCompanion(PlannerEntity entity) =>
      PlannerEntitiesCompanion(
        id: Value(entity.id),
        ownerId: Value(entity.ownerId),
        kind: Value(entity.kind.wireValue),
        payloadJson: Value(jsonEncode(entity.payload)),
        revision: Value(entity.revision),
        createdAt: Value(_utc(entity.createdAt)),
        updatedAt: Value(_utc(entity.updatedAt)),
        serverCreatedAt: Value(
          entity.serverCreatedAt == null ? null : _utc(entity.serverCreatedAt!),
        ),
        serverUpdatedAt: Value(
          entity.serverUpdatedAt == null ? null : _utc(entity.serverUpdatedAt!),
        ),
        deletedAt: Value(
          entity.deletedAt == null ? null : _utc(entity.deletedAt!),
        ),
      );

  PlannerOccurrencesCompanion _occurrenceCompanion(
    PlannerOccurrence occurrence,
  ) => PlannerOccurrencesCompanion(
    id: Value(occurrence.id),
    ownerId: Value(occurrence.ownerId),
    entityId: Value(occurrence.entityId),
    plannedFor: Value(_utc(occurrence.plannedFor)),
    status: Value(occurrence.status),
    valueJson: Value(jsonEncode(occurrence.value)),
    revision: Value(occurrence.revision),
    createdAt: Value(_utc(occurrence.createdAt)),
    updatedAt: Value(_utc(occurrence.updatedAt)),
    completedAt: Value(
      occurrence.completedAt == null ? null : _utc(occurrence.completedAt!),
    ),
    missedAt: Value(
      occurrence.missedAt == null ? null : _utc(occurrence.missedAt!),
    ),
    serverUpdatedAt: Value(
      occurrence.serverUpdatedAt == null
          ? null
          : _utc(occurrence.serverUpdatedAt!),
    ),
    deletedAt: Value(
      occurrence.deletedAt == null ? null : _utc(occurrence.deletedAt!),
    ),
  );

  PlannerFocusSessionsCompanion _focusSessionCompanion(
    PlannerFocusSession session,
  ) => PlannerFocusSessionsCompanion(
    id: Value(session.id),
    ownerId: Value(session.ownerId),
    entityId: Value(session.entityId),
    mode: Value(session.mode),
    status: Value(session.status),
    payloadJson: Value(jsonEncode(session.payload)),
    revision: Value(session.revision),
    startedAt: Value(_utc(session.startedAt)),
    endedAt: Value(session.endedAt == null ? null : _utc(session.endedAt!)),
    createdAt: Value(_utc(session.createdAt)),
    updatedAt: Value(_utc(session.updatedAt)),
    serverUpdatedAt: Value(
      session.serverUpdatedAt == null ? null : _utc(session.serverUpdatedAt!),
    ),
    deletedAt: Value(
      session.deletedAt == null ? null : _utc(session.deletedAt!),
    ),
  );

  PlannerEntity _entityFromRow(PlannerEntityRow row) => PlannerEntity(
    id: row.id,
    ownerId: row.ownerId,
    kind: PlannerEntityKind.fromWire(row.kind),
    payload: safeJsonMap(row.payloadJson),
    revision: row.revision,
    createdAt: _utc(row.createdAt),
    updatedAt: _utc(row.updatedAt),
    serverCreatedAt: row.serverCreatedAt == null
        ? null
        : _utc(row.serverCreatedAt!),
    serverUpdatedAt: row.serverUpdatedAt == null
        ? null
        : _utc(row.serverUpdatedAt!),
    deletedAt: row.deletedAt == null ? null : _utc(row.deletedAt!),
  );

  PlannerOccurrence _occurrenceFromRow(PlannerOccurrenceRow row) =>
      PlannerOccurrence(
        id: row.id,
        ownerId: row.ownerId,
        entityId: row.entityId,
        plannedFor: _utc(row.plannedFor),
        status: row.status,
        value: safeJsonMap(row.valueJson),
        revision: row.revision,
        createdAt: _utc(row.createdAt),
        updatedAt: _utc(row.updatedAt),
        completedAt: row.completedAt == null ? null : _utc(row.completedAt!),
        missedAt: row.missedAt == null ? null : _utc(row.missedAt!),
        serverUpdatedAt: row.serverUpdatedAt == null
            ? null
            : _utc(row.serverUpdatedAt!),
        deletedAt: row.deletedAt == null ? null : _utc(row.deletedAt!),
      );

  PlannerFocusSession _focusSessionFromRow(PlannerFocusSessionRow row) =>
      PlannerFocusSession(
        id: row.id,
        ownerId: row.ownerId,
        entityId: row.entityId,
        mode: row.mode,
        status: row.status,
        payload: safeJsonMap(row.payloadJson),
        revision: row.revision,
        startedAt: _utc(row.startedAt),
        endedAt: row.endedAt == null ? null : _utc(row.endedAt!),
        createdAt: _utc(row.createdAt),
        updatedAt: _utc(row.updatedAt),
        serverUpdatedAt: row.serverUpdatedAt == null
            ? null
            : _utc(row.serverUpdatedAt!),
        deletedAt: row.deletedAt == null ? null : _utc(row.deletedAt!),
      );

  PlannerOutboxOperation _outboxFromRow(PlannerOutboxOperationRow row) =>
      PlannerOutboxOperation(
        localSequence: row.localSequence,
        mutationId: row.mutationId,
        ownerId: row.ownerId,
        target: PlannerOperationTarget.fromWire(row.targetType),
        targetId: row.targetId,
        entityId: row.entityId,
        entityKind: row.entityKind == null
            ? null
            : PlannerEntityKind.fromWire(row.entityKind),
        type: PlannerOperationType.fromWire(row.operationType),
        patch: PlannerFieldPatch(safeJsonMap(row.fieldPatchJson)),
        baseRevision: row.baseRevision,
        createdAt: _utc(row.createdAt),
        state: PlannerOperationState.fromWire(row.state),
        attemptCount: row.attemptCount,
        lastAttemptAt: row.lastAttemptAt == null
            ? null
            : _utc(row.lastAttemptAt!),
        lastError: row.lastError,
        acknowledgedAt: row.acknowledgedAt == null
            ? null
            : _utc(row.acknowledgedAt!),
      );

  PlannerOutboxOperation? _outboxFromNullableRow(
    PlannerOutboxOperationRow? row,
  ) => row == null ? null : _outboxFromRow(row);

  PlannerSyncMetadataValue _syncMetadataFromRow(PlannerSyncMetadataRow row) =>
      PlannerSyncMetadataValue(
        ownerId: row.ownerId,
        remoteCursor: row.remoteCursor,
        lastSyncAt: row.lastSyncAt,
        lastSuccessfulSyncAt: row.lastSuccessfulSyncAt,
        lastError: row.lastError,
      );

  PlannerSyncConflict _conflictFromRow(PlannerConflictRow row) =>
      PlannerSyncConflict(
        id: row.id,
        ownerId: row.ownerId,
        targetType: PlannerOperationTarget.fromWire(row.targetType),
        targetId: row.targetId,
        mutationId: row.mutationId,
        fieldPaths: _safeStringList(row.fieldPathsJson),
        localValue: safeJsonMap(row.localValueJson),
        remoteValue: safeJsonMap(row.remoteValueJson),
        baseRevision: row.baseRevision,
        remoteRevision: row.remoteRevision,
        status: row.status,
        createdAt: _utc(row.createdAt),
        resolvedAt: row.resolvedAt == null ? null : _utc(row.resolvedAt!),
      );
}

class PlannerImportResult {
  const PlannerImportResult({
    this.imported = 0,
    this.alreadyImported = 0,
    this.skipped = 0,
    this.wasMalformedJson = false,
  });

  final int imported;
  final int alreadyImported;
  final int skipped;
  final bool wasMalformedJson;
}

class PlannerSyncMetadataValue {
  const PlannerSyncMetadataValue({
    required this.ownerId,
    required this.remoteCursor,
    required this.lastSyncAt,
    required this.lastSuccessfulSyncAt,
    required this.lastError,
  });

  final String ownerId;
  final String? remoteCursor;
  final DateTime? lastSyncAt;
  final DateTime? lastSuccessfulSyncAt;
  final String? lastError;
}

class _ParsedLegacyItems {
  const _ParsedLegacyItems({
    required this.items,
    required this.skipped,
    required this.wasMalformedJson,
  });

  final List<_LegacyImportCandidate> items;
  final int skipped;
  final bool wasMalformedJson;
}

class _LegacyImportCandidate {
  const _LegacyImportCandidate({required this.entity, required this.sourceId});

  final PlannerEntity entity;
  final String sourceId;
}

_ParsedLegacyItems _parseLegacyItems({
  required String ownerId,
  required String rawLegacyJson,
  required DateTime fallbackNow,
  required String source,
  required Uuid uuid,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(rawLegacyJson);
  } on FormatException {
    return const _ParsedLegacyItems(
      items: <_LegacyImportCandidate>[],
      skipped: 0,
      wasMalformedJson: true,
    );
  }
  if (decoded is! List) {
    return const _ParsedLegacyItems(
      items: <_LegacyImportCandidate>[],
      skipped: 0,
      wasMalformedJson: true,
    );
  }

  final items = <_LegacyImportCandidate>[];
  var skipped = 0;
  for (final candidate in decoded) {
    final raw = safeJsonMap(candidate);
    final sourceId = safeNullableJsonString(raw['id']);
    final title = safeNullableJsonString(raw['title']);
    if (sourceId == null || title == null || title.length > 160) {
      skipped++;
      continue;
    }
    // `perfect_items` has always used UUIDs, but the local v1 cache was never
    // schema-enforced. Generate a deterministic v5 UUID for malformed legacy
    // IDs so those records still reach the v2 UUID-only RPC without creating a
    // different item on a second import.
    final id = Uuid.isValidUUID(fromString: sourceId)
        ? sourceId
        : uuid.v5(Namespace.url.value, 'perfect:$source:$ownerId:$sourceId');
    final createdAt = safeJsonDateTime(raw['created_at']) ?? fallbackNow;
    var updatedAt = safeJsonDateTime(raw['updated_at']) ?? createdAt;
    if (updatedAt.isBefore(createdAt)) updatedAt = createdAt;
    final deletedAt = safeJsonDateTime(raw['deleted_at']);
    final isDone =
        raw['is_done'] == true ||
        raw['is_done'] == 1 ||
        raw['is_done'] == 'true';
    final payload = <String, dynamic>{
      ...defaultPlannerPayload(title: title),
      if (id != sourceId) 'legacy_source_id': sourceId,
      PlannerPayloadKeys.status: isDone
          ? PlannerEntityStatus.completed.wireValue
          : PlannerEntityStatus.active.wireValue,
    };
    items.add(
      _LegacyImportCandidate(
        entity: PlannerEntity(
          id: id,
          ownerId: ownerId,
          kind: PlannerEntityKind.oneOffTask,
          payload: payload,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
        sourceId: sourceId,
      ),
    );
  }
  return _ParsedLegacyItems(
    items: List<_LegacyImportCandidate>.unmodifiable(items),
    skipped: skipped,
    wasMalformedJson: false,
  );
}

DateTime _utc(DateTime? value) => (value ?? DateTime.now()).toUtc();

void _requireOwnerId(String ownerId) {
  if (ownerId.trim().isEmpty) {
    throw ArgumentError.value(ownerId, 'ownerId', 'must not be empty');
  }
}

String _requireTitle(String value) {
  final title = value.trim();
  if (title.isEmpty || title.length > 160) {
    throw ArgumentError.value(
      value,
      'title',
      'must contain between 1 and 160 characters',
    );
  }
  return title;
}

String _requireMutationId(String value) {
  final mutationId = value.trim().toLowerCase();
  if (!Uuid.isValidUUID(fromString: mutationId)) {
    throw ArgumentError.value(value, 'mutationId', 'must be an RFC UUID');
  }
  return mutationId;
}

String _requireOccurrenceStatus(String value) {
  final status = value.trim().toLowerCase();
  const supported = <String>{'pending', 'completed', 'missed', 'partial'};
  if (!supported.contains(status)) {
    throw ArgumentError.value(
      value,
      'status',
      'must be pending, completed, missed, or partial',
    );
  }
  return status;
}

String _truncateError(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 1000) return trimmed;
  return trimmed.substring(0, 1000);
}

Map<String, dynamic> _semanticPatch(
  Map<String, dynamic> patch, {
  required PlannerOperationTarget target,
}) => Map<String, dynamic>.unmodifiable(<String, dynamic>{
  for (final entry in patch.entries)
    if (!entry.key.startsWith('/client_'))
      entry.key: entry.key == '/' && target != PlannerOperationTarget.entity
          ? _normalizeRecordMutation(entry.value)
          : _normalizeGeneratedTimestamp(entry.key, entry.value),
});

Object? _normalizeRecordMutation(Object? value) {
  if (value is! Map) return value;
  const generatedTimestamps = <String>{
    'created_at',
    'updated_at',
    'server_updated_at',
    'completed_at',
    'missed_at',
    'ended_at',
    'deleted_at',
  };
  return <String, dynamic>{
    for (final entry in value.entries)
      entry.key.toString(): generatedTimestamps.contains(entry.key)
          ? _timestampPresence(entry.value)
          : entry.value,
  };
}

Object? _normalizeGeneratedTimestamp(String path, Object? value) {
  const generatedPaths = <String>{
    '/completed_at',
    '/missed_at',
    '/ended_at',
    '/deleted_at',
  };
  return generatedPaths.contains(path) ? _timestampPresence(value) : value;
}

Object? _timestampPresence(Object? value) =>
    value == null ? null : '<generated-timestamp>';

String _canonicalJson(Object? value) => jsonEncode(_sortJson(value));

Object? _sortJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, dynamic>{
      for (final key in keys) key: _sortJson(value[key]),
    };
  }
  if (value is Iterable && value is! String) {
    return value.map(_sortJson).toList(growable: false);
  }
  return value;
}

PlannerFieldPatch _createEntityPatch(PlannerEntity entity) {
  final patch = <String, dynamic>{
    '/': entity.payload,
    '/client_created_at': entity.createdAt.toUtc().toIso8601String(),
    '/client_updated_at': entity.updatedAt.toUtc().toIso8601String(),
  };
  if (entity.deletedAt != null) {
    patch['/deleted_at'] = entity.deletedAt!.toUtc().toIso8601String();
  }
  return PlannerFieldPatch(patch);
}

List<String> _safeStringList(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Iterable) return const <String>[];
    return List<String>.unmodifiable(
      decoded
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
  } on FormatException {
    return const <String>[];
  }
}
