import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_workspace_header.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final latin = FontLoader('PlusJakarta')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    final persian = FontLoader('Vazirmatn')
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Variable.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait<void>(<Future<void>>[
      latin.load(),
      persian.load(),
      icons.load(),
    ]);
  });

  testWidgets('wide glass header keeps live dual date and sync in one system', (
    tester,
  ) async {
    await _pumpHeader(
      tester,
      size: const Size(980, 180),
      now: () => DateTime(2026, 8, 6, 9, 24),
    );

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('9:24 AM'), findsOneWidget);
    expect(find.text('Thursday, August 6'), findsOneWidget);
    expect(find.text('۱۵ مرداد ۱۴۰۵'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('perfect-header-context-row')),
      findsOneWidget,
    );
    final glass = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-workspace-glass-header')),
    );
    final clock = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-dual-date-clock')),
    );
    final sync = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-sync-surface')),
    );
    expect(glass.contains(clock.topLeft), isTrue);
    expect(glass.contains(clock.bottomRight), isTrue);
    expect(glass.contains(sync.topLeft), isTrue);
    expect(glass.contains(sync.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow 200 percent text reflows instead of colliding', (
    tester,
  ) async {
    await _pumpHeader(
      tester,
      size: const Size(540, 260),
      textScaler: const TextScaler.linear(2),
      now: () => DateTime(2026, 8, 6, 21, 4),
    );

    expect(
      find.byKey(const ValueKey<String>('perfect-header-context-stacked')),
      findsOneWidget,
    );
    expect(find.text('9:04 PM'), findsOneWidget);
    final header = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-workspace-glass-header')),
    );
    final sync = tester.getRect(
      find.byKey(const ValueKey<String>('perfect-sync-surface')),
    );
    expect(header.contains(sync.topLeft), isTrue);
    expect(header.contains(sync.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high contrast uses the opaque non-blur fallback', (
    tester,
  ) async {
    await _pumpHeader(
      tester,
      size: const Size(980, 180),
      highContrast: true,
      now: () => DateTime(2026, 8, 6, 9, 24),
    );

    expect(
      find.ancestor(
        of: find.byKey(
          const ValueKey<String>('perfect-workspace-glass-header'),
        ),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final brightness in <Brightness>[Brightness.light, Brightness.dark]) {
    testWidgets(
      'sync state matrix matches ${brightness.name} glass preview',
      (tester) async {
        final now = DateTime(2026, 9, 30, 23, 59);
        await tester.binding.setSurfaceSize(const Size(920, 390));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final theme = brightness == Brightness.dark
            ? PerfectTheme.dark()
            : PerfectTheme.light();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: Scaffold(
                  body: RepaintBoundary(
                    key: const ValueKey<String>('perfect-header-state-matrix'),
                    child: Column(
                      children: [
                        for (final status in <PlannerSyncStatus>[
                          const PlannerSyncStatus.idle(),
                          const PlannerSyncStatus(
                            phase: PlannerSyncPhase.syncing,
                          ),
                          PlannerSyncStatus(
                            phase: PlannerSyncPhase.offline,
                            nextRetryAt: now.toUtc().add(
                              const Duration(seconds: 5),
                            ),
                            retryAttempt: 2,
                          ),
                          const PlannerSyncStatus(
                            phase: PlannerSyncPhase.needsAttention,
                          ),
                        ])
                          PerfectWorkspaceHeader(
                            destinationKey: 'today-${status.phase.name}',
                            destinationLabel: 'Today',
                            supportText: 'Your live day, at a glance',
                            status: status,
                            onSync: () async {},
                            now: () => now,
                            showWordmark: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Wednesday, September 30'), findsNWidgets(4));
        expect(find.text('۸ مهر ۱۴۰۵'), findsNWidgets(4));
        expect(find.text('Retry 5s'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey<String>('perfect-header-state-matrix')),
          matchesGoldenFile('../goldens/perfect_header_${brightness.name}.png'),
        );
      },
      tags: 'windows-golden',
    );
  }
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required Size size,
  required DateTime Function() now,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PerfectTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: textScaler, highContrast: highContrast),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: PerfectWorkspaceHeader(
                destinationKey: 'tasks',
                destinationLabel: 'Tasks',
                supportText: 'Capture, shape, and finish the work',
                status: const PlannerSyncStatus.idle(),
                onSync: () async {},
                now: now,
                showWordmark: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
