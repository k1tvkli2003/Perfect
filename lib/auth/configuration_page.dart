import 'package:flutter/material.dart';
import 'package:perfect/app/app_config.dart';
import 'package:perfect/presentation/perfect_brand.dart';
import 'package:perfect/presentation/perfect_theme.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({
    super.key,
    required this.onConnect,
    this.initialError,
  });

  final Future<void> Function({
    required String supabaseUrl,
    required String publishableKey,
  })
  onConnect;
  final Object? initialError;

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _url = TextEditingController(
    text: AppConfig.supabaseUrl,
  );
  late final TextEditingController _key = TextEditingController(
    text: AppConfig.supabasePublishableKey,
  );
  bool _hideKey = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialError != null) {
      _error =
          'Perfect could not initialize the saved connection. Check the project URL and publishable key, then try again.';
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PerfectSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(PerfectSpace.xxl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PerfectWordmark(fontSize: 42, includeMark: true),
                      const SizedBox(height: PerfectSpace.xxl),
                      Text(
                        'Connect your private space',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: PerfectSpace.sm),
                      const Text(
                        'Enter this device’s Supabase project URL and publishable (anon) key. They are saved only in this installation; a service-role or secret key is rejected.',
                      ),
                      const SizedBox(height: PerfectSpace.lg),
                      TextFormField(
                        controller: _url,
                        enabled: !_busy,
                        keyboardType: TextInputType.url,
                        textDirection: TextDirection.ltr,
                        autofillHints: const <String>[AutofillHints.url],
                        decoration: const InputDecoration(
                          labelText: 'Supabase project URL',
                          hintText: 'https://your-project.supabase.co',
                          prefixIcon: Icon(Icons.cloud_outlined),
                        ),
                        validator: (value) {
                          final uri = Uri.tryParse(value?.trim() ?? '');
                          if (uri == null ||
                              uri.host.isEmpty ||
                              (uri.scheme != 'https' &&
                                  !(uri.scheme == 'http' &&
                                      (uri.host == 'localhost' ||
                                          uri.host == '127.0.0.1')))) {
                            return 'Use the HTTPS project URL from Supabase.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: PerfectSpace.sm),
                      TextFormField(
                        controller: _key,
                        enabled: !_busy,
                        obscureText: _hideKey,
                        textDirection: TextDirection.ltr,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Publishable (anon) key',
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            tooltip: _hideKey ? 'Show key' : 'Hide key',
                            onPressed: _busy
                                ? null
                                : () => setState(() => _hideKey = !_hideKey),
                            icon: Icon(
                              _hideKey
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final message = AppConfig.validate(
                            supabaseUrl: _url.text,
                            publishableKey: value ?? '',
                          );
                          return message;
                        },
                        onFieldSubmitted: (_) {
                          if (!_busy) _connect();
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: PerfectSpace.md),
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(PerfectSpace.md),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: PerfectSpace.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _connect,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open_rounded),
                          label: Text(
                            _busy
                                ? 'Connecting this device…'
                                : 'Connect device',
                          ),
                        ),
                      ),
                      const SizedBox(height: PerfectSpace.lg),
                      const _SetupStep(
                        number: '1',
                        text:
                            'Apply the additive v2 SQL migration. It does not delete or rewrite perfect_items.',
                      ),
                      const _SetupStep(
                        number: '2',
                        text:
                            'Create exactly one planner_owner_profiles row for your existing private Auth user.',
                      ),
                      const _SetupStep(
                        number: '3',
                        text:
                            'Allowlist perfect://login-callback in Supabase Auth for password recovery.',
                      ),
                      const SizedBox(height: PerfectSpace.sm),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Build-time configuration'),
                        subtitle: const Text(
                          'Optional for preconfigured private APK/Windows builds',
                        ),
                        children: const <Widget>[
                          _Command(
                            command:
                                'flutter run -d windows '
                                '--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co '
                                '--dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY',
                          ),
                          SizedBox(height: PerfectSpace.sm),
                          _Command(
                            command:
                                'flutter run -d android '
                                '--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co '
                                '--dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY',
                          ),
                        ],
                      ),
                      const SizedBox(height: PerfectSpace.sm),
                      Text(
                        'Android + Windows only. Web is deliberately out of scope for this private install.',
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
    ),
  );

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConnect(
        supabaseUrl: _url.text.trim(),
        publishableKey: _key.text.trim(),
      );
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Connection setup could not finish. Your planner data was not changed; verify the project values and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Command extends StatelessWidget {
  const _Command({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(PerfectSpace.md),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff2a2d3e)
          : const Color(0xfff7f2eb),
      borderRadius: BorderRadius.circular(18),
    ),
    child: SelectableText(command, textDirection: TextDirection.ltr),
  );
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PerfectSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: PerfectColors.apricotSoft,
          foregroundColor: PerfectColors.ink,
          child: Text(number),
        ),
        const SizedBox(width: PerfectSpace.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
