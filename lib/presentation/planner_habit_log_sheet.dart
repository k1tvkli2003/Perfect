import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

class PlannerHabitLogSheet extends StatefulWidget {
  const PlannerHabitLogSheet({
    super.key,
    required this.habit,
    required this.controller,
  });

  final PlannerEntity habit;
  final PlannerWorkspaceController controller;

  static Future<void> show(
    BuildContext context, {
    required PlannerEntity habit,
    required PlannerWorkspaceController controller,
  }) {
    final sheet = PlannerHabitLogSheet(habit: habit, controller: controller);
    if (MediaQuery.sizeOf(context).width >= 680) {
      return showPerfectDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(PerfectSpace.xl),
          child: ConstrainedBox(
            key: const ValueKey<String>('perfect-habit-log-dialog-surface'),
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: sheet,
            ),
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
        key: const ValueKey<String>('perfect-habit-log-surface'),
        top: false,
        child: FractionallySizedBox(heightFactor: .9, child: sheet),
      ),
    );
  }

  @override
  State<PlannerHabitLogSheet> createState() => _PlannerHabitLogSheetState();
}

class _PlannerHabitLogSheetState extends State<PlannerHabitLogSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _note;
  late final TextEditingController _amount;
  late final String _method;
  late final List<_HabitLogChecklistItem> _checklist;
  late DateTime _selectedDay;
  final Set<String> _checkedItemIds = <String>{};
  PlannerHabitDaySummary? _summary;
  String _binaryOutcome = 'checked';
  String _avoidOutcome = 'avoided';
  bool _loading = true;
  bool _saving = false;
  Object? _loadError;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    final tracking = widget.habit.tracking;
    _selectedDay = _dateOnly(widget.controller.localNow);
    _method = safeJsonString(tracking['method'], fallback: 'check');
    _note = TextEditingController();
    _amount = TextEditingController(
      text: _formatAmount((tracking['target'] as num?)?.toDouble() ?? 1),
    );
    _checklist = _readChecklist(widget.habit);
    unawaited(_loadSummary());
  }

  @override
  void dispose() {
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = widget.habit.tracking;
    final unit = safeJsonString(
      tracking['unit'],
      fallback: _method == 'duration' ? 'minutes' : '',
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PerfectSpace.xl,
        PerfectSpace.sm,
        PerfectSpace.xl,
        PerfectSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
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
                      _summary?.hasLog == true
                          ? 'Edit $_selectedDayName · ${widget.habit.title}'
                          : 'Log $_selectedDayName · ${widget.habit.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: _textDirection(widget.habit.title),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(_subtitleFor(_method, unit)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close habit log',
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: PerfectSpace.md),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? _LoadFailure(onRetry: _loadSummary)
                : Form(
                    key: _formKey,
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        _dateNavigator(context),
                        const SizedBox(height: PerfectSpace.md),
                        if (_summary case final PlannerHabitDaySummary summary)
                          _DayStateBanner(
                            summary: summary,
                            unit: unit,
                            checkedChecklistCount: _checkedItemIds.length,
                            checklistTotal: _checklist.length,
                          ),
                        const SizedBox(height: PerfectSpace.md),
                        if (_method == 'count' || _method == 'duration')
                          _measuredEditor(unit),
                        if (_method == 'check') _binaryEditor(),
                        if (_method == 'avoid') _avoidEditor(),
                        if (_method == 'checklist') _checklistEditor(),
                        const SizedBox(height: PerfectSpace.md),
                        TextFormField(
                          controller: _note,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Note (optional)',
                            hintText: 'What helped, what got in the way?',
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (_summary?.hasLog == true) ...[
                          const SizedBox(height: PerfectSpace.md),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _undo,
                            icon: const Icon(Icons.undo_rounded),
                            label: Text('Reset $_selectedDayName to pending'),
                          ),
                          const SizedBox(height: PerfectSpace.xs),
                          Text(
                            'Reset edits the same private day record; it does not erase older synced history.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: PerfectSpace.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading || _loadError != null || _saving
                  ? null
                  : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _saving
                    ? 'Saving locally…'
                    : _summary?.hasLog == true
                    ? 'Update $_selectedDayName'
                    : 'Save $_selectedDayName',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateNavigator(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Previous day',
        onPressed: _saving
            ? null
            : () => _selectDay(_selectedDay.subtract(const Duration(days: 1))),
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _saving ? null : _pickDay,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(_selectedDayLabel),
        ),
      ),
      IconButton(
        tooltip: 'Next day',
        onPressed: _saving || _isToday
            ? null
            : () => _selectDay(_selectedDay.add(const Duration(days: 1))),
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );

  DateTime get _today => _dateOnly(widget.controller.localNow);
  bool get _isToday => _selectedDay == _today;
  String get _selectedDayName => _isToday
      ? 'today'
      : '${_monthNames[_selectedDay.month - 1]} ${_selectedDay.day}';
  String get _selectedDayLabel => _isToday
      ? 'Today · ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.day}'
      : '${_monthNames[_selectedDay.month - 1]} ${_selectedDay.day}, '
            '${_selectedDay.year}';

  Future<void> _pickDay() async {
    final selected = await showDatePicker(
      context: context,
      helpText: 'Choose a habit result date',
      firstDate: DateTime(2000),
      lastDate: _today,
      initialDate: _selectedDay,
    );
    if (selected == null || !mounted) return;
    await _selectDay(selected);
  }

  Future<void> _selectDay(DateTime day) async {
    final normalized = _dateOnly(day);
    if (normalized.isAfter(_today) || normalized == _selectedDay) return;
    if (_hasUnsavedDraft && !await _confirmDiscardDraft()) return;
    if (!mounted) return;
    setState(() => _selectedDay = normalized);
    await _loadSummary();
  }

  bool get _hasUnsavedDraft {
    final summary = _summary;
    if (_loading || summary == null) return false;
    if (_note.text != (summary.note ?? '')) return true;
    if (_method == 'count' || _method == 'duration') {
      final amount = double.tryParse(_amount.text.trim());
      if (amount == null || amount != summary.amount) return true;
    }
    if (_method == 'check') {
      final expected = summary.state == PlannerHabitDayState.missed
          ? 'missed'
          : 'checked';
      if (_binaryOutcome != expected) return true;
    }
    if (_method == 'avoid') {
      final expected =
          summary.outcome == 'slipped' ||
              summary.state == PlannerHabitDayState.missed
          ? 'slipped'
          : 'avoided';
      if (_avoidOutcome != expected) return true;
    }
    if (_method == 'checklist' &&
        !_sameStrings(_checkedItemIds, summary.checkedItemIds)) {
      return true;
    }
    return false;
  }

  Future<bool> _confirmDiscardDraft() async {
    final discard = await showPerfectDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change date?'),
        content: const Text(
          'Your unsaved edits for this day will stay only if you save first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard and change date'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Widget _measuredEditor(String unit) => Card(
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected day total',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PerfectSpace.sm),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease amount',
                onPressed: _decreaseAmount,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Measured total',
                    suffixText: unit.isEmpty ? null : unit,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || !parsed.isFinite) {
                      return 'Enter a valid amount.';
                    }
                    if (parsed < 0) return 'Amount cannot be negative.';
                    return null;
                  },
                ),
              ),
              IconButton(
                tooltip: 'Increase amount',
                onPressed: _increaseAmount,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: PerfectSpace.xs),
          Text(
            'This replaces the selected day’s total instead of adding a duplicate observation.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );

  Widget _binaryEditor() => Card(
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did $_selectedDayName go?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PerfectSpace.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'checked',
                icon: Icon(Icons.check_rounded),
                label: Text('Done'),
              ),
              ButtonSegment(
                value: 'missed',
                icon: Icon(Icons.close_rounded),
                label: Text('Not done'),
              ),
            ],
            selected: <String>{_binaryOutcome},
            onSelectionChanged: (selection) =>
                setState(() => _binaryOutcome = selection.first),
          ),
        ],
      ),
    ),
  );

  Widget _avoidEditor() => Card(
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did $_selectedDayName go?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PerfectSpace.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'avoided',
                icon: Icon(Icons.shield_outlined),
                label: Text('Stayed clear'),
              ),
              ButtonSegment(
                value: 'slipped',
                icon: Icon(Icons.healing_outlined),
                label: Text('A slip happened'),
              ),
            ],
            selected: <String>{_avoidOutcome},
            onSelectionChanged: (selection) =>
                setState(() => _avoidOutcome = selection.first),
          ),
          const SizedBox(height: PerfectSpace.sm),
          const Text(
            'You can correct this later. Perfect updates that day’s result without shame or duplication.',
          ),
        ],
      ),
    ),
  );

  Widget _checklistEditor() {
    if (_checklist.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.warning_amber_rounded),
          title: Text('This checklist has no items'),
          subtitle: Text('Open habit details and add at least one item.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedDayName checklist',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: PerfectSpace.xs),
        ..._checklist.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: PerfectSpace.xs),
            child: CheckboxListTile(
              value: _checkedItemIds.contains(item.id),
              title: Text(
                item.label,
                textDirection: _textDirection(item.label),
              ),
              subtitle: Text(item.required ? 'Required' : 'Optional'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _checkedItemIds.add(item.id);
                } else {
                  _checkedItemIds.remove(item.id);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  double get _step => _method == 'duration' ? 5 : 1;

  void _decreaseAmount() {
    final current = double.tryParse(_amount.text.trim()) ?? 0;
    _setAmount((current - _step).clamp(0, 99999));
  }

  void _increaseAmount() {
    final current = double.tryParse(_amount.text.trim()) ?? 0;
    _setAmount((current + _step).clamp(0, 99999));
  }

  void _setAmount(double value) {
    setState(() {
      _amount.text = _formatAmount(value);
      _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    });
  }

  Future<void> _loadSummary() async {
    final generation = ++_loadGeneration;
    final requestedDay = _selectedDay;
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final summary = await widget.controller.habitDaySummary(
        widget.habit,
        localDay: requestedDay,
      );
      if (!mounted ||
          generation != _loadGeneration ||
          requestedDay != _selectedDay) {
        return;
      }
      setState(() {
        _applySummary(summary);
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted ||
          generation != _loadGeneration ||
          requestedDay != _selectedDay) {
        return;
      }
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _applySummary(PlannerHabitDaySummary summary) {
    _summary = summary;
    _note.text = summary.note ?? '';
    if (_method == 'count' || _method == 'duration') {
      _amount.text = _formatAmount(summary.hasLog ? summary.amount : 0);
    }
    _checkedItemIds
      ..clear()
      ..addAll(
        summary.checkedItemIds.where(
          _checklist.map((item) => item.id).toSet().contains,
        ),
      );
    if (_method == 'check') {
      _binaryOutcome = summary.state == PlannerHabitDayState.missed
          ? 'missed'
          : 'checked';
    }
    if (_method == 'avoid') {
      _avoidOutcome =
          summary.outcome == 'slipped' ||
              summary.state == PlannerHabitDayState.missed
          ? 'slipped'
          : 'avoided';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final amount = _method == 'count' || _method == 'duration'
          ? double.parse(_amount.text.trim())
          : null;
      final summary = await widget.controller.logHabit(
        widget.habit,
        value: amount,
        note: _note.text,
        outcome: switch (_method) {
          'check' => _binaryOutcome,
          'avoid' => _avoidOutcome,
          _ => null,
        },
        checkedItemIds: _method == 'checklist' ? _checkedItemIds : null,
        localDay: _selectedDay,
      );
      if (!mounted) return;
      setState(() => _applySummary(summary));
      Navigator.of(context).maybePop();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update this day. Your edits are still here.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _undo() async {
    setState(() => _saving = true);
    try {
      final summary = await widget.controller.undoHabitDay(
        widget.habit,
        localDay: _selectedDay,
      );
      if (!mounted) return;
      setState(() => _applySummary(summary));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_selectedDayName is pending again.')),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reset this day. The saved result is unchanged.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DayStateBanner extends StatelessWidget {
  const _DayStateBanner({
    required this.summary,
    required this.unit,
    required this.checkedChecklistCount,
    required this.checklistTotal,
  });

  final PlannerHabitDaySummary summary;
  final String unit;
  final int checkedChecklistCount;
  final int checklistTotal;

  @override
  Widget build(BuildContext context) {
    final color = _summaryColor(context, summary.state);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PerfectSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(_summaryIcon(summary.state), color: color),
          const SizedBox(width: PerfectSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _summaryStateLabel(summary.state),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _summaryDetail(
                    summary,
                    unit,
                    checkedChecklistCount: checkedChecklistCount,
                    checklistTotal: checklistTotal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 42),
        const SizedBox(height: PerfectSpace.sm),
        const Text('The saved result for this day could not be loaded.'),
        const SizedBox(height: PerfectSpace.sm),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _HabitLogChecklistItem {
  const _HabitLogChecklistItem({
    required this.id,
    required this.label,
    required this.required,
  });

  final String id;
  final String label;
  final bool required;
}

List<_HabitLogChecklistItem> _readChecklist(PlannerEntity habit) {
  final source =
      habit.tracking[PlannerHabitTrackingKeys.checklist] ??
      habit.payload[PlannerHabitTrackingKeys.checklist];
  if (source is! Iterable || source is String) {
    return const <_HabitLogChecklistItem>[];
  }
  final result = <_HabitLogChecklistItem>[];
  var index = 0;
  for (final raw in source) {
    index++;
    final item = safeJsonMap(raw);
    final id = safeJsonString(
      item[PlannerHabitTrackingKeys.itemId],
      fallback: 'item-$index',
    );
    final label =
        safeNullableJsonString(item['label']) ??
        safeNullableJsonString(item['title']) ??
        id;
    result.add(
      _HabitLogChecklistItem(
        id: id,
        label: label,
        required: item[PlannerHabitTrackingKeys.itemRequired] != false,
      ),
    );
  }
  return result;
}

String _subtitleFor(String method, String unit) => switch (method) {
  'count' =>
    'Record the selected day’s total${unit.isEmpty ? '' : ' in $unit'}.',
  'duration' =>
    'Record the selected day’s time${unit.isEmpty ? '' : ' in $unit'}.',
  'avoid' => 'Track a negative habit without shame.',
  'checklist' => 'Check what happened; the success rule does the math.',
  _ => 'Choose done or not done for the selected day.',
};

String _formatAmount(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameStrings(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

const _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _summaryStateLabel(PlannerHabitDayState state) => switch (state) {
  PlannerHabitDayState.pending => 'Pending',
  PlannerHabitDayState.partial => 'In progress',
  PlannerHabitDayState.completed => 'Complete',
  PlannerHabitDayState.missed => 'Not done',
};

String _summaryDetail(
  PlannerHabitDaySummary summary,
  String unit, {
  required int checkedChecklistCount,
  required int checklistTotal,
}) {
  if (summary.method == 'count' || summary.method == 'duration') {
    final suffix = unit.isEmpty ? '' : ' $unit';
    return '${_formatAmount(summary.amount)}$suffix of '
        '${_formatAmount(summary.target)}$suffix · ${summary.progressPercent}%';
  }
  if (summary.method == 'checklist') {
    return '$checkedChecklistCount/$checklistTotal checked · '
        '${summary.requiredCount} needed · ${summary.progressPercent}%';
  }
  return summary.hasLog
      ? 'Saved for this day · tap Update to revise it.'
      : 'No result yet.';
}

IconData _summaryIcon(PlannerHabitDayState state) => switch (state) {
  PlannerHabitDayState.pending => Icons.radio_button_unchecked_rounded,
  PlannerHabitDayState.partial => Icons.timelapse_rounded,
  PlannerHabitDayState.completed => Icons.check_circle_rounded,
  PlannerHabitDayState.missed => Icons.cancel_rounded,
};

Color _summaryColor(BuildContext context, PlannerHabitDayState state) {
  final semantic = PerfectSemanticTheme.of(context);
  return switch (state) {
    PlannerHabitDayState.pending => semantic.muted,
    PlannerHabitDayState.partial => semantic.tertiary,
    PlannerHabitDayState.completed => semantic.secondary,
    PlannerHabitDayState.missed => semantic.danger,
  };
}

TextDirection _textDirection(String value) =>
    RegExp(r'[\u0600-\u08ff]').hasMatch(value)
    ? TextDirection.rtl
    : TextDirection.ltr;
