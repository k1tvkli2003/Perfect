# Stage 44 — Sync runtime, background refresh and conflict delivery

Status: pending  
Depends on: Stages 08, 15, 41–43  
Blocks: Stages 45–50  
Primary surfaces: top Sync Cloud, local projections, realtime/background workers,
Conflict Center, widget/notification refresh and owner diagnostics

## Mission

Turn the three-state Sync Cloud into a truthful projection of the durable queue,
network, auth, remote cursor and conflicts. Local work remains immediately usable;
realtime, reconnect and bounded background refresh converge changes exactly once
without scroll-triggered requests, retry storms or whole-page rebuilds.

## Autonomous product decisions

- The cloud has exactly three primary visual states: green `Synced`, yellow
  `Syncing / changes waiting / retry scheduled`, and red `Needs attention / last
  error`. Icon/label/semantics accompany color. Offline with safely queued work is
  yellow; rejected auth, unsupported schema, poisoned change or exhausted/manual
  conflict attention is red.
- Green requires: local schema ready, no pending/sending/retry/auth-blocked operation,
  no unconsumed remote hint, pull cursor caught up and at least one successful sync
  for the active owner/server capability. A timer alone can never turn it green.
- Realtime is a change hint, not data authority. Every hint schedules a durable
  cursor pull; gaps, reconnects and process restarts reconcile from the server.
- One per-owner sync coordinator owns push/pull/retry/subscription lifecycle across
  foreground and background triggers. Triggers coalesce; they do not spawn workers.
- Retry uses exponential backoff with full jitter, a defined maximum delay and an
  attempt/reset policy. Connectivity resume and explicit Retry may advance the next
  attempt but still pass through single-flight/idempotency checks.
- User scroll never performs a network refresh. Lists subscribe to narrow Drift
  projections; an explicit diagnostic refresh exists only in Sync details.

## Mandatory Stage 03–05 preview and Copy gate

Before runtime implementation, extend the internally accepted Stages 03–05 visual
direction with `modernize`, `integrity`, `anatomy` and `style`, then reproduce accepted
references with `copy`.

- Approve diagrams for trigger coalescing, push/pull/cursor order, retry/jitter,
  auth/circuit states, realtime gap recovery, background platform lifecycle and
  projection invalidation before worker code changes.
- Preview every component independently: green/yellow/red cloud at all icon sizes;
  hover/focus/press; last-sync line; pending count; retry countdown; progress phase;
  sanitized error; Retry; conflict entry/count; connection badge; background-support
  disclosure; and row-level pending/conflict mark.
- Preview complete header popover, phone Sync route, tablet sheet/adjacent pane,
  Windows Sync/Conflict workspace and settings diagnostic composition in loading,
  empty/synced, offline queued, active progress, retrying, auth-required, server/
  schema error, conflict and dense-queue states.
- Cover phone portrait/short landscape, tablet portrait/landscape, compact/expanded
  Windows, light/dark/high contrast, RTL/mixed/long text, 200% text, keyboard/pointer/
  touch and reduced motion. Also preview widget pending/error and notification/deep-
  link stale/missing recovery states that this coordinator causes.
- Label artifacts `Mock Preview`, record acceptance and create a live/vector/raster/
  hybrid decomposition manifest with semantic order, anchors, responsive transforms,
  motion, refresh rates and performance budgets. Dynamic status/data stay live.
- Implement only after recorded internal acceptance. Run component-by-component and page-by-page
  normalized reference/runtime side-by-sides; close Copy mismatch, precision and
  composition-occupancy ledgers. Tests or green bounds do not certify fidelity.

## Sync state and API contracts

`SyncSnapshotV1` is a derived local projection with `phase`, connectivity class,
pending/retry/blocked/conflict counts, oldest pending age, active phase, last attempt,
last success, next retry, safe error code, cursor health and background capability.
It contains no token, URL, raw response or planner content. UI consumes this one
stream; it does not derive cloud color in multiple widgets.

`SyncCoordinator` exposes `start(ownerContext)`, `request(reason)`,
`retryNow()`, `pauseForAuth()`, `resumeAfterAuth()`, `snapshotStream` and
`dispose()`. Reasons are typed: local operation, app start/resume, realtime hint,
connectivity regained, background wake, widget action, notification action, AI Apply,
import/recovery and explicit diagnostic retry. Each request is persisted/coalesced so
a process kill cannot hide required reconciliation.

### Deterministic synchronization cycle

1. Acquire the per-owner/device lease and current SessionCoordinator capability.
2. Pull all remote changes after the committed cursor in bounded pages; validate and
   atomically apply each page with its cursor.
3. Push pending operations in local causal order, serial per target and bounded in
   parallel across independent targets. Record acknowledgement/conflict/retry.
4. Pull again until caught up so server transforms and concurrent device writes are
   projected.
5. Reconcile reminders, widget payload, search/derived projections and conflict count
   from changed IDs only; then compute/persist the truthful SyncSnapshot.
6. Release lease. If a trigger arrived during the cycle, run one coalesced follow-up.

Malformed/unsupported remote records enter an owner-scoped quarantine with cursor
and safe reason. The cursor does not skip them; unaffected local work remains usable
and the cloud turns red with a diagnostics/recovery path.

## Trigger and platform policy

- Foreground: start after local owner workspace opens; trigger on durable operation,
  app resume, connectivity regain, explicit Retry and realtime hint.
- Android: use a unique owner-scoped WorkManager job with network constraints and
  platform-legal cadence; widget/notification actions enqueue local mutations first,
  then request work. Do not claim exact periodic timing under Doze.
- Windows installed build: sync while process is active and on launch/resume/network
  change. Register a packaged background task only if installer identity/capability is
  proven; otherwise diagnostics says “Syncs when Perfect! is open.” Portable ZIP must
  never imply an unsupported always-on background service.
- Realtime channel filters the active owner, is unique per coordinator, reconnects
  with lifecycle, and is removed on sign-out/owner/project change.
- Background executions share database lease/idempotency with foreground and cannot
  initialize a second conflicting auth/client/store namespace.

## Detailed work packets

1. Inventory all existing sync triggers, timers, realtime channels, scroll refresh,
   controller reloads, background/widget paths and cloud-state calculations. Create a
   trigger→coordinator→consumer integrity matrix and delete duplicated ownership.
2. Implement persisted trigger coalescing, per-owner lease, cancellation/dispose and
   phase/error telemetry around the Stage 42 worker. Prove kill/lease expiry recovery.
3. Implement connectivity classification without assuming “connected” means internet
   or Supabase reachable. Map timeout/DNS/TLS/5xx/429/auth/schema/conflict/quarantine to
   stable safe error codes and owner actions.
4. Add exponential full-jitter retry with cap, server `Retry-After` respect, auth
   circuit breaker, maximum immediate attempts and persisted next retry. Never spin on
   a poison operation/change.
5. Harden cursor paging, realtime gap/reconnect and duplicate/out-of-order event
   handling. Apply canonical snapshot only through Stage 41 repositories and preserve
   Stage 42 pending local intent.
6. Replace broad refreshes with changed-ID projection invalidation and narrow Drift
   streams. Batch UI notifications per transaction/frame and preserve drafts, focus,
   selection, calendar/scroll and entrance-animation state.
7. Reconcile widget and reminders after committed local changes, not network callback
   arrival. Give background work strict time/row budgets and leave remaining work
   durably queued.
8. Build one Sync details contract and Conflict Center entry. Expose safe last success,
   queue counts/age, retry timing and error-specific next action; never expose raw
   endpoint, SQL, token or planner payload in ordinary UI.
9. Add diagnostics correlation IDs and aggregate latency/queue metrics locally; any
   export is owner-reviewed and Stage 45-redacted. No analytics becomes sync authority.
10. Document platform limitations, worker lifecycle, operational error playbook and
    release capability matrix for APK, Windows setup and portable ZIP.

## Whole-product propagation

| Consumer | Required propagation |
|---|---|
| Today, Tasks, Plan, Habits and Goals | Narrow local streams update affected records/metrics once; remote changes preserve filter, selected date, scroll, focus and breakpoint state. |
| Focus | Active timer is never interrupted by sync; completed remote/local sessions reconcile history and derived totals once. |
| Capture/edit/details | Save remains local-first; drafts survive remote updates and same-field conflict routes to Stage 42 without closing editor. |
| Android widget | Projection refresh follows committed local data; action remains offline-capable and pending/error state is truthful at every widget size. |
| Notifications | Reminder reconciliation uses canonical schedule after each changed-ID batch; actions dedupe and deep-link current record. |
| Deep links/Windows protocol | Bootstrap intent waits for local/auth readiness, never waits for full sync, and later missing/archived change updates the open detail safely. |
| Perfect AI | Conversation may explain offline/auth failure; approved writes enqueue locally and AI never bypasses the coordinator or waits on remote to show success. |
| Archive/trash/import/recovery | Bulk changes use bounded operations/invalidation; sync status shows progress without dropping or duplicating records. |
| Settings/diagnostics | One snapshot drives header and detailed health; platform background limitations and retry action stay consistent. |
| Release/upgrades | Persist queue, cursor, retry, leases, quarantine and last-success safely across N→N+1; old worker cannot run concurrently after update. |

## Exact user-visible behavior

Tapping/clicking the cloud opens concise state details, not a manual refresh menu.
Green leads with “Synced” and last success; yellow names “Syncing”, “Offline—changes
saved here” or “Retrying in …”; red names the safe category and primary recovery
action. Conflict count opens Conflict Center; auth failure opens reauthentication;
unsupported data opens diagnostics/recovery. Local actions never become disabled just
because the cloud is yellow/red.

Phone uses an anchored popover when space permits and promotes dense/actionable
content to a full-height route. Tablet uses a bounded sheet or adjacent panel without
covering the daily work unnecessarily. Windows uses a keyboard-accessible anchored
flyout for summary and full Settings > Sync/Conflicts workspace for detail. Resizing
preserves selected conflict, scroll and focus.

Progress animation is restrained, does not replay on every trigger and becomes a
static icon/text change under reduced motion. Retry countdown announcements are not
spoken every second. At 200% text, rows/actions stack; no label is ellipsized if it is
the only explanation or action.

## Performance, security and rollback

- Set Stage 05 budgets for local mutation-to-projection, remote change-to-local
  projection, startup sync CPU/memory, queue query, widget publish and idle network.
  Profile sparse, 10k-record and 10k-operation cases on real Android/Windows.
- No perpetual polling, duplicate subscription, unbounded page/batch, timer per row,
  full-table payload scan or page-wide ChangeNotifier rebuild.
- Every remote call uses Stage 43 owner session and Stage 41 RPC/RLS; logs retain safe
  code/correlation only. TLS/auth errors never include raw server bodies in UI.
- Feature rollback disables background/realtime triggers and falls back to explicit
  foreground single-flight while retaining operations/cursor/retry/quarantine. It
  never clears a queue or rolls cursor forward to hide a poison record.

## Verification and required evidence

- Fake-clock/property tests prove trigger coalescing, full-jitter bounds, Retry-After,
  auth circuit, lease expiry, cursor monotonicity and no dropped wakeup race.
- Network matrix: offline before start, loss in pull/push/ack, DNS/TLS/timeout, 429,
  5xx, auth revoke, schema incompatibility, malformed change and recovery.
- Remote matrix: insert/update/archive/trash from device B, duplicate/out-of-order
  realtime hints, missed hints/reconnect and true Stage 42 conflicts; device A updates
  each required projection exactly once.
- UI state/focus/scroll/draft instrumentation plus phone/tablet/Windows real-runtime
  recordings prove no whole-page refresh, keyboard close, route duplication, entrance
  replay or retry storm.
- Android WorkManager and widget host evidence; Windows installed/portable behavior
  evidence with limitations stated; notifications and deep links pass cold/warm flows.
- Signed N→N+1 upgrade with pending/retry/conflict/quarantine fixtures resumes safely
  and preserves session/data. Artifact/log scans remain secret-free.
- Every accepted component/page preview has a normalized real-runtime Copy comparison
  across state/theme/layout/a11y matrix and clean mismatch/precision ledgers.

## Reject the stage if

- Cloud color is inferred from network reachability/spinner alone, green appears with
  pending/cursor-gap work, or color is the only state cue.
- A scroll gesture triggers sync, a remote event rebuilds the whole page, or retry can
  loop without persisted cap/jitter/next action.
- Realtime is treated as durable delivery, a cursor skips malformed data, or
  background/foreground workers can race the same operation.
- Windows portable/setup or Android background behavior is claimed without real host
  evidence.
- Runtime implementation starts before accepted diagrams/previews or deviates from
  accepted references without a documented adaptive rule and reopened internal gate.

## Handoff and release

Stage 45 receives the canonical SyncSnapshot, safe diagnostic/error vocabulary,
queue/conflict health APIs, background-capability matrix and recovery triggers.
Commit/push only after CI, two-device Supabase tests, Android/Windows host recordings,
signed upgrade/replay and Copy evidence pass; record remote deployment independently
and leave clean `main` only.
