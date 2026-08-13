const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const out = path.join(
  root,
  'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/01-foundations/stage09-motion',
);
const storyboards = path.join(out, 'storyboards');
const render = path.join(root, 'tool/render_design_svg.cjs');
const bundledNodeModules =
  process.env.CODEX_WORKSPACE_NODE_MODULES ||
  'C:\\Users\\K1\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\node_modules';

const roles = [
  {
    id: 'motion-route',
    title: 'Route hand-off',
    intent: 'Destination order remains legible while retained route state stays offstage.',
    token: 'route',
    durationMs: 380,
    reverseMs: 240,
    travel: 'Navigator routes travel 14px; workspace hand-offs use one isolated 8px edge cue',
    focus: 'Destination owns focus only after it exists; outgoing route is inert immediately.',
    budget: 'Only the selected route paints; the isolated edge cue never revives an offstage route.',
  },
  {
    id: 'motion-title',
    title: 'Title orientation',
    intent: 'A meaningful page entry gets one quiet orientation beat.',
    token: 'emphasized',
    durationMs: 320,
    reverseMs: 140,
    travel: '10px rise, 0.985→1 scale, no bounce',
    focus: 'Title never steals focus and never replays on sync or notifier rebuild.',
    budget: 'Paint-only transform/opacity; subtree isolated and disposed when complete.',
  },
  {
    id: 'motion-navigation',
    title: 'Footer and rail selection',
    intent: 'Selection acknowledgement travels without changing hit geometry.',
    token: 'quick',
    durationMs: 140,
    reverseMs: 140,
    travel: 'Lens/material interpolation inside a fixed 48dp target',
    focus: 'Keyboard focus and selected semantics remain distinct and visible.',
    budget: 'Only the selected glyph and edge cue repaint; destination-row geometry stays fixed.',
  },
  {
    id: 'motion-composer',
    title: 'Composer morph',
    intent: 'One capture instrument changes jobs without losing draft or focus.',
    token: 'emphasized',
    durationMs: 320,
    reverseMs: 240,
    travel: 'Bounded height/shape morph with 8px content hand-off',
    focus: 'IME opens only after explicit field focus; mode switches preserve the draft.',
    budget: 'One live composer subtree after settle; old glass layer removed by end frame.',
  },
  {
    id: 'motion-selector',
    title: 'Selector state',
    intent: 'Color, material and indicator explain selection without a checkmark crutch.',
    token: 'quick',
    durationMs: 140,
    reverseMs: 140,
    travel: 'No positional travel; color/shape/indicator interpolate in place',
    focus: 'Control is interactive for the entire transition and announces final state once.',
    budget: 'Paint-only transition; surrounding layout and label bounds remain stable.',
  },
  {
    id: 'motion-status-log',
    title: 'Status and log receipt',
    intent: 'Rapid outcomes feel tactile while one durable mutation remains authoritative.',
    token: 'feedback',
    durationMs: 600,
    reverseMs: 240,
    travel: '90ms press, 140ms arc/fill, bounded receipt then Undo',
    focus: 'Rapid taps coalesce; Undo targets the latest committed local mutation.',
    budget: 'Only the affected row repaints; no duplicate snackbar, sheet or write.',
  },
  {
    id: 'motion-sync',
    title: 'Sync confidence',
    intent: 'Background work stays calm, bounded and truthful.',
    token: 'standard',
    durationMs: 240,
    reverseMs: 140,
    travel: 'Small orbital activity only while work is active; symbol/label crossfade',
    focus: 'State details remain reachable; color is never the only signal.',
    budget: 'Ticker is paused offstage/background and absent when converged or reduced.',
  },
  {
    id: 'motion-overlay',
    title: 'Dialog, sheet and menu',
    intent: 'Temporary hierarchy appears from its spatial origin, not a stock surprise.',
    token: 'modal',
    durationMs: 360,
    reverseMs: 240,
    travel: 'Dialog 12px/0.96; sheet bounded vertical; menu anchored scale/fade',
    focus: 'Barrier and focus trap activate with the route; invoking focus restores on close.',
    budget: 'One overlay route and one composited surface; no duplicate child entrance.',
  },
  {
    id: 'motion-inspector',
    title: 'Inspector continuity',
    intent: 'Selected entity and inspector remain visibly connected.',
    token: 'route',
    durationMs: 380,
    reverseMs: 240,
    travel: '16px edge hand-off; selected row remains stationary',
    focus: 'Desktop focus enters inspector only by explicit action; Escape restores context.',
    budget: 'Inspector alone animates; list scroll anchor and row identity remain stable.',
  },
  {
    id: 'motion-wizard',
    title: 'Wizard progression',
    intent: 'Decision order is visible while shared chrome never jumps.',
    token: 'standard',
    durationMs: 240,
    reverseMs: 240,
    travel: '12px signed shared axis inside stable wizard chrome',
    focus: 'First invalid field receives focus only after the destination step exists.',
    budget: 'Only old/new step bodies coexist; header, footer and draft model remain single.',
  },
  {
    id: 'motion-responsive-resize',
    title: 'Responsive recomposition',
    intent: 'Window class changes preserve work instead of staging a theatrical route.',
    token: 'standard',
    durationMs: 240,
    reverseMs: 240,
    travel: 'Constraint-led pane interpolation; no page translation',
    focus: 'Draft, focus, selection and scroll survive every crossed breakpoint.',
    budget: 'No retained duplicate glass trees; continuous resize remains directly responsive.',
  },
];

const frameNames = ['FIRST 0%', 'MID 50%', 'END 100%', 'REVERSE', 'INTERRUPTED', 'REDUCED'];
const frameNotes = [
  'Prior geometry remains authoritative.',
  'Both states are bounded and interruptible.',
  'Final state is usable and announced once.',
  'Continue from the current interpolated value.',
  'Retarget to the latest request; never replay.',
  'No spatial travel; information stays equal.',
];
const palette = ['#FFA34D', '#7EC99B', '#A79ADD', '#1D2030'];

const inventoryInputs = [
  'lib/ai',
  'lib/auth',
  'lib/feedback/src/feedback_overlay.dart',
  'lib/presentation',
];
const primitivePattern = /\b(Animated[A-Z]\w*|AnimationController|TweenAnimationBuilder|PerfectMotionSwitcher|PerfectStagedEntrance|PerfectInteractiveSurface|PageRouteBuilder|showPerfectDialog|showModalBottomSheet|showMenu|InkWell|MouseRegion|GestureDetector|FocusableActionDetector)\b/g;

function dartFiles(relative) {
  const absolute = path.join(root, relative);
  if (!fs.existsSync(absolute)) return [];
  if (fs.statSync(absolute).isFile()) return [relative.replaceAll('\\', '/')];
  return fs.readdirSync(absolute, { withFileTypes: true }).flatMap((entry) =>
    dartFiles(path.join(relative, entry.name)),
  ).filter((file) => file.endsWith('.dart'));
}

function inventoryRole(file, owner, primitive) {
  const key = `${file} ${owner} ${primitive}`.toLowerCase();
  if (/showperfectdialog|showmodalbottomsheet|showmenu/.test(key)) return 'motion-overlay';
  if (/pageroutebuilder|persistentdestinationhost|pagetransitions/.test(key)) return 'motion-route';
  if (/planner_editor|plannereditor|wizard|step/.test(key)) return 'motion-wizard';
  if (/perfect_sync|syncindicator/.test(key)) return 'motion-sync';
  if (/quickcapture|captureoption|perfect_ai|aidock|feedback.*composer/.test(key)) return 'motion-composer';
  if (/navigation|footer|rail|destinationglyph/.test(key)) return 'motion-navigation';
  if (/inspector/.test(key)) return 'motion-inspector';
  if (/header|pagetitle|stagedentrance/.test(key)) return 'motion-title';
  if (/panedivider|responsive|layout|animatedsize/.test(key)) return 'motion-responsive-resize';
  if (/orbit|agenda|habit|status|completion|pulse|focus/.test(key)) return 'motion-status-log';
  return 'motion-selector';
}

function generateImplementationInventory() {
  const records = [];
  for (const file of [...new Set(inventoryInputs.flatMap(dartFiles))].sort()) {
    const lines = fs.readFileSync(path.join(root, file), 'utf8').split(/\r?\n/);
    let owner = '<top-level>';
    lines.forEach((line, index) => {
      const classMatch = line.match(/\bclass\s+([A-Za-z_]\w*)/);
      if (classMatch) owner = classMatch[1];
      if (/^\s*\/\//.test(line)) return;
      primitivePattern.lastIndex = 0;
      const recordedOnLine = new Set();
      for (const match of line.matchAll(primitivePattern)) {
        const primitive = match[1];
        if (line.includes(`class ${primitive}`) || line.includes(`Future<T?> ${primitive}`)) continue;
        if (recordedOnLine.has(primitive)) continue;
        recordedOnLine.add(primitive);
        const role = inventoryRole(file, owner, primitive);
        records.push({
          file,
          line: index + 1,
          owner,
          primitive,
          role,
          rationale: `Owned by ${owner}; uses the ${role.replace('motion-', '')} continuity contract.`,
        });
      }
    });
  }
  return {
    schema: 'perfect.motion.implementation-inventory.v1',
    generatedAt: '2026-08-13',
    scope: inventoryInputs,
    recordCount: records.length,
    records,
  };
}

function esc(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function wrap(value, length = 42) {
  const words = value.split(/\s+/);
  const lines = [];
  let line = '';
  for (const word of words) {
    if (line && `${line} ${word}`.length > length) {
      lines.push(line);
      line = word;
    } else {
      line = line ? `${line} ${word}` : word;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function textBlock(value, x, y, options = {}) {
  const { length = 42, size = 14, weight = 600, fill = '#686579', lineHeight = 20 } = options;
  return `<text x="${x}" y="${y}" font-family="Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}">${wrap(value, length)
    .map((line, index) => `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${esc(line)}</tspan>`)
    .join('')}</text>`;
}

function miniature(role, frameIndex, x, y) {
  const progress = frameIndex === 0 ? 0 : frameIndex === 1 ? 0.5 : frameIndex === 2 ? 1 : frameIndex === 3 ? 0.62 : frameIndex === 4 ? 0.35 : 1;
  const reduced = frameIndex === 5;
  const travel = reduced ? 0 : (1 - progress) * 18;
  const alpha = frameIndex === 0 ? 0.52 : 0.98;
  const accent = palette[(roles.indexOf(role) + frameIndex) % 3];
  const priorX = x + 18 - (frameIndex === 3 ? travel * 0.4 : 0);
  const nextX = x + 50 + travel;
  return `
    <rect x="${x}" y="${y}" width="330" height="122" rx="22" fill="#FFFDF9" stroke="#ECE5DC"/>
    <rect x="${priorX}" y="${y + 22}" width="118" height="78" rx="17" fill="#F7F2EB" opacity="${frameIndex === 2 ? 0.24 : 1 - progress * 0.56}"/>
    <rect x="${nextX}" y="${y + 18}" width="244" height="86" rx="20" fill="${accent}" opacity="${alpha * (0.28 + progress * 0.15)}"/>
    <circle cx="${nextX + 28}" cy="${y + 47}" r="13" fill="${accent}" opacity="${0.58 + progress * 0.4}"/>
    <rect x="${nextX + 52}" y="${y + 35}" width="${116 + progress * 28}" height="10" rx="5" fill="#1D2030" opacity="${0.48 + progress * 0.42}"/>
    <rect x="${nextX + 52}" y="${y + 56}" width="${86 + progress * 20}" height="8" rx="4" fill="#686579" opacity="${0.38 + progress * 0.34}"/>
    <rect x="${nextX + 52}" y="${y + 76}" width="64" height="7" rx="3.5" fill="${accent}" opacity="${0.5 + progress * 0.38}"/>
    ${frameIndex === 4 ? `<path d="M ${x + 286} ${y + 18} l 14 0 l -7 -8 z" fill="#C44B56"/><circle cx="${x + 293}" cy="${y + 17}" r="3" fill="#fff"/>` : ''}
    ${reduced ? `<path d="M ${x + 284} ${y + 87} h 24" stroke="#1D2030" stroke-width="3" stroke-linecap="round"/><path d="M ${x + 290} ${y + 80} l 12 14" stroke="#1D2030" stroke-width="2"/>` : `<path d="M ${x + 286} ${y + 87} c 8 -8 14 -8 22 0" fill="none" stroke="#7F68C9" stroke-width="3" stroke-linecap="round"/>`}
  `;
}

function storyboardSvg(role) {
  const cards = frameNames.map((name, index) => {
    const col = index % 3;
    const row = Math.floor(index / 3);
    const x = 54 + col * 376;
    const y = 198 + row * 226;
    return `
      <g>
        <text x="${x}" y="${y - 18}" font-family="Arial, sans-serif" font-size="12" font-weight="800" letter-spacing="1.3" fill="#7F68C9">${name}</text>
        ${miniature(role, index, x, y)}
        ${textBlock(frameNotes[index], x + 2, y + 150, { length: 44, size: 13, weight: 600, lineHeight: 17 })}
      </g>`;
  }).join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="720" viewBox="0 0 1200 720">
    <defs>
      <linearGradient id="wash" x1="0" x2="1" y1="0" y2="1"><stop stop-color="#FFFCF7"/><stop offset="0.56" stop-color="#FFF9F0"/><stop offset="1" stop-color="#F5F0FF"/></linearGradient>
      <filter id="shadow" x="-20%" y="-20%" width="140%" height="160%"><feDropShadow dx="0" dy="10" stdDeviation="16" flood-color="#1D2030" flood-opacity="0.08"/></filter>
    </defs>
    <rect width="1200" height="720" fill="url(#wash)"/>
    <circle cx="1080" cy="70" r="132" fill="#EEEAFD" opacity=".52"/>
    <circle cx="78" cy="692" r="126" fill="#E4F4E8" opacity=".58"/>
    <g filter="url(#shadow)"><rect x="34" y="28" width="1132" height="650" rx="34" fill="#FFFFFF" fill-opacity=".78" stroke="#ECE5DC"/></g>
    <rect x="54" y="52" width="48" height="48" rx="16" fill="#FFEAD7"/><path d="M68 72h20M68 79h20" stroke="#A4510E" stroke-width="3" stroke-linecap="round"/>
    <text x="118" y="67" font-family="Arial, sans-serif" font-size="11" font-weight="800" letter-spacing="1.5" fill="#7F68C9">PERFECT! MOTION · ${esc(role.id)}</text>
    <text x="118" y="98" font-family="Arial, sans-serif" font-size="30" font-weight="800" fill="#1D2030">${esc(role.title)}</text>
    ${textBlock(role.intent, 54, 139, { length: 74, size: 15, weight: 600, lineHeight: 20 })}
    <rect x="760" y="50" width="380" height="104" rx="22" fill="#FFFCF7" stroke="#ECE5DC"/>
    <text x="782" y="76" font-family="Arial, sans-serif" font-size="11" font-weight="800" letter-spacing="1.1" fill="#A4510E">${role.token.toUpperCase()} · ${role.durationMs}MS / ${role.reverseMs}MS REVERSE</text>
    ${textBlock(role.travel, 782, 101, { length: 46, size: 13, weight: 700, fill: '#1D2030', lineHeight: 18 })}
    ${cards}
    <line x1="54" y1="626" x2="1140" y2="626" stroke="#ECE5DC"/>
    ${textBlock(`FOCUS · ${role.focus}`, 54, 650, { length: 78, size: 12, weight: 700, fill: '#1D2030', lineHeight: 16 })}
    ${textBlock(`BUDGET · ${role.budget}`, 640, 650, { length: 66, size: 12, weight: 700, fill: '#1D2030', lineHeight: 16 })}
  </svg>`;
}

fs.mkdirSync(storyboards, { recursive: true });
for (const role of roles) {
  const svg = path.join(storyboards, `${role.id}.svg`);
  const png = path.join(storyboards, `${role.id}.png`);
  const canonicalSvg = storyboardSvg(role).replace(/[ \t]+$/gm, '');
  fs.writeFileSync(svg, canonicalSvg, 'utf8');
  execFileSync(process.execPath, [render, svg, png, '1200', '720'], {
    cwd: root,
    stdio: 'inherit',
    env: {
      ...process.env,
      NODE_PATH: [process.env.NODE_PATH, bundledNodeModules].filter(Boolean).join(path.delimiter),
    },
  });
}

const manifest = {
  schema: 'perfect.motion.storyboards.v1',
  generatedAt: '2026-08-13',
  authority: 'fnd-motion + Stage 09 runtime contract',
  frameOrder: ['first', 'mid', 'end', 'reverse', 'interrupted', 'reduced'],
  roles: roles.map((role) => ({
    ...role,
    curve: 'PerfectMotion.enter / PerfectMotion.exit',
    reduced: 'Duration.zero for spatial movement; final geometry and equal semantic feedback remain.',
    background: 'Pause decorative tickers offstage/background; resume from durable current truth.',
    files: {
      svg: `storyboards/${role.id}.svg`,
      png: `storyboards/${role.id}.png`,
    },
  })),
};
fs.writeFileSync(path.join(out, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
fs.writeFileSync(
  path.join(out, 'implementation-inventory.json'),
  `${JSON.stringify(generateImplementationInventory(), null, 2)}\n`,
  'utf8',
);

const files = [
  'manifest.json',
  'implementation-inventory.json',
  ...roles.flatMap((role) => [
    `storyboards/${role.id}.svg`,
    `storyboards/${role.id}.png`,
  ]),
];
const hashes = files.map((relative) => {
  const digest = crypto.createHash('sha256').update(fs.readFileSync(path.join(out, relative))).digest('hex');
  return `${digest}  ${relative.replaceAll('\\', '/')}`;
});
fs.writeFileSync(path.join(out, 'hashes.sha256'), `${hashes.join('\n')}\n`, 'utf8');
console.log(`Generated ${roles.length} Stage 09 motion storyboards.`);
