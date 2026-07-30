import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_today_widget_settings_sheet.dart';
import 'package:perfect/presentation/planner_archive_sheet.dart';
import 'package:perfect/presentation/planner_conflict_center_sheet.dart';
import 'package:perfect/presentation/planner_insights_sheet.dart';
import 'package:perfect/presentation/planner_reminder_settings_sheet.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

typedef _OpenSurface =
    Future<void> Function(
      BuildContext context,
      PlannerWorkspaceController controller,
    );

class _SurfaceCase {
  const _SurfaceCase({
    required this.buttonLabel,
    required this.heading,
    required this.bodyType,
    required this.maxWidth,
    required this.open,
  });

  final String buttonLabel;
  final String heading;
  final Type bodyType;
  final double maxWidth;
  final _OpenSurface open;
}

final _surfaces = <_SurfaceCase>[
  _SurfaceCase(
    buttonLabel: 'Open archive',
    heading: 'Archive',
    bodyType: PlannerArchiveSheet,
    maxWidth: 680,
    open: (context, controller) =>
        PlannerArchiveSheet.show(context, controller: controller),
  ),
  _SurfaceCase(
    buttonLabel: 'Open conflicts',
    heading: 'Conflict center',
    bodyType: PlannerConflictCenterSheet,
    maxWidth: 680,
    open: (context, controller) =>
        PlannerConflictCenterSheet.show(context, controller: controller),
  ),
  _SurfaceCase(
    buttonLabel: 'Open insights',
    heading: 'Your rhythm',
    bodyType: PlannerInsightsSheet,
    maxWidth: 680,
    open: (context, controller) =>
        PlannerInsightsSheet.show(context, controller: controller),
  ),
  _SurfaceCase(
    buttonLabel: 'Open reminders',
    heading: 'Reminders',
    bodyType: PlannerReminderSettingsSheet,
    maxWidth: 680,
    open: (context, controller) =>
        PlannerReminderSettingsSheet.show(context, controller: controller),
  ),
  _SurfaceCase(
    buttonLabel: 'Open widget settings',
    heading: 'Perfect Today',
    bodyType: PerfectTodayWidgetSettingsSheet,
    maxWidth: 620,
    open: (context, controller) =>
        PerfectTodayWidgetSettingsSheet.show(context, controller: controller),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlannerWorkspaceController controller;

  setUp(() {
    final local = PlannerLocalStore(PlannerDatabase(NativeDatabase.memory()));
    controller = PlannerWorkspaceController(
      local,
      PlannerSyncRepository(
        local,
        _DisconnectedGateway(),
        ownerId: 'adaptive-surface-owner',
        deviceId: '11111111-1111-4111-8111-111111111111',
      ),
      ownerId: 'adaptive-surface-owner',
    );
  });

  tearDown(() => controller.disposeAsync());

  testWidgets(
    'expanded secondary surfaces use bounded dialogs dismissible by Escape',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _SurfaceLauncher(
          controller: controller,
          platform: TargetPlatform.windows,
        ),
      );

      for (final surface in _surfaces) {
        await tester.tap(find.text(surface.buttonLabel));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget, reason: surface.heading);
        expect(find.byType(BottomSheet), findsNothing, reason: surface.heading);
        expect(find.text(surface.heading), findsOneWidget);
        final size = tester.getSize(find.byType(surface.bodyType));
        expect(size.width, lessThanOrEqualTo(surface.maxWidth));
        expect(size.height, lessThanOrEqualTo(720));

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing, reason: surface.heading);
      }
    },
  );

  testWidgets('compact secondary surfaces preserve modal bottom sheets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _SurfaceLauncher(
        controller: controller,
        platform: TargetPlatform.android,
      ),
    );

    for (final surface in _surfaces) {
      await tester.tap(find.text(surface.buttonLabel));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget, reason: surface.heading);
      expect(find.byType(Dialog), findsNothing, reason: surface.heading);
      expect(find.text(surface.heading), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing, reason: surface.heading);
    }
  });
}

class _SurfaceLauncher extends StatelessWidget {
  const _SurfaceLauncher({required this.controller, required this.platform});

  final PlannerWorkspaceController controller;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(useMaterial3: true, platform: platform),
    home: Scaffold(
      body: Builder(
        builder: (context) => ListView(
          children: [
            for (final surface in _surfaces)
              FilledButton(
                onPressed: () => surface.open(context, controller),
                child: Text(surface.buttonLabel),
              ),
          ],
        ),
      ),
    ),
  );
}

class _DisconnectedGateway implements PlannerRemoteGateway {
  @override
  Future<PlannerRemoteMutationResult> apply(PlannerRemoteMutation mutation) =>
      Future<PlannerRemoteMutationResult>.error(
        StateError('offline for adaptive surface test'),
      );

  @override
  Future<void> dispose() async {}

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async => PlannerRemoteChangePage(
    changes: const <PlannerRemoteChange>[],
    requestedLimit: limit,
  );

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<void> subscribe(void Function() onChangeHint) async {}
}
