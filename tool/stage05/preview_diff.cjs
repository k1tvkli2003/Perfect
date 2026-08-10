#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

function ensureDir(directory) {
  fs.mkdirSync(directory, { recursive: true });
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writeJson(file, value) {
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

function relativeDifference(left, right) {
  if (typeof left !== 'number' || typeof right !== 'number') return left === right ? 0 : 1;
  return Math.abs(left - right) / Math.max(1, Math.abs(left));
}

function compareMetadata(reference, runtime) {
  const mismatches = [];
  const identify = (category, severity, field, expected, actual, threshold, note) => {
    if (relativeDifference(expected, actual) <= threshold) return;
    mismatches.push({ category, severity, field, expected, actual, note });
  };

  if (reference.page_id !== runtime.page_id) {
    mismatches.push({
      category: 'route',
      severity: 'P0',
      field: 'page_id',
      expected: reference.page_id,
      actual: runtime.page_id,
      note: 'Runtime rendered a different semantic surface.',
    });
  }
  if (reference.scenario_id !== runtime.scenario_id) {
    mismatches.push({
      category: 'state',
      severity: 'P1',
      field: 'scenario_id',
      expected: reference.scenario_id,
      actual: runtime.scenario_id,
      note: 'Reference and runtime state fixtures are not comparable.',
    });
  }

  for (const [landmark, expected] of Object.entries(reference.landmarks || {})) {
    const actual = (runtime.landmarks || {})[landmark];
    if (!actual) {
      mismatches.push({ category: 'geometry', severity: 'P1', field: `landmarks.${landmark}`, expected, actual: null, note: 'Required landmark is absent.' });
      continue;
    }
    for (const field of ['x', 'y', 'width', 'height']) {
      identify('geometry', 'P2', `landmarks.${landmark}.${field}`, expected[field], actual[field], 0.012, 'Normalized bounds drift beyond the 1.2% Stage 05 tolerance.');
    }
  }

  for (const [role, expected] of Object.entries(reference.typography || {})) {
    const actual = (runtime.typography || {})[role];
    if (!actual) {
      mismatches.push({ category: 'typography', severity: 'P1', field: `typography.${role}`, expected, actual: null, note: 'Required live type role is absent.' });
      continue;
    }
    identify('typography', 'P2', `typography.${role}.size`, expected.size, actual.size, 0.02, 'Live type scale drift changes hierarchy.');
    identify('typography', 'P2', `typography.${role}.line_height`, expected.line_height, actual.line_height, 0.025, 'Line-height drift changes block rhythm.');
    if (expected.family !== actual.family || expected.weight !== actual.weight) {
      mismatches.push({ category: 'typography', severity: 'P2', field: `typography.${role}.family_weight`, expected: `${expected.family}/${expected.weight}`, actual: `${actual.family}/${actual.weight}`, note: 'Font identity or weight does not match the frozen live type role.' });
    }
  }

  for (const [key, expected] of Object.entries(reference.system_state || {})) {
    const actual = (runtime.system_state || {})[key];
    if (expected !== actual) {
      mismatches.push({ category: 'state', severity: 'P1', field: `system_state.${key}`, expected, actual, note: 'Runtime state meaning differs from the exact frozen scenario.' });
    }
  }

  return mismatches;
}

async function normalizedPixels(file, width, height) {
  return sharp(file)
    .resize(width, height, { fit: 'fill' })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
}

async function renderPixelEvidence(referenceFile, runtimeFile, outputRoot) {
  const referenceMeta = await sharp(referenceFile).metadata();
  const runtimeMeta = await sharp(runtimeFile).metadata();
  const width = referenceMeta.width;
  const height = referenceMeta.height;
  if (!width || !height || !runtimeMeta.width || !runtimeMeta.height) throw new Error('Comparison requires decodable raster dimensions.');
  ensureDir(outputRoot);
  const referenceOutput = path.join(outputRoot, 'reference.png');
  const runtimeOutput = path.join(outputRoot, 'runtime.png');
  await sharp(referenceFile).resize(width, height, { fit: 'fill' }).png({ compressionLevel: 9 }).toFile(referenceOutput);
  await sharp(runtimeFile).resize(width, height, { fit: 'fill' }).png({ compressionLevel: 9 }).toFile(runtimeOutput);

  const runtimeOverlay = await sharp(runtimeOutput).ensureAlpha().toBuffer();
  await sharp(referenceOutput)
    .composite([{ input: runtimeOverlay, blend: 'over', opacity: 0.5 }])
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(path.join(outputRoot, 'overlay.png'));

  const left = await normalizedPixels(referenceOutput, width, height);
  const right = await normalizedPixels(runtimeOutput, width, height);
  const diff = Buffer.alloc(left.data.length);
  let changedPixels = 0;
  let absoluteDelta = 0;
  let maximumChannelDelta = 0;
  for (let offset = 0; offset < left.data.length; offset += 3) {
    let pixelChanged = false;
    for (let channel = 0; channel < 3; channel += 1) {
      const delta = Math.abs(left.data[offset + channel] - right.data[offset + channel]);
      absoluteDelta += delta;
      maximumChannelDelta = Math.max(maximumChannelDelta, delta);
      if (delta > 8) pixelChanged = true;
      diff[offset + channel] = Math.min(255, delta * 4);
    }
    if (pixelChanged) changedPixels += 1;
  }
  await sharp(diff, { raw: { width, height, channels: 3 } })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(path.join(outputRoot, 'diff.png'));
  return {
    width,
    height,
    changed_pixels: changedPixels,
    changed_ratio: changedPixels / (width * height),
    mean_channel_delta: absoluteDelta / left.data.length,
    maximum_channel_delta: maximumChannelDelta,
  };
}

function mismatchMarkdown(reference, runtime, mismatches, pixels) {
  const rows = mismatches.length === 0
    ? '| none | — | — | exact normalized match |'
    : mismatches.map((entry) => `| ${entry.severity} | ${entry.category} | \`${entry.field}\` | expected \`${JSON.stringify(entry.expected)}\`; actual \`${JSON.stringify(entry.actual)}\` — ${entry.note} |`).join('\n');
  return `# Preview/runtime mismatch\n\n- Preview: \`${reference.preview_id}\`\n- Page: \`${reference.page_id}\`\n- Scenario: \`${reference.scenario_id}\`\n- Runtime page/scenario: \`${runtime.page_id}\` / \`${runtime.scenario_id}\`\n- Normalized raster: \`${pixels.width}×${pixels.height}\`\n- Changed pixels: \`${pixels.changed_pixels}\` (${(pixels.changed_ratio * 100).toFixed(4)}%)\n- Mean/max channel delta: \`${pixels.mean_channel_delta.toFixed(4)}\` / \`${pixels.maximum_channel_delta}\`\n\n| Severity | Category | Field | Evidence |\n| --- | --- | --- | --- |\n${rows}\n\nThe harness names the exact preview, page, state and field. A non-zero mismatch is not acceptance; later runtime stages must correct it or record a proven adaptive/platform exception.\n`;
}

async function comparePreview(options) {
  const reference = readJson(options.referenceMeta);
  const runtime = readJson(options.runtimeMeta);
  const mismatches = compareMetadata(reference, runtime);
  const pixels = await renderPixelEvidence(options.reference, options.runtime, options.output);
  const result = {
    preview_id: reference.preview_id,
    page_id: reference.page_id,
    scenario_id: reference.scenario_id,
    runtime_page_id: runtime.page_id,
    runtime_scenario_id: runtime.scenario_id,
    mismatch_count: mismatches.length,
    categories: [...new Set(mismatches.map((entry) => entry.category))].sort(),
    mismatches,
    pixels,
  };
  writeJson(path.join(options.output, 'comparison.json'), result);
  fs.writeFileSync(path.join(options.output, 'mismatch.md'), mismatchMarkdown(reference, runtime, mismatches, pixels), 'utf8');
  return result;
}

function cliOptions(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === '--fail-on-mismatch') options.failOnMismatch = true;
    else if (value.startsWith('--')) options[value.slice(2)] = argv[++index];
  }
  for (const field of ['reference', 'runtime', 'reference-meta', 'runtime-meta', 'output']) {
    if (!options[field]) throw new Error(`Missing --${field}.`);
  }
  return {
    reference: path.resolve(options.reference),
    runtime: path.resolve(options.runtime),
    referenceMeta: path.resolve(options['reference-meta']),
    runtimeMeta: path.resolve(options['runtime-meta']),
    output: path.resolve(options.output),
    failOnMismatch: Boolean(options.failOnMismatch),
  };
}

async function main() {
  const options = cliOptions(process.argv.slice(2));
  const result = await comparePreview(options);
  const message = `PREVIEW_DIFF page=${result.page_id} scenario=${result.scenario_id} mismatches=${result.mismatch_count} categories=${result.categories.join(',') || 'none'} changed=${(result.pixels.changed_ratio * 100).toFixed(4)}%`;
  console.log(message);
  if (options.failOnMismatch && result.mismatch_count > 0) process.exitCode = 2;
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.stack || error);
    process.exitCode = 1;
  });
}

module.exports = {
  compareMetadata,
  renderPixelEvidence,
  comparePreview,
};
