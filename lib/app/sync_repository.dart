import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:perfect/app/personal_item.dart';
import 'package:perfect/app/personal_items_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncState { idle, syncing, offlineError }

class SyncRepository {
  SyncRepository({
    required this.client,
    required this.userId,
    required this.store,
  });

  final SupabaseClient client;
  final PersonalItemsStore store;
  final String userId;
  final _items = <String, PersonalItem>{};
  final ValueNotifier<SyncState> syncState = ValueNotifier(SyncState.idle);

  RealtimeChannel? _channel;
  Future<void>? _activeSync;

  List<PersonalItem> get items => _items.values.toList(growable: false)
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> start() async {
    for (final item in await store.read(userId)) {
      _items[item.id] = item;
    }
    _subscribe();
    unawaited(sync());
  }

  Future<void> add(String title, String id, DateTime now) async {
    _items[id] = PersonalItem(
      id: id,
      title: title,
      isDone: false,
      createdAt: now,
      updatedAt: now,
      dirty: true,
    );
    await _persist();
  }

  Future<void> toggle(PersonalItem item, DateTime now) async {
    _items[item.id] = item.copyWith(
      isDone: !item.isDone,
      updatedAt: now,
      dirty: true,
    );
    await _persist();
  }

  Future<void> delete(PersonalItem item, DateTime now) async {
    _items[item.id] = item.copyWith(
      updatedAt: now,
      deletedAt: now,
      dirty: true,
    );
    await _persist();
  }

  Future<void> sync() {
    if (_activeSync != null) return _activeSync!;
    _activeSync = _sync().whenComplete(() => _activeSync = null);
    return _activeSync!;
  }

  Future<void> _sync() async {
    syncState.value = SyncState.syncing;
    try {
      await _pull();
      await _pushDirtyItems();
      await _pull();
      syncState.value = SyncState.idle;
    } catch (_) {
      // Local changes remain marked dirty and will be retried by Sync now.
      syncState.value = SyncState.offlineError;
    }
  }

  Future<void> _pull() async {
    final response = await client
        .from('perfect_items')
        .select('id,title,is_done,created_at,updated_at,deleted_at')
        .eq('owner_id', userId);
    final remoteItems = (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PersonalItem.fromJson);

    for (final remote in remoteItems) {
      final local = _items[remote.id];
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        _items[remote.id] = remote;
      }
    }
    await _persist();
  }

  Future<void> _pushDirtyItems() async {
    final dirtyItems = _items.values.where((item) => item.dirty).toList();
    for (final item in dirtyItems) {
      await client.from('perfect_items').upsert(
            {
              ...item.toRemoteJson(),
              'owner_id': userId,
            },
            onConflict: 'id',
          );
      _items[item.id] = item.copyWith(dirty: false);
      await _persist();
    }
  }

  void _subscribe() {
    _channel = client
        .channel('perfect-items-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'perfect_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: userId,
          ),
          callback: (_) => unawaited(sync()),
        )
        .subscribe();
  }

  Future<void> _persist() => store.write(userId, _items.values);

  Future<void> dispose() async {
    if (_channel != null) await client.removeChannel(_channel!);
    syncState.dispose();
  }
}
