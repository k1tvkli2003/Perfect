import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/app/personal_item.dart';

void main() {
  group('PersonalItem', () {
    test('local serialization preserves a tombstone and dirty state', () {
      final createdAt = DateTime.utc(2026, 7, 27, 12);
      final deletedAt = DateTime.utc(2026, 7, 27, 13);
      final item = PersonalItem(
        id: 'c5993908-f4d7-4ba8-b0f0-b8731a3c5ca5',
        title: 'نمونه',
        isDone: true,
        createdAt: createdAt,
        updatedAt: deletedAt,
        deletedAt: deletedAt,
        dirty: true,
      );

      final restored = PersonalItem.fromJson(item.toLocalJson());

      expect(restored.id, item.id);
      expect(restored.title, 'نمونه');
      expect(restored.isDeleted, isTrue);
      expect(restored.dirty, isTrue);
      expect(restored.updatedAt, deletedAt);
    });

    test('value equality compares all fields', () {
      final createdAt = DateTime.utc(2026, 8, 1, 9);
      final base = PersonalItem(
        id: 'a1',
        title: 'Read',
        isDone: false,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final identical = PersonalItem(
        id: 'a1',
        title: 'Read',
        isDone: false,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final different = base.copyWith(title: 'Write');

      expect(base, equals(identical));
      expect(base.hashCode, equals(identical.hashCode));
      expect(base, isNot(equals(different)));
    });

    test('copyWith preserves unchanged fields and clears deletedAt', () {
      final createdAt = DateTime.utc(2026, 6, 15);
      final deletedAt = DateTime.utc(2026, 6, 16);
      final item = PersonalItem(
        id: 'x',
        title: 'Original',
        isDone: true,
        createdAt: createdAt,
        updatedAt: createdAt,
        deletedAt: deletedAt,
        dirty: true,
      );

      final restored = item.copyWith(clearDeletedAt: true);
      expect(restored.deletedAt, isNull);
      expect(restored.isDeleted, isFalse);
      expect(restored.title, 'Original');
      expect(restored.dirty, isTrue);

      final renamed = item.copyWith(title: 'Renamed', dirty: false);
      expect(renamed.title, 'Renamed');
      expect(renamed.dirty, isFalse);
      expect(renamed.deletedAt, deletedAt);
    });

    test('remote JSON round-trip omits the dirty flag', () {
      final now = DateTime.utc(2026, 9, 1);
      final item = PersonalItem(
        id: 'b2',
        title: 'Synced',
        isDone: false,
        createdAt: now,
        updatedAt: now,
        dirty: true,
      );
      final remote = item.toRemoteJson();
      expect(remote, isNot(contains('dirty')));
      final restored = PersonalItem.fromJson(remote);
      expect(restored.dirty, isFalse);
    });
  });
}
