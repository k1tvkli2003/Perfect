import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_task_progress.dart';
import 'package:perfect/presentation/task_status_control.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    PlannerTaskProgress progress, {
    VoidCallback? onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TaskStatusControl(
              progress: progress,
              color: Colors.teal,
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('every task outcome has stable 48dp hit and 30dp visual bounds', (
    tester,
  ) async {
    final states = <PlannerTaskProgress>[
      const PlannerTaskProgress.pending(),
      const PlannerTaskProgress(
        state: PlannerTaskProgressState.partial,
        percent: 63,
      ),
      const PlannerTaskProgress(
        state: PlannerTaskProgressState.completed,
        percent: 100,
      ),
      const PlannerTaskProgress(
        state: PlannerTaskProgressState.missed,
        percent: 0,
      ),
    ];
    Rect? hit;
    Rect? visual;
    for (final progress in states) {
      await show(tester, progress);
      final currentHit = tester.getRect(
        find.byKey(const ValueKey('task-status-hit')),
      );
      final currentVisual = tester.getRect(
        find.byKey(const ValueKey('task-status-glyph')),
      );
      expect(currentHit.size, const Size(48, 48));
      expect(currentVisual.size, const Size(30, 30));
      expect(currentVisual.center, currentHit.center);
      if (hit != null) expect(currentHit, hit);
      if (visual != null) expect(currentVisual, visual);
      hit = currentHit;
      visual = currentVisual;
    }
  });

  testWidgets(
    'partial arc holds exact percent in semantics, never visible text',
    (tester) async {
      await show(
        tester,
        const PlannerTaskProgress(
          state: PlannerTaskProgressState.partial,
          percent: 63,
        ),
      );
      expect(find.text('63%'), findsNothing);
      final indicator = tester.widget<CircularProgressIndicator>(
        find.descendant(
          of: find.byKey(const ValueKey('task-status-glyph')),
          matching: find.byType(CircularProgressIndicator),
        ),
      );
      expect(indicator.value, 0.63);
      expect(
        find.byTooltip('63% progress · clear task outcome'),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('task-status-hit')))
            .value,
        '63% progress',
      );
    },
  );

  testWidgets('status activation never bubbles into an ancestor action', (
    tester,
  ) async {
    var taps = 0;
    var secondary = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: () => secondary++,
              child: TaskStatusControl(
                progress: const PlannerTaskProgress.pending(),
                color: Colors.teal,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('task-status-hit')));
    await tester.pump();
    expect(taps, 1);
    expect(secondary, 0);
  });
}
