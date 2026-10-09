# Stage 37 — Plan workspace: day, week and month

Status: blocked — Stage 03–05 preview/Copy gate plus temporal projection, drag/resize, unscheduled-tray, and keyboard contracts have no recorded autonomous acceptance; existing projection/edit suites remain GREEN as characterization only
Depends on: accepted Stages 03–05 preview/copy contract; Stages 08, 12–13,
17–18, 22–25, 31–36  
Primary surfaces: Plan day/week/month, unscheduled tray, time blocking,
rescheduling, collision and capacity cues

## Mission

Make Plan the spatial decision surface for when work will happen. It must combine
dual-date orientation, actual scheduled work, recurring occurrences and a deliberate
unscheduled tray without stretching the current seven-day strip into a decorative
calendar. Every move is local-first, reversible and timezone-safe.

## Failure statement and autonomous decisions

The current Plan page projects one selected day from entities and renders a week strip
plus list. It has no durable view model for overlapping blocks, unscheduled work,
occurrence exceptions, drag, zoom, overload or month navigation. Replace that path.

- Day is the first-launch phone mode; week is the first-launch tablet/Windows mode.
  Each device remembers its last mode, selected date, working-hour window and zoom.
- Day, week and month are different compositions over one temporal projection—not
  three route implementations or a phone list scaled outward.
- Persist instants in UTC with the IANA timezone used for placement and retain a
  civil-date key for intentional all-day/date-only work. Display uses current owner
  timezone, but timezone changes never silently rewrite historical intent.
- Moving a recurring item edits that occurrence via an exception. It never shifts the
  whole recurrence rule unless the owner explicitly enters the recurring edit flow.
- Unscheduled means no date/time placement. All-day/date-only and time-blocked work
  are separate states; do not fake midnight to force them onto a timeline.
- Collision means blocks truly overlap. Overload is shown only when owner capacity is
  configured and planned duration exceeds it; without capacity, show factual total
  planned time and collisions, not an invented judgement.
- Drag is acceleration, not the only path. Every placement action has a keyboard and
  touch-friendly `Move or schedule` surface with the same preview/result contract.

## Preview and Copy fidelity gate — before any runtime edit

No runtime/schema work starts until Stage 03–05 direction/primitives are internally
accepted and all Plan component/page references have a recorded autonomous acceptance
decision. A missing or rejected preview keeps the stage in design/specification; it
does not authorize a generic calendar build.

1. Use Modernize in **Radical rebuild** mode: generate at least 24 Plan recipes,
   shortlist 6–8 and render 2–4 final high-fidelity directions grounded in temporal
   placement and reversible planning. Reject decorative calendars, stretched phone
   lists, generic productivity grids and visually copied competitors.
2. Apply Integrity's five-way opinion ledger to crown, mode/date navigation, dual date,
   time rail/current-time line, all-day lane, task block, collision stack, capacity
   cue, unscheduled tray/row, placement ghost, move/resize form, month cell/day drawer,
   inspector, empty/loading/offline/error/conflict, reminders/widget and composer.
3. Produce an **individual component preview plate for every component and state**:
   default, hover, focus, pressed, selected, dragging, valid/invalid drop, resizing,
   disabled, busy, optimistic, Undo, warning/error in light/dark/high contrast, RTL/
   mixed text, 200% text and reduced motion. Each plate specifies exact bounds,
   timeline/optical axis, token math, 48dp target, live semantics, z-order and SVG/
   raster/live/hybrid route.
4. Produce accepted full-page day/week/month references for phone portrait, short phone
   landscape, tablet portrait/landscape with compact/expanded rail, and 720x540,
   1024x640, 1366x768, 1600+ Windows. Cover empty/sparse/dense/overlap, all-day/date-
   only/timed/unscheduled, DST/midnight, tray closed/open, drag/resize/Move preview,
   inspector, long mixed copy, 200% text, light/dark/high contrast, reduced motion,
   offline/retry/conflict/error and optimistic/Undo.
5. Build Anatomy route/task and composition maps, compare at least two responsive IA
   candidates, then create the preview-to-production manifest for every layer, frame,
   occupancy/alignment equation, compact/medium/expanded transform, crop/z-order,
   asset path/provenance, live data/semantics, interaction and performance budget.
6. Record internal acceptance under the owner-delegated autonomous design authority.
   Implement through Copy fidelity: component inventory,
   exact reference viewport/state, real runtime capture, normalized side-by-side/diff,
   macro → component → micro repairs, then responsive sibling regression. Close the
   mismatch, precision, occupancy and opinion ledgers before acceptance.

## Detailed work packets

1. Freeze current day projection, selection, scroll and resize behavior with empty,
   sparse, overlapping, all-day, recurring and DST fixtures. Inventory every Plan
   route, schedule write and duplicated date calculation.
2. Define `PlannerTemporalPlacement`, `PlannerPlanItem`, `PlannerPlanQuery`,
   `PlannerPlanProjection` and `PlannerRescheduleCommand`. Centralize civil-day,
   timezone, recurrence-occurrence and range-boundary math outside widgets.
3. Add range queries for occurrences and one-off tasks. Materialize only the visible
   day/week/month plus a bounded prefetch window; resolve each projection row back to
   current owner-scoped entity/occurrence IDs.
4. Implement schedule mutation paths for create, move, resize time block, date-only,
   unschedule and recurring occurrence exception. Each returns before/after placement,
   mutation receipt and bounded Undo token.
5. Build shared Plan chrome: mode selector, dual-date navigator, Today action,
   previous/next period, search/filter entry and factual load summary. Reuse Stage 36
   query primitives for project/area/category/label scope.
6. Build exact day, week and month compositions below, including a genuine
   unscheduled tray. Do not append the tray as an unrelated full-width bar.
7. Add drag/drop and block resize with snap settings (default 15 minutes), live target
   copy, collision preview, edge auto-scroll and cancellation. Commit only on drop;
   Escape/pointer cancel restores the exact original projection.
8. Add keyboard scheduling: arrow navigation, Enter detail, `M` Move, `N` create at
   focused slot, `[`/`]` previous/next period and zoom shortcuts where they do not
   conflict with text entry. Publish shortcuts in tooltips/help.
9. Preserve selected date, focused item/slot, timeline scroll, zoom, tray disclosure,
   inspector and drag state through detail/edit return, remote updates, navigation
   rail change and continuous resize. On impossible resize during drag, cancel with
   explicit feedback rather than committing to an unseen target.
10. Replace all old Plan-only projection/sort helpers and direct payload writes.
    Update reminder and widget projections from the canonical placement receipt.

## Exact UI composition

### Shared Plan crown

The compact glass crown has two lines only when content requires it. The first line is
`Plan`, Day/Week/Month segmented selector, period navigation and whole `New` action.
The second line pairs Gregorian and Solar Hijri context for the selected period with
factual total scheduled time/collision count. At narrow width these recompose in that
reading order; required date or action copy never ellipsizes.

### Day

An all-day/date-only lane sits above a vertical time field. The field has a stable
time rail, subtle working-hours band, real current-time line only for today, and blocks
whose height corresponds to duration within bounded minimum geometry. Overlaps form
side-by-side columns with a readable minimum; when the minimum cannot be sustained,
they become a numbered collision stack that opens a focused overlap list. The
unscheduled tray is a collapsible dock attached to the trailing/bottom edge and shows
actionable Inbox rows, not a duplicate Tasks workspace.

### Week

Tablet landscape and Windows use seven day lanes beside one shared time rail. Headers
show weekday, Gregorian day and Solar Hijri day; Today uses shape/weight as well as
color. All-day items occupy a bounded band above the lanes. Phone week is a vertical
seven-day sequence with each day's load, collisions and chronological rows; it never
compresses seven unusable columns into 320dp. Selecting a day can promote it to Day
without losing the week anchor.

### Month

Month uses a complete six-row-capable calendar grid with non-color marks for workload,
completion and collisions. It does not squeeze task titles into tiny cells. Selecting
a date opens an adjacent agenda on expanded tablet/Windows or an in-page day drawer on
phone/compact Windows. A bounded unscheduled tray remains accessible without covering
the selected-day agenda.

### Placement preview

Before save/drop, render an outlined ghost block with exact date, start/end, timezone,
collision and recurrence-exception consequence. Invalid targets use a distinct shape,
text explanation and disabled commit—not red tint alone.

## Interaction and motion behavior

- Period navigation moves in temporal direction with a restrained shared-axis shift;
  view-mode change crossfades preserved date context. Reduced motion uses immediate
  replacement while retaining focus and announcement.
- Drag begins only after handle/long press threshold so vertical scrolling remains
  reliable. Windows starts from a visible handle or pointer drag; right-click never
  begins movement. Haptics mark valid snap and drop on supported Android devices.
- Auto-scroll accelerates only near an edge and is capped. Crossing midnight or a
  DST boundary updates the preview copy before commit.
- Optimistic save updates the projection once and exposes Undo. Remote acknowledgement
  changes only sync state. Failure restores the prior placement and keeps the command
  available for retry.
- Current-time line updates narrowly once per minute; it does not rebuild every block
  or jump scroll. Midnight advances Today styling and range projection without moving
  the owner's selected historical/future date.

## Responsive behavior

### Android phone

Day is a single timeline with bottom-attached tray; week is vertical; month uses the
grid plus selected-day drawer. At 320dp, 200% text and IME intrusion, the crown wraps,
date navigation remains operable and Move form actions remain visible. Short landscape
may show day timeline and a narrow tray only if both retain useful width; otherwise
stay single-pane. Final time slots and rows clear the floating composer/safe area.

### Android tablet

600dp split view favors vertical week/day plus modal tray. At 800dp portrait, month
can pair grid with selected-day agenda when text scale allows. At 900dp landscape,
week lanes occupy the central field and the unscheduled tray is a 280–340dp adjacent
dock. Rail collapse/expand never changes the selected civil day or drag destination.

### Windows compact and expanded

720x540 uses compact phone ordering with keyboard affordances. 1024x640 may show day/
week plus collapsible tray, but never seven lanes below minimum width. At 1366x768 and
1600+, week is a bounded canvas with tray and optional Stage 35 inspector; pane sizing
prioritizes the timeline. Continuous resize migrates week to vertical form and detail
inspector to page without resetting date, zoom, scroll or focus.

## Data and domain contracts

`PlannerTemporalPlacement` contains stable entity/occurrence ID, placement kind
(`unscheduled`, `dateOnly`, `timeBlock`), UTC start/end where applicable, intended
IANA timezone, civil-date key, all-day flag and revision. End must be after start;
date-only has no fabricated instant. Existing `timing.scheduled_at` and `end_at` are
migrated additively and preserved for older-client round trips.

`PlannerPlanItem` distinguishes one-off entity placement from recurring occurrence
placement and exposes immutable display facts: title, kind, relation IDs, progress,
placement, source revision and conflict flags. The UI never edits the row object.

`PlannerPlanProjection` contains period bounds, zone, day buckets, all-day buckets,
timed layout intervals, collisions, factual planned minutes, optional configured
capacity and source revision. Layout column assignment is deterministic for the same
interval set. Query boundaries use half-open ranges and one canonical local-day
resolver.

`PlannerRescheduleCommand` includes source ID/revision, before/after placement,
recurrence scope (`thisOccurrence` by default), idempotency key and origin. Local store
applies entity/occurrence update and outbox append atomically. For a recurring item,
the exception identity is deterministic per owner + rule + original civil occurrence.

## Whole-product propagation

- **Today:** Today consumes the same placement/civil-day resolver. A Plan move into or
  out of today inserts/removes/reorders exactly once while preserving scroll anchor.
- **Tasks:** Inbox/Scheduled/Overdue facets and rows update from placement receipts;
  unscheduling returns an item to Inbox without cloning it.
- **Capture and wizards:** Quick creation at a slot pre-fills placement; the full
  wizard may alter it and returns to the same date/scroll. Plain Quick Capture remains
  unscheduled. Recurrence edit distinguishes one occurrence from future rule.
- **Details:** Plan block/agenda row opens canonical detail. Detail reschedule uses the
  same Move surface; Focus and lifecycle actions update the active projection.
- **Habits:** eligible habit occurrences may appear as availability windows, but habit
  logging remains method-specific and does not convert a habit into a task block.
- **Goals/projects/horizons:** relation filters and later forecasts reuse stable IDs
  and planned-duration facts; horizon totals must not double count the same block.
- **Search/filter:** Stage 36 query tokens constrain the Plan projection consistently;
  active filter summary remains visible and saved Plan views use their own mode/range.
- **Widget/notifications/deep links:** a schedule receipt reschedules notifications and
  republishes widget data after local commit. Notification/widget open resolves entity
  or occurrence detail and selected Plan date without trusting caller timezone/owner.
- **Perfect AI:** AI may propose placements/time blocks using the versioned command,
  but the owner sees date, zone, collisions and recurrence consequence before Apply.
- **Sync/conflicts:** remote moves merge by field/revision policy. Concurrent placement
  conflict is explicit; never stack two silently chosen times or last-write away an
  occurrence exception.
- **Settings/diagnostics:** timezone, week start, working hours, snap interval, capacity
  and default mode are explicit owner/device settings. Diagnostics show projection
  bounds, zone and queue state without exposing task copy by default.
- **Empty/dense states:** distinguish no planned work, active filters with no matches,
  all work unscheduled, range-load failure and calendar with only habits. Dense overlap
  uses collision stacks and bounded agenda, not unreadable blocks.
- **Upgrades/backup:** migrate legacy scheduled/end fields without day drift; include
  placements, occurrence exceptions and settings in export/import; rebuild projections
  as derived state while retaining session, data and pending operations.

## Offline, sync, conflict and error cases

Scheduling is fully available offline. A drag/drop or Move command commits locally
with an outbox mutation, updates Today/Tasks/widget projection and schedules local
notifications. If platform notification scheduling fails, the planner write remains
successful and diagnostics expose the secondary failure with retry.

Test network loss mid-drag, duplicate drop, stale source revision, remote move during
preview, deleted relation/entity, conflicting recurring exception, timezone database
failure, DST gap/fold, midnight while open, notification denial, auth expiry and range
query error. Keep the last valid period visible; isolate retry to the failed command or
range. Never fall back to UTC display silently or clear the owner's selection.

## Accessibility, keyboard and touch

Timeline blocks expose title, full local date/time/zone, duration, collision position,
state and available actions. Current time, Today, collision and overload use text/
shape in addition to color. Keyboard can reach date controls, all-day lane, slots,
blocks, tray and inspector in logical order. A hidden semantic grid/list equivalent
must not duplicate screen-reader focus; choose one representation per composition.
Drag has Move/Resize dialogs and arrow/shortcut alternatives. Minimum targets remain
48dp, high-contrast focus is visible, mixed RTL titles do not reverse the time axis,
and 200% text switches to agenda/stack treatments before clipping.

## Performance budgets

- Query only the visible range plus bounded prefetch; no full-history scan in `build`.
- Warm period switch target <=100ms for normal data and <=200ms for a 2,000-item month
  projection; pointer drag/resize must sustain frame budget on target Android/Windows.
- Recompute interval columns only for changed day lanes. Current-time tick and sync
  acknowledgement rebuild no unrelated lane.
- Paginate selected-day agenda and unscheduled tray. Bound recurrence expansion and
  cache by rule revision + range + timezone; invalidate deterministically.

## Verification and required evidence

1. Golden data vectors for local-day boundaries, Gregorian/Jalali labels, week start,
   month edge, leap dates, UTC offsets, DST gap/fold, timezone travel and recurrence
   exceptions.
2. Projection tests for unscheduled/date-only/time-block, all-day, collision layout,
   capacity, deterministic ordering, bounded expansion and no double inclusion.
3. Mutation tests for create/move/resize/unschedule, recurring occurrence exception,
   duplicate replay, stale revision, Undo, offline replay and two-device conflict.
4. Interaction tests for touch/pointer drag, edge auto-scroll, cancel, keyboard Move,
   view/date navigation, zoom, detail return, remote insert and resize continuity.
5. Cross-consumer proof for Today, Tasks facets, detail, reminders, widget, AI proposal,
   conflict center and sync queue after each placement mutation.
6. Runtime screenshot matrix for all master viewports, sparse/dense/overlap/empty,
   light/dark/high contrast, RTL/mixed text, 100/200% text, IME and reduced motion.
   Record real Android and Windows day/week/month use and continuous resize.
7. Profile range query, recurrence expansion, drag build/raster and memory. Run focused
   tests plus full analyze/test at release checkpoint and record exact evidence.
8. Include every accepted component plate/full-page reference, decomposition manifest,
   component inventory, exact preview/runtime/diff artifacts and closed mismatch/
   precision/occupancy/opinion ledgers as mandatory evidence.

## Reject if

- Week/month are stretched phone lists or seven unreadable columns at narrow width.
- Runtime/schema edits start before preview acceptance, or a component/page is accepted
  without an exact Copy side-by-side runtime comparison.
- Any date-only item is persisted as fake midnight, a DST transition changes intended
  civil day, or recurring drag edits the entire rule without explicit confirmation.
- Drag is the only way to schedule, cancellation still writes, or a retry duplicates
  an occurrence/notification.
- Collision/overload is decorative, unexplained or calculated from invented capacity.
- View/resize/sync loses selected date, focus, zoom, tray state, scroll or draft.
- Plan changes remain stale in Today, Tasks, details, widget, reminders, AI or sync.
- The layout technically fits but strands tiny calendar content in dead space, covers
  the final slot with composer/tray, or hides a primary action in overflow.
- Runtime hierarchy, geometry, copy, assets, timing states or responsive transformation
  materially diverges from an accepted preview without a documented adaptive rule and
  reopened internal design gate.

## Handoff and release

Hand Stage 38 the shared date/filter primitives and occurrence range contract. Hand
Stage 39 factual planned-time/capacity projections for horizons, and Stage 40 the
entity/time-block attachment contract for focus. Stage 41 adopts temporal placement
and exception identities without changing persisted meaning.

Finish with a focused commit, push to `main`, successful workflow and all three private
install-ready artifacts. Record exact SHA, schema/version change, runtime evidence,
internally accepted preview/decomposition paths, reference/runtime/diff evidence, notification
caveats and artifact hashes; restore clean `main`-only state while
preserving the retained pre-rebuild stash.

### Evidence — 2026-09-25 (real runs, Stage 37 characterization only)

- Existing projection/edit timing behavior is GREEN as characterization
  (`planner_editor_test.dart` **EXIT:0, 17 pass**; Today projection/retry
  vectors in the integrated **EXIT:0, 198 pass** gate).
- This does **not** close Stage 37. Temporal projection, day/week/month
  compositions, tray/drag/resize/keyboard contracts, and preview acceptance
  remain blocked with no recorded autonomous acceptance.
