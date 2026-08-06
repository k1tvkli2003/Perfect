# Stage 32 — Task detail, status and history

Status: pending  
Depends on: Stage 31 and task occurrence/progress contracts  
Primary surfaces: one-off and recurring Task detail

## Mission

Build a high-craft Task detail page that answers: what is it, when/where does it fit,
what is its state, what happened, and what can I do now? Never invent statistics the
data model cannot support.

## Mandatory preview and Copy entry gate

- Bind implementation to `pg-detail-task`, `pg-detail-recurring-task`, `det-hero`,
  `det-fact-group`, `det-relations`, `det-history-timeline`, `det-month-calendar`,
  `det-chart`, `det-focus-link` and `det-lifecycle-actions`.
- Preview one-off/recurring, no/long history, pending/partial/done/missed, schedule/
  recovery/conflict and phone/tablet/Windows inspector variants separately.
- Decompose live facts/calendar/events/metrics from authored frames/graphics; runtime
  fixtures must reproduce every displayed count, date, denominator and source.
- Compare full compositions and individual calendar/timeline states; fabricated stats,
  generic equal cards or stale copied entity data are blocking mismatches.

## Information hierarchy

1. Identity: title, state control, category/project/area, sync/conflict cue.
2. Immediate actions: status/percentage, Focus, reschedule, Edit.
3. Schedule: start/block/deadline, recurrence and next occurrence.
4. Working context: note, checklist, estimate, energy, priority, labels, custom fields.
5. Recovery: missed policy, Carry/current decision and exceptions.
6. History/analytics: calendar/timeline derived from durable evidence.

## One-off history

- Show created/updated/completion/missed/partial events only if captured durably.
- Month calendar marks the meaningful planned/completion day; do not fabricate a
  multi-day success rate for a one-off task.
- Checklist progress and focus sessions may form an activity timeline with source.

## Recurring history

- Query owner/entity occurrences by date range and display completed/partial/missed/
  skipped/pending accurately.
- Month calendar uses clear legend and selectable day details.
- Summary may include eligible count, completion rate, current period and trend when
  mathematically defined; document denominator.

## Composition

- Use a distinctive summary field/strip, grouped facts and calendar—not generic equal
  dashboard cards.
- Calendar cell stays at least semantic target size or uses separate selected-day
  panel when dense; colors work in dark/high contrast and have non-color shapes.
- Long note/checklist scroll naturally; Edit remains contextual, not permanently huge.

## Data/API work

Expose bounded range queries for task occurrences/focus/events through controller or
repository; never let UI access raw Drift internals. Paginate/aggregate long history.

## Edge scenarios

No history, one-off unscheduled, recurring paused, future-only edit, conflict, remote
occurrence update, 10-year history, month boundary/timezone, long mixed copy.

## Verification

Known occurrence fixtures→calendar/stat vectors; one-off no-fake-stat test; range query
performance; current state mutation/Undo; detail→Edit→return; all layout/theme/a11y
screenshots and semantics.

## Reject if

- Statistics are inferred from missing logs or generic entity `updatedAt`.
- Calendar and list use different day/timezone semantics.
- Detail is a dump of label/value rows with no hierarchy.

## Handoff

Stage 33 reuses calendar/history primitives for Habit-specific metrics. Commit/push/
release with data derivation and visual evidence; clean Git.
