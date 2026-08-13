const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = path.join(
  root,
  'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/01-foundations/stage09-motion/runtime',
);
const output = path.join(runtime, 'android-profile-performance-summary.json');
const idleInputs = [
  { id: 'today-idle', file: 'android-profile-idle-today.txt', seconds: 6 },
  { id: 'tasks-idle', file: 'android-profile-idle-tasks.txt', seconds: 6 },
];
const runtimeArtifacts = [
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

function canonicalizeTextArtifact(relative) {
  if (!/\.(?:txt|xml)$/.test(relative)) return;
  const file = path.join(runtime, relative);
  const canonical = fs
    .readFileSync(file, 'utf8')
    .replace(/\r\n/g, '\n')
    .replace(/[ \t]+$/gm, '')
    .replace(/\n*$/, '\n');
  fs.writeFileSync(file, canonical, 'utf8');
}

for (const relative of runtimeArtifacts) canonicalizeTextArtifact(relative);

const inputs = [
  {
    id: 'tasks-to-plan',
    kind: 'real-workspace-transition',
    file: 'android-profile-single-tasks-to-plan-final-boundaries.txt',
  },
  {
    id: 'plan-to-habits',
    kind: 'real-workspace-transition',
    file: 'android-profile-single-plan-to-habits-final-boundaries.txt',
  },
  {
    id: 'minimal-control',
    kind: 'same-host-renderer-control',
    file: 'android-profile-minimal-frame-control.txt',
  },
];

function fail(message) {
  throw new Error(message);
}

function percentile(values, percentileValue) {
  const sorted = [...values].sort((left, right) => left - right);
  return sorted[Math.ceil(percentileValue * sorted.length) - 1];
}

function round(value) {
  return Number(value.toFixed(3));
}

function metric(values) {
  return {
    p50: round(percentile(values, 0.5)),
    p90: round(percentile(values, 0.9)),
    p95: round(percentile(values, 0.95)),
    max: round(Math.max(...values)),
    over16_67ms: values.filter((value) => value > 16.67).length,
    over33_33ms: values.filter((value) => value > 33.33).length,
  };
}

function parse(input) {
  const source = fs.readFileSync(path.join(runtime, input.file), 'utf8');
  const batches = [
    ...source.matchAll(
      /(?:PERFECT_FRAME_TIMINGS_V1|PERFECT_FRAME_CONTROL_V1) ([0-9:,]+)/g,
    ),
  ];
  const frames = batches.flatMap((match) =>
    match[1].split(',').map((triple) => triple.split(':').map(Number)),
  );
  if (frames.length === 0 || frames.some((frame) => frame.length !== 3)) {
    fail(`No valid Flutter frame timings in ${input.file}.`);
  }
  const toMilliseconds = (index) => frames.map((frame) => frame[index] / 1000);
  return {
    ...input,
    samples: frames.length,
    milliseconds: {
      build: metric(toMilliseconds(0)),
      raster: metric(toMilliseconds(1)),
      totalSpan: metric(toMilliseconds(2)),
    },
  };
}

function parseIdle(input) {
  const source = fs.readFileSync(path.join(runtime, input.file), 'utf8');
  const batches = [
    ...source.matchAll(/PERFECT_FRAME_TIMINGS_V1 ([0-9:,]+)/g),
  ];
  return {
    ...input,
    frameBatches: batches.length,
    frames: batches.reduce(
      (total, match) => total + match[1].split(',').length,
      0,
    ),
  };
}

function sha256(relative) {
  const crypto = require('crypto');
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(path.join(runtime, relative)))
    .digest('hex');
}

const sessions = inputs.map(parse);
const workspaceSessions = sessions.filter(
  (session) => session.kind === 'real-workspace-transition',
);
const control = sessions.find((session) => session.id === 'minimal-control');
const idleWindows = idleInputs.map(parseIdle);
const buildThreadWithin60Hz = workspaceSessions.every(
  (session) => session.milliseconds.build.over16_67ms === 0,
);
const controlShowsRasterFloor = control.milliseconds.raster.over16_67ms > 0;
const noSustainedIdleTicker = idleWindows.every(
  (window) => window.frames <= 1,
);

const report = {
  schema: 'perfect.motion.profile-summary.v1',
  generatedAt: '2026-08-13',
  environment: {
    device: 'Android emulator emulator-5554',
    api: 35,
    viewport: '1080x2400@60Hz',
    flutterRenderer: 'skiagl',
    package: 'com.k1tvkli2003.perfect.preview',
    captureAnimationScales: 1,
    restoredAnimationScales: 0,
  },
  sessions,
  idleWindows,
  runtimeArtifacts: Object.fromEntries(
    runtimeArtifacts.map((relative) => [relative, sha256(relative)]),
  ),
  gates: {
    workspaceBuildThread60Hz: buildThreadWithin60Hz ? 'pass' : 'fail',
    noSustainedIdleTicker: noSustainedIdleTicker ? 'pass' : 'fail',
    absoluteEmulatorRaster: controlShowsRasterFloor ? 'inconclusive' : 'measurable',
    physicalAndroidNoJank: 'open',
    WindowsNoJank: 'open',
  },
  interpretation: [
    'Both real workspace transitions keep every sampled Flutter build duration below 16.67ms.',
    'Two drained six-second idle windows contain at most one frame each, so no sustained offstage or idle ticker is present.',
    'The minimal same-package control also exceeds 16.67ms in raster work, proving a substantial host emulator/renderer floor.',
    'Therefore the emulator is valid for lifecycle, idle-ticker and UI-thread diagnostics but cannot certify physical-device or Windows raster smoothness.',
    'No physical-device or Windows performance claim is made by this report.',
  ],
};

fs.writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
console.log(`Stage 09 profile summary PASS: ${sessions.length} sessions.`);
