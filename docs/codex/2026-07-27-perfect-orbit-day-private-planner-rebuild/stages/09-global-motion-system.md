# Stage 09 — Global route and microinteraction motion system

Status: externally closed on source checkpoint `6ca824ef2f0dd0b3facd66c194668381e81b88d1`
Depends on: Stages 04, 05, 07–08  
Primary surfaces: all pages, overlays, selectors, actions and responsive changes

## Mission

Make motion explain state and spatial relationship. Remove missing, default,
arbitrary and showy animations; establish a recognizable Perfect! rhythm that is
smooth on target hardware and complete under reduced motion.

## Mandatory preview, animatic and Copy entry gate

- Freeze `fnd-motion` plus storyboard IDs for route, title, footer/rail, composer,
  selector, status/log, sync, overlay, inspector, wizard and responsive resize.
- Every motion has first/mid/end/reverse/interrupted/background/reduced frames,
  semantic/focus timing and an explicit frame/resource budget before implementation.
- Compare synchronized reference animatic and real runtime recording, not only still
  endpoints; log spatial, temporal, opacity, curve, focus and hit-surface mismatches.
- A default framework animation or timing change must be named and reaccepted through
  the internal motion gate rather than silently replacing the storyboard.

## Motion vocabulary

- Route: subtle shared-axis based on destination order/spatial relation.
- Major title/hero: staged rise + fade once per meaningful entry, not every rebuild.
- Detail/editor: anchored fade/scale/short rise from the invoking context.
- Composer: shape/height morph with preserved draft/focus.
- Selection: color/shape/indicator interpolation without layout jump.
- Status/log: tactile press, arc/fill transition, tiny success response and Undo.
- Loading/sync: calm bounded progress; no perpetual decorative spinner.

## Work packets

1. Inventory every `Animated*`, route builder, popup, dialog, sheet, painter ticker,
   hover/press and implicit Material default.
2. Assign each to a semantic motion role or remove it.
3. Centralize duration, easing, distance and spring values by role and platform.
4. Prevent enter animations from replaying on sync/list notifier rebuilds.
5. Preserve scroll/focus/selection through AnimatedSwitcher and breakpoint morphs;
   avoid retaining expensive old/new glass subtrees beyond the transition.
6. Add pointer hover/focus/press states that complement—not duplicate—movement.
7. Define reduced-motion equivalents and test `disableAnimations` dynamically.
8. Record GPU/frame/memory evidence for composer, page switch, wizard and dense rows.

## Adjacent behavior audit

Inspect IME open/close, system back, route interruption, app background, resize,
error during transition, optimistic mutation rollback and repeated rapid taps.
Motion must never delay authorization/transaction logic or hide failure.

## Acceptance thresholds

- No unexplained direction reversal or element teleport.
- Required control becomes interactive when visually available.
- No double snackbar/sheet or duplicate write from taps during motion.
- No sustained jank or memory balloon on Android host renderer/Windows.
- Reduced motion keeps equal information and feedback without spatial animation.

## Reject if

- “Modern” is simulated by animating everything.
- A popup uses stock animation inconsistent with its spatial origin.
- Tests settle only by using arbitrary long delays.

## Implemented contract — 2026-08-13

- `PerfectMotion` now owns seven semantic roles, forward/reverse timing, curves,
  pixel-bounded travel, staged rhythm, calm loops and dynamic reduced-motion
  resolution. Raw presentation durations and curves outside that authority are
  rejected by an executable source contract.
- The workspace keeps all five destination states mounted but paints, focuses,
  hits and ticks only the selected one. A four-pixel isolated edge cue plus the
  selected navigation glyph communicate direction without translating or fading
  a glass-heavy viewport.
- Major page titles receive one ten-pixel rise/fade per meaningful destination
  entry. Sync/list/controller rebuilds do not replay it. Today deliberately avoids
  cascading Orbit, next-up and every agenda row.
- Every production dialog now enters from its invoker through one focus-trapped
  fade/scale/rise route and restores invocation focus. Sheets, popup menus,
  inspector, wizard, capture, AI, selector and log surfaces use the same vocabulary.
- Quick Capture, Sync and Orbit tickers pause when reduced, offstage or backgrounded;
  lifecycle resume restarts from current durable truth rather than stale animation
  progress.
- Eleven deterministic first/mid/end/reverse/interrupted/reduced storyboards and a
  131-record implementation inventory are generated and hash-verified. Nine real
  runtime artifacts are independently hashed by the profile summary/verifier.

## Local gate

- `flutter analyze`: pass, no issues.
- full Flutter suite: pass, 432/432.
- focused motion suite: pass, 19/19.
- Workspace regression: pass, 60/60; Header/Sync regression: pass, 10/10.
- Android profile `1.1.0+2060`: build and `adb install -r` pass; sibling preview
  `firstInstallTime=2026-08-02 19:20:44` remained unchanged.
- Real workspace samples keep Flutter build work below 16.67ms. Absolute emulator
  raster smoothness is intentionally inconclusive because the minimal same-package
  control also exceeds 16.67ms; physical Android and Windows no-jank remain open.
- Local Windows compile reaches the plugin build and then fails because this host
  lacks ATL `atlbase.h`; the official Windows runner is the mandatory closure gate.

Full evidence and proof boundaries are recorded in `../09-stage-verification.md`.

## Handoff

Stage 10 receives stable motion tokens for theme-state transitions. Branch run
`31663309577` attempt 2 and trusted main run `#54` / `31664886708` close the exact
source SHA; release `v1.1.0-build.2054` contains exactly APK, Portable ZIP and Setup.
Physical-target no-jank remains a later runtime gate rather than a hosted-build claim.
