import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/domain/planner_habit_day_summary.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/today_pulse.dart';

void main() {
  group('TodayPulseSnapshot', () {
    test('empty projection remains truthful and action-oriented', () {
      final snapshot = TodayPulseSnapshot.fromPlanner(
        items: const <PlannerEntity>[],
        taskProgressById: const <String, PlannerTaskProgress>{},
        habitSummaryById: const <String, PlannerHabitDaySummary>{},
        projectionResolved: true,
      );

      expect(snapshot.state, TodayPulseState.empty);
      expect(snapshot.outcomePrimary, 'Nothing planned');
      expect(snapshot.boundaryLabel(DateTime(2026, 8, 14)), 'Shape the day');
      expect(snapshot.progress, 0);
    });

    test(
      'uses daily task occurrence and habit summary, not lifecycle status',
      () {
        final task = _entity(
          id: 'recurring',
          kind: PlannerEntityKind.recurringTask,
          status: PlannerEntityStatus.completed,
          scheduledAt: DateTime(2026, 8, 14, 8),
        );
        final habit = _entity(
          id: 'habit',
          kind: PlannerEntityKind.habit,
          scheduledAt: DateTime(2026, 8, 14, 12),
        );
        final snapshot = TodayPulseSnapshot.fromPlanner(
          items: <PlannerEntity>[task, habit],
          taskProgressById: const <String, PlannerTaskProgress>{
            'recurring': PlannerTaskProgress(
              state: PlannerTaskProgressState.partial,
              percent: 50,
            ),
          },
          habitSummaryById: <String, PlannerHabitDaySummary>{
            'habit': _habitSummary(
              state: PlannerHabitDayState.partial,
              progressPercent: 40,
            ),
          },
          projectionResolved: true,
        );

        expect(snapshot.state, TodayPulseState.active);
        expect(snapshot.completed, 0);
        expect(snapshot.partial, 2);
        expect(snapshot.remaining, 2);
        expect(snapshot.progress, closeTo(.45, .0001));
        expect(snapshot.outcomePrimary, '0 complete');
        expect(snapshot.outcomeSecondary, '2 remaining');
      },
    );

    test('separates missed decisions from remaining work', () {
      final first = _entity(id: 'missed-a');
      final second = _entity(id: 'missed-b');
      final snapshot = TodayPulseSnapshot.fromPlanner(
        items: <PlannerEntity>[first, second],
        taskProgressById: const <String, PlannerTaskProgress>{
          'missed-a': PlannerTaskProgress(
            state: PlannerTaskProgressState.missed,
            percent: 0,
          ),
          'missed-b': PlannerTaskProgress(
            state: PlannerTaskProgressState.missed,
            percent: 0,
          ),
        },
        habitSummaryById: const <String, PlannerHabitDaySummary>{},
        projectionResolved: true,
      );

      expect(snapshot.state, TodayPulseState.missedOnly);
      expect(snapshot.remaining, 0);
      expect(snapshot.missed, 2);
      expect(snapshot.outcomePrimary, '2 need a decision');
      expect(
        snapshot.boundaryLabel(DateTime(2026, 8, 14)),
        'Review before tomorrow',
      );
    });

    test('never treats recurring lifecycle completion as today completion', () {
      final recurring = _entity(
        id: 'recurring-without-occurrence',
        kind: PlannerEntityKind.recurringTask,
        status: PlannerEntityStatus.completed,
        scheduledAt: DateTime(2026, 8, 14, 10),
      );
      final snapshot = TodayPulseSnapshot.fromPlanner(
        items: <PlannerEntity>[recurring],
        taskProgressById: const <String, PlannerTaskProgress>{},
        habitSummaryById: const <String, PlannerHabitDaySummary>{},
        projectionResolved: true,
      );

      expect(snapshot.completed, 0);
      expect(snapshot.remaining, 1);
      expect(snapshot.progress, 0);
    });

    test(
      'selects the next future start, due, or cross-midnight end boundary',
      () {
        final item = _entity(
          id: 'timed',
          scheduledAt: DateTime(2026, 8, 14, 8),
          dueAt: DateTime(2026, 8, 14, 20),
          endAt: DateTime(2026, 8, 15, 1),
        );
        final snapshot = TodayPulseSnapshot.fromPlanner(
          items: <PlannerEntity>[item],
          taskProgressById: const <String, PlannerTaskProgress>{},
          habitSummaryById: const <String, PlannerHabitDaySummary>{},
          projectionResolved: true,
        );

        expect(snapshot.boundaryLabel(DateTime(2026, 8, 14, 19)), '8:00 PM');
        expect(
          snapshot.boundaryLabel(DateTime(2026, 8, 14, 21)),
          'Tomorrow · 1:00 AM',
        );
        expect(
          snapshot.boundaryLabel(DateTime(2026, 8, 15, 2)),
          'No later boundary',
        );
      },
    );

    test('keeps visible items while projection resolves', () {
      final snapshot = TodayPulseSnapshot.fromPlanner(
        items: <PlannerEntity>[_entity(id: 'visible')],
        taskProgressById: const <String, PlannerTaskProgress>{},
        habitSummaryById: const <String, PlannerHabitDaySummary>{},
        projectionResolved: false,
      );

      expect(snapshot.state, TodayPulseState.resolving);
      expect(snapshot.outcomePrimary, 'Updating today…');
    });
  });

  group('TodayPulse widget', () {
    testWidgets(
      'compact surface keeps Plan reachable and exposes one summary',
      (tester) async {
        var opened = 0;
        await tester.pumpWidget(
          _host(
            width: 390,
            snapshot: _activeSnapshot(),
            onOpenPlan: () => opened++,
          ),
        );

        expect(
          find.byKey(const ValueKey<String>('today-pulse-compact')),
          findsOne,
        );
        expect(
          find.byKey(const ValueKey<String>('today-pulse-wide')),
          findsNothing,
        );
        expect(find.text('3 complete'), findsOne);
        expect(find.text('4 remaining'), findsOne);
        expect(find.text('8:00 PM'), findsOne);
        expect(tester.takeException(), isNull);

        await tester.tap(
          find.byKey(const ValueKey<String>('today-pulse-plan')),
        );
        expect(opened, 1);
        final semantics = tester.getSemantics(
          find.byKey(const ValueKey<String>('today-pulse')),
        );
        expect(semantics.label, contains('Solar Hijri'));
        expect(semantics.label, contains('3 complete'));
      },
    );

    testWidgets('wide surface uses bounded three-column composition', (
      tester,
    ) async {
      await tester.pumpWidget(_host(width: 980, snapshot: _activeSnapshot()));

      expect(find.byKey(const ValueKey<String>('today-pulse-wide')), findsOne);
      expect(find.text('DAY SO FAR'), findsOne);
      expect(find.text('NEXT BOUNDARY'), findsOne);
      expect(find.byType(VerticalDivider), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '200 percent text recomposes without clipping required actions',
      (tester) async {
        await tester.pumpWidget(
          _host(width: 320, textScale: 2, snapshot: _activeSnapshot()),
        );

        expect(
          find.byKey(const ValueKey<String>('today-pulse-compact')),
          findsOne,
        );
        expect(
          find.byKey(const ValueKey<String>('today-pulse-plan')),
          findsOne,
        );
        expect(find.text('Friday, August 14'), findsOne);
        expect(find.text('۲۳ مرداد ۱۴۰۵'), findsOne);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('dark and high-contrast themes retain the same semantics', (
      tester,
    ) async {
      for (final theme in <ThemeData>[
        PerfectTheme.dark(),
        PerfectTheme.highContrastLight(),
        PerfectTheme.highContrastDark(),
      ]) {
        await tester.pumpWidget(
          _host(width: 980, snapshot: _activeSnapshot(), theme: theme),
        );
        expect(find.byKey(const ValueKey<String>('today-pulse')), findsOne);
        expect(find.text('3 complete'), findsOne);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'minute tick rebuilds only Pulse and leaves sibling work stable',
      (tester) async {
        var current = DateTime(2026, 8, 14, 19, 42, 30);
        VoidCallback? tick;
        var siblingBuilds = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: PerfectTheme.light(),
            home: Scaffold(
              body: Column(
                children: [
                  Builder(
                    builder: (context) {
                      siblingBuilds++;
                      return const Text('Stable day row');
                    },
                  ),
                  TodayPulse(
                    snapshot: _activeSnapshot(),
                    now: () => current,
                    schedule: (_, callback) {
                      tick = callback;
                      return () {};
                    },
                    onOpenPlan: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(siblingBuilds, 1);
        expect(
          tester
              .getSemantics(find.byKey(const ValueKey<String>('today-pulse')))
              .label,
          contains('7:42 PM'),
        );

        current = DateTime(2026, 8, 14, 19, 43);
        tick!();
        await tester.pump();

        expect(siblingBuilds, 1);
        expect(
          tester
              .getSemantics(find.byKey(const ValueKey<String>('today-pulse')))
              .label,
          contains('7:43 PM'),
        );
      },
    );
  });
}

Widget _host({
  required double width,
  required TodayPulseSnapshot snapshot,
  double textScale = 1,
  ThemeData? theme,
  VoidCallback? onOpenPlan,
}) => MaterialApp(
  theme: theme ?? PerfectTheme.light(),
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: TodayPulse(
            snapshot: snapshot,
            now: () => DateTime(2026, 8, 14, 19, 42),
            onOpenPlan: onOpenPlan ?? () {},
          ),
        ),
      ),
    ),
  ),
);

TodayPulseSnapshot _activeSnapshot() => TodayPulseSnapshot(
  state: TodayPulseState.active,
  total: 7,
  completed: 3,
  remaining: 4,
  missed: 0,
  partial: 1,
  progress: 3.5 / 7,
  boundaries: <DateTime>[DateTime(2026, 8, 14, 20)],
);

PlannerEntity _entity({
  required String id,
  PlannerEntityKind kind = PlannerEntityKind.oneOffTask,
  PlannerEntityStatus status = PlannerEntityStatus.active,
  DateTime? scheduledAt,
  DateTime? dueAt,
  DateTime? endAt,
}) {
  final now = DateTime.utc(2026, 8, 14);
  return PlannerEntity(
    id: id,
    ownerId: 'owner',
    kind: kind,
    payload: <String, dynamic>{
      PlannerPayloadKeys.title: id,
      PlannerPayloadKeys.status: status.wireValue,
      PlannerPayloadKeys.timing: <String, dynamic>{
        if (scheduledAt != null)
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        if (dueAt != null) 'due_at': dueAt.toUtc().toIso8601String(),
        if (endAt != null)
          PlannerTaskMetadataKeys.timeBlockEndAt: endAt
              .toUtc()
              .toIso8601String(),
      },
    },
    createdAt: now,
    updatedAt: now,
  );
}

PlannerHabitDaySummary _habitSummary({
  required PlannerHabitDayState state,
  required int progressPercent,
}) => PlannerHabitDaySummary(
  state: state,
  method: 'count',
  hasLog: true,
  amount: progressPercent / 10,
  target: 10,
  progressPercent: progressPercent,
  checkedItemIds: const <String>{},
  checkedCount: 0,
  requiredCount: 0,
  totalChecklistItems: 0,
  occurrences: const [],
);
