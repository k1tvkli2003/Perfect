import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:perfect/widgets/perfect_today_widget_projector.dart';

/// Runs from Android WorkManager after a native widget check control is tapped.
///
/// It never performs network I/O. The only durable effect is the same local
/// planner mutation/outbox entry that a foreground app interaction would make.
/// Sync remains asynchronous when the normal private workspace is available.
@pragma('vm:entry-point')
Future<void> perfectTodayWidgetBackgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final action = PerfectTodayWidgetBridge.actionFromBackgroundUri(uri);
  final refresh = PerfectTodayWidgetBridge.refreshRequestFromBackgroundUri(uri);
  final candidateToken = uri?.queryParameters['token'];
  if ((action == null && refresh == null) ||
      candidateToken == null ||
      candidateToken.isEmpty) {
    return;
  }

  final bridge = const PerfectTodayWidgetBridge();
  final security = await bridge.readSecurityContext();
  if (security == null ||
      security.ownerId != (action?.ownerId ?? refresh?.ownerId) ||
      !PerfectTodayWidgetBridge.secretsMatch(security.token, candidateToken)) {
    return;
  }

  final database = PlannerDatabase();
  final store = PlannerLocalStore(database);
  try {
    if (action != null) {
      // home_widget's WorkManager callback can overlap while Dart awaits
      // SQLite. Replaying the entire bounded, time-sorted native queue in every
      // callback makes those workers converge: older mutation IDs become
      // idempotent no-ops and can never overwrite a newer outcome.
      final queuedActions = <PlannerWidgetTaskAction>[
        ...await bridge.pendingActions(),
        action,
      ];
      await replayPerfectTodayWidgetActions(
        store: store,
        ownerId: security.ownerId,
        actions: queuedActions,
      );
      await bridge.acknowledgeActions(
        queuedActions
            .where((queued) => queued.ownerId == security.ownerId)
            .map((queued) => queued.id),
      );
    }
    await PerfectTodayWidgetProjector(
      store,
      ownerId: security.ownerId,
      bridge: bridge,
    ).publish();
  } on Object catch (_) {
    // The bounded native replay queue stays intact for task actions. A future
    // foreground launch retries the idempotent mutation and republishes Today.
    // A day refresh is also retried by the widget's periodic update contract.
  } finally {
    await store.close();
  }
}

/// Replays the native queue in event order. A single archived/stale row is a
/// semantic no-op and must not permanently block newer valid taps behind it;
/// actual database failures still escape so WorkManager can retry later.
Future<void> replayPerfectTodayWidgetActions({
  required PlannerLocalStore store,
  required String ownerId,
  required Iterable<PlannerWidgetTaskAction> actions,
}) async {
  final queuedById = <String, PlannerWidgetTaskAction>{
    for (final queued in actions)
      if (queued.ownerId == ownerId) queued.id: queued,
  };
  final queuedActions = queuedById.values.toList()
    ..sort((first, second) => first.compareReplayOrder(second));
  for (final queued in queuedActions) {
    try {
      await PlannerTaskProgressService(
        store,
        ownerId: ownerId,
        now: () => queued.occurredAt,
      ).applyWidgetAction(queued);
    } on StateError {
      // Archived, deleted, owner-mismatched, or stale-kind rows are no longer
      // actionable. Keep draining the later entries in the bounded queue.
    }
  }
}

/// Keeps the home_widget callback handle registered after a normal app launch.
/// This is harmless when the user has not pinned the Android widget yet.
Future<void> registerPerfectTodayWidgetBackgroundCallback() async {
  try {
    await HomeWidget.registerInteractivityCallback(
      perfectTodayWidgetBackgroundCallback,
    );
  } on Object catch (_) {
    // Widget registration must not block sign-in or the local-first planner.
  }
}
