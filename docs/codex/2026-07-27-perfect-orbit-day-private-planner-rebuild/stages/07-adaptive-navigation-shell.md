# Stage 07 — Adaptive navigation shell

Status: pending  
Depends on: Stages 04–06  
Primary surfaces: phone footer, tablet/Windows rail, page host, shortcuts

## Mission

Build one coherent shell whose composition changes by interaction context. Phone,
tablet and Windows must feel native to their input/space without losing route,
draft, selection, focus or scroll state.

## Mandatory preview and Copy entry gate

- Bind implementation to `sh-page-canvas`, `sh-phone-footer`,
  `sh-footer-destination`, `sh-tablet-rail`, `sh-windows-rail`, `sh-rail-toggle`,
  `sh-page-scroll-frame`, `sh-pane-divider` and every `pg-shell-*` preview.
- Preview default/hover/focus/pressed/selected, collapsed/expanded, short-height,
  200% mixed text and continuous breakpoint transition frames before code.
- Capture the same route/fixture at phone, tablet and Windows runtime; compare
  `reference | runtime | overlay/diff` including outer hit bounds and negative space.
- A platform reflow is valid only when its rule is already in the frozen composition
  manifest and route/draft/focus/scroll state remains equivalent.

## Fixed decisions

- Phone uses a floating icon-only glass footer; labels remain in semantics/tooltips.
- Selected destination is a compact prismatic tile/light field, not Material's
  stock oversized oval and not a redundant checkmark.
- Tablet starts with a compact icon rail and can expand when constraints permit.
- Windows remembers the owner's rail width choice and provides keyboard shortcuts.
- Today alone owns the capture instrument; other pages do not reserve its space.

## Work packets

1. Extract a persistent page-state host so navigation does not recreate filter,
   scroll, calendar, detail selection or capture draft unnecessarily.
2. Define content-driven transitions among footer, compact rail and expanded rail;
   test intermediate resize rather than three isolated widths.
3. Rebuild footer geometry: equal destination hit zones, optical icon centering,
   selected accent, safe-area spacing and content-visible background.
4. Rebuild rail geometry: mark/wordmark, collapse affordance, selected state,
   tooltip, focus order and short-landscape scroll.
5. Normalize Ctrl+1…5, arrow/focus traversal, Escape behavior and pointer hover.
6. Remove stale three-dot menus and duplicate sign-out/shortcut surfaces; place
   secondary commands in More/settings where they belong.
7. Preserve open detail/AI/capture state intentionally when navigation changes;
   close only contexts whose scope would become misleading.
8. Ensure final list actions remain reachable above/behind floating surfaces.

## Adjacent-surface audit

Check auth return, deep links, widget navigation, notification navigation, editor
return, detail return, AI open/close, IME and feedback overlay. Every route must
restore the correct shell destination and focus owner.

## Motion contract

- Page content uses direction-aware shared-axis movement with subtle title rise.
- Footer selection glides/fades without moving other icons.
- Rail resize interpolates width/content without text clipping or focus loss.
- Reduced motion swaps movement for immediate state plus short opacity change.

## Verification

Continuous resize recordings; touch/mouse/keyboard navigation; RTL and 200% text;
short landscape; semantics uniqueness; final-row reachability; frame timings.

## Reject if

- Footer/rail merely fits but feels oversized, sparse or generic.
- A breakpoint rebuild drops state or shifts the active route.
- Invisible dock bounds intercept content outside the visible glass.

## Handoff

Stage 08 receives a stable header slot and shell geometry. Commit/push/release with
goldens for every layout class and leave only clean `main`.
