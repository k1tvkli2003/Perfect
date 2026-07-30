import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/auth/auth_page.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  testWidgets(
    'wrong project recovery confirms before replacing device connection',
    (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          home: AuthPage(
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
