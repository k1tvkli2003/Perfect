import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:uuid/uuid.dart';

/// The shared outcome model for task controls in the Flutter app and Android
/// home-screen widget. These are task outcomes, not lifecycle states: archive
/// and cancellation remain separate and recoverable.
enum PlannerTaskProgressState {
  pending('pending'),
  completed('completed'),
  missed('missed'),
  partial('partial');

  const PlannerTaskProgressState(this.wireValue);

  final String wireValue;

  static PlannerTaskProgressState fromWire(Object? value) =>
      PlannerTaskProgressState.values.firstWhere(
        (state) => state.wireValue == value,
        orElse: () => PlannerTaskProgressState.pending,
      );

  /// Empty → done → not done → partial → empty. The order keeps the two most
  /// common one-tap choices adjacent while still making deliberate progress
  /// visible without opening the editor.
  PlannerTaskProgressState get next => switch (this) {
    PlannerTaskProgressState.pending => PlannerTaskProgressState.completed,
    PlannerTaskProgressState.completed => PlannerTaskProgressState.missed,
    PlannerTaskProgressState.missed => PlannerTaskProgressState.partial,
    PlannerTaskProgressState.partial => PlannerTaskProgressState.pending,
  };

  String get occurrenceStatus => switch (this) {
    PlannerTaskProgressState.pending => 'pending',
    PlannerTaskProgressState.completed => 'completed',
    PlannerTaskProgressState.missed => 'missed',
    PlannerTaskProgressState.partial => 'partial',
  };
}

/// Immutable value used for rendering, storage patches, native widget JSON and
/// replay-safe widget actions.
class PlannerTaskProgress {
  const PlannerTaskProgress({required this.state, required this.percent});

  const PlannerTaskProgress.pending()
    : state = PlannerTaskProgressState.pending,
      percent = 0;

  final PlannerTaskProgressState state;
  final int percent;

  bool get isComplete => state == PlannerTaskProgressState.completed;
  bool get isMissed => state == PlannerTaskProgressState.missed;
  bool get isPartial => state == PlannerTaskProgressState.partial;

  PlannerTaskProgress get next {
    final nextState = state.next;
    return PlannerTaskProgress(
      state: nextState,
      // Entering the partial state from a binary outcome needs a useful,
      // intentional default. Once the owner customises the percentage, that
      // value remains intact while the state itself is partial.
      percent: switch (nextState) {
        PlannerTaskProgressState.completed => 100,
        PlannerTaskProgressState.missed ||
        PlannerTaskProgressState.pending => 0,
        PlannerTaskProgressState.partial => 50,
      },
    );
  }

  PlannerTaskProgress get normalized =>
      PlannerTaskProgress(state: state, percent: _percentFor(state, percent));

  PlannerTaskProgress copyWith({
    PlannerTaskProgressState? state,
    int? percent,
  }) {
    final resolvedState = state ?? this.state;
    return PlannerTaskProgress(
      state: resolvedState,
      percent: _percentFor(resolvedState, percent ?? this.percent),
    );
  }

  factory PlannerTaskProgress.fromEntity(PlannerEntity entity) {
    if (entity.status == PlannerEntityStatus.completed) {
      return const PlannerTaskProgress(
        state: PlannerTaskProgressState.completed,
        percent: 100,
      );
    }
    final state = PlannerTaskProgressState.fromWire(
      entity.payload[PlannerPayloadKeys.taskProgressState],
    );
    return PlannerTaskProgress(
      state: state,
      percent: _percentFor(
        state,
        safeJsonInt(
          entity.payload[PlannerPayloadKeys.taskProgressPercent],
          fallback: state == PlannerTaskProgressState.partial ? 50 : 0,
        ),
      ),
    );
  }

  factory PlannerTaskProgress.fromOccurrence(PlannerOccurrence? occurrence) {
    if (occurrence == null) return const PlannerTaskProgress.pending();
    final state = switch (occurrence.status) {
      'completed' => PlannerTaskProgressState.completed,
      'missed' => PlannerTaskProgressState.missed,
      'partial' => PlannerTaskProgressState.partial,
      _ => PlannerTaskProgressState.pending,
    };
    return PlannerTaskProgress(
      state: state,
      percent: _percentFor(
        state,
        safeJsonInt(
          occurrence.value[PlannerPayloadKeys.taskProgressPercent],
          fallback: state == PlannerTaskProgressState.partial ? 50 : 0,
        ),
      ),
    );
  }

  Map<String, dynamic> applyToPayload(Map<String, dynamic> payload) =>
      <String, dynamic>{
        ...payload,
        PlannerPayloadKeys.status: state == PlannerTaskProgressState.completed
            ? PlannerEntityStatus.completed.wireValue
            : PlannerEntityStatus.active.wireValue,
        PlannerPayloadKeys.taskProgressState: state.wireValue,
        PlannerPayloadKeys.taskProgressPercent: percent,
      };

  Map<String, dynamic> applyToOccurrenceValue(Map<String, dynamic> value) =>
      <String, dynamic>{
        ...value,
        PlannerPayloadKeys.taskProgressPercent: percent,
      };

  @override
  bool operator ==(Object other) =>
      other is PlannerTaskProgress &&
      other.state == state &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(state, percent);

  static int _percentFor(PlannerTaskProgressState state, int value) =>
      switch (state) {
        PlannerTaskProgressState.completed => 100,
        PlannerTaskProgressState.missed ||
        PlannerTaskProgressState.pending => 0,
        PlannerTaskProgressState.partial => value.clamp(1, 99).toInt(),
      };
}

/// A versioned, idempotent command emitted by the Android widget. The native
/// side uses the exact wire values below and stores a bounded replay queue;
/// replaying the same [id] is harmless because it is the local outbox ID.
class PlannerWidgetTaskAction {
  const PlannerWidgetTaskAction({
    required this.id,
    required this.ownerId,
    required this.entityId,
    required this.kind,
    required this.progress,
    required this.localDay,
    required this.occurredAt,
    this.queueSequence = 0,
  });

  final String id;
  final String ownerId;
  final String entityId;
  final PlannerEntityKind kind;
  final PlannerTaskProgress progress;
  final DateTime localDay;
  final DateTime occurredAt;
  final int queueSequence;

  int compareReplayOrder(PlannerWidgetTaskAction other) {
    final byTime = occurredAt.compareTo(other.occurredAt);
    if (byTime != 0) return byTime;
    final bySequence = queueSequence.compareTo(other.queueSequence);
    if (bySequence != 0) return bySequence;
    return id.compareTo(other.id);
  }

  factory PlannerWidgetTaskAction.fromJson(Map<String, dynamic> json) {
    final actionId = safeJsonString(json['id'], fallback: '');
    if (!Uuid.isValidUUID(fromString: actionId)) {
      throw const FormatException('Widget action id must be a UUID.');
    }
    final ownerId = safeJsonString(json['owner_id'], fallback: '');
    final entityId = safeJsonString(json['entity_id'], fallback: '');
    if (ownerId.isEmpty || entityId.isEmpty) {
      throw const FormatException(
        'Widget action is missing its owner or task.',
      );
    }
    final localDay = _readLocalDay(json['local_day']);
    final occurredAt = safeJsonDateTime(json['occurred_at']);
    if (localDay == null || occurredAt == null) {
      throw const FormatException(
        'Widget action is missing a valid timestamp.',
      );
    }
    final state = PlannerTaskProgressState.fromWire(json['state']);
    return PlannerWidgetTaskAction(
      id: actionId.toLowerCase(),
      ownerId: ownerId,
      entityId: entityId,
      kind: PlannerEntityKind.fromWire(json['kind']),
      progress: PlannerTaskProgress(
        state: state,
        percent: safeJsonInt(
          json['progress_percent'],
          fallback: state == PlannerTaskProgressState.partial ? 50 : 0,
        ),
      ),
      localDay: localDay.toLocal(),
      occurredAt: occurredAt.toUtc(),
      queueSequence: safeJsonInt(
        json['queue_sequence'],
        fallback: 0,
      ).clamp(0, 0x7fffffffffffffff).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'owner_id': ownerId,
    'entity_id': entityId,
    'kind': kind.wireValue,
    'state': progress.state.wireValue,
    'progress_percent': progress.percent,
    'local_day': localDateKey(localDay),
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'queue_sequence': queueSequence,
  };
}

DateTime? _readLocalDay(Object? value) {
  if (value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    final parts = value.split('-').map(int.tryParse).toList(growable: false);
    if (parts.length == 3 && parts.every((part) => part != null)) {
      return DateTime(parts[0]!, parts[1]!, parts[2]!);
    }
  }
  final parsed = safeJsonDateTime(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// The sole mutation owner for the four-state task outcome. Both Flutter UI
/// and the Android widget call this service, so they cannot drift into two
/// incompatible completion semantics.
class PlannerTaskProgressService {
  PlannerTaskProgressService(
    this._store, {
    required this.ownerId,
    DateTime Function()? now,
    Uuid? uuid,
  }) : _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final PlannerLocalStore _store;
  final String ownerId;
  final DateTime Function() _now;
  final Uuid _uuid;

  Future<PlannerTaskProgress> readProgress(
    PlannerEntity entity, {
    DateTime? localDay,
  }) async {
    if (entity.kind == PlannerEntityKind.oneOffTask) {
      return PlannerTaskProgress.fromEntity(entity);
    }
    if (entity.kind != PlannerEntityKind.recurringTask) {
      return const PlannerTaskProgress.pending();
    }
    final day = _day(localDay ?? _now().toLocal());
    return PlannerTaskProgress.fromOccurrence(
      await _store.readOccurrence(
        ownerId: ownerId,
        occurrenceId: recurringOccurrenceId(entity, day),
      ),
    );
  }

  Future<PlannerTaskProgress> cycle(
    PlannerEntity entity, {
    String? mutationId,
    DateTime? localDay,
    String source = 'app',
  }) async {
    final current = await _store.readEntity(
      ownerId: ownerId,
      entityId: entity.id,
    );
    if (current == null) {
      throw StateError('Task is no longer available locally.');
    }
    final currentProgress = await readProgress(current, localDay: localDay);
    return setProgress(
      current,
      progress: currentProgress.next,
      mutationId: mutationId,
      localDay: localDay,
      source: source,
    );
  }

  Future<PlannerTaskProgress> setProgress(
    PlannerEntity entity, {
    required PlannerTaskProgress progress,
    String? mutationId,
    DateTime? localDay,
    String source = 'app',
  }) async {
    if (entity.kind != PlannerEntityKind.oneOffTask &&
        entity.kind != PlannerEntityKind.recurringTask) {
      throw UnsupportedError('Only task kinds have a four-state outcome.');
    }
    final now = _now().toUtc();
    final normalized = progress.normalized;
    final stableMutationId = mutationId ?? _uuid.v4();
    if (entity.kind == PlannerEntityKind.oneOffTask) {
      final payload = normalized.applyToPayload(entity.payload);
      await _store.upsertEntity(
        entity: entity.copyWith(payload: payload, updatedAt: now),
        now: now,
        mutationId: stableMutationId,
        patch: PlannerFieldPatch(<String, dynamic>{
          '/${PlannerPayloadKeys.status}': payload[PlannerPayloadKeys.status],
          '/${PlannerPayloadKeys.taskProgressState}':
              normalized.state.wireValue,
          '/${PlannerPayloadKeys.taskProgressPercent}': normalized.percent,
          '/completed_at': normalized.isComplete ? now.toIso8601String() : null,
        }),
      );
      return normalized;
    }

    final day = _day(localDay ?? _now().toLocal());
    final occurrenceId = recurringOccurrenceId(entity, day);
    final existing = await _store.readOccurrence(
      ownerId: ownerId,
      occurrenceId: occurrenceId,
    );
    await _store.appendOccurrence(
      ownerId: ownerId,
      entityId: entity.id,
      occurrenceId: occurrenceId,
      plannedFor: plannedTimeForDay(entity, day),
      status: normalized.state.occurrenceStatus,
      value: normalized.applyToOccurrenceValue(<String, dynamic>{
        ...?existing?.value,
        'source': source,
      }),
      now: now,
      mutationId: stableMutationId,
    );
    return normalized;
  }

  Future<PlannerTaskProgress> applyWidgetAction(
    PlannerWidgetTaskAction action,
  ) async {
    if (action.ownerId != ownerId) {
      throw StateError('Widget action belongs to another private owner.');
    }
    final entity = await _store.readEntity(
      ownerId: ownerId,
      entityId: action.entityId,
    );
    if (entity == null || entity.kind != action.kind) {
      throw StateError('Widget task no longer matches its local record.');
    }
    return setProgress(
      entity,
      progress: action.progress,
      mutationId: action.id,
      localDay: action.localDay,
      source: 'android_widget',
    );
  }

  static String recurringOccurrenceId(
    PlannerEntity entity,
    DateTime localDay,
  ) => const Uuid().v5(
    Namespace.url.value,
    'perfect:recurring-occurrence:${entity.ownerId}:${entity.id}:${localDateKey(localDay)}',
  );

  static DateTime plannedTimeForDay(PlannerEntity entity, DateTime localDay) {
    final scheduled = entity.scheduledAt?.toLocal();
    return DateTime(
      localDay.year,
      localDay.month,
      localDay.day,
      scheduled?.hour ?? 12,
      scheduled?.minute ?? 0,
    ).toUtc();
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

String localDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
