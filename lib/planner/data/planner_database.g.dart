// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_database.dart';

// ignore_for_file: type=lint
class $PlannerEntitiesTable extends PlannerEntities
    with TableInfo<$PlannerEntitiesTable, PlannerEntityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverCreatedAtMeta = const VerificationMeta(
    'serverCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverCreatedAt =
      GeneratedColumn<DateTime>(
        'server_created_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    kind,
    payloadJson,
    revision,
    createdAt,
    updatedAt,
    serverCreatedAt,
    serverUpdatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerEntityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_created_at')) {
      context.handle(
        _serverCreatedAtMeta,
        serverCreatedAt.isAcceptableOrUnknown(
          data['server_created_at']!,
          _serverCreatedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, id};
  @override
  PlannerEntityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerEntityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      serverCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_created_at'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PlannerEntitiesTable createAlias(String alias) {
    return $PlannerEntitiesTable(attachedDatabase, alias);
  }
}

class PlannerEntityRow extends DataClass
    implements Insertable<PlannerEntityRow> {
  final String id;
  final String ownerId;
  final String kind;
  final String payloadJson;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? serverCreatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;
  const PlannerEntityRow({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.payloadJson,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.serverCreatedAt,
    this.serverUpdatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverCreatedAt != null) {
      map['server_created_at'] = Variable<DateTime>(serverCreatedAt);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PlannerEntitiesCompanion toCompanion(bool nullToAbsent) {
    return PlannerEntitiesCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverCreatedAt: serverCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverCreatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PlannerEntityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerEntityRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverCreatedAt: serializer.fromJson<DateTime?>(json['serverCreatedAt']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverCreatedAt': serializer.toJson<DateTime?>(serverCreatedAt),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PlannerEntityRow copyWith({
    String? id,
    String? ownerId,
    String? kind,
    String? payloadJson,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> serverCreatedAt = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => PlannerEntityRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    kind: kind ?? this.kind,
    payloadJson: payloadJson ?? this.payloadJson,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverCreatedAt: serverCreatedAt.present
        ? serverCreatedAt.value
        : this.serverCreatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PlannerEntityRow copyWithCompanion(PlannerEntitiesCompanion data) {
    return PlannerEntityRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverCreatedAt: data.serverCreatedAt.present
          ? data.serverCreatedAt.value
          : this.serverCreatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerEntityRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverCreatedAt: $serverCreatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    kind,
    payloadJson,
    revision,
    createdAt,
    updatedAt,
    serverCreatedAt,
    serverUpdatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerEntityRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverCreatedAt == this.serverCreatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlannerEntitiesCompanion extends UpdateCompanion<PlannerEntityRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> kind;
  final Value<String> payloadJson;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> serverCreatedAt;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PlannerEntitiesCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverCreatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerEntitiesCompanion.insert({
    required String id,
    required String ownerId,
    required String kind,
    required String payloadJson,
    this.revision = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.serverCreatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       kind = Value(kind),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlannerEntityRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? serverCreatedAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverCreatedAt != null) 'server_created_at': serverCreatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerEntitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? kind,
    Value<String>? payloadJson,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? serverCreatedAt,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PlannerEntitiesCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverCreatedAt.present) {
      map['server_created_at'] = Variable<DateTime>(serverCreatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerEntitiesCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverCreatedAt: $serverCreatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerSavedViewsTable extends PlannerSavedViews
    with TableInfo<$PlannerSavedViewsTable, PlannerSavedViewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerSavedViewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionJsonMeta = const VerificationMeta(
    'definitionJson',
  );
  @override
  late final GeneratedColumn<String> definitionJson = GeneratedColumn<String>(
    'definition_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    definitionJson,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_saved_views';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerSavedViewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('definition_json')) {
      context.handle(
        _definitionJsonMeta,
        definitionJson.isAcceptableOrUnknown(
          data['definition_json']!,
          _definitionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, id};
  @override
  PlannerSavedViewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerSavedViewRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      definitionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PlannerSavedViewsTable createAlias(String alias) {
    return $PlannerSavedViewsTable(attachedDatabase, alias);
  }
}

class PlannerSavedViewRow extends DataClass
    implements Insertable<PlannerSavedViewRow> {
  final String id;
  final String ownerId;
  final String definitionJson;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const PlannerSavedViewRow({
    required this.id,
    required this.ownerId,
    required this.definitionJson,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['definition_json'] = Variable<String>(definitionJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PlannerSavedViewsCompanion toCompanion(bool nullToAbsent) {
    return PlannerSavedViewsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      definitionJson: Value(definitionJson),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PlannerSavedViewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerSavedViewRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      definitionJson: serializer.fromJson<String>(json['definitionJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'definitionJson': serializer.toJson<String>(definitionJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PlannerSavedViewRow copyWith({
    String? id,
    String? ownerId,
    String? definitionJson,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => PlannerSavedViewRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    definitionJson: definitionJson ?? this.definitionJson,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PlannerSavedViewRow copyWithCompanion(PlannerSavedViewsCompanion data) {
    return PlannerSavedViewRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      definitionJson: data.definitionJson.present
          ? data.definitionJson.value
          : this.definitionJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerSavedViewRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('definitionJson: $definitionJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerId, definitionJson, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerSavedViewRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.definitionJson == this.definitionJson &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlannerSavedViewsCompanion extends UpdateCompanion<PlannerSavedViewRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> definitionJson;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PlannerSavedViewsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.definitionJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerSavedViewsCompanion.insert({
    required String id,
    required String ownerId,
    required String definitionJson,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       definitionJson = Value(definitionJson),
       updatedAt = Value(updatedAt);
  static Insertable<PlannerSavedViewRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? definitionJson,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (definitionJson != null) 'definition_json': definitionJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerSavedViewsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? definitionJson,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PlannerSavedViewsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      definitionJson: definitionJson ?? this.definitionJson,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (definitionJson.present) {
      map['definition_json'] = Variable<String>(definitionJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerSavedViewsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('definitionJson: $definitionJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerOccurrencesTable extends PlannerOccurrences
    with TableInfo<$PlannerOccurrencesTable, PlannerOccurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedForMeta = const VerificationMeta(
    'plannedFor',
  );
  @override
  late final GeneratedColumn<DateTime> plannedFor = GeneratedColumn<DateTime>(
    'planned_for',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missedAtMeta = const VerificationMeta(
    'missedAt',
  );
  @override
  late final GeneratedColumn<DateTime> missedAt = GeneratedColumn<DateTime>(
    'missed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    entityId,
    plannedFor,
    status,
    valueJson,
    revision,
    createdAt,
    updatedAt,
    completedAt,
    missedAt,
    serverUpdatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerOccurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('planned_for')) {
      context.handle(
        _plannedForMeta,
        plannedFor.isAcceptableOrUnknown(data['planned_for']!, _plannedForMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedForMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('missed_at')) {
      context.handle(
        _missedAtMeta,
        missedAt.isAcceptableOrUnknown(data['missed_at']!, _missedAtMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, id};
  @override
  PlannerOccurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerOccurrenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      plannedFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planned_for'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      missedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}missed_at'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PlannerOccurrencesTable createAlias(String alias) {
    return $PlannerOccurrencesTable(attachedDatabase, alias);
  }
}

class PlannerOccurrenceRow extends DataClass
    implements Insertable<PlannerOccurrenceRow> {
  final String id;
  final String ownerId;
  final String entityId;
  final DateTime plannedFor;
  final String status;
  final String valueJson;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? missedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;
  const PlannerOccurrenceRow({
    required this.id,
    required this.ownerId,
    required this.entityId,
    required this.plannedFor,
    required this.status,
    required this.valueJson,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.missedAt,
    this.serverUpdatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['entity_id'] = Variable<String>(entityId);
    map['planned_for'] = Variable<DateTime>(plannedFor);
    map['status'] = Variable<String>(status);
    map['value_json'] = Variable<String>(valueJson);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || missedAt != null) {
      map['missed_at'] = Variable<DateTime>(missedAt);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PlannerOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return PlannerOccurrencesCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      entityId: Value(entityId),
      plannedFor: Value(plannedFor),
      status: Value(status),
      valueJson: Value(valueJson),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      missedAt: missedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(missedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PlannerOccurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerOccurrenceRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      plannedFor: serializer.fromJson<DateTime>(json['plannedFor']),
      status: serializer.fromJson<String>(json['status']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      missedAt: serializer.fromJson<DateTime?>(json['missedAt']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'entityId': serializer.toJson<String>(entityId),
      'plannedFor': serializer.toJson<DateTime>(plannedFor),
      'status': serializer.toJson<String>(status),
      'valueJson': serializer.toJson<String>(valueJson),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'missedAt': serializer.toJson<DateTime?>(missedAt),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PlannerOccurrenceRow copyWith({
    String? id,
    String? ownerId,
    String? entityId,
    DateTime? plannedFor,
    String? status,
    String? valueJson,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> missedAt = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => PlannerOccurrenceRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    entityId: entityId ?? this.entityId,
    plannedFor: plannedFor ?? this.plannedFor,
    status: status ?? this.status,
    valueJson: valueJson ?? this.valueJson,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    missedAt: missedAt.present ? missedAt.value : this.missedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PlannerOccurrenceRow copyWithCompanion(PlannerOccurrencesCompanion data) {
    return PlannerOccurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      plannedFor: data.plannedFor.present
          ? data.plannedFor.value
          : this.plannedFor,
      status: data.status.present ? data.status.value : this.status,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      missedAt: data.missedAt.present ? data.missedAt.value : this.missedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerOccurrenceRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('entityId: $entityId, ')
          ..write('plannedFor: $plannedFor, ')
          ..write('status: $status, ')
          ..write('valueJson: $valueJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('missedAt: $missedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    entityId,
    plannedFor,
    status,
    valueJson,
    revision,
    createdAt,
    updatedAt,
    completedAt,
    missedAt,
    serverUpdatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerOccurrenceRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.entityId == this.entityId &&
          other.plannedFor == this.plannedFor &&
          other.status == this.status &&
          other.valueJson == this.valueJson &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.missedAt == this.missedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlannerOccurrencesCompanion
    extends UpdateCompanion<PlannerOccurrenceRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> entityId;
  final Value<DateTime> plannedFor;
  final Value<String> status;
  final Value<String> valueJson;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> missedAt;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PlannerOccurrencesCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.plannedFor = const Value.absent(),
    this.status = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.missedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerOccurrencesCompanion.insert({
    required String id,
    required String ownerId,
    required String entityId,
    required DateTime plannedFor,
    this.status = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.missedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       entityId = Value(entityId),
       plannedFor = Value(plannedFor),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlannerOccurrenceRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? entityId,
    Expression<DateTime>? plannedFor,
    Expression<String>? status,
    Expression<String>? valueJson,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? missedAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (entityId != null) 'entity_id': entityId,
      if (plannedFor != null) 'planned_for': plannedFor,
      if (status != null) 'status': status,
      if (valueJson != null) 'value_json': valueJson,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (missedAt != null) 'missed_at': missedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? entityId,
    Value<DateTime>? plannedFor,
    Value<String>? status,
    Value<String>? valueJson,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? missedAt,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PlannerOccurrencesCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      entityId: entityId ?? this.entityId,
      plannedFor: plannedFor ?? this.plannedFor,
      status: status ?? this.status,
      valueJson: valueJson ?? this.valueJson,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      missedAt: missedAt ?? this.missedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (plannedFor.present) {
      map['planned_for'] = Variable<DateTime>(plannedFor.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (missedAt.present) {
      map['missed_at'] = Variable<DateTime>(missedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('entityId: $entityId, ')
          ..write('plannedFor: $plannedFor, ')
          ..write('status: $status, ')
          ..write('valueJson: $valueJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('missedAt: $missedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerFocusSessionsTable extends PlannerFocusSessions
    with TableInfo<$PlannerFocusSessionsTable, PlannerFocusSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerFocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('stopwatch'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    entityId,
    mode,
    status,
    payloadJson,
    revision,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerFocusSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, id};
  @override
  PlannerFocusSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerFocusSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PlannerFocusSessionsTable createAlias(String alias) {
    return $PlannerFocusSessionsTable(attachedDatabase, alias);
  }
}

class PlannerFocusSessionRow extends DataClass
    implements Insertable<PlannerFocusSessionRow> {
  final String id;
  final String ownerId;
  final String? entityId;
  final String mode;
  final String status;
  final String payloadJson;
  final int revision;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;
  const PlannerFocusSessionRow({
    required this.id,
    required this.ownerId,
    this.entityId,
    required this.mode,
    required this.status,
    required this.payloadJson,
    required this.revision,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    map['payload_json'] = Variable<String>(payloadJson);
    map['revision'] = Variable<int>(revision);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PlannerFocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return PlannerFocusSessionsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      mode: Value(mode),
      status: Value(status),
      payloadJson: Value(payloadJson),
      revision: Value(revision),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PlannerFocusSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerFocusSessionRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      revision: serializer.fromJson<int>(json['revision']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'entityId': serializer.toJson<String?>(entityId),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'revision': serializer.toJson<int>(revision),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PlannerFocusSessionRow copyWith({
    String? id,
    String? ownerId,
    Value<String?> entityId = const Value.absent(),
    String? mode,
    String? status,
    String? payloadJson,
    int? revision,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => PlannerFocusSessionRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    entityId: entityId.present ? entityId.value : this.entityId,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    payloadJson: payloadJson ?? this.payloadJson,
    revision: revision ?? this.revision,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PlannerFocusSessionRow copyWithCompanion(PlannerFocusSessionsCompanion data) {
    return PlannerFocusSessionRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      revision: data.revision.present ? data.revision.value : this.revision,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerFocusSessionRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('entityId: $entityId, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('revision: $revision, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    entityId,
    mode,
    status,
    payloadJson,
    revision,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerFocusSessionRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.entityId == this.entityId &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.payloadJson == this.payloadJson &&
          other.revision == this.revision &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlannerFocusSessionsCompanion
    extends UpdateCompanion<PlannerFocusSessionRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String?> entityId;
  final Value<String> mode;
  final Value<String> status;
  final Value<String> payloadJson;
  final Value<int> revision;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PlannerFocusSessionsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerFocusSessionsCompanion.insert({
    required String id,
    required String ownerId,
    this.entityId = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       startedAt = Value(startedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlannerFocusSessionRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? entityId,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? payloadJson,
    Expression<int>? revision,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (entityId != null) 'entity_id': entityId,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (revision != null) 'revision': revision,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerFocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String?>? entityId,
    Value<String>? mode,
    Value<String>? status,
    Value<String>? payloadJson,
    Value<int>? revision,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PlannerFocusSessionsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      entityId: entityId ?? this.entityId,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      payloadJson: payloadJson ?? this.payloadJson,
      revision: revision ?? this.revision,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerFocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('entityId: $entityId, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('revision: $revision, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerOutboxOperationsTable extends PlannerOutboxOperations
    with TableInfo<$PlannerOutboxOperationsTable, PlannerOutboxOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerOutboxOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localSequenceMeta = const VerificationMeta(
    'localSequence',
  );
  @override
  late final GeneratedColumn<int> localSequence = GeneratedColumn<int>(
    'local_sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  @override
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldPatchJsonMeta = const VerificationMeta(
    'fieldPatchJson',
  );
  @override
  late final GeneratedColumn<String> fieldPatchJson = GeneratedColumn<String>(
    'field_patch_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acknowledgedAtMeta = const VerificationMeta(
    'acknowledgedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acknowledgedAt =
      GeneratedColumn<DateTime>(
        'acknowledged_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    localSequence,
    mutationId,
    ownerId,
    targetType,
    targetId,
    entityId,
    entityKind,
    operationType,
    fieldPatchJson,
    baseRevision,
    createdAt,
    state,
    attemptCount,
    lastAttemptAt,
    lastError,
    acknowledgedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_outbox_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerOutboxOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_sequence')) {
      context.handle(
        _localSequenceMeta,
        localSequence.isAcceptableOrUnknown(
          data['local_sequence']!,
          _localSequenceMeta,
        ),
      );
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('field_patch_json')) {
      context.handle(
        _fieldPatchJsonMeta,
        fieldPatchJson.isAcceptableOrUnknown(
          data['field_patch_json']!,
          _fieldPatchJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fieldPatchJsonMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(
        _acknowledgedAtMeta,
        acknowledgedAt.isAcceptableOrUnknown(
          data['acknowledged_at']!,
          _acknowledgedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localSequence};
  @override
  PlannerOutboxOperationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerOutboxOperationRow(
      localSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_sequence'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      ),
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      fieldPatchJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_patch_json'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      acknowledgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acknowledged_at'],
      ),
    );
  }

  @override
  $PlannerOutboxOperationsTable createAlias(String alias) {
    return $PlannerOutboxOperationsTable(attachedDatabase, alias);
  }
}

class PlannerOutboxOperationRow extends DataClass
    implements Insertable<PlannerOutboxOperationRow> {
  final int localSequence;
  final String mutationId;
  final String ownerId;
  final String targetType;
  final String targetId;
  final String? entityId;
  final String? entityKind;
  final String operationType;
  final String fieldPatchJson;
  final int baseRevision;
  final DateTime createdAt;
  final String state;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final DateTime? acknowledgedAt;
  const PlannerOutboxOperationRow({
    required this.localSequence,
    required this.mutationId,
    required this.ownerId,
    required this.targetType,
    required this.targetId,
    this.entityId,
    this.entityKind,
    required this.operationType,
    required this.fieldPatchJson,
    required this.baseRevision,
    required this.createdAt,
    required this.state,
    required this.attemptCount,
    this.lastAttemptAt,
    this.lastError,
    this.acknowledgedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_sequence'] = Variable<int>(localSequence);
    map['mutation_id'] = Variable<String>(mutationId);
    map['owner_id'] = Variable<String>(ownerId);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || entityKind != null) {
      map['entity_kind'] = Variable<String>(entityKind);
    }
    map['operation_type'] = Variable<String>(operationType);
    map['field_patch_json'] = Variable<String>(fieldPatchJson);
    map['base_revision'] = Variable<int>(baseRevision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['state'] = Variable<String>(state);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || acknowledgedAt != null) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt);
    }
    return map;
  }

  PlannerOutboxOperationsCompanion toCompanion(bool nullToAbsent) {
    return PlannerOutboxOperationsCompanion(
      localSequence: Value(localSequence),
      mutationId: Value(mutationId),
      ownerId: Value(ownerId),
      targetType: Value(targetType),
      targetId: Value(targetId),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      entityKind: entityKind == null && nullToAbsent
          ? const Value.absent()
          : Value(entityKind),
      operationType: Value(operationType),
      fieldPatchJson: Value(fieldPatchJson),
      baseRevision: Value(baseRevision),
      createdAt: Value(createdAt),
      state: Value(state),
      attemptCount: Value(attemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      acknowledgedAt: acknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAt),
    );
  }

  factory PlannerOutboxOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerOutboxOperationRow(
      localSequence: serializer.fromJson<int>(json['localSequence']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      entityKind: serializer.fromJson<String?>(json['entityKind']),
      operationType: serializer.fromJson<String>(json['operationType']),
      fieldPatchJson: serializer.fromJson<String>(json['fieldPatchJson']),
      baseRevision: serializer.fromJson<int>(json['baseRevision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      state: serializer.fromJson<String>(json['state']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      acknowledgedAt: serializer.fromJson<DateTime?>(json['acknowledgedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localSequence': serializer.toJson<int>(localSequence),
      'mutationId': serializer.toJson<String>(mutationId),
      'ownerId': serializer.toJson<String>(ownerId),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'entityId': serializer.toJson<String?>(entityId),
      'entityKind': serializer.toJson<String?>(entityKind),
      'operationType': serializer.toJson<String>(operationType),
      'fieldPatchJson': serializer.toJson<String>(fieldPatchJson),
      'baseRevision': serializer.toJson<int>(baseRevision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'state': serializer.toJson<String>(state),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'acknowledgedAt': serializer.toJson<DateTime?>(acknowledgedAt),
    };
  }

  PlannerOutboxOperationRow copyWith({
    int? localSequence,
    String? mutationId,
    String? ownerId,
    String? targetType,
    String? targetId,
    Value<String?> entityId = const Value.absent(),
    Value<String?> entityKind = const Value.absent(),
    String? operationType,
    String? fieldPatchJson,
    int? baseRevision,
    DateTime? createdAt,
    String? state,
    int? attemptCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> acknowledgedAt = const Value.absent(),
  }) => PlannerOutboxOperationRow(
    localSequence: localSequence ?? this.localSequence,
    mutationId: mutationId ?? this.mutationId,
    ownerId: ownerId ?? this.ownerId,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    entityId: entityId.present ? entityId.value : this.entityId,
    entityKind: entityKind.present ? entityKind.value : this.entityKind,
    operationType: operationType ?? this.operationType,
    fieldPatchJson: fieldPatchJson ?? this.fieldPatchJson,
    baseRevision: baseRevision ?? this.baseRevision,
    createdAt: createdAt ?? this.createdAt,
    state: state ?? this.state,
    attemptCount: attemptCount ?? this.attemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    acknowledgedAt: acknowledgedAt.present
        ? acknowledgedAt.value
        : this.acknowledgedAt,
  );
  PlannerOutboxOperationRow copyWithCompanion(
    PlannerOutboxOperationsCompanion data,
  ) {
    return PlannerOutboxOperationRow(
      localSequence: data.localSequence.present
          ? data.localSequence.value
          : this.localSequence,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      fieldPatchJson: data.fieldPatchJson.present
          ? data.fieldPatchJson.value
          : this.fieldPatchJson,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      state: data.state.present ? data.state.value : this.state,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      acknowledgedAt: data.acknowledgedAt.present
          ? data.acknowledgedAt.value
          : this.acknowledgedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerOutboxOperationRow(')
          ..write('localSequence: $localSequence, ')
          ..write('mutationId: $mutationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('entityId: $entityId, ')
          ..write('entityKind: $entityKind, ')
          ..write('operationType: $operationType, ')
          ..write('fieldPatchJson: $fieldPatchJson, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('acknowledgedAt: $acknowledgedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localSequence,
    mutationId,
    ownerId,
    targetType,
    targetId,
    entityId,
    entityKind,
    operationType,
    fieldPatchJson,
    baseRevision,
    createdAt,
    state,
    attemptCount,
    lastAttemptAt,
    lastError,
    acknowledgedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerOutboxOperationRow &&
          other.localSequence == this.localSequence &&
          other.mutationId == this.mutationId &&
          other.ownerId == this.ownerId &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.entityId == this.entityId &&
          other.entityKind == this.entityKind &&
          other.operationType == this.operationType &&
          other.fieldPatchJson == this.fieldPatchJson &&
          other.baseRevision == this.baseRevision &&
          other.createdAt == this.createdAt &&
          other.state == this.state &&
          other.attemptCount == this.attemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError &&
          other.acknowledgedAt == this.acknowledgedAt);
}

class PlannerOutboxOperationsCompanion
    extends UpdateCompanion<PlannerOutboxOperationRow> {
  final Value<int> localSequence;
  final Value<String> mutationId;
  final Value<String> ownerId;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<String?> entityId;
  final Value<String?> entityKind;
  final Value<String> operationType;
  final Value<String> fieldPatchJson;
  final Value<int> baseRevision;
  final Value<DateTime> createdAt;
  final Value<String> state;
  final Value<int> attemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime?> acknowledgedAt;
  const PlannerOutboxOperationsCompanion({
    this.localSequence = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.operationType = const Value.absent(),
    this.fieldPatchJson = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
  });
  PlannerOutboxOperationsCompanion.insert({
    this.localSequence = const Value.absent(),
    required String mutationId,
    required String ownerId,
    required String targetType,
    required String targetId,
    this.entityId = const Value.absent(),
    this.entityKind = const Value.absent(),
    required String operationType,
    required String fieldPatchJson,
    this.baseRevision = const Value.absent(),
    required DateTime createdAt,
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
  }) : mutationId = Value(mutationId),
       ownerId = Value(ownerId),
       targetType = Value(targetType),
       targetId = Value(targetId),
       operationType = Value(operationType),
       fieldPatchJson = Value(fieldPatchJson),
       createdAt = Value(createdAt);
  static Insertable<PlannerOutboxOperationRow> custom({
    Expression<int>? localSequence,
    Expression<String>? mutationId,
    Expression<String>? ownerId,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<String>? entityId,
    Expression<String>? entityKind,
    Expression<String>? operationType,
    Expression<String>? fieldPatchJson,
    Expression<int>? baseRevision,
    Expression<DateTime>? createdAt,
    Expression<String>? state,
    Expression<int>? attemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? acknowledgedAt,
  }) {
    return RawValuesInsertable({
      if (localSequence != null) 'local_sequence': localSequence,
      if (mutationId != null) 'mutation_id': mutationId,
      if (ownerId != null) 'owner_id': ownerId,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (entityId != null) 'entity_id': entityId,
      if (entityKind != null) 'entity_kind': entityKind,
      if (operationType != null) 'operation_type': operationType,
      if (fieldPatchJson != null) 'field_patch_json': fieldPatchJson,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (createdAt != null) 'created_at': createdAt,
      if (state != null) 'state': state,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
    });
  }

  PlannerOutboxOperationsCompanion copyWith({
    Value<int>? localSequence,
    Value<String>? mutationId,
    Value<String>? ownerId,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<String?>? entityId,
    Value<String?>? entityKind,
    Value<String>? operationType,
    Value<String>? fieldPatchJson,
    Value<int>? baseRevision,
    Value<DateTime>? createdAt,
    Value<String>? state,
    Value<int>? attemptCount,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastError,
    Value<DateTime?>? acknowledgedAt,
  }) {
    return PlannerOutboxOperationsCompanion(
      localSequence: localSequence ?? this.localSequence,
      mutationId: mutationId ?? this.mutationId,
      ownerId: ownerId ?? this.ownerId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      entityId: entityId ?? this.entityId,
      entityKind: entityKind ?? this.entityKind,
      operationType: operationType ?? this.operationType,
      fieldPatchJson: fieldPatchJson ?? this.fieldPatchJson,
      baseRevision: baseRevision ?? this.baseRevision,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localSequence.present) {
      map['local_sequence'] = Variable<int>(localSequence.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (fieldPatchJson.present) {
      map['field_patch_json'] = Variable<String>(fieldPatchJson.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (acknowledgedAt.present) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerOutboxOperationsCompanion(')
          ..write('localSequence: $localSequence, ')
          ..write('mutationId: $mutationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('entityId: $entityId, ')
          ..write('entityKind: $entityKind, ')
          ..write('operationType: $operationType, ')
          ..write('fieldPatchJson: $fieldPatchJson, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('acknowledgedAt: $acknowledgedAt')
          ..write(')'))
        .toString();
  }
}

class $PlannerSyncMetadataTable extends PlannerSyncMetadata
    with TableInfo<$PlannerSyncMetadataTable, PlannerSyncMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerSyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteCursorMeta = const VerificationMeta(
    'remoteCursor',
  );
  @override
  late final GeneratedColumn<String> remoteCursor = GeneratedColumn<String>(
    'remote_cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>(
        'last_successful_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    remoteCursor,
    lastSyncAt,
    lastSuccessfulSyncAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerSyncMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('remote_cursor')) {
      context.handle(
        _remoteCursorMeta,
        remoteCursor.isAcceptableOrUnknown(
          data['remote_cursor']!,
          _remoteCursorMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
        _lastSuccessfulSyncAtMeta,
        lastSuccessfulSyncAt.isAcceptableOrUnknown(
          data['last_successful_sync_at']!,
          _lastSuccessfulSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  PlannerSyncMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerSyncMetadataRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      remoteCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_cursor'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_sync_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PlannerSyncMetadataTable createAlias(String alias) {
    return $PlannerSyncMetadataTable(attachedDatabase, alias);
  }
}

class PlannerSyncMetadataRow extends DataClass
    implements Insertable<PlannerSyncMetadataRow> {
  final String ownerId;
  final String? remoteCursor;
  final DateTime? lastSyncAt;
  final DateTime? lastSuccessfulSyncAt;
  final String? lastError;
  const PlannerSyncMetadataRow({
    required this.ownerId,
    this.remoteCursor,
    this.lastSyncAt,
    this.lastSuccessfulSyncAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || remoteCursor != null) {
      map['remote_cursor'] = Variable<String>(remoteCursor);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PlannerSyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return PlannerSyncMetadataCompanion(
      ownerId: Value(ownerId),
      remoteCursor: remoteCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteCursor),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PlannerSyncMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerSyncMetadataRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      remoteCursor: serializer.fromJson<String?>(json['remoteCursor']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'remoteCursor': serializer.toJson<String?>(remoteCursor),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PlannerSyncMetadataRow copyWith({
    String? ownerId,
    Value<String?> remoteCursor = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => PlannerSyncMetadataRow(
    ownerId: ownerId ?? this.ownerId,
    remoteCursor: remoteCursor.present ? remoteCursor.value : this.remoteCursor,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PlannerSyncMetadataRow copyWithCompanion(PlannerSyncMetadataCompanion data) {
    return PlannerSyncMetadataRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      remoteCursor: data.remoteCursor.present
          ? data.remoteCursor.value
          : this.remoteCursor,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerSyncMetadataRow(')
          ..write('ownerId: $ownerId, ')
          ..write('remoteCursor: $remoteCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    remoteCursor,
    lastSyncAt,
    lastSuccessfulSyncAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerSyncMetadataRow &&
          other.ownerId == this.ownerId &&
          other.remoteCursor == this.remoteCursor &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.lastError == this.lastError);
}

class PlannerSyncMetadataCompanion
    extends UpdateCompanion<PlannerSyncMetadataRow> {
  final Value<String> ownerId;
  final Value<String?> remoteCursor;
  final Value<DateTime?> lastSyncAt;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const PlannerSyncMetadataCompanion({
    this.ownerId = const Value.absent(),
    this.remoteCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerSyncMetadataCompanion.insert({
    required String ownerId,
    this.remoteCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId);
  static Insertable<PlannerSyncMetadataRow> custom({
    Expression<String>? ownerId,
    Expression<String>? remoteCursor,
    Expression<DateTime>? lastSyncAt,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (remoteCursor != null) 'remote_cursor': remoteCursor,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerSyncMetadataCompanion copyWith({
    Value<String>? ownerId,
    Value<String?>? remoteCursor,
    Value<DateTime?>? lastSyncAt,
    Value<DateTime?>? lastSuccessfulSyncAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return PlannerSyncMetadataCompanion(
      ownerId: ownerId ?? this.ownerId,
      remoteCursor: remoteCursor ?? this.remoteCursor,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (remoteCursor.present) {
      map['remote_cursor'] = Variable<String>(remoteCursor.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<DateTime>(
        lastSuccessfulSyncAt.value,
      );
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerSyncMetadataCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('remoteCursor: $remoteCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerConflictsTable extends PlannerConflicts
    with TableInfo<$PlannerConflictsTable, PlannerConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldPathsJsonMeta = const VerificationMeta(
    'fieldPathsJson',
  );
  @override
  late final GeneratedColumn<String> fieldPathsJson = GeneratedColumn<String>(
    'field_paths_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localValueJsonMeta = const VerificationMeta(
    'localValueJson',
  );
  @override
  late final GeneratedColumn<String> localValueJson = GeneratedColumn<String>(
    'local_value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteValueJsonMeta = const VerificationMeta(
    'remoteValueJson',
  );
  @override
  late final GeneratedColumn<String> remoteValueJson = GeneratedColumn<String>(
    'remote_value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    targetType,
    targetId,
    mutationId,
    fieldPathsJson,
    localValueJson,
    remoteValueJson,
    baseRevision,
    remoteRevision,
    status,
    createdAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerConflictRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    }
    if (data.containsKey('field_paths_json')) {
      context.handle(
        _fieldPathsJsonMeta,
        fieldPathsJson.isAcceptableOrUnknown(
          data['field_paths_json']!,
          _fieldPathsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fieldPathsJsonMeta);
    }
    if (data.containsKey('local_value_json')) {
      context.handle(
        _localValueJsonMeta,
        localValueJson.isAcceptableOrUnknown(
          data['local_value_json']!,
          _localValueJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localValueJsonMeta);
    }
    if (data.containsKey('remote_value_json')) {
      context.handle(
        _remoteValueJsonMeta,
        remoteValueJson.isAcceptableOrUnknown(
          data['remote_value_json']!,
          _remoteValueJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteValueJsonMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, id};
  @override
  PlannerConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerConflictRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      ),
      fieldPathsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_paths_json'],
      )!,
      localValueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_value_json'],
      )!,
      remoteValueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_value_json'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      ),
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $PlannerConflictsTable createAlias(String alias) {
    return $PlannerConflictsTable(attachedDatabase, alias);
  }
}

class PlannerConflictRow extends DataClass
    implements Insertable<PlannerConflictRow> {
  final String id;
  final String ownerId;
  final String targetType;
  final String targetId;
  final String? mutationId;
  final String fieldPathsJson;
  final String localValueJson;
  final String remoteValueJson;
  final int? baseRevision;
  final int? remoteRevision;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  const PlannerConflictRow({
    required this.id,
    required this.ownerId,
    required this.targetType,
    required this.targetId,
    this.mutationId,
    required this.fieldPathsJson,
    required this.localValueJson,
    required this.remoteValueJson,
    this.baseRevision,
    this.remoteRevision,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    if (!nullToAbsent || mutationId != null) {
      map['mutation_id'] = Variable<String>(mutationId);
    }
    map['field_paths_json'] = Variable<String>(fieldPathsJson);
    map['local_value_json'] = Variable<String>(localValueJson);
    map['remote_value_json'] = Variable<String>(remoteValueJson);
    if (!nullToAbsent || baseRevision != null) {
      map['base_revision'] = Variable<int>(baseRevision);
    }
    if (!nullToAbsent || remoteRevision != null) {
      map['remote_revision'] = Variable<int>(remoteRevision);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  PlannerConflictsCompanion toCompanion(bool nullToAbsent) {
    return PlannerConflictsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      targetType: Value(targetType),
      targetId: Value(targetId),
      mutationId: mutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(mutationId),
      fieldPathsJson: Value(fieldPathsJson),
      localValueJson: Value(localValueJson),
      remoteValueJson: Value(remoteValueJson),
      baseRevision: baseRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(baseRevision),
      remoteRevision: remoteRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteRevision),
      status: Value(status),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory PlannerConflictRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerConflictRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      mutationId: serializer.fromJson<String?>(json['mutationId']),
      fieldPathsJson: serializer.fromJson<String>(json['fieldPathsJson']),
      localValueJson: serializer.fromJson<String>(json['localValueJson']),
      remoteValueJson: serializer.fromJson<String>(json['remoteValueJson']),
      baseRevision: serializer.fromJson<int?>(json['baseRevision']),
      remoteRevision: serializer.fromJson<int?>(json['remoteRevision']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'mutationId': serializer.toJson<String?>(mutationId),
      'fieldPathsJson': serializer.toJson<String>(fieldPathsJson),
      'localValueJson': serializer.toJson<String>(localValueJson),
      'remoteValueJson': serializer.toJson<String>(remoteValueJson),
      'baseRevision': serializer.toJson<int?>(baseRevision),
      'remoteRevision': serializer.toJson<int?>(remoteRevision),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  PlannerConflictRow copyWith({
    String? id,
    String? ownerId,
    String? targetType,
    String? targetId,
    Value<String?> mutationId = const Value.absent(),
    String? fieldPathsJson,
    String? localValueJson,
    String? remoteValueJson,
    Value<int?> baseRevision = const Value.absent(),
    Value<int?> remoteRevision = const Value.absent(),
    String? status,
    DateTime? createdAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => PlannerConflictRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    mutationId: mutationId.present ? mutationId.value : this.mutationId,
    fieldPathsJson: fieldPathsJson ?? this.fieldPathsJson,
    localValueJson: localValueJson ?? this.localValueJson,
    remoteValueJson: remoteValueJson ?? this.remoteValueJson,
    baseRevision: baseRevision.present ? baseRevision.value : this.baseRevision,
    remoteRevision: remoteRevision.present
        ? remoteRevision.value
        : this.remoteRevision,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  PlannerConflictRow copyWithCompanion(PlannerConflictsCompanion data) {
    return PlannerConflictRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      fieldPathsJson: data.fieldPathsJson.present
          ? data.fieldPathsJson.value
          : this.fieldPathsJson,
      localValueJson: data.localValueJson.present
          ? data.localValueJson.value
          : this.localValueJson,
      remoteValueJson: data.remoteValueJson.present
          ? data.remoteValueJson.value
          : this.remoteValueJson,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerConflictRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('mutationId: $mutationId, ')
          ..write('fieldPathsJson: $fieldPathsJson, ')
          ..write('localValueJson: $localValueJson, ')
          ..write('remoteValueJson: $remoteValueJson, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    targetType,
    targetId,
    mutationId,
    fieldPathsJson,
    localValueJson,
    remoteValueJson,
    baseRevision,
    remoteRevision,
    status,
    createdAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerConflictRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.mutationId == this.mutationId &&
          other.fieldPathsJson == this.fieldPathsJson &&
          other.localValueJson == this.localValueJson &&
          other.remoteValueJson == this.remoteValueJson &&
          other.baseRevision == this.baseRevision &&
          other.remoteRevision == this.remoteRevision &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt);
}

class PlannerConflictsCompanion extends UpdateCompanion<PlannerConflictRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<String?> mutationId;
  final Value<String> fieldPathsJson;
  final Value<String> localValueJson;
  final Value<String> remoteValueJson;
  final Value<int?> baseRevision;
  final Value<int?> remoteRevision;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const PlannerConflictsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.fieldPathsJson = const Value.absent(),
    this.localValueJson = const Value.absent(),
    this.remoteValueJson = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerConflictsCompanion.insert({
    required String id,
    required String ownerId,
    required String targetType,
    required String targetId,
    this.mutationId = const Value.absent(),
    required String fieldPathsJson,
    required String localValueJson,
    required String remoteValueJson,
    this.baseRevision = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       targetType = Value(targetType),
       targetId = Value(targetId),
       fieldPathsJson = Value(fieldPathsJson),
       localValueJson = Value(localValueJson),
       remoteValueJson = Value(remoteValueJson),
       createdAt = Value(createdAt);
  static Insertable<PlannerConflictRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<String>? mutationId,
    Expression<String>? fieldPathsJson,
    Expression<String>? localValueJson,
    Expression<String>? remoteValueJson,
    Expression<int>? baseRevision,
    Expression<int>? remoteRevision,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (mutationId != null) 'mutation_id': mutationId,
      if (fieldPathsJson != null) 'field_paths_json': fieldPathsJson,
      if (localValueJson != null) 'local_value_json': localValueJson,
      if (remoteValueJson != null) 'remote_value_json': remoteValueJson,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (remoteRevision != null) 'remote_revision': remoteRevision,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<String?>? mutationId,
    Value<String>? fieldPathsJson,
    Value<String>? localValueJson,
    Value<String>? remoteValueJson,
    Value<int?>? baseRevision,
    Value<int?>? remoteRevision,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return PlannerConflictsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      mutationId: mutationId ?? this.mutationId,
      fieldPathsJson: fieldPathsJson ?? this.fieldPathsJson,
      localValueJson: localValueJson ?? this.localValueJson,
      remoteValueJson: remoteValueJson ?? this.remoteValueJson,
      baseRevision: baseRevision ?? this.baseRevision,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (fieldPathsJson.present) {
      map['field_paths_json'] = Variable<String>(fieldPathsJson.value);
    }
    if (localValueJson.present) {
      map['local_value_json'] = Variable<String>(localValueJson.value);
    }
    if (remoteValueJson.present) {
      map['remote_value_json'] = Variable<String>(remoteValueJson.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerConflictsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('mutationId: $mutationId, ')
          ..write('fieldPathsJson: $fieldPathsJson, ')
          ..write('localValueJson: $localValueJson, ')
          ..write('remoteValueJson: $remoteValueJson, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerImportMarkersTable extends PlannerImportMarkers
    with TableInfo<$PlannerImportMarkersTable, PlannerImportMarkerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerImportMarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFingerprintMeta = const VerificationMeta(
    'sourceFingerprint',
  );
  @override
  late final GeneratedColumn<String> sourceFingerprint =
      GeneratedColumn<String>(
        'source_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    source,
    sourceId,
    importedAt,
    sourceFingerprint,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_import_markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerImportMarkerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('source_fingerprint')) {
      context.handle(
        _sourceFingerprintMeta,
        sourceFingerprint.isAcceptableOrUnknown(
          data['source_fingerprint']!,
          _sourceFingerprintMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, source, sourceId};
  @override
  PlannerImportMarkerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerImportMarkerRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      sourceFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_fingerprint'],
      ),
    );
  }

  @override
  $PlannerImportMarkersTable createAlias(String alias) {
    return $PlannerImportMarkersTable(attachedDatabase, alias);
  }
}

class PlannerImportMarkerRow extends DataClass
    implements Insertable<PlannerImportMarkerRow> {
  final String ownerId;
  final String source;
  final String sourceId;
  final DateTime importedAt;
  final String? sourceFingerprint;
  const PlannerImportMarkerRow({
    required this.ownerId,
    required this.source,
    required this.sourceId,
    required this.importedAt,
    this.sourceFingerprint,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['source'] = Variable<String>(source);
    map['source_id'] = Variable<String>(sourceId);
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || sourceFingerprint != null) {
      map['source_fingerprint'] = Variable<String>(sourceFingerprint);
    }
    return map;
  }

  PlannerImportMarkersCompanion toCompanion(bool nullToAbsent) {
    return PlannerImportMarkersCompanion(
      ownerId: Value(ownerId),
      source: Value(source),
      sourceId: Value(sourceId),
      importedAt: Value(importedAt),
      sourceFingerprint: sourceFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFingerprint),
    );
  }

  factory PlannerImportMarkerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerImportMarkerRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      sourceFingerprint: serializer.fromJson<String?>(
        json['sourceFingerprint'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String>(sourceId),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'sourceFingerprint': serializer.toJson<String?>(sourceFingerprint),
    };
  }

  PlannerImportMarkerRow copyWith({
    String? ownerId,
    String? source,
    String? sourceId,
    DateTime? importedAt,
    Value<String?> sourceFingerprint = const Value.absent(),
  }) => PlannerImportMarkerRow(
    ownerId: ownerId ?? this.ownerId,
    source: source ?? this.source,
    sourceId: sourceId ?? this.sourceId,
    importedAt: importedAt ?? this.importedAt,
    sourceFingerprint: sourceFingerprint.present
        ? sourceFingerprint.value
        : this.sourceFingerprint,
  );
  PlannerImportMarkerRow copyWithCompanion(PlannerImportMarkersCompanion data) {
    return PlannerImportMarkerRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      sourceFingerprint: data.sourceFingerprint.present
          ? data.sourceFingerprint.value
          : this.sourceFingerprint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerImportMarkerRow(')
          ..write('ownerId: $ownerId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('importedAt: $importedAt, ')
          ..write('sourceFingerprint: $sourceFingerprint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ownerId, source, sourceId, importedAt, sourceFingerprint);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerImportMarkerRow &&
          other.ownerId == this.ownerId &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.importedAt == this.importedAt &&
          other.sourceFingerprint == this.sourceFingerprint);
}

class PlannerImportMarkersCompanion
    extends UpdateCompanion<PlannerImportMarkerRow> {
  final Value<String> ownerId;
  final Value<String> source;
  final Value<String> sourceId;
  final Value<DateTime> importedAt;
  final Value<String?> sourceFingerprint;
  final Value<int> rowid;
  const PlannerImportMarkersCompanion({
    this.ownerId = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.sourceFingerprint = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerImportMarkersCompanion.insert({
    required String ownerId,
    required String source,
    required String sourceId,
    required DateTime importedAt,
    this.sourceFingerprint = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       source = Value(source),
       sourceId = Value(sourceId),
       importedAt = Value(importedAt);
  static Insertable<PlannerImportMarkerRow> custom({
    Expression<String>? ownerId,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<DateTime>? importedAt,
    Expression<String>? sourceFingerprint,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (importedAt != null) 'imported_at': importedAt,
      if (sourceFingerprint != null) 'source_fingerprint': sourceFingerprint,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerImportMarkersCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? source,
    Value<String>? sourceId,
    Value<DateTime>? importedAt,
    Value<String?>? sourceFingerprint,
    Value<int>? rowid,
  }) {
    return PlannerImportMarkersCompanion(
      ownerId: ownerId ?? this.ownerId,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      importedAt: importedAt ?? this.importedAt,
      sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (sourceFingerprint.present) {
      map['source_fingerprint'] = Variable<String>(sourceFingerprint.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerImportMarkersCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('importedAt: $importedAt, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerWidgetActionSequencesTable extends PlannerWidgetActionSequences
    with
        TableInfo<
          $PlannerWidgetActionSequencesTable,
          PlannerWidgetActionSequenceRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerWidgetActionSequencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDayMeta = const VerificationMeta(
    'localDay',
  );
  @override
  late final GeneratedColumn<String> localDay = GeneratedColumn<String>(
    'local_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceDomainMeta = const VerificationMeta(
    'sequenceDomain',
  );
  @override
  late final GeneratedColumn<int> sequenceDomain = GeneratedColumn<int>(
    'sequence_domain',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queueSequenceMeta = const VerificationMeta(
    'queueSequence',
  );
  @override
  late final GeneratedColumn<int> queueSequence = GeneratedColumn<int>(
    'queue_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMicrosMeta = const VerificationMeta(
    'occurredAtMicros',
  );
  @override
  late final GeneratedColumn<int> occurredAtMicros = GeneratedColumn<int>(
    'occurred_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionIdMeta = const VerificationMeta(
    'actionId',
  );
  @override
  late final GeneratedColumn<String> actionId = GeneratedColumn<String>(
    'action_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    entityId,
    localDay,
    sequenceDomain,
    queueSequence,
    occurredAtMicros,
    actionId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_widget_action_sequences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerWidgetActionSequenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('local_day')) {
      context.handle(
        _localDayMeta,
        localDay.isAcceptableOrUnknown(data['local_day']!, _localDayMeta),
      );
    } else if (isInserting) {
      context.missing(_localDayMeta);
    }
    if (data.containsKey('sequence_domain')) {
      context.handle(
        _sequenceDomainMeta,
        sequenceDomain.isAcceptableOrUnknown(
          data['sequence_domain']!,
          _sequenceDomainMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceDomainMeta);
    }
    if (data.containsKey('queue_sequence')) {
      context.handle(
        _queueSequenceMeta,
        queueSequence.isAcceptableOrUnknown(
          data['queue_sequence']!,
          _queueSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queueSequenceMeta);
    }
    if (data.containsKey('occurred_at_micros')) {
      context.handle(
        _occurredAtMicrosMeta,
        occurredAtMicros.isAcceptableOrUnknown(
          data['occurred_at_micros']!,
          _occurredAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMicrosMeta);
    }
    if (data.containsKey('action_id')) {
      context.handle(
        _actionIdMeta,
        actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, entityId, localDay};
  @override
  PlannerWidgetActionSequenceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerWidgetActionSequenceRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      localDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day'],
      )!,
      sequenceDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_domain'],
      )!,
      queueSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queue_sequence'],
      )!,
      occurredAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_micros'],
      )!,
      actionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlannerWidgetActionSequencesTable createAlias(String alias) {
    return $PlannerWidgetActionSequencesTable(attachedDatabase, alias);
  }
}

class PlannerWidgetActionSequenceRow extends DataClass
    implements Insertable<PlannerWidgetActionSequenceRow> {
  final String ownerId;
  final String entityId;
  final String localDay;
  final int sequenceDomain;
  final int queueSequence;
  final int occurredAtMicros;
  final String actionId;
  final DateTime updatedAt;
  const PlannerWidgetActionSequenceRow({
    required this.ownerId,
    required this.entityId,
    required this.localDay,
    required this.sequenceDomain,
    required this.queueSequence,
    required this.occurredAtMicros,
    required this.actionId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['entity_id'] = Variable<String>(entityId);
    map['local_day'] = Variable<String>(localDay);
    map['sequence_domain'] = Variable<int>(sequenceDomain);
    map['queue_sequence'] = Variable<int>(queueSequence);
    map['occurred_at_micros'] = Variable<int>(occurredAtMicros);
    map['action_id'] = Variable<String>(actionId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlannerWidgetActionSequencesCompanion toCompanion(bool nullToAbsent) {
    return PlannerWidgetActionSequencesCompanion(
      ownerId: Value(ownerId),
      entityId: Value(entityId),
      localDay: Value(localDay),
      sequenceDomain: Value(sequenceDomain),
      queueSequence: Value(queueSequence),
      occurredAtMicros: Value(occurredAtMicros),
      actionId: Value(actionId),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlannerWidgetActionSequenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerWidgetActionSequenceRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      localDay: serializer.fromJson<String>(json['localDay']),
      sequenceDomain: serializer.fromJson<int>(json['sequenceDomain']),
      queueSequence: serializer.fromJson<int>(json['queueSequence']),
      occurredAtMicros: serializer.fromJson<int>(json['occurredAtMicros']),
      actionId: serializer.fromJson<String>(json['actionId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'entityId': serializer.toJson<String>(entityId),
      'localDay': serializer.toJson<String>(localDay),
      'sequenceDomain': serializer.toJson<int>(sequenceDomain),
      'queueSequence': serializer.toJson<int>(queueSequence),
      'occurredAtMicros': serializer.toJson<int>(occurredAtMicros),
      'actionId': serializer.toJson<String>(actionId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlannerWidgetActionSequenceRow copyWith({
    String? ownerId,
    String? entityId,
    String? localDay,
    int? sequenceDomain,
    int? queueSequence,
    int? occurredAtMicros,
    String? actionId,
    DateTime? updatedAt,
  }) => PlannerWidgetActionSequenceRow(
    ownerId: ownerId ?? this.ownerId,
    entityId: entityId ?? this.entityId,
    localDay: localDay ?? this.localDay,
    sequenceDomain: sequenceDomain ?? this.sequenceDomain,
    queueSequence: queueSequence ?? this.queueSequence,
    occurredAtMicros: occurredAtMicros ?? this.occurredAtMicros,
    actionId: actionId ?? this.actionId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlannerWidgetActionSequenceRow copyWithCompanion(
    PlannerWidgetActionSequencesCompanion data,
  ) {
    return PlannerWidgetActionSequenceRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      localDay: data.localDay.present ? data.localDay.value : this.localDay,
      sequenceDomain: data.sequenceDomain.present
          ? data.sequenceDomain.value
          : this.sequenceDomain,
      queueSequence: data.queueSequence.present
          ? data.queueSequence.value
          : this.queueSequence,
      occurredAtMicros: data.occurredAtMicros.present
          ? data.occurredAtMicros.value
          : this.occurredAtMicros,
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerWidgetActionSequenceRow(')
          ..write('ownerId: $ownerId, ')
          ..write('entityId: $entityId, ')
          ..write('localDay: $localDay, ')
          ..write('sequenceDomain: $sequenceDomain, ')
          ..write('queueSequence: $queueSequence, ')
          ..write('occurredAtMicros: $occurredAtMicros, ')
          ..write('actionId: $actionId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    entityId,
    localDay,
    sequenceDomain,
    queueSequence,
    occurredAtMicros,
    actionId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerWidgetActionSequenceRow &&
          other.ownerId == this.ownerId &&
          other.entityId == this.entityId &&
          other.localDay == this.localDay &&
          other.sequenceDomain == this.sequenceDomain &&
          other.queueSequence == this.queueSequence &&
          other.occurredAtMicros == this.occurredAtMicros &&
          other.actionId == this.actionId &&
          other.updatedAt == this.updatedAt);
}

class PlannerWidgetActionSequencesCompanion
    extends UpdateCompanion<PlannerWidgetActionSequenceRow> {
  final Value<String> ownerId;
  final Value<String> entityId;
  final Value<String> localDay;
  final Value<int> sequenceDomain;
  final Value<int> queueSequence;
  final Value<int> occurredAtMicros;
  final Value<String> actionId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlannerWidgetActionSequencesCompanion({
    this.ownerId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.localDay = const Value.absent(),
    this.sequenceDomain = const Value.absent(),
    this.queueSequence = const Value.absent(),
    this.occurredAtMicros = const Value.absent(),
    this.actionId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerWidgetActionSequencesCompanion.insert({
    required String ownerId,
    required String entityId,
    required String localDay,
    required int sequenceDomain,
    required int queueSequence,
    required int occurredAtMicros,
    required String actionId,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       entityId = Value(entityId),
       localDay = Value(localDay),
       sequenceDomain = Value(sequenceDomain),
       queueSequence = Value(queueSequence),
       occurredAtMicros = Value(occurredAtMicros),
       actionId = Value(actionId),
       updatedAt = Value(updatedAt);
  static Insertable<PlannerWidgetActionSequenceRow> custom({
    Expression<String>? ownerId,
    Expression<String>? entityId,
    Expression<String>? localDay,
    Expression<int>? sequenceDomain,
    Expression<int>? queueSequence,
    Expression<int>? occurredAtMicros,
    Expression<String>? actionId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (entityId != null) 'entity_id': entityId,
      if (localDay != null) 'local_day': localDay,
      if (sequenceDomain != null) 'sequence_domain': sequenceDomain,
      if (queueSequence != null) 'queue_sequence': queueSequence,
      if (occurredAtMicros != null) 'occurred_at_micros': occurredAtMicros,
      if (actionId != null) 'action_id': actionId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerWidgetActionSequencesCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? entityId,
    Value<String>? localDay,
    Value<int>? sequenceDomain,
    Value<int>? queueSequence,
    Value<int>? occurredAtMicros,
    Value<String>? actionId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlannerWidgetActionSequencesCompanion(
      ownerId: ownerId ?? this.ownerId,
      entityId: entityId ?? this.entityId,
      localDay: localDay ?? this.localDay,
      sequenceDomain: sequenceDomain ?? this.sequenceDomain,
      queueSequence: queueSequence ?? this.queueSequence,
      occurredAtMicros: occurredAtMicros ?? this.occurredAtMicros,
      actionId: actionId ?? this.actionId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (localDay.present) {
      map['local_day'] = Variable<String>(localDay.value);
    }
    if (sequenceDomain.present) {
      map['sequence_domain'] = Variable<int>(sequenceDomain.value);
    }
    if (queueSequence.present) {
      map['queue_sequence'] = Variable<int>(queueSequence.value);
    }
    if (occurredAtMicros.present) {
      map['occurred_at_micros'] = Variable<int>(occurredAtMicros.value);
    }
    if (actionId.present) {
      map['action_id'] = Variable<String>(actionId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerWidgetActionSequencesCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('entityId: $entityId, ')
          ..write('localDay: $localDay, ')
          ..write('sequenceDomain: $sequenceDomain, ')
          ..write('queueSequence: $queueSequence, ')
          ..write('occurredAtMicros: $occurredAtMicros, ')
          ..write('actionId: $actionId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PlannerDatabase extends GeneratedDatabase {
  _$PlannerDatabase(QueryExecutor e) : super(e);
  $PlannerDatabaseManager get managers => $PlannerDatabaseManager(this);
  late final $PlannerEntitiesTable plannerEntities = $PlannerEntitiesTable(
    this,
  );
  late final $PlannerSavedViewsTable plannerSavedViews =
      $PlannerSavedViewsTable(this);
  late final $PlannerOccurrencesTable plannerOccurrences =
      $PlannerOccurrencesTable(this);
  late final $PlannerFocusSessionsTable plannerFocusSessions =
      $PlannerFocusSessionsTable(this);
  late final $PlannerOutboxOperationsTable plannerOutboxOperations =
      $PlannerOutboxOperationsTable(this);
  late final $PlannerSyncMetadataTable plannerSyncMetadata =
      $PlannerSyncMetadataTable(this);
  late final $PlannerConflictsTable plannerConflicts = $PlannerConflictsTable(
    this,
  );
  late final $PlannerImportMarkersTable plannerImportMarkers =
      $PlannerImportMarkersTable(this);
  late final $PlannerWidgetActionSequencesTable plannerWidgetActionSequences =
      $PlannerWidgetActionSequencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    plannerEntities,
    plannerSavedViews,
    plannerOccurrences,
    plannerFocusSessions,
    plannerOutboxOperations,
    plannerSyncMetadata,
    plannerConflicts,
    plannerImportMarkers,
    plannerWidgetActionSequences,
  ];
}

typedef $$PlannerEntitiesTableCreateCompanionBuilder =
    PlannerEntitiesCompanion Function({
      required String id,
      required String ownerId,
      required String kind,
      required String payloadJson,
      Value<int> revision,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> serverCreatedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$PlannerEntitiesTableUpdateCompanionBuilder =
    PlannerEntitiesCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> kind,
      Value<String> payloadJson,
      Value<int> revision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> serverCreatedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$PlannerEntitiesTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerEntitiesTable> {
  $$PlannerEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverCreatedAt => $composableBuilder(
    column: $table.serverCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerEntitiesTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerEntitiesTable> {
  $$PlannerEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverCreatedAt => $composableBuilder(
    column: $table.serverCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerEntitiesTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerEntitiesTable> {
  $$PlannerEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverCreatedAt => $composableBuilder(
    column: $table.serverCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PlannerEntitiesTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerEntitiesTable,
          PlannerEntityRow,
          $$PlannerEntitiesTableFilterComposer,
          $$PlannerEntitiesTableOrderingComposer,
          $$PlannerEntitiesTableAnnotationComposer,
          $$PlannerEntitiesTableCreateCompanionBuilder,
          $$PlannerEntitiesTableUpdateCompanionBuilder,
          (
            PlannerEntityRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerEntitiesTable,
              PlannerEntityRow
            >,
          ),
          PlannerEntityRow,
          PrefetchHooks Function()
        > {
  $$PlannerEntitiesTableTableManager(
    _$PlannerDatabase db,
    $PlannerEntitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannerEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> serverCreatedAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerEntitiesCompanion(
                id: id,
                ownerId: ownerId,
                kind: kind,
                payloadJson: payloadJson,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverCreatedAt: serverCreatedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String kind,
                required String payloadJson,
                Value<int> revision = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> serverCreatedAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerEntitiesCompanion.insert(
                id: id,
                ownerId: ownerId,
                kind: kind,
                payloadJson: payloadJson,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverCreatedAt: serverCreatedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerEntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerEntitiesTable,
      PlannerEntityRow,
      $$PlannerEntitiesTableFilterComposer,
      $$PlannerEntitiesTableOrderingComposer,
      $$PlannerEntitiesTableAnnotationComposer,
      $$PlannerEntitiesTableCreateCompanionBuilder,
      $$PlannerEntitiesTableUpdateCompanionBuilder,
      (
        PlannerEntityRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerEntitiesTable,
          PlannerEntityRow
        >,
      ),
      PlannerEntityRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerSavedViewsTableCreateCompanionBuilder =
    PlannerSavedViewsCompanion Function({
      required String id,
      required String ownerId,
      required String definitionJson,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$PlannerSavedViewsTableUpdateCompanionBuilder =
    PlannerSavedViewsCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> definitionJson,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$PlannerSavedViewsTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerSavedViewsTable> {
  $$PlannerSavedViewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionJson => $composableBuilder(
    column: $table.definitionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerSavedViewsTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerSavedViewsTable> {
  $$PlannerSavedViewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionJson => $composableBuilder(
    column: $table.definitionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerSavedViewsTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerSavedViewsTable> {
  $$PlannerSavedViewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get definitionJson => $composableBuilder(
    column: $table.definitionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PlannerSavedViewsTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerSavedViewsTable,
          PlannerSavedViewRow,
          $$PlannerSavedViewsTableFilterComposer,
          $$PlannerSavedViewsTableOrderingComposer,
          $$PlannerSavedViewsTableAnnotationComposer,
          $$PlannerSavedViewsTableCreateCompanionBuilder,
          $$PlannerSavedViewsTableUpdateCompanionBuilder,
          (
            PlannerSavedViewRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerSavedViewsTable,
              PlannerSavedViewRow
            >,
          ),
          PlannerSavedViewRow,
          PrefetchHooks Function()
        > {
  $$PlannerSavedViewsTableTableManager(
    _$PlannerDatabase db,
    $PlannerSavedViewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerSavedViewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerSavedViewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannerSavedViewsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> definitionJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerSavedViewsCompanion(
                id: id,
                ownerId: ownerId,
                definitionJson: definitionJson,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String definitionJson,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerSavedViewsCompanion.insert(
                id: id,
                ownerId: ownerId,
                definitionJson: definitionJson,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerSavedViewsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerSavedViewsTable,
      PlannerSavedViewRow,
      $$PlannerSavedViewsTableFilterComposer,
      $$PlannerSavedViewsTableOrderingComposer,
      $$PlannerSavedViewsTableAnnotationComposer,
      $$PlannerSavedViewsTableCreateCompanionBuilder,
      $$PlannerSavedViewsTableUpdateCompanionBuilder,
      (
        PlannerSavedViewRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerSavedViewsTable,
          PlannerSavedViewRow
        >,
      ),
      PlannerSavedViewRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerOccurrencesTableCreateCompanionBuilder =
    PlannerOccurrencesCompanion Function({
      required String id,
      required String ownerId,
      required String entityId,
      required DateTime plannedFor,
      Value<String> status,
      Value<String> valueJson,
      Value<int> revision,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> missedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$PlannerOccurrencesTableUpdateCompanionBuilder =
    PlannerOccurrencesCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> entityId,
      Value<DateTime> plannedFor,
      Value<String> status,
      Value<String> valueJson,
      Value<int> revision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> missedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$PlannerOccurrencesTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerOccurrencesTable> {
  $$PlannerOccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get missedAt => $composableBuilder(
    column: $table.missedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerOccurrencesTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerOccurrencesTable> {
  $$PlannerOccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get missedAt => $composableBuilder(
    column: $table.missedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerOccurrencesTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerOccurrencesTable> {
  $$PlannerOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get missedAt =>
      $composableBuilder(column: $table.missedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PlannerOccurrencesTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerOccurrencesTable,
          PlannerOccurrenceRow,
          $$PlannerOccurrencesTableFilterComposer,
          $$PlannerOccurrencesTableOrderingComposer,
          $$PlannerOccurrencesTableAnnotationComposer,
          $$PlannerOccurrencesTableCreateCompanionBuilder,
          $$PlannerOccurrencesTableUpdateCompanionBuilder,
          (
            PlannerOccurrenceRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerOccurrencesTable,
              PlannerOccurrenceRow
            >,
          ),
          PlannerOccurrenceRow,
          PrefetchHooks Function()
        > {
  $$PlannerOccurrencesTableTableManager(
    _$PlannerDatabase db,
    $PlannerOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerOccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerOccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannerOccurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<DateTime> plannedFor = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> missedAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerOccurrencesCompanion(
                id: id,
                ownerId: ownerId,
                entityId: entityId,
                plannedFor: plannedFor,
                status: status,
                valueJson: valueJson,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                missedAt: missedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String entityId,
                required DateTime plannedFor,
                Value<String> status = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> missedAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerOccurrencesCompanion.insert(
                id: id,
                ownerId: ownerId,
                entityId: entityId,
                plannedFor: plannedFor,
                status: status,
                valueJson: valueJson,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                missedAt: missedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerOccurrencesTable,
      PlannerOccurrenceRow,
      $$PlannerOccurrencesTableFilterComposer,
      $$PlannerOccurrencesTableOrderingComposer,
      $$PlannerOccurrencesTableAnnotationComposer,
      $$PlannerOccurrencesTableCreateCompanionBuilder,
      $$PlannerOccurrencesTableUpdateCompanionBuilder,
      (
        PlannerOccurrenceRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerOccurrencesTable,
          PlannerOccurrenceRow
        >,
      ),
      PlannerOccurrenceRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerFocusSessionsTableCreateCompanionBuilder =
    PlannerFocusSessionsCompanion Function({
      required String id,
      required String ownerId,
      Value<String?> entityId,
      Value<String> mode,
      Value<String> status,
      Value<String> payloadJson,
      Value<int> revision,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$PlannerFocusSessionsTableUpdateCompanionBuilder =
    PlannerFocusSessionsCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String?> entityId,
      Value<String> mode,
      Value<String> status,
      Value<String> payloadJson,
      Value<int> revision,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$PlannerFocusSessionsTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerFocusSessionsTable> {
  $$PlannerFocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerFocusSessionsTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerFocusSessionsTable> {
  $$PlannerFocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerFocusSessionsTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerFocusSessionsTable> {
  $$PlannerFocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PlannerFocusSessionsTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerFocusSessionsTable,
          PlannerFocusSessionRow,
          $$PlannerFocusSessionsTableFilterComposer,
          $$PlannerFocusSessionsTableOrderingComposer,
          $$PlannerFocusSessionsTableAnnotationComposer,
          $$PlannerFocusSessionsTableCreateCompanionBuilder,
          $$PlannerFocusSessionsTableUpdateCompanionBuilder,
          (
            PlannerFocusSessionRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerFocusSessionsTable,
              PlannerFocusSessionRow
            >,
          ),
          PlannerFocusSessionRow,
          PrefetchHooks Function()
        > {
  $$PlannerFocusSessionsTableTableManager(
    _$PlannerDatabase db,
    $PlannerFocusSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerFocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerFocusSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlannerFocusSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerFocusSessionsCompanion(
                id: id,
                ownerId: ownerId,
                entityId: entityId,
                mode: mode,
                status: status,
                payloadJson: payloadJson,
                revision: revision,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                Value<String?> entityId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerFocusSessionsCompanion.insert(
                id: id,
                ownerId: ownerId,
                entityId: entityId,
                mode: mode,
                status: status,
                payloadJson: payloadJson,
                revision: revision,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerFocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerFocusSessionsTable,
      PlannerFocusSessionRow,
      $$PlannerFocusSessionsTableFilterComposer,
      $$PlannerFocusSessionsTableOrderingComposer,
      $$PlannerFocusSessionsTableAnnotationComposer,
      $$PlannerFocusSessionsTableCreateCompanionBuilder,
      $$PlannerFocusSessionsTableUpdateCompanionBuilder,
      (
        PlannerFocusSessionRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerFocusSessionsTable,
          PlannerFocusSessionRow
        >,
      ),
      PlannerFocusSessionRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerOutboxOperationsTableCreateCompanionBuilder =
    PlannerOutboxOperationsCompanion Function({
      Value<int> localSequence,
      required String mutationId,
      required String ownerId,
      required String targetType,
      required String targetId,
      Value<String?> entityId,
      Value<String?> entityKind,
      required String operationType,
      required String fieldPatchJson,
      Value<int> baseRevision,
      required DateTime createdAt,
      Value<String> state,
      Value<int> attemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
      Value<DateTime?> acknowledgedAt,
    });
typedef $$PlannerOutboxOperationsTableUpdateCompanionBuilder =
    PlannerOutboxOperationsCompanion Function({
      Value<int> localSequence,
      Value<String> mutationId,
      Value<String> ownerId,
      Value<String> targetType,
      Value<String> targetId,
      Value<String?> entityId,
      Value<String?> entityKind,
      Value<String> operationType,
      Value<String> fieldPatchJson,
      Value<int> baseRevision,
      Value<DateTime> createdAt,
      Value<String> state,
      Value<int> attemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
      Value<DateTime?> acknowledgedAt,
    });

class $$PlannerOutboxOperationsTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerOutboxOperationsTable> {
  $$PlannerOutboxOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localSequence => $composableBuilder(
    column: $table.localSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldPatchJson => $composableBuilder(
    column: $table.fieldPatchJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerOutboxOperationsTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerOutboxOperationsTable> {
  $$PlannerOutboxOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localSequence => $composableBuilder(
    column: $table.localSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldPatchJson => $composableBuilder(
    column: $table.fieldPatchJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerOutboxOperationsTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerOutboxOperationsTable> {
  $$PlannerOutboxOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localSequence => $composableBuilder(
    column: $table.localSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldPatchJson => $composableBuilder(
    column: $table.fieldPatchJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => column,
  );
}

class $$PlannerOutboxOperationsTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerOutboxOperationsTable,
          PlannerOutboxOperationRow,
          $$PlannerOutboxOperationsTableFilterComposer,
          $$PlannerOutboxOperationsTableOrderingComposer,
          $$PlannerOutboxOperationsTableAnnotationComposer,
          $$PlannerOutboxOperationsTableCreateCompanionBuilder,
          $$PlannerOutboxOperationsTableUpdateCompanionBuilder,
          (
            PlannerOutboxOperationRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerOutboxOperationsTable,
              PlannerOutboxOperationRow
            >,
          ),
          PlannerOutboxOperationRow,
          PrefetchHooks Function()
        > {
  $$PlannerOutboxOperationsTableTableManager(
    _$PlannerDatabase db,
    $PlannerOutboxOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerOutboxOperationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PlannerOutboxOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlannerOutboxOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> localSequence = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String?> entityKind = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> fieldPatchJson = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> acknowledgedAt = const Value.absent(),
              }) => PlannerOutboxOperationsCompanion(
                localSequence: localSequence,
                mutationId: mutationId,
                ownerId: ownerId,
                targetType: targetType,
                targetId: targetId,
                entityId: entityId,
                entityKind: entityKind,
                operationType: operationType,
                fieldPatchJson: fieldPatchJson,
                baseRevision: baseRevision,
                createdAt: createdAt,
                state: state,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                acknowledgedAt: acknowledgedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> localSequence = const Value.absent(),
                required String mutationId,
                required String ownerId,
                required String targetType,
                required String targetId,
                Value<String?> entityId = const Value.absent(),
                Value<String?> entityKind = const Value.absent(),
                required String operationType,
                required String fieldPatchJson,
                Value<int> baseRevision = const Value.absent(),
                required DateTime createdAt,
                Value<String> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> acknowledgedAt = const Value.absent(),
              }) => PlannerOutboxOperationsCompanion.insert(
                localSequence: localSequence,
                mutationId: mutationId,
                ownerId: ownerId,
                targetType: targetType,
                targetId: targetId,
                entityId: entityId,
                entityKind: entityKind,
                operationType: operationType,
                fieldPatchJson: fieldPatchJson,
                baseRevision: baseRevision,
                createdAt: createdAt,
                state: state,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                acknowledgedAt: acknowledgedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerOutboxOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerOutboxOperationsTable,
      PlannerOutboxOperationRow,
      $$PlannerOutboxOperationsTableFilterComposer,
      $$PlannerOutboxOperationsTableOrderingComposer,
      $$PlannerOutboxOperationsTableAnnotationComposer,
      $$PlannerOutboxOperationsTableCreateCompanionBuilder,
      $$PlannerOutboxOperationsTableUpdateCompanionBuilder,
      (
        PlannerOutboxOperationRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerOutboxOperationsTable,
          PlannerOutboxOperationRow
        >,
      ),
      PlannerOutboxOperationRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerSyncMetadataTableCreateCompanionBuilder =
    PlannerSyncMetadataCompanion Function({
      required String ownerId,
      Value<String?> remoteCursor,
      Value<DateTime?> lastSyncAt,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$PlannerSyncMetadataTableUpdateCompanionBuilder =
    PlannerSyncMetadataCompanion Function({
      Value<String> ownerId,
      Value<String?> remoteCursor,
      Value<DateTime?> lastSyncAt,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$PlannerSyncMetadataTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerSyncMetadataTable> {
  $$PlannerSyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteCursor => $composableBuilder(
    column: $table.remoteCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerSyncMetadataTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerSyncMetadataTable> {
  $$PlannerSyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteCursor => $composableBuilder(
    column: $table.remoteCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerSyncMetadataTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerSyncMetadataTable> {
  $$PlannerSyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get remoteCursor => $composableBuilder(
    column: $table.remoteCursor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PlannerSyncMetadataTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerSyncMetadataTable,
          PlannerSyncMetadataRow,
          $$PlannerSyncMetadataTableFilterComposer,
          $$PlannerSyncMetadataTableOrderingComposer,
          $$PlannerSyncMetadataTableAnnotationComposer,
          $$PlannerSyncMetadataTableCreateCompanionBuilder,
          $$PlannerSyncMetadataTableUpdateCompanionBuilder,
          (
            PlannerSyncMetadataRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerSyncMetadataTable,
              PlannerSyncMetadataRow
            >,
          ),
          PlannerSyncMetadataRow,
          PrefetchHooks Function()
        > {
  $$PlannerSyncMetadataTableTableManager(
    _$PlannerDatabase db,
    $PlannerSyncMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerSyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerSyncMetadataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlannerSyncMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String?> remoteCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerSyncMetadataCompanion(
                ownerId: ownerId,
                remoteCursor: remoteCursor,
                lastSyncAt: lastSyncAt,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                Value<String?> remoteCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerSyncMetadataCompanion.insert(
                ownerId: ownerId,
                remoteCursor: remoteCursor,
                lastSyncAt: lastSyncAt,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerSyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerSyncMetadataTable,
      PlannerSyncMetadataRow,
      $$PlannerSyncMetadataTableFilterComposer,
      $$PlannerSyncMetadataTableOrderingComposer,
      $$PlannerSyncMetadataTableAnnotationComposer,
      $$PlannerSyncMetadataTableCreateCompanionBuilder,
      $$PlannerSyncMetadataTableUpdateCompanionBuilder,
      (
        PlannerSyncMetadataRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerSyncMetadataTable,
          PlannerSyncMetadataRow
        >,
      ),
      PlannerSyncMetadataRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerConflictsTableCreateCompanionBuilder =
    PlannerConflictsCompanion Function({
      required String id,
      required String ownerId,
      required String targetType,
      required String targetId,
      Value<String?> mutationId,
      required String fieldPathsJson,
      required String localValueJson,
      required String remoteValueJson,
      Value<int?> baseRevision,
      Value<int?> remoteRevision,
      Value<String> status,
      required DateTime createdAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });
typedef $$PlannerConflictsTableUpdateCompanionBuilder =
    PlannerConflictsCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> targetType,
      Value<String> targetId,
      Value<String?> mutationId,
      Value<String> fieldPathsJson,
      Value<String> localValueJson,
      Value<String> remoteValueJson,
      Value<int?> baseRevision,
      Value<int?> remoteRevision,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });

class $$PlannerConflictsTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerConflictsTable> {
  $$PlannerConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldPathsJson => $composableBuilder(
    column: $table.fieldPathsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localValueJson => $composableBuilder(
    column: $table.localValueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteValueJson => $composableBuilder(
    column: $table.remoteValueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerConflictsTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerConflictsTable> {
  $$PlannerConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldPathsJson => $composableBuilder(
    column: $table.fieldPathsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localValueJson => $composableBuilder(
    column: $table.localValueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteValueJson => $composableBuilder(
    column: $table.remoteValueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerConflictsTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerConflictsTable> {
  $$PlannerConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldPathsJson => $composableBuilder(
    column: $table.fieldPathsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localValueJson => $composableBuilder(
    column: $table.localValueJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteValueJson => $composableBuilder(
    column: $table.remoteValueJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$PlannerConflictsTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerConflictsTable,
          PlannerConflictRow,
          $$PlannerConflictsTableFilterComposer,
          $$PlannerConflictsTableOrderingComposer,
          $$PlannerConflictsTableAnnotationComposer,
          $$PlannerConflictsTableCreateCompanionBuilder,
          $$PlannerConflictsTableUpdateCompanionBuilder,
          (
            PlannerConflictRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerConflictsTable,
              PlannerConflictRow
            >,
          ),
          PlannerConflictRow,
          PrefetchHooks Function()
        > {
  $$PlannerConflictsTableTableManager(
    _$PlannerDatabase db,
    $PlannerConflictsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannerConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String?> mutationId = const Value.absent(),
                Value<String> fieldPathsJson = const Value.absent(),
                Value<String> localValueJson = const Value.absent(),
                Value<String> remoteValueJson = const Value.absent(),
                Value<int?> baseRevision = const Value.absent(),
                Value<int?> remoteRevision = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerConflictsCompanion(
                id: id,
                ownerId: ownerId,
                targetType: targetType,
                targetId: targetId,
                mutationId: mutationId,
                fieldPathsJson: fieldPathsJson,
                localValueJson: localValueJson,
                remoteValueJson: remoteValueJson,
                baseRevision: baseRevision,
                remoteRevision: remoteRevision,
                status: status,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String targetType,
                required String targetId,
                Value<String?> mutationId = const Value.absent(),
                required String fieldPathsJson,
                required String localValueJson,
                required String remoteValueJson,
                Value<int?> baseRevision = const Value.absent(),
                Value<int?> remoteRevision = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerConflictsCompanion.insert(
                id: id,
                ownerId: ownerId,
                targetType: targetType,
                targetId: targetId,
                mutationId: mutationId,
                fieldPathsJson: fieldPathsJson,
                localValueJson: localValueJson,
                remoteValueJson: remoteValueJson,
                baseRevision: baseRevision,
                remoteRevision: remoteRevision,
                status: status,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerConflictsTable,
      PlannerConflictRow,
      $$PlannerConflictsTableFilterComposer,
      $$PlannerConflictsTableOrderingComposer,
      $$PlannerConflictsTableAnnotationComposer,
      $$PlannerConflictsTableCreateCompanionBuilder,
      $$PlannerConflictsTableUpdateCompanionBuilder,
      (
        PlannerConflictRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerConflictsTable,
          PlannerConflictRow
        >,
      ),
      PlannerConflictRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerImportMarkersTableCreateCompanionBuilder =
    PlannerImportMarkersCompanion Function({
      required String ownerId,
      required String source,
      required String sourceId,
      required DateTime importedAt,
      Value<String?> sourceFingerprint,
      Value<int> rowid,
    });
typedef $$PlannerImportMarkersTableUpdateCompanionBuilder =
    PlannerImportMarkersCompanion Function({
      Value<String> ownerId,
      Value<String> source,
      Value<String> sourceId,
      Value<DateTime> importedAt,
      Value<String?> sourceFingerprint,
      Value<int> rowid,
    });

class $$PlannerImportMarkersTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerImportMarkersTable> {
  $$PlannerImportMarkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerImportMarkersTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerImportMarkersTable> {
  $$PlannerImportMarkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerImportMarkersTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerImportMarkersTable> {
  $$PlannerImportMarkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => column,
  );
}

class $$PlannerImportMarkersTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerImportMarkersTable,
          PlannerImportMarkerRow,
          $$PlannerImportMarkersTableFilterComposer,
          $$PlannerImportMarkersTableOrderingComposer,
          $$PlannerImportMarkersTableAnnotationComposer,
          $$PlannerImportMarkersTableCreateCompanionBuilder,
          $$PlannerImportMarkersTableUpdateCompanionBuilder,
          (
            PlannerImportMarkerRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerImportMarkersTable,
              PlannerImportMarkerRow
            >,
          ),
          PlannerImportMarkerRow,
          PrefetchHooks Function()
        > {
  $$PlannerImportMarkersTableTableManager(
    _$PlannerDatabase db,
    $PlannerImportMarkersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerImportMarkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerImportMarkersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlannerImportMarkersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<String?> sourceFingerprint = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerImportMarkersCompanion(
                ownerId: ownerId,
                source: source,
                sourceId: sourceId,
                importedAt: importedAt,
                sourceFingerprint: sourceFingerprint,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String source,
                required String sourceId,
                required DateTime importedAt,
                Value<String?> sourceFingerprint = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerImportMarkersCompanion.insert(
                ownerId: ownerId,
                source: source,
                sourceId: sourceId,
                importedAt: importedAt,
                sourceFingerprint: sourceFingerprint,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerImportMarkersTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerImportMarkersTable,
      PlannerImportMarkerRow,
      $$PlannerImportMarkersTableFilterComposer,
      $$PlannerImportMarkersTableOrderingComposer,
      $$PlannerImportMarkersTableAnnotationComposer,
      $$PlannerImportMarkersTableCreateCompanionBuilder,
      $$PlannerImportMarkersTableUpdateCompanionBuilder,
      (
        PlannerImportMarkerRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerImportMarkersTable,
          PlannerImportMarkerRow
        >,
      ),
      PlannerImportMarkerRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerWidgetActionSequencesTableCreateCompanionBuilder =
    PlannerWidgetActionSequencesCompanion Function({
      required String ownerId,
      required String entityId,
      required String localDay,
      required int sequenceDomain,
      required int queueSequence,
      required int occurredAtMicros,
      required String actionId,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlannerWidgetActionSequencesTableUpdateCompanionBuilder =
    PlannerWidgetActionSequencesCompanion Function({
      Value<String> ownerId,
      Value<String> entityId,
      Value<String> localDay,
      Value<int> sequenceDomain,
      Value<int> queueSequence,
      Value<int> occurredAtMicros,
      Value<String> actionId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlannerWidgetActionSequencesTableFilterComposer
    extends Composer<_$PlannerDatabase, $PlannerWidgetActionSequencesTable> {
  $$PlannerWidgetActionSequencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceDomain => $composableBuilder(
    column: $table.sequenceDomain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queueSequence => $composableBuilder(
    column: $table.queueSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerWidgetActionSequencesTableOrderingComposer
    extends Composer<_$PlannerDatabase, $PlannerWidgetActionSequencesTable> {
  $$PlannerWidgetActionSequencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceDomain => $composableBuilder(
    column: $table.sequenceDomain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queueSequence => $composableBuilder(
    column: $table.queueSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerWidgetActionSequencesTableAnnotationComposer
    extends Composer<_$PlannerDatabase, $PlannerWidgetActionSequencesTable> {
  $$PlannerWidgetActionSequencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get localDay =>
      $composableBuilder(column: $table.localDay, builder: (column) => column);

  GeneratedColumn<int> get sequenceDomain => $composableBuilder(
    column: $table.sequenceDomain,
    builder: (column) => column,
  );

  GeneratedColumn<int> get queueSequence => $composableBuilder(
    column: $table.queueSequence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionId =>
      $composableBuilder(column: $table.actionId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlannerWidgetActionSequencesTableTableManager
    extends
        RootTableManager<
          _$PlannerDatabase,
          $PlannerWidgetActionSequencesTable,
          PlannerWidgetActionSequenceRow,
          $$PlannerWidgetActionSequencesTableFilterComposer,
          $$PlannerWidgetActionSequencesTableOrderingComposer,
          $$PlannerWidgetActionSequencesTableAnnotationComposer,
          $$PlannerWidgetActionSequencesTableCreateCompanionBuilder,
          $$PlannerWidgetActionSequencesTableUpdateCompanionBuilder,
          (
            PlannerWidgetActionSequenceRow,
            BaseReferences<
              _$PlannerDatabase,
              $PlannerWidgetActionSequencesTable,
              PlannerWidgetActionSequenceRow
            >,
          ),
          PlannerWidgetActionSequenceRow,
          PrefetchHooks Function()
        > {
  $$PlannerWidgetActionSequencesTableTableManager(
    _$PlannerDatabase db,
    $PlannerWidgetActionSequencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerWidgetActionSequencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PlannerWidgetActionSequencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlannerWidgetActionSequencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> localDay = const Value.absent(),
                Value<int> sequenceDomain = const Value.absent(),
                Value<int> queueSequence = const Value.absent(),
                Value<int> occurredAtMicros = const Value.absent(),
                Value<String> actionId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerWidgetActionSequencesCompanion(
                ownerId: ownerId,
                entityId: entityId,
                localDay: localDay,
                sequenceDomain: sequenceDomain,
                queueSequence: queueSequence,
                occurredAtMicros: occurredAtMicros,
                actionId: actionId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String entityId,
                required String localDay,
                required int sequenceDomain,
                required int queueSequence,
                required int occurredAtMicros,
                required String actionId,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlannerWidgetActionSequencesCompanion.insert(
                ownerId: ownerId,
                entityId: entityId,
                localDay: localDay,
                sequenceDomain: sequenceDomain,
                queueSequence: queueSequence,
                occurredAtMicros: occurredAtMicros,
                actionId: actionId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerWidgetActionSequencesTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerDatabase,
      $PlannerWidgetActionSequencesTable,
      PlannerWidgetActionSequenceRow,
      $$PlannerWidgetActionSequencesTableFilterComposer,
      $$PlannerWidgetActionSequencesTableOrderingComposer,
      $$PlannerWidgetActionSequencesTableAnnotationComposer,
      $$PlannerWidgetActionSequencesTableCreateCompanionBuilder,
      $$PlannerWidgetActionSequencesTableUpdateCompanionBuilder,
      (
        PlannerWidgetActionSequenceRow,
        BaseReferences<
          _$PlannerDatabase,
          $PlannerWidgetActionSequencesTable,
          PlannerWidgetActionSequenceRow
        >,
      ),
      PlannerWidgetActionSequenceRow,
      PrefetchHooks Function()
    >;

class $PlannerDatabaseManager {
  final _$PlannerDatabase _db;
  $PlannerDatabaseManager(this._db);
  $$PlannerEntitiesTableTableManager get plannerEntities =>
      $$PlannerEntitiesTableTableManager(_db, _db.plannerEntities);
  $$PlannerSavedViewsTableTableManager get plannerSavedViews =>
      $$PlannerSavedViewsTableTableManager(_db, _db.plannerSavedViews);
  $$PlannerOccurrencesTableTableManager get plannerOccurrences =>
      $$PlannerOccurrencesTableTableManager(_db, _db.plannerOccurrences);
  $$PlannerFocusSessionsTableTableManager get plannerFocusSessions =>
      $$PlannerFocusSessionsTableTableManager(_db, _db.plannerFocusSessions);
  $$PlannerOutboxOperationsTableTableManager get plannerOutboxOperations =>
      $$PlannerOutboxOperationsTableTableManager(
        _db,
        _db.plannerOutboxOperations,
      );
  $$PlannerSyncMetadataTableTableManager get plannerSyncMetadata =>
      $$PlannerSyncMetadataTableTableManager(_db, _db.plannerSyncMetadata);
  $$PlannerConflictsTableTableManager get plannerConflicts =>
      $$PlannerConflictsTableTableManager(_db, _db.plannerConflicts);
  $$PlannerImportMarkersTableTableManager get plannerImportMarkers =>
      $$PlannerImportMarkersTableTableManager(_db, _db.plannerImportMarkers);
  $$PlannerWidgetActionSequencesTableTableManager
  get plannerWidgetActionSequences =>
      $$PlannerWidgetActionSequencesTableTableManager(
        _db,
        _db.plannerWidgetActionSequences,
      );
}
