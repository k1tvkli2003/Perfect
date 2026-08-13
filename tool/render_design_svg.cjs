const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const { chromium } = require('playwright');

function findBrowserExecutable() {
  const candidates = [
    process.env.PERFECT_DESIGN_BROWSER,
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  ].filter(Boolean);
  return candidates.find((candidate) => fs.existsSync(candidate));
}

async function main() {
  const [inputArg, outputArg, widthArg, heightArg] = process.argv.slice(2);
  if (!inputArg || !outputArg || !widthArg || !heightArg) {
    throw new Error(
      'Usage: node tool/render_design_svg.cjs <input.svg> <output.png> <width> <height>',
    );
  }

  const input = path.resolve(inputArg);
  const output = path.resolve(outputArg);
  const width = Number.parseInt(widthArg, 10);
  const height = Number.parseInt(heightArg, 10);

  if (!fs.existsSync(input) || path.extname(input).toLowerCase() !== '.svg') {
    throw new Error(`Input SVG not found: ${input}`);
  }
  if (!Number.isInteger(width) || !Number.isInteger(height) || width < 1 || height < 1) {
    throw new Error(`Invalid viewport: ${widthArg}x${heightArg}`);
  }

  fs.mkdirSync(path.dirname(output), { recursive: true });
  const executablePath = findBrowserExecutable();
  const browser = await chromium.launch({
    headless: true,
    ...(executablePath ? { executablePath } : {}),
  });
  try {
    const page = await browser.newPage({
      viewport: { width, height },
      deviceScaleFactor: 1,
    });
    await page.goto(pathToFileURL(input).href, { waitUntil: 'load' });
    const documentState = await page.evaluate(() => ({
      rootTag: document.documentElement?.tagName?.toLowerCase() ?? '',
      parserErrorCount: document.querySelectorAll('parsererror').length,
      bodyText: document.body?.innerText?.slice(0, 240) ?? '',
    }));
    if (
      documentState.rootTag !== 'svg' ||
      documentState.parserErrorCount > 0 ||
      documentState.bodyText.includes('This page contains the following errors:')
    ) {
      throw new Error(
        `SVG parse failure for ${input}: root=${documentState.rootTag} parserErrors=${documentState.parserErrorCount} ${documentState.bodyText}`,
      );
    }
    await page.screenshot({ path: output, fullPage: false });
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
