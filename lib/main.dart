import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect/app/app_config.dart';
import 'package:perfect/app/personal_items_controller.dart';
import 'package:perfect/app/personal_items_store.dart';
import 'package:perfect/app/sync_repository.dart';
import 'package:perfect/auth/auth_page.dart';
import 'package:perfect/auth/configuration_page.dart';
import 'package:perfect/workspace/workspace_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  runApp(const PerfectApp());
}

class PerfectApp extends StatelessWidget {
  const PerfectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff9ee37d),
          brightness: Brightness.dark,
          surface: const Color(0xff111827),
        ),
        scaffoldBackgroundColor: const Color(0xff080d18),
        useMaterial3: true,
      ),
      home: AppConfig.isConfigured
          ? const _AuthenticatedApp()
          : const ConfigurationPage(),
    );
  }
}

class _AuthenticatedApp extends StatelessWidget {
  const _AuthenticatedApp();

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, auth.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) {
          return const AuthPage();
        }
        return _WorkspaceScope(userId: session.user.id);
      },
    );
  }
}

class _WorkspaceScope extends StatefulWidget {
  const _WorkspaceScope({required this.userId});

  final String userId;

  @override
  State<_WorkspaceScope> createState() => _WorkspaceScopeState();
}

class _WorkspaceScopeState extends State<_WorkspaceScope> {
  late final PersonalItemsController _controller;

  @override
  void initState() {
    super.initState();
    final repository = SyncRepository(
      client: Supabase.instance.client,
      userId: widget.userId,
      store: PersonalItemsStore(),
    );
    _controller = PersonalItemsController(repository)..start();
  }

  @override
  void dispose() {
    unawaited(_controller.disposeAsync());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WorkspacePage(controller: _controller);
}
