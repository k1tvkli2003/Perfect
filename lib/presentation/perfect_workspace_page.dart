import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:perfect/ai/perfect_ai_client.dart';
import 'package:perfect/ai/perfect_ai_dock.dart';
import 'package:perfect/ai/perfect_voice_recorder.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_formula.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_recovery_engine.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/focus_session_sheet.dart';
import 'package:perfect/presentation/orbit_stage.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_today_widget_settings_sheet.dart';
import 'package:perfect/presentation/perfect_sync_indicator.dart';
import 'package:perfect/presentation/planner_conflict_center_sheet.dart';
import 'package:perfect/presentation/planner_archive_sheet.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/planner_editor.dart';
import 'package:perfect/presentation/planner_habit_log_sheet.dart';
import 'package:perfect/presentation/planner_insights_sheet.dart';
import 'package:perfect/presentation/planner_reminder_settings_sheet.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

/// Typed navigation bridge for native surfaces such as the Android Today
/// widget. Requests are retained until a mounted workspace consumes them, so
/// cold-start and already-running clicks share one safe path.
class PerfectWorkspaceNavigationController extends ChangeNotifier {
  int _requestSerial = 0;
  _PerfectWorkspaceNavigationRequest? _latestRequest;

  void showToday() {
    _latestRequest = const _PerfectWorkspaceNavigationRequest.today();
    _requestSerial++;
    notifyListeners();
  }

  void showEntity(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) return;
    _latestRequest = _PerfectWorkspaceNavigationRequest.entity(normalized);
    _requestSerial++;
    notifyListeners();
  }
}

class _PerfectWorkspaceNavigationRequest {
  const _PerfectWorkspaceNavigationRequest.today() : entityId = null;

  const _PerfectWorkspaceNavigationRequest.entity(this.entityId);

  final String? entityId;
}

class PerfectWorkspacePage extends StatefulWidget {
  const PerfectWorkspacePage({
    super.key,
    required this.controller,
    required this.onSignOut,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.now = DateTime.now,
    this.navigationController,
    this.aiClient,
    this.aiVoiceRecorder,
    this.feedbackController,
  });

  final PlannerWorkspaceController controller;
  final Future<void> Function() onSignOut;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DateTime Function() now;
  final PerfectWorkspaceNavigationController? navigationController;
  final PerfectAiClient? aiClient;
  final PerfectVoiceRecorder? aiVoiceRecorder;
  final ReadyFeedbackController? feedbackController;

  @override
  State<PerfectWorkspacePage> createState() => _PerfectWorkspacePageState();
}

class _PerfectWorkspacePageState extends State<PerfectWorkspacePage> {
  _PerfectDestination _destination = _PerfectDestination.today;
  PlannerEntity? _inspected;
  final FocusNode _workspaceFocusNode = FocusNode(
    debugLabel: 'Perfect workspace shortcuts',
  );
  final FocusNode _quickCaptureFocusNode = FocusNode(
    debugLabel: 'Perfect quick capture',
  );
  final TextEditingController _quickCaptureController = TextEditingController();
  final GlobalKey<_QuickCaptureDockState> _quickCaptureDockKey =
      GlobalKey<_QuickCaptureDockState>();
  _WorkspaceLayoutTier? _lastLayoutTier;
  bool _editorSurfaceOpen = false;
  bool _focusSurfaceOpen = false;
  bool _tabletNavigationExtended = false;
  bool _desktopNavigationExtended = true;
  bool _navigationConsumptionScheduled = false;
  int _handledNavigationRequestSerial = 0;
  String? _requestedTodayProjection;
  String? _resolvedTodayProjection;
  List<PlannerEntity> _projectedTodayItems = const <PlannerEntity>[];
  Map<String, PlannerTodayEligibility> _todayEligibilityById =
      const <String, PlannerTodayEligibility>{};
  Map<String, PlannerHabitDaySummary> _habitDaySummaryById =
      const <String, PlannerHabitDaySummary>{};

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareShortcut);
    widget.navigationController?.addListener(_handleNavigationRequest);
    _consumeNavigationRequest(rebuild: false);
    unawaited(_restoreDesktopNavigationWidth());
  }

  Future<void> _restoreDesktopNavigationWidth() async {
    final saved = await PerfectPreferences.readNavigationRailExtended();
    if (!mounted || saved == null || saved == _desktopNavigationExtended) {
      return;
    }
    setState(() => _desktopNavigationExtended = saved);
  }

  @override
  void didUpdateWidget(covariant PerfectWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _requestedTodayProjection = null;
      _resolvedTodayProjection = null;
      _projectedTodayItems = const <PlannerEntity>[];
      _todayEligibilityById = const <String, PlannerTodayEligibility>{};
      _habitDaySummaryById = const <String, PlannerHabitDaySummary>{};
    }
    if (oldWidget.navigationController == widget.navigationController) return;
    oldWidget.navigationController?.removeListener(_handleNavigationRequest);
    _handledNavigationRequestSerial = 0;
    widget.navigationController?.addListener(_handleNavigationRequest);
    _consumeNavigationRequest(rebuild: false);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareShortcut);
    widget.navigationController?.removeListener(_handleNavigationRequest);
    _workspaceFocusNode.dispose();
    _quickCaptureFocusNode.dispose();
    _quickCaptureController.dispose();
    super.dispose();
  }

  void _handleNavigationRequest() => _consumeNavigationRequest(rebuild: true);

  void _consumeNavigationRequest({required bool rebuild}) {
    final navigation = widget.navigationController;
    final serial = navigation?._requestSerial ?? 0;
    if (serial <= _handledNavigationRequestSerial) return;
    final request = navigation?._latestRequest;
    if (request == null) return;
    final entityId = request.entityId;
    if (entityId != null && !widget.controller.isReady) return;
    _handledNavigationRequestSerial = serial;
    if (entityId != null) {
      if (_findNavigableEntity(entityId) == null) return;
      if (rebuild) {
        _navigateToEntity(entityId, requestSerial: serial);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToEntity(entityId, requestSerial: serial);
        });
      }
      return;
    }
    final needsToday = _destination != _PerfectDestination.today;
    final needsInspectorReset = _inspected != null;
    if (!needsToday && !needsInspectorReset) return;
    if (rebuild) {
      setState(() {
        _destination = _PerfectDestination.today;
        _inspected = null;
      });
      return;
    }
    _destination = _PerfectDestination.today;
    _inspected = null;
  }

  void _schedulePendingNavigationConsumption() {
    final serial = widget.navigationController?._requestSerial ?? 0;
    if (_navigationConsumptionScheduled ||
        serial <= _handledNavigationRequestSerial) {
      return;
    }
    _navigationConsumptionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationConsumptionScheduled = false;
      if (mounted) _consumeNavigationRequest(rebuild: true);
    });
  }

  PlannerEntity? _findNavigableEntity(String entityId) {
    for (final entity in <PlannerEntity>[
      ...widget.controller.tasks,
      ...widget.controller.habits,
    ]) {
      if (entity.id == entityId) return entity;
    }
    return null;
  }

  void _navigateToEntity(String entityId, {required int requestSerial}) {
    if (!mounted ||
        widget.navigationController?._requestSerial != requestSerial) {
      return;
    }
    final entity = _findNavigableEntity(entityId);
    if (entity == null) return;
    final destination = entity.kind == PlannerEntityKind.habit
        ? _PerfectDestination.habits
        : _PerfectDestination.tasks;
    final expanded =
        _lastLayoutTier == _WorkspaceLayoutTier.expanded ||
        (_lastLayoutTier == null && MediaQuery.sizeOf(context).width >= 1280);
    setState(() {
      _destination = destination;
      _inspected = expanded ? entity : null;
    });
    if (expanded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.navigationController?._requestSerial != requestSerial) {
        return;
      }
      final current = _findNavigableEntity(entityId);
      if (current != null) _openEditor(existing: current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspace = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _openEditor,
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            _selectDestination(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            _selectDestination(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            _selectDestination(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            _selectDestination(3),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
            _selectDestination(4),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _focusQuickCapture,
        const SingleActivator(
          LogicalKeyboardKey.keyF,
          control: true,
          shift: true,
        ): _openFocusFromShortcut,
        const SingleActivator(LogicalKeyboardKey.escape): _dismissLocalContext,
      },
      child: Focus(
        focusNode: _workspaceFocusNode,
        autofocus: true,
        child: FocusTraversalGroup(
          key: const ValueKey<String>('workspace-focus-traversal'),
          policy: ReadingOrderTraversalPolicy(),
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              if (!widget.controller.isReady) return const _WorkspaceLoading();
              _schedulePendingNavigationConsumption();
              _ensureTodayProjection();
              return LayoutBuilder(
                builder: (context, constraints) {
                  final shortLandscape =
                      constraints.maxHeight < 520 &&
                      constraints.maxWidth >= 520;
                  final tier = constraints.maxWidth < 640
                      ? _WorkspaceLayoutTier.compact
                      : constraints.maxWidth < 1280
                      ? _WorkspaceLayoutTier.medium
                      : _WorkspaceLayoutTier.expanded;
                  _preserveQuickCaptureFocusAcross(tier);
                  if (shortLandscape && constraints.maxWidth < 1280) {
                    return _medium(context, shortLandscape: true);
                  }
                  return switch (tier) {
                    _WorkspaceLayoutTier.compact => _compact(context),
                    _WorkspaceLayoutTier.medium => _medium(context),
                    _WorkspaceLayoutTier.expanded => _expanded(context),
                  };
                },
              );
            },
          ),
        ),
      ),
    );
    final feedbackController = widget.feedbackController;
    if (feedbackController == null) return workspace;
    return ReadyFeedbackOverlay(
      controller: feedbackController,
      routeName: _destination.label,
      child: workspace,
    );
  }

  Widget _compact(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          _Header(
            compact: true,
            status: widget.controller.syncStatus,
            onSync: widget.controller.refresh,
            onSignOut: widget.onSignOut,
            onShowKeyboardShortcuts: _showKeyboardShortcuts,
          ),
          Expanded(
            child: _pageContent(
              context,
              includeOrbit: _destination == _PerfectDestination.today,
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.aiClient case final client?)
          PerfectAiDock(
            client: client,
            voiceRecorder: widget.aiVoiceRecorder,
            onProposalApplied: widget.controller.refresh,
          ),
        _QuickCaptureDock(
          key: _quickCaptureDockKey,
          controller: widget.controller,
          onOpenEditor: () => _openEditor(),
          captureController: _quickCaptureController,
          focusNode: _quickCaptureFocusNode,
        ),
        NavigationBar(
          selectedIndex: _destination.index,
          onDestinationSelected: _selectDestination,
          destinations: _destinations
              .map(
                (destination) => NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
              )
              .toList(growable: false),
        ),
      ],
    ),
  );

  Widget _medium(BuildContext context, {bool shortLandscape = false}) =>
      Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              if (shortLandscape)
                SingleChildScrollView(
                  child: SizedBox(
                    height: 500,
                    child: _NavigationRail(
                      selected: _destination,
                      onSelect: _selectDestination,
                      extended: _tabletNavigationExtended,
                      onToggleExtended: _toggleTabletNavigationWidth,
                    ),
                  ),
                )
              else
                _NavigationRail(
                  selected: _destination,
                  onSelect: _selectDestination,
                  extended: _tabletNavigationExtended,
                  onToggleExtended: _toggleTabletNavigationWidth,
                ),
              Expanded(
                child: Column(
                  children: [
                    _Header(
                      compact: shortLandscape,
                      // The navigation rail already owns the product identity
                      // in both compact and extended states. Keep the header
                      // contextual instead of repeating the brand.
                      showWordmark: false,
                      status: widget.controller.syncStatus,
                      onSync: widget.controller.refresh,
                      onSignOut: widget.onSignOut,
                      onShowKeyboardShortcuts: _showKeyboardShortcuts,
                    ),
                    Expanded(
                      child: _destination == _PerfectDestination.today
                          ? _MediumTodayDeck(
                              controller: widget.controller,
                              now: widget.now().toLocal(),
                              items: _todayItems,
                              eligibilityById: _displayTodayEligibility,
                              habitSummaryById: _displayHabitSummaries,
                              onInspect: _inspect,
                              onAdd: _openEditor,
                              onOpenPlan: () => _selectDestination(
                                _PerfectDestination.plan.index,
                              ),
                              shortLandscape: shortLandscape,
                            )
                          : _pageContent(context, includeOrbit: false),
                    ),
                    if (widget.aiClient case final client?)
                      PerfectAiDock(
                        client: client,
                        voiceRecorder: widget.aiVoiceRecorder,
                        onProposalApplied: widget.controller.refresh,
                        desktop: true,
                      ),
                    _QuickCaptureDock(
                      key: _quickCaptureDockKey,
                      controller: widget.controller,
                      onOpenEditor: () => _openEditor(),
                      captureController: _quickCaptureController,
                      focusNode: _quickCaptureFocusNode,
                      desktop: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _expanded(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Row(
        children: [
          _NavigationRail(
            selected: _destination,
            onSelect: _selectDestination,
            extended: _desktopNavigationExtended,
            onToggleExtended: _toggleDesktopNavigationWidth,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(16) / 16;
                final inspectorWidth = (constraints.maxWidth * .29)
                    .clamp(300.0, 420.0)
                    .toDouble();
                final showAdjacentInspector =
                    _destination != _PerfectDestination.today &&
                    _inspected != null &&
                    constraints.maxWidth - inspectorWidth >= 680 &&
                    textScale < 1.5;

                return Column(
                  children: [
                    _Header(
                      showWordmark: _destination != _PerfectDestination.today,
                      status: widget.controller.syncStatus,
                      onSync: widget.controller.refresh,
                      onSignOut: widget.onSignOut,
                      onShowKeyboardShortcuts: _showKeyboardShortcuts,
                    ),
                    Expanded(
                      child: _destination == _PerfectDestination.today
                          ? _ExpandedTodayDeck(
                              controller: widget.controller,
                              now: widget.now().toLocal(),
                              items: _todayItems,
                              eligibilityById: _displayTodayEligibility,
                              habitSummaryById: _displayHabitSummaries,
                              inspected: _inspected,
                              onInspect: _inspect,
                              onAdd: _openEditor,
                              onOpenPlan: () => _selectDestination(
                                _PerfectDestination.plan.index,
                              ),
                              onEditInspected: () =>
                                  _openEditor(existing: _inspected),
                              onClearInspection: () =>
                                  setState(() => _inspected = null),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _pageContent(
                                    context,
                                    includeOrbit: false,
                                  ),
                                ),
                                if (showAdjacentInspector)
                                  SizedBox(
                                    width: inspectorWidth,
                                    child: _Inspector(
                                      entity: _inspected,
                                      controller: widget.controller,
                                      onEdit: () =>
                                          _openEditor(existing: _inspected),
                                      onReveal: _inspect,
                                      onClear: () =>
                                          setState(() => _inspected = null),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    if (widget.aiClient case final client?)
                      PerfectAiDock(
                        client: client,
                        voiceRecorder: widget.aiVoiceRecorder,
                        onProposalApplied: widget.controller.refresh,
                        desktop: true,
                      ),
                    _QuickCaptureDock(
                      key: _quickCaptureDockKey,
                      controller: widget.controller,
                      onOpenEditor: () => _openEditor(),
                      captureController: _quickCaptureController,
                      focusNode: _quickCaptureFocusNode,
                      desktop: true,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _pageContent(BuildContext context, {required bool includeOrbit}) =>
      switch (_destination) {
        _PerfectDestination.today => _TodayPage(
          controller: widget.controller,
          includeOrbit: includeOrbit,
          now: widget.now().toLocal(),
          items: _todayItems,
          eligibilityById: _displayTodayEligibility,
          habitSummaryById: _displayHabitSummaries,
          onInspect: _inspect,
          onAdd: _openEditor,
          onOpenPlan: () => _selectDestination(_PerfectDestination.plan.index),
        ),
        _PerfectDestination.tasks => _TasksPage(
          controller: widget.controller,
          onInspect: _inspect,
          onAdd: _openEditor,
        ),
        _PerfectDestination.plan => _PlanPage(
          controller: widget.controller,
          now: widget.now().toLocal(),
          onInspect: _inspect,
          onAdd: _openEditor,
        ),
        _PerfectDestination.habits => _HabitsPage(
          controller: widget.controller,
          summaries: _displayHabitSummaries,
          onInspect: _inspect,
          onAdd: () => _openEditor(initialKind: PlannerEntityKind.habit),
        ),
        _PerfectDestination.more => _MorePage(
          controller: widget.controller,
          feedbackController: widget.feedbackController,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onSignOut: widget.onSignOut,
          onAddProject: () =>
              _openEditor(initialKind: PlannerEntityKind.project),
          onAddArea: () => _openEditor(initialKind: PlannerEntityKind.area),
        ),
      };

  List<PlannerEntity> get _todayItems {
    final now = widget.now().toLocal();
    if (_resolvedTodayProjection == _todayProjectionSignature(now)) {
      return _projectedTodayItems;
    }
    return _todayItemsFor(widget.controller, now: now);
  }

  Map<String, PlannerTodayEligibility> get _displayTodayEligibility {
    final now = widget.now().toLocal();
    if (_resolvedTodayProjection == _todayProjectionSignature(now)) {
      return _todayEligibilityById;
    }
    return const <String, PlannerTodayEligibility>{};
  }

  Map<String, PlannerHabitDaySummary> get _displayHabitSummaries {
    final now = widget.now().toLocal();
    if (_resolvedTodayProjection == _todayProjectionSignature(now)) {
      return _habitDaySummaryById;
    }
    return const <String, PlannerHabitDaySummary>{};
  }

  String _todayProjectionSignature(DateTime now) {
    final day = '${now.year}-${now.month}-${now.day}';
    final entities = <PlannerEntity>[
      ...widget.controller.tasks,
      ...widget.controller.habits,
    ];
    final revisions = entities
        .map(
          (entity) =>
              '${entity.id}:${entity.updatedAt.microsecondsSinceEpoch}:${entity.revision}',
        )
        .join('|');
    return '${identityHashCode(widget.controller)}:'
        '${widget.controller.todayProjectionRevision}:$day:$revisions';
  }

  void _ensureTodayProjection() {
    final now = widget.now().toLocal();
    final signature = _todayProjectionSignature(now);
    if (_requestedTodayProjection == signature) return;
    _requestedTodayProjection = signature;
    final entities = <PlannerEntity>[
      ...widget.controller.tasks,
      ...widget.controller.habits,
    ];
    unawaited(
      _resolveTodayProjection(
        signature: signature,
        entities: entities,
        day: now,
      ),
    );
  }

  Future<void> _resolveTodayProjection({
    required String signature,
    required List<PlannerEntity> entities,
    required DateTime day,
  }) async {
    try {
      final results = await Future.wait(
        entities.map((entity) async {
          final eligibility = await widget.controller.todayEligibilityForDay(
            entity,
            localDay: day,
          );
          PlannerHabitDaySummary? summary;
          if (entity.kind == PlannerEntityKind.habit) {
            try {
              summary = await widget.controller.habitDaySummary(
                entity,
                localDay: day,
              );
            } on Object {
              // Eligibility remains useful if one optional habit summary
              // cannot be read; the log sheet offers an explicit retry.
            }
          }
          return (entity, eligibility, summary);
        }),
      );
      if (!mounted || _requestedTodayProjection != signature) return;
      final eligible = <PlannerEntity>[];
      final byId = <String, PlannerTodayEligibility>{};
      final habitSummaries = <String, PlannerHabitDaySummary>{};
      for (final (entity, result, summary) in results) {
        byId[entity.id] = result;
        if (summary != null) habitSummaries[entity.id] = summary;
        if (result.isEligible) eligible.add(entity);
      }
      _sortAgenda(eligible);
      setState(() {
        _resolvedTodayProjection = signature;
        _projectedTodayItems = eligible;
        _todayEligibilityById = byId;
        _habitDaySummaryById = habitSummaries;
      });
    } on Object {
      if (!mounted || _requestedTodayProjection != signature) return;
      final fallback = _todayItemsFor(widget.controller, now: day);
      setState(() {
        _resolvedTodayProjection = signature;
        _projectedTodayItems = fallback;
        _todayEligibilityById = const <String, PlannerTodayEligibility>{};
        _habitDaySummaryById = const <String, PlannerHabitDaySummary>{};
      });
    }
  }

  void _selectDestination(int value) {
    final next = _PerfectDestination.values[value];
    if (next == _destination) return;
    setState(() {
      _destination = next;
      _inspected = null;
    });
  }

  void _focusQuickCapture() {
    if (_quickCaptureFocusNode.context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _quickCaptureFocusNode.requestFocus();
      });
      return;
    }
    _quickCaptureFocusNode.requestFocus();
  }

  void _preserveQuickCaptureFocusAcross(_WorkspaceLayoutTier nextTier) {
    final previousTier = _lastLayoutTier;
    _lastLayoutTier = nextTier;
    if (previousTier == null ||
        previousTier == nextTier ||
        !_quickCaptureFocusNode.hasFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _quickCaptureFocusNode.requestFocus();
    });
  }

  void _toggleTabletNavigationWidth() {
    setState(() => _tabletNavigationExtended = !_tabletNavigationExtended);
  }

  void _toggleDesktopNavigationWidth() {
    final next = !_desktopNavigationExtended;
    setState(() => _desktopNavigationExtended = next);
    unawaited(PerfectPreferences.saveNavigationRailExtended(next));
  }

  void _dismissLocalContext() {
    if (_inspected != null) {
      setState(() => _inspected = null);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _openFocusFromShortcut() {
    if (_focusSurfaceOpen) return;
    _focusSurfaceOpen = true;
    final inspected = _inspected;
    final focusEntity = inspected != null && _canFocusEntity(inspected)
        ? inspected
        : null;
    unawaited(
      FocusSessionSheet.show(
        context,
        controller: widget.controller,
        entity: focusEntity,
      ).whenComplete(() => _focusSurfaceOpen = false),
    );
  }

  bool _handleHardwareShortcut(KeyEvent event) {
    if (!mounted ||
        _editorSurfaceOpen ||
        _focusSurfaceOpen ||
        event is! KeyDownEvent) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.keyF &&
        keyboard.isControlPressed &&
        keyboard.isShiftPressed) {
      _openFocusFromShortcut();
      return true;
    }
    return false;
  }

  void _showKeyboardShortcuts() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(PerfectSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            child: const _KeyboardShortcutsDialog(),
          ),
        ),
      ),
    );
  }

  void _inspect(PlannerEntity entity) {
    final expanded =
        _lastLayoutTier == _WorkspaceLayoutTier.expanded ||
        (_lastLayoutTier == null && MediaQuery.sizeOf(context).width >= 1280);
    if (!expanded) {
      _openEditor(existing: entity);
      return;
    }
    setState(() => _inspected = entity);
  }

  void _openEditor({
    PlannerEntity? existing,
    PlannerEntityKind initialKind = PlannerEntityKind.oneOffTask,
  }) {
    if (_editorSurfaceOpen) return;
    _editorSurfaceOpen = true;
    final previousFocus = FocusManager.instance.primaryFocus;
    unawaited(
      PlannerEditor.show(
        context,
        controller: widget.controller,
        existing: existing,
        initialKind: initialKind,
      ).whenComplete(() {
        if (!mounted) return;
        _editorSurfaceOpen = false;
        if (previousFocus?.canRequestFocus == true) {
          previousFocus!.requestFocus();
        } else {
          _workspaceFocusNode.requestFocus();
        }
      }),
    );
  }
}

enum _PerfectDestination {
  today('Today', Icons.today_outlined, Icons.today_rounded),
  tasks('Tasks', Icons.check_circle_outline, Icons.check_circle_rounded),
  plan('Plan', Icons.schedule_outlined, Icons.schedule_rounded),
  habits('Habits', Icons.eco_outlined, Icons.eco_rounded),
  more('More', Icons.menu_rounded, Icons.menu_rounded);

  const _PerfectDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = _PerfectDestination.values;

enum _WorkspaceLayoutTier { compact, medium, expanded }

class _WorkspaceLoading extends StatelessWidget {
  const _WorkspaceLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PerfectMark(size: 64),
          const SizedBox(height: PerfectSpace.lg),
          Text(
            'Opening your local space…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PerfectSpace.sm),
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    ),
  );
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.selected,
    required this.onSelect,
    required this.extended,
    required this.onToggleExtended,
  });

  final _PerfectDestination selected;
  final ValueChanged<int> onSelect;
  final bool extended;
  final VoidCallback onToggleExtended;

  @override
  Widget build(BuildContext context) {
    final duration = PerfectMotion.responsive(context, PerfectMotion.standard);
    final availableWidth = MediaQuery.sizeOf(context).width;
    final expandedWidth =
        (availableWidth * (availableWidth < 1280 ? .22 : .155)).clamp(
          176.0,
          224.0,
        );
    return ClipRect(
      child: AnimatedContainer(
        key: const ValueKey<String>('perfect-navigation-rail-layout'),
        duration: duration,
        curve: PerfectMotion.productive,
        width: extended ? expandedWidth : 78,
        child: NavigationRail(
          extended: extended,
          minExtendedWidth: expandedWidth,
          minWidth: 78,
          selectedIndex: selected.index,
          onDestinationSelected: onSelect,
          leading: Padding(
            padding: const EdgeInsets.only(top: PerfectSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  child: extended
                      ? const SizedBox(
                          key: ValueKey<String>('rail-wordmark'),
                          width: 174,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: PerfectWordmark(
                              fontSize: 26,
                              includeMark: true,
                            ),
                          ),
                        )
                      : const PerfectMark(
                          key: ValueKey<String>('rail-mark'),
                          size: 44,
                        ),
                ),
                const SizedBox(height: PerfectSpace.xs),
                Semantics(
                  button: true,
                  label: extended
                      ? 'Collapse navigation rail'
                      : 'Expand navigation rail',
                  child: IconButton(
                    key: const ValueKey<String>(
                      'perfect-navigation-rail-toggle',
                    ),
                    tooltip: extended
                        ? 'Collapse navigation'
                        : 'Expand navigation',
                    onPressed: onToggleExtended,
                    icon: Icon(
                      extended
                          ? Icons.keyboard_double_arrow_left_rounded
                          : Icons.keyboard_double_arrow_right_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          destinations: _destinations.indexed
              .map(
                (entry) => NavigationRailDestination(
                  icon: Tooltip(
                    message: '${entry.$2.label} (Ctrl+${entry.$1 + 1})',
                    child: Icon(entry.$2.icon),
                  ),
                  selectedIcon: Tooltip(
                    message: '${entry.$2.label} (Ctrl+${entry.$1 + 1})',
                    child: Icon(entry.$2.selectedIcon),
                  ),
                  label: Text(entry.$2.label),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.status,
    required this.onSync,
    required this.onSignOut,
    required this.onShowKeyboardShortcuts,
    this.compact = false,
    this.showWordmark = true,
  });

  final PlannerSyncStatus status;
  final Future<void> Function() onSync;
  final Future<void> Function() onSignOut;
  final VoidCallback onShowKeyboardShortcuts;
  final bool compact;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      compact ? PerfectSpace.md : PerfectSpace.xl,
      PerfectSpace.md,
      compact ? PerfectSpace.md : PerfectSpace.xl,
      PerfectSpace.sm,
    ),
    child: Row(
      children: [
        if (showWordmark) ...[
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: PerfectWordmark(
                  fontSize: compact ? 24 : 30,
                  includeMark: !compact,
                ),
              ),
            ),
          ),
          const SizedBox(width: PerfectSpace.xs),
        ] else
          const Spacer(),
        PerfectSyncIndicator(status: status, onRetry: onSync, compact: compact),
        const SizedBox(width: PerfectSpace.xs),
        PopupMenuButton<String>(
          tooltip: 'Account and commands',
          onSelected: (value) {
            if (value == 'shortcuts') onShowKeyboardShortcuts();
            if (value == 'sign_out') onSignOut();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'shortcuts',
              child: _ContextMenuLabel(
                icon: Icons.keyboard_alt_outlined,
                label: 'Keyboard shortcuts',
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'sign_out',
              child: _ContextMenuLabel(
                icon: Icons.logout_rounded,
                label: 'Sign out',
              ),
            ),
          ],
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    ),
  );
}

class _KeyboardShortcutsDialog extends StatelessWidget {
  const _KeyboardShortcutsDialog();

  static const _shortcuts = <(String, String)>[
    ('New task', 'Ctrl + N'),
    ('Today', 'Ctrl + 1'),
    ('Tasks', 'Ctrl + 2'),
    ('Plan', 'Ctrl + 3'),
    ('Habits', 'Ctrl + 4'),
    ('More', 'Ctrl + 5'),
    ('Quick capture', 'Ctrl + K'),
    ('Open focus', 'Ctrl + Shift + F'),
    ('Close local context', 'Esc'),
    ('Item actions', 'Menu or Shift + F10'),
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    namesRoute: true,
    label: 'Keyboard shortcuts',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        PerfectSpace.xl,
        PerfectSpace.lg,
        PerfectSpace.lg,
        PerfectSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Keyboard shortcuts',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Close shortcuts',
                onPressed: Navigator.of(context).pop,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: PerfectSpace.xs),
          Text(
            'Everything important stays reachable without leaving the keyboard.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PerfectSpace.lg),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final (index, shortcut) in _shortcuts.indexed) ...[
                    Semantics(
                      label: '${shortcut.$1}, ${shortcut.$2}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: PerfectSpace.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                shortcut.$1,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: PerfectSpace.md),
                            _ShortcutKeyLabel(shortcut.$2),
                          ],
                        ),
                      ),
                    ),
                    if (index < _shortcuts.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShortcutKeyLabel extends StatelessWidget {
  const _ShortcutKeyLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PerfectSpace.sm,
        vertical: PerfectSpace.xs,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _QuickCaptureDock extends StatefulWidget {
  const _QuickCaptureDock({
    super.key,
    required this.controller,
    required this.onOpenEditor,
    required this.captureController,
    required this.focusNode,
    this.desktop = false,
  });

  final PlannerWorkspaceController controller;
  final VoidCallback onOpenEditor;
  final TextEditingController captureController;
  final FocusNode focusNode;
  final bool desktop;

  @override
  State<_QuickCaptureDock> createState() => _QuickCaptureDockState();
}

class _QuickCaptureDockState extends State<_QuickCaptureDock> {
  bool _sending = false;

  TextEditingController get _capture => widget.captureController;

  @override
  Widget build(BuildContext context) {
    final bodySize =
        DefaultTextStyle.of(context).style.fontSize ??
        Theme.of(context).textTheme.bodyLarge?.fontSize ??
        16;
    final effectiveTextScale =
        MediaQuery.textScalerOf(context).scale(bodySize) / bodySize;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.desktop ? PerfectSpace.xl : PerfectSpace.md,
          PerfectSpace.xs,
          widget.desktop ? PerfectSpace.xl : PerfectSpace.md,
          PerfectSpace.xs,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showPlanShortcut =
                widget.desktop ||
                (constraints.maxWidth >= 350 && effectiveTextScale < 1.35);
            final hintText = widget.desktop
                ? 'Capture a task, before it disappears…'
                : effectiveTextScale >= 1.35
                ? 'New task…'
                : 'Capture a task…';
            return DecoratedBox(
              key: const ValueKey<String>('perfect-quick-capture-surface'),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .07),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: PerfectSpace.xs,
                    ),
                    child: IconButton.filled(
                      tooltip: widget.desktop
                          ? 'New task in full editor (Ctrl+N)'
                          : 'Open full editor',
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(48),
                        backgroundColor: PerfectColors.apricotSoft,
                        foregroundColor: PerfectColors.ink,
                      ),
                      onPressed: widget.onOpenEditor,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                  Expanded(
                    child: Tooltip(
                      message: widget.desktop
                          ? 'Quick capture (Ctrl+K)'
                          : 'Quick capture',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: TextField(
                          key: const ValueKey<String>('perfect_quick_capture'),
                          controller: _capture,
                          focusNode: widget.focusNode,
                          maxLength: 160,
                          textDirection: _directionForCapture(
                            context,
                            _capture.text,
                          ),
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: hintText,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showPlanShortcut)
                    IconButton(
                      tooltip: 'Plan in the full editor',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      onPressed: widget.onOpenEditor,
                      icon: const Icon(Icons.calendar_month_outlined),
                    ),
                  IconButton(
                    tooltip: 'Save quick capture',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: _sending || _capture.text.trim().isEmpty
                        ? null
                        : _submit,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _capture.text.trim();
    if (title.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.controller.quickCapture(title);
      _capture.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Captured locally. Sync will follow.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

/// The expanded Windows surface is a single working instrument rather than a
/// row of fixed sidebars. The Compass and Stream keep a continuous visual axis;
/// item detail joins that instrument only when requested and only as a third
/// pane when the live constraints can sustain it.
class _ExpandedTodayDeck extends StatelessWidget {
  const _ExpandedTodayDeck({
    required this.controller,
    required this.now,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.inspected,
    required this.onInspect,
    required this.onAdd,
    required this.onOpenPlan,
    required this.onEditInspected,
    required this.onClearInspection,
  });

  final PlannerWorkspaceController controller;
  final DateTime now;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final PlannerEntity? inspected;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;
  final VoidCallback onOpenPlan;
  final VoidCallback onEditInspected;
  final VoidCallback onClearInspection;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final horizontalPadding = constraints.maxWidth >= 1500
          ? PerfectSpace.xxl
          : PerfectSpace.xl;
      final contentWidth = math.max(
        0,
        constraints.maxWidth - horizontalPadding * 2,
      );
      final sideBySide = contentWidth >= 820 && textScale < 1.5;
      final inlineInspector =
          inspected != null && contentWidth >= 1320 && textScale < 1.35;
      final lowHeight = constraints.maxHeight < 650;
      final stageHeight = lowHeight
          // Preserve the Compass as a real instrument in short windows. The
          // enclosing day scroll owns the overflow instead of shrinking the
          // orbit into an undersized decorative summary.
          ? 500.0
          : (constraints.maxHeight - 96).clamp(500.0, 820.0).toDouble();
      final compassWidth = inlineInspector
          ? 0.0
          : (contentWidth * .4).clamp(340.0, 520.0).toDouble();
      final floatingInspectorWidth = (contentWidth * .3)
          .clamp(320.0, 380.0)
          .toDouble();

      Widget inspectorPanel() => _Inspector(
        key: ValueKey<String>('expanded-inspector-${inspected?.id}'),
        entity: inspected,
        controller: controller,
        onEdit: onEditInspected,
        onReveal: onInspect,
        onClear: onClearInspection,
        embedded: true,
      );

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          key: const PageStorageKey<String>('perfect-expanded-today-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                PerfectSpace.xs,
                horizontalPadding,
                PerfectSpace.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  key: const ValueKey<String>('expanded-day-deck'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DayDeckHeading(
                      now: now,
                      items: items,
                      habitSummaryById: habitSummaryById,
                    ),
                    const SizedBox(height: PerfectSpace.lg),
                    if (sideBySide)
                      SizedBox(
                        key: const ValueKey<String>('expanded-day-deck-stage'),
                        height: stageHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (inlineInspector)
                                  Expanded(
                                    flex: 10,
                                    child: _DayCompassPanel(
                                      items: items,
                                      onOpenPlan: onOpenPlan,
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: compassWidth,
                                    child: _DayCompassPanel(
                                      items: items,
                                      onOpenPlan: onOpenPlan,
                                    ),
                                  ),
                                const SizedBox(width: PerfectSpace.lg),
                                Expanded(
                                  flex: inlineInspector ? 12 : 1,
                                  child: _DayStreamPanel(
                                    controller: controller,
                                    items: items,
                                    eligibilityById: eligibilityById,
                                    habitSummaryById: habitSummaryById,
                                    onInspect: onInspect,
                                    onAdd: onAdd,
                                    constrained: true,
                                    dense: lowHeight,
                                  ),
                                ),
                                if (inlineInspector) ...[
                                  const SizedBox(width: PerfectSpace.lg),
                                  Expanded(flex: 8, child: inspectorPanel()),
                                ],
                              ],
                            ),
                            if (inspected != null && !inlineInspector)
                              PositionedDirectional(
                                key: const ValueKey<String>(
                                  'expanded-focus-panel',
                                ),
                                top: 0,
                                end: 0,
                                bottom: 0,
                                width: floatingInspectorWidth,
                                child: inspectorPanel(),
                              ),
                          ],
                        ),
                      )
                    else
                      Column(
                        key: const ValueKey<String>(
                          'expanded-day-deck-stacked',
                        ),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: (contentWidth * .52)
                                .clamp(460.0, 640.0)
                                .toDouble(),
                            child: _DayCompassPanel(
                              items: items,
                              onOpenPlan: onOpenPlan,
                            ),
                          ),
                          const SizedBox(height: PerfectSpace.lg),
                          _DayStreamPanel(
                            controller: controller,
                            items: items,
                            eligibilityById: eligibilityById,
                            habitSummaryById: habitSummaryById,
                            onInspect: onInspect,
                            onAdd: onAdd,
                            constrained: false,
                            dense: false,
                          ),
                          if (inspected != null) ...[
                            const SizedBox(height: PerfectSpace.lg),
                            SizedBox(
                              height: (constraints.maxHeight * .76)
                                  .clamp(480.0, 640.0)
                                  .toDouble(),
                              child: inspectorPanel(),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// The medium-width Today composition is intentionally its own surface.
///
/// A tablet is not a stretched phone and it is not a desktop with two narrow
/// fragments pinned to opposite corners. This deck uses the live viewport to
/// create one coherent stage: a meaningful Day Compass and an operational Day
/// Stream. At constrained widths or large text scales the same content reflows
/// into one reading column without changing its state or interaction model.
class _MediumTodayDeck extends StatelessWidget {
  const _MediumTodayDeck({
    required this.controller,
    required this.now,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.onInspect,
    required this.onAdd,
    required this.onOpenPlan,
    required this.shortLandscape,
  });

  final PlannerWorkspaceController controller;
  final DateTime now;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;
  final VoidCallback onOpenPlan;
  final bool shortLandscape;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 760
            ? PerfectSpace.md
            : PerfectSpace.xl;
        final contentWidth = math.max(
          0,
          constraints.maxWidth - horizontalPadding * 2,
        );
        // The content itself decides when two panes remain genuinely useful.
        // A 768dp tablet gets one generous reading column; at 900dp the
        // compact and expanded rail states can both sustain the two-pane
        // instrument + stream relationship.
        final sideBySide =
            constraints.maxWidth >= 700 &&
            contentWidth >= 620 &&
            textScale < 1.45;
        final lowHeight = constraints.maxHeight < 720;
        final stageHeight = shortLandscape
            ? (constraints.maxHeight * .94).clamp(300.0, 430.0)
            : lowHeight
            ? (constraints.maxHeight - 112).clamp(420.0, 620.0)
            : (constraints.maxHeight - 72).clamp(560.0, 850.0);
        final compassWidth = sideBySide
            ? (contentWidth * .45).clamp(292.0, 410.0).toDouble()
            : contentWidth.toDouble();

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            key: const PageStorageKey<String>('perfect-medium-today-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  PerfectSpace.xs,
                  horizontalPadding,
                  shortLandscape ? PerfectSpace.md : PerfectSpace.xxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DayDeckHeading(
                        now: now,
                        items: items,
                        habitSummaryById: habitSummaryById,
                      ),
                      const SizedBox(height: PerfectSpace.lg),
                      if (sideBySide)
                        SizedBox(
                          key: const ValueKey<String>('medium-day-deck'),
                          height: stageHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: compassWidth,
                                child: _DayCompassPanel(
                                  items: items,
                                  onOpenPlan: onOpenPlan,
                                ),
                              ),
                              const SizedBox(width: PerfectSpace.lg),
                              Expanded(
                                child: _DayStreamPanel(
                                  controller: controller,
                                  items: items,
                                  eligibilityById: eligibilityById,
                                  habitSummaryById: habitSummaryById,
                                  onInspect: onInspect,
                                  onAdd: onAdd,
                                  constrained: true,
                                  dense: lowHeight,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          key: const ValueKey<String>('medium-day-deck'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: shortLandscape
                                  ? stageHeight
                                  : (contentWidth * .72).clamp(390.0, 530.0),
                              child: _DayCompassPanel(
                                items: items,
                                onOpenPlan: onOpenPlan,
                              ),
                            ),
                            const SizedBox(height: PerfectSpace.lg),
                            _DayStreamPanel(
                              controller: controller,
                              items: items,
                              eligibilityById: eligibilityById,
                              habitSummaryById: habitSummaryById,
                              onInspect: onInspect,
                              onAdd: onAdd,
                              constrained: false,
                              dense: shortLandscape || lowHeight,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayDeckHeading extends StatelessWidget {
  const _DayDeckHeading({
    required this.now,
    required this.items,
    required this.habitSummaryById,
  });

  final DateTime now;
  final List<PlannerEntity> items;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) {
      if (item.kind == PlannerEntityKind.oneOffTask) {
        return PlannerTaskProgress.fromEntity(item).isComplete;
      }
      return habitSummaryById[item.id]?.state == PlannerHabitDayState.completed;
    }).length;
    final loggedHabits = habitSummaryById.values
        .where((summary) => summary.hasLog)
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final stacked = constraints.maxWidth < 610 || textScale >= 1.45;
        final title = Column(
          key: const ValueKey<String>('day-deck-heading'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(now),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: PerfectSpace.xxs),
            Text(
              _todayLabel(now),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        final metrics = Wrap(
          spacing: PerfectSpace.xs,
          runSpacing: PerfectSpace.xs,
          alignment: WrapAlignment.end,
          children: [
            _DeckMetric(
              icon: Icons.route_rounded,
              value: '${items.length}',
              label: 'planned',
              color: PerfectColors.apricot,
              background: PerfectColors.apricotSoft,
            ),
            _DeckMetric(
              icon: Icons.done_all_rounded,
              value: '$completed',
              label: 'complete',
              color: PerfectColors.mint,
              background: PerfectColors.mintSoft,
            ),
            _DeckMetric(
              icon: Icons.spa_outlined,
              value: '$loggedHabits',
              label: 'habits',
              color: PerfectColors.lilac,
              background: PerfectColors.lilacSoft,
            ),
          ],
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: PerfectSpace.md),
              metrics,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: title),
            const SizedBox(width: PerfectSpace.lg),
            Flexible(child: metrics),
          ],
        );
      },
    );
  }
}

class _DeckMetric extends StatelessWidget {
  const _DeckMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label',
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PerfectSpace.sm,
          vertical: PerfectSpace.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DayCompassPanel extends StatelessWidget {
  const _DayCompassPanel({required this.items, required this.onOpenPlan});

  final List<PlannerEntity> items;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey<String>('day-compass-panel'),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final circularFloor =
              constraints.maxHeight >= 390 && constraints.maxWidth >= 240
              ? 240.0
              : 0.0;
          final orbitHeight = math.min(
            constraints.maxWidth,
            math.max(circularFloor, constraints.maxHeight * .52),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayZoneHeading(
                eyebrow: 'DAY COMPASS',
                title: 'Your rhythm, at a glance',
                icon: Icons.explore_outlined,
                color: PerfectColors.apricot,
                action: IconButton(
                  tooltip: 'Open day plan',
                  onPressed: onOpenPlan,
                  icon: const Icon(Icons.arrow_outward_rounded),
                ),
              ),
              const SizedBox(height: PerfectSpace.sm),
              SizedBox(
                height: orbitHeight,
                child: OrbitStage(
                  items: items,
                  compact: true,
                  onTap: onOpenPlan,
                ),
              ),
              const SizedBox(height: PerfectSpace.sm),
              Expanded(child: _CompassRunway(items: items)),
            ],
          );
        },
      ),
    ),
  );
}

class _CompassRunway extends StatelessWidget {
  const _CompassRunway({required this.items});

  final List<PlannerEntity> items;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) {
      if (item.kind == PlannerEntityKind.oneOffTask) {
        return PlannerTaskProgress.fromEntity(item).isComplete;
      }
      return item.status == PlannerEntityStatus.completed;
    }).length;
    final timed = items.where((item) => item.scheduledAt != null).toList();
    final progress = items.isEmpty ? 0.0 : completed / items.length;
    final firstTime = timed.isEmpty
        ? 'Open'
        : _shortTime(timed.first.scheduledAt!.toLocal());
    final lastTime = timed.length < 2
        ? 'Open'
        : _shortTime(timed.last.scheduledAt!.toLocal());
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 190;
        return DecoratedBox(
          key: const ValueKey<String>('day-compass-runway'),
          decoration: BoxDecoration(
            color: PerfectColors.apricotSoft,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              compact ? PerfectSpace.xs : PerfectSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 18,
                      color: PerfectColors.apricotAction,
                    ),
                    const SizedBox(width: PerfectSpace.xs),
                    Expanded(
                      child: Text(
                        'Today’s runway',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '$completed/${items.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PerfectSpace.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: PerfectColors.apricot,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .72),
                  ),
                ),
                if (compact && constraints.maxHeight >= 100) ...[
                  const SizedBox(height: PerfectSpace.xs),
                  Text(
                    '$firstTime → $lastTime · ${timed.length} timed',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else if (!compact) ...[
                  const SizedBox(height: PerfectSpace.sm),
                  Wrap(
                    spacing: PerfectSpace.xs,
                    runSpacing: PerfectSpace.xs,
                    children: [
                      _RunwayFact(label: 'First', value: firstTime),
                      _RunwayFact(label: 'Last', value: lastTime),
                      _RunwayFact(
                        label: 'Rhythm',
                        value: '${timed.length} timed',
                      ),
                    ],
                  ),
                  const SizedBox(height: PerfectSpace.sm),
                  Expanded(child: _RunwaySchedule(items: items)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RunwaySchedule extends StatelessWidget {
  const _RunwaySchedule({required this.items});

  final List<PlannerEntity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No fixed moments yet',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final visible = items.take(3).toList(growable: false);
    return Column(
      children: [
        for (final entity in visible)
          Expanded(
            child: _RunwayScheduleEntry(
              entity: entity,
              drawTail: entity != visible.last,
            ),
          ),
        if (items.length > visible.length)
          Text(
            '+${items.length - visible.length} more in the Day Stream',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _RunwayScheduleEntry extends StatelessWidget {
  const _RunwayScheduleEntry({required this.entity, required this.drawTail});

  final PlannerEntity entity;
  final bool drawTail;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 18,
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _colorFor(entity),
                shape: BoxShape.circle,
              ),
            ),
            if (drawTail)
              Expanded(
                child: Container(
                  width: 2,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
      const SizedBox(width: PerfectSpace.xs),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PerfectSpace.sm,
            vertical: PerfectSpace.xs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                entity.scheduledAt == null
                    ? 'Flexible'
                    : _shortTime(entity.scheduledAt!.toLocal()),
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _RunwayFact extends StatelessWidget {
  const _RunwayFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: PerfectSpace.sm,
      vertical: 7,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _DayStreamPanel extends StatelessWidget {
  const _DayStreamPanel({
    required this.controller,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.onInspect,
    required this.onAdd,
    required this.constrained,
    required this.dense,
  });

  final PlannerWorkspaceController controller;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;
  final bool constrained;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final body = <Widget>[
      _DayZoneHeading(
        eyebrow: 'DAY STREAM',
        title: 'Today’s flow',
        icon: Icons.view_timeline_outlined,
        color: PerfectColors.mint,
        action: FilledButton.tonalIcon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Plan'),
        ),
      ),
      SizedBox(height: dense ? PerfectSpace.xs : PerfectSpace.md),
      if (items.isEmpty)
        _DayStreamEmpty(onAdd: onAdd)
      else
        _DayStreamTimeline(
          controller: controller,
          items: items,
          eligibilityById: eligibilityById,
          habitSummaryById: habitSummaryById,
          onInspect: onInspect,
        ),
      SizedBox(height: dense ? PerfectSpace.xs : PerfectSpace.md),
      _DayStreamZone(
        key: const ValueKey<String>('day-stream-habit-zone'),
        color: PerfectColors.mintSoft,
        icon: Icons.spa_outlined,
        title: 'Habit pulse',
        dense: dense,
        child: _HabitPulse(controller: controller, summaries: habitSummaryById),
      ),
      SizedBox(height: dense ? PerfectSpace.xs : PerfectSpace.sm),
      _NextUpZone(items: items, dense: dense),
    ];
    return DecoratedBox(
      key: const ValueKey<String>('day-stream-panel'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: constrained
            ? Stack(
                children: [
                  CustomScrollView(
                    key: const PageStorageKey<String>('day-stream-scroll'),
                    slivers: [
                      SliverList.list(children: body),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: dense ? PerfectSpace.xs : PerfectSpace.sm,
                              bottom: dense
                                  ? PerfectSpace.sm
                                  : PerfectSpace.xxs,
                            ),
                            child: _DayCompletionZone(
                              items: items,
                              habitSummaryById: habitSummaryById,
                              dense: dense,
                              fill: !dense,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dense)
                    const PositionedDirectional(
                      end: PerfectSpace.xs,
                      bottom: 0,
                      child: IgnorePointer(child: _StreamContinuationCue()),
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...body,
                  SizedBox(height: dense ? PerfectSpace.xs : PerfectSpace.sm),
                  _DayCompletionZone(
                    items: items,
                    habitSummaryById: habitSummaryById,
                    dense: dense,
                    fill: false,
                  ),
                ],
              ),
      ),
    );
  }
}

class _DayZoneHeading extends StatelessWidget {
  const _DayZoneHeading({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.color,
    this.action,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, size: 21, color: color),
      ),
      const SizedBox(width: PerfectSpace.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: PerfectSpace.xs), action!],
    ],
  );
}

class _StreamContinuationCue extends StatelessWidget {
  const _StreamContinuationCue();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'More day details below',
    child: ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: .1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('More'),
              SizedBox(width: 3),
              Icon(Icons.keyboard_arrow_down_rounded, size: 17),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DayStreamTimeline extends StatelessWidget {
  const _DayStreamTimeline({
    required this.controller,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.onInspect,
  });

  final PlannerWorkspaceController controller;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final ValueChanged<PlannerEntity> onInspect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final showTimeRail = constraints.maxWidth >= 360 && textScale < 1.45;
      return Column(
        children: items
            .map(
              (entity) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTimeRail) ...[
                    SizedBox(
                      width: 58,
                      child: Padding(
                        padding: const EdgeInsets.only(top: PerfectSpace.md),
                        child: Text(
                          entity.scheduledAt == null
                              ? 'Anytime'
                              : _shortTime(entity.scheduledAt!.toLocal()),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: PerfectSpace.xs),
                    SizedBox(
                      width: 14,
                      child: Column(
                        children: [
                          const SizedBox(height: PerfectSpace.lg),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _colorFor(entity),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 54,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: PerfectSpace.xs),
                  ],
                  Expanded(
                    child: _AgendaRow(
                      entity: entity,
                      controller: controller,
                      onInspect: onInspect,
                      todayEligibility: eligibilityById[entity.id],
                      habitSummary: habitSummaryById[entity.id],
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      );
    },
  );
}

class _DayStreamZone extends StatelessWidget {
  const _DayStreamZone({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
    this.dense = false,
  });

  final Color color;
  final IconData icon;
  final String title;
  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(dense ? 18 : 22),
    ),
    child: Padding(
      padding: EdgeInsets.all(dense ? PerfectSpace.sm : PerfectSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: PerfectColors.ink),
              const SizedBox(width: PerfectSpace.xs),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          SizedBox(height: dense ? PerfectSpace.xs : PerfectSpace.sm),
          child,
        ],
      ),
    ),
  );
}

class _NextUpZone extends StatelessWidget {
  const _NextUpZone({required this.items, required this.dense});

  final List<PlannerEntity> items;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final next = items.isEmpty ? null : items.first;
    return _DayStreamZone(
      key: const ValueKey<String>('day-stream-next-zone'),
      color: PerfectColors.lilacSoft,
      icon: Icons.bolt_rounded,
      title: 'Next up',
      dense: dense,
      child: next == null
          ? Text(
              'The runway is clear. Add a moment when you need one.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: PerfectSpace.xxs),
                      Text(
                        next.scheduledAt == null
                            ? 'Ready whenever you are'
                            : 'Starts ${_shortTime(next.scheduledAt!.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!dense) ...[
                  const SizedBox(width: PerfectSpace.sm),
                  const Icon(Icons.arrow_forward_rounded),
                ],
              ],
            ),
    );
  }
}

class _DayCompletionZone extends StatelessWidget {
  const _DayCompletionZone({
    required this.items,
    required this.habitSummaryById,
    required this.dense,
    required this.fill,
  });

  final List<PlannerEntity> items;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final bool dense;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) {
      if (item.kind == PlannerEntityKind.oneOffTask) {
        return PlannerTaskProgress.fromEntity(item).isComplete;
      }
      return habitSummaryById[item.id]?.state == PlannerHabitDayState.completed;
    }).length;
    final progress = items.isEmpty ? 0.0 : completed / items.length;
    final remaining = math.max(0, items.length - completed);
    return DecoratedBox(
      key: const ValueKey<String>('day-stream-signal-zone'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(dense ? 18 : 22),
      ),
      child: Padding(
        padding: EdgeInsets.all(dense ? PerfectSpace.sm : PerfectSpace.md),
        child: Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded, size: 18),
                const SizedBox(width: PerfectSpace.xs),
                Expanded(
                  child: Text(
                    'Day signal',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  items.isEmpty ? 'Clear' : '${(progress * 100).round()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            SizedBox(height: dense ? PerfectSpace.xs : PerfectSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: PerfectColors.mint,
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            if (!dense) ...[
              if (fill) ...[
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _SignalMeasure(
                        value: '$remaining',
                        label: 'open',
                        color: PerfectColors.apricot,
                      ),
                    ),
                    const SizedBox(width: PerfectSpace.sm),
                    Expanded(
                      child: _SignalMeasure(
                        value: '$completed',
                        label: 'complete',
                        color: PerfectColors.mint,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ] else
                const SizedBox(height: PerfectSpace.xs),
              Text(
                items.isEmpty
                    ? 'Nothing is asking for your attention right now.'
                    : remaining == 0
                    ? 'The day is complete. Leave some room to land.'
                    : '$remaining ${remaining == 1 ? 'moment' : 'moments'} still open.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignalMeasure extends StatelessWidget {
  const _SignalMeasure({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.sm),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DayStreamEmpty extends StatelessWidget {
  const _DayStreamEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.lg),
      child: Column(
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            size: 34,
            color: PerfectColors.apricot,
          ),
          const SizedBox(height: PerfectSpace.xs),
          Text(
            'A quiet orbit.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: PerfectSpace.xxs),
          const Text(
            'Capture the first thing you want to make space for.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PerfectSpace.sm),
          FilledButton(onPressed: onAdd, child: const Text('Add a task')),
        ],
      ),
    ),
  );
}

class _TodayPage extends StatelessWidget {
  const _TodayPage({
    required this.controller,
    required this.includeOrbit,
    required this.now,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.onInspect,
    required this.onAdd,
    required this.onOpenPlan,
  });

  final PlannerWorkspaceController controller;
  final bool includeOrbit;
  final DateTime now;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        key: const ValueKey<String>('perfect-today-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          PerfectSpace.lg,
          PerfectSpace.sm,
          PerfectSpace.lg,
          PerfectSpace.giant,
        ),
        children: [
          Text(
            _greeting(now),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: PerfectSpace.xs),
          Text(
            _todayLabel(now),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (includeOrbit) ...[
            const SizedBox(height: PerfectSpace.lg),
            SizedBox(
              height: 360,
              child: OrbitStage(items: items, compact: true, onTap: onOpenPlan),
            ),
          ],
          const SizedBox(height: PerfectSpace.lg),
          _SectionHeader(
            title: 'Today’s flow',
            trailing: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Plan'),
            ),
          ),
          if (items.isEmpty)
            _EmptyState(
              icon: Icons.wb_sunny_outlined,
              title: 'A quiet orbit.',
              body: 'Capture the first thing you want to make space for.',
              actionLabel: 'Add a task',
              onAction: onAdd,
            )
          else
            ...items.map(
              (entity) => _AgendaRow(
                entity: entity,
                controller: controller,
                onInspect: onInspect,
                todayEligibility: eligibilityById[entity.id],
                habitSummary: habitSummaryById[entity.id],
              ),
            ),
          const SizedBox(height: PerfectSpace.xl),
          _SectionHeader(title: 'Habit pulse'),
          _HabitPulse(controller: controller, summaries: habitSummaryById),
        ],
      ),
    );
  }
}

class _TasksPage extends StatefulWidget {
  const _TasksPage({
    required this.controller,
    required this.onInspect,
    required this.onAdd,
  });

  final PlannerWorkspaceController controller;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;

  @override
  State<_TasksPage> createState() => _TasksPageState();
}

enum _TaskFilter { inbox, active, scheduled, completed }

enum _TaskKindFilter { all, oneOff, recurring }

class _TasksPageState extends State<_TasksPage> {
  final _search = TextEditingController();
  _TaskFilter _filter = _TaskFilter.inbox;
  _TaskKindFilter _kindFilter = _TaskKindFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final tasks = widget.controller.tasks
        .where((task) {
          final matchesKind = switch (_kindFilter) {
            _TaskKindFilter.all => true,
            _TaskKindFilter.oneOff => task.kind == PlannerEntityKind.oneOffTask,
            _TaskKindFilter.recurring =>
              task.kind == PlannerEntityKind.recurringTask,
          };
          if (!matchesKind) return false;
          final matchesFilter = switch (_filter) {
            _TaskFilter.inbox =>
              task.status == PlannerEntityStatus.active &&
                  task.scheduledAt == null,
            _TaskFilter.active => task.status == PlannerEntityStatus.active,
            _TaskFilter.scheduled =>
              task.status == PlannerEntityStatus.active &&
                  task.scheduledAt != null,
            _TaskFilter.completed =>
              task.status == PlannerEntityStatus.completed,
          };
          if (!matchesFilter) return false;
          if (query.isEmpty) return true;
          return '${task.title} ${task.note ?? ''} ${task.payload['category'] ?? ''}'
              .toLowerCase()
              .contains(query);
        })
        .toList(growable: false);
    return ListView(
      key: const ValueKey<String>('perfect-tasks-scroll'),
      padding: const EdgeInsets.all(PerfectSpace.lg),
      children: [
        _PageTitle(
          title: 'Tasks',
          subtitle: 'Inbox first. Details only when you need them.',
          onAdd: widget.onAdd,
        ),
        const SizedBox(height: PerfectSpace.md),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          textDirection: _textDirection(_search.text),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
            labelText: 'Search tasks',
          ),
        ),
        const SizedBox(height: PerfectSpace.sm),
        Text('Task type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: PerfectSpace.xs),
        Wrap(
          spacing: PerfectSpace.xs,
          runSpacing: PerfectSpace.xs,
          children: _TaskKindFilter.values
              .map(
                (filter) => ChoiceChip(
                  avatar: Icon(_taskKindFilterIcon(filter), size: 17),
                  label: Text(_taskKindFilterLabel(filter)),
                  selected: _kindFilter == filter,
                  onSelected: (_) => setState(() => _kindFilter = filter),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: PerfectSpace.sm),
        Text('Status', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: PerfectSpace.xs),
        Wrap(
          spacing: PerfectSpace.xs,
          runSpacing: PerfectSpace.xs,
          children: _TaskFilter.values
              .map(
                (filter) => ChoiceChip(
                  label: Text(_taskFilterLabel(filter)),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: PerfectSpace.xs),
        Text(
          '${tasks.length} ${tasks.length == 1 ? 'item' : 'items'} · '
          '${_taskKindFilterLabel(_kindFilter)} · '
          '${_taskFilterLabel(_filter)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: PerfectSpace.md),
        if (tasks.isEmpty)
          _EmptyState(
            icon: _filter == _TaskFilter.completed
                ? Icons.celebration_outlined
                : Icons.inbox_outlined,
            title: _search.text.trim().isEmpty
                ? 'Your ${_taskFilterLabel(_filter).toLowerCase()} is clear.'
                : 'Nothing matches that search.',
            body: _search.text.trim().isEmpty
                ? 'Use quick capture when the next task appears.'
                : 'Try a title, note, or category you used before.',
            actionLabel: 'Create task',
            onAction: widget.onAdd,
          )
        else
          ...tasks.map(
            (entity) => _AgendaRow(
              entity: entity,
              controller: widget.controller,
              onInspect: widget.onInspect,
              showKind: true,
            ),
          ),
      ],
    );
  }
}

String _taskFilterLabel(_TaskFilter filter) => switch (filter) {
  _TaskFilter.inbox => 'Inbox',
  _TaskFilter.active => 'Active',
  _TaskFilter.scheduled => 'Scheduled',
  _TaskFilter.completed => 'Completed',
};

String _taskKindFilterLabel(_TaskKindFilter filter) => switch (filter) {
  _TaskKindFilter.all => 'All',
  _TaskKindFilter.oneOff => 'Single',
  _TaskKindFilter.recurring => 'Recurring',
};

IconData _taskKindFilterIcon(_TaskKindFilter filter) => switch (filter) {
  _TaskKindFilter.all => Icons.view_agenda_outlined,
  _TaskKindFilter.oneOff => Icons.check_circle_outline_rounded,
  _TaskKindFilter.recurring => Icons.repeat_rounded,
};

class _PlanPage extends StatefulWidget {
  const _PlanPage({
    required this.controller,
    required this.now,
    required this.onInspect,
    required this.onAdd,
  });

  final PlannerWorkspaceController controller;
  final DateTime now;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;

  @override
  State<_PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<_PlanPage> {
  late DateTime _selectedDay = _dateOnly(widget.now);
  String? _requestedProjection;
  String? _resolvedProjection;
  List<PlannerEntity> _projectedItems = const <PlannerEntity>[];

  @override
  Widget build(BuildContext context) {
    _ensureProjection();
    final planned = _plannedItems;
    final isToday = _isSameDate(_selectedDay, widget.now);
    return ListView(
      padding: const EdgeInsets.all(PerfectSpace.lg),
      children: [
        _PageTitle(
          title: 'Plan',
          subtitle: 'Move across days without losing unfinished work.',
          onAdd: widget.onAdd,
        ),
        const SizedBox(height: PerfectSpace.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PerfectSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous day',
                      onPressed: () => _moveDay(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDay,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatFullDate(_selectedDay),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next day',
                      onPressed: () => _moveDay(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                if (!isToday)
                  Align(
                    alignment: AlignmentDirectional.center,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _selectedDay = _dateOnly(widget.now)),
                      icon: const Icon(Icons.today_outlined),
                      label: const Text('Back to today'),
                    ),
                  ),
                const SizedBox(height: PerfectSpace.sm),
                Text(
                  'Time blocks · ${planned.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Only timed items appear here. Unscheduled work stays safely in Tasks until you choose a slot.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PerfectSpace.md),
        if (planned.isEmpty)
          _EmptyState(
            icon: Icons.schedule_outlined,
            title: 'No blocks yet.',
            body: 'Assign a time in the editor and it will land here.',
            actionLabel: 'Plan a task',
            onAction: widget.onAdd,
          )
        else
          ...planned.map(
            (entity) => _AgendaRow(
              entity: entity,
              controller: widget.controller,
              onInspect: widget.onInspect,
              showKind: true,
            ),
          ),
      ],
    );
  }

  void _moveDay(int offset) =>
      setState(() => _selectedDay = _selectedDay.add(Duration(days: offset)));

  Future<void> _pickDay() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(widget.now.year - 5),
      lastDate: DateTime(widget.now.year + 30),
    );
    if (selected != null && mounted) {
      setState(() => _selectedDay = _dateOnly(selected));
    }
  }

  List<PlannerEntity> get _plannedItems {
    final signature = _projectionSignature;
    if (_resolvedProjection == signature) return _projectedItems;
    return _plannedItemsFor(widget.controller, now: _selectedDay);
  }

  String get _projectionSignature {
    final day =
        '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}';
    return '${identityHashCode(widget.controller)}:'
        '${widget.controller.todayProjectionRevision}:$day';
  }

  void _ensureProjection() {
    final signature = _projectionSignature;
    if (_requestedProjection == signature) return;
    _requestedProjection = signature;
    unawaited(
      _resolveProjection(
        signature: signature,
        controller: widget.controller,
        day: _selectedDay,
        entities: <PlannerEntity>[
          ...widget.controller.tasks,
          ...widget.controller.habits,
        ],
      ),
    );
  }

  Future<void> _resolveProjection({
    required String signature,
    required PlannerWorkspaceController controller,
    required DateTime day,
    required List<PlannerEntity> entities,
  }) async {
    try {
      final planned = <PlannerEntity>[];
      for (final entity in entities) {
        final scheduled = entity.scheduledAt?.toLocal();
        if (scheduled == null) continue;
        if (entity.kind == PlannerEntityKind.oneOffTask) {
          if (_isSameDate(scheduled, day)) planned.add(entity);
          continue;
        }
        final eligibility = await controller.todayEligibilityForDay(
          entity,
          localDay: day,
        );
        if (eligibility.isEligible) planned.add(entity);
      }
      if (!mounted || _requestedProjection != signature) return;
      _sortAgenda(planned);
      setState(() {
        _resolvedProjection = signature;
        _projectedItems = planned;
      });
    } on Object {
      if (!mounted || _requestedProjection != signature) return;
      setState(() {
        _resolvedProjection = signature;
        _projectedItems = _plannedItemsFor(controller, now: day);
      });
    }
  }
}

class _HabitsPage extends StatelessWidget {
  const _HabitsPage({
    required this.controller,
    required this.summaries,
    required this.onInspect,
    required this.onAdd,
  });

  final PlannerWorkspaceController controller;
  final Map<String, PlannerHabitDaySummary> summaries;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final habits = controller.habits;
    return ListView(
      padding: const EdgeInsets.all(PerfectSpace.lg),
      children: [
        _PageTitle(
          title: 'Habits',
          subtitle:
              'Build consistency without pretending rest days are failures.',
          onAdd: onAdd,
        ),
        const SizedBox(height: PerfectSpace.md),
        if (habits.isEmpty)
          _EmptyState(
            icon: Icons.eco_outlined,
            title: 'Start one gentle habit.',
            body:
                'Choose how it is measured, when it rests, and how misses recover.',
            actionLabel: 'Create habit',
            onAction: onAdd,
          )
        else
          ...habits.map(
            (habit) => _HabitCard(
              habit: habit,
              controller: controller,
              summary: summaries[habit.id],
              onInspect: onInspect,
            ),
          ),
      ],
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.controller,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onSignOut,
    required this.onAddProject,
    required this.onAddArea,
    this.feedbackController,
  });

  final PlannerWorkspaceController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Future<void> Function() onSignOut;
  final VoidCallback onAddProject;
  final VoidCallback onAddArea;
  final ReadyFeedbackController? feedbackController;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(PerfectSpace.lg),
    children: [
      _PageTitle(
        title: 'More',
        subtitle: 'Private controls, not public settings.',
      ),
      const SizedBox(height: PerfectSpace.md),
      if (feedbackController case final feedback?) ...[
        Semantics(
          container: true,
          label: 'Private feedback and diagnostics settings',
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: ReadyFeedbackSettingsTile(controller: feedback),
          ),
        ),
        const SizedBox(height: PerfectSpace.md),
      ],
      Card(
        child: Padding(
          padding: const EdgeInsets.all(PerfectSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: PerfectSpace.xs),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: <ThemeMode>{themeMode},
                onSelectionChanged: (selection) =>
                    onThemeModeChanged(selection.first),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: PerfectSpace.md),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Projects'),
              subtitle: Text('${controller.projects.length} active'),
              trailing: IconButton(
                tooltip: 'Create project',
                onPressed: onAddProject,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            const Divider(indent: PerfectSpace.md, endIndent: PerfectSpace.md),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('Areas'),
              subtitle: Text('${controller.areas.length} active'),
              trailing: IconButton(
                tooltip: 'Create area',
                onPressed: onAddArea,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            const Divider(indent: PerfectSpace.md, endIndent: PerfectSpace.md),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Focus'),
              subtitle: const Text(
                'Pomodoro, countdown, and stopwatch sessions',
              ),
              onTap: () =>
                  FocusSessionSheet.show(context, controller: controller),
            ),
            const Divider(indent: PerfectSpace.md, endIndent: PerfectSpace.md),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Your rhythm'),
              subtitle: const Text(
                'Private insight from your recorded tasks, habits, and focus.',
              ),
              onTap: () =>
                  PlannerInsightsSheet.show(context, controller: controller),
            ),
            const Divider(indent: PerfectSpace.md, endIndent: PerfectSpace.md),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Archive'),
              subtitle: const Text('Restore any planning item you archived.'),
              onTap: () =>
                  PlannerArchiveSheet.show(context, controller: controller),
            ),
            const Divider(indent: PerfectSpace.md, endIndent: PerfectSpace.md),
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: const Text('Reminders & quiet hours'),
              subtitle: const Text(
                'Multiple alerts, device-local delivery, and gentle silence.',
              ),
              onTap: () => PlannerReminderSettingsSheet.show(
                context,
                controller: controller,
              ),
            ),
            if (controller.todayWidgetSettings.isAvailable) ...[
              const Divider(
                indent: PerfectSpace.md,
                endIndent: PerfectSpace.md,
              ),
              ListTile(
                leading: const Icon(Icons.widgets_outlined),
                title: const Text('Perfect Today widget'),
                subtitle: const Text(
                  'Resizable, scrollable, and directly actionable.',
                ),
                onTap: () => PerfectTodayWidgetSettingsSheet.show(
                  context,
                  controller: controller,
                ),
              ),
            ],
            const Divider(indent: PerfectSpace.md, endIndent: PerfectSpace.md),
            ListTile(
              leading: const Icon(Icons.merge_type_rounded),
              title: const Text('Conflict center'),
              subtitle: const Text(
                'Review only simultaneous edits that cannot merge safely.',
              ),
              onTap: () => PlannerConflictCenterSheet.show(
                context,
                controller: controller,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: PerfectSpace.md),
      Card(
        child: ListTile(
          leading: Icon(
            _syncIcon(controller.syncStatus.phase),
            color: _syncColor(controller.syncStatus.phase),
          ),
          title: const Text('Sync & diagnostics'),
          subtitle: Text(_syncCopy(controller.syncStatus)),
          trailing: TextButton(
            onPressed: controller.refresh,
            child: const Text('Sync now'),
          ),
        ),
      ),
      const SizedBox(height: PerfectSpace.md),
      OutlinedButton.icon(
        onPressed: onSignOut,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out of this private space'),
      ),
    ],
  );
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle, this.onAdd});

  final String title;
  final String subtitle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: PerfectSpace.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      if (onAdd != null)
        IconButton.filled(
          tooltip: 'Add $title',
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
        ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      ...?(trailing == null ? null : <Widget>[trailing!]),
    ],
  );
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.entity,
    required this.controller,
    required this.onInspect,
    this.showKind = false,
    this.todayEligibility,
    this.habitSummary,
  });

  final PlannerEntity entity;
  final PlannerWorkspaceController controller;
  final ValueChanged<PlannerEntity> onInspect;
  final bool showKind;
  final PlannerTodayEligibility? todayEligibility;
  final PlannerHabitDaySummary? habitSummary;

  @override
  Widget build(BuildContext context) {
    final oneOffProgress = entity.kind == PlannerEntityKind.oneOffTask
        ? PlannerTaskProgress.fromEntity(entity)
        : null;
    final completed =
        oneOffProgress?.isComplete ??
        (habitSummary?.state == PlannerHabitDayState.completed ||
            entity.status == PlannerEntityStatus.completed);
    final missed =
        oneOffProgress?.isMissed ??
        (habitSummary?.state == PlannerHabitDayState.missed);
    final requiresRecoveryDecision =
        todayEligibility?.requiresDecision ?? false;
    final color = _colorFor(entity);
    final row = Card(
      margin: const EdgeInsets.only(bottom: PerfectSpace.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onInspect(entity),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PerfectSpace.sm,
            vertical: PerfectSpace.xs,
          ),
          child: Row(
            children: [
              _AgendaCompletionButton(
                entity: entity,
                controller: controller,
                habitSummary: habitSummary,
              ),
              Container(
                width: 4,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: PerfectSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: _textDirection(entity.title),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: missed
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _agendaMeta(entity, showKind: showKind),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (habitSummary != null) ...[
                      const SizedBox(height: 4),
                      _HabitDayStatus(
                        habit: entity,
                        summary: habitSummary!,
                        onTap: () => PlannerHabitLogSheet.show(
                          context,
                          habit: entity,
                          controller: controller,
                        ),
                      ),
                    ],
                    if (requiresRecoveryDecision) ...[
                      const SizedBox(height: 3),
                      Semantics(
                        button: true,
                        label: 'Resolve missed task recovery',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showOneOffRecoverySheet(
                            context,
                            entity: entity,
                            controller: controller,
                            eligibility: todayEligibility!,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  size: 15,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Decision needed · tap to resolve',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Item actions',
                onSelected: (value) {
                  if (value == 'delete') {
                    unawaited(
                      _confirmArchiveEntity(
                        context,
                        entity: entity,
                        controller: controller,
                      ),
                    );
                  }
                  if (value == 'focus') {
                    unawaited(
                      FocusSessionSheet.show(
                        context,
                        controller: controller,
                        entity: entity,
                      ),
                    );
                  }
                  if (value == 'inspect') onInspect(entity);
                  if (value == 'duplicate') {
                    unawaited(
                      _duplicateAndReveal(
                        context,
                        entity: entity,
                        controller: controller,
                        onReveal: onInspect,
                      ),
                    );
                  }
                  if (value == 'postpone') {
                    unawaited(
                      _performEntityMutation(
                        context,
                        operation: () => controller.postponeToTomorrow(entity),
                        failureMessage:
                            'Could not move this item. Nothing was changed.',
                      ),
                    );
                  }
                  if (value == 'miss') {
                    unawaited(
                      _performEntityMutation(
                        context,
                        operation: () => controller.markTodayMissed(entity),
                        failureMessage:
                            'Could not mark this item missed. Nothing changed.',
                      ),
                    );
                  }
                  if (value == 'recover') {
                    unawaited(
                      _showOneOffRecoverySheet(
                        context,
                        entity: entity,
                        controller: controller,
                        eligibility: todayEligibility!,
                      ),
                    );
                  }
                  if (value == 'percent') {
                    unawaited(
                      _showRecurringPercentageSheet(
                        context,
                        entity: entity,
                        controller: controller,
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'inspect',
                    child: Text('Open details'),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  if (entity.kind == PlannerEntityKind.oneOffTask)
                    const PopupMenuItem(
                      value: 'postpone',
                      child: Text('Move to tomorrow'),
                    ),
                  if (requiresRecoveryDecision)
                    const PopupMenuItem(
                      value: 'recover',
                      child: Text('Resolve missed task'),
                    ),
                  if (entity.kind == PlannerEntityKind.recurringTask ||
                      entity.kind == PlannerEntityKind.habit)
                    const PopupMenuItem(
                      value: 'miss',
                      child: Text('Mark miss today'),
                    ),
                  if (entity.kind == PlannerEntityKind.recurringTask)
                    const PopupMenuItem(
                      value: 'percent',
                      child: Text('Set today’s percentage'),
                    ),
                  if (_canFocusEntity(entity))
                    const PopupMenuItem(
                      value: 'focus',
                      child: Text('Start focus'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Archive')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return _DesktopEntityContextRegion(
      key: ValueKey<String>('entity-context-${entity.id}'),
      semanticLabel: '${entity.title}. Item actions available.',
      onOpen: (anchorContext, globalPosition) => _showEntityContextMenu(
        anchorContext,
        entity: entity,
        controller: controller,
        onInspect: () => onInspect(entity),
        onOpenEntity: onInspect,
        eligibility: todayEligibility,
        globalPosition: globalPosition,
      ),
      child: row,
    );
  }
}

class _OpenEntityContextMenuIntent extends Intent {
  const _OpenEntityContextMenuIntent();
}

class _DesktopEntityContextRegion extends StatefulWidget {
  const _DesktopEntityContextRegion({
    super.key,
    required this.semanticLabel,
    required this.onOpen,
    required this.child,
  });

  final String semanticLabel;
  final Future<void> Function(
    BuildContext anchorContext,
    Offset? globalPosition,
  )
  onOpen;
  final Widget child;

  @override
  State<_DesktopEntityContextRegion> createState() =>
      _DesktopEntityContextRegionState();
}

class _DesktopEntityContextRegionState
    extends State<_DesktopEntityContextRegion> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'Perfect entity context menu',
  );
  bool _showFocus = false;
  bool _opening = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _open(Offset? globalPosition) async {
    if (_opening) return;
    _opening = true;
    _focusNode.requestFocus();
    try {
      await widget.onOpen(context, globalPosition);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      key: ValueKey<String>('${widget.key}-keyboard'),
      focusNode: _focusNode,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.contextMenu):
            _OpenEntityContextMenuIntent(),
        SingleActivator(LogicalKeyboardKey.f10, shift: true):
            _OpenEntityContextMenuIntent(),
      },
      actions: <Type, Action<Intent>>{
        _OpenEntityContextMenuIntent:
            CallbackAction<_OpenEntityContextMenuIntent>(
              onInvoke: (_) {
                unawaited(_open(null));
                return null;
              },
            ),
      },
      onShowFocusHighlight: (value) {
        if (mounted) setState(() => _showFocus = value);
      },
      child: Semantics(
        label: widget.semanticLabel,
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          const CustomSemanticsAction(label: 'Show item actions'): () =>
              unawaited(_open(null)),
        },
        child: Listener(
          onPointerDown: (_) => _focusNode.requestFocus(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onSecondaryTapUp: (details) =>
                unawaited(_open(details.globalPosition)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              foregroundDecoration: _showFocus
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: PerfectColors.apricot,
                        width: 2,
                      ),
                    )
                  : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

enum _EntityContextAction {
  inspect,
  edit,
  duplicate,
  logHabit,
  resolveRecovery,
  percentage,
  miss,
  focus,
  tomorrow,
  archive,
}

Future<void> _showEntityContextMenu(
  BuildContext context, {
  required PlannerEntity entity,
  required PlannerWorkspaceController controller,
  required VoidCallback onInspect,
  required ValueChanged<PlannerEntity> onOpenEntity,
  PlannerTodayEligibility? eligibility,
  Offset? globalPosition,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final overlayBox = overlay.context.findRenderObject()! as RenderBox;
  final anchorBox = context.findRenderObject();
  final anchorRect = anchorBox is RenderBox
      ? Rect.fromPoints(
          anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox),
          anchorBox.localToGlobal(
            anchorBox.size.bottomRight(Offset.zero),
            ancestor: overlayBox,
          ),
        )
      : Offset.zero & overlayBox.size;
  final menuPoint = globalPosition == null
      ? anchorRect.center
      : overlayBox.globalToLocal(globalPosition);
  final position = RelativeRect.fromRect(
    Rect.fromCenter(center: menuPoint, width: 1, height: 1),
    Offset.zero & overlayBox.size,
  );
  final action = await showMenu<_EntityContextAction>(
    context: context,
    position: position,
    semanticLabel: 'Actions for ${entity.title}',
    items: <PopupMenuEntry<_EntityContextAction>>[
      const PopupMenuItem<_EntityContextAction>(
        value: _EntityContextAction.inspect,
        child: _ContextMenuLabel(
          icon: Icons.open_in_new_rounded,
          label: 'Open details',
        ),
      ),
      const PopupMenuItem<_EntityContextAction>(
        value: _EntityContextAction.edit,
        child: _ContextMenuLabel(icon: Icons.edit_outlined, label: 'Edit'),
      ),
      const PopupMenuItem<_EntityContextAction>(
        value: _EntityContextAction.duplicate,
        child: _ContextMenuLabel(
          icon: Icons.content_copy_rounded,
          label: 'Duplicate',
        ),
      ),
      if (entity.kind == PlannerEntityKind.habit)
        const PopupMenuItem<_EntityContextAction>(
          value: _EntityContextAction.logHabit,
          child: _ContextMenuLabel(
            icon: Icons.edit_calendar_outlined,
            label: 'Log or correct today',
          ),
        ),
      if (entity.kind == PlannerEntityKind.oneOffTask &&
          eligibility?.requiresDecision == true)
        const PopupMenuItem<_EntityContextAction>(
          value: _EntityContextAction.resolveRecovery,
          child: _ContextMenuLabel(
            icon: Icons.rule_folder_outlined,
            label: 'Resolve missed task',
          ),
        ),
      if (entity.kind == PlannerEntityKind.recurringTask)
        const PopupMenuItem<_EntityContextAction>(
          value: _EntityContextAction.percentage,
          child: _ContextMenuLabel(
            icon: Icons.percent_rounded,
            label: 'Set today’s percentage',
          ),
        ),
      if (entity.kind == PlannerEntityKind.recurringTask ||
          entity.kind == PlannerEntityKind.habit)
        const PopupMenuItem<_EntityContextAction>(
          value: _EntityContextAction.miss,
          child: _ContextMenuLabel(
            icon: Icons.close_rounded,
            label: 'Mark miss today',
          ),
        ),
      if (_canFocusEntity(entity))
        const PopupMenuItem<_EntityContextAction>(
          value: _EntityContextAction.focus,
          child: _ContextMenuLabel(
            icon: Icons.center_focus_strong_rounded,
            label: 'Start focus',
          ),
        ),
      if (_canPostponeEntity(entity))
        const PopupMenuItem<_EntityContextAction>(
          value: _EntityContextAction.tomorrow,
          child: _ContextMenuLabel(
            icon: Icons.event_repeat_rounded,
            label: 'Move to tomorrow',
          ),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem<_EntityContextAction>(
        value: _EntityContextAction.archive,
        child: _ContextMenuLabel(
          icon: Icons.archive_outlined,
          label: 'Archive…',
          danger: true,
        ),
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case _EntityContextAction.inspect:
      onInspect();
      return;
    case _EntityContextAction.edit:
      unawaited(
        PlannerEditor.show(context, controller: controller, existing: entity),
      );
      return;
    case _EntityContextAction.duplicate:
      await _duplicateAndReveal(
        context,
        entity: entity,
        controller: controller,
        onReveal: onOpenEntity,
      );
      return;
    case _EntityContextAction.logHabit:
      unawaited(
        PlannerHabitLogSheet.show(
          context,
          habit: entity,
          controller: controller,
        ),
      );
      return;
    case _EntityContextAction.resolveRecovery:
      if (eligibility != null) {
        unawaited(
          _showOneOffRecoverySheet(
            context,
            entity: entity,
            controller: controller,
            eligibility: eligibility,
          ),
        );
      }
      return;
    case _EntityContextAction.percentage:
      unawaited(
        _showRecurringPercentageSheet(
          context,
          entity: entity,
          controller: controller,
        ),
      );
      return;
    case _EntityContextAction.miss:
      await _performEntityMutation(
        context,
        operation: () => controller.markTodayMissed(entity),
        failureMessage: 'Could not mark this item missed. Nothing changed.',
      );
      return;
    case _EntityContextAction.focus:
      unawaited(
        FocusSessionSheet.show(context, controller: controller, entity: entity),
      );
      return;
    case _EntityContextAction.tomorrow:
      await _performEntityMutation(
        context,
        operation: () => controller.postponeToTomorrow(entity),
        failureMessage: 'Could not move this item. Nothing was changed.',
      );
      return;
    case _EntityContextAction.archive:
      await _confirmArchiveEntity(
        context,
        entity: entity,
        controller: controller,
      );
      return;
  }
}

Future<void> _performEntityMutation(
  BuildContext context, {
  required Future<void> Function() operation,
  required String failureMessage,
}) async {
  try {
    await operation();
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

Future<void> _duplicateAndReveal(
  BuildContext context, {
  required PlannerEntity entity,
  required PlannerWorkspaceController controller,
  required ValueChanged<PlannerEntity> onReveal,
}) async {
  try {
    final duplicate = await controller.duplicateEntity(entity);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Duplicated “${entity.title}”. Progress starts fresh.',
          textDirection: _textDirection(entity.title),
        ),
      ),
    );
    onReveal(duplicate);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not duplicate this item. Nothing was changed.'),
      ),
    );
  }
}

class _ContextMenuLabel extends StatelessWidget {
  const _ContextMenuLabel({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Theme.of(context).colorScheme.error : null;
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: PerfectSpace.sm),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

bool _canFocusEntity(PlannerEntity entity) =>
    entity.status == PlannerEntityStatus.active &&
    (entity.kind == PlannerEntityKind.oneOffTask ||
        entity.kind == PlannerEntityKind.recurringTask ||
        entity.kind == PlannerEntityKind.habit);

bool _canPostponeEntity(PlannerEntity entity) =>
    entity.status == PlannerEntityStatus.active &&
    entity.kind == PlannerEntityKind.oneOffTask;

Future<void> _confirmArchiveEntity(
  BuildContext context, {
  required PlannerEntity entity,
  required PlannerWorkspaceController controller,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Archive “${entity.title}”?',
        textDirection: _textDirection(entity.title),
      ),
      content: const Text(
        'This removes the item from active views. You can restore it later from Archive.',
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep item'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Archive item'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await controller.archiveEntity(entity);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not archive this item. Nothing was changed.'),
      ),
    );
  }
}

Future<void> _showOneOffRecoverySheet(
  BuildContext context, {
  required PlannerEntity entity,
  required PlannerWorkspaceController controller,
  required PlannerTodayEligibility eligibility,
}) async {
  if (entity.kind != PlannerEntityKind.oneOffTask) return;
  Widget buildSurface(BuildContext surfaceContext) {
    var resolving = false;
    return StatefulBuilder(
      builder: (context, setSurfaceState) {
        Future<void> resolve(PlannerRecoveryDisposition disposition) async {
          if (resolving) return;
          setSurfaceState(() => resolving = true);
          try {
            await controller.resolveOneOffRecovery(
              entity,
              disposition: disposition,
              carryCount: eligibility.recovery?.carryCount,
            );
            if (surfaceContext.mounted) {
              Navigator.of(surfaceContext).pop();
            }
          } on Object {
            if (!surfaceContext.mounted) return;
            setSurfaceState(() => resolving = false);
            ScaffoldMessenger.of(surfaceContext).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not save that recovery choice. Your task is unchanged.',
                ),
              ),
            );
          }
        }

        return SafeArea(
          key: const ValueKey<String>('perfect-recovery-surface'),
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PerfectSpace.lg,
              PerfectSpace.sm,
              PerfectSpace.lg,
              PerfectSpace.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'What should happen to “${entity.title}”?',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textDirection: _textDirection(entity.title),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close recovery decision',
                      onPressed: resolving
                          ? null
                          : () => Navigator.of(surfaceContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: PerfectSpace.xs),
                Text(
                  eligibility.recovery?.reason ??
                      'This task passed its planned day and needs your decision.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PerfectSpace.md),
                ListTile(
                  enabled: !resolving,
                  leading: const Icon(Icons.pending_actions_rounded),
                  title: const Text('Keep pending today'),
                  subtitle: const Text(
                    'Leave it active in Today without calling it a miss.',
                  ),
                  onTap: () => resolve(PlannerRecoveryDisposition.pending),
                ),
                ListTile(
                  enabled: !resolving,
                  leading: const Icon(Icons.redo_rounded),
                  title: const Text('Carry into today'),
                  subtitle: const Text(
                    'Explicitly accept the overdue item in today’s next available slot.',
                  ),
                  onTap: () => resolve(PlannerRecoveryDisposition.carryForward),
                ),
                ListTile(
                  enabled: !resolving,
                  leading: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Mark not done'),
                  subtitle: const Text(
                    'Record the miss and remove this occurrence from Today.',
                  ),
                  onTap: () => resolve(PlannerRecoveryDisposition.missed),
                ),
                if (resolving) ...[
                  const SizedBox(height: PerfectSpace.sm),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  if (_prefersBoundedDialog(context)) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(PerfectSpace.xl),
        child: ConstrainedBox(
          key: const ValueKey<String>('perfect-recovery-dialog-surface'),
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight: (MediaQuery.sizeOf(dialogContext).height - 48).clamp(
              320,
              700,
            ),
          ),
          child: buildSurface(dialogContext),
        ),
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: buildSurface,
  );
}

Future<void> _showRecurringPercentageSheet(
  BuildContext context, {
  required PlannerEntity entity,
  required PlannerWorkspaceController controller,
}) async {
  if (entity.kind != PlannerEntityKind.recurringTask) return;
  final current = await controller.taskProgressForDay(
    entity,
    localDay: controller.localNow,
  );
  if (!context.mounted) return;
  final surface = _RecurringPercentageSurface(
    entity: entity,
    controller: controller,
    initialPercent: current.isPartial ? current.percent : 50,
  );

  if (_prefersBoundedDialog(context)) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(PerfectSpace.xl),
        child: ConstrainedBox(
          key: const ValueKey<String>('perfect-progress-dialog-surface'),
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: (MediaQuery.sizeOf(dialogContext).height - 48).clamp(
              320,
              620,
            ),
          ),
          child: surface,
        ),
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => surface,
  );
}

class _RecurringPercentageSurface extends StatefulWidget {
  const _RecurringPercentageSurface({
    required this.entity,
    required this.controller,
    required this.initialPercent,
  });

  final PlannerEntity entity;
  final PlannerWorkspaceController controller;
  final int initialPercent;

  @override
  State<_RecurringPercentageSurface> createState() =>
      _RecurringPercentageSurfaceState();
}

class _RecurringPercentageSurfaceState
    extends State<_RecurringPercentageSurface> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _percentage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _percentage = TextEditingController(text: '${widget.initialPercent}');
  }

  @override
  void dispose() {
    _percentage.dispose();
    super.dispose();
  }

  void _save() {
    if (_saving) return;
    _saveRecurringPercentage(
      sheetContext: context,
      controller: widget.controller,
      entity: widget.entity,
      percentage: _percentage,
      formKey: _formKey,
      setSaving: (value) {
        if (mounted) setState(() => _saving = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    key: const ValueKey<String>('perfect-progress-surface'),
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        PerfectSpace.lg,
        PerfectSpace.sm,
        PerfectSpace.lg,
        PerfectSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Set today’s progress',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close progress editor',
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: PerfectSpace.xs),
            Text(
              widget.entity.title,
              style: Theme.of(context).textTheme.titleMedium,
              textDirection: _textDirection(widget.entity.title),
            ),
            const SizedBox(height: PerfectSpace.md),
            TextFormField(
              controller: _percentage,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Progress today (%)',
                helperText:
                    'Use 1–99. Done remains 100%; empty and not done remain 0%.',
                suffixText: '%',
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null) return 'Enter a whole percentage.';
                if (parsed < 1 || parsed > 99) {
                  return 'Choose a value from 1 to 99.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: PerfectSpace.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.percent_rounded),
                label: const Text('Save partial progress'),
              ),
            ),
            const SizedBox(height: PerfectSpace.xs),
            Text(
              'Quick cycling still enters partial at 50%. This control stores your exact value for today’s occurrence and the widget reflects it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

bool _prefersBoundedDialog(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 680;

Future<void> _saveRecurringPercentage({
  required BuildContext sheetContext,
  required PlannerWorkspaceController controller,
  required PlannerEntity entity,
  required TextEditingController percentage,
  required GlobalKey<FormState> formKey,
  required ValueChanged<bool> setSaving,
}) async {
  if (!(formKey.currentState?.validate() ?? false)) return;
  setSaving(true);
  try {
    await controller.setTaskProgress(
      entity,
      progress: PlannerTaskProgress(
        state: PlannerTaskProgressState.partial,
        percent: int.parse(percentage.text.trim()),
      ),
      localDay: controller.localNow,
      source: 'app_exact_percent',
    );
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
  } on Object {
    if (!sheetContext.mounted) return;
    setSaving(false);
    ScaffoldMessenger.of(sheetContext).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not save today’s percentage. The previous state is unchanged.',
        ),
      ),
    );
  }
}

/// One-off tasks, recurring tasks, and habits deliberately do not share the
/// same completion mutation. A completed series would make tomorrow vanish;
/// a habit needs an explicit log with its own measurement and outcome.
class _AgendaCompletionButton extends StatelessWidget {
  const _AgendaCompletionButton({
    required this.entity,
    required this.controller,
    this.habitSummary,
  });

  final PlannerEntity entity;
  final PlannerWorkspaceController controller;
  final PlannerHabitDaySummary? habitSummary;

  @override
  Widget build(BuildContext context) {
    if (entity.kind == PlannerEntityKind.habit) {
      return IconButton(
        tooltip: habitSummary?.hasLog == true
            ? 'Edit today’s habit result'
            : 'Log habit',
        onPressed: () => PlannerHabitLogSheet.show(
          context,
          habit: entity,
          controller: controller,
        ),
        icon: _habitSummaryVisual(habitSummary),
      );
    }
    if (entity.kind == PlannerEntityKind.recurringTask) {
      return FutureBuilder<PlannerTaskProgress>(
        future: controller.taskProgressForDay(entity),
        builder: (context, snapshot) {
          final progress = snapshot.data ?? const PlannerTaskProgress.pending();
          return IconButton(
            tooltip: _taskProgressTooltip(progress),
            onPressed: () =>
                _cycleTaskProgressWithFeedback(context, controller, entity),
            icon: _animatedTaskProgressVisual(
              context,
              progress,
              fallback: _colorFor(entity),
            ),
          );
        },
      );
    }
    final progress = PlannerTaskProgress.fromEntity(entity);
    return IconButton(
      tooltip: _taskProgressTooltip(progress),
      onPressed: () =>
          _cycleTaskProgressWithFeedback(context, controller, entity),
      icon: _animatedTaskProgressVisual(
        context,
        progress,
        fallback: _colorFor(entity),
      ),
    );
  }
}

Widget _animatedTaskProgressVisual(
  BuildContext context,
  PlannerTaskProgress progress, {
  required Color fallback,
}) => AnimatedSwitcher(
  duration: PerfectMotion.responsive(context, PerfectMotion.quick),
  switchInCurve: PerfectMotion.productive,
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween<double>(begin: .92, end: 1).animate(animation),
      child: child,
    ),
  ),
  child: KeyedSubtree(
    key: ValueKey<String>('${progress.state.name}-${progress.percent}'),
    child: _taskProgressVisual(context, progress, fallback: fallback),
  ),
);

Future<void> _cycleTaskProgressWithFeedback(
  BuildContext context,
  PlannerWorkspaceController controller,
  PlannerEntity entity,
) async {
  final view = View.of(context);
  final textDirection = Directionality.of(context);
  try {
    final progress = await controller.cycleTaskProgress(entity);
    if (!context.mounted) return;
    await HapticFeedback.selectionClick();
    await SemanticsService.sendAnnouncement(
      view,
      _taskProgressTooltip(progress),
      textDirection,
    );
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Today’s status did not change. Your previous value is still safe.',
        ),
      ),
    );
  }
}

class _HabitPulse extends StatelessWidget {
  const _HabitPulse({required this.controller, required this.summaries});

  final PlannerWorkspaceController controller;
  final Map<String, PlannerHabitDaySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final habits = controller.habits;
    if (habits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(PerfectSpace.md),
          child: Text(
            'Habits live here when you are ready—rest days and recovery rules included.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Wrap(
      spacing: PerfectSpace.sm,
      runSpacing: PerfectSpace.sm,
      children: habits
          .take(4)
          .map(
            (habit) => _HabitChip(
              habit: habit,
              controller: controller,
              summary: summaries[habit.id],
            ),
          )
          .toList(),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.controller,
    required this.summary,
    required this.onInspect,
  });

  final PlannerEntity habit;
  final PlannerWorkspaceController controller;
  final PlannerHabitDaySummary? summary;
  final ValueChanged<PlannerEntity> onInspect;

  @override
  Widget build(BuildContext context) {
    final tracking = habit.tracking;
    final method = safeJsonString(tracking['method'], fallback: 'check');
    final card = Card(
      margin: const EdgeInsets.only(bottom: PerfectSpace.sm),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: PerfectColors.mintSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _habitTrackingIcon(method),
                    color: PerfectColors.mint,
                  ),
                ),
                const SizedBox(width: PerfectSpace.sm),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onInspect(habit),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: PerfectSpace.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: _textDirection(habit.title),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _habitTrackingLabel(habit),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: PerfectSpace.xs),
                FilledButton.tonalIcon(
                  onPressed: () => PlannerHabitLogSheet.show(
                    context,
                    habit: habit,
                    controller: controller,
                  ),
                  icon: Icon(
                    summary?.hasLog == true
                        ? Icons.edit_calendar_outlined
                        : Icons.add_task_rounded,
                  ),
                  label: Text(summary?.hasLog == true ? 'Edit today' : 'Log'),
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: PerfectSpace.sm),
              _HabitDayStatus(
                habit: habit,
                summary: summary!,
                onTap: () => PlannerHabitLogSheet.show(
                  context,
                  habit: habit,
                  controller: controller,
                ),
                expanded: true,
              ),
            ],
            const SizedBox(height: PerfectSpace.sm),
            Wrap(
              spacing: PerfectSpace.xs,
              runSpacing: PerfectSpace.xs,
              children: [
                _HabitFact(
                  icon: Icons.event_repeat_rounded,
                  label: _habitScheduleLabel(habit),
                ),
                if (habit.recurrence['flexible'] == true)
                  const _HabitFact(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Flexible',
                  ),
                if (habit.recurrence['paused'] == true)
                  const _HabitFact(
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'Paused',
                  ),
              ],
            ),
            const SizedBox(height: PerfectSpace.sm),
            Text(
              'Schedule this week',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PerfectSpace.xs),
            _HabitWeekStrip(habit: habit, now: controller.localNow),
          ],
        ),
      ),
    );
    return _DesktopEntityContextRegion(
      key: ValueKey<String>('entity-context-${habit.id}'),
      semanticLabel: '${habit.title}. Item actions available.',
      onOpen: (anchorContext, globalPosition) => _showEntityContextMenu(
        anchorContext,
        entity: habit,
        controller: controller,
        onInspect: () => onInspect(habit),
        onOpenEntity: onInspect,
        globalPosition: globalPosition,
      ),
      child: card,
    );
  }
}

class _HabitFact extends StatelessWidget {
  const _HabitFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: PerfectSpace.sm,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}

class _HabitDayStatus extends StatelessWidget {
  const _HabitDayStatus({
    required this.habit,
    required this.summary,
    required this.onTap,
    this.expanded = false,
  });

  final PlannerEntity habit;
  final PlannerHabitDaySummary summary;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final color = _habitSummaryColor(summary.state, context);
    return Semantics(
      button: true,
      label: '${_habitSummaryDetail(summary, habit)}. Tap to edit today.',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: expanded ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? PerfectSpace.sm : PerfectSpace.xs,
            vertical: PerfectSpace.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .28)),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(_habitSummaryIcon(summary.state), size: 16, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  _habitSummaryDetail(summary, habit),
                  maxLines: expanded ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.edit_outlined, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _habitSummaryVisual(PlannerHabitDaySummary? summary) {
  if (summary?.state == PlannerHabitDayState.partial) {
    return SizedBox(
      width: 31,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${summary!.progressPercent}%',
          style: const TextStyle(
            color: PerfectColors.lilac,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
  return Icon(
    _habitSummaryIcon(summary?.state),
    color: switch (summary?.state) {
      PlannerHabitDayState.completed => PerfectColors.mint,
      PlannerHabitDayState.missed => PerfectColors.danger,
      PlannerHabitDayState.partial => PerfectColors.lilac,
      _ => PerfectColors.mutedInk,
    },
  );
}

IconData _habitSummaryIcon(PlannerHabitDayState? state) => switch (state) {
  PlannerHabitDayState.completed => Icons.check_circle_rounded,
  PlannerHabitDayState.missed => Icons.cancel_rounded,
  PlannerHabitDayState.partial => Icons.timelapse_rounded,
  _ => Icons.radio_button_unchecked_rounded,
};

Color _habitSummaryColor(PlannerHabitDayState? state, BuildContext context) =>
    switch (state) {
      PlannerHabitDayState.completed => PerfectColors.mint,
      PlannerHabitDayState.missed => PerfectColors.danger,
      PlannerHabitDayState.partial => PerfectColors.lilac,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };

String _habitSummaryCompact(
  PlannerHabitDaySummary? summary,
  PlannerEntity habit,
) {
  if (summary == null || summary.isPending && !summary.hasLog) return 'Pending';
  if (summary.method == 'count' || summary.method == 'duration') {
    final unit = safeNullableJsonString(habit.tracking['unit']);
    return '${_compactNumber(summary.amount)}${unit == null ? '' : ' $unit'}'
        ' · ${summary.progressPercent}%';
  }
  if (summary.method == 'checklist') {
    final total = _habitChecklistItems(habit).length;
    final checked = _habitCheckedChecklistCount(summary, habit);
    return '$checked/$total'
        ' · ${summary.progressPercent}%';
  }
  return switch (summary.state) {
    PlannerHabitDayState.completed => 'Done',
    PlannerHabitDayState.missed => 'Not done',
    PlannerHabitDayState.partial => '${summary.progressPercent}%',
    PlannerHabitDayState.pending => 'Pending',
  };
}

String _habitSummaryDetail(
  PlannerHabitDaySummary summary,
  PlannerEntity habit,
) {
  final state = switch (summary.state) {
    PlannerHabitDayState.pending => 'Pending',
    PlannerHabitDayState.partial => 'In progress',
    PlannerHabitDayState.completed => 'Complete',
    PlannerHabitDayState.missed => 'Not done',
  };
  if (summary.method == 'count' || summary.method == 'duration') {
    final unit = safeNullableJsonString(habit.tracking['unit']);
    final suffix = unit == null ? '' : ' $unit';
    return '$state · ${_compactNumber(summary.amount)}$suffix of '
        '${_compactNumber(summary.target)}$suffix · ${summary.progressPercent}%';
  }
  if (summary.method == 'checklist') {
    final total = _habitChecklistItems(habit).length;
    final checked = _habitCheckedChecklistCount(summary, habit);
    return '$state · $checked/$total '
        'checked · ${summary.requiredCount} needed · '
        '${summary.progressPercent}%';
  }
  if (summary.method == 'avoid') {
    return summary.state == PlannerHabitDayState.missed
        ? 'Slip recorded today'
        : summary.state == PlannerHabitDayState.completed
        ? 'Stayed clear today'
        : 'Pending today';
  }
  return '$state today';
}

List<Map<String, dynamic>> _habitChecklistItems(PlannerEntity habit) =>
    safeJsonMapList(
      habit.tracking[PlannerHabitTrackingKeys.checklist] ??
          habit.payload[PlannerHabitTrackingKeys.checklist],
    );

int _habitCheckedChecklistCount(
  PlannerHabitDaySummary summary,
  PlannerEntity habit,
) {
  final configuredIds = _habitChecklistItems(habit)
      .map(
        (item) => safeNullableJsonString(item[PlannerHabitTrackingKeys.itemId]),
      )
      .whereType<String>()
      .toSet();
  return summary.checkedItemIds.where(configuredIds.contains).length;
}

class _HabitWeekStrip extends StatelessWidget {
  const _HabitWeekStrip({required this.habit, required this.now});

  final PlannerEntity habit;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 336 ? 336.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Row(
              children: List<Widget>.generate(7, (index) {
                final date = weekStart.add(Duration(days: index));
                final isToday = _isSameDate(date, today);
                final scheduled = PlannerRecurrenceEngine.occursOnDate(
                  entity: habit,
                  date: date,
                );
                return Expanded(
                  child: Semantics(
                    label:
                        '${_weekdayShortLabel(date.weekday)}, ${date.day}: '
                        '${scheduled ? 'scheduled' : 'rest day'}'
                        '${isToday ? ', today' : ''}',
                    child: Column(
                      children: [
                        Text(
                          _weekdayShortLabel(date.weekday),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheduled
                                ? PerfectColors.mintSoft
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isToday
                                  ? PerfectColors.apricot
                                  : scheduled
                                  ? PerfectColors.mint
                                  : Colors.transparent,
                              width: isToday ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${date.day}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: isToday
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: scheduled
                                      ? PerfectColors.mint
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

IconData _habitTrackingIcon(String method) => switch (method) {
  'count' => Icons.pin_outlined,
  'duration' => Icons.timer_outlined,
  'avoid' => Icons.do_not_disturb_alt_rounded,
  'checklist' => Icons.checklist_rounded,
  _ => Icons.eco_outlined,
};

String _habitTrackingLabel(PlannerEntity habit) {
  final tracking = habit.tracking;
  final method = safeJsonString(tracking['method'], fallback: 'check');
  if (method == 'check') return 'Yes / no check-in';
  if (method == 'checklist') {
    final items = _habitChecklistItems(habit);
    final condition = safeJsonMap(
      tracking[PlannerHabitTrackingKeys.successCondition],
    );
    final type = safeJsonString(
      condition[PlannerHabitTrackingKeys.successType],
      fallback: 'all',
    );
    final value = safeJsonInt(
      condition[PlannerHabitTrackingKeys.successValue],
      fallback: items.length,
    );
    final rule = switch (type) {
      'count' => '$value needed',
      'percent' => '$value% needed',
      _ => 'all required',
    };
    return 'Checklist · ${items.length} items · $rule';
  }
  final target = tracking['target'];
  final value = target is num ? _compactNumber(target.toDouble()) : '1';
  final unit = safeNullableJsonString(tracking['unit']);
  final direction = safeJsonString(
    tracking['goal'],
    fallback: method == 'avoid' ? 'at_most' : 'at_least',
  );
  final prefix = direction == 'at_most' ? 'At most' : 'At least';
  if (method == 'duration') return '$prefix $value ${unit ?? 'minutes'}';
  if (method == 'avoid') return '$prefix $value ${unit ?? 'times'}';
  return '$prefix $value ${unit ?? 'per day'}';
}

String _habitScheduleLabel(PlannerEntity habit) {
  final recurrence = habit.recurrence;
  final rule = safeJsonString(recurrence['rule'], fallback: 'none');
  final interval = safeJsonInt(recurrence['interval'], fallback: 1);
  return switch (rule) {
    'daily' || 'none' => 'Every day',
    'weekdays' => 'Weekdays',
    'weekly' => _weeklyScheduleLabel(recurrence),
    'interval' => 'Every $interval days',
    'monthly' => interval == 1 ? 'Every month' : 'Every $interval months',
    'yearly' => interval == 1 ? 'Every year' : 'Every $interval years',
    _ => 'Custom schedule',
  };
}

String _weeklyScheduleLabel(Map<String, dynamic> recurrence) {
  final stored = recurrence['weekdays'];
  if (stored is! Iterable) return 'Every week';
  final days = stored
      .map((value) => safeJsonInt(value, fallback: -1))
      .where((value) => value >= DateTime.monday && value <= DateTime.sunday)
      .map(_weekdayShortLabel)
      .toList(growable: false);
  return days.isEmpty ? 'Every week' : days.join(', ');
}

String _weekdayShortLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'Mon',
  DateTime.tuesday => 'Tue',
  DateTime.wednesday => 'Wed',
  DateTime.thursday => 'Thu',
  DateTime.friday => 'Fri',
  DateTime.saturday => 'Sat',
  _ => 'Sun',
};

bool _isSameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _compactNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

class _HabitChip extends StatelessWidget {
  const _HabitChip({
    required this.habit,
    required this.controller,
    required this.summary,
  });

  final PlannerEntity habit;
  final PlannerWorkspaceController controller;
  final PlannerHabitDaySummary? summary;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(
      _habitSummaryIcon(summary?.state),
      size: 17,
      color: _habitSummaryColor(summary?.state, context),
    ),
    label: Text(
      '${habit.title} · ${_habitSummaryCompact(summary, habit)}',
      overflow: TextOverflow.ellipsis,
    ),
    onPressed: () => PlannerHabitLogSheet.show(
      context,
      habit: habit,
      controller: controller,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(PerfectSpace.xxl),
      child: Column(
        children: [
          Icon(icon, size: 44, color: PerfectColors.apricot),
          const SizedBox(height: PerfectSpace.sm),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: PerfectSpace.xs),
          Text(body, textAlign: TextAlign.center),
          const SizedBox(height: PerfectSpace.md),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class _Inspector extends StatelessWidget {
  const _Inspector({
    super.key,
    required this.entity,
    required this.controller,
    required this.onEdit,
    required this.onReveal,
    required this.onClear,
    this.embedded = false,
  });

  final PlannerEntity? entity;
  final PlannerWorkspaceController controller;
  final VoidCallback onEdit;
  final ValueChanged<PlannerEntity> onReveal;
  final VoidCallback onClear;
  final bool embedded;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: embedded ? Theme.of(context).colorScheme.surface : null,
      borderRadius: embedded ? BorderRadius.circular(30) : null,
      border: embedded
          ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
          : Border(
              left: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
      boxShadow: embedded
          ? [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: .1),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
    ),
    child: Padding(
      padding: EdgeInsets.all(embedded ? PerfectSpace.md : PerfectSpace.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showFocusPrompt =
              embedded && constraints.maxHeight >= 700 && entity != null;
          return entity == null
              ? const _InspectorEmpty()
              : CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Inspector',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close inspector',
                                onPressed: onClear,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: PerfectSpace.xl),
                          Text(
                            entity!.title,
                            textDirection: _textDirection(entity!.title),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: PerfectSpace.sm),
                          Text(entity!.note ?? 'No note yet.'),
                          const SizedBox(height: PerfectSpace.lg),
                          _InspectorFact(
                            label: 'Kind',
                            value: _kindLabel(entity!.kind),
                          ),
                          _InspectorFact(
                            label: 'Recovery',
                            value: safeJsonString(
                              entity!.recovery['on_miss'],
                              fallback: 'default',
                            ),
                          ),
                          _InspectorFact(
                            label: 'Sync',
                            value: controller.syncStatus.phase.name,
                          ),
                          if (entity!.dueAt != null)
                            _InspectorFact(
                              label: 'Deadline',
                              value: _inspectorDateTime(entity!.dueAt!),
                            ),
                          if (safeNullableJsonString(
                                entity!.payload['category'],
                              ) !=
                              null)
                            _InspectorFact(
                              label: 'Category',
                              value: safeJsonString(
                                entity!.payload['category'],
                                fallback: '',
                              ),
                            ),
                          if (entity!.customProperties.isNotEmpty)
                            _CustomPropertyFacts(
                              properties: entity!.customProperties,
                            ),
                          if (showFocusPrompt)
                            Expanded(
                              child: Center(
                                child: _InspectorFocusPrompt(
                                  entity: entity!,
                                  controller: controller,
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(height: PerfectSpace.xs),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _duplicateAndReveal(
                                context,
                                entity: entity!,
                                controller: controller,
                                onReveal: onReveal,
                              ),
                              icon: const Icon(Icons.content_copy_rounded),
                              label: const Text('Duplicate'),
                            ),
                          ),
                          if (!showFocusPrompt) ...[
                            const SizedBox(height: PerfectSpace.xs),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => FocusSessionSheet.show(
                                  context,
                                  controller: controller,
                                  entity: entity,
                                ),
                                icon: const Icon(Icons.timer_outlined),
                                label: const Text('Focus'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
        },
      ),
    ),
  );
}

class _InspectorFocusPrompt extends StatelessWidget {
  const _InspectorFocusPrompt({required this.entity, required this.controller});

  final PlannerEntity entity;
  final PlannerWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final schedule = entity.scheduledAt == null
        ? 'Flexible on today’s runway'
        : 'Scheduled for ${_shortTime(entity.scheduledAt!.toLocal())}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PerfectColors.lilacSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.center_focus_strong_rounded,
              color: PerfectColors.lilac,
              size: 28,
            ),
            const SizedBox(height: PerfectSpace.sm),
            Text(
              'Shape the next block',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: PerfectSpace.xxs),
            Text(
              schedule,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PerfectSpace.md),
            FilledButton.tonalIcon(
              onPressed: () => FocusSessionSheet.show(
                context,
                controller: controller,
                entity: entity,
              ),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Focus now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorEmpty extends StatelessWidget {
  const _InspectorEmpty();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.touch_app_outlined,
          size: 42,
          color: PerfectColors.lilac,
        ),
        const SizedBox(height: PerfectSpace.sm),
        Text('Select an item', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: PerfectSpace.xs),
        const Text(
          'Details stay out of your way until you ask for them.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _InspectorFact extends StatelessWidget {
  const _InspectorFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PerfectSpace.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _CustomPropertyFacts extends StatelessWidget {
  const _CustomPropertyFacts({required this.properties});

  final Map<String, dynamic> properties;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: properties.entries
        .map((entry) {
          final descriptor = safeJsonMap(entry.value);
          final type = safeJsonString(descriptor['type'], fallback: 'text');
          final value = _propertyDisplay(type, descriptor, properties);
          return _InspectorFact(label: entry.key, value: value);
        })
        .toList(growable: false),
  );
}

String _propertyDisplay(
  String type,
  Map<String, dynamic> descriptor,
  Map<String, dynamic> allProperties,
) {
  if (type == 'formula') {
    final result = PlannerFormula.evaluate(
      safeJsonString(descriptor['formula'], fallback: ''),
      allProperties,
    );
    return result.isValid
        ? result.displayValue
        : result.error ?? 'Formula error';
  }
  if (type == 'checkbox') {
    return descriptor['value'] == true ? 'Checked' : 'Not checked';
  }
  if (type == 'relation') {
    return safeJsonString(
      descriptor['formula'],
      fallback: 'No relation target',
    );
  }
  final value = descriptor['value'];
  return value == null || value.toString().trim().isEmpty
      ? 'Not set'
      : value.toString();
}

List<PlannerEntity> _todayItemsFor(
  PlannerWorkspaceController controller, {
  required DateTime now,
}) {
  final items = <PlannerEntity>[...controller.tasks, ...controller.habits]
      .where(
        (entity) =>
            PlannerTodayEngine.evaluate(entity: entity, day: now).isEligible,
      )
      .toList();
  _sortAgenda(items);
  return items;
}

List<PlannerEntity> _plannedItemsFor(
  PlannerWorkspaceController controller, {
  required DateTime now,
}) {
  final items = <PlannerEntity>[...controller.tasks, ...controller.habits]
      .where((entity) {
        final scheduled = entity.scheduledAt?.toLocal();
        if (scheduled == null) return false;
        if (entity.kind == PlannerEntityKind.oneOffTask) {
          final localDay = now.toLocal();
          return scheduled.year == localDay.year &&
              scheduled.month == localDay.month &&
              scheduled.day == localDay.day;
        }
        return PlannerTodayEngine.evaluate(entity: entity, day: now).isEligible;
      })
      .toList();
  _sortAgenda(items);
  return items;
}

void _sortAgenda(List<PlannerEntity> items) => items.sort((a, b) {
  final first = a.scheduledAt?.toLocal();
  final second = b.scheduledAt?.toLocal();
  if (first != null && second != null) return first.compareTo(second);
  if (first != null) return -1;
  if (second != null) return 1;
  return a.updatedAt.compareTo(b.updatedAt);
});

String _greeting(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning.';
  if (hour < 18) return 'Good afternoon.';
  return 'Good evening.';
}

String _todayLabel(DateTime now) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[now.month - 1]} ${now.day} · ${now.year}';
}

String _agendaMeta(PlannerEntity entity, {required bool showKind}) {
  final time = entity.scheduledAt?.toLocal();
  final due = entity.dueAt?.toLocal();
  final category = safeNullableJsonString(entity.payload['category']);
  final parts = <String>[
    if (time == null) 'Inbox' else _shortTime(time),
    if (due != null) 'Due ${_shortDate(due)}',
    if (showKind) _kindLabel(entity.kind),
    if (category case final String value) value,
    safeJsonString(entity.payload['priority'], fallback: 'normal'),
  ];
  return parts.join(' · ');
}

String _inspectorDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} · ${_shortTime(local)}';
}

String _shortDate(DateTime value) {
  const months = <String>[
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
  return '${months[value.month - 1]} ${value.day}';
}

String _shortTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  return '$hour:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
}

String _kindLabel(PlannerEntityKind kind) => switch (kind) {
  PlannerEntityKind.oneOffTask => 'Task',
  PlannerEntityKind.recurringTask => 'Recurring task',
  PlannerEntityKind.habit => 'Habit',
  PlannerEntityKind.project => 'Project',
  PlannerEntityKind.area => 'Area',
};

IconData _taskProgressIcon(PlannerTaskProgress progress) =>
    switch (progress.state) {
      PlannerTaskProgressState.pending => Icons.radio_button_unchecked_rounded,
      PlannerTaskProgressState.completed => Icons.check_circle_rounded,
      PlannerTaskProgressState.missed => Icons.cancel_rounded,
      PlannerTaskProgressState.partial => Icons.percent_rounded,
    };

Widget _taskProgressVisual(
  BuildContext context,
  PlannerTaskProgress progress, {
  required Color fallback,
}) {
  final color = _taskProgressColor(progress, fallback: fallback);
  if (!progress.isPartial) {
    return Icon(_taskProgressIcon(progress), color: color);
  }
  return SizedBox(
    width: 30,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${progress.percent}%',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

Color _taskProgressColor(
  PlannerTaskProgress progress, {
  required Color fallback,
}) => switch (progress.state) {
  PlannerTaskProgressState.pending => fallback,
  PlannerTaskProgressState.completed => PerfectColors.mint,
  PlannerTaskProgressState.missed => PerfectColors.danger,
  PlannerTaskProgressState.partial => PerfectColors.lilac,
};

String _taskProgressTooltip(
  PlannerTaskProgress progress,
) => switch (progress.state) {
  PlannerTaskProgressState.pending => 'Mark done',
  PlannerTaskProgressState.completed => 'Mark not done',
  PlannerTaskProgressState.missed =>
    'Mark ${progress.percent == 0 ? '50%' : '${progress.percent}%'} progress',
  PlannerTaskProgressState.partial =>
    '${progress.percent}% progress · clear task outcome',
};

Color _colorFor(PlannerEntity entity) => switch (entity.kind) {
  PlannerEntityKind.habit => PerfectColors.mint,
  PlannerEntityKind.project => PerfectColors.lilac,
  PlannerEntityKind.area => PerfectColors.lilac,
  _ => _categoryColor(entity),
};

Color _categoryColor(PlannerEntity entity) {
  final category = safeJsonString(
    entity.payload['category'],
    fallback: '',
  ).toLowerCase();
  if (<String>{'health', 'home', 'personal'}.contains(category)) {
    return PerfectColors.mint;
  }
  if (<String>{'study', 'finance'}.contains(category)) {
    return PerfectColors.lilac;
  }
  return PerfectColors.apricot;
}

TextDirection _textDirection(String value) =>
    RegExp(r'[\u0600-\u08ff]').hasMatch(value)
    ? TextDirection.rtl
    : TextDirection.ltr;

IconData _syncIcon(PlannerSyncPhase phase) => switch (phase) {
  PlannerSyncPhase.idle => Icons.cloud_done_outlined,
  PlannerSyncPhase.syncing => Icons.sync_rounded,
  PlannerSyncPhase.offline => Icons.cloud_off_outlined,
  PlannerSyncPhase.needsAttention => Icons.error_outline_rounded,
};

Color _syncColor(PlannerSyncPhase phase) => switch (phase) {
  PlannerSyncPhase.idle => PerfectColors.mint,
  PlannerSyncPhase.syncing => PerfectColors.apricot,
  PlannerSyncPhase.offline => PerfectColors.lilac,
  PlannerSyncPhase.needsAttention => PerfectColors.danger,
};

String _syncCopy(PlannerSyncStatus status) => switch (status.phase) {
  PlannerSyncPhase.idle =>
    'Local changes are safely reconciled when connected.',
  PlannerSyncPhase.syncing =>
    'Working in the background; your page stays usable.',
  PlannerSyncPhase.offline =>
    'Everything is stored locally and queued for retry.',
  PlannerSyncPhase.needsAttention =>
    status.message ?? 'Open this after configuring the private owner profile.',
};

TextDirection _directionForCapture(BuildContext context, String value) {
  final firstRtl = RegExp(
    r'[\u0590-\u08ff\ufb1d-\ufdfd\ufe70-\ufefc]',
  ).firstMatch(value)?.start;
  final firstLtr = RegExp(r'[A-Za-z\u00c0-\u02af]').firstMatch(value)?.start;
  if (firstRtl == null && firstLtr == null) {
    return Directionality.of(context);
  }
  if (firstRtl == null) return TextDirection.ltr;
  if (firstLtr == null) return TextDirection.rtl;
  return firstRtl < firstLtr ? TextDirection.rtl : TextDirection.ltr;
}
