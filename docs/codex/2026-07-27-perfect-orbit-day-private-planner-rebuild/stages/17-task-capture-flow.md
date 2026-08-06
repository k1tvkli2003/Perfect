# Stage 17 — Task capture mode and resilient quick save

Status: pending; centering prototype not yet accepted  
Depends on: Stage 16  
Primary surfaces: Task mode of the morphing composer

## Mission

Turn a thought into exactly one local task with minimal friction. Remove redundant
`Quick capture / type-plan-ask-speak` copy and make field geometry, keyboard behavior,
feedback and failure recovery exact.

## Mandatory preview and Copy entry gate

- Bind implementation to `cap-task-mode`, `cap-mode-actions`, `cap-send-action`,
  `ct-text-field`, `ct-toast-undo`, `pg-capture-task` and `pg-capture-ime`.
- Preview unfocused-open, focused/IME, empty, mixed-direction, max-length, sending,
  saved/Undo, local error, offline pending, outside dismissal and resize states.
- Measure hint, glyph, caret and entered-text optical centering in the frozen plate;
  compare runtime bounds and pixels rather than trusting InputDecoration properties.
- The visual Copy loop is accepted only with exactly-one local entity/operation proof,
  preserved failure draft and no Supabase wait in the interaction trace.

## Composition

- The open Task mode contains one optically centered input, send action and a short
  coherent mode/action row. It has no extra title/header above the field.
- Hint and entered text center against the input field shell, not the icon/send row;
  use explicit vertical alignment because borderless InputDecorator defaults top.
- Prefix art is project-owned and visually legible on light/dark; it never competes
  with the insertion point or text start.
- Phone actions reflow without tiny squeezed tiles; wide layout becomes one compact
  row. The glass shell sizes to content only.

## Behavior

1. Launcher opens unfocused.
2. Direct input tap requests focus; outside tap/Escape dismisses IME promptly.
3. Mixed Persian/English direction follows first strong character while hint follows
   ambient direction.
4. Empty send focuses the field; non-empty send trims and validates title.
5. Submit writes local entity + operation atomically and disables duplicate submit.
6. Success closes composer, clears draft and offers Undo; sync happens separately.
7. Failure retains draft/focus context and shows a local actionable error.
8. Ctrl+K focuses; Enter submits; Shift+Enter behavior is explicit if multiline is
   ever enabled; 160-character limit never truncates silently.

## Data contract

- Default quick task has no sample category/time/note and uses owner ID, stable UUID,
  normal priority and pending progress only.
- Idempotency key prevents repeat submit after slow UI/resume.
- No remote dependency blocks the local receipt.

## Edge scenarios

Double tap/Enter, whitespace, max length, RTL, IME suggestions/toolbars, app pause,
local DB error, offline queue, resize during typing, route switch and Undo after sync.

## Verification

Geometry assertion keeps hint/text center within <=1.5dp; focus/IME tests; direction
tests; exactly-one entity/op tests; failure draft retention; screenshot matrix at
320/390/Windows and 1x/2x text; real device tap/outside/back behavior.

## Reject if

- A redundant label consumes a separate row.
- Text looks vertically high/low despite a property-level “center” assertion.
- Success waits for Supabase or duplicate records can appear.

## Handoff

Stage 18 receives a stable Task-mode shell and retained draft. Commit/push/release
with local-first receipt proof and clean Git.
