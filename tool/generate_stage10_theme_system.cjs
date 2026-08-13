#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const model = require('./stage10/theme_system_model.cjs');
const visuals = require('./stage10/theme_system_visuals.cjs');

const renderScript = path.join(model.projectRoot, 'tool/render_design_svg.cjs');
const generatedAt = '2026-08-13';

function ensureDir(directory) {
  fs.mkdirSync(directory, { recursive: true });
}

function assertOutputTarget(target) {
  const root = path.resolve(model.outputRoot);
  const resolved = path.resolve(target);
  if (resolved === root || !resolved.startsWith(`${root}${path.sep}`)) {
    throw new Error(`Refusing unsafe Stage 10 output target: ${resolved}`);
  }
  return resolved;
}

function resetOutput() {
  const root = path.resolve(model.outputRoot);
  const designRoot = path.resolve(model.designRoot);
  if (root === designRoot || !root.startsWith(`${designRoot}${path.sep}`)) {
    throw new Error(`Refusing unsafe Stage 10 reset: ${root}`);
  }
  ensureDir(root);
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    // Runtime captures are separately owned, immutable evidence. Regenerating
    // deterministic design boards must never erase exact-build proof.
    if (entry.name === 'runtime') continue;
    const target = assertOutputTarget(path.join(root, entry.name));
    fs.rmSync(target, { recursive: true, force: true });
  }
}

function sha256Buffer(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

function sha256File(file) {
  return sha256Buffer(fs.readFileSync(file));
}

function relative(file) {
  return path.relative(model.projectRoot, file).replaceAll('\\', '/');
}

function writeText(file, value) {
  const target = assertOutputTarget(file);
  ensureDir(path.dirname(target));
  fs.writeFileSync(target, value.endsWith('\n') ? value : `${value}\n`, 'utf8');
}

function writeJson(file, value) {
  writeText(file, `${JSON.stringify(value, null, 2)}\n`);
}

function dataUrl(file, mime) {
  return `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
}

function hexChannels(value) {
  const normalized = value.replace('#', '');
  if (!/^[0-9a-f]{6}$/i.test(normalized)) {
    throw new Error(`Contrast color must be #RRGGBB: ${value}`);
  }
  return [0, 2, 4].map((offset) => Number.parseInt(normalized.slice(offset, offset + 2), 16) / 255);
}

function luminance(value) {
  const channels = hexChannels(value).map((channel) => channel <= .04045 ? channel / 12.92 : ((channel + .055) / 1.055) ** 2.4);
  return channels[0] * .2126 + channels[1] * .7152 + channels[2] * .0722;
}

function contrast(a, b) {
  const first = luminance(a);
  const second = luminance(b);
  const lighter = Math.max(first, second);
  const darker = Math.min(first, second);
  return (lighter + .05) / (darker + .05);
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function verifySourceHash(file, expected, label) {
  const bytes = fs.readFileSync(file);
  const raw = sha256Buffer(bytes);
  const textExtensions = new Set(['.svg', '.json', '.md', '.yaml', '.yml', '.txt']);
  const canonical = textExtensions.has(path.extname(file).toLowerCase())
    ? sha256Buffer(Buffer.from(bytes.toString('utf8').replace(/\r\n/g, '\n'), 'utf8'))
    : raw;
  if (raw !== expected && canonical !== expected) {
    throw new Error(`${label} source drift: ${relative(file)} expected ${expected} raw ${raw} canonical ${canonical}`);
  }
  return expected;
}

function freezeComponents() {
  const source = path.join(model.manifestRoot, 'components.json');
  const manifest = readJson(source);
  if (!Array.isArray(manifest.components) || manifest.components.length !== 181) {
    throw new Error(`Stage 10 expected 181 Stage 04 components, got ${manifest.components?.length}`);
  }
  return manifest.components.map((component) => {
    const variants = {
      light: 'states-light.png',
      dark: 'states-dark.png',
      high_contrast: 'accessibility.png',
    };
    const frozen = {};
    for (const [theme, previewName] of Object.entries(variants)) {
      const preview = component.previews[previewName];
      const expected = component.preview_sha256[previewName];
      if (!preview || !expected) throw new Error(`${component.component_id} lacks ${previewName}`);
      const absolute = path.join(model.projectRoot, preview);
      verifySourceHash(absolute, expected, `${component.component_id}/${theme}`);
      frozen[theme] = { file: preview, sha256: expected };
    }
    return {
      component_id: component.component_id,
      family: component.family,
      consumers: component.consumers,
      theme_variants: frozen,
      token_contract: 'No live consumer may introduce an unregistered raw color; authored assets require a stable theme-aware asset ID.',
    };
  });
}

function freezePages() {
  const source = path.join(model.manifestRoot, 'pages.json');
  const manifest = readJson(source);
  if (!Array.isArray(manifest.pages) || manifest.pages.length !== 134) {
    throw new Error(`Stage 10 expected 134 Stage 05 pages, got ${manifest.pages?.length}`);
  }
  return manifest.pages.map((page) => {
    const variants = {
      light_phone: 'phone-compact.png',
      dark_phone: 'dark.png',
      high_contrast_stress: 'stress.png',
      tablet_portrait: 'tablet-portrait.png',
      tablet_landscape: 'tablet-landscape.png',
      windows_compact: 'windows-compact.png',
      windows_wide: 'windows-wide.png',
    };
    const frozen = {};
    for (const [theme, previewName] of Object.entries(variants)) {
      const preview = page.previews[previewName];
      const expected = page.preview_sha256[previewName];
      if (!preview || !expected) throw new Error(`${page.page_id} lacks ${previewName}`);
      const absolute = path.join(model.projectRoot, preview);
      verifySourceHash(absolute, expected, `${page.page_id}/${theme}`);
      frozen[theme] = { file: preview, sha256: expected };
    }
    return {
      page_id: page.page_id,
      family: page.family,
      component_ids: page.component_ids,
      theme_variants: frozen,
      state_contract: 'Theme substitution preserves route, selection, scroll, draft, focus, timers, local records and outbox identity.',
    };
  });
}

function freezeFoundations() {
  const source = path.join(model.manifestRoot, 'foundations.json');
  const manifest = readJson(source);
  const required = ['fnd-color-roles', 'fnd-material', 'fnd-focus-a11y'];
  return required.map((id) => {
    const foundation = manifest.foundations.find((entry) => entry.foundation_id === id);
    if (!foundation) throw new Error(`Stage 10 source foundation missing: ${id}`);
    const previews = {};
    for (const previewName of foundation.preview_files) {
      const file = foundation.previews[previewName];
      const expected = foundation.preview_sha256[previewName];
      verifySourceHash(path.join(model.projectRoot, file), expected, `${id}/${previewName}`);
      previews[previewName] = { file, sha256: expected };
    }
    return {
      foundation_id: id,
      source_catalog_version: foundation.catalog_version,
      source_previews: previews,
      stage10_variant_ids: Object.values(model.themes).map((theme) => theme.id),
    };
  });
}

function contrastReport() {
  const reports = [];
  for (const theme of Object.values(model.themes)) {
    const pairs = model.contrastPairs.map(([foreground, background, baseThreshold, purpose]) => {
      const ratio = contrast(theme[foreground], theme[background]);
      const threshold = theme.contrast === 'high' && baseThreshold === 4.5 ? 7 : baseThreshold;
      return {
        foreground_role: foreground,
        background_role: background,
        purpose,
        foreground: theme[foreground],
        background: theme[background],
        ratio: Number(ratio.toFixed(2)),
        threshold,
        pass: ratio + 1e-6 >= threshold,
      };
    });
    const failures = pairs.filter((pair) => !pair.pass);
    reports.push({
      theme_id: theme.id,
      brightness: theme.brightness,
      contrast: theme.contrast,
      exact_pair_count: pairs.length,
      failures,
      pairs,
    });
  }
  const failures = reports.flatMap((report) => report.failures.map((failure) => ({ theme_id: report.theme_id, ...failure })));
  if (failures.length > 0) {
    throw new Error(`Stage 10 contrast gate failed:\n${JSON.stringify(failures, null, 2)}`);
  }
  return {
    standard_text_threshold: 4.5,
    high_contrast_text_threshold: 7,
    non_text_and_focus_threshold: 3,
    note: 'Ratios are necessary but not sufficient. Generated contact sheets still require visual comparison for hierarchy, muddy glass and pastel separation.',
    themes: reports,
  };
}

function renderBoards(assets) {
  const specs = [
    ['candidate-comparison', 2400, 1120, visuals.candidateBoard(assets)],
    ['theme-foundations', 2400, 1110, visuals.foundationBoard(assets)],
    ['phone-empty-dense-matrix', 2400, 1530, visuals.phoneMatrix(assets)],
    ['adaptive-tablet-windows-matrix', 2400, 1420, visuals.adaptiveMatrix(assets)],
    ['component-state-matrix', 2400, 1320, visuals.componentMatrix(assets)],
    ['native-surface-matrix', 2400, 1350, visuals.nativeMatrix(assets)],
  ];
  const rendered = [];
  for (const [id, width, height, svg] of specs) {
    const svgFile = path.join(model.outputRoot, `${id}.svg`);
    const pngFile = path.join(model.outputRoot, `${id}.png`);
    writeText(svgFile, svg);
    execFileSync(process.execPath, [renderScript, svgFile, pngFile, String(width), String(height)], {
      cwd: model.projectRoot,
      stdio: 'inherit',
      env: process.env,
    });
    rendered.push({
      id,
      viewport: `${width}x${height}`,
      svg: { file: relative(svgFile), sha256: sha256File(svgFile) },
      png: { file: relative(pngFile), sha256: sha256File(pngFile) },
    });
  }
  return rendered;
}

function decisionMarkdown(report) {
  const candidates = model.candidates.map((candidate) => `| ${candidate.title} | ${candidate.score} | ${candidate.verdict} |`).join('\n');
  const minimums = report.themes.map((theme) => {
    const minimum = Math.min(...theme.pairs.map((pair) => pair.ratio));
    return `- \`${theme.theme_id}\`: lowest registered pair **${minimum.toFixed(2)}:1**; ${theme.exact_pair_count}/${theme.exact_pair_count} passed.`;
  }).join('\n');
  return `# Stage 10 design decision — Graphite Bloom\n\nStatus: **autonomously accepted for implementation**\nCatalog: \`${model.catalogVersion}\`\nBoundary: design evidence only; fixture labels never seed owner data.\n\n## Product truth\n\nPerfect is a calm private day instrument used repeatedly across Android and Windows. The theme system must make long planning sessions legible without turning the product into a generic black dashboard, muddy pastel canvas, or color-only status display.\n\n## Candidates compared\n\n| Direction | Score / 100 | Verdict |\n| --- | ---: | --- |\n${candidates}\n\n## Selected\n\n**Graphite Bloom** keeps neutral graphite depth, authored pastel light and explicit boundaries. It is recognizably Perfect in a cropped screenshot, preserves the PS01 Pulse/Stream anatomy, and leaves enough contrast headroom for live mixed Persian/English copy, focus, hover and sync states.\n\nThe separate **Clarity** variants are accessibility products, not inversions: blur is removed, boundaries become structural, text targets 7:1, focus targets at least 3:1 and every status keeps icon + copy + color.\n\n## Modernize / Integrity / Anatomy / Style / Copy verdicts\n\n- **Modernize:** uncommon material idea remains tied to the day-instrument job; no template dashboard or generic gradient glass.\n- **Integrity:** one semantic registry owns Flutter, authored assets, Android native surfaces and Windows chrome.\n- **Anatomy:** theme substitution never moves navigation, actions, text blocks, panes or state surfaces.\n- **Style:** pastel identity is concentrated in intention/rhythm/focus roles; neutral separation carries long-session hierarchy.\n- **Copy:** Stage 04/05 exact component/page assets are frozen by hash, and the new matrices preserve their layout/state contracts before runtime work begins.\n\n## Measured contrast\n\n${minimums}\n\n## Autonomous authority\n\nThe owner explicitly requested independent design decisions and no consultation during this execution. The already-selected PS01 direction is unchanged; this file approves only its Stage 10 theme/material variants.\n`;
}

function sourceMapMarkdown() {
  return `# Stage 10 source-of-truth map\n\n| Concern | Source of truth | Consumers | Rejected duplication |\n| --- | --- | --- | --- |\n| Theme choice | \`PerfectPreferences\` appearance value | app root, settings, native bridge, widget projection | per-page booleans |\n| Light/dark/high-contrast colors | \`PerfectTheme\` semantic factories + theme extensions | every Flutter surface, painter and authored-asset selector | raw colors in live widgets |\n| System request | \`MediaQuery.highContrast\` plus owner override | \`MaterialApp.highContrastTheme\`, asset variants, glass fallback | asset-only high contrast |\n| Android native appearance | system-appearance channel + HomeWidget preference | splash mode, widget, Quick Add | light-only XML colors |\n| Windows frame | system-appearance channel | DWM caption/border/text | registry-only system brightness |\n| Design evidence | \`${model.catalogVersion}\` registry | Stage 11+ previews and Copy comparisons | screenshots without IDs/hashes |\n| Contrast proof | generated role-pair report + runtime screenshots | tests, docs and Critics | ratio-only acceptance |\n\nTheme changes preserve route, selection, scroll, focus, draft, timers, local records, authenticated session and outbox identity.\n`;
}

function mismatchLedgerMarkdown() {
  return `# Stage 10 preview / runtime mismatch ledger\n\nStatus: **preview gate frozen; Flutter and Android runtime rows closed; hosted Windows row pending exact-SHA build**\n\n| Surface | Preview evidence | Runtime evidence | Expected mismatch before implementation | Acceptance after implementation |\n| --- | --- | --- | --- | --- |\n| Foundations | \`theme-foundations.png\` | four authored ThemeData variants, 76 measured pairs, semantic-role source scan | closed | four stable theme IDs; zero reusable raw-color bypass; every measured pair passes its threshold |\n| Phone empty/dense | \`phone-empty-dense-matrix.png\` | five Stage 10 phone goldens plus real build-2062 Daylight/Graphite/Clarity captures | closed | geometry remains stable; Orbit live text and curved period labels remain visible in all four themes |\n| Tablet/Windows | \`adaptive-tablet-windows-matrix.png\` | tablet/Windows dark and Clarity goldens; Windows MethodChannel/DWM contract | Flutter closed; hosted Windows compile pending | pane geometry stable; exact-SHA hosted runner must compile and package the native frame bridge |\n| Components | \`component-state-matrix.png\` | 444-test suite, focused theme/accessibility, workspace, Sync and widget contracts | closed | sheets, dialogs, snackbars, painters, focus, status and controls resolve through semantic roles |\n| Native surfaces | \`native-surface-matrix.png\` | Android four-layout contract, 40 theme rasters, 16 status vectors, four surfaces and Quick Add projection | Android closed; hosted Windows pending | Android widget/Quick Add follow effective appearance; Windows DWM bridge awaits hosted compile proof |\n\nNo preview image is runtime proof. Android rows close against the hash-verified\n\`runtime/android/runtime-manifest.json\` evidence from the confirmed foreground\npreview package. Windows remains explicitly open until the exact source SHA passes\nthe trusted hosted build because this local host lacks the optional ATL header used\nby \`flutter_local_notifications_windows\`.\n`;
}

function main() {
  resetOutput();
  const assets = {
    plusJakarta: dataUrl(path.join(model.projectRoot, 'assets/fonts/PlusJakartaSans-Variable.ttf'), 'font/ttf'),
    vazirmatn: dataUrl(path.join(model.projectRoot, 'assets/fonts/Vazirmatn-Variable.ttf'), 'font/ttf'),
    wordmarkLight: dataUrl(path.join(model.projectRoot, 'assets/brand/perfect-wordmark.png'), 'image/png'),
    wordmarkDark: dataUrl(path.join(model.projectRoot, 'assets/brand/perfect-wordmark-dark.png'), 'image/png'),
    markLight: dataUrl(path.join(model.projectRoot, 'assets/brand/perfect-launcher.png'), 'image/png'),
    markDark: dataUrl(path.join(model.projectRoot, 'assets/brand/perfect-mark-dark.png'), 'image/png'),
  };
  const foundations = freezeFoundations();
  const components = freezeComponents();
  const pages = freezePages();
  const contrast = contrastReport();
  const boards = renderBoards(assets);

  const paletteFile = path.join(model.outputRoot, 'theme-tokens.json');
  const contrastFile = path.join(model.outputRoot, 'contrast-report.json');
  const componentFile = path.join(model.outputRoot, 'component-theme-freeze.json');
  const pageFile = path.join(model.outputRoot, 'page-theme-freeze.json');
  const registryFile = path.join(model.outputRoot, 'stage10-theme-registry.json');
  writeJson(paletteFile, {
    catalog_version: model.catalogVersion,
    direction: model.direction,
    generated_at: generatedAt,
    themes: model.themes,
    raw_color_policy: 'Source palette literals may exist only in the theme/native resource registries. Live reusable UI consumes semantic roles.',
  });
  writeJson(contrastFile, contrast);
  writeJson(componentFile, { catalog_version: model.catalogVersion, exact_component_count: components.length, components });
  writeJson(pageFile, { catalog_version: model.catalogVersion, exact_page_count: pages.length, pages });
  writeText(path.join(model.outputRoot, 'decision.md'), decisionMarkdown(contrast));
  writeText(path.join(model.outputRoot, 'source-of-truth-map.md'), sourceMapMarkdown());
  writeText(path.join(model.outputRoot, 'preview-runtime-mismatch-ledger.md'), mismatchLedgerMarkdown());

  const registry = {
    catalog_version: model.catalogVersion,
    generated_at: generatedAt,
    direction: model.direction,
    source_catalogs: {
      stage04: 'ps01-ds-1.0.0',
      stage05: 'ps01-pages-1.0.0',
    },
    counts: {
      foundations: foundations.length,
      themes: Object.keys(model.themes).length,
      candidates: model.candidates.length,
      components: components.length,
      component_theme_variants: components.length * 3,
      pages: pages.length,
      page_theme_layout_variants: pages.length * 7,
      measured_contrast_pairs: contrast.themes.reduce((sum, theme) => sum + theme.pairs.length, 0),
      boards: boards.length,
    },
    selected_candidate: model.candidates[0].id,
    foundations,
    artifacts: {
      theme_tokens: relative(paletteFile),
      contrast_report: relative(contrastFile),
      component_freeze: relative(componentFile),
      page_freeze: relative(pageFile),
      decision: relative(path.join(model.outputRoot, 'decision.md')),
      source_map: relative(path.join(model.outputRoot, 'source-of-truth-map.md')),
      mismatch_ledger: relative(path.join(model.outputRoot, 'preview-runtime-mismatch-ledger.md')),
      boards,
    },
    acceptance: 'Design-only Copy entry gate. Runtime fidelity requires Stage 10 implementation, exact-build screenshots, contrast tests and native theme proof.',
  };
  writeJson(registryFile, registry);

  const hashFile = path.join(model.outputRoot, 'stage10-hashes.sha256');
  const hashTargets = fs.readdirSync(model.outputRoot)
    .map((name) => path.join(model.outputRoot, name))
    .filter((file) => fs.statSync(file).isFile() && file !== hashFile)
    .sort((a, b) => relative(a).localeCompare(relative(b)));
  writeText(hashFile, hashTargets.map((file) => `${sha256File(file)}  ${relative(file)}`).join('\n'));

  console.log(`STAGE10_PREVIEW_PASS foundations=${foundations.length} themes=${Object.keys(model.themes).length} components=${components.length} pages=${pages.length} boards=${boards.length}`);
}

main();
