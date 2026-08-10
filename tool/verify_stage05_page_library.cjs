#!/usr/bin/env node

const assert = require('assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const sharp = require('sharp');

const model = require('./stage05/page_catalog_model.cjs');

const manifestNames = [
  'pages.json',
  'copy.json',
  'fixtures.json',
  'coverage-ledger.json',
  'quality-harness.json',
  'stage05-registry.json',
];
const comparisonFiles = [
  'comparison.json',
  'diff.png',
  'mismatch.md',
  'overlay.png',
  'reference-meta.json',
  'reference.png',
  'runtime-meta.json',
  'runtime.png',
];
const protectedStage03Handoff = path.join(model.pageRoot, 'stage03-selected', 'README.md');
const protectedStage03Sha256 = '7f8fbadb64e383201eaa547d16ab7be3d9a28d10e3eabac44aab242584f416ba';

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function absolute(relativePath) {
  const value = path.resolve(model.projectRoot, relativePath);
  assert.ok(
    value === model.projectRoot || value.startsWith(`${model.projectRoot}${path.sep}`),
    `Path escaped project root: ${relativePath}`,
  );
  return value;
}

function normalizedRelative(file) {
  return path.relative(model.projectRoot, file).replaceAll('\\', '/');
}

function listFiles(root) {
  if (!fs.existsSync(root)) return [];
  const files = [];
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const target = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(target);
      else files.push(target);
    }
  };
  visit(root);
  return files;
}

function pngDimensions(file) {
  const bytes = fs.readFileSync(file);
  assert.ok(bytes.length > 24, `${normalizedRelative(file)} is truncated.`);
  assert.equal(bytes.subarray(0, 8).toString('hex'), '89504e470d0a1a0a', `${normalizedRelative(file)} is not a PNG.`);
  assert.equal(bytes.subarray(12, 16).toString('ascii'), 'IHDR', `${normalizedRelative(file)} has no leading IHDR.`);
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

async function rawPixelSha256(file) {
  const { data, info } = await sharp(file)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  return {
    width: info.width,
    height: info.height,
    channels: info.channels,
    sha256: crypto.createHash('sha256').update(data).digest('hex'),
  };
}

function verifySheet(metadata, label) {
  const file = absolute(metadata.file);
  assert.ok(fs.existsSync(file), `Missing ${label}: ${metadata.file}`);
  assert.equal(sha256(file), metadata.sha256, `${label} hash mismatch.`);
  assert.deepEqual(pngDimensions(file), { width: metadata.width, height: metadata.height }, `${label} dimensions mismatch.`);
}

function textSourcesUnder(root) {
  return listFiles(root).filter((file) => ['.dart', '.sql', '.json', '.md', '.yaml', '.cjs'].includes(path.extname(file).toLowerCase()));
}

function assertNoRawEmoji(files) {
  const rawEmoji = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/u;
  for (const file of files) {
    assert.ok(!rawEmoji.test(fs.readFileSync(file, 'utf8')), `Raw keyboard emoji found: ${normalizedRelative(file)}`);
  }
}

function verifyIntentionalFailure(smoke) {
  const comparisonRoot = absolute(smoke.output);
  const output = fs.mkdtempSync(path.join(os.tmpdir(), 'perfect-stage05-diff-'));
  try {
    const result = spawnSync(
      process.execPath,
      [
        path.join(model.projectRoot, 'tool', 'stage05', 'preview_diff.cjs'),
        '--reference', path.join(comparisonRoot, 'reference.png'),
        '--runtime', path.join(comparisonRoot, 'runtime.png'),
        '--reference-meta', path.join(comparisonRoot, 'reference-meta.json'),
        '--runtime-meta', path.join(comparisonRoot, 'runtime-meta.json'),
        '--output', output,
        '--fail-on-mismatch',
      ],
      { cwd: model.projectRoot, encoding: 'utf8', env: process.env },
    );
    const transcript = `${result.stdout || ''}\n${result.stderr || ''}`;
    assert.equal(result.status, 2, `Intentional preview mismatch must exit 2, got ${result.status}: ${transcript}`);
    assert.ok(transcript.includes(smoke.pageId), `Intentional failure omitted page ID: ${transcript}`);
    assert.ok(transcript.includes(smoke.scenario_id), `Intentional failure omitted scenario ID: ${transcript}`);
    assert.ok(transcript.includes(smoke.injected), `Intentional failure omitted category: ${transcript}`);
  } finally {
    fs.rmSync(output, { recursive: true, force: true });
  }
}

async function main() {
  const catalog = model.buildCatalog();
  const manifests = {
    registry: readJson(path.join(model.manifestRoot, 'stage05-registry.json')),
    pages: readJson(path.join(model.manifestRoot, 'pages.json')),
    copy: readJson(path.join(model.manifestRoot, 'copy.json')),
    fixtures: readJson(path.join(model.manifestRoot, 'fixtures.json')),
    coverage: readJson(path.join(model.manifestRoot, 'coverage-ledger.json')),
    quality: readJson(path.join(model.manifestRoot, 'quality-harness.json')),
    stage04: readJson(path.join(model.manifestRoot, 'components.json')),
  };

  assert.equal(manifests.registry.catalog_version, model.catalogVersion);
  assert.equal(manifests.registry.component_catalog_version, model.componentCatalogVersion);
  assert.equal(manifests.registry.direction, 'PS01 Perfect Day Instrument');
  assert.deepEqual(manifests.registry.counts, {
    pages: 134,
    page_families: 11,
    structural_candidates: 402,
    canonical_previews: 1340,
    canonical_render_audits: 1340,
    component_consumers: 181,
    live_copy_entries: 1072,
    fixtures: 6,
    motion_ids: 20,
    comparison_smokes: 3,
  });
  assert.equal(manifests.pages.exact_page_count, 134);
  assert.equal(manifests.pages.exact_candidate_count, 402);
  assert.equal(manifests.pages.exact_canonical_preview_count, 1340);
  assert.equal(manifests.copy.exact_live_copy_count, 1072);
  assert.equal(manifests.coverage.exact_component_count, 181);
  assert.equal(manifests.coverage.unconsumed_component_count, 0);
  assert.equal(manifests.quality.exact_rendered_composition_audits, 1340);

  const gateIds = catalog.gate.rows.map((entry) => entry.id);
  const manifestIds = manifests.pages.pages.map((entry) => entry.page_id);
  assert.deepEqual(manifestIds, gateIds, 'Page manifest must preserve the exact gate order and IDs.');
  assert.equal(new Set(manifestIds).size, 134, 'Page IDs must be unique.');
  const pageIdSet = new Set(manifestIds);
  assert.deepEqual(
    [...new Set(manifests.pages.pages.map((entry) => entry.family))].sort(),
    Object.keys(model.familyLabels).sort(),
    'All eleven page families must be represented.',
  );

  const expectedCandidateFiles = model.candidates.map((entry) => entry.file);
  const expectedCandidateIds = model.candidates.map((entry) => entry.id);
  const expectedPreviewFiles = model.canonicalVariants.map((entry) => entry.file);
  const expectedPreviewDimensions = Object.fromEntries(model.canonicalVariants.map((entry) => [entry.file, { width: entry.width, height: entry.height }]));
  assert.deepEqual(manifests.pages.candidates_per_page, model.candidates);
  assert.deepEqual(manifests.pages.canonical_preview_files_per_page, model.canonicalVariants);

  const componentIds = manifests.stage04.components.map((entry) => entry.component_id);
  assert.equal(componentIds.length, 181);
  const componentIdSet = new Set(componentIds);
  const reverseConsumers = new Map(componentIds.map((id) => [id, []]));
  const contractByPage = new Map();
  const allDecisionFiles = [];
  const allContractFiles = [];

  for (const pageEntry of manifests.pages.pages) {
    const id = pageEntry.page_id;
    const contractFile = absolute(pageEntry.contract);
    const decisionFile = absolute(pageEntry.decision);
    assert.ok(fs.existsSync(contractFile), `Missing page contract: ${id}`);
    assert.ok(fs.existsSync(decisionFile), `Missing page decision: ${id}`);
    assert.equal(sha256(contractFile), pageEntry.contract_sha256, `Contract hash mismatch: ${id}`);
    assert.equal(sha256(decisionFile), pageEntry.decision_sha256, `Decision hash mismatch: ${id}`);
    const contract = readJson(contractFile);
    contractByPage.set(id, contract);
    allContractFiles.push(contractFile);
    allDecisionFiles.push(decisionFile);

    assert.equal(contract.page_id, id);
    assert.equal(contract.preview_version, model.catalogVersion);
    assert.equal(contract.component_catalog_version, model.componentCatalogVersion);
    assert.equal(contract.family, pageEntry.family);
    assert.equal(contract.fixture_id, pageEntry.fixture_id);
    assert.equal(contract.selected_candidate, pageEntry.selected_candidate);
    assert.match(contract.production_boundary, /^Design-only\./, `Missing design-only boundary: ${id}`);
    for (const protectedLayer of ['Flutter', 'native', 'domain', 'database', 'auth', 'sync']) {
      assert.ok(
        contract.production_boundary.includes(protectedLayer),
        `Production boundary omits ${protectedLayer}: ${id}`,
      );
    }
    assert.match(
      contract.production_boundary,
      /may be generated or mutated by Stage 05\.$/,
      `Production mutation boundary is not explicit: ${id}`,
    );
    assert.match(contract.fixture_boundary, /isolated preview fixtures/, `Fixture isolation is not explicit: ${id}`);
    assert.match(
      contract.fixture_boundary,
      /cannot be imported or seeded into production\.$/,
      `Fixture-to-production boundary is not explicit: ${id}`,
    );
    assert.ok(contract.primary_question.length > 12, id);
    assert.ok(contract.primary_action.length > 1, id);
    assert.ok(contract.scan_order.length >= 5, id);
    assert.ok(contract.semantic_order.length >= 6, id);
    assert.ok(contract.responsive_equations.length >= 4, id);
    assert.ok(contract.pane_rules.length >= 3, id);
    assert.ok(contract.motion_ids.length >= 3, id);
    assert.ok(contract.states.length >= 4, id);
    assert.deepEqual(contract.scenario_ids, model.canonicalVariants.map((variant) => `scn-${id.slice(3)}-${variant.file.replace('.png', '')}`));

    assert.equal(pageEntry.component_count, contract.component_ids.length, id);
    assert.deepEqual(pageEntry.component_ids, contract.component_ids, id);
    assert.equal(new Set(contract.component_ids).size, contract.component_ids.length, `Duplicate component consumer in ${id}.`);
    for (const componentId of contract.component_ids) {
      assert.ok(componentIdSet.has(componentId), `Unknown Stage 04 component ${componentId} in ${id}.`);
      reverseConsumers.get(componentId).push(id);
    }

    assert.equal(contract.candidates.length, 3, id);
    assert.deepEqual(contract.candidates.map((candidate) => candidate.id), expectedCandidateIds, id);
    assert.deepEqual(contract.candidates.map((candidate) => candidate.file), expectedCandidateFiles, id);
    assert.equal(new Set(contract.candidates.map((candidate) => candidate.structure)).size, 3, `Candidates are not structurally distinct: ${id}`);
    assert.ok(expectedCandidateIds.includes(contract.selected_candidate), id);
    assert.ok(expectedCandidateIds.includes(contract.strongest_rejected_candidate), id);
    assert.notEqual(contract.selected_candidate, contract.strongest_rejected_candidate, id);
    assert.deepEqual(Object.keys(contract.candidate_previews), expectedCandidateFiles, id);
    assert.deepEqual(Object.keys(contract.candidate_sha256), expectedCandidateFiles, id);
    assert.deepEqual(Object.keys(pageEntry.candidates), expectedCandidateFiles, id);
    assert.deepEqual(Object.keys(pageEntry.candidate_sha256), expectedCandidateFiles, id);
    const candidateHashes = [];
    for (const candidateFile of expectedCandidateFiles) {
      const file = absolute(pageEntry.candidates[candidateFile]);
      assert.deepEqual(pngDimensions(file), { width: 720, height: 480 }, `${id}/${candidateFile}`);
      const hash = sha256(file);
      candidateHashes.push(hash);
      assert.equal(hash, contract.candidate_sha256[candidateFile], `${id}/${candidateFile}`);
      assert.equal(hash, pageEntry.candidate_sha256[candidateFile], `${id}/${candidateFile}`);
    }
    assert.equal(new Set(candidateHashes).size, 3, `Candidate rasters are not distinct: ${id}`);

    assert.deepEqual(Object.keys(contract.canonical_previews), expectedPreviewFiles, id);
    assert.deepEqual(Object.keys(contract.preview_sha256), expectedPreviewFiles, id);
    assert.deepEqual(Object.keys(contract.canonical_audits), expectedPreviewFiles, id);
    assert.deepEqual(Object.keys(pageEntry.previews), expectedPreviewFiles, id);
    assert.deepEqual(Object.keys(pageEntry.preview_sha256), expectedPreviewFiles, id);
    assert.deepEqual(Object.keys(pageEntry.canonical_audits), expectedPreviewFiles, id);
    assert.deepEqual(contract.canonical_preview_metadata, model.canonicalVariants, id);
    for (const previewFile of expectedPreviewFiles) {
      const file = absolute(pageEntry.previews[previewFile]);
      assert.deepEqual(pngDimensions(file), expectedPreviewDimensions[previewFile], `${id}/${previewFile}`);
      const hash = sha256(file);
      assert.equal(hash, contract.preview_sha256[previewFile], `${id}/${previewFile}`);
      assert.equal(hash, pageEntry.preview_sha256[previewFile], `${id}/${previewFile}`);
      const audit = contract.canonical_audits[previewFile];
      assert.deepEqual(audit, pageEntry.canonical_audits[previewFile], `${id}/${previewFile}/audit`);
      assert.equal(audit.page_id, id);
      assert.equal(audit.viewport, `${expectedPreviewDimensions[previewFile].width}x${expectedPreviewDimensions[previewFile].height}`);
      assert.deepEqual(audit.document, expectedPreviewDimensions[previewFile]);
      assert.deepEqual(audit.horizontal_overflow, [], `${id}/${previewFile}/horizontal`);
      assert.deepEqual(audit.clipped_copy, [], `${id}/${previewFile}/copy`);
      assert.deepEqual(audit.failure_ids, [], `${id}/${previewFile}/failures`);
      assert.equal(audit.root_bounds.left, 0, `${id}/${previewFile}/root-left`);
      assert.equal(audit.root_bounds.top, 0, `${id}/${previewFile}/root-top`);
      assert.equal(audit.root_bounds.right, expectedPreviewDimensions[previewFile].width, `${id}/${previewFile}/root-right`);
      assert.equal(audit.root_bounds.bottom, expectedPreviewDimensions[previewFile].height, `${id}/${previewFile}/root-bottom`);
    }

    assert.deepEqual(Object.keys(contract.acceptance), ['modernize', 'integrity', 'anatomy', 'style', 'critics'], id);
    for (const verdict of Object.values(contract.acceptance)) assert.ok(verdict.length > 50, id);
    assert.ok(contract.decomposition.live_layers.includes('all dynamic/critical copy'), id);
    assert.ok(contract.decomposition.forbidden_flattening.includes('owner data'), id);
    assert.ok(contract.decomposition.forbidden_flattening.includes('interactive controls'), id);
    assert.ok(contract.decomposition.copy_protocol.includes('reference/runtime/overlay/diff'), id);

    const decision = fs.readFileSync(decisionFile, 'utf8');
    for (const verdict of ['Modernize', 'Integrity', 'Anatomy', 'Style', 'Critics']) assert.ok(decision.includes(`**${verdict}:**`), `${id}/${verdict}`);
    assert.ok(decision.includes(`\`${contract.selected_candidate}\``), `${id}/selected`);
    assert.ok(decision.includes(contract.candidates.find((candidate) => candidate.id === contract.strongest_rejected_candidate).title), `${id}/rejected`);
    assert.ok(decision.includes('design-only'), `${id}/production-boundary`);
  }

  for (const [family, metadata] of Object.entries(manifests.pages.family_contact_sheets)) {
    assert.equal(metadata.page_count, manifests.pages.pages.filter((entry) => entry.family === family).length, `${family} family sheet count.`);
    verifySheet(metadata, `${family} family contact sheet`);
  }
  assert.deepEqual(Object.keys(manifests.pages.family_contact_sheets).sort(), Object.keys(model.familyLabels).sort());
  for (const candidate of model.candidates) verifySheet(manifests.pages.candidate_contact_sheets[candidate.id], `${candidate.id} contact sheet`);
  verifySheet(manifests.pages.master_contact_sheet, 'master page contact sheet');

  assert.deepEqual(manifests.coverage.component_consumers.map((entry) => entry.component_id), componentIds);
  for (const row of manifests.coverage.component_consumers) {
    assert.equal(row.consumer_count, row.consumers.length, row.component_id);
    assert.ok(row.consumer_count > 0, row.component_id);
    assert.deepEqual(row.consumers, reverseConsumers.get(row.component_id), row.component_id);
    for (const pageId of row.consumers) assert.ok(pageIdSet.has(pageId), `${row.component_id}/${pageId}`);
  }
  for (const family of manifests.coverage.whole_product_families) {
    assert.deepEqual(family.pages, manifests.pages.pages.filter((entry) => entry.family === family.family).map((entry) => entry.page_id));
  }

  const copyIds = new Set();
  const copyByPage = new Map(manifestIds.map((id) => [id, []]));
  for (const entry of manifests.copy.entries) {
    assert.ok(!copyIds.has(entry.copy_id), `Duplicate live copy ID: ${entry.copy_id}`);
    copyIds.add(entry.copy_id);
    assert.ok(pageIdSet.has(entry.page_id), entry.copy_id);
    assert.equal(entry.live, true, entry.copy_id);
    assert.equal(entry.flattening, 'forbidden', entry.copy_id);
    assert.ok(['ltr', 'rtl', 'mixed', 'auto'].includes(entry.direction), entry.copy_id);
    assert.ok(entry.wrapping.length > 20, entry.copy_id);
    copyByPage.get(entry.page_id).push(entry);
  }
  assert.equal(copyIds.size, 1072);
  for (const pageId of manifestIds) {
    const contract = contractByPage.get(pageId);
    const entries = copyByPage.get(pageId);
    assert.equal(entries.length, 8, `${pageId}/live-copy-count`);
    assert.deepEqual(entries.map((entry) => entry.copy_id), contract.live_copy_ids, `${pageId}/live-copy-ids`);
    for (const entry of entries) assert.equal(entry.value, contract.live_copy[entry.role], entry.copy_id);
  }

  assert.equal(manifests.fixtures.fixtures.length, 6);
  assert.equal(new Set(manifests.fixtures.fixtures.map((fixture) => fixture.id)).size, 6);
  assert.ok(manifests.fixtures.entrypoint.includes('design/test harness only'));
  for (const fixture of manifests.fixtures.fixtures) assert.equal(fixture.production_reachable, false, fixture.id);
  for (const relativeSource of manifests.fixtures.forbidden_production_sources) {
    const target = absolute(relativeSource);
    assert.ok(fs.existsSync(target), `Missing production leak-check target: ${relativeSource}`);
    const sourceFiles = fs.statSync(target).isDirectory() ? textSourcesUnder(target) : [target];
    for (const sourceFile of sourceFiles) {
      const source = fs.readFileSync(sourceFile, 'utf8');
      for (const entityName of manifests.fixtures.sample_entity_names) {
        assert.ok(
          !source.includes(entityName),
          `Preview fixture leaked into ${normalizedRelative(sourceFile)}: ${entityName}`,
        );
      }
      assert.ok(
        !source.includes(model.catalogVersion),
        `Stage 05 catalog imported by production persistence: ${normalizedRelative(sourceFile)}`,
      );
    }
  }
  const productionSources = [
    ...textSourcesUnder(path.join(model.projectRoot, 'lib')),
    ...textSourcesUnder(path.join(model.projectRoot, 'android')),
    ...textSourcesUnder(path.join(model.projectRoot, 'windows')),
    ...textSourcesUnder(path.join(model.projectRoot, 'supabase')),
  ];
  for (const file of productionSources) {
    const source = fs.readFileSync(file, 'utf8');
    assert.ok(!source.includes('tool/stage05'), `Production imports Stage 05 tool source: ${normalizedRelative(file)}`);
    assert.ok(!source.includes(model.catalogVersion), `Production imports Stage 05 catalog: ${normalizedRelative(file)}`);
  }

  assert.deepEqual(manifests.quality.required_axes, ['geometry', 'density', 'text', 'theme', 'input', 'motion', 'connectivity', 'auth', 'lifecycle', 'origin']);
  assert.deepEqual(manifests.quality.expected_failure_categories, ['geometry', 'typography', 'state']);
  assert.ok(manifests.quality.rendered_composition_gate.includes('Every canonical page/variant'));
  assert.equal(manifests.quality.injected_failure_smoke.length, 3);
  assert.deepEqual(manifests.quality.injected_failure_smoke.map((entry) => entry.injected), ['geometry', 'typography', 'state']);
  for (const smoke of manifests.quality.injected_failure_smoke) {
    const output = absolute(smoke.output);
    assert.deepEqual(fs.readdirSync(output).sort(), [...comparisonFiles].sort(), `${smoke.pageId}/${smoke.scenario_id}`);
    const comparison = readJson(path.join(output, 'comparison.json'));
    assert.equal(comparison.page_id, smoke.pageId);
    assert.equal(comparison.scenario_id, smoke.scenario_id);
    assert.ok(comparison.mismatch_count > 0);
    assert.ok(comparison.categories.includes(smoke.injected));
    assert.ok(comparison.mismatches.every((entry) => entry.category && entry.field && entry.note));
    const mismatch = fs.readFileSync(path.join(output, 'mismatch.md'), 'utf8');
    assert.ok(mismatch.includes(smoke.pageId));
    assert.ok(mismatch.includes(smoke.scenario_id));
    assert.ok(mismatch.includes(smoke.injected));
    const pageEntry = manifests.pages.pages.find((entry) => entry.page_id === smoke.pageId);
    const referencePreview = absolute(pageEntry.previews[smoke.variantFile]);
    assert.deepEqual(
      await rawPixelSha256(path.join(output, 'reference.png')),
      await rawPixelSha256(referencePreview),
      `${smoke.pageId}/reference-pixels`,
    );
    const dimensions = expectedPreviewDimensions[smoke.variantFile];
    for (const image of ['reference.png', 'runtime.png', 'overlay.png', 'diff.png']) {
      assert.deepEqual(pngDimensions(path.join(output, image)), dimensions, `${smoke.pageId}/${image}`);
    }
  }
  verifyIntentionalFailure(manifests.quality.injected_failure_smoke[0]);

  assert.ok(fs.existsSync(protectedStage03Handoff), 'Protected Stage 03 handoff was deleted.');
  assert.equal(sha256(protectedStage03Handoff), protectedStage03Sha256, 'Protected Stage 03 handoff changed during Stage 05 generation.');
  const hashRows = fs.readFileSync(path.join(model.manifestRoot, 'stage05-hashes.sha256'), 'utf8').trim().split(/\r?\n/).map((line) => {
    const match = line.match(/^([a-f0-9]{64})  (.+)$/);
    assert.ok(match, `Malformed Stage 05 hash row: ${line}`);
    return { hash: match[1], relative: match[2] };
  });
  assert.equal(hashRows.length, 2055);
  assert.equal(new Set(hashRows.map((row) => row.relative)).size, hashRows.length);
  assert.ok(!hashRows.some((row) => row.relative.includes('/stage03-selected/')), 'Stage 05 hash scope swallowed protected Stage 03 files.');
  for (const row of hashRows) {
    const file = absolute(row.relative);
    assert.ok(fs.existsSync(file), `Hash path missing: ${row.relative}`);
    assert.equal(sha256(file), row.hash, `Hash mismatch: ${row.relative}`);
  }
  const generatedFiles = [
    ...manifestIds.flatMap((id) => listFiles(path.join(model.pageRoot, id))),
    ...Object.keys(model.familyLabels).map((family) => path.join(model.pageRoot, `${family}-contact-sheet.png`)),
    path.join(model.pageRoot, 'stage05-page-library-contact-sheet.png'),
    ...listFiles(model.comparisonRoot),
    ...listFiles(model.rejectedRoot),
    ...manifestNames.map((name) => path.join(model.manifestRoot, name)),
  ].map(normalizedRelative).sort();
  assert.deepEqual(hashRows.map((row) => row.relative).sort(), generatedFiles, 'Stage 05 hash manifest must cover all and only generated Stage 05 files.');

  assertNoRawEmoji([
    ...allContractFiles,
    ...allDecisionFiles,
    ...manifestNames.map((name) => path.join(model.manifestRoot, name)),
    ...listFiles(model.comparisonRoot).filter((file) => ['.json', '.md'].includes(path.extname(file))),
  ]);

  console.log('STAGE05_VERIFY_PASS pages=134 candidates=402 previews=1340 audits=1340 components=181 copy=1072 fixtures=6 comparisons=3 hashes=2055');
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
