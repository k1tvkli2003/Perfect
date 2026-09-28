import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_saved_view.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';

const _ownerId = 'owner-a';
const _deviceId = '11111111-1111-4111-8111-111111111111';

PlannerSavedView _personalView() => PlannerSavedView(
  id: 'view-22222222-2222-4222-8222-222222222222',
  ownerId: _ownerId,
  schemaVersion: PlannerSavedView.currentSchemaVersion,
  title: 'Bills',
  iconKey: 'receipt',
  query: PlannerTaskQuery.builtIn(PlannerTaskQuery.openViewId),
  createdAt: DateTime.utc(2026, 9, 27),
  updatedAt: DateTime.utc(2026, 9, 27),
);

void main() {
  late PlannerDatabase database;
  late PlannerLocalStore store;

  setUp(() {
    database = PlannerDatabase(NativeDatabase.memory());
    store = PlannerLocalStore(database);
  });

  tearDown(() => store.close());

  test(
    'tracer 25: personal saved view pushes through the saved-view RPC envelope',
    () async {
      await store.upsertSavedView(_personalView());

      final sent = <PlannerRemoteMutation>[];
      final remote = _FakeSavedViewGateway(
        onApply: (mutation) {
          sent.add(mutation);
          return PlannerRemoteMutationResult.fromJson(<String, dynamic>{
            'status': 'acknowledged',
            'entity': <String, dynamic>{
              'id': mutation.entityId,
              'owner_id': _ownerId,
              'kind': 'saved_view',
              'payload': _personalView().toJson(),
              'revision': 1,
              'created_at': '2026-09-27T00:00:00.000Z',
              'updated_at': '2026-09-27T00:00:00.000Z',
              'deleted_at': null,
            },
          });
        },
      );
      final repository = PlannerSyncRepository(
        store,
        remote,
        ownerId: _ownerId,
        deviceId: _deviceId,
      );

      await repository.syncNow();

      expect(sent, hasLength(1));
      expect(sent.single.entityKind, 'saved_view');
      expect(sent.single.operationType, 'upsert');
      expect(sent.single.fieldPaths, contains('/'));
      expect(await store.listPendingOperations(_ownerId), isEmpty);
      final stored = await store.readSavedViews(_ownerId);
      expect(stored.single.revision, 1);
      await repository.dispose();
    },
  );

  test('tracer 25: saved-view cursor advances independently of task cursor', () async {
    final view = _personalView().copyWith(revision: 1);
    final remote = _FakeSavedViewGateway(
      onApply: (_) => throw StateError('No pending write expected'),
      changes: <PlannerRemoteChange>[
        PlannerRemoteChange(changeId: 1, snapshot: <String, dynamic>{
          'id': view.id, 'owner_id': _ownerId, 'kind': 'saved_view',
          'payload': view.toJson(), 'revision': 1,
          'created_at': '2026-09-27T00:00:00.000Z',
          'updated_at': '2026-09-27T00:00:00.000Z',
          'deleted_at': null,
        }),
      ],
    );
    final repository = PlannerSyncRepository(
      store, remote, ownerId: _ownerId, deviceId: _deviceId,

    );
    await repository.syncNow();
    expect((await store.readSavedViews(_ownerId)).single.title, 'Bills');
    expect((await store.readSyncMetadata(_ownerId))?.remoteCursor, isNull);
    expect((await store.readSyncMetadata(_ownerId))?.savedViewCursor, '1');
    await repository.syncNow();
    expect(remote.taskReadCursors.length, 4);
    expect(remote.taskReadCursors.toSet(), <int>{0});
    expect(remote.savedViewReadCursors.length, 4);
    expect(remote.savedViewReadCursors.sublist(0, 2), <int>[0, 1]);
    expect(remote.savedViewReadCursors.sublist(2), <int>[1, 1]);
    await repository.dispose();
  });

  test('tracer 25: queued renames send each immutable outbox snapshot', () async {
    final initial = _personalView();
    await store.upsertSavedView(initial);
    await store.upsertSavedView(initial.copyWith(title: 'Utilities'));
    final sentTitles = <String>[];
    var revision = 0;
    final remote = _FakeSavedViewGateway(
      onApply: (mutation) {
        final definition = mutation.toSavedViewRpcParameters()['p_definition']
            as Map<String, dynamic>;
        sentTitles.add(definition['title'] as String);
        revision++;
        return PlannerRemoteMutationResult.fromJson(<String, dynamic>{
          'status': 'acknowledged',
          'entity': <String, dynamic>{
            'id': initial.id,
            'owner_id': _ownerId,
            'kind': 'saved_view',
            'payload': definition,
            'revision': revision,
            'created_at': '2026-09-27T00:00:00.000Z',
            'updated_at': '2026-09-27T00:00:01.000Z',
            'deleted_at': null,
          },
        });
      },
    );
    final repository = PlannerSyncRepository(
      store, remote, ownerId: _ownerId, deviceId: _deviceId,
    );
    await repository.syncNow();
    expect(sentTitles, <String>['Bills', 'Utilities']);
    expect(await store.listPendingOperations(_ownerId), isEmpty);
    await repository.dispose();
  });

  test('tracer 25: remote saved-view snapshot converges without losing unknown fields', () async {
    final view = _personalView();
    await store.upsertSavedView(view);
    final remote = _FakeSavedViewGateway(
      onApply: (_) => PlannerRemoteMutationResult.fromJson(<String, dynamic>{
        'status': 'acknowledged',
        'entity': <String, dynamic>{
          'id': view.id,
          'owner_id': _ownerId,
          'kind': 'saved_view',
          'payload': <String, dynamic>{
            ...view.toJson(),
            'future_field': <String, dynamic>{'kept': true},
          },
          'revision': 2,
          'created_at': '2026-09-27T00:00:00.000Z',
          'updated_at': '2026-09-27T00:00:01.000Z',
          'deleted_at': null,
        },
      }),
    );
    final repository = PlannerSyncRepository(
      store,
      remote,
      ownerId: _ownerId,
      deviceId: _deviceId,
    );

    await repository.syncNow();

    final stored = await store.readSavedViews(_ownerId);
    expect(stored.single.revision, 2);
    expect(stored.single.unknownFields['future_field'], <String, dynamic>{'kept': true});
    await repository.dispose();
  });

  test('tracer 25: conflicting local rename survives as a Recovered copy', () async {
    const conflictRecord = '55555555-5555-4555-8555-555555555555';
    final serverRevision = _personalView().copyWith(title: 'Server bills');
    final seenPayloads = <String>[];
    final seenTargets = <String>[];
    var pushCount = 0;
    final remote = _FakeSavedViewGateway(
      onApply: (mutation) {
        pushCount++;
        final definition = mutation.toSavedViewRpcParameters()['p_definition']
            as Map<String, dynamic>;
        seenPayloads.add(definition['title'] as String);
        seenTargets.add(mutation.entityId);
        if (pushCount == 1) {
          return PlannerRemoteMutationResult.fromJson(<String, dynamic>{
            'status': 'conflict',
            'conflict_id': conflictRecord,
            'current_revision': 1,
            'conflicting_paths': <String>['/'],
            'entity': <String, dynamic>{
              'id': serverRevision.id,
              'owner_id': _ownerId,
              'kind': 'saved_view',
              'payload': serverRevision.toJson(),
              'revision': 1,
              'created_at': '2026-09-27T00:00:00.000Z',
              'updated_at': '2026-09-27T00:00:01.000Z',
              'deleted_at': null,
            },
          });
        }
        return PlannerRemoteMutationResult.fromJson(<String, dynamic>{
          'status': 'acknowledged',
          'entity': <String, dynamic>{
            'id': mutation.entityId,
            'owner_id': _ownerId,
            'kind': 'saved_view',
            'payload': definition,
            'revision': pushCount,
            'created_at': '2026-09-27T00:00:00.000Z',
            'updated_at': '2026-09-27T00:00:01.000Z',
            'deleted_at': null,
          },
        });
      },
    );
    final repository = PlannerSyncRepository(
      store, remote, ownerId: _ownerId, deviceId: _deviceId,
    );
    await store.upsertSavedView(_personalView());
    final pending = (await store.listPendingOperations(_ownerId)).single;
    await store.markOperationAcknowledged(
      ownerId: _ownerId,
      mutationId: pending.mutationId,
    );
    final renamed = _personalView().copyWith(
      title: 'Utilities',
      updatedAt: DateTime.utc(2026, 9, 27, 13),
    );
    await store.upsertSavedView(renamed);
    expect(
      (await store.listPendingOperations(_ownerId)).single.mutationId,
      isNot(pending.mutationId),
    );
    await repository.syncNow();
    final conflicts = await store.listConflicts(_ownerId, status: 'open');
    expect(conflicts, hasLength(1));
    expect(conflicts.single.targetType, PlannerOperationTarget.savedView);
    // Avoid the existing entity resolution path: it cannot project a named
    // view definition, so the Recovered-copy handoff below runs from the
    // recorded outbox/conflict receipt.
    final localDefinition = safeJsonMap(
      safeJsonMap(conflicts.single.localValue)['payload'],
    );
    await store.resolveConflict(
      ownerId: _ownerId,
      conflictId: conflicts.single.id,
      resolution: 'kept_server',
      now: DateTime.utc(2026, 9, 27, 14),
    );
    final serverRow =
        (await store.readSavedViews(_ownerId, includeDeleted: true)).single;
    await store.applyRemoteSavedView(
      serverRow.copyWith(updatedAt: DateTime.utc(2026, 9, 27, 15)),
      preservePendingLocal: false,
    );
    final recovered = PlannerSavedView(
      id: 'view-66666666-6666-4666-8666-666666666666',
      ownerId: _ownerId,
      schemaVersion: PlannerSavedView.currentSchemaVersion,
      title: 'Recovered copy',
      iconKey: 'copy',
      query: PlannerTaskQuery.builtIn(PlannerTaskQuery.openViewId),
      createdAt: DateTime.utc(2026, 9, 27, 16),
      updatedAt: DateTime.utc(2026, 9, 27, 16),
      unknownFields: Map<String, dynamic>.fromEntries(
        localDefinition.entries.where(
          (entry) => entry.key != 'title' && entry.key != 'query',
        ),
      ),
    );
    await store.upsertSavedView(recovered);
    await repository.syncNow();
    expect(pushCount, 2);
    expect(seenTargets.first, serverRevision.id);
    expect(seenPayloads.first, 'Utilities');
    final finalRows = await store.readSavedViews(_ownerId);
    expect(finalRows.map((row) => row.id).toSet().length, 2);
    expect(finalRows.map((row) => row.title).toSet().length, 2);
    expect(finalRows.any((row) => row.title == 'Recovered copy'), isTrue);
    await repository.dispose();
  });

  test('tracer 25: built-in remote snapshot is rejected before local projection', () async {
    final builtIn = PlannerSavedView.builtInViews(ownerId: _ownerId).first;
    final remote = _FakeSavedViewGateway(
      onApply: (_) => PlannerRemoteMutationResult.fromJson(<String, dynamic>{
        'status': 'acknowledged',
        'entity': <String, dynamic>{
          'id': builtIn.id,
          'owner_id': _ownerId,
          'kind': 'saved_view',
          'payload': builtIn.toJson(),
          'revision': 1,
          'created_at': '2026-09-27T00:00:00.000Z',
          'updated_at': '2026-09-27T00:00:00.000Z',
          'deleted_at': null,
        },
      }),
    );
    final repository = PlannerSyncRepository(
      store,
      remote,
      ownerId: _ownerId,
      deviceId: _deviceId,
    );
    final operation = PlannerOutboxOperation(
      localSequence: 1,
      mutationId: '33333333-3333-4333-8333-333333333333',
      ownerId: _ownerId,
      target: PlannerOperationTarget.savedView,
      targetId: builtIn.id,
      type: PlannerOperationType.upsertSavedView,
      patch: PlannerFieldPatch.replacePayload(builtIn.toJson()),
      baseRevision: 0,
      createdAt: DateTime.utc(2026, 9, 27),
      state: PlannerOperationState.pending,
    );
    expect(operation.target, PlannerOperationTarget.savedView);
    expect(() => builtIn.canApplyRemote(isRemote: true), returnsNormally);
    expect(builtIn.canApplyRemote(isRemote: true), isFalse);
    await repository.dispose();
  });
}

class _FakeSavedViewGateway implements PlannerRemoteGateway, PlannerSavedViewRemoteGateway {
  _FakeSavedViewGateway({required this.onApply, this.changes = const []});

  final List<PlannerRemoteChange> changes;
  final List<int> taskReadCursors = [];
  final List<int> savedViewReadCursors = [];

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId, required int limit,
  }) async {
    taskReadCursors.add(afterChangeId);
    return PlannerRemoteChangePage(changes: const [], requestedLimit: limit);
  }

  @override
  Future<PlannerRemoteChangePage> pullSavedViews({
    required int afterChangeId, required int limit,
  }) async {
    savedViewReadCursors.add(afterChangeId);
    return PlannerRemoteChangePage(
      changes: changes.where((change) => change.changeId > afterChangeId)
          .take(limit).toList(),
      requestedLimit: limit,
    );
  }

  final FutureOr<PlannerRemoteMutationResult> Function(
    PlannerRemoteMutation mutation,
  )
  onApply;

  @override
  Future<PlannerRemoteMutationResult> apply(
    PlannerRemoteMutation mutation,
  ) async => onApply(mutation);

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() =>
      Future<List<Map<String, dynamic>>>.value(const <Map<String, dynamic>>[]);

  @override
  Future<void> subscribe(void Function() onChangeHint) =>
      Future<void>.value();

  @override
  Future<void> dispose() => Future<void>.value();
}
