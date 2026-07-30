import 'package:flutter/material.dart';
import 'package:perfect/app/app_config.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Private-owner access only. There is intentionally no public sign-up path.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onChangeConnection});

  final Future<void> Function()? onChangeConnection;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _recoveryMode = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@')) {
      setState(() => _message = 'Enter the private account email.');
      return;
    }
    if (!_recoveryMode && password.length < 8) {
      setState(() => _message = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_recoveryMode) {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          email,
          redirectTo: AppConfig.authRedirectUri,
        );
        if (mounted) {
          setState(
            () => _message =
                'Recovery instructions were sent to the private inbox.',
          );
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
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

  Future<void> _changeConnection() async {
    final onChangeConnection = widget.onChangeConnection;
    if (onChangeConnection == null || _busy) return;
    final confirmed = await showDialog<bool>(
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
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: _recoveryMode
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) {
                        if (_recoveryMode) _submit();
                      },
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    if (!_recoveryMode) ...[
                      const SizedBox(height: PerfectSpace.sm),
                      TextField(
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
                              ? PerfectColors.mint
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
                      'This app has no public registration. The one private owner is approved in Supabase before first access.',
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
    if (_password.text.length < 12) {
      setState(
        () => _message =
            'Choose at least 12 characters for this private account.',
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
