# Stage 06 — Brand assets and installed identity

Status: pending  
Depends on: Stages 01–05  
Primary surfaces: splash, auth, app header/rail, launcher, widget, Windows shell

## Mission

Make Perfect! unmistakable and technically correct from the OS launcher through
the last in-app surface. Fixing an in-app mark while Android splash, Windows ICO
or widget crop remains weak is failure.

## Mandatory preview and Copy entry gate

- Freeze `id-perfect-mark`, `id-perfect-wordmark`, `id-launcher-android`,
  `id-splash-android`, `id-icon-windows` and `id-widget-brand` from
  [preview-production-gate.md](preview-production-gate.md) before editing assets.
- Each preview includes transparent bounds, optical center, mask/safe-zone, small-size,
  light/dark/high-contrast, DPI/density and platform-context contact sheets.
- Implement only from the asset/decomposition manifest; compare master, generated
  resource and installed OS screenshot at identical visible bounds.
- Any material crop, scale, color or geometry delta reopens the internal preview gate;
  it is not accepted as a platform quirk without evidence.

## Product decisions

- The selected six-part symmetric pastel mark with dark center is authoritative.
- The selected custom Perfect! typography is an authored asset/wordmark, not a
  normal font approximation in the product identity position.
- App icon background is transparent wherever the platform permits; adaptive
  Android layers may use only the quiet platform-safe treatment required to avoid
  black/white fallback, while keeping the visible mark isolated and uncropped.
- No raw emoji or unowned generic illustration is allowed as product artwork.

## Work packets

1. Locate the exact selected masters and checksum them; compare every generated
   launcher/splash/widget/ICO derivative against the master.
2. Rebuild transparent 512/1024 masters with correct optical bounds and no hidden
   matte pixels, accidental magenta key color or clipped antialiasing.
3. Generate Android legacy/adaptive/monochrome resources and test common circle,
   squircle, rounded-square and themed masks at actual launcher size.
4. Rebuild splash composition so the mark is neither edge-cropped nor visually
   tiny; theme system background for light/dark without baking a box into art.
5. Generate multi-frame Windows ICO and verify Explorer, Start, taskbar, titlebar,
   installer and protocol surfaces at 100/150/200% DPI.
6. Audit `PerfectMark`, `PerfectWordmark`, sync glyph and every header/widget use
   for scale, baseline, color and semantic label consistency.
7. Replace remaining emoji/generic placeholders with project-owned SVGs; create
   dedicated artwork when a meaningful graphic cannot be expressed by one glyph.
8. Add asset-generation scripts and deterministic output checks.

## Cross-surface states

- Light/dark splash, Android themed icon, disabled/high-contrast in-app mark.
- Compact phone header, collapsed rail mark, extended Windows wordmark.
- 2x2 widget, expanded widget, app picker preview and quick-add dialog.
- Auth/loading/error screens before full theme/data initialization.

## Verification

- Pixel alpha-bound checks prove transparent perimeter and safe optical inset.
- Real Android launcher/splash screenshots and Windows taskbar/Explorer/installer
  screenshots are compared side by side with the master.
- Secret/text scans ensure no generated asset accidentally embeds private values.
- Semantics expose `Perfect!` once without reading decorative pieces separately.

## Reject if

- The icon is “technically transparent” but appears boxed, too small or cut.
- One platform uses a different mark/color geometry.
- The wordmark is recreated with ordinary text because it is easier.

## Handoff

Stage 07 receives verified brand primitives and exact safe sizes. Commit generated
sources/outputs, run asset and platform checks, push/release and clean Git.
