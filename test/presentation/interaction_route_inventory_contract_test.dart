import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String inventory;
  late String mainSource;
  late String workspaceSource;
  late String controllerSource;
  late String syncSource;
  late String aiDockSource;
  late String aiFunctionSource;
  late String widgetProviderSource;
  late String widgetBackgroundSource;

  setUpAll(() {
    inventory = _source(
      'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/'
      'stages/evidence/02-interaction-route-inventory.md',
    );
    mainSource = _source('lib/main.dart');
    workspaceSource = _source('lib/presentation/perfect_workspace_page.dart');
    controllerSource = _source(
      'lib/presentation/planner_workspace_controller.dart',
    );
    syncSource = _source('lib/planner/sync/planner_sync_repository.dart');
    aiDockSource = _source('lib/ai/perfect_ai_dock.dart');
    aiFunctionSource = _source('supabase/functions/perfect-agent/index.ts');
    widgetProviderSource = _source(
      'android/app/src/main/kotlin/com/k1tvkli2003/perfect/'
      'PerfectTodayWidgetProvider.kt',
    );
    widgetBackgroundSource = _source(
      'lib/widgets/perfect_today_widget_background.dart',
    );
  });

  group('Stage 02 interaction and route inventory', () {
    test(
      'keeps every required diagram and ten core job budgets executable',
      () {
        for (final marker in const <String>[
          'Entity lifecycle',
          'Application and route tree',
          'Local-first foreground sequence',
          'AI proposal sequence',
          'Android widget action sequence',
        ]) {
          expect(inventory, contains(marker), reason: marker);
        }
        for (final job in const <String>[
          '1. Quick task',
          '2. Scheduled one-off task',
          '3. Recurring task',
          '4. Habit',
          '5. Add +1 to count habit',
          '6. Correct a habit day',
          '7. Complete / cycle task',
          '8. View personal stats',
          '9. Edit an item',
          '10. Ask Perfect AI',
        ]) {
          expect(inventory, contains(job), reason: job);
        }
        for (var issue = 1; issue <= 15; issue++) {
          expect(
            inventory,
            contains('IR-${issue.toString().padLeft(3, '0')}'),
            reason: 'Every source-backed route debt needs a stable owner.',
          );
        }
      },
    );

    test('classifies every whole-product coverage-ledger row', () {
      for (final productSystem in const <String>[
        'Boot, splash, configuration and private sign-in',
        'Installed brand, typography, icon and platform identity',
        'Responsive shell, header, footer and rail',
        'Sync cloud, dual date/time and ambient state',
        'Today orientation and day stream',
        'Task row, progress and status cycle',
        'Habit logging and streak state',
        'Quick Capture/Plan/AI/Voice instrument',
        'Task/recurring/habit creation and edit',
        'Detail, history, analytics and lifecycle',
        'Tasks workspace',
        'Plan day/week/month and time blocks',
        'Habits workspace and insights',
        'Goals, projects, areas, notes and horizons',
        'Focus sessions and gamification',
        'Categories, icons, colors and custom metadata',
        'Search, filter, sort, saved views and bulk actions',
        'Reminders, quiet windows and notification actions',
        'Archive, trash, conflict center and recovery',
        'Settings, profile, theme and widget settings',
        'Feedback, logs, screenshot and private diagnostics',
        'Local database, operation log and migrations',
        'Supabase RLS, realtime, RPC/functions and sync',
        'Perfect AI text/voice/context/actions/audit',
        'Android widget and Quick Add',
        'Accessibility, localization and mixed direction',
        'Performance, privacy, packaging and release',
      ]) {
        expect(
          inventory,
          contains('| $productSystem |'),
          reason: productSystem,
        );
      }
      expect(
        inventory,
        contains('No product-surface row was silently omitted'),
      );
    });

    test(
      'centralizes live and cold native navigation in the workspace router',
      () {
        expect(mainSource, contains('PerfectWorkspaceNavigationController'));
        expect(
          mainSource,
          contains('_navigationController.showEntity(entityId)'),
        );
        expect(mainSource, contains('_navigationController.showToday()'));
        expect(
          mainSource,
          contains('PlannerReminderNavigation.takePendingEntityId()'),
        );
        expect(mainSource, contains('initiallyLaunchedUri()'));
        expect(mainSource, contains('widgetLaunchUris().listen'));
        expect(workspaceSource, contains('_consumeNavigationRequest'));
        expect(workspaceSource, contains('_navigateToEntity'));
      },
    );

    test('foreground planner writes commit locally before requesting sync', () {
      final quickCapture = _methodBody(
        controllerSource,
        'Future<PlannerMutationReceipt> quickCapture',
        'Future<void> saveEntity',
      );
      _expectOrdered(
        quickCapture,
        'await _localStore.createQuickTask',
        'unawaited(_syncRepository.syncNow())',
      );

      final saveEntity = _methodBody(
        controllerSource,
        'Future<void> saveEntity',
        'Future<PlannerEntity> duplicateEntity',
      );
      _expectOrdered(
        saveEntity,
        'await _localStore.upsertEntity',
        'unawaited(_syncRepository.syncNow())',
      );

      final synchronize = _methodBody(
        syncSource,
        'Future<void> _synchronize()',
        'void _scheduleRetry()',
      );
      _expectOrdered(
        synchronize,
        'await _pullAllChanges()',
        'await _pushPendingOperations()',
      );
      final firstPull = synchronize.indexOf('await _pullAllChanges()');
      final secondPull = synchronize.indexOf(
        'await _pullAllChanges()',
        firstPull + 1,
      );
      expect(
        secondPull,
        greaterThan(synchronize.indexOf('_pushPendingOperations')),
      );
    });

    test(
      'AI rejects unconfirmed writes and verifies the persisted proposal',
      () {
        expect(aiDockSource, contains('!proposal.requiresConfirmation'));
        expect(aiDockSource, contains('widget.client.applyProposal'));
        expect(aiDockSource, contains('await widget.onProposalApplied()'));
        expect(
          aiFunctionSource,
          contains('proposal.requires_confirmation !== true'),
        );

        final applyBranch = _methodBody(
          aiFunctionSource,
          'if (action === "apply_proposal")',
          'if (action !== "chat")',
        );
        _expectOrdered(
          applyBranch,
          'await requirePersistedProposal',
          'await applyProposal',
        );
        expect(aiFunctionSource, contains('/rest/v1/rpc/submit_agent_plan'));
        expect(aiFunctionSource, contains('record_ai_action_result'));
      },
    );

    test(
      'Android widget actions retain optimistic and durable replay paths',
      () {
        final actionReceiver = _methodBody(
          widgetProviderSource,
          'class PerfectTodayWidgetActionReceiver',
          'class PerfectTodayWidgetService',
        );
        _expectOrdered(
          actionReceiver,
          'PerfectTodayWidgetStore.cycle(context, entityId)',
          'HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()',
        );
        _expectOrdered(
          widgetBackgroundSource,
          'PerfectTodayWidgetBridge.secretsMatch',
          'PlannerTaskProgressService(',
        );
        expect(widgetBackgroundSource, contains('mutationId: request.id'));
        expect(widgetBackgroundSource, contains('acknowledgeActions'));
        expect(widgetBackgroundSource, contains('acknowledgeQuickAdds'));
      },
    );

    test(
      'documents view-first intent without freezing the compact edit defect',
      () {
        expect(
          inventory,
          contains('Perfect! has one view-first interaction hierarchy'),
        );
        expect(inventory, contains('IR-001'));
        expect(inventory, contains('IR-002'));
        expect(
          inventory,
          contains('not the target contract'),
          reason: 'Current direct-to-editor tests are characterization only.',
        );
        expect(inventory, contains('EntityDetailCoordinator'));
        expect(inventory, contains('Always pass ID, resolve live entity'));
      },
    );
  });
}

String _source(String path) => File(
  path,
).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');

String _methodBody(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: 'Missing start marker: $startMarker',
  );
  final end = source.indexOf(endMarker, start + startMarker.length);
  expect(end, greaterThan(start), reason: 'Missing end marker: $endMarker');
  return source.substring(start, end);
}

void _expectOrdered(String source, String first, String second) {
  final firstIndex = source.indexOf(first);
  final secondIndex = source.indexOf(second);
  expect(
    firstIndex,
    greaterThanOrEqualTo(0),
    reason: 'Missing first marker: $first',
  );
  expect(
    secondIndex,
    greaterThanOrEqualTo(0),
    reason: 'Missing second marker: $second',
  );
  expect(
    firstIndex,
    lessThan(secondIndex),
    reason: '$first must remain before $second',
  );
}
