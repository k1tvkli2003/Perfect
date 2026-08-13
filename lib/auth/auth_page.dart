import 'package:flutter/material.dart';
import 'package:perfect/app/app_config.dart';
import 'package:perfect/auth/private_owner_identity.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef PrivateOwnerSignIn =
    Future<void> Function({required String email, required String password});
typedef PrivateOwnerPasswordRecovery =
    Future<void> Function({required String email, required String redirectTo});

/// Private-owner access only. There is intentionally no public sign-up path.
class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.onChangeConnection,
    this.ownerIdentity = const PrivateOwnerIdentity.compiled(),
    this.signIn,
    this.sendPasswordRecovery,
  });

  final Future<void> Function()? onChangeConnection;
  final PrivateOwnerIdentity ownerIdentity;
  final PrivateOwnerSignIn? signIn;
  final PrivateOwnerPasswordRecovery? sendPasswordRecovery;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _recoveryMode = false;
  String? _message;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (!widget.ownerIdentity.recognizes(username)) {
      setState(
        () => _message =
            'Use the private username ${widget.ownerIdentity.username}.',
      );
      return;
    }
    final email = widget.ownerIdentity.resolveEmail(username);
    if (email == null) {
      setState(
        () => _message =
            'This build is missing the private account identity. Install a trusted Perfect release.',
      );
      return;
    }
    if (!_recoveryMode && password.isEmpty) {
      setState(() => _message = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_recoveryMode) {
        final recover =
            widget.sendPasswordRecovery ?? _sendSupabasePasswordRecovery;
        await recover(email: email, redirectTo: AppConfig.authRedirectUri);
        if (mounted) {
          setState(
            () => _message =
                'Recovery instructions were sent to the private inbox.',
          );
        }
      } else {
        final signIn = widget.signIn ?? _signInWithSupabase;
        await signIn(email: email, password: password);
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(
          () => _message = _recoveryMode
              ? error.message
              : 'The username or password is incorrect.',
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Perfect could not reach this private project. Check the connection or change this device’s Supabase settings.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static Future<void> _signInWithSupabase({
    required String email,
    required String password,
  }) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> _sendSupabasePasswordRecovery({
    required String email,
    required String redirectTo,
  }) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  Future<void> _changeConnection() async {
    final onChangeConnection = widget.onChangeConnection;
    if (onChangeConnection == null || _busy) return;
    final confirmed = await showPerfectDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change this device’s connection?'),
        content: const Text(
          'Your local planner data stays on this device. Perfect will close the current unauthenticated Supabase client, then let you replace its project URL and publishable key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep current'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change connection'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await onChangeConnection();
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Perfect could not close the current connection. Restart the app and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PerfectSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(PerfectSpace.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: PerfectMark(size: 68)),
                    const SizedBox(height: PerfectSpace.md),
                    const Center(child: PerfectWordmark(fontSize: 38)),
                    const SizedBox(height: PerfectSpace.xxl),
                    Text(
                      _recoveryMode
                          ? 'Recover private access'
                          : 'Welcome back.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: PerfectSpace.xs),
                    Text(
                      _recoveryMode
                          ? 'We will use the approved Perfect redirect to finish the password reset.'
                          : 'Your workspace opens from the local copy first, then catches up privately.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: PerfectSpace.lg),
                    TextField(
                      key: const ValueKey('private-owner-username'),
                      controller: _username,
                      keyboardType: TextInputType.text,
                      textInputAction: _recoveryMode
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) {
                        if (_recoveryMode) _submit();
                      },
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    if (!_recoveryMode) ...[
                      const SizedBox(height: PerfectSpace.sm),
                      TextField(
                        key: const ValueKey('private-owner-password'),
                        controller: _password,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: PerfectSpace.sm),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.startsWith('Recovery')
                              ? PerfectSemanticTheme.of(context).secondary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: PerfectSpace.lg),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        _busy
                            ? 'Working…'
                            : _recoveryMode
                            ? 'Send recovery instructions'
                            : 'Sign in privately',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _recoveryMode = !_recoveryMode;
                              _message = null;
                            }),
                      child: Text(
                        _recoveryMode ? 'Back to sign in' : 'Forgot password?',
                      ),
                    ),
                    if (widget.onChangeConnection != null)
                      OutlinedButton.icon(
                        key: const ValueKey('change-supabase-connection'),
                        onPressed: _busy ? null : _changeConnection,
                        icon: const Icon(Icons.settings_ethernet_rounded),
                        label: const Text('Change this device’s connection'),
                      ),
                    const SizedBox(height: PerfectSpace.xs),
                    Text(
                      'This app has no public registration. Only the private Perfect account can sign in.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_password.text.length < 8) {
      setState(
        () =>
            _message = 'Choose at least 8 characters for this private account.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _password.text),
      );
      if (mounted) {
        setState(
          () => _message = 'Password updated. Your private workspace is ready.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(PerfectSpace.xl),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(PerfectSpace.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PerfectWordmark(fontSize: 34, includeMark: true),
                    const SizedBox(height: PerfectSpace.xxl),
                    Text(
                      'Set a new password',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: PerfectSpace.sm),
                    TextField(
                      controller: _password,
                      autofocus: true,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      onSubmitted: (_) => _update(),
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: PerfectSpace.sm),
                      Text(_message!),
                    ],
                    const SizedBox(height: PerfectSpace.lg),
                    FilledButton(
                      onPressed: _busy ? null : _update,
                      child: Text(_busy ? 'Updating…' : 'Update password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
