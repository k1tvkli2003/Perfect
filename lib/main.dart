import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:perfect/ai/perfect_ai_client.dart';
import 'package:perfect/app/app_config.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/app/perfect_system_appearance.dart';
import 'package:perfect/auth/auth_page.dart';
import 'package:perfect/auth/configuration_page.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/notifications/planner_reminder_scheduler.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/perfect_workspace_page.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:perfect/widgets/perfect_today_widget_background.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ReadyFeedbackLogger.instance.installGlobalErrorCapture();
  runApp(const PerfectApp());
}

typedef PerfectAppBootstrapper = Future<PerfectAppBootstrapResult> Function();
typedef PerfectWidgetBackgroundRegistrar = Future<void> Function();

@immutable
class PerfectAppBootstrapResult {
  const PerfectAppBootstrapResult({
    required this.themeMode,
    required this.supabaseReady,
    this.contrastMode = PerfectContrastMode.system,
    this.configurationError,
  });

  final ThemeMode themeMode;
  final PerfectContrastMode contrastMode;
  final bool supabaseReady;
  final Object? configurationError;
}

Future<PerfectAppBootstrapResult> _bootstrapPerfectApp() async {
  final themeModeFuture = _readThemeModeSafely();
  final contrastModeFuture = _readContrastModeSafely();
  var supabaseReady = false;
  Object? configurationError;
  try {
    await AppConfig.load();
    if (AppConfig.isConfigured) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
      supabaseReady = true;
    }
  } on Object catch (error) {
    configurationError = error;
  }
  return PerfectAppBootstrapResult(
    themeMode: await themeModeFuture,
    contrastMode: await contrastModeFuture,
    supabaseReady: supabaseReady,
    configurationError: configurationError,
  );
}

Future<PerfectContrastMode> _readContrastModeSafely() async {
  try {
    return await PerfectPreferences.readContrastMode();
  } on Object {
    return PerfectContrastMode.system;
  }
}

Future<ThemeMode> _readThemeModeSafely() async {
  try {
    return await PerfectPreferences.readThemeMode();
  } on Object {
    return ThemeMode.system;
  }
}

class PerfectApp extends StatefulWidget {
  const PerfectApp({
    super.key,
    this.bootstrapper,
    this.widgetBackgroundRegistrar,
  });

  final PerfectAppBootstrapper? bootstrapper;
  final PerfectWidgetBackgroundRegistrar? widgetBackgroundRegistrar;

  @override
  State<PerfectApp> createState() => _PerfectAppState();
}

class _PerfectAppState extends State<PerfectApp> {
  ThemeMode _themeMode = ThemeMode.system;
  PerfectContrastMode _contrastMode = PerfectContrastMode.system;
  bool _bootstrapComplete = false;
  bool _supabaseReady = false;
  Object? _configurationError;

  @override
  void initState() {
    super.initState();
    // Paint the owned Perfect surface first. Storage, platform channels,
    // Supabase session recovery, and widget registration begin only after that
    // first frame, so a slow plugin cannot hold Android's first frame hostage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_registerWidgetBackground());
      unawaited(_bootstrap());
    });
  }

  Future<void> _registerWidgetBackground() async {
    try {
      await (widget.widgetBackgroundRegistrar ??
          registerPerfectTodayWidgetBackgroundCallback)();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Perfect widget bootstrap',
          context: ErrorDescription(
            'while registering non-blocking home widget interactivity',
          ),
        ),
      );
    }
  }

  Future<void> _bootstrap() async {
    PerfectAppBootstrapResult result;
    try {
      result = await (widget.bootstrapper ?? _bootstrapPerfectApp)();
    } on Object catch (error) {
      result = PerfectAppBootstrapResult(
        themeMode: ThemeMode.system,
        supabaseReady: false,
        configurationError: error,
      );
    }
    if (!mounted) return;
    setState(() {
      _themeMode = result.themeMode;
      _contrastMode = result.contrastMode;
      _supabaseReady = result.supabaseReady;
      _configurationError = result.configurationError;
      _bootstrapComplete = true;
    });
  }

  void _changeThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    setState(() => _themeMode = value);
    unawaited(PerfectPreferences.saveThemeMode(value));
  }

  void _changeContrastMode(PerfectContrastMode value) {
    if (_contrastMode == value) return;
    setState(() => _contrastMode = value);
    unawaited(PerfectPreferences.saveContrastMode(value));
  }

  Future<void> _configureSupabase({
    required String supabaseUrl,
    required String publishableKey,
  }) async {
    await AppConfig.configureDevice(
      supabaseUrl: supabaseUrl,
      publishableKey: publishableKey,
    );
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
      if (!mounted) return;
      setState(() {
        _supabaseReady = true;
        _configurationError = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _configurationError = error);
      rethrow;
    }
  }

  Future<void> _changeSupabaseConnection() async {
    // Supabase.initialize intentionally skips a second initialization. Dispose
    // the unauthenticated client first so ConfigurationPage can replace this
    // device's project safely without requiring an app-data wipe or restart.
    await Supabase.instance.dispose();
    if (!mounted) return;
    setState(() {
      _supabaseReady = false;
      _configurationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final forcedHighContrast = _contrastMode == PerfectContrastMode.high;
    return MaterialApp(
      title: 'Perfect!',
      debugShowCheckedModeBanner: false,
      theme: forcedHighContrast
          ? PerfectTheme.highContrastLight()
          : PerfectTheme.light(),
      darkTheme: forcedHighContrast
          ? PerfectTheme.highContrastDark()
          : PerfectTheme.dark(),
      highContrastTheme: PerfectTheme.highContrastLight(),
      highContrastDarkTheme: PerfectTheme.highContrastDark(),
      themeMode: _themeMode,
      themeAnimationDuration: PerfectMotion.standard,
      themeAnimationCurve: PerfectMotion.productive,
      builder: (context, child) => PerfectSystemAppearanceProjection(
        themeMode: _themeMode,
        contrastMode: _contrastMode,
        child: child ?? const SizedBox.shrink(),
      ),
      home: !_bootstrapComplete
          ? const _PerfectBootstrapSurface()
          : _supabaseReady
          ? _AuthenticatedApp(
              themeMode: _themeMode,
              contrastMode: _contrastMode,
              onThemeModeChanged: _changeThemeMode,
              onContrastModeChanged: _changeContrastMode,
              onChangeSupabaseConnection: _changeSupabaseConnection,
            )
          : ConfigurationPage(
              onConnect: _configureSupabase,
              initialError: _configurationError,
            ),
    );
  }
}

class _PerfectBootstrapSurface extends StatelessWidget {
  const _PerfectBootstrapSurface();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey<String>('perfect-bootstrap'),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colors.surface,
              colors.primaryContainer.withValues(alpha: .48),
              colors.secondaryContainer.withValues(alpha: .42),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(PerfectSpace.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: colors.outlineVariant),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: .08),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: PerfectMark(size: 82),
                      ),
                    ),
                    const SizedBox(height: PerfectSpace.lg),
                    const PerfectWordmark(fontSize: 36),
                    const SizedBox(height: PerfectSpace.sm),
                    Text(
                      'Opening your day',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: PerfectSpace.xl),
                    SizedBox(
                      width: 92,
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(999),
                        color: colors.primary,
                        backgroundColor: colors.surfaceContainerHighest,
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
  }
}

class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp({
    required this.themeMode,
    required this.contrastMode,
    required this.onThemeModeChanged,
    required this.onContrastModeChanged,
    required this.onChangeSupabaseConnection,
  });

  final ThemeMode themeMode;
  final PerfectContrastMode contrastMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<PerfectContrastMode> onContrastModeChanged;
  final Future<void> Function() onChangeSupabaseConnection;

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp> {
  final PerfectTodayWidgetBridge _todayWidgetBridge =
      const PerfectTodayWidgetBridge();
  String? _activeOwnerId;
  bool _widgetClearQueued = false;

  void _queueWidgetPrivacyClear() {
    _activeOwnerId = null;
    if (_widgetClearQueued) return;
    _widgetClearQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetClearQueued = false;
      if (!mounted || _activeOwnerId != null) return;
      unawaited(_todayWidgetBridge.clearForSignOut());
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        auth.currentSession,
      ),
      builder: (context, snapshot) {
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          _queueWidgetPrivacyClear();
          return const UpdatePasswordPage();
        }
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) {
          _queueWidgetPrivacyClear();
          return AuthPage(
            onChangeConnection: widget.onChangeSupabaseConnection,
          );
        }
        _activeOwnerId = session.user.id;
        return _PlannerWorkspaceScope(
          key: ValueKey<String>(session.user.id),
          userId: session.user.id,
          themeMode: widget.themeMode,
          contrastMode: widget.contrastMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onContrastModeChanged: widget.onContrastModeChanged,
        );
      },
    );
  }
}

class _PlannerWorkspaceScope extends StatefulWidget {
  const _PlannerWorkspaceScope({
    super.key,
    required this.userId,
    required this.themeMode,
    required this.contrastMode,
    required this.onThemeModeChanged,
    required this.onContrastModeChanged,
  });

  final String userId;
  final ThemeMode themeMode;
  final PerfectContrastMode contrastMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<PerfectContrastMode> onContrastModeChanged;

  @override
  State<_PlannerWorkspaceScope> createState() => _PlannerWorkspaceScopeState();
}

class _PlannerWorkspaceScopeState extends State<_PlannerWorkspaceScope>
    with WidgetsBindingObserver {
  late final Future<PlannerWorkspaceController> _controllerFuture = _create();
  PlannerWorkspaceController? _controller;
  final PerfectTodayWidgetBridge _todayWidgetBridge =
      const PerfectTodayWidgetBridge();
  final PerfectWorkspaceNavigationController _navigationController =
      PerfectWorkspaceNavigationController();
  late final ReadyFeedbackController _feedbackController;
  StreamSubscription<Uri?>? _widgetLaunchSubscription;
  StreamSubscription<String>? _reminderNavigationSubscription;
  String? _lastLoggedLocalError;
  String? _lastLoggedSyncDiagnostic;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final ownerScope = base64UrlEncode(
      utf8.encode(widget.userId),
    ).replaceAll('=', '');
    _feedbackController = ReadyFeedbackController(
      config: ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'perfect-feedback-$ownerScope',
        settingsKey: 'perfect.feedback_capture_enabled.$ownerScope',
      ),
    );
    unawaited(_initializeFeedback());
    _bindReminderNavigation();
    unawaited(_bindWidgetNavigation());
  }

  Future<void> _initializeFeedback() async {
    try {
      await _feedbackController.initialize();
    } on Object catch (error, stackTrace) {
      ReadyFeedbackLogger.instance.error(
        error,
        stackTrace: stackTrace,
        context: 'Starting owner-scoped feedback capture',
      );
    }
  }

  void _bindReminderNavigation() {
    _reminderNavigationSubscription = PlannerReminderNavigation.entityIds
        .listen(_handleReminderTarget);
    final pendingEntityId = PlannerReminderNavigation.takePendingEntityId();
    if (pendingEntityId != null) _handleReminderTarget(pendingEntityId);
  }

  void _handleReminderTarget(String entityId) {
    if (_isDisposed) return;
    _navigationController.showEntity(entityId);
  }

  Future<void> _bindWidgetNavigation() async {
    _widgetLaunchSubscription = _todayWidgetBridge.widgetLaunchUris().listen(
      _handleWidgetLaunchUri,
    );
    _handleWidgetLaunchUri(await _todayWidgetBridge.initiallyLaunchedUri());
  }

  void _handleWidgetLaunchUri(Uri? uri) {
    if (_isDisposed || !PerfectTodayWidgetBridge.isTodayLaunchUri(uri)) return;
    _navigationController.showToday();
  }

  Future<PlannerWorkspaceController> _create() async {
    PlannerLocalStore? localStore;
    PlannerWorkspaceController? controller;
    try {
      final deviceId = await const PlannerDeviceIdentity().readOrCreate();
      if (_isDisposed) {
        throw StateError('Planner workspace closed during startup.');
      }
      final database = PlannerDatabase();
      localStore = PlannerLocalStore(database);
      final remote = SupabasePlannerRemoteGateway(
        Supabase.instance.client,
        ownerId: widget.userId,
      );
      final syncRepository = PlannerSyncRepository(
        localStore,
        remote,
        ownerId: widget.userId,
        deviceId: deviceId,
      );
      controller = PlannerWorkspaceController(
        localStore,
        syncRepository,
        ownerId: widget.userId,
        reminderScheduler: DevicePlannerReminderScheduler(
          recurrenceHistory: (entity, day) => localStore!.readRecurrenceHistory(
            ownerId: widget.userId,
            entity: entity,
            day: day,
          ),
        ),
        todayWidgetBridge: _todayWidgetBridge,
      );
      _controller = controller;
      controller.addListener(_capturePlannerDiagnostics);
      if (_isDisposed) controller.requestShutdown();
      await controller.start();
      if (_isDisposed) {
        controller.requestShutdown();
        await controller.disposeAsync();
      }
      return controller;
    } on Object {
      if (controller != null) {
        controller.requestShutdown();
        await controller.disposeAsync();
      } else if (localStore != null) {
        await localStore.close();
      }
      rethrow;
    }
  }

  void _capturePlannerDiagnostics() {
    final controller = _controller;
    if (_isDisposed || controller == null) return;

    final localError = controller.localError?.toString().trim();
    if (localError == null || localError.isEmpty) {
      _lastLoggedLocalError = null;
    } else if (localError != _lastLoggedLocalError) {
      _lastLoggedLocalError = localError;
      ReadyFeedbackLogger.instance.error(
        localError,
        context: 'Planner local data',
      );
    }

    final syncStatus = controller.syncStatus;
    final syncMessage = syncStatus.message?.trim();
    final shouldCaptureSync =
        syncMessage != null &&
        syncMessage.isNotEmpty &&
        (syncStatus.phase == PlannerSyncPhase.offline ||
            syncStatus.phase == PlannerSyncPhase.needsAttention);
    if (!shouldCaptureSync) {
      // Keep the last failure through the transient syncing phase so every
      // automatic retry does not duplicate the same diagnostic. A confirmed
      // successful idle state re-arms capture for a later regression.
      if (syncStatus.phase == PlannerSyncPhase.idle) {
        _lastLoggedSyncDiagnostic = null;
      }
      return;
    }
    final diagnostic = '${syncStatus.phase.name}:$syncMessage';
    if (diagnostic == _lastLoggedSyncDiagnostic) return;
    _lastLoggedSyncDiagnostic = diagnostic;
    ReadyFeedbackLogger.instance.warning(
      syncMessage,
      context: syncStatus.phase == PlannerSyncPhase.offline
          ? 'Planner sync offline; automatic retry remains active'
          : 'Planner sync needs attention; automatic retry remains active',
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final widgetLaunchSubscription = _widgetLaunchSubscription;
    if (widgetLaunchSubscription != null) {
      unawaited(widgetLaunchSubscription.cancel());
    }
    final reminderNavigationSubscription = _reminderNavigationSubscription;
    if (reminderNavigationSubscription != null) {
      unawaited(reminderNavigationSubscription.cancel());
    }
    _navigationController.dispose();
    // The feedback controller explicitly makes in-flight initialization safe
    // after disposal. Detach its owner-scoped repository immediately so a
    // fast sign-out cannot keep routing new global logs into the old owner.
    _feedbackController.dispose();
    final controller = _controller;
    controller?.removeListener(_capturePlannerDiagnostics);
    controller?.requestShutdown();
    // Startup owns the database until its current await completes. Disposing
    // through the same future prevents close-vs-start races and guarantees that
    // an auth scope removed mid-bootstrap cannot leak an old-owner controller.
    unawaited(
      _controllerFuture.then(
        (created) => created.disposeAsync(),
        onError: (Object _, StackTrace _) {},
      ),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAfterResume());
    }
  }

  Future<void> _refreshAfterResume() async {
    final controller = _controller;
    if (controller == null || _isDisposed) return;
    await controller.resume();
  }

  Future<void> _signOut() async {
    await _controller?.clearTodayWidgetForSignOut();
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<PlannerWorkspaceController>(
        future: _controllerFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _BootstrapFailure(error: snapshot.error);
          }
          final controller = snapshot.data;
          if (controller == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return PerfectWorkspacePage(
            controller: controller,
            feedbackController: _feedbackController,
            aiClient: SupabasePerfectAiClient(Supabase.instance.client),
            themeMode: widget.themeMode,
            contrastMode: widget.contrastMode,
            onThemeModeChanged: widget.onThemeModeChanged,
            onContrastModeChanged: widget.onContrastModeChanged,
            onSignOut: _signOut,
            navigationController: _navigationController,
          );
        },
      );
}

class _BootstrapFailure extends StatelessWidget {
  const _BootstrapFailure({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfect needs local storage',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your remote data has not been changed. Restart the app after checking local disk access.',
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  SelectableText('$error'),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
