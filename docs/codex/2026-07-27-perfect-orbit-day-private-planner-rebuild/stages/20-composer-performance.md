# Stage 20 — Composer motion, layout and performance hardening

Status: pending  
Depends on: Stages 16–19  
Primary surfaces: all composer modes under real viewport/input constraints

## Mission

Turn the authored composer into a reliable high-frequency instrument. Eliminate
double-painted glass, jank, state loss, keyboard obstruction and excessive memory
while preserving the intended morph and visual craft.

## Mandatory preview/Copy preservation gate

- Use the complete frozen `cap-*`, `ai-*`, `voice-recorder` and composer page/motion
  registry as a non-regression contract while changing layers/state ownership.
- Capture pre-optimization reference/runtime pairs and post-optimization runtime at
  identical fixture, viewport, renderer and frame index; optimization cannot flatten
  blur, alter geometry or remove authored states without reopening Stage 04–05.
- Compare layer tree, hit/semantic tree, synchronized motion and final pixels along
  with frame/memory metrics; a faster visually weaker shell is not accepted.
- Stress closed/open/IME/long-proposal/resize/background states and verify drafts,
  focus, scroll and operation IDs survive every optimized transition.

## Work packets

1. Profile widget rebuilds, layers, saveLayer/BackdropFilter, raster time and memory
   for collapsed heartbeat and every mode transition.
2. Ensure inactive modes preserve only necessary state while remaining offstage,
   unfocusable and unpainted; avoid keeping two expensive blurred surfaces alive.
3. Bound open height by usable viewport/IME and give conversation/proposal its own
   scroll rather than overflowing the page.
4. Ensure body/list bottom inset tracks actual visible composer/footer height without
   jumping scroll or leaving a permanent blank bar when closed.
5. Coalesce rapid mode requests and block duplicate writes during transition.
6. Stop timers/recording/animations on lifecycle changes according to explicit rules.
7. Verify Android host renderer and Windows high-DPI; document unsupported emulator
   renderer separately rather than misclassifying product behavior.
8. Tune blur fallback for low-end GPU/high contrast/reduced transparency if exposed.

## Stress sequences

- 20 collapsed heartbeats; 20 open/close cycles; Task↔Plan↔AI↔Voice rapid switch.
- IME open/close while resizing and rotating; long proposal at 200% text.
- Background/resume during send/record; offline retry; navigation away and back.
- Dense Today list scroll underneath transparent floating launcher.

## Acceptance budgets

Set evidence-based budgets from Stage 05 baseline for p95 build/raster, frame misses,
working set growth and retained layers. No unbounded growth or responsiveness loss
is accepted even if one emulator mode is known-bad.

## Upgrade milestone

Install signed N, preserve Task draft, AI conversation, selected theme and local
planner data, then update to N+1 and verify continuity with same package/signature.

## Reject if

- Visual smoothness exists only with blur disabled everywhere without design fallback.
- Closed composer still reserves or paints a full-width surface.
- `pumpAndSettle` succeeds but real repeated interaction stalls/crashes.

## Handoff

Stage 21 receives stable bottom/IME behavior for full-screen wizard transitions.
Commit/push/release with performance and signed-upgrade evidence; clean Git.
