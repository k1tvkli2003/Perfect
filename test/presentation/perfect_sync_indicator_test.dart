import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_sync_indicator.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  testWidgets('sync indicator has explicit icon, text and semantic states', (
    tester,
  ) async {
    for (final testCase
        in <({PlannerSyncPhase phase, String label, IconData icon})>[
          (
            phase: PlannerSyncPhase.idle,
            label: 'Up to date',
            icon: Icons.cloud_done_rounded,
          ),
          (
            phase: PlannerSyncPhase.syncing,
            label: 'Syncing',
            icon: Icons.cloud_sync_rounded,
          ),
          (
            phase: PlannerSyncPhase.offline,
            label: 'Retrying',
            icon: Icons.cloud_queue_rounded,
          ),
          (
            phase: PlannerSyncPhase.needsAttention,
            label: 'Sync issue',
            icon: Icons.cloud_off_rounded,
          ),
        ]) {
      await _pumpIndicator(
        tester,
        status: PlannerSyncStatus(phase: testCase.phase),
      );
      expect(find.text(testCase.label), findsOneWidget);
      expect(find.byIcon(testCase.icon), findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('perfect-sync-indicator')),
      );
      expect(semantics.label, contains(testCase.label));
      expect(semantics.label, contains('Tap for sync details and retry'));
    }
  });

  testWidgets('yellow flow pulses unless reduced motion is requested', (
    tester,
  ) async {
    await _pumpIndicator(
      tester,
      status: const PlannerSyncStatus(phase: PlannerSyncPhase.syncing),
    );
    expect(tester.hasRunningAnimations, isTrue);

    await _pumpIndicator(
      tester,
      status: const PlannerSyncStatus(phase: PlannerSyncPhase.syncing),
      disableAnimations: true,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse);

    await _pumpIndicator(
      tester,
      status: const PlannerSyncStatus(phase: PlannerSyncPhase.idle),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'red details protect local-first use and Retry Now invokes sync',
    (tester) async {
      var retries = 0;
      await _pumpIndicator(
        tester,
        status: const PlannerSyncStatus(
          phase: PlannerSyncPhase.needsAttention,
          message: 'postgres-password=must-never-render',
        ),
        onRetry: () async => retries++,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-sync-indicator')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sync issue'), findsWidgets);
      expect(
        find.textContaining('Local-first mode stays available'),
        findsOneWidget,
      );
      expect(find.textContaining('postgres-password'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('perfect-sync-retry-now')),
      );
      await tester.pumpAndSettle();
      expect(retries, 1);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'compact phone state hides text but keeps a 48dp semantic target',
    (tester) async {
      await _pumpIndicator(
        tester,
        status: const PlannerSyncStatus(phase: PlannerSyncPhase.offline),
        compact: true,
      );

      expect(find.text('Retrying'), findsNothing);
      final size = tester.getSize(
        find.byKey(const ValueKey<String>('perfect-sync-indicator')),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      final control = tester.widget<InkWell>(
        find.byKey(const ValueKey<String>('perfect-sync-indicator')),
      );
      expect(control.mouseCursor, SystemMouseCursors.click);
      expect(control.canRequestFocus, isTrue);
      control.focusNode!.requestFocus();
      await tester.pump();
      expect(control.focusNode!.hasFocus, isTrue);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey<String>('perfect-sync-indicator')),
            )
            .label,
        contains('Retrying'),
      );
    },
  );
}

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required PlannerSyncStatus status,
  Future<void> Function()? onRetry,
  bool compact = false,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(disableAnimations: disableAnimations),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: Center(
          child: PerfectSyncIndicator(
            status: status,
            compact: compact,
            onRetry: onRetry ?? () async {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
