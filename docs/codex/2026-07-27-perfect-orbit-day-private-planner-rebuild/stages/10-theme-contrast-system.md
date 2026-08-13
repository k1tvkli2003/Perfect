# Stage 10 — Complete light, dark and high-contrast surface system

Status: local implementation and Android runtime verified; exact-SHA hosted closure pending
Depends on: Stages 04–09  
Primary surfaces: entire app, native system chrome, widget and installer previews

## Mission

Treat dark/high-contrast as authored products, not transformations of light mode.
Every live text, SVG, ring, painter, blur and system surface must remain legible,
balanced and recognizably Perfect!.

## Mandatory preview and Copy entry gate

- Freeze `fnd-color-roles`, `fnd-material`, `fnd-focus-a11y` and dark/high-contrast
  variants for every canonical component/page in the Stage 04–05 registries.
- Produce matching contact sheets for empty and dense phone/tablet/Windows surfaces;
  inspect live text, SVG, ring, focus, status, blur, native widget and system chrome.
- Compare normalized reference/runtime captures and measured contrast together;
  automated ratios do not certify hierarchy, muddy glass or weak pastel separation.
- No later component may invent an unregistered raw color; intentional authored-asset
  variants carry stable IDs and consumer lists.

## Work packets

1. Inventory hardcoded colors, asset fills, painter colors, opacity stacks, shadows,
   system bar styles, widget colors and native Android/Windows resources.
2. Map each to a semantic role; eliminate direct light-only values in reusable UI.
3. Author dark palette with preserved pastel identity, controlled luminance and
   neutral separation; do not wash every surface with one purple/cream tint.
4. Author high-contrast overrides for text, focus, boundaries, status and progress.
5. Tune blur tint/stroke/shadow independently per theme so glass remains spatial,
   not muddy or low-contrast.
6. Audit SVGs for theme-aware variants or sufficient contrast; create variants
   where recoloring would damage authored art.
7. Style keyboard/selection/caret, dialogs, menus, snackbars, date/time pickers,
   notifications, splash and native widget consistently.
8. Ensure theme switch preserves route, scroll, focus, draft and running timers.

## Visual matrix

Capture every primary page and modal in empty/dense states, phone/tablet/Windows,
light/dark/high contrast. Inspect text on colored chips, disabled actions, focus
rings, progress arcs, sync states, errors and mixed Persian typography.

## Accessibility/performance gates

- Contrast is measured for required text/actions and supported by non-color cues.
- No dark-mode text disappears on a painter/authored asset.
- Theme change causes no full data reload or visible flash of the wrong theme.
- Blur and shadows remain within raster budget on target devices.

## Upgrade milestone

Install signed build N, set dark theme and create local/session markers; update to
N+1 with same identity and verify theme, session, records and pending queue remain.

## Reject if

- Screens merely avoid black-on-black but remain visually flat or muddy.
- Hardcoded reference colors survive in a shared live component.
- Native widget/splash contradicts in-app theme/identity.

## Handoff

Stage 11 receives final surface tokens. Commit/push/release, attach theme and signed
upgrade evidence, update docs and leave a clean main-only state.
