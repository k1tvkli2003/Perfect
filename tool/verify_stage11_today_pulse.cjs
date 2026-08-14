#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const outputRoot = path.join(
  projectRoot,
  'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/05-runtime-comparisons/stage11-today-pulse',
);

function fail(message) {
  throw new Error(`Stage 11 verification failed: ${message}`);
}

function readJson(name) {
  return JSON.parse(fs.readFileSync(path.join(outputRoot, name), 'utf8'));
}

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

const manifest = readJson('preview-manifest.json');
const layout = readJson('layout-contract.json');
const decomposition = readJson('decomposition-manifest.json');
const runtime = readJson('runtime/android/runtime-manifest.json');

if (manifest.stage !== 11 || manifest.concept_id !== 'today-pulse-dayline-v2') {
  fail('manifest identity drift');
}
if (manifest.board_count !== 8) fail(`expected 8 boards, got ${manifest.board_count}`);
if (layout.semantic_component_id !== 'td-pulse') fail('td-pulse is not the semantic owner');
if (layout.decisions.circular_model !== 'removed') fail('circular model must be removed');
for (const forbidden of ['ring progress', 'clock-face labels', 'heartbeat orbit', 'duplicated next task title', 'metric card grid']) {
  if (!layout.decisions.forbidden.includes(forbidden)) fail(`missing forbidden contract: ${forbidden}`);
}
for (const state of ['empty', 'all-complete', 'missed-only', 'habits-only', 'unscheduled-only', 'syncing', 'offline', 'retry-error']) {
  if (!layout.state_matrix.includes(state)) fail(`missing state: ${state}`);
}
if (!decomposition.live_layers.includes('Gregorian and Jalali dates with direction isolation')) {
  fail('dual-date live ownership missing');
}
if (!decomposition.authored_layers.includes('semantic linear Dayline stroke')) {
  fail('authored Dayline missing');
}

for (const entry of manifest.files) {
  const file = path.join(projectRoot, entry.file);
  if (!fs.existsSync(file)) fail(`missing file: ${entry.file}`);
  const stat = fs.statSync(file);
  if (stat.size !== entry.bytes) fail(`size drift: ${entry.file}`);
  if (sha256(file) !== entry.sha256) fail(`hash drift: ${entry.file}`);
}

for (const board of layout.rendered_boards) {
  if (!fs.existsSync(path.join(projectRoot, board.svg.file))) fail(`missing SVG: ${board.id}`);
  if (!fs.existsSync(path.join(projectRoot, board.png.file))) fail(`missing PNG: ${board.id}`);
  if (sha256(path.join(projectRoot, board.svg.file)) !== board.svg.sha256) fail(`SVG hash drift: ${board.id}`);
  if (sha256(path.join(projectRoot, board.png.file)) !== board.png.sha256) fail(`PNG hash drift: ${board.id}`);
}

const mismatch = fs.readFileSync(path.join(outputRoot, 'preview-runtime-mismatch-ledger.md'), 'utf8');
if (!mismatch.includes('preview and Android runtime comparison closed')) {
  fail('Android runtime comparison is not explicitly closed');
}
for (const markdown of ['decision.md', 'symmetry-ledger.md', 'preview-runtime-mismatch-ledger.md']) {
  const content = fs.readFileSync(path.join(outputRoot, markdown), 'utf8');
  if (content.includes('\t')) fail(`accidental tab escape in ${markdown}`);
}

const adaptiveSvg = fs.readFileSync(path.join(outputRoot, 'adaptive-matrix.svg'), 'utf8');
if (!adaptiveSvg.includes('perfect-mark-1024') && !adaptiveSvg.includes('data:image/png;base64')) {
  fail('collapsed navigation mark is missing');
}
const stateSvg = fs.readFileSync(path.join(outputRoot, 'component-state-matrix.svg'), 'utf8');
if (!stateSvg.includes('NEXT BOUNDARY') || !stateSvg.includes('DAY SO FAR')) {
  fail('wide semantic columns are missing');
}

if (runtime.stage !== 11 || runtime.application.version_code !== 2064) {
  fail('runtime identity drift');
}
if (runtime.upgrade_proof.first_install_time_preserved !== true) {
  fail('runtime install-over continuity is not proven');
}
if (runtime.device.final_override_size !== null || runtime.device.final_override_density !== null) {
  fail('emulator was not returned to its physical phone profile');
}
if (runtime.evidence.length !== 9) fail(`expected 9 runtime files, got ${runtime.evidence.length}`);
const runtimeRoot = path.join(outputRoot, 'runtime/android');
for (const entry of runtime.evidence) {
  const file = path.join(runtimeRoot, entry.file);
  if (!fs.existsSync(file)) fail(`missing runtime file: ${entry.file}`);
  const stat = fs.statSync(file);
  if (stat.size !== entry.bytes) fail(`runtime size drift: ${entry.file}`);
  if (sha256(file) !== entry.sha256) fail(`runtime hash drift: ${entry.file}`);
}

const phoneSemantics = fs.readFileSync(path.join(runtimeRoot, 'phone-runtime.xml'), 'utf8');
const pulseOccurrences = (phoneSemantics.match(/Today pulse/g) || []).length;
if (pulseOccurrences !== 1) fail(`expected one phone Pulse semantic, got ${pulseOccurrences}`);
if (/orbit/i.test(phoneSemantics)) fail('retired Orbit remains in phone semantics');
for (const taskTitle of ['Review project brief', 'Focus deep work', 'Call Mom']) {
  const pulseStart = phoneSemantics.indexOf('Today pulse');
  const pulseEnd = phoneSemantics.indexOf('Open day plan', pulseStart);
  if (phoneSemantics.slice(pulseStart, pulseEnd).includes(taskTitle)) {
    fail(`Pulse duplicates stream title: ${taskTitle}`);
  }
}

const scrolledSemantics = fs.readFileSync(
  path.join(runtimeRoot, 'tablet-landscape-runtime-scrolled.xml'),
  'utf8',
);
if (!scrolledSemantics.includes('content-desc="Call Mom. Item actions available."')) {
  fail('final landscape item is not reachable after scroll');
}
if (!scrolledSemantics.includes('bounds="[440,1166][2480,1318]"')) {
  fail('final landscape item bounds drift');
}
if (!scrolledSemantics.includes('content-desc="Open quick capture"') ||
    !scrolledSemantics.includes('bounds="[1308,1396][1436,1524]"')) {
  fail('landscape capture clearance bounds drift');
}

const runtimeLog = fs.readFileSync(path.join(runtimeRoot, 'phone-runtime-log.txt'), 'utf8');
for (const forbidden of [
  /FATAL EXCEPTION/,
  /E\/flutter/,
  /RenderFlex/,
  /ANR in com\.k1tvkli2003\.perfect\.preview/,
  /Process: com\.k1tvkli2003\.perfect\.preview/,
]) {
  if (forbidden.test(runtimeLog)) fail(`runtime log contains ${forbidden}`);
}

process.stdout.write(
  `STAGE11_PREVIEW_VERIFY_PASS boards=${manifest.board_count} files=${manifest.files.length} ` +
  `states=${layout.state_matrix.length} runtime=${runtime.evidence.length}\n`,
);
