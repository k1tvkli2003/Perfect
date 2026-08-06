# Stage 18 — Inline Plan mode morph

Status: pending; prototype kind row not yet accepted  
Depends on: Stages 17 and 21 route contract characterization  
Primary surfaces: Plan mode inside the same composer

## Mission

Selecting Plan must transform the existing composer rather than open/stack a second
toolbar. The transformation offers the smallest useful decision before entering the
full wizard and preserves the unfinished Task draft.

## Mandatory preview and Copy entry gate

- Freeze `cap-plan-mode`, `cap-expanded-shell`, `cap-mode-actions`,
  `pg-capture-plan` and `pg-capture-interrupted-resize` with Task/Recurring/Habit
  choice variants at compact/wide/200%.
- Storyboard Task→Plan→Task first/mid/end/reverse/interruption and reduced-motion
  frames; the same outer shell and external draft owner are explicit manifest rules.
- Compare synchronized runtime recording and canonical animatic, then verify hidden
  content has no focus/semantics/hit surface and the wizard route kind is exact.
- A second stacked toolbar, squeezed labels, draft loss or local checkmark language
  rejects the stage even if the transition animates smoothly.

## Product decisions

- Plan mode initially offers Task, Recurring Task and Habit. Project/Area/Goal are
  accessed from their contextual workspaces/More unless usability evidence supports
  inclusion without crowding.
- Type options use project-owned pictograms, short labels and equal geometry.
- A single Back affordance returns to Task mode; outside/Escape collapses while
  retaining draft. No redundant Plan heading is required when choices are clear.
- Choosing a kind launches the create wizard already configured for that kind.

## Morph specification

- Same outer shell/key/alignment remains; height and internal content interpolate.
- Task field fades/slides out only after its draft is stored externally.
- Kind choices enter along the action direction with no overlapping readable copy.
- The shell tint/accent shifts subtly toward planning apricot while preserving dark
  contrast. Shape changes are bounded and GPU-safe.
- Reduced motion performs immediate content replacement plus short opacity change.

## Work packets

1. Define explicit composer mode state independent from TextField focus.
2. Externalize/preserve Task draft and AI conversation before mode switch.
3. Implement responsive kind choices: compact equal cells, wide inline controls,
   48dp targets, whole labels at 200% via vertical reflow.
4. Route each type to canonical wizard creation with correct first step and defaults.
5. Restore composer state after wizard cancel/save and route return.
6. Add semantics announcing mode and choices once; prevent hidden mode from focus.

## Edge scenarios

Draft present, AI open, IME still closing, rapid mode toggles, wizard canceled,
breakpoint change mid-morph, 320dp/200% text, RTL and reduced motion.

## Verification

One-surface widget-tree assertion; draft preservation; type routing tests; focus order;
no overlap/whole-label geometry; recorded morph on Android/Windows; memory/frame
evidence and cancel/return behavior.

## Reject if

- Plan appears as another card/popup above the composer.
- Switching mode loses or submits the Task draft.
- Choice labels/icons squeeze or use selected checkmarks unnecessarily.

## Handoff

Stage 19 receives the same mode host. Commit/push/release with morph/route evidence
and clean Git.
