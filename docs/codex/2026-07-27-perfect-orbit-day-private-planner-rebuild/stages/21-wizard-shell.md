# Stage 21 — Unified modern wizard shell

Status: pending  
Depends on: Stages 04, 05, 07–10, 18  
Primary surfaces: create/edit Task, Recurring Task, Habit, Project, Area and Goal

## Mission

Replace the visually old, inconsistent editor shell with a coherent Perfect!
multi-step environment. Preserve HabitNow's strong decision sequence while making
the shell responsive, calm, fast and visibly related to Tasks/Plan selectors.

## Mandatory preview and Copy entry gate

- Freeze `ov-wizard-chrome`, `wiz-progress`, `wiz-footer`, `wiz-discard-draft`,
  common field/selector overlays and all `pg-create-*`, `pg-edit-*`,
  `pg-editor-validation/discard-draft` shell compositions.
- Preview each shared chrome component separately, then composed with simple/dense
  Task/Habit steps at phone, short landscape, tablet and Windows with IME/200%.
- Implement shell/chrome from the manifest before migrating step bodies; compare
  reference/runtime and reject any legacy local footer, selector or blank strip.
- Route, draft, validation focus, scroll and back behavior are part of Copy fidelity,
  not separate polish; every transition carries a motion and continuity ID.

## Header contract

- Header is a compact clipped glass layer, not a solid color bar.
- Close, step pictogram, Create/Edit context, immutable kind and step count align
  optically; large page copy belongs in scrollable stage content.
- Phone header does not exceed the minimum height needed for controls at normal
  scale; 200%/short height uses a deliberate compact reflow, not clipping.
- Blur has contrast/performance fallback and never obscures content underneath.

## Progress/navigation contract

- Phone uses a slim animated meter with current label only when space permits.
- Tablet/Windows uses a collapsible/efficient step rail only when it improves direct
  navigation; it must not create an empty permanent sidebar.
- Completed/current/upcoming states use shape/weight/color without redundant checks
  where order/position already communicates completion.
- Navigating backward/rail preserves values, validation, focus and per-step scroll.

## Footer contract

- Remove the empty row/bar currently created by a lone compact Quick Save action.
- Footer contains only actual Back, optional Quick Save and Continue/Save controls;
  compact actions share one balanced row or move into contextual header/menu.
- Required primary action stays whole and reachable under IME/safe area/200% text.
- Glass footer sizes intrinsically; no unexplained blank height above Continue.

## Stage surface and selectors

- Stage title/subtitle enter with a restrained rise once per step.
- Selector tiles, filter pills, disclosures and chips use Stage 04 shared primitives,
  matching Tasks/Plan. Retire old outlined card/checkmark language.
- Inputs activate only on direct tap; outside tap closes keyboard; focus moves in
  reading order and validation returns to the exact field.
- Advanced groups use meaningful progressive disclosure, not hidden required data.

## Work packets

1. Characterize current wizard routes/steps/saves before shell changes.
2. Extract shell from step content and define create/edit mode contract.
3. Implement responsive glass header, meter/rail, stage transition and footer.
4. Replace selector/disclosure/chip primitives across every wizard step, not only Type.
5. Add unsaved-change guard and restore state through resize/background.
6. Audit every icon; replace emoji/generic/misaligned glyphs with owned SVGs.

## Verification

All entity kinds; create/edit; phone/tablet/Windows; short landscape; IME; RTL/mixed;
200% text; dark/high contrast; keyboard traversal; step motion/reduced motion; no
blank footer strip; screenshot side-by-side with Tasks/Plan selection language.

## Reject if

- Only the header/footer changes while internal controls remain legacy/inconsistent.
- Edit and Create accidentally share the same immutable Type question.
- Quick Save occupies an empty row or is unreachable/ambiguous.

## Handoff

Stages 22–30 receive shell APIs and primitive contracts. Commit/push/release with
wizard matrix evidence and clean Git.
