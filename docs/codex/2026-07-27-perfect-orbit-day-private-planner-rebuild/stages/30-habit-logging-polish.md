# Stage 30 — Habit logging feedback, ergonomics and upgrade proof

Status: behavior-complete, committed as 7b1f0b0 (pushed to feat/stage13-status-undo, PR #4, 2026-09-25) — primary-tap/Undo geometry, compact correction, tooltip
contracts, and controller/widget gesture suites are GREEN; celebration,
haptics/rebuild profiling, accessibility announcements, parity matrices, and
signed N→N+1 upgrade remain open
Depends on: Stages 14, 27–29  
Primary surfaces: Today/Habits/detail/widget logging interactions

## Mission

Polish high-frequency habit logging until it is fast, tactile, visually distinctive
and reliable under stress. Animation may reward progress but must never slow the next
tap, move controls or obscure correction.

## Mandatory preview/animatic and Copy gate

- Use the frozen method controls, `habit-streak-receipt`, `game-reward-receipt` and
  their press/increment/target/over-target/Undo/error motion IDs as exact references.
- Compare synchronized real-device recordings to first/mid/end animatics while also
  tracking hit-target coordinates, rebuild scope, frame time and haptic setting state.
- Every reduced/no-motion frame is a separate accepted variant, not a global animation
  disable that removes progress/error information.
- Polish may change no occurrence semantics or derived streak truth; every visual
  optimization reruns app/widget/detail parity and Copy diffs.

## Feedback system

- Press: immediate scale/light response inside fixed bounds.
- Increment: arc/value interpolates and a small additive trace confirms exact delta.
- Target crossing: one restrained pastel bloom/streak spark plus accessible success.
- Over-target: calm continuation, no repeated celebration.
- Undo/correction: clear reversal response without punitive animation.
- Error rollback: value visibly returns with concise reason/retry; draft/history safe.
- Reduced motion: immediate value/color/state plus announcement, no movement.

## Ergonomics

- Thumb target separated from row navigation and vertical scroll arbitration.
- Long press threshold does not trigger during ordinary slow scroll.
- Correction remains reachable one-handed; desktop uses hover/context/keyboard parity.
- Repeated actions keep pointer/finger target stationary.
- Haptic/audio feedback is optional, platform-appropriate and setting-controlled.

## Performance and rebuild containment

Profile per-row notifier/selectors so one habit log does not rebuild Today, Pulse,
footer and unrelated rows. Bound animations/tickers and stop them offscreen/background.
Validate local store query and widget update cost for rapid logging.

## Signed upgrade milestone

Install signed N; create each tracking method, multiple logs, streak/freeze, pending
offline operation and placed widget. Update to signed N+1 and prove session, local
history, operation IDs, streak derivation, widget and settings survive.

## Verification

Gesture-arena tests; animation/reduced-motion tests; per-row rebuild/frame metrics;
rapid device recording; dark/high contrast; accessibility announcements; app/widget
parity; signed upgrade artifact/install evidence.

## Reject if

- Celebration blocks input, moves target or causes list scroll jump.
- One log refreshes/re-enters the entire page.
- Upgrade proof omits pending operation or occurrence history.

## Handoff

Stage 31 receives trustworthy status/log APIs and history. Commit/push/release with
performance and signed-upgrade proof; clean Git.

### Evidence — 2026-09-25 (real runs, Stage 30 partial)

- `flutter test --no-pub
  test/presentation/planner_workspace_controller_test.dart
  test/presentation/today_pulse_test.dart
  test/presentation/perfect_workspace_page_test.dart` —
  **EXIT:0, 133 pass**, including boolean/count/numeric/duration/checklist
  primary taps, one-tap Undo, `-1`/set-exact/reset correction, tooltip copy,
  and desktop context/keyboard rows.
- Celebration choreography, rebuild containment, announcement semantics,
  dark/high-contrast interaction parity, widget parity, real-device recording,
  and signed upgrade artifacts remain open.
