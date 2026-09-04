/// The original, intentionally minimal personal-item record.
///
/// Perfect's planner has since grown into a rich, owner-scoped entity model
/// (Task, Habit, Project, Area, Recurring Task) backed by [PlannerEntity].
/// [PersonalItem] predates that system and survives only as the legacy
/// application contract: one-time migration, durable local JSON, and the
/// recovery path that the new planner must never break.
///
/// New planner capabilities belong in `lib/planner/domain/`.
class PersonalItem {
  const PersonalItem({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.dirty = false,
  });

  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;

  bool get isDeleted => deletedAt != null;

  PersonalItem copyWith({
    String? title,
    bool? isDone,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? dirty,
  }) => PersonalItem(
    id: id,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    dirty: dirty ?? this.dirty,
  );

  Map<String, dynamic> toLocalJson() => {...toRemoteJson(), 'dirty': dirty};

  Map<String, dynamic> toRemoteJson() => {
    'id': id,
    'title': title,
    'is_done': isDone,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  factory PersonalItem.fromJson(Map<String, dynamic> json) => PersonalItem(
    id: json['id'] as String,
    title: json['title'] as String,
    isDone: json['is_done'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    deletedAt: json['deleted_at'] == null
        ? null
        : DateTime.parse(json['deleted_at'] as String).toUtc(),
    dirty: json['dirty'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is PersonalItem &&
      other.id == id &&
      other.title == title &&
      other.isDone == isDone &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt &&
      other.dirty == dirty;

  @override
  int get hashCode => Object.hash(id, title, isDone, createdAt, updatedAt, deletedAt, dirty);
}
