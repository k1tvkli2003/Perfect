import 'dart:convert';

import 'package:perfect/app/personal_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalItemsStore {
  static const _keyPrefix = 'perfect.personal_items.v1.';

  /// Exposes the immutable legacy payload for one-time v2 projection. Callers
  /// must never clear or rewrite this key; it remains the recovery source for
  /// the original application contract.
  Future<String?> readRaw(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_keyPrefix$userId');
  }

  Future<List<PersonalItem>> read(String userId) async {
    final raw = await readRaw(userId);
    if (raw == null) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(PersonalItem.fromJson)
        .toList(growable: false);
  }

  Future<void> write(String userId, Iterable<PersonalItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_keyPrefix$userId',
      jsonEncode(items.map((item) => item.toLocalJson()).toList()),
    );
  }
}
