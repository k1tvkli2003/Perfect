import 'package:flutter/material.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

/// Honest local insight: a missing check-in is not silently scored as a
/// failure. This keeps recovery compassionate while still showing progress.
class PlannerInsightsSheet extends StatefulWidget {
  const PlannerInsightsSheet({super.key, required this.controller});

  final PlannerWorkspaceController controller;

  static Future<void> show(
    BuildContext context, {
    required PlannerWorkspaceController controller,
  }) {
    if (Theme.of(context).platform == TargetPlatform.windows ||
        MediaQuery.sizeOf(context).width >= 900) {
      return showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(PerfectSpace.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 560,
              maxWidth: 680,
              maxHeight: (MediaQuery.sizeOf(context).height - 48).clamp(
                320,
                720,
              ),
            ),
            child: PlannerInsightsSheet(controller: controller),
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: PerfectMotion.modalSheetStyle(context),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: MediaQuery.sizeOf(context).width >= 680 ? .68 : .82,
          child: PlannerInsightsSheet(controller: controller),
        ),
      ),
    );
  }

  @override
  State<PlannerInsightsSheet> createState() => _PlannerInsightsSheetState();
}

class _PlannerInsightsSheetState extends State<PlannerInsightsSheet> {
  int _days = 28;
  Future<PlannerInsights>? _insights;

  @override
  void initState() {
    super.initState();
    _insights = widget.controller.loadInsights(days: _days);
  }

  void _reload() {
    final insights = widget.controller.loadInsights(days: _days);
    if (!mounted) return;
    setState(() {
      _insights = insights;
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PerfectSpace.lg,
      PerfectSpace.sm,
      PerfectSpace.lg,
      PerfectSpace.xl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_outlined, color: PerfectColors.apricot),
            const SizedBox(width: PerfectSpace.xs),
            Expanded(
              child: Text(
                'Your rhythm',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh insight',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: PerfectSpace.xs),
        Text(
          'Only recorded activity is counted. An empty day is information, not a failure.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: PerfectSpace.sm),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 28, label: Text('28 days')),
            ButtonSegment(value: 90, label: Text('90 days')),
          ],
          selected: <int>{_days},
          onSelectionChanged: (selection) {
            _days = selection.first;
            _reload();
          },
        ),
        const SizedBox(height: PerfectSpace.md),
        Expanded(
          child: FutureBuilder<PlannerInsights>(
            future: _insights,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const Center(
                  child: Text(
                    'Insight is unavailable until local history is readable.',
                  ),
                );
              }
              final insight = snapshot.data!;
              return ListView(
                children: [
                  Wrap(
                    spacing: PerfectSpace.sm,
                    runSpacing: PerfectSpace.sm,
                    children: [
                      _InsightMetric(
                        label: 'Active tasks',
                        value: '${insight.activeTaskCount}',
                        color: PerfectColors.apricot,
                      ),
                      _InsightMetric(
                        label: 'One-off done',
                        value: '${insight.completedTaskCount}',
                        color: PerfectColors.mint,
                      ),
                      _InsightMetric(
                        label: 'Recorded wins',
                        value: '${insight.completedOccurrences}',
                        color: PerfectColors.lilac,
                      ),
                      _InsightMetric(
                        label: 'Habit check-ins',
                        value: '${insight.habitCheckIns}',
                        color: PerfectColors.mint,
                      ),
                    ],
                  ),
                  const SizedBox(height: PerfectSpace.md),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Focused time'),
                      subtitle: Text('Across the last ${insight.days} days'),
                      trailing: Text(
                        _formatFocus(insight.focusDuration),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: PerfectSpace.sm),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions_outlined),
                      title: const Text('Misses you recorded'),
                      subtitle: const Text(
                        'Use them to adjust recovery—not to erase your history.',
                      ),
                      trailing: Text(
                        '${insight.missedOccurrences}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: PerfectSpace.sm),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: const Text('Recoverable archive'),
                      subtitle: const Text(
                        'Nothing here is a destructive delete.',
                      ),
                      trailing: Text(
                        '${insight.archivedCount}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 148,
    child: Card(
      color: color.withValues(alpha: .13),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

String _formatFocus(Duration value) {
  if (value.inHours > 0) {
    return '${value.inHours}h ${value.inMinutes.remainder(60)}m';
  }
  return '${value.inMinutes}m';
}
