# Perfect! Project Instructions

These rules are specific to the private Perfect! planner and complement the
global Codex protocol.

## Product invariants

- Ship Flutter Android, Windows and PWA. PWA replaces native iOS/iPadOS/macOS
  delivery; preserve any existing Apple/Linux folders without modifying them.
  The 2026-09-17 platform amendment in
  `docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/11-master-50-stage-plan.md`
  supersedes the former Android/Windows-only scope and owns browser delivery gates.
  Treat Android phone, Android tablet,
  portrait/landscape, compact Windows, and expanded Windows as distinct
  first-class compositions.
- Preserve local-first behavior, owner isolation, Supabase sync, authenticated
  session, and local app data across normal in-place upgrades. Never reset auth
  or storage as an update shortcut.
- Keep app identity and signing lineage stable. Android and Windows versions
  must increase monotonically so a new private build installs over the previous
  one.

## Experience contract

- Use the approved Perfect! Day Compass identity and pastel system. Do not ship
  raw keyboard emoji as UI artwork; use project-owned modern SVG elements with
  semantic labels.
- Tablet and desktop navigation must collapse. Tablet defaults to a compact
  icon rail; Windows may remember the owner's last rail state. Reflow content
  without overlap, focus loss, or scroll jumps.
- Primary phrases and actions must remain whole, readable, and reachable. At
  narrow widths, short heights, long RTL/mixed copy, or 200% text, recompose
  cramped rows into Wrap/Column layouts before allowing clipping, accidental
  overlap, split labels, or tiny side-by-side controls. Ellipsis is reserved
  for genuinely secondary or user-authored preview text and must not hide the
  meaning or the only available action.
- Build geometry from live constraints and content with a deliberate mixed
  model: intrinsic sizing for copy/controls, flex for distribution, bounded
  fractions for panes, aspect ratios for meaningful compositions, and fixed
  semantic tokens for hit targets, icons, strokes, radii, and rhythm. Do not
  hardcode a reference screen, but do not force every value into percentages
  either. Breakpoints are content-driven and preserve draft, focus, selection,
  scroll, and state.
- A layout is not accepted merely because it has no overflow. Inspect sparse
  and dense screenshots for dead space, primary-workflow scale, visual weight,
  panel adjacency, and action continuity. Today Pulse, day stream, AI, capture, and
  navigation must compose as one instrument; reject tiny floating content and
  unrelated full-width bars appended to the viewport.
- Treat proportion as a product contract: typography hierarchy, icon/control
  scale, readable line length, card weight, radius, spacing rhythm, optical
  alignment, density, and negative space must feel deliberately related across
  every surface. Automated bounds checks cannot certify this; compare sparse
  and dense screenshots at every layout class and reject compositions that
  merely fit while looking imbalanced, cramped, oversized, or generic.
- Treat motion as a system: hover, press, focus, expand/collapse, breakpoint
  transition, loading, completion feedback, and reduced-motion behavior must be
  designed and verified, not left to component defaults.
- The top Sync Cloud has three explicit states: green synced, yellow
  syncing/retrying, and red last-error. Do not rely on color alone; keep local
  work available and automatic bounded retry active.
- The Android Today widget stays scrollable and directly actionable at every
  supported size. Where space permits it exposes Quick Add through a compact
  native dialog and commits through the same durable local-first queue.
- Perfect AI appears as a collapsible dock above the footer. It supports text
  and voice, never embeds a provider secret in the client, and shows a
  reviewable proposal before any planner write.

## Verification gates

- Test phone, tablet, and desktop widths; portrait/landscape; keyboard, mouse,
  touch, RTL/mixed text, 200% text, reduced motion, offline, retry, and error
  states.
- Stress both axes, including short landscape, tall/narrow, split-screen,
  intermediate Windows resize, IME intrusion, and transitions across every
  breakpoint. Reject overflow, clipped required actions, excessive empty space,
  unstable line length, intersecting critical bounds, unreachable visible
  controls, or geometry that only passes a single golden viewport.
- Inspect animation continuity, hover/focus/pressed states, resize behavior,
  clipping, scroll retention, and frame jank in real runtime screenshots or
  recordings before final handoff.
- Prove upgrade continuity with two consecutively versioned artifacts signed by
  the same identity; verify the second installs over the first while preserving
  session and local data.
- PWA additionally requires private hosting, manifest/service-worker identity,
  offline reload, safe update activation, storage/session/outbox preservation and
  actual Chromium/Safari evidence. A web build does not prove these gates.
