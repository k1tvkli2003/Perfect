import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/app/app_config.dart';
import 'package:perfect/auth/configuration_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppConfig.resetForTesting();
  });

  testWidgets('an unconfigured install can connect itself without a rebuild', (
    tester,
  ) async {
    String? submittedUrl;
    String? submittedKey;
    await tester.pumpWidget(
      MaterialApp(
        home: ConfigurationPage(
          onConnect:
              ({
                required String supabaseUrl,
                required String publishableKey,
              }) async {
                submittedUrl = supabaseUrl;
                submittedKey = publishableKey;
              },
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://personal-perfect.supabase.co',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'sb_publishable_123456789012345678901234567890',
    );
    await tester.tap(find.text('Connect device'));
    await tester.pump();

    expect(submittedUrl, 'https://personal-perfect.supabase.co');
    expect(submittedKey, 'sb_publishable_123456789012345678901234567890');
  });

  testWidgets('a privileged key is stopped before the connection callback', (
    tester,
  ) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ConfigurationPage(
          onConnect:
              ({
                required String supabaseUrl,
                required String publishableKey,
              }) async {
                submitted = true;
              },
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://personal-perfect.supabase.co',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'sb_'
      'secret_synthetic_test_value_000000000000',
    );
    await tester.tap(find.text('Connect device'));
    await tester.pump();

    expect(submitted, isFalse);
    expect(find.textContaining('must never'), findsOneWidget);
  });
}
