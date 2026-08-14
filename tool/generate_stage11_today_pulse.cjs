#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const projectRoot = path.resolve(__dirname, '..');
const outputRoot = path.join(
  projectRoot,
  'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/05-runtime-comparisons/stage11-today-pulse',
);
const renderScript = path.join(projectRoot, 'tool/render_design_svg.cjs');
const generatedAt = '2026-08-14';

const palette = {
  paper: '#FBF7F2',
  surface: '#FFFDF9',
  surfaceAlt: '#F8F2EC',
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
  yellow: '#E6B84E',
  dark: '#11121A',
  darkSurface: '#1B1D27',
  darkSurfaceAlt: '#222532',
  darkInk: '#FFF9F1',
  darkMuted: '#B9B6C8',
  darkOutline: '#343746',
};

function ensureDir(directory) {
  fs.mkdirSync(directory, { recursive: true });
}

function assertOutput(file) {
  const root = path.resolve(outputRoot);
  const target = path.resolve(file);
  if (target === root || !target.startsWith(`${root}${path.sep}`)) {
    throw new Error(`Unsafe Stage 11 output target: ${target}`);
  }
  return target;
}

function resetOutput() {
  ensureDir(outputRoot);
  for (const entry of fs.readdirSync(outputRoot, { withFileTypes: true })) {
    if (entry.name === 'runtime') continue;
    fs.rmSync(assertOutput(path.join(outputRoot, entry.name)), {
      recursive: true,
      force: true,
    });
  }
}

function writeText(file, value) {
  const target = assertOutput(file);
  ensureDir(path.dirname(target));
  const normalized = value.replace(/[ \t]+$/gm, '');
  fs.writeFileSync(
    target,
    normalized.endsWith('\n') ? normalized : `${normalized}\n`,
    'utf8',
  );
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
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

const fonts = {
  jakarta: dataUrl(path.join(projectRoot, 'assets/fonts/PlusJakartaSans-Variable.ttf'), 'font/ttf'),
  vazir: dataUrl(path.join(projectRoot, 'assets/fonts/Vazirmatn-Variable.ttf'), 'font/ttf'),
};
const wordmarks = {
  light: dataUrl(path.join(projectRoot, 'assets/brand/perfect-wordmark.svg'), 'image/svg+xml'),
  dark: dataUrl(path.join(projectRoot, 'assets/brand/perfect-wordmark-dark.svg'), 'image/svg+xml'),
};
const marks = {
  light: dataUrl(path.join(projectRoot, 'assets/brand/perfect-mark-1024.png'), 'image/png'),
  dark: dataUrl(path.join(projectRoot, 'assets/brand/perfect-mark-dark.png'), 'image/png'),
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
    <linearGradient id="pulseDay" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#F0FAF4"/><stop offset=".46" stop-color="#FFF8F0"/><stop offset="1" stop-color="#F5F0FD"/>
    </linearGradient>
    <linearGradient id="pulseDark" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#17251F"/><stop offset=".48" stop-color="#25201C"/><stop offset="1" stop-color="#211D31"/>
    </linearGradient>
    <linearGradient id="dayline" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="${palette.mint}"/><stop offset=".48" stop-color="${palette.orange}"/><stop offset="1" stop-color="${palette.lilac}"/>
    </linearGradient>
    <linearGradient id="capture" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#2CAFA0"/><stop offset="1" stop-color="#7764CE"/>
    </linearGradient>
    <filter id="shadow" x="-40%" y="-40%" width="180%" height="200%">
      <feDropShadow dx="0" dy="10" stdDeviation="18" flood-color="#57493C" flood-opacity=".13"/>
    </filter>
    <filter id="softShadow" x="-30%" y="-30%" width="160%" height="180%">
      <feDropShadow dx="0" dy="5" stdDeviation="9" flood-color="#4C4038" flood-opacity=".11"/>
    </filter>
    <filter id="glow" x="-300%" y="-300%" width="700%" height="700%">
      <feGaussianBlur stdDeviation="9" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>`;
}

function document(width, height, body, { dark = false } = {}) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    ${defs()}
    <rect width="${width}" height="${height}" fill="${dark ? palette.dark : 'url(#paper)'}"/>
    ${body}
  </svg>`;
}

function label(x, y, textValue, options = {}) {
  const {
    size = 24,
    weight = 560,
    fill = palette.ink,
    anchor = 'start',
    opacity = 1,
    family = '',
    letter = 0,
  } = options;
  return `<text x="${x}" y="${y}" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${opacity}" letter-spacing="${letter}" class="${family}">${escapeXml(textValue)}</text>`;
}

function boardHeader(title, subtitle, { dark = false } = {}) {
  const ink = dark ? palette.darkInk : palette.ink;
  const muted = dark ? palette.darkMuted : palette.muted;
  return `${label(96, 94, 'PERFECT! · STAGE 11', { size: 20, weight: 760, fill: palette.orange, letter: 2 })}
    ${label(96, 154, title, { size: 42, weight: 760, fill: ink, letter: -1.2 })}
    ${label(96, 194, subtitle, { size: 21, weight: 520, fill: muted })}
    <path d="M96 226 H2304" stroke="${dark ? palette.darkOutline : palette.outline}" stroke-width="2"/>`;
}

function cloudIcon(x, y, color, status = 'synced', scale = 1) {
  const badge = status === 'syncing' ? palette.yellow : status === 'error' ? palette.red : color;
  const glyph = status === 'syncing'
    ? `<path d="M${x + 36 * scale} ${y + 27 * scale} a9 9 0 1 1 -3 -6" fill="none" stroke="${badge}" stroke-width="${3 * scale}" stroke-linecap="round"/><path d="M${x + 30 * scale} ${y + 18 * scale} l5 2 -2 5" fill="none" stroke="${badge}" stroke-width="${3 * scale}" stroke-linecap="round" stroke-linejoin="round"/>`
    : status === 'error'
      ? `<path d="M${x + 36 * scale} ${y + 18 * scale} v11 M${x + 36 * scale} ${y + 35 * scale} v1" stroke="${badge}" stroke-width="${3 * scale}" stroke-linecap="round"/>`
      : `<path d="M${x + 29 * scale} ${y + 29 * scale} l5 5 9 -11" fill="none" stroke="${badge}" stroke-width="${3 * scale}" stroke-linecap="round" stroke-linejoin="round"/>`;
  return `<path d="M${x + 18 * scale} ${y + 40 * scale}h31a13 13 0 0 0 2-26 18 18 0 0 0-34-2A14 14 0 0 0 ${x + 18 * scale} ${y + 40 * scale}Z" fill="none" stroke="${color}" stroke-width="${2.6 * scale}" stroke-linecap="round" stroke-linejoin="round"/>${glyph}`;
}

function calendarPlus(x, y, color, scale = 1) {
  return `<rect x="${x}" y="${y + 4 * scale}" width="${28 * scale}" height="${25 * scale}" rx="${6 * scale}" fill="none" stroke="${color}" stroke-width="${2.2 * scale}"/>
    <path d="M${x} ${y + 12 * scale}h${28 * scale}M${x + 7 * scale} ${y}v${8 * scale}M${x + 21 * scale} ${y}v${8 * scale}" stroke="${color}" stroke-width="${2.2 * scale}" stroke-linecap="round"/>
    <path d="M${x + 14 * scale} ${y + 17 * scale}v${8 * scale}M${x + 10 * scale} ${y + 21 * scale}h${8 * scale}" stroke="${color}" stroke-width="${2 * scale}" stroke-linecap="round"/>`;
}

function pulseInstrument({
  x,
  y,
  w,
  h,
  dark = false,
  highContrast = false,
  state = 'normal',
  progress = 43,
  time = '7:42',
  period = 'PM',
  next = '8:00 PM',
  compact = false,
  focus = false,
  largeText = false,
}) {
  const ink = dark ? palette.darkInk : palette.ink;
  const muted = dark ? palette.darkMuted : palette.muted;
  const outline = highContrast ? ink : dark ? palette.darkOutline : palette.outline;
  const surface = highContrast ? (dark ? '#000000' : '#FFFFFF') : dark ? 'url(#pulseDark)' : 'url(#pulseDay)';
  const pad = compact ? 24 : 32;
  const timeSize = compact ? (largeText ? 58 : 54) : 64;
  const metric = state === 'empty'
    ? 'Nothing planned yet'
    : state === 'complete'
      ? 'Everything complete'
      : state === 'missed'
        ? '2 need a decision'
        : state === 'habits'
          ? '2 habits remaining'
          : state === 'unscheduled'
            ? '3 flexible items'
            : '3 complete · 4 remaining';
  const boundary = state === 'empty'
    ? 'Shape the day'
    : state === 'complete'
      ? 'You made it yours'
      : state === 'missed'
        ? 'Review before tomorrow'
        : state === 'unscheduled'
          ? 'No fixed boundary'
          : `Next boundary · ${next}`;
  const resolvedProgress = state === 'empty' ? 0 : state === 'complete' ? 100 : state === 'missed' ? 68 : progress;
  const metricPrimary = state === 'empty'
    ? 'Nothing planned'
    : state === 'complete'
      ? 'Everything complete'
      : state === 'missed'
        ? '2 need a decision'
        : state === 'habits'
          ? '2 habits remaining'
          : state === 'unscheduled'
            ? '3 flexible items'
            : '3 complete';
  const metricSecondary = state === 'normal' ? '4 remaining' : '';
  const wide = w >= 760;
  const lineY = y + h - (wide ? 24 : 22);
  const lineStart = x + pad;
  const lineEnd = x + w - pad;
  const markerX = lineStart + (lineEnd - lineStart) * (resolvedProgress / 100);
  const planW = compact ? 78 : 96;
  const planX = x + w - pad - planW;
  const planY = wide ? y + 92 : y + pad;
  const focusRing = focus ? `<rect x="${x - 5}" y="${y - 5}" width="${w + 10}" height="${h + 10}" rx="${compact ? 33 : 39}" fill="none" stroke="${palette.orange}" stroke-width="4"/>` : '';
  const missedNotch = state === 'missed'
    ? `<path d="M${markerX - 9} ${lineY - 17}l9 9 9-9" fill="none" stroke="${palette.red}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>`
    : '';
  const material = `<g>
    ${focusRing}
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${compact ? 28 : 34}" fill="${surface}" stroke="${outline}" stroke-width="${highContrast ? 2.4 : 1.5}" filter="url(#shadow)"/>
    <path d="M${x + w * .56} ${y} C${x + w * .68} ${y + h * .2},${x + w * .76} ${y + h * .28},${x + w} ${y + h * .12}" fill="none" stroke="${dark ? '#5B4C86' : '#D9CEF4'}" stroke-width="${compact ? 35 : 48}" opacity=".24"/>
    <path d="M${x} ${y + h * .1} C${x + w * .2} ${y + h * .28},${x + w * .18} ${y + h * .54},${x + w * .4} ${y + h * .5}" fill="none" stroke="${dark ? '#3A8B71' : '#A9E0C8'}" stroke-width="${compact ? 24 : 32}" opacity=".18"/>
  </g>`;
  const planControl = `<g>
    <rect x="${planX}" y="${planY}" width="${planW}" height="${compact ? 48 : 52}" rx="${compact ? 18 : 20}" fill="${highContrast ? 'none' : dark ? '#2A2733' : '#FFFDF9'}" stroke="${outline}" stroke-width="1.4"/>
    ${calendarPlus(planX + (compact ? 13 : 15), planY + (compact ? 10 : 11), palette.orange, compact ? .8 : .86)}
    ${label(planX + planW - (compact ? 11 : 14), planY + (compact ? 31 : 34), 'Plan', { size: compact ? 14 : 15, weight: 720, fill: palette.orange, anchor: 'end' })}
  </g>`;
  const dayline = `<g>
    <path d="M${lineStart} ${lineY} C${x + w * .25} ${lineY - 8},${x + w * .36} ${lineY + 8},${x + w * .48} ${lineY} S${x + w * .72} ${lineY - 8},${lineEnd} ${lineY}" fill="none" stroke="${dark ? '#343746' : '#E9E2DB'}" stroke-width="${compact ? 8 : 10}" stroke-linecap="round" pathLength="100"/>
    <path d="M${lineStart} ${lineY} C${x + w * .25} ${lineY - 8},${x + w * .36} ${lineY + 8},${x + w * .48} ${lineY} S${x + w * .72} ${lineY - 8},${lineEnd} ${lineY}" fill="none" stroke="url(#dayline)" stroke-width="${compact ? 8 : 10}" stroke-linecap="round" pathLength="100" stroke-dasharray="${resolvedProgress} ${100 - resolvedProgress}"/>
    <circle cx="${lineStart}" cy="${lineY}" r="${compact ? 5 : 6}" fill="${palette.mint}"/>
    <circle cx="${lineEnd}" cy="${lineY}" r="${compact ? 5 : 6}" fill="${dark ? '#525568' : '#D7D0C8'}"/>
    ${resolvedProgress > 0 && resolvedProgress < 100 ? `<circle cx="${markerX}" cy="${lineY}" r="${compact ? 9 : 11}" fill="${dark ? palette.dark : palette.surface}" stroke="${state === 'missed' ? palette.red : palette.lilac}" stroke-width="4" filter="url(#glow)"/>` : ''}
    ${missedNotch}
  </g>`;
  if (wide) {
    const col2 = x + w * .34;
    const col3 = x + w * .65;
    const copyTop = y + 30;
    return `<g>
      ${material}
      <path d="M${col2 - 22} ${y + 24}v${Math.max(92, h - 70)}M${col3 - 22} ${y + 24}v${Math.max(92, h - 70)}" stroke="${outline}" stroke-width="1.2" opacity=".9"/>
      ${label(x + pad, copyTop + 15, 'NOW', { size: 13, weight: 760, fill: muted, letter: 1.8 })}
      ${label(x + pad, copyTop + 63, time, { size: 48, weight: 760, fill: ink, letter: -2.2 })}
      ${label(x + pad + 126, copyTop + 63, period, { size: 15, weight: 760, fill: ink })}
      ${label(x + pad, copyTop + 91, 'Friday, August 14', { size: 14, weight: 560, fill: muted })}
      ${label(x + pad, copyTop + 116, '۲۳ مرداد ۱۴۰۵', { size: 14, weight: 560, fill: muted, family: 'fa' })}
      ${label(col2, copyTop + 15, 'DAY SO FAR', { size: 13, weight: 760, fill: muted, letter: 1.7 })}
      ${label(col2, copyTop + 58, metricPrimary, { size: 22, weight: 720, fill: state === 'missed' ? palette.red : ink })}
      ${metricSecondary ? label(col2, copyTop + 88, metricSecondary, { size: 17, weight: 590, fill: muted }) : ''}
      ${label(col3, copyTop + 15, 'NEXT BOUNDARY', { size: 13, weight: 760, fill: muted, letter: 1.7 })}
      ${label(col3, copyTop + 58, state === 'normal' || state === 'habits' ? next : boundary, { size: 18, weight: 700, fill: ink })}
      ${planControl}
      ${dayline}
    </g>`;
  }
  const dateBlock = largeText
    ? `${label(x + pad, y + 124, 'Friday, August 14', { size: 17, weight: 580, fill: muted })}${label(x + pad, y + 150, '۲۳ مرداد ۱۴۰۵', { size: 17, weight: 580, fill: muted, family: 'fa' })}`
    : `${label(x + pad, y + pad + 17 + timeSize * 1.35, 'Friday, Aug 14', { size: compact ? 14 : 17, weight: 560, fill: muted })}${label(x + w - pad, y + pad + 17 + timeSize * 1.35, '۲۳ مرداد ۱۴۰۵', { size: compact ? 14 : 17, weight: 560, fill: muted, anchor: 'end', family: 'fa' })}`;
  return `<g>
    ${material}
    ${label(x + pad, y + pad + 17, 'NOW', { size: largeText ? 16 : compact ? 14 : 16, weight: 760, fill: muted, letter: 1.8 })}
    ${label(x + pad, y + pad + 17 + timeSize * .9, time, { size: timeSize, weight: 760, fill: ink, letter: -2.6 })}
    ${label(x + pad + timeSize * 2.15, y + pad + 17 + timeSize * .9, period, { size: largeText ? 18 : compact ? 16 : 18, weight: 760, fill: ink })}
    ${dateBlock}
    ${planControl}
    ${label(x + pad, lineY - (largeText ? 40 : 42), metric, { size: largeText ? 19 : compact ? 16 : 20, weight: 700, fill: state === 'missed' ? palette.red : ink })}
    ${label(x + w - pad, lineY - (largeText ? 15 : 17), boundary, { size: largeText ? 15 : compact ? 13 : 16, weight: 570, fill: muted, anchor: 'end' })}
    ${dayline}
  </g>`;
}

function syncPill(x, y, status = 'synced', dark = false, compact = false) {
  const color = status === 'syncing' ? palette.yellow : status === 'error' ? palette.red : '#2CA095';
  const words = status === 'syncing' ? 'Syncing' : status === 'error' ? 'Retrying' : status === 'offline' ? 'Offline' : 'Synced';
  const w = compact ? 128 : 154;
  return `<g>
    <rect x="${x}" y="${y}" width="${w}" height="54" rx="27" fill="${dark ? palette.darkSurfaceAlt : '#FFFFFFCC'}" stroke="${color}" stroke-width="1.5"/>
    ${cloudIcon(x + 11, y + 9, color, status === 'offline' ? 'error' : status, .67)}
    ${label(x + w - 14, y + 34, words, { size: compact ? 14 : 16, weight: 700, fill: color, anchor: 'end' })}
  </g>`;
}

function row({ x, y, w, time, title, meta, state = 'pending', rtl = false, habit = false, dark = false }) {
  const ink = dark ? palette.darkInk : palette.ink;
  const muted = dark ? palette.darkMuted : palette.muted;
  const accent = state === 'done' ? palette.mint : state === 'missed' ? palette.red : state === 'partial' ? palette.lilac : palette.orange;
  const textX = rtl ? x + w - 50 : x + 120;
  const anchor = rtl ? 'end' : 'start';
  const stateGlyph = state === 'done' ? '✓' : state === 'missed' ? '×' : state === 'partial' ? '—' : '';
  return `<g>
    ${label(x, y + 31, time, { size: 14, weight: 620, fill: muted })}
    <rect x="${x + 48}" y="${y}" width="${w - 48}" height="76" rx="20" fill="${dark ? '#1E202A' : '#FFFFFFA6'}" stroke="${dark ? palette.darkOutline : '#ECE4DC'}" stroke-width="1.2"/>
    <rect x="${x + 58}" y="${y + 14}" width="48" height="48" rx="16" fill="${habit ? palette.mintSoft : state === 'missed' ? palette.redSoft : '#F5F1EC'}"/>
    ${habit
      ? `<path d="M${x + 72} ${y + 45}c10-2 16-10 17-19 7 8 10 18 3 27-7 8-20 5-20-8Z" fill="none" stroke="#3A9872" stroke-width="2.4" stroke-linecap="round"/>`
      : `<circle cx="${x + 82}" cy="${y + 38}" r="13" fill="none" stroke="${accent}" stroke-width="3"/>${label(x + 82, y + 44, stateGlyph, { size: 18, weight: 760, fill: accent, anchor: 'middle' })}`}
    ${label(textX, y + 31, title, { size: rtl ? 15 : 16, weight: 700, fill: ink, anchor, family: rtl ? 'fa' : '' })}
    ${label(textX, y + 54, meta, { size: 13, weight: 520, fill: muted, anchor, family: rtl ? 'fa' : '' })}
    <path d="M${x + w - 24} ${y + 31}l7 7-7 7" fill="none" stroke="${muted}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  </g>`;
}

function footer(x, y, w, dark = false) {
  const ink = dark ? palette.darkMuted : palette.muted;
  const selected = dark ? '#342B31' : '#FFF0E3';
  const centers = [x + 42, x + w * .28, x + w * .5, x + w * .72, x + w - 42];
  return `<g filter="url(#softShadow)">
    <rect x="${x}" y="${y}" width="${w}" height="70" rx="30" fill="${dark ? '#1E2029E8' : '#FFFFFFD9'}" stroke="${dark ? palette.darkOutline : palette.outline}" stroke-width="1.3"/>
    <rect x="${centers[0] - 24}" y="${y + 11}" width="48" height="48" rx="17" fill="${selected}"/>
    <g stroke="${ink}" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round">
      <rect x="${centers[0] - 10}" y="${y + 26}" width="20" height="18" rx="4"/><path d="M${centers[0] - 6} ${y + 21}v8M${centers[0] + 6} ${y + 21}v8"/>
      <circle cx="${centers[1]}" cy="${y + 35}" r="11"/><path d="M${centers[1] - 5} ${y + 35}l4 4 7-9"/>
      <circle cx="${centers[2]}" cy="${y + 35}" r="11"/><path d="M${centers[2]} ${y + 27}v9l6 4"/>
      <path d="M${centers[3] - 9} ${y + 42}c2-13 9-18 19-19-1 11-6 18-19 19Z"/><path d="M${centers[3] - 8} ${y + 43}l12-12"/>
      <path d="M${centers[4] - 10} ${y + 27}h20M${centers[4] - 10} ${y + 35}h20M${centers[4] - 10} ${y + 43}h20"/>
    </g>
    <circle cx="${centers[0]}" cy="${y + 59}" r="2.4" fill="${palette.orange}"/>
  </g>`;
}

function navGlyph(cx, cy, index, color) {
  const common = `fill="none" stroke="${color}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"`;
  if (index === 0) {
    return `<g ${common}><rect x="${cx - 10}" y="${cy - 9}" width="20" height="18" rx="4"/><path d="M${cx - 6} ${cy - 14}v8M${cx + 6} ${cy - 14}v8M${cx - 10} ${cy - 3}h20"/></g>`;
  }
  if (index === 1) {
    return `<g ${common}><circle cx="${cx}" cy="${cy}" r="11"/><path d="M${cx - 5} ${cy}l4 4 7-9"/></g>`;
  }
  if (index === 2) {
    return `<g ${common}><circle cx="${cx}" cy="${cy}" r="11"/><path d="M${cx} ${cy - 7}v8l6 4"/></g>`;
  }
  if (index === 3) {
    return `<g ${common}><path d="M${cx - 9} ${cy + 8}c2-13 9-18 19-19-1 11-6 18-19 19Z"/><path d="M${cx - 8} ${cy + 9}l12-12"/></g>`;
  }
  return `<g ${common}><path d="M${cx - 10} ${cy - 8}h20M${cx - 10} ${cy}h20M${cx - 10} ${cy + 8}h20"/></g>`;
}

function captureOrb(cx, cy) {
  return `<g filter="url(#shadow)"><circle cx="${cx}" cy="${cy}" r="38" fill="#FFFFFFAA" stroke="#D8D2E8"/><circle cx="${cx}" cy="${cy}" r="31" fill="url(#capture)"/><path d="M${cx - 10} ${cy}h20M${cx} ${cy - 10}v20" stroke="#FFF" stroke-width="3" stroke-linecap="round"/></g>`;
}

function phoneFrame({ x, y, scale = 1, mode = 'normal', dark = false, status = 'synced', title = 'Good evening', dense = false, stress = false }) {
  const w = 430;
  const h = 932;
  const ink = dark ? palette.darkInk : palette.ink;
  const muted = dark ? palette.darkMuted : palette.muted;
  const rows = mode === 'empty' ? [] : mode === 'complete'
    ? [
        ['8:00', 'Morning review', 'Work · completed', 'done', false, false],
        ['12:30', 'Walk outside', 'Health · completed', 'done', false, false],
      ]
    : dense
      ? [
          ['7:15', 'Review project brief', 'Work · 60%', 'partial', false, false],
          ['8:00', 'Focus deep work', 'Work · 45 min', 'pending', false, false],
          ['11:30', 'مرور برنامه هفتگی', 'مطالعه · ۴۵ دقیقه', 'pending', false, true],
          ['14:00', 'Drink water', '5 of 8 · 6 day streak', 'partial', true, false],
        ]
      : [
          ['7:15', 'Review project brief', 'Work · 60%', 'partial', false, false],
          ['8:00', 'Focus deep work', 'Work · 45 min', 'pending', false, false],
          ['11:30', 'Drink water', '5 of 8 · 6 day streak', 'partial', true, false],
        ];
  let body = `<g transform="translate(${x} ${y}) scale(${scale})">
    <rect width="${w}" height="${h}" rx="42" fill="${dark ? palette.dark : palette.paper}" stroke="${dark ? palette.darkOutline : '#DCD5CD'}" stroke-width="2" filter="url(#shadow)"/>
    <rect x="1" y="1" width="428" height="52" rx="40" fill="${dark ? '#151721' : '#FFFDF9'}" opacity=".92"/>
    ${label(24, 34, '7:42', { size: 15, weight: 700, fill: ink })}
    <rect x="337" y="20" width="18" height="10" rx="2" fill="none" stroke="${ink}" stroke-width="2"/><rect x="340" y="23" width="10" height="4" rx="1" fill="${ink}"/>
    <image href="${dark ? wordmarks.dark : wordmarks.light}" x="24" y="72" width="142" height="32" preserveAspectRatio="xMinYMid meet"/>
    ${syncPill(274, 63, status, dark, true)}
    ${label(24, 142, 'TODAY', { size: 13, weight: 760, fill: muted, letter: 2 })}
    ${/[؀-ۿ]/.test(title)
      ? label(406, 175, title, { size: stress ? 30 : 27, weight: 720, fill: ink, anchor: 'end', family: 'fa' })
      : label(24, 175, title, { size: 27, weight: 720, fill: ink, letter: -.7 })}
    ${pulseInstrument({ x: 20, y: 202, w: 390, h: stress ? 250 : 218, dark, highContrast: stress, state: mode, progress: dense ? 38 : 43, compact: true, largeText: stress })}
    ${label(24, stress ? 474 : 442, rows.length === 0 ? 'YOUR DAY' : 'NEXT AND LATER', { size: stress ? 15 : 13, weight: 760, fill: muted, letter: 1.6 })}
    ${rows.length === 0
      ? `<rect x="20" y="${stress ? 496 : 462}" width="390" height="234" rx="28" fill="${dark ? palette.darkSurface : '#FFFFFFB8'}" stroke="${dark ? palette.darkOutline : palette.outline}"/>
         <path d="M185 ${stress ? 560 : 526}c20-14 50-14 70 0" fill="none" stroke="${palette.mint}" stroke-width="5" stroke-linecap="round"/>
         ${label(215, stress ? 609 : 575, 'Your day has room.', { size: 22, weight: 720, fill: ink, anchor: 'middle' })}
         ${label(215, stress ? 641 : 607, 'Capture something meaningful, or leave it open.', { size: 14, weight: 520, fill: muted, anchor: 'middle' })}
         <rect x="143" y="${stress ? 666 : 632}" width="144" height="48" rx="19" fill="${palette.orangeSoft}"/>
         ${calendarPlus(158, stress ? 677 : 643, '#B95F16', .8)}${label(267, stress ? 697 : 663, 'Plan the day', { size: 15, weight: 720, fill: '#A95210', anchor: 'end' })}`
      : rows.map((entry, index) => row({
          x: 24,
          y: (stress ? 496 : 462) + index * 80,
          w: 382,
          time: entry[0],
          title: entry[1],
          meta: entry[2],
          state: entry[3],
          habit: entry[4],
          rtl: entry[5],
          dark,
        })).join('')}
    ${footer(18, 850, 394, dark)}
    ${captureOrb(215, 822)}
  </g>`;
  return body;
}

function wideFrame({ x, y, w = 1120, h = 700, dark = false, status = 'synced', dense = false, tablet = false }) {
  const ink = dark ? palette.darkInk : palette.ink;
  const muted = dark ? palette.darkMuted : palette.muted;
  const rail = tablet ? 84 : 176;
  const contentX = x + rail + 38;
  const contentW = w - rail - 76;
  const entries = [
    ['7:15', 'Review project brief', 'Work · 60%', 'partial', false, false],
    ['8:00', 'Focus deep work', 'Work · 45 min', 'pending', false, false],
    ['11:30', 'مرور برنامه هفتگی', 'مطالعه · ۴۵ دقیقه', 'pending', false, true],
    ['14:00', 'Drink water', '5 of 8 · 6 day streak', 'partial', true, false],
    ['15:30', 'Client follow-up', 'Work · 20 min', 'pending', false, false],
    ['17:00', 'Walk outside', 'Health · 30 min', 'pending', false, false],
    ['19:20', 'Read two chapters', 'Personal · 50 min', 'pending', false, false],
    ['21:00', 'Plan tomorrow', 'Planning · 20 min', 'missed', false, false],
  ];
  const short = h < 520;
  const rows = short ? 2 : Math.max(2, Math.min(entries.length, Math.floor((h - 432) / 76)));
  let body = `<g>
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="28" fill="${dark ? palette.dark : palette.paper}" stroke="${dark ? palette.darkOutline : '#DCD5CD'}" stroke-width="2" filter="url(#shadow)"/>
    <rect x="${x}" y="${y}" width="${rail}" height="${h}" rx="28" fill="${dark ? '#171923' : '#FFFFFFB8'}"/>
    <path d="M${x + rail} ${y}v${h}" stroke="${dark ? palette.darkOutline : palette.outline}"/>
    <image href="${tablet ? (dark ? marks.dark : marks.light) : (dark ? wordmarks.dark : wordmarks.light)}" x="${x + (tablet ? 23 : 28)}" y="${y + 26}" width="${tablet ? 38 : 116}" height="42" preserveAspectRatio="xMidYMid meet"/>
    ${['Today', 'Tasks', 'Plan', 'Habits', 'More'].map((item, index) => {
      const cy = y + (short ? 88 + index * 48 : 130 + index * 62);
      const selectedH = short ? 38 : 48;
      return `${index === 0 ? `<rect x="${x + 12}" y="${cy - selectedH / 2}" width="${rail - 24}" height="${selectedH}" rx="${short ? 15 : 18}" fill="${dark ? '#312732' : '#FFF0E3'}"/><rect x="${x + 12}" y="${cy - (short ? 11 : 14)}" width="4" height="${short ? 22 : 28}" rx="2" fill="${palette.orange}"/>` : ''}
        ${navGlyph(x + 34, cy, index, index === 0 ? ink : muted)}${!tablet ? label(x + 58, cy + 6, item, { size: 15, weight: index === 0 ? 700 : 560, fill: index === 0 ? ink : muted }) : ''}`;
    }).join('')}
    ${label(contentX, y + (short ? 38 : 54), 'TODAY', { size: 13, weight: 760, fill: muted, letter: 2 })}
    ${!short ? label(contentX, y + 89, dense ? 'A full day, still calm' : 'Good evening', { size: 28, weight: 720, fill: ink, letter: -.7 }) : ''}
    ${syncPill(x + w - 168, y + 26, status, dark, false)}
    ${short
      ? `${pulseInstrument({ x: contentX, y: y + 68, w: contentW * .48, h: 228, dark, state: 'normal', progress: 43, compact: true })}
         ${label(contentX + contentW * .52, y + 82, 'NEXT AND LATER', { size: 13, weight: 760, fill: muted, letter: 1.7 })}
         ${entries.slice(0, 2).map((e, index) => row({ x: contentX + contentW * .52, y: y + 102 + index * 86, w: contentW * .48, time: e[0], title: e[1], meta: e[2], state: e[3], habit: e[4], rtl: e[5], dark })).join('')}`
      : `${pulseInstrument({ x: contentX, y: y + 120, w: contentW, h: 184, dark, state: 'normal', progress: dense ? 38 : 43 })}
         ${label(contentX, y + 350, 'NEXT AND LATER', { size: 13, weight: 760, fill: muted, letter: 1.7 })}
         <rect x="${contentX}" y="${y + 370}" width="${contentW}" height="${rows * 76 + 34}" rx="28" fill="${dark ? palette.darkSurface : '#FFFFFFB8'}" stroke="${dark ? palette.darkOutline : palette.outline}"/>
         ${entries.slice(0, rows).map((e, index) => row({ x: contentX + 22, y: y + 386 + index * 76, w: contentW - 44, time: e[0], title: e[1], meta: e[2], state: e[3], habit: e[4], rtl: e[5], dark })).join('')}`}
  </g>`;
  return body;
}

function candidateComparison() {
  const cards = [
    { x: 90, title: 'A · Dayline', note: 'Selected · one calm instrument', kind: 'dayline' },
    { x: 870, title: 'B · Split ticker', note: 'Rejected · too dashboard-like', kind: 'split' },
    { x: 1650, title: 'C · Calm ledger', note: 'Rejected · too administrative', kind: 'ledger' },
  ];
  const content = cards.map((card) => {
    const selected = card.kind === 'dayline';
    return `<g>
      <rect x="${card.x}" y="280" width="660" height="760" rx="38" fill="#FFFFFFC9" stroke="${selected ? palette.orange : palette.outline}" stroke-width="${selected ? 4 : 2}" filter="url(#shadow)"/>
      ${label(card.x + 38, 340, card.title, { size: 30, weight: 760 })}
      ${label(card.x + 38, 380, card.note, { size: 18, weight: 560, fill: selected ? '#A95210' : palette.muted })}
      ${card.kind === 'dayline'
        ? pulseInstrument({ x: card.x + 36, y: 440, w: 588, h: 300, progress: 43 })
        : card.kind === 'split'
          ? `<rect x="${card.x + 36}" y="440" width="280" height="300" rx="30" fill="url(#pulseDay)" stroke="${palette.outline}"/>${label(card.x + 66, 510, '7:42 PM', { size: 48, weight: 760 })}<rect x="${card.x + 336}" y="440" width="288" height="300" rx="30" fill="#FFF" stroke="${palette.outline}"/>${label(card.x + 368, 502, '3 complete', { size: 24, weight: 700 })}${label(card.x + 368, 545, '4 remaining', { size: 24, weight: 700 })}`
          : `<rect x="${card.x + 36}" y="440" width="588" height="300" rx="30" fill="#FFF" stroke="${palette.outline}"/>${['Time  7:42 PM','Done  3','Left  4','Next  8:00 PM'].map((value, index) => `${label(card.x + 70, 500 + index * 58, value, { size: 22, weight: 650 })}<path d="M${card.x + 70} ${518 + index * 58}h500" stroke="${palette.outline}"/>`).join('')}`}
      <rect x="${card.x + 36}" y="790" width="588" height="196" rx="28" fill="#FFF" stroke="${palette.outline}"/>
      ${label(card.x + 68, 846, selected ? 'Why it wins' : 'Why it loses', { size: 18, weight: 760, fill: selected ? '#A95210' : palette.muted, letter: 1 })}
      ${label(card.x + 68, 892, selected ? 'One scan path; no repeated task title.' : card.kind === 'split' ? 'Two cards fragment one answer.' : 'Fast to scan, emotionally flat.', { size: 19, weight: 570 })}
      ${label(card.x + 68, 932, selected ? 'Progress and boundary share one line.' : card.kind === 'split' ? 'Metrics compete with the task stream.' : 'Feels like project administration.', { size: 19, weight: 570 })}
    </g>`;
  }).join('');
  return document(2400, 1120, `${boardHeader('Today Pulse · concept selection', 'Three structurally distinct directions, judged against real daily use')}${content}`);
}

function componentStates() {
  const states = [
    ['Empty', 'empty', 0, 'synced'],
    ['All complete', 'complete', 100, 'synced'],
    ['Missed only', 'missed', 68, 'error'],
    ['Habits only', 'habits', 55, 'synced'],
    ['Unscheduled only', 'unscheduled', 22, 'offline'],
    ['Syncing / retry', 'normal', 43, 'syncing'],
  ];
  const body = states.map((entry, index) => {
    const col = index % 2;
    const rowIndex = Math.floor(index / 2);
    const x = 92 + col * 1154;
    const y = 330 + rowIndex * 310;
    return `<g>${label(x, y - 22, entry[0], { size: 21, weight: 740, fill: palette.muted, letter: .7 })}${syncPill(x + 888, y - 66, entry[3], false, false)}${pulseInstrument({ x, y, w: 1058, h: 230, state: entry[1], progress: entry[2] })}</g>`;
  }).join('');
  return document(2400, 1260, `${boardHeader('Dayline · semantic state matrix', 'No ring, no duplicated task title, no decorative metric card grid')}${body}`);
}

function phoneDensityMatrix() {
  return document(2400, 1360, `${boardHeader('Today · phone density matrix', 'Empty, complete, normal and dense all preserve useful stream space')}
    ${phoneFrame({ x: 80, y: 280, scale: 1, mode: 'empty', title: 'A day with room' })}
    ${phoneFrame({ x: 660, y: 280, scale: 1, mode: 'complete', title: 'Day complete' })}
    ${phoneFrame({ x: 1240, y: 280, scale: 1, mode: 'normal', title: 'Good evening' })}
    ${phoneFrame({ x: 1820, y: 280, scale: 1, mode: 'normal', title: 'A full day, still calm', dense: true })}`);
}

function stressMatrix() {
  const landscape = `<g transform="translate(900 312)">
    <rect width="1360" height="640" rx="38" fill="${palette.paper}" stroke="${palette.outline}" stroke-width="2" filter="url(#shadow)"/>
    <image href="${wordmarks.light}" x="30" y="32" width="132" height="30"/>
    ${syncPill(1190, 22, 'syncing', false, false)}
    ${pulseInstrument({ x: 34, y: 98, w: 1292, h: 238, state: 'normal', progress: 43 })}
    ${label(34, 384, 'NEXT AND LATER', { size: 14, weight: 760, fill: palette.muted, letter: 1.8 })}
    ${row({ x: 34, y: 408, w: 620, time: '7:15', title: 'Review project brief', meta: 'Work · 60%', state: 'partial' })}
    ${row({ x: 676, y: 408, w: 650, time: '11:30', title: 'مرور برنامه هفتگی و زمان‌های آزاد', meta: 'مطالعه · ۴۵ دقیقه', rtl: true })}
    ${footer(438, 548, 484, false)}${captureOrb(680, 535)}
  </g>`;
  return document(2400, 1240, `${boardHeader('Stress and short-height recomposition', '200% mixed text stacks; landscape uses two rows instead of squeezing copy')}
    ${phoneFrame({ x: 120, y: 280, scale: .88, mode: 'normal', title: 'امروز با تمرکز پیش می‌ره', dense: false, stress: true })}
    ${landscape}`);
}

function adaptiveMatrix() {
  return document(2400, 1520, `${boardHeader('Adaptive Today composition', 'Bounded columns share one axis; the stream receives the reclaimed Orbit space')}
    ${wideFrame({ x: 90, y: 280, w: 930, h: 1100, tablet: true, dense: true })}
    ${wideFrame({ x: 1080, y: 280, w: 1220, h: 760, tablet: false, dense: true })}
    ${wideFrame({ x: 1080, y: 1080, w: 1220, h: 330, tablet: false, dense: false })}`);
}

function themeMatrix() {
  return document(2400, 1160, `${boardHeader('Dayline · authored theme matrix', 'Daylight, Graphite Bloom and Clarity keep the same geometry and semantic cues')}
    <g>${label(90, 300, 'DAYLIGHT', { size: 18, weight: 760, fill: palette.muted, letter: 1.8 })}${pulseInstrument({ x: 90, y: 330, w: 700, h: 360, state: 'normal', progress: 43 })}</g>
    <g>${label(850, 300, 'GRAPHITE BLOOM', { size: 18, weight: 760, fill: palette.muted, letter: 1.8 })}<rect x="830" y="316" width="740" height="394" rx="42" fill="${palette.dark}"/>${pulseInstrument({ x: 850, y: 330, w: 700, h: 360, state: 'normal', progress: 43, dark: true })}</g>
    <g>${label(1610, 300, 'CLARITY LIGHT', { size: 18, weight: 760, fill: palette.muted, letter: 1.8 })}${pulseInstrument({ x: 1610, y: 330, w: 700, h: 360, state: 'normal', progress: 43, highContrast: true })}</g>
    <g>${label(90, 808, 'SYNC STATES · NON-COLOR CUES', { size: 18, weight: 760, fill: palette.muted, letter: 1.8 })}${syncPill(90, 842, 'synced')}${syncPill(270, 842, 'syncing')}${syncPill(450, 842, 'error')}${syncPill(630, 842, 'offline')}</g>
    ${label(1610, 850, 'One geometry · authored material per theme', { size: 26, weight: 720 })}${label(1610, 894, 'Focus outline and words remain visible without color.', { size: 18, weight: 540, fill: palette.muted })}`);
}

function motionStoryboard() {
  const frames = [
    ['0 ms', 0, 14, 'Shell stable'],
    ['90 ms', .35, 10, 'Title rises'],
    ['150 ms', .62, 6, 'Pulse resolves'],
    ['220 ms', .85, 2, 'Stream joins'],
    ['280 ms', 1, 0, 'Ready'],
  ];
  const body = frames.map((entry, index) => {
    const x = 80 + index * 460;
    const opacity = .2 + entry[1] * .8;
    return `<g>
      ${label(x, 310, entry[0], { size: 18, weight: 760, fill: palette.orange, letter: 1 })}
      <rect x="${x}" y="340" width="410" height="530" rx="32" fill="#FFFFFFC9" stroke="${palette.outline}" filter="url(#softShadow)"/>
      <image href="${wordmarks.light}" x="${x + 24}" y="${374 - entry[2]}" width="126" height="28" opacity="${opacity}"/>
      <g opacity="${opacity}" transform="translate(0 ${entry[2]})">${pulseInstrument({ x: x + 20, y: 438, w: 370, h: 220, compact: true, progress: 43 })}</g>
      <g opacity="${Math.max(.12, entry[1] - .2)}" transform="translate(0 ${entry[2] * 1.4})">${row({ x: x + 24, y: 690, w: 360, time: '8:00', title: 'Focus deep work', meta: 'Work · 45 min', state: 'pending' })}</g>
      ${label(x + 205, 920, entry[3], { size: 18, weight: 680, anchor: 'middle' })}
    </g>`;
  }).join('');
  return document(2400, 1080, `${boardHeader('Today entrance choreography', 'Stable shell → title → Pulse → stream; never replay on rebuild or scroll')}${body}${label(80, 1012, 'Reduced motion: final geometry appears through a 90 ms crossfade; no rise, travel, pulse or stagger.', { size: 20, weight: 650, fill: palette.muted })}`);
}

function symmetryBoard() {
  const pulseX = 210;
  const pulseY = 330;
  const pulseW = 1980;
  const pulseH = 470;
  return document(2400, 1120, `${boardHeader('Geometry, axes and safe zones', 'Exact axes are measured; optical asymmetry is intentional and bounded')}
    ${pulseInstrument({ x: pulseX, y: pulseY, w: pulseW, h: pulseH, progress: 43 })}
    <path d="M1200 260v640" stroke="${palette.red}" stroke-width="2" stroke-dasharray="10 10" opacity=".7"/>
    <path d="M150 ${pulseY + pulseH / 2}h2100" stroke="${palette.lilac}" stroke-width="2" stroke-dasharray="10 10" opacity=".7"/>
    <rect x="${pulseX + 32}" y="${pulseY + 32}" width="${pulseW - 64}" height="${pulseH - 64}" rx="22" fill="none" stroke="${palette.mint}" stroke-width="2" stroke-dasharray="8 8"/>
    ${label(1208, 302, 'frame center', { size: 16, weight: 700, fill: palette.red })}
    ${label(170, pulseY + pulseH / 2 - 12, 'content baseline', { size: 16, weight: 700, fill: palette.lilac, anchor: 'end' })}
    ${label(pulseX + 42, pulseY + pulseH + 52, '32–40 dp responsive safe zone', { size: 18, weight: 700, fill: '#348565' })}
    ${label(1200, 1000, 'Time/date mass leads the scan; Plan is end-anchored; the Dayline spans the shared content axis.', { size: 20, weight: 570, fill: palette.muted, anchor: 'middle' })}`);
}

const boards = [
  ['candidate-comparison', 2400, 1120, candidateComparison()],
  ['component-state-matrix', 2400, 1260, componentStates()],
  ['phone-density-matrix', 2400, 1360, phoneDensityMatrix()],
  ['stress-responsive-matrix', 2400, 1240, stressMatrix()],
  ['adaptive-matrix', 2400, 1520, adaptiveMatrix()],
  ['theme-system-matrix', 2400, 1160, themeMatrix()],
  ['motion-storyboard', 2400, 1080, motionStoryboard()],
  ['geometry-axis-board', 2400, 1120, symmetryBoard()],
];

function renderBoards() {
  const manifest = [];
  for (const [id, width, height, svg] of boards) {
    const svgFile = path.join(outputRoot, `${id}.svg`);
    const pngFile = path.join(outputRoot, `${id}.png`);
    writeText(svgFile, svg);
    execFileSync(process.execPath, [renderScript, svgFile, pngFile, String(width), String(height)], {
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

function writeContracts(rendered) {
  writeJson(path.join(outputRoot, 'layout-contract.json'), {
    stage: 11,
    concept_id: 'today-pulse-dayline-v2',
    semantic_component_id: 'td-pulse',
    status: 'preview-approved-autonomously',
    generated_at: generatedAt,
    decisions: {
      circular_model: 'removed',
      pulse_model: 'one composed instrument with a slim semantic Dayline',
      stream_ownership: 'task and habit titles, mutation and row detail remain in the stream',
      pulse_content: ['minute-aligned local time', 'Gregorian date', 'Jalali date', 'complete and remaining measure', 'next temporal boundary', 'Plan action'],
      forbidden: ['ring progress', 'clock-face labels', 'heartbeat orbit', 'duplicated next task title', 'metric card grid', 'decorative substitute for Orbit'],
    },
    geometry: {
      phone: { outer_gutter: 20, pulse_min_height: 218, pulse_max_height_at_200_percent: 250, plan_target: 48, stream_gap: 28 },
      short_landscape: { rows: 2, horizontal_gutter: 34, pulse_height: 238 },
      tablet: { rail: 84, content_gutter: 38, pulse_height: 184, columns: 3 },
      windows: { rail_expanded: 176, content_gutter: 38, pulse_height: 184, max_content_width: 1320 },
      semantic_fixed_tokens: ['48dp minimum target', '2dp focus boundary', 'icon stroke', 'corner rhythm'],
      adaptive_tokens: ['intrinsic copy width', 'bounded pane fractions', 'content-driven reflow', 'safe-area/footer clearance'],
    },
    state_matrix: ['empty', 'all-complete', 'missed-only', 'habits-only', 'unscheduled-only', 'syncing', 'offline', 'retry-error'],
    rendered_boards: rendered,
  });

  writeJson(path.join(outputRoot, 'decomposition-manifest.json'), {
    concept_id: 'today-pulse-dayline-v2',
    live_layers: [
      'time and AM/PM',
      'Gregorian and Jalali dates with direction isolation',
      'complete/remaining projection copy',
      'next boundary copy',
      'Plan control and semantics',
      'sync state and retry semantics',
      'Dayline progress value and non-color cues',
    ],
    authored_layers: [
      'theme-specific material field',
      'semantic linear Dayline stroke',
      'bounded soft bloom',
      'project-owned vector icons',
    ],
    forbidden_flattening: ['planner data', 'time/date', 'status', 'actions', 'screen-reader copy'],
    implementation_boundary: 'Preview geometry is authoritative; all dynamic values remain live Flutter semantics.',
  });

  writeText(path.join(outputRoot, 'decision.md'), `# Stage 11 Today Pulse preview decision

Status: **autonomously approved for implementation**

## Selected direction

**Dayline** replaces Orbit. It is one responsive orientation instrument, not a
dashboard grid and not a disguised circular dial. The time/date mass starts the
scan, a live semantic line visualises daily completion, the next boundary closes
the scan, and the only control is Plan. Task and Habit titles remain solely in the
stream so the Pulse never repeats the row immediately below it.

## Rejected directions

- **Split ticker:** two adjacent cards fragmented one answer and competed with the
  stream.
- **Calm ledger:** fast to scan but emotionally administrative for a personal day.

## Supersession

The Stage 04/05 **td-pulse** preview remains immutable historical catalog evidence.
Its circular percent ring and decorative arc are explicitly superseded for Stage 11
by **today-pulse-dayline-v2** because the approved stage contract forbids an
Orbit-like substitute.

## Acceptance

The eight generated boards cover component state, phone density, short landscape,
200% mixed Persian/English copy, tablet, Windows, theme/contrast, entrance motion,
and measured axes. Preview fixtures are synthetic and must never enter owner data.
`);

  writeText(path.join(outputRoot, 'symmetry-ledger.md'), `# Stage 11 symmetry and placement ledger

| Group | Contract | Verification |
| --- | --- | --- |
| Pulse outer frame | exact centered within the live content column | equal logical gutters; axis overlay |
| Time and AM/PM | optical baseline, not box-center | AM/PM aligns to numeric baseline |
| Gregorian/Jalali block | start aligned with per-span direction isolation | no mirrored punctuation or broken date |
| Plan control | end anchored, >=48dp, independent from time mass | does not shift when dates grow |
| Dayline | spans shared safe inset; marker represents value | no ring; no decorative false progress |
| Phone footer/capture | exact viewport center for orb; footer icons balanced by visual mass | safe clearance from last row and system inset |
| Wide three-column Pulse | controlled asymmetry around information weight | bounded columns; no stretched one-line copy |
`);

  writeText(path.join(outputRoot, 'preview-runtime-mismatch-ledger.md'), `# Stage 11 preview / runtime mismatch ledger

Status: **preview and Android runtime comparison closed; hosted Windows row remains the checkpoint gate**

| Surface | Preview authority | Runtime result | Evidence / remaining boundary |
| --- | --- | --- | --- |
| Phone Today | **phone-density-matrix.png** | Closed: one bounded Pulse, no Orbit tree/semantics, no duplicated task title, three actionable rows in the first view | \`runtime/android/phone-runtime.png\` + fresh semantics XML; preview fixture only |
| Short landscape / 200% | **stress-responsive-matrix.png** | Flutter stress tests pass at 200%; live tablet landscape uses the wide three-column composition | physical short-landscape recording remains outside this emulator capture |
| Tablet / Windows | **adaptive-matrix.png** | Android portrait and landscape closed; one Pulse sits above the dominant scrollable stream | hosted exact-SHA Windows composition/install-over remains mandatory |
| Theme / contrast | **theme-system-matrix.png** | Closed in source/goldens: Dayline resolves semantic roles; retired Orbit assets are deleted | Stage 10 theme verifier plus Stage 11 dark/high-contrast widget tests |
| Motion | **motion-storyboard.png** | Minute tick is isolated to Pulse; row identity/scroll stay stable; reduced motion resolves to zero-duration | physical frame-pacing is not claimed from the emulator |
| Geometry | **geometry-axis-board.png** | Phone/tablet axes remain aligned; scrolled final item ends at y=1318 and clears capture at y=1396 | bounds are locked in \`runtime-manifest.json\` |

## Android runtime checkpoint

- Preview APK \`1.1.0-preview+2064\` installed with \`adb install -r -t\` over build
  2063; \`firstInstallTime=2026-08-02 19:20:44\` remained unchanged.
- Final emulator state is reset to its physical \`1080×2400 @ 420dpi\` phone
  profile and the exact preview activity remains foregrounded.
- The clean launch log has zero \`FATAL EXCEPTION\`, app-process, \`E/flutter\`,
  \`RenderFlex\` or package ANR matches.
- Nine screenshots/semantic/log artifacts are hash-locked by
  \`runtime/android/runtime-manifest.json\`; the verifier rejects byte or semantic
  drift.
- Deterministic Alex/task content belongs only to \`lib/dev/perfect_live_preview.dart\`;
  it is not owner seed data and does not weaken the empty-account contract.
`);
}

function main() {
  resetOutput();
  const rendered = renderBoards();
  writeContracts(rendered);
  const manifestFiles = fs.readdirSync(outputRoot)
    .filter((name) => name !== 'runtime' && !name.startsWith('preview-manifest.'))
    .sort()
    .map((name) => ({
      file: relative(path.join(outputRoot, name)),
      bytes: fs.statSync(path.join(outputRoot, name)).size,
      sha256: sha256File(path.join(outputRoot, name)),
    }));
  writeJson(path.join(outputRoot, 'preview-manifest.json'), {
    stage: 11,
    generated_at: generatedAt,
    generator: relative(__filename),
    concept_id: 'today-pulse-dayline-v2',
    board_count: rendered.length,
    files: manifestFiles,
  });
  process.stdout.write(`STAGE11_PREVIEW_GENERATED boards=${rendered.length} files=${manifestFiles.length + 1}\n`);
}

main();
