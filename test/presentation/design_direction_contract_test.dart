import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _root = 'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild';

void main() {
  late String recipes;
  late String habitNow;
  late String habitNowManifest;
  late String research;
  late String currentRuntimeManifest;
  late String opinionLedger;
  late String selection;
  late String selected;
  late String modelManifest;
  late String deterministicManifest;
  late String renderer;

  setUpAll(() {
    recipes = _source(
      '$_root/design/00-evidence/decomposition/'
      '24-raw-direction-recipes.md',
    );
    habitNow = _source(
      '$_root/design/00-evidence/decomposition/'
      'habitnow-2026-flow.md',
    );
    habitNowManifest = _source(
      '$_root/design/00-evidence/references/'
      'habitnow-2026/manifest.md',
    );
    research = _source(
      '$_root/design/00-evidence/references/research-sources.md',
    );
    currentRuntimeManifest = _source(
      '$_root/design/00-evidence/current-runtime/manifest.md',
    );
    opinionLedger = _source(
      '$_root/design/00-evidence/decision-ledger/'
      'integrity-opinion-ledger.md',
    );
    selection = _source(
      '$_root/design/00-evidence/decision-ledger/'
      'direction-selection.md',
    );
    selected = _source(
      '$_root/design/00-evidence/decision-ledger/'
      'selected-direction.md',
    );
    modelManifest = _source(
      '$_root/design/00-evidence/references/'
      'finalist-boards/manifest.md',
    );
    deterministicManifest = _source(
      '$_root/design/01-foundations/'
      'stage03-selected/manifest.md',
    );
    renderer = _source('tool/render_design_svg.cjs');
  });

  group('Stage 03 evidence-led design direction', () {
    test('evaluates exactly 24 distinct named recipes before selection', () {
      final headings = RegExp(
        r'^## R\d{2} — .+$',
        multiLine: true,
      ).allMatches(recipes).map((match) => match.group(0)!).toList();
      expect(headings, hasLength(24));
      for (var index = 1; index <= 24; index++) {
        final id = 'R${index.toString().padLeft(2, '0')}';
        expect(
          headings.where((heading) => heading.startsWith('## $id ')),
          hasLength(1),
          reason: '$id must be one real direction, not a palette duplicate.',
        );
      }
      for (final requiredModel in const <String>[
        'radical rebuild',
        'operationally calm',
        'Windows-first',
        'one-handed',
      ]) {
        expect(recipes.toLowerCase(), contains(requiredModel.toLowerCase()));
      }
    });

    test('decomposes all 25 owner-provided HabitNow screenshots by logic', () {
      final screenshotRows = RegExp(
        r'^\| `Screenshot_[^`]+\.png` \|',
        multiLine: true,
      ).allMatches(habitNow);
      expect(screenshotRows, hasLength(25));
      for (final contract in const <String>[
        'Canonical dependency graph',
        'Named adaptive steps',
        'recurrence',
        'Flexible',
        'Pending',
        'Draft continuity',
        'No example entity',
      ]) {
        expect(habitNow, contains(contract), reason: contract);
      }
    });

    test('uses current product, platform and visual evidence without cargo cult', () {
      for (final url in const <String>[
        'https://play.google.com/store/apps/details?gl=US&id=com.habitnow',
        'https://ticktick.com/features?language=en_US',
        'https://www.todoist.com/help/articles/does-todoist-support-start-dates-qhqlgZhk',
        'https://structured.app/',
        'https://help.sunsama.com/docs/usage-guides/daily-planning/',
        'https://product.akiflow.com/help/articles/6483573-command-bar',
        'https://help.amazingmarvin.com/en/articles/4835241-habits',
        'https://developer.android.com/develop/adaptive-apps/guides/use-window-size-classes?hl=en',
        'https://developer.android.com/develop/adaptive-apps/guides/canonical-layouts',
        'https://developer.android.com/develop/ui/views/appwidgets/layouts',
        'https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/navigationview',
        'https://learn.microsoft.com/en-us/windows/apps/develop/motion/connected-animation',
      ]) {
        expect(research, contains(url), reason: url);
      }
      expect(research, contains('Dribbble'));
      expect(
        _singleLine(research),
        contains(
          'never a fidelity target and cannot overrule operational evidence',
        ),
      );

      final currentRouteRoot = Directory(
        '$_root/design/00-evidence/current-runtime/android-routes',
      );
      final currentRouteNames =
          currentRouteRoot
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .where((name) => name.endsWith('.png'))
              .toList()
            ..sort();
      expect(currentRouteNames, hasLength(14));
      expect(
        RegExp(
          r'^\| `android-routes/[^`]+\.png` \|',
          multiLine: true,
        ).allMatches(currentRuntimeManifest),
        hasLength(14),
      );
      for (final extension in const <String>['svg', 'png']) {
        expect(
          File(
            '$_root/design/00-evidence/current-runtime/'
            'current-phone-contact-sheet.$extension',
          ).existsSync(),
          isTrue,
        );
      }

      final habitNowRoot = Directory(
        '$_root/design/00-evidence/references/habitnow-2026',
      );
      final habitNowSourceNames =
          habitNowRoot
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .where(
                (name) =>
                    name.startsWith('Screenshot_') && name.endsWith('.png'),
              )
              .toList()
            ..sort();
      expect(habitNowSourceNames, hasLength(25));
      expect(
        RegExp(
          r'^\| `Screenshot_[^`]+\.png` \|',
          multiLine: true,
        ).allMatches(habitNowManifest),
        hasLength(25),
      );
      for (final name in habitNowSourceNames) {
        expect(habitNowManifest, contains('`$name`'));
      }
      for (final extension in const <String>['svg', 'png']) {
        expect(
          File(
            '$_root/design/00-evidence/references/habitnow-2026/'
            'habitnow-contact-sheet.$extension',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '$_root/design/00-evidence/references/finalist-boards/'
            'finalist-contact-sheet.$extension',
          ).existsSync(),
          isTrue,
        );
      }
    });

    test('classifies the whole product with the five-way Integrity ledger', () {
      for (final decision in const <String>[
        '`KEEP`',
        '`REFINE`',
        '`REDESIGN`',
        '`REMOVE`',
        '`ADD`',
      ]) {
        expect(opinionLedger, contains(decision), reason: decision);
      }
      final normalizedLedger = opinionLedger.toLowerCase();
      for (final surface in const <String>[
        'identity, shell, navigation, common components',
        'today/tasks/plan/habits/goals/focus',
        'create/edit/detail',
        'ai/voice',
        'states, motion',
        'widget, notifications/deep links',
        'feedback, auth/session, settings/diagnostics',
        'local-first/sync/conflict',
        'packaging/release',
      ]) {
        expect(normalizedLedger, contains(surface), reason: surface);
      }
      expect(opinionLedger, contains('No silent rows'));
    });

    test('keeps eight ImageGen boards as rejected model-native evidence', () {
      final boardDirectory = Directory(
        '$_root/design/00-evidence/references/finalist-boards',
      );
      final boardNames =
          boardDirectory
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .where((name) => name.endsWith('-model-native.png'))
              .toList()
            ..sort();
      expect(boardNames, hasLength(8));
      for (final prefix in const <String>['f1', 'f2', 'f3', 'f4']) {
        expect(
          boardNames.where((name) => name.startsWith('$prefix-')),
          hasLength(2),
        );
      }
      expect(modelManifest, contains('`textEmbeddingMode`: `model_native`'));
      expect(
        RegExp('rejected as canonical').allMatches(modelManifest),
        hasLength(8),
      );
      expect(modelManifest, contains('None is a canonical Copy target'));
    });

    test('freezes PS01 as a responsive day instrument, not an Orbit', () {
      expect(selection, contains('R01 Pulse and Stream'));
      for (final finalist in const <String>[
        'Finalist F1 — Pulse and Stream',
        'Finalist F2 — Living Ledger',
        'Finalist F3 — Daily Desk',
        'Finalist F4 — Adaptive Instrument Cluster',
      ]) {
        expect(selection, contains(finalist));
      }
      expect(selected, contains('`PS01 Perfect Day Instrument`'));
      expect(selected, contains('Status: **selected and frozen'));
      expect(selected, contains('It is not an Orbit'));
      expect(selected, contains('one continuous day Stream'));
      expect(selected, contains('Android phone'));
      expect(selected, contains('Android tablet'));
      expect(selected, contains('### Windows'));
      expect(selected, contains('row body -> view-first detail/history'));
      expect(_singleLine(selected), contains('does not summon IME'));
      expect(selected, contains('no write before Apply'));
      expect(selected, contains('Rapid habit taps coalesce visually'));
      expect(selected, contains('## Supersession rule'));
    });

    test(
      'freezes exact identity bytes and six deterministic native plates',
      () {
        final selectedRoot = '$_root/design/01-foundations/stage03-selected';
        _expectSameBytes(
          '$selectedRoot/day-compass-transparent-512.png',
          'assets/brand/perfect-launcher.png',
        );
        _expectSameBytes(
          '$selectedRoot/perfect-wordmark.png',
          'assets/brand/perfect-wordmark.png',
        );
        _expectSameBytes(
          '$selectedRoot/perfect-wordmark-dark.png',
          'assets/brand/perfect-wordmark-dark.png',
        );

        for (final plate in const <String>[
          'identity-plate',
          'shell-plate',
          'workflow-plate',
          'state-plate',
          'motion-plate',
          'typography-plate',
        ]) {
          expect(File('$selectedRoot/$plate.svg').existsSync(), isTrue);
          expect(File('$selectedRoot/$plate.png').existsSync(), isTrue);
          expect(
            deterministicManifest,
            contains('`ps01-${plate.split('-').first}`'),
          );
        }
        expect(
          deterministicManifest,
          contains('`textEmbeddingMode`: `single_render_native`'),
        );
        expect(deterministicManifest, contains('original size'));
        expect(renderer, contains("require('playwright')"));
        expect(renderer, contains('PERFECT_DESIGN_BROWSER'));
        expect(renderer, isNot(contains('overlay')));
      },
    );

    test(
      'keeps preview fixture entities out of persisted production seeds',
      () {
        final productionSeedSources = <String>[
          _source('lib/planner/data/planner_database.dart'),
          _source('lib/planner/data/planner_local_store.dart'),
          ..._textSourcesUnder('supabase/migrations'),
        ].join('\n');
        for (final fixture in const <String>[
          'Focus Deep Work',
          'Water plants',
          'Cardiology deep work',
          'Review project brief',
          'Book lab appointment',
        ]) {
          expect(
            productionSeedSources,
            isNot(contains(fixture)),
            reason: fixture,
          );
        }
      },
    );
  });
}

String _source(String path) => File(
  path,
).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');

void _expectSameBytes(String first, String second) {
  expect(
    File(first).readAsBytesSync(),
    orderedEquals(File(second).readAsBytesSync()),
    reason: '$first must stay byte-identical to $second.',
  );
}

Iterable<String> _textSourcesUnder(String path) sync* {
  final directory = Directory(path);
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!const <String>['.sql', '.md', '.json'].contains(
      entity.path.substring(entity.path.lastIndexOf('.')).toLowerCase(),
    )) {
      continue;
    }
    yield _source(entity.path);
  }
}

String _singleLine(String value) => value.replaceAll(RegExp(r'\s+'), ' ');
