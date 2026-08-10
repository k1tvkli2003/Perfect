import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _root = 'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild';
const _pageRoot = '$_root/design/03-pages';
const _manifestRoot = '$_root/design/04-copy-manifests';
const _comparisonRoot = '$_root/design/05-runtime-comparisons/stage05';
const _rejectedRoot = '$_root/design/rejected/stage05';
const _catalogVersion = 'ps01-pages-1.0.0';
const _candidateFiles = <String>[
  'candidate-focus-spine.png',
  'candidate-split-workbench.png',
  'candidate-command-ledger.png',
];
const _canonicalDimensions = <String, (int, int)>{
  'phone-compact.png': (390, 844),
  'phone-landscape.png': (844, 390),
  'tablet-portrait.png': (800, 1280),
  'tablet-landscape.png': (1280, 800),
  'windows-compact.png': (720, 540),
  'windows-wide.png': (1366, 768),
  'dark.png': (390, 844),
  'stress.png': (720, 540),
  'system-state.png': (1200, 800),
  'motion-board.png': (1200, 800),
};
const _comparisonFiles = <String>{
  'comparison.json',
  'diff.png',
  'mismatch.md',
  'overlay.png',
  'reference-meta.json',
  'reference.png',
  'runtime-meta.json',
  'runtime.png',
};
const _hashedManifestNames = <String>[
  'pages.json',
  'copy.json',
  'fixtures.json',
  'coverage-ledger.json',
  'quality-harness.json',
  'stage05-registry.json',
];

void main() {
  late Map<String, dynamic> registry;
  late Map<String, dynamic> pages;
  late Map<String, dynamic> copy;
  late Map<String, dynamic> fixtures;
  late Map<String, dynamic> coverage;
  late Map<String, dynamic> quality;
  late List<String> gatePageIds;

  setUpAll(() {
    registry = _json('$_manifestRoot/stage05-registry.json');
    pages = _json('$_manifestRoot/pages.json');
    copy = _json('$_manifestRoot/copy.json');
    fixtures = _json('$_manifestRoot/fixtures.json');
    coverage = _json('$_manifestRoot/coverage-ledger.json');
    quality = _json('$_manifestRoot/quality-harness.json');

    final gate = _source('$_root/stages/preview-production-gate.md');
    final pageSection = gate.substring(
      gate.indexOf('## 5. Full-page composition registry'),
      gate.indexOf('## 6. Coverage matrix'),
    );
    gatePageIds = RegExp(r'`(pg-[a-z0-9-]+)`')
        .allMatches(pageSection)
        .map((match) => match.group(1)!)
        .toList(growable: false);
  });

  group('Stage 05 page-preview and Copy quality gate', () {
    test('freezes the exact 134-page catalog and canonical order', () {
      expect(registry['catalog_version'], _catalogVersion);
      expect(registry['component_catalog_version'], 'ps01-ds-1.0.0');
      expect(registry['direction'], 'PS01 Perfect Day Instrument');
      expect(registry['counts'], <String, dynamic>{
        'pages': 134,
        'page_families': 11,
        'structural_candidates': 402,
        'canonical_previews': 1340,
        'canonical_render_audits': 1340,
        'component_consumers': 181,
        'live_copy_entries': 1072,
        'fixtures': 6,
        'motion_ids': 20,
        'comparison_smokes': 3,
      });
      expect(gatePageIds, hasLength(134));
      expect(gatePageIds.toSet(), hasLength(134));
      expect(
        _listOfMaps(pages['pages']).map((page) => page['page_id']),
        orderedEquals(gatePageIds),
      );
      expect(
        _listOfMaps(pages['pages']).map((page) => page['family']).toSet(),
        hasLength(11),
      );
    });

    test('gives every page three structurally distinct decided candidates', () {
      for (final page in _listOfMaps(pages['pages'])) {
        final id = page['page_id'] as String;
        final contract = _json(page['contract'] as String);
        final decision = _source(page['decision'] as String);
        final candidates = _map(page['candidates']);
        final hashes = _map(page['candidate_sha256']);

        expect(contract['page_id'], id, reason: id);
        expect(contract['preview_version'], _catalogVersion, reason: id);
        expect(contract['selected_candidate'], page['selected_candidate']);
        expect(contract['primary_question'], isNotEmpty, reason: id);
        expect(contract['primary_action'], isNotEmpty, reason: id);
        expect(contract['scan_order'], hasLength(greaterThanOrEqualTo(5)));
        expect(contract['semantic_order'], hasLength(greaterThanOrEqualTo(6)));
        expect(
          contract['responsive_equations'],
          hasLength(greaterThanOrEqualTo(4)),
        );
        expect(contract['pane_rules'], hasLength(greaterThanOrEqualTo(3)));
        expect(contract['production_boundary'], startsWith('Design-only.'));
        expect(
          contract['fixture_boundary'],
          contains('cannot be imported or seeded into production'),
        );
        expect(candidates.keys, orderedEquals(_candidateFiles), reason: id);
        expect(hashes.keys, orderedEquals(_candidateFiles), reason: id);
        for (final name in _candidateFiles) {
          final file = File(candidates[name] as String);
          expect(file.existsSync(), isTrue, reason: '$id/$name');
          expect(_pngDimensions(file), const (720, 480), reason: '$id/$name');
          expect(hashes[name], matches(RegExp(r'^[a-f0-9]{64}$')));
          expect(decision, contains(name.substring(0, name.length - 4)));
        }
        expect(decision, contains('## Verdicts'), reason: id);
        expect(decision, contains('## Selected'), reason: id);
      }
    });

    test('ships and audits ten canonical compositions for every page', () {
      var previewCount = 0;
      var auditCount = 0;
      for (final page in _listOfMaps(pages['pages'])) {
        final id = page['page_id'] as String;
        final previews = _map(page['previews']);
        final hashes = _map(page['preview_sha256']);
        final audits = _map(page['canonical_audits']);
        expect(
          previews.keys,
          orderedEquals(_canonicalDimensions.keys),
          reason: id,
        );
        expect(
          hashes.keys,
          orderedEquals(_canonicalDimensions.keys),
          reason: id,
        );
        expect(
          audits.keys,
          orderedEquals(_canonicalDimensions.keys),
          reason: id,
        );

        for (final entry in _canonicalDimensions.entries) {
          final file = File(previews[entry.key] as String);
          expect(file.existsSync(), isTrue, reason: '$id/${entry.key}');
          expect(_pngDimensions(file), entry.value, reason: '$id/${entry.key}');
          expect(hashes[entry.key], matches(RegExp(r'^[a-f0-9]{64}$')));

          final audit = _map(audits[entry.key]);
          final document = _map(audit['document']);
          final rootBounds = _map(audit['root_bounds']);
          expect(document['width'], entry.value.$1, reason: '$id/${entry.key}');
          expect(
            document['height'],
            entry.value.$2,
            reason: '$id/${entry.key}',
          );
          expect(rootBounds['left'], 0, reason: '$id/${entry.key}');
          expect(rootBounds['top'], 0, reason: '$id/${entry.key}');
          expect(
            rootBounds['width'],
            entry.value.$1,
            reason: '$id/${entry.key}',
          );
          expect(
            rootBounds['height'],
            entry.value.$2,
            reason: '$id/${entry.key}',
          );
          expect(
            audit['horizontal_overflow'],
            isEmpty,
            reason: '$id/${entry.key}',
          );
          expect(audit['clipped_copy'], isEmpty, reason: '$id/${entry.key}');
          expect(audit['failure_ids'], isEmpty, reason: '$id/${entry.key}');
          previewCount += 1;
          auditCount += 1;
        }
      }
      expect(previewCount, 1340);
      expect(auditCount, 1340);
    });

    test('maps all 181 Stage 04 components to explicit page consumers', () {
      final componentCatalog = _json('$_manifestRoot/components.json');
      final componentIds = _listOfMaps(
        componentCatalog['components'],
      ).map((entry) => entry['component_id'] as String).toSet();
      final consumerEntries = _listOfMaps(coverage['component_consumers']);
      final pageIds = gatePageIds.toSet();
      expect(componentIds, hasLength(181));
      expect(consumerEntries, hasLength(181));
      expect(
        consumerEntries.map((entry) => entry['component_id']).toSet(),
        componentIds,
      );
      expect(coverage['unconsumed_component_count'], 0);
      for (final entry in consumerEntries) {
        final consumers = (entry['consumers'] as List<dynamic>).cast<String>();
        expect(consumers, isNotEmpty, reason: '${entry['component_id']}');
        expect(entry['consumer_count'], consumers.length);
        expect(consumers.every(pageIds.contains), isTrue);
      }
    });

    test('keeps all 1072 labels live, unique, wrapped and page-owned', () {
      final entries = _listOfMaps(copy['entries']);
      final ids = entries.map((entry) => entry['copy_id'] as String).toSet();
      expect(copy['exact_live_copy_count'], 1072);
      expect(entries, hasLength(1072));
      expect(ids, hasLength(1072));

      final byPage = <String, List<Map<String, dynamic>>>{};
      for (final entry in entries) {
        expect(entry['live'], isTrue, reason: '${entry['copy_id']}');
        expect(entry['flattening'], 'forbidden', reason: '${entry['copy_id']}');
        expect(entry['value'], isNotEmpty, reason: '${entry['copy_id']}');
        expect(
          entry['wrapping'],
          anyOf(
            contains('preserve complete phrase'),
            contains('recompose before clipping'),
          ),
        );
        byPage.putIfAbsent(entry['page_id'] as String, () => []).add(entry);
      }
      for (final page in _listOfMaps(pages['pages'])) {
        final id = page['page_id'] as String;
        final contract = _json(page['contract'] as String);
        final owned = byPage[id] ?? const <Map<String, dynamic>>[];
        expect(owned, hasLength(8), reason: id);
        expect(
          owned.map((entry) => entry['copy_id']),
          orderedEquals((contract['live_copy_ids'] as List<dynamic>)),
          reason: id,
        );
      }
    });

    test('isolates six deterministic fixtures from production persistence', () {
      final entries = _listOfMaps(fixtures['fixtures']);
      expect(entries, hasLength(6));
      expect(entries.map((entry) => entry['id']).toSet(), hasLength(6));
      expect(fixtures['entrypoint'], contains('design/test harness only'));
      for (final entry in entries) {
        expect(
          entry['production_reachable'],
          isFalse,
          reason: '${entry['id']}',
        );
      }

      final productionText =
          (fixtures['forbidden_production_sources'] as List<dynamic>)
              .cast<String>()
              .expand(_textSourcesAt)
              .join('\n');
      for (final name
          in (fixtures['sample_entity_names'] as List<dynamic>)
              .cast<String>()) {
        expect(productionText, isNot(contains(name)), reason: name);
      }
      expect(productionText, isNot(contains(_catalogVersion)));
    });

    test('proves Copy catches geometry, typography and state defects', () {
      final smokes = _listOfMaps(quality['injected_failure_smoke']);
      expect(smokes, hasLength(3));
      expect(
        smokes.map((entry) => entry['injected']),
        orderedEquals(<String>['geometry', 'typography', 'state']),
      );
      for (final smoke in smokes) {
        final output = Directory(smoke['output'] as String);
        expect(output.existsSync(), isTrue);
        expect(
          output
              .listSync()
              .whereType<File>()
              .map((file) => _basename(file.path))
              .toSet(),
          _comparisonFiles,
        );
        final comparison = _json('${output.path}/comparison.json');
        final mismatch = _source('${output.path}/mismatch.md');
        expect(comparison['page_id'], smoke['pageId']);
        expect(comparison['scenario_id'], smoke['scenario_id']);
        expect(comparison['mismatch_count'], greaterThan(0));
        expect(comparison['categories'], contains(smoke['injected']));
        for (final field in <String>['pageId', 'scenario_id', 'injected']) {
          expect(
            mismatch,
            contains(smoke[field]),
            reason: '$field/${smoke['pageId']}',
          );
        }
      }
      expect(
        quality['ci_failure_contract'],
        contains('Exit code 2 names exact page/scenario/categories'),
      );
    });

    test('hash ledger covers all and only the 2055 Stage 05 artifacts', () {
      final rows = _source('$_manifestRoot/stage05-hashes.sha256')
          .trim()
          .split('\n')
          .map((line) {
            final match = RegExp(r'^([a-f0-9]{64})  (.+)$').firstMatch(line);
            expect(match, isNotNull, reason: line);
            return (hash: match!.group(1)!, path: match.group(2)!);
          })
          .toList(growable: false);
      expect(rows, hasLength(2055));
      expect(rows.map((row) => row.path).toSet(), hasLength(2055));
      expect(
        rows.any((row) => row.path.contains('/stage03-selected/')),
        isFalse,
      );
      for (final row in rows) {
        expect(File(row.path).existsSync(), isTrue, reason: row.path);
      }

      final generated = <String>{
        for (final page in _listOfMaps(pages['pages']))
          ..._filesUnder('$_pageRoot/${page['page_id']}'),
        for (final metadata in _map(pages['family_contact_sheets']).values)
          _relativePath(_map(metadata)['file'] as String),
        _relativePath(_map(pages['master_contact_sheet'])['file'] as String),
        ..._filesUnder(_comparisonRoot),
        ..._filesUnder(_rejectedRoot),
        for (final name in _hashedManifestNames) '$_manifestRoot/$name',
      };
      expect(rows.map((row) => row.path).toSet(), generated);
    });

    test(
      'keeps the generator, verifier and protected Stage 03 handoff explicit',
      () {
        expect(
          File('$_pageRoot/stage03-selected/README.md').existsSync(),
          isTrue,
        );
        final generator = _source('tool/generate_stage05_page_library.cjs');
        final verifier = _source('tool/verify_stage05_page_library.cjs');
        expect(generator, contains('--audit-only'));
        expect(generator, contains('STAGE05_GENERATION_PASS'));
        expect(generator, contains('snapshotProtectedPageArtifacts'));
        expect(generator, contains('assertProtectedPageArtifacts'));
        expect(verifier, contains('STAGE05_VERIFY_PASS'));
        expect(verifier, contains('--fail-on-mismatch'));
        expect(verifier, contains('Intentional preview mismatch must exit 2'));
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

Iterable<String> _textSourcesAt(String path) sync* {
  final entity = FileSystemEntity.typeSync(path);
  final files = entity == FileSystemEntityType.directory
      ? Directory(path).listSync(recursive: true).whereType<File>()
      : <File>[File(path)];
  for (final file in files) {
    final name = file.path.toLowerCase();
    if (!const <String>[
      '.dart',
      '.sql',
      '.json',
      '.md',
      '.yaml',
      '.cjs',
    ].any(name.endsWith)) {
      continue;
    }
    yield _source(file.path);
  }
}

Set<String> _filesUnder(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .map((file) => _relativePath(file.path))
    .toSet();

String _relativePath(String path) {
  final project = Directory.current.absolute.path.replaceAll('\\', '/');
  final absolute = File(path).absolute.path.replaceAll('\\', '/');
  expect(absolute.toLowerCase(), startsWith('${project.toLowerCase()}/'));
  return absolute.substring(project.length + 1);
}

String _basename(String path) => path.replaceAll('\\', '/').split('/').last;
