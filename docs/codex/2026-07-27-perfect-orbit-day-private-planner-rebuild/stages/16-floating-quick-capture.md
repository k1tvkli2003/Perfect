# Stage 16 — Floating Quick Capture control

Status: pending; current uncommitted code is only a prototype  
Depends on: Stages 07, 09, 12, 15  
Primary surfaces: Today lower edge on phone/tablet/Windows

## Mission

Create a true floating launcher with no invisible/full-width colored strip behind
it. It must feel like a precise Perfect! instrument, never obscure reachable work,
and never summon the keyboard merely because the launcher opened.

## Mandatory preview and Copy entry gate

- Freeze `cap-orb`, `cap-expanded-shell`, `cap-mode-actions` and
  `pg-capture-collapsed` previews over real Today sparse/dense backgrounds.
- Preview transparent bounds, halo/heartbeat frames, hover/focus/press/draft,
  open/close, reduced motion, short-height, safe-area and footer/rail relationships.
- Implement from exact visible and hit-test geometry, then compare runtime with debug
  hit bounds plus normalized screenshot/recording at phone/tablet/Windows sizes.
- Any background strip, invisible intercept region, auto-focus/IME request or
  unmanifested position drift is a blocking Copy/interaction mismatch.

## Visual contract

- Collapsed state is one 64dp semantic circle containing a 56dp authored pastel
  control, transparent outside its own shape.
- A bounded mint/lilac halo and restrained double-beat communicate availability;
  no rectangular glass/tint/background reserves visual space behind it.
- Draft presence uses one small non-color-reliant state cue without growing bounds.
- Position follows footer/rail/content geometry; it is not centered by hardcoded
  device width and does not collide with the last row or system gesture area.

## Interaction contract

- Tap opens composer but keeps IME closed and no field focused.
- Ctrl+K or explicit field tap opens and focuses Task mode.
- Tap outside, Escape or collapse closes; a non-empty draft remains preserved.
- Drag/scroll starting near the orb must not accidentally open it.
- Hover, focus, pressed, draft and disabled states share fixed geometry.

## Work packets

1. Move phone body/background behind the dock without allowing list actions to be
   hidden; use explicit scroll insets rather than a Scaffold color strip.
2. For tablet/Windows, overlay the launcher/composer on the content canvas instead
   of adding a reserved bottom row; preserve pointer access and content extent.
3. Remove nested full-width/glass parents and audit hit-test bounds with debug paint.
4. Tune heartbeat timing and halo raster cost; stop animation when offscreen,
   expanded, reduced-motion or app background.
5. Persist external capture controller/focus across breakpoint changes.
6. Add semantic label/tooltip and keyboard traversal placement.

## Edge scenarios

Short landscape, IME open, footer safe area, Windows compact height, 200% text,
AI mode active, draft active, route change and Android software/host renderer.

## Verification

Pixel screenshot shows Today background continuously behind orb; hit-test test proves
only circle activates; no-focus/no-IME open test; last-row reachability; repeated
heartbeat/open/close memory/frame evidence; reduced motion and breakpoint state.

## Reject if

- Transparent child still sits on a visible bottomNavigationBar strip.
- Opening launcher focuses TextField or shows system writing/IME toolbar.
- Invisible width intercepts a task row.

## Handoff

Stage 17 receives preserved draft/focus and verified floating geometry. Commit/push/
release with real Android/Windows evidence and clean Git.
