import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_tasks_copy.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// Bulk action surface for the Tasks selection (Stage 36 tracer 15).
///
/// Intent-only owner for `ws-bulk-bar`: this widget never writes persistence
/// and never imports a controller or store. It announces the selection state
/// through a single semantic owner and emits [onOpenPreview] /
/// [onClearSelection] intents for its host to execute.
class TasksBulkBar extends StatelessWidget {
  const TasksBulkBar({
    super.key,
    required this.selectedCount,
    required this.eligibleCount,
    required this.skippedCount,
    required this.onOpenPreview,
    required this.onClearSelection,
  });

  final int selectedCount;
  final int eligibleCount;
  final int skippedCount;
  final VoidCallback onOpenPreview;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final title = PlannerTasksCopy.titleFor('pg-tasks-bulk');
    final subtitle = PlannerTasksCopy.defaultSubtitle;
    final semantic = PerfectSemanticTheme.of(context);
    final value =
        '$selectedCount selected · $eligibleCount eligible · $skippedCount skipped';
    return Semantics(
      container: true,
      label: '$title. $subtitle',
      value: value,
      child: AnimatedContainer(
        key: const ValueKey<String>('tasks-bulk-bar'),
        duration: PerfectMotion.responsive(context, PerfectMotion.quick),
        curve: PerfectMotion.productive,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(PerfectRadius.card),
          border: Border.all(
            color: skippedCount > 0
                ? Theme.of(context).colorScheme.outline
                : semantic.outline,
          ),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(
          PerfectSpace.md,
          PerfectSpace.sm,
          PerfectSpace.md,
          PerfectSpace.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: PerfectSpace.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: PerfectSpace.sm),
            Wrap(
              spacing: PerfectSpace.sm,
              runSpacing: PerfectSpace.sm,
              children: [
                FilledButton(
                  key: const ValueKey<String>('tasks-bulk-preview'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: onOpenPreview,
                  child: const Text('Preview'),
                ),
                TextButton(
                  key: const ValueKey<String>('tasks-bulk-clear'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: onClearSelection,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation surface for one bulk run: eligible IDs plus skipped IDs with
/// reasons, then confirm/cancel intents. Stateless and persistence-free; the
/// host executes the frozen receipt after [onConfirm].
class TasksBulkPreviewSheet extends StatelessWidget {
  const TasksBulkPreviewSheet({
    super.key,
    required this.actionLabel,
    required this.eligibleIds,
    required this.skippedReasons,
    required this.onConfirm,
    required this.onCancel,
  });

  final String actionLabel;
  final List<String> eligibleIds;
  final Map<String, String> skippedReasons;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final title = PlannerTasksCopy.titleFor('pg-tasks-bulk');
    final subtitle = PlannerTasksCopy.defaultSubtitle;
    final value =
        '${eligibleIds.length} eligible · ${skippedReasons.length} skipped';
    return Semantics(
      container: true,
      label: '$title. $subtitle. $actionLabel.',
      value: value,
      child: AnimatedContainer(
        duration: PerfectMotion.responsive(context, PerfectMotion.quick),
        curve: PerfectMotion.productive,
        padding: const EdgeInsetsDirectional.fromSTEB(
          PerfectSpace.lg,
          PerfectSpace.sm,
          PerfectSpace.lg,
          PerfectSpace.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: PerfectSpace.sm),
              Text(
                '$actionLabel · $value',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: PerfectSpace.md),
              Text(
                'Eligible (${eligibleIds.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: PerfectSpace.xs),
              if (eligibleIds.isEmpty)
                Text(
                  'No eligible items.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final id in eligibleIds)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: PerfectSpace.xs,
                    ),
                    child: Text(
                      id,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              const SizedBox(height: PerfectSpace.md),
              Text(
                'Skipped (${skippedReasons.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: PerfectSpace.xs),
              if (skippedReasons.isEmpty)
                Text(
                  'No skipped items.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final entry in skippedReasons.entries)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: PerfectSpace.xs,
                    ),
                    child: Text(
                      '${entry.key} — ${entry.value}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              const SizedBox(height: PerfectSpace.lg),
              Wrap(
                spacing: PerfectSpace.sm,
                runSpacing: PerfectSpace.sm,
                children: [
                  FilledButton(
                    key: const ValueKey<String>('tasks-bulk-confirm'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: onConfirm,
                    child: Text(actionLabel),
                  ),
                  TextButton(
                    key: const ValueKey<String>('tasks-bulk-cancel'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
