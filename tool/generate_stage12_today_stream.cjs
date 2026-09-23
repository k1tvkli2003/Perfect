const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const projectRoot = path.resolve(__dirname, '..');
const outputRoot = path.join(
  projectRoot,
  'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/05-runtime-comparisons/stage12-today-stream',
);
const renderScript = path.join(projectRoot, 'tool/render_design_svg.cjs');
const generatedAt = '2026-09-11';

const palette = {
  paper: '#FBF7F2',
  surface: '#FFFDF9',
  surfaceAlt: '#F7F1EA',
  ink: '#171827',
  muted: '#6F7084',
  outline: '#E4DBD2',
  mint: '#72C8A4',
  mintSoft: '#DDF3E8',
  orange: '#FFA255',
  orangeSoft: '#FFE6CF',
  lilac: '#9B86DD',
  lilacSoft: '#E9E2FB',
  red: '#E46B70',
  redSoft: '#FBE1E2',
};

function ensureDir(directory) {
  fs.mkdirSync(directory, { recursive: true });
}

function assertOutput(file) {
  const root = path.resolve(outputRoot);
  const target = path.resolve(file);
  if (target === root || !target.startsWith(`${root}${path.sep}`)) {
    throw new Error(`Unsafe Stage 12 output target: ${target}`);
  }
  return target;
}

function resetOutput() {
  ensureDir(outputRoot);
  for (const entry of fs.readdirSync(outputRoot, { withFileTypes: true })) {
    const target = assertOutput(path.join(outputRoot, entry.name));
    // Keep authored decision/evidence files. Generator owns only its rendered
    // boards and machine manifests; never erase a work-doc or runtime capture.
    const owned =
      /^candidate-[abc].+\.(svg|png)$/i.test(entry.name) ||
      /^preview-manifest\.json$/i.test(entry.name);
    if (owned) fs.rmSync(target, { recursive: true, force: true });
  }
}

function writeText(file, value) {
  const target = assertOutput(file);
  ensureDir(path.dirname(target));
  const normalized = value.replace(/[ \t]+$/gm, '');
  fs.writeFileSync(target, normalized.endsWith('\n') ? normalized : `${normalized}\n`, 'utf8');
}

function writeJson(file, value) {
  writeText(file, JSON.stringify(value, null, 2));
}

function sha256File(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function relative(file) {
  return path.relative(projectRoot, file).replaceAll('\\', '/');
}

function dataUrl(file, mime) {
  return `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
}

function escapeXml(value) {
  return String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}

const fonts = {
  jakarta: dataUrl(path.join(projectRoot, 'assets/fonts/PlusJakartaSans-Variable.ttf'), 'font/ttf'),
  vazir: dataUrl(path.join(projectRoot, 'assets/fonts/Vazirmatn-Variable.ttf'), 'font/ttf'),
};

function defs() {
  return `<defs>
    <style>
      @font-face { font-family: PerfectJakarta; src: url('${fonts.jakarta}'); }
      @font-face { font-family: PerfectVazir; src: url('${fonts.vazir}'); }
      text { font-family: PerfectJakarta, sans-serif; font-variation-settings: 'wght' 560; }
      .fa { font-family: PerfectVazir, sans-serif; }
    </style>
    <linearGradient id="paper" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFFDF9"/><stop offset=".55" stop-color="#FBF7F2"/><stop offset="1" stop-color="#F5F3EC"/>
    </linearGradient>
    <linearGradient id="nextSweep" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#DDF3E8"/><stop offset="1" stop-color="#FFF7EF"/>
    </linearGradient>
    <filter id="shadow" x="-30%" y="-30%" width="160%" height="180%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#57493C" flood-opacity=".13"/>
    </filter>
  </defs>`;
}

function document(width, height, body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    ${defs()}
    <rect width="${width}" height="${height}" fill="url(#paper)"/>
    ${body}
  </svg>`;
}

function label(x, y, value, options = {}) {
  const {
    size = 24,
    weight = 560,
    fill = palette.ink,
    anchor = 'start',
    opacity = 1,
    letter = 0,
    family = '',
  } = options;
  return `<text x="${x}" y="${y}" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${opacity}" letter-spacing="${letter}" class="${family}">${escapeXml(value)}</text>`;
}

function boardHeader(title, subtitle) {
  return `${label(96, 92, 'PERFECT! · STAGE 12', { size: 20, weight: 780, fill: palette.orange, letter: 2 })}
    ${label(96, 150, title, { size: 42, weight: 770, letter: -1.2 })}
    ${label(96, 190, subtitle, { size: 21, fill: palette.muted })}
    <path d="M96 224 H2304" stroke="${palette.outline}" stroke-width="2"/>`;
}

function statusRing(x, y, color, value, text) {
  const circumference = 2 * Math.PI * 24;
  const filled = value * circumference;
  const rest = circumference - filled;
  return `<g transform="translate(${x} ${y})">
    <circle r="27" fill="${palette.surface}" stroke="${palette.outline}" stroke-width="4.5"/>
    <circle r="24" fill="none" stroke="${palette.surfaceAlt}" stroke-width="4.5"/>
    <circle r="24" fill="none" stroke="${color}" stroke-width="4.5" stroke-linecap="round"
      stroke-dasharray="${filled.toFixed(1)} ${rest.toFixed(1)}" transform="rotate(-90)"/>
    <text y="6" font-size="13.5" font-weight="740" fill="${palette.ink}" text-anchor="middle">${escapeXml(text)}</text>
  </g>`;
}

function rowCandidateA(x, y, w, item) {
  return `<g transform="translate(${x} ${y})">
    <rect width="${w}" height="92" rx="22" fill="${palette.surface}" stroke="${palette.outline}" stroke-width="2"/>
    <rect width="6" height="58" x="22" y="17" rx="3" fill="${item.color}"/>
      ${statusRing(72, 46, item.color, item.progress, item.progress === 1 ? '✓' : '')}
    <g transform="translate(126 24)">
      <text font-size="11.5" font-weight="760" fill="${item.color}" letter-spacing="1.1">${escapeXml(item.time.toUpperCase())}</text>
      <text y="30" font-size="24" font-weight="700" fill="${palette.ink}">${escapeXml(item.title)}</text>
      <text y="56" font-size="15" fill="${palette.muted}">${escapeXml(item.meta)}</text>
    </g>
    <g transform="translate(${w - 94} 30)">
      <rect width="52" height="32" rx="16" fill="${palette.surfaceAlt}"/>
      <circle cx="18" cy="16" r="5" fill="${palette.muted}"/>
      <circle cx="34" cy="16" r="5" fill="${palette.muted}"/>
    </g>
  </g>`;
}

function rowCandidateB(x, y, w, item, emphasized = false) {
  const fill = emphasized ? 'url(#nextSweep)' : palette.surface;
  return `<g transform="translate(${x} ${y})">
    <rect width="${w}" height="100" rx="24" fill="${fill}" stroke="${emphasized ? item.color : palette.outline}" stroke-width="${emphasized ? 2.5 : 2}"/>
    ${statusRing(58, 50, item.color, item.progress, item.progress === 1 ? '✓' : '')}
    <g transform="translate(104 25)">
      <text font-size="12.5" font-weight="760" fill="${emphasized ? item.color : palette.muted}" letter-spacing="1.1">${escapeXml(item.label.toUpperCase())}</text>
      <text y="31" font-size="25" font-weight="${emphasized ? 740 : 700}" fill="${palette.ink}">${escapeXml(item.title)}</text>
      <text y="57" font-size="15" fill="${palette.muted}">${escapeXml(item.meta)}</text>
    </g>
    <g transform="translate(${w - 46} 36)">
      <rect width="28" height="28" rx="9" fill="${palette.surfaceAlt}"/>
      <path d="M9 19 L19 9 M19 12 L19 19 L12 19" fill="none" stroke="${palette.muted}" stroke-width="2.5" stroke-linecap="round"/>
    </g>
  </g>`;
}

function rowCandidateC(x, y, w, item) {
  return `<g transform="translate(${x} ${y})">
    <rect width="${w}" height="80" rx="20" fill="${palette.surface}" stroke="${palette.outline}" stroke-width="2"/>
    <g transform="translate(24 24)">
      <rect width="50" height="32" rx="16" fill="${item.soft}"/>
      <text x="25" y="21" font-size="12.5" font-weight="740" fill="${item.color}" text-anchor="middle">${escapeXml(item.time)}</text>
    </g>
    <g transform="translate(96 20)">
      <text font-size="25" font-weight="700" fill="${palette.ink}">${escapeXml(item.title)}</text>
      <text y="30" font-size="15" fill="${palette.muted}">${escapeXml(item.meta)}</text>
    </g>
    <g transform="translate(${w - 46} 24)">
      <rect width="28" height="28" rx="9" fill="${palette.surfaceAlt}"/>
      <circle cx="14" cy="14" r="6" fill="none" stroke="${item.color}" stroke-width="3.5"/>
    </g>
  </g>`;
}

function sparseA(w = 760) {
  const items = [
    { color: palette.mint, time: 'NOW', title: 'Focus deep work', meta: 'Work · 48%', progress: .48 },
    { color: palette.lilac, time: '2:00 PM', title: 'Read clinical card', meta: 'Study · 15 min', progress: 0 },
  ];
  return `${rowCandidateA(26, 92, w, items[0])}
    ${rowCandidateA(26, 200, w, items[1])}
    ${label(26, 352, 'NEXT IN 1H 12M · ANYTIME WORK REMAINS', { size: 14, weight: 720, fill: palette.muted, letter: 1.4 })}`;
}

function denseA(w = 760) {
  const items = [
    { color: palette.orange, time: '9:00 AM', title: 'Resolve delayed task', meta: 'Decision needed', progress: .12 },
    { color: palette.mint, time: '9:30 AM', title: 'Focus deep work', meta: 'Work · 48%', progress: .48 },
    { color: palette.lilac, time: '2:00 PM', title: 'Read clinical card', meta: 'Study · 15 min', progress: 0 },
    { color: palette.red, time: 'ANYTIME', title: 'Pack hospital bag', meta: 'Personal · Habit', progress: .25 },
  ];
  return items.map((item, index) => rowCandidateA(26, 92 + index * 108, w, item)).join('\n');
}

function sparseB(w = 700) {
  return rowCandidateB(28, 96, w, { color: palette.mint, label: 'Next', title: 'Focus deep work', meta: 'Work · 48%', progress: .48 }, true)
    + rowCandidateB(28, 216, w, { color: palette.lilac, label: 'Later', title: 'Read clinical card', meta: 'Study · 15 min', progress: 0 });
}

function denseB(w = 700) {
  const items = [
    { color: palette.orange, label: 'Decision', title: 'Resolve delayed task', meta: 'Miss recovery', progress: .12, emphasized: true },
    { color: palette.mint, label: 'Next', title: 'Focus deep work', meta: 'Work · 48%', progress: .48 },
    { color: palette.lilac, label: 'Later', title: 'Read clinical card', meta: 'Study · 15 min', progress: 0 },
    { color: palette.red, label: 'Habit', title: 'Pack hospital bag', meta: 'Personal · 25%', progress: .25 },
  ];
  return items.map((item, index) => rowCandidateB(28, 96 + index * 114, w, item, item.emphasized === true)).join('\n');
}

function sparseC(w = 660) {
  const items = [
    { color: palette.mint, soft: palette.mintSoft, time: 'Now', title: 'Focus deep work', meta: 'Work · 48%' },
    { color: palette.lilac, soft: palette.lilacSoft, time: '2:00', title: 'Read clinical card', meta: 'Study · 15 min' },
  ];
  return items.map((item, index) => rowCandidateC(26, 100 + index * 96, w, item)).join('\n');
}

function denseC(w = 660) {
  const items = [
    { color: palette.orange, soft: palette.orangeSoft, time: '9:00', title: 'Resolve delayed task', meta: 'Decision needed' },
    { color: palette.mint, soft: palette.mintSoft, time: '9:30', title: 'Focus deep work', meta: 'Work · 48%' },
    { color: palette.lilac, soft: palette.lilacSoft, time: '2:00', title: 'Read clinical card', meta: 'Study · 15 min' },
    { color: palette.red, soft: palette.redSoft, time: 'Any', title: 'Pack hospital bag', meta: 'Personal · Habit' },
  ];
  return items.map((item, index) => rowCandidateC(26, 100 + index * 96, w, item)).join('\n');
}

function phoneShell(x, y, scale, title, content, height = 560) {
  const width = 812;
  return `<g transform="translate(${x} ${y}) scale(${scale})">
    <rect width="${width}" height="${height}" rx="46" fill="${palette.surface}" stroke="${palette.outline}" stroke-width="3" filter="url(#shadow)"/>
    <rect x="24" y="24" width="${width - 48}" height="52" rx="20" fill="${palette.surfaceAlt}"/>
    <text x="46" y="57" font-size="22" font-weight="740" fill="${palette.ink}">${escapeXml(title)}</text>
    <circle cx="${width - 52}" cy="50" r="13" fill="${palette.mintSoft}" stroke="${palette.mint}" stroke-width="3"/>
    <clipPath id="clip-${Math.round(x)}-${Math.round(y)}"><rect x="24" y="88" width="${width - 48}" height="${height - 112}" rx="24"/></clipPath>
    <g clip-path="url(#clip-${Math.round(x)}-${Math.round(y)})">${content}</g>
  </g>`;
}

function candidateA() {
  return document(2400, 1160, `${boardHeader('A · Time ribbon', 'The fixed rail carries time meaning; the row carries actions and live progress.')}
    ${label(96, 290, 'SPARSE', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${phoneShell(96, 330, 1, 'Today', sparseA())}
    ${label(960, 290, 'DENSE', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${phoneShell(960, 330, 1, 'Today', denseA())}
    ${label(96, 1020, 'KEEPS: 48dp targets, one row per entity, stable time rail, no duplicated next task.', { size: 20, weight: 620, fill: palette.muted })}
    ${label(96, 1060, 'COST: rail consumes 74dp; recurrence time should be projected per day.', { size: 20, fill: palette.muted })}`);
}

function candidateB() {
  return document(2400, 1160, `${boardHeader('B · Attention gate', 'One semantic Next block leads scan; grouping replaces a persistent rail.')}
    ${label(96, 290, 'SPARSE', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${phoneShell(96, 330, 1, 'Today', sparseB())}
    ${label(860, 290, 'DENSE', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${phoneShell(860, 330, 1, 'Today', denseB())}
    ${label(1640, 290, 'RISK', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${label(1640, 340, 'Dense labels can crowd.', { size: 20, fill: palette.muted })}
    ${label(1640, 378, 'No native Add button.', { size: 20, fill: palette.muted })}
    ${label(96, 1020, 'KEEPS: fastest Next, strongest hierarchy, no repeated title.', { size: 20, weight: 620, fill: palette.muted })}
    ${label(96, 1060, 'COST: less stable rhythm; time hidden until row inspection.', { size: 20, fill: palette.muted })}`);
}

function candidateC() {
  return document(2400, 1160, `${boardHeader('C · Day lanes', 'Compact lanes fold time into color-soft chips; dense work becomes one list.')}
    ${label(96, 290, 'SPARSE', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${phoneShell(96, 330, 1, 'Today', sparseC())}
    ${label(860, 290, 'DENSE', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${phoneShell(860, 330, 1, 'Today', denseC())}
    ${label(1640, 290, 'RISK', { size: 18, weight: 750, fill: palette.muted, letter: 1.6 })}
    ${label(1640, 340, 'Looks administrative.', { size: 20, fill: palette.muted })}
    ${label(1640, 378, 'Weaker action affordance.', { size: 20, fill: palette.muted })}
    ${label(96, 1020, 'KEEPS: highest density and clean scan.', { size: 20, weight: 620, fill: palette.muted })}
    ${label(96, 1060, 'COST: weaker Next; less friendly than A.', { size: 20, fill: palette.muted })}`);
}

const boards = [
  ['candidate-a-time-ribbon', 2400, 1160, candidateA()],
  ['candidate-b-attention-gate', 2400, 1160, candidateB()],
  ['candidate-c-day-lanes', 2400, 1160, candidateC()],
];

function renderBoards() {
  const manifest = [];
  const browserCandidates = [
    process.env.PERFECT_DESIGN_BROWSER,
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  ].filter(Boolean);
  const browser = browserCandidates.find((candidate) => fs.existsSync(candidate));
  if (!browser) {
    throw new Error('No local Chromium browser found for design rendering.');
  }
  for (const [id, width, height, svg] of boards) {
    const svgFile = path.join(outputRoot, `${id}.svg`);
    const pngFile = path.join(outputRoot, `${id}.png`);
    writeText(svgFile, svg);
    const url = `file:///${svgFile.replaceAll('\\', '/')}`;
    execFileSync(browser, [
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      `--window-size=${width},${height}`,
      `--screenshot=${pngFile}`,
      url,
    ], {
      cwd: projectRoot,
      stdio: 'inherit',
      env: process.env,
    });
    manifest.push({
      id,
      viewport: `${width}x${height}`,
      svg: { file: relative(svgFile), sha256: sha256File(svgFile) },
      png: { file: relative(pngFile), sha256: sha256File(pngFile) },
    });
  }
  return manifest;
}

function main() {
  resetOutput();
  const rendered = renderBoards();
  writeContracts(rendered);
  const files = fs.readdirSync(outputRoot).filter((name) => !name.startsWith('preview-manifest.')).sort().map((name) => ({
    file: relative(path.join(outputRoot, name)),
    bytes: fs.statSync(path.join(outputRoot, name)).size,
    sha256: sha256File(path.join(outputRoot, name)),
  }));
  writeJson(path.join(outputRoot, 'preview-manifest.json'), {
    stage: 12,
    generated_at: generatedAt,
    generator: relative(__filename),
    concept_id: 'today-time-ribbon-v1',
    board_count: rendered.length,
    files,
  });
  process.stdout.write(`STAGE12_PREVIEW_GENERATED boards=${rendered.length} files=${files.length + 1}\n`);
}

function writeContracts(rendered) {
  if (!fs.existsSync(path.join(outputRoot, 'layout-contract.json'))) writeJson(path.join(outputRoot, 'layout-contract.json'), {
    stage: 12,
    concept_id: 'today-time-ribbon-v1',
    status: 'mock-preview-not-approved',
    generated_at: generatedAt,
    selected_candidate: null,
    rejected_candidates: [],
    decisions: {
      one_row_per_entity: true,
      time_rail: 'persistent semantic time, not duplicated task title',
      next_emphasis: 'first actionable row only; no separate Next card',
      settled_zone: 'visually quiet but reviewable; never silently removed',
      empty_zone_suppression: true,
    },
    geometry: {
      row_min_height: 76,
      row_preferred_height: 88,
      row_gap: 14,
      section_gap: 24,
      rail_width: 58,
      status_ring: { size: 58, stroke: 4.5, inner_text_safe: 38 },
      semantic_fixed_tokens: ['48dp minimum target', '2dp focus boundary', 'icon stroke', 'corner rhythm'],
      adaptive_tokens: ['intrinsic copy width', 'bounded row height', 'content-driven reflow', 'safe-area/footer clearance'],
    },
    rendered_boards: rendered,
  });
  if (!fs.existsSync(path.join(outputRoot, 'decision.md'))) writeText(path.join(outputRoot, 'decision.md'), `# Stage 12 Today stream preview decision

Status: **Mock Preview — not approved and not implementation evidence**

## Current state

Three synthetic sparse/dense candidates exist for internal comparison only.
No candidate is selected. They do not represent the real Flutter runtime,
approved brand composition, or final responsive behavior.

## Known defects

- Status rings must show progress through the arc; no numeric percentage copy.
- Candidates still need full phone/tablet/Windows shell context, footer/capture
  relationship, empty/settled states, and native-scale visual review.
- A candidate can become implementation input only after a fresh runtime
  comparison and an explicit recorded decision.

## Acceptance gate

Until that gate passes, this folder contains Mock Preview assets only.
`);
  if (!fs.existsSync(path.join(outputRoot, 'symmetry-ledger.md'))) writeText(path.join(outputRoot, 'symmetry-ledger.md'), `# Stage 12 symmetry and placement ledger

| Group | Contract | Verification |
| --- | --- | --- |
| Row status ring | optical center, text-safe inner core | 58dp ring, 38dp inner safe area |
| Time rail | end-aligned, one shared baseline | no recurrence anchor drift |
| Row content | start-aligned; title and meta share left edge | RTL mirrors rail and content |
| Row trailing action | end-anchored, fixed 48dp target | title growth never shifts action |
| Section headings | small, quiet; never stronger than actionable rows | empty sections suppressed |
| Dense list | row height bounded, title wraps before clipping | sparse/dense boards |
`);
}

main();
