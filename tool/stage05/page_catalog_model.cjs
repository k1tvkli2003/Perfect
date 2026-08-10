const fs = require('fs');
const path = require('path');

const stage04 = require('../stage04/design_catalog_model.cjs');

const projectRoot = stage04.projectRoot;
const documentRoot = stage04.documentRoot;
const gatePath = stage04.gatePath;
const pageRoot = path.join(documentRoot, 'design', '03-pages');
const manifestRoot = path.join(documentRoot, 'design', '04-copy-manifests');
const comparisonRoot = path.join(
  documentRoot,
  'design',
  '05-runtime-comparisons',
  'stage05',
);
const rejectedRoot = path.join(documentRoot, 'design', 'rejected', 'stage05');
const componentsManifestPath = path.join(manifestRoot, 'components.json');

const catalogVersion = 'ps01-pages-1.0.0';
const componentCatalogVersion = stage04.catalogVersion;
const generatedAt = '2026-08-10';

const canonicalVariants = Object.freeze([
  {
    file: 'phone-compact.png',
    viewport: '390x844',
    width: 390,
    height: 844,
    layout: 'phone-compact',
    theme: 'light',
    density: 'normal',
    textScale: 1,
    locale: 'en-GB',
    direction: 'ltr',
  },
  {
    file: 'phone-landscape.png',
    viewport: '844x390',
    width: 844,
    height: 390,
    layout: 'phone-landscape-short',
    theme: 'light',
    density: 'dense',
    textScale: 1,
    locale: 'en-GB',
    direction: 'ltr',
  },
  {
    file: 'tablet-portrait.png',
    viewport: '800x1280',
    width: 800,
    height: 1280,
    layout: 'tablet-portrait',
    theme: 'light',
    density: 'normal',
    textScale: 1,
    locale: 'fa-IR',
    direction: 'rtl',
  },
  {
    file: 'tablet-landscape.png',
    viewport: '1280x800',
    width: 1280,
    height: 800,
    layout: 'tablet-landscape',
    theme: 'light',
    density: 'dense',
    textScale: 1,
    locale: 'en-GB',
    direction: 'ltr',
  },
  {
    file: 'windows-compact.png',
    viewport: '720x540',
    width: 720,
    height: 540,
    layout: 'windows-compact',
    theme: 'light',
    density: 'normal',
    textScale: 1,
    locale: 'en-GB',
    direction: 'ltr',
  },
  {
    file: 'windows-wide.png',
    viewport: '1366x768',
    width: 1366,
    height: 768,
    layout: 'windows-wide',
    theme: 'light',
    density: 'dense',
    textScale: 1,
    locale: 'en-GB',
    direction: 'ltr',
  },
  {
    file: 'dark.png',
    viewport: '390x844',
    width: 390,
    height: 844,
    layout: 'phone-compact',
    theme: 'dark',
    density: 'dense',
    textScale: 1,
    locale: 'en-GB',
    direction: 'ltr',
  },
  {
    file: 'stress.png',
    viewport: '720x540',
    width: 720,
    height: 540,
    layout: 'windows-compact-short',
    theme: 'high-contrast',
    density: 'dense-long-copy',
    textScale: 2,
    locale: 'fa-IR+en-GB',
    direction: 'mixed',
  },
  {
    file: 'system-state.png',
    viewport: '1200x800',
    width: 1200,
    height: 800,
    layout: 'state-comparison-board',
    theme: 'light-dark-high-contrast',
    density: 'state-matrix',
    textScale: 1,
    locale: 'en-GB+fa-IR',
    direction: 'mixed',
  },
  {
    file: 'motion-board.png',
    viewport: '1200x800',
    width: 1200,
    height: 800,
    layout: 'motion-storyboard',
    theme: 'light',
    density: 'five-frames',
    textScale: 1,
    locale: 'en-GB',
    direction: 'ltr',
  },
]);

const candidates = Object.freeze([
  {
    id: 'candidate-focus-spine',
    file: 'candidate-focus-spine.png',
    title: 'Focus Spine',
    structure: 'One continuous vertical answer path with the primary action inside reach, not in a detached dashboard card.',
  },
  {
    id: 'candidate-split-workbench',
    file: 'candidate-split-workbench.png',
    title: 'Split Workbench',
    structure: 'Master context and live work remain adjacent; wide layouts gain an inspector while compact layouts preserve route continuity.',
  },
  {
    id: 'candidate-command-ledger',
    file: 'candidate-command-ledger.png',
    title: 'Command Ledger',
    structure: 'Query, filters and reversible actions lead a dense evidence-first ledger with restrained decoration.',
  },
]);

const familyLabels = Object.freeze({
  entry: 'Entry and trust',
  shell: 'Adaptive shell',
  today: 'Today instrument',
  capture: 'Capture instrument',
  wizard: 'Creation and editing',
  detail: 'View-first detail',
  workspace: 'Workspace and horizons',
  focus: 'Focus and healthy reward',
  settings: 'Owner tools and recovery',
  assistant: 'Feedback and Perfect AI',
  native: 'Native and external entry',
});

const titleOverrides = Object.freeze({
  'pg-bootstrap': 'Starting Perfect!',
  'pg-splash-transition': 'From launch to your day',
  'pg-configuration': 'Finish private setup',
  'pg-sign-in': 'Welcome back',
  'pg-password-update': 'Update private access',
  'pg-session-expired': 'Session needs attention',
  'pg-bootstrap-recovery': 'Recover startup',
  'pg-shell-phone': 'Phone day shell',
  'pg-shell-short-landscape': 'Short landscape shell',
  'pg-shell-tablet-collapsed': 'Tablet compact rail',
  'pg-shell-tablet-expanded': 'Tablet expanded rail',
  'pg-shell-windows-compact': 'Compact Windows workspace',
  'pg-shell-windows-intermediate': 'Intermediate Windows workspace',
  'pg-shell-windows-wide': 'Wide Windows workspace',
  'pg-today-empty': 'A clean first day',
  'pg-today-sparse': 'Today, at a glance',
  'pg-today-normal': 'Today',
  'pg-today-dense': 'A full day, still calm',
  'pg-today-offline': 'Today is ready offline',
  'pg-today-retry-error': 'Today needs a retry',
  'pg-today-conflict': 'Resolve today safely',
  'pg-capture-collapsed': 'Quick Capture at rest',
  'pg-capture-task': 'Capture a task',
  'pg-capture-plan': 'Plan time quickly',
  'pg-capture-ai': 'Ask Perfect AI',
  'pg-capture-voice': 'Speak to Perfect',
  'pg-capture-proposal-review': 'Review the plan first',
  'pg-capture-ime': 'Capture with the keyboard open',
  'pg-capture-interrupted-resize': 'Capture survives resize',
  'pg-create-choice': 'What are you creating?',
  'pg-task-identity': 'Name and place the task',
  'pg-task-definition': 'Define the outcome',
  'pg-task-schedule': 'Choose when it belongs',
  'pg-task-recurrence': 'Set the repeat pattern',
  'pg-task-recovery': 'Decide what happens when missed',
  'pg-task-reminder': 'Add useful reminders',
  'pg-task-review': 'Review the task',
  'pg-habit-identity': 'Name and place the habit',
  'pg-habit-tracking': 'Choose how progress is logged',
  'pg-habit-target': 'Set a meaningful target',
  'pg-habit-multiple-daily': 'Make repeated logging effortless',
  'pg-habit-schedule': 'Choose valid habit days',
  'pg-habit-recovery': 'Protect continuity without cheating',
  'pg-habit-reminder': 'Choose gentle reminders',
  'pg-habit-review': 'Review the habit',
  'pg-edit-task': 'Edit task details',
  'pg-edit-recurring-task': 'Edit the recurring series safely',
  'pg-edit-habit': 'Edit habit details',
  'pg-editor-validation': 'Fix what needs attention',
  'pg-editor-discard-draft': 'Keep or discard this draft?',
  'pg-detail-task': 'Task details',
  'pg-detail-recurring-task': 'Recurring task details',
  'pg-detail-habit': 'Habit details',
  'pg-detail-habit-history': 'Habit history',
  'pg-detail-habit-analytics': 'Habit patterns',
  'pg-detail-goal': 'Goal details',
  'pg-detail-project': 'Project details',
  'pg-detail-area': 'Area details',
  'pg-detail-note': 'Note details',
  'pg-detail-focus-session': 'Focus session details',
  'pg-detail-lifecycle-confirm': 'Confirm this lifecycle change',
  'pg-detail-desktop-inspector': 'Selected item inspector',
  'pg-tasks-default': 'Tasks',
  'pg-tasks-search': 'Search tasks',
  'pg-tasks-filtered': 'Filtered tasks',
  'pg-tasks-dense': 'Dense task workspace',
  'pg-tasks-bulk': 'Bulk task actions',
  'pg-plan-day': 'Day plan',
  'pg-plan-week': 'Week plan',
  'pg-plan-month': 'Month plan',
  'pg-plan-unscheduled': 'Unscheduled work',
  'pg-plan-overlap-conflict': 'Resolve a time conflict',
  'pg-plan-drag-resize': 'Move and resize time',
  'pg-habits-today': 'Habits today',
  'pg-habits-insights': 'Habit insights',
  'pg-habits-build-maintain-quit': 'Build, maintain and quit',
  'pg-habits-dense': 'Dense habit workspace',
  'pg-goals': 'Goals',
  'pg-projects': 'Projects',
  'pg-areas': 'Areas',
  'pg-notes': 'Notes',
  'pg-horizon-week': 'This week',
  'pg-horizon-month': 'This month',
  'pg-horizon-quarter': 'This quarter',
  'pg-horizon-year': 'This year',
  'pg-review-week': 'Weekly review',
  'pg-review-month': 'Monthly review',
  'pg-focus-setup': 'Set up focus',
  'pg-focus-running': 'Focus in progress',
  'pg-focus-paused-background': 'Focus is paused',
  'pg-focus-complete-reflection': 'Close the focus loop',
  'pg-focus-history': 'Focus history',
  'pg-achievements': 'Achievements',
  'pg-streak-recovery': 'Recover a streak honestly',
  'pg-reward-receipt': 'Reward receipt',
  'pg-more': 'More',
  'pg-profile-session': 'Profile and devices',
  'pg-settings-appearance': 'Appearance',
  'pg-settings-reminders': 'Reminders and quiet hours',
  'pg-settings-widget': 'Android widget',
  'pg-settings-ai': 'Perfect AI',
  'pg-settings-data': 'Data and privacy',
  'pg-archive-trash': 'Archive and trash',
  'pg-conflict-center': 'Conflict center',
  'pg-insights-review': 'Insights and reviews',
  'pg-diagnostics': 'Diagnostics',
  'pg-backup-export': 'Backup and export',
  'pg-import-dry-run': 'Import preview',
  'pg-data-recovery': 'Data recovery',
  'pg-update-status': 'Update status',
  'pg-feedback-launcher': 'Feedback, within reach',
  'pg-feedback-menu': 'What would you like to capture?',
  'pg-feedback-screenshot-draft': 'Screenshot feedback',
  'pg-feedback-note-draft': 'Write a private note',
  'pg-feedback-entries': 'Saved feedback',
  'pg-feedback-entry-detail': 'Feedback details',
  'pg-feedback-export': 'Export feedback',
  'pg-ai-empty': 'What should we shape?',
  'pg-ai-conversation': 'Plan with Perfect AI',
  'pg-ai-listening': 'Perfect is listening',
  'pg-ai-proposal': 'Review AI changes',
  'pg-ai-conflict': 'AI proposal has a conflict',
  'pg-ai-error-offline': 'AI is unavailable, your plan is not',
  'pg-widget-compact': 'Compact widget',
  'pg-widget-medium': 'Medium widget',
  'pg-widget-tall': 'Tall widget',
  'pg-widget-wide': 'Wide widget',
  'pg-widget-large': 'Large widget',
  'pg-widget-empty': 'Empty widget',
  'pg-widget-quick-add': 'Widget Quick Add',
  'pg-widget-offline-action': 'Widget action queued offline',
  'pg-notification-open': 'Opened from a reminder',
  'pg-stale-deep-link': 'That item changed',
  'pg-windows-protocol-open': 'Opened from Windows',
});

function parseGate() {
  const source = fs.readFileSync(gatePath, 'utf8').replace(/\r\n?/g, '\n');
  const start = source.indexOf('## 5. Full-page composition registry');
  const end = source.indexOf('## 6. Coverage matrix');
  if (start < 0 || end <= start) throw new Error('Cannot locate the full-page registry in the preview gate.');
  const section = source.slice(start, end);
  const rows = [];
  let subgroup = '';
  for (const line of section.split('\n')) {
    const heading = line.match(/^### 5\.\d+ (.+)$/);
    if (heading) subgroup = heading[1].trim();
    for (const match of line.matchAll(/`(pg-[a-z0-9-]+)`/g)) {
      rows.push({ id: match[1], subgroup });
    }
  }
  if (rows.length !== 134) throw new Error(`Expected 134 page IDs, found ${rows.length}.`);
  if (new Set(rows.map((row) => row.id)).size !== rows.length) throw new Error('Page IDs are not unique.');
  return { source, section, rows };
}

function titleFor(pageId) {
  if (titleOverrides[pageId]) return titleOverrides[pageId];
  return pageId
    .replace(/^pg-/, '')
    .split('-')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function familyFor(pageId) {
  if (/^pg-(bootstrap|splash|configuration|sign-in|password|session)/.test(pageId)) return 'entry';
  if (/^pg-shell-/.test(pageId)) return 'shell';
  if (/^pg-today-/.test(pageId)) return 'today';
  if (/^pg-capture-/.test(pageId)) return 'capture';
  if (/^pg-(create|task-|habit-|edit-|editor-)/.test(pageId)) return 'wizard';
  if (/^pg-detail-/.test(pageId)) return 'detail';
  if (/^pg-(tasks|plan|habits|goals$|projects$|areas$|notes$|horizon|review)/.test(pageId)) return 'workspace';
  if (/^pg-(focus|achievements|streak|reward)/.test(pageId)) return 'focus';
  if (/^pg-(more$|profile|settings|archive|conflict|insights|diagnostics|backup|import|data|update)/.test(pageId)) return 'settings';
  if (/^pg-(feedback|ai-)/.test(pageId)) return 'assistant';
  return 'native';
}

function primaryQuestion(page) {
  const family = familyFor(page.id);
  const title = titleFor(page.id);
  const questions = {
    entry: 'Can I enter my private planner safely and recover without losing local work?',
    shell: 'Where am I, what matters now, and how do I move without losing context?',
    today: 'What deserves my attention next, and what can I complete in one touch?',
    capture: 'How can I record this thought now without turning it into form-filling?',
    wizard: 'What is the next meaningful decision, with advanced options available only when needed?',
    detail: 'What is true about this item, how has it changed, and what is the safest next action?',
    workspace: 'How do I find, compare and act on the right work without filter or card noise?',
    focus: 'How do I protect attention, finish honestly and learn without manipulative gamification?',
    settings: 'How do I understand and change this owner-level setting without risking data or session continuity?',
    assistant: 'How do I capture or ask for help while retaining review and control over every write?',
    native: 'How does this native entry stay glanceable, actionable and consistent with local-first truth?',
  };
  return `${questions[family]} Surface: ${title}.`;
}

function primaryAction(page) {
  const id = page.id;
  if (/sign-in/.test(id)) return 'Continue securely';
  if (/recovery|retry|error|stale|conflict/.test(id)) return 'Inspect and recover';
  if (/capture-task/.test(id)) return 'Save task';
  if (/capture-plan/.test(id)) return 'Add time block';
  if (/capture-ai|ai-(empty|conversation)/.test(id)) return 'Send to Perfect AI';
  if (/proposal/.test(id)) return 'Review then apply';
  if (/voice|listening/.test(id)) return 'Start or stop recording';
  if (/task-|habit-|create|edit|editor/.test(id)) return /review/.test(id) ? 'Save after review' : 'Continue';
  if (/detail/.test(id)) return 'Act on the live item';
  if (/focus-setup/.test(id)) return 'Begin focus';
  if (/focus-running/.test(id)) return 'Pause safely';
  if (/backup/.test(id)) return 'Create verified backup';
  if (/import/.test(id)) return 'Confirm dry run';
  if (/widget-quick-add/.test(id)) return 'Add to today';
  if (/today|tasks|plan|habits|goals|projects|areas|notes/.test(id)) return 'Open the next relevant item';
  return 'Continue with the clearest safe action';
}

function fixtureFor(pageId) {
  if (/empty/.test(pageId)) return 'fx-owner-empty';
  if (/sparse/.test(pageId)) return 'fx-owner-sparse';
  if (/dense|history|analytics|month|year|entries/.test(pageId)) return 'fx-owner-dense';
  if (/offline|retry|error|conflict|expired|recovery|stale/.test(pageId)) return 'fx-system-adversarial';
  return 'fx-owner-normal';
}

function stateSet(pageId) {
  const states = ['local-ready', 'loading', 'optimistic', 'synced'];
  if (/offline/.test(pageId)) states.unshift('offline-start', 'write-queued');
  if (/retry|error|recovery/.test(pageId)) states.push('retrying', 'recoverable-error', 'hard-error');
  if (/conflict/.test(pageId)) states.push('conflict', 'resolved', 'Undo');
  if (/capture|wizard|task-|habit-|edit|editor/.test(pageId)) states.push('draft', 'validation', 'saving', 'success-Undo');
  if (/ai-|proposal/.test(pageId)) states.push('thinking', 'proposal', 'review', 'applying', 'partial-failure');
  if (/widget/.test(pageId)) states.push('pending-native-action', 'background-replay');
  return [...new Set(states)];
}

function routeSet(page) {
  const base = page.id.replace(/^pg-/, '');
  const family = familyFor(page.id);
  const entry = family === 'native'
    ? ['native-intent', `/${base}`]
    : ['authenticated-shell', `/${base}`];
  const exit = ['back-with-state', family === 'detail' ? '/previous-workspace' : '/today'];
  return { entry, exit };
}

function candidateWinner(pageId) {
  const family = familyFor(pageId);
  if (['entry', 'today', 'capture', 'focus', 'native'].includes(family)) return 'candidate-focus-spine';
  if (['shell', 'detail', 'workspace'].includes(family)) return 'candidate-split-workbench';
  return 'candidate-command-ledger';
}

function pageAccent(pageId) {
  const family = familyFor(pageId);
  if (['today', 'capture', 'wizard'].includes(family)) return 'apricot';
  if (['workspace', 'focus', 'settings'].includes(family)) return 'mint';
  if (['detail', 'assistant'].includes(family)) return 'lilac';
  if (family === 'native') return 'sync';
  return 'ink';
}

function preferredPrefixes(pageId) {
  const family = familyFor(pageId);
  const groups = {
    entry: ['id', 'sh', 'ct', 'st'],
    shell: ['id', 'sh', 'ct', 'ov', 'st'],
    today: ['sh', 'td', 'task', 'habit', 'cap', 'st'],
    capture: ['sh', 'cap', 'ai', 'voice', 'ct', 'st'],
    wizard: ['sh', 'wiz', 'ct', 'sel', 'ov', 'st'],
    detail: ['sh', 'det', 'task', 'habit', 'goal', 'project', 'game', 'ct', 'ov'],
    workspace: ['sh', 'ws', 'task', 'habit', 'plan', 'goal', 'project', 'review', 'ct', 'sel'],
    focus: ['sh', 'focus', 'game', 'review', 'ct', 'st'],
    settings: ['sh', 'set', 'diag', 'data', 'update', 'fb', 'ct', 'ov', 'st'],
    assistant: ['sh', 'fb', 'ai', 'voice', 'cap', 'ct', 'ov', 'st'],
    native: ['wg', 'id', 'st'],
  };
  return groups[family];
}

function directComponentIds(pageId) {
  const ids = new Set(['sh-page-canvas', 'sh-title-cluster', 'sh-page-scroll-frame', 'sh-system-overlay-anchor']);
  if (!/^pg-widget/.test(pageId)) ids.add('sh-glass-header');
  if (/today|shell|tasks|plan|habits|goals|projects|areas|notes|more|settings|feedback|ai/.test(pageId)) {
    ids.add('sh-sync-cloud');
  }
  if (/phone|today|capture/.test(pageId)) ids.add('sh-phone-footer');
  if (/tablet/.test(pageId)) ids.add('sh-tablet-rail');
  if (/windows/.test(pageId)) ids.add('sh-windows-rail');
  if (/today/.test(pageId)) {
    ['td-pulse', 'td-stream', 'td-next-action', 'task-row', 'task-status-control', 'habit-row', 'cap-orb'].forEach((id) => ids.add(id));
  }
  if (/capture/.test(pageId)) {
    ['cap-orb', 'cap-expanded-shell', 'cap-mode-actions', 'cap-send-action'].forEach((id) => ids.add(id));
  }
  if (/capture-task/.test(pageId)) ids.add('cap-task-mode');
  if (/capture-plan/.test(pageId)) ids.add('cap-plan-mode');
  if (/capture-ai|ai-/.test(pageId)) ['ai-shell', 'ai-context-strip', 'ai-message'].forEach((id) => ids.add(id));
  if (/proposal/.test(pageId)) ['ai-proposal', 'ai-proposal-action'].forEach((id) => ids.add(id));
  if (/voice|listening/.test(pageId)) ['voice-recorder', 'ct-voice-field'].forEach((id) => ids.add(id));
  if (/task-|habit-|create|edit|editor/.test(pageId)) ['wiz-progress', 'wiz-footer'].forEach((id) => ids.add(id));
  if (/identity/.test(pageId)) ids.add('wiz-identity-step');
  if (/definition|tracking|target|multiple/.test(pageId)) ids.add('wiz-definition-step');
  if (/schedule/.test(pageId)) ids.add('wiz-schedule-step');
  if (/recurrence/.test(pageId)) ids.add('wiz-recurrence-step');
  if (/recovery/.test(pageId)) ids.add('wiz-recovery-step');
  if (/reminder/.test(pageId)) ids.add('wiz-reminder-step');
  if (/review/.test(pageId)) ids.add('wiz-review-step');
  if (/detail/.test(pageId)) ['det-hero', 'det-fact-group', 'det-relations', 'det-history-timeline', 'det-lifecycle-actions'].forEach((id) => ids.add(id));
  if (/analytics|insights/.test(pageId)) ['det-chart', 'det-insight'].forEach((id) => ids.add(id));
  if (/habit-history/.test(pageId)) ['det-month-calendar', 'det-habit-heatmap'].forEach((id) => ids.add(id));
  if (/tasks/.test(pageId)) ['ws-query-bar', 'ws-filter-deck', 'ws-group-header'].forEach((id) => ids.add(id));
  if (/plan/.test(pageId)) ['plan-week-strip', 'plan-day-column', 'plan-unscheduled-tray'].forEach((id) => ids.add(id));
  if (/goals|horizon/.test(pageId)) ['goal-outcome-card', 'goal-horizon-strip'].forEach((id) => ids.add(id));
  if (/projects|areas/.test(pageId)) ids.add('project-area-card');
  if (/review-(week|month)/.test(pageId)) ids.add('review-checkpoint');
  if (/focus/.test(pageId)) ['focus-setup', 'focus-timer', 'focus-reflection'].forEach((id) => ids.add(id));
  if (/achievement/.test(pageId)) ids.add('game-achievement');
  if (/streak/.test(pageId)) ids.add('game-streak');
  if (/reward/.test(pageId)) ids.add('game-reward-receipt');
  if (/settings|profile|more/.test(pageId)) ['set-section', 'set-row'].forEach((id) => ids.add(id));
  if (/diagnostics/.test(pageId)) ['diag-status-card', 'diag-log-viewer'].forEach((id) => ids.add(id));
  if (/feedback/.test(pageId)) ['fb-launcher', 'fb-menu'].forEach((id) => ids.add(id));
  if (/backup|import|data-recovery/.test(pageId)) ['data-backup-summary', 'data-import-dry-run', 'data-recovery'].forEach((id) => ids.add(id));
  if (/update/.test(pageId)) ids.add('update-status');
  if (/widget/.test(pageId)) ['wg-header', 'wg-scroll-list', 'wg-task-row', 'wg-habit-row'].forEach((id) => ids.add(id));
  if (/widget-quick-add/.test(pageId)) ids.add('wg-quick-add');
  return [...ids];
}

function assignComponents(pageRows, componentRows) {
  const valid = new Set(componentRows.map((entry) => entry.component_id));
  const assignments = new Map(pageRows.map((page) => [page.id, directComponentIds(page.id).filter((id) => valid.has(id))]));
  const counters = new Map();
  for (const component of componentRows) {
    const prefix = component.family || component.component_id.split('-')[0];
    const eligible = pageRows.filter((page) => preferredPrefixes(page.id).includes(prefix));
    if (eligible.length === 0) throw new Error(`No compatible page for component ${component.component_id}.`);
    const index = counters.get(prefix) || 0;
    counters.set(prefix, index + 1);
    const target = eligible[index % eligible.length];
    const current = assignments.get(target.id);
    if (!current.includes(component.component_id)) current.push(component.component_id);
  }
  return assignments;
}

function liveCopy(page) {
  const title = titleFor(page.id);
  const family = familyFor(page.id);
  const primary = primaryAction(page);
  const descriptions = {
    entry: 'Private, local-first and ready to continue where you left off.',
    shell: 'Your place, selection, draft and scroll stay intact while the workspace adapts.',
    today: 'A continuous day stream—next action first, everything else still reachable.',
    capture: 'One calm instrument that changes shape only when you choose its job.',
    wizard: 'Only the next decision is prominent; advanced power stays available without crowding.',
    detail: 'Truth, history and safe actions live together. Editing is explicit, never accidental.',
    workspace: 'Search, filter and act without losing the working context.',
    focus: 'Quiet progress, honest feedback and no guilt mechanics.',
    settings: 'Owner controls with clear consequences and recovery before reset.',
    assistant: 'Your words stay reviewable; planner writes happen only after Apply.',
    native: 'Fast native action, queued locally and reconciled when sync returns.',
  };
  return {
    title,
    subtitle: descriptions[family],
    primary_action: primary,
    secondary_action: /error|conflict|recovery/.test(page.id) ? 'View technical details' : 'More options',
    date: 'Monday, Aug 10 · ۱۹ مرداد ۱۴۰۵',
    sync: /offline/.test(page.id) ? 'Offline · saved locally' : /retry|error/.test(page.id) ? 'Needs attention' : 'Synced',
    fixture_notice: 'Preview fixture only — never production data',
    persian_sample: 'برنامه امروزت آماده است؛ قدم بعدی روشن و قابل انجام می‌ماند.',
  };
}

function pageSpec(page, componentIds) {
  const family = familyFor(page.id);
  const routes = routeSet(page);
  const copy = liveCopy(page);
  const winner = candidateWinner(page.id);
  const motionIds = new Set(['motion-route-enter', 'motion-title-rise', 'motion-continuous-resize']);
  if (family === 'capture' || family === 'assistant') motionIds.add('motion-capture-morph');
  if (family === 'wizard') motionIds.add('motion-wizard-step');
  if (family === 'detail') motionIds.add('motion-detail-continuity');
  if (family === 'focus') motionIds.add('motion-focus-timer');
  if (family === 'native') motionIds.add('motion-widget-action');
  return {
    page_id: page.id,
    preview_version: catalogVersion,
    component_catalog_version: componentCatalogVersion,
    version: 1,
    subgroup: page.subgroup,
    family,
    family_label: familyLabels[family],
    title: copy.title,
    accent: pageAccent(page.id),
    primary_question: primaryQuestion(page),
    primary_action: copy.primary_action,
    scan_order: ['identity and page question', 'current system state', 'primary live content', 'reversible primary action', 'secondary evidence or navigation'],
    semantic_order: ['page title', 'state summary', 'primary content collection', 'primary action', 'secondary actions', 'navigation'],
    component_ids: componentIds,
    live_copy_ids: Object.keys(copy).map((key) => `copy.${page.id}.${key}`),
    live_copy: copy,
    asset_layers: [
      'live: dynamic copy, owner data, controls, status and semantics',
      'vector: Stage 04 icons/category pictograms and authored state geometry',
      'raster: exact Perfect mark/wordmark only where the identity manifest permits',
      'hybrid: live controls over authored pastel material',
    ],
    z_order: ['canvas', 'persistent navigation', 'scrolling live content', 'sticky context', 'capture or contextual floating control', 'temporary overlay', 'system receipt'],
    responsive_equations: [
      'phone: clamp(16px, 4.1vw, 24px) gutters; one scan spine; footer/capture clear final action',
      'tablet: 72px collapsed rail + bounded primary pane; add secondary pane only when its minimum readable width survives',
      'windows: remembered 72/232px rail; minmax(0, primary) + optional 320–440px inspector; 760px readable line cap',
      'short height or IME: preserve focused control and primary action; scroll body, never the action into an unreachable layer',
    ],
    pane_rules: [
      'compact owns one route and one scroll owner',
      'medium may pair context and work without duplicating actions',
      'wide may open an inspector that collapses back to a full route with selection preserved',
    ],
    scroll_owner: family === 'native' ? 'native widget collection or compact dialog body' : `${page.id}-primary-scroll-frame`,
    sticky_floating_layers: family === 'today' || family === 'capture' ? ['glass header', 'capture orb', 'icon-only footer'] : ['glass header', 'contextual action only when it does not occlude content'],
    occlusion_clearance: 'final required action and final row retain >=24px breathing room plus safe-area/footer/composer inset; no invisible spacer bar',
    states: stateSet(page.id),
    scenario_ids: canonicalVariants.map((variant) => `scn-${page.id.slice(3)}-${variant.file.replace('.png', '')}`),
    fixture_id: fixtureFor(page.id),
    fixture_boundary: 'All page names, dates, tasks, habits, counts and history are isolated preview fixtures and cannot be imported or seeded into production.',
    motion_ids: [...motionIds],
    entry_routes: routes.entry,
    exit_routes: routes.exit,
    state_continuity: ['draft', 'focus', 'selection', 'scroll', 'route intent', 'optimistic receipt'],
    candidates: candidates.map((candidate) => ({ ...candidate, path: `candidates/${candidate.file}` })),
    selected_candidate: winner,
    canonical_previews: canonicalVariants.map((variant) => `canonical/${variant.file}`),
    canonical_preview_metadata: canonicalVariants,
    preview_sha256: {},
    decision_record: 'decision.md',
    decomposition: {
      live_layers: ['all dynamic/critical copy', 'controls', 'planner values', 'validation', 'system state', 'semantic tree'],
      authored_layers: ['brand identity', 'token material', 'icon/category vectors', 'noninteractive graphic scaffolding'],
      forbidden_flattening: ['owner data', 'editable copy', 'interactive controls', 'errors', 'permissions', 'AI proposal consequences'],
      copy_protocol: 'Implement from component IDs and this manifest, then compare normalized reference/runtime/overlay/diff—not visual memory.',
    },
    acceptance: {
      modernize: `The ${winner} topology reduces navigation or interpretation cost and avoids a generic card dashboard.`,
      integrity: 'Brand, system state, component ownership, local-first truth and all consumers remain in one canonical language.',
      anatomy: 'Primary question and action own the scan path; scroll, sticky layers, reach zones and platform transformation are explicit.',
      style: 'Perfect pastel material, exact identity, live typography, optical alignment and restrained glass are applied by role.',
      critics: 'Sparse/dense, dark/high contrast, 200% mixed copy, short height, IME, offline/error and continuous resize are adversarial inputs, not afterthoughts.',
    },
    strongest_rejected_candidate: winner === 'candidate-command-ledger' ? 'candidate-split-workbench' : 'candidate-command-ledger',
    rejection_reason: winner === 'candidate-focus-spine'
      ? 'The ledger made a personal, moment-to-moment route feel administrative and pushed the primary action below evidence chrome.'
      : winner === 'candidate-split-workbench'
        ? 'The command ledger was efficient at wide width but fractured the primary question on compact and touch layouts.'
        : 'The split workbench added a second pane before this route had a second simultaneous job, wasting reach and attention.',
    residual_risks: [`Runtime visual fidelity, semantics and interaction proof remain owned by the numbered implementation stage for ${page.id}.`],
    production_boundary: 'Design-only. No Flutter/native/domain/database/auth/sync source may be generated or mutated by Stage 05.',
  };
}

function buildCatalog() {
  const gate = parseGate();
  const componentManifest = JSON.parse(fs.readFileSync(componentsManifestPath, 'utf8'));
  if (componentManifest.catalog_version !== componentCatalogVersion) {
    throw new Error(`Stage 04 component catalog mismatch: ${componentManifest.catalog_version}.`);
  }
  const componentRows = componentManifest.components;
  if (componentRows.length !== 181) throw new Error('Stage 05 requires all 181 Stage 04 components.');
  const assignments = assignComponents(gate.rows, componentRows);
  const pages = gate.rows.map((page) => pageSpec(page, assignments.get(page.id)));
  const consumed = new Set(pages.flatMap((page) => page.component_ids));
  const missing = componentRows.map((entry) => entry.component_id).filter((id) => !consumed.has(id));
  if (missing.length > 0) throw new Error(`Unconsumed Stage 04 components: ${missing.join(', ')}`);
  return { gate, componentManifest, pages };
}

module.exports = {
  projectRoot,
  documentRoot,
  gatePath,
  pageRoot,
  manifestRoot,
  comparisonRoot,
  rejectedRoot,
  componentsManifestPath,
  catalogVersion,
  componentCatalogVersion,
  generatedAt,
  canonicalVariants,
  candidates,
  familyLabels,
  parseGate,
  titleFor,
  familyFor,
  primaryQuestion,
  primaryAction,
  fixtureFor,
  stateSet,
  candidateWinner,
  pageAccent,
  liveCopy,
  buildCatalog,
};
