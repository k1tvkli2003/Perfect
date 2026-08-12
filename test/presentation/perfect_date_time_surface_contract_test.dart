import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workspace = _read('lib/presentation/perfect_workspace_page.dart');
  final editor = _read('lib/presentation/planner_editor.dart');
  final orbit = _read('lib/presentation/orbit_stage.dart');
  final widgetBridge = _read('lib/widgets/perfect_today_widget.dart');
  final widgetProjector = _read(
    'lib/widgets/perfect_today_widget_projector.dart',
  );
  final reminders = _read(
    'lib/planner/notifications/planner_reminder_scheduler.dart',
  );
  final feedback = _read('lib/feedback/src/feedback_overlay.dart');
  final aiContract = _read('lib/ai/perfect_ai_contract.dart');
  final aiEdge = _read('supabase/functions/perfect-agent/index.ts');
  final localStore = _read('lib/planner/data/planner_local_store.dart');

  test('user-facing surfaces share one local calendar vocabulary', () {
    expect(workspace, contains('PerfectDualDateClock.value(value: current)'));
    expect(workspace, contains('PerfectLocalTime.inspector(value)'));
    expect(workspace, contains('PerfectLocalTime.clock(value)'));
    expect(editor, contains('PerfectLocalTime.gregorianShort(local)'));
    expect(editor, contains('PerfectLocalTime.clock(local)'));
    expect(orbit, contains('PerfectLocalTime.clock(value)'));
    expect(widgetBridge, contains('PerfectLocalTime.gregorianShort(date)'));
    expect(widgetProjector, contains('PerfectLocalTime.clock(value)'));
    expect(feedback, contains('PerfectLocalTime.inspector(value)'));
  });

  test(
    'notifications and remote writes cross timezone boundaries explicitly',
    () {
      expect(reminders, contains('entity.scheduledAt!.toLocal()'));
      expect(
        reminders,
        contains('tz.TZDateTime.from(candidate.alertAt, tz.local)'),
      );
      expect(localStore, contains('scheduledAt.toUtc().toIso8601String()'));
      expect(
        localStore,
        contains('entity.updatedAt.toUtc().toIso8601String()'),
      );
    },
  );

  test(
    'AI receives validated local date context and never a client secret',
    () {
      expect(aiContract, contains("'client_context': _clientTimeContext"));
      expect(aiContract, contains("'utc_offset_minutes'"));
      expect(aiContract, contains('local.toUtc().toIso8601String()'));
      expect(
        aiEdge,
        contains('validateClientTimeContext(body.client_context)'),
      );
      expect(aiEdge, contains('Validated device time context:'));
      expect(aiContract, isNot(contains('api_key')));
    },
  );

  test('scrolling Today never becomes an implicit sync command', () {
    expect(workspace, isNot(contains('RefreshIndicator(')));
    expect(workspace, contains('controller.syncStatus'));
  });
}

String _read(String path) => File(path).readAsStringSync();
