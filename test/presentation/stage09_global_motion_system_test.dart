import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_sync_indicator.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('semantic motion roles own timing, curves and optical travel', () {
    expect(PerfectMotionRole.values, hasLength(7));
    expect(
      PerfectMotion.spec(PerfectMotionRole.micro).duration,
      lessThan(PerfectMotion.spec(PerfectMotionRole.quick).duration),
    );
    expect(
      PerfectMotion.spec(PerfectMotionRole.quick).duration,
      lessThan(PerfectMotion.spec(PerfectMotionRole.standard).duration),
    );
    expect(
      PerfectMotion.spec(PerfectMotionRole.standard).duration,
      lessThan(PerfectMotion.spec(PerfectMotionRole.emphasized).duration),
    );
    expect(
      PerfectMotion.spec(PerfectMotionRole.modal).reverseDuration,
      PerfectMotion.standard,
    );
    expect(PerfectMotion.routeEnterTravel, 14);
    expect(PerfectMotion.routeExitTravel, 8);
    expect(PerfectMotion.dialogRise, 12);
    expect(PerfectMotion.dialogScaleBegin, .96);
  });

  testWidgets('Navigator route travel is pixel-bounded on wide windows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final route = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.expand(),
    );
    addTearDown(route.dispose);
    const builder = PerfectPageTransitionsBuilder(axis: Axis.horizontal);
    final transition = builder.buildTransitions<void>(
      route,
      hostContext,
      const AlwaysStoppedAnimation<double>(0),
      const AlwaysStoppedAnimation<double>(0),
      const ColoredBox(color: Colors.orange),
    );
    await tester.pumpWidget(
      MaterialApp(home: SizedBox.expand(child: transition)),
    );

    final translation = tester
        .widgetList<Transform>(find.byType(Transform))
        .firstWhere((widget) => widget.transform.getTranslation().x != 0)
        .transform
        .getTranslation();
    expect(translation.x, PerfectMotion.routeEnterTravel);
    expect(translation.y, 0);
  });

  testWidgets(
    'destination host retargets rapid taps with one painted page and an edge cue',
    (tester) async {
      late StateSetter update;
      var selected = 0;
      var direction = 1;
      var rebuildSerial = 0;

      Widget host() => MaterialApp(
        theme: PerfectTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Scaffold(
              body: PerfectPersistentDestinationHost(
                selectedIndex: selected,
                direction: direction,
                children: List<Widget>.generate(
                  4,
                  (index) => _StatefulMotionPage(
                    key: ValueKey<String>('page-$index'),
                    index: index,
                    rebuildSerial: rebuildSerial,
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final initialPageZeroState = tester.state<_StatefulMotionPageState>(
        find.byKey(const ValueKey<String>('page-0')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('counter-0')));
      await tester.pump();
      expect(find.text('page 0 · 1'), findsOneWidget);

      update(() {
        selected = 1;
        direction = 1;
      });
      await tester.pump();
      expect(
        tester.state<_StatefulMotionPageState>(
          find.byKey(const ValueKey<String>('page-0'), skipOffstage: false),
        ),
        same(initialPageZeroState),
        reason: 'State changed at the first destination hand-off.',
      );
      await tester.pump(const Duration(milliseconds: 72));
      expect(_activeDestinationIndices(tester), <int>[1]);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Opacity &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'perfect-destination-opacity-',
              ),
        ),
        findsNothing,
        reason: 'A fractional whole-page opacity would allocate a saveLayer.',
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Transform &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'perfect-destination-translation-',
              ),
        ),
        findsNothing,
        reason: 'A whole-page transform would reraster every glass surface.',
      );
      final firstCue = tester
          .widget<Transform>(
            find.byKey(const ValueKey<String>('perfect-route-edge-cue')),
          )
          .transform
          .getTranslation();
      expect(firstCue.x, greaterThan(0));

      update(() {
        selected = 3;
        direction = -1;
      });
      await tester.pump();
      expect(
        tester.state<_StatefulMotionPageState>(
          find.byKey(const ValueKey<String>('page-0'), skipOffstage: false),
        ),
        same(initialPageZeroState),
        reason: 'State changed while a rapid destination retargeted.',
      );
      expect(_activeDestinationIndices(tester), <int>[3]);
      final retargetedCue = tester
          .widget<Transform>(
            find.byKey(const ValueKey<String>('perfect-route-edge-cue')),
          )
          .transform
          .getTranslation();
      expect(retargetedCue.x, lessThan(0));
      expect(
        find.byKey(const ValueKey<String>('perfect-route-edge-cue')),
        findsOneWidget,
        reason: 'Rapid taps coalesce into one isolated direction cue.',
      );

      await tester.pump(PerfectMotion.standard);
      expect(find.text('page 3 · 0'), findsOneWidget);
      final retainedPageZero = find.textContaining(
        'page 0 ·',
        skipOffstage: false,
      );
      expect(
        retainedPageZero,
        findsOneWidget,
        reason: 'Every destination subtree keeps its local state offstage.',
      );
      expect(tester.widget<Text>(retainedPageZero).data, 'page 0 · 1');
      expect(
        tester.state<_StatefulMotionPageState>(
          find.byKey(const ValueKey<String>('page-0'), skipOffstage: false),
        ),
        same(initialPageZeroState),
      );

      update(() {
        selected = 0;
        direction = -1;
        rebuildSerial++;
      });
      await tester.pump(PerfectMotion.standard);
      expect(find.text('page 0 · 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dynamic reduced motion ends an interrupted destination hand-off',
    (tester) async {
      late StateSetter update;
      var selected = 0;
      final reduced = ValueNotifier<bool>(false);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disabled),
              child: child!,
            ),
          ),
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return PerfectPersistentDestinationHost(
                selectedIndex: selected,
                direction: 1,
                children: const <Widget>[
                  ColoredBox(color: Colors.orange, child: Text('First')),
                  ColoredBox(color: Colors.green, child: Text('Second')),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      update(() => selected = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(_activeDestinationIndices(tester), <int>[1]);
      expect(
        find.byKey(const ValueKey<String>('perfect-route-edge-cue')),
        findsOneWidget,
      );

      reduced.value = true;
      await tester.pump();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('perfect-route-edge-cue')),
        findsNothing,
      );
      expect(_activeDestinationIndices(tester), <int>[1]);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'staged entrance plays once per entry and never on data rebuild',
    (tester) async {
      late StateSetter update;
      var entry = 'today';
      var dataRevision = 0;
      final reduced = ValueNotifier<bool>(false);
      addTearDown(reduced.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disabled),
              child: child!,
            ),
          ),
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return PerfectMotionEntryScope(
                entryKey: entry,
                child: PerfectStagedEntrance(
                  child: Text(
                    'revision $dataRevision',
                    key: const ValueKey<String>('staged-copy'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(PerfectMotion.emphasized);
      expect(_stagedOpacity(tester), 1);

      update(() => dataRevision++);
      await tester.pump();
      expect(find.text('revision 1'), findsOneWidget);
      expect(_stagedOpacity(tester), 1);

      update(() => entry = 'tasks');
      await tester.pump();
      await tester.pump();
      expect(_stagedOpacity(tester), lessThan(.05));
      await tester.pump(const Duration(milliseconds: 90));
      expect(_stagedOpacity(tester), inOpenClosedRange(.05, 1));

      reduced.value = true;
      await tester.pump();
      expect(_stagedOpacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'dialog has a spatial mid-frame, dynamic reduced fallback and focus restoration',
    (tester) async {
      final invokingFocus = FocusNode(debugLabel: 'dialog invoker');
      addTearDown(invokingFocus.dispose);
      final reduced = ValueNotifier<bool>(false);
      addTearDown(reduced.dispose);
      final dialogClosed = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.light(),
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disabled),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Builder(
                builder: (buttonContext) => TextButton(
                  key: const ValueKey<String>('dialog-invoker'),
                  focusNode: invokingFocus,
                  onPressed: () {
                    final dialog = showPerfectDialog<void>(
                      context: buttonContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Motion details'),
                        actions: [
                          TextButton(
                            key: const ValueKey<String>('dialog-close'),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                    unawaited(
                      dialog.whenComplete(() {
                        if (!dialogClosed.isCompleted) dialogClosed.complete();
                      }),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      invokingFocus.requestFocus();
      await tester.pump();
      expect(invokingFocus.hasFocus, isTrue);

      await tester.tap(find.byKey(const ValueKey<String>('dialog-invoker')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final scale = tester.widget<Transform>(
        find.byKey(const ValueKey<String>('perfect-dialog-scale')),
      );
      final translation = tester.widget<Transform>(
        find.byKey(const ValueKey<String>('perfect-dialog-translate')),
      );
      expect(
        scale.transform.storage.first,
        inExclusiveRange(PerfectMotion.dialogScaleBegin, 1),
      );
      final resolvedAlignment = scale.alignment!.resolve(TextDirection.ltr);
      expect(resolvedAlignment.x, lessThan(0));
      expect(resolvedAlignment.y, lessThan(0));
      expect(
        translation.transform.getTranslation().y,
        inExclusiveRange(0, PerfectMotion.dialogRise),
      );

      reduced.value = true;
      await tester.pump();
      expect(find.text('Motion details'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('perfect-dialog-scale')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey<String>('perfect-dialog-scale')),
            )
            .transform
            .storage
            .first,
        1,
      );

      await tester.tap(find.byKey(const ValueKey<String>('dialog-close')));
      await tester.pump();
      await tester.pump();
      await dialogClosed.future;
      await tester.pump();
      expect(find.text('Motion details'), findsNothing);
      expect(invokingFocus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sync loop pauses in background and resumes from current truth', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PerfectTheme.light(),
        home: Scaffold(
          body: PerfectSyncIndicator(
            status: const PlannerSyncStatus(phase: PlannerSyncPhase.syncing),
            onRetry: () async {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test(
    'storyboards and implementation inventory cover every Stage 09 role',
    () {
      final root = Directory.current.path;
      final evidence = Directory(
        '$root/docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/'
        'design/01-foundations/stage09-motion',
      );
      final manifest =
          jsonDecode(File('${evidence.path}/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      final inventory =
          jsonDecode(
                File(
                  '${evidence.path}/implementation-inventory.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final roles = (manifest['roles'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final records = (inventory['records'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final expected = <String>{
        'motion-route',
        'motion-title',
        'motion-navigation',
        'motion-composer',
        'motion-selector',
        'motion-status-log',
        'motion-sync',
        'motion-overlay',
        'motion-inspector',
        'motion-wizard',
        'motion-responsive-resize',
      };
      expect(roles.map((role) => role['id']).toSet(), expected);
      expect(records.length, greaterThanOrEqualTo(90));
      expect(
        records.map((record) => record['role']).toSet(),
        containsAll(expected),
      );
      for (final role in roles) {
        expect(role['focus'], isNotEmpty);
        expect(role['budget'], isNotEmpty);
        expect(role['background'], contains('Pause'));
        for (final file in (role['files'] as Map<String, dynamic>).values) {
          expect(File('${evidence.path}/$file').existsSync(), isTrue);
        }
      }
    },
  );

  test('profile evidence is hashed and keeps emulator claims bounded', () {
    final runtime = Directory(
      '${Directory.current.path}/docs/codex/'
      '2026-07-27-perfect-orbit-day-private-planner-rebuild/'
      'design/01-foundations/stage09-motion/runtime',
    );
    final summary =
        jsonDecode(
              File(
                '${runtime.path}/android-profile-performance-summary.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(summary['schema'], 'perfect.motion.profile-summary.v1');
    final gates = (summary['gates'] as Map<String, dynamic>);
    expect(gates['workspaceBuildThread60Hz'], 'pass');
    expect(gates['noSustainedIdleTicker'], 'pass');
    expect(gates['absoluteEmulatorRaster'], 'inconclusive');
    expect(gates['physicalAndroidNoJank'], 'open');
    expect(gates['WindowsNoJank'], 'open');

    final idleWindows = (summary['idleWindows'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(idleWindows, hasLength(2));
    expect(
      idleWindows.every((window) => (window['frames'] as int) <= 1),
      isTrue,
    );

    final hashes = (summary['runtimeArtifacts'] as Map<String, dynamic>);
    expect(hashes, hasLength(9));
    for (final entry in hashes.entries) {
      final file = File('${runtime.path}/${entry.key}');
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(entry.value, hasLength(64), reason: entry.key);
    }
    expect(
      (summary['interpretation'] as List<dynamic>).last,
      contains('No physical-device or Windows performance claim'),
    );
  });

  test('local Android profile runs cannot replace the signed private app', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final profileStart = gradle.indexOf('getByName("profile")');
    final releaseStart = gradle.indexOf('release {', profileStart);

    expect(profileStart, greaterThanOrEqualTo(0));
    expect(releaseStart, greaterThan(profileStart));
    final profileBlock = gradle.substring(profileStart, releaseStart);
    expect(profileBlock, contains('applicationIdSuffix = ".preview"'));
    expect(profileBlock, contains('versionNameSuffix = "-profile"'));
    expect(
      profileBlock,
      contains("Never let a local performance run replace or"),
    );
  });

  test(
    'production overlays and motion timings cannot bypass the vocabulary',
    () {
      final sourceFiles = <File>[
        ..._dartFiles(Directory('lib/presentation')),
        ..._dartFiles(Directory('lib/ai')),
        ..._dartFiles(Directory('lib/auth')),
        File('lib/feedback/src/feedback_overlay.dart'),
      ];
      var perfectDialogs = 0;
      var sheets = 0;
      var menus = 0;
      for (final file in sourceFiles) {
        final source = file.readAsStringSync();
        expect(
          RegExp(r'\bshowDialog(?:<[^>]+>)?\s*\(').hasMatch(source),
          isFalse,
          reason: '${file.path} bypasses showPerfectDialog.',
        );
        expect(
          RegExp(r'\bCurves\.').hasMatch(source),
          file.path.endsWith('perfect_theme.dart'),
          reason: '${file.path} owns a curve outside PerfectMotion.',
        );
        if (!file.path.endsWith('perfect_theme.dart')) {
          expect(
            RegExp(r'Duration\(milliseconds:').hasMatch(source),
            isFalse,
            reason: '${file.path} owns a raw UI motion duration.',
          );
        }

        for (final match in RegExp(
          r'\bshowPerfectDialog(?:<[^>]+>)?\s*\(',
        ).allMatches(source)) {
          perfectDialogs++;
          final call = _balancedCall(source, match.start);
          expect(
            call.contains('PerfectStagedEntrance'),
            isFalse,
            reason: '${file.path} double-animates a dialog child.',
          );
        }
        for (final match in RegExp(
          r'\bshowModalBottomSheet(?:<[^>]+>)?\s*\(',
        ).allMatches(source)) {
          sheets++;
          expect(
            _balancedCall(source, match.start),
            contains(
              'sheetAnimationStyle: PerfectMotion.modalSheetStyle(context)',
            ),
            reason: '${file.path} uses a stock sheet transition.',
          );
        }
        for (final match in RegExp(
          r'\bshowMenu(?:<[^>]+>)?\s*\(',
        ).allMatches(source)) {
          menus++;
          expect(
            _balancedCall(source, match.start),
            contains('popUpAnimationStyle: PerfectMotion.menuStyle(context)'),
            reason: '${file.path} uses a stock popup transition.',
          );
        }
      }
      expect(perfectDialogs, greaterThanOrEqualTo(15));
      expect(sheets, greaterThanOrEqualTo(10));
      expect(menus, greaterThanOrEqualTo(1));
    },
  );
}

class _StatefulMotionPage extends StatefulWidget {
  const _StatefulMotionPage({
    super.key,
    required this.index,
    required this.rebuildSerial,
  });

  final int index;
  final int rebuildSerial;

  @override
  State<_StatefulMotionPage> createState() => _StatefulMotionPageState();
}

class _StatefulMotionPageState extends State<_StatefulMotionPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.primaries[widget.index],
    child: Center(
      child: TextButton(
        key: ValueKey<String>('counter-${widget.index}'),
        onPressed: () => setState(() => count++),
        child: Text('page ${widget.index} · $count'),
      ),
    ),
  );
}

List<int> _activeDestinationIndices(WidgetTester tester) => tester
    .widgetList<Offstage>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Offstage &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'perfect-destination-offstage-',
            ),
        skipOffstage: false,
      ),
    )
    .where((widget) => !widget.offstage)
    .map((widget) {
      final key = (widget.key! as ValueKey<String>).value;
      return int.parse(key.substring(key.lastIndexOf('-') + 1));
    })
    .toList(growable: false);

double _stagedOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.byKey(const ValueKey<String>('perfect-staged-entrance-opacity')),
    )
    .opacity;

Iterable<File> _dartFiles(Directory directory) sync* {
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

String _balancedCall(String source, int start) {
  final open = source.indexOf('(', start);
  expect(open, greaterThanOrEqualTo(0));
  var depth = 0;
  var quote = 0;
  var escaped = false;
  for (var index = open; index < source.length; index++) {
    final code = source.codeUnitAt(index);
    if (quote != 0) {
      if (escaped) {
        escaped = false;
      } else if (code == 92) {
        escaped = true;
      } else if (code == quote) {
        quote = 0;
      }
      continue;
    }
    if (code == 39 || code == 34) {
      quote = code;
    } else if (code == 40) {
      depth++;
    } else if (code == 41 && --depth == 0) {
      return source.substring(start, index + 1);
    }
  }
  fail('Unbalanced call at source offset $start.');
}
