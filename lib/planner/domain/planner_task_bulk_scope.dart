import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_task_bulk.dart';

/// Stage 36 eligibility rule shared by the Tasks bulk bar and the
/// bulk preview sheet: the page builds both from this one helper so
/// counts and the preview row split can never disagree.
PlannerTasksBulkPlan planVisibleTasksBulk({
  required List<String> orderedIds,
  required Set<String> selectedIds,
  required PlannerTasksBulkAction action,
  required PlannerEntity? Function(String id) entityById,
}) {
  bool isEligible(String id, PlannerEntity? entity) {
    if (entity == null) return false;
    if (action == PlannerTasksBulkAction.complete) {
      if (entity.kind != PlannerEntityKind.oneOffTask &&
          entity.kind != PlannerEntityKind.recurringTask) {
        return false;
      }
      return entity.status == PlannerEntityStatus.active;
    }
    if (action == PlannerTasksBulkAction.reopen) {
      return entity.status == PlannerEntityStatus.completed;
    }
    return true;
  }

  return planTasksBulk(
    orderedIds: orderedIds,
    selectedIds: selectedIds,
    isEligible: (id) => isEligible(id, entityById(id)),
    skipReason: (id) {
      final entity = entityById(id);
      if (entity == null) {
        return 'Task is no longer available locally.';
      }
      if (action == PlannerTasksBulkAction.complete &&
          entity.status != PlannerEntityStatus.active) {
        return 'Only open tasks can be completed in bulk.';
      }
      if (action == PlannerTasksBulkAction.reopen &&
          entity.status != PlannerEntityStatus.completed) {
        return 'Only completed tasks can be reopened in bulk.';
      }
      return 'Scheduled and move targets need the Refine surface first.';
    },
  );
}
