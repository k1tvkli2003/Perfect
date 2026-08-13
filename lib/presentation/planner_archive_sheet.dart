import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

/// A recoverable archive, intentionally separate from ordinary lists. Perfect
/// never presents a destructive delete action for planning data.
class PlannerArchiveSheet extends StatefulWidget {
  const PlannerArchiveSheet({super.key, required this.controller});

  final PlannerWorkspaceController controller;

  static Future<void> show(
    BuildContext context, {
    required PlannerWorkspaceController controller,
  }) {
    if (Theme.of(context).platform == TargetPlatform.windows ||
        MediaQuery.sizeOf(context).width >= 900) {
      return showPerfectDialog<void>(
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
            child: PlannerArchiveSheet(controller: controller),
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
          child: PlannerArchiveSheet(controller: controller),
        ),
      ),
    );
  }

  @override
  State<PlannerArchiveSheet> createState() => _PlannerArchiveSheetState();
}

class _PlannerArchiveSheetState extends State<PlannerArchiveSheet> {
  Future<List<PlannerEntity>>? _entries;
  String? _restoringId;

  @override
  void initState() {
    super.initState();
    _entries = widget.controller.archivedEntities();
  }

  void _reload() {
    final entries = widget.controller.archivedEntities();
    if (!mounted) return;
    setState(() {
      _entries = entries;
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
            Icon(
              Icons.inventory_2_outlined,
              color: PerfectSemanticTheme.of(context).tertiary,
            ),
            const SizedBox(width: PerfectSpace.xs),
            Expanded(
              child: Text(
                'Archive',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh archive',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: PerfectSpace.xs),
        Text(
          'Archived items are recoverable and stay in your private sync history.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: PerfectSpace.md),
        Expanded(
          child: FutureBuilder<List<PlannerEntity>>(
            future: _entries,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('The archive could not be read on this device.'),
                );
              }
              final entries = snapshot.data ?? const <PlannerEntity>[];
              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    'Nothing is archived. Calm is good.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: PerfectSpace.xs),
                itemBuilder: (context, index) {
                  final entity = entries[index];
                  final restoring = _restoringId == entity.id;
                  return Card(
                    child: ListTile(
                      leading: Icon(_iconFor(entity.kind)),
                      title: Text(
                        entity.title,
                        textDirection: _directionFor(entity.title),
                      ),
                      subtitle: Text(
                        '${_kindLabel(entity.kind)} · archived locally',
                      ),
                      trailing: TextButton.icon(
                        onPressed: restoring ? null : () => _restore(entity),
                        icon: restoring
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.unarchive_outlined),
                        label: const Text('Restore'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _restore(PlannerEntity entity) async {
    setState(() => _restoringId = entity.id);
    try {
      await widget.controller.restoreEntity(entity);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entity.title} is back in your workspace.')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not restore this item locally.')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoringId = null);
    }
  }
}

IconData _iconFor(PlannerEntityKind kind) => switch (kind) {
  PlannerEntityKind.habit => Icons.eco_outlined,
  PlannerEntityKind.project => Icons.folder_outlined,
  PlannerEntityKind.area => Icons.grid_view_outlined,
  PlannerEntityKind.recurringTask => Icons.repeat_rounded,
  PlannerEntityKind.oneOffTask => Icons.check_circle_outline,
};

String _kindLabel(PlannerEntityKind kind) => switch (kind) {
  PlannerEntityKind.habit => 'Habit',
  PlannerEntityKind.project => 'Project',
  PlannerEntityKind.area => 'Area',
  PlannerEntityKind.recurringTask => 'Recurring task',
  PlannerEntityKind.oneOffTask => 'Task',
};

TextDirection _directionFor(String value) =>
    RegExp(r'[\u0600-\u08ff]').hasMatch(value)
    ? TextDirection.rtl
    : TextDirection.ltr;
