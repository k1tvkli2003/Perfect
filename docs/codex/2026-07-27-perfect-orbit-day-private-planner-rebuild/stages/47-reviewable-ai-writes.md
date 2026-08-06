# Stage 47 — Reviewable and undoable AI planner writes

Status: pending  
Depends on: Stages 25, 31–45 and 46  
Blocks: Stages 49 and 50  
Primary surfaces: AI proposal review, local apply coordinator, planner operation
queue, audit/undo history, Supabase convergence, affected lists/details/widget

## Mission

Complete the only lawful write path for Perfect AI: schema-aware read context →
typed proposal → human-readable diff → explicit confirmation → one atomic local
transaction → durable sync operations → audit → compensating undo. A model response
alone has no authority, and no planner mutation may be silent.

The title is not a scope boundary. Every accepted AI action must produce the same
domain, sync, history, reminder, widget and UI result as the equivalent manual action.

## Autonomous decisions

- Move authoritative apply into a Flutter/domain `PlannerAiApplyCoordinator`. The
  Edge Function generates and authenticates proposals but does not directly create
  remote planner rows. Confirmed AI writes enter the same local-first store and
  operation queue as manual writes; Supabase convergence follows Stage 42/44.
- Use a versioned, explicit action registry. Initial actions cover create/update for
  Task, recurring Task, Habit, Note, Project, Area and Goal; schedule/reschedule;
  relations/linking; Task status/progress and method-valid Habit logging. Each action
  delegates to the canonical domain validator, never to arbitrary map ingestion.
- Exclude credential/settings changes, provider configuration, raw SQL/RPC, file or
  URL execution, notification delivery, account/session operations, permanent purge
  and external messaging. Archive/delete require their existing manual lifecycle
  flow and are not smuggled through a generic AI update.
- Apply the reviewed set all-or-nothing. If the owner removes or edits an item, build
  a new derived proposal/diff and require a fresh confirmation; never partially
  apply the hash that was reviewed.
- A confirmation is valid only for the exact canonical proposal hash and expected
  source revisions. Changed entities create a visible stale/conflict state and
  require rebase/regeneration, not silent last-write-wins.
- Undo is a new, audited compensating operation group using the post-apply revisions;
  it never deletes immutable occurrence/focus history or rewinds the database file.

## Accepted preview and Copy-fidelity gate

Before any review/apply runtime or schema edit, extend the approved Stage 03 direction
and Stage 04–05 component/quality contracts through `modernize` + `integrity` +
`anatomy` + `style`, then freeze the internally accepted result as the `copy` reference.
The work order must contain a five-way opinion ledger, concept-to-consumer integrity
matrix, action/recovery anatomy, math/precision ledger, motion storyboard and preview-
to-production asset/live-component manifest. Approval is a hard dependency, not a
retroactive screenshot exercise.

Preview individually: proposal chip/receipt, item row, entity pictogram, before/after
field, schedule/relation consequence, no-change explanation, conflict/stale warning,
selection/removal control, Apply/Dismiss, progress, local-commit receipt, sync state,
audit entry and Undo/undo-conflict. Preview complete review compositions for one item,
mixed multi-entity bundle, long diff, conflict, invalid/security rejection, applying,
locally applied/offline, syncing, synced, partial transport failure and undo at every
phone/tablet/Windows composition, light/dark/high contrast, RTL/mixed, 200% text,
keyboard/IME and reduced motion.

Every reference names exact copy, bounds, alignment axis, visible item count, wrap/
scroll/sticky behavior, focus order, asset provenance and first/mid/end/reversal motion
frames. Dynamic planner values and all confirmation controls remain live semantic UI.
Implementation reproduces the accepted hierarchy and geometry responsively; no generic
diff card, stock warning, placeholder icon or flattened critical copy may substitute.

## Allowlisted action contract

| Action family | Required identity/precondition | Domain result |
|---|---|---|
| `task.create`, `task.update`, `recurring_task.create/update` | client UUID; expected revision for update | canonical Task/rule plus schedule/checklist relations |
| `habit.create`, `habit.update`, `habit.log` | method/rule version; expected revision/day | canonical Habit or immutable occurrence/log event |
| `note.create/update` | stable ID; expected revision for update | owner-scoped Note without executable attachment/URL behavior |
| `project.create/update`, `area.create/update`, `goal.create/update` | stable ID/revision and relationship checks | canonical hierarchy with no orphan/cycle/double count |
| `schedule.set/reschedule` | entity ID/revision, timezone and temporal policy | canonical schedule/occurrence exception |
| `relation.link/unlink` | both owner-scoped IDs and relation version | validated Project/Area/Goal/entity relation |
| `task.status/progress` | entity/occurrence ID, expected state/revision | same state machine and immutable event as manual control |

Every registry entry declares JSON schema, maximum size/count, validator, local
command, inverse/undo builder, audit serializer, sync projection and UI consumers.
Unknown action names or extra privileged fields are rejected before diff generation.

## Work packets

1. **Freeze manual command semantics.** Map each allowlisted action to the canonical
   editor/status/log/recovery command and record validation, occurrence/history,
   reminder and sync side effects. Fill gaps in domain services before adding AI.
2. **Replace direct server ingestion.** Retire `apply_proposal`/`submit_agent_plan`
   as an authoritative remote-first write path. Keep a compatibility rejection or
   narrow migration bridge so an older client cannot bypass local review. Do not
   delete existing audit/history records during migration.
3. **Build the registry and typed decoder.** Parse the Stage 46 envelope into sealed
   actions; enforce owner from session, schema version, stable UUIDs, enum/date/time
   semantics, payload bounds, relationship constraints and action-specific fields.
   Never pass model maps directly to Drift or Supabase.
4. **Resolve and diff against current local state.** Re-read each entity by owner +
   stable ID, compare expected/current revision, calculate canonical before/after,
   derived schedule/history effects, collisions, reminder changes and linked-goal
   consequences. Creation diffs state exactly what is new; updates highlight only
   changed fields while retaining unchanged context for meaning.
5. **Design the review model.** Produce ordered sections for New, Changed, Schedule,
   Relationships and Conflicts. For each item show entity type/title, before → after,
   local date/time/timezone, recurrence/recovery, affected day/project/goal and any
   irreversible consequence. “No change” actions are removed and explained.
6. **Require explicit confirmation.** Apply is disabled until decoding, current-state
   hydration, diff and conflict checks complete. Confirmation captures proposal hash,
   context/current revision set, local owner and a new apply operation ID. Displaying,
   scrolling, pressing Enter in the prompt or saying “yes” to voice never applies.
7. **Commit atomically and locally first.** In one Drift transaction, execute all
   domain commands, append immutable domain/history records, enqueue idempotent sync
   operations, write the AI audit row and undo recipe, and mark the proposal applied.
   Any validation/storage failure rolls back every planner/audit/queue change.
8. **Make apply crash- and retry-safe.** Key the group by `(owner, submission_id,
   canonical_hash)` and each operation by stable UUID. A retry after timeout/crash
   returns the stored receipt; it cannot duplicate entities, occurrences, relations,
   notifications or audit rows.
9. **Propagate one committed snapshot.** Publish a single controller invalidation
   after commit, then project widget/reminders/search/analytics from canonical local
   data. Avoid per-action route rebuilds, scroll jumps and transient half-applied UI.
10. **Synchronize normally.** Let Stage 42/44 send the queued operations with bounded
    retry. Show locally applied / syncing / synced / conflict states separately. A
    server outage never rolls back the confirmed local transaction or re-runs AI.
11. **Implement audit and undo.** Audit source, proposal/model/prompt/schema versions,
    canonical hash, action IDs, redacted before/after summary, timestamps, apply
    receipt and sync outcome. Undo shows its own diff, requires explicit confirmation,
    validates current revisions and creates compensating operations plus an audit
    link; expired/conflicting undo explains why it cannot proceed safely.
12. **Migrate pending proposals.** Preserve reviewable Stage 46 proposals through app
    restart and N→N+1. Old proposals missing hash/revision/action schema remain visible
    as read-only history but cannot be applied; offer regenerate with current context.

## UI/UX and motion contract

- Proposal review is an intentional state of the embedded AI instrument. The summary
  says “proposal—not saved”, identifies the number/types affected and exposes Review
  and Dismiss; only the expanded verified diff exposes Apply.
- Use live text and controls for every decision-critical field. Do not flatten dates,
  consequences, validation errors or Apply into an image. Project-owned SVGs may
  support type/status identity but never replace semantic copy.
- Changed fields use restrained before/after emphasis plus explicit labels, not red/
  green alone. Conflicts are above Apply, linked to the affected item and keyboard
  reachable. Long notes are collapsed with an accessible reveal, not destructive
  ellipsis of the changed meaning.
- Apply enters one progress state, then a receipt summarizing applied locally and
  current sync state. The animation never implies remote sync before convergence.
  Undo is visible for the configured safe window and remains discoverable in audit.
- Dismiss/reject has zero planner side effect and keeps the conversation. Reduced
  motion substitutes state/shape changes for morph, count-up or celebration.

## Responsive and device behavior

- **Phone/IME:** review becomes a full-height scrollable composition when needed;
  sticky actions respect safe area/keyboard, never cover the last diff, and stack at
  200% text. Back dismisses transient detail before leaving review.
- **Tablet:** use a bounded proposal list plus selected-item diff only when both panes
  retain readable width. Rail changes keep selection, scroll and confirmation state.
- **Windows:** compact width uses the phone-like linear review; expanded width may use
  proposal navigator + diff inspector. Support arrows between items, Space/Enter for
  explicit controls, Escape cancel and stable visible focus through resize.
- Applying or undoing cannot be triggered twice by rapid tap/click, key repeat,
  double window events, background/resume or two open views of one proposal.

## Domain, security and data contracts

- Proposal authority is `(owner, submission_id, schema_version, canonical_hash,
  expected_revisions)`. The UI cannot edit this object in place; a derived proposal
  receives a new ID/hash and review lifecycle.
- The registry is deny-by-default and shared by decoder, diff builder, apply, audit,
  undo and tests. Domain invariants—owner isolation, recurrence, habit method,
  hierarchy acyclicity, timezone/day boundary and immutable history—remain final.
- One local transaction contains planner rows, operation-log rows, audit receipt and
  proposal state. Sync acknowledgements append/update delivery metadata without
  rewriting the reviewed before/after record.
- Audit/export redacts provider secrets, auth tokens and unnecessary private prompt
  bodies. Backup/import versions AI audit and pending proposal data without treating
  imported audit as authorization to reapply.

## Offline, errors and retries

- An already hydrated, unexpired proposal may be reviewed and applied offline after
  rechecking local revisions. It commits locally and enters the normal durable queue;
  the UI says “saved locally—waiting to sync”. Generation/regeneration still needs
  the Stage 46 service.
- Apply retry uses the same operation/group receipt. Validation, storage-full or
  transaction failure leaves zero partial writes. Post-commit UI refresh failure can
  be recovered by rehydrating the stored receipt, not reapplying.
- Remote rejection becomes a normal sync conflict tied to the affected operation and
  AI audit. Automatic bounded retry is allowed only for retryable delivery failures;
  authorization/schema/domain rejection requires visible resolution.
- If any expected revision changed, stop before mutation. Offer inspect conflict,
  regenerate proposal or dismiss; never merge model and user edits silently.

## Accessibility and performance

- Screen readers announce proposal count, item type, changed fields, conflict count,
  Apply availability, local commit, sync state and Undo result. Focus moves to the
  first error on failed validation and to the receipt after successful commit.
- Diff reading order is identical visually and semantically in RTL/mixed copy. At
  200% text, labels/actions remain whole and the review is scrollable in both axes
  only where code/user text truly requires horizontal preservation.
- Decode/diff large proposals off the UI-critical path, cap proposal/action count,
  batch current-state queries and publish one controller update. Apply transaction
  and first visible result must meet Stage 05 latency/frame budgets on the dense
  fixture; no N+1 entity query or per-row widget refresh.

## Verification and required evidence

1. A registry coverage test fails when an action lacks schema, validator, command,
   inverse, audit, sync or consumer mapping; unknown/extra privileged actions fail.
2. For every action family and every entity kind, run the full vector: prompt fixture
   → proposal → hydrated diff → explicit Apply → local list/detail/history → queued
   operation → Supabase convergence → widget/search/analytics where applicable.
3. Assert zero planner/audit/queue writes for malformed hash/schema, stale revision,
   foreign ID, cross-owner relation, invalid recurrence/habit method, ambiguous date,
   oversized payload, dismissed proposal and simulated crash before transaction end.
4. Assert exactly-once results for double tap, client retry, process death after
   commit, duplicated queue replay, duplicate realtime echo and two-device delivery.
5. Prove all-or-nothing with a multi-entity plan whose final action fails validation;
   counts, hashes, history and queue remain identical to before.
6. Undo vectors cover create/update/schedule/link/status/log, current-revision
   conflict, sync pending/synced, process restart and immutable-history preservation.
7. Runtime screenshots/recordings cover new/changed/conflict/long diff, phone with
   IME, tablet rail states, Windows compact/expanded, RTL/mixed, 200% text, dark/high
   contrast, reduced motion, offline, retry and error.
8. Run focused AI/domain/local-store/sync/widget tests, full analyze/test, RLS/RPC
   verification and the signed artifact secret scan. Live Supabase evidence must use
   the private owner and a sacrificial labeled fixture that is removed through the
   normal audited lifecycle, never raw SQL cleanup.
9. Preserve canonical before/after DB snapshots, operation IDs, redacted audit rows,
   Supabase convergence query, screenshots, recordings, commands and exact SHA.
10. Gate the first runtime edit on internally accepted component/page previews and their
    decomposition manifest. For each implemented state, capture normalized accepted-
    preview ↔ real-runtime side-by-sides and motion/behavior traces at the same data,
    viewport, theme and text scale; attach every mismatch to the Copy inventory and
    rerun after repair at the touched and adjacent layout classes.

## Reject the stage if

- The Edge Function/model writes the remote planner before the local reviewed apply.
- Any proposal arrival, timeout retry, Enter key, voice acknowledgement or UI rebuild
  can mutate data without the exact explicit confirmation.
- Diff omits changed dates/timezone, recurrence, relationship, conflict or destructive
  consequence; “saved” is shown before the local transaction succeeds.
- Apply can partially commit, duplicate on retry, bypass domain validation/RLS or
  diverge from the equivalent manual action.
- Undo erases immutable history, rewinds storage or silently overwrites later edits.
- A Task/Habit/Note/Project/Area/Goal/schedule consumer remains stale after apply.
- Runtime work began before preview approval, or review/loading/conflict/security/
  receipt/undo UI materially diverges from its accepted Stage 03–05-derived reference.

## Whole-product propagation

Exercise every AI-created/updated entity in Today, Tasks, Plan, Habits, Goals,
Projects, Areas, Notes, Focus, Quick Capture/full wizards, detail/history/edit,
search/filter/sort/bulk views, reminders/notifications, archive/conflict center,
local database/operation queue, Supabase RLS/realtime, sync cloud, Android widget and
deep links. Include settings, diagnostics, feedback export, backup/import, auth expiry,
theme/a11y and upgrade migration. Manual and AI paths must converge on one canonical
behavior; AI failure must not degrade manual planning.

## Handoff and release

Stage 48 receives the canonical operation/result invalidation contract needed to
refresh widget data; Stage 49 receives the allowlist matrix, attack corpus, atomicity,
audit, undo and end-to-end evidence. If runtime/schema/function code changed, apply
forward-safe migrations, commit/push `main`, pass CI and publish/install the three
signed private artifacts. Record any unrun live two-device/Supabase proof as a blocker,
not as completion, and leave the tree clean with no extra branch or secret.
