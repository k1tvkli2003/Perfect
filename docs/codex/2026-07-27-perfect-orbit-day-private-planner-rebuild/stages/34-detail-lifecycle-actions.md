# Stage 34 — Detail actions and entity lifecycle safety

Status: behavior-complete, committed as HEAD (pushed to feat/stage13-status-undo, PR #4, 2026-09-26) — explicit Edit separation, context-menu placement, archive
compatibility naming, duplicate-ID reset, and owner-scoped mutation suites are
GREEN; confirmation semantics, cross-consumer invalidation, conflict/offline
replay, and native matrices remain open
Depends on: Stages 25, 31–33  
Primary surfaces: detail action hierarchy, context menus, archive/conflict surfaces

## Mission

Organize immediate, reversible and destructive actions so normal viewing is fast and
dangerous operations are deliberate. Keep every lifecycle mutation owner-scoped,
local-first, idempotent and reflected across all consumers.

## Mandatory preview and Copy entry gate

- Bind implementation to `det-lifecycle-actions`, `ct-split-action`, `ct-menu`,
  `st-destructive-confirm`, `ct-toast-undo`, `pg-detail-lifecycle-confirm`, archive/
  trash and conflict compositions.
- Preview task/habit/goal/project/note variants, compact/wide placement, hover/focus,
  archive/Undo, duplicate, pause, conflict and delete consequence states.
- Implement from one lifecycle/action registry and compare every detail/context menu/
  keyboard/native entry consumer; anonymous local action order is not allowed.
- Visual acceptance is paired with exact owner/revision re-fetch, operation idempotency,
  cross-consumer update and no-write-on-cancel evidence.

## Action hierarchy

- Immediate: status/log, Focus, reschedule/today action.
- Primary contextual: Edit.
- Reversible secondary: Duplicate, Archive, move project/category, pause recurrence.
- Data/utility: Export/share private record, copy summary, open sync/conflict detail.
- Destructive: Delete/erase scoped history, separated visually and behind explicit
  consequence-aware confirmation.

## UX rules

- Do not place frequent actions behind three-dot overflow if space/relevance allows.
- Do not show every low-frequency action permanently. Use an anchored adaptive More
  surface with project-owned icons, whole labels and keyboard navigation.
- Archive provides immediate Undo and remains recoverable in Archive Center.
- Duplicate creates a new stable ID but preserves intentional fields and clearly
  resets history/status/occurrence links.
- Delete language states local/remote/history scope. Default is safest reversible
  alternative where product semantics permit.

## Data/authorization

Each mutation re-fetches current owner/entity/revision, validates scope and emits an
idempotent operation. Model-provided/entity-supplied owner IDs are never trusted.
Conflicting remote revisions surface merge/decision before destructive action.

## Cross-consumer updates

After mutation update detail, Today/Tasks/Plan/Habits, goals/relations, notifications,
widget payload, search index, AI context and sync queue without full app refresh.

## Edge scenarios

Offline archive/delete, duplicate tap, remote deletion during confirmation, entity
with child relations/history, active focus timer, placed widget, pending AI proposal,
auth expiry and Undo after sync.

## Verification

Authorization/idempotency tests; action placement/focus/semantics; archive/restore/
duplicate/delete data effects; cross-consumer notifier tests; conflict and offline
replay; confirmation/Undo screenshots and keyboard/touch flows.

## Reject if

- Row tap or innocuous gesture can archive/delete.
- Duplicate copies occurrence history or stable IDs.
- UI updates only after global refresh/restart.

## Handoff

Stage 35 receives stable detail actions for inspector/deep-link contexts. Commit/push/
release with lifecycle proof and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 34 partial)

- Desktop context/keyboard rows
  (`desktop context menu is mouse and keyboard reachable with named archive
  confirmation`, recurring controls) GREEN inside the integrated workspace
  gate.
- `duplicateEntity` fresh-ID/history-reset behavior and owner-scoped
  archive/restore/delete controller vectors GREEN in the same gate.
- Confirmation/Undo receipts, cross-consumer notifier invalidation, conflict
  and offline replay, and screenshots remain open.
