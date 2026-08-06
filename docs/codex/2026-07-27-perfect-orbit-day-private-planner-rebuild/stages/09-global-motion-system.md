# Stage 09 — Global route and microinteraction motion system

Status: pending  
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

## Handoff

Stage 10 receives stable motion tokens for theme-state transitions. Commit motion
tests, recordings and code; push/release and leave clean `main`.
