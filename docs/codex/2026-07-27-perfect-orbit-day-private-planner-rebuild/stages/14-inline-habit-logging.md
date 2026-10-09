# Stage 14 — Effortless inline habit logging

Status: behavior-complete, committed as 7b1f0b0 (pushed to feat/stage13-status-undo, PR #4) — controller + workspace suites GREEN (43 + 97 = 140 pass, exit 0, 2026-09-25); native/device, Android widget parity, preview and cross-consumer acceptance pending; CI workflows disabled_manually so no fresh remote run
Depends on: Stages 12–13 and existing habit domain contracts  
Primary consumers: Today, Habits, Detail and Android widget

## Mission

Make daily habit logging easier than opening a form. The row adapts to the tracking
method so one tap performs the most likely safe action while correction remains
fast, reversible and discoverable.

## Mandatory preview and Copy entry gate

- Freeze `habit-row`, all `habit-control-*`, `habit-day-state`, `habit-week-strip`,
  `habit-streak-receipt`, `habit-recovery-preview` and their Today/Habits/detail/
  widget neighbor plates.
- Preview initial, pressed, rapid-pending, partial, target crossing, over-target,
  correction, Undo, offline, conflict, error and reduced-motion states for each method.
- Implement from one method-aware contract; compare stills and recordings so additive
  feedback, stationary hit geometry and rapid-tap serialization match the reference.
- Visual success is rejected if the durable occurrence result or cross-consumer state
  differs; Copy and function evidence are paired for every method.

## Tracking-specific interaction

### Boolean/check habit

- One tap toggles today's completion; immediate Undo appears.
- Visual uses the fixed Stage 13 geometry and a habit-specific success accent.

### Count habit / multiple times per day

- Primary control is `+1`; current/target appears adjacent without tiny text.
- Rapid taps accumulate atomically/serially with tactile visual feedback.
- Long press, secondary click or an adjacent correction affordance opens a compact
  `−1 / set exact / reset today` surface. Never require full editor.

### Duration or numeric value

- One tap adds an owner-relevant recent/default increment shown before activation.
- Tapping the value opens a compact numeric/time entry surface with unit and target.
- Invalid/negative/out-of-range input never clears the previous value.

### Checklist habit

- Row shows completed/total and the next remaining item affordance.
- Tap may complete the next item; detail/log sheet exposes explicit item selection.
- Habit success follows configured `all/at least/value` rule, not naive item count.

### Formula habit

- Inline action uses only validated variables/inputs; formula evaluation errors are
  visible and non-destructive.

## Data and concurrency rules

- Each tap is an idempotent owner-scoped occurrence mutation through the same
  local-first queue used by app/widget/AI.
- Serialize rapid local mutations per habit/day; merge remote updates without
  losing increments or double-applying widget outcomes.
- Day key is computed from the owner's local timezone contract, not raw UTC date.
- Undo writes an inverse/correction event without erasing unrelated history.

## UX feedback

- Progress arc/value animates within fixed geometry; no page refresh or row jump.
- Reaching target triggers restrained success + streak response; over-target remains
  valid and does not repeatedly celebrate.
- Reduced motion uses immediate value/state and accessible announcement.

## Edge scenarios

Rapid 20-tap burst; app background mid-burst; offline; widget and app increment
concurrently; target change during day; reset; timezone midnight; archived habit;
formula error; 200% text and one-handed scroll proximity.

## Verification

Domain/concurrency tests for every method; UI gesture and correction tests; widget
parity; exact local/remote occurrence values; frame/rebuild count; light/dark state
sheet; real-device repeated-tap recording.

## Reject if

- Count habit still opens a sheet for every increment.
- Logging rebuilds/refreshes the whole page or loses a rapid tap.
- Correction deletes durable history without explicit scope.

## Evidence — 2026-09-25 (integrated Stage 14 gate, real runs)

`C:/Users/K1/AppData/Local/Temp/perfect-stage14-integrated-20260925e.log`
(`controller + workspace page + Pulse suites`): **EXIT:0, 127 pass**.
Count/numeric contract fixed at both layers: a `count` primary tap always
adds `+1` (`Add one`, `Subtract one`) even when a correction `step` exists,
while `numeric` follows its configured step/unit in the primary tooltip,
menu label, and durable amount. `flutter analyze --no-pub`: no issues;
`git diff --check`: clean.

### Stage 15 in-progress evidence — 2026-09-25 (local-source retry, real runs)

`flutter test --no-pub
test/presentation/perfect_workspace_page_test.dart
--plain-name "Today local-source retries without destructive reset"
--reporter expanded`: **EXIT:0, 1 pass** (`TODAY_PROJECTION_READ_FAILED`
printed inline as proof the injectable local read actually failed before the
UI retry recovered).

`flutter test --no-pub
test/presentation/planner_workspace_controller_test.dart
test/presentation/today_pulse_test.dart
test/presentation/perfect_workspace_page_test.dart
test/ai/perfect_ai_dock_test.dart
test/presentation/planner_editor_test.dart
test/presentation/interaction_route_inventory_contract_test.dart
test/presentation/planner_secondary_surfaces_adaptive_test.dart
test/presentation/stage11_today_pulse_contract_test.dart
test/presentation/task_status_control_test.dart
test/presentation/focus_session_sheet_test.dart
test/presentation/stage09_global_motion_system_test.dart`: **EXIT:0, 198 pass**
(integrated Stage 14 + Stage 15/16/17/18/19/20/21/31/32/34/40 gate; collapsed
64dp orb geometry, quick capture exactly-one local receipt plus Undo,
failed-save draft retention, Plan-mode draft/kind routing, AI proposal
review boundary, wizard continuity, local-first route contract, secondary
dialog parity, Pulse contract, task status control, focus session, and
motion vocabulary are proven by
`collapsed capture is only a 64dp circle above the footer`,
`quick capture writes exactly one local task with undo`,
`quick capture failure keeps the draft with local recovery`,
`Plan mode preserves task draft and routes exact habit kind`,
`text answer becomes history and a proposal requires Apply`, and the
`habit-correction-dialog` now routes through `showPerfectDialog`).
`flutter analyze --no-pub`: no issues; `git diff --check`: clean.

`C:/Users/K1/AppData/Local/Temp/perfect-stage14-integrated.log`:
`flutter test --no-pub
test/presentation/planner_workspace_controller_test.dart
test/presentation/perfect_workspace_page_test.dart` — **EXIT:0, 112 pass**
(every Stage 14 method slice GREEN on first integrated attempt;
only stdout noise is an in-test second `PlannerDatabase.memory()`
drift multi-open warning).
Prior sqlite crashes (`flutter_18-21.log`) were infra-only
(`sqlite3.dll` errno 5 delete lock), not product failures.

## Handoff

Stage 15 receives optimistic/loading/error states for these controls. Commit/push/
release with occurrence proofs and clean Git.
