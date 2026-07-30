import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/app/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppConfig.resetForTesting();
  });

  test(
    'device configuration persists the public Supabase client values',
    () async {
      const key = 'sb_publishable_123456789012345678901234567890';
      await AppConfig.configureDevice(
        supabaseUrl: 'https://personal-perfect.supabase.co',
        publishableKey: key,
      );
      expect(AppConfig.isConfigured, isTrue);

      AppConfig.resetForTesting();
      await AppConfig.load();
      expect(AppConfig.supabaseUrl, 'https://personal-perfect.supabase.co');
      expect(AppConfig.supabasePublishableKey, key);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool('perfect.supabase_device_override.v1'),
        isTrue,
      );
      expect(
        preferences.getString('perfect.supabase_connection.v2'),
        contains('personal-perfect.supabase.co'),
      );
      expect(preferences.getString('perfect.supabase_url.v1'), isNull);
      expect(
        preferences.getString('perfect.supabase_publishable_key.v1'),
        isNull,
      );
    },
  );

  test('an invalid partial saved connection fails closed on load', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'perfect.supabase_url.v1': 'https://wrong.supabase.co',
      'perfect.supabase_publishable_key.v1': 'short',
      'perfect.supabase_device_override.v1': true,
    });

    await AppConfig.load();

    expect(AppConfig.isConfigured, isFalse);
    expect(AppConfig.supabaseUrl, isEmpty);
    expect(AppConfig.supabasePublishableKey, isEmpty);
  });

  test(
    'a corrupt atomic connection never falls through as configured',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'perfect.supabase_connection.v2': '{"url":"https://wrong.supabase.co"',
        'perfect.supabase_device_override.v1': true,
      });

      await AppConfig.load();

      expect(AppConfig.isConfigured, isFalse);
    },
  );

  test('service role and secret key shapes are rejected', () {
    expect(
      AppConfig.validate(
        supabaseUrl: 'https://personal-perfect.supabase.co',
        publishableKey:
            'sb_'
            'secret_synthetic_test_value_000000000000',
      ),
      contains('must never'),
    );
    final serviceRoleJwt = [
      _segment(<String, dynamic>{'alg': 'HS256', 'typ': 'JWT'}),
      _segment(<String, dynamic>{'role': 'service_role'}),
      'signature-long-enough',
    ].join('.');
    expect(
      AppConfig.validate(
        supabaseUrl: 'https://personal-perfect.supabase.co',
        publishableKey: serviceRoleJwt,
      ),
      contains('must never'),
    );
  });

  test(
    'insecure remote URLs fail closed while local development stays valid',
    () {
      const key = 'sb_publishable_123456789012345678901234567890';
      expect(
        AppConfig.validate(
          supabaseUrl: 'http://example.com',
          publishableKey: key,
        ),
        contains('HTTPS'),
      );
      expect(
        AppConfig.validate(
          supabaseUrl: 'http://localhost:54321',
          publishableKey: key,
        ),
        isNull,
      );
    },
  );
}

String _segment(Map<String, dynamic> value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
