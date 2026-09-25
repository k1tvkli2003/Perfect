# Stage 29 — Habit skip, miss, recovery and streak integrity

Status: in progress — daily-state outcomes (pending/partial/completed/missed),
miss-then-next recovery, carry-cap, flexible quota, and editing-old-work
preservation are GREEN at domain/projection layers; derived streak math,
freeze/quit semantics, accessibility wording, and calendar parity remain open
Depends on: Stages 24, 27–28  
Primary consumers: Today, Habit detail/calendar, insights, gamification and AI

## Mission

Make streaks motivating and mathematically honest. Eligibility, skip, pending, miss,
completion, recovery and quit-habit success must be distinct; no guilt from days that
were not scheduled and no history rewriting to protect a number.

## Mandatory preview and Copy entry gate

- Bind implementation to `habit-day-state`, `habit-week-strip`,
  `habit-streak-receipt`, `habit-recovery-preview`, `game-streak`,
  `pg-streak-recovery` and relevant detail/calendar compositions.
- Preview every daily state side by side with non-color shape/label cues, then weekly/
  flexible-period, quit/at-most, correction, freeze and recovery consequence variants.
- Compare accepted calendar/receipt/runtime output using the same golden occurrence
  ledger; a visual streak is invalid unless the derivation and denominator reproduce.
- Motion/copy must motivate without guilt or fear-of-loss; any manipulative wording,
  history rewrite or stored mutable streak authority reopens/rejects the gate.

## Daily-state model

- Not eligible: outside schedule; neutral and excluded from denominator/streak.
- Upcoming/pending: eligible but outcome not final.
- Completed: success rule met.
- Partial: meaningful progress below success threshold.
- Skipped valid: owner/system-approved skip; policy explicitly states streak effect.
- Missed: eligible outcome finalized unsuccessful.
- Recovered/carry: a later authorized outcome satisfies the configured prior scope
  while retaining both original and recovery evidence.

## Streak rules

- Current/longest streak derive from normalized eligible-day outcomes and timezone.
- Flexible X/week streak uses successful periods, not arbitrary calendar daily chain.
- At-most/quit habits succeed when the allowed window closes with value within target;
  zero input is not prematurely celebrated before the day/period is final.
- Freeze is an explicit earned/owner-enabled event with audit and bounded policy,
  not silent mutation of missed status.

## UX

- Today shows only the state/action needed now; detail explains streak math and lets
  owner inspect/correct a day.
- Before correction that changes streak, preview effect and retain Undo/audit.
- Recovery decision language predicts which date/period receives credit.
- Avoid shame copy, red overload and manipulative loss aversion.

## Edge scenarios

Timezone travel, midnight open app, weekly quota, paused days, exception dates,
schedule edit future-only, late sync, duplicate occurrence, recovered miss, freeze,
quit habit, historical correction and two-device conflict.

## Verification

Golden outcome/streak vectors; timezone/period boundary tests; history immutability;
correction preview/undo; detail/calendar parity; gamification event idempotency; AI
read/write contract and accessible state semantics.

## Reject if

- Missing log is automatically marked missed before policy/time boundary.
- Streak is stored as mutable authority detached from occurrences.
- Schedule edit retroactively rewrites history without explicit migration scope.

## Handoff

Stage 30 adds feedback/performance on top of proven outcomes. Commit/push/release
with math/history evidence and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 29 partial)

- `flutter test --no-pub test/planner/planner_recovery_engine_test.dart` —
  carry cap asks the owner, overdue miss-then-next honored, quota-stable
  flexible work, and old completed work not resurrected.
- `flutter test --no-pub test/planner/planner_habit_day_summary_test.dart` —
  pending/partial/completed/at-most daily outcomes with legacy observations
  folded into one aggregate result.
- Both live inside the **EXIT:0, 68 pass** combined domain+wizard gate.
- Actual streak derivation (current/longest/flexible/freeze/at-most-close),
  correction preview/Undo math, detail/calendar parity, gamification
  idempotency, AI contract, and accessible wording remain unverified.
