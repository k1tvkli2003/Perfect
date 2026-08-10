#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { chromium } = require('playwright');

const model = require('./stage04/design_catalog_model.cjs');
const visuals = require('./stage04/design_catalog_visuals.cjs');
const foundationsVisuals = require('./stage04/design_catalog_foundations.cjs');

const previewKinds = [
  'states-light',
  'states-dark',
  'responsive',
  'accessibility',
  'motion-board',
  'neighbor-plate',
];

const chromeCandidates = [
  process.env.PERFECT_CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
].filter(Boolean);

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

function fileDataUrl(file, mime) {
  return `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
}

function resolveChrome() {
  const found = chromeCandidates.find((candidate) => fs.existsSync(candidate));
  if (!found) throw new Error('No local Chrome/Edge executable is available for deterministic Stage 04 rendering.');
  return found;
}

function categoryIconSvg(id, label, icon, index) {
  const palettes = [
    ['#A4510E', '#FFD7AF'],
    ['#347B54', '#CDEED8'],
    ['#6954B8', '#DED7FF'],
    ['#1D6870', '#CBEFF0'],
  ];
  const [ink, soft] = palettes[index % palettes.length];
  const inner = visuals.iconSvg(icon, 24)
    .replace(/^<svg[^>]*>/, '')
    .replace(/<\/svg>$/, '');
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512" role="img" aria-labelledby="title desc">
    <title id="title">${visuals.escapeHtml(label)}</title>
    <desc id="desc">Perfect category pictogram: ${visuals.escapeHtml(id)}</desc>
    <g transform="translate(56 56) scale(16.6666667)" fill="none" stroke="${soft}" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round" opacity=".96">${inner}</g>
    <g transform="translate(56 56) scale(16.6666667)" fill="none" stroke="${ink}" stroke-width="1.72" stroke-linecap="round" stroke-linejoin="round">${inner}</g>
    <circle cx="432" cy="92" r="17" fill="${soft}"/><circle cx="432" cy="92" r="7" fill="${ink}"/>
  </svg>`;
}

async function waitForAssets(page) {
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.images].map((image) => image.decode().catch(() => undefined)));
  });
}

async function capture(page, html, output) {
  await page.setContent(html, { waitUntil: 'load' });
  await waitForAssets(page);
  await page.screenshot({
    path: output,
    type: 'png',
    animations: 'disabled',
    caret: 'hide',
    omitBackground: false,
  });
  const optimized = await sharp(output)
    .png({
      compressionLevel: 9,
      adaptiveFiltering: true,
      palette: true,
      quality: 96,
      colours: 256,
      dither: 0.35,
    })
    .toBuffer();
  fs.writeFileSync(output, optimized);
}

function tileLabelSvg(width, height, title, subtitle = '') {
  const safeTitle = visuals.escapeHtml(title);
  const safeSubtitle = visuals.escapeHtml(subtitle);
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <rect width="${width}" height="${height}" rx="18" fill="#FFFFFF" stroke="#E7DED3"/>
    <text x="14" y="22" font-family="Segoe UI, sans-serif" font-size="12" font-weight="700" fill="#1D2030">${safeTitle}</text>
    <text x="${width - 14}" y="22" text-anchor="end" font-family="Consolas, monospace" font-size="9" fill="#686579">${safeSubtitle}</text>
  </svg>`);
}

async function makeContactSheet(items, output, options = {}) {
  const columns = options.columns || 4;
  const tileWidth = options.tileWidth || 300;
  const tileHeight = options.tileHeight || 220;
  const gutter = options.gutter || 14;
  const padding = options.padding || 22;
  const imageTop = 32;
  const imageInset = 9;
  const rows = Math.ceil(items.length / columns);
  const width = padding * 2 + columns * tileWidth + (columns - 1) * gutter;
  const height = padding * 2 + rows * tileHeight + Math.max(0, rows - 1) * gutter;
  const composite = [];

  for (let index = 0; index < items.length; index += 1) {
    const item = items[index];
    const column = index % columns;
    const row = Math.floor(index / columns);
    const left = padding + column * (tileWidth + gutter);
    const top = padding + row * (tileHeight + gutter);
    const label = tileLabelSvg(tileWidth, tileHeight, item.id, item.subtitle || '');
    const image = await sharp(item.file)
      .resize(tileWidth - imageInset * 2, tileHeight - imageTop - imageInset, {
        fit: 'contain',
        background: '#FFFCF7',
      })
      .png()
      .toBuffer();
    composite.push({ input: label, left, top });
    composite.push({ input: image, left: left + imageInset, top: top + imageTop });
  }

  ensureDir(path.dirname(output));
  await sharp({ create: { width, height, channels: 4, background: '#F6F0E8' } })
    .composite(composite)
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(output);
  return { width, height, sha256: sha256File(output) };
}

function motionManifest() {
  return {
    catalog_version: model.catalogVersion,
    generated_at: model.generatedAt,
    count: model.motionBible.families.length,
    motions: model.motionBible.families.map((motion) => ({
      ...motion,
      trigger: `${motion.intent} becomes active through explicit user or system state change`,
      affected_layers: ['semantic owner', 'selection/state material', 'focus continuity'],
      frames: ['first: prior stable geometry', 'mid: interruptible semantic transition', 'end: final value announced'],
      interruption: 'Settle toward the latest requested state without replaying intermediate acknowledgements.',
      reverse: 'Reverse from current interpolated value; do not jump to the original frame first.',
      focus_semantics_timing: 'Focus ownership changes only when the destination exists; state announcement follows committed local projection.',
      background_resume: 'Pause decorative progress offstage; recompute from durable truth on resume.',
      frame_resource_budget: 'No layout-wide repaint loop; warm transition targets a stable 60Hz frame budget and remains cancelable.',
    })),
  };
}

function assetRecord(id, source, classification, ownership, consumers, extra = {}) {
  const absolute = path.resolve(model.projectRoot, source);
  return {
    asset_id: id,
    classification,
    source_master: source.replaceAll('\\', '/'),
    ownership_license: ownership,
    export_tool: extra.export_tool || 'project source asset',
    dimensions_viewbox: extra.dimensions_viewbox || 'source-owned; inspected by Stage 04 specimen',
    transparent_bounds: extra.transparent_bounds || 'preserved; no synthetic black/white backing field',
    safe_zone: extra.safe_zone || 'consumer-specific semantic safe zone',
    optical_center: extra.optical_center || 'visually inspected; geometry center is baseline',
    anchor_crop: extra.anchor_crop || 'contain; never edge-crop meaningful geometry',
    theme_density_platform_variants: extra.variants || ['light', 'dark', 'Android', 'Windows'],
    compression_memory_budget: extra.budget || 'decode once; retain only consumer-size raster in memory',
    semantic_equivalent: extra.semantic || id,
    consumers,
    sha256: fs.existsSync(absolute) ? sha256File(absolute) : extra.sha256,
  };
}

async function main() {
  const gate = model.parseGate();
  const gateHash = sha256Text(gate.source);
  const chromePath = resolveChrome();
  const componentRoot = assertGeneratedTarget(model.componentRoot);
  const foundationRoot = assertGeneratedTarget(model.foundationRoot);
  const manifestRoot = assertGeneratedTarget(model.manifestRoot);

  resetGeneratedDirectory(componentRoot);
  resetGeneratedDirectory(foundationRoot);
  ensureDir(manifestRoot);

  const brand = {
    markPath: path.join(model.projectRoot, 'assets', 'brand', 'perfect-launcher.png'),
    wordmarkPath: path.join(model.projectRoot, 'assets', 'brand', 'perfect-wordmark.png'),
    wordmarkDarkPath: path.join(model.projectRoot, 'assets', 'brand', 'perfect-wordmark-dark.png'),
    latinFontPath: path.join(model.projectRoot, 'assets', 'fonts', 'PlusJakartaSans-Variable.ttf'),
    persianFontPath: path.join(model.projectRoot, 'assets', 'fonts', 'Vazirmatn-Variable.ttf'),
  };
  for (const file of Object.values(brand)) {
    if (!fs.existsSync(file)) throw new Error(`Required canonical asset missing: ${file}`);
  }
  const assets = {
    mark: fileDataUrl(brand.markPath, 'image/png'),
    wordmark: fileDataUrl(brand.wordmarkPath, 'image/png'),
    wordmarkDark: fileDataUrl(brand.wordmarkDarkPath, 'image/png'),
    fonts: {
      latin: fs.readFileSync(brand.latinFontPath).toString('base64'),
      persian: fs.readFileSync(brand.persianFontPath).toString('base64'),
    },
  };

  const iconRoot = path.join(foundationRoot, 'category-icons');
  ensureDir(iconRoot);
  const iconManifest = [];
  model.categoryIcons.forEach(([id, label, icon], index) => {
    const file = path.join(iconRoot, `${id}.svg`);
    fs.writeFileSync(file, `${categoryIconSvg(id, label, icon, index)}\n`, 'utf8');
    iconManifest.push({ id, label, lucide_icon: icon, file: relative(file), sha256: sha256File(file) });
  });
  const lucideRoot = path.dirname(require.resolve('lucide/package.json'));
  const lucideLicenseSource = path.join(lucideRoot, 'LICENSE');
  const lucideNotice = path.join(iconRoot, 'LUCIDE-ISC-LICENSE.txt');
  fs.copyFileSync(lucideLicenseSource, lucideNotice);

  console.log(`FOUNDATION_SETUP gate=${gateHash} components=${gate.componentRows.length} icons=${iconManifest.length}`);
  console.log(`RENDERER chrome=${chromePath}`);

  let browser;
  let page;
  const openRenderer = async () => {
    browser = await chromium.launch({ headless: true, executablePath: chromePath });
    page = await browser.newPage({ viewport: { width: 1200, height: 800 }, deviceScaleFactor: 1 });
  };
  const closeRenderer = async () => {
    if (page) await page.close().catch(() => undefined);
    if (browser) await browser.close().catch(() => undefined);
    page = undefined;
    browser = undefined;
  };
  const recycleRenderer = async () => {
    await closeRenderer();
    await openRenderer();
  };
  const renderTo = async (html, output) => {
    for (let attempt = 1; attempt <= 2; attempt += 1) {
      try {
        await capture(page, html, output);
        return;
      } catch (error) {
        if (attempt === 2) throw error;
        console.log(`RENDERER_RECOVERY file=${relative(output)} reason=${String(error.message || error).split('\n')[0]}`);
        await recycleRenderer();
      }
    }
  };
  await openRenderer();
  const foundationManifest = [];
  try {
    for (const foundation of model.foundations) {
      const directory = path.join(foundationRoot, foundation.id);
      ensureDir(directory);
      const anatomyFile = path.join(directory, 'anatomy.svg');
      const specimenFile = path.join(directory, 'specimen.png');
      const stressFile = path.join(directory, 'stress.png');
      fs.writeFileSync(anatomyFile, `${foundationsVisuals.foundationSvg(foundation)}\n`, 'utf8');
      await renderTo(foundationsVisuals.foundationDocument(foundation, assets, false), specimenFile);
      await renderTo(foundationsVisuals.foundationDocument(foundation, assets, true), stressFile);
      const hashes = {
        'anatomy.svg': sha256File(anatomyFile),
        'specimen.png': sha256File(specimenFile),
        'stress.png': sha256File(stressFile),
      };
      const contract = {
        foundation_id: foundation.id,
        catalog_version: model.catalogVersion,
        version: 1,
        title: foundation.title,
        purpose: foundation.purpose,
        semantic_owner: `Perfect foundation / ${foundation.id}`,
        required_themes: ['light', 'dark', 'high-contrast'],
        required_layouts: ['320 compact', '390 phone', '600 fold/tablet', '900 tablet', '1024 wide tablet', '1366 Windows', 'expanded Windows', 'short height + IME'],
        live_copy_boundary: 'Typography and interactive values remain live; brand wordmark alone is an accepted image asset.',
        fixture_boundary: 'Specimen values are design-only and unreachable from production persistence.',
        preview_files: Object.keys(hashes),
        preview_sha256: hashes,
      };
      const contractFile = path.join(directory, 'contract.yaml');
      writeJson(contractFile, contract);
      const record = {
        ...contract,
        contract: relative(contractFile),
        previews: Object.fromEntries(Object.keys(hashes).map((name) => [name, relative(path.join(directory, name))])),
        contract_sha256: sha256File(contractFile),
      };
      writeJson(path.join(directory, 'manifest.json'), record);
      foundationManifest.push(record);
      console.log(`FOUNDATION ${foundation.id} pass`);
    }

    await recycleRenderer();
    const componentManifest = [];
    for (let index = 0; index < gate.componentRows.length; index += 1) {
      if (index > 0 && index % 8 === 0) await recycleRenderer();
      const component = gate.componentRows[index];
      const family = model.familyFor(component.id);
      const directory = path.join(componentRoot, family, component.id);
      ensureDir(directory);
      const anatomyFile = path.join(directory, 'anatomy.svg');
      fs.writeFileSync(anatomyFile, `${visuals.anatomySvg(component, assets)}\n`, 'utf8');

      const previewHashes = { 'anatomy.svg': sha256File(anatomyFile) };
      for (const kind of previewKinds) {
        const file = path.join(directory, `${kind}.png`);
        const renderingAssets = kind === 'states-dark'
          ? { ...assets, wordmark: assets.wordmarkDark }
          : assets;
        await renderTo(visuals.documentHtml(visuals.boardHtml(component, kind), renderingAssets), file);
        previewHashes[`${kind}.png`] = sha256File(file);
      }

      const contract = model.contractFor(component);
      contract.preview_sha256 = previewHashes;
      const contractFile = path.join(directory, 'contract.yaml');
      writeJson(contractFile, contract);
      componentManifest.push({
        component_id: component.id,
        title: model.titleFor(component.id),
        family,
        family_title: model.familyMeta[family][0],
        purpose: component.description,
        contract: relative(contractFile),
        contract_sha256: sha256File(contractFile),
        previews: Object.fromEntries(Object.keys(previewHashes).map((name) => [name, relative(path.join(directory, name))])),
        preview_sha256: previewHashes,
        render_layer_classification: family === 'id' ? 'hybrid/build-time brand layer plus live semantics' : 'live semantic component over token/vector material',
        consumers: contract.consumers,
        fixture_boundary: contract.fixture_boundary,
        metadata: {
          logical_viewport: 'board-specific phone/tablet/Windows scenarios',
          physical_export: '1200x800',
          device_pixel_ratio: 1,
          text_scale: ['100%', '200% stress'],
          locale_direction: ['en-LTR', 'fa-RTL', 'mixed isolated'],
          theme: ['light', 'dark', 'high-contrast stress'],
          preview_version: 1,
        },
      });
      if ((index + 1) % 10 === 0 || index + 1 === gate.componentRows.length) {
        console.log(`COMPONENT_PROGRESS ${index + 1}/${gate.componentRows.length} latest=${component.id}`);
      }
    }

    const familyGroups = new Map();
    for (const component of componentManifest) {
      if (!familyGroups.has(component.family)) familyGroups.set(component.family, []);
      familyGroups.get(component.family).push(component);
    }
    const familySheets = {};
    for (const [family, components] of familyGroups.entries()) {
      const file = path.join(componentRoot, family, `${family}-contact-sheet.png`);
      const result = await makeContactSheet(
        components.map((component) => ({
          id: component.component_id,
          subtitle: 'states-light',
          file: path.resolve(model.projectRoot, component.previews['states-light.png']),
        })),
        file,
        { columns: components.length >= 9 ? 4 : 3, tileWidth: 300, tileHeight: 220 },
      );
      familySheets[family] = { file: relative(file), count: components.length, ...result };
      console.log(`CONTACT_FAMILY ${family} count=${components.length}`);
    }

    const masterSheet = path.join(componentRoot, 'stage04-component-catalog-contact-sheet.png');
    const masterSheetMeta = await makeContactSheet(
      componentManifest.map((component) => ({
        id: component.component_id,
        subtitle: component.family,
        file: path.resolve(model.projectRoot, component.previews['neighbor-plate.png']),
      })),
      masterSheet,
      { columns: 5, tileWidth: 300, tileHeight: 220, gutter: 12, padding: 20 },
    );

    const foundationSheet = path.join(foundationRoot, 'stage04-foundations-contact-sheet.png');
    const foundationSheetMeta = await makeContactSheet(
      foundationManifest.map((foundation) => ({
        id: foundation.foundation_id,
        subtitle: 'specimen',
        file: path.resolve(model.projectRoot, foundation.previews['specimen.png']),
      })),
      foundationSheet,
      { columns: 3, tileWidth: 390, tileHeight: 280, gutter: 16, padding: 22 },
    );

    const foundationsFile = path.join(manifestRoot, 'foundations.json');
    writeJson(foundationsFile, {
      catalog_version: model.catalogVersion,
      generated_at: model.generatedAt,
      gate_source: relative(model.gatePath),
      gate_sha256: gateHash,
      exact_foundation_count: foundationManifest.length,
      foundations: foundationManifest,
      category_icon_archive: {
        count: iconManifest.length,
        license_notice: relative(lucideNotice),
        license_sha256: sha256File(lucideNotice),
        icons: iconManifest,
      },
      contact_sheet: { file: relative(foundationSheet), ...foundationSheetMeta },
    });

    const componentsFile = path.join(manifestRoot, 'components.json');
    writeJson(componentsFile, {
      catalog_version: model.catalogVersion,
      generated_at: model.generatedAt,
      design_direction: model.tokens.direction,
      gate_source: relative(model.gatePath),
      gate_sha256: gateHash,
      exact_component_count: componentManifest.length,
      exact_family_count: familyGroups.size,
      exact_preview_count: componentManifest.length * 7,
      canonical_preview_files_per_component: ['anatomy.svg', ...previewKinds.map((kind) => `${kind}.png`)],
      fixture_boundary: 'All preview names, dates, counts and planner entries are design-only and unreachable from production persistence.',
      production_boundary: 'No Flutter, native, domain, database, auth or sync source is generated or mutated by this catalog.',
      family_contact_sheets: familySheets,
      master_contact_sheet: { file: relative(masterSheet), ...masterSheetMeta },
      components: componentManifest,
    });

    const assetsFile = path.join(manifestRoot, 'assets.json');
    const assetRecords = [
      assetRecord('brand-perfect-launcher', 'assets/brand/perfect-launcher.png', 'build-time/raster', 'Project-owned private Perfect! brand asset', ['launcher', 'splash', 'header mark', 'widget']),
      assetRecord('brand-perfect-wordmark-light', 'assets/brand/perfect-wordmark.png', 'raster', 'Project-owned private Perfect! selected typography', ['light header', 'identity previews']),
      assetRecord('brand-perfect-wordmark-dark', 'assets/brand/perfect-wordmark-dark.png', 'raster', 'Project-owned private Perfect! selected typography', ['dark header', 'identity previews']),
      assetRecord('type-plus-jakarta-variable', 'assets/fonts/PlusJakartaSans-Variable.ttf', 'live font', 'SIL Open Font License; see assets/fonts/OFL-PlusJakartaSans.txt', ['all Latin live copy'], { semantic: 'Perfect Jakarta live typography roles' }),
      assetRecord('type-vazirmatn-variable', 'assets/fonts/Vazirmatn-Variable.ttf', 'live font', 'SIL Open Font License; see assets/fonts/OFL-Vazirmatn.txt', ['all Persian and mixed-script live copy'], { semantic: 'Perfect Vazirmatn live typography roles' }),
      ...iconManifest.map((icon) => ({
        asset_id: `category-${icon.id}`,
        classification: 'vector',
        source_master: icon.file,
        ownership_license: `Lucide ${icon.lucene_icon || icon.lucide_icon} source geometry under ISC; Perfect optical two-stroke export`,
        export_tool: 'tool/generate_stage04_design_system.cjs',
        dimensions_viewbox: '512x512 / viewBox 0 0 512 512',
        transparent_bounds: 'transparent canvas; no white or black backing',
        safe_zone: '56 logical px minimum; decorative status dot remains inside bounds',
        optical_center: 'geometry-centered with category-specific Lucide balance retained',
        anchor_crop: 'contain; no crop',
        theme_density_platform_variants: ['semantic foreground role', '16', '20', '24', '32', '48'],
        compression_memory_budget: 'SVG parse/cache once; rasterize only at consumer size',
        semantic_equivalent: icon.label,
        consumers: ['category selector', 'task/habit row', 'detail', 'widget where supported'],
        sha256: icon.sha256,
      })),
    ];
    writeJson(assetsFile, {
      catalog_version: model.catalogVersion,
      generated_at: model.generatedAt,
      layer_policy: {
        live: 'Dynamic text, controls, planner data and critical/system copy remain semantic and editable.',
        vector: 'Versioned SVG geometry for categories and authored visual language.',
        raster: 'Only selected brand art and inspected graphic masters.',
        hybrid: 'Live semantic control over authored token/vector/raster material.',
        build_time: 'Launcher, splash, ICO and widget exports remain reproducible.',
      },
      exact_asset_count: assetRecords.length,
      assets: assetRecords,
    });

    const motionFile = path.join(manifestRoot, 'motion.json');
    writeJson(motionFile, motionManifest());

    const registryFile = path.join(manifestRoot, 'stage04-registry.json');
    writeJson(registryFile, {
      catalog_version: model.catalogVersion,
      generated_at: model.generatedAt,
      direction: model.tokens.direction,
      gate_sha256: gateHash,
      counts: {
        foundations: foundationManifest.length,
        components: componentManifest.length,
        families: familyGroups.size,
        component_previews: componentManifest.length * 7,
        category_icons: iconManifest.length,
        motions: model.motionBible.families.length,
      },
      manifests: [foundationsFile, componentsFile, assetsFile, motionFile].map(relative),
      generator: relative(__filename),
      renderer: { engine: 'Playwright', browser: path.basename(chromePath), viewport: '1200x800@1x' },
      acceptance: 'Design-only Stage 04 corpus. Stage 05 page composition must consume these stable IDs and hashes before runtime implementation.',
    });

    const generatedFiles = [];
    for (const root of [foundationRoot, componentRoot]) {
      const visit = (directory) => {
        for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
          const absolute = path.join(directory, entry.name);
          if (entry.isDirectory()) visit(absolute);
          else generatedFiles.push(absolute);
        }
      };
      visit(root);
    }
    for (const file of [foundationsFile, componentsFile, assetsFile, motionFile, registryFile]) generatedFiles.push(file);
    generatedFiles.sort((a, b) => relative(a).localeCompare(relative(b)));
    const hashesFile = path.join(manifestRoot, 'stage04-hashes.sha256');
    fs.writeFileSync(
      hashesFile,
      `${generatedFiles.map((file) => `${sha256File(file)}  ${relative(file)}`).join('\n')}\n`,
      'utf8',
    );

    console.log(`STAGE04_GENERATION_PASS foundations=${foundationManifest.length} components=${componentManifest.length} previews=${componentManifest.length * 7} icons=${iconManifest.length} motions=${model.motionBible.families.length}`);
    console.log(`STAGE04_HASH_MANIFEST ${relative(hashesFile)} entries=${generatedFiles.length}`);
  } finally {
    await closeRenderer();
  }
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
