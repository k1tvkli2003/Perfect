# Stage 14 — Effortless inline habit logging

Status: pending  
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

## Handoff

Stage 15 receives optimistic/loading/error states for these controls. Commit/push/
release with occurrence proofs and clean Git.
