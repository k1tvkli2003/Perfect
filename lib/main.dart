import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect/app/app_config.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/auth/auth_page.dart';
import 'package:perfect/auth/configuration_page.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/notifications/planner_reminder_scheduler.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/perfect_workspace_page.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';
import 'package:perfect/widgets/perfect_today_widget_background.dart';
import 'package:perfect/widgets/perfect_today_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();
  var supabaseReady = false;
  Object? configurationError;
  if (AppConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
      supabaseReady = true;
    } on Object catch (error) {
      configurationError = error;
    }
  }

  // Android registers a background callback for direct home-screen task
  // actions. The helper is no-op-safe on Windows and never blocks startup.
  await registerPerfectTodayWidgetBackgroundCallback();

  final themeMode = await PerfectPreferences.readThemeMode();
  runApp(
    PerfectApp(
      initialThemeMode: themeMode,
      initialSupabaseReady: supabaseReady,
      initialConfigurationError: configurationError,
    ),
  );
}

class PerfectApp extends StatefulWidget {
  const PerfectApp({
    super.key,
    this.initialThemeMode = ThemeMode.system,
    this.initialSupabaseReady = false,
    this.initialConfigurationError,
  });

  final ThemeMode initialThemeMode;
  final bool initialSupabaseReady;
  final Object? initialConfigurationError;

  @override
  State<PerfectApp> createState() => _PerfectAppState();
}

class _PerfectAppState extends State<PerfectApp> {
  late ThemeMode _themeMode = widget.initialThemeMode;
  late bool _supabaseReady = widget.initialSupabaseReady;
  late Object? _configurationError = widget.initialConfigurationError;

  void _changeThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    setState(() => _themeMode = value);
    unawaited(PerfectPreferences.saveThemeMode(value));
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
  Widget build(BuildContext context) => MaterialApp(
    title: 'Perfect!',
    debugShowCheckedModeBanner: false,
    theme: PerfectTheme.light(),
    darkTheme: PerfectTheme.dark(),
    themeMode: _themeMode,
    home: _supabaseReady
        ? _AuthenticatedApp(
            themeMode: _themeMode,
            onThemeModeChanged: _changeThemeMode,
            onChangeSupabaseConnection: _changeSupabaseConnection,
          )
        : ConfigurationPage(
            onConnect: _configureSupabase,
            initialError: _configurationError,
          ),
  );
}

class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onChangeSupabaseConnection,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
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
          onThemeModeChanged: widget.onThemeModeChanged,
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
    required this.onThemeModeChanged,
  });

  final String userId;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

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
  StreamSubscription<Uri?>? _widgetLaunchSubscription;
  StreamSubscription<String>? _reminderNavigationSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindReminderNavigation();
    unawaited(_bindWidgetNavigation());
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
    final controller = _controller;
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
    await controller.reconcileTodayWidgetActions();
    if (_isDisposed) return;
    await controller.refreshTodayProjection();
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
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
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
