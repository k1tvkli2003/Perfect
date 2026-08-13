const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const out = path.join(
  root,
  'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/01-foundations/stage09-motion',
);
const manifestPath = path.join(out, 'manifest.json');
const hashPath = path.join(out, 'hashes.sha256');
const inventoryPath = path.join(out, 'implementation-inventory.json');
const runtime = path.join(out, 'runtime');
const profileSummaryPath = path.join(
  runtime,
  'android-profile-performance-summary.json',
);
const expected = [
  'motion-route',
  'motion-title',
  'motion-navigation',
  'motion-composer',
  'motion-selector',
  'motion-status-log',
  'motion-sync',
  'motion-overlay',
  'motion-inspector',
  'motion-wizard',
  'motion-responsive-resize',
];

function fail(message) {
  throw new Error(message);
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
if (manifest.schema !== 'perfect.motion.storyboards.v1') fail('Unexpected schema.');
if (JSON.stringify(manifest.frameOrder) !== JSON.stringify(['first', 'mid', 'end', 'reverse', 'interrupted', 'reduced'])) {
  fail('Frame order drifted.');
}
const ids = manifest.roles.map((role) => role.id);
if (JSON.stringify(ids) !== JSON.stringify(expected)) fail(`Role order drifted: ${ids.join(', ')}`);
for (const role of manifest.roles) {
  for (const key of ['intent', 'token', 'durationMs', 'reverseMs', 'travel', 'focus', 'budget', 'reduced', 'background']) {
    if (role[key] === undefined || role[key] === '') fail(`${role.id} misses ${key}.`);
  }
  if (!(role.durationMs > 0) || !(role.reverseMs > 0)) fail(`${role.id} has an invalid budget.`);
  for (const relative of Object.values(role.files)) {
    if (!fs.existsSync(path.join(out, relative))) fail(`Missing ${relative}.`);
  }
  const png = fs.readFileSync(path.join(out, role.files.png));
  if (png.readUInt32BE(16) !== 1200 || png.readUInt32BE(20) !== 720) {
    fail(`${role.id} PNG is not 1200x720.`);
  }
}

const inventory = JSON.parse(fs.readFileSync(inventoryPath, 'utf8'));
if (inventory.schema !== 'perfect.motion.implementation-inventory.v1') fail('Unexpected inventory schema.');
if (inventory.recordCount !== inventory.records.length || inventory.records.length < 90) {
  fail(`Motion inventory is incomplete: ${inventory.records.length} records.`);
}
const roleSet = new Set(expected);
const implementedRoles = new Set(inventory.records.map((record) => record.role));
for (const role of expected) {
  if (!implementedRoles.has(role)) fail(`Storyboard role has no implementation inventory: ${role}`);
}
const identities = new Set();
for (const record of inventory.records) {
  if (!record.file.endsWith('.dart') || !(record.line > 0) || !record.owner || !record.primitive) {
    fail(`Malformed inventory record: ${JSON.stringify(record)}`);
  }
  if (!roleSet.has(record.role) || !record.rationale) fail(`Unclassified motion: ${record.file}:${record.line}`);
  const identity = `${record.file}:${record.line}:${record.primitive}`;
  if (identities.has(identity)) fail(`Duplicate motion inventory record: ${identity}`);
  identities.add(identity);
}

const hashLines = fs.readFileSync(hashPath, 'utf8').trim().split(/\r?\n/);
if (hashLines.length !== 2 + expected.length * 2) fail('Hash scope is not exact.');
for (const line of hashLines) {
  const match = line.match(/^([0-9a-f]{64})  (.+)$/);
  if (!match) fail(`Malformed hash line: ${line}`);
  const file = path.join(out, match[2]);
  const actual = crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  if (actual !== match[1]) fail(`Hash mismatch: ${match[2]}`);
}

const profile = JSON.parse(fs.readFileSync(profileSummaryPath, 'utf8'));
if (profile.schema !== 'perfect.motion.profile-summary.v1') {
  fail('Unexpected profile summary schema.');
}
if (
  profile.gates.workspaceBuildThread60Hz !== 'pass' ||
  profile.gates.noSustainedIdleTicker !== 'pass'
) {
  fail('Measured Stage 09 UI-thread or idle gate did not pass.');
}
if (
  profile.gates.absoluteEmulatorRaster !== 'inconclusive' ||
  profile.gates.physicalAndroidNoJank !== 'open' ||
  profile.gates.WindowsNoJank !== 'open'
) {
  fail('Profile evidence overclaims emulator or unmeasured target hardware.');
}
const expectedRuntimeArtifacts = [
  'android-profile-idle-tasks.txt',
  'android-profile-idle-today.txt',
  'android-profile-minimal-frame-control.txt',
  'android-profile-motion.mp4',
  'android-profile-navigation-final-meminfo.txt',
  'android-profile-navigation-final-ui.xml',
  'android-profile-navigation-final.png',
  'android-profile-single-plan-to-habits-final-boundaries.txt',
  'android-profile-single-tasks-to-plan-final-boundaries.txt',
];
if (
  JSON.stringify(Object.keys(profile.runtimeArtifacts)) !==
  JSON.stringify(expectedRuntimeArtifacts)
) {
  fail('Runtime artifact scope drifted.');
}
for (const relative of expectedRuntimeArtifacts) {
  const actual = crypto
    .createHash('sha256')
    .update(fs.readFileSync(path.join(runtime, relative)))
    .digest('hex');
  if (actual !== profile.runtimeArtifacts[relative]) {
    fail(`Runtime hash mismatch: ${relative}`);
  }
}
if (
  profile.idleWindows.length !== 2 ||
  profile.idleWindows.some((window) => window.frames > 1)
) {
  fail('Idle evidence contains a sustained ticker.');
}

console.log(
  `Stage 09 motion evidence PASS: ${expected.length} roles, ` +
    `${inventory.records.length} implementation records, ` +
    `${hashLines.length} hashed design files, ` +
    `${expectedRuntimeArtifacts.length} hashed runtime artifacts.`,
);
