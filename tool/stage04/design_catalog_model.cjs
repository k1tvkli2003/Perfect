const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..', '..');
const documentRoot = path.join(
  projectRoot,
  'docs',
  'codex',
  '2026-07-27-perfect-orbit-day-private-planner-rebuild',
);
const gatePath = path.join(documentRoot, 'stages', 'preview-production-gate.md');
const foundationRoot = path.join(
  documentRoot,
  'design',
  '01-foundations',
  'stage04-system',
);
const componentRoot = path.join(documentRoot, 'design', '02-components');
const manifestRoot = path.join(documentRoot, 'design', '04-copy-manifests');

const catalogVersion = 'ps01-ds-1.0.0';
const generatedAt = '2026-08-10';

const tokens = Object.freeze({
  version: catalogVersion,
  direction: 'PS01 Perfect Day Instrument',
  color: {
    light: {
      canvas: '#FFFCF7',
      canvasAccent: '#FFF5EA',
      surfaceLow: '#FFFAF4',
      surface: '#FFFFFF',
      surfaceHigh: '#F7F2EB',
      stroke: '#ECE5DC',
      strokeStrong: '#8A8493',
      ink: '#1D2030',
      muted: '#686579',
      apricot: '#FFA34D',
      apricotAction: '#A4510E',
      apricotSoft: '#FFEAD7',
      mint: '#7EC99B',
      mintSoft: '#E4F4E8',
      lilac: '#A79ADD',
      lilacAction: '#6954B8',
      lilacSoft: '#EEEAFD',
      sync: '#2E9B91',
      syncing: '#C48712',
      danger: '#C44B56',
      dangerSoft: '#FFE3E5',
      focus: '#8A4B16',
    },
    dark: {
      canvas: '#171924',
      canvasAccent: '#211F2E',
      surfaceLow: '#1D202C',
      surface: '#232635',
      surfaceHigh: '#303446',
      stroke: '#3A3E50',
      strokeStrong: '#A7A3B7',
      ink: '#F7F4FF',
      muted: '#C8C4D5',
      apricot: '#FFBD7C',
      apricotAction: '#FFBD7C',
      apricotSoft: '#4A3527',
      mint: '#A9DFBB',
      mintSoft: '#253C31',
      lilac: '#CFC5FF',
      lilacAction: '#CFC5FF',
      lilacSoft: '#37334F',
      sync: '#69D3C7',
      syncing: '#FFD272',
      danger: '#FFAAB0',
      dangerSoft: '#542C35',
      focus: '#FFBD7C',
    },
    highContrast: {
      canvas: '#000000',
      surface: '#000000',
      ink: '#FFFFFF',
      stroke: '#FFFFFF',
      focus: '#FFFF00',
      positive: '#00FF66',
      warning: '#FFFF00',
      danger: '#FF4D4D',
    },
  },
  spacing: {
    xxs: 4,
    xs: 8,
    sm: 12,
    md: 16,
    lg: 20,
    xl: 24,
    xxl: 32,
    xxxl: 40,
    huge: 48,
    giant: 64,
  },
  radius: {
    compact: 12,
    control: 16,
    card: 22,
    panel: 28,
    dock: 32,
    pill: 999,
  },
  stroke: { hairline: 1, control: 1.5, emphasis: 2, focus: 3 },
  icon: { micro: 16, compact: 20, control: 24, feature: 32, hero: 48 },
  hitTarget: { minimum: 48, comfortable: 52, desktopCompact: 40 },
  blur: { glass: 18, glassStrong: 26, ambient: 42 },
  type: {
    latinFamily: 'Perfect Jakarta',
    persianFamily: 'Perfect Vazirmatn',
    roles: {
      display: { size: 44, height: 1.06, weight: 670 },
      pageTitle: { size: 30, height: 1.14, weight: 650 },
      section: { size: 20, height: 1.25, weight: 640 },
      body: { size: 16, height: 1.45, weight: 480 },
      label: { size: 13, height: 1.25, weight: 650 },
      meta: { size: 12, height: 1.3, weight: 540 },
    },
  },
  motion: {
    micro: { durationMs: 90, easing: 'ease-out' },
    quick: { durationMs: 140, easing: 'ease-out-cubic' },
    standard: { durationMs: 240, easing: 'ease-out-cubic' },
    emphasized: { durationMs: 320, easing: 'ease-in-out-emphasized' },
    modal: { durationMs: 360, easing: 'cubic-bezier(.22,1,.36,1)' },
    route: { durationMs: 380, easing: 'cubic-bezier(.22,1,.36,1)' },
    feedback: { durationMs: 600, easing: 'ease-out-cubic' },
  },
  geometry: {
    compactMax: 599,
    mediumMax: 899,
    expandedMax: 1199,
    contentReadableMax: 760,
    inspectorMin: 320,
    inspectorMax: 440,
    railCompact: 72,
    railExpanded: 232,
    phoneGutterMin: 16,
    phoneGutterMax: 24,
    wideGutterMax: 48,
  },
});

const familyMeta = Object.freeze({
  id: ['Identity', 'Shapes'],
  sh: ['Shell and navigation', 'PanelLeft'],
  ct: ['Common controls', 'MousePointer2'],
  sel: ['Selectors and metadata', 'ListFilter'],
  ov: ['Overlays', 'PanelsTopLeft'],
  st: ['System states', 'ShieldCheck'],
  td: ['Today stream', 'ListTree'],
  task: ['Task language', 'ListTodo'],
  habit: ['Habit language', 'Repeat2'],
  cap: ['Capture instrument', 'CirclePlus'],
  ai: ['Perfect AI', 'Sparkles'],
  voice: ['Voice', 'AudioLines'],
  wiz: ['Wizard and editor', 'PanelsTopLeft'],
  det: ['Detail and analytics', 'ChartNoAxesCombined'],
  ws: ['Workspace', 'Rows3'],
  plan: ['Planning', 'CalendarRange'],
  goal: ['Goals', 'Goal'],
  project: ['Projects and areas', 'FolderKanban'],
  review: ['Review rituals', 'ClipboardCheck'],
  focus: ['Focus', 'Timer'],
  game: ['Healthy gamification', 'Award'],
  set: ['Settings', 'Settings2'],
  diag: ['Diagnostics', 'Activity'],
  fb: ['Feedback', 'MessageSquareMore'],
  data: ['Data safety', 'DatabaseBackup'],
  update: ['Updates', 'Download'],
  wg: ['Android widget', 'LayoutDashboard'],
});

const foundations = Object.freeze([
  {
    id: 'fnd-color-roles',
    title: 'Semantic color roles',
    purpose: 'Paired foreground, background, border and status roles across light, dark and high contrast.',
    icon: 'SwatchBook',
  },
  {
    id: 'fnd-type-latin',
    title: 'Latin typography',
    purpose: 'Exact wordmark boundary plus live Plus Jakarta roles, numerals and long-copy behavior.',
    icon: 'Type',
  },
  {
    id: 'fnd-type-persian',
    title: 'Persian and bidi typography',
    purpose: 'Vazirmatn roles, Persian numerals, punctuation, bidi isolation and fallback metrics.',
    icon: 'Languages',
  },
  {
    id: 'fnd-spacing-density',
    title: 'Spacing, density and optical rhythm',
    purpose: 'Shared spacing, radius, stroke, elevation, blur, icon and hit-target ladders.',
    icon: 'Ruler',
  },
  {
    id: 'fnd-grid-width',
    title: 'Responsive geometry equations',
    purpose: 'Content-driven phone, tablet and Windows pane equations including short-height stress.',
    icon: 'PanelsTopLeft',
  },
  {
    id: 'fnd-icons',
    title: 'Icon and pictogram language',
    purpose: 'Optically corrected action family and 48-category SVG archive with no keyboard emoji.',
    icon: 'Shapes',
  },
  {
    id: 'fnd-material',
    title: 'Surface and material language',
    purpose: 'Quiet canvas, repeated rows, floating glass and non-blur/high-contrast fallbacks.',
    icon: 'Layers3',
  },
  {
    id: 'fnd-motion',
    title: 'Motion Bible',
    purpose: 'Triggers, timing, spatial intent, interruption, reverse and reduced-motion replacements.',
    icon: 'Waves',
  },
  {
    id: 'fnd-focus-a11y',
    title: 'Focus and accessibility language',
    purpose: 'Hover, focus, pressed, disabled, selected, target and semantic patterns.',
    icon: 'Accessibility',
  },
]);

const categoryIcons = Object.freeze([
  ['home', 'Home', 'Home'],
  ['work', 'Work', 'BriefcaseBusiness'],
  ['study', 'Study', 'GraduationCap'],
  ['health', 'Health', 'HeartPulse'],
  ['fitness', 'Fitness', 'Dumbbell'],
  ['medication', 'Medication', 'Pill'],
  ['mindfulness', 'Mindfulness', 'Brain'],
  ['sleep', 'Sleep', 'MoonStar'],
  ['water', 'Water', 'Droplets'],
  ['nutrition', 'Nutrition', 'Salad'],
  ['finance', 'Finance', 'WalletCards'],
  ['shopping', 'Shopping', 'ShoppingBag'],
  ['chores', 'Chores', 'ListChecks'],
  ['cleaning', 'Cleaning', 'Sparkles'],
  ['family', 'Family', 'Users'],
  ['friends', 'Friends', 'UserRound'],
  ['relationship', 'Relationship', 'HeartHandshake'],
  ['pets', 'Pets', 'PawPrint'],
  ['travel', 'Travel', 'Plane'],
  ['car', 'Car', 'Car'],
  ['learning', 'Learning', 'LibraryBig'],
  ['reading', 'Reading', 'BookOpen'],
  ['writing', 'Writing', 'PenLine'],
  ['coding', 'Coding', 'Code2'],
  ['design', 'Design', 'Palette'],
  ['music', 'Music', 'Music2'],
  ['art', 'Art', 'Brush'],
  ['photography', 'Photography', 'Camera'],
  ['creativity', 'Creativity', 'Lightbulb'],
  ['career', 'Career', 'TrendingUp'],
  ['meetings', 'Meetings', 'UsersRound'],
  ['calls', 'Calls', 'Phone'],
  ['email', 'Email', 'Mail'],
  ['planning', 'Planning', 'CalendarDays'],
  ['goals', 'Goals', 'Goal'],
  ['focus', 'Focus', 'Focus'],
  ['routine', 'Routine', 'Repeat2'],
  ['morning', 'Morning', 'Sunrise'],
  ['evening', 'Evening', 'Sunset'],
  ['outdoors', 'Outdoors', 'Trees'],
  ['nature', 'Nature', 'Leaf'],
  ['sports', 'Sports', 'Trophy'],
  ['gaming', 'Gaming', 'Gamepad2'],
  ['spiritual', 'Spiritual', 'Sparkle'],
  ['self-care', 'Self care', 'HandHeart'],
  ['appointment', 'Appointment', 'Stethoscope'],
  ['errands', 'Errands', 'MapPinned'],
  ['other', 'Other', 'Shapes'],
]);

const motionBible = Object.freeze({
  version: catalogVersion,
  families: [
    ['motion-route-enter', 'route', 'context continuity', 'title rises 10px while content fades and settles', 'crossfade in place'],
    ['motion-route-exit', 'standard', 'hierarchy reversal', 'content softens before route ownership changes', 'instant semantic swap'],
    ['motion-title-rise', 'standard', 'fresh page orientation', 'title rises 8px with no bounce', 'opacity only'],
    ['motion-header-scroll', 'quick', 'retain context', 'blur/stroke and compact title interpolate', 'two discrete states'],
    ['motion-footer-selection', 'quick', 'destination acknowledgement', 'pastel lens glides without geometry jump', 'instant lens placement'],
    ['motion-rail-collapse', 'emphasized', 'preserve workspace position', 'width and labels interpolate; content reflows', 'single layout swap'],
    ['motion-capture-morph', 'emphasized', 'one instrument changes jobs', 'orb unfolds into the selected Task/Plan/AI/Voice shell', 'crossfade within final bounds'],
    ['motion-ime', 'standard', 'maintain focused field', 'composer and viewport negotiate inset together', 'final inset applied'],
    ['motion-overlay', 'modal', 'show temporary hierarchy', 'anchor/scale/fade follows origin', 'fade only'],
    ['motion-task-state', 'quick', 'reversible outcome feedback', 'arc/color/icon interpolate within stable outer ring', 'state swaps in place'],
    ['motion-habit-increment', 'micro', 'rapid tactile counting', 'number ticks and receipt coalesces', 'value swaps without travel'],
    ['motion-sync-state', 'standard', 'background continuity', 'cloud mark changes stroke and bounded activity', 'label and symbol swap'],
    ['motion-optimistic-receipt', 'feedback', 'local-first confidence', 'receipt enters, holds, then yields to saved/Undo', 'persistent static receipt'],
    ['motion-detail-continuity', 'route', 'preserve selected entity', 'row identity connects to detail hero', 'crossfade preserving focus'],
    ['motion-wizard-step', 'standard', 'decision order', 'shared chrome stays; body moves 12px along progression', 'body crossfade'],
    ['motion-drag-reschedule', 'quick', 'direct manipulation', 'block lifts, snaps and confirms conflict/result', 'keyboard move receipt'],
    ['motion-focus-timer', 'standard', 'quiet temporal feedback', 'progress advances continuously without pulsing text', 'minute-step updates'],
    ['motion-reward', 'feedback', 'earned acknowledgement', 'one restrained bloom and receipt; never blocks work', 'static badge receipt'],
    ['motion-widget-action', 'quick', 'native optimistic action', 'row state changes immediately, queue marker resolves', 'native state swap'],
    ['motion-continuous-resize', 'standard', 'preserve state across breakpoints', 'panes reflow without scroll/focus reset', 'stable-state recomposition'],
  ].map(([id, token, intent, full, reduced]) => ({ id, token, intent, full, reduced })),
});

function parseGate() {
  const source = fs.readFileSync(gatePath, 'utf8').replace(/\r\n?/g, '\n');
  const rows = [];
  for (const line of source.split('\n')) {
    const match = line.match(/^\| `([a-z0-9-]+)` \| (.+) \|$/);
    if (!match) continue;
    rows.push({ id: match[1], description: match[2].trim() });
  }
  const foundationRows = rows.filter((row) => row.id.startsWith('fnd-'));
  const componentRows = rows.filter((row) => !row.id.startsWith('fnd-'));
  if (foundationRows.length !== 9) {
    throw new Error(`Expected 9 foundation rows, found ${foundationRows.length}.`);
  }
  if (componentRows.length !== 181) {
    throw new Error(`Expected 181 component rows, found ${componentRows.length}.`);
  }
  const ids = new Set(componentRows.map((row) => row.id));
  if (ids.size !== componentRows.length) {
    throw new Error('Component IDs are not unique.');
  }
  return { source, foundationRows, componentRows };
}

function familyFor(id) {
  return id.split('-')[0];
}

function titleFor(id) {
  return id
    .split('-')
    .slice(1)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function statesFor(component) {
  const id = component.id;
  const states = ['default'];
  if (/button|field|chip|toggle|checkbox|radio|slider|stepper|picker|menu|footer|rail|row|action|launcher|orb|calendar|block|bar|divider/.test(id)) {
    states.push('hover', 'focus', 'pressed');
  }
  if (/button|field|toggle|checkbox|radio|slider|stepper|picker|row|action|selector|swatch/.test(id)) {
    states.push('disabled');
  }
  if (/sync|receipt|status|control|capture|proposal|voice|data|update|feedback|quick-add|error|loading|progress/.test(id)) {
    states.push('pending', 'success', 'warning', 'offline', 'error');
  }
  if (/task|habit|calendar|history|streak|goal|project|plan|focus|game/.test(id)) {
    states.push('empty', 'sparse', 'dense');
  }
  return [...new Set(states)];
}

function slotsFor(component) {
  const id = component.id;
  if (/field/.test(id)) return ['label', 'input', 'leading', 'trailing-action', 'supporting-or-error'];
  if (/row/.test(id)) return ['leading-state', 'identity', 'metadata', 'secondary-progress', 'trailing-actions'];
  if (/footer|rail/.test(id)) return ['destinations', 'selection-lens', 'tooltip-or-label', 'safe-area', 'overflow'];
  if (/dialog|sheet|popover|route|wizard/.test(id)) return ['header', 'body', 'primary-action', 'secondary-action', 'dismiss-boundary'];
  if (/calendar|picker|library|selector/.test(id)) return ['query-or-period', 'option-grid', 'selection', 'summary', 'actions'];
  if (/chart|metric|heatmap|history|timeline/.test(id)) return ['title', 'measure', 'visual-series', 'legend', 'empty-or-source-note'];
  if (/capture|cap-|ai-|voice/.test(id)) return ['mode-identity', 'context', 'input-or-content', 'mode-actions', 'commit-or-cancel'];
  if (/button|action|toggle|checkbox|radio|slider|stepper/.test(id)) return ['hit-target', 'visual-control', 'label-or-value', 'focus-ring', 'state-layer'];
  return ['identity', 'primary-content', 'secondary-context', 'state-cue', 'action-or-continuation'];
}

function inputsFor(component) {
  const family = familyFor(component.id);
  const base = ['theme', 'locale-and-direction', 'text-scale', 'input-modality', 'window-constraints'];
  if (['task', 'habit', 'td', 'det', 'plan', 'goal', 'project', 'review', 'focus', 'game', 'wg'].includes(family)) {
    base.push('durable-planner-projection');
  }
  if (['cap', 'ai', 'voice', 'wiz'].includes(family)) base.push('draft-state');
  if (['st', 'sh', 'diag', 'data', 'update'].includes(family)) base.push('system-state');
  return base;
}

function outputsFor(component) {
  const id = component.id;
  const outputs = ['semantic-state', 'focus-and-pointer-feedback'];
  if (/action|control|button|toggle|checkbox|radio|slider|stepper|picker|row|capture|proposal|quick-add|block/.test(id)) {
    outputs.push('intent-only-event');
  }
  if (/field|capture|voice|wizard|wiz-/.test(id)) outputs.push('draft-change');
  return outputs;
}

function mutationFor(component) {
  const id = component.id;
  if (/status-control|habit-control|quick-add|proposal-action|capture|cap-send|plan-time-block|lifecycle-actions|data-import/.test(id)) {
    return 'durable local-first operation id; optimistic projection; retry-safe outbox; Undo where reversible';
  }
  return 'none; component emits intent and never writes persistence directly';
}

function consumersFor(component) {
  const family = familyFor(component.id);
  const common = {
    id: ['bootstrap', 'header', 'widget', 'Windows shell', 'installer'],
    sh: ['every in-app route', 'phone footer', 'tablet rail', 'Windows rail'],
    ct: ['forms', 'filters', 'capture', 'settings', 'feedback', 'AI'],
    sel: ['wizard', 'editor', 'filters', 'settings'],
    ov: ['wizard', 'detail actions', 'settings', 'feedback', 'AI review'],
    st: ['bootstrap', 'workspaces', 'sync', 'AI', 'widget', 'recovery'],
    td: ['Today phone', 'Today tablet', 'Today Windows'],
    task: ['Today', 'Tasks', 'Plan', 'detail', 'widget'],
    habit: ['Today', 'Habits', 'detail', 'widget', 'review'],
    cap: ['Today capture instrument', 'Windows shortcut'],
    ai: ['capture instrument', 'AI route', 'proposal review'],
    voice: ['capture instrument', 'AI route'],
    wiz: ['task create', 'recurring create', 'habit create', 'edit flows'],
    det: ['phone detail route', 'tablet detail pane', 'Windows inspector'],
    ws: ['Tasks', 'Habits', 'Goals', 'Projects', 'Notes'],
    plan: ['day plan', 'week plan', 'month plan'],
    goal: ['Goals', 'horizon review', 'detail'],
    project: ['Projects', 'Areas', 'detail'],
    review: ['weekly review', 'monthly review'],
    focus: ['focus setup', 'running session', 'history'],
    game: ['habit detail', 'review', 'achievements'],
    set: ['More', 'settings', 'profile'],
    diag: ['diagnostics', 'feedback evidence'],
    fb: ['feedback launcher', 'draft', 'entries'],
    data: ['settings data', 'recovery'],
    update: ['settings', 'installer handoff'],
    wg: ['Android widget size families'],
  };
  return common[family] || ['mapped consumers'];
}

function siblingNamesFor(component) {
  const family = familyFor(component.id);
  const siblings = {
    id: ['wordmark', 'header', 'installed surface'],
    sh: ['page title', 'Sync Cloud', 'content frame'],
    ct: ['label', 'supporting copy', 'neighbor action'],
    sel: ['search', 'selection summary', 'create action'],
    ov: ['anchor', 'body content', 'safe dismissal'],
    st: ['local content', 'recovery action', 'diagnostics'],
    td: ['Today Pulse', 'stream zone', 'capture orb'],
    task: ['time rail', 'task row', 'status control'],
    habit: ['habit identity', 'method control', 'streak receipt'],
    cap: ['capture orb', 'mode actions', 'footer'],
    ai: ['context strip', 'conversation', 'proposal'],
    voice: ['mode action', 'recorder', 'transcript'],
    wiz: ['named progress', 'step body', 'footer'],
    det: ['detail hero', 'facts', 'history'],
    ws: ['query bar', 'group heading', 'result row'],
    plan: ['period strip', 'time grid', 'unscheduled tray'],
    goal: ['horizon', 'outcome card', 'checkpoint'],
    project: ['project health', 'linked work', 'goal'],
    review: ['evidence', 'reflection', 'next adjustment'],
    focus: ['setup', 'timer', 'reflection'],
    game: ['earned source', 'reward receipt', 'history'],
    set: ['section', 'row', 'value'],
    diag: ['health card', 'log evidence', 'recovery'],
    fb: ['launcher', 'draft', 'private entry'],
    data: ['backup summary', 'dry run', 'recovery'],
    update: ['current version', 'download', 'install'],
    wg: ['header', 'scroll list', 'Quick Add'],
  };
  return siblings[family] || ['context', 'component', 'action'];
}

function contractFor(component) {
  const family = familyFor(component.id);
  const [familyTitle] = familyMeta[family] || ['Unclassified'];
  return {
    component_id: component.id,
    catalog_version: catalogVersion,
    version: 1,
    family,
    family_title: familyTitle,
    title: titleFor(component.id),
    purpose: component.description,
    correct_use: `Use the canonical ${component.id} owner anywhere this semantic job appears; do not redraw a route-local substitute.`,
    anatomy: {
      slots: slotsFor(component),
      alignment_axes: ['content-baseline', 'optical-center', 'interactive-center'],
      stable_outer_geometry: true,
    },
    semantic_owner: `${familyTitle} / ${component.id}`,
    canonical_semantic_owner: `${familyTitle} / ${component.id}`,
    inputs: inputsFor(component),
    outputs: outputsFor(component),
    mutation_contract: mutationFor(component),
    states: {
      precedence: ['disabled', 'hard-error', 'conflict', 'busy', 'pressed', 'focus', 'hover', 'selected', 'default'],
      required: statesFor(component),
      documented_variants: component.description,
    },
    responsive: {
      phone: 'Intrinsic copy and >=48dp targets; wrap or stack before clipping; preserve one-handed primary action.',
      tablet: 'Use compact rail and supporting/list-detail space only when live constraints keep both panes useful.',
      windows: 'Use pointer density, hover/focus/shortcut and bounded panes; never stretch a phone card across the canvas.',
      short_height: 'Move secondary content into the scroll owner; keep focused field and required actions reachable above IME.',
      breakpoint_state_continuity: ['draft', 'focus', 'selection', 'scroll', 'expanded-state'],
    },
    interaction: {
      touch: ['minimum 48dp semantic target', 'press feedback before mutation receipt'],
      mouse: ['hover without geometry jump', 'right-click only where a visible route/action alternative exists'],
      keyboard: ['ordered focus', 'Enter/Space activation where conventional', 'Escape restores prior focus'],
      screen_reader: ['single semantic owner', 'state and value announced without color dependence'],
    },
    rtl_mixed_copy: 'Direction derives per live field/span; icon mirroring is semantic, not automatic; mandatory labels remain whole at 200%.',
    tokens: ['PS01 color roles', 'Perfect spacing/radius ladder', 'Perfect type roles', 'Perfect motion Bible'],
    assets: family === 'id' ? ['canonical Day Compass/wordmark or manifest-owned SVG'] : [],
    decomposition: {
      live_layers: ['dynamic copy', 'value/state semantics', 'focusable controls', 'screen-reader value'],
      authored_layers: family === 'id'
        ? ['canonical brand raster/vector selected by asset manifest']
        : ['token-authored surface, stroke, icon and state material'],
      forbidden_flattening: ['user data', 'editable copy', 'interactive control', 'error or permission message'],
      implementation_boundary: 'Preview pixels define composition; production retains live Flutter/native semantics.',
    },
    motion_ids: motionIdsFor(component),
    reduced_motion: 'Preserve final geometry and semantic announcement; replace travel, pulse and continuous rotation with crossfade or state swap.',
    performance_budget: performanceBudgetFor(component),
    consumers: consumersFor(component),
    preview_files: [
      'anatomy.svg',
      'states-light.png',
      'states-dark.png',
      'responsive.png',
      'accessibility.png',
      'motion-board.png',
      'neighbor-plate.png',
    ],
    preview_sha256: {},
    intentional_variants: ['theme role substitution', 'input-modality affordance', 'documented responsive recomposition'],
    fixture_boundary: 'All names and values in previews are fixture-only and cannot be imported or seeded into production persistence.',
    sibling_context: siblingNamesFor(component),
  };
}

function motionIdsFor(component) {
  const id = component.id;
  const ids = ['motion-continuous-resize'];
  if (/footer/.test(id)) ids.push('motion-footer-selection');
  if (/rail/.test(id)) ids.push('motion-rail-collapse');
  if (/cap-|capture|ai-shell|voice/.test(id)) ids.push('motion-capture-morph');
  if (/task-status|habit-control/.test(id)) ids.push('motion-task-state');
  if (/habit-control-count/.test(id)) ids.push('motion-habit-increment');
  if (/sync/.test(id)) ids.push('motion-sync-state');
  if (/receipt|toast/.test(id)) ids.push('motion-optimistic-receipt');
  if (/detail|det-/.test(id)) ids.push('motion-detail-continuity');
  if (/wiz-/.test(id)) ids.push('motion-wizard-step');
  if (/focus/.test(id)) ids.push('motion-focus-timer');
  if (/game-/.test(id)) ids.push('motion-reward');
  if (/wg-/.test(id)) ids.push('motion-widget-action');
  if (/dialog|sheet|popover|overlay/.test(id)) ids.push('motion-overlay');
  return [...new Set(ids)];
}

function performanceBudgetFor(component) {
  const family = familyFor(component.id);
  if (['task', 'habit', 'td', 'ws', 'plan', 'wg'].includes(family)) {
    return 'steady-state row interaction <=1 frame of synchronous work; no full-list rebuild; authored assets decode once';
  }
  if (['cap', 'ai', 'voice', 'wiz', 'ov'].includes(family)) {
    return 'open/transition remains within frame budget after warm-up; no layout jump; expensive work is cancelable and off the UI thread';
  }
  return 'no unbounded intrinsic pass; assets cached; hover/focus/press state changes stay within one frame';
}

module.exports = {
  projectRoot,
  documentRoot,
  gatePath,
  foundationRoot,
  componentRoot,
  manifestRoot,
  catalogVersion,
  generatedAt,
  tokens,
  familyMeta,
  foundations,
  categoryIcons,
  motionBible,
  parseGate,
  familyFor,
  titleFor,
  statesFor,
  slotsFor,
  contractFor,
  siblingNamesFor,
};
