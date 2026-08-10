#!/usr/bin/env node

const assert = require('assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const model = require('./stage04/design_catalog_model.cjs');

const expectedPreviewFiles = [
  'anatomy.svg',
  'states-light.png',
  'states-dark.png',
  'responsive.png',
  'accessibility.png',
  'motion-board.png',
  'neighbor-plate.png',
];

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

function pngDimensions(file) {
  const bytes = fs.readFileSync(file);
  assert.equal(bytes.subarray(0, 8).toString('hex'), '89504e470d0a1a0a', `${file} is not a PNG`);
  assert.equal(bytes.subarray(12, 16).toString('ascii'), 'IHDR', `${file} has no leading IHDR`);
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

function listFiles(root) {
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

function normalizedRelative(file) {
  return path.relative(model.projectRoot, file).replaceAll('\\', '/');
}

async function validateSvgXml(svgFiles) {
  const chromeCandidates = [
    process.env.PERFECT_CHROME_PATH,
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  ].filter(Boolean);
  const executablePath = chromeCandidates.find((candidate) => fs.existsSync(candidate));
  assert.ok(executablePath, 'Chrome or Edge is required for SVG DOMParser validation.');
  const browser = await chromium.launch({ headless: true, executablePath });
  try {
    const page = await browser.newPage();
    for (let start = 0; start < svgFiles.length; start += 30) {
      const batch = svgFiles.slice(start, start + 30).map((file) => ({
        file: normalizedRelative(file),
        source: fs.readFileSync(file, 'utf8'),
      }));
      const failures = await page.evaluate((items) => items.flatMap((item) => {
        const documentValue = new DOMParser().parseFromString(item.source, 'image/svg+xml');
        const parserError = documentValue.querySelector('parsererror');
        const root = documentValue.documentElement;
        if (parserError || root?.localName !== 'svg') {
          return [{ file: item.file, error: parserError?.textContent || 'root is not svg' }];
        }
        return [];
      }), batch);
      assert.deepEqual(failures, [], `Invalid SVG XML: ${JSON.stringify(failures)}`);
    }
  } finally {
    await browser.close();
  }
}

async function main() {
  const gate = model.parseGate();
  const manifests = {
    registry: readJson(path.join(model.manifestRoot, 'stage04-registry.json')),
    foundations: readJson(path.join(model.manifestRoot, 'foundations.json')),
    components: readJson(path.join(model.manifestRoot, 'components.json')),
    assets: readJson(path.join(model.manifestRoot, 'assets.json')),
    motion: readJson(path.join(model.manifestRoot, 'motion.json')),
  };

  assert.equal(manifests.registry.catalog_version, model.catalogVersion);
  assert.deepEqual(manifests.registry.counts, {
    foundations: 9,
    components: 181,
    families: 27,
    component_previews: 1267,
    category_icons: 48,
    motions: 20,
  });
  assert.equal(manifests.foundations.exact_foundation_count, 9);
  assert.equal(manifests.components.exact_component_count, 181);
  assert.equal(manifests.components.exact_family_count, 27);
  assert.equal(manifests.components.exact_preview_count, 1267);
  assert.equal(manifests.assets.exact_asset_count, 53);
  assert.equal(manifests.motion.count, 20);

  const gateIds = gate.componentRows.map((component) => component.id);
  const manifestIds = manifests.components.components.map((component) => component.component_id);
  assert.deepEqual(manifestIds, gateIds, 'Component manifest must preserve the exact gate registry order and IDs.');
  assert.equal(new Set(manifestIds).size, 181, 'Component IDs must be unique.');

  const svgFiles = [];
  for (const entry of manifests.components.components) {
    const contractFile = absolute(entry.contract);
    assert.ok(fs.existsSync(contractFile), `Missing contract: ${entry.contract}`);
    assert.equal(sha256(contractFile), entry.contract_sha256, `Contract hash mismatch: ${entry.component_id}`);
    const contract = readJson(contractFile);
    assert.equal(contract.component_id, entry.component_id);
    assert.equal(contract.catalog_version, model.catalogVersion);
    assert.equal(contract.semantic_owner, contract.canonical_semantic_owner);
    assert.equal(contract.anatomy.stable_outer_geometry, true);
    assert.ok(contract.interaction.touch.some((value) => value.includes('48dp')));
    assert.ok(contract.interaction.keyboard.length >= 3);
    assert.ok(contract.interaction.screen_reader.length >= 2);
    assert.ok(contract.responsive.breakpoint_state_continuity.includes('focus'));
    assert.ok(contract.responsive.breakpoint_state_continuity.includes('scroll'));
    assert.ok(contract.rtl_mixed_copy.includes('200%'));
    assert.ok(contract.reduced_motion.length > 30);
    assert.ok(contract.performance_budget.length > 30);
    assert.ok(contract.consumers.length > 0);
    assert.deepEqual(contract.preview_files, expectedPreviewFiles);
    assert.deepEqual(Object.keys(contract.preview_sha256), expectedPreviewFiles);
    assert.ok(contract.fixture_boundary.includes('cannot be imported or seeded'));
    assert.ok(contract.decomposition.forbidden_flattening.includes('interactive control'));

    for (const preview of expectedPreviewFiles) {
      const previewFile = absolute(entry.previews[preview]);
      assert.ok(fs.existsSync(previewFile), `Missing ${entry.component_id}/${preview}`);
      assert.equal(sha256(previewFile), contract.preview_sha256[preview], `Contract preview hash mismatch: ${entry.component_id}/${preview}`);
      assert.equal(sha256(previewFile), entry.preview_sha256[preview], `Manifest preview hash mismatch: ${entry.component_id}/${preview}`);
      if (preview.endsWith('.png')) {
        assert.deepEqual(pngDimensions(previewFile), { width: 1200, height: 800 }, `Wrong dimensions: ${entry.component_id}/${preview}`);
      } else {
        svgFiles.push(previewFile);
      }
    }
  }

  assert.equal(manifests.foundations.category_icon_archive.count, 48);
  assert.equal(manifests.foundations.category_icon_archive.icons.length, 48);
  for (const icon of manifests.foundations.category_icon_archive.icons) {
    const iconFile = absolute(icon.file);
    const source = fs.readFileSync(iconFile, 'utf8');
    assert.equal(sha256(iconFile), icon.sha256, `Category icon hash mismatch: ${icon.id}`);
    assert.ok(source.includes('viewBox="0 0 512 512"'));
    assert.ok(source.includes('role="img"'));
    assert.ok(source.includes('<title'));
    assert.ok(
      !/<rect[^>]+(?:width="512"|width="100%")/i.test(source),
      `Category icon must keep a transparent backing field: ${icon.id}`,
    );
    svgFiles.push(iconFile);
  }

  for (const foundation of manifests.foundations.foundations) {
    const contract = readJson(absolute(foundation.contract));
    assert.equal(contract.foundation_id, foundation.foundation_id);
    assert.deepEqual(contract.required_themes, ['light', 'dark', 'high-contrast']);
    assert.ok(contract.required_layouts.length >= 8);
    for (const [preview, expectedHash] of Object.entries(foundation.preview_sha256)) {
      const previewFile = absolute(foundation.previews[preview]);
      assert.equal(sha256(previewFile), expectedHash, `Foundation preview hash mismatch: ${foundation.foundation_id}/${preview}`);
      if (preview.endsWith('.png')) assert.deepEqual(pngDimensions(previewFile), { width: 1200, height: 800 });
      else svgFiles.push(previewFile);
    }
  }

  const motionIds = manifests.motion.motions.map((motion) => motion.id);
  assert.equal(new Set(motionIds).size, 20);
  for (const motion of manifests.motion.motions) {
    for (const field of ['trigger', 'affected_layers', 'frames', 'interruption', 'reverse', 'focus_semantics_timing', 'background_resume', 'reduced', 'frame_resource_budget']) {
      assert.ok(motion[field], `Motion ${motion.id} misses ${field}`);
    }
  }

  const hashManifestFile = path.join(model.manifestRoot, 'stage04-hashes.sha256');
  const hashRows = fs.readFileSync(hashManifestFile, 'utf8').trim().split(/\r?\n/).map((line) => {
    const match = line.match(/^([a-f0-9]{64})  (.+)$/);
    assert.ok(match, `Malformed SHA-256 row: ${line}`);
    return { hash: match[1], relative: match[2] };
  });
  assert.equal(hashRows.length, 1576);
  assert.equal(new Set(hashRows.map((row) => row.relative)).size, hashRows.length);
  for (const row of hashRows) {
    const file = absolute(row.relative);
    assert.ok(fs.existsSync(file), `Hash manifest path missing: ${row.relative}`);
    assert.equal(sha256(file), row.hash, `Hash manifest mismatch: ${row.relative}`);
  }

  const generatedFiles = [
    ...listFiles(model.foundationRoot),
    ...listFiles(model.componentRoot),
    ...['foundations.json', 'components.json', 'assets.json', 'motion.json', 'stage04-registry.json'].map((name) => path.join(model.manifestRoot, name)),
  ].map(normalizedRelative).sort();
  assert.deepEqual(hashRows.map((row) => row.relative).sort(), generatedFiles, 'Hash manifest must cover every generated Stage 04 file and no stale file.');

  const rawEmoji = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/u;
  for (const file of [
    path.join(model.manifestRoot, 'components.json'),
    path.join(model.manifestRoot, 'foundations.json'),
    path.join(model.manifestRoot, 'assets.json'),
    path.join(model.manifestRoot, 'motion.json'),
    ...svgFiles,
  ]) {
    assert.ok(!rawEmoji.test(fs.readFileSync(file, 'utf8')), `Raw keyboard emoji found: ${normalizedRelative(file)}`);
  }

  await validateSvgXml([...new Set(svgFiles)]);
  console.log(`STAGE04_VERIFY_PASS foundations=9 components=181 previews=1267 hashes=${hashRows.length} svg=${new Set(svgFiles).size} icons=48 motions=20`);
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
