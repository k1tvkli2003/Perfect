# Stage 36 — Tasks workspace reconstruction

Status: pending  
Depends on: accepted Stages 03–05 preview/copy contract; Stages 07, 13, 17,
22–25, 31–35  
Primary surfaces: Tasks workspace, task search/filter/sort/grouping, saved views,
selection and bulk actions

## Mission

Turn Tasks into the owner's fast, trustworthy control room for all one-off and
recurring work. The workspace must answer “what set am I looking at, why is each
item here, and what can I safely do next?” without becoming a permanent wall of
filters. It reuses the canonical row, detail and lifecycle contracts; it does not
create a Tasks-only model or route.

## Failure statement and autonomous decisions

The current implementation filters an in-memory controller list inside the widget,
supports only four statuses and two kinds, has no sort/group/saved-view contract,
and cannot scale to dense data or desktop selection. Replace that path completely.

- First launch opens the built-in `Open` view. The owner may pin another default;
  current view, query and selection are never inferred from the last entity opened.
- Built-in views are immutable: Inbox, Open, Scheduled, Recurring, Completed and
  Archive. A personal saved view is a named query definition, not a duplicated list.
- Saved-view definitions sync between the owner's devices; the active view, filter
  deck disclosure and list/inspector scroll remain device-local so phone use cannot
  unexpectedly rearrange Windows.
- Search, filter, sort and grouping compose as one typed query. No widget may apply a
  second hidden predicate after the repository returns results.
- Default ordering is actionable first, then scheduled instant, then manual order,
  then stable ID. User-selected sorts always declare their tie-breakers.
- Row-body tap opens Stage 31 detail. Status, context menu and selection targets stay
  disjoint. No task opens directly in Edit.
- Desktop bulk selection is first-class. Android also supports deliberate long-press
  selection, but ordinary one-handed status changes remain one tap.

## Preview and Copy fidelity gate — before any runtime edit

No Dart, database, Supabase, Android, Windows or test-runtime edit starts until the
internally accepted Stage 03–05 Perfect! direction is materially available and this
stage's complete preview set has a recorded autonomous acceptance decision. If the
preview, decision record or generation is missing, stop at preview/spec work and
record the blocker.

1. Use Modernize in **Recompose** mode: generate at least 24 product-grounded Tasks
   workspace recipes, shortlist 6–8 and render 2–4 high-fidelity final directions.
   Preserve the Day Compass system, dense scanning, detail continuity and capture;
   reject generic card grids, stock filter dashboards and copied reference layouts.
2. Apply Integrity's five-way opinion ledger to crown, saved views, search, Refine,
   tokens, grouping, task row, selection, bulk review/actions, empty/loading/offline/
   conflict, inspector, composer adjacency, widget/notification and lifecycle states.
3. Produce an **individual component preview plate for every component**: crown and
   New action; saved-view selector/tab/editor; search; Refine trigger/panel; constraint
   token; sort/group control; group header; canonical task row in every task/progress/
   sync state; selection control; bulk action surface and consequence preview; result/
   Undo receipt; empty/no-result/loading/offline/error/conflict; and inspector handoff.
   Each plate covers default, hover, focus, pressed, selected, disabled, busy, success,
   warning/error, light/dark/high contrast, RTL/mixed text and reduced motion, and
   records bounds, alignment, tokens, 48dp target, semantics and live/SVG/asset route.
4. Produce accepted full-page references for Inbox/Open/Scheduled/Recurring/Completed/
   Archive and a personal saved view at phone portrait, short phone landscape, tablet
   portrait/landscape with both rail states, and 720x540, 1024x640, 1366x768, 1600+
   Windows. Include zero/one/dense/5,000-task, long mixed copy, 200% text, Refine open,
   selection/bulk preview, inspector, optimistic/Undo, offline/retry/conflict/error and
   light/dark/high-contrast/reduced-motion states.
5. Build the Anatomy route/task map, compare at least two IA compositions, and create
   the preview-to-production decomposition manifest: every layer, frame/occupancy and
   alignment decision, compact/medium/expanded transform, asset path/provenance,
   crop/z-order, live data/semantics, focus behavior and performance budget. Real task
   text, controls and lists remain live; never ship a flattened workspace screenshot.
6. Record internal acceptance under the owner-delegated autonomous design authority.
   Implement with Copy fidelity component by component: visible
   inventory → accepted exact viewport/state → runtime capture → normalized side-by-
   side/diff → macro-to-micro repairs. Repeat for responsive siblings and close the
   mismatch, precision, occupancy and opinion ledgers before runtime acceptance.

## Detailed work packets

1. Freeze sparse, one-item, dense, long-copy, mixed-script and 5,000-task before
   states. Inventory every existing Tasks entrypoint, filter, context action, scroll
   key, inspector state and direct editor route.
2. Introduce immutable `PlannerTaskQuery` and `PlannerTaskQueryResult` contracts.
   Move filtering, normalized search, sorting, grouping and counts behind a
   repository/controller query API with cancellation and revision tokens.
3. Add built-in view registry and owner-scoped `PlannerSavedView` definitions. Give
   every definition a stable ID, schema version, title, icon key, query, created/
   updated time and optional default rank. Reject unknown fields conservatively while
   preserving forward-compatible JSON during older-client round trips.
4. Add local persistence and additive Supabase sync for saved-view definitions;
   migrate the current `_TaskFilter` choice into a device preference only once. Do
   not reset planner/auth data, and let Stage 41 adopt—not reinvent—the contract.
5. Build one task workspace projection that returns rows plus facet counts. Index
   normalized title, note, label, category, project and area text transactionally;
   never scan or lowercase the full entity collection in `build()`.
6. Replace the current filter deck with the exact adaptive composition below using
   Stage 04 selector primitives. Keep personal-view rename/duplicate/delete actions
   separate from task lifecycle actions.
7. Implement stable grouping with accessible headings and collapse state: None,
   Schedule, Project, Area, Category, Priority and Status. Empty groups are omitted;
   an “Unassigned” group is explicit rather than an empty string.
8. Add pointer/keyboard/touch selection. Implement Select all results, Select visible
   group, Clear, and range selection against stable result IDs—not list indices.
9. Add preview-first bulk Move, Schedule, Complete/Reopen, Archive and Delete flows.
   Re-fetch each owner-scoped entity and revision, show eligible/skipped counts, emit
   one idempotency key per entity plus a batch receipt, and provide Undo where safe.
10. Preserve query, selected saved view, expanded groups, selection, scroll anchor,
    focused row and inspector entity through detail round trips, remote inserts and
    responsive breakpoint changes. Clear only now-ineligible selected IDs with an
    announced summary.
11. Remove the obsolete widget-local filtering code and any duplicated Tasks row,
    status or context menu implementation. Route all writes through the existing
    local-first controller/operation queue.

## Exact UI composition

The workspace is one instrument with three vertically adjacent layers, not a title,
generic filter card and unrelated list.

1. **Workspace crown:** compact title, current result count and whole `New task`
   action. On wide layouts, saved-view tabs occupy the remaining line; on compact
   layouts the current view is a 48dp selector directly below the title.
2. **Task lens:** a visually quiet search field shares a continuous surface with a
   `Refine` control and current sort/group summary. Active non-default constraints
   appear as removable semantic tokens on a second wrapping line. `Clear` is shown
   only when it changes something. Search results announce count after a short
   debounce but never steal focus.
3. **Work field:** sticky group headers, canonical Stage 13 rows and Stage 35 adjacent
   inspector where useful width permits. Density is compact but every independent
   control retains at least 48dp touch geometry. The final row remains reachable
   above the floating composer.

The Refine surface contains sections in this order: status/lifecycle, kind, schedule,
project/area/category, labels, priority/energy, then sort/group. It shows an exact
human-readable query summary before `Apply`. On phone it is a scroll-controlled
bottom sheet; tablet uses an anchored side sheet when it does not cover the list;
Windows uses an anchored dismissible panel. Changes preview counts without mutating
the saved definition until explicit `Save changes`.

Selection replaces the crown actions with `n selected`, Close and the two most common
eligible bulk actions. Lower-frequency actions live in a labeled More menu. It does
not append a full-width action bar to the bottom or cover the composer/list.

## Interaction and motion behavior

- `/` or `Ctrl+F` focuses search on Windows; `Esc` clears search first, closes Refine
  second, exits selection third, closes inspector fourth, then defers to navigation.
- `Ctrl+A` selects the current result set only when focus is in the work field;
  `Shift+Arrow` extends the stable range and `Space` toggles the focused row.
- Long press enters Android selection. A normal row tap opens detail; a status-control
  tap mutates only status; secondary click opens the context menu at the pointer.
- View changes use a restrained selector glide and list crossfade while preserving
  shared rows. Group expand/collapse animates size without rerunning page entrance.
- Search/filter results update after cancellable debounce. The old result remains
  visible with a small busy affordance until the newest revision arrives; stale
  responses are discarded.
- Optimistic task/bulk changes keep affected rows in place until receipt. Movement to
  another group happens after a short confirmation window and exposes Undo; reduced
  motion substitutes an immediate state/announcement with no spatial transition.

## Responsive behavior

### Android phone

Use a single readable list. Saved-view selector, search and collapsed Refine summary
wrap intrinsically; no horizontal chip scroller hides constraints. The filter sheet
can reach above the IME, preserves the search draft and keeps Apply/Reset reachable.
At 320dp and 200% text, crown actions recompose into two rows and primary labels stay
whole. Short landscape may use denser rows but not two cramped panes.

### Android tablet

Portrait keeps one list plus modal detail. At useful landscape width, list and Stage
35 inspector are adjacent. Refine becomes an anchored 300–360dp pane only if the list
retains readable width; otherwise it is modal. Compact rail is the default and its
transition cannot reset query, selection or scroll.

### Windows compact and expanded

At 720x540 use the phone information order with native keyboard/pointer behavior. At
intermediate width, saved views and lens share the crown without forcing an inspector.
At expanded width, use a bounded list column plus inspector; the list receives enough
width for title, meaningful metadata and actions before the inspector appears. The
owner's collapsed/expanded navigation rail choice and Tasks pane fractions persist.

## Data and domain contracts

`PlannerTaskQuery` is versioned and contains: lifecycle set, task-kind set, scheduling
relation (`inbox`, `dated`, `overdue`, bounded range), relation IDs, category IDs,
labels, priority/energy, normalized text query, sort clauses, group clause and
include-archived flag. Unknown or deleted referenced IDs yield a visible unavailable
constraint and repair action; they never broaden the query silently.

`PlannerSavedView` is owner-scoped and has `id`, `schemaVersion`, `title`, `iconKey`,
`query`, `createdAt`, `updatedAt`, `revision` and soft-delete metadata. Title is not
identity. Built-in IDs use a reserved namespace and cannot be overwritten remotely.
The active-view preference stores only stable ID and falls back to `Open` if missing.

`PlannerTaskQueryResult` includes ordered stable entity IDs, group descriptors, total
count, facet counts, source revision and continuation cursor. Rows resolve current
entities by owner + ID. Search normalization must be Unicode-aware and preserve raw
Persian/English display text; sorting uses deterministic locale/case behavior and ID
tie-breakers. Pagination cannot split selection semantics or duplicate rows.

Bulk execution returns a receipt with `batchId`, per-entity mutation ID/result,
skipped reason and Undo eligibility. Partial local failure rolls back the local batch;
remote acknowledgement may be partial but the outbox remains independently replayable.

## Whole-product propagation

- **Today:** task mutations, schedule changes and recovery immediately re-project the
  day stream without copying Tasks query state or duplicating “next up.”
- **Capture and wizards:** Quick Capture lands in Inbox and becomes visible under the
  active query only if it matches. Full create/edit reuses category/project/area/
  label IDs and returns to the prior result anchor; no workspace-only enums leak in.
- **Details and lifecycle:** row, search result and bulk preview open the canonical
  Stage 31 detail; Edit, Archive, Restore, Delete and conflict results update selection
  and counts without full refresh.
- **Plan:** scheduling or bulk rescheduling changes the Plan projection exactly once;
  Tasks' `Scheduled` view consumes the same temporal placement contract.
- **Habits, goals and relations:** task filters and groups consume stable Project,
  Area and later Goal relations; deleted relation targets show `Unassigned/Unavailable`
  honestly and never orphan the task.
- **Global search/filter:** expose the query parser and stable result descriptor to
  future global search; do not create a second text-normalization implementation.
- **Widget, notifications and deep links:** status/archive/schedule changes refresh
  widget payload and reminder schedule. External opens resolve the same entity detail,
  never a saved-view-local row object.
- **Perfect AI:** AI context may receive the active query summary and selected stable
  IDs, but an AI proposal must show explicit task diffs and cannot execute a bulk
  action without owner Apply.
- **Sync/conflicts:** saved views and task mutations are owner-scoped, revisioned and
  conflict-visible. Conflicting saved-view definitions duplicate as `Recovered copy`
  rather than silently discarding either query.
- **Settings/diagnostics:** provide default-view and per-device density settings;
  diagnostics report query revision, result count, index health and pending batches,
  never task text unless included in an explicitly initiated private export.
- **Empty/dense states:** separate “no tasks exist” from “this view has no matches,”
  search failure and unavailable relations. Dense lists use pagination/slivers, not a
  reduced hit target.
- **Upgrades/backup:** migrate old filter preference once, include saved definitions
  and index schema in backup/export, rebuild derived search index safely, and preserve
  auth, entities, pending operations, views and device-local selection defaults.

## Offline, sync, conflict and error cases

All queries and mutations work against local authority. Offline is a compact state in
the shared Sync Cloud, never a disabled list. Saved-view edits and bulk operations
enqueue immediately with stable mutation IDs. A retry cannot duplicate a task change.

Handle malformed saved query, removed relation, stale continuation, remote insert
above scroll, remote archive of selected row, simultaneous view rename, partial batch
acknowledgement, index migration/rebuild, database error and auth expiry. Keep last
valid results visible with an actionable local error; only the affected operation is
blocked. Conflict resolution restores current query/selection where still meaningful.

## Accessibility, keyboard and touch

Every view, token, group and row exposes role, name, state, position and action. Do
not rely on pastel color for lifecycle or selection. Result-count announcements are
debounced; bulk summaries announce eligible/skipped results once. Focus order follows
crown → lens → active tokens → groups/rows → inspector. RTL reverses directional
geometry but not time meaning or shortcut behavior. Tooltips label icon-only rail and
desktop actions. Touch/pointer targets are at least 48dp, visible focus rings survive
high contrast, and 200% text recomposes rather than ellipsizing required labels.

## Performance budgets

- A query change must not rebuild the shell, navigation or unchanged inspector.
- First local page for 5,000 tasks: target <=100ms release-mode warm query; search
  response after debounce <=150ms; scrolling sustains frame budget on target Android
  host renderer and Windows hardware.
- Use indexed/range queries, paged slivers, stable keys and narrow subscriptions.
  Facet counts may be cached by source revision; visible entities remain authoritative.
- Instrument query, projection, build/raster and batch duration without logging owner
  content. Cancel stale requests and bound cached result pages.

## Verification and required evidence

1. Unit vectors for every predicate, compound filter, sort tie, group, deleted
   relation, Unicode search and saved-view encode/decode/migration.
2. Repository tests for indexed pagination, cursor stability, 5,000-task budget and
   local/Supabase saved-view convergence.
3. Widget/interaction tests for view switching, refine preview/apply, row/detail,
   status control, long-press/Ctrl/Shift selection, each bulk action, Undo and focus/
   scroll preservation.
4. Cross-consumer tests proving schedule/status/archive updates Today, Plan, detail,
   reminder, widget projector, search index, AI context and sync queue once.
5. Golden/runtime evidence for no/one/dense/long/mixed data at 320x700, 360x800,
   390x844, short landscape, 600/800/900dp tablet, 720x540, 1024x640, 1366x768 and
   1600+ Windows; light/dark/high contrast, 100/200% text and reduced motion.
6. Real Android and Windows recordings of search, filter, selection, bulk Undo,
   inspector resize, offline mutation and recovery. Include frame/query traces and a
   side-by-side craft critique, not goldens alone.
7. Run focused tests plus full `flutter analyze` and `flutter test` at the stage
   release checkpoint. Record pass/fail/skipped honestly.
8. Include the accepted final direction, every component/state plate, every full-page
   layout/theme/state reference, decomposition manifest, component inventory,
   reference/runtime/diff pairs and closed mismatch/precision/occupancy/opinion ledgers.

## Reject if

- Any filter/sort remains ad hoc in a widget or hidden from the query summary.
- Runtime edits start before complete preview acceptance, or a component/page is
  accepted without an exact Copy side-by-side runtime comparison.
- A no-overflow layout is accepted while the task list is tiny, visually stranded,
  permanently buried under controls or missing its final reachable action.
- Search scans/rebuilds the entire in-memory entity list on each keystroke.
- Saved views duplicate tasks, silently broaden after a deleted relation, or let a
  remote active-view choice disrupt another device.
- Multi-select relies on list indices, lets a normal row tap destructively mutate, or
  applies an unreviewed partial batch.
- Status/lifecycle changes are stale in Today, Plan, detail, widget, reminders, AI,
  search or sync until restart/global refresh.
- Required copy clips, primary actions hide in overflow, or selection is color-only.
- Runtime hierarchy, geometry, copy, assets, density, states or responsive transforms
  materially diverge from the accepted reference without a documented adaptive rule
  and reopened internal design gate.

## Handoff and release

Hand Stage 37 the typed temporal query, stable list/selection state and shared saved-
view/filter primitives. Hand Stages 39 and 41 the adopted relation, saved-view and
index contracts; they extend them additively rather than replacing IDs or semantics.

Finish with a focused commit, push to `main`, successful workflow and the three private
install-ready artifacts required by the project. Record exact commit/artifact hashes,
internally accepted preview/decomposition paths, reference/runtime/diff artifacts, runtime evidence
and known limitations, then return to clean `main`-only branch state.
Do not remove the retained pre-rebuild stash.
