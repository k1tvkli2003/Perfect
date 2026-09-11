# Stage 12 continuation and recovery ledger

Status: active  
Updated: 2026-09-12
Objective: review the whole scope and finish the existing 50-stage product plan.

## Current evidence, not inherited completion

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
  `screenshots/perfect-stage12-preview-runtime-2026-09-12.png`. This is
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
