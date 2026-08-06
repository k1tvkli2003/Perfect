# Stage 15 — Today empty, loading, offline, retry and optimistic states

Status: pending  
Depends on: Stages 11–14  
Primary surfaces: Today and all shared rows/controls

## Mission

Make Today useful and trustworthy before, during and after data/sync problems. A
fresh private owner sees a genuinely empty planner, not fake tasks or a sterile
blank screen; network failure never hides local work.

## Mandatory preview and Copy entry gate

- Bind implementation to every `st-*` component plus `pg-today-empty`,
  `pg-today-offline`, `pg-today-retry-error` and `pg-today-conflict` compositions.
- Preview transition pairs—boot→local, local→syncing, optimistic→saved/rollback,
  offline→retry→synced and conflict→resolved—with unchanged content anchors.
- Keep real owner content/live queue state semantic; empty-state art is a separate
  project-owned asset with small/dark/high-contrast variants and no fake entities.
- Compare reference/runtime at identical system state and verify focus/scroll/draft;
  a visually correct screen that refreshes/replays entrance or blocks local work fails.

## State model

1. Boot/local opening: compact branded skeleton only until local DB is readable.
2. Local ready/remote pending: show real local content immediately plus yellow sync.
3. Empty owner: no entities/history; present Today Pulse and one concise capture/
   plan invitation with no fictional dates, counts, names or placeholder rows.
4. Optimistic mutation: update exact row/value immediately; preserve Undo and mark
   pending sync subtly.
5. Offline: content and actions remain active; queue state is visible but quiet.
6. Retryable sync error: red cloud, local content retained, bounded retry/details.
7. Local data error: actionable recovery/diagnostic path; never reset automatically.
8. Conflict: preserve both meaningful versions and route to explicit resolution.

## Work packets

1. Trace/remove production reachability of every preview/sample/default entity.
2. Separate dev preview package/entrypoint/database namespace and add release guard.
3. Design authored empty illustrations/pictograms only where they help action;
   avoid generic large empty-state cards that dominate the page.
4. Add row-level pending/rollback/undo state without global spinners.
5. Replace scroll-triggered refresh with local/realtime subscriptions; keep explicit
   refresh only in sync diagnostics/recovery.
6. Preserve scroll anchor, composer draft, detail selection and keyboard focus when
   remote updates arrive.
7. Add diagnostic feedback capture link for unrecoverable local errors without an
   intrusive permanent launcher.

## Edge scenarios

- Valid owner and truly empty local/remote DB.
- Remote has data but first sync delayed; local has pending data but auth expired.
- Mutation succeeds locally then server rejects; app killed before retry.
- Entity disappears remotely while visible; conflict arrives during quick logging.
- Dense list updated from second device while user is typing/scrolling.

## Verification

Release-entrypoint fixture isolation test; clean-account integration test; offline
mutation/replay; remote notifier update exactly once; no pull-refresh-on-scroll;
empty/sparse/dense/error screenshots; state/focus/scroll retention tests.

## Reject if

- Production account receives sample Task/Habit/Plan/Note data.
- Error state offers destructive reset as the default fix.
- A remote update rebuilds the page enough to close keyboard, move scroll or replay
  entrance animation.

## Handoff

Stage 16 receives stable Today bottom insets and system-state behavior. Commit/push/
release, verify signed clean-account build and leave Git clean.
