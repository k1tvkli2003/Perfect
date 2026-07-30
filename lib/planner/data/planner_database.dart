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

@DriftDatabase(
  tables: <Type>[
    PlannerEntities,
    PlannerOccurrences,
    PlannerFocusSessions,
    PlannerOutboxOperations,
    PlannerSyncMetadata,
    PlannerConflicts,
    PlannerImportMarkers,
  ],
)
class PlannerDatabase extends _$PlannerDatabase {
  PlannerDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'perfect_planner'));

  @override
  int get schemaVersion => 1;

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
    },
  );
}
