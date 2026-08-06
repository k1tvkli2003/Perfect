# Stage 31 — Shared view-first entity detail route

Status: pending  
Depends on: Stages 02, 07, 12–15, 25, 27–30  
Primary surfaces: Task/Habit row taps, widget/notification/deep links, desktop detail

## Mission

Replace direct-to-edit navigation with one canonical detail destination. Viewing,
acting, understanding history and choosing Edit become separate, predictable jobs.

## Mandatory preview and Copy entry gate

- Freeze `det-hero`, `det-fact-group`, `det-relations`, `det-history-timeline`,
  `det-lifecycle-actions`, `sh-desktop-inspector`, every `pg-detail-*` shell and
  stale/deleted deep-link composition.
- Preview phone full route, tablet adaptive surface and Windows inspector/full-page
  transition with zero/sparse/dense data, loading/offline/conflict and 200% text.
- Implement one semantic body/action contract and compare all entry origins against
  their canonical page; platform presentation may differ but facts/actions may not.
- Copy acceptance includes current-record resolution, no direct-to-edit routes,
  state migration across resize and exact origin scroll/focus restoration.

## Route contract

- Body tap on Task/Habit in Today, Tasks, Plan or Habits opens detail.
- Status/log control mutates without navigation; explicit contextual Edit opens editor.
- Android widget row, notification and protocol/deep link open the same detail once
  auth/local initialization resolves.
- Missing/archived/deleted entity produces a recoverable current-state page, never an
  unrelated editor or silent no-op.

## Adaptive presentation

### Phone

Full page with compact glass header, scrollable facts/history and anchored contextual
actions that remain reachable under safe area/IME.

### Tablet

Use a modal/full detail composition according to available content width/height; avoid
a narrow phone sheet stretched across landscape.

### Windows

Adjacent inspector when main workspace retains >=680dp useful width; otherwise full
detail route. Both render the same detail body/data/actions and preserve selection.

## Shared state

- Resolve current entity by owner + stable ID from controller/local store, not a stale
  row object captured at navigation time.
- Subscribe narrowly to entity, occurrence/progress and sync/conflict changes.
- Preserve selected calendar month, internal tab/section, scroll and focus across
  resize/theme/remote updates.
- Back restores exact origin route/filter/scroll/focus; Edit return refreshes current
  entity without stacking duplicate detail routes.

## Work packets

1. Add typed `showEntityDetail(id, origin)` API and route/deep-link bridge.
2. Replace every direct `_openEditor(existing:)` row/deep-link path.
3. Build shared detail scaffold/body/action slots with Task/Habit specialization.
4. Add lifecycle not-found/archive/conflict states.
5. Add route observer/focus restoration and Windows adjacent selection behavior.
6. Update context menus: Open details primary, Edit explicit secondary.

## Edge scenarios

Remote delete/archive/edit while open; local pending change; widget cold-start; auth
refresh delayed; rapid double tap; resize inspector→page→inspector; deep link twice;
200% text, RTL and keyboard back/Escape.

## Verification

Entrypoint matrix tests; no-direct-edit source/behavior assertions; current-record
subscription; route de-duplication; origin state restoration; adaptive screenshots;
semantics and keyboard traversal.

## Reject if

- Some row/notification/widget paths still jump directly into edit.
- Desktop inspector presents different facts/actions from phone detail.
- Detail holds stale copied entity after sync/edit.

## Handoff

Stages 32–35 receive shared route/body contracts. Commit/push/release with entrypoint
evidence and clean Git.
