import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';

/// An owner-scoped saved Tasks workspace view: Stage 36 contract.
///
/// Identity is the stable [id]; [title] is display text only and renames
/// never change identity. Built-in IDs live under the reserved
/// [builtInNamespacePrefix] namespace and cannot be overwritten remotely —
/// a remote payload for a built-in ID is rejected via [canApplyRemote].
/// Unknown JSON fields are preserved through decode/encode round trips so an
/// older client never drops a newer client's data. Missing [schemaVersion]
/// migrates to [currentSchemaVersion].
class PlannerSavedView {
  PlannerSavedView({
    required this.id,
    required this.ownerId,
    required this.schemaVersion,
    required this.title,
    required this.iconKey,
    required this.query,
    required this.createdAt,
    required this.updatedAt,
    this.revision = 0,
    this.deletedAt,
    Map<String, dynamic> unknownFields = const <String, dynamic>{},
  }) : unknownFields = Map<String, dynamic>.unmodifiable(unknownFields);

  static const int currentSchemaVersion = 1;

  static const String builtInNamespacePrefix = 'builtin:';

  /// Fallback active view when the stored ID is missing or unknown.
  static const String fallbackViewId = '${builtInNamespacePrefix}open';

  final String id;
  final String ownerId;
  final int schemaVersion;
  final String title;
  final String iconKey;
  final PlannerTaskQuery query;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final DateTime? deletedAt;

  /// Forward-compatible fields this client does not understand, preserved
  /// verbatim through [toJson].
  final Map<String, dynamic> unknownFields;

  bool get isBuiltIn => id.startsWith(builtInNamespacePrefix);

  bool get isDeleted => deletedAt != null;

  /// Built-in definitions are local-only: a remote write for a built-in ID
  /// is rejected so one device can never disrupt another's built-in views.
  /// Custom views accept both local and remote writes.
  bool canApplyRemote({required bool isRemote}) {
    if (isRemote && isBuiltIn) return false;
    return true;
  }

  /// Resolves the stored active-view preference: the stored ID when it is
  /// still available, otherwise the Open fallback. Never returns null and
  /// never invents an ID.
  static String resolveActiveViewId({
    required String? storedId,
    required Set<String> availableIds,
  }) {
    if (storedId != null && availableIds.contains(storedId)) return storedId;
    return fallbackViewId;
  }

  PlannerSavedView copyWith({
    String? title,
    String? iconKey,
    PlannerTaskQuery? query,
    DateTime? updatedAt,
    int? revision,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => PlannerSavedView(
    id: id,
    ownerId: ownerId,
    schemaVersion: schemaVersion,
    title: title ?? this.title,
    iconKey: iconKey ?? this.iconKey,
    query: query ?? this.query,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    unknownFields: unknownFields,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'owner_id': ownerId,
    'schema_version': schemaVersion,
    'title': title,
    'icon_key': iconKey,
    'query': query.toJson(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'revision': revision,
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
    ...unknownFields,
  };

  factory PlannerSavedView.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    final rawQuery = json['query'];
    const knownKeys = <String>{
      'id',
      'owner_id',
      'schema_version',
      'title',
      'icon_key',
      'query',
      'created_at',
      'updated_at',
      'revision',
      'deleted_at',
    };
    final unknown = <String, dynamic>{};
    for (final entry in json.entries) {
      final key = entry.key.toString();
      if (!knownKeys.contains(key)) unknown[key] = entry.value;
    }
    return PlannerSavedView(
      id: safeJsonString(json['id'], fallback: 'invalid-view'),
      ownerId: safeJsonString(json['owner_id'], fallback: 'unknown-owner'),
      schemaVersion: json['schema_version'] is int
          ? (json['schema_version'] as int)
          : currentSchemaVersion,
      title: safeJsonString(json['title'], fallback: 'Untitled view'),
      iconKey: safeJsonString(json['icon_key'], fallback: 'view'),
      query: rawQuery is Map<String, dynamic>
          ? PlannerTaskQuery.fromJson(rawQuery)
          : PlannerTaskQuery.builtIn(PlannerTaskQuery.openViewId),
      createdAt: safeJsonDateTime(json['created_at']) ?? now,
      updatedAt:
          safeJsonDateTime(json['updated_at']) ??
          safeJsonDateTime(json['created_at']) ??
          now,
      revision: safeJsonInt(json['revision'], fallback: 0),
      deletedAt: safeJsonDateTime(json['deleted_at']),
      unknownFields: unknown,
    );
  }
}
