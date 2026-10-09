# Stage 36 Tasks runtime vs preview evidence

Verdict: **REJECTED** — composition proven, pixel Copy not equivalent.

| Surface | Preview authority | Runtime result | Evidence |
| --- | --- | --- | --- |
| Tasks default phone | `03-pages/pg-tasks-default/canonical/phone-compact.png` (390x844) | Live runtime Tasks reachable: header + switcher + Refine deck + 3 rows; Tasks Tab 2 of 5 selected | `stage36-tasks-workspace/runtime/android/tasks-runtime.png` + `tasks-runtime.xml`; normalized diff `tasks-diff-normalized.png` (58.1122% changed, MAE 20.087, RMS 48.3508) |
| Tasks saved-view switcher | `Inbox / Open / Scheduled` reference chips | Inbox / Open active / Scheduled truncated + Save + Manage saved views controls present | semantics: `Inbox`, `Open` selected, `Scheduled`, `Save`, `Manage saved views` |
| Tasks Refine/query | accepted subtitle and Refine summary | `Open · All · Due date` with count badge `3` matching listed rows | `tasks-runtime.xml` semantics |
| Tasks rows | 4 fixture rows with priority metadata | 3 live tracker rows: Review project brief 60%, Focus deep work Pending, Call Mom Missed | `tasks-runtime.xml` semantics |

Mismatch ledger (must close before Copy gate passes):
- Crown text/geometry open (shell vs preview crown/date line).
- Action row open (+ New flow vs Filters + brown Add task).
- Search/summary open (live Filter chips vs Search tasks/Ctrl K).
- Row composition open (3 live tracker rows vs 4 fixture rows).
- Bottom navigation open (5-tab shell vs reference icon row).

Validation run in this turn: `dart analyze lib` clean; focused planner + page + controller gate 285/285 GREEN; full suite 605/605 GREEN.

This folder is honest mismatch evidence. It is not Copy acceptance.
