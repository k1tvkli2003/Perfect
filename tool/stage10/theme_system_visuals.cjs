const model = require('./theme_system_model.cjs');

function escapeXml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function cssColor(value) {
  if (/^#[0-9a-f]{8}$/i.test(value)) {
    return `#${value.slice(3)}${value.slice(1, 3)}`;
  }
  return value;
}

function svgDocument({ width, height, title, content, assets }) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
  <title id="title">${escapeXml(title)}</title>
  <desc id="desc">Deterministic Perfect Stage 10 theme preview. Design evidence only; no production data.</desc>
  <defs>
    <style>
      @font-face{font-family:PerfectLatin;src:url('${assets.plusJakarta}') format('truetype');font-weight:100 900}
      @font-face{font-family:PerfectPersian;src:url('${assets.vazirmatn}') format('truetype');font-weight:100 900}
      text{font-family:PerfectLatin,PerfectPersian,sans-serif;font-kerning:normal}
      .mono{font-family:ui-monospace,Consolas,monospace}
    </style>
    <filter id="shadow" x="-30%" y="-30%" width="160%" height="180%"><feDropShadow dx="0" dy="12" stdDeviation="18" flood-color="#221A2D" flood-opacity=".12"/></filter>
    <filter id="shadow-dark" x="-30%" y="-30%" width="160%" height="180%"><feDropShadow dx="0" dy="16" stdDeviation="22" flood-color="#000" flood-opacity=".42"/></filter>
    <filter id="glow" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="11"/></filter>
    <linearGradient id="brand-gradient" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFA34D"/><stop offset=".5" stop-color="#7EC99B"/><stop offset="1" stop-color="#A79ADD"/></linearGradient>
    <linearGradient id="brand-gradient-dark" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFC184"/><stop offset=".5" stop-color="#A8DFB9"/><stop offset="1" stop-color="#D1C6FF"/></linearGradient>
  </defs>
  ${content}
</svg>`;
}

function boardBackground(width, height) {
  return `<rect width="${width}" height="${height}" fill="#F2EEE9"/><circle cx="${width - 180}" cy="92" r="260" fill="#EEE7FB" opacity=".46"/><circle cx="110" cy="${height - 60}" r="300" fill="#E3F2EA" opacity=".5"/>`;
}

function boardHeader({ title, subtitle, width, tag = model.catalogVersion }) {
  return `<g transform="translate(70 58)">
    <text x="0" y="0" dominant-baseline="hanging" fill="#1D2030" font-size="36" font-weight="820" letter-spacing="-1">${escapeXml(title)}</text>
    <text x="0" y="52" dominant-baseline="hanging" fill="#686579" font-size="16" font-weight="560">${escapeXml(subtitle)}</text>
    <rect x="${width - 300}" y="0" width="230" height="44" rx="22" fill="#FFFFFF" stroke="#DDD4CB"/>
    <text x="${width - 185}" y="22" dominant-baseline="middle" text-anchor="middle" fill="#605D70" font-size="13" font-weight="760" class="mono">${escapeXml(tag)}</text>
  </g>`;
}

function panel({ x, y, width, height, fill = '#FFFFFF', stroke = '#DED7D0', radius = 30, shadow = true, content = '' }) {
  return `<g transform="translate(${x} ${y})"><rect width="${width}" height="${height}" rx="${radius}" fill="${cssColor(fill)}" stroke="${cssColor(stroke)}" ${shadow ? 'filter="url(#shadow)"' : ''}/>${content}</g>`;
}

function paletteVars(p) {
  return Object.fromEntries(Object.entries(p).map(([key, value]) => [key, typeof value === 'string' && value.startsWith('#') ? cssColor(value) : value]));
}

function labelPill(x, y, label, fill, ink, stroke = fill) {
  const width = Math.max(86, label.length * 8 + 30);
  return `<g transform="translate(${x} ${y})"><rect width="${width}" height="32" rx="16" fill="${fill}" stroke="${stroke}"/><text x="${width / 2}" y="16" dominant-baseline="middle" text-anchor="middle" fill="${ink}" font-size="11" font-weight="760">${escapeXml(label)}</text></g>`;
}

function cloudIcon(x, y, size, color, state = 'check') {
  const scale = size / 32;
  const glyph = state === 'warning'
    ? `<path d="M16 10v7"/><circle cx="16" cy="22" r="1.1" fill="${color}" stroke="none"/>`
    : state === 'error'
      ? `<path d="m12 12 8 8m0-8-8 8"/>`
      : `<path d="m11.5 17 3.2 3.1 6.2-7"/>`;
  return `<g transform="translate(${x} ${y}) scale(${scale})" fill="none" stroke="${color}" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"><path d="M9.2 24.5h13.4a6.5 6.5 0 0 0 1.2-12.9A8.5 8.5 0 0 0 7.4 13 5.8 5.8 0 0 0 9.2 24.5Z"/>${glyph}</g>`;
}

function checkIcon(x, y, size, color) {
  return `<g transform="translate(${x} ${y})" fill="none" stroke="${color}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="${size / 2}" cy="${size / 2}" r="${size / 2 - 2}"/><path d="M${size * .27} ${size * .52}l${size * .16} ${size * .16} ${size * .31}-${size * .34}"/></g>`;
}

function clockIcon(x, y, size, color) {
  return `<g transform="translate(${x} ${y})" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round"><circle cx="${size / 2}" cy="${size / 2}" r="${size / 2 - 2}"/><path d="M${size / 2} ${size * .27}v${size * .25}l${size * .18} ${size * .12}"/></g>`;
}

function leafIcon(x, y, size, color) {
  return `<g transform="translate(${x} ${y})" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M${size * .5} ${size * .82}V${size * .43}M${size * .5} ${size * .56}C${size * .24} ${size * .54} ${size * .15} ${size * .34} ${size * .2} ${size * .16}c${size * .2} 0 ${size * .38} ${size * .13} ${size * .4} ${size * .36}M${size * .5} ${size * .46}c${size * .04}-${size * .24} ${size * .23}-${size * .37} ${size * .42}-${size * .37} ${size * .05} ${size * .2}-${size * .05} ${size * .4}-${size * .3} ${size * .43}"/></g>`;
}

function miniWordmark(x, y, width, palette, assets) {
  const source = palette.brightness === 'dark' ? assets.wordmarkDark : assets.wordmarkLight;
  return `<image href="${source}" x="${x}" y="${y}" width="${width}" height="${width * .28}" preserveAspectRatio="xMinYMid meet"/>`;
}

function swatchRow(palette, x, y, key, label, value, width = 210) {
  const color = cssColor(value);
  const bg = cssColor(palette.surfaceLow);
  return `<g transform="translate(${x} ${y})"><rect width="${width}" height="44" rx="14" fill="${bg}" stroke="${cssColor(palette.outlineVariant)}"/><rect x="8" y="8" width="28" height="28" rx="9" fill="${color}" stroke="${cssColor(palette.outlineVariant)}"/><text x="46" y="15" dominant-baseline="middle" fill="${cssColor(palette.ink)}" font-size="11" font-weight="720">${escapeXml(label)}</text><text x="46" y="31" dominant-baseline="middle" fill="${cssColor(palette.muted)}" font-size="9" class="mono">${escapeXml(key)} · ${escapeXml(value)}</text></g>`;
}

function candidatePanel(candidate, x, y, assets) {
  const p = paletteVars(candidate.palette);
  const content = `<rect width="700" height="850" rx="34" fill="${p.canvas}"/>
    <circle cx="580" cy="90" r="210" fill="${p.tertiaryContainer}" opacity=".42"/>
    <circle cx="70" cy="760" r="180" fill="${p.secondaryContainer}" opacity=".36"/>
    <text x="36" y="42" dominant-baseline="hanging" fill="${p.ink}" font-size="28" font-weight="820">${escapeXml(candidate.title)}</text>
    <text x="36" y="82" dominant-baseline="hanging" fill="${p.muted}" font-size="13">${escapeXml(candidate.subtitle)}</text>
    ${labelPill(550, 34, `${candidate.score}/100`, p.surfaceHigh, p.ink, p.outlineVariant)}
    <g transform="translate(34 138)"><rect width="632" height="92" rx="26" fill="${p.glassStrong}" stroke="${p.outlineVariant}" filter="url(#shadow-dark)"/>${miniWordmark(22, 30, 150, candidate.palette, assets)}${cloudIcon(498, 25, 38, p.sync)}<text x="546" y="46" dominant-baseline="middle" fill="${p.sync}" font-size="14" font-weight="760">Synced</text></g>
    <g transform="translate(34 254)"><rect width="632" height="224" rx="30" fill="${p.surface}" stroke="${p.outlineVariant}"/><text x="26" y="24" dominant-baseline="hanging" fill="${p.muted}" font-size="11" font-weight="800" letter-spacing="1.6">TODAY PULSE</text><text x="26" y="60" dominant-baseline="hanging" fill="${p.ink}" font-size="32" font-weight="820">Your day, in rhythm.</text><text x="26" y="108" dominant-baseline="hanging" fill="${p.muted}" font-size="14">7:42 PM · Next boundary at 8:00 PM</text><g transform="translate(26 154)">${labelPill(0, 0, '3 planned', p.primaryContainer, p.onPrimaryContainer, p.outlineVariant)}${labelPill(124, 0, '1 complete', p.secondaryContainer, p.onSecondaryContainer, p.outlineVariant)}${labelPill(254, 0, '2 habits', p.tertiaryContainer, p.onTertiaryContainer, p.outlineVariant)}</g><circle cx="550" cy="105" r="46" fill="${p.surfaceHigh}" stroke="${p.tertiary}" stroke-width="5" stroke-dasharray="180 110" transform="rotate(-90 550 105)"/><text x="550" y="105" dominant-baseline="middle" text-anchor="middle" fill="${p.ink}" font-size="18" font-weight="800">68</text></g>
    <g transform="translate(34 502)"><rect width="632" height="238" rx="30" fill="${p.surface}" stroke="${p.outlineVariant}"/><text x="26" y="24" dominant-baseline="hanging" fill="${p.secondary}" font-size="11" font-weight="820" letter-spacing="1.6">DAY STREAM</text>${taskRow(candidate.palette, 22, 62, '7:15 PM', 'Review project brief', 'Work · 60%', 'secondary')}${taskRow(candidate.palette, 22, 134, '8:00 PM', 'Focus deep work', 'Work · planned', 'primary')}</g>
    <g transform="translate(34 768)"><rect width="632" height="54" rx="20" fill="${p.surfaceHigh}" stroke="${p.outlineVariant}"/><circle cx="31" cy="27" r="18" fill="url(#brand-gradient-dark)"/><path d="M23 27h16M31 19v16" stroke="#141620" stroke-width="2.5" stroke-linecap="round"/><text x="62" y="27" dominant-baseline="middle" fill="${p.muted}" font-size="13">Capture, plan, or ask Perfect AI</text><circle cx="588" cy="27" r="18" fill="${p.tertiary}"/><path d="m582 27 5 5 9-11" fill="none" stroke="${p.onTertiary}" stroke-width="2.2" stroke-linecap="round"/></g>`;
  return panel({ x, y, width: 700, height: 850, fill: p.canvas, stroke: p.outlineVariant, radius: 36, shadow: false, content });
}

function taskRow(palette, x, y, time, title, meta, tone) {
  const p = paletteVars(palette);
  const color = tone === 'primary' ? p.primary : tone === 'tertiary' ? p.tertiary : p.secondary;
  return `<g transform="translate(${x} ${y})"><text x="0" y="30" dominant-baseline="middle" fill="${p.muted}" font-size="11" font-weight="650">${escapeXml(time)}</text><circle cx="95" cy="30" r="18" fill="${p.surfaceLow}" stroke="${color}" stroke-width="3"/><path d="M95 12a18 18 0 0 1 14 29" fill="none" stroke="${color}" stroke-width="4" stroke-linecap="round"/><text x="128" y="20" dominant-baseline="middle" fill="${p.ink}" font-size="15" font-weight="760">${escapeXml(title)}</text><text x="128" y="43" dominant-baseline="middle" fill="${p.muted}" font-size="11">${escapeXml(meta)}</text><path d="m565 23 8 7-8 7" fill="none" stroke="${p.muted}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></g>`;
}

function candidateBoard(assets) {
  const width = 2400;
  const height = 1120;
  const panels = model.candidates.map((candidate, index) => candidatePanel(candidate, 70 + index * 770, 190, assets)).join('');
  return svgDocument({
    width,
    height,
    title: 'Perfect Stage 10 dark-theme candidate comparison',
    assets,
    content: `${boardBackground(width, height)}${boardHeader({ width, title: 'Stage 10 · authored dark-theme directions', subtitle: 'Three product-aware material systems compared under the frozen PS01 anatomy. Selection is autonomous and evidence-led.' })}${panels}`,
  });
}

function foundationColumn(theme, x, y, width, height, assets) {
  const p = paletteVars(theme);
  const rows = [
    ['canvas', 'Canvas', theme.canvas],
    ['surface', 'Surface', theme.surface],
    ['ink', 'Ink', theme.ink],
    ['primary', 'Intention', theme.primary],
    ['secondary', 'Rhythm', theme.secondary],
    ['tertiary', 'Focus', theme.tertiary],
    ['sync', 'Synced', theme.sync],
    ['warning', 'Retrying', theme.warning],
    ['danger', 'Needs attention', theme.danger],
    ['outline', 'Boundary', theme.outline],
  ];
  return `<g transform="translate(${x} ${y})"><rect width="${width}" height="${height}" rx="34" fill="${p.canvas}" stroke="${p.outlineVariant}"/>
    <text x="30" y="28" dominant-baseline="hanging" fill="${p.ink}" font-size="25" font-weight="820">${escapeXml(theme.label)}</text>
    <text x="30" y="66" dominant-baseline="hanging" fill="${p.muted}" font-size="12" class="mono">${escapeXml(theme.id)}</text>
    ${rows.map((row, index) => swatchRow(theme, 30 + (index % 2) * 254, 112 + Math.floor(index / 2) * 58, row[0], row[1], row[2], 238)).join('')}
    <g transform="translate(30 428)"><rect width="492" height="128" rx="25" fill="${p.glassStrong}" stroke="${p.outlineVariant}" ${theme.contrast === 'high' ? '' : 'filter="url(#shadow-dark)"'}/>${miniWordmark(20, 20, 126, theme, assets)}${cloudIcon(356, 17, 40, p.sync)}<text x="404" y="40" dominant-baseline="middle" fill="${p.sync}" font-size="13" font-weight="780">Synced</text><text x="20" y="78" dominant-baseline="hanging" fill="${p.ink}" font-size="18" font-weight="780">Glass carries orientation, not content.</text><text x="20" y="104" dominant-baseline="hanging" fill="${p.muted}" font-size="11">Blur ${theme.blur}px · stroke remains explicit · no muddy text layer</text></g>
    <g transform="translate(30 578)"><text x="0" y="0" dominant-baseline="hanging" fill="${p.muted}" font-size="11" font-weight="820" letter-spacing="1.4">FOCUS + COMPONENT STATES</text>${stateControl(theme, 0, 38, 'Default', 'default')}${stateControl(theme, 166, 38, 'Hover', 'hover')}${stateControl(theme, 332, 38, 'Focus', 'focus')}${stateControl(theme, 0, 106, 'Selected', 'selected')}${stateControl(theme, 166, 106, 'Disabled', 'disabled')}${stateControl(theme, 332, 106, 'Pressed', 'pressed')}</g>
  </g>`;
}

function stateControl(theme, x, y, label, state) {
  const p = paletteVars(theme);
  const selected = state === 'selected';
  const disabled = state === 'disabled';
  const focused = state === 'focus';
  const pressed = state === 'pressed';
  const hovered = state === 'hover';
  const fill = selected ? p.primaryContainer : pressed ? p.surfaceHigh : hovered ? p.surfaceLow : p.surface;
  const stroke = focused ? p.focus : selected ? p.primary : p.outlineVariant;
  return `<g transform="translate(${x} ${y})" opacity="${disabled ? .48 : 1}"><rect width="150" height="52" rx="17" fill="${fill}" stroke="${stroke}" stroke-width="${focused ? 3 : 1.5}"/><circle cx="25" cy="26" r="8" fill="${selected ? p.primary : p.surface}" stroke="${selected ? p.primary : p.outline}" stroke-width="2"/><text x="44" y="26" dominant-baseline="middle" fill="${p.ink}" font-size="11" font-weight="720">${escapeXml(label)}</text></g>`;
}

function foundationBoard(assets) {
  const width = 2400;
  const height = 1110;
  const ordered = [model.themes.light, model.themes.dark, model.themes.highContrastDark];
  const columns = ordered.map((theme, index) => foundationColumn(theme, 70 + index * 770, 190, 700, 850, assets)).join('');
  return svgDocument({
    width,
    height,
    title: 'Perfect Stage 10 semantic theme foundations',
    assets,
    content: `${boardBackground(width, height)}${boardHeader({ width, title: 'Semantic roles · material · focus', subtitle: 'One registry, three authored products. Pastels stay branded; foregrounds, boundaries and system status stay measurable.' })}${columns}`,
  });
}

function phoneSurface(theme, x, y, scale, dense, assets) {
  const p = paletteVars(theme);
  const width = 390;
  const height = 844;
  const stream = dense
    ? `${taskRow(theme, 20, 424, '7:15 PM', 'Review project brief', 'Work · partial', 'secondary')}${taskRow(theme, 20, 496, '8:00 PM', 'Focus deep work', 'Work · planned', 'primary')}${taskRow(theme, 20, 568, '9:30 PM', 'Call Mom', 'Personal · missed', 'tertiary')}`
    : `<g transform="translate(28 448)"><circle cx="167" cy="42" r="34" fill="${p.tertiaryContainer}"/>${leafIcon(151, 26, 32, p.tertiary)}<text x="167" y="98" text-anchor="middle" fill="${p.ink}" font-size="18" font-weight="780">Nothing is waiting on you</text><text x="167" y="126" text-anchor="middle" fill="${p.muted}" font-size="11">Capture one thing or plan with Perfect AI.</text><rect x="82" y="150" width="170" height="44" rx="16" fill="${p.primaryContainer}" stroke="${p.primary}"/><text x="167" y="172" dominant-baseline="middle" text-anchor="middle" fill="${p.onPrimaryContainer}" font-size="11" font-weight="760">Open the next relevant item</text></g>`;
  return `<g transform="translate(${x} ${y}) scale(${scale})"><rect width="${width}" height="${height}" rx="42" fill="${p.canvas}" stroke="${p.outlineVariant}" stroke-width="2" ${theme.contrast === 'high' ? '' : 'filter="url(#shadow)"'}/><rect x="18" y="18" width="354" height="74" rx="24" fill="${p.glassStrong}" stroke="${p.outlineVariant}"/>${miniWordmark(36, 38, 126, theme, assets)}${cloudIcon(252, 34, 34, p.sync)}<text x="294" y="51" dominant-baseline="middle" fill="${p.sync}" font-size="12" font-weight="780">Synced</text><text x="26" y="126" dominant-baseline="hanging" fill="${p.ink}" font-size="28" font-weight="820">${dense ? 'A full day, still calm' : 'A clean first day'}</text><text x="26" y="166" dominant-baseline="hanging" fill="${p.muted}" font-size="12">Today · 7:42 PM · ۲۲ اردیبهشت ۱۴۰۴</text><g transform="translate(18 206)"><rect width="354" height="178" rx="28" fill="${p.surface}" stroke="${p.outlineVariant}"/><text x="22" y="22" dominant-baseline="hanging" fill="${p.primary}" font-size="10" font-weight="820" letter-spacing="1.4">TODAY PULSE</text><text x="22" y="55" dominant-baseline="hanging" fill="${p.ink}" font-size="24" font-weight="820">${dense ? 'Your rhythm, at a glance.' : 'Open canvas.'}</text><text x="22" y="95" dominant-baseline="hanging" fill="${p.muted}" font-size="12">${dense ? 'Next boundary · Focus deep work at 8:00 PM' : 'No task is preloaded for this owner.'}</text><g transform="translate(22 128)">${labelPill(0, 0, dense ? '3 planned' : '0 planned', p.primaryContainer, p.onPrimaryContainer, p.outlineVariant)}${labelPill(112, 0, dense ? '1 complete' : '0 complete', p.secondaryContainer, p.onSecondaryContainer, p.outlineVariant)}${labelPill(240, 0, dense ? '2 habits' : '0 habits', p.tertiaryContainer, p.onTertiaryContainer, p.outlineVariant)}</g></g>${stream}<g transform="translate(18 760)"><rect width="354" height="64" rx="24" fill="${p.glassStrong}" stroke="${p.outlineVariant}"/><circle cx="44" cy="32" r="22" fill="${p.primaryContainer}"/>${clockIcon(33, 21, 22, p.primary)}${checkIcon(105, 21, 22, p.muted)}${clockIcon(176, 21, 22, p.muted)}${leafIcon(247, 21, 22, p.muted)}<path d="M318 24h24M318 32h24M318 40h24" stroke="${p.muted}" stroke-width="2.3" stroke-linecap="round"/></g><g transform="translate(166 712)"><circle cx="30" cy="30" r="30" fill="url(#brand-gradient${theme.brightness === 'dark' ? '-dark' : ''})" stroke="${p.canvas}" stroke-width="7"/><circle cx="30" cy="30" r="10" fill="none" stroke="${p.ink}" stroke-width="2"/><path d="M30 12v8M30 40v8M12 30h8M40 30h8" stroke="${p.ink}" stroke-width="2" stroke-linecap="round"/></g></g>`;
}

function phoneMatrix(assets) {
  const width = 2400;
  const height = 1530;
  const themes = [model.themes.light, model.themes.dark, model.themes.highContrastDark];
  const columns = themes.map((theme, index) => {
    const x = 70 + index * 770;
    return panel({
      x,
      y: 190,
      width: 700,
      height: 1270,
      fill: theme.contrast === 'high' ? '#111217' : theme.brightness === 'dark' ? '#20222D' : '#FFFDFC',
      stroke: theme.contrast === 'high' ? '#FFFFFF' : theme.outlineVariant,
      radius: 34,
      content: `<text x="28" y="24" dominant-baseline="hanging" fill="${cssColor(theme.ink)}" font-size="23" font-weight="820">${escapeXml(theme.label)}</text><text x="28" y="58" dominant-baseline="hanging" fill="${cssColor(theme.muted)}" font-size="11" class="mono">empty + dense · 390×844 · LTR/mixed</text>${phoneSurface(theme, 30, 104, .78, false, assets)}${phoneSurface(theme, 365, 104, .78, true, assets)}`,
      shadow: false,
    });
  }).join('');
  return svgDocument({ width, height, title: 'Perfect Stage 10 phone theme matrix', assets, content: `${boardBackground(width, height)}${boardHeader({ width, title: 'Phone composition · empty and dense', subtitle: 'Exact same anatomy and content rhythm across Daylight, Graphite Bloom and Clarity. No theme may change task geometry.' })}${columns}` });
}

function adaptiveTaskRow(theme, x, y, width, time, title, meta, accent) {
  const p = paletteVars(theme);
  const color = p[accent];
  const circleX = 58;
  const textX = 86;
  return `<g transform="translate(${x} ${y})"><text x="0" y="20" dominant-baseline="middle" fill="${p.muted}" font-size="9" font-weight="700">${escapeXml(time)}</text><circle cx="${circleX}" cy="20" r="15" fill="${p.surfaceLow}" stroke="${color}" stroke-width="3"/><text x="${textX}" y="13" dominant-baseline="middle" fill="${p.ink}" font-size="12" font-weight="760">${escapeXml(title)}</text><text x="${textX}" y="31" dominant-baseline="middle" fill="${p.muted}" font-size="9">${escapeXml(meta)}</text><path d="m${width - 13} 15 6 5-6 5" fill="none" stroke="${p.muted}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></g>`;
}

function adaptiveSurface(theme, x, y, width, height, kind, dense, assets) {
  const p = paletteVars(theme);
  const railWidth = kind === 'windows' ? 66 : 58;
  const headerHeight = 64;
  const paneGap = 16;
  const bodyX = railWidth + 18;
  const bodyWidth = width - bodyX - 18;
  const twoPane = dense || kind === 'windows';
  const leftWidth = twoPane ? Math.floor(bodyWidth * .43) : bodyWidth;
  const rightX = bodyX + leftWidth + paneGap;
  const rightWidth = bodyWidth - leftWidth - paneGap;
  const paneY = headerHeight + 20;
  const paneHeight = height - paneY - 10;
  const stream = dense
    ? `${adaptiveTaskRow(theme, bodyX + 14, paneY + 66, leftWidth - 28, '7:15', 'Review brief', 'Work · partial', 'secondary')}${adaptiveTaskRow(theme, bodyX + 14, paneY + 108, leftWidth - 28, '8:00', 'Focus work', 'Work · planned', 'primary')}`
    : `<text x="${bodyX + 20}" y="${paneY + 86}" dominant-baseline="hanging" fill="${p.muted}" font-size="11">Capture one thing or plan with Perfect AI.</text>`;
  const detailCardY = paneY + 86;
  const detailCardHeight = Math.min(72, Math.max(48, paneHeight - 102));
  const detail = twoPane
    ? `<rect x="${rightX}" y="${paneY}" width="${rightWidth}" height="${paneHeight}" rx="22" fill="${p.surface}" stroke="${p.outlineVariant}"/><text x="${rightX + 20}" y="${paneY + 20}" dominant-baseline="hanging" fill="${p.tertiary}" font-size="9" font-weight="820" letter-spacing="1.2">DETAIL + PLAN</text><text x="${rightX + 20}" y="${paneY + 48}" dominant-baseline="hanging" fill="${p.ink}" font-size="17" font-weight="820">${dense ? 'Focus deep work' : 'Choose an item'}</text><rect x="${rightX + 20}" y="${detailCardY}" width="${Math.max(100, rightWidth - 40)}" height="${detailCardHeight}" rx="16" fill="${p.tertiaryContainer}"/><text x="${rightX + 34}" y="${detailCardY + 17}" dominant-baseline="hanging" fill="${p.onTertiaryContainer}" font-size="10" font-weight="760">Context survives resize</text><text x="${rightX + 34}" y="${detailCardY + 38}" dominant-baseline="hanging" fill="${p.muted}" font-size="8.5">Selection · draft · focus · scroll</text>`
    : '';
  return `<g transform="translate(${x} ${y})"><rect width="${width}" height="${height}" rx="24" fill="${p.canvas}" stroke="${p.outlineVariant}"/><rect x="10" y="10" width="${railWidth}" height="${height - 20}" rx="20" fill="${p.glassStrong}" stroke="${p.outlineVariant}"/><circle cx="${10 + railWidth / 2}" cy="42" r="17" fill="url(#brand-gradient${theme.brightness === 'dark' ? '-dark' : ''})"/><g stroke="${p.muted}" stroke-width="2" fill="none">${checkIcon(26, 92, 22, p.primary)}${clockIcon(26, 139, 22, p.muted)}${leafIcon(26, 186, 22, p.muted)}<path d="M26 224h22M26 232h22M26 240h22"/></g><rect x="${bodyX}" y="10" width="${bodyWidth}" height="${headerHeight}" rx="20" fill="${p.glassStrong}" stroke="${p.outlineVariant}"/>${miniWordmark(bodyX + 16, 29, 102, theme, assets)}<text x="${bodyX + bodyWidth - 214}" y="29" dominant-baseline="hanging" fill="${p.tertiary}" font-size="14" font-weight="800">7:42 PM</text><text x="${bodyX + bodyWidth - 214}" y="49" dominant-baseline="hanging" fill="${p.muted}" font-size="9">Monday, May 12 · ۲۲ اردیبهشت</text>${cloudIcon(bodyX + bodyWidth - 72, 25, 31, p.sync)}<rect x="${bodyX}" y="${paneY}" width="${leftWidth}" height="${paneHeight}" rx="22" fill="${p.surface}" stroke="${p.outlineVariant}"/><text x="${bodyX + 20}" y="${paneY + 20}" dominant-baseline="hanging" fill="${p.primary}" font-size="9" font-weight="820" letter-spacing="1.2">${dense ? 'DAY STREAM' : 'OPEN CANVAS'}</text><text x="${bodyX + 20}" y="${paneY + 48}" dominant-baseline="hanging" fill="${p.ink}" font-size="${twoPane ? 17 : 19}" font-weight="820">${dense ? 'Today’s flow' : 'Nothing is waiting on you'}</text>${stream}${detail}</g>`;
}

function adaptiveMatrix(assets) {
  const width = 2400;
  const height = 1420;
  const themes = [model.themes.light, model.themes.dark, model.themes.highContrastDark];
  const columns = themes.map((theme, index) => {
    const x = 70 + index * 770;
    return panel({ x, y: 190, width: 700, height: 1160, fill: theme.brightness === 'dark' ? '#20222D' : '#FFFDFC', stroke: theme.contrast === 'high' ? '#FFFFFF' : theme.outlineVariant, radius: 34, shadow: false, content: `<text x="28" y="24" dominant-baseline="hanging" fill="${cssColor(theme.ink)}" font-size="23" font-weight="820">${escapeXml(theme.label)}</text><text x="28" y="58" dominant-baseline="hanging" fill="${cssColor(theme.muted)}" font-size="11" class="mono">tablet portrait/landscape + Windows compact/wide</text><text x="28" y="102" dominant-baseline="hanging" fill="${cssColor(theme.muted)}" font-size="10" font-weight="800" letter-spacing="1.2">TABLET · EMPTY</text>${adaptiveSurface(theme, 28, 132, 644, 310, 'tablet', false, assets)}<text x="28" y="474" dominant-baseline="hanging" fill="${cssColor(theme.muted)}" font-size="10" font-weight="800" letter-spacing="1.2">TABLET LANDSCAPE · DENSE</text>${adaptiveSurface(theme, 28, 504, 644, 310, 'tablet', true, assets)}<text x="28" y="846" dominant-baseline="hanging" fill="${cssColor(theme.muted)}" font-size="10" font-weight="800" letter-spacing="1.2">WINDOWS · WIDE WORKBENCH</text>${adaptiveSurface(theme, 28, 876, 644, 250, 'windows', true, assets)}` });
  }).join('');
  return svgDocument({ width, height, title: 'Perfect Stage 10 adaptive theme matrix', assets, content: `${boardBackground(width, height)}${boardHeader({ width, title: 'Tablet and Windows composition', subtitle: 'Theme changes material, not information architecture. Compact rail, panes and live selection keep identical geometry.' })}${columns}` });
}

function componentColumn(theme, x, y) {
  const p = paletteVars(theme);
  return `<g transform="translate(${x} ${y})"><rect width="700" height="1050" rx="34" fill="${p.canvas}" stroke="${p.outlineVariant}"/><text x="30" y="28" dominant-baseline="hanging" fill="${p.ink}" font-size="24" font-weight="820">${escapeXml(theme.label)}</text><text x="30" y="66" dominant-baseline="hanging" fill="${p.muted}" font-size="11" class="mono">controls · fields · status · progress · overlays</text><g transform="translate(30 112)"><text x="0" y="0" dominant-baseline="hanging" fill="${p.muted}" font-size="10" font-weight="820" letter-spacing="1.2">ACTIONS</text><rect x="0" y="34" width="180" height="52" rx="17" fill="${p.primary}"/><text x="90" y="60" dominant-baseline="middle" text-anchor="middle" fill="${p.onPrimary}" font-size="13" font-weight="780">Save locally</text><rect x="194" y="34" width="180" height="52" rx="17" fill="${p.surface}" stroke="${p.outline}"/><text x="284" y="60" dominant-baseline="middle" text-anchor="middle" fill="${p.ink}" font-size="13" font-weight="760">Review</text><rect x="388" y="34" width="180" height="52" rx="17" fill="${p.dangerContainer}" stroke="${p.danger}"/><text x="478" y="60" dominant-baseline="middle" text-anchor="middle" fill="${p.onDangerContainer}" font-size="13" font-weight="760">Archive</text></g><g transform="translate(30 232)"><text x="0" y="0" dominant-baseline="hanging" fill="${p.muted}" font-size="10" font-weight="820" letter-spacing="1.2">INPUT + SELECTION</text><rect x="0" y="34" width="420" height="60" rx="18" fill="${p.surfaceLowest}" stroke="${p.focus}" stroke-width="3"/><text x="18" y="64" dominant-baseline="middle" fill="${p.ink}" font-size="13">Capture a task…</text><path d="M390 54v20M380 64h20" stroke="${p.primary}" stroke-width="2.3" stroke-linecap="round"/>${stateControl(theme, 438, 38, 'Selected', 'selected')}</g><g transform="translate(30 360)"><text x="0" y="0" dominant-baseline="hanging" fill="${p.muted}" font-size="10" font-weight="820" letter-spacing="1.2">SYNC + RECOVERY · ICON + COPY + COLOR</text><g transform="translate(0 34)"><rect width="190" height="58" rx="20" fill="${p.syncContainer}" stroke="${p.sync}"/>${cloudIcon(15, 12, 34, p.sync)}<text x="60" y="29" dominant-baseline="middle" fill="${p.sync}" font-size="12" font-weight="780">Synced</text></g><g transform="translate(204 34)"><rect width="190" height="58" rx="20" fill="${p.warningContainer}" stroke="${p.warning}"/>${cloudIcon(15, 12, 34, p.warning, 'warning')}<text x="60" y="29" dominant-baseline="middle" fill="${p.warning}" font-size="12" font-weight="780">Retrying</text></g><g transform="translate(408 34)"><rect width="230" height="58" rx="20" fill="${p.dangerContainer}" stroke="${p.danger}"/>${cloudIcon(15, 12, 34, p.danger, 'error')}<text x="60" y="29" dominant-baseline="middle" fill="${p.danger}" font-size="12" font-weight="780">Needs attention</text></g></g><g transform="translate(30 490)"><text x="0" y="0" dominant-baseline="hanging" fill="${p.muted}" font-size="10" font-weight="820" letter-spacing="1.2">TASK + HABIT OUTCOMES</text>${taskRow(theme, 0, 32, '7:15 PM', 'Review project brief', 'Partial · Work', 'secondary')}${taskRow(theme, 0, 106, '8:00 PM', 'Focus deep work', 'Pending · Work', 'primary')}<g transform="translate(0 188)"><rect width="638" height="90" rx="22" fill="${p.surface}" stroke="${p.outlineVariant}"/>${leafIcon(18, 26, 36, p.secondary)}<text x="70" y="33" dominant-baseline="middle" fill="${p.ink}" font-size="14" font-weight="760">Drink water</text><text x="70" y="58" dominant-baseline="middle" fill="${p.muted}" font-size="11">Count · 3 of 8 today</text><rect x="490" y="20" width="128" height="50" rx="17" fill="${p.secondaryContainer}" stroke="${p.secondary}"/><text x="554" y="45" dominant-baseline="middle" text-anchor="middle" fill="${p.onSecondaryContainer}" font-size="13" font-weight="820">+1</text></g></g><g transform="translate(30 820)"><text x="0" y="0" dominant-baseline="hanging" fill="${p.muted}" font-size="10" font-weight="820" letter-spacing="1.2">OVERLAY + FOCUS PERIMETER</text><rect x="0" y="34" width="638" height="154" rx="26" fill="${p.surfaceHigh}" stroke="${p.focus}" stroke-width="${theme.contrast === 'high' ? 3 : 2}" ${theme.contrast === 'high' ? '' : 'filter="url(#shadow-dark)"'}/><text x="22" y="58" dominant-baseline="hanging" fill="${p.ink}" font-size="18" font-weight="800">Review before applying</text><text x="22" y="92" dominant-baseline="hanging" fill="${p.muted}" font-size="12">Perfect AI prepared 2 planner changes. Nothing writes yet.</text><rect x="386" y="126" width="105" height="44" rx="15" fill="${p.surface}" stroke="${p.outline}"/><text x="438" y="148" dominant-baseline="middle" text-anchor="middle" fill="${p.ink}" font-size="11" font-weight="740">Cancel</text><rect x="503" y="126" width="113" height="44" rx="15" fill="${p.tertiary}"/><text x="559" y="148" dominant-baseline="middle" text-anchor="middle" fill="${p.onTertiary}" font-size="11" font-weight="760">Apply</text></g></g>`;
}

function componentMatrix(assets) {
  const width = 2400;
  const height = 1320;
  const themes = [model.themes.light, model.themes.dark, model.themes.highContrastDark];
  return svgDocument({ width, height, title: 'Perfect Stage 10 component state matrix', assets, content: `${boardBackground(width, height)}${boardHeader({ width, title: 'Canonical component-state comparison', subtitle: 'Action, field, status, outcome and overlay roles stay whole, focused and non-color-dependent in every theme.' })}${themes.map((theme, index) => componentColumn(theme, 70 + index * 770, 190)).join('')}` });
}

function nativeRow(theme, x, y, assets) {
  const p = paletteVars(theme);
  return `<g transform="translate(${x} ${y})"><rect width="2260" height="338" rx="32" fill="${p.canvas}" stroke="${p.outlineVariant}"/><text x="28" y="24" dominant-baseline="hanging" fill="${p.ink}" font-size="22" font-weight="820">${escapeXml(theme.label)}</text><text x="28" y="58" dominant-baseline="hanging" fill="${p.muted}" font-size="11" class="mono">splash · Android widget · quick add · Windows frame</text><g transform="translate(250 28)"><rect width="310" height="280" rx="32" fill="${p.canvas}" stroke="${p.outlineVariant}"/><circle cx="155" cy="118" r="62" fill="url(#brand-gradient${theme.brightness === 'dark' ? '-dark' : ''})"/><circle cx="155" cy="118" r="16" fill="${p.ink}"/><text x="155" y="208" text-anchor="middle" fill="${p.ink}" font-size="19" font-weight="820">Perfect!</text><text x="155" y="238" text-anchor="middle" fill="${p.muted}" font-size="10">private planner · same identity</text></g><g transform="translate(590 28)"><rect width="520" height="280" rx="30" fill="${p.surface}" stroke="${p.outline}"/><rect width="520" height="74" rx="30" fill="${p.primaryContainer}"/><image href="${theme.brightness === 'dark' ? assets.markDark : assets.markLight}" x="20" y="15" width="44" height="44"/><text x="78" y="27" dominant-baseline="hanging" fill="${p.ink}" font-size="17" font-weight="800">Today · 3 items</text><text x="78" y="51" dominant-baseline="hanging" fill="${p.muted}" font-size="10">Local &amp; ready · scroll all</text><circle cx="476" cy="37" r="22" fill="${p.primary}"/><path d="M466 37h20M476 27v20" stroke="${p.onPrimary}" stroke-width="2.4" stroke-linecap="round"/>${taskRow(theme, 18, 88, '7:15', 'Review brief', 'Partial', 'secondary')}${taskRow(theme, 18, 158, '8:00', 'Focus deep work', 'Pending', 'primary')}</g><g transform="translate(1140 28)"><rect width="430" height="280" rx="28" fill="${p.surface}" stroke="${p.outline}"/><text x="24" y="24" dominant-baseline="hanging" fill="${p.ink}" font-size="18" font-weight="820">Quick add</text><text x="24" y="56" dominant-baseline="hanging" fill="${p.muted}" font-size="11">Saved locally first; sync follows.</text><rect x="24" y="94" width="382" height="60" rx="18" fill="${p.surfaceLowest}" stroke="${p.focus}" stroke-width="2"/><text x="42" y="124" dominant-baseline="middle" fill="${p.muted}" font-size="12">Task title</text><rect x="244" y="194" width="162" height="50" rx="17" fill="${p.primary}"/><text x="325" y="219" dominant-baseline="middle" text-anchor="middle" fill="${p.onPrimary}" font-size="12" font-weight="780">Add to Today</text></g><g transform="translate(1600 28)"><rect width="620" height="280" rx="22" fill="${p.surfaceLow}" stroke="${p.outline}"/><rect width="620" height="44" rx="22" fill="${p.surfaceHigh}"/><image href="${theme.brightness === 'dark' ? assets.markDark : assets.markLight}" x="14" y="9" width="26" height="26"/><text x="50" y="22" dominant-baseline="middle" fill="${p.ink}" font-size="12" font-weight="720">Perfect!</text><g transform="translate(520 11)"><path d="M0 8h18M30 8h18M60 0v16M78 0v16" stroke="${p.ink}" stroke-width="1.6"/></g><text x="28" y="82" dominant-baseline="hanging" fill="${p.ink}" font-size="24" font-weight="820">Windows workspace</text><text x="28" y="122" dominant-baseline="hanging" fill="${p.muted}" font-size="12">Caption, border, focus and canvas follow the same appearance state.</text><rect x="28" y="174" width="270" height="70" rx="20" fill="${p.tertiaryContainer}" stroke="${p.tertiary}"/><text x="46" y="195" dominant-baseline="hanging" fill="${p.onTertiaryContainer}" font-size="12" font-weight="760">System chrome stays coherent</text><text x="46" y="220" dominant-baseline="hanging" fill="${p.muted}" font-size="10">Light · Dark · High Contrast</text></g></g>`;
}

function nativeMatrix(assets) {
  const width = 2400;
  const height = 1350;
  const rows = [model.themes.light, model.themes.dark, model.themes.highContrastDark].map((theme, index) => nativeRow(theme, 70, 190 + index * 370, assets)).join('');
  return svgDocument({ width, height, title: 'Perfect Stage 10 native surface matrix', assets, content: `${boardBackground(width, height)}${boardHeader({ width, title: 'Native identity and system-surface continuity', subtitle: 'Android splash/widget/Quick Add and Windows caption participate in the same semantic appearance contract.' })}${rows}` });
}

module.exports = {
  svgDocument,
  candidateBoard,
  foundationBoard,
  phoneMatrix,
  adaptiveMatrix,
  componentMatrix,
  nativeMatrix,
};
