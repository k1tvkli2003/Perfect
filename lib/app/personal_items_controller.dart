import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:perfect/app/personal_item.dart';
import 'package:perfect/app/sync_repository.dart';
import 'package:uuid/uuid.dart';

class PersonalItemsController extends ChangeNotifier {
  PersonalItemsController(this._repository) {
    _repository.syncState.addListener(notifyListeners);
  }

  final SyncRepository _repository;
  final _uuid = const Uuid();
  bool _started = false;

  List<PersonalItem> get items =>
      _repository.items.where((item) => !item.isDeleted).toList(growable: false);
  SyncState get syncState => _repository.syncState.value;
  int get completedCount => items.where((item) => item.isDone).length;

  Future<void> start() async {
    await _repository.start();
    _started = true;
    notifyListeners();
  }

  Future<void> add(String rawTitle) async {
    final title = rawTitle.trim();
    if (title.isEmpty || title.length > 160) return;
    await _repository.add(title, _uuid.v4(), DateTime.now().toUtc());
    notifyListeners();
    unawaited(_repository.sync());
  }

  Future<void> toggle(PersonalItem item) async {
    await _repository.toggle(item, DateTime.now().toUtc());
    notifyListeners();
    unawaited(_repository.sync());
  }

  Future<void> delete(PersonalItem item) async {
    await _repository.delete(item, DateTime.now().toUtc());
    notifyListeners();
    unawaited(_repository.sync());
  }

  Future<void> syncNow() async {
    await _repository.sync();
    notifyListeners();
  }

  Future<void> disposeAsync() async {
    _repository.syncState.removeListener(notifyListeners);
    if (_started) await _repository.dispose();
    dispose();
  }
}
