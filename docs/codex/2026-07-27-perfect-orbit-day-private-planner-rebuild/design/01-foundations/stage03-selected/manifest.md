# PS01 deterministic direction manifest

Direction: `PS01 Perfect Day Instrument`
Frozen: 2026-08-10
Canonical scope: Stage 03 direction, identity, shell, workflow, state, motion and
typography handoff only
`textEmbeddingMode`: `single_render_native`

The SVG source is the deterministic specification and the PNG is its first-pass
raster inspection. Text, identity assets and interface geometry are authored in the
same source before rasterization. No text overlay, generative repair, crop, resize,
color correction or post-render recomposition is allowed.

## Exact identity inputs

| Local file | Canonical source | SHA-256 | Contract |
| --- | --- | --- | --- |
| `day-compass-transparent-512.png` | `assets/brand/perfect-launcher.png` | `43a5344bc25ce9c3a3562153c4667a6f49d9652209345ff6bcba25d4607c5728` | Exact selected transparent Day Compass mark; no baked tile |
| `perfect-wordmark.png` | `assets/brand/perfect-wordmark.png` | `89a010f6d60f414c144045f2aeddd81a023b4e9cd9bf67c7262a77813a06e87b` | Exact selected light-canvas wordmark image |
| `perfect-wordmark-dark.png` | `assets/brand/perfect-wordmark-dark.png` | `3a5eefc491e2e1bb9ef51ecd279d3c8d1016f00a11abe3bf3ed0b72af3e3a0cf` | Exact selected dark-canvas wordmark image |

The copied bytes are identical to their canonical sources. Stage 04 may derive
platform-safe expressions, but may not redraw, regenerate or live-font-substitute the
selected mark/wordmark.

## Frozen plates

| Plate ID | Source / SHA-256 | Raster / SHA-256 | Pixels | Original-size inspection |
| --- | --- | --- | ---: | --- |
| `ps01-identity` | `identity-plate.svg` / `2bf3191e837339e6759b99bf2965ae4574ba707a1657e67d2b51e43527ed093e` | `identity-plate.png` / `12bafa435bdd651b8daae51cbf2afef61307fe08a7dc8a7a7ec885e41ce97b7e` | 1600x1000 | passed: exact wordmark/mark, transparent master, 16–96 px ladder, semantic pastel/status independence and dark expression remain legible |
| `ps01-shell` | `shell-plate.svg` / `dedadea47cce363f4c9e2395169b39a7fe95a5ffeb160fc9ac6dfe0213f3dd7a` | `shell-plate.png` / `ca725184ccee3c8212a5d1223af1eec5fd25f9fd15531975e096fac1ae8bdff6` | 1800x1100 | passed: phone, tablet and Windows are distinct compositions; footer is icon-only; capture has no backing strip; vector navigation and attached Sync cloud are aligned |
| `ps01-workflow` | `workflow-plate.svg` / `0ff5d5aa36fb431bae0bf51688d1f802dd8c33146da55c530d420d0e1837e758` | `workflow-plate.png` / `2923dd93d057e2d41aa5cd7f7b8ed46da654141f917451703c557a13208f1c48` | 1600x1000 | passed: named adaptive wizard, one morphing capture surface, view-first detail/edit separation and six method-specific habit controls fit without overlap |
| `ps01-state` | `state-plate.svg` / `62830af80068e0bbbc77f2a9dce243e426f7b13ed5229ee75c850e0b7fd2395a` | `state-plate.png` / `bc3bfa11fbb9d087176c311b19ba78dbc67c867c796b22e59bd187f3933c712d` | 1600x1000 | passed: Sync labels do not rely on color; outcome geometry is stable; focus/IME and empty/offline/conflict/provider-error recovery are explicit |
| `ps01-motion` | `motion-plate.svg` / `a7bfcd54a7fb01844227f3715d0a5f184ef16efa17801c63b52f327cdd28f1f1` | `motion-plate.png` / `1ab70bd924844c3ca5669ff0653ef222986f574377b2ef7c106b6697c422aae7` | 1600x920 | passed: title rise, status receipt, capture morph, sync/breakpoint continuity and reduced-motion replacements have explicit frames/timing |
| `ps01-typography` | `typography-plate.svg` / `133a8d4e5d91417b09c027a560fdf93c0b5ef1e30990145abdf9cb613529031a` | `typography-plate.png` / `e95a59be18dc6ac6f2427d2e939a6e2ba93a5e72415faa9164c9d65ee5d2dd6f` | 1600x1000 | passed: wordmark is raster identity; live Latin/Persian/mixed bidi, dual date and 200% recomposition remain whole and inside bounds |

## Deterministic render

Renderer: `tool/render_design_svg.cjs`
Browser selection: `PERFECT_DESIGN_BROWSER`, installed Microsoft Edge, installed
Chrome, then Playwright-managed Chromium
Device scale factor: 1

Example:

```powershell
$env:NODE_PATH='C:\Users\K1\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\K1\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' `
  tool\render_design_svg.cjs `
  docs\codex\2026-07-27-perfect-orbit-day-private-planner-rebuild\design\01-foundations\stage03-selected\shell-plate.svg `
  docs\codex\2026-07-27-perfect-orbit-day-private-planner-rebuild\design\01-foundations\stage03-selected\shell-plate.png `
  1800 1100
```

Re-rendering any frozen source changes the raster hash and reopens original-size
inspection. A later canonical component/page preview receives its own version/hash;
it must not silently overwrite these direction plates.

## Inspection boundary

- All six PNGs were inspected at original size after the last render.
- Embedded Persian is carried in XHTML `foreignObject` blocks with explicit RTL and
  isolated LTR spans where browser bidi anchoring would otherwise clip or reorder it.
- The plates specify the visual/behavior system; they do not claim runtime hover,
  screen-reader, keyboard, jank, installation or device proof.
- The eight ImageGen finalist boards remain noncanonical `model_native` evidence in
  `../../00-evidence/references/finalist-boards/manifest.md`.
- Stage 04 decomposes these relationships into individual foundation/component
  contracts. Stage 05 freezes complete page targets before production UI mutation.
