import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_task_bulk.dart';
import 'package:perfect/presentation/tasks_bulk_bar.dart';

// Stage 36 tracer 15: bulk action surface tests.
//
// - planTasksBulk preview splits eligible vs skipped with reasons, no keys.
// - execute freezes receipt with batchId + one UUID-v5 key per eligible,
//   undoEligible only when applied non-empty.
// - TasksBulkBar (real widget) renders combined counts, preview/clear keys,
//   single semantic owner, and fires intent callbacks.
// - TasksBulkPreviewSheet (real widget) lists eligible IDs + skipped reasons
//   with confirm/cancel keys.

PlannerTasksBulkPlan _samplePlan() => planTasksBulk(
  orderedIds: const <String>['task-a', 'task-b', 'task-c'],
  selectedIds: const <String>{'task-a', 'task-b', 'task-c'},
  isEligible: (id) => id != 'task-c',
  skipReason: (id) => 'Skipped $id: archived on another device.',
);

void main() {
  group('planTasksBulk preview', () {
    test('splits eligible vs skipped with reasons and issues no keys', () {
      final plan = _samplePlan();

      expect(plan.eligibleIds, <String>['task-a', 'task-b']);
      expect(plan.skippedIds, <String>['task-c']);
      expect(
        plan.skippedReasons['task-c'],
        contains('archived on another device'),
      );
      expect(plan.issuedKeys, isEmpty);
      expect(plan.executed, isFalse);
      expect(plan.eligibleCount, 2);
      expect(plan.skippedCount, 1);
    });
  });

  group('PlannerTasksBulkPlan.execute', () {
    test('issues exactly one key per eligible and enables undo', () {
      final receipt = _samplePlan().execute(
        action: PlannerTasksBulkAction.complete,
      );

      expect(receipt.batchId, isNotEmpty);
      expect(receipt.appliedIds, <String>['task-a', 'task-b']);
      expect(receipt.perEntityKeys.keys.toSet(), <String>{'task-a', 'task-b'});
      expect(receipt.perEntityKeys.values.toSet(), hasLength(2));
      for (final key in receipt.perEntityKeys.values) {
        expect(key, isNotEmpty);
      }
      expect(receipt.skippedIds, <String>['task-c']);
      expect(
        receipt.skippedReasons['task-c'],
        contains('archived on another device'),
      );
      expect(receipt.undoEligible, isTrue);
    });

    test('empty selection is a no-op with undo disabled', () {
      final receipt = planTasksBulk(
        orderedIds: const <String>['task-a'],
        selectedIds: const <String>{},
        isEligible: (_) => true,
        skipReason: (_) => '',
      ).execute(action: PlannerTasksBulkAction.archive);

      expect(receipt.batchId, isNotEmpty);
      expect(receipt.appliedIds, isEmpty);
      expect(receipt.perEntityKeys, isEmpty);
      expect(receipt.undoEligible, isFalse);
    });
  });

  group('TasksBulkBar widget', () {
    testWidgets('renders counts plus preview/clear keys and semantics', (
      tester,
    ) async {
      var previewTaps = 0;
      var clearTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasksBulkBar(
              selectedCount: 3,
              eligibleCount: 2,
              skippedCount: 1,
              onOpenPreview: () => previewTaps++,
              onClearSelection: () => clearTaps++,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('tasks-bulk-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tasks-bulk-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tasks-bulk-clear')),
        findsOneWidget,
      );
      expect(find.textContaining('3 selected'), findsOneWidget);
      expect(find.textContaining('2 eligible'), findsOneWidget);
      expect(find.textContaining('1 skipped'), findsOneWidget);
      expect(find.text('Bulk task actions'), findsOneWidget);
      final node = tester.getSemantics(
        find.byKey(const ValueKey<String>('tasks-bulk-bar')),
      );
      expect(
        node.label,
        startsWith(
          'Bulk task actions. '
          'Search, filter and act without losing the working context.',
        ),
      );
      expect(node.value, contains('3 selected'));

      await tester.tap(
        find.byKey(const ValueKey<String>('tasks-bulk-preview')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('tasks-bulk-clear')));
      expect(previewTaps, 1);
      expect(clearTaps, 1);
    });
  });

  group('TasksBulkPreviewSheet widget', () {
    testWidgets(
      'lists eligible IDs plus skipped reasons with confirm/cancel keys',
      (tester) async {
        final plan = _samplePlan();
        var confirmed = 0;
        var cancelled = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TasksBulkPreviewSheet(
                actionLabel: 'Complete',
                eligibleIds: plan.eligibleIds,
                skippedReasons: plan.skippedReasons,
                onConfirm: () => confirmed++,
                onCancel: () => cancelled++,
              ),
            ),
          ),
        );

        expect(find.text('Bulk task actions'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
        expect(find.text('task-a'), findsOneWidget);
        expect(find.text('task-b'), findsOneWidget);
        expect(
          find.textContaining('task-c'),
          findsWidgets,
          reason: 'Skipped ID must render alongside its reason.',
        );
        expect(
          find.textContaining('archived on another device'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('tasks-bulk-confirm')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('tasks-bulk-cancel')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('tasks-bulk-confirm')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('tasks-bulk-cancel')),
        );
        expect(confirmed, 1);
        expect(cancelled, 1);
      },
    );
  });
}
