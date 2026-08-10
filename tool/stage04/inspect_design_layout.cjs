#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const model = require('./design_catalog_model.cjs');
const visuals = require('./design_catalog_visuals.cjs');

function dataUrl(file, mime) {
  return `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
}

async function main() {
  const id = process.argv[2] || 'cap-expanded-shell';
  const kind = process.argv[3] || 'responsive';
  const component = model.parseGate().componentRows.find((candidate) => candidate.id === id);
  if (!component) throw new Error(`Unknown component: ${id}`);
  const root = model.projectRoot;
  const assets = {
    mark: dataUrl(path.join(root, 'assets/brand/perfect-launcher.png'), 'image/png'),
    wordmark: dataUrl(path.join(root, kind === 'states-dark' ? 'assets/brand/perfect-wordmark-dark.png' : 'assets/brand/perfect-wordmark.png'), 'image/png'),
    fonts: {
      latin: fs.readFileSync(path.join(root, 'assets/fonts/PlusJakartaSans-Variable.ttf')).toString('base64'),
      persian: fs.readFileSync(path.join(root, 'assets/fonts/Vazirmatn-Variable.ttf')).toString('base64'),
    },
  };
  const chrome = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const browser = await chromium.launch({ headless: true, executablePath: chrome });
  const page = await browser.newPage({ viewport: { width: 1200, height: 800 }, deviceScaleFactor: 1 });
  await page.setContent(visuals.documentHtml(visuals.boardHtml(component, kind), assets));
  await page.evaluate(() => document.fonts.ready);
  const result = await page.evaluate(() => {
    const rect = (element) => {
      const value = element.getBoundingClientRect();
      return {
        x: Math.round(value.x * 10) / 10,
        y: Math.round(value.y * 10) / 10,
        width: Math.round(value.width * 10) / 10,
        height: Math.round(value.height * 10) / 10,
        right: Math.round(value.right * 10) / 10,
        bottom: Math.round(value.bottom * 10) / 10,
      };
    };
    const containers = [...document.querySelectorAll('.state-grid article,.responsive-grid .device,.motion-grid article,.a11y-grid article')];
    return {
      boardHeader: {
        rect: rect(document.querySelector('.board-header')),
        text: document.querySelector('.board-header').innerText,
        color: getComputedStyle(document.querySelector('.board-header')).color,
        opacity: getComputedStyle(document.querySelector('.board-header')).opacity,
      },
      containers: containers.map((container) => {
        const demo = container.querySelector('.demo');
        const outer = rect(container);
        const inner = demo ? rect(demo) : null;
        return {
          label: container.querySelector('label')?.innerText || '',
          outer,
          inner,
          fits: !inner || (inner.x >= outer.x - 1 && inner.right <= outer.right + 1 && inner.y >= outer.y - 1 && inner.bottom <= outer.bottom + 1),
        };
      }),
    };
  });
  console.log(JSON.stringify(result, null, 2));
  await browser.close();
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
