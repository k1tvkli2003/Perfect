# Stage 35 — Windows inspector, adaptive detail and deep-link continuity

Status: in progress — Windows rail/inspector geometry, adjacent-pane
selection, resizable divider/keyboard, and cold navigation controller suites
are GREEN; resize-state migration, protocol/widget/notification cold starts,
duplicate/deleted-link behavior, and high-DPI/native matrices remain open
Depends on: Stages 07, 31–34  
Primary surfaces: expanded Windows/tablet detail, notifications, widget/protocol links

## Mission

Deliver a genuinely Windows-native information workflow without creating a separate
product. Detail adapts from adjacent inspector to full page based on useful remaining
space and all external entrypoints converge on the same current record.

## Mandatory preview and Copy entry gate

- Freeze `sh-desktop-inspector`, `sh-pane-divider`, all `pg-detail-*` inspector
  compositions, `pg-notification-open`, `pg-stale-deep-link` and
  `pg-windows-protocol-open`.
- Storyboard compact↔inspector↔full-page resize with selected entity/month/day/scroll/
  focus preserved; preview high-DPI, pointer, keyboard, 200% and short-window states.
- Compare synchronized resize/reference recordings and still diffs at both sides of
  each content-driven threshold; inspector/full route must share semantic body data.
- Deep-link visual fidelity cannot mask unsafe caller identity, duplicate route stack,
  stale entity copy or direct-to-edit behavior; those are P0 gate failures.

## Inspector composition

- Show adjacent detail only when list/workspace retains >=680dp and detail can retain
  its minimum readable width at current text scale.
- Inspector uses the same summary, calendar/history and actions as full detail but may
  collapse secondary sections—not replace them with a shallow fact dump.
- Header includes current entity context and close; rail/header are not repeated.
- Mouse wheel, keyboard tab/arrow, selectable text and context actions feel native.

## Resize behavior

- At threshold crossing, migrate detail state (entity, month, selected day, scroll,
  disclosure) between inspector and full-page presentation without duplicate routes.
- Remember selection while rail collapses/expands; do not compress both panes below
  useful line length just to avoid navigation.
- Preserve list scroll/focus; Escape closes the most local context first.

## External navigation

- Android widget row/action, notification and Windows `perfect://` protocol carry a
  normalized entity ID/action—not raw serialized entity or owner ID.
- Queue request through bootstrap until auth/local store ready; authorize current owner
  and resolve latest record once.
- If missing/archived, present a recoverable state with Today/Archive navigation.
- Repeated identical launch while route active focuses/reveals rather than stacking.

## Windows craft audit

Hover/focus/tooltip, right-click menu placement, Ctrl shortcuts, minimum window,
high-DPI icons, title/taskbar identity, window restore and multi-monitor DPI changes.

## Verification

Continuous resize recording/state assertions; inspector/full parity; keyboard/pointer;
protocol/widget/notification cold/warm starts; duplicate/deleted link behavior; auth
delay; Windows high-DPI screenshot matrix; no direct edit route.

## Reject if

- Inspector is a different shallow implementation from detail.
- Resize loses selected month/scroll or leaves duplicate routes.
- External navigation trusts owner/resource data supplied by caller.

## Handoff

Stage 36 receives final list/detail selection behavior. Commit/push/release with deep-
link/Windows evidence and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 35 partial)

- `expanded Windows keeps Today Pulse above one dominant day stream`,
  `sparse wide Today keeps the selected inspector content-led`,
  `desktop inspector divider supports drag keyboard and a useful main pane`,
  `Today deep link clears an inspector already open on Today`, and rail
  persistence suites GREEN inside the integrated workspace gate.
- Inspector/full semantic parity, resize migration without duplicate routes,
  external widget/notification/protocol navigation, and high-DPI/native
  proof remain open.
