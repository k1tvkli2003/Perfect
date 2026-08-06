# Stage 45 — Owner settings, diagnostics, backup and recovery

Status: pending  
Depends on: Stages 01, 05–10, 15, 34 and 41–44  
Blocks: Stages 46–50  
Primary surfaces: More/Settings, keyvan profile, archive/trash, feedback capture,
diagnostics, backup/export/import, local recovery and production empty-account proof

## Mission

Finish the private owner's control plane. A brand-new `keyvan` workspace contains
zero demo/sample planner data; settings and profile are coherent on Android and
Windows; feedback captures log + screenshot + note with explicit privacy review; and
the owner can archive, trash, back up, export, dry-run import, repair and recover data
without a destructive reset as the default answer.

## Autonomous product decisions

- Production has no seed/demo/preview/sample planner entity path. Developer fixtures
  use a separate dev entrypoint, package/application identity and database namespace;
  a release compile-time/runtime guard fails closed if fixture code is reachable.
- Settings are a utility destination under More/profile, never a new peer daily-work
  destination. Deep links may open a precise subsection while retaining shell context.
- Preferences declare scope: `owner_synced`, `device_local`, `secure_secret` or
  `ephemeral`. No setting is duplicated across SharedPreferences, payload JSON and
  Supabase without one canonical owner and explicit adapter.
- Archive is reversible and has no automatic expiry. Trash is a separate reversible
  30-day holding area; permanent erase is explicit, consequence-aware and retains
  only the minimal content-free sync tombstone required to prevent resurrection.
- Private backup is encrypted by default. Human-readable data export is a separate,
  explicitly warned action. Neither format ever contains passwords, auth/provider
  tokens, Supabase secret keys, device secure-store contents or raw diagnostic logs.
- Import is validate + dry-run + owner confirmation + transactional apply. Default is
  deterministic merge/deduplication, never blind replace or delete-missing.
- Feedback stays local until the owner explicitly exports/shares it. Screenshot and
  diagnostic attachment are separately reviewable; no background upload exists.
- Recovery escalates from integrity check → rebuild derived projections → restore a
  safe snapshot/backup → owner-confirmed reset. Every destructive option first offers
  salvage/export and names exactly what survives.

## Mandatory Stage 03–05 preview and Copy gate

No runtime or data implementation begins until all visible surfaces below extend the
accepted Stages 03–05 Day Compass direction. Use `modernize` for the complete opinion
ledger, `integrity` for setting/data/consumer ownership, `anatomy` for IA, action
placement and escape paths, and `style` for exact components/assets/tokens/states/
motion. After recorded internal acceptance under the owner-delegated autonomous design
authority, `copy` owns production fidelity.

Before any data-only work, internally accept diagrams for preference authority/propagation,
fixture isolation, backup encryption/container, import staging/rollback,
archive→trash→purge/tombstone, feedback privacy and the recovery ladder. Diagrams and
mock states are implementation specifications, never runtime evidence.

### Required component previews

Preview every component individually in all applicable default, hover, focus, press,
selected, disabled, loading, progress, success, warning and error states:

- settings group/row, value/status line, toggle, segmented choice, permission row,
  owner identity/profile field, avatar/mark treatment and sign-out confirmation;
- archive/trash row, age badge, multi-select, restore, move-to-trash, empty-trash and
  permanent-erase confirmation/receipt;
- backup type/contents selector, passphrase/reveal/strength guidance, save location,
  progress, cancel, checksum/receipt and last-backup health;
- file picker entry, import manifest summary, compatibility badge, validation issue,
  create/update/unchanged/conflict/skipped counts, collision review and Apply/Undo;
- diagnostic health row, schema/build/storage/queue/permission status, safe error,
  copy report, recovery ladder action and pre-repair snapshot receipt;
- feedback launcher, note editor, screenshot preview/remove/redaction cue, bounded log
  preview, privacy checklist, capture/export/delete progress and corrupt-store repair;
- zero-owner empty composition, dev-fixture warning (dev only), privacy/exclusion label
  and offline/sync/auth state used within these flows.

### Required page and system-surface previews

Preview complete Settings overview and each destination: Profile & account;
Appearance & accessibility; Planning defaults; Notifications; Today widget; Perfect
AI/voice/privacy; Sync & conflicts; Data & recovery; Archive & Trash; Feedback;
Diagnostics; About/release. Also preview backup/export wizard, import dry-run/review,
recovery flow, feedback capture/history and permanent-delete flow.

For every page provide empty/sparse/dense, loading, offline, retry, validation, partial
failure, conflict, success and destructive states where meaningful across phone
portrait/short landscape, tablet portrait/landscape, compact/expanded Windows,
light/dark/high contrast, RTL/mixed/long copy, 200% text, keyboard/IME and reduced
motion. Include actual-shape Android file/share/permission surfaces, Windows file
picker/save dialog, widget privacy state, notification permission/deep-link result and
post-upgrade recovery banner.

All artifacts are labeled `Mock Preview`, internally accepted and converted to a decomposition
manifest covering live/vector/raster/hybrid layers, semantics, focus order, anchor/
crop, size/density/theme variants, responsive transformation, motion and budgets.
Owner data, forms, controls, privacy copy and diagnostics remain live. Implementation
then follows `copy`: reference viewport first, responsive-exact variants next, and
fresh real-runtime side-by-side comparison for every component/page/system state.
Mismatch, precision and composition-occupancy ledgers must close before acceptance.

## Settings and profile contract

| Group | Canonical values and scope |
|---|---|
| Profile & account | Auth UUID/username are read-only identity; optional display name and locale/calendar/time-zone are `owner_synced`; session and connection actions come from Stage 43. |
| Appearance & accessibility | Theme, contrast, text/density preference, reduced-motion override and Windows rail state are `device_local`; system defaults remain valid choices. |
| Planning defaults | Default task/habit schedule behavior, focus preset, week start, carry/recovery preference and capture defaults are versioned `owner_synced` values; they affect new records only unless explicitly applied. |
| Notifications | Quiet hours and semantic reminder defaults may sync; OS permission, scheduled IDs and platform capability are `device_local`. |
| Today widget | Title privacy, density and selected sections are Android `device_local`; server never treats widget config as planner truth. |
| Perfect AI & voice | Tone/language/context-retention consent may sync; microphone permission and local draft/cache are device-local; provider secrets are server-only. |
| Sync & conflicts | Read-only Stage 44 health plus Retry/Conflict Center; endpoints/tokens/raw bodies are never shown or copied. |
| Data, privacy & feedback | Backup/export/import, archive/trash, diagnostics and capture consent/history; each operation states local/remote/content scope. |

Define `PreferenceDefinitionV1(key, type, scope, default_semantics, constraints,
introduced_version, migration, consumers)`. Defaults are product behavior, not
persisted fake owner choices. Typed repositories expose streams; feature screens do
not read arbitrary preference keys. Unknown newer keys are preserved, ignored safely
and reported in compatibility diagnostics.

## Zero-demo production contract

- A clean signed build plus authenticated fresh keyvan owner yields exact zero counts
  locally and remotely for Task, recurring Task, Habit, Note, Project, Area, Goal,
  relation, schedule, occurrence, progress, focus and AI action records.
- Empty Today/Tasks/Plan/Habits/Goals/Notes/Focus use authored instructions and
  project-owned visual assets only—never fake rows, dates, streaks, stats or names.
- Dev previews may use deterministic fixtures only under a distinct dev entrypoint,
  app ID/executable label, database and Supabase-disabled/test configuration. Import
  of a dev database into production is rejected by provenance marker.
- Release CI searches source/generated assets/snapshots for production fixture
  registration and launches the signed artifact against a fresh local directory and
  disposable owner to assert zero counts.

## Backup, export and import contracts

### Private backup

`perfect-backup-v1` is a documented, streaming container with a small magic/version
header and encrypted manifest/data. Use an audited cross-platform implementation of
Argon2id (salt + recorded cost) and AES-256-GCM with independent random nonce; never
invent cryptography or store/pass the passphrase in argv/log/preferences. The
encrypted manifest records contract/schema versions, created time, app version,
owner-binding fingerprint, selected domains, per-kind counts, canonical hashes and
attachment inventory.

Include canonical entities, schedules, relations, reminders, occurrences/progress,
focus history, selected owner-synced preferences, archive/trash state and optionally
AI conversation history/feedback attachments only after separate consent. Include
unacknowledged local operations only in a clearly marked recovery journal with their
idempotency IDs. Exclude tokens/keys, device ID, remote cursor, leases, scheduled OS
notification IDs, widget cache, screenshots/logs unless selected, derived indexes and
ephemeral UI state.

### Human-readable export

Offer owner-selected canonical JSON plus optional task/habit/history CSV summaries in
a documented versioned folder/ZIP. Warn that it is not encrypted and may contain
private notes. Export uses stable IDs, ISO timestamps + zone/local date, explicit
enums and UTF-8; it never uses localized display labels as machine fields. A manifest
provides counts and SHA-256 checksums.

### Import and restore

1. Read header/manifest only after passphrase authentication where encrypted; enforce
   file/record/string/depth/attachment limits and reject path traversal/bombs.
2. Verify authenticated owner binding, hashes, schema support and all Stage 41
   constraints in an isolated staging database. Older supported versions migrate in
   staging; a newer unsupported version remains untouched with actionable copy.
3. Present dry-run counts by kind and action: create, update, unchanged, duplicate,
   conflict, skipped and invalid, plus settings/history/attachments impact.
4. Default merge by stable ID + canonical hash + revision/history semantics. Same ID
   with divergent content is a reviewable conflict; “replace everything” is absent.
5. Before Apply, create/hash a local pre-import snapshot. Apply canonical records and
   Stage 42 operations in one resumable transaction, rebuild derived projections,
   reconcile reminders/widget and then offer Undo to that snapshot until verified.
6. Round-trip export/import must preserve stable IDs, meaningful content, timestamps,
   relations, history, archive/trash, counts and canonical hashes. Remote convergence
   happens through Stage 42/44, never direct unaudited table inserts.

## Archive, trash and permanent deletion

- Archive removes active entities from Today/workspaces/widget/reminders while
  retaining details, relations and history. Restore returns the entity without
  inventing missed occurrences for the archived period.
- Trash soft-deletes content, cancels projected reminders/widget actions and retains a
  30-day owner-visible recovery deadline. Restore revalidates parent relations,
  schedules and conflicts before returning projections.
- Permanent Delete is separated from Archive/Trash, lists affected children/history/
  AI proposals/feedback references, requires explicit confirmation and remains
  idempotent offline. Content purge is synchronized; a minimal ID/revision/deleted-at
  tombstone persists for the documented device-safety window without title/note/value.
- Empty Trash is a review page, not a row swipe. If any known device has not crossed
  the safe cursor/watermark, show that purge will complete after synchronization or
  require an explicit device retirement decision—never allow resurrection.

## Feedback, diagnostics and recovery contracts

Retain the integrated project feedback component as one coherent owner-scoped
`log + screenshot + note` experience. Note is editable; screenshot is optional and
visually reviewed; bounded logs are selected/redacted by default. Each entry records
opaque ID, created time, app/build/platform, route label, safe sync/error codes,
attachment hashes and export state. It does not auto-upload or capture keyboard,
password/token fields, clipboard, raw HTTP/SQL, full DB or background screenshots.

The privacy review shows exactly what will leave the device and permits removing
screenshot/logs independently. Redaction is defense in depth, not consent. Feedback
storage is owner-namespaced, size/age bounded, corrupt-store recovery first copies the
original, and Delete removes entry plus attachments with a result receipt.

Diagnostics exposes safe facts: app/build/signing channel, platform/package identity,
local/remote schema capability, DB quick-check, owner-scoped counts, storage size,
queue/conflict/quarantine counts and age, last sync/error code, background/widget/
notification permission/capability, last backup and migration state. “Copy safe
report” excludes titles, notes, values, IDs where not needed, paths, URLs and secrets.

Recovery ladder:

1. Retry the failed bounded operation or reopen after permission/storage fix.
2. Run read-only DB `quick_check`, schema/foreign-key/count/hash checks.
3. Create a safety snapshot, then rebuild derived indexes/search/widget/reminders.
4. Quarantine and export individually invalid records; forward-repair from canonical
   event/source data without silently discarding owner content.
5. Restore an authenticated backup/pre-migration snapshot through dry-run.
6. Offer Reset workspace only in Advanced Recovery after successful/declined salvage,
   typed confirmation and exact local/remote/session consequences. It is never the
   recommended first action and never runs automatically.

## Detailed work packets

1. Inventory every production seed/fixture/default record path; every preference key,
   profile value and scope; archive/delete/reset path; export/import/recovery tool;
   diagnostics/log/screenshot flow; and Settings/More route/entrypoint.
2. Build the whole-product preference/consumer matrix and migrate to typed
   `PreferenceDefinitionV1` repositories with one-time, reversible legacy adapters.
   Preserve owner values during N→N+1 and do not overwrite them with new defaults.
3. Enforce dev fixture isolation by package/entrypoint/database/provenance and add
   release source/artifact/runtime zero-data gates.
4. Implement Settings IA and adaptive compositions from approved previews. Reuse
   canonical theme, reminder, widget, AI, sync, feedback and auth controllers rather
   than duplicating state in the page.
5. Implement/archive/trash queries and operations, retention/deletion receipts,
   reminder/widget/search/AI cleanup and sync-safe tombstone/purge workflow.
6. Implement streaming encrypted backup and human-readable export with manifests,
   limits, cancellation cleanup, file-picker/share adapters and known crypto vectors.
7. Implement import staging, schema adapters, dry-run diff/conflict review,
   transactional Apply, post-apply verification and Undo snapshot. Fuzz hostile files.
8. Integrate feedback capture/history/privacy review using the existing component,
   owner namespaces, bounded logging and screenshot redaction/exclusion zones. Verify
   source-version attribution rather than silently forking it.
9. Implement diagnostics and recovery ladder with a read-only first pass, safe report,
   pre-repair snapshot, derived-only rebuilds and advanced destructive isolation.
10. Publish user help plus technical format/schema/privacy/retention/recovery docs;
    record exact supported backup range and a fixture corpus for future releases.

## Whole-product propagation

| Consumer | Required propagation |
|---|---|
| Today | Fresh owner is honestly empty; settings/defaults affect future capture; archive/trash/import/recovery update sections once without fake content or lost scroll. |
| Tasks and Plan | Lifecycle/import restores filters, schedules and local dates; export includes canonical task/plan semantics and no duplicate occurrences. |
| Habits and Goals | Round-trip tracking rules, immutable progress, relations and derived metrics without reseeding or double counting. |
| Focus | Preserve active/completed sessions through backup/upgrade; recovery never fabricates elapsed time and trash consequences are explicit. |
| Capture/edit/details | New-item defaults are read from typed settings; profile/locale changes preserve drafts; archive/trash/restore/import refresh the current record safely. |
| Android widget | Widget settings stay device-local; archive/trash/sign-out/recovery redact/reconcile rows; backup excludes widget cache and import republishes canonical projection. |
| Notifications | Quiet hours/defaults remain canonical; archive/trash/import/recovery cancel/rebuild schedules from durable reminders, not stale OS IDs. |
| Deep links/Windows protocol | Settings/diagnostic/import routes queue through auth; deleted/missing records open recoverable Archive/Trash/Today context, never editor/reset. |
| Perfect AI | Context excludes trashed/private diagnostic/feedback data by default; imported IDs remain stable; AI proposals cannot change settings or purge data outside allowlist/review. |
| Sync/conflicts | Backup displays queue health; restore/import emits idempotent operations; unresolved conflicts/unsynced work are never hidden or cleared by repair. |
| Settings/profile | One adaptive source displays real current values and capabilities; no duplicate theme/reminder/widget/auth/sync state. |
| Release/upgrades | Preserve settings, session, owner DB, archive/trash deadlines, feedback, last-backup metadata and recovery snapshots; production starts with zero planner seeds. |

## Exact adaptive UX and system surfaces

Phone Settings is a scan-friendly grouped route with search only if the final IA needs
it; frequent owner controls are near the top, Data & recovery is deliberate, and Sign
out/Permanent delete are physically separated. Long backup/import/recovery work uses
full routes with sticky reachable actions, safe area and IME preservation—not a chain
of fragile sheets.

Tablet uses a compact settings category rail + detail when useful width remains;
short landscape collapses to a single route. Windows uses a resizable two-pane
Settings workspace, native keyboard traversal/shortcuts/tooltips and file dialogs;
selection, field draft, import dry-run and scroll survive rail/window changes.

Empty Archive/Trash/Feedback/backup history uses purposeful Day Compass pictograms
and one next action. Dense lists paginate/virtualize. Destructive confirmations state
entity/history/local/remote scope with whole labels; no swipe is the only route. File
pickers/share/permission dialogs follow host conventions and return to the exact step.

At 200% text, settings values move below labels and action rows become columns. RTL
mirrors structural direction but not brand/universal icons; mixed filenames/hashes
are isolated LTR. Progress/copy/export success is announced once. Reduced motion uses
stable crossfades/static progress, never removes information or cancelability.

## Offline, failure and conflict states

- Settings/profile/local backup/export/archive/feedback remain available offline;
  server-only verification/purge is labeled queued and uses Stage 42 operations.
- Disk full, permission denied, file removed, wrong passphrase, corrupt/truncated
  file, checksum mismatch, unsupported newer/too-old schema, owner mismatch, duplicate
  IDs, partial attachment and cancel/process kill each preserve original data and the
  selected file/dry-run state where safe.
- A failed import writes zero canonical records before Apply. Failed Apply rolls back
  or resumes from its checkpoint and retains pre-import snapshot. Failed export
  removes incomplete temporary output without deleting a prior valid backup.
- Repair failure retains the untouched corrupt copy plus diagnostics; UI never labels
  a salvage as complete until counts/hashes/integrity checks pass.
- Concurrent remote changes during import/archive/trash become normal Stage 42
  conflicts; no timestamp overwrite or global refresh.

## Performance, accessibility, privacy and security

- Stream exports/imports and hash/encrypt off the UI isolate with bounded memory,
  progress and cancellation. Set budgets for 10k entities, long history and large
  optional screenshots; dense Settings/Archive lists stay virtualized.
- Use audited crypto/library primitives and known vectors; random salt/nonce per
  backup; clear passphrase buffers where platform permits. Never invent encryption,
  include secrets or send passphrases through argv/telemetry.
- Validate archive paths, ZIP entries, MIME/magic, sizes/counts/depth, JSON schemas,
  UTF-8 and attachment hashes. Prevent traversal, symlink escape, zip bombs and
  cross-owner import.
- Screenshot consent warns that visible planner content may be present. Secure/auth
  fields are excluded; safe logs are bounded/redacted; owner can inspect/delete all
  feedback artifacts.
- Focus order follows visible order, status does not rely on color, progress and error
  copy is screen-reader usable, confirmations name consequences, and all controls meet
  touch/pointer/keyboard target/contrast requirements.

## Rollback contract

Settings migration retains legacy keys until canonical readback and consumer parity
pass; rollback adapter reads them without overwriting newer values. Backup format v1
remains readable for the documented compatibility window. A feature rollback hides
new import/recovery actions but never deletes backup files, snapshots, feedback,
archive/trash or new preference values. Remote purge is postponed rather than
reversed; destructive cleanup migrations are not part of this stage.

## Verification and required evidence

- Release-entrypoint source/artifact/runtime scan plus clean local/disposable remote
  account proves exact zero planner records and no reachable fixture registration.
- Preference registry/consumer tests cover type, scope, defaults, legacy migration,
  unknown version, owner isolation and signed N→N+1 preservation on Android/Windows.
- Backup golden vectors, wrong-passphrase/tamper tests, round-trip stable IDs/counts/
  hashes, cancellation/disk-full and 10k-record performance pass on both platforms.
- Import fuzz/security corpus, dry-run no-write assertion, older migration, newer
  refusal, owner mismatch, dedupe/conflict, transactional Apply/Undo and remote
  convergence pass.
- Archive→restore, trash→restore, 30-day boundary, offline purge, stale device,
  empty-trash and content-free tombstone tests reconcile every consumer.
- Feedback log+screenshot+note creation, redaction/privacy review, export/delete,
  corrupt-store recovery and no-auto-upload tests pass; bundles/source/builds contain
  no secret or excluded field.
- Diagnostic quick-check, safe-report snapshot and every recovery rung are exercised;
  counts/hashes and preserved original/snapshot evidence accompany repair claims.
- Accepted preview versus real Android/tablet/Windows runtime side-by-sides cover every
  component/page/system state, both themes/high contrast, RTL/mixed, 200% text,
  keyboard/touch, reduced motion, empty/dense/offline/error/conflict. Mismatch and
  precision ledgers are clean.
- Install signed version N, set preferences/create archive+feedback+pending operation/
  backup marker, install N+1 with same identities, and prove session/data/settings/
  files/widget state survive. No uninstall/fresh directory is allowed.

## Reject the stage if

- A signed fresh keyvan build creates any planner sample/demo/placeholder entity, or
  dev fixtures share production identity/database/entrypoint reachability.
- Backup/import contains secrets, relies on home-grown crypto, mutates before dry-run
  approval, loses stable IDs/history/relations, accepts foreign owner or uses replace/
  reset as default.
- Archive equals delete, Trash cannot restore, permanent delete can occur by swipe/
  ordinary row tap, or a stale device can resurrect purged content.
- Diagnostics expose raw planner content/token/URL/SQL, feedback auto-uploads, or the
  owner cannot review/remove screenshot/log/note independently.
- Recovery recommends reset before snapshot/salvage or declares success without
  integrity/count/hash proof.
- Any visible component/page/system surface lacks an accepted preview, or runtime is
  implemented without clean `copy` side-by-side fidelity evidence.

## Handoff and release

Stages 46–48 receive the typed preference scopes, zero-data release guard, privacy/
feedback policy, backup/import schema, archive/trash lifecycle, safe diagnostics and
recovery APIs. Stage 49 receives the complete visual/state evidence matrix; Stage 50
receives backup/upgrade fixtures and release-entrypoint seed scan. Commit/push only
after CI, security/round-trip/recovery tests, real Android/Windows system surfaces,
Copy evidence and signed upgrade proof pass; record any remote retention/RPC
deployment separately and leave clean `main` only.
