# Stage 42 — Local-first operations, causality and conflict correctness

Status: pending  
Depends on: Stage 41; Stages 13–14, 24, 28–30, 34 and 40 mutation semantics  
Blocks: Stages 44–50  
Primary surfaces: every planner write, durable outbox, undo, conflict center,
multi-device convergence, widget/notification/AI actions

## Mission

Make every action succeed atomically against local state first, survive crashes and
replay exactly once remotely. Define deterministic merge behavior per field and
preserve both meanings when automatic convergence would lose intent. “Last write
wins” is not an acceptable universal conflict policy.

## Autonomous product decisions

- One local transaction writes the canonical record/event and its operation-log row.
  A visible success is never possible without a durable replay instruction.
- Each user intent has a stable `mutation_id`. Retries, foreground/background widget
  execution and AI Apply reuse it; a second payload under the same ID is rejected.
- Server revision advances only after an authenticated RPC accepts an operation.
  Clients retain `base_revision`, per-field base versions and causal predecessors;
  they never manufacture remote revisions.
- Immutable history is append-only. Correction creates a compensating event linked
  to the original; sync never rewrites an occurrence/focus/progress event in place.
- Automatic merge is allowed only when semantics are provably independent. A real
  same-field/schedule/delete conflict is stored durably and shown to the owner.
- Undo is another idempotent operation with an explicit inverse and deadline, not a
  UI-only rewind or outbox deletion.

## Mandatory Stage 03–05 preview and Copy gate

Before any runtime change, extend the accepted Stages 03–05 direction. Use
`modernize` for the opinion ledger, `integrity` for the producer/consumer and state-
ownership map, `anatomy` for Conflict Center hierarchy/reachability, and `style` for
exact component/state/theme/motion specs.

- First approve operation lifecycle, causality/merge, conflict-resolution and
  offline-replay diagrams. Even data-only worker changes are blocked until these
  contracts and their user-visible state mapping are unambiguous.
- Preview individually: pending mark, queued/offline badge, Undo receipt, conflict
  count, conflict row, version comparison, field selector, edited merge, destructive
  conflict, resolution progress/success/error and queue diagnostic. Cover default,
  loading, empty, dense, disabled, hover/focus/press and validation/error variants.
- Preview whole flows at phone portrait/short landscape, tablet portrait/landscape,
  compact/expanded Windows, light/dark/high contrast, RTL/mixed text, 200% text and
  reduced motion. Include zero/one/many conflicts, very long note/schedule values,
  offline queue, auth-blocked queue and remote update during review.
- Label every artifact `Mock Preview`, record internal acceptance under the
  owner-delegated autonomous design authority and decompose it
  into live/vector/raster/hybrid assets, semantic/focus order, responsive rules and
  performance budgets. Keep owner content live; never flatten conflict values.
- Implement with `copy` fidelity only after that acceptance. Create normalized reference/
  fresh-runtime side-by-sides for every component plate and page composition, then
  close mismatch, precision and composition-occupancy ledgers without silent
  substitution.

## Operation-log contract

`PlannerOperationV1` contains `contract_version`, `mutation_id`, owner injected from
context, `device_id`, monotonic `local_sequence`, `target_type/id`, `verb`,
`base_revision`, `base_field_versions`, `causal_after`, canonical field patch,
`created_at`, optional `undo_of` and `source` (`app`, `widget`, `notification`,
`ai_review`, `import`, `recovery`). Payload size, depth and allowed paths are bounded.

Local state is `pending`, `sending`, `retry_wait`, `conflicted`, `acknowledged` or
`blocked_auth`; `sending` is a lease with expiry so a killed worker returns it to
pending. Persist attempt count, sanitized error code, next retry, server receipt and
acknowledged revision. Diagnostic text is separate from user data and never stores a
token or raw HTTP body.

The server enforces unique `(owner_id, mutation_id)`, verifies that a duplicate has
the same canonical hash, serializes per target, writes record + operation receipt +
change feed in one transaction and returns the saved snapshot/revision. Pull applies
change cursor and local projection in one transaction; cursor never advances past a
failed/quarantined change.

## Merge and conflict policy

| Data class | Deterministic policy |
|---|---|
| Independent entity scalar fields | Merge non-overlapping field paths. Concurrent edits to the same normalized field become an open conflict with base/local/remote values. |
| Title, note and custom text | Never concatenate or silently choose by clock. Show both versions and allow local, remote or edited merge. |
| Lifecycle | Archive versus ordinary edit preserves the edit and archives. Trash versus post-base edit is a conflict; restore is an explicit newer intent. Permanent purge never auto-merges. |
| Schedule, time zone and recurrence | Treat the active schedule/rule version as one semantic unit. Concurrent changes conflict; generated occurrences already in history remain tied to their rule version. |
| Relations and labels | Merge as stable-ID add/remove intents with observed-remove semantics; ordering uses stable position tokens plus deterministic tie-breaker. Referential deletion surfaces affected links. |
| Task progress | Same occurrence uses append-only outcome/correction events. Canonical fold by causal order prevents rapid taps from losing increments. |
| Habit count/duration/value/checklist | Delta events commute; absolute set/correction against the same base conflicts with concurrent absolute/delta meaning when it cannot be safely rebased. |
| Occurrence/focus history | Union by stable event ID and mutation receipt. Duplicate is ignored; contradictory event IDs are quarantined. |
| Goal measures | Recompute from canonical relations/events. Concurrent definition edits conflict; derived totals never sync as authority. |
| Reminder/settings projection | Entity reminder definition follows field policy; platform scheduled IDs remain device-local and are reconciled after merge. |

Conflict rows contain owner, target, field group, base snapshot/version, local intent,
remote snapshot, originating mutation, affected dependent records, creation time and
resolution status. Sensitive content is loaded only when the owner opens the item;
notification/widget surfaces show a count, not titles or values.

## Detailed work packets

1. Inventory every mutation entrypoint and map it to one `PlannerOperationV1` verb,
   inverse, field group, source and cross-consumer projection invalidation set.
2. Refactor repository writes into `runLocalCommand`: validate owner/current record,
   append event or update projection, enqueue operation and return a receipt inside
   one Drift transaction.
3. Add crash-safe send leases, per-owner single-flight drain, target ordering and
   bounded batching. Multiple isolates/connections coordinate through SQLite, not
   process-local booleans.
4. Implement server idempotency/hash verification, base/per-field revision checks,
   transactional change feed and explicit acknowledged/conflict/error responses.
5. Implement the merge table as pure functions with property/golden tests. Store
   unknown target kind/version in quarantine and stop only that target, not all local
   work.
6. Add durable conflict creation and resolution commands: Keep mine, Keep synced,
   Edit merged copy, Restore/Archive choice, and a per-field review for composite
   schedule/text conflicts. Resolution references the conflict and latest revision.
7. Add compaction that removes only acknowledged operations older than the retention
   watermark and covered by a verified snapshot. Pending, retry, blocked-auth,
   conflicted and undo dependencies are never compacted.
8. Route task status, habit rapid increments, recurrence recovery, focus, archive/
   trash/restore, import, widget, notification and AI Apply through the same command
   path. Delete parallel write implementations.
9. Add operation/conflict diagnostics with counts, oldest age, next retry and safe
   error codes; content export remains an explicit owner-reviewed action.
10. Document replay order, merge matrix, correction math, compaction proof and
    disaster recovery procedure for Stage 44 and future agents.

## Whole-product propagation

| Consumer | Required propagation |
|---|---|
| Today, Tasks, Plan, Habits and Goals | Optimistically update only affected rows/metrics; pending/conflict marks survive navigation and remote changes do not reset filters or scroll. |
| Focus | Begin/pause/end and reflections are durable events; app kill/background and duplicate completion converge once. |
| Capture and editors | Save returns a local receipt immediately; repeated taps are coalesced by mutation ID and conflict errors preserve the complete draft. |
| Details/history | Timeline shows source/correction truth and can open the exact unresolved field conflict. |
| Android widget | Rapid task cycles/habit increments serialize through the database, remain actionable offline and receive acknowledgement without duplicate values. |
| Notifications | Action buttons use stable mutation IDs and the same status/log rules; late duplicate callbacks are harmless. |
| Deep links | Carry target/action only; resolving an action still fetches owner/current revision and asks for destructive confirmation in app. |
| Perfect AI | Apply converts approved actions to allowlisted operations; retry/reopen reuses IDs and Rejected produces zero operations. |
| Settings and diagnostics | Show queue/conflict health and safe retry; no “clear queue” shortcut. |
| Archive/trash/recovery | Lifecycle operations retain dependent history; restore/import participates in the same merge and undo contracts. |
| Release/upgrades | Schema migrations preserve every non-acknowledged operation, lease, conflict, inverse and causal edge. |

## User-visible conflict and offline UX

Normal offline work looks complete locally; a subtle row pending mark and yellow
cloud explain that changes are waiting. No modal appears for mere disconnection.
True conflicts show a non-color icon/count in the cloud detail and affected row; the
content remains usable until the owner chooses.

On phone, Conflict Center is a full-height safe-area route with one conflict at a
time, concise consequence summary and whole stacked actions. Tablet uses a bounded
sheet or adjacent review pane when both versions retain readable width. Windows uses
a resizable two-column list/review workspace with keyboard next/previous, selectable
text and Escape hierarchy. At 200% text, versions stack rather than squeeze; screen
readers announce field name, origin/time and resolution consequence. Reduced motion
replaces merge animations with immediate focus-preserving state changes.

Errors distinguish offline, retry scheduled, sign-in required, unsupported data and
manual conflict. Retry never disables local capture/logging. Resolving one conflict
updates the originating detail/list/widget projection without closing unrelated
drafts, replaying page entrance or moving the scroll anchor.

## Performance, security and rollback

- Budget local command commit independently from widget render and network; test p95
  with 10k entities, dense histories and 10k queued operations. Indexed queue drains
  and conflict counts must not scan payload JSON.
- Bound server batches and concurrent targets; apply backpressure without losing
  operations. Connectivity/auth failures use error classes, not message parsing.
- RPC derives owner and allowlists target/verb/path. RLS, composite foreign keys,
  canonical hash and two-owner tests prevent forged owner/ID/duplicate payloads.
- Logs redact content and credentials. Conflict snapshots are owner data and follow
  backup/export/privacy rules.
- Feature rollback stops new drains and returns to the last compatible worker while
  retaining new operations/conflicts. Never downgrade by deleting the outbox or
  rewriting immutable history; forward-repair an incompatible record.

## Verification and required evidence

- Transaction-fault tests at every point between projection write, event append and
  enqueue prove all-or-nothing local results and recovery after process kill.
- Duplicate replay, mismatched duplicate hash, out-of-order change pages, stale
  revision, lease expiry, reconnect and compaction property tests pass.
- Two simulated devices exhaust the merge table, including schedule/delete, 20 rapid
  habit increments, task correction, relation ordering and simultaneous focus end;
  canonical hashes converge deterministically.
- Offline create/edit/log/archive/restore/import/AI/widget/notification matrices pass
  through app restart and later synchronization.
- Phone/tablet/Windows conflict screenshots, keyboard/semantics tests, 200% text,
  RTL/mixed text and empty/one/many conflict states pass.
- Pending/conflicted operations survive signed N→N+1 Android and Windows updates and
  subsequently acknowledge once against the test Supabase project.

## Reject the stage if

- Any visible mutation can change local projection without a durable operation, or
  any retry can duplicate history/value.
- Timestamp last-write-wins silently chooses same-field text, schedule or destructive
  intent.
- Conflict resolution discards one version before recording a durable decision, or
  “Clear queue/reset data” is the normal recovery path.
- Tests use one in-memory repository and claim multi-isolate, multi-device or remote
  convergence proof.
- Runtime work begins before accepted diagrams/previews, or default/error/dense/
  responsive states do not match their accepted references item by item.

## Handoff and release

Stage 44 receives the frozen operation state machine, retry/error taxonomy, change
cursor, merge matrix, conflict APIs and compaction watermark. Commit/push the shared
write-path implementation and evidence, run CI and signed upgrade/replay proof on
Android and Windows, record remote RPC deployment separately, and leave clean
`main` only.
