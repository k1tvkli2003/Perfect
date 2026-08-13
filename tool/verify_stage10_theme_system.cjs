#!/usr/bin/env node

const assert = require('assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const model = require('./stage10/theme_system_model.cjs');

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function sha256Buffer(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function sha256File(file) {
  return sha256Buffer(fs.readFileSync(file));
}

function canonicalSourceHash(file) {
  const bytes = fs.readFileSync(file);
  const textExtensions = new Set(['.svg', '.json', '.md', '.yaml', '.yml', '.txt']);
  if (!textExtensions.has(path.extname(file).toLowerCase())) return sha256Buffer(bytes);
  return sha256Buffer(Buffer.from(bytes.toString('utf8').replace(/\r\n/g, '\n'), 'utf8'));
}

function absolute(relativePath) {
  const resolved = path.resolve(model.projectRoot, relativePath);
  assert.ok(
    resolved === model.projectRoot || resolved.startsWith(`${model.projectRoot}${path.sep}`),
    `Path escaped project root: ${relativePath}`,
  );
  return resolved;
}

function relative(file) {
  return path.relative(model.projectRoot, file).replaceAll('\\', '/');
}

function pngDimensions(file) {
  const bytes = fs.readFileSync(file);
  assert.equal(bytes.subarray(0, 8).toString('hex'), '89504e470d0a1a0a', `${relative(file)} is not a PNG`);
  assert.equal(bytes.subarray(12, 16).toString('ascii'), 'IHDR', `${relative(file)} lacks IHDR`);
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

function parseViewport(value) {
  const match = /^(\d+)x(\d+)$/.exec(value);
  assert.ok(match, `Malformed viewport: ${value}`);
  return { width: Number(match[1]), height: Number(match[2]) };
}

function verifyFrozenFile(entry, label) {
  const file = absolute(entry.file);
  assert.ok(fs.existsSync(file), `Missing frozen ${label}: ${entry.file}`);
  const raw = sha256File(file);
  const canonical = canonicalSourceHash(file);
  assert.ok(
    raw === entry.sha256 || canonical === entry.sha256,
    `${label} drift: expected ${entry.sha256}; raw ${raw}; canonical ${canonical}`,
  );
}

async function verifySvgDocuments(svgFiles) {
  const candidates = [
    process.env.PERFECT_DESIGN_BROWSER,
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  ].filter(Boolean);
  const executablePath = candidates.find((candidate) => fs.existsSync(candidate));
  assert.ok(executablePath, 'Edge or Chrome is required for Stage 10 SVG validation.');
  const browser = await chromium.launch({ headless: true, executablePath });
  try {
    const page = await browser.newPage();
    const entries = svgFiles.map((file) => ({ file: relative(file), source: fs.readFileSync(file, 'utf8') }));
    const failures = await page.evaluate((items) => items.flatMap((item) => {
      const parsed = new DOMParser().parseFromString(item.source, 'image/svg+xml');
      const parserError = parsed.querySelector('parsererror');
      const root = parsed.documentElement;
      if (parserError || root?.localName !== 'svg') {
        return [{ file: item.file, error: parserError?.textContent || 'root is not svg' }];
      }
      return [];
    }), entries);
    assert.deepEqual(failures, [], `Invalid Stage 10 SVG XML: ${JSON.stringify(failures)}`);
  } finally {
    await browser.close();
  }
}

async function main() {
  const registryFile = path.join(model.outputRoot, 'stage10-theme-registry.json');
  const registry = readJson(registryFile);
  const tokens = readJson(absolute(registry.artifacts.theme_tokens));
  const report = readJson(absolute(registry.artifacts.contrast_report));
  const components = readJson(absolute(registry.artifacts.component_freeze));
  const pages = readJson(absolute(registry.artifacts.page_freeze));

  assert.equal(registry.catalog_version, 'ps01-theme-2.0.0');
  assert.equal(registry.direction, 'Graphite Bloom / Perfect Day Instrument');
  assert.equal(registry.selected_candidate, 'candidate-graphite-bloom');
  assert.deepEqual(registry.counts, {
    foundations: 3,
    themes: 4,
    candidates: 3,
    components: 181,
    component_theme_variants: 543,
    pages: 134,
    page_theme_layout_variants: 938,
    measured_contrast_pairs: 76,
    boards: 6,
  });

  assert.equal(tokens.catalog_version, registry.catalog_version);
  assert.equal(tokens.direction, registry.direction);
  assert.deepEqual(Object.keys(tokens.themes), ['light', 'dark', 'highContrastLight', 'highContrastDark']);
  assert.match(tokens.raw_color_policy, /Live reusable UI consumes semantic roles/);

  assert.equal(report.standard_text_threshold, 4.5);
  assert.equal(report.high_contrast_text_threshold, 7);
  assert.equal(report.non_text_and_focus_threshold, 3);
  assert.equal(report.themes.length, 4);
  assert.equal(report.themes.reduce((sum, theme) => sum + theme.exact_pair_count, 0), 76);
  for (const theme of report.themes) {
    assert.equal(theme.exact_pair_count, 19, `${theme.theme_id} pair count`);
    assert.deepEqual(theme.failures, [], `${theme.theme_id} contrast failures`);
    for (const pair of theme.pairs) {
      assert.equal(pair.pass, true, `${theme.theme_id} ${pair.foreground_role}/${pair.background_role}`);
      assert.ok(pair.ratio >= pair.threshold, `${theme.theme_id} ${pair.purpose} ratio`);
      if (theme.contrast === 'high' && pair.threshold === 7) assert.ok(pair.ratio >= 7);
      if (pair.purpose.includes('focus') || pair.purpose.includes('boundary')) assert.ok(pair.ratio >= 3);
    }
  }

  assert.equal(components.exact_component_count, 181);
  assert.equal(components.components.length, 181);
  assert.equal(new Set(components.components.map((entry) => entry.component_id)).size, 181);
  for (const component of components.components) {
    assert.deepEqual(Object.keys(component.theme_variants), ['light', 'dark', 'high_contrast']);
    for (const [theme, entry] of Object.entries(component.theme_variants)) {
      verifyFrozenFile(entry, `${component.component_id}/${theme}`);
    }
    assert.match(component.token_contract, /unregistered raw color/);
  }

  assert.equal(pages.exact_page_count, 134);
  assert.equal(pages.pages.length, 134);
  assert.equal(new Set(pages.pages.map((entry) => entry.page_id)).size, 134);
  for (const page of pages.pages) {
    assert.deepEqual(Object.keys(page.theme_variants), [
      'light_phone',
      'dark_phone',
      'high_contrast_stress',
      'tablet_portrait',
      'tablet_landscape',
      'windows_compact',
      'windows_wide',
    ]);
    for (const [variant, entry] of Object.entries(page.theme_variants)) {
      verifyFrozenFile(entry, `${page.page_id}/${variant}`);
    }
    assert.match(page.state_contract, /route, selection, scroll, draft, focus, timers/);
  }

  assert.deepEqual(registry.foundations.map((entry) => entry.foundation_id), [
    'fnd-color-roles',
    'fnd-material',
    'fnd-focus-a11y',
  ]);
  for (const foundation of registry.foundations) {
    assert.equal(foundation.source_catalog_version, 'ps01-ds-1.0.0');
    assert.equal(foundation.stage10_variant_ids.length, 4);
    for (const [name, entry] of Object.entries(foundation.source_previews)) {
      verifyFrozenFile(entry, `${foundation.foundation_id}/${name}`);
    }
  }

  const svgFiles = [];
  const expectedBoardIds = [
    'candidate-comparison',
    'theme-foundations',
    'phone-empty-dense-matrix',
    'adaptive-tablet-windows-matrix',
    'component-state-matrix',
    'native-surface-matrix',
  ];
  assert.deepEqual(registry.artifacts.boards.map((entry) => entry.id), expectedBoardIds);
  for (const board of registry.artifacts.boards) {
    const viewport = parseViewport(board.viewport);
    verifyFrozenFile(board.svg, `${board.id}/svg`);
    verifyFrozenFile(board.png, `${board.id}/png`);
    const svgFile = absolute(board.svg.file);
    const source = fs.readFileSync(svgFile, 'utf8');
    assert.ok(!source.includes('This page contains the following errors:'), `${board.id} captured an error document`);
    assert.match(source, new RegExp(`<svg[^>]+width="${viewport.width}"[^>]+height="${viewport.height}"`));
    assert.deepEqual(pngDimensions(absolute(board.png.file)), viewport, `${board.id} PNG dimensions`);
    svgFiles.push(svgFile);
  }

  for (const field of ['decision', 'source_map', 'mismatch_ledger']) {
    const file = absolute(registry.artifacts[field]);
    assert.ok(fs.existsSync(file), `Missing ${field}`);
    assert.ok(fs.statSync(file).size > 500, `${field} is too small to be useful`);
  }
  assert.match(fs.readFileSync(absolute(registry.artifacts.decision), 'utf8'), /autonomously accepted for implementation/);
  assert.match(fs.readFileSync(absolute(registry.artifacts.source_map), 'utf8'), /Theme changes preserve route, selection, scroll, focus, draft, timers/);
  assert.match(fs.readFileSync(absolute(registry.artifacts.mismatch_ledger), 'utf8'), /No preview image is runtime proof/);

  const hashRows = fs.readFileSync(path.join(model.outputRoot, 'stage10-hashes.sha256'), 'utf8').trim().split(/\r?\n/).map((line) => {
    const match = line.match(/^([a-f0-9]{64})  (.+)$/);
    assert.ok(match, `Malformed Stage 10 hash row: ${line}`);
    return { hash: match[1], file: match[2] };
  });
  const outputFiles = fs.readdirSync(model.outputRoot)
    .map((name) => path.join(model.outputRoot, name))
    .filter((file) => fs.statSync(file).isFile() && path.basename(file) !== 'stage10-hashes.sha256')
    .map(relative)
    .sort();
  assert.deepEqual(hashRows.map((row) => row.file).sort(), outputFiles, 'Stage 10 hash manifest coverage');
  for (const row of hashRows) assert.equal(sha256File(absolute(row.file)), row.hash, `Stage 10 hash mismatch: ${row.file}`);

  await verifySvgDocuments(svgFiles);
  console.log(`STAGE10_THEME_VERIFY_PASS foundations=3 themes=4 candidates=3 components=181 componentVariants=543 pages=134 pageVariants=938 contrastPairs=76 boards=6 hashes=${hashRows.length}`);
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
