#!/usr/bin/env node

const assert = require('assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const brand = path.join(root, 'assets', 'brand');
const sources = {
  highContrastLight: {
    source: 'orbit_period_ring_light.svg',
    expectedSourceHash: '341fe4eb382ee76ef49ff00ce85530bd5cc18208252f1ecb646c2bc7e8b87e34',
    output: 'orbit_period_ring_hc_light.svg',
    map: {
      '#4C8D69': '#145D34', '#4F9B72': '#145D34', '#5F4B3C': '#090A0F',
      '#68579E': '#3E2A82', '#8CCFAB': '#6DBD8A', '#9F8DD5': '#9B87DD',
      '#A7DDBF': '#77C696', '#B96D32': '#6D2E00', '#B9A9E4': '#B8A8EF',
      '#B9E5CF': '#A7DDBB', '#C9BCEC': '#CCBFF7', '#D7CCF5': '#DED4FF',
      '#D8CFC5': '#4A4B55', '#DAF3E5': '#E8F8EE', '#EEE6DC': '#D9D9DF',
      '#F7AA5C': '#F39A49', '#F8F2EA': '#E8E8EC', '#FFC17C': '#FFB36D',
      '#FFD3A0': '#FFD1A3', '#FFE0B8': '#FFF0E1', '#FFFDF9': '#FFFFFF',
      '#FFFFFF': '#FFFFFF',
    },
  },
  highContrastDark: {
    source: 'orbit_period_ring_dark.svg',
    expectedSourceHash: 'c4f5968ae8f2a55319e1749c920735001e90fab8f6edcdf4944882c71b95f4fd',
    output: 'orbit_period_ring_hc_dark.svg',
    map: {
      '#07110B': '#001308', '#090A11': '#000000', '#0D091A': '#11092F',
      '#160B04': '#100700', '#202330': '#000000', '#2A2E40': '#08090D',
      '#34384C': '#171922', '#565C75': '#FFFFFF', '#6DB78D': '#57B678',
      '#70768F': '#A6A6B0', '#747A94': '#FFFFFF', '#7FC29B': '#75D497',
      '#806FB9': '#8F79E2', '#91CEAA': '#89E4A7', '#9D8BD3': '#A793F0',
      '#B5A6E2': '#C5B7FF', '#BCE4CD': '#AEF2C4', '#C8BAEE': '#DED4FF',
      '#C8EBD5': '#E2FFEA', '#D98745': '#D9853E', '#DDF5E6': '#E2FFEA',
      '#E2DBFA': '#F4F0FF', '#E5DEFB': '#F4F0FF', '#F4A861': '#FFAD63',
      '#FBC080': '#FFBD7C', '#FFD19B': '#FFD1A3', '#FFE2BE': '#FFF0DF',
      '#FFE5C4': '#FFF0DF', '#FFFFFF': '#FFFFFF',
    },
  },
};

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function colours(source) {
  return [...new Set(source.match(/#[0-9A-F]{6}/g) ?? [])].sort();
}

const outputs = [];
for (const [theme, spec] of Object.entries(sources)) {
  const sourcePath = path.join(brand, spec.source);
  const sourceBytes = fs.readFileSync(sourcePath);
  assert.equal(sha256(sourceBytes), spec.expectedSourceHash, `${spec.source} drifted`);
  const source = sourceBytes.toString('utf8').replace(/\r\n/g, '\n');
  assert.deepEqual(colours(source), Object.keys(spec.map).sort(), `${theme} colour map coverage`);
  const transformed = source.replace(/#[0-9A-F]{6}/g, (colour) => spec.map[colour]);
  assert.ok(!transformed.includes('filter='), `${theme} must not depend on SVG blur filters`);
  assert.equal((transformed.match(/stroke-width="(?:70|78|80|82|84)"/g) ?? []).length >= 10, true);
  const outputPath = path.join(brand, spec.output);
  fs.writeFileSync(outputPath, transformed, 'utf8');
  outputs.push({
    theme,
    path: path.relative(root, outputPath).replaceAll('\\', '/'),
    source: path.relative(root, sourcePath).replaceAll('\\', '/'),
    source_sha256: spec.expectedSourceHash,
    sha256: sha256(Buffer.from(transformed, 'utf8')),
    mapped_colours: Object.keys(spec.map).length,
    structural_contract: 'three positioned period arcs plus neutral remainder with explicit inner and outer boundaries',
  });
}

const manifest = {
  schema_version: 1,
  identity: 'Perfect! authored orbit period ring theme assets',
  high_contrast_contract: {
    blur_filters: false,
    position_is_non_colour_cue: true,
    explicit_inner_outer_boundaries: true,
    live_arc_copy_remains_semantic_flutter_text: true,
  },
  outputs,
};
fs.writeFileSync(
  path.join(brand, 'orbit-period-ring-manifest.json'),
  `${JSON.stringify(manifest, null, 2)}\n`,
  'utf8',
);
console.log(`ORBIT_THEME_ASSETS_PASS variants=${outputs.length} mapped=${outputs.reduce((sum, entry) => sum + entry.mapped_colours, 0)}`);
