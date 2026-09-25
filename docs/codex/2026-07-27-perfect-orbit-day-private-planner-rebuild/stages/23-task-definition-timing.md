# Stage 23 — Task definition, timing, reminders and working context

Status: in progress — dual-calendar local time, reminder copy/recovery, and
wizard definition/timing suites are GREEN; permission/Device flow, picker
screenshots, and native review-summary proof remain open
Depends on: Stages 08, 21–22  
Primary surfaces: definition, schedule and details steps; notification consumers

## Mission

Support both a two-second simple task and a fully specified work block without
front-loading complexity. Make date/time logic predictable, local-time correct and
consistent with Plan, detail, notifications, widget and AI.

## Mandatory preview and Copy entry gate

- Freeze `wiz-definition-step`, `wiz-schedule-step`, `wiz-reminder-step`,
  `ct-note-field`, stepper/picker/calendar components and `pg-task-definition`,
  `pg-task-schedule`, `pg-task-reminder`, `pg-editor-validation`.
- Preview collapsed/expanded advanced groups, checklist editing, all-day/exact/window/
  unscheduled, due contradiction, permission denied, quiet-hours and review summaries.
- Compare exact field/picker/footer geometry and motion, but also verify the same
  frozen fixture resolves to identical local instant/day/notification in Plan/detail/
  widget; visual fidelity cannot mask time-semantic drift.
- All dynamic dates, labels, validation and permission states remain live and
  accessible; only authored pictograms/material may be asset layers.

## Definition fields

- Title is required, direct and first in its stage; note is optional multiline.
- Checklist supports add/reorder/complete/delete with stable IDs and keyboard/touch
  parity; empty rows are never saved.
- Estimate, energy and priority use compact semantic choices with live summary.
- Custom properties are typed (text, number, boolean, date, link) and validated;
  no arbitrary code/formula execution from plain text.

## Timing model

- `scheduled_at` means intended local start represented by an instant plus timezone
  context where recurrence requires it.
- `time_block_end_at` must follow start; all-day suppresses incompatible time block.
- `due_at` is a deadline and may differ from schedule; contradiction is explained.
- Unscheduled/inbox is first-class, not a fake midnight value.

## Picker UX

- Date/time controls display dual Gregorian/Jalali context and use platform-friendly
  pickers; preserve current choice on cancel.
- Common shortcuts: Today, Tomorrow, This evening, Next week, No time; shortcuts show
  the resolved actual value before commit.
- Plan preview summarizes start/end/deadline/reminders in plain language.
- Keyboard entry and tab order are excellent on Windows; touch targets are 48dp.

## Reminders

- Per-item opt-in, lead times, multiple reminders, snooze rules and quiet hours.
- Request permission at the moment a reminder is actually enabled, with recovery
  path to system settings; denial never blocks saving the task.
- Notification IDs remain stable across edit/sync/update and cancel obsolete alarms.

## Edge scenarios

Overnight block, DST/timezone change, midnight, invalid range, due before start,
all-day transition, permission denied, duplicate leads, past schedule, recurring
edit, app update and remote timing change.

## Verification

Domain validation, local/UTC round-trip, dual-date tests, notification schedule/
cancel replacement tests, IME/focus/draft tests, real Android permission flow,
Windows keyboard/picker screenshots and review-summary agreement.

## Reject if

- UI silently “fixes” contradictory times by discarding user input.
- A reminder permission failure clears the draft or prevents save.
- Plan/detail/widget show a different local day/time than editor review.

## Handoff

Stage 24 receives canonical timing/reminder values. Commit/push/release with schedule
and notification proof and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 23 partial)

- `flutter test --no-pub
  test/presentation/planner_reminder_settings_message_test.dart`:
  **EXIT:0, 2 pass** (capacity truncation and failed cancellation remain visible).
- `flutter test --no-pub
  test/presentation/perfect_local_time_test.dart
  test/presentation/perfect_date_time_surface_contract_test.dart`:
  **EXIT:0, 10 pass** (local minute tick/midnight and dual-calendar surface).
- `flutter test --no-pub test/presentation/planner_editor_test.dart`:
  **EXIT:0, 17 pass** (definition/timing validation, draft retention, responsive
  wizard flow).
- Permission/device and screenshot/cross-consumer timing proof remain open.
