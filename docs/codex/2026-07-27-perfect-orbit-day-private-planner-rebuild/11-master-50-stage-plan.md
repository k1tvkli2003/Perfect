# Perfect! — 50-stage product perfection plan

Status: active canonical execution plan  
Platforms: Android phone, Android tablet, Windows desktop  
Distribution: private only  
Owner model: one private owner, local-first, Supabase-synced  
Current direction: remove Orbit; rebuild the product around a compact Today
Pulse, a fast day stream, first-class details, effortless habit logging, and a
single morphing Capture/Plan/AI/Voice instrument.

## Scope model: 50 owners, one whole product

The title of a stage identifies its primary implementation owner; it is not a
permission to ignore adjacent or downstream surfaces. Every decision must pass
the mandatory
[whole-product coverage and propagation ledger](stages/coverage-ledger.md),
which traces entrypoints, presentation, interaction, durability and lifecycle
through every applicable Android, tablet, Windows, widget, notification, sync,
AI, settings, recovery and release consumer.

This deliberately prevents a page-by-page rebuild. For example, changing task
progress also owns its Today/Tasks/Plan/detail/widget/AI/sync/export behavior;
changing a category selector also owns search, filters, custom SVG/color choices,
AI writes and backup/import; changing motion also owns route, overlay, resize,
keyboard, reduced-motion and performance behavior across the entire app.

## Non-negotiable acceptance matrix

Every runtime-changing stage is incomplete until its relevant surface is
exercised at all applicable points below. Passing compilation is never visual
or behavioral acceptance.

- Android phone: 320x700, 360x800, 390x844, tall phone, short landscape.
- Android tablet: 600dp split view, 800dp portrait, 900dp landscape, collapsed
  and expanded rail.
- Windows: 720x540 compact, 1024x640 intermediate, 1366x768 standard, 1600+
  expanded, plus continuous resize across breakpoints.
- Input: touch, mouse hover/press, keyboard traversal, shortcuts, IME open and
  dismissal, click/tap outside, long press, secondary click.
- Content: no data, one item, dense day, long user text, mixed Persian/English,
  RTL, 100% and 200% text scale.
- Presentation: light, dark, high contrast, reduced motion, focus rings, hover,
  pressed, disabled, loading, optimistic, success, retry, error and offline.
- Continuity: local draft, focus, selection, scroll and authenticated session
  survive route transitions, resize, background/resume and in-place update.
- Evidence: focused tests, a real runtime screenshot/recording, side-by-side
  critique, full analyze/test at release checkpoints, and a clean Git state.

## Execution and release discipline

1. Work on one numbered stage at a time; later-stage prototypes may exist but
   do not count as accepted before their dependencies pass.
2. Stages 03–05 complete the mandatory
   [preview-before-production gate](stages/preview-production-gate.md): component
   plates first, composed page previews second, then frozen Copy manifests. No
   shipped UI implementation may begin before that gate passes.
3. Start each stage with a frozen before-state and explicit failure statement.
4. Finish each runtime stage with behavior tests, geometry checks and runtime visual
   evidence for every affected layout class.
5. Any runtime-changing stage ends in a focused commit, push to `main`, a
   successful GitHub workflow and three install-ready release artifacts.
6. Design/documentation-only stages still end in a focused commit, push, link and
   clean branch state, but do not fabricate a binary release when runtime bytes are
   unchanged.
7. Preserve the Android/Windows signing line, monotonically increment versions,
   retain the authenticated session and prove upgrade continuity at milestone
   stages 10, 20, 30, 40 and 50.
8. Keep only `main` locally/remotely after each accepted stage; preserve the
   explicitly retained pre-rebuild stash until the full plan is complete.
9. Update `02-state.md`, `04-progress.md`, `05-verification.md` and this plan at
   every checkpoint. Record honest blockers; never turn a partial check into a
   completion claim.

## Wave 1 — truth, contracts and quality harness

### Stage 01 — preservation and personal-product contract

- Freeze Git, release, schema, signing, local database, auth/session and widget
  contracts before further structural edits.
- Codify Android/Windows-only scope, `Perfect!` identity, owner isolation,
  local-first writes, Supabase sync, no client secrets and no destructive reset.
- Prove that a normal upgrade cannot clear local records, pending operations,
  settings, AI drafts, auth tokens or widget state.
- Gate: preservation test inventory exists; dirty work and the retained stash
  are accounted for; forbidden reset/seed shortcuts have deterministic tests.

### Stage 02 — full interaction and route inventory

- Map every entry point: header, footer/rail, Today rows, Tasks, Plan, Habits,
  More, notifications, Android widget, deep links, shortcuts and AI actions.
- Map every entity lifecycle: create, quick capture, view, log, progress, edit,
  duplicate, archive, restore, delete, conflict and sync.
- Identify direct-to-edit routes, duplicate actions, dead controls, excess taps,
  ambiguous icons, inaccessible visible actions and state-loss transitions.
- Gate: every visible action has one owner, one destination and one tested
  result; redundant or conflicting routes have an explicit retirement plan.

### Stage 03 — evidence-led design direction and reference decomposition

- Decompose the accepted Perfect! brand, HabitNow creation logic and strongest
  task/planner references into information hierarchy, geometry, motion and
  interaction principles—not copied decoration.
- Build a side-by-side critique board for phone, tablet and Windows using sparse
  and dense content, including dark mode and IME intrusion.
- Define what is uniquely Perfect!: pastel prism identity, calm precision,
  quick reversible actions, owner-only intelligence and tactile day rhythm.
- Gate: the owner-delegated autonomous Modernize/Integrity/Anatomy/Style/Critics
  review internally accepts one evidence-backed direction that can explain every
  major surface; no generic card grid, arbitrary gradient or placeholder survives.

### Stage 04 — responsive design system and component preview library

- Finalize semantic tokens, responsive equations, typography/icon/material systems,
  Motion Bible and the vector/raster/hybrid asset manifest.
- Preview every reusable component separately across anatomy, interaction, domain,
  system, theme, direction, 200% text, phone/tablet/Windows and motion states.
- Compare each component beside real siblings; freeze one contract, consumer list,
  canonical preview version/hash and decomposition entry for Copy implementation.
- Gate: the component registry in `preview-production-gate.md` is complete and
  internally accepted; no full-page mockup is allowed to hide undefined controls.

### Stage 05 — full-product page preview library, Copy contract and quality harness

- Compose every route, overlay, workflow and Android widget size from the frozen
  component library; compare structurally distinct candidates before selecting one.
- Cover sparse/dense/system states plus phone, tablet, Windows, both themes, high
  contrast, mixed direction, 200% text, IME, short height and motion storyboards.
- Freeze page previews and preview-to-production manifests, then establish the
  normalized `reference | runtime | overlay/diff` Copy loop and quality harness.
- Gate: registries, hashes, fixtures and comparison tooling are complete; an injected
  geometry/type/state defect identifies the exact surface. Stage 06 receives an
  immutable preview ID rather than prose or visual memory.

## Wave 2 — shell, brand, navigation and ambient behavior

### Stage 06 — brand asset and installed identity audit

- Re-verify selected mark and typography asset at runtime, Android launcher,
  splash, widget header, Windows ICO frames, taskbar, Start and installer.
- Ensure the mark itself remains transparent, optically centered and safe inside
  Android masks without white/black fallback, edge crop or undersized artwork.
- Remove any remaining raw keyboard emoji and generic placeholder glyphs.
- Gate: real Android and Windows screenshots prove consistent identity at small,
  medium and high-DPI sizes; asset masters and generated outputs are reproducible.

### Stage 07 — adaptive navigation shell

- Rebuild phone footer as a floating icon-only glass dock with a restrained,
  destination-specific selected state and no stock oversized pill.
- Keep tablet rail compact by default; let Windows remember collapsed/expanded
  state; preserve focus, page state and scroll through live resize.
- Remove unreachable, duplicated or nonessential header menus.
- Gate: every destination is reachable by touch, mouse and keyboard; selection
  is obvious without text labels; 200% text and short landscape remain usable.

### Stage 08 — compact glass header, sync and dual date/time contract

- Replace heavy colored header strips with a compact blurred layer whose content
  remains readable over live page surfaces.
- Present the real device-local clock plus Gregorian and Solar Hijri dates in a
  compact, culturally correct, mixed-script composition.
- Redesign Sync Cloud states: green synced, yellow syncing/retrying, red error,
  each with shape/copy semantics and bounded automatic retry—not color alone.
- Gate: known Gregorian/Jalali boundary dates, midnight, timezone conversion and
  retry/error states pass tests and real light/dark screenshots.

### Stage 09 — global route, surface and microinteraction motion

- Define motion roles: page shared-axis, title rise, sheet fade/scale, dock morph,
  selector glide, completion spring and calm background progress.
- Remove unrelated or default popup animations; match direction to navigation
  intent and keep outgoing/incoming geometry stable.
- Add hover, press, keyboard focus, drag and reduced-motion behavior to every
  shared primitive.
- Gate: recordings show no jump cuts, double-painted surfaces, focus loss,
  scroll reset or frame stalls on Android host renderer and Windows runtime.

### Stage 10 — complete light/dark/high-contrast surface system

- Rebalance every semantic color role for light and dark instead of dimming the
  light palette; validate text, icon, ring, border and glass contrast.
- Audit all authored SVG assets and painter colors against both themes.
- Make system bars, selection, text fields, menus, dialogs and widget previews
  theme-consistent.
- Gate: contrast checks and full dark screenshots pass; two consecutively signed
  builds prove in-place update with session and local data retained.

## Wave 3 — Today surface rebuilt from first principles

### Stage 11 — remove Orbit and introduce Today Pulse

- Remove Orbit from phone, tablet and Windows compositions and retire its runtime
  labels, hit targets and motion; do not leave a decorative empty replacement.
- Build an adaptive Today Pulse with local time, Gregorian/Jalali date, completed
  vs remaining work, next temporal boundary and a direct Plan action.
- Use a compact phone composition and a wider tablet/desktop composition without
  wasting the space returned by Orbit.
- Gate: Orbit is absent from the semantics and widget tree; Today Pulse remains
  useful in empty, dense, dark, landscape and 200% text states.

### Stage 12 — Today information architecture and day-stream grouping

- Reorder Today around immediate decisions: orientation, next actionable work,
  chronological stream, flexible/inbox work and habits needing attention.
- Avoid repeating the same next task in separate cards; the first actionable row
  receives contextual emphasis inside the stream.
- Keep quick capture/footer reachable without hiding the final visible row.
- Gate: a user can identify what to do now, what is later and what is unscheduled
  in one scan; empty and dense screenshots have deliberate scale and no dead zone.

### Stage 13 — task-row and status-control reconstruction

- Replace legacy rows with one precise responsive component: stable time rail,
  title, category/context, optional schedule/estimate and quiet detail affordance.
- Normalize Pending, Partial, Done and Missed into one fixed geometry and stroke
  system; multi-tap cycles state without size or alignment jumps.
- Show partial progress through the ring arc only; keep exact percentage in
  semantics and detail view, not cramped inside the ring.
- Gate: all states align side-by-side, hit targets are at least 48dp, long copy
  reflows safely and state changes are optimistic, reversible and persisted.

### Stage 14 — effortless inline habit logging

- Render the row control by tracking method: toggle for check, `+1` for count,
  quick increment for time/value, and remaining-step affordance for checklist.
- Provide immediate `Undo`, controlled decrement/correction and completion/streak
  feedback without opening a full editor or refreshing the page.
- Keep today totals and target visible without turning every row into a dashboard.
- Gate: check, count, value, duration and checklist habits can be logged/corrected
  one-handed; repeated rapid taps serialize correctly and never lose increments.

### Stage 15 — Today empty/loading/offline/error and optimistic states

- Guarantee a real owner with no records sees a useful empty state, not demo
  tasks, habits, dates, names or placeholder planner entities.
- Distinguish first load, local data ready, background sync, retry and hard error
  without blocking local work or replacing content with full-screen spinners.
- Add capture-first guidance and restoreable optimistic/undo feedback.
- Gate: clean account, airplane mode, delayed sync, conflict and recovery paths
  all remain actionable; no fixture code is reachable from production entrypoints.

## Wave 4 — one morphing Capture/Plan/AI/Voice instrument

### Stage 16 — collapsed Quick Capture as a true floating control

- Remove every full-width tint/strip behind the collapsed orb; keep only the
  authored circular control, a soft blur halo and a subtle heartbeat when idle.
- Opening the orb must not summon the keyboard; only direct field activation may
  request focus, and tapping elsewhere dismisses it immediately.
- Preserve draft and state through route changes, resize and temporary AI use.
- Gate: screenshots prove page content continues behind the orb; no invisible
  surface intercepts rows; focus and IME behavior pass on Android and Windows.

### Stage 17 — task capture mode and resilient quick-save flow

- Center the text/hint optically inside the field using the field's geometry—not
  the adjacent action row—and remove redundant Quick Capture headings/copy.
- Support title-first save, mixed RTL direction, Enter/Ctrl+Enter, disabled/send
  states, local-first confirmation, undo and clear validation.
- Preserve text through transient errors and never duplicate on repeat submit.
- Gate: hint/content centers geometrically at normal/200% scale; one fast action
  creates exactly one local record, schedules sync and leaves the UI coherent.

### Stage 18 — inline Plan mode morph

- Transform the same composer into compact Task, Recurring Task and Habit entry
  choices; do not stack a new box over it.
- Transition shape/height/content while retaining the capture draft and provide a
  clear return gesture without redundant title bars.
- Route the chosen type into the correct create wizard state.
- Gate: morph is continuous and reduced-motion safe; each kind opens the expected
  wizard and back/cancel restores the previous composer state.

### Stage 19 — embedded Perfect AI and Voice modes

- Replace the separate AI dock with the same composer morphing into conversation,
  voice recording, response and proposal review states.
- Keep AI draft/conversation while switching modes; present recording consent,
  duration, stop/cancel/retry and transcription errors in the same instrument.
- Make the AI glyph unmistakable and project-owned.
- Gate: only one composer surface exists at a time; Task→AI→Voice→Task preserves
  drafts and focus; no provider secret is present in client assets or process argv.

### Stage 20 — composer motion, performance and release proof

- Tune shape morph, height animation, content crossfade, heartbeat and busy states
  to avoid double-painted glass and software-renderer memory spikes.
- Verify final-row reachability when the composer is closed/open, AI is tall and
  IME occupies the viewport.
- Profile frame build/raster and memory on Android and Windows.
- Gate: repeated open/close/mode cycles stay responsive; signed upgrade build
  preserves capture/AI drafts, session and local records.

## Wave 5 — creation and editing wizards

### Stage 21 — unified wizard shell and visual language

- Replace legacy selector/filter styling with shared modern selection surfaces
  already used by Tasks/Plan; remove selected checkmarks when color/shape suffices.
- Use a compact blurred header, clear stage identity, modern meter/rail, coherent
  surface transitions and a footer sized only to its real actions.
- Remove the empty quick-save strip above Continue; place secondary actions in a
  balanced same-row or contextual location.
- Gate: create/edit shells match across phone/tablet/Windows, dark mode, RTL and
  200% text; no empty bar, clipped action or stale old-style control remains.

### Stage 22 — task creation: identity and organization

- Keep entity Type only in create mode; then guide category, project, area, icon,
  color and labels with searchable, customizable choices.
- Seed at least 30 useful categories as choices only—not records—with project-owned
  icons; allow custom category, color and icon archive selection.
- Avoid forcing optional organization before a title can be captured.
- Gate: default, custom and long/mixed labels save correctly; selection state is
  clear without redundant ticks and every required action remains reachable.

### Stage 23 — task definition, timing and scheduling

- Build title/note/checklist/estimate/energy/priority inputs with progressive
  disclosure and precise keyboard/focus behavior.
- Handle all-day, exact start, time block end, due date, timezone and reminders;
  prevent invalid or contradictory time relationships.
- Show a live human-readable schedule summary before save.
- Gate: midnight, no-time, overnight, timezone change, invalid range and reminder
  permission failures are tested without losing the draft.

### Stage 24 — recurring task, recovery and carry policy

- Support daily, weekdays, interval, flexible quota, month dates, last day,
  annual dates, end/limit, pauses and exceptions.
- Expose per-item Miss/Pending/next-valid/ask policy and bounded Carry cap in
  language that predicts actual behavior.
- Preview upcoming occurrences and recovery outcomes before save.
- Gate: recurrence/recovery engine and UI summaries agree across month/year edges,
  missed sequences, cap exhaustion and offline mutation replay.

### Stage 25 — edit path, draft safety and validation

- Edit opens at the first mutable step and never asks Type; header carries the
  immutable kind as context only.
- Detect unsaved changes, preserve draft through resize/background, provide
  discard/continue choices and retain field focus/scroll on validation failure.
- Apply edits to the same stable ID without breaking logs, recurrence or sync.
- Gate: direct row tap never opens edit; detail→Edit does; type picker is absent,
  footer has no blank strip and history survives every allowed edit.

## Wave 6 — habit creation, tracking and recovery

### Stage 26 — HabitNow-inspired habit creation flow

- Use the proven order: organization, measurement, definition/goal, frequency,
  time/reminders/recovery, review—improved for Perfect!'s local-first model.
- Keep each stage focused and preview its consequence; advanced controls remain
  discoverable without filling the first screen.
- Tailor copy and visuals to build/maintain/quit habits.
- Gate: common habit creation is fast; every advanced scenario remains expressible
  and revisitable without restarting or losing prior steps.

### Stage 27 — complete tracking-method model

- Support boolean, count, duration, numeric, checklist and formula-based tracking
  with units, direction, target, partial credit and success thresholds.
- Validate impossible targets/formulas and preview exactly what one tap will add.
- Store method/version metadata so future clients and AI can reason safely.
- Gate: each method round-trips through local store, Supabase, editor, Today row,
  detail stats and Android widget without semantic drift.

### Stage 28 — multiple-per-day frequency and fast accumulation

- Model several planned/allowed completions per day without forcing separate
  entities or cumbersome sheets.
- Provide atomic increment/decrement and recent-value shortcuts, serialize rapid
  taps and expose remaining target directly on the row.
- Handle over-target, reset/correction and per-day boundaries explicitly.
- Gate: 20 rapid increments produce the exact expected value locally/remotely;
  correction and undo are deterministic and day rollover cannot leak counts.

### Stage 29 — skip, miss, recovery and streak integrity

- Distinguish not-yet-due, pending, completed, skipped-valid, missed and recovered;
  never punish a day outside the schedule.
- Implement quit-habit direction, streak freeze/recovery and carry behavior without
  rewriting immutable history.
- Explain streak changes before destructive correction.
- Gate: streak/longest/rate calculations match retained occurrence history across
  timezone/day boundaries, offline replay and conflict resolution.

### Stage 30 — habit logging polish and signed upgrade proof

- Add tactile progress, success celebration, restrained streak feedback, undo and
  accessible announcements; honor reduced motion.
- Make one-handed logging safe near scroll gestures and prevent accidental row
  navigation while incrementing.
- Verify dense habit days and widget logging remain fast.
- Gate: real device recordings and frame metrics pass; signed upgrade preserves
  all habit logs, streak state, session and pending sync operations.

## Wave 7 — view-first details, statistics and history

### Stage 31 — shared view-first detail route

- Route Task/Habit taps from Today, Tasks, Plan, Habits, widget and deep links to
  one detail destination—not directly to edit.
- Build responsive phone page, tablet composition and Windows adjacent/full detail
  using the same data contract and action hierarchy.
- Provide explicit Edit, status/log, Focus and More actions.
- Gate: every entrypoint resolves the current owner-scoped entity or a recoverable
  not-found state; back restores prior page, selection, focus and scroll.

### Stage 32 — task detail and progress history

- Present title, note, status, schedule, deadline, recurrence, recovery, estimate,
  project/area, checklist, custom fields and sync state in a scan-friendly layout.
- Show occurrence/completion history for recurring tasks and the meaningful event
  timeline for one-off tasks; avoid invented analytics where history does not exist.
- Include a month calendar with clear completed/missed/partial/pending legend.
- Gate: stats derive only from durable records; exact dates/statuses match local
  store queries and remain readable in empty/long-history states.

### Stage 33 — habit detail, streak and calendar analytics

- Show today control, current/longest streak, success rate, totals, target trend,
  schedule and recovery context.
- Build an interactive month heatmap/calendar and selectable day detail with safe
  correction/undo; adapt intensity to tracking method rather than binary-only data.
- Add week/month/quarter/year trend views without overwhelming the default page.
- Gate: every metric is reproducible from occurrences; calendar navigation, RTL,
  dark colors and zero-history states pass behavioral and visual checks.

### Stage 34 — detail actions and lifecycle safety

- Place Edit as a clear primary contextual action; group Duplicate, Archive,
  Restore, Export and Delete by reversibility and frequency.
- Require appropriate confirmation for destructive actions and offer undo where
  possible; never expose archive/delete through an accidental row tap.
- Show sync/conflict consequences before irreversible history changes.
- Gate: each lifecycle action is owner-authorized, idempotent, tested offline and
  reflected immediately across detail, lists, widgets and sync queue.

### Stage 35 — desktop inspector, deep link and resize continuity

- Reuse the full detail content in Windows adjacent inspector when width permits;
  fall back to a full detail page when it does not.
- Keep selected entity, calendar month, scroll and focus stable through rail and
  window resize; support keyboard next/previous item navigation.
- Route notification/widget/deep-link opens to detail with no intermediate edit.
- Gate: continuous resize causes no duplicated route, stale entity, lost state or
  cramped pane; signed upgrade keeps deep-link protocol behavior intact.

## Wave 8 — Tasks, Plan, Habits, goals and focus

### Stage 36 — Tasks workspace reconstruction

- Rebuild hierarchy, search, filter, sort, saved view and grouping controls with
  shared selector primitives and responsive action placement.
- Support Inbox, active, scheduled, completed, recurring and custom category/project
  views without hiding the only action behind overflow.
- Add efficient keyboard/mouse multi-select and safe bulk actions on Windows.
- Gate: filters compose predictably, persist appropriately and remain understandable
  in narrow/RTL/200% layouts; dense lists scroll and update without full rebuild.

### Stage 37 — Plan workspace: day, week and month

- Build useful day/week/month views with clear current time, dual date context,
  unscheduled tray and conflict/overload cues.
- Support move/reschedule, time blocking and quick creation with keyboard/touch
  parity, reversible optimistic writes and no accidental day drift.
- Preserve selected date/scroll/zoom through navigation and sync updates.
- Gate: timezone, midnight, month edge, dense overlap and drag cancellation tests
  pass; Windows/tablet layouts use space intentionally rather than stretched phone UI.

### Stage 38 — Habits workspace and actionable insights

- Rebuild the default page around today's logability, streak momentum and habits
  needing attention; keep analytics one intentional layer deeper.
- Offer filters for build/maintain/quit, category, schedule and risk without a
  noisy permanent toolbar.
- Surface evidence-based suggestions, never guilt-driven generic copy.
- Gate: logging remains possible from list and detail; insights match durable data
  and the page is useful with zero, one and many habits.

### Stage 39 — Goals, projects, areas and planning horizons

- Add first-class Goals with outcome, horizon, measures, linked projects/tasks/
  habits and weekly/monthly checkpoints.
- Provide week, month, quarter and year review/forecast surfaces with progress and
  realistic replanning—not ornamental dashboards.
- Keep Project and Area semantics distinct and AI-writable through stable IDs.
- Gate: linked progress is explainable, no double counting occurs and goal edits
  cannot orphan child records or cross owner boundaries.

### Stage 40 — Focus system and meaningful gamification

- Integrate Pomodoro, custom focus blocks, flip-to-focus where platform-feasible,
  optional distraction guidance and post-session reflection.
- Add streak/achievement/reward feedback that reinforces planned behavior without
  manipulative pressure or corruptible derived state.
- Connect focus history to entity details and reviews.
- Gate: interruption, pause/resume, app background, notification and upgrade paths
  preserve timers/history; reduced motion and signed update proof pass.

## Wave 9 — data plane, auth, sync and empty-account integrity

### Stage 41 — agent-friendly canonical schema and migrations

- Finalize stable owner-scoped entities for tasks, recurring tasks, habits, notes,
  projects, areas and goals plus schedule, occurrence, progress and relation tables.
- Use explicit versioned JSON contracts only where extensibility is needed; keep
  query-critical identity/status/time fields typed and indexed.
- Make migrations idempotent, forward-safe and easy for an authorized agent to
  generate valid planner writes without guessing UI implementation details.
- Gate: clean install and upgrade migrations pass; schema/RPC docs and examples
  cover every entity/action and reject malformed/cross-owner payloads.

### Stage 42 — local-first operation log and conflict correctness

- Keep the local database authoritative for immediate interaction; represent each
  mutation as an idempotent operation with revision, owner and causality metadata.
- Define merge policy per field/entity and immutable occurrence/focus history;
  surface real conflicts instead of silent last-write data loss.
- Bound retries and compaction without dropping pending operations.
- Gate: offline create/edit/log/delete, duplicate replay, out-of-order remote events
  and two-device conflicts converge deterministically.

### Stage 43 — private auth/session and personal account bootstrap

- Verify the single private Supabase account flow for `keyvan`, safe credential
  handling and persisted refresh session across app/process/OS updates.
- Never hardcode raw credentials or provider keys in client source/build artifacts;
  use secure server-side/bootstrap mechanisms appropriate to the private product.
- Handle expired/revoked session without deleting local data.
- Gate: sign-in, cold start, token refresh, offline start, revoke and in-place update
  pass on Android and Windows; no secret scan finding remains.

### Stage 44 — sync state, retry, background refresh and conflicts

- Drive the three-state cloud from real queue/network/error state and expose useful
  retry detail without blocking local work.
- Refresh from realtime/background events rather than scroll gestures or perpetual
  pull-to-refresh; suppress duplicate rebuilds and retry storms.
- Keep bounded backoff, jitter, connectivity resume and a visible conflict center.
- Gate: network loss/recovery, server errors, auth failure, remote insert and two
  devices update UI exactly once and preserve scroll/focus/drafts.

### Stage 45 — zero-demo production, backup/import/export and recovery

- Remove all production seed/demo/placeholder entity paths; isolate dev fixtures by
  separate entrypoint/package and prove they cannot run for the signed owner build.
- Add owner-controlled backup/export/import with schema version, validation,
  deduplication and dry-run summary.
- Provide local database/diagnostic recovery without destructive reset as default.
- Gate: brand-new keyvan account is empty locally/remotely; import round-trip hashes
  and counts match; invalid/older backup fails safely with actionable explanation.

## Wave 10 — agentic AI, Android widget and final hardening

### Stage 46 — secure Perfect AI conversation contract

- Keep provider/model credentials server-only and centralize supported model config;
  authenticate every request and retrieve only owner-scoped planning context.
- Support Persian/English text and consent-first bounded voice; preserve a friendly,
  personal default tone without allowing prompt injection to alter authorization.
- Require strict versioned structured proposals and never treat model output as
  executable authorization, raw SQL or unrestricted tool arguments.
- Gate: deterministic contract, malformed output, refusal, timeout, rate-limit,
  injection and cross-owner tests pass; live smoke runs only with a valid rotated key.

### Stage 47 — reviewable AI writes across the complete planner

- Allow proposals for tasks, recurring tasks, habits, notes, schedules, projects,
  areas, goals and safe updates using an explicit allowlisted action registry.
- Show human-readable diff, conflicts and consequences; write only after explicit
  Apply, with idempotency, transaction boundary and audit trail.
- Refresh local state and sync/widget surfaces after apply; support retry without
  duplicate records and rejection without side effects.
- Gate: prompt→proposal→review→apply→local view→Supabase convergence is proven for
  every kind; unauthorized/malformed/duplicate action attempts produce zero writes.

### Stage 48 — responsive actionable Android widget

- Rebuild widget layouts by actual size class: compact summary, medium actionable
  list and expanded scrollable day stream; keep mark transparent and uncropped.
- Support direct status cycle, habit quick increment and compact Quick Add dialog,
  all through the same durable local-first queue and owner authorization.
- Update from app, background sync and widget actions without stale duplicated rows.
- Gate: picker, add, resize, scroll, task/habit action, quick add, offline replay and
  app deep link pass on a real launcher at every supported size.

### Stage 49 — whole-product adversarial quality gate

- Run an obsessive route-by-route critique of copy, hierarchy, geometry, symmetry,
  graphics, motion, state, accessibility, performance, failure and recovery.
- Compare before/reference/after side by side for every layout class; reject merely
  non-overflowing output that remains generic, cramped, sparse or visually weak.
- Profile startup, list/build/raster, local queries, sync and AI latency/memory.
- Gate: full matrix, golden review, real Android/Windows recordings, semantics,
  keyboard traversal, reduced motion, offline/error and performance budgets pass.

### Stage 50 — final release, upgrade proof and clean handoff

- Produce monotonically versioned Android APK, Windows portable ZIP and installable
  signed Windows setup with only install-ready contents.
- Install version N, create data/session/pending operation, update to N+1 with the
  same identities and prove all state survives and new migrations run once.
- Confirm exact `main` SHA, clean local/remote branches, retained intentional stash,
  release checksums, changelog, architecture/schema/AI/widget/user documentation.
- Gate: GitHub workflow and release succeed, artifacts install on target devices,
  all required evidence is linked, and no known P0/P1 or dishonest completion claim
  remains. The ongoing Critics→Perfect loop continues for future feedback.

## Current mapping

- Stage 01 is the active gate.
- Existing uncommitted Quick Capture, date formatter and Today changes are
  prototypes mapped to stages 08, 11 and 16–19; they are not accepted until the
  earlier contracts/harness and their own stage gates pass.
- The last accepted release before this plan is build 2038 at commit
  `6b810449acd2c028d3ad7c15d6d5d6401c01e5f5`.
