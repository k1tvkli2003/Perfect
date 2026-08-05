import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/auth/auth_page.dart';
import 'package:perfect/auth/configuration_page.dart';
import 'package:perfect/main.dart';
import 'package:perfect/presentation/perfect_brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'first frame is branded while config and widget registration run after it',
    (tester) async {
      final bootstrap = Completer<PerfectAppBootstrapResult>();
      final widgetRegistration = Completer<void>();
      var bootstrapCalls = 0;
      var widgetRegistrationCalls = 0;

      await tester.pumpWidget(
        PerfectApp(
          bootstrapper: () {
            bootstrapCalls++;
            return bootstrap.future;
          },
          widgetBackgroundRegistrar: () {
            widgetRegistrationCalls++;
            return widgetRegistration.future;
          },
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('perfect-bootstrap')),
        findsOneWidget,
      );
      expect(find.byType(PerfectWordmark), findsOneWidget);
      expect(find.bySemanticsLabel('Perfect!'), findsNWidgets(2));
      expect(find.text('Opening your day'), findsOneWidget);
      expect(find.byType(ConfigurationPage), findsNothing);
      expect(find.byType(AuthPage), findsNothing);
      expect(bootstrapCalls, 1);
      expect(widgetRegistrationCalls, 1);

      bootstrap.complete(
        const PerfectAppBootstrapResult(
          themeMode: ThemeMode.dark,
          supabaseReady: false,
        ),
      );
      await tester.pump();

      expect(find.byType(ConfigurationPage), findsOneWidget);
      expect(
        widgetRegistration.isCompleted,
        isFalse,
        reason:
            'A stalled platform widget channel must not hold app bootstrap.',
      );

      widgetRegistration.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('late bootstrap completion never updates a disposed app', (
    tester,
  ) async {
    final bootstrap = Completer<PerfectAppBootstrapResult>();
    final widgetRegistration = Completer<void>();

    await tester.pumpWidget(
      PerfectApp(
        bootstrapper: () => bootstrap.future,
        widgetBackgroundRegistrar: () => widgetRegistration.future,
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());

    bootstrap.complete(
      const PerfectAppBootstrapResult(
        themeMode: ThemeMode.light,
        supabaseReady: false,
      ),
    );
    widgetRegistration.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('bootstrap errors resolve to configuration without a flash', (
    tester,
  ) async {
    final bootstrap = Completer<PerfectAppBootstrapResult>();

    await tester.pumpWidget(
      PerfectApp(
        bootstrapper: () => bootstrap.future,
        widgetBackgroundRegistrar: () async {},
      ),
    );
    expect(find.byType(ConfigurationPage), findsNothing);

    bootstrap.completeError(StateError('private config unavailable'));
    await tester.pump();

    expect(find.byType(ConfigurationPage), findsOneWidget);
    expect(find.textContaining('could not initialize'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
