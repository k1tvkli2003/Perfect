import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_saved_view.dart';
import 'package:perfect/planner/domain/planner_task_query.dart';

/// RED tracer 5 — Stage 36: owner-scoped saved-view contract.
///
/// Covers the spec surface that later tracers build on: stable ID identity,
/// schema version + migration, forward-compatible unknown-field round trip,
/// reserved built-in namespace with remote-overwrite rejection, and
/// active-view fallback to Open.
void main() {
  PlannerSavedView customView() => PlannerSavedView(
    id: 'view-bills',
    ownerId: 'owner-a',
    schemaVersion: PlannerSavedView.currentSchemaVersion,
    title: 'Bills',
    iconKey: 'receipt',
    query: const PlannerTaskQuery(
      viewId: PlannerTaskQuery.completedViewId,
      text: 'bills',
      kinds: {PlannerEntityKind.oneOffTask},
    ),
    createdAt: DateTime.utc(2026, 9, 1, 8),
    updatedAt: DateTime.utc(2026, 9, 2, 9),
  );

  test('encode/decode round trip preserves every field', () {
    final view = customView();

    final encoded = view.toJson();
    final decoded = PlannerSavedView.fromJson(
      Map<String, dynamic>.from(encoded),
    );

    expect(decoded.id, view.id);
    expect(decoded.ownerId, view.ownerId);
    expect(decoded.schemaVersion, view.schemaVersion);
    expect(decoded.title, view.title);
    expect(decoded.iconKey, view.iconKey);
    expect(decoded.query.viewId, view.query.viewId);
    expect(decoded.query.text, view.query.text);
    expect(decoded.query.kinds, view.query.kinds);
    expect(decoded.createdAt, view.createdAt);
    expect(decoded.updatedAt, view.updatedAt);
    expect(decoded.revision, view.revision);
    expect(decoded.deletedAt, isNull);
    expect(decoded.toJson(), encoded);
  });

  test('unknown fields survive a decode/encode round trip', () {
    final raw = <String, dynamic>{
      ...customView().toJson(),
      'future_flag': true,
      'query': <String, dynamic>{
        ...customView().query.toJson(),
        'future_mode': 'grouped',
      },
    };

    final decoded = PlannerSavedView.fromJson(raw);

    expect(decoded.title, 'Bills');
    expect(decoded.query.viewId, PlannerTaskQuery.completedViewId);
    final reEncoded = decoded.toJson();
    expect(reEncoded['future_flag'], isTrue);
    expect(
      (reEncoded['query'] as Map<String, dynamic>)['future_mode'],
      'grouped',
    );
  });

  test('missing schemaVersion migrates to the current version', () {
    final raw = Map<String, dynamic>.from(customView().toJson())
      ..remove('schema_version');

    final decoded = PlannerSavedView.fromJson(raw);

    expect(decoded.schemaVersion, PlannerSavedView.currentSchemaVersion);
    expect(decoded.id, 'view-bills');
  });

  test(
    'built-in IDs use the reserved namespace and reject remote overwrite',
    () {
      final builtIn = PlannerSavedView(
        id: '${PlannerSavedView.builtInNamespacePrefix}open',
        ownerId: 'owner-a',
        schemaVersion: PlannerSavedView.currentSchemaVersion,
        title: 'Open',
        iconKey: 'inbox',
        query: PlannerTaskQuery.builtIn(PlannerTaskQuery.openViewId),
        createdAt: DateTime.utc(2026, 9, 1, 8),
        updatedAt: DateTime.utc(2026, 9, 1, 8),
      );

      expect(builtIn.isBuiltIn, isTrue);
      expect(customView().isBuiltIn, isFalse);
      expect(builtIn.canApplyRemote(isRemote: true), isFalse);
      expect(builtIn.canApplyRemote(isRemote: false), isTrue);
      expect(customView().canApplyRemote(isRemote: true), isTrue);
    },
  );

  test(
    'active-view preference falls back to Open when stored ID is missing',
    () {
      expect(
        PlannerSavedView.resolveActiveViewId(
          storedId: 'view-bills',
          availableIds: const {'view-bills', 'builtin:open'},
        ),
        'view-bills',
      );
      expect(
        PlannerSavedView.resolveActiveViewId(
          storedId: 'view-deleted',
          availableIds: const {'view-bills', 'builtin:open'},
        ),
        'builtin:open',
      );
      expect(
        PlannerSavedView.resolveActiveViewId(
          storedId: null,
          availableIds: const {'view-bills'},
        ),
        'builtin:open',
      );
    },
  );

  test('title is not identity: rename preserves stable ID and query', () {
    final renamed = customView().copyWith(title: 'Utility bills');

    expect(renamed.id, 'view-bills');
    expect(renamed.title, 'Utility bills');
    expect(renamed.query.viewId, PlannerTaskQuery.completedViewId);
  });
}
