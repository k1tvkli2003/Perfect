# Stage 13 — Task row and unified status control

Status: pending  
Depends on: Stages 04, 05, 12  
Primary consumers: Today, Tasks, Plan, Detail, widget and accessibility

## Mission

Replace the current mismatched Pending/Partial/Done/Missed visuals and legacy row
composition with one precise, fast and resilient task component. State changes may
alter meaning, color and arc—not physical alignment or hit geometry.

## Mandatory preview and Copy entry gate

- Freeze `task-row`, `task-status-control`, `task-partial-ring`, `task-time-rail`,
  `task-meta-line`, `task-subtasks-summary`, `task-row-actions` and
  `task-inline-receipt` plates before editing shared widgets.
- Plates must align Pending/Partial/Done/Missed side by side at exact outer bounds and
  cover scheduled/unscheduled/overdue/recurring/checklist/long-copy variants.
- Implement the canonical shared primitive, inventory every Today/Tasks/Plan/detail/
  widget consumer, then compare each host against its frozen neighbor/page plate.
- A host-specific exception needs a named variant; anonymous local diameter, stroke,
  padding, icon or state-cycle forks fail Copy acceptance.

## Status-control contract

- Outer semantic hit region: minimum 48x48dp in every state.
- Visual disc/ring diameter, stroke width and optical center are identical for
  Pending, Partial, Completed and Missed.
- Pending: quiet neutral ring, no check.
- Partial: colored arc proportional to exact percent; center remains visually
  empty. The exact value lives in semantics, tooltip and detail—not inside ring.
- Completed: full/filled success treatment with centered authored check.
- Missed: equally weighted error treatment with centered authored cross.
- Repeated tap follows the configured cycle and announces the resulting state.
  Exact percentage remains available through explicit context/action UI.

## Row composition

- Stable leading status control; time rail/time metadata; flexible title/context;
  optional compact trailing schedule/progress affordance; detail chevron only when
  it adds clarity rather than duplicating row affordance.
- First actionable row receives restrained Next emphasis without changing geometry.
- Category/project/estimate information is prioritized by relevance and available
  width; required title/action never ellipsizes due to decorative metadata.
- Completed text may quiet/strike only if readability and undo remain clear.

## Work packets

1. Extract status visual/state machine from page-local widgets into a shared tested
   primitive consumed by lists/detail/widget mappings.
2. Normalize optimistic write, serialized tap cycle, error rollback and Undo.
3. Build compact/reflow row compositions driven by constraints/text scale.
4. Remove textual percentage from every small ring and update semantics/goldens.
5. Unify hover, focus, pressed, keyboard activation and context-menu positioning.
6. Ensure row tap opens detail and status tap never bubbles into navigation.
7. Map native widget visual/action states to the same domain cycle contract.

## Edge scenarios

- Rapid taps during local write/sync; rollback after local/store failure.
- Partial 1%, 50%, 99%; completed 100%; missed with prior partial value.
- Recurring task per-day occurrence versus one-off entity progress.
- Disabled/archived/conflicted item; 200% text; RTL; touch near scroll gesture.

## Verification

State-machine and idempotency tests; geometry equality assertions for every state;
semantics value/action tests; no-tap-bubbling tests; Today/Tasks/Plan/widget contract
tests; side-by-side state sheet in light/dark/high contrast.

## Reject if

- Done and missed controls have different diameters, stroke or baseline.
- Exact percent is deleted from data merely because text is removed visually.
- A tap can both change status and open edit/detail.

## Handoff

Stage 14 reuses fixed row/control geometry for tracking-specific habit controls.
Commit/push/release, verify real device taps and keep Git clean.
