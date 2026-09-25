# Stage 26 — HabitNow-inspired Habit creation flow

Status: in progress — six-step order, measurement choices, checklist
definition round-trip, frequency/plan/review, and edit-return suites are GREEN;
template library, method-migration matrix, engine-summary equality proof, and
native screenshot comparison remain open
Depends on: Stages 21–25  
Primary surfaces: Create/Edit Habit wizard and review summary

## Mission

Rebuild Habit creation around the strongest decision order observed in HabitNow,
then improve it for Perfect!'s richer tracking, recovery, local-first sync and
personal AI. Common habits should be fast; unusual habits must remain expressible.

## Mandatory preview and Copy entry gate

- Freeze every `pg-habit-*` wizard composition plus `wiz-identity-step`,
  `wiz-definition-step`, tracking/target/schedule/recovery/reminder/review components.
- For every step create individual component plates and full flow boards for one-tap
  simple, count multiple-daily, duration, numeric, checklist, formula and quit habits.
- Use HabitNow screenshots only as decision-order evidence; internally accept a
  distinctly Perfect! composition, then implement from its frozen manifest with Copy.
- Compare every reference/runtime step, transition and summary; pair visual evidence
  with round-trip behavior so no attractive control writes an ambiguous contract.

## Step order

1. Category/identity: where it belongs, optional icon/color/project/area.
2. Measurement: how progress is recorded and what one quick action means.
3. Definition/goal: title, note, unit, direction, target, checklist/formula.
4. Frequency: eligible days/period quota/multiple-per-day behavior.
5. Plan: time window, reminders, priority, recovery and quit/build mode.
6. Review: natural-language contract, next eligible dates and row interaction preview.

Type is create-only and precedes this sequence. Edit omits Type and enters the first
relevant mutable stage as defined by Stage 25.

## UX principles

- Each step asks one conceptual question and shows its consequence.
- Measurement choices use visual examples (`tap once`, `+1`, `10 min`, checklist),
  not domain jargon alone.
- Advanced controls expand inline with smooth state-preserving motion.
- A live preview shows how the Habit row/status/logging control will behave.
- Review uses the same engine/schema that runtime and AI consume.

## Build/maintain/quit distinction

- Build: reach at least a positive target.
- Maintain: stay within a target/range as configured.
- Quit/reduce: success means at most/zero occurrences, with non-shaming language.
- Direction changes are explicit and revalidate target/history interpretation without
  rewriting old occurrence values.

## Work packets

1. Trace every HabitNow screenshot option and map useful behavior into canonical
   Perfect! domain fields; document intentional differences.
2. Replace old controls with Stage 04/21 primitives across all six steps.
3. Implement field compatibility/migration when measurement method changes.
4. Add live summary/occurrence preview and common templates as choice definitions,
   never seeded habit records.
5. Ensure review/save is local-first, idempotent and widget/AI compatible.

## Edge scenarios

Switch method after values entered; quit habit with zero target; flexible quota;
custom unit/formula; multiple reminders; paused habit; 320dp/200%; RTL; offline save;
edit with existing history and method change consequences.

## Verification

Step/order/state tests; screenshot comparison against reference logic; fast-path tap
count; every method/recovery combination round-trip; draft/resize/IME tests; review
summary==domain behavior; no default records for clean owner.

## Reject if

- The flow copies HabitNow visuals without preserving its decision clarity.
- Advanced scenarios require raw JSON or cannot be represented.
- Common simple habit creation feels like filling a database form.

## Handoff

Stage 27 receives the selected measurement method and preview contract. Commit/push/
release with reference mapping and flow evidence; clean Git.

### Evidence — 2026-09-25 (real runs, Stage 26 partial)

`flutter test --no-pub test/presentation/planner_editor_test.dart`:
**EXIT:0, 17 pass**. The decisive slice is
`habit flow follows category evaluation definition frequency plan review`,
which walks all six Stage 26 steps (category → evaluation → definition →
frequency → plan → review), selects the checklist method, defines a checklist
title/item, returns through the method switch without losing the draft, then
saves a local-first `tracking.method == 'checklist'` entity with one checklist
item and a daily rule. Template library, per-method migration, engine-summary
equality, and screenshot comparison remain open.
