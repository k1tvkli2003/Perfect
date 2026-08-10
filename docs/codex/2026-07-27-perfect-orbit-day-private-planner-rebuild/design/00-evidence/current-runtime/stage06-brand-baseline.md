# Stage 06 brand runtime baseline

Frozen: 2026-08-10
Runtime: Pixel emulator, Android 15 / API 35, 1080x2400
Package: `com.k1tvkli2003.perfect`, version `1.1.0` (`2037`)
Purpose: adversarial visual and asset baseline before any Stage 06 mutation

## Why this baseline exists

The focused source tests pass 23/23, yet the installed product still has a
visibly broken splash identity and unsafe small-size derivatives. Passing
structural tests is therefore not an acceptance signal for this stage. The
master, every surface-specific derivative and the installed result must agree
at comparable visible bounds.

## Frozen runtime evidence

| File | Pixels | SHA-256 | Evidence |
| --- | ---: | --- | --- |
| `stage06-brand/android-home-before.png` | 1080x2400 | `233663f8dc525e25e48972e5208c97d672b86e2ced7ca81801df81e4a40b9fcf` | Home-screen launcher treatment and OS mask context. |
| `stage06-brand/android-app-drawer-before.png` | 1080x2400 | `d6978d2c13b25814877aae8e5132b591374fe1b11d2f2eccd7ab3304bfdd0514` | App-drawer scale, quiet plate and label relationship. |
| `stage06-brand/android-splash-before.png` | 1080x2400 | `9c0311e2b42e2a6d99bddcdcc682509cf72fb5541990453666b3cdfd720b693c` | Android 12+ splash visibly clips and enlarges the petals into a circular disk. |
| `stage06-brand/android-first-frame-before.png` | 1080x2400 | `26d2452242e20579ab6631f9d4aa1494a853d7efb4548a1164c2876a478f9866` | First Flutter frame and auth/header brand scale. |

## Asset measurements before mutation

- Canonical 512px raster: alpha bounds `[43, 8, 468, 504]`, visible fraction
  `0.5209`, seven connected visible components, SHA-256 prefix `43a534`.
- Selected concept source: SHA-256
  `10280e3c4fae3b80bafdc8df35bcf26d75653566c7b9670fc6ca2462801dce77`.
- The 36px Android widget derivative touches all four canvas edges at mdpi.
- Several 16-32px Windows ICO frames touch every canvas edge.
- The current wordmark SVG contains live `<text>` rather than final authored
  vector paths.

## Adversarial findings

| ID | Severity | Finding | Required closure |
| --- | --- | --- | --- |
| `B06-01` | P1 | Android 12+ splash uses the widget drawable as its animated icon. The system mask turns the mark into an oversized clipped disk. | Create a dedicated 288dp splash composition whose visible mark remains inside the 192dp no-background safe circle; inspect the installed splash. |
| `B06-02` | P2 | One raster is reused across launcher, splash, widget and Windows despite incompatible masks and viewing sizes. | Generate explicit per-surface derivatives from one checksum-pinned geometry source. |
| `B06-03` | P2 | Widget and small ICO frames touch their alpha bounds, so antialiasing and silhouette are clipped or visually crowded. | Require deterministic transparent perimeter and per-frame small-size tuning. |
| `B06-04` | P2 | Native widget headers combine a raster mark with ordinary `Perfect!` text, diverging from the authored wordmark and risking duplicate semantics. | Use a dedicated native wordmark asset or one combined accessible brand group. |
| `B06-05` | P2 | Night splash inherits the light splash background and no explicit high-contrast mark/wordmark path exists. | Generate and wire light, dark and high-contrast variants without changing brand geometry. |
| `B06-06` | P2 | The authored wordmark source is not path-final; renderer/font availability can change the identity. | Generate path-based SVG masters and deterministic raster fallbacks. |
| `B06-07` | P3 | ICO frames are naive downscales of one canvas. The smallest frames lose optical breathing room and clarity. | Emit and validate individually padded frames at 16, 20, 24, 32, 40, 48, 64, 128 and 256px. |

## Platform constraint already proved

Pixel Launcher normalizes a fully transparent adaptive-icon background to a
black plate. The Android adaptive icon may therefore retain a quiet pastel
platform-safe background layer. This is not permission to bake a box into the
mark or reuse that plate on Windows, widgets, splash art or in-app identity.

## Acceptance delta

Stage 06 is accepted only after the same installed host shows an uncropped
splash, readable masked launcher icon and clean widget brand; Windows must show
the unplated mark in Explorer/taskbar/installer contexts. Source tests alone
cannot close any visual finding above.
