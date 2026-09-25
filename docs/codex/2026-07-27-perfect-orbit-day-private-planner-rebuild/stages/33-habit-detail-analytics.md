# Stage 33 — Habit detail, calendar and actionable analytics

Status: in progress — method-aware logging/correction, daily-state outcomes,
over-target and legacy-observation folding suites are GREEN; derived metrics,
calendar encoding, pagination, parity, and keyboard/screen-reader matrices
remain open
Depends on: Stages 27–32  
Primary surfaces: Habit detail and selected-day correction

## Mission

Make Habit detail the trusted place to understand rhythm, log/correct today and learn
from real history. It must support every tracking method and build/maintain/quit goal,
not just paint a binary green heatmap.

## Mandatory preview and Copy entry gate

- Freeze `pg-detail-habit`, `pg-detail-habit-history`,
  `pg-detail-habit-analytics`, `det-month-calendar`, `det-habit-heatmap`,
  `det-chart`, `det-insight`, `habit-metric-strip` and method-aware controls.
- Preview every tracking method/direction, zero/short/long history, selected-day
  correction, insufficient data, over-target, recovered/frozen and error states.
- Compare reference/runtime pixels and semantics with metric/calendar golden fixtures;
  every intensity, denominator, streak and trend must be reproducible from the ledger.
- A pretty binary heatmap, invented coaching claim or chart inaccessible by keyboard/
  screen reader fails even when the overall page matches visually.

## Default hierarchy

1. Identity + today's method-specific control/value/target.
2. Current streak/period momentum with an explanation link, not an unexplained flame.
3. Month calendar/heatmap with selected-day detail and correction.
4. Current/longest streak, eligible success rate, total/value trend and schedule.
5. Week/month/quarter/year insight controls one level deeper.
6. Definition, measurement, reminders, recovery, category/project and sync facts.

## Calendar encoding

- Ineligible: neutral absent/outlined state.
- Pending/upcoming, partial, completed, skipped, missed and recovered each have a
  distinguishable shape/mark plus theme-safe color.
- Count/duration/value intensity derives from progress toward target; over-target is
  visible but bounded. Quit/at-most habits invert success semantics correctly.
- Selecting a day shows raw inputs, normalized result, source (app/widget/AI), edits
  and safe correction/undo.

## Analytics contracts

- Denominators include only eligible finalized periods as defined by Stage 29.
- Trends state aggregation and comparison window; insufficient data yields an honest
  message, not a random motivational claim.
- Metrics are recomputable from occurrence/rule versions; cached aggregates are not
  authority and are invalidated/versioned safely.

## Interaction and motion

Calendar month navigation preserves selected day when valid; keyboard arrows/Enter
work on Windows. Cell selection uses subtle shared highlight, not layout movement.
Target logging and correction update relevant cell/metrics without rerunning page
entrance or jumping scroll. Reduced motion remains equally informative.

## Edge scenarios

Zero history, method/rule version change, flexible weekly quota, quit habit, timezone
travel, recovered/frozen day, over-target, formula error, long history and remote edit.

## Verification

Metric/calendar golden vectors for each method/direction/state; range/pagination
performance; correction/history integrity; app/widget/AI source parity; keyboard/
screen-reader calendar; visual matrix at phone/tablet/Windows/light/dark/200%.

## Reject if

- Binary-only calendar misrepresents count/value/checklist habits.
- Success rate denominator includes unscheduled/unfinalized days.
- Gamified streak display is more prominent than today's useful action.

## Handoff

Stage 34 receives complete detail body and history constraints. Commit/push/release
with reproducible metric evidence and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 33 partial)

- Method-aware Today/Habit logging and correction inside the **EXIT:0, 133
  pass** integrated controller/Pulse/workspace gate.
- Daily-state vectors inside the **EXIT:0, 68 pass** domain+wizard gate.
- Metric/calendar goldens, pagination, app/widget/AI parity, keyboard/screen
  reader, and visual matrices remain open.
