# Stage 27 — Complete Habit tracking-method model

Status: in progress — check/count/duration/numeric/checklist/formula method
vectors, checklist all/threshold rules, invalid/missing formula safety, and the
Stage 14 count-vs-numeric contract are GREEN at domain/controller/widget
layers; schema migration, server/RLS, AI proposal, and old-client parity remain
open
Depends on: Stage 26 and occurrence schema baseline  
Primary consumers: wizard, Today/Habits rows, detail analytics, widget and AI

## Mission

Give every realistic habit an explicit, versioned way to record and evaluate
progress. UI, local store, sync, widget, statistics and AI must interpret the same
contract exactly.

## Mandatory preview and Copy entry gate

- Bind visible work to `habit-control-check/count/duration/numeric/checklist/formula`,
  `wiz-definition-step`, `pg-habit-tracking` and `pg-habit-target` previews.
- Plate every method's input, unit, aggregation, target/direction, quick action,
  invalid/missing/over-target and method-switch consequence states.
- Implement a canonical typed contract first, then compare wizard/row/detail/widget/
  AI renderers against their preview and against one shared method fixture.
- Unknown-version/error UI must match its accepted state and fail visibly; silent
  fallback to boolean/check is both a functional and Copy rejection.

## Supported methods

### Check

One boolean completion per eligible day; optional skip/recovery remains distinct.

### Count

Integer/decimal accumulation with increment, target, at-least/at-most/exact/range
direction and optional multiple planned instances.

### Duration

Accumulated seconds/minutes with quick presets, timer/focus contribution and target.

### Numeric value

One or more measured values with unit; define whether success uses latest, total,
average, minimum or maximum rather than guessing.

### Checklist

Stable item IDs, item weights/required flags and success rule (`all`, `at least N`,
weighted threshold). Item edits preserve historical meaning through version/snapshot.

### Formula

Restricted parsed expression over allowlisted numeric inputs; no eval/code/SQL.
Version expression and inputs; report invalid/missing input safely.

## Canonical contract

- `tracking_method`, `goal_direction`, `target`, unit, aggregation, precision,
  quick_increment(s), checklist version and formula/schema version.
- Occurrence stores raw input plus normalized progress/success evidence needed for
  reproducible analytics. Derived values can be recomputed and must not authorize.
- Server/Edge Function validates the same enum/ranges; unknown future method fails
  visibly rather than falling back silently to Task/check.

## UI behavior

- Measurement step explains one-tap behavior and shows interactive preview.
- Hide irrelevant fields but preserve compatible draft when changing method.
- Prevent invalid target/direction/precision combinations in context.
- Review states exact success rule in plain language.

## Edge scenarios

Decimal precision, negative/zero values for reduction habits, unit change with history,
checklist item removal, formula division by zero, locale decimal separator, over-target,
multiple values/day, sync from older client and AI-proposed unsupported method.

## Verification

Schema/domain/serialization/RLS tests; method-specific occurrence and success vectors;
editor round-trip; Today/detail/widget parity; old-version migration; AI proposal
validation; mixed locale input; performance over long history.

## Reject if

- Any consumer infers method differently or defaults unknown method silently.
- Formula accepts arbitrary executable text.
- Method changes make retained history uninterpretable without warning/snapshot.

## Handoff

Stage 28 builds high-frequency multiple-per-day behavior on Count/Duration/Value.
Commit/push/release with cross-consumer contract evidence and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 27 partial)

- Domain method vectors:
  `flutter test --no-pub
  test/planner/planner_habit_tracking_test.dart
  test/planner/planner_habit_day_summary_test.dart
  test/planner/planner_formula_test.dart` — checklist `all`/threshold success,
  legacy checklist readability, measured-method daily summary, safe arithmetic
  from typed values, bracketed names/bounded functions. Covered inside the
  **EXIT:0, 68 pass** combined domain+wizard gate.
- Stage 14 runtime contract is now the decisive method-boundary proof:
  `flutter test --no-pub
  test/presentation/planner_workspace_controller_test.dart
  test/presentation/today_pulse_test.dart
  test/presentation/perfect_workspace_page_test.dart` — **EXIT:0, 133 pass**,
  including count `+1` versus numeric configured-step behavior at controller
  and row layers.
- Migration, server/RLS, AI proposal, old-client parity, mixed-locale input,
  and long-history performance remain open.
