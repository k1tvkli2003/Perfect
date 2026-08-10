import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _root = 'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild';
const _manifestRoot = '$_root/design/04-copy-manifests';
const _previewFiles = <String>[
  'anatomy.svg',
  'states-light.png',
  'states-dark.png',
  'responsive.png',
  'accessibility.png',
  'motion-board.png',
  'neighbor-plate.png',
];

void main() {
  late Map<String, dynamic> registry;
  late Map<String, dynamic> foundations;
  late Map<String, dynamic> components;
  late Map<String, dynamic> assets;
  late Map<String, dynamic> motion;
  late List<String> gateComponentIds;

  setUpAll(() {
    registry = _json('$_manifestRoot/stage04-registry.json');
    foundations = _json('$_manifestRoot/foundations.json');
    components = _json('$_manifestRoot/components.json');
    assets = _json('$_manifestRoot/assets.json');
    motion = _json('$_manifestRoot/motion.json');
    gateComponentIds = RegExp(r'^\| `([a-z0-9-]+)` \| .+ \|$', multiLine: true)
        .allMatches(_source('$_root/stages/preview-production-gate.md'))
        .map((match) => match.group(1)!)
        .where((id) => !id.startsWith('fnd-'))
        .toList(growable: false);
  });

  group('Stage 04 responsive design-system gate', () {
    test('freezes the exact 9/181/27/1267/48/20 catalog counts', () {
      expect(registry['catalog_version'], 'ps01-ds-1.0.0');
      expect(registry['direction'], 'PS01 Perfect Day Instrument');
      expect(registry['counts'], <String, dynamic>{
        'foundations': 9,
        'components': 181,
        'families': 27,
        'component_previews': 1267,
        'category_icons': 48,
        'motions': 20,
      });
      expect(foundations['exact_foundation_count'], 9);
      expect(components['exact_component_count'], 181);
      expect(components['exact_family_count'], 27);
      expect(components['exact_preview_count'], 1267);
      expect(assets['exact_asset_count'], 53);
      expect(motion['count'], 20);
      expect(gateComponentIds, hasLength(181));
      expect(gateComponentIds.toSet(), hasLength(181));
    });

    test('maps every gate ID once and preserves its canonical order', () {
      final entries = _listOfMaps(components['components']);
      final ids = entries
          .map((entry) => entry['component_id'] as String)
          .toList(growable: false);
      expect(ids, orderedEquals(gateComponentIds));
      expect(ids.toSet(), hasLength(181));

      final familyCounts = <String, int>{};
      for (final entry in entries) {
        final family = entry['family'] as String;
        familyCounts.update(family, (value) => value + 1, ifAbsent: () => 1);
      }
      expect(familyCounts, hasLength(27));
      expect(familyCounts['ct'], 28);
      expect(familyCounts['sh'], 14);
      expect(familyCounts['habit'], 12);
      expect(familyCounts['wg'], 8);
    });

    test(
      'gives every component one full behavior and decomposition contract',
      () {
        for (final entry in _listOfMaps(components['components'])) {
          final id = entry['component_id'] as String;
          final contract = _json(entry['contract'] as String);
          expect(contract['component_id'], id, reason: id);
          expect(contract['catalog_version'], 'ps01-ds-1.0.0', reason: id);
          expect(
            contract['semantic_owner'],
            contract['canonical_semantic_owner'],
          );

          final anatomy = _map(contract['anatomy']);
          expect(anatomy['slots'], isNotEmpty, reason: id);
          expect(
            anatomy['alignment_axes'],
            contains('optical-center'),
            reason: id,
          );
          expect(anatomy['stable_outer_geometry'], isTrue, reason: id);

          final responsive = _map(contract['responsive']);
          for (final layout in const <String>[
            'phone',
            'tablet',
            'windows',
            'short_height',
          ]) {
            expect(responsive[layout], isNotEmpty, reason: '$id/$layout');
          }
          expect(
            responsive['breakpoint_state_continuity'],
            containsAll(<String>['draft', 'focus', 'selection', 'scroll']),
            reason: id,
          );

          final interaction = _map(contract['interaction']);
          expect(interaction['touch'].join(' '), contains('48dp'), reason: id);
          expect(interaction['mouse'], isNotEmpty, reason: id);
          expect(
            interaction['keyboard'],
            hasLength(greaterThanOrEqualTo(3)),
            reason: id,
          );
          expect(
            interaction['screen_reader'],
            hasLength(greaterThanOrEqualTo(2)),
            reason: id,
          );
          expect(contract['rtl_mixed_copy'], contains('200%'), reason: id);
          expect(contract['reduced_motion'], isNotEmpty, reason: id);
          expect(contract['performance_budget'], isNotEmpty, reason: id);
          expect(contract['consumers'], isNotEmpty, reason: id);
          expect(
            contract['fixture_boundary'],
            contains('cannot be imported or seeded'),
            reason: id,
          );

          final decomposition = _map(contract['decomposition']);
          expect(
            decomposition['forbidden_flattening'],
            containsAll(<String>['user data', 'interactive control']),
            reason: id,
          );
          expect(
            contract['preview_files'],
            orderedEquals(_previewFiles),
            reason: id,
          );
          expect(
            _map(contract['preview_sha256']).keys,
            orderedEquals(_previewFiles),
            reason: id,
          );
        }
      },
    );

    test(
      'ships all seven canonical previews at exact dimensions with hashes',
      () {
        for (final entry in _listOfMaps(components['components'])) {
          final id = entry['component_id'] as String;
          final previews = _map(entry['previews']);
          final hashes = _map(entry['preview_sha256']);
          expect(previews.keys, orderedEquals(_previewFiles), reason: id);
          expect(hashes.keys, orderedEquals(_previewFiles), reason: id);
          for (final preview in _previewFiles) {
            final path = previews[preview] as String;
            final file = File(path);
            expect(file.existsSync(), isTrue, reason: '$id/$preview');
            expect(file.lengthSync(), greaterThan(100), reason: '$id/$preview');
            expect(
              hashes[preview],
              matches(RegExp(r'^[a-f0-9]{64}$')),
              reason: '$id/$preview',
            );
            if (preview.endsWith('.png')) {
              expect(_pngDimensions(file), const (
                1200,
                800,
              ), reason: '$id/$preview');
            } else {
              final svg = _source(path);
              expect(
                svg.trimLeft(),
                startsWith('<svg'),
                reason: '$id/$preview',
              );
              expect(
                svg.trimRight(),
                endsWith('</svg>'),
                reason: '$id/$preview',
              );
            }
          }
        }
      },
    );

    test('keeps nine responsive foundation specimens and their contracts', () {
      final entries = _listOfMaps(foundations['foundations']);
      expect(entries, hasLength(9));
      final ids = entries.map((entry) => entry['foundation_id']).toSet();
      expect(ids, <String>{
        'fnd-color-roles',
        'fnd-type-latin',
        'fnd-type-persian',
        'fnd-spacing-density',
        'fnd-grid-width',
        'fnd-icons',
        'fnd-material',
        'fnd-motion',
        'fnd-focus-a11y',
      });
      for (final entry in entries) {
        final contract = _json(entry['contract'] as String);
        expect(
          contract['required_themes'],
          orderedEquals(<String>['light', 'dark', 'high-contrast']),
        );
        expect(
          contract['required_layouts'],
          hasLength(greaterThanOrEqualTo(8)),
        );
        expect(contract['live_copy_boundary'], contains('remain live'));
        for (final preview in const <String>['specimen.png', 'stress.png']) {
          expect(
            _pngDimensions(File(_map(entry['previews'])[preview] as String)),
            const (1200, 800),
          );
        }
      }
    });

    test('provides 48 transparent semantic SVG category pictograms', () {
      final archive = _map(foundations['category_icon_archive']);
      final icons = _listOfMaps(archive['icons']);
      expect(archive['count'], 48);
      expect(icons, hasLength(48));
      expect(icons.map((icon) => icon['id']).toSet(), hasLength(48));
      expect(File(archive['license_notice'] as String).existsSync(), isTrue);
      for (final icon in icons) {
        final source = _source(icon['file'] as String);
        expect(
          source,
          contains('viewBox="0 0 512 512"'),
          reason: '${icon['id']}',
        );
        expect(source, contains('role="img"'), reason: '${icon['id']}');
        expect(source, contains('<title'), reason: '${icon['id']}');
        expect(
          source,
          isNot(matches(RegExp(r'<rect[^>]+(?:width="512"|width="100%")'))),
          reason: '${icon['id']} transparent backing',
        );
        expect(icon['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
      }
    });

    test(
      'defines complete motion and asset provenance instead of decoration',
      () {
        final motions = _listOfMaps(motion['motions']);
        expect(motions, hasLength(20));
        expect(motions.map((entry) => entry['id']).toSet(), hasLength(20));
        for (final entry in motions) {
          for (final field in const <String>[
            'trigger',
            'affected_layers',
            'frames',
            'interruption',
            'reverse',
            'focus_semantics_timing',
            'background_resume',
            'reduced',
            'frame_resource_budget',
          ]) {
            expect(entry[field], isNotEmpty, reason: '${entry['id']}/$field');
          }
        }

        final assetEntries = _listOfMaps(assets['assets']);
        expect(assetEntries, hasLength(53));
        for (final entry in assetEntries) {
          expect(
            entry['classification'],
            isNotEmpty,
            reason: '${entry['asset_id']}',
          );
          expect(
            entry['ownership_license'],
            isNotEmpty,
            reason: '${entry['asset_id']}',
          );
          expect(
            entry['transparent_bounds'],
            isNotEmpty,
            reason: '${entry['asset_id']}',
          );
          expect(
            entry['safe_zone'],
            isNotEmpty,
            reason: '${entry['asset_id']}',
          );
          expect(
            entry['semantic_equivalent'],
            isNotEmpty,
            reason: '${entry['asset_id']}',
          );
          expect(
            entry['consumers'],
            isNotEmpty,
            reason: '${entry['asset_id']}',
          );
          expect(entry['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
        }
      },
    );

    test(
      'keeps preview fixtures and generated catalog out of production state',
      () {
        expect(
          components['production_boundary'],
          contains('No Flutter, native, domain, database, auth or sync source'),
        );
        final productionSeedSources = <String>[
          _source('lib/planner/data/planner_database.dart'),
          _source('lib/planner/data/planner_local_store.dart'),
          ..._textSourcesUnder('supabase/migrations'),
        ].join('\n');
        for (final fixture in const <String>[
          'Cardiology deep work',
          'Review project brief',
          'Drink water',
          'Review brief',
          'Deep work',
        ]) {
          expect(
            productionSeedSources,
            isNot(contains(fixture)),
            reason: fixture,
          );
        }
        expect(
          _source('tool/generate_stage04_design_system.cjs'),
          contains('STAGE04_GENERATION_PASS'),
        );
        expect(
          _source('tool/verify_stage04_design_system.cjs'),
          contains('STAGE04_VERIFY_PASS'),
        );
      },
    );
  });
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(_source(path)) as Map<String, dynamic>;

Map<String, dynamic> _map(dynamic value) =>
    (value as Map<Object?, Object?>).cast<String, dynamic>();

List<Map<String, dynamic>> _listOfMaps(dynamic value) =>
    (value as List<dynamic>).map(_map).toList(growable: false);

String _source(String path) => File(
  path,
).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');

(int, int) _pngDimensions(File file) {
  final handle = file.openSync();
  try {
    final header = Uint8List(24);
    expect(handle.readIntoSync(header), 24, reason: file.path);
    expect(
      header.sublist(0, 8),
      orderedEquals(const <int>[137, 80, 78, 71, 13, 10, 26, 10]),
      reason: file.path,
    );
    final bytes = ByteData.sublistView(header);
    return (bytes.getUint32(16), bytes.getUint32(20));
  } finally {
    handle.closeSync();
  }
}

Iterable<String> _textSourcesUnder(String path) sync* {
  final directory = Directory(path);
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is! File) continue;
    final extension = entity.path
        .substring(entity.path.lastIndexOf('.'))
        .toLowerCase();
    if (!const <String>['.sql', '.md', '.json'].contains(extension)) continue;
    yield _source(entity.path);
  }
}
