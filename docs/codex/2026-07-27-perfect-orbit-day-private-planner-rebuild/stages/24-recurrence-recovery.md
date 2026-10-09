# Stage 24 — Recurring task, recovery and Carry policy

Status: behavior-complete, committed as 7b1f0b0 (pushed to feat/stage13-status-undo, PR #4, 2026-09-25) — leap/yearly/monthly/flexible recurrence vectors,
exception/limit handling, carry/miss-then-next recovery domain suites, and
responsive wizard flows GREEN; preview/UI parity, notifications, AI/schema
and device matrices remain open; CI workflows disabled_manually
Depends on: Stages 21–23 and recurrence domain baseline  
Primary surfaces: recurring wizard, Today projection, Plan, notifications, detail, AI

## Mission

Expose the complete recurrence/recovery power without making ordinary schedules
painful. The editor must predict engine behavior exactly, including missed work and
bounded Carry, across all devices and agent-generated records.

## Mandatory preview and Copy entry gate

- Freeze `wiz-recurrence-step`, `wiz-recovery-step`, `sel-repeat-summary`,
  `habit-recovery-preview`, `pg-task-recurrence` and `pg-task-recovery` including
  simple, flexible and advanced contracts.
- Preview intent chips→exact controls→occurrence forecast→recovery consequence across
  phone/tablet/Windows, 200%, long bilingual summaries and invalid/conflict states.
- Implement from the component/page manifest and compare reference/runtime at the
  same rule; pair each screenshot with engine-generated next occurrences.
- Any preview/summary/AI schema/notification disagreement, hidden raw JSON escape or
  unbounded Carry rejects the stage regardless of visual polish.

## Recurrence options

- Never / daily / selected weekdays / every N days-weeks-months-years.
- Flexible X times per week/month.
- Specific month days, last day, multiple annual dates.
- Optional start, end date, occurrence limit, pause and exception dates.
- Time windows/flexibility remain separate from the repeat rule.

## Recovery options per item

- Mark Missed.
- Keep Pending until explicitly resolved.
- Move to the next valid scheduled opportunity.
- Ask the owner at the appropriate time.
- Carry forward with explicit bounded cap; show current/maximum Carry consequence.

## UX design

1. Begin with human intent chips (Daily, Weekdays, Weekly, Flexible…) then reveal
   exact rule controls.
2. Show a 6–10 occurrence preview using the same engine as production.
3. Summarize recovery in scenario language: “If Tuesday is missed, …”.
4. Prevent impossible combinations before Save without erasing other selections.
5. Keep recovery advanced but clearly reachable in recurring create/edit/detail.

## Data/engine integrity

- UI writes a versioned canonical recurrence contract; no alternate widget/AI rule.
- Projection, notifications, detail calendar and server validation consume it.
- History occurrences are immutable; rule edit affects future range according to an
  explicit scope, never rewrites past logs.
- Agent action schemas validate recurrence/recovery/carry identically.

## Edge scenarios

February/month end, leap year, last day, 31st skip, annual leap date, timezone/DST,
pause/resume, exception collision, occurrence cap, Carry cap exhaustion, two-device
edit and remote rule conflict.

## Verification

Golden recurrence vectors; UI preview==engine tests; notification generation;
recovery scenario tests; future-only edit/history preservation; AI/schema parity;
visual matrices for simple/advanced rules and 200% text.

## Reject if

- UI summary and actual next occurrences can disagree.
- Carry can grow unbounded or history is rewritten to simulate recovery.
- Powerful options are hidden in raw JSON/custom fields.

## Handoff

Stage 25 receives immutable kind/rule/history contracts for editing. Commit/push/
release with recurrence/recovery evidence and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 24 partial)

- `flutter test --no-pub
  test/planner/planner_recovery_engine_test.dart
  test/planner/planner_habit_day_summary_test.dart
  test/planner/planner_habit_tracking_test.dart
  test/planner/planner_formula_test.dart
  test/planner/planner_today_stream_test.dart
  test/planner/planner_reminder_projection_test.dart
  test/presentation/planner_editor_test.dart
  test/presentation/planner_habit_log_sheet_test.dart`:
  **EXIT:0, 68 pass**. Includes leap-day/yearly/monthly recurrence, exception
  and flexible quota behavior; one-off Carry cap; overdue miss-then-next;
  editing old completed task not resurrected in Today.
- Cross-consumer visual parity, notification receipt and AI/schema validation
  remain unverified for this stage.

### Evidence — 2026-09-25 (real runs, Stage 31+ partial)

- View-first route intent (Stage 31): `IR-002` characterizes the current
  compact direct-to-editor defect, while `IR-001`/detail requirements own the
  target contract. `interaction_route_inventory_contract_test.dart`
  **EXIT:0, 7 pass**, including the corrected `quickCapture` local-first
  signature marker.
- Task status/four-state transitions (Stage 32+34 surface):
  `task_status_control_test.dart` and controller rapid-tap/order/receipt
  vectors are GREEN inside the **EXIT:0, 187 pass** combined workspace gate.
- Focus session surface (Stage 40 surface):
  `focus_session_sheet_test.dart` compact/Windows dialog behavior GREEN in the
  same 187 gate.
- Adaptive secondary sheets/dialogs (Stages 31/35 surface):
  `planner_secondary_surfaces_adaptive_test.dart` GREEN in the same gate.
- Pulse contract (Stage 11 baseline): `stage11_today_pulse_contract_test.dart`
  GREEN in the same gate.
- Full visual matrices, deep-link queueing, inspector parity, and lifecycle
  confirmation semantics remain open across Stages 31–40.
