import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workspace = File(
    'lib/presentation/perfect_workspace_page.dart',
  ).readAsStringSync();
  final pulse = File('lib/presentation/today_pulse.dart').readAsStringSync();

  test('Today runtime contains one Pulse and no Orbit compatibility shell', () {
    expect(workspace, contains('TodayPulse('));
    expect(
      workspace,
      contains("PageStorageKey<String>('perfect-today-scroll')"),
    );
    expect(workspace, isNot(contains('OrbitStage')));
    expect(workspace, isNot(contains('day-compass-panel')));
    expect(workspace, isNot(contains('_TodayNextUpCard')));
    expect(workspace, isNot(contains("'Habit pulse'")));
    expect(workspace, isNot(contains("'Next up'")));
    expect(File('lib/presentation/orbit_stage.dart').existsSync(), isFalse);
    expect(
      File(
        'test/presentation/orbit_stage_accessibility_test.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'retired Orbit production assets and generator cannot return silently',
    () {
      final retired = Directory('assets/brand')
          .listSync()
          .whereType<File>()
          .where((file) {
            final name = file.uri.pathSegments.last.toLowerCase();
            return name.startsWith('orbit_') || name.startsWith('orbit-');
          })
          .map((file) => file.path)
          .toList(growable: false);

      expect(retired, isEmpty);
      expect(
        File('tool/generate_orbit_theme_assets.cjs').existsSync(),
        isFalse,
      );
    },
  );

  test('Pulse owns orientation only and leaves titles to the day stream', () {
    expect(pulse, contains('TodayPulseSnapshot.fromPlanner'));
    expect(pulse, contains('PerfectMinuteClockBuilder'));
    expect(pulse, contains('PerfectLocalTime.gregorianLong(current)'));
    expect(pulse, contains('PerfectLocalTime.jalaliLong(current)'));
    expect(pulse, contains("ValueKey<String>('today-pulse-plan')"));
    expect(pulse, isNot(contains('item.title')));
    expect(pulse, isNot(contains('controller.')));
  });
}
