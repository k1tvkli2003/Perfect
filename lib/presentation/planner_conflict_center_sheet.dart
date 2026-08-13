import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

class PlannerConflictCenterSheet extends StatefulWidget {
  const PlannerConflictCenterSheet({super.key, required this.controller});

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
            child: PlannerConflictCenterSheet(controller: controller),
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
          heightFactor: MediaQuery.sizeOf(context).width >= 680 ? .68 : .88,
          child: PlannerConflictCenterSheet(controller: controller),
        ),
      ),
    );
  }

  @override
  State<PlannerConflictCenterSheet> createState() =>
      _PlannerConflictCenterSheetState();
}

class _PlannerConflictCenterSheetState
    extends State<PlannerConflictCenterSheet> {
  late Future<List<PlannerSyncConflict>> _conflicts = widget.controller
      .openConflicts();
  String? _busyId;
  String? _message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PerfectSpace.xl,
      PerfectSpace.sm,
      PerfectSpace.xl,
      PerfectSpace.xl,
    ),
    child: Column(
      children: [
        Row(
          children: [
            const PerfectMark(size: 40),
            const SizedBox(width: PerfectSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conflict center',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text('Only true concurrent changes arrive here.'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close conflict center',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: PerfectSpace.md),
        Expanded(
          child: FutureBuilder<List<PlannerSyncConflict>>(
            future: _conflicts,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final conflicts = snapshot.data ?? const <PlannerSyncConflict>[];
              if (conflicts.isEmpty) {
                return Center(
                  child: Text(
                    'Nothing needs your decision. Independent fields already merge automatically.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }
              return ListView.separated(
                itemCount: conflicts.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: PerfectSpace.sm),
                itemBuilder: (context, index) => _ConflictCard(
                  conflict: conflicts[index],
                  busy: _busyId == conflicts[index].id,
                  onKeepServer: () =>
                      _resolve(conflicts[index], keepLocal: false),
                  onKeepLocal:
                      conflicts[index].targetType ==
                          PlannerOperationTarget.entity
                      ? () => _resolve(conflicts[index], keepLocal: true)
                      : null,
                ),
              );
            },
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: PerfectSpace.sm),
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );

  Future<void> _resolve(
    PlannerSyncConflict conflict, {
    required bool keepLocal,
  }) async {
    setState(() => _busyId = conflict.id);
    try {
      if (keepLocal) {
        await widget.controller.keepLocalConflict(conflict);
      } else {
        await widget.controller.keepServerConflict(conflict);
      }
      if (!mounted) return;
      setState(() {
        _message = keepLocal
            ? 'Your local version was re-applied as a new, syncable change.'
            : 'The server version remains the source of truth for this item.';
        _conflicts = widget.controller.openConflicts();
      });
    } on Object catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.busy,
    required this.onKeepServer,
    this.onKeepLocal,
  });

  final PlannerSyncConflict conflict;
  final bool busy;
  final VoidCallback onKeepServer;
  final VoidCallback? onKeepLocal;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conflict.targetType == PlannerOperationTarget.entity
                ? 'Concurrent item edit'
                : 'Immutable history conflict',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PerfectSpace.xs),
          Text('Fields: ${conflict.fieldPaths.join(', ')}'),
          Text('Server revision ${conflict.remoteRevision ?? '—'}'),
          const SizedBox(height: PerfectSpace.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onKeepServer,
                  child: const Text('Keep server'),
                ),
              ),
              if (onKeepLocal != null) ...[
                const SizedBox(width: PerfectSpace.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onKeepLocal,
                    child: Text(busy ? 'Saving…' : 'Keep mine'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
