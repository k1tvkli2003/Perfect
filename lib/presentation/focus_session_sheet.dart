import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_operation.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

class FocusSessionSheet extends StatefulWidget {
  const FocusSessionSheet({super.key, required this.controller, this.entity});

  final PlannerWorkspaceController controller;
  final PlannerEntity? entity;

  static Future<void> show(
    BuildContext context, {
    required PlannerWorkspaceController controller,
    PlannerEntity? entity,
  }) {
    final desktop =
        Theme.of(context).platform == TargetPlatform.windows ||
        MediaQuery.sizeOf(context).width >= 900;
    if (desktop) {
      return showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 560,
              maxWidth: 680,
              maxHeight: (MediaQuery.sizeOf(context).height - 80).clamp(
                560,
                780,
              ),
            ),
            child: FocusSessionSheet(controller: controller, entity: entity),
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
          heightFactor: .9,
          child: FocusSessionSheet(controller: controller, entity: entity),
        ),
      ),
    );
  }

  @override
  State<FocusSessionSheet> createState() => _FocusSessionSheetState();
}

class _FocusSessionSheetState extends State<FocusSessionSheet> {
  Timer? _ticker;
  PlannerFocusSession? _session;
  DateTime? _startedAt;
  Duration _pausedFor = Duration.zero;
  DateTime? _pausedAt;
  String _mode = 'pomodoro';
  int _minutes = 25;
  String _breakPolicy = 'none';
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _longBreakAfterCycles = 4;
  bool _busy = false;
  bool _loading = true;

  bool get _isRunning => _session != null && _pausedAt == null;
  bool get _isPaused => _session != null && _pausedAt != null;

  Duration get _elapsed {
    final started = _startedAt;
    if (started == null) return Duration.zero;
    final end = _pausedAt ?? DateTime.now();
    return end.difference(started) - _pausedFor;
  }

  Duration get _remaining => Duration(minutes: _minutes) - _elapsed;

  @override
  void initState() {
    super.initState();
    final preset = safeJsonMap(widget.entity?.payload['focus']);
    if (preset['enabled'] == true) {
      final mode = safeJsonString(preset['mode'], fallback: 'pomodoro');
      _mode =
          const <String>{'pomodoro', 'countdown', 'stopwatch'}.contains(mode)
          ? mode
          : 'pomodoro';
      _minutes = safeJsonInt(
        preset['minutes'],
        fallback: _mode == 'pomodoro' ? 25 : 30,
      ).clamp(1, 240).toInt();
      final policy = safeJsonString(
        preset[PlannerFocusPresetKeys.breakPolicy],
        fallback: 'none',
      );
      _breakPolicy =
          const <String>{
            'none',
            'after_session',
            'pomodoro_cycle',
          }.contains(policy)
          ? policy
          : 'none';
      _shortBreakMinutes = safeJsonInt(
        preset[PlannerFocusPresetKeys.shortBreakMinutes],
        fallback: 5,
      ).clamp(1, 60);
      _longBreakMinutes = safeJsonInt(
        preset[PlannerFocusPresetKeys.longBreakMinutes],
        fallback: 15,
      ).clamp(1, 120);
      _longBreakAfterCycles = safeJsonInt(
        preset[PlannerFocusPresetKeys.longBreakAfterCycles],
        fallback: 4,
      ).clamp(2, 12);
    }
    unawaited(_restoreActiveSession());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerMode = _mode != 'stopwatch';
    final visible = timerMode
        ? _remaining.isNegative
              ? Duration.zero
              : _remaining
        : _elapsed;
    final progress = timerMode
        ? (1 -
                  (_remaining.inMilliseconds /
                      Duration(minutes: _minutes).inMilliseconds))
              .clamp(0.0, 1.0)
        : 0.32;
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
                      'Focus',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      _focusTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close focus',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Spacer(),
          SizedBox.square(
            dimension: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 13,
                  color: PerfectColors.apricot,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: .45),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(visible),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: PerfectSpace.xs),
                    Text(
                      _session == null
                          ? 'Ready when you are'
                          : _isPaused
                          ? 'Paused locally'
                          : _mode == 'pomodoro'
                          ? 'Deep work'
                          : _mode == 'countdown'
                          ? 'Countdown'
                          : 'Stopwatch',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: PerfectSpace.xl),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: PerfectSpace.lg),
              child: CircularProgressIndicator(),
            )
          else if (_session == null) ...[
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pomodoro', label: Text('Pomodoro')),
                ButtonSegment(value: 'countdown', label: Text('Countdown')),
                ButtonSegment(value: 'stopwatch', label: Text('Stopwatch')),
              ],
              selected: <String>{_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            if (_mode != 'stopwatch') ...[
              const SizedBox(height: PerfectSpace.md),
              Row(
                children: [
                  const Expanded(child: Text('Session length')),
                  IconButton(
                    tooltip: 'Reduce focus duration',
                    onPressed: _minutes <= 5
                        ? null
                        : () => setState(() => _minutes -= 5),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_minutes min'),
                  IconButton(
                    tooltip: 'Increase focus duration',
                    onPressed: _minutes >= 240
                        ? null
                        : () => setState(() => _minutes += 5),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
            if (_breakPolicy != 'none') ...[
              const SizedBox(height: PerfectSpace.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.free_breakfast_outlined),
                title: const Text('Break plan'),
                subtitle: Text(_breakPolicySummary),
              ),
            ],
          ],
          const Spacer(),
          if (_loading)
            const SizedBox.shrink()
          else if (_session == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _start,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start focus'),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : (_isRunning ? _pause : _resume),
                icon: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(_isRunning ? 'Pause' : 'Resume'),
              ),
            ),
            const SizedBox(height: PerfectSpace.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _finish(cancelled: true),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: PerfectSpace.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _finish(),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Complete'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: PerfectSpace.xs),
          Text(
            _loading
                ? 'Checking this device for an interrupted focus session…'
                : _session == null
                ? 'Starting stores the session locally before any network request.'
                : 'Close safely: reopening Focus restores this active session on this device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final session = await widget.controller.beginFocus(
        entity: widget.entity,
        mode: _mode,
        plannedMinutes: _mode == 'stopwatch' ? null : _minutes,
        breakPolicy: _breakPolicy,
        shortBreakMinutes: _shortBreakMinutes,
        longBreakMinutes: _longBreakMinutes,
        longBreakAfterCycles: _longBreakAfterCycles,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _applySessionSettings(session);
      });
      _startTicker();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pause() => setState(() => _pausedAt = DateTime.now());

  void _resume() => setState(() {
    final pausedAt = _pausedAt;
    if (pausedAt != null) _pausedFor += DateTime.now().difference(pausedAt);
    _pausedAt = null;
  });

  Future<void> _finish({bool cancelled = false}) async {
    final session = _session;
    if (session == null || _busy) return;
    _ticker?.cancel();
    setState(() => _busy = true);
    try {
      await widget.controller.completeFocus(
        session,
        elapsed: _elapsed,
        cancelled: cancelled,
      );
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreActiveSession() async {
    try {
      final session = await widget.controller.activeFocusSession();
      if (!mounted) return;
      setState(() {
        _session = session;
        if (session != null) _applySessionSettings(session);
        _loading = false;
      });
      if (session != null) _startTicker();
    } on Object {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySessionSettings(PlannerFocusSession session) {
    _startedAt = session.startedAt.toLocal();
    _mode = session.mode;
    _minutes = safeJsonInt(
      session.payload['planned_duration_minutes'],
      fallback: session.mode == 'pomodoro' ? 25 : 30,
    ).clamp(1, 240).toInt();
    final policy = safeJsonString(
      session.payload[PlannerFocusPresetKeys.breakPolicy],
      fallback: 'none',
    );
    _breakPolicy =
        const <String>{
          'none',
          'after_session',
          'pomodoro_cycle',
        }.contains(policy)
        ? policy
        : 'none';
    _shortBreakMinutes = safeJsonInt(
      session.payload[PlannerFocusPresetKeys.shortBreakMinutes],
      fallback: 5,
    ).clamp(1, 60);
    _longBreakMinutes = safeJsonInt(
      session.payload[PlannerFocusPresetKeys.longBreakMinutes],
      fallback: 15,
    ).clamp(1, 120);
    _longBreakAfterCycles = safeJsonInt(
      session.payload[PlannerFocusPresetKeys.longBreakAfterCycles],
      fallback: 4,
    ).clamp(2, 12);
    _pausedAt = null;
    _pausedFor = Duration.zero;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused || _busy) return;
      if (_mode != 'stopwatch' && _remaining <= Duration.zero) {
        unawaited(_finish());
        return;
      }
      setState(() {});
    });
  }

  String get _focusTitle {
    final entityId = _session?.entityId;
    if (entityId != null) {
      for (final entity in widget.controller.entities) {
        if (entity.id == entityId) return entity.title;
      }
      return 'Recovered task session';
    }
    return widget.entity?.title ?? 'Unattached session';
  }

  String get _breakPolicySummary => switch (_breakPolicy) {
    'after_session' => '$_shortBreakMinutes min after this session',
    'pomodoro_cycle' =>
      '$_shortBreakMinutes min short · $_longBreakMinutes min after '
          '$_longBreakAfterCycles sessions',
    _ => 'No planned break',
  };
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = value.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
