const {
  tokens,
  categoryIcons,
  motionBible,
} = require('./design_catalog_model.cjs');
const {
  escapeHtml,
  iconSvg,
  css: componentCss,
} = require('./design_catalog_visuals.cjs');

function colorRoles(theme) {
  const palette = tokens.color[theme];
  return Object.entries(palette)
    .map(([role, value]) => `
      <article class="color-role">
        <i style="background:${value}"></i>
        <div><strong>${escapeHtml(role)}</strong><code>${value}</code></div>
      </article>`)
    .join('');
}

function categoryArchive() {
  return categoryIcons
    .map(([id, label, icon], index) => {
      const tones = ['apricot', 'mint', 'lilac', 'neutral'];
      return `<article class="category-icon tone-${tones[index % tones.length]}">
        <span>${iconSvg(icon, 20)}</span>
        <small>${escapeHtml(label)}</small>
        <code>${escapeHtml(id)}</code>
      </article>`;
    })
    .join('');
}

function foundationMarkup(foundation, assets) {
  switch (foundation.id) {
    case 'fnd-color-roles':
      return `<div class="color-foundation">
        <section><header><strong>Light roles</strong><small>paired live contrast</small></header><div>${colorRoles('light')}</div></section>
        <section class="dark-sample"><header><strong>Dark roles</strong><small>paired live contrast</small></header><div>${colorRoles('dark')}</div></section>
        <section class="contrast-sample"><header><strong>High contrast</strong><small>color-independent cues</small></header><div>${colorRoles('highContrast')}</div></section>
      </div>`;
    case 'fnd-type-latin':
      return `<div class="type-foundation latin-type">
        <section class="wordmark-spec"><img src="${assets.wordmark}" alt="Perfect!"/><span>Custom image typography · never replaced by live body type</span></section>
        <section class="type-ramp">
          <p class="role-display">Shape a day that feels possible.</p>
          <p class="role-page">Today · Monday, August 10</p>
          <p class="role-section">Next up</p>
          <p class="role-body">Review the project brief before the focus block begins.</p>
          <p class="role-label">CATEGORY · WORK</p>
          <p class="role-meta">9:30 AM · 45 min · UTC+03:30</p>
        </section>
        <section class="type-metrics"><strong>0123456789</strong><span>Tabular time 09:41 · 19:05 · 100%</span><code>Plus Jakarta Sans Variable · 100—900</code></section>
      </div>`;
    case 'fnd-type-persian':
      return `<div class="type-foundation persian-type" dir="rtl">
        <section class="persian-ramp">
          <p class="role-display">امروز را قابل‌انجام بچین.</p>
          <p class="role-page">امروز · دوشنبه ۱۹ مرداد</p>
          <p class="role-section">کار بعدی</p>
          <p class="role-body">مرور فصل <bdi>Arrhythmia</bdi> را پیش از ساعت <bdi>9:30 AM</bdi> تمام کن.</p>
          <p class="role-label">دسته‌بندی · مطالعه</p>
          <p class="role-meta">۰۹:۳۰ · ۴۵ دقیقه · <bdi>UTC+03:30</bdi></p>
        </section>
        <section class="bidi-grid">
          <article><small>Persian digits</small><strong>۰۱۲۳۴۵۶۷۸۹</strong></article>
          <article><small>Latin digits isolated</small><strong><bdi>0123456789</bdi></strong></article>
          <article><small>Mixed title</small><strong>مرور <bdi>ECG Workbook</bdi></strong></article>
          <article><small>Punctuation</small><strong>انجام شد؛ ادامه بده!</strong></article>
        </section>
      </div>`;
    case 'fnd-spacing-density': {
      const spaces = Object.entries(tokens.spacing)
        .map(([name, value]) => `<div class="space-token"><i style="width:${value}px"></i><span>${name}</span><code>${value}</code></div>`)
        .join('');
      const radii = Object.entries(tokens.radius)
        .filter(([, value]) => value < 100)
        .map(([name, value]) => `<article style="border-radius:${value}px"><strong>${name}</strong><code>${value}px</code></article>`)
        .join('');
      return `<div class="rhythm-foundation">
        <section class="space-ladder"><header><strong>Spacing ladder</strong><small>4px base rhythm</small></header>${spaces}</section>
        <section><header><strong>Radius and target ladder</strong><small>fixed semantic tokens</small></header><div class="radius-grid">${radii}</div><div class="target-grid"><span class="target-40">40</span><span class="target-48">48</span><span class="target-52">52</span></div></section>
        <section class="density-examples"><header><strong>Density changes rhythm, never meaning</strong></header><article class="phone-density">Phone · 52dp</article><article class="pointer-density">Windows pointer · 40dp visual / 48dp semantic</article></section>
      </div>`;
    }
    case 'fnd-grid-width':
      return `<div class="grid-foundation">
        ${[
          ['320', 'compact', '16 + intrinsic + 16'],
          ['390', 'phone', '20 + minmax(0,1fr) + 20'],
          ['600', 'fold / tablet', '72 rail + flexible stream'],
          ['900', 'tablet', '72 rail + 1fr + minmax(320,38%)'],
          ['1024', 'wide tablet', '72 rail + bounded primary + support'],
          ['1366', 'Windows', 'rail + minmax(520,760) + inspector'],
          ['1600+', 'expanded', '232 rail + bounded canvas + 400 inspector'],
        ].map(([width, label, equation], index) => `<article class="grid-case grid-${index}"><header><strong>${width}</strong><small>${label}</small></header><div><i></i><b></b><em></em></div><code>${equation}</code></article>`).join('')}
        <aside><strong>Constraint negotiation</strong><span>Width + height + IME + text scale</span><small>Draft, focus, selection and scroll survive every recomposition.</small></aside>
      </div>`;
    case 'fnd-icons':
      return `<div class="icons-foundation"><header><div><strong>48 semantic category pictograms</strong><span>Lucide geometry · Perfect optical containers · no keyboard emoji</span></div><small>16 / 20 / 24 / 32 inspection</small></header><section>${categoryArchive()}</section></div>`;
    case 'fnd-material':
      return `<div class="material-foundation">
        <article class="material-canvas"><small>Canvas</small><strong>Quiet, warm, continuous</strong></article>
        <article class="material-solid"><small>Solid row</small><strong>Repeated information</strong><span>1px semantic border</span></article>
        <article class="material-elevated"><small>Elevated</small><strong>Temporary hierarchy</strong><span>bounded authored shadow</span></article>
        <article class="material-glass"><small>Floating glass</small><strong>Navigation / capture only</strong><span>blur 18 · translucent role</span></article>
        <article class="material-no-blur"><small>No-blur fallback</small><strong>Opaque surface + stronger stroke</strong><span>same geometry and semantics</span></article>
        <article class="material-hc"><small>High contrast</small><strong>Black / white / focus yellow</strong><span>no transparency dependency</span></article>
      </div>`;
    case 'fnd-motion':
      return `<div class="motion-foundation"><header><strong>Motion is continuity, not decoration</strong><span>${motionBible.families.length} named contracts</span></header><section>${motionBible.families.map((motion, index) => `<article><div class="motion-frames"><i></i><i></i><i></i><i></i></div><strong>${escapeHtml(motion.id.replace('motion-', ''))}</strong><small>${escapeHtml(motion.intent)}</small><code>${escapeHtml(motion.token)}</code><span>${escapeHtml(motion.reduced)}</span></article>`).join('')}</section></div>`;
    case 'fnd-focus-a11y':
      return `<div class="a11y-foundation">
        <section class="interaction-states">${['Default', 'Hover', 'Focus', 'Pressed', 'Selected', 'Disabled'].map((state) => `<article class="a11y-${state.toLowerCase()}"><button>${iconSvg('CalendarCheck2', 22)}<span>${state}</span></button><small>Stable 52 × 156 outer bounds</small></article>`).join('')}</section>
        <section class="semantic-pattern"><header>${iconSvg('Accessibility', 28)}<div><strong>One semantic owner</strong><small>State and value announced without color</small></div></header><ul><li>48dp minimum touch target</li><li>Visible 3px keyboard focus</li><li>200% text recomposes before clipping</li><li>RTL and mixed-script isolation</li><li>Reduced motion preserves outcome</li></ul></section>
      </div>`;
    default:
      throw new Error(`Unknown foundation: ${foundation.id}`);
  }
}

function foundationDocument(foundation, assets, stress = false) {
  const content = stress
    ? `<div class="foundation-stress">
        <article class="stress-compact"><label>320 × 568 · 200%</label><div>${foundationMarkup(foundation, assets)}</div></article>
        <article class="stress-short"><label>900 × 520 · IME / short height</label><div>${foundationMarkup(foundation, assets)}</div></article>
        <article class="stress-dark"><label>Dark / high contrast / reduced motion</label><div>${foundationMarkup(foundation, { ...assets, wordmark: assets.wordmarkDark })}</div></article>
      </div>`
    : foundationMarkup(foundation, assets);
  return `<!doctype html><html><head><meta charset="utf-8"><style>${componentCss(assets.fonts)}${foundationCss()}</style></head><body style="margin:0;width:1200px;height:800px;overflow:hidden"><div class="foundation-board ${stress ? 'is-stress' : ''}">
    <header><div class="foundation-id"><span>${iconSvg(foundation.icon, 26)}</span><div><small>PS01 FOUNDATION · ${escapeHtml(foundation.id)}</small><strong>${escapeHtml(foundation.title)}</strong></div></div><p>${escapeHtml(foundation.purpose)}</p></header>
    <main>${content}</main>
    <footer><span>Perfect! responsive design system · ${tokens.version}</span><span>deterministic · live-copy boundary · fixture-only</span></footer>
  </div></body></html>`;
}

function foundationSvg(foundation) {
  const palette = ['#FFA34D', '#7EC99B', '#A79ADD', '#2E9B91'];
  const checks = [
    'Exact semantic owner',
    'Light · dark · high contrast',
    'Phone · tablet · Windows',
    'LTR · RTL · mixed script · 200%',
    'Stable geometry · reduced motion',
  ];
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 800" width="1200" height="800">
    <defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FFFCF7"/><stop offset="1" stop-color="#FFF0E2"/></linearGradient><filter id="s"><feDropShadow dx="0" dy="18" stdDeviation="24" flood-color="#3B3128" flood-opacity=".12"/></filter></defs>
    <rect width="1200" height="800" fill="url(#bg)"/>
    <text x="70" y="82" font-family="Segoe UI, sans-serif" font-size="15" font-weight="700" letter-spacing="2" fill="#A4510E">FOUNDATION ANATOMY · PS01</text>
    <text x="70" y="138" font-family="Segoe UI, sans-serif" font-size="36" font-weight="700" fill="#1D2030">${escapeHtml(foundation.title)}</text>
    <text x="70" y="176" font-family="Segoe UI, sans-serif" font-size="17" fill="#686579">${escapeHtml(foundation.purpose)}</text>
    <rect x="70" y="224" width="1060" height="430" rx="34" fill="#FFFFFF" stroke="#ECE5DC" filter="url(#s)"/>
    ${palette.map((color, index) => `<g><rect x="120" y="${280 + index * 72}" width="190" height="48" rx="16" fill="${color}"/><path d="M326 ${304 + index * 72} H466" stroke="#A79ADD" stroke-width="2" stroke-dasharray="6 8"/><circle cx="466" cy="${304 + index * 72}" r="5" fill="#FFA34D"/><text x="490" y="${311 + index * 72}" font-family="Segoe UI, sans-serif" font-size="17" font-weight="600" fill="#1D2030">layer ${index + 1} · named token</text></g>`).join('')}
    ${checks.map((check, index) => `<g><circle cx="738" cy="${282 + index * 58}" r="15" fill="#E4F4E8"/><path d="m730 ${282 + index * 58} 6 6 11-14" fill="none" stroke="#347B54" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><text x="770" y="${289 + index * 58}" font-family="Segoe UI, sans-serif" font-size="17" fill="#1D2030">${escapeHtml(check)}</text></g>`).join('')}
    <line x1="600" y1="210" x2="600" y2="668" stroke="#2E9B91" stroke-width="1" stroke-dasharray="4 8" opacity=".6"/>
    <text x="70" y="738" font-family="Consolas, monospace" font-size="15" fill="#686579">${escapeHtml(foundation.id)} · ${tokens.version}</text>
    <text x="1130" y="738" text-anchor="end" font-family="Segoe UI, sans-serif" font-size="15" fill="#686579">specimen.png owns rendered craft · this SVG owns decomposition</text>
  </svg>`;
}

function foundationCss() {
  return `
    .foundation-board{width:1200px;height:800px;padding:36px 48px 28px;background:radial-gradient(circle at 86% 0,rgba(167,154,221,.18),transparent 28%),linear-gradient(145deg,#fffcf7,#fff5ea);display:grid;grid-template-rows:112px 1fr 30px;gap:16px;overflow:hidden;color:#1d2030}.foundation-board>header{display:grid;grid-template-columns:1fr 460px;align-items:start;gap:30px}.foundation-id{display:flex;align-items:center;gap:14px}.foundation-id>span{width:50px;height:50px;border-radius:17px;background:#ffead7;color:#a4510e;display:grid;place-items:center}.foundation-id>div{display:flex;flex-direction:column;gap:5px}.foundation-id small{font-size:11px;letter-spacing:.1em;color:#686579}.foundation-id strong{font-size:29px}.foundation-board>header p{margin:4px 0 0;color:#686579;line-height:1.45;font-size:14px}.foundation-board>main{min-height:0}.foundation-board>footer{border-top:1px solid #ece5dc;display:flex;align-items:flex-end;justify-content:space-between;color:#686579;font-size:10px}
    .color-foundation{display:grid;grid-template-columns:1.25fr 1.25fr .8fr;gap:14px;height:100%}.color-foundation>section{padding:16px;border:1px solid #ece5dc;border-radius:24px;background:#fff;overflow:hidden}.color-foundation header{display:flex;justify-content:space-between;margin-bottom:12px}.color-foundation header small{color:#686579}.color-foundation section>div{display:grid;grid-template-columns:1fr 1fr;gap:7px}.color-role{min-width:0;height:49px;padding:6px;border:1px solid #ece5dc;border-radius:13px;display:flex;align-items:center;gap:7px;background:#fff}.color-role i{width:34px;height:34px;border-radius:10px;border:1px solid rgba(0,0,0,.12);flex:none}.color-role div{display:flex;flex-direction:column;min-width:0}.color-role strong{font-size:9px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.color-role code{font-size:8px;color:#686579}.color-foundation .dark-sample{background:#232635;color:#f7f4ff;border-color:#3a3e50}.dark-sample .color-role{background:#292c3d;border-color:#3a3e50}.dark-sample .color-role code,.dark-sample header small{color:#c8c4d5}.color-foundation .contrast-sample{background:#000;color:#fff;border:2px solid #fff}.contrast-sample>div{grid-template-columns:1fr}.contrast-sample .color-role{background:#000;color:#fff;border-color:#fff}.contrast-sample .color-role code,.contrast-sample header small{color:#fff}
    .type-foundation{height:100%;display:grid;grid-template-columns:.78fr 1.45fr .7fr;gap:15px}.type-foundation>section{padding:22px;border:1px solid #ece5dc;border-radius:25px;background:#fff;overflow:hidden}.wordmark-spec{display:flex;flex-direction:column;justify-content:center;gap:22px}.wordmark-spec img{width:250px;max-width:100%}.wordmark-spec span,.type-metrics span,.type-metrics code{color:#686579;font-size:11px;line-height:1.45}.type-ramp{display:flex;flex-direction:column;justify-content:center}.type-ramp p,.persian-ramp p{margin:4px 0}.role-display{font-size:32px;line-height:1.08;font-weight:670}.role-page{font-size:25px;line-height:1.14;font-weight:650}.role-section{font-size:19px;font-weight:640;color:#6954b8}.role-body{font-size:15px;line-height:1.45}.role-label{font-size:12px;font-weight:700;color:#a4510e;letter-spacing:.05em}.role-meta{font-size:11px;color:#686579}.type-metrics{display:flex;flex-direction:column;justify-content:center;gap:14px}.type-metrics strong{font-size:26px;font-variant-numeric:tabular-nums}.persian-type{grid-template-columns:1.15fr .85fr;font-family:"Perfect Vazirmatn","Segoe UI",sans-serif}.persian-ramp{display:flex;flex-direction:column;justify-content:center;text-align:right}.bidi-grid{display:grid!important;grid-template-columns:1fr 1fr;gap:10px!important}.bidi-grid article{padding:14px;border-radius:16px;background:#f7f2eb;display:flex;flex-direction:column;gap:6px}.bidi-grid small{color:#686579}.bidi-grid strong{font-size:18px}
    .rhythm-foundation{height:100%;display:grid;grid-template-columns:1fr 1.15fr .9fr;gap:15px}.rhythm-foundation>section{padding:18px;border:1px solid #ece5dc;border-radius:25px;background:#fff}.rhythm-foundation header{display:flex;justify-content:space-between;margin-bottom:14px}.rhythm-foundation header small{color:#686579}.space-ladder{display:flex;flex-direction:column}.space-token{height:34px;display:grid;grid-template-columns:74px 1fr 28px;align-items:center;gap:9px}.space-token i{height:12px;border-radius:999px;background:linear-gradient(90deg,#ffa34d,#a79add);justify-self:end}.space-token span{font-size:11px}.space-token code{font-size:10px;color:#686579}.radius-grid{display:grid;grid-template-columns:1fr 1fr;gap:9px}.radius-grid article{height:72px;padding:12px;background:#eeeafd;border:1px solid #a79add;display:flex;flex-direction:column}.radius-grid code{color:#6954b8}.target-grid{display:flex;align-items:center;justify-content:center;gap:18px;margin-top:22px}.target-grid span{border-radius:16px;background:#e4f4e8;border:1px dashed #347b54;display:grid;place-items:center;font-size:10px}.target-40{width:40px;height:40px}.target-48{width:48px;height:48px}.target-52{width:52px;height:52px}.density-examples{display:flex;flex-direction:column;gap:14px}.density-examples article{padding:16px;border-radius:17px;border:1px solid #ece5dc;background:#fffaf4}.pointer-density{min-height:40px}.phone-density{min-height:52px}
    .grid-foundation{height:100%;display:grid;grid-template-columns:repeat(4,1fr);gap:10px}.grid-case{padding:12px;border:1px solid #ece5dc;border-radius:20px;background:#fff;display:flex;flex-direction:column;gap:9px}.grid-case header{display:flex;justify-content:space-between}.grid-case header strong{font-size:20px}.grid-case header small,.grid-case code{color:#686579;font-size:9px}.grid-case>div{height:70px;padding:6px;border-radius:13px;background:#f7f2eb;display:grid;grid-template-columns:18% 1fr 28%;gap:5px}.grid-case>div i,.grid-case>div b,.grid-case>div em{border-radius:7px;background:#eeeafd}.grid-case>div b{background:#ffead7}.grid-case>div em{background:#e4f4e8}.grid-case:nth-child(-n+2)>div{grid-template-columns:1fr}.grid-case:nth-child(-n+2)>div i,.grid-case:nth-child(-n+2)>div em{display:none}.grid-foundation aside{grid-column:span 1;padding:14px;border-radius:20px;background:linear-gradient(145deg,#ffead7,#eeeafd);display:flex;flex-direction:column;gap:7px}.grid-foundation aside small{color:#686579;line-height:1.4}
    .icons-foundation{height:100%;padding:16px;border:1px solid #ece5dc;border-radius:25px;background:#fff}.icons-foundation>header{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}.icons-foundation>header div{display:flex;flex-direction:column}.icons-foundation>header span,.icons-foundation>header small{color:#686579;font-size:10px}.icons-foundation>section{display:grid;grid-template-columns:repeat(8,1fr);gap:7px}.category-icon{height:68px;padding:6px;border:1px solid #ece5dc;border-radius:14px;display:grid;grid-template-columns:28px 1fr;grid-template-rows:1fr 1fr;align-items:center;gap:0 6px}.category-icon>span{grid-row:1/-1;width:28px;height:28px;border-radius:9px;display:grid;place-items:center;background:#ffead7;color:#a4510e}.category-icon small{font-size:8px;font-weight:700}.category-icon code{font-size:7px;color:#686579}.category-icon.tone-mint>span{background:#e4f4e8;color:#347b54}.category-icon.tone-lilac>span{background:#eeeafd;color:#6954b8}.category-icon.tone-neutral>span{background:#f7f2eb;color:#1d2030}
    .material-foundation{height:100%;display:grid;grid-template-columns:repeat(3,1fr);gap:15px;padding:18px;border-radius:30px;background:linear-gradient(145deg,#fffaf4,#f7f2eb)}.material-foundation article{padding:22px;border-radius:25px;display:flex;flex-direction:column;justify-content:flex-end;gap:7px;min-height:170px}.material-foundation small{font-size:10px;text-transform:uppercase;letter-spacing:.08em}.material-foundation span{color:#686579;font-size:11px}.material-canvas{background:#fffcf7;border:1px dashed #ece5dc}.material-solid{background:#fff;border:1px solid #ece5dc}.material-elevated{background:#fff;box-shadow:0 20px 40px rgba(75,61,50,.15)}.material-glass{background:rgba(255,255,255,.67);border:1px solid rgba(255,255,255,.9);backdrop-filter:blur(18px);box-shadow:0 18px 40px rgba(75,61,50,.12)}.material-no-blur{background:#fff;border:2px solid #8a8493}.material-hc{background:#000;color:#fff;border:2px solid #fff}.material-hc span{color:#fff}
    .motion-foundation{height:100%;padding:16px;border:1px solid #ece5dc;border-radius:25px;background:#fff}.motion-foundation>header{display:flex;justify-content:space-between;margin-bottom:12px}.motion-foundation>section{display:grid;grid-template-columns:repeat(5,1fr);gap:7px}.motion-foundation article{height:103px;padding:8px;border-radius:14px;background:#fffaf4;border:1px solid #ece5dc;display:grid;grid-template-columns:1fr auto;gap:3px}.motion-frames{grid-column:1/-1;display:flex;align-items:center;gap:4px}.motion-frames i{width:13px;height:13px;border-radius:5px;background:#ffead7}.motion-frames i:nth-child(2){transform:translateY(-3px);background:#e4f4e8}.motion-frames i:nth-child(3){transform:translateX(3px);background:#eeeafd}.motion-frames i:nth-child(4){background:#1d2030}.motion-foundation article strong{font-size:8px}.motion-foundation article small,.motion-foundation article span{font-size:7px;color:#686579}.motion-foundation article code{font-size:7px;color:#6954b8}
    .a11y-foundation{height:100%;display:grid;grid-template-columns:1.4fr .8fr;gap:16px}.interaction-states{display:grid;grid-template-columns:repeat(3,1fr);gap:11px}.interaction-states article{padding:14px;border:1px solid #ece5dc;border-radius:20px;background:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px}.interaction-states button{width:156px;height:52px;border:1px solid #ece5dc;border-radius:17px;background:#fff;display:flex;align-items:center;justify-content:center;gap:9px}.interaction-states small{font-size:9px;color:#686579}.a11y-hover button{transform:translateY(-1px);box-shadow:0 10px 22px rgba(75,61,50,.1)}.a11y-focus button{outline:3px solid #a4510e;outline-offset:3px}.a11y-pressed button{transform:translateY(1px) scale(.985)}.a11y-selected button{background:#ffead7;color:#a4510e}.a11y-disabled{opacity:.45}.semantic-pattern{padding:20px;border-radius:25px;background:#171924;color:#f7f4ff}.semantic-pattern header{display:flex;gap:11px;align-items:center}.semantic-pattern header>span{width:48px;height:48px;border-radius:16px;background:#37334f;color:#cfc5ff;display:grid;place-items:center}.semantic-pattern header div{display:flex;flex-direction:column}.semantic-pattern header small{color:#c8c4d5}.semantic-pattern ul{margin:24px 0;padding-left:20px;display:grid;gap:15px}
    .foundation-stress{height:100%;display:grid;grid-template-columns:280px 1fr 1fr;gap:13px}.foundation-stress>article{position:relative;border:1px solid #ece5dc;border-radius:23px;background:#fff;padding:42px 12px 12px;overflow:hidden}.foundation-stress>article>label{position:absolute;left:14px;top:12px;font-size:10px;font-weight:700;color:#686579}.foundation-stress>article>div{width:1060px;height:490px;transform-origin:top left}.stress-compact>div{transform:scale(.31);font-size:1.8em}.stress-short>div{transform:scale(.39,.72)}.foundation-stress .stress-dark{background:#171924;border-color:#3a3e50}.stress-dark>label{color:#f7f4ff!important}.stress-dark>div{transform:scale(.39,.72);filter:saturate(.9) brightness(.78)}
  `;
}

module.exports = {
  foundationDocument,
  foundationSvg,
};
