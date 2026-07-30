import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;

  setUpAll(() async {
    migration = await File(
      'supabase/migrations/20260727210000_add_private_planner_v2.sql',
    ).readAsString();
  });

  test('outcome-bearing records never derive lifecycle from payload status', () {
    expect(
      migration,
      contains(
        "'occurrence', 'habit_log', 'focus_session', 'property_definition', 'relation'",
      ),
    );
    expect(migration, contains(") then 'active'"));
    expect(migration, contains("then v_existing.lifecycle_state"));
  });

  test('mutation replay is serialized and rejects a changed request', () {
    expect(migration, contains("'perfect:planner-mutation:'"));
    expect(migration, contains("'perfect:planner-entity:'"));
    expect(
      migration,
      contains('A mutation ID cannot be reused for a different request.'),
    );
    expect(migration, contains('v_existing_operation.patch is distinct from'));
  });
}
