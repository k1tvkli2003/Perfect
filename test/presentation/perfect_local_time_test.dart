import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/presentation/perfect_local_time.dart';

void main() {
  group('PerfectJalaliDate', () {
    test('matches Nowruz and product acceptance vectors', () {
      expect(
        PerfectJalaliDate.fromGregorian(DateTime(2024, 3, 20)),
        const PerfectJalaliDate(year: 1403, month: 1, day: 1),
      );
      expect(
        PerfectJalaliDate.fromGregorian(DateTime(2026, 8, 6)),
        const PerfectJalaliDate(year: 1405, month: 5, day: 15),
      );
    });

    test('crosses leap Esfand without skipping or repeating a day', () {
      expect(
        PerfectJalaliDate.fromGregorian(DateTime(2025, 3, 20)),
        const PerfectJalaliDate(year: 1403, month: 12, day: 30),
      );
      expect(
        PerfectJalaliDate.fromGregorian(DateTime(2025, 3, 21)),
        const PerfectJalaliDate(year: 1404, month: 1, day: 1),
      );
    });
  });

  group('PerfectLocalTime', () {
    test('formats the 12 AM and 12 PM boundaries correctly', () {
      expect(PerfectLocalTime.clock(DateTime(2026, 8, 6)), '12:00 AM');
      expect(PerfectLocalTime.clock(DateTime(2026, 8, 6, 12)), '12:00 PM');
      expect(PerfectLocalTime.clock(DateTime(2026, 8, 6, 23, 7)), '11:07 PM');
    });

    test('builds a real mixed-script Gregorian and Jalali line', () {
      expect(
        PerfectLocalTime.dualDate(DateTime(2026, 8, 6)),
        'Thursday, August 6 · ۱۵ مرداد ۱۴۰۵',
      );
      expect(
        PerfectLocalTime.inspector(DateTime(2026, 8, 6, 21, 4)),
        'Aug 6, 2026 · 9:04 PM',
      );
    });
  });

  testWidgets('minute clock aligns once and rebuilds only its own subtree', (
    tester,
  ) async {
    var current = DateTime(2026, 8, 6, 9, 24, 30, 250);
    Duration? scheduledDelay;
    VoidCallback? tick;
    var cancelled = false;
    var clockBuilds = 0;
    var siblingBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Builder(
              builder: (context) {
                siblingBuilds++;
                return const Text('Stable planner row');
              },
            ),
            PerfectMinuteClockBuilder(
              now: () => current,
              schedule: (delay, callback) {
                scheduledDelay = delay;
                tick = callback;
                cancelled = false;
                return () => cancelled = true;
              },
              builder: (context, now) {
                clockBuilds++;
                return Text(PerfectLocalTime.clock(now));
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text('9:24 AM'), findsOneWidget);
    expect(scheduledDelay, const Duration(seconds: 29, milliseconds: 750));
    expect(siblingBuilds, 1);
    expect(clockBuilds, 1);

    current = DateTime(2026, 8, 6, 9, 25);
    tick!();
    await tester.pump();

    expect(find.text('9:25 AM'), findsOneWidget);
    expect(siblingBuilds, 1);
    expect(clockBuilds, 2);
    expect(scheduledDelay, const Duration(minutes: 1));

    await tester.pumpWidget(const SizedBox.shrink());
    expect(cancelled, isTrue);
  });

  testWidgets(
    'minute clock crosses local midnight and updates both calendars',
    (tester) async {
      var current = DateTime(2026, 3, 20, 23, 59, 59, 500);
      VoidCallback? tick;
      await tester.pumpWidget(
        MaterialApp(
          home: PerfectMinuteClockBuilder(
            now: () => current,
            schedule: (_, callback) {
              tick = callback;
              return () {};
            },
            builder: (context, now) => Text(PerfectLocalTime.dualDate(now)),
          ),
        ),
      );
      expect(find.textContaining('Friday, March 20'), findsOneWidget);

      current = DateTime(2026, 3, 21);
      tick!();
      await tester.pump();

      expect(find.textContaining('Saturday, March 21'), findsOneWidget);
      expect(find.textContaining('۱ فروردین ۱۴۰۵'), findsOneWidget);
    },
  );
}
