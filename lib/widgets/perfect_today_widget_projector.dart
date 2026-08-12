import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';

/// Builds the single canonical Android Today-widget projection.
///
/// Both the foreground controller and the background day-rollover worker use
/// this class. That keeps recurrence, recovery, sort order, privacy, and
/// four-state progress identical even when Flutter's main isolate is absent.
class PerfectTodayWidgetProjector {
  PerfectTodayWidgetProjector(
    this._localStore, {
    required this.ownerId,
    PerfectTodayWidgetBridge? bridge,
    PlannerTaskProgressService? taskProgressService,
    DateTime Function()? now,
  }) : _bridge = bridge ?? const PerfectTodayWidgetBridge(),
       _now = now ?? DateTime.now,
       _taskProgressService =
           taskProgressService ??
           PlannerTaskProgressService(_localStore, ownerId: ownerId, now: now);

  final PlannerLocalStore _localStore;
  final String ownerId;
  final PerfectTodayWidgetBridge _bridge;
  final PlannerTaskProgressService _taskProgressService;
  final DateTime Function() _now;

  Future<void> publish({
    Iterable<PlannerEntity>? entities,
    PerfectTodayWidgetSettings? settings,
  }) async {
    final effectiveSettings = settings ?? await _bridge.readSettings();
    if (!effectiveSettings.isAvailable || ownerId.trim().isEmpty) return;

    final localNow = _now().toLocal();
    final day = DateTime(localNow.year, localNow.month, localNow.day);
    final source =
        entities?.toList(growable: false) ??
        await _localStore.readActiveEntities(ownerId);
    final candidates = <PlannerEntity>[];
    for (final entity in source) {
      if (entity.kind != PlannerEntityKind.oneOffTask &&
          entity.kind != PlannerEntityKind.recurringTask) {
        continue;
      }
      final eligibility = await _localStore.evaluateTodayEligibility(
        ownerId: ownerId,
        entity: entity,
        day: day,
      );
      if (eligibility.isEligible) candidates.add(entity);
    }
    candidates.sort(_compareForTimeline);

    final items = await Future.wait<PerfectTodayWidgetItem>(
      candidates.map((entity) async {
        final scheduled = entity.scheduledAt?.toLocal();
        return PerfectTodayWidgetItem(
          entityId: entity.id,
          kind: entity.kind,
          title: entity.title,
          timeLabel: scheduled == null ? 'Inbox' : _timeLabel(scheduled),
          progress: await _taskProgressService.readProgress(
            entity,
            localDay: day,
          ),
          accent: _accent(entity),
        );
      }),
    );

    await _bridge.publish(
      ownerId: ownerId,
      now: localNow,
      items: items,
      showTaskTitles: effectiveSettings.showTaskTitles,
    );
  }
}

int _compareForTimeline(PlannerEntity first, PlannerEntity second) {
  final firstTime = _minutesOfDay(first.scheduledAt?.toLocal());
  final secondTime = _minutesOfDay(second.scheduledAt?.toLocal());
  final byTime = firstTime.compareTo(secondTime);
  if (byTime != 0) return byTime;
  return first.title.toLowerCase().compareTo(second.title.toLowerCase());
}

int _minutesOfDay(DateTime? value) =>
    value == null ? -1 : value.hour * 60 + value.minute;

String _accent(PlannerEntity entity) {
  final category = safeJsonString(
    entity.payload['category'],
    fallback: '',
  ).toLowerCase();
  if (<String>{'health', 'home', 'personal'}.contains(category)) return 'mint';
  if (<String>{'study', 'finance'}.contains(category) ||
      entity.kind == PlannerEntityKind.recurringTask) {
    return 'lilac';
  }
  return 'apricot';
}

String _timeLabel(DateTime value) {
  return PerfectLocalTime.clock(value);
}
