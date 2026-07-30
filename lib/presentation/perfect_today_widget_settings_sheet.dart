import 'package:flutter/material.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

class PerfectTodayWidgetSettingsSheet extends StatefulWidget {
  const PerfectTodayWidgetSettingsSheet({super.key, required this.controller});

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
              minWidth: 520,
              maxWidth: 620,
              maxHeight: (MediaQuery.sizeOf(context).height - 48).clamp(
                320,
                720,
              ),
            ),
            child: PerfectTodayWidgetSettingsSheet(controller: controller),
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PerfectTodayWidgetSettingsSheet(controller: controller),
    );
  }

  @override
  State<PerfectTodayWidgetSettingsSheet> createState() =>
      _PerfectTodayWidgetSettingsSheetState();
}

class _PerfectTodayWidgetSettingsSheetState
    extends State<PerfectTodayWidgetSettingsSheet> {
  late bool _showTitles = widget.controller.todayWidgetSettings.showTaskTitles;
  bool _requestingPin = false;

  Future<void> _toggleTitles(bool value) async {
    setState(() => _showTitles = value);
    await widget.controller.setTodayWidgetTitleVisibility(value);
    if (!mounted) return;
    setState(
      () => _showTitles = widget.controller.todayWidgetSettings.showTaskTitles,
    );
  }

  Future<void> _requestPin() async {
    setState(() => _requestingPin = true);
    final accepted = await widget.controller.requestTodayWidgetPin();
    if (!mounted) return;
    setState(() => _requestingPin = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted
              ? 'Choose a spot for Perfect Today on your home screen.'
              : 'This launcher does not expose the add-widget prompt. Long-press the home screen and add Perfect Today manually.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PerfectSpace.lg,
          PerfectSpace.md,
          PerfectSpace.lg,
          PerfectSpace.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: PerfectSpace.lg),
            Text(
              'Perfect Today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: PerfectSpace.xs),
            Text(
              'A resizable, scrollable Android agenda. Tap a task status to cycle empty → done → not done → 50% → empty.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PerfectSpace.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _showTitles,
              onChanged: _toggleTitles,
              title: const Text('Show task titles on home screen'),
              subtitle: const Text(
                'Turn this off instantly when someone else can see your screen. Notes, links, and descriptions never leave the app.',
              ),
            ),
            const SizedBox(height: PerfectSpace.sm),
            FilledButton.icon(
              onPressed: _requestingPin ? null : _requestPin,
              icon: _requestingPin
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_to_home_screen_rounded),
              label: const Text('Add Perfect Today'),
            ),
          ],
        ),
      ),
    ),
  );
}
