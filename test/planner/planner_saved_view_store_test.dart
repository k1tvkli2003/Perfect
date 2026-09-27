import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_saved_view.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';

void main() {
  late PlannerDatabase database;
  late PlannerLocalStore store;

  setUp(() {
    database = PlannerDatabase(NativeDatabase.memory());
    store = PlannerLocalStore(database);
  });
  tearDown(() => store.close());

  PlannerSavedView personal({String owner = 'owner-a'}) => PlannerSavedView(
    id: 'view-bills',
    ownerId: owner,
    schemaVersion: PlannerSavedView.currentSchemaVersion,
    title: 'Bills',
    iconKey: 'receipt',
    query: const PlannerTaskQuery(
      viewId: PlannerTaskQuery.openViewId,
      text: 'utilities',
      unknownFields: {'future_query': 'preserve'},
    ),
    createdAt: DateTime.utc(2026, 9, 27, 10),
    updatedAt: DateTime.utc(2026, 9, 27, 10),
    unknownFields: const {'future_view': true},
  );

  test(
    'owner isolation, unknown fields and stable-ID rename survive store reopen',
    () async {
      await store.upsertSavedView(personal());
      expect(await store.readSavedViews('owner-b'), isEmpty);
      var rows = await store.readSavedViews('owner-a');
      expect(rows, hasLength(1));
      expect(rows.single.toJson()['future_view'], true);
      expect(rows.single.query.toJson()['future_query'], 'preserve');
      final renamed = rows.single.copyWith(
        title: 'Utilities',
        updatedAt: DateTime.utc(2026, 9, 27, 11),
      );
      await store.upsertSavedView(renamed);
      rows = await store.readSavedViews('owner-a');
      expect(rows, hasLength(1));
      expect(rows.single.id, 'view-bills');
      expect(rows.single.title, 'Utilities');
      expect(rows.single.toJson()['future_view'], true);
      expect(rows.single.query.toJson()['future_query'], 'preserve');
    },
  );

  test(
    'owner-scoped tombstone hides definition without erasing identity',
    () async {
      await store.upsertSavedView(personal());
      await store.upsertSavedView(personal(owner: 'owner-b'));
      await store.softDeleteSavedView(
        ownerId: 'owner-a',
        viewId: 'view-bills',
        deletedAt: DateTime.utc(2026, 9, 27, 12),
      );
      expect(await store.readSavedViews('owner-a'), isEmpty);
      expect(
        (await store.readSavedViews(
          'owner-a',
          includeDeleted: true,
        )).single.isDeleted,
        true,
      );
      expect((await store.readSavedViews('owner-b')).single.title, 'Bills');
    },
  );

  test(
    'v2 database upgrades to v3 without losing existing planner tasks',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final directory = await Directory.systemTemp.createTemp(
        'perfect-view-v2-',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}planner.sqlite',
      );
      addTearDown(() async {
        await store.close();
        for (var attempt = 0; attempt < 20; attempt++) {
          try {
            await directory.delete(recursive: true);
            return;
          } on FileSystemException {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }
      });
      try {
        final originalDatabase = PlannerDatabase(
          NativeDatabase.createInBackground(file),
        );
        final originalStore = PlannerLocalStore(originalDatabase);
        late String taskId;
        try {
          taskId = (await originalStore.createQuickTask(
            ownerId: 'owner-a',
            title: 'Keep me after v3 upgrade',
          )).entity!.id;
          // Simulate a pre-saved-view database: remove the v3 table and stamp
          // the schema back to version 2, exactly like a real old install.
          await originalDatabase.customStatement(
            'DROP TABLE planner_saved_views',
          );
          await originalDatabase.customStatement('PRAGMA user_version = 2');
        } finally {
          await originalStore.close();
        }
        database = PlannerDatabase(NativeDatabase.createInBackground(file));
        store = PlannerLocalStore(database);
        expect(
          (await store.readEntity(ownerId: 'owner-a', entityId: taskId))?.title,
          'Keep me after v3 upgrade',
        );
        await store.upsertSavedView(personal());
        expect((await store.readSavedViews('owner-a')).single.title, 'Bills');
        expect(
          (await store.readEntity(ownerId: 'owner-a', entityId: taskId))?.title,
          'Keep me after v3 upgrade',
        );
      } finally {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting;
      }
    },
  );

  test(
    'built-in namespace cannot be stored or removed as a personal view',
    () async {
      final builtIn = PlannerSavedView.builtInViews(ownerId: 'owner-a').first;
      await expectLater(store.upsertSavedView(builtIn), throwsArgumentError);
      await expectLater(
        store.softDeleteSavedView(
          ownerId: 'owner-a',
          viewId: builtIn.id,
          deletedAt: DateTime.utc(2026, 9, 27),
        ),
        throwsArgumentError,
      );
      expect(await store.readSavedViews('owner-a'), isEmpty);
    },
  );
}
