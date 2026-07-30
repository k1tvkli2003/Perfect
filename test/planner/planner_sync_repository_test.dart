import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';

const _snapshotOwnerId = 'owner-a';

void main() {
  const ownerId = 'owner-a';
  const deviceId = '11111111-1111-4111-8111-111111111111';
  late PlannerDatabase database;
  late PlannerLocalStore store;

  setUp(() {
    database = PlannerDatabase(NativeDatabase.memory());
    store = PlannerLocalStore(database);
  });

  tearDown(() => store.close());

  test(
    'pushes a local task through the RPC envelope and applies its ack',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Ship the local-first sync',
        mutationId: '22222222-2222-4222-8222-222222222222',
        now: DateTime.utc(2026, 7, 27, 10),
      );
      final remote = _FakeGateway(
        onApply: (mutation) {
          expect(mutation.entityKind, 'one_off_task');
          expect(mutation.operationType, 'upsert');
          expect(mutation.fieldPaths, contains('/'));
          expect(mutation.patch['title'], 'Ship the local-first sync');
          expect(
            (mutation.patch['payload'] as Map<String, dynamic>)['title'],
            'Ship the local-first sync',
          );
          return PlannerRemoteMutationResult.fromJson(
            _entitySnapshot(
              id: mutation.entityId,
              title: 'Ship the local-first sync',
              revision: 1,
            ),
          );
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      await repository.syncNow();

      expect(await store.listPendingOperations(ownerId), isEmpty);
      final acknowledged = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(acknowledged!.revision, 1);
      expect(acknowledged.title, 'Ship the local-first sync');
      expect(repository.syncStatus.value.phase, PlannerSyncPhase.idle);
      await repository.dispose();
    },
  );

  test(
    'pull projects a remote change but never overwrites a dirty local row',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Local draft',
        mutationId: '33333333-3333-4333-8333-333333333333',
        now: DateTime.utc(2026, 7, 27, 11),
      );
      final remote = _FakeGateway(
        changes: <PlannerRemoteChange>[
          PlannerRemoteChange(
            changeId: 7,
            snapshot:
                _entitySnapshot(
                      id: created.entity!.id,
                      title: 'Remote edit',
                      revision: 2,
                    )['entity']
                    as Map<String, dynamic>,
          ),
        ],
        onApply: (mutation) => PlannerRemoteMutationResult.fromJson(
          _entitySnapshot(
            id: mutation.entityId,
            title: 'Local draft',
            revision: 3,
          ),
        ),
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      await repository.syncNow();

      final current = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(current!.title, 'Local draft');
      expect(current.revision, 3);
      expect(await store.listPendingOperations(ownerId), isEmpty);
      final metadata = await store.readSyncMetadata(ownerId);
      expect(metadata!.remoteCursor, '7');
      await repository.dispose();
    },
  );

  test(
    'records a true conflict and replaces the optimistic projection safely',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'My local version',
        mutationId: '44444444-4444-4444-8444-444444444444',
      );
      final remote = _FakeGateway(
        onApply: (mutation) =>
            PlannerRemoteMutationResult.fromJson(<String, dynamic>{
              'status': 'conflict',
              'conflict_id': '55555555-5555-4555-8555-555555555555',
              'current_revision': 5,
              'conflicting_paths': <String>['/'],
              'entity': _entitySnapshot(
                id: mutation.entityId,
                title: 'Authoritative remote version',
                revision: 5,
              )['entity'],
            }),
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      await repository.syncNow();

      expect(await store.listPendingOperations(ownerId), isEmpty);
      final current = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(current!.title, 'Authoritative remote version');
      final conflicts = await store.listConflicts(ownerId, status: 'open');
      expect(conflicts, hasLength(1));
      expect(conflicts.single.fieldPaths, <String>['/']);
      expect(conflicts.single.localValue['/'], isA<Map<String, dynamic>>());
      await repository.dispose();
    },
  );

  test(
    'sends an explicit restore operation after an archived task is restored',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Recover this task safely',
        mutationId: '66666666-6666-4666-8666-666666666666',
        now: DateTime.utc(2026, 7, 27, 12),
      );
      var revision = 0;
      final remoteOperationTypes = <String>[];
      final remote = _FakeGateway(
        onApply: (mutation) {
          remoteOperationTypes.add(mutation.operationType);
          return PlannerRemoteMutationResult.fromJson(
            _entitySnapshot(
              id: mutation.entityId,
              title: 'Recover this task safely',
              revision: ++revision,
              deletedAt: mutation.operationType == 'soft_delete'
                  ? '2026-07-27T12:30:00.000Z'
                  : null,
            ),
          );
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      await repository.syncNow();
      await store.softDeleteEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        now: DateTime.utc(2026, 7, 27, 12, 30),
      );
      await repository.syncNow();
      await store.restoreEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        now: DateTime.utc(2026, 7, 27, 13),
      );
      await repository.syncNow();

      expect(remoteOperationTypes, <String>[
        'upsert',
        'soft_delete',
        'restore',
      ]);
      expect(await store.listPendingOperations(ownerId), isEmpty);
      final restored = await store.readEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
      );
      expect(restored, isNotNull);
      expect(restored!.isDeleted, isFalse);
      expect(restored.revision, 3);
      await repository.dispose();
    },
  );

  test(
    'queued entity mutations serialize their own snapshot, not the latest row',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Original queued title',
        mutationId: '77777777-7777-4777-8777-777777777777',
        now: DateTime.utc(2026, 7, 27, 14),
      );
      await store.completeEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        mutationId: '88888888-8888-4888-8888-888888888888',
        now: DateTime.utc(2026, 7, 27, 14, 1),
      );
      final sent = <PlannerRemoteMutation>[];
      var revision = 0;
      final remote = _FakeGateway(
        onApply: (mutation) {
          sent.add(mutation);
          return PlannerRemoteMutationResult.fromJson(
            _snapshotForMutation(mutation, revision: ++revision),
          );
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      await repository.syncNow();

      expect(sent, hasLength(2));
      expect(sent.first.patch['title'], 'Original queued title');
      expect(sent.first.patch['lifecycle_state'], 'active');
      expect(sent.last.patch.containsKey('title'), isFalse);
      expect(sent.last.patch['lifecycle_state'], 'completed');
      expect(sent.last.baseRevision, 1);
      await repository.dispose();
    },
  );

  test(
    'occurrence outcome remains payload data while lifecycle stays server-owned',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Daily outcome',
        mutationId: '99999999-9999-4999-8999-999999999999',
      );
      final sent = <PlannerRemoteMutation>[];
      var revision = 0;
      final remote = _FakeGateway(
        onApply: (mutation) {
          sent.add(mutation);
          return PlannerRemoteMutationResult.fromJson(
            _snapshotForMutation(mutation, revision: ++revision),
          );
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );
      await repository.syncNow();
      await store.appendOccurrence(
        ownerId: ownerId,
        entityId: created.entity!.id,
        occurrenceId: 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa',
        plannedFor: DateTime.utc(2026, 7, 27, 16),
        status: 'partial',
        value: const <String, dynamic>{'percent': 50},
        mutationId: 'aaaaaaaa-2222-4222-8222-aaaaaaaaaaaa',
      );

      await repository.syncNow();

      final occurrence = sent.singleWhere(
        (mutation) => mutation.entityKind == 'occurrence',
      );
      expect(occurrence.patch.containsKey('lifecycle_state'), isFalse);
      expect(
        (occurrence.patch['payload'] as Map<String, dynamic>)['status'],
        'partial',
      );
      expect(
        (occurrence.patch['payload'] as Map<String, dynamic>)['value'],
        <String, dynamic>{'percent': 50},
      );
      await repository.dispose();
    },
  );

  test(
    'a conflict never rebases a later local mutation behind the owner',
    () async {
      final created = await store.createQuickTask(
        ownerId: ownerId,
        title: 'Conflicting sequence',
        mutationId: 'bbbbbbbb-1111-4111-8111-bbbbbbbbbbbb',
      );
      await store.completeEntity(
        ownerId: ownerId,
        entityId: created.entity!.id,
        mutationId: 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb',
      );
      var call = 0;
      final remote = _FakeGateway(
        onApply: (mutation) {
          call++;
          if (call == 1) {
            return PlannerRemoteMutationResult.fromJson(<String, dynamic>{
              'status': 'conflict',
              'conflict_id': 'bbbbbbbb-3333-4333-8333-bbbbbbbbbbbb',
              'current_revision': 5,
              'conflicting_paths': <String>['/'],
              'entity':
                  _entitySnapshot(
                        id: mutation.entityId,
                        title: 'Remote branch',
                        revision: 5,
                      )['entity']
                      as Map<String, dynamic>,
            });
          }
          throw const SocketException('network stopped after conflict');
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      await repository.syncNow();

      final pending = await store.listPendingOperations(ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.mutationId, 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb');
      expect(pending.single.baseRevision, 0);
      expect(await store.listConflicts(ownerId, status: 'open'), hasLength(1));
      await repository.dispose();
    },
  );

  test(
    'a snapshot without an explicit owner never advances the durable cursor',
    () async {
      final snapshot =
          _entitySnapshot(
                id: 'cccccccc-1111-4111-8111-cccccccccccc',
                title: 'Ownerless remote row',
                revision: 1,
              )['entity']
              as Map<String, dynamic>;
      snapshot.remove('owner_id');
      final remote = _FakeGateway(
        changes: <PlannerRemoteChange>[
          PlannerRemoteChange(changeId: 1, snapshot: snapshot),
        ],
        onApply: (_) => throw StateError('No push was expected.'),
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      await repository.syncNow();

      expect(
        repository.syncStatus.value.phase,
        PlannerSyncPhase.needsAttention,
      );
      final metadata = await store.readSyncMetadata(ownerId);
      expect(metadata!.remoteCursor, isNull);
      expect(metadata.lastSuccessfulSyncAt, isNull);
      await repository.dispose();
    },
  );

  test(
    'a sync request arriving mid-flight is drained before completion',
    () async {
      await store.createQuickTask(
        ownerId: ownerId,
        title: 'First mutation',
        mutationId: 'dddddddd-1111-4111-8111-dddddddddddd',
      );
      final finalPullEntered = Completer<void>();
      final releaseFinalPull = Completer<void>();
      var applyCalls = 0;
      var pullCalls = 0;
      final remote = _FakeGateway(
        onApply: (mutation) {
          applyCalls++;
          return PlannerRemoteMutationResult.fromJson(
            _snapshotForMutation(mutation, revision: 1),
          );
        },
        onPull: ({required afterChangeId, required limit}) async {
          pullCalls++;
          if (pullCalls == 2) {
            finalPullEntered.complete();
            await releaseFinalPull.future;
          }
          return PlannerRemoteChangePage(
            changes: const <PlannerRemoteChange>[],
            requestedLimit: limit,
          );
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
      );

      final active = repository.syncNow();
      await finalPullEntered.future;
      await store.createQuickTask(
        ownerId: ownerId,
        title: 'Arrived during sync',
        mutationId: 'dddddddd-2222-4222-8222-dddddddddddd',
      );
      final coalesced = repository.syncNow();
      releaseFinalPull.complete();
      await Future.wait(<Future<void>>[active, coalesced]);

      expect(applyCalls, 2);
      expect(await store.listPendingOperations(ownerId), isEmpty);
      await repository.dispose();
    },
  );

  test('connectivity failures retry with bounded backoff', () async {
    var pullCalls = 0;
    final remote = _FakeGateway(
      onApply: (_) => throw StateError('No push was expected.'),
      onPull: ({required afterChangeId, required limit}) {
        pullCalls++;
        if (pullCalls == 1) {
          throw const SocketException('network unavailable');
        }
        return PlannerRemoteChangePage(
          changes: const <PlannerRemoteChange>[],
          requestedLimit: limit,
        );
      },
    );
    final repository = PlannerSyncRepository(
      store,
      remote,
      ownerId: ownerId,
      deviceId: deviceId,
      retryBaseDelay: const Duration(milliseconds: 10),
      retryMaxDelay: const Duration(milliseconds: 10),
    );

    await repository.syncNow();
    expect(repository.syncStatus.value.phase, PlannerSyncPhase.offline);
    await _waitUntil(
      () => repository.syncStatus.value.phase == PlannerSyncPhase.idle,
    );

    expect(pullCalls, greaterThanOrEqualTo(3));
    expect(
      (await store.readSyncMetadata(ownerId))!.lastSuccessfulSyncAt,
      isNotNull,
    );
    await repository.dispose();
  });

  test(
    'non-connectivity failures retain red phase and recover with capped backoff',
    () async {
      final retryScheduler = _ControlledRetryScheduler();
      var failuresRemaining = 3;
      var pullCalls = 0;
      final remote = _FakeGateway(
        onApply: (_) => throw StateError('No push was expected.'),
        onPull: ({required afterChangeId, required limit}) {
          pullCalls++;
          if (failuresRemaining > 0) {
            failuresRemaining--;
            throw const FormatException('transient malformed server response');
          }
          return PlannerRemoteChangePage(
            changes: const <PlannerRemoteChange>[],
            requestedLimit: limit,
          );
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
        retryBaseDelay: const Duration(milliseconds: 10),
        retryMaxDelay: const Duration(milliseconds: 25),
        retryTimerFactory: retryScheduler.schedule,
      );

      await repository.syncNow();
      expect(
        repository.syncStatus.value.phase,
        PlannerSyncPhase.needsAttention,
      );
      expect(retryScheduler.delays, const <Duration>[
        Duration(milliseconds: 10),
      ]);

      retryScheduler.fireNext();
      await _waitUntil(() => pullCalls == 2);
      expect(
        repository.syncStatus.value.phase,
        PlannerSyncPhase.needsAttention,
      );
      expect(retryScheduler.delays.last, const Duration(milliseconds: 20));

      retryScheduler.fireNext();
      await _waitUntil(() => pullCalls == 3);
      expect(
        repository.syncStatus.value.phase,
        PlannerSyncPhase.needsAttention,
      );
      expect(retryScheduler.delays.last, const Duration(milliseconds: 25));

      retryScheduler.fireNext();
      await _waitUntil(
        () => repository.syncStatus.value.phase == PlannerSyncPhase.idle,
      );
      expect(pullCalls, 5, reason: 'A successful sync pulls before and after.');

      failuresRemaining = 1;
      await repository.syncNow();
      expect(
        repository.syncStatus.value.phase,
        PlannerSyncPhase.needsAttention,
      );
      expect(
        retryScheduler.delays.last,
        const Duration(milliseconds: 10),
        reason: 'A successful sync resets the consecutive-failure backoff.',
      );
      await repository.dispose();
    },
  );

  test('offline retry is cancelled by a coalesced manual recovery', () async {
    final retryScheduler = _ControlledRetryScheduler();
    var offline = true;
    var pullCalls = 0;
    final remote = _FakeGateway(
      onApply: (_) => throw StateError('No push was expected.'),
      onPull: ({required afterChangeId, required limit}) {
        pullCalls++;
        if (offline) throw const SocketException('network unavailable');
        return PlannerRemoteChangePage(
          changes: const <PlannerRemoteChange>[],
          requestedLimit: limit,
        );
      },
    );
    final repository = PlannerSyncRepository(
      store,
      remote,
      ownerId: ownerId,
      deviceId: deviceId,
      retryTimerFactory: retryScheduler.schedule,
    );

    await repository.syncNow();
    expect(repository.syncStatus.value.phase, PlannerSyncPhase.offline);
    expect(retryScheduler.activeCount, 1);

    offline = false;
    final first = repository.syncNow();
    final coalesced = repository.syncNow();
    expect(identical(first, coalesced), isTrue);
    expect(retryScheduler.activeCount, 0);
    await Future.wait(<Future<void>>[first, coalesced]);

    expect(repository.syncStatus.value.phase, PlannerSyncPhase.idle);
    expect(
      pullCalls,
      5,
      reason:
          'Concurrent manual requests share one future and drain one extra pass.',
    );
    await repository.dispose();
  });

  test(
    'dispose cancels a pending retry and prevents late remote work',
    () async {
      final retryScheduler = _ControlledRetryScheduler();
      var pullCalls = 0;
      final remote = _FakeGateway(
        onApply: (_) => throw StateError('No push was expected.'),
        onPull: ({required afterChangeId, required limit}) {
          pullCalls++;
          throw StateError('temporary service rejection');
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: ownerId,
        deviceId: deviceId,
        retryTimerFactory: retryScheduler.schedule,
      );

      await repository.syncNow();
      expect(retryScheduler.activeCount, 1);
      await repository.dispose();
      expect(retryScheduler.activeCount, 0);

      retryScheduler.fireAll();
      await Future<void>.delayed(Duration.zero);
      expect(pullCalls, 1);
    },
  );
}

Map<String, dynamic> _entitySnapshot({
  required String id,
  required String title,
  required int revision,
  String? deletedAt,
}) => <String, dynamic>{
  'status': 'acknowledged',
  'entity': <String, dynamic>{
    'id': id,
    'owner_id': _snapshotOwnerId,
    'kind': 'one_off_task',
    'title': title,
    'lifecycle_state': 'active',
    'payload': <String, dynamic>{
      PlannerPayloadKeys.title: title,
      PlannerPayloadKeys.status: 'active',
    },
    'revision': revision,
    'created_at': '2026-07-27T10:00:00.000Z',
    'updated_at': '2026-07-27T10:00:00.000Z',
    'deleted_at': deletedAt,
  },
};

Map<String, dynamic> _snapshotForMutation(
  PlannerRemoteMutation mutation, {
  required int revision,
}) {
  final payload = Map<String, dynamic>.from(
    mutation.patch['payload'] as Map? ?? const <String, dynamic>{},
  );
  final title =
      mutation.patch['title']?.toString() ??
      payload[PlannerPayloadKeys.title]?.toString() ??
      '';
  return <String, dynamic>{
    'status': 'acknowledged',
    'entity': <String, dynamic>{
      'id': mutation.entityId,
      'owner_id': _snapshotOwnerId,
      'kind': mutation.entityKind,
      'title': title,
      'lifecycle_state':
          mutation.patch['lifecycle_state']?.toString() ?? 'active',
      'payload': payload,
      'revision': revision,
      'created_at': '2026-07-27T10:00:00.000Z',
      'updated_at': '2026-07-27T10:00:00.000Z',
      'deleted_at': null,
    },
  };
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Timed out waiting for planner sync state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _FakeGateway implements PlannerRemoteGateway {
  _FakeGateway({
    this.changes = const <PlannerRemoteChange>[],
    required this.onApply,
    this.onPull,
  });

  final List<PlannerRemoteChange> changes;
  final FutureOr<PlannerRemoteMutationResult> Function(
    PlannerRemoteMutation mutation,
  )
  onApply;
  final FutureOr<PlannerRemoteChangePage> Function({
    required int afterChangeId,
    required int limit,
  })?
  onPull;
  bool _didReturnChanges = false;

  @override
  Future<PlannerRemoteMutationResult> apply(
    PlannerRemoteMutation mutation,
  ) async => onApply(mutation);

  @override
  Future<void> dispose() => Future<void>.value();

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async {
    final handler = onPull;
    if (handler != null) {
      return handler(afterChangeId: afterChangeId, limit: limit);
    }
    if (_didReturnChanges || changes.isEmpty) {
      return PlannerRemoteChangePage(
        changes: const <PlannerRemoteChange>[],
        requestedLimit: limit,
      );
    }
    _didReturnChanges = true;
    return PlannerRemoteChangePage(changes: changes, requestedLimit: limit);
  }

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() =>
      Future<List<Map<String, dynamic>>>.value(const <Map<String, dynamic>>[]);

  @override
  Future<void> subscribe(void Function() onChangeHint) => Future<void>.value();
}

class _ControlledRetryScheduler {
  final List<Duration> delays = <Duration>[];
  final List<_ControlledTimer> _timers = <_ControlledTimer>[];

  int get activeCount => _timers.where((timer) => timer.isActive).length;

  Timer schedule(Duration delay, void Function() callback) {
    delays.add(delay);
    final timer = _ControlledTimer(callback);
    _timers.add(timer);
    return timer;
  }

  void fireNext() {
    _timers.firstWhere((timer) => timer.isActive).fire();
  }

  void fireAll() {
    for (final timer in _timers.toList(growable: false)) {
      timer.fire();
    }
  }
}

class _ControlledTimer implements Timer {
  _ControlledTimer(this._callback);

  final void Function() _callback;
  bool _active = true;
  int _tick = 0;

  void fire() {
    if (!_active) return;
    _active = false;
    _tick++;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;
}
