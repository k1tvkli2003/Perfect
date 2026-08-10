#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { chromium } = require('playwright');

const model = require('./stage05/page_catalog_model.cjs');
const visuals = require('./stage05/page_catalog_visuals.cjs');
const diff = require('./stage05/preview_diff.cjs');

const chromeCandidates = [
  process.env.PERFECT_CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
].filter(Boolean);

const stage05ManifestNames = [
  'pages.json',
  'copy.json',
  'fixtures.json',
  'coverage-ledger.json',
  'quality-harness.json',
  'stage05-registry.json',
  'stage05-hashes.sha256',
];

function ensureDir(directory) {
  fs.mkdirSync(directory, { recursive: true });
}

function assertGeneratedTarget(target) {
  const root = path.resolve(model.documentRoot);
  const resolved = path.resolve(target);
  if (resolved === root || !resolved.startsWith(`${root}${path.sep}`)) {
    throw new Error(`Refusing unsafe generated target: ${resolved}`);
  }
  return resolved;
}

function resetGeneratedDirectory(directory) {
  const resolved = assertGeneratedTarget(directory);
  if (fs.existsSync(resolved)) fs.rmSync(resolved, { recursive: true, force: true });
  ensureDir(resolved);
}

function assertPageOutputTarget(target) {
  const root = path.resolve(model.pageRoot);
  const resolved = path.resolve(target);
  if (resolved === root || !resolved.startsWith(`${root}${path.sep}`)) {
    throw new Error(`Refusing unsafe Stage 05 page target: ${resolved}`);
  }
  return resolved;
}

function snapshotProtectedPageArtifacts() {
  const protectedRoot = path.join(model.pageRoot, 'stage03-selected');
  const handoff = path.join(protectedRoot, 'README.md');
  if (!fs.existsSync(handoff)) {
    throw new Error(`Stage 03 handoff is missing before Stage 05 generation: ${handoff}`);
  }
  return new Map(listFiles(protectedRoot).map((file) => [relative(file), sha256File(file)]));
}

function resetStage05PageOutputs(pageIds) {
  ensureDir(model.pageRoot);
  for (const pageId of pageIds) {
    if (!/^pg-[a-z0-9-]+$/.test(pageId)) throw new Error(`Unsafe Stage 05 page id: ${pageId}`);
    const target = assertPageOutputTarget(path.join(model.pageRoot, pageId));
    if (fs.existsSync(target)) fs.rmSync(target, { recursive: true, force: true });
  }
  const sheets = [
    ...Object.keys(model.familyLabels).map((family) => `${family}-contact-sheet.png`),
    'stage05-page-library-contact-sheet.png',
  ];
  for (const name of sheets) {
    const target = assertPageOutputTarget(path.join(model.pageRoot, name));
    if (fs.existsSync(target)) fs.rmSync(target, { force: true });
  }
}

function assertProtectedPageArtifacts(snapshot) {
  const protectedRoot = path.join(model.pageRoot, 'stage03-selected');
  const after = new Map(listFiles(protectedRoot).map((file) => [relative(file), sha256File(file)]));
  if (snapshot.size !== after.size) {
    throw new Error(`Stage 03 preservation failure: protected artifact count changed ${snapshot.size} -> ${after.size}.`);
  }
  for (const [file, hash] of snapshot) {
    if (after.get(file) !== hash) throw new Error(`Stage 03 preservation failure: ${file} changed during Stage 05 generation.`);
  }
}

function sha256File(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function sha256Text(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest('hex');
}

function relative(file) {
  return path.relative(model.projectRoot, file).replaceAll('\\', '/');
}

function writeJson(file, value) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

function resolveChrome() {
  const found = chromeCandidates.find((candidate) => fs.existsSync(candidate));
  if (!found) throw new Error('No local Chrome/Edge executable is available for deterministic Stage 05 rendering.');
  return found;
}

function fileDataUrl(file, mime) {
  return `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
}

function listFiles(root) {
  const files = [];
  if (!fs.existsSync(root)) return files;
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(absolute);
      else files.push(absolute);
    }
  };
  visit(root);
  return files;
}

function decisionMarkdown(page) {
  const chosen = page.candidates.find((candidate) => candidate.id === page.selected_candidate);
  const rejected = page.candidates.find((candidate) => candidate.id === page.strongest_rejected_candidate);
  return `# ${page.page_id} — autonomous acceptance\n\n- Preview: \`${page.page_id}@${page.preview_version}\`\n- Family: ${page.family_label}\n- Problem: ${page.primary_question}\n- Primary action: **${page.primary_action}**\n- Fixture: \`${page.fixture_id}\` (preview-only)\n\n## Candidates compared\n\n${page.candidates.map((candidate) => `- **${candidate.title}** (\`${candidate.id}\`): ${candidate.structure}`).join('\n')}\n\n## Verdicts\n\n- **Modernize:** ${page.acceptance.modernize}\n- **Integrity:** ${page.acceptance.integrity}\n- **Anatomy:** ${page.acceptance.anatomy}\n- **Style:** ${page.acceptance.style}\n- **Critics:** ${page.acceptance.critics}\n\n## Selected\n\n**${chosen.title}** wins because it answers the route's primary question before exposing secondary evidence, preserves direct action continuity, and recomposes by platform without stretching a phone canvas. The exact selection is \`${chosen.id}\`.\n\n## Strongest rejected alternative\n\n**${rejected.title}** lost: ${page.rejection_reason}\n\n## Responsive, accessibility and system-state proof\n\nThe canonical set includes phone compact, short phone landscape, tablet portrait/landscape, Windows compact/wide, dark, 200% mixed high-contrast stress, four-state system comparison and first/mid/end/reverse/reduced-motion evidence. The component manifest retains touch, mouse, keyboard and screen-reader contracts.\n\n## Residual risk and owner\n\n${page.residual_risks.map((risk) => `- ${risk}`).join('\n')}\n\nAccepted under owner-delegated autonomous design authority: **yes**. This acceptance is design-only and cannot be used as runtime fidelity proof.\n`;
}

function copyRegistry(pages) {
  const entries = [];
  for (const page of pages) {
    for (const [key, value] of Object.entries(page.live_copy)) {
      entries.push({
        copy_id: `copy.${page.page_id}.${key}`,
        page_id: page.page_id,
        role: key,
        value,
        live: true,
        flattening: 'forbidden',
        direction: key === 'persian_sample' ? 'rtl' : key === 'date' ? 'mixed' : 'auto',
        wrapping: ['title', 'subtitle', 'primary_action', 'secondary_action', 'persian_sample'].includes(key)
          ? 'intrinsic wrap; preserve complete phrase and action meaning'
          : 'single semantic unit; recompose before clipping',
      });
    }
  }
  return {
    catalog_version: model.catalogVersion,
    generated_at: model.generatedAt,
    exact_live_copy_count: entries.length,
    policy: 'Every dynamic, critical, editable and owner-authored string remains live. Preview copy is exact source text, not generated pixels.',
    entries,
  };
}

function fixturesRegistry() {
  return {
    catalog_version: model.catalogVersion,
    generated_at: model.generatedAt,
    entrypoint: 'design/test harness only; no production import, seed, merge or signed-build route',
    fixtures: [
      { id: 'fx-owner-empty', purpose: 'Valid private owner/session with zero planner entities or history.', entities: 0, production_reachable: false },
      { id: 'fx-owner-sparse', purpose: 'One unscheduled task and one simple habit.', entities: 2, production_reachable: false },
      { id: 'fx-owner-normal', purpose: 'Realistic mixed day/week with scheduling and tracking methods.', entities: 14, production_reachable: false },
      { id: 'fx-owner-dense', purpose: 'Long bilingual titles, overlapping recurrence, all progress states, relations, notes, goals, conflicts and long history.', entities: 64, production_reachable: false },
      { id: 'fx-system-adversarial', purpose: 'Local first load, offline, retry, auth expiry, conflict, hard error, AI proposal and widget-origin mutation.', entities: 16, production_reachable: false },
      { id: 'fx-time-boundaries', purpose: '00:00, 05:59, noon, 18:00, 23:59, timezone and Gregorian/Jalali boundary projections.', entities: 12, production_reachable: false },
    ],
    forbidden_production_sources: ['lib/planner/data/planner_database.dart', 'lib/planner/data/planner_local_store.dart', 'supabase/migrations'],
    sample_entity_names: ['Review project brief', 'Study clinical reasoning', 'Read medicine', 'No late caffeine'],
  };
}

function pageLandmarks(page) {
  return {
    header: { x: 0, y: 0, width: 1, height: page.family === 'entry' || /^pg-widget/.test(page.page_id) ? 0 : 0.12 },
    primary_content: { x: 0.06, y: page.family === 'entry' || /^pg-widget/.test(page.page_id) ? 0.08 : 0.15, width: 0.88, height: 0.66 },
    primary_action: { x: 0.62, y: 0.79, width: 0.28, height: 0.075 },
  };
}

function comparisonMetadata(page, variant) {
  return {
    preview_id: `${page.page_id}@${page.preview_version}#${page.preview_sha256[variant.file]}`,
    page_id: page.page_id,
    scenario_id: `scn-${page.page_id.slice(3)}-${variant.file.replace('.png', '')}`,
    viewport: variant.viewport,
    theme: variant.theme,
    locale: variant.locale,
    direction: variant.direction,
    text_scale: variant.textScale,
    landmarks: pageLandmarks(page),
    typography: {
      page_title: { family: 'Perfect Jakarta', weight: 650, size: 24, line_height: 1.12 },
      body: { family: 'Perfect Jakarta', weight: 480, size: 15, line_height: 1.45 },
    },
    system_state: { sync: /offline/.test(page.page_id) ? 'offline' : /retry|error/.test(page.page_id) ? 'error' : 'synced', local_ready: true },
  };
}

async function mutateReference(reference, output, category) {
  const metadata = await sharp(reference).metadata();
  const width = metadata.width;
  const height = metadata.height;
  if (category === 'geometry') {
    const inset = Math.max(10, Math.round(width * 0.025));
    const top = Math.max(8, Math.round(height * 0.018));
    const shrunk = await sharp(reference).resize(width - inset * 2, height - top * 2, { fit: 'fill' }).png().toBuffer();
    await sharp({ create: { width, height, channels: 4, background: '#fffcf7' } })
      .composite([{ input: shrunk, left: inset, top }])
      .png({ compressionLevel: 9, adaptiveFiltering: true })
      .toFile(output);
    return;
  }
  const overlay = category === 'typography'
    ? `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect x="${Math.round(width * 0.08)}" y="${Math.round(height * 0.13)}" width="${Math.round(width * 0.58)}" height="${Math.round(height * 0.095)}" rx="12" fill="#fff5ea" stroke="#ffa34d" stroke-width="3"/><text x="${Math.round(width * 0.1)}" y="${Math.round(height * 0.19)}" font-family="Arial" font-size="${Math.max(24, Math.round(width * 0.045))}" font-weight="400" fill="#1d2030">Wrong live title scale</text></svg>`
    : `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect x="${Math.round(width * 0.68)}" y="${Math.round(height * 0.025)}" width="${Math.round(width * 0.27)}" height="${Math.round(height * 0.075)}" rx="20" fill="#ffe3e5" stroke="#c44b56" stroke-width="3"/><circle cx="${Math.round(width * 0.73)}" cy="${Math.round(height * 0.062)}" r="8" fill="#c44b56"/><text x="${Math.round(width * 0.76)}" y="${Math.round(height * 0.07)}" font-family="Arial" font-size="${Math.max(13, Math.round(width * 0.02))}" font-weight="700" fill="#c44b56">Sync error</text></svg>`;
  await sharp(reference)
    .composite([{ input: Buffer.from(overlay), left: 0, top: 0 }])
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(output);
}

async function createHarnessSmoke(pages) {
  const cases = [
    { platform: 'phone', pageId: 'pg-today-normal', variantFile: 'phone-compact.png', injected: 'geometry' },
    { platform: 'tablet', pageId: 'pg-task-schedule', variantFile: 'tablet-portrait.png', injected: 'typography' },
    { platform: 'windows', pageId: 'pg-tasks-dense', variantFile: 'windows-wide.png', injected: 'state' },
  ];
  const tempRoot = path.join(model.comparisonRoot, '.generated-inputs');
  ensureDir(tempRoot);
  const results = [];
  for (const item of cases) {
    const page = pages.find((entry) => entry.page_id === item.pageId);
    const variant = model.canonicalVariants.find((entry) => entry.file === item.variantFile);
    const reference = path.join(model.pageRoot, page.page_id, 'canonical', item.variantFile);
    const runtime = path.join(tempRoot, `${item.platform}-runtime.png`);
    await mutateReference(reference, runtime, item.injected);
    const referenceMeta = comparisonMetadata(page, variant);
    const runtimeMeta = JSON.parse(JSON.stringify(referenceMeta));
    if (item.injected === 'geometry') {
      runtimeMeta.landmarks.primary_content.x += 0.035;
      runtimeMeta.landmarks.primary_content.width -= 0.07;
    } else if (item.injected === 'typography') {
      runtimeMeta.typography.page_title = { family: 'Arial', weight: 400, size: 31, line_height: 1.3 };
    } else {
      runtimeMeta.system_state.sync = 'error';
    }
    const metaRoot = path.join(tempRoot, item.platform);
    ensureDir(metaRoot);
    const referenceMetaFile = path.join(metaRoot, 'reference-meta.json');
    const runtimeMetaFile = path.join(metaRoot, 'runtime-meta.json');
    writeJson(referenceMetaFile, referenceMeta);
    writeJson(runtimeMetaFile, runtimeMeta);
    const output = path.join(model.comparisonRoot, page.page_id, referenceMeta.scenario_id);
    const result = await diff.comparePreview({ reference, runtime, referenceMeta: referenceMetaFile, runtimeMeta: runtimeMetaFile, output });
    fs.copyFileSync(referenceMetaFile, path.join(output, 'reference-meta.json'));
    fs.copyFileSync(runtimeMetaFile, path.join(output, 'runtime-meta.json'));
    if (!result.categories.includes(item.injected)) throw new Error(`Harness failed to detect injected ${item.injected} defect for ${item.platform}.`);
    results.push({ ...item, output: relative(output), preview_id: result.preview_id, scenario_id: result.scenario_id, mismatch_count: result.mismatch_count, categories: result.categories, changed_ratio: result.pixels.changed_ratio });
  }
  const resolved = assertGeneratedTarget(tempRoot);
  fs.rmSync(resolved, { recursive: true, force: true });
  return results;
}

function tileFrame(width, height, title, subtitle) {
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="${width}" height="${height}" rx="16" fill="#fff" stroke="#e8e0d7"/><text x="12" y="20" font-family="Segoe UI" font-size="10" font-weight="700" fill="#1d2030">${visuals.escapeHtml(title)}</text><text x="${width - 12}" y="20" text-anchor="end" font-family="Consolas" font-size="7" fill="#686579">${visuals.escapeHtml(subtitle)}</text></svg>`);
}

async function makeContactSheet(items, output, options = {}) {
  const columns = options.columns || 5;
  const tileWidth = options.tileWidth || 240;
  const tileHeight = options.tileHeight || 260;
  const gutter = options.gutter || 12;
  const padding = options.padding || 18;
  const imageTop = 28;
  const inset = 7;
  const rows = Math.ceil(items.length / columns);
  const width = padding * 2 + columns * tileWidth + Math.max(0, columns - 1) * gutter;
  const height = padding * 2 + rows * tileHeight + Math.max(0, rows - 1) * gutter;
  const composite = [];
  for (let index = 0; index < items.length; index += 1) {
    const item = items[index];
    const column = index % columns;
    const row = Math.floor(index / columns);
    const left = padding + column * (tileWidth + gutter);
    const top = padding + row * (tileHeight + gutter);
    composite.push({ input: tileFrame(tileWidth, tileHeight, item.id, item.subtitle || ''), left, top });
    const image = await sharp(item.file)
      .resize(tileWidth - inset * 2, tileHeight - imageTop - inset, { fit: 'contain', background: '#fffcf7' })
      .png({ palette: true, colours: 192 })
      .toBuffer();
    composite.push({ input: image, left: left + inset, top: top + imageTop });
  }
  ensureDir(path.dirname(output));
  await sharp({ create: { width, height, channels: 4, background: '#f4efe8' } })
    .composite(composite)
    .png({ compressionLevel: 9, adaptiveFiltering: true, palette: true, quality: 94, colours: 256 })
    .toFile(output);
  return { width, height, sha256: sha256File(output) };
}

async function inspectRenderedComposition(renderer, pageSpec, variant) {
  const report = await renderer.evaluate(({ pageId, family, layout, expectedWidth, expectedHeight }) => {
    const rectOf = (element) => {
      if (!element) return null;
      const rect = element.getBoundingClientRect();
      return {
        left: Number(rect.left.toFixed(2)),
        top: Number(rect.top.toFixed(2)),
        right: Number(rect.right.toFixed(2)),
        bottom: Number(rect.bottom.toFixed(2)),
        width: Number(rect.width.toFixed(2)),
        height: Number(rect.height.toFixed(2)),
      };
    };
    const visible = (element) => {
      if (!element) return false;
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== 'none' && style.visibility !== 'hidden' && Number(style.opacity) > 0 && rect.width > 0 && rect.height > 0;
    };
    const hasHorizontalScroller = (element) => {
      let ancestor = element.parentElement;
      while (ancestor && ancestor !== document.body) {
        const style = getComputedStyle(ancestor);
        if (/auto|scroll/.test(style.overflowX) && ancestor.scrollWidth > ancestor.clientWidth + 1) return true;
        ancestor = ancestor.parentElement;
      }
      return false;
    };
    const isEvidenceBoard = layout.includes('board');
    const candidateElements = [...document.querySelectorAll('#root button, #root h1, #root h2, #root h3, #root strong, #root label, #root article, #root section, #root header, #root footer')]
      .filter((element) => !isEvidenceBoard || !element.closest('.mini-page,.motion-mini'));
    const horizontalOverflow = candidateElements
      .filter(visible)
      .map((element) => ({ element, rect: element.getBoundingClientRect() }))
      .filter(({ rect }) => rect.bottom > 0 && rect.top < expectedHeight && (rect.left < -1 || rect.right > expectedWidth + 1))
      .filter(({ element }) => !hasHorizontalScroller(element))
      .slice(0, 24)
      .map(({ element, rect }) => ({
        selector: element.className || element.tagName.toLowerCase(),
        text: (element.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 90),
        left: Number(rect.left.toFixed(2)),
        right: Number(rect.right.toFixed(2)),
      }));
    const clippedCopy = [...document.querySelectorAll('#root button, #root h1, #root h2, #root h3, #root strong, #root span')]
      .filter((element) => !isEvidenceBoard || !element.closest('.mini-page,.motion-mini'))
      .filter(visible)
      .filter((element) => (element.textContent || '').trim().length > 0)
      .filter((element) => {
        const style = getComputedStyle(element);
        return style.whiteSpace === 'nowrap' && element.scrollWidth > element.clientWidth + 1 && style.textOverflow !== 'ellipsis';
      })
      .slice(0, 24)
      .map((element) => ({ selector: element.className || element.tagName.toLowerCase(), text: element.textContent.trim().replace(/\s+/g, ' ').slice(0, 90), client_width: element.clientWidth, scroll_width: element.scrollWidth }));
    const app = isEvidenceBoard ? null : document.querySelector('.perfect-app');
    const board = document.querySelector('.evidence-board');
    const canvas = isEvidenceBoard ? null : document.querySelector('.app-canvas');
    const header = isEvidenceBoard ? null : document.querySelector('.glass-header');
    const footer = isEvidenceBoard ? null : document.querySelector('.phone-footer');
    const capture = isEvidenceBoard ? null : document.querySelector('.capture-orb');
    const suppressAppChrome = family === 'entry' || (family === 'native' && pageId.startsWith('pg-widget-'));
    const expectedFooter = !isEvidenceBoard && layout === 'phone-compact' && !suppressAppChrome;
    const expectedHeader = !isEvidenceBoard && !suppressAppChrome;
    const expectedCapture = !isEvidenceBoard && family === 'today' && layout !== 'phone-landscape-short';
    const failures = [];
    if (document.documentElement.scrollWidth !== expectedWidth || document.documentElement.scrollHeight !== expectedHeight) failures.push('document-viewport-containment');
    const rootSurface = app || board;
    const rootRect = rectOf(rootSurface);
    if (!rootRect || Math.abs(rootRect.left) > 1 || Math.abs(rootRect.top) > 1 || Math.abs(rootRect.right - expectedWidth) > 1 || Math.abs(rootRect.bottom - expectedHeight) > 1) failures.push('root-surface-bounds');
    if (app && (!canvas || Math.abs(canvas.getBoundingClientRect().height - expectedHeight) > 1 || Math.abs(canvas.getBoundingClientRect().right - expectedWidth) > 1)) failures.push('app-canvas-bounds');
    if (horizontalOverflow.length > 0) failures.push('uncontained-horizontal-overflow');
    if (clippedCopy.length > 0) failures.push('clipped-required-copy');
    if (expectedHeader !== visible(header)) failures.push('header-visibility-contract');
    if (expectedFooter !== visible(footer)) failures.push('footer-visibility-contract');
    if (expectedCapture !== visible(capture)) failures.push('capture-visibility-contract');
    return {
      page_id: pageId,
      layout,
      viewport: `${expectedWidth}x${expectedHeight}`,
      document: { width: document.documentElement.scrollWidth, height: document.documentElement.scrollHeight },
      root_bounds: rootRect,
      canvas_bounds: rectOf(canvas),
      header_bounds: rectOf(header),
      footer_bounds: rectOf(footer),
      capture_bounds: rectOf(capture),
      horizontal_overflow: horizontalOverflow,
      clipped_copy: clippedCopy,
      failure_ids: failures,
    };
  }, { pageId: pageSpec.page_id, family: pageSpec.family, layout: variant.layout, expectedWidth: variant.width, expectedHeight: variant.height });
  if (report.failure_ids.length > 0) {
    throw new Error(`Stage 05 composition audit failed for ${pageSpec.page_id}/${variant.file}: ${report.failure_ids.join(', ')}`);
  }
  return report;
}

async function main() {
  const auditOnly = process.argv.includes('--audit-only');
  const chromePath = resolveChrome();
  const catalog = model.buildCatalog();
  const gateHash = sha256Text(catalog.gate.section);
  let protectedPageArtifacts;
  if (!auditOnly) {
    protectedPageArtifacts = snapshotProtectedPageArtifacts();
    resetStage05PageOutputs(catalog.pages.map((page) => page.page_id));
    resetGeneratedDirectory(model.comparisonRoot);
    resetGeneratedDirectory(model.rejectedRoot);
    ensureDir(model.manifestRoot);
    for (const name of stage05ManifestNames) {
      const target = path.join(model.manifestRoot, name);
      if (fs.existsSync(target)) fs.rmSync(target, { force: true });
    }
  }

  const assets = {
    mark: fileDataUrl(path.join(model.projectRoot, 'assets', 'brand', 'perfect-launcher.png'), 'image/png'),
    wordmark: fileDataUrl(path.join(model.projectRoot, 'assets', 'brand', 'perfect-wordmark.png'), 'image/png'),
    wordmarkDark: fileDataUrl(path.join(model.projectRoot, 'assets', 'brand', 'perfect-wordmark-dark.png'), 'image/png'),
    fonts: {
      latin: fs.readFileSync(path.join(model.projectRoot, 'assets', 'fonts', 'PlusJakartaSans-Variable.ttf')).toString('base64'),
      persian: fs.readFileSync(path.join(model.projectRoot, 'assets', 'fonts', 'Vazirmatn-Variable.ttf')).toString('base64'),
    },
  };

  let browser;
  let page;
  let capturesSinceRecycle = 0;
  async function openRenderer() {
    browser = await chromium.launch({ executablePath: chromePath, headless: true, args: ['--disable-gpu', '--hide-scrollbars', '--font-render-hinting=none'] });
    page = await browser.newPage({ viewport: { width: 1200, height: 800 }, deviceScaleFactor: 1 });
    await page.setContent(visuals.documentHtml('', assets, { width: 1200, height: 800 }), { waitUntil: 'load' });
    await page.evaluate(async () => document.fonts.ready);
    capturesSinceRecycle = 0;
  }
  async function closeRenderer() {
    if (browser) await browser.close();
    browser = undefined;
    page = undefined;
  }
  async function recycleIfNeeded() {
    if (capturesSinceRecycle < 360) return;
    await closeRenderer();
    await openRenderer();
  }
  async function capture(markup, width, height, output, auditContext) {
    await recycleIfNeeded();
    await page.setViewportSize({ width, height });
    await page.evaluate(({ content, targetWidth, targetHeight }) => {
      document.body.style.width = `${targetWidth}px`;
      document.body.style.height = `${targetHeight}px`;
      document.documentElement.style.width = `${targetWidth}px`;
      document.documentElement.style.height = `${targetHeight}px`;
      document.getElementById('root').innerHTML = content;
    }, { content: markup, targetWidth: width, targetHeight: height });
    await page.evaluate(async () => {
      await document.fonts.ready;
      await Promise.all([...document.images].map((image) => image.decode().catch(() => undefined)));
    });
    const audit = auditContext ? await inspectRenderedComposition(page, auditContext.pageSpec, auditContext.variant) : undefined;
    if (auditContext?.skipScreenshot) {
      capturesSinceRecycle += 1;
      return audit;
    }
    ensureDir(path.dirname(output));
    await page.screenshot({ path: output, type: 'png', animations: 'disabled', caret: 'hide', omitBackground: false });
    const optimized = await sharp(output)
      .png({ compressionLevel: 9, adaptiveFiltering: true, palette: true, quality: 95, colours: 256, dither: 0.3 })
      .toBuffer();
    fs.writeFileSync(output, optimized);
    capturesSinceRecycle += 1;
    return audit;
  }

  if (auditOnly) {
    let audited = 0;
    await openRenderer();
    try {
      for (const pageSpec of catalog.pages) {
        for (const variant of model.canonicalVariants) {
          const document = visuals.canonicalHtml(pageSpec, variant, assets);
          const markup = document.match(/<div id="root">([\s\S]*)<\/div><\/body>/)[1];
          await capture(markup, variant.width, variant.height, undefined, { pageSpec, variant, skipScreenshot: true });
          audited += 1;
        }
        if (audited % 50 === 0) console.log(`STAGE05_AUDIT_PROGRESS ${audited}/${catalog.pages.length * model.canonicalVariants.length}`);
      }
    } finally {
      await closeRenderer();
    }
    console.log(`STAGE05_AUDIT_PASS pages=${catalog.pages.length} compositions=${audited}`);
    return;
  }

  const pageEntries = [];
  await openRenderer();
  try {
    for (let index = 0; index < catalog.pages.length; index += 1) {
      const pageSpec = catalog.pages[index];
      const pageDirectory = path.join(model.pageRoot, pageSpec.page_id);
      const candidateDirectory = path.join(pageDirectory, 'candidates');
      const canonicalDirectory = path.join(pageDirectory, 'canonical');
      ensureDir(candidateDirectory);
      ensureDir(canonicalDirectory);

      const candidatePaths = {};
      const candidateHashes = {};
      for (const candidate of model.candidates) {
        const output = path.join(candidateDirectory, candidate.file);
        const document = visuals.candidateFrame(pageSpec, candidate, assets);
        const markup = document.match(/<div id="root">([\s\S]*)<\/div><\/body>/)[1];
        await capture(markup, 720, 480, output);
        candidatePaths[candidate.file] = relative(output);
        candidateHashes[candidate.file] = sha256File(output);
      }

      const previewPaths = {};
      const previewHashes = {};
      const previewAudits = {};
      for (const variant of model.canonicalVariants) {
        const output = path.join(canonicalDirectory, variant.file);
        const document = visuals.canonicalHtml(pageSpec, variant, assets);
        const markup = document.match(/<div id="root">([\s\S]*)<\/div><\/body>/)[1];
        previewAudits[variant.file] = await capture(markup, variant.width, variant.height, output, { pageSpec, variant });
        previewPaths[variant.file] = relative(output);
        previewHashes[variant.file] = sha256File(output);
      }

      pageSpec.preview_sha256 = previewHashes;
      pageSpec.candidate_sha256 = candidateHashes;
      pageSpec.canonical_previews = previewPaths;
      pageSpec.candidate_previews = candidatePaths;
      pageSpec.canonical_audits = previewAudits;
      const contractFile = path.join(pageDirectory, 'composition.yaml');
      writeJson(contractFile, pageSpec);
      const decisionFile = path.join(pageDirectory, 'decision.md');
      fs.writeFileSync(decisionFile, decisionMarkdown(pageSpec), 'utf8');
      pageEntries.push({
        page_id: pageSpec.page_id,
        family: pageSpec.family,
        subgroup: pageSpec.subgroup,
        title: pageSpec.title,
        fixture_id: pageSpec.fixture_id,
        selected_candidate: pageSpec.selected_candidate,
        component_count: pageSpec.component_ids.length,
        component_ids: pageSpec.component_ids,
        scenario_ids: pageSpec.scenario_ids,
        contract: relative(contractFile),
        contract_sha256: sha256File(contractFile),
        decision: relative(decisionFile),
        decision_sha256: sha256File(decisionFile),
        candidates: candidatePaths,
        candidate_sha256: candidateHashes,
        previews: previewPaths,
        preview_sha256: previewHashes,
        canonical_audits: previewAudits,
      });
      if ((index + 1) % 5 === 0 || index === catalog.pages.length - 1) {
        console.log(`STAGE05_RENDER_PROGRESS ${index + 1}/${catalog.pages.length} ${pageSpec.page_id}`);
      }
    }
  } finally {
    await closeRenderer();
  }

  const familySheets = {};
  for (const family of Object.keys(model.familyLabels)) {
    const entries = pageEntries.filter((entry) => entry.family === family);
    const output = path.join(model.pageRoot, `${family}-contact-sheet.png`);
    const metadata = await makeContactSheet(entries.map((entry) => ({ id: entry.page_id, subtitle: entry.selected_candidate, file: path.join(model.projectRoot, entry.previews['phone-compact.png']) })), output, { columns: Math.min(4, Math.max(2, entries.length)), tileWidth: 230, tileHeight: 270 });
    familySheets[family] = { file: relative(output), page_count: entries.length, ...metadata };
  }
  const masterSheet = path.join(model.pageRoot, 'stage05-page-library-contact-sheet.png');
  const masterSheetMeta = await makeContactSheet(pageEntries.map((entry) => ({ id: entry.page_id, subtitle: entry.family, file: path.join(model.projectRoot, entry.previews['phone-compact.png']) })), masterSheet, { columns: 7, tileWidth: 210, tileHeight: 250, gutter: 10, padding: 16 });

  const candidateSheets = {};
  for (const candidate of model.candidates) {
    const output = path.join(model.rejectedRoot, `${candidate.id}-contact-sheet.png`);
    const metadata = await makeContactSheet(pageEntries.map((entry) => ({ id: entry.page_id, subtitle: entry.selected_candidate === candidate.id ? 'selected' : 'rejected', file: path.join(model.projectRoot, entry.candidates[candidate.file]) })), output, { columns: 7, tileWidth: 210, tileHeight: 170, gutter: 9, padding: 14 });
    candidateSheets[candidate.id] = { file: relative(output), ...metadata };
  }

  const componentConsumers = new Map(catalog.componentManifest.components.map((entry) => [entry.component_id, []]));
  for (const pageEntry of pageEntries) {
    for (const componentId of pageEntry.component_ids) componentConsumers.get(componentId).push(pageEntry.page_id);
  }
  const coverage = {
    catalog_version: model.catalogVersion,
    component_catalog_version: model.componentCatalogVersion,
    generated_at: model.generatedAt,
    exact_component_count: componentConsumers.size,
    unconsumed_component_count: [...componentConsumers.values()].filter((consumers) => consumers.length === 0).length,
    component_consumers: [...componentConsumers.entries()].map(([component_id, consumers]) => ({ component_id, consumers, consumer_count: consumers.length })),
    whole_product_families: Object.entries(model.familyLabels).map(([family, label]) => ({ family, label, pages: pageEntries.filter((entry) => entry.family === family).map((entry) => entry.page_id) })),
    silent_consumer_policy: 'Every Stage 04 component and every Stage 05 page has at least one explicit owner/consumer mapping; silence is not acceptance.',
  };

  const pagesFile = path.join(model.manifestRoot, 'pages.json');
  writeJson(pagesFile, {
    catalog_version: model.catalogVersion,
    component_catalog_version: model.componentCatalogVersion,
    generated_at: model.generatedAt,
    design_direction: 'PS01 Perfect Day Instrument',
    gate_source: relative(model.gatePath),
    gate_section_sha256: gateHash,
    exact_page_count: pageEntries.length,
    exact_candidate_count: pageEntries.length * model.candidates.length,
    exact_canonical_preview_count: pageEntries.length * model.canonicalVariants.length,
    candidates_per_page: model.candidates,
    canonical_preview_files_per_page: model.canonicalVariants,
    family_contact_sheets: familySheets,
    candidate_contact_sheets: candidateSheets,
    master_contact_sheet: { file: relative(masterSheet), ...masterSheetMeta },
    fixture_boundary: 'All page preview data is isolated design/test material and is unreachable from production persistence.',
    production_boundary: 'No Flutter, native, domain, database, auth, sync or Supabase source is generated or mutated by Stage 05.',
    pages: pageEntries,
  });

  const copyFile = path.join(model.manifestRoot, 'copy.json');
  writeJson(copyFile, copyRegistry(catalog.pages));
  const fixturesFile = path.join(model.manifestRoot, 'fixtures.json');
  writeJson(fixturesFile, fixturesRegistry());
  const coverageFile = path.join(model.manifestRoot, 'coverage-ledger.json');
  writeJson(coverageFile, coverage);

  const smoke = await createHarnessSmoke(catalog.pages);
  const qualityFile = path.join(model.manifestRoot, 'quality-harness.json');
  writeJson(qualityFile, {
    catalog_version: model.catalogVersion,
    generated_at: model.generatedAt,
    required_axes: ['geometry', 'density', 'text', 'theme', 'input', 'motion', 'connectivity', 'auth', 'lifecycle', 'origin'],
    deterministic_fixtures: fixturesRegistry().fixtures.map((fixture) => fixture.id),
    geometry_assertions: ['viewport containment', 'paired-edge symmetry', 'optical center', '>=48dp target', 'safe line length', 'final action reachability', 'no critical overlap'],
    semantic_assertions: ['unique label', 'role', 'value', 'state', 'action', 'reading order', 'focus order'],
    interaction_drivers: ['task state cycle', 'rapid habit increment', 'wizard path', 'keyboard traversal', 'context menu', 'resize', 'IME', 'outside dismissal', 'back', 'deep link'],
    motion_capture: ['route/title rise', 'capture morph', 'sheet/dialog', 'selector', 'completion', 'sync', 'resize', 'reduced motion'],
    performance_capture: ['startup', 'composer', 'dense lists', 'detail', 'wizard', 'widget action'],
    copy_pipeline: 'reference.png + runtime.png + overlay.png + diff.png + mismatch.md + comparison.json',
    injected_failure_smoke: smoke,
    expected_failure_categories: ['geometry', 'typography', 'state'],
    exact_rendered_composition_audits: pageEntries.length * model.canonicalVariants.length,
    rendered_composition_gate: 'Every canonical page/variant must preserve exact root bounds, horizontal containment, required live copy, and platform chrome visibility before its PNG is accepted.',
    commands: {
      generate: 'node tool/generate_stage05_page_library.cjs',
      audit: 'node tool/generate_stage05_page_library.cjs --audit-only',
      verify: 'node tool/verify_stage05_page_library.cjs',
      contract: 'flutter test test/presentation/page_preview_quality_harness_contract_test.dart',
      intentional_failure: 'node tool/stage05/preview_diff.cjs --reference <reference> --runtime <mutated-runtime> --reference-meta <reference-meta> --runtime-meta <runtime-meta> --output <output> --fail-on-mismatch',
    },
    ci_failure_contract: 'Exit code 2 names exact page/scenario/categories when a comparison mismatch exists; exit code 1 is harness failure.',
  });

  const registryFile = path.join(model.manifestRoot, 'stage05-registry.json');
  writeJson(registryFile, {
    catalog_version: model.catalogVersion,
    component_catalog_version: model.componentCatalogVersion,
    generated_at: model.generatedAt,
    direction: 'PS01 Perfect Day Instrument',
    gate_section_sha256: gateHash,
    counts: {
      pages: pageEntries.length,
      page_families: Object.keys(model.familyLabels).length,
      structural_candidates: pageEntries.length * model.candidates.length,
      canonical_previews: pageEntries.length * model.canonicalVariants.length,
      canonical_render_audits: pageEntries.length * model.canonicalVariants.length,
      component_consumers: componentConsumers.size,
      live_copy_entries: copyRegistry(catalog.pages).entries.length,
      fixtures: fixturesRegistry().fixtures.length,
      motion_ids: 20,
      comparison_smokes: smoke.length,
    },
    manifests: [pagesFile, copyFile, fixturesFile, coverageFile, qualityFile].map(relative),
    generator: relative(__filename),
    renderer: { engine: 'Playwright', browser: path.basename(chromePath), device_scale_factor: 1, exact_viewports: model.canonicalVariants.map((variant) => `${variant.file}:${variant.viewport}`) },
    acceptance: 'Final design-only gate. Stage 06 may implement only from exact page/component IDs, decomposition records and hashes.',
  });

  assertProtectedPageArtifacts(protectedPageArtifacts);
  const generatedPageFiles = [
    ...catalog.pages.flatMap((page) => listFiles(path.join(model.pageRoot, page.page_id))),
    ...Object.keys(model.familyLabels).map((family) => path.join(model.pageRoot, `${family}-contact-sheet.png`)),
    masterSheet,
  ];
  const generatedFiles = [
    ...generatedPageFiles,
    ...listFiles(model.comparisonRoot),
    ...listFiles(model.rejectedRoot),
    pagesFile,
    copyFile,
    fixturesFile,
    coverageFile,
    qualityFile,
    registryFile,
  ].sort((left, right) => relative(left).localeCompare(relative(right)));
  const hashesFile = path.join(model.manifestRoot, 'stage05-hashes.sha256');
  fs.writeFileSync(hashesFile, `${generatedFiles.map((file) => `${sha256File(file)}  ${relative(file)}`).join('\n')}\n`, 'utf8');

  console.log(`STAGE05_GENERATION_PASS pages=${pageEntries.length} candidates=${pageEntries.length * model.candidates.length} previews=${pageEntries.length * model.canonicalVariants.length} components=${componentConsumers.size} comparisons=${smoke.length}`);
  console.log(`STAGE05_HASH_MANIFEST ${relative(hashesFile)} entries=${generatedFiles.length}`);
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
