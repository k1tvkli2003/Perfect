import 'package:flutter/material.dart';
import 'package:perfect/planner/notifications/planner_reminder_scheduler.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

class PlannerReminderSettingsSheet extends StatefulWidget {
  const PlannerReminderSettingsSheet({super.key, required this.controller});

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
            child: PlannerReminderSettingsSheet(controller: controller),
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: MediaQuery.sizeOf(context).width >= 680 ? .72 : .9,
          child: PlannerReminderSettingsSheet(controller: controller),
        ),
      ),
    );
  }

  @override
  State<PlannerReminderSettingsSheet> createState() =>
      _PlannerReminderSettingsSheetState();
}

class _PlannerReminderSettingsSheetState
    extends State<PlannerReminderSettingsSheet> {
  PlannerReminderSettings? _settings;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.controller.reminderSettings();
    if (mounted) setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
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
                      'Reminders',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text('Local, private, and never cloud-triggered.'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close reminders',
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: PerfectSpace.lg),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(PerfectSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.enabled
                              ? 'Reminders are active on this device'
                              : 'Turn on reminders for this device',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: PerfectSpace.xs),
                        Text(
                          settings.enabled
                              ? 'Only items you explicitly configure in their editor are scheduled.'
                              : 'Android asks for notification permission only after this button is tapped.',
                        ),
                        const SizedBox(height: PerfectSpace.md),
                        if (!settings.enabled)
                          FilledButton.icon(
                            onPressed: _saving ? null : _enable,
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            label: const Text('Enable local reminders'),
                          )
                        else
                          FilledButton.tonalIcon(
                            onPressed: _saving ? null : _reschedule,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh this device'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: PerfectSpace.md),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Respect quiet hours'),
                        subtitle: const Text(
                          'Each task or habit can opt in separately in its editor.',
                        ),
                        value: settings.quietHoursEnabled,
                        onChanged: _saving
                            ? null
                            : (value) => _save(
                                settings.copyWith(quietHoursEnabled: value),
                              ),
                      ),
                      if (settings.quietHoursEnabled) ...[
                        const Divider(
                          indent: PerfectSpace.md,
                          endIndent: PerfectSpace.md,
                        ),
                        ListTile(
                          leading: const Icon(Icons.nights_stay_outlined),
                          title: const Text('Quiet window'),
                          subtitle: Text(
                            '${_formatMinutes(settings.quietStartMinutes)} – ${_formatMinutes(settings.quietEndMinutes)}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _saving
                              ? null
                              : () => _editQuietWindow(settings),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PerfectSpace.md),
                Card(
                  child: SwitchListTile.adaptive(
                    title: const Text('Exact Android timing'),
                    subtitle: const Text(
                      'Optional. Inexact delivery is gentler on battery; Android may open a system permission screen for exact alarms.',
                    ),
                    value: settings.exactTiming,
                    onChanged: _saving || !settings.enabled
                        ? null
                        : (enabled) => _setExactTiming(settings, enabled),
                  ),
                ),
                const SizedBox(height: PerfectSpace.md),
                Text(
                  'On Windows, Perfect schedules individual toast occurrences. To reliably retract notifications already shown, install the private app as an MSIX package.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_message != null) ...[
                  const SizedBox(height: PerfectSpace.md),
                  Text(
                    _message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enable() async {
    setState(() => _saving = true);
    try {
      final result = await widget.controller.enableReminders();
      await _load();
      if (!mounted) return;
      setState(() {
        _message = switch (result) {
          PlannerReminderActivation.enabled => reminderScheduleSummaryMessage(
            widget.controller.lastReminderScheduleSummary,
          ),
          PlannerReminderActivation.denied =>
            'Notification permission was not granted. Your tasks remain saved locally.',
          PlannerReminderActivation.unavailable =>
            'This device cannot schedule reminders with the current private build.',
        };
      });
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Perfect could not refresh reminders on this device. Your planner data is unchanged.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reschedule() async {
    setState(() => _saving = true);
    try {
      final summary = await widget.controller.saveReminderSettings(_settings!);
      if (mounted) {
        setState(() => _message = reminderScheduleSummaryMessage(summary));
      }
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Perfect could not refresh reminders on this device. Your planner data is unchanged.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(PlannerReminderSettings settings) async {
    setState(() => _saving = true);
    try {
      final summary = await widget.controller.saveReminderSettings(settings);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _message = reminderScheduleSummaryMessage(summary);
      });
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'This reminder setting could not be saved. The previous device plan remains visible.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setExactTiming(
    PlannerReminderSettings settings,
    bool enabled,
  ) async {
    if (!enabled) {
      await _save(settings.copyWith(exactTiming: false));
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await widget.controller.enableReminders(
        requestExactTiming: true,
      );
      await _load();
      if (!mounted) return;
      setState(() {
        _message = result == PlannerReminderActivation.enabled
            ? 'Exact timing is enabled when Android allowed it.'
            : 'Exact timing was not granted; Perfect will keep using battery-friendly inexact delivery.';
      });
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Perfect could not update exact timing. Existing reminder settings remain in place.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editQuietWindow(PlannerReminderSettings settings) async {
    final start = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(settings.quietStartMinutes),
      helpText: 'Quiet hours start',
    );
    if (!mounted || start == null) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(settings.quietEndMinutes),
      helpText: 'Quiet hours end',
    );
    if (!mounted || end == null) return;
    await _save(
      settings.copyWith(
        quietStartMinutes: start.hour * 60 + start.minute,
        quietEndMinutes: end.hour * 60 + end.minute,
      ),
    );
  }
}

TimeOfDay _timeOfDay(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

String _formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final hour12 = hour == 0
      ? 12
      : hour > 12
      ? hour - 12
      : hour;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  return '$hour12:${(minutes % 60).toString().padLeft(2, '0')} $suffix';
}

String reminderScheduleSummaryMessage(PlannerReminderScheduleSummary? summary) {
  if (summary == null) {
    return 'The current local reminder plan has been refreshed.';
  }
  if (summary.disabled) {
    if (summary.failures > 0) {
      return 'Reminders are off, but ${summary.failures} older notification${summary.failures == 1 ? '' : 's'} could not be cancelled yet. Perfect will retry while reminders stay off.';
    }
    return 'Local reminders are off and every previously scheduled notification was cancelled.';
  }
  if (summary.truncated > 0) {
    return 'Scheduled the next ${summary.scheduled} notifications in chronological order. ${summary.truncated} later notification${summary.truncated == 1 ? '' : 's'} exceed this device’s ${summary.capacity}-notification safety limit; they will enter the plan as earlier reminders pass.';
  }
  if (summary.failures > 0) {
    return 'Scheduled ${summary.scheduled} notifications, but ${summary.failures} device operation${summary.failures == 1 ? '' : 's'} failed. Refresh to retry.';
  }
  if (summary.skipped > 0) {
    return 'Scheduled ${summary.scheduled} notifications. ${summary.skipped} invalid, duplicate, past, or quiet-hour reminder${summary.skipped == 1 ? '' : 's'} were skipped.';
  }
  return 'The current local reminder plan has been refreshed: ${summary.scheduled} notification${summary.scheduled == 1 ? '' : 's'} scheduled.';
}
