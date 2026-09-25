# Stage 28 — Multiple-per-day habits and atomic accumulation

Status: behavior-complete, committed as 7b1f0b0 (pushed to feat/stage13-status-undo, PR #4, 2026-09-25) — 20-operation concurrent count accumulation, serialized
row logging, Undo/correction scopes, and over-target retention are GREEN;
two-device offline sync convergence and native widget/device recording remain
open
Depends on: Stages 14, 27 and local operation contracts  
Primary surfaces: Today/Habits rows, compact correction, detail day log, widget

## Mission

Make “do this several times today” effortless and exact. Logging should feel like a
tally instrument, not repeated navigation into forms, while concurrent app/widget/
device actions never lose or duplicate increments.

## Mandatory preview and Copy entry gate

- Freeze `habit-control-count/duration/numeric`, `ct-count/value/time-stepper`,
  `pg-habit-multiple-daily`, compact correction and app/widget neighbor plates.
- Preview 0/target, partial, rapid pending queue, target crossing, over-target,
  decrement, set exact, reset, Undo, offline/conflict/error and reduced-motion states.
- Compare stationary hit geometry and time-synchronized additive feedback in real
  runtime while a deterministic 20-operation fixture proves the displayed total.
- App, widget and detail may recompose for space but must share value, operation IDs,
  correction semantics and accepted visual-state language.

## Domain decisions

- Distinguish daily target quantity from recurrence eligibility. “8 glasses today”
  is one daily habit with count target, not eight generated task entities.
- Each quick action carries operation ID, entity/day key, delta/value, method version,
  source and timestamp; application is idempotent.
- Local mutation serialization occurs per owner/entity/day. Server reconciliation
  applies commutative deltas or explicit set operations with conflict semantics.
- Over-target is retained as real data; success threshold does not clamp history.

## Inline UX

- Primary `+1`/preset area is large, thumb-safe and visually connected to value/target.
- Each successful tap updates immediately and produces a tiny additive response,
  never reopening/refreshing the row.
- Undo reverses the exact last local action. Compact correction offers −1, set exact,
  reset today and history only after explicit activation.
- Haptics where appropriate; pointer/keyboard equivalents (`+`, `-`, Enter) on Windows.
- Target reached celebrates once per crossing; decrement below target re-arms crossing.

## Multiple schedules/windows

If the habit intentionally has morning/afternoon/evening instances, represent windows
as planned guidance linked to the same daily total unless distinct history is required.
UI shows remaining total and optional window context without eight rows of clutter.

## Stress/edge scenarios

20 rapid taps; alternating +/−; app killed after local write; widget/app simultaneous;
two devices offline then sync; reset versus pending deltas; midnight/timezone change;
target/method edit during day; over-target; archived habit and auth expiry.

## Verification

Property/concurrency/idempotency tests; exact operation ledger totals; app/widget parity;
rapid real-device interaction recording; no full page rebuild; undo/correction scopes;
detail/calendar reflects exact accumulated value after sync convergence.

## Reject if

- Multiple-per-day habit requires separate tasks or a sheet per increment.
- A rapid tap is dropped, duplicated or applied to wrong local day.
- Reset erases unrelated historic days or races pending deltas silently.

## Handoff

Stage 29 consumes accurate daily outcomes for streak/recovery. Commit/push/release
with concurrency and device evidence; clean Git.

### Evidence — 2026-09-25 (real runs, Stage 28 partial)

- `flutter test --no-pub
  test/presentation/planner_workspace_controller_test.dart` —
  `20 concurrent count taps preserve every increment offline`: 20 serialized
  increments converge on one daily occurrence with operation IDs intact.
  Covered inside the **EXIT:0, 133 pass** integrated controller/Pulse/workspace
  gate.
- Row/correction/Undo scopes (`count habit correction subtracts one`,
  `measured habit edits one daily total`, habitual Undo toast) and over-target
  retention are in the same GREEN suite.
- Widget/app parity, cross-device offline convergence, native recording, no
  full-page rebuild profiling, and post-sync detail totals remain open.
