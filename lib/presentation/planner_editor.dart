import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_formula.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_pictogram.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:uuid/uuid.dart';

/// A sectioned editor: fast capture stays at the top while every task/habit
/// scenario remains reachable through deliberate, collapsed detail sections.
class PlannerEditor extends StatefulWidget {
  const PlannerEditor({
    super.key,
    required this.controller,
    this.existing,
    this.initialKind = PlannerEntityKind.oneOffTask,
    this.onDismiss,
  });

  final PlannerWorkspaceController controller;
  final PlannerEntity? existing;
  final PlannerEntityKind initialKind;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context, {
    required PlannerWorkspaceController controller,
    PlannerEntity? existing,
    PlannerEntityKind initialKind = PlannerEntityKind.oneOffTask,
  }) {
    final media = MediaQuery.of(context);
    final geometry = PerfectResponsiveGeometry.fromSize(
      media.size,
      textScale: media.textScaler.scale(1),
    );
    final editor = PlannerEditor(
      controller: controller,
      existing: existing,
      initialKind: initialKind,
      onDismiss: () => Navigator.of(context).maybePop(),
    );
    if (geometry.prefersDialog) {
      return showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: geometry.horizontalGutter,
            vertical: geometry.verticalGutter,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: geometry.editorMaxWidth,
              maxHeight: geometry.editorMaxHeight(820),
            ),
            child: editor,
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
          heightFactor: geometry.editorSheetHeightFactor,
          child: editor,
        ),
      ),
    );
  }

  @override
  State<PlannerEditor> createState() => _PlannerEditorState();
}

class _PlannerEditorState extends State<PlannerEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _category;
  late final TextEditingController _labelEntry;
  late final TextEditingController _estimateMinutes;
  late final TextEditingController _unit;
  late final TextEditingController _targetValue;
  late final TextEditingController _link;
  late final TextEditingController _customName;
  late final TextEditingController _customValue;
  late final TextEditingController _formula;
  late final TextEditingController _checklistEntry;
  late final TextEditingController _frequencyCount;
  late final TextEditingController _habitChecklistEntry;
  late final TextEditingController _habitSuccessValue;
  late PlannerEntityKind _kind;
  DateTime? _scheduledAt;
  DateTime? _timeBlockEndAt;
  DateTime? _dueAt;
  bool _allDay = false;
  final List<String> _labels = <String>[];
  String _icon = 'default';
  String _color = 'apricot';
  String _priority = 'normal';
  String _energy = 'any';
  String _recurrence = 'none';
  String _frequencyPeriod = 'week';
  int _recurrenceInterval = 1;
  int _occurrenceLimit = 0;
  final Set<int> _weekdays = <int>{};
  final Set<int> _monthDays = <int>{};
  bool _lastDayOfMonth = false;
  final Set<(int month, int day)> _annualDates = <(int, int)>{};
  final Set<DateTime> _exceptionDates = <DateTime>{};
  DateTime? _recurrenceEndAt;
  bool _recurrencePaused = false;
  bool _recurrenceFlexible = false;
  String _trackingMethod = 'check';
  String _goalDirection = 'at_least';
  double _target = 1;
  String _habitSuccessType = 'all';
  final List<_HabitChecklistDraftItem> _habitChecklist =
      <_HabitChecklistDraftItem>[];
  String _recovery = 'miss_then_next';
  int _carryCap = 7;
  bool _reminderEnabled = false;
  int _reminderLeadMinutes = 15;
  final List<int> _additionalReminderLeads = <int>[];
  final Map<int, int> _reminderSnoozeByLead = <int, int>{};
  bool _quietHours = false;
  bool _focusEnabled = false;
  String _focusMode = 'pomodoro';
  int _focusMinutes = 25;
  String _focusBreakPolicy = 'none';
  int _focusShortBreakMinutes = 5;
  int _focusLongBreakMinutes = 15;
  int _focusLongBreakAfterCycles = 4;
  PlannerTaskProgressState _taskProgressState =
      PlannerTaskProgressState.pending;
  int _taskProgressPercent = 50;
  String? _projectId;
  String? _areaId;
  String _customType = 'text';
  bool _customChecked = false;
  final List<_ChecklistDraftItem> _checklist = <_ChecklistDraftItem>[];
  bool _saving = false;

  bool get _isHabit => _kind == PlannerEntityKind.habit;
  bool get _isTask =>
      _kind == PlannerEntityKind.oneOffTask ||
      _kind == PlannerEntityKind.recurringTask;
  String get _monthRuleSummary {
    final selected = <String>[
      ...(_monthDays.toList()..sort()).map((day) => '$day'),
      if (_lastDayOfMonth) 'last day',
    ];
    if (selected.isEmpty) return 'Uses the planned start day';
    if (selected.length <= 4) return selected.join(', ');
    return '${selected.length} selected dates';
  }

  List<String> get _categorySuggestions {
    final categories = <String>{
      'Health',
      'Work',
      'Study',
      'Home',
      'Personal',
      'Finance',
    };
    for (final entity in widget.controller.entities) {
      final category = safeNullableJsonString(entity.payload['category']);
      if (category != null) categories.add(category);
    }
    final current = _category.text.trim();
    if (current.isNotEmpty) categories.add(current);
    return categories.take(12).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _kind = existing?.kind ?? widget.initialKind;
    _title = TextEditingController(text: existing?.title ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _category = TextEditingController(
      text: safeJsonString(existing?.payload['category'], fallback: ''),
    );
    _labelEntry = TextEditingController();
    final storedLabels = existing?.payload[PlannerTaskMetadataKeys.labels];
    if (storedLabels is Iterable && storedLabels is! String) {
      final seen = <String>{};
      for (final value in storedLabels) {
        final label = safeNullableJsonString(value);
        if (label != null && seen.add(label.toLowerCase())) {
          _labels.add(label);
        }
      }
    }
    final storedIcon = safeJsonString(
      existing?.payload[PlannerTaskMetadataKeys.icon],
      fallback: 'default',
    );
    _icon = _plannerIconOptions.contains(storedIcon) ? storedIcon : 'default';
    final storedColor = safeJsonString(
      existing?.payload[PlannerTaskMetadataKeys.color],
      fallback: 'apricot',
    );
    _color = _plannerColorOptions.contains(storedColor)
        ? storedColor
        : 'apricot';
    final timing = existing?.timing ?? const <String, dynamic>{};
    _scheduledAt = safeJsonDateTime(timing['scheduled_at']);
    _timeBlockEndAt = safeJsonDateTime(
      timing[PlannerTaskMetadataKeys.timeBlockEndAt],
    );
    _dueAt = safeJsonDateTime(timing['due_at']);
    _allDay = timing['all_day'] == true;
    if (_allDay) _timeBlockEndAt = null;
    _priority = safeJsonString(
      existing?.payload['priority'],
      fallback: 'normal',
    );
    final storedEnergy = safeJsonString(
      existing?.payload[PlannerTaskMetadataKeys.energy],
      fallback: 'any',
    );
    _energy =
        const <String>{'any', 'low', 'medium', 'high'}.contains(storedEnergy)
        ? storedEnergy
        : 'any';
    final storedEstimate = safeJsonInt(
      existing?.payload[PlannerTaskMetadataKeys.estimateMinutes],
      fallback: 0,
    );
    _estimateMinutes = TextEditingController(
      text: storedEstimate > 0 ? storedEstimate.toString() : '',
    );
    if (existing?.kind == PlannerEntityKind.oneOffTask) {
      final progress = PlannerTaskProgress.fromEntity(existing!);
      _taskProgressState = progress.state;
      _taskProgressPercent = progress.percent == 0 ? 50 : progress.percent;
    }
    final recurrence = existing?.recurrence ?? const <String, dynamic>{};
    _recurrence = safeJsonString(recurrence['rule'], fallback: 'none');
    final storedFrequency = safeJsonMap(
      recurrence[PlannerRecurrenceKeys.frequency],
    );
    if (storedFrequency.isNotEmpty) _recurrence = 'flexible';
    final storedPeriod = safeJsonString(
      storedFrequency[PlannerRecurrenceKeys.frequencyPeriod],
      fallback: 'week',
    );
    _frequencyPeriod = const <String>{'week', 'month'}.contains(storedPeriod)
        ? storedPeriod
        : 'week';
    _frequencyCount = TextEditingController(
      text: safeJsonInt(
        storedFrequency[PlannerRecurrenceKeys.frequencyCount],
        fallback: 3,
      ).clamp(1, 31).toString(),
    );
    _recurrenceInterval = safeJsonInt(
      recurrence['interval'],
      fallback: 1,
    ).clamp(1, 99);
    _occurrenceLimit = safeJsonInt(
      recurrence['occurrence_limit'],
      fallback: 0,
    ).clamp(0, 999);
    _recurrenceEndAt = safeJsonDateTime(recurrence['end_at']);
    _recurrencePaused = recurrence['paused'] == true;
    _recurrenceFlexible = recurrence['flexible'] == true;
    final storedExceptions = recurrence['exceptions'];
    if (storedExceptions is Iterable) {
      _exceptionDates.addAll(
        storedExceptions
            .map(safeJsonDateTime)
            .whereType<DateTime>()
            .map(_dateOnly),
      );
    }
    final storedWeekdays = recurrence['weekdays'];
    if (storedWeekdays is Iterable) {
      _weekdays.addAll(
        storedWeekdays
            .map((value) => safeJsonInt(value, fallback: -1))
            .where(
              (value) => value >= DateTime.monday && value <= DateTime.sunday,
            ),
      );
    }
    final storedMonthDays = recurrence[PlannerRecurrenceKeys.monthDays];
    if (storedMonthDays is Iterable) {
      for (final value in storedMonthDays) {
        final normalized = value.toString().trim().toLowerCase();
        if (normalized == 'last' || normalized == '-1') {
          _lastDayOfMonth = true;
          continue;
        }
        final day = safeJsonInt(value, fallback: 0);
        if (day >= 1 && day <= 31) _monthDays.add(day);
      }
    }
    _lastDayOfMonth =
        _lastDayOfMonth ||
        recurrence[PlannerRecurrenceKeys.lastDayOfMonth] == true;
    final storedAnnualDates = recurrence[PlannerRecurrenceKeys.annualDates];
    if (storedAnnualDates is Iterable) {
      for (final value in storedAnnualDates) {
        final map = safeJsonMap(value);
        var month = safeJsonInt(map['month'], fallback: 0);
        var day = safeJsonInt(map['day'], fallback: 0);
        if (map.isEmpty && value is String) {
          final match = RegExp(
            r'^(\d{1,2})[-/](\d{1,2})$',
          ).firstMatch(value.trim());
          month = int.tryParse(match?.group(1) ?? '') ?? 0;
          day = int.tryParse(match?.group(2) ?? '') ?? 0;
        }
        if (_isValidMonthDay(month, day)) {
          _annualDates.add((month, day));
        }
      }
    }
    final tracking = existing?.tracking ?? const <String, dynamic>{};
    _trackingMethod = safeJsonString(tracking['method'], fallback: 'check');
    _goalDirection = safeJsonString(
      tracking['goal'],
      fallback: _trackingMethod == 'avoid' ? 'at_most' : 'at_least',
    );
    _target = (tracking['target'] as num?)?.toDouble() ?? 1;
    _targetValue = TextEditingController(text: _formatNumericInput(_target));
    _unit = TextEditingController(
      text: safeJsonString(tracking['unit'], fallback: ''),
    );
    final storedHabitChecklist =
        tracking[PlannerHabitTrackingKeys.checklist] ??
        existing?.payload[PlannerHabitTrackingKeys.checklist];
    if (storedHabitChecklist is Iterable) {
      _habitChecklist.addAll(
        storedHabitChecklist
            .map(safeJsonMap)
            .map(_HabitChecklistDraftItem.fromJson)
            .whereType<_HabitChecklistDraftItem>(),
      );
    }
    _habitChecklistEntry = TextEditingController();
    final successConditionValue =
        tracking[PlannerHabitTrackingKeys.successCondition];
    final successCondition = safeJsonMap(successConditionValue);
    final storedSuccessType = safeJsonString(
      successCondition.isEmpty
          ? successConditionValue
          : successCondition[PlannerHabitTrackingKeys.successType],
      fallback: 'all',
    ).toLowerCase();
    _habitSuccessType = switch (storedSuccessType) {
      'count' || 'custom' || 'at_least' => 'count',
      'percent' || 'percentage' => 'percent',
      _ => 'all',
    };
    _habitSuccessValue = TextEditingController(
      text: safeJsonInt(
        successCondition[PlannerHabitTrackingKeys.successValue],
        fallback: _habitSuccessType == 'percent' ? 100 : 1,
      ).toString(),
    );
    final recovery = existing?.recovery ?? const <String, dynamic>{};
    _recovery = safeJsonString(
      recovery['on_miss'],
      fallback: _isHabit ? 'miss_then_next' : 'pending',
    );
    _carryCap = safeJsonInt(recovery['carry_cap'], fallback: 7).clamp(1, 30);
    final reminders = existing?.payload['reminders'];
    if (reminders is Iterable && reminders.isNotEmpty) {
      final first = safeJsonMap(reminders.first);
      _reminderEnabled = first[PlannerReminderKeys.enabled] != false;
      _reminderLeadMinutes = safeJsonInt(
        first[PlannerReminderKeys.leadMinutes],
        fallback: 15,
      ).clamp(0, 1440);
      _quietHours = first[PlannerReminderKeys.respectQuietHours] == true;
      for (final raw in reminders) {
        final reminder = safeJsonMap(raw);
        final lead = safeJsonInt(
          reminder[PlannerReminderKeys.leadMinutes],
          fallback: -1,
        );
        if (lead < 0 || lead > 1440) continue;
        _reminderSnoozeByLead[lead] = safeJsonInt(
          reminder[PlannerReminderKeys.snoozeMinutes],
          fallback: 10,
        ).clamp(1, 1440);
        if (lead != _reminderLeadMinutes &&
            !_additionalReminderLeads.contains(lead)) {
          _additionalReminderLeads.add(lead);
        }
      }
    }
    final focus = safeJsonMap(existing?.payload['focus']);
    _focusEnabled = focus['enabled'] == true;
    final storedFocusMode = safeJsonString(focus['mode'], fallback: 'pomodoro');
    _focusMode =
        const <String>{
          'pomodoro',
          'countdown',
          'stopwatch',
        }.contains(storedFocusMode)
        ? storedFocusMode
        : 'pomodoro';
    _focusMinutes = safeJsonInt(focus['minutes'], fallback: 25).clamp(1, 240);
    final storedBreakPolicy = safeJsonString(
      focus[PlannerFocusPresetKeys.breakPolicy],
      fallback: 'none',
    );
    _focusBreakPolicy =
        const <String>{
          'none',
          'after_session',
          'pomodoro_cycle',
        }.contains(storedBreakPolicy)
        ? storedBreakPolicy
        : 'none';
    _focusShortBreakMinutes = safeJsonInt(
      focus[PlannerFocusPresetKeys.shortBreakMinutes],
      fallback: 5,
    ).clamp(1, 60);
    _focusLongBreakMinutes = safeJsonInt(
      focus[PlannerFocusPresetKeys.longBreakMinutes],
      fallback: 15,
    ).clamp(1, 120);
    _focusLongBreakAfterCycles = safeJsonInt(
      focus[PlannerFocusPresetKeys.longBreakAfterCycles],
      fallback: 4,
    ).clamp(2, 12);
    final properties = existing?.customProperties ?? const <String, dynamic>{};
    if (properties.isNotEmpty) {
      final first = properties.entries.first;
      _customName = TextEditingController(text: first.key);
      final value = safeJsonMap(first.value);
      _customType = safeJsonString(value['type'], fallback: 'text');
      final storedValue = value['value'];
      _customValue = TextEditingController(
        text: storedValue == null ? '' : storedValue.toString(),
      );
      _customChecked = storedValue == true;
      _formula = TextEditingController(
        text: safeJsonString(value['formula'], fallback: ''),
      );
    } else {
      _customName = TextEditingController();
      _customValue = TextEditingController();
      _formula = TextEditingController();
    }
    _link = TextEditingController(
      text: safeJsonString(existing?.payload['link'], fallback: ''),
    );
    final checklist = existing?.payload['checklist'];
    if (existing?.kind != PlannerEntityKind.habit && checklist is Iterable) {
      _checklist.addAll(
        checklist
            .map(safeJsonMap)
            .map(_ChecklistDraftItem.fromJson)
            .whereType<_ChecklistDraftItem>(),
      );
    }
    _checklistEntry = TextEditingController();
    for (final relation
        in existing?.relations ?? const <Map<String, dynamic>>[]) {
      final type = safeJsonString(relation['type'], fallback: '');
      final id = safeNullableJsonString(relation['id']);
      if (type == 'project') _projectId = id;
      if (type == 'area') _areaId = id;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _category.dispose();
    _labelEntry.dispose();
    _estimateMinutes.dispose();
    _unit.dispose();
    _targetValue.dispose();
    _link.dispose();
    _customName.dispose();
    _customValue.dispose();
    _formula.dispose();
    _checklistEntry.dispose();
    _frequencyCount.dispose();
    _habitChecklistEntry.dispose();
    _habitSuccessValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PerfectGeometryBuilder(
    builder: (context, geometry) => Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: geometry.editorMaxWidth,
        height: geometry.availableSize.height,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                geometry.horizontalGutter,
                geometry.verticalGutter,
                math.max(PerfectSpace.sm, geometry.horizontalGutter - 8),
                PerfectSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? 'Make it yours'
                          : 'Edit details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close editor',
                    onPressed: _saving ? null : widget.onDismiss,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  key: const ValueKey<String>('planner-editor-scroll'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsetsDirectional.fromSTEB(
                    geometry.horizontalGutter,
                    PerfectSpace.sm,
                    geometry.horizontalGutter,
                    geometry.isShortLandscape
                        ? PerfectSpace.lg
                        : PerfectSpace.xxl,
                  ),
                  children: [
                    _kindPicker(context),
                    const SizedBox(height: PerfectSpace.md),
                    TextFormField(
                      controller: _title,
                      autofocus: widget.existing == null,
                      maxLength: 160,
                      textDirection: _directionFor(_title.text),
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'What matters?',
                        hintText: 'e.g. Finish the portfolio case study',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Give this a clear title.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: PerfectSpace.sm),
                    TextFormField(
                      controller: _note,
                      minLines: 2,
                      maxLines: 5,
                      textDirection: _directionFor(_note.text),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: PerfectSpace.lg),
                    _section(
                      context,
                      title: 'Organization',
                      subtitle:
                          'Keep one source task while placing it in an area or project.',
                      child: _organizationSection(context),
                    ),
                    _section(
                      context,
                      title: 'Category & identity',
                      subtitle:
                          'Use a familiar label; personal categories stay yours.',
                      child: _categorySection(context),
                    ),
                    _section(
                      context,
                      title: 'Time & plan',
                      subtitle: 'Schedule without forcing a deadline.',
                      child: _timeSection(context),
                    ),
                    _section(
                      context,
                      title: 'Repeat & recovery',
                      subtitle:
                          'Define what should happen when life interrupts.',
                      child: _recoverySection(context),
                    ),
                    if (_isHabit)
                      _section(
                        context,
                        title: 'Habit tracking',
                        subtitle:
                            'A check, a number, a duration, or an avoidance goal.',
                        child: _trackingSection(context),
                      ),
                    if (_isTask)
                      _section(
                        context,
                        title: 'Task context',
                        subtitle: 'Priority, focus intent, and a useful link.',
                        child: _taskContextSection(context),
                      ),
                    if (_kind == PlannerEntityKind.oneOffTask)
                      _section(
                        context,
                        title: 'Task outcome',
                        subtitle:
                            'The same four states are available from the app and Perfect Today widget.',
                        child: _taskOutcomeSection(context),
                      ),
                    _section(
                      context,
                      title: 'Reminders',
                      subtitle:
                          'Local notification setup is requested only when you turn this on.',
                      child: _reminderSection(context),
                    ),
                    _section(
                      context,
                      title: 'Custom properties',
                      subtitle:
                          'Typed data stays local-first; formulas are declarative, never executable code.',
                      child: _propertySection(context),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  geometry.horizontalGutter,
                  PerfectSpace.sm,
                  geometry.horizontalGutter,
                  geometry.verticalGutter,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _saving ? 'Saving locally…' : 'Save to Perfect',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _kindPicker(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<PlannerEntityKind>(
        initialValue: _kind,
        decoration: const InputDecoration(labelText: 'Type'),
        items: const [
          DropdownMenuItem(
            value: PlannerEntityKind.oneOffTask,
            child: Text('One-off task'),
          ),
          DropdownMenuItem(
            value: PlannerEntityKind.recurringTask,
            child: Text('Recurring task'),
          ),
          DropdownMenuItem(
            value: PlannerEntityKind.habit,
            child: Text('Habit'),
          ),
          DropdownMenuItem(
            value: PlannerEntityKind.project,
            child: Text('Project'),
          ),
          DropdownMenuItem(value: PlannerEntityKind.area, child: Text('Area')),
        ],
        onChanged: _saving || widget.existing != null
            ? null
            : (value) => setState(() {
                _kind = value ?? PlannerEntityKind.oneOffTask;
                if (_kind == PlannerEntityKind.recurringTask &&
                    _recurrence == 'none') {
                  _recurrence = 'weekly';
                }
              }),
      ),
      if (widget.existing != null) ...[
        const SizedBox(height: PerfectSpace.xs),
        Text(
          'Type is fixed after creation so every synced device keeps the same record identity.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );

  Widget _timeSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _scheduledAt == null
                    ? 'Choose date & time'
                    : _formatDateTime(_scheduledAt!, _allDay),
              ),
            ),
          ),
          if (_scheduledAt != null) ...[
            const SizedBox(width: PerfectSpace.xs),
            IconButton(
              tooltip: 'Clear schedule',
              onPressed: () => setState(() {
                _scheduledAt = null;
                _timeBlockEndAt = null;
                _reminderEnabled = false;
              }),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
      if (_scheduledAt != null)
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('All day'),
          value: _allDay,
          onChanged: (value) => setState(() {
            _allDay = value;
            if (value) _timeBlockEndAt = null;
          }),
        ),
      if (_scheduledAt != null && !_allDay) ...[
        const SizedBox(height: PerfectSpace.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTimeBlockEnd,
                icon: const Icon(Icons.timelapse_rounded),
                label: Text(
                  _timeBlockEndAt == null
                      ? 'Add time-block end'
                      : 'Ends ${_formatDateTime(_timeBlockEndAt!, false)}',
                ),
              ),
            ),
            if (_timeBlockEndAt != null) ...[
              const SizedBox(width: PerfectSpace.xs),
              IconButton(
                tooltip: 'Clear time-block end',
                onPressed: () => setState(() => _timeBlockEndAt = null),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
        if (_timeBlockValidation() case final String error)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: PerfectSpace.md,
              top: PerfectSpace.xs,
            ),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
      const SizedBox(height: PerfectSpace.sm),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickDueDateTime,
              icon: const Icon(Icons.flag_outlined),
              label: Text(
                _dueAt == null
                    ? 'Add a deadline (optional)'
                    : 'Due ${_formatDateTime(_dueAt!, false)}',
              ),
            ),
          ),
          if (_dueAt != null) ...[
            const SizedBox(width: PerfectSpace.xs),
            IconButton(
              tooltip: 'Clear deadline',
              onPressed: () => setState(() => _dueAt = null),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
      const SizedBox(height: PerfectSpace.xs),
      Text(
        'Plan time decides where it appears. A deadline is a separate promise and never moves the item by itself.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _organizationSection(BuildContext context) => Column(
    children: [
      DropdownButtonFormField<String?>(
        initialValue: _areaId,
        decoration: const InputDecoration(labelText: 'Area'),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem(value: null, child: Text('No area')),
          ...widget.controller.areas.map(
            (area) => DropdownMenuItem(value: area.id, child: Text(area.title)),
          ),
        ],
        onChanged: (value) => setState(() => _areaId = value),
      ),
      const SizedBox(height: PerfectSpace.sm),
      DropdownButtonFormField<String?>(
        initialValue: _projectId,
        decoration: const InputDecoration(labelText: 'Project'),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem(value: null, child: Text('No project')),
          ...widget.controller.projects.map(
            (project) =>
                DropdownMenuItem(value: project.id, child: Text(project.title)),
          ),
        ],
        onChanged: (value) => setState(() => _projectId = value),
      ),
    ],
  );

  Widget _categorySection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _category,
        maxLength: 48,
        textDirection: _directionFor(_category.text),
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Category (optional)',
          hintText: 'e.g. Health, Work, Home',
          counterText: '',
        ),
      ),
      const SizedBox(height: PerfectSpace.xs),
      Wrap(
        spacing: PerfectSpace.xs,
        runSpacing: PerfectSpace.xs,
        children: [
          ..._categorySuggestions.map(
            (category) => ChoiceChip(
              avatar: PerfectPictogram(name: category, size: 19, framed: true),
              label: Text(category),
              selected:
                  _category.text.trim().toLowerCase() == category.toLowerCase(),
              onSelected: (_) => setState(() => _category.text = category),
            ),
          ),
          if (_category.text.trim().isNotEmpty)
            ActionChip(
              avatar: const Icon(Icons.close_rounded, size: 17),
              label: const Text('No category'),
              onPressed: () => setState(_category.clear),
            ),
        ],
      ),
      const SizedBox(height: PerfectSpace.md),
      TextField(
        controller: _labelEntry,
        maxLength: 40,
        textDirection: _directionFor(_labelEntry.text),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _addLabel(),
        decoration: InputDecoration(
          labelText: 'Labels',
          hintText: 'Add a reusable context',
          counterText: '',
          suffixIcon: IconButton(
            tooltip: 'Add label',
            onPressed: _addLabel,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ),
      if (_labels.isNotEmpty) ...[
        const SizedBox(height: PerfectSpace.xs),
        Wrap(
          spacing: PerfectSpace.xs,
          runSpacing: PerfectSpace.xs,
          children: _labels
              .map(
                (label) => InputChip(
                  label: Text(label, textDirection: _directionFor(label)),
                  deleteButtonTooltipMessage: 'Remove label $label',
                  onDeleted: () => setState(() => _labels.remove(label)),
                ),
              )
              .toList(growable: false),
        ),
      ],
      const SizedBox(height: PerfectSpace.md),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text('Icon', style: Theme.of(context).textTheme.labelLarge),
      ),
      const SizedBox(height: PerfectSpace.xs),
      Wrap(
        spacing: PerfectSpace.xs,
        runSpacing: PerfectSpace.xs,
        children: _plannerIconOptions
            .map(
              (icon) => ChoiceChip(
                avatar: PerfectPictogram(name: icon, size: 20, framed: true),
                label: Text(_plannerIconLabel(icon)),
                selected: _icon == icon,
                onSelected: (_) => setState(() => _icon = icon),
              ),
            )
            .toList(growable: false),
      ),
      const SizedBox(height: PerfectSpace.md),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text('Color', style: Theme.of(context).textTheme.labelLarge),
      ),
      const SizedBox(height: PerfectSpace.xs),
      Wrap(
        spacing: PerfectSpace.xs,
        runSpacing: PerfectSpace.xs,
        children: _plannerColorOptions
            .map(
              (color) => ChoiceChip(
                avatar: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _plannerColorValue(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: const SizedBox.square(dimension: 18),
                ),
                label: Text(_plannerColorLabel(color)),
                selected: _color == color,
                onSelected: (_) => setState(() => _color = color),
              ),
            )
            .toList(growable: false),
      ),
    ],
  );

  Widget _recoverySection(BuildContext context) => Column(
    children: [
      DropdownButtonFormField<String>(
        initialValue: _recurrence,
        decoration: const InputDecoration(labelText: 'Schedule rule'),
        items: [
          const DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
          const DropdownMenuItem(value: 'daily', child: Text('Every day')),
          const DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
          const DropdownMenuItem(value: 'weekly', child: Text('Every week')),
          const DropdownMenuItem(
            value: 'interval',
            child: Text('Every N days'),
          ),
          const DropdownMenuItem(value: 'monthly', child: Text('Every month')),
          const DropdownMenuItem(value: 'yearly', child: Text('Every year')),
          const DropdownMenuItem(
            value: 'flexible',
            child: Text('Flexible goal · N times per period'),
          ),
        ],
        onChanged: (value) => setState(() => _recurrence = value ?? 'none'),
      ),
      if (_recurrence == 'flexible') ...[
        const SizedBox(height: PerfectSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _frequencyCount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Completions per period',
                  helperText: 'One completion can be recorded per day.',
                ),
                validator: (value) {
                  if (_recurrence != 'flexible') return null;
                  final count = int.tryParse(value?.trim() ?? '');
                  if (count == null) return 'Enter a whole number.';
                  final maximum = _frequencyPeriod == 'week' ? 7 : 31;
                  if (count < 1 || count > maximum) {
                    return 'Choose 1–$maximum.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: PerfectSpace.sm),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _frequencyPeriod,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('Week')),
                  DropdownMenuItem(value: 'month', child: Text('Month')),
                ],
                onChanged: (value) =>
                    setState(() => _frequencyPeriod = value ?? 'week'),
              ),
            ),
          ],
        ),
        const SizedBox(height: PerfectSpace.xs),
        Text(
          'It stays available on valid days until this period’s quota is complete, then disappears from Today and Plan until the next period.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      if (_recurrence == 'interval' ||
          _recurrence == 'monthly' ||
          _recurrence == 'yearly') ...[
        const SizedBox(height: PerfectSpace.sm),
        Row(
          children: [
            Text(
              _recurrence == 'interval'
                  ? 'Every'
                  : 'Every $_recurrenceInterval',
            ),
            const SizedBox(width: PerfectSpace.sm),
            IconButton(
              tooltip: 'Decrease interval',
              onPressed: _recurrenceInterval <= 1
                  ? null
                  : () => setState(() => _recurrenceInterval--),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              _recurrence == 'interval'
                  ? '$_recurrenceInterval days'
                  : _recurrence == 'monthly'
                  ? 'months'
                  : 'years',
            ),
            IconButton(
              tooltip: 'Increase interval',
              onPressed: () => setState(() => _recurrenceInterval++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
      if (_recurrence == 'monthly') ...[
        const SizedBox(height: PerfectSpace.sm),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: PerfectSpace.sm),
          initiallyExpanded: _monthDays.isNotEmpty || _lastDayOfMonth,
          title: const Text('Dates in each month'),
          subtitle: Text(_monthRuleSummary),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: PerfectSpace.xs,
                runSpacing: PerfectSpace.xs,
                children: [
                  ...List<Widget>.generate(31, (index) {
                    final day = index + 1;
                    return FilterChip(
                      label: Text('$day'),
                      selected: _monthDays.contains(day),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _monthDays.add(day);
                        } else {
                          _monthDays.remove(day);
                        }
                      }),
                    );
                  }),
                  FilterChip(
                    avatar: const Icon(Icons.last_page_rounded, size: 18),
                    label: const Text('Last'),
                    selected: _lastDayOfMonth,
                    onSelected: (selected) =>
                        setState(() => _lastDayOfMonth = selected),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      if (_recurrence == 'yearly') ...[
        const SizedBox(height: PerfectSpace.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                _annualDates.isEmpty
                    ? 'Yearly date: use the planned start date'
                    : 'Yearly dates',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: _addAnnualDate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add date'),
            ),
          ],
        ),
        if (_annualDates.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: PerfectSpace.xs,
              runSpacing: PerfectSpace.xs,
              children: (_annualDates.toList()..sort(_compareAnnualDates))
                  .map(
                    (date) => InputChip(
                      avatar: const Icon(Icons.event_repeat_rounded, size: 18),
                      label: Text(_annualDateLabel(date)),
                      onDeleted: () =>
                          setState(() => _annualDates.remove(date)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: PerfectSpace.xs),
        Text(
          'Add every date this item should recur each year. The year itself is ignored.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      if (_recurrence == 'weekly' || _recurrence == 'weekdays') ...[
        const SizedBox(height: PerfectSpace.sm),
        Wrap(
          spacing: PerfectSpace.xs,
          runSpacing: PerfectSpace.xs,
          children: List<Widget>.generate(7, (index) {
            final weekday = index + 1;
            final selected = _recurrence == 'weekdays'
                ? weekday <= DateTime.friday
                : _weekdays.contains(weekday);
            return FilterChip(
              label: Text(_weekdayLabel(weekday)),
              selected: selected,
              onSelected: _recurrence == 'weekdays'
                  ? null
                  : (value) => setState(() {
                      if (value) {
                        _weekdays.add(weekday);
                      } else {
                        _weekdays.remove(weekday);
                      }
                    }),
            );
          }),
        ),
      ],
      if (_recurrence != 'none') ...[
        const SizedBox(height: PerfectSpace.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickRecurrenceEnd,
                icon: const Icon(Icons.event_busy_outlined),
                label: Text(
                  _recurrenceEndAt == null
                      ? 'No end date'
                      : 'Ends ${_formatDateTime(_recurrenceEndAt!, true)}',
                ),
              ),
            ),
            if (_recurrenceEndAt != null)
              IconButton(
                tooltip: 'Clear end date',
                onPressed: () => setState(() => _recurrenceEndAt = null),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        Row(
          children: [
            const Expanded(
              child: Text('Lifetime occurrence limit (0 = no limit)'),
            ),
            IconButton(
              tooltip: 'Reduce occurrence limit',
              onPressed: _occurrenceLimit <= 0
                  ? null
                  : () => setState(() => _occurrenceLimit--),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$_occurrenceLimit'),
            IconButton(
              tooltip: 'Increase occurrence limit',
              onPressed: () => setState(() => _occurrenceLimit++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'This caps the total lifetime occurrences, not the quota inside each week or month.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pause this schedule'),
          subtitle: const Text(
            'Keep history and settings without generating a new occurrence.',
          ),
          value: _recurrencePaused,
          onChanged: (value) => setState(() => _recurrencePaused = value),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _addExceptionDate,
            icon: const Icon(Icons.block_outlined),
            label: const Text('Add exception date'),
          ),
        ),
        if (_exceptionDates.isNotEmpty)
          Wrap(
            spacing: PerfectSpace.xs,
            runSpacing: PerfectSpace.xs,
            children: _exceptionDates
                .map(
                  (date) => InputChip(
                    label: Text(_formatDateTime(date, true)),
                    onDeleted: () =>
                        setState(() => _exceptionDates.remove(date)),
                  ),
                )
                .toList(),
          ),
      ],
      const SizedBox(height: PerfectSpace.md),
      DropdownButtonFormField<String>(
        initialValue: _recovery,
        decoration: const InputDecoration(labelText: 'When this is missed'),
        items: [
          const DropdownMenuItem(
            value: 'pending',
            child: Text('Keep pending until I finish it'),
          ),
          const DropdownMenuItem(
            value: 'miss_then_next',
            child: Text('Record a miss, move to the next valid slot'),
          ),
          const DropdownMenuItem(
            value: 'ask',
            child: Text('Ask me before moving it'),
          ),
        ],
        onChanged: (value) => setState(() => _recovery = value ?? 'pending'),
      ),
      if (_recovery == 'pending') ...[
        const SizedBox(height: PerfectSpace.sm),
        Row(
          children: [
            const Expanded(child: Text('Carry cap before asking')),
            IconButton(
              tooltip: 'Reduce carry cap',
              onPressed: _carryCap <= 1
                  ? null
                  : () => setState(() => _carryCap--),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$_carryCap d'),
            IconButton(
              tooltip: 'Increase carry cap',
              onPressed: _carryCap >= 30
                  ? null
                  : () => setState(() => _carryCap++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _trackingSection(BuildContext context) => Column(
    children: [
      DropdownButtonFormField<String>(
        initialValue: _trackingMethod,
        decoration: const InputDecoration(labelText: 'How do you log it?'),
        items: const [
          DropdownMenuItem(value: 'check', child: Text('A simple check-in')),
          DropdownMenuItem(value: 'count', child: Text('A number / amount')),
          DropdownMenuItem(value: 'duration', child: Text('A duration')),
          DropdownMenuItem(
            value: 'checklist',
            child: Text('A checklist with a success rule'),
          ),
          DropdownMenuItem(
            value: 'avoid',
            child: Text('Avoid / negative habit'),
          ),
        ],
        onChanged: (value) => setState(() {
          _trackingMethod = value ?? 'check';
          if (_trackingMethod == 'avoid') _goalDirection = 'at_most';
          if (_trackingMethod == 'duration' && _target < 1) {
            _target = 25;
            _targetValue.text = _formatNumericInput(_target);
          }
        }),
      ),
      if (<String>{'count', 'duration', 'avoid'}.contains(_trackingMethod)) ...[
        const SizedBox(height: PerfectSpace.sm),
        DropdownButtonFormField<String>(
          initialValue: _goalDirection,
          decoration: const InputDecoration(labelText: 'Goal direction'),
          items: const [
            DropdownMenuItem(
              value: 'at_least',
              child: Text('At least this much'),
            ),
            DropdownMenuItem(
              value: 'at_most',
              child: Text('At most this much'),
            ),
          ],
          onChanged: (value) =>
              setState(() => _goalDirection = value ?? 'at_least'),
        ),
        const SizedBox(height: PerfectSpace.sm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _targetValue,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: _trackingMethod == 'duration'
                      ? 'Daily target'
                      : 'Goal or limit',
                  suffixText: _trackingMethod == 'duration' ? 'minutes' : null,
                  helperText: _goalDirection == 'at_most'
                      ? 'Zero is valid for an avoidance limit.'
                      : 'Enter any positive value.',
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.trim());
                  if (parsed != null && parsed >= 0) {
                    setState(() => _target = parsed);
                  }
                },
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a valid target.';
                  if (parsed < 0) return 'A target cannot be negative.';
                  if (_goalDirection != 'at_most' && parsed == 0) {
                    return 'An “at least” target must be above zero.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: PerfectSpace.xs),
            IconButton(
              tooltip: 'Reduce target',
              onPressed: _target <= _minimumTarget
                  ? null
                  : () => _adjustTarget(
                      -(_trackingMethod == 'duration' ? 5.0 : 1.0),
                    ),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              tooltip: 'Increase target',
              onPressed: () =>
                  _adjustTarget(_trackingMethod == 'duration' ? 5.0 : 1.0),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_trackingMethod != 'duration') ...[
          const SizedBox(height: PerfectSpace.sm),
          TextFormField(
            controller: _unit,
            decoration: const InputDecoration(
              labelText: 'Unit (optional)',
              hintText: 'pages, glasses, km, times…',
            ),
          ),
        ],
      ],
      if (_trackingMethod == 'checklist') ...[
        const SizedBox(height: PerfectSpace.sm),
        _habitChecklistEditor(context),
      ],
    ],
  );

  Widget _habitChecklistEditor(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _habitChecklistEntry,
        maxLength: 80,
        onFieldSubmitted: (_) => _addHabitChecklistItem(),
        decoration: InputDecoration(
          labelText: 'Checklist item',
          hintText: 'e.g. Drink water',
          counterText: '',
          suffixIcon: IconButton(
            tooltip: 'Add habit checklist item',
            onPressed: _addHabitChecklistItem,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ),
      FormField<void>(
        validator: (_) {
          if (_trackingMethod == 'checklist' && _habitChecklist.isEmpty) {
            return 'Add at least one checklist item.';
          }
          return null;
        },
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_habitChecklist.isEmpty)
              Text(
                'Each item keeps a stable private ID, so editing its label never breaks today’s history.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ..._habitChecklist.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: PerfectSpace.xs),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      PerfectSpace.sm,
                      PerfectSpace.xs,
                      PerfectSpace.xs,
                      PerfectSpace.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.required
                                  ? Icons.verified_outlined
                                  : Icons.add_circle_outline_rounded,
                              size: 20,
                              color: item.required
                                  ? PerfectColors.mint
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: PerfectSpace.sm),
                            Expanded(
                              child: Text(
                                item.label,
                                textDirection: _directionFor(item.label),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit ${item.label}',
                              onPressed: () => _editHabitChecklistItem(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete ${item.label}',
                              onPressed: () =>
                                  setState(() => _habitChecklist.remove(item)),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                        FilterChip(
                          label: Text(item.required ? 'Required' : 'Optional'),
                          selected: item.required,
                          onSelected: (selected) =>
                              setState(() => item.required = selected),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (field.hasError) ...[
              const SizedBox(height: PerfectSpace.xs),
              Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: PerfectSpace.sm),
      DropdownButtonFormField<String>(
        initialValue: _habitSuccessType,
        decoration: const InputDecoration(labelText: 'Success rule'),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Complete all required')),
          DropdownMenuItem(
            value: 'count',
            child: Text('Complete at least a count'),
          ),
          DropdownMenuItem(
            value: 'percent',
            child: Text('Complete at least a percentage'),
          ),
        ],
        onChanged: (value) {
          final next = value ?? 'all';
          setState(() {
            if (next != _habitSuccessType) {
              if (next == 'percent') _habitSuccessValue.text = '100';
              if (next == 'count') _habitSuccessValue.text = '1';
            }
            _habitSuccessType = next;
          });
        },
      ),
      if (_habitSuccessType != 'all') ...[
        const SizedBox(height: PerfectSpace.sm),
        TextFormField(
          controller: _habitSuccessValue,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _habitSuccessType == 'count'
                ? 'Required completed items'
                : 'Required percentage',
            suffixText: _habitSuccessType == 'percent' ? '%' : null,
          ),
          validator: (value) {
            if (_trackingMethod != 'checklist' || _habitSuccessType == 'all') {
              return null;
            }
            final parsed = int.tryParse(value?.trim() ?? '');
            if (parsed == null) return 'Enter a whole number.';
            final maximum = _habitSuccessType == 'percent'
                ? 100
                : _habitMeasuredChecklistCount;
            if (parsed < 1 || parsed > maximum) {
              return 'Choose 1–$maximum.';
            }
            return null;
          },
        ),
      ],
      const SizedBox(height: PerfectSpace.xs),
      Text(
        'Optional items remain loggable but do not increase the required-item denominator while at least one required item exists.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _taskOutcomeSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<PlannerTaskProgressState>(
        initialValue: _taskProgressState,
        decoration: const InputDecoration(labelText: 'Current outcome'),
        items: PlannerTaskProgressState.values
            .map(
              (state) => DropdownMenuItem(
                value: state,
                child: Text(_taskProgressLabel(state)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) => setState(
          () => _taskProgressState = value ?? PlannerTaskProgressState.pending,
        ),
      ),
      if (_taskProgressState == PlannerTaskProgressState.partial) ...[
        const SizedBox(height: PerfectSpace.sm),
        Text(
          'Progress ${_taskProgressPercent.toString()}%',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          min: 1,
          max: 99,
          divisions: 98,
          value: _taskProgressPercent.toDouble(),
          label: '${_taskProgressPercent.toString()}%',
          onChanged: (value) =>
              setState(() => _taskProgressPercent = value.round().clamp(1, 99)),
        ),
      ],
    ],
  );

  Widget _taskContextSection(BuildContext context) => Column(
    children: [
      DropdownButtonFormField<String>(
        initialValue: _priority,
        decoration: const InputDecoration(labelText: 'Priority'),
        items: const [
          DropdownMenuItem(value: 'low', child: Text('Low')),
          DropdownMenuItem(value: 'normal', child: Text('Normal')),
          DropdownMenuItem(value: 'high', child: Text('High')),
          DropdownMenuItem(value: 'critical', child: Text('Critical')),
        ],
        onChanged: (value) => setState(() => _priority = value ?? 'normal'),
      ),
      const SizedBox(height: PerfectSpace.sm),
      TextFormField(
        controller: _estimateMinutes,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Estimate (minutes, optional)',
          hintText: 'e.g. 45',
        ),
        validator: (value) {
          final normalized = value?.trim() ?? '';
          if (normalized.isEmpty) return null;
          final parsed = int.tryParse(normalized);
          if (parsed == null) return 'Use a whole number of minutes.';
          if (parsed < 1 || parsed > 10080) {
            return 'Choose 1–10080 minutes.';
          }
          return null;
        },
      ),
      const SizedBox(height: PerfectSpace.sm),
      DropdownButtonFormField<String>(
        initialValue: _energy,
        decoration: const InputDecoration(labelText: 'Energy needed'),
        items: const [
          DropdownMenuItem(value: 'any', child: Text('Any energy')),
          DropdownMenuItem(value: 'low', child: Text('Low energy')),
          DropdownMenuItem(value: 'medium', child: Text('Medium energy')),
          DropdownMenuItem(value: 'high', child: Text('High energy')),
        ],
        onChanged: (value) => setState(() => _energy = value ?? 'any'),
      ),
      const SizedBox(height: PerfectSpace.sm),
      TextFormField(
        controller: _link,
        keyboardType: TextInputType.url,
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          labelText: 'Useful link (optional)',
          hintText: 'https://…',
        ),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Attach a focus preset'),
        subtitle: const Text(
          'Pomodoro, countdown, or stopwatch stays linked to this item.',
        ),
        value: _focusEnabled,
        onChanged: (value) => setState(() => _focusEnabled = value),
      ),
      if (_focusEnabled) ...[
        const SizedBox(height: PerfectSpace.xs),
        DropdownButtonFormField<String>(
          initialValue: _focusMode,
          decoration: const InputDecoration(labelText: 'Focus mode'),
          items: const [
            DropdownMenuItem(value: 'pomodoro', child: Text('Pomodoro')),
            DropdownMenuItem(value: 'countdown', child: Text('Countdown')),
            DropdownMenuItem(value: 'stopwatch', child: Text('Stopwatch')),
          ],
          onChanged: (value) =>
              setState(() => _focusMode = value ?? 'pomodoro'),
        ),
        if (_focusMode != 'stopwatch')
          Row(
            children: [
              Expanded(
                child: Text(
                  _focusMode == 'pomodoro'
                      ? 'Pomodoro length'
                      : 'Countdown length',
                ),
              ),
              IconButton(
                tooltip: 'Reduce focus minutes',
                onPressed: _focusMinutes <= 5
                    ? null
                    : () => setState(() => _focusMinutes -= 5),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_focusMinutes min'),
              IconButton(
                tooltip: 'Increase focus minutes',
                onPressed: _focusMinutes >= 240
                    ? null
                    : () => setState(() => _focusMinutes += 5),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        const SizedBox(height: PerfectSpace.sm),
        DropdownButtonFormField<String>(
          initialValue: _focusBreakPolicy,
          decoration: const InputDecoration(labelText: 'Break policy'),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('No planned break')),
            DropdownMenuItem(
              value: 'after_session',
              child: Text('Short break after each session'),
            ),
            DropdownMenuItem(
              value: 'pomodoro_cycle',
              child: Text('Short breaks + a long cycle break'),
            ),
          ],
          onChanged: (value) =>
              setState(() => _focusBreakPolicy = value ?? 'none'),
        ),
        if (_focusBreakPolicy != 'none') ...[
          const SizedBox(height: PerfectSpace.xs),
          _integerStepper(
            label: 'Short break',
            value: _focusShortBreakMinutes,
            unit: 'min',
            minimum: 1,
            maximum: 60,
            onChanged: (value) =>
                setState(() => _focusShortBreakMinutes = value),
          ),
        ],
        if (_focusBreakPolicy == 'pomodoro_cycle') ...[
          _integerStepper(
            label: 'Long break',
            value: _focusLongBreakMinutes,
            unit: 'min',
            minimum: 1,
            maximum: 120,
            step: 5,
            onChanged: (value) =>
                setState(() => _focusLongBreakMinutes = value),
          ),
          _integerStepper(
            label: 'Long break after',
            value: _focusLongBreakAfterCycles,
            unit: 'sessions',
            minimum: 2,
            maximum: 12,
            onChanged: (value) =>
                setState(() => _focusLongBreakAfterCycles = value),
          ),
        ],
      ],
      const SizedBox(height: PerfectSpace.sm),
      TextField(
        controller: _checklistEntry,
        onSubmitted: (_) => _addChecklistItem(),
        decoration: InputDecoration(
          labelText: 'Checklist item',
          hintText: 'Break this task into a next step',
          suffixIcon: IconButton(
            tooltip: 'Add checklist item',
            onPressed: _addChecklistItem,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ),
      if (_checklist.isNotEmpty) ...[
        const SizedBox(height: PerfectSpace.xs),
        Wrap(
          spacing: PerfectSpace.xs,
          runSpacing: PerfectSpace.xs,
          children: _checklist
              .map(
                (item) => Semantics(
                  button: true,
                  checked: item.isDone,
                  label:
                      '${item.isDone ? 'Reopen' : 'Complete'} checklist item ${item.title}',
                  child: InputChip(
                    avatar: Icon(
                      item.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                    ),
                    label: Text(
                      item.title,
                      style: item.isDone
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    selected: item.isDone,
                    onSelected: (_) => setState(item.toggle),
                    deleteButtonTooltipMessage:
                        'Delete checklist item ${item.title}',
                    onDeleted: () => setState(() => _checklist.remove(item)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ],
  );

  Widget _integerStepper({
    required String label,
    required int value,
    required String unit,
    required int minimum,
    required int maximum,
    required ValueChanged<int> onChanged,
    int step = 1,
  }) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton(
        tooltip: 'Reduce ${label.toLowerCase()}',
        onPressed: value <= minimum
            ? null
            : () => onChanged((value - step).clamp(minimum, maximum).toInt()),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      Semantics(label: '$label $value $unit', child: Text('$value $unit')),
      IconButton(
        tooltip: 'Increase ${label.toLowerCase()}',
        onPressed: value >= maximum
            ? null
            : () => onChanged((value + step).clamp(minimum, maximum).toInt()),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );

  Widget _reminderSection(BuildContext context) => Column(
    children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Reminder'),
        subtitle: const Text('Only scheduled items can notify you.'),
        value: _reminderEnabled,
        onChanged: _scheduledAt == null
            ? null
            : (value) => setState(() => _reminderEnabled = value),
      ),
      if (_scheduledAt == null)
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text('Pick a date first to enable a reminder.'),
        ),
      if (_reminderEnabled) ...[
        const SizedBox(height: PerfectSpace.sm),
        DropdownButtonFormField<int>(
          initialValue: _reminderLeadMinutes,
          decoration: const InputDecoration(labelText: 'Remind me'),
          items: const [
            DropdownMenuItem(value: 0, child: Text('At the time')),
            DropdownMenuItem(value: 5, child: Text('5 minutes before')),
            DropdownMenuItem(value: 15, child: Text('15 minutes before')),
            DropdownMenuItem(value: 30, child: Text('30 minutes before')),
            DropdownMenuItem(value: 60, child: Text('1 hour before')),
            DropdownMenuItem(value: 120, child: Text('2 hours before')),
            DropdownMenuItem(value: 1440, child: Text('1 day before')),
          ],
          onChanged: (value) {
            final next = value ?? 15;
            setState(() {
              final previous = _reminderLeadMinutes;
              _reminderLeadMinutes = next;
              _additionalReminderLeads.remove(next);
              _reminderSnoozeByLead.putIfAbsent(
                next,
                () => _reminderSnoozeByLead[previous] ?? 10,
              );
            });
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Respect quiet hours'),
          value: _quietHours,
          onChanged: (value) => setState(() => _quietHours = value),
        ),
        const SizedBox(height: PerfectSpace.sm),
        _reminderSnoozeRow(_reminderLeadMinutes),
        ..._additionalReminderLeads.map(
          (lead) => _reminderSnoozeRow(lead, removable: true),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Another reminder'),
            onPressed: () => setState(() {
              const candidates = <int>[5, 30, 60, 1440];
              final selected = <int>{
                _reminderLeadMinutes,
                ..._additionalReminderLeads,
              };
              final lead = candidates.firstWhere(
                (candidate) => !selected.contains(candidate),
                orElse: () => 120,
              );
              if (!selected.contains(lead)) {
                _additionalReminderLeads.add(lead);
                _reminderSnoozeByLead[lead] = 10;
              }
            }),
          ),
        ),
      ],
    ],
  );

  Widget _reminderSnoozeRow(int lead, {bool removable = false}) => Padding(
    padding: const EdgeInsets.only(bottom: PerfectSpace.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_reminderLeadLabel(lead)} · snooze',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            if (removable)
              IconButton(
                tooltip: 'Delete ${_reminderLeadLabel(lead)} reminder',
                onPressed: () => setState(() {
                  _additionalReminderLeads.remove(lead);
                  _reminderSnoozeByLead.remove(lead);
                }),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Reduce snooze for ${_reminderLeadLabel(lead)}',
              onPressed: (_reminderSnoozeByLead[lead] ?? 10) <= 1
                  ? null
                  : () => setState(() {
                      _reminderSnoozeByLead[lead] =
                          ((_reminderSnoozeByLead[lead] ?? 10) - 5)
                              .clamp(1, 1440)
                              .toInt();
                    }),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PerfectSpace.xs,
                ),
                child: Text(
                  '${_reminderSnoozeByLead[lead] ?? 10} min',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Increase snooze for ${_reminderLeadLabel(lead)}',
              onPressed: (_reminderSnoozeByLead[lead] ?? 10) >= 1440
                  ? null
                  : () => setState(() {
                      _reminderSnoozeByLead[lead] =
                          ((_reminderSnoozeByLead[lead] ?? 10) + 5)
                              .clamp(1, 1440)
                              .toInt();
                    }),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _propertySection(BuildContext context) => Column(
    children: [
      TextFormField(
        controller: _customName,
        decoration: const InputDecoration(
          labelText: 'Property name',
          hintText: 'e.g. Energy, Cost, Mood',
        ),
      ),
      const SizedBox(height: PerfectSpace.sm),
      DropdownButtonFormField<String>(
        initialValue: _customType,
        decoration: const InputDecoration(labelText: 'Property type'),
        items: const [
          DropdownMenuItem(value: 'text', child: Text('Text')),
          DropdownMenuItem(value: 'number', child: Text('Number')),
          DropdownMenuItem(value: 'checkbox', child: Text('Checkbox')),
          DropdownMenuItem(value: 'date', child: Text('Date')),
          DropdownMenuItem(
            value: 'formula',
            child: Text('Formula specification'),
          ),
          DropdownMenuItem(
            value: 'relation',
            child: Text('Relation specification'),
          ),
        ],
        onChanged: (value) => setState(() => _customType = value ?? 'text'),
      ),
      if (_customType == 'checkbox')
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Checked value'),
          value: _customChecked,
          onChanged: (value) => setState(() => _customChecked = value),
        ),
      if (!<String>{
        'formula',
        'relation',
        'checkbox',
      }.contains(_customType)) ...[
        const SizedBox(height: PerfectSpace.sm),
        TextFormField(
          controller: _customValue,
          keyboardType: _customType == 'number'
              ? const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                )
              : TextInputType.text,
          textDirection: _customType == 'number'
              ? TextDirection.ltr
              : _directionFor(_customValue.text),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: switch (_customType) {
              'number' => 'Numeric value',
              'date' => 'Date value',
              _ => 'Text value',
            },
            hintText: _customType == 'number'
                ? 'e.g. 12.5'
                : _customType == 'date'
                ? 'e.g. 2026-07-27'
                : 'Optional value',
          ),
        ),
      ],
      if (_customType == 'formula' || _customType == 'relation') ...[
        const SizedBox(height: PerfectSpace.sm),
        TextFormField(
          controller: _formula,
          textDirection: TextDirection.ltr,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: _customType == 'formula'
                ? 'Formula DSL'
                : 'Relation target key',
            hintText: _customType == 'formula'
                ? 'amount / target'
                : 'project_id',
          ),
        ),
        const SizedBox(height: PerfectSpace.xs),
        const Text(
          'Formulas use only numbers, property names, + − × ÷, min, max, and round. Never arbitrary code.',
        ),
        if (_customType == 'formula' && _formula.text.trim().isNotEmpty) ...[
          const SizedBox(height: PerfectSpace.xs),
          _formulaPreview(context),
        ],
      ],
    ],
  );

  Widget _formulaPreview(BuildContext context) {
    final result = PlannerFormula.evaluate(
      _formula.text,
      widget.existing?.customProperties ?? const <String, dynamic>{},
    );
    return Text(
      result.isValid
          ? 'Preview: ${result.displayValue}'
          : result.error ?? 'This formula needs a value.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: result.isValid
            ? PerfectColors.mint
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) => Card(
    margin: const EdgeInsets.only(top: PerfectSpace.md),
    child: ExpansionTile(
      expansionAnimationStyle: PerfectMotion.style(
        context,
        duration: PerfectMotion.emphasized,
      ),
      tilePadding: const EdgeInsets.symmetric(
        horizontal: PerfectSpace.md,
        vertical: PerfectSpace.xs,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        PerfectSpace.md,
        0,
        PerfectSpace.md,
        PerfectSpace.lg,
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      children: [child],
    ),
  );

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _scheduledAt?.toLocal() ?? now;
    final previousDuration =
        _scheduledAt != null &&
            _timeBlockEndAt != null &&
            _timeBlockEndAt!.isAfter(_scheduledAt!)
        ? _timeBlockEndAt!.difference(_scheduledAt!)
        : null;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 20),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    setState(() {
      final selectedStart = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? initial.hour,
        time?.minute ?? initial.minute,
      ).toUtc();
      _scheduledAt = selectedStart;
      if (previousDuration != null) {
        _timeBlockEndAt = selectedStart.add(previousDuration);
      }
    });
  }

  Future<void> _pickTimeBlockEnd() async {
    final start = _scheduledAt?.toLocal();
    if (start == null || _allDay) return;
    final estimate = int.tryParse(_estimateMinutes.text.trim());
    final initial =
        _timeBlockEndAt?.toLocal() ??
        start.add(Duration(minutes: estimate?.clamp(1, 10080).toInt() ?? 60));
    final date = await showDatePicker(
      context: context,
      helpText: 'Time-block end date',
      firstDate: DateTime(start.year, start.month, start.day),
      lastDate: DateTime(start.year + 20),
      initialDate: initial.isBefore(start) ? start : initial,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Time-block end time',
    );
    if (!mounted) return;
    setState(() {
      _timeBlockEndAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? initial.hour,
        time?.minute ?? initial.minute,
      ).toUtc();
    });
  }

  String? _timeBlockValidation() {
    final end = _timeBlockEndAt;
    if (end == null) return null;
    final start = _scheduledAt;
    if (start == null) return 'Choose a start before setting a block end.';
    if (_allDay) return 'All-day items do not use a timed block end.';
    if (!end.isAfter(start)) return 'Time-block end must be after its start.';
    return null;
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final initial =
        _dueAt?.toLocal() ?? DateTime(now.year, now.month, now.day, 23, 59);
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 30),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Deadline time',
    );
    if (!mounted) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? initial.hour,
        time?.minute ?? initial.minute,
      ).toUtc();
    });
  }

  Future<void> _pickRecurrenceEnd() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      initialDate: _recurrenceEndAt?.toLocal() ?? now,
    );
    if (selected == null || !mounted) return;
    setState(() => _recurrenceEndAt = _dateOnly(selected).toUtc());
  }

  Future<void> _addExceptionDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 30),
      initialDate: now,
    );
    if (selected == null || !mounted) return;
    setState(() => _exceptionDates.add(_dateOnly(selected).toUtc()));
  }

  Future<void> _addAnnualDate() async {
    final now = widget.controller.localNow;
    final preferred = _annualDates.isEmpty
        ? (
            (_scheduledAt?.toLocal() ?? now).month,
            (_scheduledAt?.toLocal() ?? now).day,
          )
        : (_annualDates.toList()..sort(_compareAnnualDates)).first;
    final initialDate = _annualPickerDate(preferred, now.year);
    final selected = await showDatePicker(
      context: context,
      helpText: 'Choose a yearly date',
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      initialDate: initialDate,
    );
    if (selected == null || !mounted) return;
    setState(() => _annualDates.add((selected.month, selected.day)));
  }

  void _addChecklistItem() {
    final title = _checklistEntry.text.trim();
    if (title.isEmpty ||
        _checklist.any(
          (item) => item.title.toLowerCase() == title.toLowerCase(),
        )) {
      return;
    }
    setState(() {
      _checklist.add(_ChecklistDraftItem(title: title));
      _checklistEntry.clear();
    });
  }

  void _addLabel() {
    final label = _labelEntry.text.trim();
    if (label.isEmpty) return;
    if (_labels.any(
      (existing) => existing.toLowerCase() == label.toLowerCase(),
    )) {
      _labelEntry.clear();
      return;
    }
    if (_labels.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A planner item can keep up to 20 labels.'),
        ),
      );
      return;
    }
    setState(() {
      _labels.add(label);
      _labelEntry.clear();
    });
  }

  int get _habitMeasuredChecklistCount {
    final required = _habitChecklist.where((item) => item.required).length;
    return (required == 0 ? _habitChecklist.length : required).clamp(1, 9999);
  }

  void _addHabitChecklistItem() {
    final label = _habitChecklistEntry.text.trim();
    if (label.isEmpty ||
        _habitChecklist.any(
          (item) => item.label.toLowerCase() == label.toLowerCase(),
        )) {
      return;
    }
    setState(() {
      _habitChecklist.add(_HabitChecklistDraftItem.create(label));
      _habitChecklistEntry.clear();
    });
  }

  Future<void> _editHabitChecklistItem(_HabitChecklistDraftItem item) async {
    final formKey = GlobalKey<FormState>();
    var draft = item.label;
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit checklist label'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: item.label,
            autofocus: true,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Label'),
            onChanged: (value) => draft = value,
            validator: (value) {
              final normalized = value?.trim() ?? '';
              if (normalized.isEmpty) return 'Enter a label.';
              if (_habitChecklist.any(
                (candidate) =>
                    !identical(candidate, item) &&
                    candidate.label.toLowerCase() == normalized.toLowerCase(),
              )) {
                return 'That label already exists.';
              }
              return null;
            },
            onFieldSubmitted: (value) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(draft.trim());
              }
            },
            child: const Text('Save label'),
          ),
        ],
      ),
    );
    if (updated != null && mounted) {
      setState(() => item.label = updated);
    }
  }

  double get _minimumTarget => _goalDirection == 'at_most'
      ? 0
      : (_trackingMethod == 'duration' ? 1 : .1);

  void _adjustTarget(double delta) {
    final adjusted = _target + delta;
    setState(() {
      _target = adjusted < _minimumTarget ? _minimumTarget : adjusted;
      _targetValue.text = _formatNumericInput(_target);
      _targetValue.selection = TextSelection.collapsed(
        offset: _targetValue.text.length,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final pendingLabel = _labelEntry.text.trim();
    if (pendingLabel.isNotEmpty &&
        !_labels.any(
          (label) => label.toLowerCase() == pendingLabel.toLowerCase(),
        )) {
      if (_labels.length >= 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Remove a label before adding another one.'),
          ),
        );
        return;
      }
      _labels.add(pendingLabel);
      _labelEntry.clear();
    }
    final timeBlockError = _timeBlockValidation();
    if (timeBlockError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(timeBlockError)));
      return;
    }
    if (_isHabit &&
        <String>{'count', 'duration', 'avoid'}.contains(_trackingMethod)) {
      _target = double.parse(_targetValue.text.trim());
    }
    final rawCustomValue = _customValue.text.trim();
    final numericCustomValue =
        _customType == 'number' && rawCustomValue.isNotEmpty
        ? num.tryParse(rawCustomValue)
        : null;
    if (_customType == 'number' &&
        rawCustomValue.isNotEmpty &&
        numericCustomValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A number property needs a valid number.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final properties = <String, dynamic>{
      ...widget.existing?.customProperties ?? const <String, dynamic>{},
    };
    final propertyName = _customName.text.trim();
    if (propertyName.isNotEmpty) {
      properties[propertyName] = <String, dynamic>{
        'type': _customType,
        if (_customType == 'checkbox') 'value': _customChecked,
        if (_customType == 'number' && rawCustomValue.isNotEmpty)
          'value': numericCustomValue,
        if (<String>{'text', 'date'}.contains(_customType) &&
            rawCustomValue.isNotEmpty)
          'value': rawCustomValue,
        if (_formula.text.trim().isNotEmpty) 'formula': _formula.text.trim(),
      };
    }
    final taskProgress = _kind == PlannerEntityKind.oneOffTask
        ? PlannerTaskProgress(
            state: _taskProgressState,
            percent: _taskProgressPercent,
          ).normalized
        : null;
    final estimateMinutes = int.tryParse(_estimateMinutes.text.trim());
    final payload = <String, dynamic>{
      ...widget.existing?.payload ?? const <String, dynamic>{},
      PlannerPayloadKeys.title: _title.text.trim(),
      PlannerPayloadKeys.note: _note.text.trim(),
      PlannerPayloadKeys.status:
          taskProgress?.applyToPayload(
            const <String, dynamic>{},
          )[PlannerPayloadKeys.status] ??
          widget.existing?.status.wireValue ??
          'active',
      PlannerPayloadKeys.timing: <String, dynamic>{
        'scheduled_at': _scheduledAt?.toUtc().toIso8601String(),
        PlannerTaskMetadataKeys.timeBlockEndAt: _timeBlockEndAt
            ?.toUtc()
            .toIso8601String(),
        'due_at': _dueAt?.toUtc().toIso8601String(),
        'all_day': _allDay,
      },
      PlannerPayloadKeys.recurrence: <String, dynamic>{
        'rule': _recurrence,
        'interval': _recurrenceInterval,
        'occurrence_limit': _occurrenceLimit,
        'paused': _recurrencePaused,
        'flexible': _recurrenceFlexible,
        if (_recurrenceEndAt != null)
          'end_at': _recurrenceEndAt!.toUtc().toIso8601String(),
        if (_exceptionDates.isNotEmpty)
          'exceptions':
              _exceptionDates
                  .map((date) => date.toUtc().toIso8601String())
                  .toList()
                ..sort(),
        if (_recurrence == 'weekly') 'weekdays': _weekdays.toList()..sort(),
        if (_recurrence == 'weekdays')
          'weekdays': <int>[
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
          ],
        if (_recurrence == 'monthly' && _monthDays.isNotEmpty)
          PlannerRecurrenceKeys.monthDays: _monthDays.toList()..sort(),
        if (_recurrence == 'monthly' && _lastDayOfMonth)
          PlannerRecurrenceKeys.lastDayOfMonth: true,
        if (_recurrence == 'yearly' && _annualDates.isNotEmpty)
          PlannerRecurrenceKeys
              .annualDates: (_annualDates.toList()..sort(_compareAnnualDates))
              .map((date) => <String, int>{'month': date.$1, 'day': date.$2})
              .toList(growable: false),
        if (_recurrence == 'flexible')
          PlannerRecurrenceKeys.frequency: <String, dynamic>{
            PlannerRecurrenceKeys.frequencyCount: int.parse(
              _frequencyCount.text.trim(),
            ),
            PlannerRecurrenceKeys.frequencyPeriod: _frequencyPeriod,
          },
      },
      PlannerPayloadKeys.tracking: <String, dynamic>{
        'method': _isHabit ? _trackingMethod : 'check',
        if (_isHabit &&
            <String>{'count', 'duration', 'avoid'}.contains(_trackingMethod))
          'target': _target,
        if (_isHabit &&
            <String>{'count', 'duration', 'avoid'}.contains(_trackingMethod))
          'goal': _goalDirection,
        if (_isHabit && _trackingMethod == 'duration') 'unit': 'minutes',
        if (_isHabit &&
            <String>{'count', 'avoid'}.contains(_trackingMethod) &&
            _trackingMethod != 'duration' &&
            _unit.text.trim().isNotEmpty)
          'unit': _unit.text.trim(),
        if (_isHabit && _trackingMethod == 'checklist')
          PlannerHabitTrackingKeys.checklist: _habitChecklist
              .map((item) => item.toJson())
              .toList(growable: false),
        if (_isHabit && _trackingMethod == 'checklist')
          PlannerHabitTrackingKeys.successCondition: <String, dynamic>{
            PlannerHabitTrackingKeys.successType: _habitSuccessType,
            if (_habitSuccessType != 'all')
              PlannerHabitTrackingKeys.successValue: int.parse(
                _habitSuccessValue.text.trim(),
              ),
          },
      },
      PlannerPayloadKeys.recovery: <String, dynamic>{
        'on_miss': _recovery,
        'carry_cap': _carryCap,
      },
      PlannerPayloadKeys.properties: properties,
      PlannerPayloadKeys.relations: <Map<String, dynamic>>[
        if (_areaId != null) <String, dynamic>{'type': 'area', 'id': _areaId},
        if (_projectId != null)
          <String, dynamic>{'type': 'project', 'id': _projectId},
      ],
      'priority': _priority,
      'category': _category.text.trim(),
      PlannerTaskMetadataKeys.labels: _labels.toList(growable: false),
      PlannerTaskMetadataKeys.icon: _icon,
      PlannerTaskMetadataKeys.color: _color,
      PlannerTaskMetadataKeys.energy: _isTask ? _energy : null,
      PlannerTaskMetadataKeys.estimateMinutes: _isTask ? estimateMinutes : null,
      'link': _isTask && _link.text.trim().isNotEmpty
          ? _link.text.trim()
          : null,
      if (_isTask)
        'checklist': _checklist
            .map((item) => item.toJson())
            .toList(growable: false),
      'focus': <String, dynamic>{
        PlannerFocusPresetKeys.enabled: _isTask && _focusEnabled,
        PlannerFocusPresetKeys.mode: _focusMode,
        PlannerFocusPresetKeys.minutes: _focusMinutes,
        PlannerFocusPresetKeys.breakPolicy: _focusBreakPolicy,
        PlannerFocusPresetKeys.shortBreakMinutes: _focusShortBreakMinutes,
        PlannerFocusPresetKeys.longBreakMinutes: _focusLongBreakMinutes,
        PlannerFocusPresetKeys.longBreakAfterCycles: _focusLongBreakAfterCycles,
      },
      'reminders': <Map<String, dynamic>>[
        if (_reminderEnabled && _scheduledAt != null)
          for (final lead in <int>{
            _reminderLeadMinutes,
            ..._additionalReminderLeads,
          }.toList()..sort())
            <String, dynamic>{
              PlannerReminderKeys.enabled: true,
              PlannerReminderKeys.leadMinutes: lead,
              PlannerReminderKeys.snoozeMinutes:
                  (_reminderSnoozeByLead[lead] ?? 10).clamp(1, 1440).toInt(),
              PlannerReminderKeys.respectQuietHours: _quietHours,
            },
      ],
      if (taskProgress != null)
        PlannerPayloadKeys.taskProgressState: taskProgress.state.wireValue,
      if (taskProgress != null)
        PlannerPayloadKeys.taskProgressPercent: taskProgress.percent,
    };
    try {
      await widget.controller.saveEntity(
        kind: _kind,
        existing: widget.existing,
        payload: payload,
      );
      if (mounted) widget.onDismiss?.call();
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally failed. Your draft is still here.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _HabitChecklistDraftItem {
  _HabitChecklistDraftItem({
    required this.id,
    required this.label,
    required this.required,
    this.source = const <String, dynamic>{},
  });

  factory _HabitChecklistDraftItem.create(String label) =>
      _HabitChecklistDraftItem(
        id: const Uuid().v4(),
        label: label,
        required: true,
      );

  final String id;
  final Map<String, dynamic> source;
  String label;
  bool required;

  static _HabitChecklistDraftItem? fromJson(Map<String, dynamic> source) {
    final label =
        safeNullableJsonString(source['label']) ??
        safeNullableJsonString(source['title']);
    if (label == null) return null;
    return _HabitChecklistDraftItem(
      id:
          safeNullableJsonString(source[PlannerHabitTrackingKeys.itemId]) ??
          const Uuid().v4(),
      label: label,
      required: source[PlannerHabitTrackingKeys.itemRequired] != false,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...source,
    PlannerHabitTrackingKeys.itemId: id,
    'label': label,
    PlannerHabitTrackingKeys.itemRequired: required,
  };
}

class _ChecklistDraftItem {
  _ChecklistDraftItem({
    required this.title,
    this.isDone = false,
    this.source = const <String, dynamic>{},
  });

  final String title;
  final Map<String, dynamic> source;
  bool isDone;

  static _ChecklistDraftItem? fromJson(Map<String, dynamic> source) {
    final title = safeNullableJsonString(source['title']);
    if (title == null) return null;
    return _ChecklistDraftItem(
      title: title,
      isDone: source['is_done'] == true,
      source: source,
    );
  }

  void toggle() => isDone = !isDone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...source,
    'title': title,
    'is_done': isDone,
  };
}

String _formatNumericInput(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

bool _isValidMonthDay(int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return false;
  final normalized = DateTime(2000, month, day);
  return normalized.month == month && normalized.day == day;
}

int _compareAnnualDates((int month, int day) left, (int month, int day) right) {
  final month = left.$1.compareTo(right.$1);
  return month == 0 ? left.$2.compareTo(right.$2) : month;
}

DateTime _annualPickerDate((int month, int day) date, int preferredYear) {
  var year = preferredYear.clamp(2000, 2100);
  while (year <= 2100) {
    final candidate = DateTime(year, date.$1, date.$2);
    if (candidate.month == date.$1 && candidate.day == date.$2) {
      return candidate;
    }
    year++;
  }
  return DateTime(2000, date.$1, date.$2);
}

String _annualDateLabel((int month, int day) date) =>
    '${_monthLabels[date.$1 - 1]} ${date.$2}';

const _monthLabels = <String>[
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

const _plannerIconOptions = <String>[
  'default',
  'task',
  'habit',
  'work',
  'study',
  'health',
  'home',
  'idea',
  'star',
];

const _plannerColorOptions = <String>[
  'apricot',
  'mint',
  'lilac',
  'rose',
  'ink',
];

String _plannerIconLabel(String icon) => switch (icon) {
  'task' => 'Task',
  'habit' => 'Habit',
  'work' => 'Work',
  'study' => 'Study',
  'health' => 'Health',
  'home' => 'Home',
  'idea' => 'Idea',
  'star' => 'Star',
  _ => 'Perfect',
};

Color _plannerColorValue(String color) => switch (color) {
  'mint' => PerfectColors.mint,
  'lilac' => PerfectColors.lilac,
  'rose' => PerfectColors.danger,
  'ink' => PerfectColors.ink,
  _ => PerfectColors.apricot,
};

String _plannerColorLabel(String color) => switch (color) {
  'mint' => 'Mint',
  'lilac' => 'Lilac',
  'rose' => 'Rose',
  'ink' => 'Ink',
  _ => 'Apricot',
};

TextDirection _directionFor(String value) {
  final rtl = RegExp(r'[\u0600-\u08ff]').hasMatch(value);
  return rtl ? TextDirection.rtl : TextDirection.ltr;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _reminderLeadLabel(int minutes) => switch (minutes) {
  0 => 'At time',
  60 => '1 hour before',
  1440 => '1 day before',
  _ => '$minutes min before',
};

String _taskProgressLabel(PlannerTaskProgressState state) => switch (state) {
  PlannerTaskProgressState.pending => 'Empty / undecided',
  PlannerTaskProgressState.completed => 'Done',
  PlannerTaskProgressState.missed => 'Not done',
  PlannerTaskProgressState.partial => 'Partial progress',
};

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'Mon',
  DateTime.tuesday => 'Tue',
  DateTime.wednesday => 'Wed',
  DateTime.thursday => 'Thu',
  DateTime.friday => 'Fri',
  DateTime.saturday => 'Sat',
  _ => 'Sun',
};

String _formatDateTime(DateTime value, bool allDay) {
  final local = value.toLocal();
  final month = _monthLabels[local.month - 1];
  if (allDay) return '$month ${local.day} · all day';
  final hour = local.hour == 0
      ? 12
      : (local.hour > 12 ? local.hour - 12 : local.hour);
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day} · $hour:${local.minute.toString().padLeft(2, '0')} $suffix';
}
