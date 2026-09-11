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
import 'package:perfect/planner/domain/planner_today_stream.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/focus_session_sheet.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_pictogram.dart';
import 'package:perfect/presentation/planner_conflict_center_sheet.dart';
import 'package:perfect/presentation/planner_archive_sheet.dart';
import 'package:perfect/presentation/perfect_today_widget_settings_sheet.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/perfect_workspace_header.dart';
import 'package:perfect/presentation/planner_editor.dart';
import 'package:perfect/presentation/planner_habit_log_sheet.dart';
import 'package:perfect/presentation/planner_insights_sheet.dart';
import 'package:perfect/presentation/planner_reminder_settings_sheet.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:perfect/presentation/today_pulse.dart';

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
    this.contrastMode = PerfectContrastMode.system,
    required this.onThemeModeChanged,
    this.onContrastModeChanged,
    this.now = DateTime.now,
    this.ownerDisplayName,
    this.navigationController,
    this.aiClient,
    this.aiVoiceRecorder,
    this.feedbackController,
  });

  final PlannerWorkspaceController controller;
  final Future<void> Function() onSignOut;
  final ThemeMode themeMode;
  final PerfectContrastMode contrastMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<PerfectContrastMode>? onContrastModeChanged;
  final DateTime Function() now;
  final String? ownerDisplayName;
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
  final GlobalKey<PerfectAiDockState> _aiDockKey =
      GlobalKey<PerfectAiDockState>();
  final GlobalKey _destinationHostKey = GlobalKey(
    debugLabel: 'Perfect persistent destination host',
  );
  final GlobalKey _todayPageKey = GlobalKey(
    debugLabel: 'Perfect Today destination',
  );
  final GlobalKey<_TasksPageState> _tasksPageKey = GlobalKey<_TasksPageState>(
    debugLabel: 'Perfect Tasks destination',
  );
  final GlobalKey<_PlanPageState> _planPageKey = GlobalKey<_PlanPageState>(
    debugLabel: 'Perfect Plan destination',
  );
  final GlobalKey _habitsPageKey = GlobalKey(
    debugLabel: 'Perfect Habits destination',
  );
  final GlobalKey _morePageKey = GlobalKey(
    debugLabel: 'Perfect More destination',
  );
  final PageStorageBucket _destinationPageStorage = PageStorageBucket();
  final ReadyFeedbackOverlayController _feedbackOverlayController =
      ReadyFeedbackOverlayController();
  _WorkspaceLayoutTier? _lastLayoutTier;
  bool _editorSurfaceOpen = false;
  bool _focusSurfaceOpen = false;
  bool _tabletNavigationExtended = false;
  bool _desktopNavigationExtended = true;
  bool _aiOpen = false;
  int _navigationDirection = 1;
  bool _navigationConsumptionScheduled = false;
  int _handledNavigationRequestSerial = 0;
  String? _requestedTodayProjection;
  String? _resolvedTodayProjection;
  List<PlannerEntity> _projectedTodayItems = const <PlannerEntity>[];
  Map<String, PlannerTodayEligibility> _todayEligibilityById =
      const <String, PlannerTodayEligibility>{};
  Map<String, PlannerHabitDaySummary> _habitDaySummaryById =
      const <String, PlannerHabitDaySummary>{};
  Map<String, PlannerTaskProgress> _todayTaskProgressById =
      const <String, PlannerTaskProgress>{};
  double? _inspectorWidthOverride;

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
      _todayTaskProgressById = const <String, PlannerTaskProgress>{};
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
    _feedbackOverlayController.dispose();
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
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(16) / 16;
                  final geometry = PerfectResponsiveGeometry.fromConstraints(
                    constraints,
                    fallbackSize: MediaQuery.sizeOf(context),
                    textScale: textScale,
                  );
                  final tier = _layoutTierFor(geometry);
                  final shortLandscape =
                      geometry.isShortLandscape && constraints.maxWidth >= 520;
                  _preserveQuickCaptureFocusAcross(tier);
                  if (shortLandscape && tier != _WorkspaceLayoutTier.expanded) {
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
      // Feedback lives in the contextual command menu and the More settings
      // page. Keeping it out of the primary canvas prevents a nonessential
      // draggable tab from intercepting task rows or visual rhythm.
      launcherVisible: false,
      launcherController: _feedbackOverlayController,
      child: workspace,
    );
  }

  _WorkspaceLayoutTier _layoutTierFor(PerfectResponsiveGeometry geometry) {
    if (geometry.isShortLandscape && geometry.availableSize.width >= 520) {
      return _WorkspaceLayoutTier.medium;
    }

    // Expanded shell space is earned by useful content: a 1040dp primary
    // workspace plus bounded navigation/divider chrome. Each expanded pane
    // then reflows large text internally and suppresses the inspector before
    // it can starve the primary work surface.
    final expandedThreshold =
        PerfectResponsiveGeometry.expandedContentThreshold + 184;
    if (geometry.availableSize.width >= expandedThreshold) {
      return _WorkspaceLayoutTier.expanded;
    }
    return geometry.windowClass == PerfectWindowClass.compact
        ? _WorkspaceLayoutTier.compact
        : _WorkspaceLayoutTier.medium;
  }

  Widget _compact(BuildContext context) => Scaffold(
    key: const ValueKey<String>('perfect-shell-compact'),
    // The footer remains visually glassy, but Today content must finish above
    // it. Letting the first live task sit under an actionable capture field
    // makes neither the task nor the field trustworthy.
    extendBody: false,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          PerfectWorkspaceHeader(
            compact: true,
            destinationKey: _destination.name,
            destinationLabel: _destination.label,
            supportText: _headerSupportText(_destination),
            now: widget.now,
            showClock: _destination != _PerfectDestination.today,
            status: widget.controller.syncStatus,
            onSync: widget.controller.refresh,
          ),
          Expanded(
            child: _destinationHost(
              context,
              tier: _WorkspaceLayoutTier.compact,
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: Column(
      key: const ValueKey<String>('perfect-compact-bottom-dock'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_destination == _PerfectDestination.today)
          _WorkspaceComposerStack(
            aiPanel: _aiPanel(desktop: false),
            capture: _quickCapture(desktop: false),
          ),
        _CompactWorkspaceFooter(
          selectedIndex: _destination.index,
          onDestinationSelected: _selectDestination,
        ),
      ],
    ),
  );

  Widget _medium(BuildContext context, {bool shortLandscape = false}) =>
      Scaffold(
        key: const ValueKey<String>('perfect-shell-medium'),
        body: SafeArea(
          child: Row(
            children: [
              if (shortLandscape)
                _ShortLandscapeNavigationRail(
                  selected: _destination,
                  onSelect: _selectDestination,
                  extended: _tabletNavigationExtended,
                  onToggleExtended: _toggleTabletNavigationWidth,
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
                    PerfectWorkspaceHeader(
                      compact: shortLandscape,
                      // The navigation rail already owns the product identity
                      // in both compact and extended states. Keep the header
                      // contextual instead of repeating the brand.
                      showWordmark: false,
                      showContext: _destination != _PerfectDestination.today,
                      destinationKey: _destination.name,
                      destinationLabel: _destination.label,
                      supportText: _headerSupportText(_destination),
                      now: widget.now,
                      showClock: _destination != _PerfectDestination.today,
                      status: widget.controller.syncStatus,
                      onSync: widget.controller.refresh,
                    ),
                    Expanded(
                      child: _destinationHost(
                        context,
                        tier: _WorkspaceLayoutTier.medium,
                        shortLandscape: shortLandscape,
                      ),
                    ),
                    if (_destination == _PerfectDestination.today)
                      _WorkspaceComposerStack(
                        aiPanel: _aiPanel(desktop: true),
                        capture: _quickCapture(desktop: true),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _expanded(BuildContext context) {
    final tabletNavigation =
        Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      key: const ValueKey<String>('perfect-shell-expanded'),
      body: SafeArea(
        child: Row(
          children: [
            _NavigationRail(
              selected: _destination,
              onSelect: _selectDestination,
              extended: tabletNavigation
                  ? _tabletNavigationExtended
                  : _desktopNavigationExtended,
              onToggleExtended: tabletNavigation
                  ? _toggleTabletNavigationWidth
                  : _toggleDesktopNavigationWidth,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      PerfectWorkspaceHeader(
                        showWordmark: _destination != _PerfectDestination.today,
                        showContext: _destination != _PerfectDestination.today,
                        destinationKey: _destination.name,
                        destinationLabel: _destination.label,
                        supportText: _headerSupportText(_destination),
                        now: widget.now,
                        showClock: _destination != _PerfectDestination.today,
                        status: widget.controller.syncStatus,
                        onSync: widget.controller.refresh,
                      ),
                      Expanded(
                        child: _destinationHost(
                          context,
                          tier: _WorkspaceLayoutTier.expanded,
                          workspaceConstraints: constraints,
                        ),
                      ),
                      if (_destination == _PerfectDestination.today)
                        _WorkspaceComposerStack(
                          aiPanel: _aiPanel(desktop: true),
                          capture: _quickCapture(desktop: true),
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
  }

  Widget _aiPanel({required bool desktop}) {
    final client = widget.aiClient;
    if (client == null) return const SizedBox.shrink();
    return PerfectAiDock(
      key: _aiDockKey,
      client: client,
      voiceRecorder: widget.aiVoiceRecorder,
      onProposalApplied: widget.controller.refresh,
      desktop: desktop,
      showCollapsedLauncher: false,
      onOpenChanged: (open) {
        if (!mounted || _aiOpen == open) return;
        setState(() => _aiOpen = open);
      },
    );
  }

  Widget _quickCapture({required bool desktop}) => _QuickCaptureDock(
    key: _quickCaptureDockKey,
    controller: widget.controller,
    onOpenEditor: () => _openEditor(),
    captureController: _quickCaptureController,
    focusNode: _quickCaptureFocusNode,
    desktop: desktop,
    aiAvailable: widget.aiClient != null,
    aiOpen: _aiOpen,
    onToggleAi: _toggleAi,
    onOpenAiVoice: _openAiVoice,
  );

  Widget _destinationHost(
    BuildContext context, {
    required _WorkspaceLayoutTier tier,
    bool shortLandscape = false,
    BoxConstraints? workspaceConstraints,
  }) {
    final pages = <Widget>[
      KeyedSubtree(
        key: _todayPageKey,
        child: _todaySurface(tier: tier, shortLandscape: shortLandscape),
      ),
      _TasksPage(
        key: _tasksPageKey,
        controller: widget.controller,
        onInspect: _inspect,
        onAdd: _openEditor,
      ),
      _PlanPage(
        key: _planPageKey,
        controller: widget.controller,
        now: widget.now().toLocal(),
        onInspect: _inspect,
        onAdd: _openEditor,
      ),
      _HabitsPage(
        key: _habitsPageKey,
        controller: widget.controller,
        summaries: _displayHabitSummaries,
        onInspect: _inspect,
        onAdd: () => _openEditor(initialKind: PlannerEntityKind.habit),
      ),
      _MorePage(
        key: _morePageKey,
        controller: widget.controller,
        feedbackController: widget.feedbackController,
        onOpenFeedback: widget.feedbackController == null
            ? null
            : _openFeedbackCapture,
        themeMode: widget.themeMode,
        contrastMode: widget.contrastMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onContrastModeChanged: widget.onContrastModeChanged,
        onSignOut: widget.onSignOut,
        onAddProject: () => _openEditor(initialKind: PlannerEntityKind.project),
        onAddArea: () => _openEditor(initialKind: PlannerEntityKind.area),
      ),
    ];

    final composedPages =
        tier == _WorkspaceLayoutTier.expanded && workspaceConstraints != null
        ? pages.indexed
              .map(
                (entry) => entry.$1 == _PerfectDestination.today.index
                    ? entry.$2
                    : _expandedDestinationFrame(
                        context,
                        destination: _PerfectDestination.values[entry.$1],
                        page: entry.$2,
                        constraints: workspaceConstraints,
                      ),
              )
              .toList(growable: false)
        : pages;

    return PageStorage(
      bucket: _destinationPageStorage,
      child: PerfectPersistentDestinationHost(
        key: _destinationHostKey,
        selectedIndex: _destination.index,
        direction: _navigationDirection,
        children: composedPages.indexed
            .map(
              (entry) => PerfectMotionEntryScope(
                entryKey:
                    '${_PerfectDestination.values[entry.$1].name}-${_destination == _PerfectDestination.values[entry.$1]}',
                child: entry.$2,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _todaySurface({
    required _WorkspaceLayoutTier tier,
    required bool shortLandscape,
  }) {
    final now = widget.now().toLocal();
    return switch (tier) {
      _WorkspaceLayoutTier.compact => _TodayPage(
        controller: widget.controller,
        nowProvider: widget.now,
        ownerDisplayName: widget.ownerDisplayName,
        items: _todayItems,
        eligibilityById: _displayTodayEligibility,
        habitSummaryById: _displayHabitSummaries,
        taskProgressById: _displayTaskProgress,
        projectionResolved: _isTodayProjectionResolved,
        onInspect: _inspect,
        onAdd: _openEditor,
        onOpenPlan: () => _selectDestination(_PerfectDestination.plan.index),
        shortLandscape: shortLandscape,
      ),
      _WorkspaceLayoutTier.medium => _MediumTodayDeck(
        controller: widget.controller,
        now: now,
        items: _todayItems,
        eligibilityById: _displayTodayEligibility,
        habitSummaryById: _displayHabitSummaries,
        taskProgressById: _displayTaskProgress,
        projectionResolved: _isTodayProjectionResolved,
        nowProvider: widget.now,
        onInspect: _inspect,
        onAdd: _openEditor,
        onOpenPlan: () => _selectDestination(_PerfectDestination.plan.index),
        shortLandscape: shortLandscape,
      ),
      _WorkspaceLayoutTier.expanded => _ExpandedTodayDeck(
        controller: widget.controller,
        now: now,
        items: _todayItems,
        eligibilityById: _displayTodayEligibility,
        habitSummaryById: _displayHabitSummaries,
        taskProgressById: _displayTaskProgress,
        projectionResolved: _isTodayProjectionResolved,
        nowProvider: widget.now,
        inspected: _destination == _PerfectDestination.today
            ? _inspected
            : null,
        onInspect: _inspect,
        onAdd: _openEditor,
        onOpenPlan: () => _selectDestination(_PerfectDestination.plan.index),
        onEditInspected: () => _openEditor(existing: _inspected),
        onClearInspection: () => setState(() => _inspected = null),
      ),
    };
  }

  Widget _expandedDestinationFrame(
    BuildContext context, {
    required _PerfectDestination destination,
    required Widget page,
    required BoxConstraints constraints,
  }) {
    final inspected = _inspected;
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    const dividerWidth = 48.0;
    const minInspectorWidth = 300.0;
    const maxInspectorWidth = 460.0;
    final availableInspectorWidth = math.min(
      maxInspectorWidth,
      constraints.maxWidth -
          PerfectResponsiveGeometry.mediumContentThreshold -
          dividerWidth,
    );
    final canHostInspector =
        destination == _destination &&
        availableInspectorWidth >= minInspectorWidth &&
        textScale < 1.5;
    if (!canHostInspector) return page;

    final inspectorWidth =
        (_inspectorWidthOverride ?? constraints.maxWidth * .29)
            .clamp(minInspectorWidth, availableInspectorWidth)
            .toDouble();
    return Stack(
      children: [
        Positioned.fill(child: page),
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: 0,
          width: inspectorWidth + dividerWidth,
          child: _InspectorMotionPane(
            entity: inspected,
            width: inspectorWidth,
            dividerWidth: dividerWidth,
            minWidth: minInspectorWidth,
            maxWidth: availableInspectorWidth,
            controller: widget.controller,
            onResize: (value) {
              if ((_inspectorWidthOverride ?? inspectorWidth) == value) return;
              setState(() => _inspectorWidthOverride = value);
            },
            onEdit: () => _openEditor(existing: inspected),
            onReveal: _inspect,
            onClear: () => setState(() => _inspected = null),
          ),
        ),
      ],
    );
  }

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

  Map<String, PlannerTaskProgress> get _displayTaskProgress {
    final now = widget.now().toLocal();
    if (_resolvedTodayProjection == _todayProjectionSignature(now)) {
      return _todayTaskProgressById;
    }
    return const <String, PlannerTaskProgress>{};
  }

  bool get _isTodayProjectionResolved {
    final now = widget.now().toLocal();
    return _resolvedTodayProjection == _todayProjectionSignature(now);
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
          PlannerTaskProgress? taskProgress;
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
          } else if (entity.kind == PlannerEntityKind.oneOffTask ||
              entity.kind == PlannerEntityKind.recurringTask) {
            try {
              taskProgress = await widget.controller.taskProgressForDay(
                entity,
                localDay: day,
              );
            } on Object {
              // Preserve the visible Today projection when the optional daily
              // occurrence read is unavailable. The entity value is a safe
              // one-off fallback and pending for unresolved recurrence.
              taskProgress = entity.kind == PlannerEntityKind.recurringTask
                  ? const PlannerTaskProgress.pending()
                  : PlannerTaskProgress.fromEntity(entity);
            }
          }
          return (entity, eligibility, summary, taskProgress);
        }),
      );
      if (!mounted || _requestedTodayProjection != signature) return;
      final eligible = <PlannerEntity>[];
      final byId = <String, PlannerTodayEligibility>{};
      final habitSummaries = <String, PlannerHabitDaySummary>{};
      final taskProgress = <String, PlannerTaskProgress>{};
      for (final (entity, result, summary, progress) in results) {
        byId[entity.id] = result;
        if (summary != null) habitSummaries[entity.id] = summary;
        if (progress != null) taskProgress[entity.id] = progress;
        if (result.isEligible) eligible.add(entity);
      }
      final stream = PlannerTodayStream.project(
        entities: eligible,
        day: day,
        eligibilityById: byId,
        taskProgressById: taskProgress,
        habitSummaryById: habitSummaries,
      );
      setState(() {
        _resolvedTodayProjection = signature;
        _projectedTodayItems = stream.entries
            .map((entry) => entry.entity)
            .toList(growable: false);
        _todayEligibilityById = byId;
        _habitDaySummaryById = habitSummaries;
        _todayTaskProgressById = taskProgress;
      });
    } on Object {
      if (!mounted || _requestedTodayProjection != signature) return;
      final fallback = _todayItemsFor(widget.controller, now: day);
      setState(() {
        _resolvedTodayProjection = signature;
        _projectedTodayItems = fallback;
        _todayEligibilityById = const <String, PlannerTodayEligibility>{};
        _habitDaySummaryById = const <String, PlannerHabitDaySummary>{};
        _todayTaskProgressById = const <String, PlannerTaskProgress>{};
      });
    }
  }

  void _selectDestination(int value) {
    final next = _PerfectDestination.values[value];
    if (next == _destination) return;
    if (_destination == _PerfectDestination.today &&
        next != _PerfectDestination.today) {
      // Today alone owns capture. Preserve its controller-backed draft, but
      // close the spatial context before the composer leaves the shell.
      _quickCaptureDockKey.currentState?.collapse();
    }
    if (next != _PerfectDestination.today && _aiOpen) {
      _aiDockKey.currentState?.close();
    }
    setState(() {
      _navigationDirection = value >= _destination.index ? 1 : -1;
      _destination = next;
      _inspected = null;
    });
  }

  void _toggleAi() => _aiDockKey.currentState?.toggleOpen();

  void _openAiVoice() => unawaited(_aiDockKey.currentState?.openVoice());

  void _openFeedbackCapture() {
    unawaited(_feedbackOverlayController.open());
  }

  void _focusQuickCapture() {
    final dock = _quickCaptureDockKey.currentState;
    if (dock != null) {
      dock.expandAndFocus();
      return;
    }
    if (_quickCaptureFocusNode.context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _quickCaptureDockKey.currentState?.expandAndFocus();
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
    if (_aiOpen) {
      _aiDockKey.currentState?.close();
      return;
    }
    if (_inspected != null) {
      setState(() => _inspected = null);
      return;
    }
    final capture = _quickCaptureDockKey.currentState;
    if (capture?.isExpanded == true) {
      capture!.collapse();
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
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        (_aiOpen ||
            _inspected != null ||
            _quickCaptureDockKey.currentState?.isExpanded == true)) {
      _dismissLocalContext();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyF &&
        keyboard.isControlPressed &&
        keyboard.isShiftPressed) {
      _openFocusFromShortcut();
      return true;
    }
    return false;
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

class _InspectorMotionPane extends StatelessWidget {
  const _InspectorMotionPane({
    required this.entity,
    required this.width,
    required this.dividerWidth,
    required this.minWidth,
    required this.maxWidth,
    required this.controller,
    required this.onResize,
    required this.onEdit,
    required this.onReveal,
    required this.onClear,
  });

  final PlannerEntity? entity;
  final double width;
  final double dividerWidth;
  final double minWidth;
  final double maxWidth;
  final PlannerWorkspaceController controller;
  final ValueChanged<double> onResize;
  final VoidCallback onEdit;
  final ValueChanged<PlannerEntity> onReveal;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final current = entity;
    final direction = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    final inspectorAlignment = direction == 1
        ? Alignment.centerRight
        : Alignment.centerLeft;
    return IgnorePointer(
      ignoring: current == null,
      child: PerfectMotionSwitcher(
        kind: PerfectTransitionKind.sharedAxisHorizontal,
        direction: direction,
        duration: PerfectMotion.route,
        reverseDuration: PerfectMotion.standard,
        alignment: inspectorAlignment,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          alignment: inspectorAlignment,
          children: <Widget>[...previousChildren, ?currentChild],
        ),
        child: current == null
            ? const SizedBox.expand(
                key: ValueKey<String>('perfect-inspector-motion-closed'),
              )
            : Row(
                key: ValueKey<String>('perfect-inspector-motion-${current.id}'),
                children: [
                  _PaneDivider(
                    value: width,
                    min: minWidth,
                    max: maxWidth,
                    onChanged: onResize,
                  ),
                  SizedBox(
                    key: const ValueKey<String>('perfect-inspector-pane'),
                    width: width,
                    child: _Inspector(
                      entity: current,
                      controller: controller,
                      onEdit: onEdit,
                      onReveal: onReveal,
                      onClear: onClear,
                    ),
                  ),
                ],
              ),
      ),
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

enum _DestinationNavigationAxis { horizontal, vertical }

class _MoveDestinationIntent extends Intent {
  const _MoveDestinationIntent.delta(this.delta) : target = null;

  const _MoveDestinationIntent.target(this.target) : delta = null;

  final int? delta;
  final int? target;
}

class _DestinationKeyboardScope extends StatefulWidget {
  const _DestinationKeyboardScope({
    super.key,
    required this.axis,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
  });

  final _DestinationNavigationAxis axis;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  State<_DestinationKeyboardScope> createState() =>
      _DestinationKeyboardScopeState();
}

class _DestinationKeyboardScopeState extends State<_DestinationKeyboardScope> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Perfect destination keyboard scope',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.home):
          const _MoveDestinationIntent.target(0),
      const SingleActivator(LogicalKeyboardKey.end):
          _MoveDestinationIntent.target(_destinations.length - 1),
      if (widget.axis == _DestinationNavigationAxis.horizontal) ...{
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            _MoveDestinationIntent.delta(rtl ? 1 : -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            _MoveDestinationIntent.delta(rtl ? -1 : 1),
      } else ...{
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const _MoveDestinationIntent.delta(-1),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const _MoveDestinationIntent.delta(1),
      },
    };
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _MoveDestinationIntent: CallbackAction<_MoveDestinationIntent>(
            onInvoke: (intent) {
              final target =
                  intent.target ??
                  (widget.selectedIndex + intent.delta!).clamp(
                    0,
                    _destinations.length - 1,
                  );
              if (target != widget.selectedIndex) {
                widget.onSelected(target);
              }
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _focusNode.requestFocus(),
            child: FocusTraversalGroup(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _AdjustPaneIntent extends Intent {
  const _AdjustPaneIntent(this.delta);

  final double delta;
}

class _PaneDivider extends StatefulWidget {
  const _PaneDivider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<_PaneDivider> createState() => _PaneDividerState();
}

class _PaneDividerState extends State<_PaneDivider> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Perfect inspector pane divider',
  );
  bool _hovered = false;
  bool _focused = false;
  bool _dragging = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _adjust(double delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    widget.onChanged(next.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final active = _hovered || _focused || _dragging;
    final duration = PerfectMotion.responsive(context, PerfectMotion.quick);
    return Semantics(
      key: const ValueKey<String>('perfect-inspector-divider'),
      container: true,
      focusable: true,
      label: 'Resize inspector pane',
      value: '${widget.value.round()} pixels',
      increasedValue: '${widget.max.round()} pixels maximum',
      decreasedValue: '${widget.min.round()} pixels minimum',
      onIncrease: () => _adjust(24),
      onDecrease: () => _adjust(-24),
      child: FocusableActionDetector(
        focusNode: _focusNode,
        mouseCursor: SystemMouseCursors.resizeColumn,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowLeft):
              _AdjustPaneIntent(rtl ? -16 : 16),
          const SingleActivator(LogicalKeyboardKey.arrowRight):
              _AdjustPaneIntent(rtl ? 16 : -16),
        },
        actions: <Type, Action<Intent>>{
          _AdjustPaneIntent: CallbackAction<_AdjustPaneIntent>(
            onInvoke: (intent) {
              _adjust(intent.delta);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _focusNode.requestFocus(),
          onHorizontalDragStart: (_) {
            _focusNode.requestFocus();
            setState(() => _dragging = true);
          },
          onHorizontalDragUpdate: (details) {
            _adjust(details.delta.dx * (rtl ? 1 : -1));
          },
          onHorizontalDragEnd: (_) => setState(() => _dragging = false),
          onHorizontalDragCancel: () => setState(() => _dragging = false),
          child: SizedBox(
            width: 48,
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                curve: PerfectMotion.productive,
                width: active ? 4 : 2,
                height: active ? 76 : 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: active
                        ? <Color>[
                            PerfectSemanticTheme.of(context).primary,
                            PerfectSemanticTheme.of(context).tertiary,
                          ]
                        : <Color>[
                            scheme.outlineVariant.withValues(alpha: .36),
                            scheme.outlineVariant.withValues(alpha: .78),
                          ],
                  ),
                  boxShadow: active
                      ? <BoxShadow>[
                          BoxShadow(
                            color: PerfectSemanticTheme.of(
                              context,
                            ).tertiary.withValues(alpha: .22),
                            blurRadius: 14,
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

class _ShortLandscapeNavigationRail extends StatelessWidget {
  const _ShortLandscapeNavigationRail({
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
    final media = MediaQuery.of(context);
    final viewportHeight = math.max(
      0.0,
      media.size.height - media.padding.vertical,
    );
    final labelScale = media.textScaler.scale(14) / 14;
    final destinationExtent = 56.0 * labelScale.clamp(1.0, 1.5).toDouble();
    final leadingExtent =
        PerfectSpace.md + 40 + PerfectSpace.xs + 48 + PerfectSpace.md;
    final contentHeight =
        PerfectSpace.xl * 2 +
        leadingExtent +
        _destinations.length * destinationExtent;

    return SizedBox(
      height: viewportHeight,
      child: SingleChildScrollView(
        key: const ValueKey<String>('perfect-short-navigation-scroll'),
        child: SizedBox(
          height: math.max(viewportHeight, contentHeight),
          child: _NavigationRail(
            selected: selected,
            onSelect: onSelect,
            extended: extended,
            onToggleExtended: onToggleExtended,
          ),
        ),
      ),
    );
  }
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
          188.0,
          224.0,
        );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
      child: ClipRect(
        child: AnimatedContainer(
          key: const ValueKey<String>('perfect-navigation-rail-layout'),
          duration: duration,
          curve: PerfectMotion.productive,
          width: extended ? expandedWidth : 76,
          child: PerfectGlassSurface(
            borderRadius: const BorderRadius.all(
              Radius.circular(PerfectRadius.dock),
            ),
            blur: 22,
            strength: PerfectGlassStrength.strong,
            child: Material(
              color: Colors.transparent,
              child: _DestinationKeyboardScope(
                key: const ValueKey<String>('perfect-rail-keyboard-scope'),
                axis: _DestinationNavigationAxis.vertical,
                selectedIndex: selected.index,
                onSelected: onSelect,
                child: NavigationRail(
                  extended: extended,
                  minExtendedWidth: expandedWidth,
                  minWidth: 76,
                  backgroundColor: Colors.transparent,
                  groupAlignment: -.18,
                  selectedIndex: selected.index,
                  onDestinationSelected: onSelect,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: PerfectSpace.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: duration,
                          switchInCurve: PerfectMotion.enter,
                          switchOutCurve: PerfectMotion.exit,
                          child: extended
                              ? const SizedBox(
                                  key: ValueKey<String>('rail-wordmark'),
                                  width: 168,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: PerfectWordmark(
                                      fontSize: 25,
                                      includeMark: true,
                                    ),
                                  ),
                                )
                              : const PerfectMark(
                                  key: ValueKey<String>('rail-mark'),
                                  size: 40,
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
                            icon: AnimatedRotation(
                              turns: extended ? .5 : 0,
                              duration: duration,
                              curve: PerfectMotion.productive,
                              child: const Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: _destinations.indexed
                      .map(
                        (entry) => NavigationRailDestination(
                          padding: const EdgeInsets.symmetric(vertical: 2),
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
            ),
          ),
        ),
      ),
    );
  }
}

String _headerSupportText(_PerfectDestination destination) =>
    switch (destination) {
      _PerfectDestination.today => 'Your live day, at a glance',
      _PerfectDestination.tasks => 'Capture, shape, and finish the work',
      _PerfectDestination.plan => 'Make time visible before it fills up',
      _PerfectDestination.habits => 'Build the rhythm, not the pressure',
      _PerfectDestination.more => 'Your workspace, rules, and data',
    };

class _WorkspaceComposerStack extends StatelessWidget {
  const _WorkspaceComposerStack({required this.aiPanel, required this.capture});

  final Widget aiPanel;
  final Widget capture;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Column(mainAxisSize: MainAxisSize.min, children: [aiPanel, capture]),
  );
}

class _CompactWorkspaceFooter extends StatelessWidget {
  const _CompactWorkspaceFooter({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: PerfectSpace.xs),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            PerfectSpace.sm,
            2,
            PerfectSpace.sm,
            0,
          ),
          child: PerfectGlassSurface(
            surfaceKey: const ValueKey<String>('perfect-compact-glass-footer'),
            borderRadius: const BorderRadius.all(
              Radius.circular(PerfectRadius.panel),
            ),
            blur: 24,
            strength: PerfectGlassStrength.strong,
            child: NavigationBarTheme(
              key: const ValueKey<String>('perfect-compact-navigation-theme'),
              data: theme.navigationBarTheme.copyWith(
                // The Material indicator stays disabled. Perfect paints a
                // compact prismatic tile, not the stock stadium.
                indicatorColor: Colors.transparent,
                indicatorShape: const StadiumBorder(),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: <Color>[
                      PerfectSemanticTheme.of(
                        context,
                      ).surfaceLowest.withValues(alpha: .20),
                      theme.colorScheme.surface.withValues(alpha: .06),
                      PerfectSemanticTheme.of(
                        context,
                      ).tertiaryContainer.withValues(alpha: .09),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: _DestinationKeyboardScope(
                    key: const ValueKey<String>(
                      'perfect-footer-keyboard-scope',
                    ),
                    axis: _DestinationNavigationAxis.horizontal,
                    selectedIndex: selectedIndex,
                    onSelected: onDestinationSelected,
                    child: NavigationBar(
                      key: const ValueKey<String>('perfect-compact-navigation'),
                      height: 68,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysHide,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      destinations: _destinations
                          .map(
                            (destination) => NavigationDestination(
                              key: ValueKey<String>(
                                'perfect-footer-${destination.name}',
                              ),
                              tooltip: destination.label,
                              icon: _CompactDestinationGlyph(
                                destination: destination,
                                selected: false,
                              ),
                              selectedIcon: _CompactDestinationGlyph(
                                destination: destination,
                                selected: true,
                              ),
                              label: destination.label,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactDestinationGlyph extends StatelessWidget {
  const _CompactDestinationGlyph({
    required this.destination,
    required this.selected,
  });

  final _PerfectDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _destinationAccent(context, destination);
    final companion = _destinationCompanion(context, destination);
    final duration = PerfectMotion.responsive(context, PerfectMotion.standard);
    final icon = selected ? destination.selectedIcon : destination.icon;

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        key: selected
            ? ValueKey<String>('perfect-footer-selected-${destination.name}')
            : null,
        tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
        duration: duration,
        curve: PerfectMotion.modalEnter,
        builder: (context, progress, child) => SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 2 - progress * 4),
                  child: Transform.scale(
                    scale: .76 + progress * .24,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: ShapeDecoration(
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: PerfectContrast.of(context)
                                ? PerfectSemanticTheme.of(context).outline
                                : PerfectSemanticTheme.of(
                                    context,
                                  ).surfaceLowest.withValues(alpha: .88),
                            width: 1.2,
                          ),
                        ),
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: <Color>[
                            accent.withValues(alpha: .34),
                            companion.withValues(alpha: .22),
                            scheme.surface.withValues(alpha: .92),
                          ],
                          stops: const <double>[0, .56, 1],
                        ),
                        shadows: <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(alpha: .24),
                            blurRadius: 18,
                            spreadRadius: -3,
                            offset: const Offset(0, 7),
                          ),
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: .08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: const Alignment(-.58, -.62),
                        child: Container(
                          width: 14,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              colors: <Color>[
                                PerfectSemanticTheme.of(
                                  context,
                                ).surfaceLowest.withValues(alpha: .78),
                                PerfectSemanticTheme.of(
                                  context,
                                ).surfaceLowest.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, selected ? -2.3 * progress : 0),
                child: Transform.scale(
                  scale: selected ? .88 + progress * .12 : 1,
                  child: Icon(
                    icon,
                    size: selected ? 24 : 23,
                    color: selected
                        ? PerfectSemanticTheme.of(context).ink
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (selected)
                PositionedDirectional(
                  bottom: -1,
                  child: Opacity(
                    opacity: progress,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            accent,
                            accent.withValues(alpha: .12),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(alpha: .45),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: const SizedBox.square(dimension: 5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _destinationAccent(
  BuildContext context,
  _PerfectDestination destination,
) {
  final semantic = PerfectSemanticTheme.of(context);
  return switch (destination) {
    _PerfectDestination.today => semantic.primary,
    _PerfectDestination.tasks => semantic.sync,
    _PerfectDestination.plan => semantic.tertiary,
    _PerfectDestination.habits => semantic.secondary,
    _PerfectDestination.more => semantic.tertiary,
  };
}

Color _destinationCompanion(
  BuildContext context,
  _PerfectDestination destination,
) {
  final semantic = PerfectSemanticTheme.of(context);
  return switch (destination) {
    _PerfectDestination.today => semantic.tertiary,
    _PerfectDestination.tasks => semantic.secondary,
    _PerfectDestination.plan => semantic.primary,
    _PerfectDestination.habits => semantic.tertiary,
    _PerfectDestination.more => semantic.sync,
  };
}

class _QuickCaptureDock extends StatefulWidget {
  const _QuickCaptureDock({
    super.key,
    required this.controller,
    required this.onOpenEditor,
    required this.captureController,
    required this.focusNode,
    this.desktop = false,
    this.aiAvailable = false,
    this.aiOpen = false,
    this.onToggleAi,
    this.onOpenAiVoice,
  });

  final PlannerWorkspaceController controller;
  final VoidCallback onOpenEditor;
  final TextEditingController captureController;
  final FocusNode focusNode;
  final bool desktop;
  final bool aiAvailable;
  final bool aiOpen;
  final VoidCallback? onToggleAi;
  final VoidCallback? onOpenAiVoice;

  @override
  State<_QuickCaptureDock> createState() => _QuickCaptureDockState();
}

class _QuickCaptureDockState extends State<_QuickCaptureDock>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: PerfectMotion.heartbeat,
  );
  Timer? _heartbeatTimer;
  bool _sending = false;
  bool _hovered = false;
  bool _fieldFocused = false;
  bool _expanded = false;
  bool _reduceMotion = false;
  bool _foreground = true;

  TextEditingController get _capture => widget.captureController;
  bool get isExpanded => _expanded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fieldFocused = widget.focusNode.hasFocus;
    _expanded = _fieldFocused || _capture.text.trim().isNotEmpty;
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPulseAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = PerfectMotion.reduced(context);
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant _QuickCaptureDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _fieldFocused = widget.focusNode.hasFocus;
      _expanded =
          _fieldFocused ||
          _expanded ||
          widget.captureController.text.trim().isNotEmpty;
      widget.focusNode.addListener(_handleFocusChanged);
    }
    _syncPulseAnimation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.focusNode.removeListener(_handleFocusChanged);
    _heartbeatTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    final focused = widget.focusNode.hasFocus;
    setState(() {
      _fieldFocused = focused;
      if (focused) _expanded = true;
    });
    _syncPulseAnimation();
  }

  void _syncPulseAnimation() {
    if (!mounted) return;
    final shouldPulse =
        !_expanded &&
        !_reduceMotion &&
        _foreground &&
        TickerMode.valuesOf(context).enabled;
    if (shouldPulse) {
      if (!_pulseController.isAnimating && _heartbeatTimer == null) {
        _playHeartbeat();
      }
    } else {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  void _playHeartbeat() {
    if (!mounted ||
        _expanded ||
        _reduceMotion ||
        !_foreground ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    _pulseController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pulseController.value = 0;
      if (_expanded ||
          _reduceMotion ||
          !_foreground ||
          !TickerMode.valuesOf(context).enabled) {
        return;
      }
      _heartbeatTimer = Timer(PerfectMotion.heartbeatRest, () {
        _heartbeatTimer = null;
        _playHeartbeat();
      });
    });
  }

  void expandAndFocus() {
    _expand();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.focusNode.requestFocus();
    });
  }

  void _expand() {
    if (!_expanded) setState(() => _expanded = true);
    _syncPulseAnimation();
  }

  void _collapse() {
    widget.focusNode.unfocus();
    if (_expanded) setState(() => _expanded = false);
    _syncPulseAnimation();
  }

  void collapse() => _collapse();

  void _openFullEditor() {
    _collapse();
    widget.onOpenEditor();
  }

  @override
  Widget build(BuildContext context) {
    final bodySize =
        DefaultTextStyle.of(context).style.fontSize ??
        Theme.of(context).textTheme.bodyLarge?.fontSize ??
        16;
    final effectiveTextScale =
        MediaQuery.textScalerOf(context).scale(bodySize) / bodySize;
    final duration = PerfectMotion.responsive(context, PerfectMotion.quick);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final hintText = widget.desktop
            ? 'Capture a task, before it disappears…'
            : effectiveTextScale >= 1.35
            ? 'New task…'
            : 'Capture a task…';
        final horizontalPadding = widget.desktop
            ? PerfectSpace.xl
            : PerfectSpace.xxs;
        final maxDockWidth = widget.desktop
            ? math.min(980.0, availableWidth - horizontalPadding * 2)
            : math.max(0.0, availableWidth - horizontalPadding * 2);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            _expanded ? 4 : 10,
            horizontalPadding,
            6,
          ),
          child: Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxDockWidth),
              child: TapRegion(
                onTapOutside: (_) => _collapse(),
                child: _MotionAwareAnimatedSize(
                  alignment: AlignmentDirectional.bottomCenter,
                  duration: PerfectMotion.responsive(
                    context,
                    PerfectMotion.emphasized,
                  ),
                  curve: PerfectMotion.modalEnter,
                  clipBehavior: Clip.none,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(
                      _expanded
                          ? 'quick-capture-one-surface-expanded'
                          : 'quick-capture-one-surface-collapsed',
                    ),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: PerfectMotion.responsive(
                      context,
                      _expanded
                          ? PerfectMotion.emphasized
                          : PerfectMotion.quick,
                    ),
                    curve: PerfectMotion.modalEnter,
                    // This is intentionally a one-child morph. AnimatedSwitcher
                    // retains the outgoing subtree even with a custom layout;
                    // that doubled the compositor load and could terminate a
                    // SwiftShader emulator. Size, fade, rise and scale remain,
                    // but only the current dock is ever painted.
                    builder: (context, progress, child) {
                      if (_reduceMotion) return child!;
                      return Opacity(
                        opacity: progress,
                        child: Transform.translate(
                          offset: Offset(0, (1 - progress) * 10),
                          child: Transform.scale(
                            alignment: Alignment.bottomCenter,
                            scale: .96 + progress * .04,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _expanded
                        ? _buildExpandedComposer(
                            context,
                            key: const ValueKey<String>(
                              'quick-capture-expanded',
                            ),
                            maxWidth: maxDockWidth,
                            effectiveTextScale: effectiveTextScale,
                            hintText: hintText,
                            duration: duration,
                          )
                        : _buildCollapsedLauncher(
                            context,
                            key: const ValueKey<String>(
                              'quick-capture-collapsed',
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedLauncher(BuildContext context, {required Key key}) {
    final scheme = Theme.of(context).colorScheme;
    final hasDraft = _capture.text.trim().isNotEmpty;
    return MouseRegion(
      key: key,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final phase = _pulseController.value;
          final first = math.exp(-math.pow((phase - .18) / .055, 2));
          final second = math.exp(-math.pow((phase - .31) / .045, 2));
          final heartbeat = _reduceMotion ? 0.0 : first * .72 + second;
          final scale = 1 + heartbeat * .046 + (_hovered ? .035 : 0);
          return Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: PerfectSemanticTheme.of(
                      context,
                    ).sync.withValues(alpha: .10 + heartbeat * .08),
                    blurRadius: 14 + heartbeat * 10,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: PerfectSemanticTheme.of(
                      context,
                    ).tertiary.withValues(alpha: .10 + heartbeat * .07),
                    blurRadius: 18 + heartbeat * 8,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: PerfectGlassSurface(
                surfaceKey: const ValueKey<String>(
                  'perfect-quick-capture-surface',
                ),
                borderRadius: const BorderRadius.all(Radius.circular(999)),
                strength: PerfectGlassStrength.soft,
                enableBlur: false,
                tint: scheme.surface.withValues(alpha: .94),
                borderColor: PerfectContrast.of(context)
                    ? PerfectSemanticTheme.of(context).outline
                    : PerfectSemanticTheme.of(
                        context,
                      ).surfaceLowest.withValues(alpha: .68),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey<String>('perfect-quick-capture-toggle'),
                    customBorder: const CircleBorder(),
                    onTap: _expand,
                    child: SizedBox.square(
                      dimension: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  PerfectSemanticTheme.of(
                                    context,
                                  ).secondary.withValues(alpha: .92),
                                  PerfectSemanticTheme.of(
                                    context,
                                  ).tertiary.withValues(alpha: .96),
                                ],
                              ),
                            ),
                            child: const SizedBox.square(
                              dimension: 54,
                              child: Center(
                                child: PerfectPictogram(
                                  name: 'capture',
                                  size: 30,
                                  semanticLabel: 'Open quick capture',
                                ),
                              ),
                            ),
                          ),
                          if (hasDraft)
                            PositionedDirectional(
                              top: 5,
                              end: 5,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: PerfectSemanticTheme.of(
                                    context,
                                  ).primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedComposer(
    BuildContext context, {
    required Key key,
    required double maxWidth,
    required double effectiveTextScale,
    required String hintText,
    required Duration duration,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final stacked = maxWidth < 620 || effectiveTextScale >= 1.25;
    final showOptionLabels =
        effectiveTextScale < 1.42 &&
        (stacked ? maxWidth >= 350 : maxWidth >= 740);
    final showIdentitySupport = effectiveTextScale < 1.32 && maxWidth >= 350;
    final field = _buildCaptureField(
      context,
      hintText: hintText,
      duration: duration,
    );
    final collapse = IconButton(
      key: const ValueKey<String>('perfect-quick-capture-collapse'),
      tooltip: 'Collapse quick capture',
      onPressed: _collapse,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        shape: const CircleBorder(),
        backgroundColor: scheme.surface.withValues(alpha: .62),
        foregroundColor: scheme.onSurfaceVariant,
        side: BorderSide(color: scheme.outline.withValues(alpha: .20)),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 23),
    );
    final send = _buildSendAction(context, duration: duration);
    final plan = _CaptureOptionButton(
      key: const ValueKey<String>('perfect-capture-plan'),
      tooltip: widget.desktop
          ? 'Plan a task or habit (Ctrl+N)'
          : 'Plan a task or habit',
      label: 'Plan',
      tone: _CaptureOptionTone.plan,
      showLabel: showOptionLabels,
      vertical: stacked,
      onPressed: _openFullEditor,
      icon: const PerfectPictogram(
        name: 'calendar',
        size: 23,
        semanticLabel: 'Plan a task or habit',
      ),
    );
    final ai = _CaptureOptionButton(
      key: const ValueKey<String>('perfect-ai-toggle'),
      tooltip: widget.aiOpen ? 'Close Perfect AI' : 'Ask Perfect AI',
      label: 'Perfect AI',
      tone: _CaptureOptionTone.ai,
      selected: widget.aiOpen,
      showLabel: showOptionLabels,
      vertical: stacked,
      onPressed: widget.onToggleAi,
      icon: const PerfectPictogram(
        name: 'ai',
        size: 28,
        semanticLabel: 'Perfect AI',
      ),
    );
    final voice = _CaptureOptionButton(
      key: const ValueKey<String>('perfect-ai-voice-toggle'),
      tooltip: 'Start a private voice note with Perfect AI',
      label: 'Voice',
      tone: _CaptureOptionTone.voice,
      showLabel: showOptionLabels,
      vertical: stacked,
      onPressed: widget.onOpenAiVoice,
      icon: const PerfectPictogram(
        name: 'voice',
        size: 24,
        semanticLabel: 'Voice with Perfect AI',
      ),
    );
    final options = <Widget>[
      plan,
      if (widget.aiAvailable) ai,
      if (widget.aiAvailable) voice,
    ];
    final compactActionShelf = SizedBox(
      key: const ValueKey<String>('perfect-capture-action-shelf'),
      child: Row(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            if (index > 0) const SizedBox(width: 7),
            Expanded(child: options[index]),
          ],
        ],
      ),
    );
    final identity = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: <Color>[
                PerfectSemanticTheme.of(
                  context,
                ).secondaryContainer.withValues(alpha: .92),
                PerfectSemanticTheme.of(
                  context,
                ).tertiaryContainer.withValues(alpha: .82),
              ],
            ),
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: PerfectContrast.of(context)
                    ? PerfectSemanticTheme.of(context).outline
                    : PerfectSemanticTheme.of(
                        context,
                      ).surfaceLowest.withValues(alpha: .76),
              ),
            ),
          ),
          child: const Center(
            child: PerfectPictogram(
              name: 'task',
              size: 23,
              semanticLabel: 'Quick capture',
            ),
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick capture',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.18,
                ),
              ),
              if (showIdentitySupport)
                Text(
                  'Type · plan · ask · speak',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return MouseRegion(
      key: key,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && !_fieldFocused ? 1.002 : 1,
        duration: duration,
        curve: PerfectMotion.productive,
        child: PerfectGlassSurface(
          surfaceKey: const ValueKey<String>('perfect-quick-capture-surface'),
          borderRadius: const BorderRadius.all(
            Radius.circular(PerfectRadius.dock),
          ),
          strength: PerfectGlassStrength.soft,
          // Animating a large BackdropFilter inside Scaffold.bottomNavigationBar
          // can balloon SwiftShader memory and stall low-end Android GPUs. The
          // authored tint, highlight border and inner gradients keep the glass
          // read without re-blurring the entire Today surface every frame.
          enableBlur: false,
          tint: scheme.surface.withValues(alpha: .94),
          borderColor: _fieldFocused
              ? PerfectSemanticTheme.of(context).focus
              : PerfectContrast.of(context)
              ? PerfectSemanticTheme.of(context).outline
              : PerfectSemanticTheme.of(
                  context,
                ).surfaceLowest.withValues(alpha: .58),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: <Color>[
                  PerfectSemanticTheme.of(
                    context,
                  ).secondaryContainer.withValues(alpha: .34),
                  scheme.surface.withValues(alpha: .18),
                  PerfectSemanticTheme.of(
                    context,
                  ).tertiaryContainer.withValues(alpha: .38),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child: identity),
                            const SizedBox(width: 8),
                            collapse,
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(child: field),
                            const SizedBox(width: 8),
                            send,
                          ],
                        ),
                        const SizedBox(height: 9),
                        compactActionShelf,
                      ],
                    )
                  : Row(
                      children: [
                        collapse,
                        const SizedBox(width: 8),
                        identity,
                        const SizedBox(width: PerfectSpace.md),
                        plan,
                        const SizedBox(width: PerfectSpace.xs),
                        Expanded(child: field),
                        const SizedBox(width: PerfectSpace.xs),
                        if (widget.aiAvailable) ...[
                          ai,
                          const SizedBox(width: 4),
                          voice,
                          const SizedBox(width: PerfectSpace.xs),
                        ],
                        send,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureField(
    BuildContext context, {
    required String hintText,
    required Duration duration,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.desktop ? 'Quick capture (Ctrl+K)' : 'Quick capture',
      child: AnimatedContainer(
        duration: duration,
        curve: PerfectMotion.productive,
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: _fieldFocused ? .94 : .70),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: _fieldFocused
                ? PerfectSemanticTheme.of(context).focus
                : scheme.outline.withValues(alpha: .25),
          ),
          boxShadow: _fieldFocused
              ? <BoxShadow>[
                  BoxShadow(
                    color: PerfectSemanticTheme.of(
                      context,
                    ).tertiary.withValues(alpha: .12),
                    blurRadius: 16,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: TextField(
          key: const ValueKey<String>('perfect_quick_capture'),
          controller: _capture,
          focusNode: widget.focusNode,
          maxLength: 160,
          textDirection: _directionForCapture(context, _capture.text),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            prefixIcon: const Center(
              child: PerfectPictogram(
                name: 'task',
                size: 20,
                semanticLabel: 'Write a quick task',
              ),
            ),
            prefixIconConstraints: const BoxConstraints.tightFor(
              width: 44,
              height: 44,
            ),
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: PerfectSpace.sm,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildSendAction(BuildContext context, {required Duration duration}) =>
      AnimatedSwitcher(
        duration: duration,
        switchInCurve: PerfectMotion.enter,
        switchOutCurve: PerfectMotion.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .86, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: _sending
            ? const Padding(
                key: ValueKey<String>('quick-capture-sending'),
                padding: EdgeInsets.all(15),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                key: ValueKey<bool>(_capture.text.trim().isNotEmpty),
                tooltip: _capture.text.trim().isEmpty
                    ? 'Type a task to save it'
                    : 'Save quick capture',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  foregroundColor: PerfectSemanticTheme.of(context).onTertiary,
                ),
                onPressed: _capture.text.trim().isEmpty
                    ? widget.focusNode.requestFocus
                    : _submit,
                icon: _CaptureActionDisc(
                  color: PerfectSemanticTheme.of(context).tertiary,
                  child: const PerfectPictogram(
                    name: 'send',
                    size: 23,
                    semanticLabel: 'Save quick capture',
                  ),
                ),
              ),
      );

  Future<void> _submit() async {
    final title = _capture.text.trim();
    if (title.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.controller.quickCapture(title);
      _capture.clear();
      widget.focusNode.unfocus();
      if (mounted) {
        setState(() => _expanded = false);
        _syncPulseAnimation();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Captured locally. Sync will follow.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _MotionAwareAnimatedSize extends StatelessWidget {
  const _MotionAwareAnimatedSize({
    required this.alignment,
    required this.duration,
    required this.curve,
    required this.clipBehavior,
    required this.child,
  });

  final AlignmentGeometry alignment;
  final Duration duration;
  final Curve curve;
  final Clip clipBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (PerfectMotion.reduced(context)) return child;
    return AnimatedSize(
      alignment: alignment,
      duration: duration,
      curve: curve,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

enum _CaptureOptionTone { plan, ai, voice }

class _CaptureOptionButton extends StatelessWidget {
  const _CaptureOptionButton({
    super.key,
    required this.tooltip,
    required this.label,
    required this.tone,
    required this.icon,
    required this.onPressed,
    this.showLabel = false,
    this.selected = false,
    this.vertical = false,
  });

  final String tooltip;
  final String label;
  final _CaptureOptionTone tone;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool showLabel;
  final bool selected;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = PerfectSemanticTheme.of(context);
    final accent = switch (tone) {
      _CaptureOptionTone.plan => semantic.primary,
      _CaptureOptionTone.ai => semantic.tertiary,
      _CaptureOptionTone.voice => semantic.sync,
    };
    final companion = switch (tone) {
      _CaptureOptionTone.plan => semantic.secondary,
      _CaptureOptionTone.ai => semantic.secondary,
      _CaptureOptionTone.voice => semantic.tertiary,
    };
    final radius = BorderRadius.circular(vertical ? 20 : 18);
    final duration = PerfectMotion.responsive(context, PerfectMotion.standard);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: AnimatedContainer(
          duration: duration,
          curve: PerfectMotion.productive,
          constraints: BoxConstraints(
            minWidth: 48,
            minHeight: vertical ? 66 : 48,
          ),
          decoration: BoxDecoration(
            color: selected ? null : accent.withValues(alpha: .075),
            gradient: selected
                ? LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: <Color>[
                      accent.withValues(alpha: .24),
                      companion.withValues(alpha: .15),
                      scheme.surface.withValues(alpha: .84),
                    ],
                  )
                : null,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: .44)
                  : accent.withValues(alpha: .18),
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: .14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: showLabel ? 8 : 4,
                  vertical: vertical ? 7 : 4,
                ),
                child: vertical
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CaptureOptionIconPlate(
                            accent: accent,
                            selected: selected,
                            icon: icon,
                          ),
                          if (showLabel) ...[
                            const SizedBox(height: 4),
                            _CaptureOptionLabel(
                              label: label,
                              selected: selected,
                            ),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CaptureOptionIconPlate(
                            accent: accent,
                            selected: selected,
                            icon: icon,
                          ),
                          if (showLabel) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: _CaptureOptionLabel(
                                label: label,
                                selected: selected,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureOptionIconPlate extends StatelessWidget {
  const _CaptureOptionIconPlate({
    required this.accent,
    required this.selected,
    required this.icon,
  });

  final Color accent;
  final bool selected;
  final Widget icon;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: PerfectMotion.responsive(context, PerfectMotion.standard),
    curve: PerfectMotion.productive,
    width: 36,
    height: 36,
    decoration: ShapeDecoration(
      color: selected
          ? Theme.of(context).colorScheme.surface.withValues(alpha: .88)
          : accent.withValues(alpha: .11),
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: selected ? .26 : .14)),
      ),
    ),
    child: Center(child: icon),
  );
}

class _CaptureOptionLabel extends StatelessWidget {
  const _CaptureOptionLabel({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.fade,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: selected
          ? Theme.of(context).colorScheme.onSurface
          : Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
      fontSize: 11.5,
    ),
  );
}

class _CaptureActionDisc extends StatelessWidget {
  const _CaptureActionDisc({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 42,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: .18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    ),
  );
}

/// The expanded Windows surface keeps one bounded orientation instrument above
/// a dominant, continuously actionable stream. Item detail joins only when the
/// live constraints can sustain it.
class _ExpandedTodayDeck extends StatelessWidget {
  const _ExpandedTodayDeck({
    required this.controller,
    required this.now,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.taskProgressById,
    required this.projectionResolved,
    required this.nowProvider,
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
  final Map<String, PlannerTaskProgress> taskProgressById;
  final bool projectionResolved;
  final PerfectNow nowProvider;
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
      final inlineInspector =
          inspected != null && contentWidth >= 1320 && textScale < 1.35;
      final lowHeight = constraints.maxHeight < 650;
      final visibleRows = math.min(items.length, 5);
      final rowHeight = textScale >= 1.45 ? 108.0 : 88.0;
      final streamHeight = (128 + visibleRows * rowHeight)
          .clamp(300.0, 620.0)
          .toDouble();
      final inspectorHeight = inspected == null
          ? 0.0
          : constraints.maxHeight >= 850
          ? 600.0
          : 420.0;
      final desiredStageHeight = math.max(streamHeight, inspectorHeight);
      final stageBudget = (constraints.maxHeight - 250)
          .clamp(lowHeight ? 300.0 : 340.0, 700.0)
          .toDouble();
      final stageHeight = math.min(desiredStageHeight, stageBudget);
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

      return CustomScrollView(
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
                  _DayDeckHeading(now: now),
                  const SizedBox(height: PerfectSpace.md),
                  PerfectStagedEntrance(
                    order: 1,
                    child: TodayPulse(
                      snapshot: TodayPulseSnapshot.fromPlanner(
                        items: items,
                        taskProgressById: taskProgressById,
                        habitSummaryById: habitSummaryById,
                        projectionResolved: projectionResolved,
                      ),
                      now: nowProvider,
                      onOpenPlan: onOpenPlan,
                    ),
                  ),
                  const SizedBox(height: PerfectSpace.lg),
                  SizedBox(
                    key: const ValueKey<String>('expanded-day-deck-stage'),
                    height: stageHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: inlineInspector ? 12 : 1,
                              child: _DayStreamPanel(
                                controller: controller,
                                items: items,
                                eligibilityById: eligibilityById,
                                habitSummaryById: habitSummaryById,
                                taskProgressById: taskProgressById,
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
                        if (inspected != null && !inlineInspector) ...[
                          Positioned.fill(
                            child: BlockSemantics(
                              child: Semantics(
                                button: true,
                                label: 'Close inspector and return to Today',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: onClearInspection,
                                  child: ColoredBox(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.scrim.withValues(alpha: .1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            key: const ValueKey<String>('expanded-focus-panel'),
                            top: 0,
                            end: 0,
                            bottom: 0,
                            width: floatingInspectorWidth,
                            child: inspectorPanel(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// The medium-width Today composition is intentionally its own surface.
///
/// A tablet is not a stretched phone and it is not a desktop with two narrow
/// fragments pinned to opposite corners. The bounded Today Pulse and operational
/// stream share one content axis and reflow without changing state.
class _MediumTodayDeck extends StatelessWidget {
  const _MediumTodayDeck({
    required this.controller,
    required this.now,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.taskProgressById,
    required this.projectionResolved,
    required this.nowProvider,
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
  final Map<String, PlannerTaskProgress> taskProgressById;
  final bool projectionResolved;
  final PerfectNow nowProvider;
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
        final lowHeight = constraints.maxHeight < 720;
        final visibleRows = math.min(items.length, 5);
        final rowHeight = textScale >= 1.45 ? 112.0 : 92.0;
        final desiredStageHeight = (128 + visibleRows * rowHeight)
            .clamp(270.0, 620.0)
            .toDouble();
        final verticalBudget = shortLandscape
            ? (constraints.maxHeight * .68).clamp(270.0, 420.0).toDouble()
            : (constraints.maxHeight - (lowHeight ? 280 : 320))
                  .clamp(290.0, 650.0)
                  .toDouble();
        final widthBudget = (contentWidth * .78).clamp(290.0, 650.0).toDouble();
        final stageHeight = math.min(
          desiredStageHeight,
          math.min(verticalBudget, widthBudget),
        );

        return CustomScrollView(
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
                    _DayDeckHeading(now: now),
                    const SizedBox(height: PerfectSpace.md),
                    PerfectStagedEntrance(
                      order: 1,
                      child: TodayPulse(
                        snapshot: TodayPulseSnapshot.fromPlanner(
                          items: items,
                          taskProgressById: taskProgressById,
                          habitSummaryById: habitSummaryById,
                          projectionResolved: projectionResolved,
                        ),
                        now: nowProvider,
                        onOpenPlan: onOpenPlan,
                        shortLandscape: shortLandscape,
                      ),
                    ),
                    const SizedBox(height: PerfectSpace.lg),
                    SizedBox(
                      key: const ValueKey<String>('medium-day-deck'),
                      height: stageHeight,
                      child: _DayStreamPanel(
                        controller: controller,
                        items: items,
                        eligibilityById: eligibilityById,
                        habitSummaryById: habitSummaryById,
                        taskProgressById: taskProgressById,
                        onInspect: onInspect,
                        onAdd: onAdd,
                        constrained: true,
                        dense: shortLandscape || lowHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayDeckHeading extends StatelessWidget {
  const _DayDeckHeading({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) => PerfectStagedEntrance(
    order: 0,
    duration: PerfectMotion.standard,
    rise: PerfectMotion.titleRise,
    child: Column(
      key: const ValueKey<String>('day-deck-heading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: PerfectSemanticTheme.of(context).muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: PerfectSpace.xxs),
        Text(
          _greeting(now),
          maxLines: 2,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
            height: 1.08,
          ),
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
    required this.taskProgressById,
    required this.onInspect,
    required this.onAdd,
    required this.constrained,
    required this.dense,
  });

  final PlannerWorkspaceController controller;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final Map<String, PlannerTaskProgress> taskProgressById;
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
        color: PerfectSemanticTheme.of(context).secondary,
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
          taskProgressById: taskProgressById,
          onInspect: onInspect,
        ),
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
            ? Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      key: const PageStorageKey<String>('day-stream-scroll'),
                      slivers: [
                        SliverList.list(children: body),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: PerfectSpace.sm),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: body,
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
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final Color color;

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
    ],
  );
}

class _DayStreamTimeline extends StatelessWidget {
  const _DayStreamTimeline({
    required this.controller,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.taskProgressById,
    required this.onInspect,
  });

  final PlannerWorkspaceController controller;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final Map<String, PlannerTaskProgress> taskProgressById;
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
                              color: _colorFor(context, entity),
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
                      taskProgress: taskProgressById[entity.id],
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
          Icon(
            Icons.wb_sunny_outlined,
            size: 34,
            color: PerfectSemanticTheme.of(context).primary,
          ),
          const SizedBox(height: PerfectSpace.xs),
          Text(
            'Your day has room.',
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
    required this.nowProvider,
    required this.ownerDisplayName,
    required this.items,
    required this.eligibilityById,
    required this.habitSummaryById,
    required this.taskProgressById,
    required this.projectionResolved,
    required this.onInspect,
    required this.onAdd,
    required this.onOpenPlan,
    required this.shortLandscape,
  });

  final PlannerWorkspaceController controller;
  final PerfectNow nowProvider;
  final String? ownerDisplayName;
  final List<PlannerEntity> items;
  final Map<String, PlannerTodayEligibility> eligibilityById;
  final Map<String, PlannerHabitDaySummary> habitSummaryById;
  final Map<String, PlannerTaskProgress> taskProgressById;
  final bool projectionResolved;
  final ValueChanged<PlannerEntity> onInspect;
  final VoidCallback onAdd;
  final VoidCallback onOpenPlan;
  final bool shortLandscape;

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey<String>('perfect-today-scroll'),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.fromLTRB(
      PerfectSpace.lg,
      0,
      PerfectSpace.lg,
      math.max(152, MediaQuery.paddingOf(context).bottom + 136),
    ),
    children: [
      PerfectStagedEntrance(
        order: 0,
        duration: PerfectMotion.standard,
        rise: PerfectMotion.titleRise,
        child: _CompactTodayIntro(
          now: nowProvider,
          ownerDisplayName: ownerDisplayName,
        ),
      ),
      const SizedBox(height: PerfectSpace.md),
      PerfectStagedEntrance(
        order: 1,
        child: TodayPulse(
          snapshot: TodayPulseSnapshot.fromPlanner(
            items: items,
            taskProgressById: taskProgressById,
            habitSummaryById: habitSummaryById,
            projectionResolved: projectionResolved,
          ),
          now: nowProvider,
          onOpenPlan: onOpenPlan,
          shortLandscape: shortLandscape,
        ),
      ),
      const SizedBox(height: PerfectSpace.lg),
      PerfectStagedEntrance(
        order: 2,
        child: Text(
          'YOUR DAY',
          key: const ValueKey<String>('compact-day-stream-heading'),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: PerfectSemanticTheme.of(context).muted,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.7,
          ),
        ),
      ),
      const SizedBox(height: PerfectSpace.xs),
      if (items.isEmpty)
        _DayStreamEmpty(onAdd: onAdd)
      else
        ...items.map(
          (entity) => _AgendaRow(
            key: ValueKey<String>('compact-day-row-${entity.id}'),
            entity: entity,
            controller: controller,
            onInspect: onInspect,
            todayEligibility: eligibilityById[entity.id],
            habitSummary: habitSummaryById[entity.id],
            taskProgress: taskProgressById[entity.id],
            referenceStyle: true,
          ),
        ),
    ],
  );
}

class _CompactTodayIntro extends StatelessWidget {
  const _CompactTodayIntro({required this.now, required this.ownerDisplayName});

  final PerfectNow now;
  final String? ownerDisplayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodySize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final textScale =
        MediaQuery.textScalerOf(context).scale(bodySize) / bodySize;
    return PerfectMinuteClockBuilder(
      now: now,
      builder: (context, current) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: PerfectSemanticTheme.of(context).muted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: PerfectSpace.xxs),
          Text(
            _greeting(current, ownerDisplayName: ownerDisplayName),
            maxLines: 2,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: textScale >= 1.35 ? null : 21.5,
              // The greeting leads with the same warm, rounded confidence as
              // the approved reference—not a dashboard-style black weight.
              fontWeight: FontWeight.w600,
              letterSpacing: -.7,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksPage extends StatefulWidget {
  const _TasksPage({
    super.key,
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
  _TaskFilter _filter = _TaskFilter.active;
  _TaskKindFilter _kindFilter = _TaskKindFilter.all;
  bool _filtersExpanded = false;

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
    return _PageScrollFrame(
      scrollKey: const ValueKey<String>('perfect-tasks-scroll'),
      children: [
        _PageTitle(
          title: 'Tasks',
          subtitle: 'All open work first. Narrow only when you need to.',
          onAdd: widget.onAdd,
        ),
        const SizedBox(height: PerfectSpace.md),
        _TaskFilterDeck(
          search: _search,
          filter: _filter,
          kindFilter: _kindFilter,
          resultCount: tasks.length,
          expanded: _filtersExpanded,
          onSearchChanged: () => setState(() {}),
          onFilterChanged: (value) => setState(() => _filter = value),
          onKindChanged: (value) => setState(() => _kindFilter = value),
          onToggleExpanded: () =>
              setState(() => _filtersExpanded = !_filtersExpanded),
        ),
        const SizedBox(height: PerfectSpace.md),
        if (tasks.isEmpty)
          _EmptyState(
            icon: _filter == _TaskFilter.completed
                ? Icons.celebration_outlined
                : Icons.inbox_outlined,
            title: _search.text.trim().isEmpty
                ? _taskEmptyTitle(_filter)
                : 'Nothing matches that search.',
            body: _search.text.trim().isEmpty
                ? _taskEmptyBody(_filter)
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

class _TaskFilterDeck extends StatelessWidget {
  const _TaskFilterDeck({
    required this.search,
    required this.filter,
    required this.kindFilter,
    required this.resultCount,
    required this.expanded,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onKindChanged,
    required this.onToggleExpanded,
  });

  final TextEditingController search;
  final _TaskFilter filter;
  final _TaskKindFilter kindFilter;
  final int resultCount;
  final bool expanded;
  final VoidCallback onSearchChanged;
  final ValueChanged<_TaskFilter> onFilterChanged;
  final ValueChanged<_TaskKindFilter> onKindChanged;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final showControls = wide || expanded;
            final animationDuration = PerfectMotion.responsive(
              context,
              PerfectMotion.standard,
            );
            final searchField = TextField(
              controller: search,
              onChanged: (_) => onSearchChanged(),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              textDirection: _textDirection(search.text),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          search.clear();
                          onSearchChanged();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                hintText: 'Find a task, note, or category…',
              ),
            );
            final controls = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterGroup<_TaskKindFilter>(
                  label: 'TYPE',
                  values: _TaskKindFilter.values,
                  selected: kindFilter,
                  labelFor: _taskKindFilterLabel,
                  iconFor: _taskKindFilterIcon,
                  onChanged: onKindChanged,
                ),
                const SizedBox(height: PerfectSpace.sm),
                _FilterGroup<_TaskFilter>(
                  label: 'STATUS',
                  values: _TaskFilter.values,
                  selected: filter,
                  labelFor: _taskFilterLabel,
                  onChanged: onFilterChanged,
                ),
              ],
            );
            final resultCopy =
                '$resultCount ${resultCount == 1 ? 'result' : 'results'}';
            final filterSummary =
                '${_taskFilterLabel(filter)} · '
                '${_taskKindFilterLabel(kindFilter)}';
            final highTextScale =
                MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.6;
            final compactToggle = Semantics(
              button: true,
              label:
                  '${expanded ? 'Hide' : 'Show'} task filters. '
                  '$filterSummary. $resultCopy.',
              child: ExcludeSemantics(
                child: Material(
                  color: scheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey<String>('task-filter-toggle'),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      onToggleExpanded();
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PerfectSpace.sm,
                          vertical: PerfectSpace.xs,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 19,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: PerfectSpace.xs),
                            Expanded(
                              child: highTextScale
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          filterSummary,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        Text(
                                          resultCopy,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      filterSummary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                            ),
                            if (!highTextScale) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  '$resultCount',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: scheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              const SizedBox(width: PerfectSpace.xs),
                            ],
                            AnimatedRotation(
                              turns: expanded ? .5 : 0,
                              duration: animationDuration,
                              curve: PerfectMotion.productive,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: searchField),
                      const SizedBox(width: PerfectSpace.lg),
                      Expanded(flex: 6, child: controls),
                    ],
                  )
                else ...[
                  searchField,
                  const SizedBox(height: PerfectSpace.xs),
                  compactToggle,
                  AnimatedSwitcher(
                    duration: animationDuration,
                    switchInCurve: PerfectMotion.enter,
                    switchOutCurve: PerfectMotion.exit,
                    transitionBuilder: (child, animation) => SizeTransition(
                      sizeFactor: animation,
                      alignment: Alignment.topCenter,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: showControls
                        ? Padding(
                            key: const ValueKey<String>('task-filter-controls'),
                            padding: const EdgeInsets.only(
                              top: PerfectSpace.sm,
                            ),
                            child: controls,
                          )
                        : const SizedBox.shrink(
                            key: ValueKey<String>(
                              'task-filter-controls-collapsed',
                            ),
                          ),
                  ),
                ],
                if (wide) ...[
                  const SizedBox(height: PerfectSpace.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        size: 17,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$resultCopy · $filterSummary',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterGroup<T> extends StatelessWidget {
  const _FilterGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
    this.iconFor,
  });

  final String label;
  final Iterable<T> values;
  final T selected;
  final String Function(T) labelFor;
  final IconData Function(T)? iconFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: PerfectSpace.xs,
        runSpacing: PerfectSpace.xs,
        children: values
            .map(
              (value) => ChoiceChip(
                avatar: iconFor == null
                    ? null
                    : Icon(iconFor!(value), size: 17),
                label: Text(labelFor(value)),
                selected: selected == value,
                showCheckmark: false,
                onSelected: (_) => onChanged(value),
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}

String _taskFilterLabel(_TaskFilter filter) => switch (filter) {
  _TaskFilter.inbox => 'Inbox',
  _TaskFilter.active => 'Open',
  _TaskFilter.scheduled => 'Scheduled',
  _TaskFilter.completed => 'Completed',
};

String _taskEmptyTitle(_TaskFilter filter) => switch (filter) {
  _TaskFilter.inbox => 'Your inbox is clear.',
  _TaskFilter.active => 'No open tasks.',
  _TaskFilter.scheduled => 'Nothing scheduled.',
  _TaskFilter.completed => 'No completed tasks yet.',
};

String _taskEmptyBody(_TaskFilter filter) => switch (filter) {
  _TaskFilter.inbox =>
    'Everything has a place. Add a task when something new appears.',
  _TaskFilter.active =>
    'Create the next task, or switch to Completed to review finished work.',
  _TaskFilter.scheduled => 'Plan a task when it needs a date or time.',
  _TaskFilter.completed =>
    'Finished work will collect here without leaving your active list.',
};

String _taskKindFilterLabel(_TaskKindFilter filter) => switch (filter) {
  _TaskKindFilter.all => 'All',
  _TaskKindFilter.oneOff => 'Single',
  _TaskKindFilter.recurring => 'Recurring',
};

IconData _taskKindFilterIcon(_TaskKindFilter filter) => switch (filter) {
  _TaskKindFilter.all => Icons.view_agenda_outlined,
  _TaskKindFilter.oneOff => Icons.filter_1_rounded,
  _TaskKindFilter.recurring => Icons.repeat_rounded,
};

class _PlanPage extends StatefulWidget {
  const _PlanPage({
    super.key,
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
    return _PageScrollFrame(
      children: [
        _PageTitle(
          title: 'Plan',
          subtitle: 'Move across days without losing unfinished work.',
          onAdd: widget.onAdd,
        ),
        const SizedBox(height: PerfectSpace.md),
        _PlannerDateDeck(
          selectedDay: _selectedDay,
          today: _dateOnly(widget.now),
          itemCount: planned.length,
          onMove: _moveDay,
          onPick: _pickDay,
          onSelectDay: (day) => setState(() => _selectedDay = _dateOnly(day)),
          onToday: isToday
              ? null
              : () => setState(() => _selectedDay = _dateOnly(widget.now)),
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

class _PlannerDateDeck extends StatelessWidget {
  const _PlannerDateDeck({
    required this.selectedDay,
    required this.today,
    required this.itemCount,
    required this.onMove,
    required this.onPick,
    required this.onSelectDay,
    this.onToday,
  });

  final DateTime selectedDay;
  final DateTime today;
  final int itemCount;
  final ValueChanged<int> onMove;
  final Future<void> Function() onPick;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final labelScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final selectedDayLabel = labelScale >= 1.3
        ? localizations.formatMediumDate(selectedDay)
        : localizations.formatFullDate(selectedDay);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: () => onMove(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.calendar_month_outlined, size: 19),
                    label: Text(selectedDayLabel, maxLines: 2),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  onPressed: () => onMove(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: PerfectSpace.xs),
            _PlannerWeekStrip(
              selectedDay: selectedDay,
              today: today,
              onSelectDay: onSelectDay,
            ),
            const SizedBox(height: PerfectSpace.md),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: PerfectSpace.md,
              runSpacing: PerfectSpace.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: PerfectSemanticTheme.of(context).primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: PerfectSpace.xs),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'time block' : 'time blocks'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (onToday != null)
                  TextButton.icon(
                    key: const ValueKey<String>('planner-back-to-today'),
                    onPressed: onToday,
                    icon: const Icon(Icons.today_outlined, size: 18),
                    label: const Text('Today'),
                  ),
              ],
            ),
            Text(
              'Timed work lands here. Unscheduled work stays safely in Tasks.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerWeekStrip extends StatelessWidget {
  const _PlannerWeekStrip({
    required this.selectedDay,
    required this.today,
    required this.onSelectDay,
  });

  final DateTime selectedDay;
  final DateTime today;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final chipWidth = 48.0 * labelScale.clamp(1.0, 1.5).toDouble();
      final requiredWidth = chipWidth * 7 + 4 * 6;
      final days = [
        for (var offset = -3; offset <= 3; offset++)
          selectedDay.add(Duration(days: offset)),
      ];

      Widget chip(DateTime day) => _PlannerDayChip(
        day: day,
        selected: _isSameDate(day, selectedDay),
        today: _isSameDate(day, today),
        onTap: onSelectDay,
      );

      if (constraints.maxWidth >= requiredWidth) {
        return Row(
          children: [
            for (final (index, day) in days.indexed) ...[
              if (index > 0) const SizedBox(width: 4),
              Expanded(child: chip(day)),
            ],
          ],
        );
      }

      return SingleChildScrollView(
        key: const ValueKey<String>('planner-week-strip-scroll'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (index, day) in days.indexed) ...[
              if (index > 0) const SizedBox(width: 4),
              SizedBox(width: chipWidth, child: chip(day)),
            ],
          ],
        ),
      );
    },
  );
}

class _PlannerDayChip extends StatelessWidget {
  const _PlannerDayChip({
    required this.day,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: localizations.formatFullDate(day),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onTap(day),
        child: AnimatedContainer(
          duration: PerfectMotion.responsive(context, PerfectMotion.quick),
          curve: PerfectMotion.productive,
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(vertical: PerfectSpace.xs),
          decoration: BoxDecoration(
            color: selected
                ? PerfectSemanticTheme.of(context).primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? PerfectSemanticTheme.of(context).primary
                  : today
                  ? scheme.secondary.withValues(alpha: .66)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.narrowWeekdays[day.weekday % 7],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${day.day}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitsPage extends StatelessWidget {
  const _HabitsPage({
    super.key,
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
    final completed = habits
        .where(
          (habit) =>
              summaries[habit.id]?.state == PlannerHabitDayState.completed,
        )
        .length;
    final logged = habits
        .where((habit) => summaries[habit.id]?.hasLog ?? false)
        .length;
    return _PageScrollFrame(
      children: [
        _PageTitle(
          title: 'Habits',
          subtitle:
              'Build consistency without pretending rest days are failures.',
          onAdd: onAdd,
        ),
        const SizedBox(height: PerfectSpace.md),
        if (habits.isNotEmpty) ...[
          _HabitOverviewBand(
            total: habits.length,
            logged: logged,
            completed: completed,
          ),
          const SizedBox(height: PerfectSpace.md),
        ],
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

class _HabitOverviewBand extends StatelessWidget {
  const _HabitOverviewBand({
    required this.total,
    required this.logged,
    required this.completed,
  });

  final int total;
  final int logged;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.secondaryContainer.withValues(alpha: .76),
            scheme.tertiaryContainer.withValues(alpha: .60),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed == total
                      ? 'Today’s rhythm is complete.'
                      : 'Keep the rhythm gentle and visible.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '$logged logged · $completed reached · $total active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
            final meter = SizedBox(
              width: constraints.maxWidth < 540 ? double.infinity : 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.spa_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${(progress * 100).round()}%',
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
                      minHeight: 9,
                      color: PerfectSemanticTheme.of(context).secondary,
                      backgroundColor: scheme.surface.withValues(alpha: .72),
                    ),
                  ),
                ],
              ),
            );
            if (constraints.maxWidth < 540) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: PerfectSpace.md),
                  meter,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: PerfectSpace.lg),
                meter,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    super.key,
    required this.controller,
    required this.themeMode,
    required this.contrastMode,
    required this.onThemeModeChanged,
    this.onContrastModeChanged,
    required this.onSignOut,
    required this.onAddProject,
    required this.onAddArea,
    this.feedbackController,
    this.onOpenFeedback,
  });

  final PlannerWorkspaceController controller;
  final ThemeMode themeMode;
  final PerfectContrastMode contrastMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<PerfectContrastMode>? onContrastModeChanged;
  final Future<void> Function() onSignOut;
  final VoidCallback onAddProject;
  final VoidCallback onAddArea;
  final ReadyFeedbackController? feedbackController;
  final VoidCallback? onOpenFeedback;

  @override
  Widget build(BuildContext context) {
    final semantic = PerfectSemanticTheme.of(context);
    return _PageScrollFrame(
      maxWidth: 1120,
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
              child: ReadyFeedbackSettingsTile(
                controller: feedback,
                onCapture: onOpenFeedback,
              ),
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
                const SizedBox(height: PerfectSpace.xxs),
                Text(
                  'Choose the light environment separately from contrast.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PerfectSpace.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final mode = SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: <ThemeMode>{themeMode},
                      onSelectionChanged: (selection) =>
                          onThemeModeChanged(selection.first),
                    );
                    final contrast = SegmentedButton<PerfectContrastMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: PerfectContrastMode.system,
                          icon: Icon(Icons.settings_brightness_outlined),
                          label: Text('System contrast'),
                        ),
                        ButtonSegment(
                          value: PerfectContrastMode.high,
                          icon: Icon(Icons.contrast_rounded),
                          label: Text('Clarity'),
                        ),
                      ],
                      selected: <PerfectContrastMode>{contrastMode},
                      onSelectionChanged: onContrastModeChanged == null
                          ? null
                          : (selection) =>
                                onContrastModeChanged!(selection.first),
                    );
                    if (constraints.maxWidth < 700) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: mode,
                          ),
                          const SizedBox(height: PerfectSpace.sm),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: contrast,
                          ),
                        ],
                      );
                    }
                    return Wrap(
                      spacing: PerfectSpace.sm,
                      runSpacing: PerfectSpace.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [mode, contrast],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PerfectSpace.md),
        _MoreCommandGroup(
          title: 'Workspace structure',
          commands: [
            _MoreCommand(
              icon: Icons.folder_outlined,
              title: 'Projects',
              subtitle: '${controller.projects.length} active · create or edit',
              tint: semantic.primaryContainer,
              onTap: onAddProject,
            ),
            _MoreCommand(
              icon: Icons.grid_view_rounded,
              title: 'Areas',
              subtitle: '${controller.areas.length} active · organize contexts',
              tint: semantic.secondaryContainer,
              onTap: onAddArea,
            ),
          ],
        ),
        const SizedBox(height: PerfectSpace.md),
        _MoreCommandGroup(
          title: 'Focus and review',
          commands: [
            _MoreCommand(
              icon: Icons.timer_outlined,
              title: 'Focus',
              subtitle: 'Pomodoro, countdown, and stopwatch',
              tint: semantic.primaryContainer,
              onTap: () =>
                  FocusSessionSheet.show(context, controller: controller),
            ),
            _MoreCommand(
              icon: Icons.insights_outlined,
              title: 'Your rhythm',
              subtitle: 'Private insight from tasks, habits, and focus',
              tint: semantic.tertiaryContainer,
              onTap: () =>
                  PlannerInsightsSheet.show(context, controller: controller),
            ),
            _MoreCommand(
              icon: Icons.inventory_2_outlined,
              title: 'Archive',
              subtitle: 'Restore anything you archived',
              tint: Theme.of(context).colorScheme.surfaceContainerHigh,
              onTap: () =>
                  PlannerArchiveSheet.show(context, controller: controller),
            ),
          ],
        ),
        const SizedBox(height: PerfectSpace.md),
        _MoreCommandGroup(
          title: 'Devices and resilience',
          commands: [
            _MoreCommand(
              icon: Icons.notifications_none_rounded,
              title: 'Reminders & quiet hours',
              subtitle: 'Multiple alerts with device-local delivery',
              tint: semantic.primaryContainer,
              onTap: () => PlannerReminderSettingsSheet.show(
                context,
                controller: controller,
              ),
            ),
            if (controller.todayWidgetSettings.isAvailable)
              _MoreCommand(
                icon: Icons.widgets_outlined,
                title: 'Perfect Today widget',
                subtitle: 'Resize, scroll, complete, and quick-add',
                tint: semantic.secondaryContainer,
                onTap: () => PerfectTodayWidgetSettingsSheet.show(
                  context,
                  controller: controller,
                ),
              ),
            _MoreCommand(
              icon: Icons.merge_type_rounded,
              title: 'Conflict center',
              subtitle: 'Review simultaneous edits that need you',
              tint: semantic.tertiaryContainer,
              onTap: () => PlannerConflictCenterSheet.show(
                context,
                controller: controller,
              ),
            ),
          ],
        ),
        const SizedBox(height: PerfectSpace.md),
        Card(
          child: ListTile(
            leading: Icon(
              _syncIcon(controller.syncStatus.phase),
              color: _syncColor(context, controller.syncStatus.phase),
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
}

@immutable
class _MoreCommand {
  const _MoreCommand({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;
}

class _MoreCommandGroup extends StatelessWidget {
  const _MoreCommandGroup({required this.title, required this.commands});

  final String title;
  final List<_MoreCommand> commands;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final twoColumns = constraints.maxWidth >= 700 && textScale < 1.5;
          final itemWidth = twoColumns
              ? (constraints.maxWidth - PerfectSpace.sm) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: PerfectSpace.sm,
            runSpacing: PerfectSpace.sm,
            children: [
              for (final command in commands)
                SizedBox(
                  width: itemWidth,
                  child: _MoreCommandTile(command: command),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _MoreCommandTile extends StatelessWidget {
  const _MoreCommandTile({required this.command});

  final _MoreCommand command;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${command.title}. ${command.subtitle}',
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: command.onTap,
        child: Padding(
          padding: const EdgeInsets.all(PerfectSpace.md),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: command.tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  command.icon,
                  color: PerfectSemanticTheme.of(context).ink,
                ),
              ),
              const SizedBox(width: PerfectSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      command.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PerfectSpace.xs),
              const Icon(Icons.arrow_outward_rounded, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PageScrollFrame extends StatelessWidget {
  const _PageScrollFrame({
    required this.children,
    this.scrollKey,
    this.maxWidth = 980,
  });

  final List<Widget> children;
  final Key? scrollKey;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 640;
      final horizontal = compact
          ? PerfectSpace.md
          : constraints.maxWidth >= 1200
          ? PerfectSpace.xxl
          : PerfectSpace.xl;
      return ListView(
        key: scrollKey,
        padding: EdgeInsets.fromLTRB(
          horizontal,
          PerfectSpace.md,
          horizontal,
          compact ? 168 : PerfectSpace.xxl,
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      );
    },
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
            PerfectStagedEntrance(
              key: ValueKey<String>('page-title-$title'),
              rise: PerfectMotion.titleRise,
              scaleBegin: .99,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: PerfectSpace.xs),
            PerfectStagedEntrance(
              key: ValueKey<String>('page-subtitle-$title'),
              order: 1,
              rise: PerfectMotion.titleRise,
              scaleBegin: .995,
              duration: PerfectMotion.standard,
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      if (onAdd != null)
        PerfectStagedEntrance(
          key: ValueKey<String>('page-add-$title'),
          order: 1,
          rise: PerfectMotion.titleRise,
          scaleBegin: .96,
          duration: PerfectMotion.standard,
          child: IconButton.filled(
            tooltip: 'Add $title',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
    ],
  );
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    super.key,
    required this.entity,
    required this.controller,
    required this.onInspect,
    this.showKind = false,
    this.todayEligibility,
    this.habitSummary,
    this.taskProgress,
    this.referenceStyle = false,
  });

  final PlannerEntity entity;
  final PlannerWorkspaceController controller;
  final ValueChanged<PlannerEntity> onInspect;
  final PlannerTaskProgress? taskProgress;
  final bool showKind;
  final PlannerTodayEligibility? todayEligibility;
  final PlannerHabitDaySummary? habitSummary;
  final bool referenceStyle;

  @override
  Widget build(BuildContext context) {
    final oneOffProgress = entity.kind == PlannerEntityKind.oneOffTask
        ? PlannerTaskProgress.fromEntity(entity)
        : null;
    final completed =
        oneOffProgress?.isComplete ??
        taskProgress?.isComplete ??
        (habitSummary?.state == PlannerHabitDayState.completed ||
            entity.status == PlannerEntityStatus.completed);
    final missed =
        oneOffProgress?.isMissed ??
        taskProgress?.isMissed ??
        (habitSummary?.state == PlannerHabitDayState.missed);
    final requiresRecoveryDecision =
        todayEligibility?.requiresDecision ?? false;
    final color = _colorFor(context, entity);
    if (referenceStyle) {
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
        child: _ReferenceAgendaRow(
          entity: entity,
          controller: controller,
          onInspect: onInspect,
          taskProgress: taskProgress,
          todayEligibility: todayEligibility,
          habitSummary: habitSummary,
          completed: completed,
          missed: missed,
          color: color,
        ),
      );
    }
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
                taskProgress: taskProgress,
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
                                    maxLines: 2,
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

/// The compact Day Stream row deliberately follows the reference's readable
/// time → title → category hierarchy. It remains a live task control: the
/// leading control cycles status, the row opens details, and desktop context
/// actions are retained by the parent region.
class _ReferenceAgendaRow extends StatelessWidget {
  const _ReferenceAgendaRow({
    required this.entity,
    required this.controller,
    required this.onInspect,
    this.taskProgress,
    required this.todayEligibility,
    required this.habitSummary,
    required this.completed,
    required this.missed,
    required this.color,
  });

  final PlannerEntity entity;
  final PlannerWorkspaceController controller;
  final ValueChanged<PlannerEntity> onInspect;
  final PlannerTaskProgress? taskProgress;
  final PlannerTodayEligibility? todayEligibility;
  final PlannerHabitDaySummary? habitSummary;
  final bool completed;
  final bool missed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheduled = entity.scheduledAt?.toLocal();
    final category =
        safeNullableJsonString(entity.payload['category']) ??
        _kindLabel(entity.kind);
    final progress = entity.kind == PlannerEntityKind.oneOffTask
        ? PlannerTaskProgress.fromEntity(entity).percent
        : taskProgress?.percent ?? habitSummary?.progressPercent ?? 0;
    final requiresRecoveryDecision =
        todayEligibility?.requiresDecision ?? false;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodySize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;
        final textScale =
            MediaQuery.textScalerOf(context).scale(bodySize) / bodySize;
        // A regular phone has enough room for the progress ring beside its
        // row. Only a truly narrow split pane or enlarged type turns it into
        // a second line; otherwise that split destroys the day-stream rhythm.
        final stackedTrailing = constraints.maxWidth < 330 || textScale >= 1.32;
        final detail = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  scheduled == null
                      ? Icons.inbox_outlined
                      : progress > 0 && !missed
                      ? Icons.calendar_month_outlined
                      : Icons.schedule_rounded,
                  size: 15,
                  color: color,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    scheduled == null ? 'INBOX' : _shortTime(scheduled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              entity.title,
              maxLines: stackedTrailing ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              textDirection: _textDirection(entity.title),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.1,
                letterSpacing: -.35,
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? scheme.onSurfaceVariant : null,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sell_outlined,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        final trailing = entity.kind == PlannerEntityKind.recurringTask
            ? _ReferenceAgendaStatus(
                progress: taskProgress?.percent ?? 0,
                completed: taskProgress?.isComplete ?? false,
                missed: taskProgress?.isMissed ?? false,
                color: color,
              )
            : _ReferenceAgendaStatus(
                progress: progress,
                completed: completed,
                missed: missed,
                color: color,
              );
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onInspect(entity),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AgendaCompletionButton(
                        entity: entity,
                        controller: controller,
                        taskProgress: taskProgress,
                        habitSummary: habitSummary,
                        referenceStyle: true,
                      ),
                      const SizedBox(width: PerfectSpace.xxs),
                      Expanded(child: detail),
                      if (!stackedTrailing) ...[
                        const SizedBox(width: PerfectSpace.xs),
                        trailing,
                      ],
                      const SizedBox(width: PerfectSpace.xxs),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 27,
                      ),
                    ],
                  ),
                  if (stackedTrailing) ...[
                    const SizedBox(height: PerfectSpace.xs),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing,
                    ),
                  ],
                  if (requiresRecoveryDecision) ...[
                    const SizedBox(height: PerfectSpace.xxs),
                    Semantics(
                      button: true,
                      label: 'Resolve missed task recovery',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showOneOffRecoverySheet(
                          context,
                          entity: entity,
                          controller: controller,
                          eligibility: todayEligibility!,
                        ),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: PerfectSpace.sm,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer.withValues(
                              alpha: .54,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_send_outlined,
                                size: 16,
                                color: scheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Decision needed · tap to resolve',
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: scheme.onTertiaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: scheme.onTertiaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: .78),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReferenceAgendaStatus extends StatelessWidget {
  const _ReferenceAgendaStatus({
    required this.progress,
    required this.completed,
    required this.missed,
    required this.color,
  });

  final int progress;
  final bool completed;
  final bool missed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (missed) {
      return Text(
        'MISSED',
        maxLines: 1,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: PerfectSemanticTheme.of(context).danger,
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
        ),
      );
    }
    final value = completed ? 1.0 : progress.clamp(0, 100) / 100;
    return SizedBox.square(
      dimension: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 4.5,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          Container(
            key: const ValueKey<String>('perfect-agenda-progress-safe-core'),
            width: 43,
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .88),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${completed ? 100 : progress}%',
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
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
            onLongPressStart: (details) =>
                unawaited(_open(details.globalPosition)),
            onSecondaryTapUp: (details) =>
                unawaited(_open(details.globalPosition)),
            child: AnimatedContainer(
              duration: PerfectMotion.responsive(context, PerfectMotion.quick),
              foregroundDecoration: _showFocus
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: PerfectSemanticTheme.of(context).focus,
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
    popUpAnimationStyle: PerfectMotion.menuStyle(context),
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
  final confirmed = await showPerfectDialog<bool>(
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
    await showPerfectDialog<void>(
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
    sheetAnimationStyle: PerfectMotion.modalSheetStyle(context),
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
    await showPerfectDialog<void>(
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
    sheetAnimationStyle: PerfectMotion.modalSheetStyle(context),
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
    this.taskProgress,
    this.habitSummary,
    this.referenceStyle = false,
  });

  final PlannerEntity entity;
  final PlannerWorkspaceController controller;
  final PlannerTaskProgress? taskProgress;
  final PlannerHabitDaySummary? habitSummary;
  final bool referenceStyle;

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
        icon: _habitSummaryVisual(
          context,
          habitSummary,
          referenceStyle: referenceStyle,
        ),
      );
    }
    if (entity.kind == PlannerEntityKind.recurringTask) {
      final progress = taskProgress ?? const PlannerTaskProgress.pending();
      return IconButton(
        tooltip: _taskProgressTooltip(progress),
        onPressed: () =>
            _cycleTaskProgressWithFeedback(context, controller, entity),
        icon: _animatedTaskProgressVisual(
          context,
          progress,
          fallback: _colorFor(context, entity),
          referenceStyle: referenceStyle,
        ),
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
        fallback: _colorFor(context, entity),
        referenceStyle: referenceStyle,
      ),
    );
  }
}

Widget _animatedTaskProgressVisual(
  BuildContext context,
  PlannerTaskProgress progress, {
  required Color fallback,
  bool referenceStyle = false,
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
    child: _taskProgressVisual(
      context,
      progress,
      fallback: fallback,
      referenceStyle: referenceStyle,
    ),
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
                  decoration: BoxDecoration(
                    color: PerfectSemanticTheme.of(context).secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _habitTrackingIcon(method),
                    color: PerfectSemanticTheme.of(
                      context,
                    ).onSecondaryContainer,
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

Widget _habitSummaryVisual(
  BuildContext context,
  PlannerHabitDaySummary? summary, {
  bool referenceStyle = false,
}) {
  if (summary?.state == PlannerHabitDayState.partial) {
    if (referenceStyle) {
      return SizedBox.square(
        dimension: 30,
        child: CircularProgressIndicator(
          value: summary!.progressPercent / 100,
          strokeWidth: 2.8,
          strokeCap: StrokeCap.round,
          color: PerfectSemanticTheme.of(context).tertiary,
          backgroundColor: PerfectSemanticTheme.of(
            context,
          ).tertiary.withValues(alpha: .16),
        ),
      );
    }
    return SizedBox(
      width: 31,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${summary!.progressPercent}%',
          style: TextStyle(
            color: PerfectSemanticTheme.of(context).tertiary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
  return Icon(
    _habitSummaryIcon(summary?.state),
    color: switch (summary?.state) {
      PlannerHabitDayState.completed => PerfectSemanticTheme.of(
        context,
      ).secondary,
      PlannerHabitDayState.missed => PerfectSemanticTheme.of(context).danger,
      PlannerHabitDayState.partial => PerfectSemanticTheme.of(context).tertiary,
      _ => PerfectSemanticTheme.of(context).muted,
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
      PlannerHabitDayState.completed => PerfectSemanticTheme.of(
        context,
      ).secondary,
      PlannerHabitDayState.missed => PerfectSemanticTheme.of(context).danger,
      PlannerHabitDayState.partial => PerfectSemanticTheme.of(context).tertiary,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };

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
    return '$state · ${_compactNumber(summary.amount)} of '
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
                          duration: PerfectMotion.responsive(
                            context,
                            PerfectMotion.standard,
                          ),
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheduled
                                ? PerfectSemanticTheme.of(
                                    context,
                                  ).secondaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isToday
                                  ? PerfectSemanticTheme.of(context).primary
                                  : scheduled
                                  ? PerfectSemanticTheme.of(context).secondary
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
                                      ? PerfectSemanticTheme.of(
                                          context,
                                        ).secondary
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
          Icon(icon, size: 44, color: PerfectSemanticTheme.of(context).primary),
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
          final current = entity;
          if (current == null) return const _InspectorEmpty();
          final compactActions =
              !showFocusPrompt && constraints.maxHeight < 520;

          Widget duplicateButton() => OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: PerfectSpace.xs),
            ),
            onPressed: () => _duplicateAndReveal(
              context,
              entity: current,
              controller: controller,
              onReveal: onReveal,
            ),
            icon: const Icon(Icons.content_copy_rounded),
            label: const Text('Duplicate', maxLines: 1),
          );

          Widget focusButton() => OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: PerfectSpace.xs),
            ),
            onPressed: () => FocusSessionSheet.show(
              context,
              controller: controller,
              entity: current,
            ),
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Focus', maxLines: 1),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: PerfectSpace.sm),
              Expanded(
                child: CustomScrollView(
                  key: const PageStorageKey<String>(
                    'perfect-inspector-detail-scroll',
                  ),
                  slivers: [
                    SliverList.list(
                      children: [
                        Text(
                          current.title,
                          textDirection: _textDirection(current.title),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: PerfectSpace.sm),
                        Text(current.note ?? 'No note yet.'),
                        SizedBox(
                          height: compactActions
                              ? PerfectSpace.sm
                              : PerfectSpace.lg,
                        ),
                        if (compactActions) ...[
                          _CompactInspectorFact(
                            label: 'Kind',
                            value: _kindLabel(current.kind),
                          ),
                          _CompactInspectorFact(
                            label: 'Recovery',
                            value: safeJsonString(
                              current.recovery['on_miss'],
                              fallback: 'default',
                            ),
                          ),
                          _CompactInspectorFact(
                            label: 'Sync',
                            value: controller.syncStatus.phase.name,
                          ),
                          if (current.dueAt != null)
                            _CompactInspectorFact(
                              label: 'Deadline',
                              value: _inspectorDateTime(current.dueAt!),
                            ),
                          if (safeNullableJsonString(
                                current.payload['category'],
                              ) !=
                              null)
                            _CompactInspectorFact(
                              label: 'Category',
                              value: safeJsonString(
                                current.payload['category'],
                                fallback: '',
                              ),
                            ),
                        ] else ...[
                          _InspectorFact(
                            label: 'Kind',
                            value: _kindLabel(current.kind),
                          ),
                          _InspectorFact(
                            label: 'Recovery',
                            value: safeJsonString(
                              current.recovery['on_miss'],
                              fallback: 'default',
                            ),
                          ),
                          _InspectorFact(
                            label: 'Sync',
                            value: controller.syncStatus.phase.name,
                          ),
                          if (current.dueAt != null)
                            _InspectorFact(
                              label: 'Deadline',
                              value: _inspectorDateTime(current.dueAt!),
                            ),
                          if (safeNullableJsonString(
                                current.payload['category'],
                              ) !=
                              null)
                            _InspectorFact(
                              label: 'Category',
                              value: safeJsonString(
                                current.payload['category'],
                                fallback: '',
                              ),
                            ),
                        ],
                        if (current.customProperties.isNotEmpty)
                          _CustomPropertyFacts(
                            properties: current.customProperties,
                          ),
                        if (showFocusPrompt) ...[
                          const SizedBox(height: PerfectSpace.md),
                          _InspectorFocusPrompt(
                            entity: current,
                            controller: controller,
                          ),
                        ],
                        const SizedBox(height: PerfectSpace.sm),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PerfectSpace.xs),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              const SizedBox(height: PerfectSpace.xs),
              if (compactActions)
                Row(
                  children: [
                    Expanded(child: duplicateButton()),
                    const SizedBox(width: PerfectSpace.xs),
                    Expanded(child: focusButton()),
                  ],
                )
              else ...[
                duplicateButton(),
                if (!showFocusPrompt) ...[
                  const SizedBox(height: PerfectSpace.xs),
                  focusButton(),
                ],
              ],
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
        color: PerfectSemanticTheme.of(context).tertiaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PerfectSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.center_focus_strong_rounded,
              color: PerfectSemanticTheme.of(context).onTertiaryContainer,
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
        Icon(
          Icons.touch_app_outlined,
          size: 42,
          color: PerfectSemanticTheme.of(context).tertiary,
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

class _CompactInspectorFact extends StatelessWidget {
  const _CompactInspectorFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PerfectSpace.xs),
    child: Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: PerfectSpace.sm),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
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

String _greeting(DateTime now, {String? ownerDisplayName}) {
  final hour = now.hour;
  final period = hour < 12
      ? 'Good morning'
      : hour < 18
      ? 'Good afternoon'
      : 'Good evening';
  final name = ownerDisplayName?.trim();
  return name == null || name.isEmpty ? period : '$period, $name';
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
  return PerfectLocalTime.inspector(value);
}

String _shortDate(DateTime value) {
  return PerfectLocalTime.gregorianShort(value);
}

String _shortTime(DateTime value) {
  return PerfectLocalTime.clock(value);
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
      PlannerTaskProgressState.missed => Icons.cancel_outlined,
      PlannerTaskProgressState.partial => Icons.percent_rounded,
    };

Widget _taskProgressVisual(
  BuildContext context,
  PlannerTaskProgress progress, {
  required Color fallback,
  bool referenceStyle = false,
}) {
  final color = _taskProgressColor(context, progress, fallback: fallback);
  if (referenceStyle && progress.isPartial) {
    return SizedBox.square(
      dimension: 30,
      child: CircularProgressIndicator(
        value: progress.percent / 100,
        strokeWidth: 2.8,
        strokeCap: StrokeCap.round,
        color: color,
        backgroundColor: color.withValues(alpha: .15),
      ),
    );
  }
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
  BuildContext context,
  PlannerTaskProgress progress, {
  required Color fallback,
}) => switch (progress.state) {
  PlannerTaskProgressState.pending => fallback,
  PlannerTaskProgressState.completed => PerfectSemanticTheme.of(
    context,
  ).secondary,
  PlannerTaskProgressState.missed => PerfectSemanticTheme.of(context).danger,
  PlannerTaskProgressState.partial => fallback,
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

Color _colorFor(BuildContext context, PlannerEntity entity) {
  // The editor persists the owner’s explicit swatch at the payload root. Use
  // it before any category fallback so a Work task can legitimately be mint
  // while another Work task stays apricot—category and color are separate
  // choices, not two competing meanings.
  final explicit = safeJsonString(
    entity.payload[PlannerTaskMetadataKeys.color],
    fallback: '',
  ).toLowerCase();
  final explicitColor = switch (explicit) {
    'mint' => PerfectSemanticTheme.of(context).secondary,
    'lilac' => PerfectSemanticTheme.of(context).tertiary,
    'rose' => PerfectSemanticTheme.of(context).danger,
    'ink' => PerfectSemanticTheme.of(context).ink,
    'apricot' || 'orange' => PerfectSemanticTheme.of(context).primary,
    _ => null,
  };
  if (explicitColor != null) return explicitColor;
  return switch (entity.kind) {
    PlannerEntityKind.habit => PerfectSemanticTheme.of(context).secondary,
    PlannerEntityKind.project => PerfectSemanticTheme.of(context).tertiary,
    PlannerEntityKind.area => PerfectSemanticTheme.of(context).tertiary,
    _ => _categoryColor(context, entity),
  };
}

Color _categoryColor(BuildContext context, PlannerEntity entity) {
  final category = safeJsonString(
    entity.payload['category'],
    fallback: '',
  ).toLowerCase();
  if (<String>{'health', 'home', 'personal'}.contains(category)) {
    return PerfectSemanticTheme.of(context).secondary;
  }
  if (<String>{'study', 'finance'}.contains(category)) {
    return PerfectSemanticTheme.of(context).tertiary;
  }
  return PerfectSemanticTheme.of(context).primary;
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

Color _syncColor(BuildContext context, PlannerSyncPhase phase) {
  final semantic = PerfectSemanticTheme.of(context);
  return switch (phase) {
    PlannerSyncPhase.idle => semantic.sync,
    PlannerSyncPhase.syncing => semantic.warning,
    PlannerSyncPhase.offline => semantic.tertiary,
    PlannerSyncPhase.needsAttention => semantic.danger,
  };
}

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
