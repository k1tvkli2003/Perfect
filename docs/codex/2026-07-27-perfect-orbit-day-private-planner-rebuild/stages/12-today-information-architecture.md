# Stage 12 — Today information architecture and day stream

Status: pending  
Depends on: Stage 11  
Primary surfaces: Today stream, grouping, scroll and next-action emphasis

## Mission

Rebuild Today from first principles so the owner can answer “what now, what later,
what is flexible and what needs a decision?” in one scan. Remove duplicate cards,
weak grouping and empty zones inherited from the Orbit layout.

## Mandatory preview and Copy entry gate

- Bind implementation to `td-zone-heading`, `td-stream-timeline`,
  `td-next-emphasis`, `td-continuation-cue`, canonical task/habit rows and every
  `pg-today-*` state composition.
- Preview three structurally different stream arrangements with identical sparse and
  dense fixtures; internally accept the one with the fastest scan and lowest action
  duplication, then freeze its ordering/scroll/occlusion equations.
- Implement from the page/component manifests and compare full-page phone/tablet/
  Windows captures including the final row behind footer/capture clearances.
- Any reorder that changes semantics, scroll anchoring or next-action emphasis reopens
  the composition gate even when individual rows remain pixel-faithful.

## Ordering model

1. Overdue/recovery-decision items that genuinely require owner input.
2. Current/next scheduled work by local start time.
3. Remaining scheduled work.
4. Habits due/available today, ordered by planned window and logging need.
5. Flexible/unscheduled work in a distinct but connected section.
6. Completed/missed items collapsed or visually quiet according to owner setting,
   never silently removed when review/undo is relevant.

## Product decisions

- “Next up” is a contextual treatment on the first actionable stream row, not a
  second copy of the same entity in a separate card.
- A time rail is used only when it improves chronological scanning. Unscheduled
  rows do not fake a time; they use a clear flexible/inbox anchor.
- Task and habit rows share the stream rhythm but expose type-specific controls.
- Pull-to-refresh is not the normal scroll behavior. Realtime/local notifiers update
  content; explicit refresh is available only as recovery/diagnostic action.

## Work packets

1. Write a deterministic Today projection/grouping function with stable ordering.
2. Distinguish eligibility, occurrence state and source entity state correctly.
3. Design phone grouping headers/dividers with minimal vertical cost.
4. Design tablet/desktop stream density and optional adjacent detail without making
   a sidebar mandatory at widths that cannot sustain it.
5. Add a sticky/ambient “Now” cue only if it survives dense/short layouts without
   obscuring rows; otherwise rely on Pulse and next-row emphasis.
6. Preserve scroll anchor when remote/local updates insert or reorder rows.
7. Keep composer/footer floating over the page background while adding precise
   bottom content inset so the final row/action remains reachable.
8. Add empty-section suppression and a single meaningful page-empty composition.

## Interaction rules

- Row body opens detail (Stage 31 contract; characterization route until built).
- Leading status/log control mutates only its explicit state.
- Secondary/context menu offers advanced actions without stealing normal tap.
- Swipe gestures, if retained, require reversible action and cannot conflict with
  horizontal system back or Windows pointer behavior.

## Edge scenarios

- Dense simultaneous times, long titles, mixed RTL, 200% text and split view.
- Remote insertion above current scroll position.
- Completion moves a row between active/completed while Undo remains reachable.
- Midnight/day rollover while Today is open; paused/exception recurring items.

## Verification

Projection unit tests; scroll-anchor widget tests; touch/pointer/keyboard flows;
sparse/dense side-by-side screenshots; final-row reachability with composer/IME;
frame timings for 500+ retained entities and realistic Today subset.

## Reject if

- Sorting is performed ad hoc inside widgets.
- Next item is duplicated or completion causes disorienting uncontrolled jumps.
- Group labels consume more attention than actionable rows.

## Handoff

Stage 13 receives row constraints, grouping roles and exact state inputs. Commit,
push/release with projection and visual evidence, then clean Git.
