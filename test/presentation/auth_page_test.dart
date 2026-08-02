import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/auth/auth_page.dart';
import 'package:perfect/auth/private_owner_identity.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  const identity = PrivateOwnerIdentity(
    username: 'keyvan',
    email: 'owner@perfect.test',
  );

  testWidgets('private username leaves password policy to Supabase', (
    tester,
  ) async {
    String? submittedEmail;
    String? submittedPassword;
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: AuthPage(
          ownerIdentity: identity,
          signIn: ({required email, required password}) async {
            submittedEmail = email;
            submittedPassword = password;
          },
        ),
      ),
    );

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('private-owner-username')),
      ' KeyVan ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('private-owner-password')),
      '0000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in privately'));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'owner@perfect.test');
    expect(submittedPassword, '0000');
    expect(find.text('Enter your password.'), findsNothing);
  });

  testWidgets('unknown username never reaches private authentication', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: AuthPage(
          ownerIdentity: identity,
          signIn: ({required email, required password}) async => attempts++,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('private-owner-username')),
      'someone-else',
    );
    await tester.enterText(
      find.byKey(const ValueKey('private-owner-password')),
      '0000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in privately'));
    await tester.pump();

    expect(attempts, 0);
    expect(find.text('Use the private username keyvan.'), findsOneWidget);
  });

  testWidgets('recovery resolves the username without exposing email', (
    tester,
  ) async {
    String? recoveryEmail;
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: AuthPage(
          ownerIdentity: identity,
          sendPasswordRecovery: ({required email, required redirectTo}) async {
            recoveryEmail = email;
          },
        ),
      ),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('private-owner-username')),
      'keyvan',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Send recovery instructions'),
    );
    await tester.pumpAndSettle();

    expect(recoveryEmail, 'owner@perfect.test');
    expect(
      find.text('Recovery instructions were sent to the private inbox.'),
      findsOneWidget,
    );
    expect(find.textContaining('owner@perfect.test'), findsNothing);
  });

  testWidgets(
    'wrong project recovery confirms before replacing device connection',
    (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: AuthPage(
            ownerIdentity: identity,
            onChangeConnection: () async {
              changes++;
            },
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('change-supabase-connection')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change this device’s connection?'), findsOneWidget);
      expect(find.textContaining('local planner data stays'), findsOneWidget);
      expect(changes, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'Change connection'));
      await tester.pumpAndSettle();

      expect(changes, 1);
      expect(find.text('Change this device’s connection?'), findsNothing);
    },
  );
}
