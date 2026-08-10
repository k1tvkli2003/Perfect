#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { chromium } = require('playwright');

const model = require('./page_catalog_model.cjs');
const visuals = require('./page_catalog_visuals.cjs');

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith('--')) continue;
    result[token.slice(2)] = argv[index + 1];
    index += 1;
  }
  return result;
}

function resolveChrome() {
  const candidates = [
    process.env.PERFECT_CHROME_PATH,
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  ].filter(Boolean);
  const found = candidates.find((candidate) => fs.existsSync(candidate));
  if (!found) throw new Error('No local Chrome/Edge executable is available for Stage 05 smoke rendering.');
  return found;
}

function fileDataUrl(file, mime) {
  return `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
}

function assets() {
  return {
    mark: fileDataUrl(path.join(model.projectRoot, 'assets', 'brand', 'perfect-launcher.png'), 'image/png'),
    wordmark: fileDataUrl(path.join(model.projectRoot, 'assets', 'brand', 'perfect-wordmark.png'), 'image/png'),
    wordmarkDark: fileDataUrl(path.join(model.projectRoot, 'assets', 'brand', 'perfect-wordmark-dark.png'), 'image/png'),
    fonts: {
      latin: fs.readFileSync(path.join(model.projectRoot, 'assets', 'fonts', 'PlusJakartaSans-Variable.ttf')).toString('base64'),
      persian: fs.readFileSync(path.join(model.projectRoot, 'assets', 'fonts', 'Vazirmatn-Variable.ttf')).toString('base64'),
    },
  };
}

async function inspect(page) {
  return page.evaluate(() => {
    const selectors = [
      '.perfect-app', '.app-canvas', '.glass-header', '.page-scroll', '.phone-footer',
      '.capture-orb', '.today-stack', '.stream-section', '.workspace-ledger',
      '.wizard-shell', '.wizard-main', '.schedule-panel', '.schedule-slots',
      '.ai-layout', '.conversation', '.settings-layout',
    ];
    const specimen = (selector) => {
      const element = document.querySelector(selector);
      if (!element) return null;
      const rect = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      return {
        selector,
        rect: {
          left: Number(rect.left.toFixed(2)),
          top: Number(rect.top.toFixed(2)),
          right: Number(rect.right.toFixed(2)),
          bottom: Number(rect.bottom.toFixed(2)),
          width: Number(rect.width.toFixed(2)),
          height: Number(rect.height.toFixed(2)),
        },
        display: style.display,
        visibility: style.visibility,
        opacity: style.opacity,
        color: style.color,
        overflowX: style.overflowX,
        overflowY: style.overflowY,
        zIndex: style.zIndex,
        scrollWidth: element.scrollWidth,
        clientWidth: element.clientWidth,
        scrollHeight: element.scrollHeight,
        clientHeight: element.clientHeight,
      };
    };
    const overflow = [...document.querySelectorAll('#root button, #root article, #root section, #root header, #root footer, #root main, #root aside')]
      .map((element) => {
        const rect = element.getBoundingClientRect();
        return {
          element,
          rect,
          label: element.className || element.tagName.toLowerCase(),
          text: (element.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 72),
        };
      })
      .filter(({ rect }) => rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.top < innerHeight)
      .filter(({ rect }) => rect.left < -1 || rect.right > innerWidth + 1)
      .slice(0, 30)
      .map(({ rect, label, text }) => ({
        label,
        text,
        left: Number(rect.left.toFixed(2)),
        right: Number(rect.right.toFixed(2)),
        width: Number(rect.width.toFixed(2)),
      }));
    const textSamples = ['.page-title-cluster h1', '.ai-layout h2', '.ai-layout p', '.wizard-main h2', '.workspace-ledger h2']
      .map((selector) => {
        const element = document.querySelector(selector);
        if (!element) return null;
        const style = getComputedStyle(element);
        return { selector, text: element.textContent.trim(), color: style.color, fontFamily: style.fontFamily, fontSize: style.fontSize, fontWeight: style.fontWeight };
      })
      .filter(Boolean);
    return {
      viewport: { width: innerWidth, height: innerHeight },
      document: { scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight },
      specimens: selectors.map(specimen).filter(Boolean),
      horizontalOverflow: overflow,
      textSamples,
      bottomCenterStack: document.elementsFromPoint(innerWidth / 2, innerHeight - 28).slice(0, 6).map((element) => element.className || element.tagName.toLowerCase()),
    };
  });
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const pageId = args.page || 'pg-today-normal';
  const variantFile = args.variant || 'phone-compact.png';
  const catalog = model.buildCatalog();
  const pageSpec = catalog.pages.find((entry) => entry.page_id === pageId);
  const variant = model.canonicalVariants.find((entry) => entry.file === variantFile);
  if (!pageSpec) throw new Error(`Unknown page id: ${pageId}`);
  if (!variant) throw new Error(`Unknown canonical variant: ${variantFile}`);
  const output = path.resolve(args.output || path.join(model.projectRoot, '.codex-tmp', 'stage05-smoke', `${pageId}-${variantFile}`));
  const diagnostics = output.replace(/\.png$/i, '.json');
  fs.mkdirSync(path.dirname(output), { recursive: true });

  const browser = await chromium.launch({
    executablePath: resolveChrome(),
    headless: true,
    args: ['--disable-gpu', '--hide-scrollbars', '--font-render-hinting=none'],
  });
  try {
    const browserPage = await browser.newPage({ viewport: { width: variant.width, height: variant.height }, deviceScaleFactor: 1 });
    await browserPage.setContent(visuals.canonicalHtml(pageSpec, variant, assets()), { waitUntil: 'load' });
    await browserPage.evaluate(async () => {
      await document.fonts.ready;
      await Promise.all([...document.images].map((image) => image.decode().catch(() => undefined)));
    });
    await browserPage.screenshot({ path: output, type: 'png', animations: 'disabled', caret: 'hide', omitBackground: false });
    const optimized = await sharp(output).png({ compressionLevel: 9, adaptiveFiltering: true }).toBuffer();
    fs.writeFileSync(output, optimized);
    const report = await inspect(browserPage);
    const result = { page_id: pageId, scenario_id: `scn-${pageId.slice(3)}-${variantFile.replace('.png', '')}`, variant, screenshot: output, ...report };
    fs.writeFileSync(diagnostics, `${JSON.stringify(result, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(result));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
