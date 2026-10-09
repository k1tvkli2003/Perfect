# Stage 49 — Adversarial whole-product quality gate

Status: blocked — host/device matrices, side-by-side Copy comparisons,
motion/system traces, and N→N+1 rehearsal have no recorded acceptance;
behavioral test suites remain GREEN as partial characterization only
Depends on: Stages 01–48 accepted with linked evidence  
Blocks: Stage 50  
Primary surfaces: every shipped Android/Windows route, state, interaction, asset,
data/sync/AI/widget path, accessibility tree, performance trace and recovery path

## Mission

Try to disprove that the release candidate is coherent, beautiful, safe and complete.
Audit route by route and contract by contract under hostile geometry, content, input,
network and lifecycle conditions. A build that merely compiles, avoids overflow or
passes isolated tests is rejected when it remains generic, cramped, sparse, unstable,
inaccessible, slow or visually weaker than the accepted Perfect! direction.

The title is deliberately whole-product: no earlier stage title limits this gate.

## Autonomous decisions

- Freeze one candidate SHA, dependency lock, schema/function version and signed debug/
  release artifact set before each audit pass. Any source/schema/asset fix invalidates
  the candidate and restarts every affected check; evidence never migrates silently.
- Use an explicit coverage ledger joining route × layout class × content/state ×
  input × theme/a11y × lifecycle. No “representative screen” substitutes for an
  untested unique composition or behavior.
- Require side-by-side boards for every layout class: approved reference intent,
  current sparse state and current dense/hostile state at identical viewport/theme.
  Reference/mock images are labeled as such; only screenshots from the frozen running
  candidate count as implementation evidence.
- Allow no production placeholder/demo/sample entities, lorem copy, fake metrics,
  disabled visible controls, generic emoji/artwork or unfinished interaction. Development
  fixtures remain isolated to the dev package/entrypoint and are never captured as
  signed-owner proof.
- P0/P1 defects are zero-tolerance. A P2 may remain only when it is non-regressive,
  has owner/impact/workaround and is explicitly excluded from Stage 50 acceptance;
  cosmetic rationalization is not a waiver for broken proportion or accessibility.
- Evaluate motion, performance and network-dependent AI/sync with recorded devices,
  datasets and conditions. Do not compare timings from different hardware as though
  they were the same benchmark.

## Accepted preview and Copy comparison authority

Stage 49 first verifies that every visual runtime change in Stages 01–48 was preceded
by the exact internally accepted preview required by Stages 03–05. Each surface must carry
the `modernize` opinion ledger, `integrity` consumer/state map, `anatomy` hierarchy and
responsive geometry, `style` tokens/assets/motion storyboard and `copy` component
inventory/decomposition manifest. Missing or retroactively invented acceptance is a
blocking defect; runtime screenshots cannot manufacture a design spec after coding.

The accepted preview is the visual/interaction source of truth. Compare component by
component and page composition by page composition across default, loading, empty,
offline, retry, error, conflict, destructive, security/refusal, success and recovery
states; light/dark/high contrast; compact/medium/expanded; sparse/dense/long RTL/mixed/
200%; IME and reduced motion. AI composer/review and every widget size class/picker/
Quick Add state are explicitly included, as are release-visible first-run/migration,
setup, launcher/splash and diagnostics surfaces.

For each cell create a normalized accepted-preview ↔ frozen-runtime side-by-side plus
an overlay/diff metric when image files permit. Inspect pixel/color/material evidence,
but decide on geometry, frame/crop, hierarchy, typography baselines, live copy, item
count/order, icon/asset weight, state semantics and optical balance by human review.
Motion comparisons use synchronized first/mid/end/reversal/reduced-motion frames and
timing/event traces; behavior comparisons replay the exact gesture/key/network event
and verify focus, scroll, state and durable side effect. Every delta enters the Copy
mismatch ledger with repair SHA and adjacent-layout rerun; “similar vibe,” passing
pixel average or no overflow cannot close it.

## Complete surface ledger

Audit boot/splash, sign-in/session restore/auth-expired, header/sync/date, footer and
phone navigation, tablet/Windows rails, Today, Tasks, Plan day/week/month, Habits,
Goals, Projects, Areas, Notes, Focus, More/settings/profile, Quick Capture and its
Task/Plan/AI/Voice modes, full Task/Habit wizards, detail/history/analytics, search/
filter/sort/saved views/bulk actions, category/icon/color selectors, reminders and
notifications, archive/restore/delete, conflicts, feedback/log/screenshot capture,
diagnostics, backup/export/import/recovery, AI review/audit/undo, Android widget,
deep links, Windows protocol, local operation queue and Supabase sync/realtime.

## Mandatory adversarial matrix

- **Android phone:** 320x700, 360x800, 390x844, tall/narrow and short landscape.
- **Android tablet:** 600dp split view, 800dp portrait, 900dp landscape; compact and
  expanded rail where supported.
- **Windows:** 720x540, 1024x640, 1366x768 and 1600+ expanded plus slow continuous
  resize across every breakpoint.
- **Content:** zero entities, one item, dense day/workspace, maximum-length user text,
  long primary/system copy, Persian RTL, English LTR, mixed bidi, long numbers/dates,
  100% and 200% text.
- **Presentation:** light, dark, high contrast, reduced motion, loading, empty, dense,
  optimistic, success, offline, syncing/retrying, last-error, conflict, auth-expired,
  destructive confirmation and recovery.
- **Input/lifecycle:** touch, mouse hover/press/secondary click, keyboard-only, screen
  reader/TalkBack, IME open/dismiss, outside click, long press, rapid repeat, rotation,
  split-screen, resize, background/resume, process death, reboot and N→N+1 rehearsal.

## Work packets

1. **Assemble the evidence manifest.** Resolve every Stage 01–48 acceptance claim to
   command, result, screenshot/recording, artifact, device and SHA. Mark missing,
   simulated, stale or wrong-SHA evidence red before launching new tests.
2. **Build deterministic hostile fixtures.** Create production-isolated fixture sets
   for empty, sparse and dense owner state with long RTL/mixed copy, recurring edges,
   history, conflicts, pending operations and AI/widget states. Record schema version
   and hashes so visual/behavior reruns use identical content.
3. **Walk every route and entrypoint.** Exercise navigation shell, direct row/control,
   notification/widget/deep-link/protocol, keyboard shortcuts and back restoration.
   Verify destination, action owner, scroll/focus/selection/draft continuity and
   recoverable missing/deleted state.
4. **Critique composition side by side.** For each layout class, compare reference,
   sparse and dense candidate screenshots. Inspect framing, scale, pane adjacency,
   visual weight, optical alignment, spacing rhythm, readable line length, card
   hierarchy, action continuity, asset crop, negative space and Day Compass identity.
5. **Stress geometry continuously.** Sweep width and height, including short
   landscape, tall/narrow, tablet split, intermediate Windows and IME intrusion.
   Record bounds/scroll extents while inspecting the runtime: no clipping required
   copy/actions, overlap, focus loss, scroll jump, tiny floating work or unrelated
   full-width bars.
6. **Audit complete interaction states.** Capture default, hover, pressed, focus,
   disabled, loading, optimistic, success, undo, retry, error, conflict and destructive
   confirmation for every shared primitive and unique action. Verify touch, mouse and
   keyboard parity rather than inferring it from semantics.
7. **Audit motion as a system.** Record route, composer morph, sheet/menu, rail,
   completion/log, breakpoint resize, loading and error transitions at normal and
   reduced motion. Reject jump cuts, double paint, spatially wrong direction, focus/
   scroll reset and celebratory motion that misstates persistence/sync.
8. **Audit language and accessibility.** Review all user-facing copy for natural
   Persian, accurate state/action language and safe destructive consequences. Run
   semantics traversal, TalkBack/Windows screen reader, keyboard focus, contrast,
   target size, bidi and 200% text checks; color/animation alone conveys nothing.
9. **Attack local-first and sync.** Inject offline start/write, intermittent network,
   429/5xx, auth expiry, duplicate/out-of-order realtime, storage error, two-device
   conflict, process death and retry storms. Verify local work remains available,
   the three-state cloud is truthful and conflicts converge without lost drafts/data.
10. **Attack AI and widget.** Replay Stage 46 injection/authorization/secret corpus
    and Stage 47 malformed/stale/duplicate/atomicity/undo vectors. On a real launcher,
    resize/scroll/cycle/log/Quick Add offline and through update; verify every result
    in local history, queue, Supabase and app UI.
11. **Profile the exact candidate.** Measure startup, first useful frame, build/raster
    jank, route/composer/detail latency, dense list scroll, local query/transaction,
    sync replay, widget bind/action and AI client/server latency/memory. Capture traces,
    dataset, thermal/power/network and device specification.
12. **Run Critics → repair → re-audit loops.** Classify each finding P0–P3 with surface,
    reproduction, evidence, likely cause and acceptance check. Fix through the owning
    earlier-stage contract, create a new SHA and rerun affected plus smoke matrix until
    the release ledger contains no unresolved blocker or ambiguous claim.
13. **Audit preview provenance and fidelity.** Reject runtime-first surfaces, then run
    the Copy loop in priority order—viewport/framing, macro geometry, component/item
    completeness, copy/type, color/material, asset crop, micro-spacing, responsive
    variants and state/motion/behavior. Re-render from the new frozen SHA after every
    material repair; never compare an old screenshot to new code.

## UI/UX and motion quality contract

- Perfect! must read as one Day Compass instrument: navigation, Pulse/day stream,
  Capture/Plan/AI/Voice, details and secondary workspaces share intentional tokens and
  hierarchy without becoming repetitive cards or a single pastel color wash.
- Sparse states make the primary workflow appropriately prominent without floating
  tiny islands in dead space. Dense states preserve hierarchy and action continuity
  without cramming. Tablet/Windows use additional space for adjacency and clarity,
  not stretched phone UI.
- Primary phrases/actions remain whole; composition switches Wrap/Column/pane before
  clipping. Ellipsis hides only genuinely secondary/user preview text. Dedicated SVG/
  raster assets are sharp, theme-safe, semantic and never generic placeholders.
- Motion proves causality—navigation direction, optimistic local commit, later sync,
  undo and error are visually distinct. Reduced motion carries the same information
  without spatial animation.

## Responsive and device behavior

- Compare sparse and dense candidate screenshots at every named phone/tablet/Windows
  layout, both applicable orientations, 100%/200% text, light/dark and rail states.
  Add targeted states for IME, high contrast, reduced motion and conflict/error.
- During continuous resize/rotation/split-screen, preserve route, draft, selected item/
  date, editor cursor, keyboard focus, scroll and pending action. No duplicate route,
  stale pane or threshold oscillation is accepted.
- Validate reachability under safe areas, system bars, taskbar, keyboard and short
  height. Android widget size behavior is tested in the launcher, not represented by
  a Flutter mock.

## Domain, security and data contract

- Freeze and compare database counts/hashes, migration version, operation/audit IDs,
  RLS results and owner identity before/after destructive, offline, AI, widget and
  upgrade rehearsals. Expected domain changes are explicit; collateral changes fail.
- Secret/privacy review covers source, Git history/diff, generated code, APK, portable
  ZIP, setup payload, logs, screenshots, diagnostics, backups and AI context. No key,
  bearer/refresh token, signing private material or unrelated private content leaks.
- Confirm production has zero seeds/placeholders and dev fixtures cannot run under the
  signed application/package identity. Validate backup/import dry run and recovery
  without reset or accepting any foreign-owner data.

## Offline, errors and retries

- Each mutable workflow is tested offline first and then through bounded recovery:
  create/edit/status/log/focus/AI confirmed apply/widget Quick Add/archive/undo. Local
  commit, queue state, cloud cue and final remote convergence must agree.
- 429/timeout/5xx use bounded backoff with jitter; non-retryable auth/schema/domain
  errors stop and explain resolution. No retry storm, duplicate entity/history/audit
  or scroll/focus churn.
- Error, empty and recovery compositions remain useful and visually finished. A
  technical exception string, indefinite spinner, dead Retry or reset-first advice is
  a product defect.

## Accessibility and performance budgets

- Meet Stage 04/05 semantic target and contrast tokens; as a hard floor, normal text
  reaches 4.5:1, large text/non-text controls 3:1, and every required action is
  keyboard/screen-reader reachable with visible focus and correct name/role/state.
- On the recorded 60 Hz baseline devices, scripted common interactions keep build and
  raster p95 within one 16.67 ms frame, jank below 1%, and no unexplained frame above
  100 ms. Any stricter Stage 05 budget wins.
- On the recorded dense fixture, optimistic control feedback appears within 100 ms and
  local command transactions meet the Stage 05 p95 budget without N+1 queries. Android
  cold first-useful-frame is at most 3.0 s and Windows at most 2.5 s on the named
  baseline unless Stage 05 already sets a stricter measured target.
- AI and network timings are separated into client, Edge Function, provider and sync;
  the UI thread never blocks on them. Widget journal acknowledgement/local commit and
  all remaining memory/startup/query budgets from Stages 05, 20, 42, 46 and 48 pass.

## Verification and required evidence

1. A machine-readable coverage ledger has no missing route/layout/state/input/theme/
   lifecycle cell and links each result to candidate SHA, device and artifact.
2. Side-by-side reference/sparse/dense boards exist for every layout class and major
   route. Each board includes a written proportion/hierarchy/action critique, not only
   a screenshot. All mock/reference material is labeled and never counted as runtime.
3. A preview-provenance ledger proves recorded autonomous acceptance predates implementation for
   every visual component/page; it links the Stage 03–05-derived opinion, integrity,
   anatomy, style, decomposition, precision and Copy inventories. Missing provenance
   fails the gate rather than being waived as documentation debt.
4. Real Android and Windows screenshots/recordings cover the mandatory matrix,
   continuous resize, IME, 200% text, reduced motion, offline/retry/error/conflict and
   widget launcher actions. Bounds XML/goldens supplement but do not replace viewing.
5. Automated evidence includes full format/analyze/test, golden/geometry/motion/a11y
   suites, Android unit/instrumentation, Windows packaging contracts, migration/RLS/
   Edge tests, secret/placeholder scans and performance traces.
6. Behavioral ledgers prove every visible action has one reachable result, every
   lifecycle mutation updates all consumers exactly once, and back/resize/update
   continuity retains route/draft/focus/selection/scroll/session/local data.
7. Findings ledger includes severity, reproduction, evidence, fix SHA and rerun. No
   P0/P1, unresolved security/data/accessibility blocker, placeholder or dishonest
   “not tested = pass” remains.
8. Produce a Stage 50 release-candidate manifest: exact SHA/schema/function versions,
   version proposal, signer fingerprints as public metadata, evidence links, known
   non-blocking limitations and the commands needed to reproduce the gate.

## Reject the stage if

- Any required matrix cell is blank, simulated without label, wrong-SHA or inferred
  from a different surface/device.
- Screens fit but remain generic, imbalanced, cramped, excessively empty, poorly
  aligned, visually inconsistent or weaker than the approved reference direction.
- Any placeholder/demo/sample path, raw emoji UI artwork, dead/duplicate control,
  clipped required phrase/action, inaccessible visible control or unstable resize
  remains in the signed candidate.
- Offline/retry/error/conflict loses or duplicates data, blocks local work, lies about
  sync, or requires destructive reset as normal recovery.
- Performance/a11y/security budgets fail, artifact scans leak private material, or a
  P0/P1 is waived because tests elsewhere pass.
- Source changes after evidence capture without a new SHA and affected re-audit.
- Any component/page lacks pre-implementation accepted preview provenance, or the
  pixel/geometry/motion/behavior mismatch ledger contains an unresolved material delta.

## Whole-product propagation

This gate is the propagation audit: verify boot/auth/shell/navigation plus Today,
Tasks, Plan, Habits, Goals, Projects, Areas, Notes, Focus and More; all capture/editor/
detail/history/search/bulk/lifecycle/reminder/notification paths; local DB, operation
queue, Supabase RLS/realtime/functions, sync/conflict/recovery; AI text/voice/review/
audit/undo; Android widget/deep links and Windows protocol; themes, RTL/mixed/200%,
reduced motion/a11y; diagnostics/backups; performance, privacy, packaging and upgrade.

## Handoff and release

Only a frozen candidate with a complete green evidence manifest advances to Stage 50.
Commit/push each repair to `main`, require successful CI and re-capture invalidated
evidence. Handoff the exact candidate SHA, artifact-independent verification bundle,
resolved finding ledger, device matrix and explicit limitations; do not publish the
final release in this stage or call a locally passing subset release proof.

### Evidence — 2026-09-25 (real runs, Stage 49 characterization only)

- **EXIT:0, 537 pass** full suite `flutter test --no-pub` in one command
  (`C:/Users/K1/AppData/Local/Temp/perfect-full-20260925.log`).
- **EXIT:0, 198 pass** 11-file integrated behavioral gate
  (controller/Pulse/workspace/AI-dock/editor/route/secondary/Pulse-contract/
  task-status/focus/motion).
- **EXIT:0, 68 pass** combined domain+wizard gate; **EXIT:0, 29 pass**
  store/sync/migration gate; **EXIT:0, 27 pass** AI/agent bundle; **EXIT:0, 18
  pass** widget gate; **EXIT:0, 6 pass** preservation gate.
- `flutter analyze --no-pub`: `No issues found!`; `git diff --check`: clean.
- This is characterization only. Frozen-candidate SHA, host/device matrices,
  Copy side-by-sides, motion/system traces, injection/corpus attacks, and
  N→N+1 rehearsal remain blocked with no recorded acceptance.
