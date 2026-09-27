import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'planner_database.g.dart';

@DataClassName('PlannerEntityRow')
class PlannerEntities extends Table {
  @override
  String get tableName => 'planner_entities';

  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get kind => text()();
  TextColumn get payloadJson => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get serverCreatedAt => dateTime().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId, id};

  @override
  List<String> get customConstraints => <String>[
    "CHECK (kind IN ('one_off_task', 'recurring_task', 'habit', 'project', 'area'))",
    'CHECK (revision >= 0)',
  ];
}

/// Private, owner-scoped named task queries. Built-in definitions remain
/// compiled into the client and never occupy this table.
@DataClassName('PlannerSavedViewRow')
class PlannerSavedViews extends Table {
  @override
  String get tableName => 'planner_saved_views';

  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get definitionJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId, id};
}

@DataClassName('PlannerOccurrenceRow')
class PlannerOccurrences extends Table {
  @override
  String get tableName => 'planner_occurrences';

  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get entityId => text()();
  DateTimeColumn get plannedFor => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get valueJson => text().withDefault(const Constant('{}'))();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get missedAt => dateTime().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId, id};

  @override
  List<String> get customConstraints => <String>['CHECK (revision >= 0)'];
}

@DataClassName('PlannerFocusSessionRow')
class PlannerFocusSessions extends Table {
  @override
  String get tableName => 'planner_focus_sessions';

  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get mode => text().withDefault(const Constant('stopwatch'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId, id};

  @override
  List<String> get customConstraints => <String>['CHECK (revision >= 0)'];
}

@DataClassName('PlannerOutboxOperationRow')
class PlannerOutboxOperations extends Table {
  @override
  String get tableName => 'planner_outbox_operations';

  IntColumn get localSequence => integer().autoIncrement()();
  TextColumn get mutationId => text().unique()();
  TextColumn get ownerId => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get entityKind => text().nullable()();
  TextColumn get operationType => text()();
  TextColumn get fieldPatchJson => text()();
  IntColumn get baseRevision => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get acknowledgedAt => dateTime().nullable()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (target_type IN ('entity', 'occurrence', 'focus_session'))",
    "CHECK (entity_kind IS NULL OR entity_kind IN ('one_off_task', 'recurring_task', 'habit', 'project', 'area'))",
    "CHECK (operation_type IN ('create_entity', 'upsert_entity', 'complete_entity', 'soft_delete_entity', 'append_occurrence', 'complete_occurrence', 'append_focus_session'))",
    "CHECK (state IN ('pending', 'retrying', 'acknowledged'))",
    'CHECK (base_revision >= 0)',
    'CHECK (attempt_count >= 0)',
  ];
}

@DataClassName('PlannerSyncMetadataRow')
class PlannerSyncMetadata extends Table {
  @override
  String get tableName => 'planner_sync_metadata';

  TextColumn get ownerId => text()();
  TextColumn get remoteCursor => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId};
}

@DataClassName('PlannerConflictRow')
class PlannerConflicts extends Table {
  @override
  String get tableName => 'planner_conflicts';

  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  TextColumn get mutationId => text().nullable()();
  TextColumn get fieldPathsJson => text()();
  TextColumn get localValueJson => text()();
  TextColumn get remoteValueJson => text()();
  IntColumn get baseRevision => integer().nullable()();
  IntColumn get remoteRevision => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId, id};

  @override
  List<String> get customConstraints => <String>[
    "CHECK (target_type IN ('entity', 'occurrence', 'focus_session'))",
    'CHECK (base_revision IS NULL OR base_revision >= 0)',
    'CHECK (remote_revision IS NULL OR remote_revision >= 0)',
  ];
}

@DataClassName('PlannerImportMarkerRow')
class PlannerImportMarkers extends Table {
  @override
  String get tableName => 'planner_import_markers';

  TextColumn get ownerId => text()();
  TextColumn get source => text()();
  TextColumn get sourceId => text()();
  DateTimeColumn get importedAt => dateTime()();
  TextColumn get sourceFingerprint => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId, source, sourceId};
}

/// Local-only ordering clock for Android widget task outcomes.
///
/// This table is deliberately not part of the Supabase data model or outbox.
/// It serializes background and foreground executors that may open independent
/// SQLite connections to the same private planner database.
@DataClassName('PlannerWidgetActionSequenceRow')
class PlannerWidgetActionSequences extends Table {
  @override
  String get tableName => 'planner_widget_action_sequences';

  TextColumn get ownerId => text()();
  TextColumn get entityId => text()();
  TextColumn get localDay => text()();
  IntColumn get sequenceDomain => integer()();
  IntColumn get queueSequence => integer()();
  IntColumn get occurredAtMicros => integer()();
  TextColumn get actionId => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column>{ownerId, entityId, localDay};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (sequence_domain IN (0, 1))',
    'CHECK (queue_sequence >= 0)',
    'CHECK (occurred_at_micros >= 0)',
  ];
}

@DriftDatabase(
  tables: <Type>[
    PlannerEntities,
    PlannerSavedViews,
    PlannerOccurrences,
    PlannerFocusSessions,
    PlannerOutboxOperations,
    PlannerSyncMetadata,
    PlannerConflicts,
    PlannerImportMarkers,
    PlannerWidgetActionSequences,
  ],
)
class PlannerDatabase extends _$PlannerDatabase {
  PlannerDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'perfect_planner'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE INDEX planner_entities_owner_active_idx '
        'ON planner_entities(owner_id, deleted_at, updated_at DESC)',
      );
      await customStatement(
        'CREATE INDEX planner_occurrences_owner_entity_due_idx '
        'ON planner_occurrences(owner_id, entity_id, planned_for)',
      );
      await customStatement(
        'CREATE INDEX planner_outbox_owner_state_sequence_idx '
        'ON planner_outbox_operations(owner_id, state, local_sequence)',
      );
      await customStatement(
        'CREATE INDEX planner_conflicts_owner_status_idx '
        'ON planner_conflicts(owner_id, status, created_at DESC)',
      );
      await customStatement(
        'CREATE INDEX planner_saved_views_owner_active_idx '
        'ON planner_saved_views(owner_id, deleted_at, updated_at DESC)',
      );
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(plannerWidgetActionSequences);
      }
      if (from < 3) {
        await migrator.createTable(plannerSavedViews);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS planner_saved_views_owner_active_idx '
          'ON planner_saved_views(owner_id, deleted_at, updated_at DESC)',
        );
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // Android widget and foreground engines can briefly contend for the
      // same local file. Wait for the active transaction instead of surfacing
      // SQLITE_BUSY and dropping an otherwise valid widget tap.
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
