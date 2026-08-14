# Stage 11 — Remove Orbit and build Today Pulse

Status: locally verified; exact-SHA hosted closure pending
Depends on: Stages 05, 08–10  
Primary surfaces: Today phone/tablet/Windows; widget orientation summary

## Mission

Delete Orbit as an interaction and visual model. Reinvest its dominant space in a
compact, information-dense but calm Today Pulse that orients the owner immediately
and leaves most of the viewport for actionable work.

## Mandatory preview and Copy entry gate

Gate result (2026-08-14): **passed after two adversarial correction rounds**.
The authoritative `today-pulse-dayline-v2` corpus is under
`design/05-runtime-comparisons/stage11-today-pulse/`. Eight deterministic boards
cover concept rejection, semantic states, phone density, 200%/short-height stress,
tablet/Windows composition, authored themes, motion choreography and measured axes.
The generator and independent verifier are `tool/generate_stage11_today_pulse.cjs`
and `tool/verify_stage11_today_pulse.cjs`.

- Bind implementation to `td-pulse`, `sh-dual-date-clock`, `sh-sync-cloud` and
  `pg-today-empty/sparse/normal/dense` canonical compositions.
- Preview no-data, all-complete, missed-only, habits-only, unscheduled-only,
  syncing/offline, short landscape, 200% mixed text and wide pane variants.
- The decomposition manifest separates live time/date/projection copy from any
  authored progress path; no ring/orbit-like decorative substitute is allowed.
- Compare Pulse scale, alignment, negative space and stream adjacency at identical
  fixtures; passing bounds without reclaiming useful work area is a mismatch.

## Product decisions

- No circular day dial, clock labels around a ring, heartbeat arc or decorative
  substitute survives in the production widget tree or semantics.
- Today Pulse contains only decision-relevant orientation: live local time, dual
  Gregorian/Jalali date, completed/remaining summary, next schedule boundary and
  one direct Plan action.
- The pulse is not another dashboard card grid. It is one composed instrument that
  reflows from compact stacked phone to wide tablet/desktop.
- The stream—not the pulse—owns task/habit content and status mutation.

## Composition specification

### Phone portrait

- Greeting/title enters above or within the pulse without repeating brand/date.
- Time receives the strongest numeric role but remains smaller than the removed
  Orbit footprint; AM/PM is secondary and baseline-aligned.
- Gregorian and Persian dates form one mixed-script block with intentional
  direction isolates and Persian digits for Jalali values.
- A slim authored progress path and two textual measures show done/remaining.
- Plan affordance is 48dp, visually quiet, and does not compete with the stream.

### Phone landscape/200% text

- Recompose into two compact rows; never squeeze date/time/metrics side by side.
- Allow intrinsic height and make the stream scroll; preserve final actions above
  floating footer/composer.

### Tablet/Windows

- Use bounded columns: time/date, daily outcome, next boundary/Plan. Do not stretch
  one line across the viewport or leave a tiny pulse floating in dead space.
- Align to stream content axis and rail/header geometry.

## Work packets

1. Remove every `OrbitStage` runtime use, import, semantics, motion toggle and
   golden expectation; retain source only if a separately justified reusable
   component exists, otherwise delete dead code/assets/tests.
2. Implement minute-aligned live time from the shared Stage 08 clock source.
3. Compute complete/remaining from real projected Today eligibility/log/progress,
   including recurring tasks and habits; do not infer from generic entity status.
4. Compute next temporal boundary without duplicating the next entity as a card.
5. Build adaptive Pulse primitives and transitions using Stage 04/09 tokens.
6. Provide empty, all-complete, unscheduled-only, syncing and offline variants.
7. Update Today widget summary only if it benefits its size class; do not force the
   entire in-app composition into RemoteViews.

## Edge scenarios

- No items; all completed; only missed; only habits; unscheduled inbox items.
- Current time after all planned work; tasks crossing midnight; timezone change.
- Long Persian date at 200%; device 24-hour preference if supported later.
- Projection still resolving while local entities are visible.

## Verification

- Source/tree/semantics search proves Orbit absent.
- Date/time vectors and next-boundary unit tests pass.
- Sparse/dense screenshots at all target compositions show reclaimed useful space.
- Real device recording proves minute update does not reset scroll or rebuild rows.

## Reject if

- Orbit is hidden only on phone but remains on tablet/Windows.
- Pulse repeats the same task already shown immediately below.
- Reclaimed space becomes empty padding or a generic metric-card collection.

## Local implementation checkpoint — 2026-08-14

- Deleted the production Orbit widget, its five authored ring files, generator and
  accessibility test. A source/asset contract test prevents a compatibility shell
  or hidden Orbit semantic from returning.
- Added one immutable daily `TodayPulseSnapshot` backed by projected task
  occurrences and habit-day summaries. Recurring lifecycle completion can never be
  misreported as today's completion; missed, partial, resolving, all-complete,
  habits-only, unscheduled-only and empty outcomes remain distinct.
- The compact phone composition owns live time, Gregorian/Jalali date, outcome,
  next boundary, Dayline and Plan only. Tablet/Windows recompose into three bounded
  columns; task titles and every mutation stay in the stream.
- The minute-aligned tick is injected and isolated to the Pulse. Today suppresses
  the header clock, removes the duplicate Plan/next-up/habit summary, preserves
  stream keys/scroll and keeps sparse content intrinsic instead of stretching a
  false empty panel.
- Short Inspector panes pin Edit while pairing Duplicate/Focus and render metadata
  as atomic label/value rows, so actions remain reachable without orphaning facts.
- All 14 refreshed workspace goldens were inspected after the final marker and
  Inspector corrections. `flutter analyze --no-pub` is clean and the full suite
  passes 449/449; the Stage 10 runtime and Stage 11 artifact verifiers pass.
- Preview build `1.1.0-preview+2064` installed over 2063 with
  `firstInstallTime=2026-08-02 19:20:44` preserved. Fresh phone, tablet portrait,
  tablet landscape and scrolled-last-item captures have zero app/Flutter fatal
  matches and are hash-locked in `runtime/android/runtime-manifest.json`.
- Local Windows compilation reaches the native notification plugin and stops only
  at the host's missing optional ATL header `atlbase.h`. Signed Windows build,
  install-over/LocalState continuity and the three-asset release remain mandatory
  exact-SHA hosted gates; no Stage 11 completion is claimed before them.

## Handoff

Stage 12 receives the Pulse height/content axis and projection outputs. Commit the
removal/replacement, run full affected tests/goldens, push/release and clean Git.
