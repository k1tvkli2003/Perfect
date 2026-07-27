import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/app/personal_item.dart';

void main() {
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
}
