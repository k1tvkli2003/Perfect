# Stage 41 — Agent-friendly canonical schema and migrations

Status: in progress — migration rollback/recovery, owner-scoped local store,
and AI/agent proposal validation domain suites are GREEN; canonical table
contract, Supabase/RLS, and import/export matrices remain open
Depends on: Stages 01, 05, 17, 21–29, 31–40  
Blocks: Stages 42–50  
Primary surfaces: Drift, repositories/controllers, Supabase/RPC/RLS, import/export,
AI proposal validation and every planner projection

## Mission

Replace the current payload-heavy planner contract with one canonical,
owner-scoped and migration-safe model that a UI, widget, sync worker or authorized
agent can read and write without guessing screen implementation. Preserve every
existing ID, record and history row; this stage is a forward migration, never a
reset or a production reseed.

## Autonomous product decisions

- Drift remains the immediate local authority; Supabase is the durable private
  replica and cross-device transport. Neither side gets a separate domain model.
- Common identity, lifecycle, status, schedule, ownership, revision and time fields
  are typed. JSON is allowed only for versioned extensibility such as custom fields,
  method-specific measurements and recurrence exceptions.
- `owner_id` is derived from the authenticated `OwnerContext` at every public API
  boundary. It is never accepted from a screen, deep link, widget or AI document.
- Existing opaque IDs remain unchanged. New IDs are client-generated UUIDs; their
  meaning is never encoded in the string and display order never depends on them.
- Timestamps cross boundaries as UTC ISO-8601. Day-based planning also stores an
  explicit IANA time zone and `local_date`; it is never reconstructed from the
  current device zone after travel.
- Lifecycle (`active`, `completed`, `archived`, `trashed`) is distinct from an
  occurrence result (`pending`, `partial`, `completed`, `skipped`, `missed`,
  `recovered`) and from synchronization state.
- Unknown fields in a supported extension envelope survive round trips, but an
  unsupported contract version is quarantined with an explanation rather than
  silently normalized to defaults.

## Mandatory Stage 03–05 preview and Copy gate

No runtime, migration or UI implementation in this stage may begin until this
stage-specific extension of the internally accepted Stages 03–05 direction carries a
recorded autonomous acceptance decision.

1. Use `modernize` to complete a KEEP/REFINE/REDESIGN/REMOVE/ADD opinion ledger,
   `integrity` to map schema/state producers to every consumer, `anatomy` to define
   placement/reading/focus order, and `style` to specify exact tokens, assets,
   interaction states and motion. Preserve the accepted Perfect! identity.
2. Produce contract diagrams before data work: canonical ER/ownership diagram,
   command-to-transaction-to-projection trace, migration/rollback state machine and
   old/new compatibility map. These are approved implementation specs, not proof.
3. Preview every visible component individually: migration progress, progress row,
   phase indicator, retry, diagnostics, recovery export, restore-prior-version and
   queued widget/deep-link notice—each in default/loading/success/error/disabled/
   focus/hover/pressed states as applicable.
4. Preview every complete composition with empty, sparse, dense, long/error content
   across phone portrait/short landscape, tablet portrait/landscape, compact and
   expanded Windows, light/dark/high contrast, RTL/mixed text, 200% text and reduced
   motion. Include boot, queued widget/notification/deep-link and rollback flows.
5. Label previews `Mock Preview`, record internal acceptance under the
   owner-delegated autonomous design authority, then create a
   preview-to-production manifest for every live/vector/raster/hybrid layer, state,
   semantic role, anchor, responsive transformation and performance budget.
6. Implement only from the accepted images using `copy`: fixed reference viewport
   first, then responsive-exact adaptations. Compare fresh runtime captures side by
   side, repair item-by-item and close mismatch, precision and composition-occupancy
   ledgers. A golden, compile or non-overflow test cannot replace visual fidelity.

## Canonical data contract

The same logical records and constraints must exist in Drift and Supabase. Physical
names may follow platform conventions, but generated adapters must prove lossless
round trips.

| Record | Required typed authority | Extensible data and invariants |
|---|---|---|
| `planner_entities` | `(owner_id,id)`, `kind`, `title`, `note`, `lifecycle`, `created_at`, `updated_at`, `archived_at`, `trashed_at`, `revision` | Kind is exactly task, recurring task, habit, note, project, area or goal. Title limits are explicit by kind. JSON `custom_fields_v1` is size/depth bounded. |
| `planner_schedules` | `(owner_id,id)`, `entity_id`, `zone_id`, `local_date`, `start_at`, `end_at`, `deadline_at`, `all_day`, `rule_type`, `rule_version`, `effective_from/to` | Exactly one active definition per entity/version. Recurrence detail is a validated `rule_v1`; exceptions have stable IDs and dates. |
| `planner_occurrences` | `(owner_id,id)`, `entity_id`, `schedule_id/version`, `local_date`, planned window, result, finalized timestamps, `revision` | Unique logical occurrence key prevents duplicate day generation. Rows are retained evidence; corrections append progress events. |
| `planner_progress_events` | `(owner_id,id)`, `entity_id`, optional `occurrence_id`, `event_type`, `source`, `occurred_at`, `mutation_id` | Append-only event ledger for status, percent, count, duration, value, checklist, recovery and focus linkage. Method-specific `value_v1` is validated and bounded. |
| `planner_relations` | `(owner_id,id)`, `from_id`, `to_id`, `relation_type`, `position`, lifecycle timestamps | Supports goal/project/area/task/habit/note links and checklist dependencies. Both endpoints must share the owner; duplicate active edges are rejected. |
| `planner_focus_sessions` | owner, stable ID, optional entity/occurrence, mode, start/end, result, revision | Completed history is immutable; pause/resume segments live in a versioned bounded detail object. |
| `planner_reminders` | owner, ID, entity/schedule target, trigger semantics, channel, enabled, revision | Scheduled platform notification IDs are projections, never authority. Quiet-hours preference is referenced by stable setting key. |
| `planner_labels` / `planner_entity_labels` | owner, stable ID, name, icon asset key, color token, join position | Category/icon/color choices use project-owned keys; labels cannot point across owners. |

Every owner-scoped foreign key includes `owner_id`. Supabase constraints and RLS
defend the boundary even if a client bug sends a valid ID from another owner. Local
repositories require an `OwnerContext`, and debug/test builds assert that result rows
match it before projection.

## Read and command APIs

- Publish typed repository queries for Today range, task workspace, habit eligibility,
  Plan interval, goal graph, Focus history, Archive/Trash, detail history, reminders,
  widget projection and bounded AI context. Screens must not parse Drift rows or raw
  JSON themselves.
- Define `PlannerCommandV1` with `contract_version`, `command_id`, `target_kind`,
  `action`, optional `target_id`, `base_revision` and allowlisted `arguments`.
  Owner, device credentials and authorization are injected after validation.
- Allowlisted actions cover create/update/archive/trash/restore for all entity kinds,
  schedule/exception changes, relation changes, occurrence logging/correction,
  focus completion and reminder changes. Each action declares required fields,
  limits, consequence preview and whether it appends immutable history.
- Return a `PlannerCommandResultV1` containing affected stable IDs, new revisions,
  changed projection keys and an idempotency receipt. Never return raw SQL or accept
  arbitrary table/column/path names.
- Check JSON Schemas and canonical valid/invalid examples into the schema contract
  directory. Generate Dart validators/types where practical and run the same corpus
  against RPC validation so app, backup importer and AI cannot drift.

## Detailed work packets

1. Freeze current Drift/Supabase schemas, migrations, row counts, IDs, owner counts,
   payload keys, malformed legacy values and all repository query call sites.
2. Write the canonical dictionary: every field, unit, nullability, enum, limit,
   default, source of truth, index, retention rule and compatible older form.
3. Add typed tables/columns and composite owner foreign keys additively. Create the
   Today/range, active-kind, relation, occurrence-history, outbox and archive indexes
   from measured query plans—not speculative indexes.
4. Build pure deterministic adapters from existing `payload_json` and current remote
   snapshots. Invalid rows enter a migration quarantine with record ID/reason; no
   record is discarded or replaced with an invented value.
5. Backfill inside bounded transactions with resumable checkpoints and per-table
   before/after counts and hashes. Preserve current local and remote IDs/revisions.
6. Dual-read old/new records during one compatibility window, compare projections in
   tests, then switch repository reads to the canonical model. Dual-write only where
   the supported N-1 client contract requires it and document its removal gate.
7. Implement Drift `onCreate` and every sequential `onUpgrade` path; prove both
   direct N→current and stepwise N→N+1→current. Run foreign-key/integrity checks before
   committing the version marker.
8. Ship Supabase expand/backfill/constraint/RPC/RLS changes as separately reversible,
   idempotent migrations. Functions pin `search_path`, derive `auth.uid()`, validate
   size/depth/enums and expose execute-only writes to `authenticated`.
9. Replace UI/controller/widget/notification/AI ad-hoc payload reads with the typed
   queries and commands. Add a source guard against new raw-table access outside the
   data layer.
10. Publish schema/RPC documentation, ER diagram, field glossary, compatibility
    matrix and examples for each entity/action before Stage 42 consumes the model.

## Whole-product propagation

| Consumer | Required propagation |
|---|---|
| Today, Tasks and Plan | Use indexed range projections and the same lifecycle, local-day and ordering semantics; Today counts must equal filtered workspace counts. |
| Habits and Goals | Derive eligibility, measures and linked progress from schedules/events/relations without double counting. |
| Focus | Link sessions by stable IDs and surface orphan-safe history if a parent is archived or trashed. |
| Capture and full editors | Emit typed commands; preserve drafts when validation reports a field-level error. |
| Details/history | Query canonical occurrences/events, not `updated_at` inference or copied row payloads. |
| Android widget | Consume a bounded redacted projection; actions send ID/action/idempotency only. |
| Notifications | Reconcile typed reminders/schedules and route stable IDs through the canonical detail route. |
| Deep links/Windows protocol | Resolve current owner + opaque ID; never deserialize an entity or owner from the URI. |
| Perfect AI | Read bounded owner-scoped DTOs and produce reviewable `PlannerCommandV1` proposals only. |
| Settings, archive/trash and diagnostics | Count/query canonical records, expose schema version and retain lifecycle/history relationships. |
| Sync/conflicts | Use the same field paths/revisions and immutable record rules defined here. |
| Release/upgrades | Package generated schema artifacts, run clean/legacy migration suites and retain package/database/signing identity. |

## User-visible and system behavior

Schema migration normally has no blocking splash: existing local content opens only
after the transactional local upgrade succeeds. A long resumable backfill shows one
honest “Finishing your private planner upgrade” surface with progress by phase, local
backup availability and a diagnostics action. Phone uses a full safe-area page;
tablet and Windows use a centered bounded panel without exposing record content in
logs. Failure offers Retry, Export recovery bundle and Restore prior database—never
Delete database. Widget actions pause with a neutral “Open Perfect! to finish update”
state; notifications/deep links queue until migration completes.

Offline launch uses the same local migration and rollback contract without waiting
for Supabase. Remote schema capability is checked later; an offline upgrade cannot
be reported as remote migration success or erase a locally queued conflict.

At 200% text, messages/actions recompose vertically and remain keyboard/touch
reachable. Progress is announced accessibly, does not animate continuously under
reduced motion, and never uses color alone. Migration work is chunked off the UI
isolate; initial local-open and common indexed queries receive explicit p50/p95
budgets based on Stage 05 baselines.

## Failure, security and rollback contracts

- Power loss, disk full, process kill, locked SQLite, malformed legacy JSON, missing
  parent, remote-newer schema and an N-1 client are mandatory fixtures.
- A local pre-migration snapshot is retained until post-open integrity, count and
  projection checks pass. Rollback restores that exact snapshot and version marker;
  it never tries to reverse partially transformed rows in place.
- Remote rollback disables new RPC capability and returns clients to compatibility
  reads; it does not drop populated columns/tables. Destructive cleanup is a later,
  separately approved release after all supported clients have crossed the gate.
- RLS tests use two synthetic owners and unauthenticated calls. Cross-owner reads,
  relations, commands, imports and RPC writes must return zero data/writes.
- Contract examples contain synthetic values only. Artifact/source/log scans reject
  passwords, tokens, service-role keys, private database URLs and real planner text.

## Verification and required evidence

- Schema dictionary + ER diagram + generated contract diff reviewed with no
  undocumented field or enum.
- Golden adapter corpus for every entity/schedule/progress/relation kind, including
  malformed and unknown-version inputs.
- Clean-create, every-version upgrade, interrupted-resume, rollback and N-1
  compatibility tests on Android and Windows database locations.
- Before/after IDs, owner-scoped counts and canonical content hashes match; quarantine
  counts are zero or individually explained without loss.
- Supabase migration lint, RPC contract tests, RLS two-owner matrix, query plans and
  remote readback pass against a disposable project before production deployment.
- Repository consumer inventory proves Today/tasks/plan/habits/goals/focus/details/
  widget/notifications/AI/import all use typed boundaries.
- Signed N→N+1 installs preserve session, local records, pending operations, widget
  placement/settings and history; runtime screenshots cover upgrade progress/failure.

## Reject the stage if

- A screen, widget, AI handler or importer still invents or parses query-critical
  fields from unversioned JSON.
- Migration success depends on clearing app data, reinstalling, recreating the owner,
  dropping unknown fields or accepting count/hash drift.
- `owner_id` is trusted from caller input, any cross-owner edge can be stored, or a
  broad authenticated grant bypasses RPC validation/RLS.
- Passing local schema tests are presented as deployed Supabase or upgrade proof.
- Runtime/migration work started without accepted component/page previews and
  diagrams, or an implemented state lacks a clean Copy comparison to its reference.

## Handoff and release

Stage 42 receives the frozen entity/field-path/command dictionary, migration
compatibility window, immutable-history list and query budgets. Commit only schema,
adapter, tests and documentation for this stage; push `main`, require CI plus signed
Android/Windows upgrade artifacts when runtime changed, record remote deployment
separately, and leave the tree clean with only `main`.

### Evidence — 2026-09-25 (real runs, Stage 41 partial)

- `flutter test --no-pub test/planner/planner_local_store_test.dart
  test/planner/planner_sync_repository_test.dart
  test/planner/planner_migration_contract_test.dart`: **EXIT:0, 29 pass**
  (durable local operations, sync backoff/retry/dispose, migration rollback).
- `flutter test --no-pub test/planner/agent_plan_ingestion_contract_test.dart
  test/planner/private_ai_sync_migration_contract_test.dart
  test/ai/perfect_ai_contract_test.dart
  test/ai/perfect_agent_edge_contract_test.dart`: **EXIT:0, 27 pass**
  (proposal/category metadata preservation, turn/apply parsing, deterministic
  replay, final-state persistence, transcription boundary).
- Canonical table contract, Supabase/RLS, import/export, and upgrade proof
  remain open.
