# Perfect! — Preview-before-production gate

Status: mandatory design authority for Stages 03–50  
Applies to: Android phone/tablet, Windows compact/expanded, Android widget  
Rule: no shipped UI component may be rebuilt until its component and page previews
are complete, internally accepted, versioned and decomposed for Copy implementation

## 1. Purpose

This registry prevents coding from becoming the place where product design is
improvised. Perfect! is designed twice:

1. deliberately, as component plates and complete page compositions;
2. faithfully, as adaptive Flutter/native runtime output compared side by side with
   the frozen previews.

The preview is a working specification, not inspiration. It owns hierarchy,
geometry, assets, copy, states, responsive transformation, input behavior and motion.
Implementation may recompose at constrained viewports, but every difference must be
traceable to a documented adaptive rule rather than accidental drift.

## 2. Artifact topology and naming

Canonical artifacts live below the stage documentation root:

```text
design/
  00-evidence/
    current-runtime/
    references/
    decomposition/
    decision-ledger/
  01-foundations/
    tokens/
    typography/
    iconography/
    material/
    motion/
  02-components/
    <family>/<component-id>/
      contract.yaml
      anatomy.svg
      states-light.png
      states-dark.png
      responsive.png
      accessibility.png
      motion-board.png
      neighbor-plate.png
      assets/
  03-pages/
    <page-id>/
      composition.yaml
      candidates/
      canonical/
        phone-compact.png
        phone-landscape.png
        tablet-portrait.png
        tablet-landscape.png
        windows-compact.png
        windows-wide.png
        dark.png
        stress.png
        motion-board.png
      decision.md
  04-copy-manifests/
    components.json
    pages.json
    assets.json
    motion.json
  05-runtime-comparisons/
    <stage>/<preview-id>/<scenario-id>/
      reference.png
      runtime.png
      overlay.png
      diff.png
      mismatch.md
  rejected/
```

File IDs use stable lowercase kebab case. Canonical image metadata records logical
viewport, physical export size, device-pixel ratio, text scale, locale/direction,
theme, fixture/scenario, preview version and SHA-256. Re-exporting a canonical
preview changes its version/hash and reopens every runtime consumer of that ID.

## 3. Foundation preview registry

Every foundation receives a specimen sheet before component work:

| ID | Required preview |
| --- | --- |
| `fnd-color-roles` | every semantic background/foreground/border/status pair in light, dark and high contrast |
| `fnd-type-latin` | exact Perfect! wordmark plus all live Latin roles, weights, numerals and long-copy samples |
| `fnd-type-persian` | Persian roles, numerals, punctuation, bidi isolation and real fallback behavior |
| `fnd-spacing-density` | spacing/radius/stroke/elevation/blur/icon/hit-target ladder at phone, tablet and Windows density |
| `fnd-grid-width` | content/pane equations at every mandatory width and short-height constraint |
| `fnd-icons` | action icon family, category pictograms, custom SVG rules and small-scale optical corrections |
| `fnd-material` | canvas, solid, elevated, floating glass and non-blur/high-contrast fallbacks |
| `fnd-motion` | duration/easing/spring roles with start/mid/end/reverse/interruption/reduced-motion frames |
| `fnd-focus-a11y` | hover, focus, pressed, disabled, selected and screen-reader/keyboard semantics patterns |

## 4. Component preview registry

Every ID below gets its own contract and individual preview plate. Slash-separated
variants are distinct states on the same semantic component only when anatomy remains
stable; if anatomy changes, create a child component ID. A later source audit may add
IDs, but it may never silently remove one.

### 4.1 Identity and installed-brand components

| ID | Component and required variants |
| --- | --- |
| `id-perfect-mark` | master mark, monochrome/accessibility and 16/24/32/48/96/512 small-scale inspection |
| `id-perfect-wordmark` | selected custom typography image, light/dark/high-contrast and compact-header crops |
| `id-launcher-android` | adaptive foreground/monochrome/mask-safe variants with transparent visual field |
| `id-splash-android` | system splash scale and transition into first app frame without clipping |
| `id-icon-windows` | ICO frame ladder, taskbar, Start, Alt-Tab and installer representations |
| `id-widget-brand` | uncropped transparent mark/wordmark treatment at native widget sizes |
| `id-category-pictogram` | curated SVG optical system and semantic label behavior |

### 4.2 Shell, header and navigation components

| ID | Component and required variants |
| --- | --- |
| `sh-page-canvas` | compact/medium/expanded backgrounds, safe areas and scroll boundaries |
| `sh-glass-header` | compact page/default/detail headers, scrolled blur, solid/high-contrast fallback |
| `sh-title-cluster` | title-rise, optional subtitle/action, long bilingual/200% transformation |
| `sh-dual-date-clock` | local time plus Gregorian/Jalali compact/expanded/midnight-boundary variants |
| `sh-sync-cloud` | synced green, syncing/retrying yellow, error red, offline/detail/reduced-motion variants |
| `sh-phone-footer` | icon-only floating dock, all destination states, keyboard/semantics labels and occlusion clearance |
| `sh-footer-destination` | idle/hover/focus/pressed/selected/disabled with no redundant check mark |
| `sh-tablet-rail` | compact default/expanded/tooltip/selection/short-landscape variants |
| `sh-windows-rail` | remembered compact/expanded, resize transition, hover/focus/context behavior |
| `sh-rail-toggle` | compact control with discoverable tooltip and keyboard state |
| `sh-page-scroll-frame` | header/footer/composer clearance, short-height and IME behavior |
| `sh-desktop-inspector` | empty/selected/detail/loading/error and compact-to-route fallback |
| `sh-pane-divider` | resize/hover/focus/drag/min-max behavior |
| `sh-system-overlay-anchor` | menu/dialog/sheet/popover/toast safe anchor zones |

### 4.3 Common action and input components

| ID | Component and required variants |
| --- | --- |
| `ct-button-primary` | default/hover/focus/pressed/loading/disabled/success and long-copy wrap |
| `ct-button-secondary` | same interaction/state matrix |
| `ct-button-ghost` | same interaction/state matrix on plain/glass surfaces |
| `ct-button-danger` | guarded/destructive/confirming/busy/disabled states |
| `ct-icon-button` | familiar actions, tooltip, selected and dangerous variants |
| `ct-split-action` | primary plus disclosure; narrow-stack and keyboard behavior |
| `ct-text-field` | idle/hover/focus/filled/error/disabled/read-only/IME and 200% variants |
| `ct-search-field` | empty/query/results/no-results/loading/clear/shortcut variants |
| `ct-note-field` | multiline, expanding, scroll, limit/error and mixed-direction variants |
| `ct-password-field` | concealed/reveal/error/autofill/password-manager variants |
| `ct-voice-field` | permission/idle/listening/processing/transcript/error/cancel states |
| `ct-chip-filter` | idle/hover/focus/pressed/selected/removable/count/disabled variants |
| `ct-segmented-view` | 2–4 choices, compact wrap/scroll, selection motion and keyboard behavior |
| `ct-checkbox` | unchecked/checked/indeterminate/error/disabled |
| `ct-radio` | unselected/selected/focus/disabled without redundant external check mark |
| `ct-toggle` | off/on/focus/disabled/loading and semantic copy placement |
| `ct-slider` | value/range/keyboard/touch/error/read-only variants |
| `ct-count-stepper` | minus/value/plus, rapid input, limit, disabled and correction states |
| `ct-value-stepper` | unit-aware numeric/decimal/negative/bounds variants |
| `ct-time-duration-stepper` | minute/hour presets, custom entry and rollover behavior |
| `ct-date-picker` | Gregorian/Jalali display, selected/today/range/disabled/month-edge variants |
| `ct-time-picker` | 12/24-hour, keyboard/touch, timezone and validation variants |
| `ct-calendar` | month/week cells, events, selected/today/outside/disabled and dense states |
| `ct-menu` | touch/desktop context, nested/destructive/disabled/shortcut variants |
| `ct-tooltip` | pointer/keyboard, edge flip, delay, long label and high contrast |
| `ct-toast-undo` | success/error/offline/pending with action, timer and screen-reader announcement |
| `ct-progress` | determinate/indeterminate/sync/retry/reduced-motion variants |
| `ct-skeleton` | row/page/detail shapes with stable final geometry and reduced motion |

### 4.4 Selectors and customizable metadata components

| ID | Component and required variants |
| --- | --- |
| `sel-category-tile` | 30+ curated categories, custom, selected, search match and disabled |
| `sel-category-picker` | search/recent/all/custom-create/edit/archive and narrow/wide compositions |
| `sel-icon-library` | grouped SVG archive, search, empty, selected, custom preview and semantics |
| `sel-color-swatch` | pastel palette, custom color, contrast warning and theme preview |
| `sel-project-area-goal` | relation selector, create-inline, missing/archived and multi-select variants |
| `sel-tag-context` | add/remove/search/create/duplicate behavior |
| `sel-priority-energy` | semantic labels and color-independent selected states |
| `sel-repeat-summary` | human-readable recurrence preview and invalid/conflict states |
| `sel-reminder-summary` | permission, schedule, quiet-hours conflict and timezone variants |

### 4.5 Overlays, feedback and system-state components

| ID | Component and required variants |
| --- | --- |
| `ov-dialog` | compact/wide, keyboard, destructive, loading and scroll variants |
| `ov-bottom-sheet` | peek/expanded/IME/drag-dismiss/reduced-motion variants |
| `ov-popover` | anchored, edge-flipped, compact and keyboard variants |
| `ov-full-route` | phone form/detail fallback and predictive-back behavior |
| `ov-wizard-chrome` | header/progress/body/footer, validation, draft save and short-height variants |
| `st-empty` | useful first-action state with no demo entities |
| `st-local-loading` | local-store initialization without fake content |
| `st-local-ready-syncing` | usable content plus bounded background progress |
| `st-offline` | usable local content, queue count and non-blocking explanation |
| `st-retrying` | bounded retry detail and manual retry where useful |
| `st-error-recoverable` | actionable retry/diagnostics without destructive reset |
| `st-error-hard` | safe fallback, support evidence and preserved data statement |
| `st-conflict` | concise surface cue and explicit conflict-center route |
| `st-destructive-confirm` | named target/consequence, cancel priority and irreversible copy |

### 4.6 Task and Today components

| ID | Component and required variants |
| --- | --- |
| `td-pulse` | time/date/progress/next-boundary/Plan action, empty through dense, phone/wide |
| `td-zone-heading` | next/later/flexible/habits/completed headings and continuation behavior |
| `td-stream-timeline` | time rail, now marker, zone transitions and dense overlap handling |
| `td-next-emphasis` | first actionable row emphasis without duplicate next-task card |
| `td-continuation-cue` | scroll continuation, final state and accessibility behavior |
| `task-row` | one-off/recurring, scheduled/unscheduled/overdue/completed, metadata/checklist variants |
| `task-status-control` | Pending/Partial/Done/Missed/empty multi-tap cycle with stable outer geometry |
| `task-partial-ring` | arc-only visual progress, semantics value, no cramped center percentage |
| `task-time-rail` | exact/all-day/window/unscheduled/overdue and compact-stack variants |
| `task-meta-line` | category/project/context/estimate/repeat/reminder priority rules |
| `task-subtasks-summary` | none/partial/all, expand/collapse and narrow behavior |
| `task-row-actions` | details/quick reschedule/archive/context; touch/desktop discoverability |
| `task-inline-receipt` | optimistic pending/saved/Undo/retry/conflict feedback |

### 4.7 Habit components

| ID | Component and required variants |
| --- | --- |
| `habit-row` | build/maintain/quit, due/not-due/risk/completed/missed/paused variants |
| `habit-control-check` | boolean log/undo/correction/queued states |
| `habit-control-count` | rapid +1, decrement, target/over-target and serialized pending states |
| `habit-control-duration` | quick presets, running/manual correction and target states |
| `habit-control-numeric` | unit-aware add/set/correct and bounds states |
| `habit-control-checklist` | step count, remaining action, expand and completion states |
| `habit-control-formula` | derived inputs, valid/invalid/explanation and correction states |
| `habit-day-state` | pending/partial/completed/missed/skipped/not-applicable visual language |
| `habit-week-strip` | today/selected/logged/missed/not-due and month-edge behavior |
| `habit-streak-receipt` | current/best/milestone/risk/recovery with non-guilt copy |
| `habit-recovery-preview` | Miss/Pending/Carry/next-valid/prompt and carry-cap consequences |
| `habit-metric-strip` | target/actual/trend/consistency with honest sparse-data behavior |

### 4.8 Capture, AI and voice components

| ID | Component and required variants |
| --- | --- |
| `cap-orb` | collapsed floating control, subtle heartbeat, hover/focus/press/reduced motion |
| `cap-expanded-shell` | no background strip, closed/open/closing/resize/interruption variants |
| `cap-task-mode` | centered inactive field, focused IME, parsing, saving, success/error/draft |
| `cap-plan-mode` | same shell morphed to date/time/duration/quick-block controls |
| `cap-mode-actions` | Task/Plan/AI/Voice icon actions with clear selected state and semantics |
| `cap-send-action` | disabled/ready/sending/saved/error without geometry jump |
| `ai-shell` | same morphing instrument expanded to conversation; phone/tablet/Windows |
| `ai-context-strip` | selected date/entities/constraints, removable and overflow variants |
| `ai-starter-path` | plan/habit/rebalance paths with distinct modern AI pictogram |
| `ai-message` | owner/assistant/system, long/mixed copy, streaming and failure variants |
| `ai-thinking` | bounded progress and reduced-motion alternative |
| `ai-proposal` | create/update/conflict/multi-action human-readable diff |
| `ai-proposal-action` | review/apply/edit/reject/busy/success/partial-failure/Undo states |
| `ai-history-banner` | restored/truncated/offline/unavailable context states |
| `ai-error-ribbon` | timeout/rate limit/auth/provider/malformed/refusal and retry copy |
| `voice-recorder` | permission/idle/listening/paused/processing/transcribed/cancel/error |

### 4.9 Wizard and editor components

| ID | Component and required variants |
| --- | --- |
| `wiz-progress` | meaningful named steps, completed/current/upcoming/error and narrow behavior |
| `wiz-type-choice` | creation-only Task/Recurring/Habit choice; absent in immutable edit paths |
| `wiz-identity-step` | title/category/icon/color/project/area/tags, validation and long-copy states |
| `wiz-definition-step` | task outcome/checklist/notes or habit target/tracking method |
| `wiz-schedule-step` | date/time/window/all-day/duration/timezone and conflict preview |
| `wiz-recurrence-step` | interval/weekdays/monthly/custom/end/exception/human summary |
| `wiz-recovery-step` | per-entity Miss/Pending/Carry/next-valid/prompt and carry cap |
| `wiz-reminder-step` | reminder offsets, permission, quiet hours and failure states |
| `wiz-review-step` | concise complete summary, warnings, consequences and edit jump-backs |
| `wiz-footer` | back/continue/save, validation, busy, IME and short-height behavior |
| `wiz-discard-draft` | continue editing/save draft/discard with exact consequence |

### 4.10 Detail, analytics and lifecycle components

| ID | Component and required variants |
| --- | --- |
| `det-hero` | entity identity/status/next action/edit; task/habit/goal/project/note variants |
| `det-fact-group` | adaptive label/value grid, missing values and 200% stack |
| `det-relations` | project/goal/area/note/task/habit links, empty/add and archived states |
| `det-history-timeline` | status/log/edit/sync/correction events with immutable chronology |
| `det-month-calendar` | occurrence/log/progress/selected-day and mixed dense history |
| `det-habit-heatmap` | honest scale, no-data and accessible values |
| `det-chart` | trend/target/range/tooltip/no-data and theme/high-contrast variants |
| `det-insight` | evidence/source/confidence/action, insufficient-data and dismiss states |
| `det-lifecycle-actions` | edit/duplicate/pause/archive/restore/delete with guarded hierarchy |
| `det-focus-link` | start/focus history/session summary and interruption states |

### 4.11 Workspace, planning, goals and focus components

| ID | Component and required variants |
| --- | --- |
| `ws-query-bar` | search plus compact filter/sort affordances; result/no-result states |
| `ws-filter-deck` | task/habit/plan filters, applied count, reset and narrow/wide behavior |
| `ws-group-header` | count/collapse/bulk select and sticky behavior |
| `ws-saved-view` | default/custom/rename/delete/invalid filter states |
| `ws-bulk-bar` | selection count, safe actions, cancel and narrow overflow behavior |
| `plan-week-strip` | selected/today/due-density and dual-date behavior |
| `plan-day-column` | time grid, now line, blocks, overlap and short-height scrolling |
| `plan-week-grid` | multi-day layout, current day, overlap, keyboard and drag states |
| `plan-month-cell` | day labels, event density, overflow cue and mixed-calendar context |
| `plan-time-block` | task/focus/free/overlap/drag/resize/conflict/locked states |
| `plan-unscheduled-tray` | collapsed/expanded/drag source/empty/dense variants |
| `goal-outcome-card` | horizon/measure/progress/checkpoint/at-risk and empty states |
| `goal-horizon-strip` | week/month/quarter/year selected, review and forecast states |
| `project-area-card` | status, linked work, health and archived states |
| `review-checkpoint` | planned/done/carried/learned/adjust-next without guilt framing |
| `focus-setup` | Pomodoro/custom/entity link/flip option/notification policy |
| `focus-timer` | run/pause/background/interrupted/completed/recovered and reduced motion |
| `focus-reflection` | energy/result/note/next action with skip and keyboard behavior |
| `game-streak` | current/best/freeze/recovery with derived-state provenance |
| `game-achievement` | locked/progress/unlocked/seen and non-manipulative celebration |
| `game-reward-receipt` | source/value/level change/Undo-safe derived behavior |

### 4.12 Settings, diagnostics, feedback and recovery components

| ID | Component and required variants |
| --- | --- |
| `set-section` | title/description/grouping, compact/wide and 200% behavior |
| `set-row` | value/toggle/navigation/warning/disabled/managed states |
| `set-theme-preview` | system/light/dark/high contrast/reduced motion selections |
| `set-reminder-window` | permission, quiet hours, timezone and invalid overlap states |
| `set-widget-preview` | size/content/privacy/action configuration and live preview |
| `set-profile-session` | owner identity/session/device state and safe sign-out route |
| `diag-status-card` | local DB/outbox/sync/auth/widget/AI health and actionable detail |
| `diag-log-viewer` | search/filter/redaction/copy/export/empty/error variants |
| `fb-launcher` | unobtrusive edge/floating control, hover/focus and collision avoidance |
| `fb-menu` | screenshot+note/note-only/entries actions |
| `fb-draft` | kind/note/screenshot/redaction/consent/saving/error states |
| `fb-screenshot-preview` | crop/annotation/redaction/remove and unavailable states |
| `fb-entry-row` | error/suggestion/criticism/note, attachment/export states |
| `fb-entry-detail` | metadata/log/screenshot/note/export/delete/recovery states |
| `data-backup-summary` | version/count/hash/destination/success/error variants |
| `data-import-dry-run` | new/update/duplicate/invalid/conflict and confirm/cancel states |
| `data-recovery` | inspect/repair/retry/export-first/reset-last-resort hierarchy |
| `update-status` | available/downloading/ready/installing/current/error/retry variants |

### 4.13 Native Android widget components

| ID | Component and required variants |
| --- | --- |
| `wg-header` | transparent identity, date, sync state and app-open action |
| `wg-empty` | no data and direct Quick Add without demo tasks |
| `wg-task-row` | compact title/time/status cycle/pending/offline/error variants |
| `wg-habit-row` | method-aware increment/log/correction/deep-link variants |
| `wg-scroll-list` | dense list, clipped-height continuation and final-row reachability |
| `wg-quick-add` | compact native dialog, field/date/time/save/error/offline states |
| `wg-resize-cue` | compact/medium/tall/wide/large transformations without stale bounds |
| `wg-action-receipt` | queued/saved/retry/failed state without blocking further actions |

## 5. Full-page composition registry

Every row requires canonical composed previews for all applicable layout classes and
the risk-based state matrix in Section 6. Related modes may share one route but still
receive separate composition IDs because hierarchy or anatomy changes.

### 5.1 Entry and shell

`pg-bootstrap`, `pg-splash-transition`, `pg-configuration`, `pg-sign-in`,
`pg-password-update`, `pg-session-expired`, `pg-bootstrap-recovery`,
`pg-shell-phone`, `pg-shell-short-landscape`, `pg-shell-tablet-collapsed`,
`pg-shell-tablet-expanded`, `pg-shell-windows-compact`,
`pg-shell-windows-intermediate`, `pg-shell-windows-wide`.

### 5.2 Today and capture

`pg-today-empty`, `pg-today-sparse`, `pg-today-normal`, `pg-today-dense`,
`pg-today-offline`, `pg-today-retry-error`, `pg-today-conflict`,
`pg-capture-collapsed`, `pg-capture-task`, `pg-capture-plan`, `pg-capture-ai`,
`pg-capture-voice`, `pg-capture-proposal-review`, `pg-capture-ime`,
`pg-capture-interrupted-resize`.

### 5.3 Creation and editing

`pg-create-choice`, `pg-task-identity`, `pg-task-definition`, `pg-task-schedule`,
`pg-task-recurrence`, `pg-task-recovery`, `pg-task-reminder`, `pg-task-review`,
`pg-habit-identity`, `pg-habit-tracking`, `pg-habit-target`,
`pg-habit-multiple-daily`, `pg-habit-schedule`, `pg-habit-recovery`,
`pg-habit-reminder`, `pg-habit-review`, `pg-edit-task`, `pg-edit-recurring-task`,
`pg-edit-habit`, `pg-editor-validation`, `pg-editor-discard-draft`.

### 5.4 View-first details

`pg-detail-task`, `pg-detail-recurring-task`, `pg-detail-habit`,
`pg-detail-habit-history`, `pg-detail-habit-analytics`, `pg-detail-goal`,
`pg-detail-project`, `pg-detail-area`, `pg-detail-note`, `pg-detail-focus-session`,
`pg-detail-lifecycle-confirm`, `pg-detail-desktop-inspector`.

### 5.5 Workspaces and planning horizons

`pg-tasks-default`, `pg-tasks-search`, `pg-tasks-filtered`, `pg-tasks-dense`,
`pg-tasks-bulk`, `pg-plan-day`, `pg-plan-week`, `pg-plan-month`,
`pg-plan-unscheduled`, `pg-plan-overlap-conflict`, `pg-plan-drag-resize`,
`pg-habits-today`, `pg-habits-insights`, `pg-habits-build-maintain-quit`,
`pg-habits-dense`, `pg-goals`, `pg-projects`, `pg-areas`, `pg-notes`,
`pg-horizon-week`, `pg-horizon-month`, `pg-horizon-quarter`, `pg-horizon-year`,
`pg-review-week`, `pg-review-month`.

### 5.6 Focus and gamification

`pg-focus-setup`, `pg-focus-running`, `pg-focus-paused-background`,
`pg-focus-complete-reflection`, `pg-focus-history`, `pg-achievements`,
`pg-streak-recovery`, `pg-reward-receipt`.

### 5.7 More, settings and recovery

`pg-more`, `pg-profile-session`, `pg-settings-appearance`,
`pg-settings-reminders`, `pg-settings-widget`, `pg-settings-ai`,
`pg-settings-data`, `pg-archive-trash`, `pg-conflict-center`, `pg-insights-review`,
`pg-diagnostics`, `pg-backup-export`, `pg-import-dry-run`, `pg-data-recovery`,
`pg-update-status`.

### 5.8 Feedback and AI

`pg-feedback-launcher`, `pg-feedback-menu`, `pg-feedback-screenshot-draft`,
`pg-feedback-note-draft`, `pg-feedback-entries`, `pg-feedback-entry-detail`,
`pg-feedback-export`, `pg-ai-empty`, `pg-ai-conversation`, `pg-ai-listening`,
`pg-ai-proposal`, `pg-ai-conflict`, `pg-ai-error-offline`.

### 5.9 Widget and external entry

`pg-widget-compact`, `pg-widget-medium`, `pg-widget-tall`, `pg-widget-wide`,
`pg-widget-large`, `pg-widget-empty`, `pg-widget-quick-add`,
`pg-widget-offline-action`, `pg-notification-open`, `pg-stale-deep-link`,
`pg-windows-protocol-open`.

## 6. Coverage matrix

Not every cross-product needs a redundant image, but every risk must be represented.
The registry records the exact scenario set selected for each ID.

| Axis | Mandatory values |
| --- | --- |
| Geometry | 320x700, 360x800, 390x844; short phone landscape; 600 split; 800 tablet portrait; 900 tablet landscape; 720x540, 1024x640, 1366x768, 1600+; continuous resize transition frames |
| Density | empty, one item, normal, dense, long multi-year history where applicable |
| Text | short, long, English, Persian, mixed RTL/LTR, 100%, 200%, missing-font fallback |
| Theme | light, dark, high contrast; blur available/unavailable |
| Input | touch, long press, mouse hover/press, keyboard/focus, shortcut, IME, outside dismissal |
| Motion | initial, mid, final, reverse, interrupted, background/resume, reduced/no motion |
| Connectivity | online/current, offline start, loss mid-write, syncing, retry, server error, conflict |
| Auth | valid, refresh, expired, revoked, cached offline session, post-upgrade restore |
| Lifecycle | create, view, log/progress, edit, Undo, archive, restore, delete, recover |
| Origin | app, Android widget, notification, AI proposal, remote device, imported backup |

Minimum visual set for a standard page is phone compact light/normal, phone compact
dark/dense, short landscape stress, tablet portrait, tablet landscape, Windows
compact, Windows wide, 200% mixed-direction stress, system-state sheet and motion
board. High-risk pages add every relevant scenario; low-risk duplicates may reference
a proven shared component contract but cannot omit page-level composition proof.

## 7. Component contract schema

```yaml
component_id: stable-id
version: 1
purpose: user problem solved
anatomy:
  slots: []
  alignment_axes: []
  stable_outer_geometry: true
semantic_owner: source-of-truth concept
inputs: []
outputs: []
mutation_contract: none-or-operation-id
states:
  precedence: []
responsive:
  phone: rule
  tablet: rule
  windows: rule
  short_height: rule
interaction:
  touch: []
  mouse: []
  keyboard: []
  screen_reader: []
rtl_mixed_copy: rule
tokens: []
assets: []
motion_ids: []
reduced_motion: rule
performance_budget: budget
consumers: []
preview_files: []
preview_sha256: []
intentional_variants: []
```

## 8. Page composition schema

```yaml
page_id: stable-id
version: 1
primary_question: what the owner needs answered immediately
primary_action: exact action and placement priority
scan_order: []
semantic_order: []
component_ids: []
live_copy_ids: []
asset_layers: []
responsive_equations: []
pane_rules: []
scroll_owner: id
sticky_floating_layers: []
occlusion_clearance: rule
states: []
scenario_ids: []
motion_ids: []
entry_routes: []
exit_routes: []
state_continuity: [draft, focus, selection, scroll]
canonical_previews: []
preview_sha256: []
decision_record: path
residual_risks: []
```

## 9. Asset and graphic-craft manifest

Every visible layer is classified as:

- `live`: dynamic text/control/data with semantics;
- `vector`: project-owned SVG/CustomPainter path whose exact geometry is versioned;
- `raster`: PNG/WebP art with master/export/crop/density/theme provenance;
- `hybrid`: live semantic control over authored vector/raster material;
- `build-time`: launcher/splash/ICO/widget asset generated reproducibly.

The manifest records `asset_id`, source/master, license/ownership, export tool,
dimensions/viewBox, transparent bounds, safe zone, optical center, anchor/crop,
theme/density/platform variants, compression, memory budget, semantic equivalent,
consumers and SHA-256. Graphic work that materially defines the preview—brand art,
complex rings/charts, layered material, illustrations or special iconography—must be
built through an appropriate professional vector/raster/hybrid workflow. A plain
circle, gradient or stock icon is not an acceptable substitute.

## 10. Motion storyboard registry

Every motion ID records trigger, spatial intent, duration/easing/spring, affected
layers, first/mid/end frames, interruption/reverse behavior, focus/semantics timing,
background/resume behavior, reduced/no-motion replacement and frame/resource budget.
Mandatory families: route enter/exit, title rise, header scroll response, footer/rail
selection, rail collapse, Capture/Plan/AI/Voice morph, IME transition, dialog/sheet/
popover, selector, task state, habit increment/completion, sync transition, optimistic
receipt, detail/inspector, wizard step, drag/reschedule, focus timer, restrained reward,
widget action and continuous resize.

## 11. Autonomous acceptance record

Each canonical candidate receives:

```text
preview_id / version / hash:
problem statement:
candidates compared:
Modernize verdict:
Integrity verdict:
Anatomy verdict:
Style verdict:
Critics defects found and corrected:
chosen candidate and evidence:
strongest rejected candidate and why it lost:
responsive/a11y/system-state proof:
remaining risk and owning stage:
accepted under owner-delegated autonomous design authority: yes/no
```

Acceptance is invalid if any verdict is blank, if the rationale is taste-only, or if
the preview depends on data not available in the real product.

## 12. Copy implementation and comparison protocol

For every runtime consumer:

1. Freeze `preview_id@version#hash`, scenario and consumer list.
2. Decompose live text, controls, semantic structure, vectors/rasters, geometry,
   responsive equations, z-order and motion; never copy a flattened screenshot.
3. Implement the smallest coherent shared component/system, then wire all consumers.
4. Render the exact deterministic fixture in real Android and/or Windows runtime.
5. Normalize reference/runtime to the same logical viewport, DPR, text scale, crop,
   locale, direction and theme.
6. Produce `reference`, `runtime`, 50% overlay and perceptual diff.
7. Log each mismatch with severity:
   - P0: wrong route/data/security/hidden only action;
   - P1: broken hierarchy, overlap, unreachable control, wrong state/asset/motion;
   - P2: meaningful geometry/type/material/spacing drift;
   - P3: optical/pixel polish.
8. Correct P0→P3, rerender and retain before/after comparison evidence.
9. Declare an intentional difference only when platform/content/accessibility
   constraints require it; document the adaptive rule and compare the reflow itself.
10. Recheck every listed consumer and update the whole-product coverage ledger.

## 13. Gate completion checklist

The gate passes only when:

- the current source/route audit has no visible surface missing from the registries;
- every component ID has anatomy, states, responsive, accessibility, motion and
  neighbor plates plus a complete contract;
- every page ID has structurally compared candidates, a canonical composition,
  state/layout coverage, decision record and decomposition manifest;
- canonical previews contain exact live-copy source text or clearly marked semantic
  stand-ins; generated gibberish is never accepted;
- all assets have provenance, export path, theme/density variants and small-scale
  inspection; no raw keyboard emoji or generic placeholder remains;
- the normalized comparison pipeline successfully detects an injected geometry,
  typography and state defect;
- fixtures are provably unreachable from production;
- the coverage ledger classifies every consumer;
- registry versions/hashes are committed and pushed with a clean main-only branch;
- no production binary release is fabricated for a design-only byte-identical stage.

## 14. Permanent rejection conditions

Reject or reopen this gate when any later stage:

- begins UI implementation from prose alone or from a remembered screenshot;
- accepts “same vibe,” no-overflow or compilation as visual fidelity;
- checks a component only in isolation and misses sibling/page composition;
- tests only phone/light/default or ignores height, IME, resize, RTL/mixed text, 200%,
  dark/high contrast, reduced motion, offline/error or input parity;
- flattens dynamic controls/copy into inaccessible images;
- substitutes a generic primitive for required authored graphics;
- silently changes a canonical preview without version/hash propagation;
- asks the owner to choose an ordinary design detail already delegated to this
  autonomous evidence gate.
