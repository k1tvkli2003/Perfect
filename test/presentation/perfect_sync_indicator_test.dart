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
        in <({PlannerSyncPhase phase, String label, Color color})>[
          (
            phase: PlannerSyncPhase.idle,
            label: 'Synced',
            color: PerfectSemanticTheme.light.sync,
          ),
          (
            phase: PlannerSyncPhase.syncing,
            label: 'Syncing',
            color: PerfectSemanticTheme.light.warning,
          ),
          (
            phase: PlannerSyncPhase.offline,
            label: 'Retrying',
            color: PerfectSemanticTheme.light.warning,
          ),
          (
            phase: PlannerSyncPhase.needsAttention,
            label: 'Sync issue',
            color: PerfectSemanticTheme.light.danger,
          ),
        ]) {
      await _pumpIndicator(
        tester,
        status: PlannerSyncStatus(phase: testCase.phase),
      );
      expect(find.text(testCase.label), findsOneWidget);
      expect(
        find.byKey(
          ValueKey<String>('perfect-sync-mark-${testCase.phase.name}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('perfect-sync-cloud-artwork')),
        findsOneWidget,
      );
      final surface = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey<String>('perfect-sync-surface')),
      );
      expect(
        (surface.decoration! as BoxDecoration).color,
        testCase.color.withValues(alpha: .055),
      );
      final semantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('perfect-sync-indicator')),
      );
      expect(semantics.label, contains(testCase.label));
      expect(semantics.label, contains('Sync status'));
      expect(semantics.hint, contains('Open sync details'));
    }
  });

  testWidgets('yellow flow rotates unless reduced motion is requested', (
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
      expect(find.byType(Dialog), findsNothing);
    },
  );

  testWidgets('yellow retry exposes repository deadline without hiding state', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 6, 5, 24, 30);
    await _pumpIndicator(
      tester,
      status: PlannerSyncStatus(
        phase: PlannerSyncPhase.offline,
        nextRetryAt: now.add(const Duration(seconds: 5)),
        retryAttempt: 2,
      ),
      now: () => now,
    );

    expect(find.text('Retry 5s'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey<String>('perfect-sync-indicator')),
    );
    expect(semantics.label, contains('Retrying'));
    expect(semantics.label, contains('Automatic retry in 5 seconds'));

    await tester.tap(
      find.byKey(const ValueKey<String>('perfect-sync-indicator')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Retrying'), findsOneWidget);
    expect(find.text('Automatic retry in 5 seconds.'), findsOneWidget);
  });

  testWidgets(
    'compact phone state keeps concise text and a 48dp semantic target',
    (tester) async {
      await _pumpIndicator(
        tester,
        status: const PlannerSyncStatus(phase: PlannerSyncPhase.offline),
        compact: true,
      );

      expect(find.text('Retrying'), findsOneWidget);
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
      final surface = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey<String>('perfect-sync-surface')),
      );
      expect(
        ((surface.decoration! as BoxDecoration).border! as Border).top.color,
        PerfectTheme.light().colorScheme.primary,
      );
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
  DateTime Function()? now,
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
            now: now ?? DateTime.now,
            onRetry: onRetry ?? () async {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
