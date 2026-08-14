# Progress

## 2026-08-14 — Stage 11 Today Pulse preview gate

### Before

Orbit still dominated Today, repeated the next task, split tablet/desktop attention
between a circular instrument and the stream, and degraded into weak geometry in
short-height and enlarged-text layouts.

### Preview decision

- Explored three structurally distinct replacements and selected
  `today-pulse-dayline-v2`; rejected a dashboard-like split ticker and an
  administrative metric ledger.
- Built eight deterministic boards for component states, phone density,
  short-height/200% stress, tablet/Windows, themes, motion and measured geometry.
- Rejected the first two renders for sync/Plan collision, date/metric baseline
  overlap, weak row clearance, stretched desktop composition, footer occlusion,
  dead tablet space and short-rail escape; corrected each defect before approval.
- Froze one semantic instrument containing only live local time, Gregorian/Jalali
  date, done/remaining projection, next temporal boundary and Plan. Task/habit
  titles and mutations remain exclusively in the stream.
- Generator and independent verifier now pass with 8 boards, 21 manifest-tracked
  artifacts and 8 required states.

### Next

- Implement the live projection and adaptive Flutter component, remove every Orbit
  runtime/semantic/motion path, then close preview/runtime comparisons on Android
  and Windows-sized captures without resetting scroll or owner data.

## 2026-08-05 — Critics freeze and Focus Studio direction

| Time | Status | Entry | Evidence |
|---|---|---|---|
| 2026-08-05T23:11:44+03:30 | active | Android Tasks/Habits and both wizard paths were inspected against the approved reference and HabitNow decision order; source roots were traced before mutation. | `.codex-tmp/critics-cycle1/`; `lib/presentation/perfect_workspace_page.dart`; `lib/presentation/planner_editor.dart` |
| 2026-08-05T23:11:44+03:30 | active | Focused baseline passed 61/61 while three P1 product defects remained outside the encoded assertions. | `flutter test test/planner/planner_habit_day_summary_test.dart test/presentation/planner_editor_test.dart test/presentation/focus_session_sheet_test.dart test/presentation/perfect_workspace_page_test.dart` |
| 2026-08-05T23:11:44+03:30 | active | Ranked findings and counterarguments were frozen before implementation. | `10-critics-tasks-habits-editor-ledger.md` |
| 2026-08-05T23:11:44+03:30 | active | Focus was defined as an operating mode with Focus Contract, explainable presets, Flip experiment, graduated Shield, distraction capture and outcome learning. | `09-product-opportunity-roadmap.md` section 8 |

### Next

- Perfect Cycle 1: complete — configured Habit targets and checklist thresholds survive pending projections and measured-unit copy is no longer duplicated.
- Perfect Cycle 2: complete locally — truthful Open default، progressive compact filters، keyboard dismissal، 200% reflow and selection language are verified; release gate is next.
- Perfect Cycle 3: next — compact Home task/dock continuity and approved-reference screenshot comparison.

## 2026-08-05 — Perfect Cycle 1 closure

| Time | Status | Entry | Evidence |
|---|---|---|---|
| 2026-08-05T23:17:44+03:30 | active | Fixed the pending daily projection so count/duration targets and checklist success thresholds are preserved before the first log. | `lib/planner/domain/planner_habit_day_summary.dart` |
| 2026-08-05T23:17:44+03:30 | active | Simplified measured status copy to one unit phrase and added domain plus compact-workspace regressions. | `lib/presentation/perfect_workspace_page.dart`; two focused test files |
| 2026-08-05T23:17:44+03:30 | active | Refreshed the Android sibling preview and visually confirmed `Pending · 0 of 8 glasses · 0%`. | `.codex-tmp/critics-cycle1/android-habits-cycle1-fixed.png` |
| 2026-08-05T23:17:44+03:30 | active | Closed source, full-suite and runtime-crash gates for Cycle 1. | analyzer clean; 355/355 tests; 2685 ms cold start; no fatal/Flutter error match |

## 2026-08-06 — Perfect Cycle 2 closure

| Time | Status | Entry | Evidence |
|---|---|---|---|
| 2026-08-06T01:24:13+03:30 | active | Replaced Inbox-first with a truthful Open default so scheduled active work is visible immediately. | `_TasksPageState`; scheduled-only compact regression |
| 2026-08-06T01:24:13+03:30 | active | Rebuilt compact filters as Search + one summary control with animated progressive disclosure; wide layouts retain inline controls. | `_TaskFilterDeck`; phone and 900dp tests |
| 2026-08-06T01:24:13+03:30 | active | Removed selected checkmarks from Task filter chips, replaced the misleading Single check icon, and retained semantic selection. | `_FilterGroup`; ChoiceChip assertion |
| 2026-08-06T01:24:13+03:30 | active | Added tap-out/expand keyboard dismissal and a two-line 200% text composition; corrected empty-state copy so Tasks no longer points to Home-only Quick Capture. | widget tests + Android input-method/runtime screenshots |
| 2026-08-06T01:24:13+03:30 | active | Passed full source and behavior gates. | analyzer clean; 356/356 tests; API 35 preview cold start and no fatal/Flutter error match |

## Log
| Time | Status | Entry | Evidence |
|---|---|---|---|
| 2026-07-27T20:30:42 | active | Task docs created. | docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/ |
| 2026-07-27T20:31:36+03:30 | active | Baseline Git/source inventory recorded; existing UI is a simple dark list and sync surface is still un-audited. | `git status`, `lib/main.dart`, `lib/workspace/workspace_page.dart` |
| 2026-07-27T20:31:36+03:30 | active | User approved Orbit Day, bottom-right launcher icon and bottom-left typography direction; selected mock assets copied into task evidence. | `03-previews.md`, `assets/` |
| 2026-07-27T20:31:36+03:30 | active | Added exact responsive contract: portrait, landscape/medium and expanded landscape need distinct compositions. | `01-plan.md` |
| 2026-07-27T20:31:36+03:30 | active | Expanded the capability and adversarial-scenario matrix so every task/habit remains configurable without sacrificing quick capture. | `01-plan.md` |
| 2026-07-27T20:45:00+03:30 | active | User authorized implementation; branch `codex/perfect-orbit-day` created from baseline commit `26d2ea3`. Scope reconciled to Android and Windows only. | `git switch -c`, current user instruction |
| 2026-07-27T21:05:00+03:30 | active | Completed read-only audits of sync, UI composition and Android/Windows readiness; converted findings into implementation constraints. | audit findings; `lib/`, `android/`, `windows/` inventory |
| 2026-07-27T21:15:00+03:30 | active | Added additive v2 Supabase schema/RPC contract and started a Drift local source of truth with transactional outbox; legacy v1 remains untouched. | `supabase/migrations/20260730053626_add_private_planner_v2.sql`, `lib/planner/` |
| 2026-07-27T21:22:00+03:30 | active | Resolved the Android dependency build break by pinning the compatible transitive `path_provider_android` version; debug APK built successfully. | `flutter build apk --debug` -> `build/app/outputs/flutter-apk/app-debug.apk` |
| 2026-07-28T02:15:00+03:30 | active | Orbit Day presentation, sectioned Task/Habit editor, archive/conflict/focus/reminder surfaces, responsive Android/Windows composition, branding assets and the native Android Today widget are present in the working tree. This is implementation evidence, not runtime proof. | `lib/presentation/`, `lib/widgets/`, `android/app/src/main/`, `assets/` |
| 2026-07-28T02:45:00+03:30 | active | Hardened the local-first contract: exact mutation replay, owner-fail-closed snapshots, strict cursor/success metadata, retry drain/backoff, conflict preservation, own-operation rebase, and occurrence-outcome/lifecycle separation. | `lib/planner/data/`, `lib/planner/sync/`, `supabase/migrations/20260730053626_add_private_planner_v2.sql` |
| 2026-07-28T02:50:00+03:30 | active | Centralized Today/recurrence/recovery rules and added backward-compatible contracts for several month-days, last day, several annual dates, flexible N-per-week/month, checklist success and explicit overdue recovery resolution. | `lib/planner/domain/`, `test/planner/`, `07-product-research.md` |
| 2026-07-28T03:04:00+03:30 | active | Verification audit separated current evidence from stale or missing proof: owned Dart files format successfully; focused backend tests are written but unrun; editor test has a 10-minute timeout; current APK predates final source; no Windows artifact, device/widget run, live Supabase run or current CI exists. | `05-verification.md`, `.codex-tmp/planner-editor-test/stdout.log`, build/artifact and GitHub Actions inspection |
| 2026-07-30T03:45:00+03:30 | active | Closed compact, RTL, 200% text, Orbit geometry, focus/shortcut and dialog lifecycle defects; the full Workspace interaction suite now passes. | 34 tests in `perfect_workspace_page_test.dart`; dedicated accessibility/adaptive surface tests |
| 2026-07-30T03:55:00+03:30 | active | The full suite exposed two real `setState` callbacks returning `Future` in Archive and Insights. Both ownership paths were corrected and the full suite reran green. | `planner_archive_sheet.dart`, `planner_insights_sheet.dart`; full suite |
| 2026-07-30T04:10:00+03:30 | active | Built, signed-structure-checked, installed and cold-started a fresh release APK. Verified `Perfect!` package identity, selected launcher icon, portrait and landscape configuration surfaces, and clean logcat. | APK SHA-256 and Android ledger in `05-verification.md`; runtime screenshots under `assets/` |
| 2026-07-30T04:40:00+03:30 | active | Added the native widget through Pixel Launcher, resized it across composition classes, scrolled nine local-only fixture tasks to the final row, exercised the four-state check cycle, verified the durable action queue, removed the fixture, and restored the release install. | `perfect-widget-*.png`; `uiautomator`; `dumpsys appwidget`; local-only debug harness |
| 2026-07-30T04:45:00+03:30 | active | Closed Android cloud and device-transfer backup for local database/session/widget data, added a regression contract, rebuilt and reinstalled release, and confirmed `ALLOW_BACKUP` is absent. | manifest/rules; release install; APK hash in `05-verification.md` |
| 2026-07-30T05:05:00+03:30 | active | Closed the independent Critics findings: wrong-project connection recovery, disabled-reminder cancellation, explicit 96-reminder capacity, non-evicting widget queue/ack, and golden-failure hygiene. Rebuilt and cold-started the final APK. | analyzer; 162 tests; APK `174DF8…24A89`; clean API 35 logcat |
| 2026-07-30T09:20:00+03:30 | active | Applied four aligned, idempotent migrations to private project `evyjrbwibwrdkjakooor`; enrolled exactly the management account owner, closed inherited anon/default grants, configured GitHub client secrets and appended `perfect://login-callback` without replacing existing redirects. Live anon/owner RPC, mutation replay, cursor pull and zero-residue cleanup passed. | Supabase Management API migration history, Data API/Auth smoke, Security Advisor |
| 2026-07-30T09:45:00+03:30 | active | Rebuilt what was then the selected mark from the approved image with three pastel arcs on one orbit and a transparent 512 source. Pixel runtime proved transparent adaptive and legacy fallbacks become black/white system tiles, so Android received an intentional `#FFE5CC` pastel adaptive surface while Windows kept the transparent mark. The configured APK cold-started directly on private Auth. This selection was reopened in the later entry below. | launcher source/contract tests; Pixel Launcher screenshots; configured APK `4282AA…A9329CD` |
| 2026-07-30T10:18:20+03:30 | active | Commit `d56455b` reached `main` and `origin/main`. Private CI run `30519295088` completed successfully: Quality/Android and Windows jobs passed, and configured Android plus unpackaged Windows artifacts were uploaded. No signed MSIX artifact exists because the installer-upload step was skipped without a signing identity. | Git refs؛ GitHub Actions run/jobs API؛ artifacts `perfect-android-debug-fallback-configured-private-30519295088` and `perfect-windows-x64-configured-private-30519295088` |
| 2026-07-30T10:18:20+03:30 | active | The owner reopened the launcher identity instead of accepting the three-arc candidate as final. Ten independently generated 512×512, no-letter, chroma-background concepts now exist for selection; none is transparent, wired or platform-verified. | user instruction؛ `icon-concepts-v2/README.md`؛ 10-file dimension inspection |
| 2026-07-30T10:45:00+03:30 | active | After five additional symmetric explorations, the owner selected Day Compass. Chroma and colour spill were removed, a transparent 512 master and monochrome source were produced, Android assets/widget/notification marks were regenerated, and Windows received a nine-frame transparent ICO. A transparent adaptive control rendered black on Pixel Launcher; final Android uses quiet pastel `#FFF3E8` and was visually verified in the app drawer. | selected 1254 source؛ deterministic asset pipeline؛ launcher contract tests؛ `assets/perfect-day-compass-app-drawer.png` |
| 2026-07-30T10:45:00+03:30 | active | Extended native Android widget closure to four exact resize families including tall, kept every family scrollable, hardened queue ordering against clock rollback and strict malformed-action rejection, and re-proved 12-row RTL/long-title scrolling plus four-state taps on Pixel Launcher API 35. | 31 focused tests؛ Kotlin/resource compile؛ live host screenshots and restored QA state |
| 2026-07-30T10:45:00+03:30 | active | Hardened Windows compact sizing/DPI/multi-monitor restore, OS manifest, notification identity and portable CI packaging. The workflow now includes VC runtime DLLs, checksums, SHA-pinned actions and stronger private MSIX validation; fresh hosted build proof awaits push. | 4 Windows contract tests؛ 34 desktop behavior tests؛ actionlint/YAML checks |
| 2026-07-30T15:14:13+03:30 | active | Integrated Day Compass, four-family widget and Windows closure passed the full local gate. The release APK was rebuilt, v2 signature/package identity checked, installed over the runtime state and cold-started without Flutter/Android crash evidence. | format 127 files unchanged؛ analyzer clean؛ 170/170 tests؛ release APK `B4A8DD…57D0813` |
| 2026-07-30T15:41:45+03:30 | active | An independent final critic found a foreground/WorkManager interleaving that could let an old widget worker overwrite a newer tap. Added Drift schema v2 with a local-only sequence table, atomic conditional UPSERT before mutation, 5s SQLite contention wait, v1→v2 retention proof and a real two-connection concurrent one-off/recurring regression test. The three documentation/reproducibility findings from the same audit were also closed. | analyzer clean؛ 172/172 tests؛ shared-file SQLite concurrency and migration tests؛ pinned `tool/requirements.txt` |
| 2026-07-30T18:30:00+03:30 | active | Added versioned agent-plan ingestion and private AI conversation/action-audit migrations, then applied both to the live Supabase project. Live inspection confirms migration rows, owner RPCs and RLS-enabled AI tables. | migrations `20260730190000`/`20260730192000`; Management API live query |
| 2026-07-30T18:45:00+03:30 | active | Implemented the server-side Perfect AI Edge Function contract for authenticated text/voice chat, owner-scoped planner context, Gemini tool proposals, explicit confirmation, agent-plan apply, safe telemetry and sync persistence. Deno type-check passes. | `supabase/functions/perfect-agent/index.ts`; `deno check` |
| 2026-07-30T19:00:00+03:30 | active | Provisioned stable private Android JKS and Windows code-signing PFX outside the repository; uploaded six GitHub secrets and pinned both public certificate fingerprints. Trusted CI now uses monotonic versions and fails closed on identity drift. | `tool/provision_private_signing.ps1`; GitHub secret/variable names; release contract tests |
| 2026-07-30T19:20:00+03:30 | active | Locked new UX requirements: phone/tablet/Windows tiers, collapsible tablet/desktop navigation, AI Dock above footer, three-state Sync Cloud, native Widget Quick Add, SVG-only artwork instead of raw emoji, session-preserving upgrades and a first-class motion/hover/transition system. Parallel implementation is active and project-specific guidance is persisted. | user instructions; `AGENTS.md`; requirement ledger |
| 2026-07-30T20:10:00+03:30 | active | Added the intelligent constraint-driven geometry contract globally and locally: intrinsic, flex, bounded fractional, aspect-ratio, anchored and fixed semantic sizing are selected by role; screen hardcoding and percentage dogma are both rejected. Modernize/Style/Rebuild/Widgets validators pass. | shared UI contract; four skills; `AGENTS.md`; R14 |
| 2026-07-30T20:25:00+03:30 | active | Deployed `perfect-agent` Edge Function v1 to the private Supabase project with ACTIVE status and gateway JWT verification. An unauthenticated live request returns 401. The compromised provider key was not reused and `AVALAI_API_KEY` is confirmed absent, so an authenticated provider smoke remains intentionally gated on a rotated key. | Supabase Management API deployment and secret-name/auth-boundary checks |
| 2026-07-30T20:40:00+03:30 | active | Rejected the first tablet composition after visual QA despite passing responsive tests: the orbit was underscaled, the day stream disconnected, vertical space unused, and AI/capture rendered as two heavy appended bars. Researched planner, calendar, habit and AI dashboard patterns inside Dribbble and started a parallel Day Deck + compact AI command-pill rebuild. | user rejection screenshot; Dribbble browser research; refreshed implementation tasks |
| 2026-07-30T20:48:00+03:30 | active | Hardened AI apply and release boundaries: exact persisted-proposal matching, deterministic replay, bounded request/response/history/context, provider-error redaction, stdin-only GitHub secret upload, pinned Windows certificate signing, lock/version regression gates and safe agent-plan origin handling. | Edge/Deno checks؛ 31 Flutter contracts؛ 11 Python tests؛ PowerShell/YAML/bash checks |
| 2026-07-30T20:50:00+03:30 | active | Applied and recorded migration `20260730210000` live. Probes confirm ordinary metadata passes, credential aliases and depth >32 fail, and anon/authenticated cannot execute the guard directly. Bundled and atomically promoted `perfect-agent` v2 through the official Management API; it is ACTIVE, `verify_jwt=true`, and unauthenticated invocation returns 401. | live Supabase Management API migration/function responses؛ contract tests 15/15 |
| 2026-07-30T20:52:00+03:30 | active | Rebuilt the rejected tablet composition into a coherent Day Compass + Day Stream deck. Compact/expanded portrait and `1200×800` landscape goldens now fill the workflow with real Runway/Day Signal content, intentional stream continuation and a compact AI command pill; parent visual QA approved all three surfaces. | `perfect_tablet_rail_compact.png`؛ `perfect_tablet_rail_expanded.png`؛ `perfect_tablet_landscape.png`؛ 39 Workspace tests |
| 2026-07-30T22:05:00+03:30 | active | Rebuilt expanded Windows into one coherent instrument: a correctly scaled Day Compass/Runway, adjacent Day Stream, Habit Pulse/Next Up/Day Signal and a contextual inspector that adapts between intermediate and wide windows. Short-landscape and 200% text paths were revalidated. | `perfect_expanded.png`؛ `perfect_windows_short.png`؛ `perfect_windows_wide_inspector.png`؛ Workspace suite 44/44 |
| 2026-07-30T22:10:00+03:30 | active | Made bootstrap non-blocking and sync retry truthful: branded first frame appears before Supabase/config initialization, widget callback wiring no longer blocks startup, and both offline and red needs-attention states schedule bounded exponential retry with coalescing/reset/dispose coverage. | `main.dart`؛ sync repository/controller tests؛ bootstrap test |
| 2026-07-30T22:15:00+03:30 | active | Completed AI history/context integration. Conversation/messages hydrate across restart/devices, proposals restore only when the durable audit is unambiguous, and Edge context now comes through a bounded owner-scoped security-definer RPC instead of direct planner-table grants. | AI focused suite 33 pass؛ Deno check؛ migration `20260730220000` |
| 2026-07-30T22:20:00+03:30 | active | Applied migration `20260730220000` live. Verified the migration row, authenticated execution, anon denial, direct planner-select denial, array result shape and bounded limit. | Supabase Management API live probes |
| 2026-07-30T22:25:00+03:30 | active | Closed the current local quality gate after integration: analyzer is clean, all 256 Flutter tests pass, Workspace UI is 44/44, release contract is 5/5, AI focused contracts are 33 pass and Deno type-check passes. | `flutter analyze --no-pub`؛ `flutter test --no-pub --reporter compact`؛ focused suites؛ `deno check` |
| 2026-07-30T22:29:00+03:30 | active | Corrected release version continuity to `1.1.0+2000`. CI now computes Android `versionCode` as epoch + run number; expected next run #4 is `2004`, above installed `1003`, while MSIX remains semantic plus run (`1.1.0.4`). | `pubspec.yaml`؛ `verify.yml`؛ `private-build-contract.yml`؛ release contract 5/5 |
| 2026-07-30T22:32:00+03:30 | active | Deployed the integrated `perfect-agent` bundle through the official Supabase Management API. Version 3 is ACTIVE with gateway JWT verification; the recorded bundle hash is `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b` and unauthenticated invocation fails with 401/`UNAUTHORIZED_NO_AUTH_HEADER`. | live Function metadata؛ unauthenticated POST probe |
| 2026-07-30T22:50:00+03:30 | active | Closed the final release-audit findings: same-ref installable builds now serialize with official `concurrency.queue: max` support, the Android artifact contract uses `VERSION_CODE`, and README documents machine-wide `TrustedPeople` import/`Add-AppxPackage` plus encrypted offline signing-backup recovery. Release contract remains 5/5. actionlint 1.7.12 predates the new queue key, so only its exact `concurrency.queue` diagnostic is ignored locally; GitHub service validation after push is authoritative. | `verify.yml`؛ `private-build-contract.yml`؛ README؛ release contract 5/5 |
| 2026-07-31T00:20:00+03:30 | active | Built the final signed Android `1.1.0+2004` artifact and installed it over `1003`, then over `2004` again. Package/version/ABI/zipalign/v2 certificate passed; UID `10213`, original install time, data directory and widget id `5` survived update and reboot. The device was already signed out, so authenticated-session retention and a real widget task commit were not claimed. | APK `990772FF…5C91B8D`؛ adb package/widget/runtime evidence under `build/private-update-proof/` |
| 2026-07-31T00:35:00+03:30 | active | Added a portable encrypted signing-lineage backup and restore path. A synthetic JKS/PFX round-trip exercises private-key possession, wrong passwords, tamper rejection, size/path bounds, atomic no-overwrite and ACL rollback. The first rollback test exposed a real `SeSecurityPrivilege` failure; DACL-only restoration now uses `FileSystemAclExtensions` and the full round-trip passes without touching the real signing root. | `tool/PerfectSigningPortable.psm1`؛ backup/restore commands؛ synthetic round-trip PASS؛ 5 contract tests |
| 2026-07-31T02:40:00+03:30 | active | Exact-SHA CI run `30588820127` proved the Windows app itself builds, then exposed a runner-image compatibility defect in portable CRT discovery: VS 2026 adds a `v145` folder that is not a `System.Version`. Replaced name parsing with recursive x64 `Microsoft.VC*.CRT` payload discovery plus required-DLL validation; the VS 2026-shaped synthetic fixture and Windows contract suite pass. | hosted job `91026377542` log؛ workflow fix؛ `VS2026_CRT_DISCOVERY_OK`؛ Windows contract 4/4 |
| 2026-07-31T02:58:00+03:30 | active | CI run `30589918755` passed the VS 2026 CRT gate and created/timestamped MSIX `1.1.0.5`, then correctly failed SignTool policy verification because the pinned self-signed publisher was trusted only as a person, not as a root. The same already-validated CER is now imported into both CurrentUser trust stores only inside the ephemeral runner before packaging, fingerprint-checked, and removed from both stores in `finally`. | hosted job `91029767436` SignTool chain output؛ workflow trust/cleanup contract |
| 2026-07-31T03:16:00+03:30 | active | CI run `30590543232` passed Android and reached signed MSIX packaging, but root-store `Import-Certificate` remained interactive on the headless runner for more than ten minutes. Replaced that one operation with documented non-interactive `certutil -user -f -addstore Root`, retained exact thumbprint read-back and `finally` cleanup, then cancelled only the provably hung diagnostic run so the serialized fixed run could start. | hosted run state/timing؛ Microsoft certutil contract؛ workflow/test update |
| 2026-07-31T03:33:00+03:30 | active | CI run `30591480363` localized another headless stall to the beginning of signed packaging: the step stayed active for ۷:۵۶ with no runtime output versus the prior ۲۱-second failure baseline. This was consistent with an interactive root-trust wrapper but did not prove a visible prompt. Replaced the wrapper with direct current-user `.NET X509Store` read/write, pre-mutation cleanup ownership, exact thumbprint read-back, independent failure-path removal and non-secret phase markers; no secret or certificate path enters a new process. | hosted step timing؛ X509Store workflow contract؛ Windows/release tests |
| 2026-07-31T03:52:00+03:30 | active | Exact-SHA CI run `30592545128` proved that direct Root-store mutation also stalls the hosted Windows runner: source/goldens/build/portable passed, then the MSIX step remained active beyond two minutes before controlled cancellation. Removed all CI trust-store mutation. Run `30593360276` then completed package creation in ۱۷ seconds and exposed one over-strict check: AppX timestamp data is not surfaced through the primary CMS `UnsignedAttributes`, while SignTool explicitly proved the DigiCert timestamp chain. The gate now uses `SignedCms.CheckSignature(true)` for cryptographic integrity and pinned signer, SignTool for timestamp proof and its single exact private-root policy boundary, plus manifest/block-map identity and SHA-256. Device trust remains install-time policy. | hosted step timing/logs؛ Microsoft SignedCms/SignTool contracts؛ Windows/release tests |
| 2026-07-31T04:25:00+03:30 | active | Exact-SHA CI run `30594087276` passed Android completely and the Windows gate proved package identity، CMS integrity، pinned signer، DigiCert timestamp and the single expected private-root policy error. The script then surfaced SignTool's intentionally accepted native exit code as the overall PowerShell step status. Reset `$global:LASTEXITCODE` only after the exact allowlisted error passes؛ every unexpected SignTool result still throws. | hosted run/job logs؛ Windows/release tests؛ PowerShell native-exit contract |
| 2026-07-31T15:15:00+03:30 | active | Exact-SHA CI run `30626988976` passed both Android and Windows/MSIX. Independent raw-artifact inspection found the portable checksum named all three VC runtime DLLs while the uploaded ZIP omitted exactly those files. Dependency-source inspection replaced the initial hidden-attribute hypothesis with the proven cause: `msix 3.18.0` calls `cleanTemporaryFiles()` after packaging and deletes every `_vcRuntimeDllNames` entry from the shared Release directory. Moved the checksum-covered portable upload before MSIX packaging؛ a fresh hosted download must prove ۳۷/۳۷ parity. | run ۱۲ success؛ raw artifact ZIP؛ msix 3.18.0 source؛ workflow ordering contract |
| 2026-07-31T17:45:00+03:30 | active | Migrated Windows signing from the legacy self-signed `CA=true` signer to a replacement self-signed `CA=false` code-signing end entity while preserving package identity/publisher. Provisioner synthetic validation، encrypted-backup hash and rerun identity stability passed؛ Android signer stayed `144E87CB…F49B0AF` and Windows now pins `1424F286…BA24`. | commit `fe24d33`؛ provisioner synthetic PASS؛ repository variables؛ backup validation |
| 2026-07-31T17:50:00+03:30 | active | Exact-SHA run [`30637250609`](https://github.com/k1tvkli2003/Perfect/actions/runs/30637250609) (`#20`) passed all three jobs for `fe24d33f6b22a699619e1dc7afec4440ec89f4fc`: analyzer clean، 265/265 tests، signed Android `1.1.0+2020`، signed MSIX `1.1.0.20` and portable Windows. Independent artifact inspection passed Android package/label/three ABIs/v2/hashes، MSIX identity/publisher/`CA=false` signer/137 entries/hashes and portable 37/37 hashes؛ the downloaded executable launched responsive. The install-over step correctly emitted that no lower artifact exists with the new signer، so run `#20` establishes the baseline and does not prove an upgrade. | run `#20` jobs/artifacts/logs؛ independent artifact validation؛ portable launch smoke |
| 2026-07-31T18:25:00+03:30 | active | Exact-SHA run [`30639359490`](https://github.com/k1tvkli2003/Perfect/actions/runs/30639359490) (`#21`) passed all three jobs for `265f79aada41fee9a3b71db9a855b450e9898cbd`. The Windows runner installed baseline MSIX `1.1.0.20` and upgraded it to `1.1.0.21` with the same signer؛ package family and the exact LocalState marker were preserved. Independent downloads confirmed zero checksum mismatches، Android `1.1.0+2021` with the unchanged signer، MSIX `1.1.0.21` with the same `CA=false` certificate and a 37/37 portable bundle. | run `#21` jobs/artifacts/notice؛ independent artifact validation |
| 2026-07-31T19:00:00+03:30 | active | Exact-HEAD run [`30641054596`](https://github.com/k1tvkli2003/Perfect/actions/runs/30641054596) (`#22`) passed all jobs and upgraded MSIX `1.1.0.21 → 1.1.0.22` with package family/LocalState preserved. Independent final artifacts had zero checksum mismatch. The downloaded `1.1.0.22` portable then passed live Windows auth-surface inspection: correct Perfect! title/icon، restored/maximized، short `832×414` and compact `540×414` reflow، vertical scroll and action reachability. Signed-in workspace، hover semantics and jank were not claimed. | run `#22` jobs/artifacts/notice؛ Computer Use window screenshots and accessibility tree |

## Release checkpoint — 2026-08-02

Exact-HEAD run [`30721214315`](https://github.com/k1tvkli2003/Perfect/actions/runs/30721214315) (`#30`) برای commit `1b8468b18ec8edc2645ab73dffff23a6829ba0ea` پاس شد: ۲۶۶ تست، signed Android، Windows build، raw MSIX install-over `1.1.0.29 → 1.1.0.30` و self-contained Setup clean-install/rerun همگی سبز شدند. Release immutable [`v1.1.0-build.2030`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2030) دقیقاً APK، Setup.exe و Portable.zip دارد. دانلود مستقل هر سه فایل با digestهای GitHub برابر بود؛ APK identity/signature/سه ABI، Setup metadata/signer/timestamp و portable ۳۷-file runtime/zero banned extras پاس شدند.

ورود مالک خصوصی در همان Supabase user متصل به `planner_owner_profiles` تثبیت شد: نام کاربری اپ `keyvan` است، ایمیل انتقالی فقط از Secret بیلد می‌آید و رمز در سورس/Workflow ذخیره نمی‌شود. Admin API حساب موجود را بدون تغییر UUID به‌روزرسانی کرد؛ password sign-in واقعی، تطابق UUID مالک و metadata نام کاربری پاس شد و نشست آزمایشی بلافاصله revoke شد.

## Continuous perfection checkpoints — 2026-08-06

- Cycle 2 روی commit `5f49334a82189d976fa926b31b8f9c0488113a06` و exact-SHA run [`31051013501`](https://github.com/k1tvkli2003/Perfect/actions/runs/31051013501) بسته شد. Release immutable [`v1.1.0-build.2037`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2037) دقیقاً APK، Windows Setup و Windows Portable دارد؛ install-over و LocalState پاس‌اند.
- Cycle 3 فوتر compact را icon-only کرد، indicator بیضی Material را حذف و یک tile پاستلی ۴۸dp با motion/hover/semantics جایگزین کرد. مقصدها همچنان tooltip/semantic label و target کامل دارند.
- Quick Capture از یک ردیف فشرده و کم‌معنا به یک composer سلسله‌مراتبی تبدیل شد: هویت/بستن، field صریح، send و سه action هم‌اندازهٔ Plan، Perfect AI و Voice. AI و Voice اکنون SVG اختصاصی، text-free و transparent دارند؛ toggle اولیه هیچ IME را باز نمی‌کند.
- morph داک از `AnimatedSwitcher` دو-subtree به یک child جاری با AnimatedSize + fade/rise/scale منتقل شد. روی `Codex_API35` با renderer رسمی `host` چهار باز/بسته‌شدن متوالی، ADB و QEMU responsive ماندند؛ renderer منسوخ `swiftshader_indirect` خود AVD را حتی بدون لمس پایدار نگه نمی‌داشت و به‌عنوان proof اپ استفاده نشد.
- Orbit graphic و painter با scale مشترک ۹۵٪ یک gutter واقعی برای clock labels گرفتند؛ 6 AM/PM روی یک شعاع صریح و قرینه‌اند. حلقه‌های درصد ۶۲dp، stroke 4.5 و هستهٔ ۴۳dp با padding ۷ دارند؛ تست ۲۰۰٪ ثابت می‌کند copy از safe core عبور نمی‌کند.
- گیت محلی Cycle 3: analyzer clean، full Flutter ۳۵۸/۳۵۸، Workspace ۵۵/۵۵، AI Dock ۲۱/۲۱ و SVG/emoji contract ۳/۳. push/release این checkpoint هنوز pending است.

## Done So Far
- Durable task record and master plan.
- Preservation/compatibility contract before mutation.
- Preview ledger with mock/verified separation.
- Initial source/Git baseline, selected Orbit Day/wordmark/Day Compass decisions and complete identity history.
- Product research and native Android widget contract, with non-copy and platform boundaries.
- Broad Android/Windows Flutter implementation and Android widget source are present.
- V2 local-first/sync contract now includes private-owner isolation, durable outbox, exact idempotency, field conflicts, recurrence/recovery and advanced HabitNow-derived payload/evaluator coverage.
- A fresh Android release APK was produced from current source, installed and exercised on API 35.
- The full 266-test suite and analyzer are green؛ responsive/UI، release، AI، widget، signing and Deno checks also pass.
- Pixel Launcher runtime proof covers widget discovery, resize-specific compositions, native collection scrolling, direct outcome cycling, deep link and native replay queue.
- Visual/interaction hardening now covers 320dp, short landscape, expanded Windows composition, RTL, 200% text and reduced motion.
- release candidate `1b8468b18ec8edc2645ab73dffff23a6829ba0ea` passed exact-SHA CI run `30721214315`; signed Android، self-contained Windows Setup and clean portable are published in immutable Release `v1.1.0-build.2030`.
- Day Compass is the canonical transparent app asset; the ten blank-brief and five symmetric files remain comparison history.
- Final release audit is closed in source/docs: serialized CI queue، exact Android `VERSION_CODE` naming، automatic immutable three-asset release، self-contained Windows trust/install and recoverable offline signing backup.
- Final Android `1.1.0+2004` install-over proof is closed for package/data/widget identity; authenticated session retention remains explicitly unproven because the device began signed out.
- Windows signer migration and update continuity are closed: the package uses the `CA=false` end entity `1424F286…BA24`; run `#20` established baseline `1.1.0.20` and run `#21` upgraded it to `1.1.0.21` while preserving package family and the exact LocalState marker.

## Next
1. Exercise the signed-in main workspace on Android phone/tablet/Windows and record Windows hover/focus semantics and frame jank.
2. Prove authenticated Android↔Windows convergence/session retention، signed-in widget Quick Add and physical notification/OEM/reboot behavior.
3. Run positive AI text/voice/proposal-apply only after a rotated provider key is stored through the secure Supabase secret path.

## 2026-08-06 — 50-stage plan and preview-first production gate

### Completed in this planning checkpoint

- Created one canonical 50-stage master plan and one separate detailed work-order file
  for each Stage 01–50.
- Added a whole-product propagation ledger covering every entrypoint, page, workflow,
  state, platform consumer, local/Supabase/AI/widget path and release lifecycle.
- Rebuilt Stage 03 as an autonomous evidence/generative-direction gate with broad
  concept exploration and internal, recorded selection rather than owner voting.
- Rebuilt Stage 04 as an exhaustive component preview library: foundations, anatomy,
  all domain/interaction/system states, responsive variants, assets, semantics and
  motion boards before code.
- Rebuilt Stage 05 as a full page/overlay/widget preview corpus plus deterministic
  fixture, Copy side-by-side/diff and automated quality harness.
- Added `stages/preview-production-gate.md` with stable component/page IDs, artifact
  paths, viewport/state matrices, asset/motion manifests, internal acceptance schema
  and runtime mismatch severity/repair loop.
- Added a specific mandatory Preview+Copy entry gate to every runtime Stage 06–35 and
  normalized Stages 36–50 to the same owner-delegated autonomous acceptance model.
- Fixed README links for Stages 42, 45, 49 and 50 and updated Stage 04/05 titles in
  both the README and master plan.
- Preserved all unrelated/unaccepted source prototypes without staging or claiming
  them. No implementation, test or release result was inferred from documentation.

### Next executable work

1. Finish Stage 01 by freezing current Git/release/signing/schema/storage/session and
   two-version continuity evidence without mutating live data.
2. Complete Stage 02 source-backed route/interaction/action inventory and friction
   table, including widget, notification, protocol and AI entrypoints.
3. Execute Stage 03 research and design direction artifacts; then create the complete
   Stage 04 component plates and Stage 05 page compositions before accepting any
   runtime UI work.

## 2026-08-09 — Stage 01 executable preservation checkpoint

### Before

The project already had stable package/signing contracts and a v1→v2 happy-path
migration test, but it lacked a direct negative proof that explicit sign-out and
auth-scope disposal cannot erase planner/history/outbox data. Runtime values were
also passed to Flutter as command arguments, and final installables had no
exact-secret absence scan.

### After

- Added six preservation tests covering fixture isolation, destructive sign-out
  rejection, identity pins, artifact scanner behavior, file-backed lifecycle reopen
  and rollback/recovery after a simulated migration interruption.
- Replaced Android/Windows secret-bearing `--dart-define=...` arguments with protected
  temporary JSON and `--dart-define-from-file`.
- Added a cross-platform release scanner for exact protected values in raw artifacts
  and decompressed ZIP/APK/MSIX entries; wired it to Android and Windows trusted jobs.
- Froze Git, release, identity, asset hashes, local storage keys, Drift schema,
  Supabase migrations/RPC/RLS/function inventory and reset/delete classification in
  the Stage 01 evidence record.
- Preserved the retained stash, unaccepted UI/date prototypes and unrelated
  `.vscode`/`NUL` workspace files without staging or deleting them.

Local evidence is green. Commit/push and exact-SHA hosted verification are the final
Stage 01 transport actions; Stage 02 route inventory follows immediately afterward.

## 2026-08-09 — Stage 02 interaction and route checkpoint

### Before

Perfect! had many tested callbacks but no single source-backed model connecting row
taps, adaptive inspectors, native widget/reminder launches, shortcuts, AI writes,
local outbox mutations and sync. On compact/tablet layouts even copy labelled “Open
details” entered Edit directly, while destination-local filters, selected dates and
AI drafts could disappear during normal navigation.

### After

- Added the complete application/route tree, entity lifecycle, local-first, AI and
  Android-widget sequence diagrams.
- Mapped every Task/Habit input modality and every create/view/log/progress/edit/
  duplicate/archive/restore/delete/focus mutation to its current and canonical owner.
- Measured ten core jobs and set explicit target tap/keystroke budgets.
- Registered fifteen source-backed debts with priorities and later-stage owners.
- Classified all 27 whole-product coverage rows; none was omitted by silence.
- Added seven executable route/mutation contracts; the focused suite passes locally
  and focused analysis reports no issue.
- Preserved all unrelated UI/date prototypes, `.vscode`, `NUL` and the retained
  stash without staging or treating them as accepted work.

Stage 02 had no production UI mutation. Commit `b7c7279`, exact-SHA run `#41` and
release `v1.1.0-build.2041` closed its transport gate before Stage 03 began.

## 2026-08-10 — Stage 03 evidence and direction checkpoint

### Before

The product had a detailed 50-stage registry and source-backed route map, but the
forward visual direction still existed as prose plus historical Orbit screenshots.
There was no complete alternative search, no recorded second-pass choice, no exact
selected direction family and no deterministic plate set that could safely drive
Copy implementation without inheriting ImageGen text/identity drift.

### After

- Froze 34 Flutter/Android/widget/current-route captures with exact dimensions,
  hashes, defects, fixture boundaries and explicit current-evidence gaps. The 14 new
  phone frames cover all five primary destinations plus Quick Capture, AI, Sync,
  create/category/measure and direct-row-to-edit evidence.
- Decomposed all 25 HabitNow screenshots by decision dependency, recurrence,
  recovery and logging ergonomics; researched current Android/Windows primary
  conventions, seven planning peers and Dribbble craft patterns.
- Copied the 25 HabitNow source frames byte-for-byte into the repository and created
  uncropped, hash-frozen current/HabitNow/finalist contact sheets. Comparison can now
  be repeated without relying on a mutable Downloads folder or isolated images.
- Classified every whole-product surface through `KEEP`, `REFINE`, `REDESIGN`,
  `REMOVE` or `ADD`; no surface remains silently inherited.
- Authored 24 genuinely different recipes, shortlisted eight, completed four
  normal/stress finalist families and rescored them after visual inspection.
- Selected and froze `PS01 Perfect Day Instrument`: compact Pulse, one continuous
  Stream, distinct phone/tablet/Windows compositions, view-first detail, direct habit
  controls and one morphing Capture/Plan/AI/Voice surface.
- Preserved all eight model-native boards as noncanonical evidence after exact-text,
  identity and composition inspection rejected them as Copy targets.
- Authored and original-size inspected six deterministic identity/shell/workflow/
  state/motion/typography SVG+PNG plates. Exact mark/wordmark bytes and all hashes are
  frozen in the selected manifest.
- Added a reusable Playwright SVG renderer with installed Edge/Chrome fallback and
  an executable Stage 03 contract that passes 8/8.
- Preserved the retained stash and every unrelated/unaccepted workspace/date/test,
  `.vscode` and `NUL` file without staging or claiming them.

Stage 03 changed no shipped UI, route, domain or database contract. Stage 04 now owns
the exhaustive individual foundation/component previews; Stage 05 remains the final
page-composition/Copy barrier before production UI mutation.

Exact-SHA run [`31393887073`](https://github.com/k1tvkli2003/Perfect/actions/runs/31393887073)
(`#42`) passed all jobs for Stage 03 commit
`4ff5ebe317b4f41e7508a69fba2206b68e632d7e`. Release
[`v1.1.0-build.2042`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2042)
targets that exact SHA and contains only the signed Android APK, Windows Portable ZIP
and Windows Setup, each uploaded with a SHA-256 digest.

## 2026-08-10 — Stage 04 responsive design-system checkpoint

### Before

PS01 had six accepted direction plates, but it did not yet have executable ownership
for every reusable component. The preview gate enumerates 9 foundations and 181
component IDs across 27 semantic families. Without per-ID contracts and comparison
plates, page design could still invent local controls, spacing, states or motion.

### Execution contract

- Build the nine foundation specimens and one versioned token/asset/motion registry.
- Give all 181 IDs their own contract, anatomy, light/dark state, responsive,
  accessibility, motion and real-neighbor evidence.
- Generate family and whole-catalog contact sheets, then inspect critical and stress
  surfaces at original size rather than trusting file counts.
- Lock exact inventory and hashes with an executable Stage 04 contract.
- Keep production Flutter/native/domain/database/Supabase code untouched.

### After

- Froze design-system version `ps01-ds-1.0.0`: 9 foundation packets, all 181
  component contracts across 27 families, 1,267 component preview boards, 48
  transparent category SVGs and 20 named motion contracts.
- Gave every component its own semantic owner, anatomy, states, platform
  transformations, accessibility/RTL/200% behavior, motion/reduced-motion behavior,
  performance budget, fixture boundary, consumer map and neighbor proof.
- Rebuilt weak evidence discovered during original-size review: task rows no longer
  squeeze five columns; Pulse/Capture/motion specimens remain centered and unclipped;
  dark/high-contrast copy inherits explicit readable colors; habit status uses
  semantic SVGs instead of raw glyphs; widget previews now recompose by size class.
- Added deterministic foundation, component, family and master renderers plus a live
  DOM geometry inspector. The renderer recycles/retries bounded browser sessions so
  a partial browser crash cannot silently manufacture a complete catalog.
- Reduced the complete generated corpus to 148.18 MiB with palette-aware PNG
  optimization while retaining exact `1200×800` preview geometry and inspected mark
  quality. No generated file exceeds 4.49 MiB.
- Locked 1,576 generated-file hashes and verified 238 parseable SVGs, exact PNG
  signatures/dimensions, transparent icon canvases, no raw emoji/dingbats, complete
  provenance and zero stale/missing catalog files.
- Added `responsive_design_system_contract_test.dart`; Stage 03+04 focused contracts
  pass 16/16, the Stage 04 contract passes 8/8 independently and focused analyzer is
  clean.
- Preserved every unrelated/unaccepted production prototype, `.vscode`, `NUL` and
  retained stash without staging or treating them as accepted work.

Stage 04 changed no shipped Flutter UI, native code, route, domain, database or
Supabase contract. Stage 05 may now compose complete pages only from the frozen IDs,
tokens, assets, motion contracts and hashes; production implementation remains
blocked until Stage 05 closes.

Exact-SHA run [`31404235491`](https://github.com/k1tvkli2003/Perfect/actions/runs/31404235491)
(`#43`) passed all four jobs for Stage 04 commit
`c0a01133a7a4f8e5a7bcbffe2c51bcadbf0ae6f1`. Windows install-over preserved the
package family and LocalState from `1.1.0.42` to `1.1.0.43`; clean Setup and rerun
also passed. Release
[`v1.1.0-build.2043`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2043)
targets that exact SHA and contains only the signed APK, Portable ZIP and Setup.

## 2026-08-10 — Stage 05 full-product preview and Copy checkpoint

### Before

Stage 04 owned reusable parts, but no frozen page-level authority joined them into a
complete workflow. The gate still required 134 route/overlay/native compositions,
platform transformations, live text ownership, decision records, fixture isolation
and a Copy pipeline that could prove a mismatch rather than merely show two images.

### Execution contract

- Compose every exact gate page ID from frozen Stage 04 component IDs.
- Compare three genuinely different structures per page and record the autonomous
  winner, strongest rejected alternative and residual implementation risk.
- Render ten canonical phone/tablet/Windows/dark/stress/system/motion views per page
  and reject overflow, clipped required copy or lost platform chrome before writing
  the PNG.
- Map every live phrase, fixture, component consumer and scenario without allowing
  preview data or flattened dynamic copy into production.
- Prove the Copy harness with deliberately injected phone, tablet and Windows defects.

### After

- Froze page catalog `ps01-pages-1.0.0`: 134 pages in exact gate order across 11
  families, 402 structural candidates and 134 autonomous decision records.
- Generated 1,340 canonical views and 1,340 browser-derived geometry audits. Exact
  viewports cover compact/landscape phone, portrait/landscape tablet, compact/wide
  Windows, dark, 200% mixed-direction stress, system-state and motion boards.
- Mapped 1,072 live, unflattened Copy entries (8 per page), all 181 Stage 04
  components and six explicitly production-unreachable fixtures.
- Built deterministic phone/tablet/Windows Copy smokes. Geometry, typography and
  state mutations produce reference/runtime/overlay/diff evidence, identify exact
  page/scenario/category/field and fail CI with exit code 2.
- Used the composition audit to catch and repair real defects before freeze: footer
  and Capture occlusion, Today density rhythm, wizard final-action reach, compact
  week-plan overflow, feedback short-landscape ordering, widget host overflow, dark
  AI contrast and task status-ring centering.
- Limited generated cleanup to the 134 owned `pg-*` roots and named contact sheets.
  The Stage 03 handoff is snapshotted and SHA-checked before and after generation.
- Locked exactly 2,055 generated hashes across a 121.16 MiB corpus; the largest file
  is 1.96 MiB. Scoped Git attributes pin hash-sensitive contracts/evidence to LF so
  byte verification remains stable after Windows clones. No protected Stage 03 or
  unrelated workspace file enters the scope.
- `node tool/verify_stage05_page_library.cjs` passes all inventory, dimension,
  pixel-equivalence, fixture, Copy-failure and exact-coverage checks. The new Flutter
  contract passes 9/9, Stage 03+04 focused contracts pass 25/25 and full analysis is
  clean.
- Preserved all unrelated/unaccepted production prototypes, `.vscode`, `NUL` and the
  retained stash without staging or claiming them.

Stage 05 changes no shipped Flutter UI, native code, route, domain, database, auth,
sync or Supabase contract. Its commit/push and exact-SHA hosted checkpoint close the
preview-before-production barrier; Stage 06 must implement from exact preview IDs,
decomposition records and hashes rather than visual memory.

## 2026-08-12 — Stage 07 adaptive shell local checkpoint

### Before

The shipped shell switched layouts, but route widgets were not intentionally retained
as one stateful instrument. Android wide tablets could inherit desktop navigation,
Windows rail behavior was not isolated in tests, intermediate resize contracts were
thin and real 200%/800dp runtime review exposed clipped copy plus large dead space.

### After

- Added a keyed persistent host for Today, Tasks, Plan, Habits and More with hidden
  pointer/semantics/ticker/focus isolation and retained filter/calendar/scroll state.
- Made shell tiers content-driven and platform-aware; Android wide tablets default to
  a compact rail while Windows restores the saved owner choice.
- Added direction-aware page motion, reduced-motion behavior, local footer/rail
  arrows/Home/End, Ctrl+1…5, Escape context dismissal and a keyboard-resizable 48dp
  inspector divider.
- Reflowed the 200% compact Compass summary and rebuilt 800dp portrait Today as one
  useful reading column rather than a tiny panel stretched through empty height.
- Verified real Android phone, tablet portrait and tablet landscape states; capture
  opens without the IME, rail expansion does not overlap, the last stream content is
  scroll-reachable and fatal/overflow log scans are clean.
- `flutter analyze` passes and the full suite passes 404/404. The versionCode 2048
  preview installed over the existing package while preserving first-install time.

### Next

- Complete: Stage 07 exact commit `004c2567e67efc888f767b39333fb23a4a55bcbb`
  passed run `#48` / `31549435764`; release `v1.1.0-build.2048` targets that SHA
  with exactly the three install-ready assets.

## 2026-08-12 — Stage 08 glass header, sync confidence and dual time checkpoint

### Before

The phone header relied on a translated stack instead of owned geometry, wide
surfaces repeated date copy, the clock only refreshed with broad page rebuilds and
the sync decoration did not expose the repository's actual retry deadline. Date/time
formatting was scattered across UI, widget, feedback and AI request paths.

### After

- Added a lifecycle-aware minute clock that aligns to minute boundaries and rebuilds
  only its local subtree; injected clocks keep every test deterministic.
- Centralized device-local Gregorian, Solar-Hijri, 12-hour and inspector formatting;
  required Nowruz and Jalali boundary vectors are locked by tests.
- Rebuilt the phone and wide headers as bounded theme-aware glass compositions with
  explicit non-blur/high-contrast fallback, content-driven reflow and no negative
  translation hack.
- Rebuilt Cloud as authored vector geometry with green/yellow/red states, non-color
  semantics, local last-success time, real retry countdown and a safe details/retry
  surface. Local work stays available during offline/error states.
- Removed scroll-to-refresh from Today; repository status and remote updates remain
  live without resetting scroll or destination state.
- Added validated device-local date/clock/UTC-offset context to AI requests while
  keeping persistence and sync timestamps in UTC and provider secrets off-client.
- Inspected real Android phone light, dark and 200% states, sync details, tablet
  portrait and landscape. All captures belong to the confirmed foreground Perfect
  preview package; no fatal/Flutter overflow signature matched.
- `flutter analyze`, Deno format/check and the complete 421/421 Flutter suite pass.
  VersionCode 2049 installed in place with the original first-install timestamp.

### Hosted closure

- Stage 08 source checkpoint `cc2ff2b15b81486903b425a51d351b2fa809c187`
  passed GitHub Actions run `#51` / `31636360008` attempt 2. The first attempt was
  rejected after the official SQLite binary download closed before its headers;
  rerunning the same SHA, without a source workaround, proved the failure transient.
- Quality/Android, Windows build, private build identity and atomic release jobs all
  passed. Windows proved install-over LocalState preservation and Setup clean plus
  idempotent rerun. Release `v1.1.0-build.2051` targets the exact commit and contains
  only the APK, Portable ZIP and Setup EXE with GitHub-recorded SHA-256 digests.
- The owner's five protected working-tree paths and retained pre-existing stash were
  restored byte-for-byte after every merge/push checkpoint.

### Next

- Close the Stage 08 documentation checkpoint through the same exact-SHA hosted gate,
  clean its isolated branch/worktree, then begin Stage 09 motion and interaction work.

## 2026-08-13 — Stage 09 global motion local checkpoint

### Before

Perfect! had several useful animations, but duration/curve ownership was split,
dialogs inherited a generic fade, page/content entrances could over-choreograph a
dense Today surface and persistent destination hand-off could make an expensive
glass viewport repaint. Lifecycle, focus return, interrupted taps and reduced motion
were not one executable product contract.

### After

- Added seven named motion roles and centralized timing, reverse timing, curves,
  optical travel and reduced-motion resolution.
- Rebuilt workspace hand-off so only the active retained destination paints; a tiny
  isolated edge cue and selected footer/rail glyph explain direction without moving
  the whole viewport.
- Added one-shot, ten-pixel page-title rise/fade that does not replay on sync/list
  rebuilds; removed the cascading animation of Orbit, next-up and agenda rows.
- Routed all production dialogs through an invoker-anchored, focus-trapped and focus-
  restoring transition; sheets, menus, wizard, inspector, capture and AI now use the
  same vocabulary.
- Paused Quick Capture, Sync and Orbit animation work when reduced, offstage or in
  the background; durable state remains authoritative on resume.
- Generated 11 six-frame storyboards and a 131-record motion inventory. The verifier
  passes 24 design hashes and nine Android runtime hashes.
- `flutter analyze` and all 432 tests pass. Workspace is 60/60, Header/Sync 10/10 and
  the focused Motion gate 19/19.
- Android profile `1.1.0+2060` built and installed over the sibling preview while
  retaining `firstInstallTime=2026-08-02 19:20:44`. Real runtime screenshot,
  semantics, MP4, memory, navigation timing, idle windows and minimal control are
  recorded in `09-stage-verification.md`.
- Real workspace build-thread samples stay below 16.67ms. Emulator raster is honestly
  inconclusive because the minimal control shows the same host floor; physical
  Android and Windows no-jank are not claimed.
- Local Windows compilation still stops at missing ATL `atlbase.h`; exact-SHA hosted
  Windows/install-over/release proof remains mandatory.

### Hosted closure

- Source checkpoint `6ca824ef2f0dd0b3facd66c194668381e81b88d1` passed branch run
  [`31663309577`](https://github.com/k1tvkli2003/Perfect/actions/runs/31663309577)
  attempt 2. Attempt 1's Android build ended only because the official Gradle wrapper
  download returned `Unexpected end of file from server`; the same SHA then passed
  all 432 tests, APK build/checksum/upload and the Windows portable gate unchanged.
- The source was fast-forwarded to `main`. Trusted run
  [`#54` / `31664886708`](https://github.com/k1tvkli2003/Perfect/actions/runs/31664886708)
  passed all four jobs, including signed Android, signed Windows packaging,
  `1.1.0.52 → 1.1.0.54` MSIX install-over with package family/LocalState preserved,
  and Setup clean-install plus idempotent rerun without mutating Root.
- Immutable release
  [`v1.1.0-build.2054`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2054)
  and its tag target the exact source SHA and contain exactly the install-ready APK,
  Windows Portable ZIP and Windows Setup EXE recorded in `09-stage-verification.md`.

### Next

- Close this documentation checkpoint through the same exact-SHA trusted gate,
  remove the isolated branch/worktree, then begin Stage 10 theme and accessibility
  motion without weakening the physical-target no-jank boundary.

## 2026-08-13 — Stage 10 authored theme and contrast closed checkpoint

### Before

Dark appearance still inherited light-first assumptions, Clarity had no complete
product path, shared components could bypass semantic roles, Orbit artwork and
curved labels had theme-dependent readability gaps, and native widget/Quick Add plus
the Windows frame did not follow one effective owner appearance.

### After

- Authored four complete theme registries and froze their IDs, roles, measured
  contrast and component/page consumers.
- Eliminated reusable raw color bypasses; added semantic scrim, inverse surfaces,
  interaction ink and zero-blur Clarity material.
- Added dedicated Clarity Orbit assets and fixed curved label ink against every
  pastel period arc.
- Added persisted contrast selection and a native appearance projection for Android
  application mode/widget/Quick Add and Windows DWM/system high contrast.
- Extended the development Preview to expose the same independent Theme/Clarity
  controls as production, then installed build 2062 in place and captured four live
  compositions plus the settings surface.
- Refreshed and expanded phone/tablet/Windows goldens only after side-by-side visual
  inspection; the full suite now passes 444/444.
- Hash-locked 13 real Android runtime artifacts and made the independent verifier
  reject evidence drift.

### Next

- Exact-SHA branch run `31685867478` and trusted main run `31687276749` passed.
  Windows MSIX `1.1.0.55 → 1.1.0.57` retained package family/`LocalState`; Setup
  clean/rerun passed without Root mutation. Immutable release
  `v1.1.0-build.2057` targets Stage 10 SHA `8742a676533d3337ed5d69919cd8d612e08c6024`
  and contains exactly APK, Portable ZIP and Setup EXE.
- Close the documentation checkpoint, remove the isolated Stage 10 branch/worktree
  and begin Stage 11 from the clean trusted `main` lineage.

## 2026-08-14 — Stage 11 Today Pulse local checkpoint

### Before

Orbit still consumed the dominant Today viewport, repeated orientation/task
information already owned by the stream, carried dedicated theme assets and kept
phone/tablet/Windows around a circular model the approved direction had retired.

### After

- Deleted Orbit production source, assets, generator and dedicated accessibility
  test; added a regression contract that keeps the retired model out of source,
  assets, widget tree and semantics.
- Implemented a compact adaptive Today Pulse with live local time, Gregorian/Jalali
  date, daily completed/remaining/review projection, next start/due/cross-midnight
  boundary, one Plan action and an authored semantic Dayline.
- Recomputed task truth from daily occurrences and habit truth from day summaries;
  unresolved recurrence remains pending and cannot inherit lifecycle completion.
- Removed the duplicated Today header clock, Plan command, next-up title and habit
  summary. Stream rows retain identity, mutation and scroll ownership.
- Rebalanced sparse/short/wide Today composition and corrected the final Inspector
  action/fact geometry discovered through side-by-side golden inspection.
- Regenerated and visually inspected 14 workspace goldens. Analysis is clean and
  the complete suite passes 449/449.
- `1.1.0-preview+2064` installed over 2063 without changing the original install
  time. Fresh phone, tablet portrait, tablet landscape and scrolled-final-row
  evidence is hash-locked across nine files; the clean launch has zero relevant
  fatal/Flutter/overflow matches.
- Stage 10 runtime verification and the expanded Stage 11 verifier pass. Historical
  exact-byte Stage 04/10 design-manifest scripts remain CRLF-sensitive on this
  Windows checkout; the corresponding HEAD blob hashes and Flutter contract tests
  match, so this is not treated as product drift.
- Local Windows build still stops at the machine's missing ATL `atlbase.h` before
  linking the notification plugin. Hosted exact-SHA Windows packaging remains the
  authority.

### Next

- Commit and push the isolated Stage 11 checkpoint, require the exact SHA to pass
  hosted Android and Windows gates, fast-forward trusted `main`, prove Windows
  install-over/LocalState plus Setup rerun, publish exactly APK/Portable/Setup, then
  record closure and remove every Stage 11 branch/worktree.
