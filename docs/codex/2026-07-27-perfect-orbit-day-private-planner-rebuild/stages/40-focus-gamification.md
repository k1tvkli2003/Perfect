# Stage 40 — Focus system and meaningful gamification

Status: pending  
Depends on: accepted Stages 03–05 preview/copy contract; Stages 09–10,
19–20, 23, 31–39  
Primary surfaces: Focus workspace/capsule/session, breaks, reflection, focus
history, achievements, reward receipts and milestone upgrade proof

## Mission

Turn the existing modal timer into a durable, calm focus system that survives real
interruptions and makes planned effort visible. Add honest streak, achievement and
reward feedback only where it reinforces the owner's chosen behavior. Domain events
grant progress; animation merely explains it.

## Autonomous product decisions

- A single owner can have at most one active focus session across the workspace. Its
  durable event ledger—not an in-memory `Timer`—is authority for elapsed/remaining
  time, pause, resume, break, cancellation and completion.
- Modes are Pomodoro, Countdown, Stopwatch and Custom Block. A Custom Block is an
  ordered set of focus/break phases with explicit duration and no hidden auto-repeat.
- Pause/resume is durable and syncable. Background time follows the last persisted
  state; process death or device sleep never resets the session or fabricates ticks.
- Completion never marks a linked task/habit complete. It adds attributable focus
  evidence; any separate automation requires its own explicit reviewed rule.
- Distraction guidance is optional and humane: a small intention, local distraction
  note, notification/DND guidance and a return action. Perfect! does not inspect other
  apps, block the device, shame pauses or collect surveillance data.
- Flip-to-focus is opt-in on a physical Android phone only when a reliable foreground
  sensor path exists. Stable face-down posture triggers a three-second cancelable
  preview for the configured preset; Windows, tablets, unsupported sensors and
  background state show the feature as unavailable rather than emulated.
- Focus streaks follow an owner-authored eligible schedule/commitment. Unscheduled days
  never break a streak. Recovery/comeback can be celebrated; fear-of-loss copy cannot.
- Achievements use a versioned, project-owned transparent catalog and append-only
  grants. Rewards are non-purchasable, non-random cosmetic Day Compass facets/badges or
  reflective summaries—no currency, loot boxes, variable reward schedule or mutable
  client XP counter.
- Celebration can be skipped, suppressed or reduced without changing the grant. A
  presentation receipt prevents replay storms after sync, process restore or upgrade.

## Preview, animatic and Copy fidelity gate — before any runtime edit

This stage is visually/motion intensive. No Dart, sensor, notification, schema,
Android or Windows runtime edit starts until Stages 03–05 are accepted and this
complete preview set carries a recorded autonomous acceptance decision. Missing image
generation or animatic acceptance is a blocker, not permission to build a generic
timer.

1. Use Modernize in **Recompose + selective Showpiece** mode. Generate at least 24
   product-grounded focus/reward concepts, shortlist 6–8 and create 2–4 high-fidelity
   final directions. Keep the Perfect! Day Compass/pastel DNA, long-session calm and
   planner context; reject stock Pomodoro rings, gamer XP bars, neon dashboards,
   generic confetti and copied mascot/reward choreography.
2. Build the whole-product five-way opinion/motion ledger for the current Focus sheet,
   entry points, active capsule, setup controls, timer field, phase rail, pause/resume,
   break, interruption, reflection, detail/history, achievements, reward collection,
   Today/Tasks/Plan/Habits/Goals links, notification, widget, AI and settings.
3. Produce an **individual static/state preview plate for every component**: Focus entry
   action; active global capsule; entity attachment; mode selector; duration/phase
   builder; clock/progress field; intention/distraction note; pause/resume/complete/
   cancel; break transition; flip countdown/cancel; notification permission/degraded;
   reflection; history row; rhythm/streak evidence; achievement tile; locked/unlocked/
   granted/replayed reward; presentation queue; error/offline/conflict/restore. Include
   default, hover, focus, pressed, selected, disabled, loading, active, paused, warning,
   success and failure in light/dark/high contrast and reduced/no motion.
4. Produce full-page references for Focus setup, active session, paused, break,
   interrupted/recovered, completion/reflection, Focus history and achievement
   collection at phone portrait/short landscape, tablet portrait/landscape with both
   rail states and 720x540, 1024x640, 1366x768, 1600+ Windows. Cover unattached and
   Task/Habit/Project/Goal attachment, long mixed copy, 200% text, offline/retrying/
   conflict, notification denied, sensor unavailable and active session during resize.
5. Create a project-local **Motion Bible** and storyboard/animatic for each significant
   sequence: start, pause/resume, focus→break, session completion, streak continuation,
   comeback, achievement grant and rare milestone. Define authoritative trigger,
   presentation receipt, timecoded anticipation/commit/impact/settle beats, live layers,
   rendering route, interruption/skip/re-entry, sound/haptic option, asset fallback,
   RTL, full/reduced/no-motion variants and CPU/GPU/memory/package budgets. Static
   concept frames do not approve timing-sensitive behavior.
6. Build the preview-to-production manifest and Anatomy maps. Record each asset/live/
   hybrid layer, state variants, anchors/crop/z-order, original SVG/raster provenance,
   live semantics, phase/action placement, compact/medium/expanded transformation,
   focus order, geometry/occupancy math and performance. Timer, result copy, reward
   values and controls remain live; no screenshot is shipped as a session.
7. Record internal acceptance of component plates, page compositions and animatics
   under the owner-delegated autonomous design authority. Then use Copy fidelity per
   component and key motion frame: reference →
   real runtime still/recording → normalized side-by-side or synchronized comparison →
   mismatch repair. Image diff and frame timing are supporting evidence. Close the
   component inventory, mismatch, precision, occupancy, motion and opinion ledgers.

## Detailed work packets

1. Freeze the existing `FocusSessionSheet`, controller/local-store methods, focus table,
   payload fields, sync/RPC operations, More/row/inspector entrypoints and tests. Record
   failures: pause is process-local, completion auto-closes, active lookup is device-
   local and no reflection/reward presentation contract exists.
2. Define the focus state machine and append-only event ledger. Add additive local/
   Supabase schema, RLS/RPC/sync operations and migrations for events, reflections,
   commitments, achievement grants and presentation receipts; preserve old sessions.
3. Build one `FocusSessionCoordinator` that derives time from persisted timestamps and
   accumulated paused intervals. Enforce one active session, serialize commands and
   reconcile duplicate/out-of-order events deterministically.
4. Implement session setup and custom phase plan. Validate duration/phase limits,
   linked owner-scoped entity/revision, break policy and optional intention. Restore
   unsaved setup draft through route/resize/background.
5. Replace modal-only ownership with an adaptive Focus route/surface plus a compact
   global active capsule in shell-approved locations. The capsule shows mode, linked
   object, remaining/elapsed and pause/resume/open; it never covers Capture, composer,
   Sync Cloud or the final visible row.
6. Implement background/resume correctness: schedule a platform completion reminder
   from durable end instant, cancel/reschedule on pause/resume/change, derive state on
   wake and reconcile missed notifications. A background isolate/foreground service is
   not authority and is added only if verified platform behavior requires it.
7. Implement Android flip-to-focus behind capability check and explicit setting. Use
   bounded sensor sampling, stable face-down threshold, false-trigger cooldown,
   three-second preview, haptic where enabled, cancellation and foreground-only
   lifecycle disposal. Never keep a perpetual sensor listener while disabled/offscreen.
8. Add optional distraction capture and post-session reflection (`energized`, `steady`,
   `drained`, optional note, useful/not useful). Preserve text on error and keep it
   private/owner-scoped; reflection is not required to save a completed session.
9. Define transparent focus commitment/streak projections and an original achievement
   catalog. Implement immutable qualifying events, unique grants, explainable progress,
   catalog/rule versions, non-random cosmetic reward IDs and revoked-rule migration.
10. Implement presentation receipt/queue and approved choreography. Low-value events
    coalesce; planner navigation/error can preempt; skip/reduced motion acknowledges
    presentation only. Missing/corrupt assets fall back to a live semantic receipt.
11. Connect focus history to Task/Habit/Project/Goal detail, Today/reviews/insights,
    search, AI, notifications, widget/deep links, sync/conflicts, settings/diagnostics,
    backup/export/import and upgrade. Remove old direct session assumptions after parity.
12. Complete the Stage 40 milestone release proof: version N → N+1, identical Android/
    Windows signing identity, active/paused/completed sessions, grants, receipts, auth,
    drafts and pending operations retained with migrations run once.

## Exact UI composition

### Focus setup

A quiet **Focus Chamber** is centered as the primary instrument while explanatory copy
and settings remain start-aligned. The crown identifies `Focus`, linked entity and
close/back context. Mode selector and preset sit near the timer field; advanced custom
phases/breaks disclose below. The primary `Start focus` action follows configuration
and stays reachable under IME/safe area. No giant decorative ring leaves settings as a
tiny afterthought.

### Active session

The time field is the visual anchor with tabular digits, phase name, progress path and
linked-intention context. Pause/Resume is the dominant action; Complete and Cancel are
separated by frequency/risk. A compact distraction note affordance sits beside the
working context, not as a chat feed. Shell, Sync Cloud and active capsule remain stable.

### Global active capsule

The capsule is a compact authored Day Compass surface adjacent to the floating
composer/footer or desktop shell according to accepted Stage 04 geometry. It shows one
line of identity/time and labeled Open/Pause controls; at 200% text it becomes two
lines. It never duplicates the full Focus screen or intercepts unrelated page rows.

### Completion and reflection

First present factual receipt: actual focused duration, linked entity and completed/
interrupted status. Reflection is optional and secondary. If a streak/achievement was
truthfully granted, the approved milestone layer appears after the receipt and is
skippable; otherwise no consolation reward is fabricated. `Done` returns to exact
origin and `View history` opens the Focus ledger.

### Focus history and achievements

History is a chronological evidence ledger grouped by day with duration, mode, linked
entity, interruptions and reflection. Achievements are a separate collection layer
with transparent requirement, progress source, grant date/rule version and cosmetic
reward. Locked states reveal requirements without artificial scarcity or countdowns.

## Interaction and motion behavior

- Start is an atomic local event and immediate state transition. Double Start returns
  the same active session. Pause/resume/phase change/complete/cancel are serialized
  commands with stable receipts and no timer drift.
- Closing Focus never cancels it. The capsule and platform notification preserve entry;
  opening resolves current local session once. Escape closes local overlays before the
  route and never discards an active session.
- Completion notification opens the current session receipt/reflection, not a stale
  entity editor. Action buttons authorize owner/current revision before mutation.
- Motion follows the approved Motion Bible. Session continuity precedes celebration;
  no multi-beat sequence blocks Pause, Cancel, Back or a critical error. Rapid reversal,
  resize, background and route changes settle to deterministic state.
- Full, reduced and none/minimal motion share the same event/result. Sound/haptic is
  optional, respects OS/app settings and has visual/text equivalent.

## Responsive behavior

### Android phone

Portrait uses one immersive but non-trapping session surface. Primary controls remain
in thumb reach and outside gesture/nav insets. At 320dp/200% text, the time anchor
scales within semantic bounds and actions stack with whole labels. Short landscape
places time and controls in two bounded regions only if height leaves an escape/action
path; otherwise it scrolls one column. IME for intention/reflection cannot cover save.

### Android tablet

Portrait uses a larger centered instrument with start-aligned settings below/alongside.
Landscape may pair session instrument and phase/context panel, not stretch the phone
ring. Active capsule composes with compact rail. Flip-to-focus is hidden/unsupported on
tablet unless real capability and ergonomic verification prove it.

### Windows compact and expanded

720x540 keeps all session actions visible via bounded scroll and keyboard. Expanded
Windows uses a centered instrument plus adjacent context/history preview with stable
line lengths; it does not blow the timer up to fill the window. Space/keyboard shortcut
behavior is scoped so text entry cannot trigger Pause. Window minimize/restore and
continuous resize preserve session, phase, focus order and animation endpoint.

## Data and domain contracts

`PlannerFocusSession` retains stable owner/session/entity IDs and adds state projection,
plan ID/version, planned end, accumulated pause, current phase, intention, device origin
and revision. Mutable projection is rebuildable from immutable events and cannot grant
rewards by itself.

`PlannerFocusEvent` has owner, stable ID, session ID, sequence/causal predecessor,
event type (`started`, `paused`, `resumed`, `phaseAdvanced`, `completed`, `cancelled`,
`interrupted`, `reflected`), occurred-at UTC, payload, idempotency key, device ID and
revision. State-machine validation rejects illegal transitions. Equivalent duplicate
events return the original receipt.

`PlannerFocusPlan` is versioned and contains ordered focus/break phase IDs, type,
duration, auto-advance policy and maximum total duration. An active session snapshots
its plan version so later preset edits do not rewrite history.

`PlannerFocusCommitment` defines eligible schedule/period, minimum qualifying evidence,
timezone and effective range. `PlannerFocusRhythm` derives eligible/success periods,
current/longest run and recovery facts with explicit denominator/rule version.

`PlannerAchievementDefinition` is a signed/project-owned catalog item with stable ID,
rule version, title/description/pictogram, transparent predicate, cosmetic reward ID,
rarity/display tier and effective/retirement policy. `PlannerAchievementGrant` is
owner-scoped append-only and unique by definition version + qualifying event set.

`PlannerPresentationReceipt` derives stable ID from authoritative event/grant +
presentation family and tracks `pending`, `ready`, `playing`, `interrupted`,
`acknowledged`, `skipped` or `expired`. Presentation status cannot modify domain grant.

## Whole-product propagation

- **Today:** Focus actions on task/habit rows open setup with stable entity ID. Active
  capsule appears without duplicate dock; completion updates factual focus summary and
  goal receipts but never task/habit completion.
- **Tasks/Habits/Plan:** Focus entry and active state are consistent in rows, detail and
  inspector. A planned time block can seed duration; moving the block during an active
  session does not rewrite its snapshot.
- **Goals/Projects/horizons:** completed focus event contributes only through Stage 39
  typed measure/relation and unique receipt. Horizon review displays evidence once.
- **Capture/wizards:** task/habit focus presets edit through shared wizard. Switching to
  composer/AI/voice preserves active session and setup/reflection drafts.
- **Details/history:** Task/Habit/Project/Goal detail range-queries linked sessions and
  opens the canonical Focus receipt. Archived/deleted entity leaves history with a
  safe `Former item` label rather than losing it.
- **Search/filter:** Focus history is searchable/filterable by date, mode, status and
  linked stable entity according to privacy settings; it does not pollute Tasks results.
- **Widget/notifications/deep links:** notifications use normalized session ID/action,
  authorize after bootstrap and reconcile current state. Today widget may show an
  active-focus open action if platform size permits, but cannot mutate rewards or run a
  separate timer authority.
- **Perfect AI:** AI sees bounded owner-scoped focus summaries/reflections only with the
  established private context policy. It may propose a focus block/preset, but cannot
  claim completion, grant achievements or start sensor behavior without owner Apply.
- **Sync/conflicts:** events are append-only/idempotent; projection rebuild handles out-
  of-order delivery. Concurrent session starts resolve by owner invariant with visible
  recovery; no focus history or grant is silently last-written away.
- **Settings/diagnostics:** settings own presets, commitment, feedback intensity,
  sound/haptic, full/reduced/no motion, notification, flip capability and privacy.
  Diagnostics show active state/event sequence/presentation queue/sensor capability and
  timer drift without private intention/reflection text by default.
- **Empty/dense states:** distinguish no sessions, no qualifying commitment, active
  restored session, missing linked entity, notification denied, sensor unavailable,
  asset fallback and dense multi-year history. Virtualize history/collection.
- **Upgrades/backup/import/export:** migrate legacy focus rows into deterministic
  started/completed events, quarantine ambiguity, export sessions/events/reflections/
  commitments/grants/receipts and preserve active timers/auth/outbox across N→N+1.

## Offline, sync, conflict and error cases

Every session command works locally offline and schedules/cancels local notification
best-effort after durable commit. The timer derives from monotonic elapsed time while
alive and persisted UTC anchors across process death; clock discontinuity is detected,
logged and resolved conservatively. Sync is not required to Pause or Complete.

Handle duplicate start, simultaneous second-device start, process kill active/paused,
OS sleep, manual clock/timezone change, missed/duplicate notification, denied permission,
sensor false trigger/removal, phase boundary while backgrounded, link archived/deleted,
event gap/out-of-order, reflection save failure, missing reward asset, catalog upgrade,
duplicate grant/presentation, auth expiry and server rejection. Keep session control
available; isolate sync/reward failures from timer truth and provide current-state Retry.

## Accessibility, keyboard, touch and sensory safety

The clock announces meaningful changes on request/phase boundary, not every second.
Controls expose current session state and shortcuts; visible focus never clips. Space
toggles pause only outside text fields; `Ctrl+Shift+F` opens Focus; Escape follows local
context. Touch targets are 48dp and TalkBack order follows context → time → phase →
primary action → secondary actions. Timer/status/reward uses text/shape beyond color.

No rapid flash, high-contrast flicker, forced camera motion or infinite bounce. Full,
reduced and none/minimal paths retain result. Sound/haptics can be independently muted;
sensor path is opt-in and cancelable. Persian/English, tabular digits, time direction,
RTL navigation and 200% text are tested without mirroring clocks/brand marks blindly.

## Performance budgets

- Active time rendering rebuilds only the clock/progress semantic region, not shell/
  context. Use timestamp-derived cadence; no unbounded second-stream subscriptions.
- Target stable 60fps release mode; measure p95/p99 UI/raster frame time through start,
  phase transition and highest-risk approved achievement animation on representative
  Android and Windows hardware.
- Bound event/reward/presentation queries and virtualize history. Preload only the next
  measured milestone asset; pause/dispose hidden animation/sensor controllers.
- Budget vector complexity, decoded textures, blur/overdraw, audio startup, memory,
  battery/thermal and installed size in the Motion Bible. Missing/heavy asset must have
  deterministic low-cost semantic fallback.

## Verification and required evidence

1. State-machine/event vectors for every legal/illegal transition, duplicate/out-of-
   order event, one-active invariant, elapsed/pause math, phase boundary, process/clock/
   timezone change and legacy migration.
2. Platform tests for Android/Windows background/resume, notifications/actions, process
   restoration and Android flip capability/false-trigger/cooldown/lifecycle.
3. Commitment/streak/achievement/grant tests for eligibility, no guilt/reset on rest
   days, unique contribution, catalog version, duplicate sync and no client grant.
4. Presentation queue tests for idempotency, ordering/coalescing, skip, interruption,
   replay, missing asset and full/reduced/no-motion parity.
5. Cross-consumer tests through Today, Tasks, Habits, Plan, Goal/Project, detail,
   search, widget/deep link, AI, sync/conflict, settings/diagnostics and export/import.
6. Complete preview/Copy/motion evidence: every component/state plate and full-page
   reference, accepted direction, decomposition manifest, Motion Bible/storyboards/
   animatics, frame captures, synchronized runtime comparisons, diff artifacts,
   mismatch/precision/occupancy/opinion/motion ledgers and asset provenance.
7. Real Android/Windows recordings for every master viewport/state, background/resume,
   interruption/notification, RTL/mixed/200%, high contrast and full/reduced/no motion;
   release profiler and asset/battery/memory evidence.
8. Milestone upgrade proof: install signed version N, create active then paused session,
   pending event, reflection, grant and unacknowledged presentation; install N+1 over it
   with identical identity; prove auth/data/timer/outbox/grant/receipt survive and each
   migration/event/presentation runs at most once.
9. Focused tests plus full `flutter analyze` and `flutter test`, successful workflow,
   artifact install/launch and exact evidence log.

## Reject if

- Any runtime edit begins before component/page preview and animatic acceptance, or
  implementation is accepted without exact Copy side-by-side/recording comparison.
- Timer correctness depends on the widget `Timer`, app staying foregrounded or network;
  pause is not durable, duplicate start creates two sessions, or upgrade loses state.
- Completion automatically mutates a Task/Habit, a skipped animation alters reward, or
  a mutable local XP/streak counter is treated as authority.
- Rewards use random/variable reinforcement, guilt/fear copy, artificial scarcity,
  every-tap celebration or generic confetti in place of approved original choreography.
- Flip-to-focus runs without opt-in/cancel/capability/foreground guard or pretends to
  work on unsupported Windows/tablet/background paths.
- Focus history is stale in detail/goals/reviews/widget/AI/sync or cross-owner data can
  attach/contribute.
- Runtime geometry, assets, copy, timing, state or responsive transformation materially
  diverges from accepted preview/animatic without a documented adaptive rule and a
  reopened internal design gate.
- The layout merely fits but strands a giant timer, detaches controls, covers Capture/
  final rows, clips at 200% or drops frames on target hosts.

## Handoff and release

Hand Stage 41 the adopted focus event/reflection/commitment/grant/presentation schemas,
stable IDs and migration evidence; it may harden/index without changing semantics. Hand
Stages 42–44 explicit merge, one-active, retry and notification reconciliation rules.

Finish only after focused commit, push to `main`, successful workflow and three private
install-ready artifacts. Link accepted previews/animatics, decomposition/asset manifests,
reference/runtime/diff captures, profiler traces, exact SHA, catalog/schema versions,
checksums and N→N+1 signing/data-continuity evidence. Restore clean `main`-only state
while preserving the retained pre-rebuild stash.
