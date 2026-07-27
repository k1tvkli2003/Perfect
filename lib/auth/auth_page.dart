import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool signUp}) async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || password.length < 8) {
      setState(() => _message = 'یک ایمیل معتبر و گذرواژهٔ حداقل ۸ کاراکتری وارد کن.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (signUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted && response.session == null) {
          setState(() => _message = 'ایمیل تأیید ارسال شد؛ سپس وارد شو.');
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Perfect', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      const Text('فضای شخصی شما؛ میان دستگاه‌ها همگام.'),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'ایمیل'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _submit(signUp: false),
                        decoration: const InputDecoration(labelText: 'گذرواژه'),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : () => _submit(signUp: false),
                        child: Text(_busy ? 'در حال اتصال…' : 'ورود'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => _submit(signUp: true),
                        child: const Text('ساخت حساب شخصی'),
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
