# Stage 12 continuation and recovery ledger

Status: active  
Updated: 2026-09-17
Objective: review the whole scope and finish the existing 50-stage product plan.

## 2026-09-17 execution restart

- The owner approved full 50-stage scope and autonomous, recorded design selection.
  See the dated authority correction in `../../02-state.md`.
- Stage 12 is still open. UI consumes the stream's ordered entities and occurrence
  times, but does not yet carry section and next-entry identity into all renderers.
- Next packet: record full sequential tests with expanded stack traces, analyzer
  and no-write format results; then reproduce section/next-row gaps before repair.
- Earlier release/quota and emulator restrictions below are historical snapshots,
  not current blockers. Existing `Codex_API35` is allowed; no new AVD is authorized.
- No fresh full-suite, visual, release or install-over success is claimed here.

### Verified restart packet — 2026-09-17

- Scope correction committed locally as `659241c`; no push/release performed.
- Flutter 3.44.0 / Dart 3.12.0 rejects `--chain-stack-traces` before loading tests.
  The supported `flutter test --no-pub --concurrency=1 --reporter expanded`
  completed with 480 passed, exit 0, before the new regressions/implementation.
  This does not explain the older silent exit 1. Baseline analyzer passed.
- Added `Today exposes scheduled and habit groups around real rows` to the
  workspace widget tests. Both stored rows are found, then `Scheduled` is absent:
  a real presentation assertion fails, exit 1. Test remains enabled and red;
  do not weaken it, update goldens, or claim a green current full suite.
- `PlannerTodayStream` now retains its normalized local day and resolved task/
  habit outcomes per entry. Workspace success projection retains this typed
  snapshot and adapts it to existing renderers instead of discarding it into
  parallel state maps. Section/next ID are retained, not yet rendered.
- Two snapshot tests were added. Initial missing getters caused a compile failure.
  The recurring-lifecycle fixture also initially omitted authoritative storage
  eligibility; aligned it with the existing recurring-lifecycle test contract.
  Domain plus real Drift storage tests now pass 20/20. The exact lifecycle test
  and recurring occurrence-time workspace regression also pass individually.
- Existing three design candidates explicitly remain `mock-preview-not-approved`.
  Attempted image inspection returned `view_image is not allowed because you do
  not support image inputs`. No visual acceptance was fabricated and no visible
  grouping/layout change was made. Next visual gate needs image-capable inspection
  and completion of the candidate shell/state comparisons, not another green
  projection-test rerun.
- Next implementation: accepted section/next rendering across all layout tiers,
  anchor retention and final-row clearance; separately close swallowed projection
  failures and stale/day-rollover state. Stage 12 and whole delivery remain open.
- Final checks for this snapshot packet: `flutter analyze --no-pub` passed with
  no issues; `dart format --output=none --set-exit-if-changed lib test` passed
  across 181 files with zero changes; `git diff --check` passed. These do not
  supersede the enabled red grouping regression or certify visual completion.

## Current evidence, not inherited completion

### Platform amendment and unfiltered workspace verification — 2026-09-17

- Previous packet made progress: authoritative plan/state now map native Apple
  delivery to PWA while retaining Android/Windows. All 50 stage owners remain.
- Ran `flutter test --no-pub --concurrency=1 --reporter expanded
  test/presentation/perfect_workspace_page_test.dart` without a name exclusion:
  64 passed, 1 failed, exit 1. The sole failure is `Today exposes scheduled and
  habit groups around real rows`, at line 1662: zero `Scheduled` headings inside
  `perfect-today-scroll`. Both persisted fixture rows were present. Recurring-time
  and failure-preservation regressions passed. No assertion was weakened.
- Trace: store-backed eligibility/outcomes reach `PlannerTodayStream.project`;
  it assigns `section` and `nextEntryId`. `_todaySurface` adapts the snapshot into
  entity/outcome/time inputs only. `_TodayPage` maps entities directly to rows and
  `_DayStreamTimeline` does likewise. Neither consumes section/next identity.
  This is missing presentation wiring, not missing DB fixture data. The timeline
  also still reads `entity.scheduledAt` in its outer rail; projected occurrence
  labels must be consistent at that consumer during the repair.
- Production grouping remains unchanged pending the existing preview gate.
  Next packet must accept complete same-fixture candidates, pass typed section/
  next identity through all three tiers, then prove canonical groups, unique next,
  empty/settled states, anchors and row reachability. A lone added heading does
  not close this contract.
- Ran the canonical read-only `audit_flutter_targets.py --project . --targets
  android windows pwa --skip-doctor --format markdown`, exit 0. Android/Windows
  required files exist; this run performs no native build/install verification.
  PWA lacks `web/index.html` and `web/manifest.json` and is NOT PREPARED.
- Source audit identifies native boundaries in `planner_local_store.dart`
  (`drift/native.dart`), `perfect_voice_recorder.dart`, feedback repository/exporter
  and reminder scheduler (`dart:io`). Widget support is explicitly Android-gated.
  Federated package warnings are review inputs, not unsupported-platform verdicts;
  several web implementation packages already exist in resolved dependencies.
- Canonical source version remains `1.1.0+2000`; CI owns release build allocation.
  Android application ID and Windows identity remain `com.k1tvkli2003.perfect`;
  Windows publisher remains `CN=K1 Perfect Private`. No identity/version edits,
  platform generation, dependency replacement, CI mutation or deployment occurred.
  Owner host/origin/access decision and actual Safari acceptance evidence remain
  required before PWA release. Native data is not assumed to transfer to browser
  storage automatically. Protected dirty files, stash and branches stay intact.

### Projection failure preservation checkpoint — 2026-09-17

- Reproduced a stored-outcome read failure in the real workspace: Pulse reported
  `active` instead of unresolved after the injected exception. The prior catch
  replaced missing reads with invented pending/entity outcomes and certified success.
- Removed per-row exception substitution. Only a complete successful read publishes
  a new snapshot. Failure preserves the last same-day snapshot, leaves freshness
  unresolved and emits only `TODAY_PROJECTION_READ_FAILED`, not raw private errors.
  Controller changes clear the snapshot; day matching prevents yesterday's reuse.
- Removed obsolete parallel projection state maps. Existing renderers adapt the one
  retained typed stream. Signature deduplication prevents rebuild-driven retries;
  local revision/resume invalidation enables a fresh read. Explicit error/retry UI
  and automatic retry policy are still open, not certified by this packet.
- The new failure regression verifies preserved partial outcome even after stored
  data changes to completed, no repeat reads on rebuild, then successful recovery
  showing completed. Focused test passed; workspace suite excluding only the known
  red grouping regression passed 64/64. `flutter analyze --no-pub` passed.
- User requested PWA instead of native Apple targets. The current narrow scope
  interpretation retains Android/Windows and maps Apple delivery to PWA; this is
  not an instruction to remove native targets. The canonical plan now includes
  PWA browser/storage/update/hosting gates. No web/platform/CI mutation was made.
  Existing Apple folders and all other protected work remain unchanged.

- Stage 11 **feature** SHA `59db6e479f34f25ecf66e4224b2d8c90c7f53941`
  has successful trusted run `31767013849`. This is not current source HEAD.
- `main` SHA `d0a62b9afc5d99f70f35e1e92d28401f7b8ff9ed` has failed trusted
  run `32791367184`. Live GitHub inspection on 2026-09-09 proves both build jobs
  failed at artifact upload with `Artifact storage quota has been hit`.
  Windows install-over and Setup checks were skipped. Publish was skipped.
  Artifact hygiene succeeded on its failure branch only.
- Retained signed MSIX artifact `9206952095` is **expired**, expiry
  `2026-08-28T03:46:27Z`. It cannot be claimed as an available upgrade baseline.
  Release assets were not removed. A future green job that exits because no
  previous MSIX exists is not two-version upgrade proof.
- `7f6d1ca` inadvertently tracked `.vscode/settings.json` and unused
  `lib/presentation/perfect_date_format.dart`. Neither is published on any
  observed remote branch. Remove from tracking through a forward correction,
  preserving both local files; do not rewrite history or delete their content.
- `NUL` and `stash@{0}` (`wip/android-upgrade-proof-before-ui-rebuild`) remain
  protected. Remote `arena/01a06a41-perfect` was discovered; do not delete before
  ancestry/content review.
- Previous turn made partial progress (tests and Git evidence) but also made
  the mistaken unrelated-file commit. Whole-product completion was not proven.

## 2026-09-11 solo continuation

- The protected-file forward correction is committed as `962fb25`; both local
  files remain present and untracked. `NUL`, the stash and the remote arena
  branch remain untouched.
- New work is solo. The user explicitly stopped multi-agent use; no new workers
  were spawned. The worker rows below are historical ownership evidence for
  already-completed work, not active delegation.
- Added `test/planner/planner_today_stream_storage_test.dart`: six real
  in-memory Drift/controller cases prove persisted quota, selected-day
  rollover, owner isolation, measured-habit undo, exceptions/recovery and
  read-only projection.
- Fixed `taskProgressForDay` in `_resolveTodayProjection` to pass the selected
  `day`; this prevents a recurring task completed before midnight from using
  the current day after rollover.
- Verified artifact guard 20/20, `flutter analyze` clean, and full sequential
  Flutter suite 479/479. No live deletion, hosted release, emulator/device run
  or visual implementation proof is claimed.
- Stage 12 remains blocked at its visual preview gate: generate three
  structurally distinct sparse/dense arrangements, freeze the chosen equations,
  then implement grouping/time labels/next emphasis/scroll continuity in UI.
- Trusted main run `34550905297` passed and published release
  `v1.1.0-build.2065` with exactly three assets. Windows Setup proof passed
  clean/idempotent reruns, preserving package family and `LocalState`; no
  older MSIX transport existed, so the next build must prove cross-version
  MSIX install-over. This is release infrastructure proof, not Stage 12 UI
  completion.
- The user clarified emulator use for app viewing is allowed; earlier RAM
  caution is not a standing prohibition.

## 2026-09-12 Stage 12 UI integration packet

- `_resolveTodayProjection` now builds `PlannerTodayStream` and publishes the
  ordered entity projection instead of falling back to `_sortAgenda`.
- Phone Today and medium/expanded Day Stream panels now receive
  `taskProgressById` and pass each row's daily task outcome into
  `_AgendaRow`, `_ReferenceAgendaRow` and `_AgendaCompletionButton`.
- Removed two row-local recurring-task `FutureBuilder`s that re-read the
  selected day independently; visible status/percent now come from the same
  durable projection as ordering and Pulse.
- Analyzer is clean and the full sequential Flutter suite passed 479/479.
- Cold-started the live preview on `Codex_API35` / `emulator-5554` and captured
  `../../assets/perfect-stage12-preview-runtime-2026-09-12.png`. This is
  runtime evidence, not yet a side-by-side preview gate acceptance or a claim
  that Stage 12 UI is complete.

## Ownership and dependency graph

| Owner | Outcome | Exclusive writes | Dependency / proof |
|---|---|---|---|
| root | Stage 12 deterministic daily stream model and regression fixtures | `lib/planner/domain/planner_today_stream.dart`, `test/planner/planner_today_stream_test.dart`, work docs | existing eligibility and daily outcome contracts; unit tests |
| editor_date_bounds | Existing dates remain editable without picker assertions; controller clock consistency | `lib/presentation/planner_editor.dart`, `test/presentation/planner_editor_test.dart` | reproduce first; focused widget regressions; no visual redesign |
| artifact_hygiene_guard | Fail-closed, workflow-scoped temporary artifact rotation | `.github/workflows/verify.yml`, release contract test, dedicated rotation script/tests if needed | fake API failures; no live deletion; coordinator acceptance |
| root | integration, Git preservation, final evidence | index and explicit owned commits | inspect all worker diffs; sequential Flutter tests; exact-SHA hosted proof separate |

Native worker model/effort inherited from root; no unsupported tier override.
Historical worker rows are retained below only as evidence for already-completed
work. Current work is solo, with root owning architecture and final acceptance.

## Stage 12 contract

Projection receives owner-scoped entities, a local calendar day, canonical
eligibility, task daily progress and habit daily summaries. It never writes data.
Ordering: recovery decision, scheduled tasks, habits, flexible work, settled
review. Partial remains actionable; missed and completed stay reviewable.
Repeated work uses today's occurrence time, not the historical anchor date.
Ties use creation time and ID rather than mutable update time.
Quota/exception eligibility from storage overrides fallback recurrence evaluation.
Archived/cancelled/deleted and Project/Area records cannot become actionable.
Next-row emphasis references one real row ID; no duplicated Next Up card.

## Acceptance still open

The projection and daily-outcome contract are now wired into the current
Today surfaces, but the visual/composition gate remains open. Stage 12 is not
accepted yet.
Before visible ordering changes: freeze three sparse/dense stream arrangements,
choose and compare against `td-zone-heading`, `td-stream-timeline`,
`td-next-emphasis`, `td-continuation-cue` and `pg-today-*` manifests.
Then integrate grouping, occurrence-aware time labels, scroll anchoring, final-row
reachability, daily outcomes and responsive compositions into all Today layouts.
Stage 31 remains owner of full details/history, not forgotten or falsely fixed.
Stage 12 and Stages 13–50 remain open.

Runtime screenshot, motion/jank and Android install tests are deferred by explicit
RAM constraint. Widget/unit tests and authored previews are not device evidence.
CI quota recovery, safe cleanup success branch and a new exact-SHA release remain
unverified until observed. No account billing or other repositories are in scope.
