import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';

/// Stable status target shared by task rows. The action still belongs to its
/// host; the visual state comes only from the canonical progress model.
class TaskStatusControl extends StatelessWidget {
  const TaskStatusControl({
    super.key,
    required this.progress,
    required this.color,
    required this.onPressed,
    this.enabled = true,
  });

  final PlannerTaskProgress progress;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = progress.normalized;
    final state = normalized.state;
    final partial = state == PlannerTaskProgressState.partial;
    final completed = state == PlannerTaskProgressState.completed;
    final missed = state == PlannerTaskProgressState.missed;
    final visualColor = completed
        ? scheme.tertiary
        : missed
        ? scheme.error
        : partial
        ? color
        : scheme.onSurfaceVariant;
    final tooltip = switch (state) {
      PlannerTaskProgressState.pending => 'Mark done',
      PlannerTaskProgressState.completed => 'Mark not done',
      PlannerTaskProgressState.missed =>
        'Mark ${normalized.percent == 0 ? '50%' : '${normalized.percent}%'} progress',
      PlannerTaskProgressState.partial =>
        '${normalized.percent}% progress · clear task outcome',
    };
    final statusValue = switch (state) {
      PlannerTaskProgressState.pending => 'Pending',
      PlannerTaskProgressState.completed => 'Completed',
      PlannerTaskProgressState.missed => 'Missed',
      PlannerTaskProgressState.partial => '${normalized.percent}% progress',
    };

    return Semantics(
      button: true,
      enabled: enabled,
      value: statusValue,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: InkWell(
          key: const ValueKey<String>('task-status-hit'),
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: ExcludeSemantics(
                child: SizedBox.square(
                  key: const ValueKey<String>('task-status-glyph'),
                  dimension: 30,
                  child: partial || state == PlannerTaskProgressState.pending
                      ? CircularProgressIndicator(
                          value: partial ? normalized.percent / 100 : 0,
                          strokeWidth: 2.8,
                          strokeCap: StrokeCap.round,
                          color: visualColor,
                          backgroundColor: partial
                              ? scheme.onSurfaceVariant.withValues(alpha: .3)
                              : visualColor.withValues(alpha: .45),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: visualColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            completed
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 20,
                            color: completed
                                ? scheme.onTertiary
                                : scheme.onError,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
