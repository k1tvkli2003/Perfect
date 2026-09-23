# Verification

## Compact viewport checkpoint — 2026-09-17

Changed tests only: compact Today and compact AI now set view metrics through
`_setTestViewSize` and explicitly check MediaQuery/render sizes both equal
390x844. Existing golden assertions remain intact.

- Command: `flutter test --no-pub --concurrency=1 --reporter expanded test/presentation/perfect_workspace_page_test.dart --name 'compact Today Pulse keeps navigation|compact AI toggle lives'`.
- Result: 0 passed / 2 failed, exit 1, 4 seconds. Size checks passed before the
  golden failures; original mismatches remain 12857 (3.91%) and 9530 (2.90%) pixels.
- Actual-image hashes unchanged: compact
  `f50ab9dee95be5a4355f6deffedd81d86e5e954e93578e67a0d3f728c5fbdaa1`,
  compact AI closed
  `0ce4a3fe4c033f79f897ce368d1d931b9e4e8bb69cb46217d39b499743e181b0`.
- Master compact hash unchanged:
  `304e86b34c75494667ef960d2a77cfc2465c4b24c7b889647bc85f96f70dd7fe`.
- `dart format --output=none --set-exit-if-changed test/presentation/perfect_workspace_page_test.dart`: exit 0, 0 changes.

Confirmed: viewport inconsistency is fixed for these two tests and was not the
cause of their golden differences. Not confirmed: other legacy viewport fixtures,
visual design, current full-suite pass, runtime or stage closure. No golden update.

## Typed-row refactor checkpoint — 2026-09-17

Production workspace SHA256:
`8d177cc89e3bd8ea821805eacb9b07fb0542bff0f7f64bf9561e4e92862d7a45`.

| Check | Command / method | Result |
|---|---|---|
| Workspace gate | `flutter test --no-pub --concurrency=1 --reporter expanded test/presentation/perfect_workspace_page_test.dart` | 63 passed / 8 golden failures, exit 1, 31s |
| Analysis | `flutter analyze --no-pub` | No issues, exit 0, 77.4s |
| Format | `dart format --output=none --set-exit-if-changed lib/presentation/perfect_workspace_page.dart test/presentation/perfect_workspace_page_test.dart` | exit 0, zero changes |
| Patch whitespace | `git diff --check` | exit 0 |
| Render preservation | SHA256 before/after for all eight regenerated failure actual PNGs | all equal; not acceptance against master goldens |

Before/after identical actual-image hashes:

| Image prefix | SHA256 |
|---|---|
| perfect_compact_ai_closed | `0ce4a3fe4c033f79f897ce368d1d931b9e4e8bb69cb46217d39b499743e181b0` |
| perfect_compact | `f50ab9dee95be5a4355f6deffedd81d86e5e954e93578e67a0d3f728c5fbdaa1` |
| perfect_expanded | `0532cf534a82102d29f49d822924275c9bf039e84ff6c2cc9202f3ed290179ac` |
| perfect_stage10_phone_dark | `7b6fd27650cf78864e71e60161edac30eb9c03a15bd470e801e4c8f5744316c1` |
| perfect_tablet_landscape | `5ec6a8ea9b45433825fc192ddc800a02c5ba5883501c4b0c142a73f5bc1e796f` |
| perfect_tablet_rail_compact | `28baf3fde2e68c6cfb6166298deae437320d71f4f05830c0742570db4e3b256d` |
| perfect_windows_short | `519a005194e422ac38cf2f16a896f89ca898f2220d4683dee069c26c1c442e7c` |
| perfect_windows_wide_inspector | `530fa71993270afff5f860587d5f58638969b0cfa7838ce94122c656cfa11a91` |

Image path convention: `test/presentation/failures/<prefix>_testImage.png`
relative to repository. These are local test captures, not installed runtime.
No full-suite run after refactor; no golden regeneration/acceptance or stage closure.

Additional isolated compact probe (temporary instrumentation removed): theme
font `PlusJakarta`, fallback `[Vazirmatn]`, text scale `1.0`; MediaQuery size
`800x600` while workspace render bounds are `390x844`. The test uses
`binding.setSurfaceSize`, unlike `_setTestViewSize` which also sets view metrics.
This is a confirmed test-environment inconsistency, not proof that it caused the
golden difference. Original compact golden still failed at 12857 pixels / 3.91%,
exit 1. Next viewport work must synchronize actual view metrics and constraints,
then separate harness changes from intended design changes. Do not regenerate
goldens merely to hide that distinction. No font/tolerance/master change made.

## Additive behavior checkpoint — 2026-09-17

Production UI unchanged from the grouping prototype checkpoint below. Four
tests added without deleting or altering existing golden comparisons.

| Check | Command / method | Result | Limit |
|---|---|---|---|
| Section lifecycle | `flutter test --no-pub --concurrency=1 --reporter expanded test/presentation/perfect_workspace_page_test.dart --plain-name 'Today section lifecycle follows stored outcomes'` | 3/3 passed, exit 0 | 390/800/1366dp; persisted completion/correction, empty groups, order, stable ID; not Undo button proof |
| AI interaction independent of raster checks | Same command with `--plain-name 'Today AI open close preserves capture draft independently of goldens'` | 1/1 passed, exit 0 | Two open/close cycles; draft, bounds, navigation, no new task; fake AI client, no live provider proof |
| Original isolated golden | Same command with `--plain-name 'compact AI toggle lives inside quick capture and opens above it'` | 0 passed / 1 failed, exit 1 | 2.90%, 9530 pixels; original viewport 390x844 |
| Pixel bounds | Read-only System.Drawing comparison of failure master/test images | 9530 unequal pixels, x=20..369 and y=413..546 | 6677 pixels in y=400..499, 2853 in y=500..599; numerical, not visual review |
| Formatting | `dart format --output=none --set-exit-if-changed test/presentation/perfect_workspace_page_test.dart` after formatter | passed, exit 0; 0 changes | One test file |

The file now defines 71 tests (67 prior + 4 new). No full-suite result for these
additions is inferred from prior 479/487. Image inspection remains unavailable;
golden baselines and production code were not changed in this checkpoint.

Temporary bounds instrumentation in the original isolated golden identified
`Scheduled` text at `(20,421)..(370,435)`, task title at
`(72,475.5)..(185.3,490.5)`, and `Habits` text at `(20,540)..(370,554)`.
The section widgets occupy y=401..447 and y=520..566: each adds 46px from
20px top padding, 14px text and 12px bottom padding. These match the changed
day-stream region, not the AI dock. The diagnostic run exited 1 with the same
9530-pixel mismatch. Instrumentation was removed; no assertion or golden changed.
This narrows the geometry cause but does not select/approve a visual design.

## Grouping prototype checkpoint — 2026-09-17

Source: `0ef09ce` plus existing uncommitted UI grouping patch. Supersedes the
pre-grouping status below; does not supersede historical evidence for its SHA.

| Check | Command / method | Result | Scope |
|---|---|---|---|
| Unfiltered workspace | `flutter test --no-pub --concurrency=1 --reporter expanded test/presentation/perfect_workspace_page_test.dart` | 59 passed / 8 failed, exit 1, 51 seconds | All eight failures at golden comparisons; real-row grouping passed |
| Full sequential integration | `flutter test --no-pub --concurrency=1 --reporter expanded` | 479 passed / 8 failed, exit 1, 2 minutes | Same eight workspace golden failures; no whole-suite pass |
| Analyzer | `flutter analyze --no-pub` | exit 0, 81.2 seconds; `No issues found!` | Static analysis only |
| Formatting | `dart format --output=none --set-exit-if-changed lib test` | exit 0; 181 files, 0 changed | Formatting only |
| Selected platforms | `python C:/Users/K1/.codex/skills/multi-os/scripts/audit_flutter_targets.py --project C:/Users/K1/Desktop/Projects/Perfect --targets android,windows,pwa` | exit 0 | Android/Windows files configured; PWA NOT PREPARED; no build/install proof |
| Visual inspection | `view_image` for AI-closed test/master images | unavailable | Tool rejects image inputs; screenshots not inspected or accepted |

Golden mismatches: compact 3.91%, phone dark 3.92%, compact AI closed 2.90%,
tablet compact rail 11.06%, tablet landscape 18.92%, expanded Windows 15.09%,
wide inspector 9.67%, short Windows 8.95%. Goldens remain unchanged. A failed
comparison can prevent later assertions in the same test from executing.

No stage closure, current CI/release, PWA deployment, or install-over claim.
Production workspace file SHA256 at completion:
`293f9a24d6a0714fcff092d60c5447ff7c1acd1616022bc852b16c8ab1ee5980`.
Task documentation structure validator passed; `git diff --check` passed.

## Current focused checkpoint — 2026-09-17

Source: `main` at `0ef09ce`; Flutter 3.44.0, Dart 3.12.0. Production source
unchanged during these checks. The older full-suite results below do not certify
current HEAD.

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Widget protocol/projector/replay | `flutter test --no-pub --concurrency=1 --reporter expanded test/widgets` | passed, exit 0 | 18/18; not the workspace grouping contract |
| Requested stack flag | Focused workspace command plus `--chain-stack-traces` | CLI rejected, exit 1 | `Could not find an option named "--chain-stack-traces".`; zero tests loaded |
| Workspace grouping | `flutter test --no-pub --concurrency=1 --reporter expanded test/presentation/perfect_workspace_page_test.dart --plain-name 'Today exposes scheduled and habit groups around real rows'` | failed, exit 1 | 0 passed / 1 failed; line 1737, expected one `Scheduled`, found zero; preceding Task/Habit presence assertions passed |
| Preview authority | Existing `stage12-today-stream/decision.md` and `layout-contract.json` | unapproved | Mock Preview, selected candidate null; not runtime evidence |
| Documentation structure | `python C:/Users/K1/.codex/skills/work-docs/scripts/validate_task_docs.py C:/Users/K1/Desktop/Projects/Perfect/docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild --structure-only` | passed, exit 0 | `OK`; structure only, not product acceptance |
| Patch integrity | `git diff --check`; `git diff --numstat -- lib/presentation/perfect_workspace_page.dart` | passed | No whitespace errors; no final production-source diff |
| Domain hypothesis | `flutter test --no-pub --concurrency=1 --reporter expanded test/planner/planner_today_stream_test.dart` | passed, exit 0 | 15/15 after a new timed/untimed habit input-order regression |
| Fresh sequential baseline | `flutter test --no-pub --concurrency=1 --reporter expanded` | failed, exit 1 | 486 passed / 1 failed; sole failure is `Today exposes scheduled and habit groups around real rows` at line 1737; not flake or model failure |
| Reproduction after baseline | Same focused workspace command | failed, exit 1 | 0 passed / 1 failed; `Scheduled` found 0 despite real rows; line 1737 |
| Analyzer baseline | `flutter analyze --no-pub` | passed, exit 0 | `No issues found!` |
| Formatting | `dart format --output=none --set-exit-if-changed test/planner/planner_today_stream_test.dart` | passed, exit 0 | No formatting drift after final formatting |

The full-suite and analyze entries above describe the earlier pre-grouping
checkpoint only. No Windows build, Android runtime, browser, hosted CI, release
or install-over proof is claimed for the current dirty grouping prototype.

## Current checkpoint — 2026-09-12

Historical results below remain scoped to their dated source. Stage 12 remains
active and visual acceptance is still open.

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Today UI integration | `flutter analyze --no-pub` + `flutter test --no-pub --concurrency=1` | passed | Analyzer clean; full sequential suite 479/479. `PlannerTodayStream` and daily task outcomes now drive compact/medium/expanded Today rows instead of row-local recurring reads. |
| Android runtime capture | cold start `lib/dev/perfect_live_preview.dart` on `Codex_API35` / `emulator-5554`; `adb exec-out screencap -p` | captured | [`assets/perfect-stage12-preview-runtime-2026-09-12.png`](assets/perfect-stage12-preview-runtime-2026-09-12.png). Runtime evidence only; not a side-by-side preview gate acceptance or whole-product proof. |
| Trusted main CI | [`run 34653499443`](https://github.com/k1tvkli2003/Perfect/actions/runs/34653499443) at `dbf8752` | passed | All quality, Android, Windows, publish and rotation jobs passed. |
| Private release | Release API `v1.1.0-build.2067` | passed | Exactly `Perfect-1.1.0-build.2067-Android.apk`, `Perfect-1.1.0-build.2067-Windows-Portable.zip`, and `Perfect-1.1.0-build.2067-Windows-Setup.exe`; draft false and prerelease false. |
| Windows Setup/install continuity | trusted runner job `Windows desktop build` | passed | Clean install then idempotent rerun of `1.1.0.67`; package family and `LocalState` preserved; Trusted Root unchanged. |

## Current checkpoint — 2026-09-11

Historical results below are scoped to their dated source, not current HEAD.
Stage 12 remains active; no visual or whole-product closure is claimed.

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Today semantic projection | `flutter test --no-pub --concurrency=1 test/planner/planner_today_stream_test.dart` | passed | 12/12; recurrence occurrence-time ordering, stable ties, quota override, inactive filtering, daily outcomes, rollover and immutable output. Not yet wired into Today UI. |
| Today storage-backed projection | `flutter test --no-pub --concurrency=1 test/planner/planner_today_stream_storage_test.dart` | passed | 6/6 with real in-memory Drift and production controller reads: quota exclusion, pinned-day rollover, owner isolation, habit amount/undo, exceptions/recovery and no seed/mutation on read. |
| Editor date bounds and clock | `flutter test --no-pub --concurrency=1 test/presentation/planner_editor_test.dart` | passed by owning worker | 17/17, including 11 added regressions. Old/distant schedule, deadline, recurrence-end and block-end picker assertions reproduced before repair; calendar cancellation preserves stored timestamp. |
| Artifact transport guard | `python .github/scripts/test_artifact_rotation.py` | passed | 20/20 offline fake-API cases; no live artifact deletion or API call was made. |
| Static analysis | `flutter analyze` | passed | `No issues found!` |
| Full Flutter suite | `flutter test --no-pub --concurrency=1` | passed | 479/479 sequential tests after the pinned-day projection fix. |
| CI-only feedback export flake | trusted main run `34549428281`, failed Test step | reproduced from log | `TimeoutException after 0:00:00.025000` escaped while the test waited for Windows staging; root cause was matcher attachment timing, not cleanup semantics. |
| Feedback exporter regression | `flutter test --no-pub --concurrency=1 test/feedback/feedback_exporter_test.dart` | passed | 13/13 after attaching both stalled-delivery `expectLater` futures before stage/commit waits. |
| Trusted main CI | [`run 34550905297`](https://github.com/k1tvkli2003/Perfect/actions/runs/34550905297) at `959b34d` | passed | All quality, Android, Windows, publish and rotation jobs passed. |
| Private release | Release API `v1.1.0-build.2065` | passed | Exactly `Perfect-1.1.0-build.2065-Android.apk`, `Perfect-1.1.0-build.2065-Windows-Portable.zip`, and `Perfect-1.1.0-build.2065-Windows-Setup.exe`; draft false and prerelease false. |
| Windows Setup/install continuity | trusted runner job `Windows desktop build` | passed | Clean install then idempotent rerun of `1.1.0.65`; package family and `LocalState` preserved; Trusted Root unchanged. No older MSIX transport existed, so MSIX upgrade proof begins at build 2066. |
| Current CI repair | trusted main run `32791367184` at `d0a62b9`, inspected 2026-09-09 | failed | Both artifact uploads hit storage quota; install-over, Setup and publish skipped. Failure-path artifact hygiene passed, not success rotation. |
| Existing upgrade transport | artifact `9206952095`, inspected 2026-09-09 | expired | Expired 2026-08-28; older release is not an available Actions baseline. |
| Emulator / Android install / motion | deliberately not run | deferred | Explicit RAM constraint; unit/widget tests do not prove device behavior, screenshots or upgrade continuity. |
| Artifact guard repair / store-backed Today proof | current unfinished work | pending | Require fake-API destructive-manifest tests and real in-memory daily-state fixtures before acceptance. No live deletion authorized by these tests. |

## 2026-08-05 Critics baseline

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Focused domain and presentation baseline | `flutter test test/planner/planner_habit_day_summary_test.dart test/presentation/planner_editor_test.dart test/presentation/focus_session_sheet_test.dart test/presentation/perfect_workspace_page_test.dart` | passed | 61/61; this validates existing assertions but does not waive the frozen C1–C12 findings. |
| Android signed-in preview inspection | live preview on `emulator-5556`, 1080×2400, API 35 | partial pass | Tasks/Habits/wizard flows rendered and remained actionable; runtime exposed the truthful-data, hierarchy and occlusion findings recorded in `10-critics-tasks-habits-editor-ledger.md`. |
| Approved-reference comparison | side-by-side inspection of current Android Home and the selected reference | failed quality gate | Home is directionally close, but last-row continuity and Orbit finish remain below the accepted target. |
| Local Windows preview build | `flutter build windows --debug -t lib/dev/perfect_live_preview.dart` | not run successfully | blocked by missing Visual Studio Desktop C++ toolchain on this host; existing goldens and hosted release builds are supporting evidence, not live hover/motion proof. |

## 2026-08-05 Perfect Cycle 1 — pending Habit truth

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Domain regression | `flutter test test/planner/planner_habit_day_summary_test.dart` | passed | Pending count target 8 and checklist threshold 2/3 are preserved. |
| Workspace regression | focused `perfect_workspace_page_test.dart` | passed | Compact Habits renders `Pending · 0 of 8 glasses · 0%` and rejects the old `of 1 glasses` output. |
| Static analysis | `flutter analyze` | passed | `No issues found`. |
| Full Flutter suite | `flutter test` | passed | 355/355. |
| Android preview build/install | debug sibling APK from `lib/dev/perfect_live_preview.dart`, `adb install -r` | passed | Production package/session remains untouched; preview package updated successfully. |
| Android runtime semantics and screenshot | API 35 `emulator-5556` | passed | Expected measured target present in UI and semantics; screenshot at `.codex-tmp/critics-cycle1/android-habits-cycle1-fixed.png`. |
| Cold-start crash scan | clear logcat, force-stop, cold start, 3-second scan | passed | 2685 ms; no `FATAL EXCEPTION`, `E/flutter` or preview-process fatal match. |

## 2026-08-06 Perfect Cycle 2 — truthful Tasks and progressive filters

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Exact previous-stage release | workflow run `31041370535` and release API | passed | SHA `a793531…`; run #36 success; immutable `v1.1.0-build.2036` has exactly Android APK، Windows portable ZIP and Windows Setup EXE. |
| Task default truth | compact workspace widget test + API 35 preview | passed | `Focus Deep Work` and all three active tasks are visible without choosing a filter; Inbox remains explicitly selectable. |
| Progressive filter behavior | compact/wide widget tests and Android screenshots | passed | phone defaults to Search + `Open · All`; TYPE/STATUS animate on demand; 900dp retains inline controls. |
| Keyboard lifecycle | widget input visibility + Android `dumpsys input_method` | passed | Search opens IME; tapping the filter summary unfocuses Search, reports `mInputShown=false`, opens filters and restores the task list. |
| Large text and RTL | 390dp RTL at 200% | passed | filter summary and result count recompose instead of truncating; no exception. |
| Selection language | ChoiceChip inspection | passed for Task filters | selected color/shape remains, `showCheckmark=false`; category/icon/color surfaces remain under C5. |
| Static analysis | `flutter analyze` | passed | `No issues found`; deprecated SizeTransition API was replaced before closure. |
| Full Flutter suite | `flutter test` | passed | 356/356. |
| Android runtime | debug sibling preview on `emulator-5554`, API 35 | passed | cold start 3291 ms; collapsed/expanded screenshots under `.codex-tmp/critics-cycle1/`; no `FATAL EXCEPTION` or `E/flutter` match. |

## Summary

- Result: partial
- Interpretation: the integrated Flutter/AI/backend source، exact-SHA CI and all three install-ready private Release assets pass their automated/integrity gates. Android install-over، Windows update continuity and the self-contained Setup clean-install/rerun path are proven؛ signed-in cross-device and remaining GUI/device-runtime journeys remain open.
- Last verified: 2026-08-02T02:35:00+03:30
- Final Android artifact under test: `build/private-update-proof/perfect-1.1.0+2004.apk`
- Current final APK SHA-256: `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`
- Hosted exact-HEAD commit: `1b8468b18ec8edc2645ab73dffff23a6829ba0ea`
- Hosted CI: [run `30721214315`](https://github.com/k1tvkli2003/Perfect/actions/runs/30721214315) (`#30`), conclusion `success`
- Immutable Release: [`v1.1.0-build.2030`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2030)، exactly three uploaded assets

این سند بین «اثبات اجرا»، «اثبات hosted build/artifact»، «بررسی خودکار» و «بررسی در دسترس‌نبوده» فرق می‌گذارد. source جاری analyzer و ۲۶۶ تست را پاس کرده، migration امن context و Function v3 زنده‌اند و runهای exact-SHA update continuity را حفظ کرده‌اند. Run `#30` علاوه بر raw install-over، خود Setup را برای clean install و rerun اجرا کرده و Release immutable را پس از download/hash verification منتشر کرده است. portable قبلی auth surface را در GUI واقعی wide/short/compact بررسی کرده است؛ این شاهد به signed-in Orbit workspace، hover یا jank تعمیم داده نمی‌شود.

## Current integrated source proof

| Check | Result | Evidence |
|---|---|---|
| Flutter static analysis | passed | `flutter analyze --no-pub` → no issues |
| Full Flutter suite | passed | `flutter test --no-pub --reporter compact` → 266/266 |
| Workspace UI/adaptive suite | passed | 44/44؛ expanded/short/wide Windows، tablet، 200% text and resize paths |
| Private release continuity contract | passed | monotonic Android/MSIX version mapping، signer constraints، artifact naming and baseline/install-over guards |
| Release queue and artifact contract | passed locally and hosted | `queue: max` accepted by GitHub؛ exact Android `VERSION_CODE` naming and three private artifacts proven in run `#20` |
| actionlint compatibility | passed with one scoped compatibility ignore | v1.7.12 predates `concurrency.queue`؛ only the exact new-key diagnostic is ignored، all other diagnostics remain fatal |
| Windows private installer | passed | Setup پین‌شده، clean install، rerun، حفظ package family/LocalState، عدم تغییر Root و rollback کنترل‌شده؛ encrypted offline signing backup/restore نیز باقی است |

## Immutable install-ready Release `v1.1.0-build.2030`

| Asset/gate | Result | Evidence |
|---|---|---|
| Release/tag | passed | immutable، non-draft، tag روی commit `1b8468b`؛ `gh release verify` attestation را تأیید کرد |
| Exact asset set | passed | فقط `Perfect-1.1.0-build.2030-Android.apk`، `Perfect-1.1.0-build.2030-Windows-Setup.exe` و `Perfect-1.1.0-build.2030-Windows-Portable.zip` |
| Android | passed | `com.k1tvkli2003.perfect`، label `Perfect!`، `1.1.0+2030`، سه ABI، امضای v2 و signer `144E87CB…B0AF` |
| Windows Setup | passed | `Perfect!`، version `1.1.0.30`، signer `1424F286…BA24` و DigiCert timestamp؛ روی runner تمیز نصب و rerun شد |
| Windows portable | passed | 41 entry/37 file، `perfect.exe` و runtime کامل؛ صفر MSIX/CER/checksum/log/ZIP تو‌در‌تو |
| Downloaded bytes | passed | هر سه SHA-256 محلی دقیقاً با digestهای GitHub و Release notes برابر بود |
| Portable signing recovery | passed | synthetic JKS/PFX round-trip؛ private-key possession، wrong password/tamper/non-empty rejection، DACL rollback and no real signing-root access |
| Focused AI contracts | passed | 33 tests؛ history hydration، proposal recovery، bounded context and client behavior |
| Edge source type-check | passed | Deno check |
| Final Edge deployment | passed live | `perfect-agent` v3؛ `ACTIVE`؛ `verify_jwt=true`؛ hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b`؛ unauthenticated 401 |
| Final signed Android build/install-over | passed | APK `1.1.0+2004`؛ cert `144E87CB…F49B0AF`؛ install-over preserved package UID/data/widget identity |
| Final exact-SHA CI/artifacts | passed | run `#22` on `fea3ddc`؛ Android `1.1.0+2022`، MSIX `1.1.0.22` and portable Windows independently inspected |
| Windows signer migration | passed | provisioner synthetic PASS؛ legacy self-signed `CA=true` signer replaced by a self-signed `CA=false` end entity، thumbprint `1424F286C0DCACF36701D4C1AF0C0D830F01BA24`؛ rerun identity stable |
| True Windows install-over | passed | run `#21`: `1.1.0.20 → 1.1.0.21`؛ package family and exact LocalState marker preserved |

## Latest live AI/backend proof

| Check | Result | Evidence |
|---|---|---|
| AI metadata hardening migration | passed live | migration `20260730210000` در `schema_migrations` ثبت شد؛ safe metadata=true، `api_key`=false، depth 34=false |
| Metadata guard privilege boundary | passed live | `anon` و `authenticated` برای `perfect_ai_metadata_is_safe(jsonb)` فاقد EXECUTE هستند |
| Edge Function deployment | passed live | `perfect-agent` v3، status `ACTIVE`، `verify_jwt=true`، bundle hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b` |
| Edge authentication boundary | passed live | POST بدون Authorization به Function زنده پاسخ 401 با `UNAUTHORIZED_NO_AUTH_HEADER` گرفت |
| Focused AI/migration contracts | passed | 15/15 Flutter contracts؛ Deno check و backend guard suite نیز سبز |
| Provider smoke | blocked safely | کلید AvalAI قبلی compromised فرض می‌شود و در Supabase تنظیم نشده؛ تا rotate شدن، هیچ درخواست provider با آن اجرا نمی‌شود |
| Private planner context migration | passed live | `20260730220000` recorded؛ authenticated execute، anon denial، direct planner SELECT denial، owner result and bounded limit pass |

## Latest tablet composition proof

| Check | Result | Evidence |
|---|---|---|
| Tablet compact portrait | passed + visually inspected | `test/goldens/perfect_tablet_rail_compact.png` |
| Tablet expanded portrait | passed + visually inspected | `test/goldens/perfect_tablet_rail_expanded.png` |
| Tablet short landscape | passed + visually inspected | `test/goldens/perfect_tablet_landscape.png` at `1200×800` |
| Responsive reflow | passed | 768 stack؛ 900/1024 two-pane؛ 200% text stack؛ rail animation/persistence؛ AI/capture no-overlap |

## Requirement-by-requirement completion audit

| ID | Requirement | Authoritative evidence inspected | Outcome |
|---|---|---|---|
| R1 | Flutter Android + Windows | Android install/runtime ledger؛ exact-HEAD run `#22`؛ final artifacts؛ live portable auth resize | **partial runtime / artifact pass** — signed builds، install-over and Windows auth wide/short/compact resize/scroll/title/icon pass؛ signed-in workspace، hover/jank and Android main workspace remain unobserved |
| R2 | private local-first cross-device Supabase sync | 265 tests؛ eight migrations remote/local؛ live owner/RLS/RPC/Auth/replay/cursor/context smoke | **partial** — backend و local-first/retry contracts پاس‌اند؛ convergence واقعی Android↔Windows روی دو نصب اجرا نشده است |
| R3 | planner options and hostile scenarios | 265-test suite، workspace interaction suite، Android task/habit/widget journeys | **passed for implemented source/test scope** — exact alarm/reboot/OEM behavior و همهٔ device-specific notification paths هنوز proof فیزیکی ندارند |
| R4 | final Perfect identity across app/Android/Windows | Day Compass source/master؛ Pixel Launcher؛ hosted identity؛ final portable title bar | **passed for assets/artifacts؛ partial shell runtime** — Android launcher and Windows title-bar icon pass؛ Explorer/taskbar remain unobserved |
| R5 | deliberate portrait/landscape/expanded experience | Workspace tests/goldens؛ Android screenshots؛ live Windows auth resize | **partial runtime** — final auth surface passes restored/maximized، `832×414` and `540×414` with scrolling؛ signed-in main workspace، hover and jank remain unobserved |
| R6 | precise plan and durable work record | task docs، requirement/preservation ledgers، CI/artifact evidence in this file | **current** — runs `#20`–`#22`، signer migration، artifact identities، install-over، auth GUI and remaining runtime limits recorded |
| R7 | preserve data/auth/contracts | additive migration history/replay؛ legacy compatibility tests؛ owner gate and anon denial | **passed for compatibility contract** — هیچ destructive migration گزارش نشده؛ two-install convergence جداگانه در R2 باز است |
| R8 | quality, resilience and performance gate | analyzer، 265 tests، exact-HEAD run `#22`، artifact inspection، live auth resize، Critics closure | **partial whole-product runtime proof** — automated/artifact/auth-resize gates سبزند؛ signed-in cross-device، hover/jank and physical Android/OEM proof بازند |

## Automated checks

| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Format | `dart format lib test` | passed | ۱۲۳ فایل؛ پس از آخرین اصلاح فقط یک فایل test format شد |
| Static analysis | `flutter analyze --no-pub` | passed | `No issues found` |
| Full test suite | `flutter test --no-pub --reporter compact` | passed | ۲۶۵ تست؛ domain/data/sync/UI/editor/accessibility/golden/widget/privacy/recovery/reminder/AI/startup/signing/release concurrency |
| Workspace interaction suite | `flutter test --no-pub test/presentation/perfect_workspace_page_test.dart` | passed | ۴۴ تست؛ phone/tablet/Windows، 200% text، RTL، short landscape، wide inspector، shortcut/context |
| Private release contract | focused Flutter test | passed | ۷/۷؛ semantic/epoch/run mapping، signer migration and install-over guards |
| Workflow queue lint boundary | actionlint 1.7.12 with scoped filter + GitHub service | passed | only exact old-actionlint `concurrency.queue` diagnostic is scoped؛ GitHub accepted and executed the workflow on run `#20` |
| Focused AI suite | focused Flutter tests | passed | ۳۳ pass؛ history/context/proposal/client behavior |
| Edge source check | `deno check supabase/functions/perfect-agent/index.ts` | passed | no type errors |
| Adaptive secondary surfaces | `flutter test --no-pub -r expanded test/presentation/planner_secondary_surfaces_adaptive_test.dart` | passed | dialog ویندوز و bottom sheet موبایل، Escape و lifecycle |
| Android release compile | `flutter build apk --release --no-pub` | passed | APK نهایی 63.9MB؛ Gradle `assembleRelease` موفق؛ build محلی عمداً secret خصوصی ندارد |
| Dependency currency | `flutter pub outdated --no-dev-dependencies` | passed with caveat | تمام dependencyهای مستقیم up-to-date؛ چند transitive نسخهٔ جدیدتر ولی غیرقابل resolve با graph فعلی |
| Diff hygiene | `git diff --check` | passed | فقط هشدار line-ending ویندوز؛ whitespace error ندارد |

## Hosted CI and artifact proof

| Check | Method | Result | Evidence |
|---|---|---|---|
| Exact hosted revision | Actions metadata | passed | run `30641054596` (`#22`) روی SHA `fea3ddc7dd16741e1936a5b61de0b4785c079e67` است |
| Overall private workflow | GitHub Actions run API | passed | workflow `Perfect private CI` با conclusion `success`؛ Allocate، Quality/Android و Windows هر سه success |
| Quality and Android job | Actions job `91190822424` | passed | format، analyze، 265/265 tests، Android signing/build/verification/upload همگی success |
| Hosted Android artifact | Actions artifact + independent package inspection | passed | `perfect-1.1.0-build.2022-android-stable-private-configured-private`؛ `1.1.0+2022`، package `com.k1tvkli2003.perfect`، label `Perfect!`، سه ABI، v2، SHA manifest معتبر، signer ثابت `144E87CB…F49B0AF` |
| Windows desktop job | Actions job `91190822447` | passed | Windows goldens، desktop build، portable/MSIX upload and `1.1.0.21 → 1.1.0.22` install-over success |
| Hosted Windows portable | run `#22` download + 37-file manifest + Computer Use | passed with signed-in limit | 37/37 hashes؛ correct Perfect! title/icon؛ restored/maximized and live `832×414`/`540×414` resize؛ short-height scroll kept every auth action reachable. Signed-in workspace، hover/jank not exercised |
| Signed private MSIX | artifact download + manifest/CMS/block inventory | passed | run `#22` version `1.1.0.22`، same identity/publisher، `CA=false` signer `1424F286…BA24`، 137 entries and hashes valid |
| Signing provision/recovery | synthetic provisioner + backup/hash + rerun | passed | Windows root/leaf roles valid، end-entity private-key proof passes، backup hash valid and rerun leaves both Android and Windows identities stable |
| Windows install-over | run `#22` job `91190822447` | passed | exact notice: `MSIX install-over passed: 1.1.0.21 -> 1.1.0.22; package family and LocalState were preserved.` |
| Run `#22` artifact integrity | independent artifact download | passed | Android `1.1.0+2022`، MSIX `1.1.0.22` with same `CA=false` signer and 137 entries، portable 37/37؛ all SHA manifests have zero mismatch |

## Final private Android artifact and runtime

| Check | Method | Result | Evidence |
|---|---|---|---|
| Artifact identity | `aapt2 dump badging` | passed | `Perfect!` / `com.k1tvkli2003.perfect` / `1.1.0+2004`؛ minSdk 24، targetSdk 36 |
| Artifact integrity | SHA-256 + file length | passed | `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`؛ ۶۹٬۱۸۹٬۳۵۶ bytes |
| ABI coverage | APK badging/native inventory | passed | `arm64-v8a`، `armeabi-v7a` و `x86_64` |
| Alignment/signature | `zipalign -c` + `apksigner verify --verbose --print-certs` | passed | zipalign صحیح؛ APK Signature Scheme v2؛ cert SHA-256 `144E87CB67A9074EBC11CFED26A96EE1ACE697A861C2EABD77C4203A4F49B0AF` |
| Install-over continuity | `adb install -r` over `1003`, then over `2004` | passed | UID `10213`، `firstInstallTime=2026-07-30 20:02:10` و `/data/user/0/com.k1tvkli2003.perfect` ثابت ماندند |
| Widget upgrade/reboot continuity | launcher + `dumpsys appwidget` | passed | binding `appWidgetId=5` پس از update و reboot باقی ماند؛ Quick Add popup و signed-out guard درست‌اند |
| Authenticated session continuity | pre/post session state | not proven | نصب پیش از آزمون signed out بود؛ حفظ session لاگین ادعا نمی‌شود |
| Runtime/splash/logcat | API 35 x86_64 emulator screenshots + logcat | passed with performance caveat | splash بومی Day Compass و app runtime صحیح؛ crash/`AndroidRuntime`/`E/flutter` نبود |
| Cold-start timing | repeated `am start -W` / trace | inconclusive for supported hardware | روی emulator 2GB/SwiftShader حدود ۵٫۱–۶٫۵ ثانیه و پس از reboot پرنویز حدود ۱۱–۱۲ ثانیه؛ engine/plugin/software-render path غالب است و گوشی فیزیکی لازم است |

## Historical Android artifact and runtime

| Check | Method | Result | Evidence |
|---|---|---|---|
| Package identity | `aapt2 dump badging` | passed | package `com.k1tvkli2003.perfect`، label `Perfect!`، minSdk 24، targetSdk 36 |
| Signature structure | `apksigner verify --verbose --print-certs` | passed with local-signing caveat | APK با v2 معتبر است؛ چون secret خصوصی تزریق نشده، local release با Android Debug certificate امضا شده است |
| Install/cold start | `adb install -r` + `am start -W` on `emulator-5554` API 35 | passed | cold launch موفق؛ `MainActivity` focused؛ crash یا `E/flutter` در logcat نبود |
| Release state | `dumpsys package` after reinstall | passed | `pkgFlags` فاقد `DEBUGGABLE`؛ نسخه `1.0.0+1` |
| Portrait/landscape | چرخش host و screenshot | passed | configuration surface بدون overlap؛ محتوای landscape با swipe تا انتها قابل دسترسی |
| Final launcher identity | Pixel Launcher API 35 پس از uninstall/reinstall | passed | نام `Perfect!` و Day Compass با شش ماژول پاستلی و مرکز تیره، در adaptive tile آرام `#FFF3E8` درست و خوانا نمایش داده شدند؛ control شفاف روی Pixel Launcher فضای خالی را مشکی می‌کرد، بنابراین fill فقط برای adaptive platform mask عمدی است |
| Preconfigured connection | fresh app data + cold start | passed | build مستقیم روی AuthPage پروژهٔ خصوصی باز شد و ConfigurationPage را نشان نداد |
| Widget discovery | Pixel Launcher widget picker | passed | `Perfect! Today` با توضیح private/resizable و اندازهٔ اولیهٔ 2×2 |
| Widget resize classes | host resize small → tall → wide → large | passed | چهار family دقیق با UI متفاوت؛ `110×110`، `110×180`، `220×110` و `260×220`؛ large اکشن `Open Today` را اضافه می‌کند |
| Widget collection scrolling | ۱۲ ردیف runtime و ۸۰ ردیف contract test | passed | `ListView` بومی در هر چهار family اسکرول می‌شود؛ عنوان‌های بلند و فارسی/RTL تست شده‌اند |
| Widget direct four-state cycle | چهار tap روی `Workout` | passed | semantics واقعی: `Empty → Done → Not done → 50% → Empty` |
| Widget durable queue | بازرسی SharedPreferences همان harness | passed | چهار action با `queue_sequence`های ۱ تا ۴ و state/percent متناظر ثبت شدند |
| Widget deep link | tap روی `Open Today` | passed | `Perfect/.MainActivity` foreground شد؛ crash نداشت |
| Cleanup | حذف fixture و نصب مجدد release | passed | دادهٔ مصنوعی widget پاک شد؛ release غیر-debuggable وضعیت نهایی emulator است |
| Private backup boundary | manifest/rules + installed `pkgFlags` | passed | cloud و device-transfer برای database/shared preferences/files بسته‌اند؛ `ALLOW_BACKUP` در package نصب‌شده وجود ندارد |

## Visual evidence

- `assets/perfect-runtime-portrait.png`
- `assets/perfect-runtime-landscape.png`
- `assets/perfect-runtime-landscape-scrolled.png`
- `assets/perfect-day-compass-app-drawer.png`
- `assets/perfect-auth-configured-final.png`
- `assets/perfect-widget-picker.png`
- `assets/perfect-widget-home-2x2.png`
- `assets/perfect-widget-home-resized.png`
- `assets/perfect-widget-populated3.png`
- `assets/perfect-widget-scrolled-end.png`
- `assets/perfect-widget-cycle-partial.png`
- `build/private-update-proof/perfect-native-splash-2004.png`
- `build/private-update-proof/perfect-final-runtime-2004.png`
- `build/private-update-proof/perfect-widget-host-attempt2.png`
- `build/private-update-proof/perfect-quick-add-dialog.png`
- `build/private-update-proof/perfect-widget-after-reboot-proof.png`
- `test/goldens/perfect_compact.png`
- `test/goldens/perfect_expanded.png`

شواهد launcher قدیمی `assets/perfect-launcher-icon.png` و
`assets/perfect-launcher-pastel-final.png` فقط در تاریخ تصمیم نگه‌داری می‌شوند
و evidence هویت نهایی Day Compass نیستند.

## Defects caught and closed during the final gate

- دو use-after-dispose در percentage editor و Habit checklist editor؛ controllerها به lifecycle سطح منتقل یا حذف شدند.
- `Archive` و `Insights` از callbackای در `setState` استفاده می‌کردند که `Future` برمی‌گرداند؛ init/reload اکنون synchronous state assignment دارند.
- shortcut فوکوس ویندوز پس از modal و هنگام فوکوس quick capture پایدار شد.
- تست right-click آیتم recurring، آیتم Scheduled را اشتباهاً در Inbox جست‌وجو می‌کرد؛ مسیر واقعی فیلتر و اسکرول تست شد.
- Orbit در قاب کوتاه/متن 200٪، wordmark در RTL، touch targetهای 48dp، contrast و reduced-motion سخت‌گیری شدند.
- AuthPage برای Supabase project معتبر از نظر قالب اما اشتباه، مسیر امن تغییر اتصال دارد؛ client قبلی dispose می‌شود و pair جدید به‌صورت یک مقدار atomic و device override پایدار ذخیره می‌شود.
- خاموش‌کردن reminder همهٔ notification IDهای قبلی را cancel می‌کند؛ شکست cancel برای retry نگه‌داری و در UI اعلام می‌شود.
- سقف ۹۶ reminder دیگر silent نیست: نزدیک‌ترین موارد با ترتیب deterministic انتخاب و تعداد باقی‌مانده همراه capacity در UI گزارش می‌شود.
- صف native ویجت eviction خاموش ندارد؛ stateهای مطلق هر owner/entity/day compact، actionهای اعمال‌شده با ack side-channel پاک و overflow قبل از تغییر snapshot رد و ثبت می‌شود.
- هشت PNG موقت failure-golden پیش از stage به‌صورت دقیق پاک شدند.
- Day Compass انتخاب نهایی شد. pipeline تکرارپذیر `tool/generate_day_compass_assets.py` chroma/spill را حذف، edgeهای premultiplied را پاک، master شفاف ۵۱۲×۵۱۲، monochrome، Android derivatives و Windows ICO با ۹ اندازه تولید می‌کند. master هفت component مستقل، گوشه‌های کاملاً شفاف و alpha bounds برابر `(43, 8, 468, 504)` دارد.
- Android adaptive icon نمی‌تواند در فاصله‌های mark واقعاً شفاف بماند؛ control شفاف در Pixel Launcher آن فاصله‌ها را مشکی کرد. fill پاستلی `#FFF3E8` فقط در adaptive tile استفاده شد؛ master، legacy PNG و Windows ICO شفاف باقی ماندند.
- replay ویجت دیگر برای ترتیب به wall clock وابسته نیست: `queue_sequence` یکنواخت native منبع اصلی است و rollback ساعت/malformed action/DB replay با تست پوشش دارد.
- اجرای هم‌زمان foreground و WorkManager نیز دیگر race ندارد: Drift schema v2 یک ساعت ترتیب local-only نگه می‌دارد و claim اتمیک SQLite پیش از هر mutation انجام می‌شود. تست با دو `NativeDatabase.createInBackground` روی یک فایل، sequence بالاتر را برای one-off و recurring حتی با ساعت عقب‌رفته و mutation ID تازه حفظ می‌کند؛ migration v1→v2 نیز دادهٔ قبلی را نگه می‌دارد.
- Windows window restore اکنون DPI/work-area/multi-monitor-aware است، minimum به `520×420` کاهش یافته، manifest روی PerMonitorV2 است و artifact portable باید VC runtime DLLها و `SHA256SUMS` را داشته باشد.

## Explicit limits

- build محلی Windows ممکن نیست چون این میزبان Visual Studio و workload «Desktop development with C++» ندارد. hosted CI portable/MSIX را ساخته و portable نهایی دانلودشده در GUI واقعی با title/icon، maximize/restore، resizeهای wide/short/compact و scroll بررسی شده است؛ signed-in workspace، hover/focus semantics، animation continuity and jank هنوز بررسی نشده‌اند.
- پروژهٔ `evyjrbwibwrdkjakooor` سالم است و هشت migration هم‌نسخهٔ local/remote را پذیرفته است. migration هشتم `20260730220000` authenticated execution و owner/limit bounding را پاس می‌کند؛ anon و direct planner SELECT همچنان بسته‌اند. شواهد replay/cursor/zero-residue مربوط به چهار migration پایه نیز معتبر باقی مانده‌اند. تنها convergence واقعی Android↔Windows هنوز اثبات نشده است.
- تست Android روی emulator API 35 انجام شد، نه گوشی فیزیکی؛ زمان startup به‌دلیل x86_64/2GB/SwiftShader و ANRهای سیستم نمایندهٔ سخت‌افزار هدف نیست و بهبود عملکرد ادعا نمی‌شود.
- APK نهایی `1.1.0+2004` با private certificate نهایی امضا شده است؛ سطر debug-certificate در بخش Historical فقط به artifact قدیمی اشاره دارد.
- signed MSIX `1.1.0.20` در run `#20` baseline معتبر است؛ run `#21` همان lineage را به `1.1.0.21` ارتقا داد و package family/LocalState را حفظ کرد.
- Day Compass نهایی در Android launcher و Windows title-bar runtime اثبات شده است. Windows ICO به‌صورت ساختاری ۹-frame و شفاف است؛ Explorer/taskbar rendering هنوز مشاهده نشده است.
- Flutter 3.44 دربارهٔ مهاجرت آیندهٔ Kotlin plugin در `home_widget` و `flutter_timezone` هشدار می‌دهد. هر دو dependency مستقیم در آخرین نسخهٔ قابل resolve هستند؛ این هشدار شکست فعلی نیست و مالکیت fix در upstream است.
- تصاویر Android موجود، launcher/widget و Auth/Configuration را اثبات می‌کنند؛ signed-in Orbit Day main workspace روی phone/tablet runtime نشده است.
- signed-in widget Quick Add، authenticated session retention، Android↔Windows convergence، positive AI text/voice/proposal-apply با provider key rotateشده و physical notification/OEM/reboot هنوز اجرا نشده‌اند.
- Supabase Auth API ورود حساب خصوصی را با credential جدید و همان UUID موجود در `planner_owner_profiles` تأیید کرده است؛ این اثبات API جایگزین اجرای UI نسخهٔ ریلیز بعدی روی Android/Windows نیست.

## 2026-08-05 Home / Day Compass modernization gate

| Check | Method | Result | Evidence / limit |
|---|---|---|---|
| Static analysis | `flutter analyze` | passed | `No issues found` after the final Day Compass and compact dock composition |
| Full Flutter suite | `flutter test` | passed | 352/352 tests across data، sync، AI، feedback، editor، responsive workspace، branding، accessibility and release contracts |
| Responsive Home suite | `flutter test test/presentation/perfect_workspace_page_test.dart` | passed | 51/51 including phone/tablet/Windows، intermediate resize، short landscape، RTL، 200% text، final-row scroll reachability and goldens |
| Day Compass panel contract | bounds + goldens | passed | circular Orbit is the primary tablet/Windows instrument; duplicate `Today’s runway` was removed and the dial stays adjacent to Day Stream without overlap |
| Compact composer continuity | widget bounds + Android screenshot | passed | collapsed Quick Capture reserves a transparent slot above the glass footer; it has no background rail and no longer overlays Today rows |
| Sync Cloud contract | focused tests + Android screenshot | passed | `Synced` green، `Syncing/Retrying` yellow and `Sync issue` red use distinct cloud icons، visible concise labels، semantics and a 48dp target |
| Secret-free Android runtime | `lib/dev/perfect_live_preview.dart` on `Codex_API35` / `emulator-5556` | passed | debug APK installed، cold launch completed in 4269ms، no `FATAL EXCEPTION`، `AndroidRuntime` or `E/flutter`; screenshot: `screenshots/perfect-live-preview-latest.png` |
| API 37 emulator attempt | `Gauss_QA_API37` | environment failure, replaced | system `mapper.ranchu`/`system_server` crashed while Gradle had already built the APK; the same APK installed and ran on API 35 with SwiftShader. This is not counted as app runtime proof for API 37. |

The live preview is deterministic local development evidence, not a signed private
release and not authenticated cross-device convergence proof. Release signing،
session retention and owner Supabase convergence remain separate gates.

## 2026-08-06 Cycle 3 — compact footer and capture instrument

| Check | Method | Result | Evidence / limit |
|---|---|---|---|
| Static analysis | `flutter analyze` | passed | `No issues found` after footer, Orbit, percentage and capture edits |
| Full Flutter suite | `flutter test` | passed | 358/358 |
| Workspace responsive suite | `flutter test test/presentation/perfect_workspace_page_test.dart --update-goldens` | passed | 55/55 across phone/tablet/Windows, RTL, 200% text, short height and all golden layouts |
| AI Dock focused suite | `flutter test test/ai/perfect_ai_dock_test.dart` | passed | 21/21; review-before-apply, voice, retry, resize and reduced motion retained |
| Pictogram contract | `flutter test test/presentation/no_raw_ui_emoji_contract_test.dart` | passed | 3/3; AI/Voice SVGs remain scalable, transparent and text-free; no raw keyboard emoji |
| Footer contract | widget geometry + compact goldens | passed | labels are always hidden, stock indicator is transparent, exactly one 48dp prismatic selected tile moves with destination and semantic labels remain |
| Quick Capture behavior | widget tests + Android runtime | passed | toggle does not focus the field; Plan/Perfect AI/Voice are equal 48dp+ actions; final Today row scrolls above collapsed and expanded composer |
| Percentage ring safe area | 200% widget geometry + Android screenshot | passed | 43dp inner core with 7dp horizontal padding keeps `0%`/`60%` copy away from the 4.5dp ring |
| Orbit clocks | compact/tablet/Windows goldens + Android screenshot | passed for geometry | 6 AM/PM share one symmetric anchor and no longer fight canvas edges; full authored joint/fidelity closure remains tracked under C11 |
| Android open/close stability | `Codex_API35`, API 35, `-gpu host`, secret-free preview | passed | ADB `device`, QEMU `Responding=True`, working set stayed about 3.1GB after four open/close cycles; screenshots `.codex-tmp/critics-cycle1/android-home-cycle3-host-before.png` and `android-home-cycle3-host-expanded.png` |
| Legacy renderer comparison | `-gpu swiftshader_indirect` | rejected as environment proof | current Emulator help no longer lists this deprecated mode; AVD exited independently, so it is not used to claim an app failure or success |
| Release | exact-SHA hosted workflow | pending | source is locally green; commit/push/three-asset immutable release follows this documentation checkpoint |

## 2026-08-06 — canonical plan-structure verification

This checkpoint verifies documentation structure only. It does not validate the
uncommitted Flutter prototypes, a device runtime or a release artifact.

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Exact stage count | numbered-file enumeration `^\d{2}-.*\.md$` | passed | 50 files; sequence 01–50; zero missing and zero duplicate numbers |
| Canonical local links | Markdown target resolution across master, README, ledgers and 50 stage files | passed | 54 files checked; zero broken local links |
| Stage structure | required Mission and Reject headings | passed | zero structural issues across all 50 stage files |
| Preview-before-code coverage | scan Stages 06–50 for Preview and Copy contracts | passed | 45/45 runtime stages contain both gates |
| Autonomous design authority | stale owner-approval phrase scan | passed | zero remaining design dependencies on owner voting; in-product destructive/AI Apply consent remains intentionally separate |
| Formatting hygiene | `git diff --check` scoped to master/stages | passed | no whitespace errors |
| Platform scope | canonical plan scan | passed | Android phone/tablet and Windows only; Web appears only in Stage 01 as explicitly out of scope |
| Secret hygiene | literal credential scan | passed | no private password/API value in the 50-stage plan; server-only provider and safe auth boundaries remain explicit |

### Explicit limits

- Stage 03 direction plates/manifests now exist and are frozen. Exhaustive Stage 04
  component previews and Stage 05 complete page/overlay/widget compositions do not;
  their absence still keeps Stage 06 blocked exactly as intended.
- Existing `perfect_workspace_page.dart`, its test changes and
  `perfect_date_format.dart` are unaccepted prototypes. No analyze/test/device/release
  claim is made for them in this checkpoint.
- Old Cycle 3 Orbit evidence remains historical only and cannot supersede the new
  Stage 11 removal decision or manufacture a current Preview/Copy acceptance.

## 2026-08-09 — Stage 01 preservation verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Production fixture isolation | static entrypoint/package contract | passed | seed exists only under `lib/dev`; Android debug uses `.preview`; production `main.dart` imports neither |
| Sign-out safety | static call-order + forbidden durable API scan | passed | widget projection clears before Supabase sign-out; no DB/store/preferences global clear/delete/reset path |
| Session-scope persistence | file-backed Drift close/reopen | passed | Task, Habit, completed occurrence, owner isolation and 3/3 pending mutations preserved |
| Preference canaries | SharedPreferences lifecycle fixture | passed | theme, rail state and session canary unchanged across controller disposal/reopen |
| Interrupted migration recovery | injected failure after v2 DDL then normal reopen | passed | migration transaction rolled back; original entity/outbox recovered and v2 opened normally |
| Artifact secret scanner | safe and leaking dummy binaries | passed | safe payload accepted; exact leak rejected; output contains only env label, never protected value |
| Focused cross-contract suite | ten preservation/config/migration/AI/signing/release/Windows files | passed | final expanded gate 59/59 |
| Static analysis | focused Flutter analyzer | passed | no issues in preservation gate |
| Workflow YAML | PyYAML safe load | passed | `.github/workflows/verify.yml` parses |
| Android shell | extracted build step + `bash -n` | passed | heredoc/temp-file/trap/scanner block is syntactically valid |
| Windows shell | extracted build/package steps + `ScriptBlock.Create` | passed | both modified PowerShell blocks parse |
| Prior Windows install-over | hosted run `31059011394` log | passed, historical baseline | `1.1.0.37 → 1.1.0.38`, package family + LocalState preserved; Setup proof passed |
| Current exact-SHA signed artifacts | hosted workflow after Stage 01 push | pending | no local check can substitute for signed GitHub artifacts and release |

The local fixture is strong code/storage evidence, but it does not prove a signed-in
physical Android session, real signed-in Windows upgrade, OEM widget behavior or
Android↔Windows convergence. Those remain milestone runtime gates.

### Stage 01 hosted follow-up

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Exact Stage 01 SHA | hosted run `#39` / `31331588125` | inspected | `e0840c1f34de37fb78af4101be0ef684f6800256` |
| Quality and Android | hosted job `93290608499` | passed | format, analyze, full tests, trusted APK build, package verification and upload all succeeded |
| Windows desktop build | hosted job `93290608519` | failed after successful build/signing | final MSIX and Setup signatures were created; the new secret scan referenced the pre-rename `Perfect-private.msix` path, so upload/install-over/release correctly stayed blocked |
| Final-path regression | local focused suite after `eaad6b2` | passed, 18/18 | scan now receives `$package.FullName`; test rejects `$packages[0].FullName` after rename |
| Replacement hosted gate | run `#40` / `31332512462` | passed | exact SHA `eaad6b21bb136712e5ac51d10d6b6e2bf254e5f0`; all jobs completed successfully |
| Stage 01 release | `v1.1.0-build.2040` | passed | targets exact fix SHA and contains exactly Android APK, Windows Portable ZIP and Windows Setup |

## 2026-08-09 — Stage 02 interaction/route verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Complete surface inventory | source walk across Flutter, Android native, Windows package/notifications, AI and sync | passed locally | evidence lists trigger, destination, mutation and risk for every discovered entrypoint |
| Required diagrams | static contract over Stage 02 evidence | passed | application route tree, entity lifecycle, local-first mutation, AI proposal and widget action sequences present |
| Ten core jobs | static contract and manual source trace | passed | current costs plus explicit target budgets recorded for jobs 1–10 |
| Stable findings/owners | static contract | passed | `IR-001`–`IR-015` each have severity, consequence and numbered-stage owner |
| Cross-layer behavior | `interaction_route_inventory_contract_test.dart` | passed, 7/7 | full ledger classification, native ingress, local-first ordering, sync convergence order, AI confirmation and widget replay checked |
| Related integration contracts | focused widget/reminder/sync/AI suite | passed, 74/74 | native scrolling/actions, durable replay, reminders, retry/conflict and proposal review remained green |
| Static analysis | focused Flutter analyzer | passed | no issue in the new Stage 02 test |
| Coverage propagation | 27-row classification | passed locally | every shared product-system row is changed/checked with evidence or a specific reason |
| Runtime visual/release proof | not applicable to documentation-only Stage 02 | not claimed | Stage 03–05 preview gates and later runtime stages remain mandatory |
| Stage 02 exact-SHA hosted gate | run `#41` / `31333024152` | passed | exact SHA `b7c7279791da0dd6104f0043cb5d40f5380e27a7`; all jobs completed successfully |
| Stage 02 release | `v1.1.0-build.2041` | passed | targets exact Stage 02 SHA and contains exactly Android APK, Windows Portable ZIP and Windows Setup |

## 2026-08-10 — Stage 03 design-evidence verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Current baseline freeze | file count, dimensions and SHA-256 manifest | passed | 9 Flutter goldens + 5 prior Android runtime + 6 Android widget + 14 fresh current-route captures; uncropped comparison sheet and known route/state gaps explicitly frozen |
| HabitNow evidence | exact-copy/hash and screenshot-inventory contracts | passed | exactly 25 owner screenshots copied byte-for-byte, classified by surface and converted to dependency/recovery/logging rules; uncropped five-by-five contact sheet inspected |
| Research breadth | URL/evidence contract | passed | HabitNow plus TickTick, Todoist, Structured, Sunsama, Akiflow, Amazing Marvin, Android primary guidance, Windows primary guidance and Dribbble decomposition |
| Generative breadth | heading/ID contract | passed | exactly 24 unique `R01`–`R24` mental-model recipes; radical/calm/Windows-first/one-handed sets present |
| Whole-product Integrity | five-way ledger contract | passed | `KEEP/REFINE/REDESIGN/REMOVE/ADD` and every identity-to-release surface family are explicit; no silent rows |
| Finalist honesty | file/manifest/contact-sheet contract + original-size visual inspection | passed | 4 normal + 4 stress model-native boards retained; side-by-side sheet inspected; all 8 rejected as canonical where text/identity/composition drifted |
| Selected direction | second weighted score + frozen decision | passed | `PS01 Perfect Day Instrument` won at 98.4/100 with bounded F2/F3/F4/R09/R11/R21 imports and explicit supersession rule |
| Deterministic plates | SVG/PNG manifest + original-size inspection | passed | identity, shell, workflow, state, motion and typography sources/renders frozen with exact hashes |
| Identity integrity | byte-for-byte file comparison | passed | selected Day Compass and both wordmark copies equal canonical production brand assets |
| Text integrity | single-render source inspection | passed | no post-render text repair; Persian/mixed bidi and 200% examples use explicit native XHTML layout inside deterministic SVG |
| Fixture isolation | production persistence-source scan | passed | finalist entity names absent from planner database/local store and Supabase migrations |
| Executable contract | `flutter test test/presentation/design_direction_contract_test.dart` | passed, 8/8 | evidence files/contact sheets, research, ledger, board rejection, PS01, exact assets, deterministic plates and fixture isolation locked |
| Runtime/product mutation | scoped Git diff | not claimed / not applicable | Stage 03 adds docs/design/test/tool artifacts only; existing unrelated production/test prototypes remain unstaged |
| Hosted Stage 03 gate | exact-SHA run `#42` / `31393887073` + release inspection | passed | all jobs succeeded for `4ff5ebe317b4f41e7508a69fba2206b68e632d7e`; `v1.1.0-build.2042` targets that SHA and contains exactly uploaded APK, Portable ZIP and Setup assets with SHA-256 digests; transport success is not runtime visual acceptance |

Stage 04/05 remain mandatory. These direction plates are not substitutes for every
component state, page density, dark/high-contrast, 200%, IME, reduced-motion or real
runtime side-by-side Copy proof.

## 2026-08-10 — Stage 04 responsive design-system verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Exact gate inventory | gate parser + registry comparison | passed | exactly 9 foundations, 181 unique component IDs and 27 semantic families in canonical order |
| Complete per-component packet | filesystem/contract traversal | passed | every ID has `contract.yaml`, anatomy SVG and 7 required `1200×800` PNG boards; 1,267 component previews total |
| Foundations and identity | manifest/hash checks + original-size inspection | passed | 9 foundation specimens/stress boards, exact Perfect mark/wordmark provenance and PS01 token equations frozen |
| Iconography | SVG parse/transparency/semantic-title scan | passed | 48 category SVGs, no full-canvas background, Lucide license recorded, no raw keyboard emoji or dingbat UI glyphs |
| Motion system | named registry + five-frame/reduced-motion boards | passed | 20 intent-specific motion contracts map trigger, full motion, reduced motion, duration and easing |
| Visual stress correction | original-size light/dark/high-contrast/responsive/neighbor review | passed | task-row crowding, dark contrast, capture/pulse clipping, raw habit glyphs and widget one-size scaling were corrected before freeze |
| Geometry probe | Playwright live DOM bounds inspector | passed | representative Pulse, Capture, five-frame motion and dark task state boards report contained critical bounds |
| Deterministic integrity | SHA-256 recomputation + stale-file rejection | passed | `stage04-hashes.sha256` exactly covers 1,576 generated files; all 238 SVGs parse; all PNG signatures and dimensions match |
| Corpus transport fitness | file count/size scan | passed | final corpus is 148.18 MiB; largest file 4.49 MiB; no file approaches GitHub's 100 MiB limit |
| Executable design contract | `flutter test test/presentation/responsive_design_system_contract_test.dart` | passed, 8/8 | inventory, IDs/order, contracts, previews, foundations, icons, motion/provenance and fixture isolation locked |
| Cross-stage contract | Stage 03 + Stage 04 focused Flutter tests | passed, 16/16 | selected direction and its full component decomposition remain mutually consistent |
| Focused analysis | `flutter analyze` over Stage 03/04 contract tests | passed | no issues |
| Runtime/product mutation | scoped Git diff | not claimed / not applicable | only docs/design/test/tool artifacts belong to Stage 04; unrelated production prototypes remain unstaged |
| Hosted Stage 04 gate | exact-SHA run `#43` / `31404235491` + release inspection | passed | all four jobs succeeded for `c0a01133a7a4f8e5a7bcbffe2c51bcadbf0ae6f1`; install-over `1.1.0.42 → 1.1.0.43` preserved package family/LocalState; `v1.1.0-build.2043` contains exactly APK, Portable ZIP and Setup |

Stage 04 closes the reusable-component gate only. Stage 05 must still freeze all 134
full page/overlay/widget compositions, densities and Copy manifests before any
production UI implementation can be accepted.

## 2026-08-10 — Stage 05 page-preview and Copy verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Exact page authority | gate Section 5 parser + page registry | passed | exactly 134 unique page IDs in canonical order across 11 families |
| Structural exploration | candidate files/contracts/decision traversal | passed | 3 non-color-only candidates and one explicit winner/rejection/risk record per page; 402 candidate boards total |
| Canonical composition set | Playwright render + PNG/manifest checks | passed | 10 exact phone/tablet/Windows/dark/stress/system/motion previews per page; 1,340 total |
| Live geometry gate | in-browser DOM composition audit | passed | 1,340/1,340 exact root bounds; zero uncontained horizontal overflow, clipped required copy or missing required chrome |
| Component propagation | Stage 04 reverse-consumer ledger | passed | all 181 component IDs have one or more explicit page consumers; zero silent/unconsumed IDs |
| Text integrity | live Copy registry + contract test | passed | exactly 1,072 unique entries, 8 per page, all `live: true`, flattening forbidden and wrapping behavior explicit |
| Fixture isolation | six-fixture registry + production-source scan | passed | all fixtures are production-unreachable; sample entities/catalog version absent from planner persistence and Supabase migrations |
| Copy mismatch proof | three deliberate mutated-runtime comparisons | passed | phone geometry, tablet typography and Windows state defects each name exact page/scenario/category/field and `--fail-on-mismatch` exits 2 |
| Pixel/reference integrity | normalized raw-pixel digest comparison | passed | every smoke reference is pixel-equivalent to its canonical source despite PNG recompression |
| Deterministic integrity | independent verifier + SHA recomputation + scoped LF attributes | passed | `stage05-hashes.sha256` covers all and only 2,055 generated artifacts across Windows/CI checkout semantics; protected Stage 03 handoff remains exact |
| Corpus transport fitness | file count/size scan | passed | 121.16 MiB total; largest file 1.96 MiB; no GitHub 100 MiB risk |
| Executable Stage 05 contract | `flutter test test/presentation/page_preview_quality_harness_contract_test.dart` | passed, 9/9 | counts/order, candidates, canonical audits, consumers, Copy, fixtures, mismatch smokes, exact hash scope and guard tooling locked |
| Prior design chain | Stage 03 + Stage 04 focused Flutter contracts | passed, 25/25 | selected direction and component system remain intact |
| Static analysis | full `flutter analyze` | passed | no issues after removing only the orphan test process created by an earlier command timeout |
| Runtime/product mutation | scoped Git diff | not claimed / not applicable | Stage 05 owns design/tool/test/docs only; existing unrelated production/test prototypes remain unstaged |

This closes design authority, not runtime fidelity. Every Stage 06–50 production
surface still requires matched fixture capture and normalized reference/runtime/
overlay/diff evidence before its own gate can close.

## 2026-08-12 — Stage 07 adaptive navigation shell verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Static analysis | `flutter analyze` | passed | no issues after final platform-explicit tests |
| Full Flutter suite | `flutter test --concurrency=1 --reporter compact` | passed, 404/404 | includes source, persistence, AI, sync, widget, responsive and golden contracts |
| Workspace shell suite | focused `perfect_workspace_page_test.dart` | passed, 60/60 | phone/tablet/Windows, RTL, 200%, short height, state retention, keyboard and every shell golden |
| Android in-place preview | build 2048 + `adb install -r` | passed | versionCode remains 2048; firstInstallTime remains `2026-08-02 19:20:44` |
| Phone 200% runtime | screenshot, semantics and log inspection | passed | `Today’s rhythm` reflows whole; no required phrase clips and no fatal/overflow match |
| Tablet portrait runtime | before/after + scrolled-end inspection | passed | large dead pane removed; Day Stream and final action remain reachable |
| Tablet landscape runtime | logical 1280×800 compact/expanded rail captures | passed | Android defaults compact, expands without overlap and retains useful two-pane weight |
| Capture runtime | UIAutomator + input-method state | passed | capture opens as one surface and `mInputShown=false` until the field is explicitly chosen |
| Windows local compile | not rerun | host limitation | ATL `atlbase.h` remains unavailable locally; Windows interaction/golden contracts pass |
| Trusted exact-SHA build/release | run `#48` / `31549435764` + release inspection | passed | all four jobs succeeded for `004c2567e67efc888f767b39333fb23a4a55bcbb`; Windows install-over preserved LocalState, Setup clean/rerun passed and `v1.1.0-build.2048` contains exactly APK, Portable ZIP and Setup EXE |

Full evidence and honest proof boundaries are recorded in `07-stage-verification.md`.

## 2026-08-12 — Stage 08 glass header, sync and dual date/time verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Static analysis | `flutter analyze` | passed | no issues across the complete project |
| Full Flutter suite | `flutter test --concurrency=1` | passed, 421/421 | includes date boundaries, clock isolation, sync repository/UI, AI, widget, wizard, feedback, responsive and golden contracts |
| Edge Function | `npx --yes deno fmt` + `npx --yes deno check` | passed | validated UTC/local date/clock/offset context; no client provider secret |
| Date vectors | deterministic unit tests | passed | `2024-03-20 → 1403-01-01`, `2026-08-06 → 1405-05-15`, leap Esfand, local midnight and 12 AM/PM |
| Clock locality | widget rebuild counter + injected scheduler | passed | minute boundary is aligned and an unrelated sibling does not rebuild |
| Sync truth | repository + indicator tests | passed | actual bounded retry deadline/attempt, green/yellow/red semantics, reduced motion and safe retry |
| Header visual states | exact light/dark/high-contrast/200% goldens | passed | real Plus Jakarta Sans, Vazirmatn and Material Icons loaded in tests |
| Android in-place preview | versionCode 2049 + `adb install -r -t` | passed | `firstInstallTime` remained `2026-08-02 19:20:44`; no uninstall/reset |
| Phone runtime | light, real app dark, 200% and sync-details captures | passed | foreground package confirmed; required copy whole, controls reachable, no fatal/overflow match |
| Tablet portrait runtime | logical 800×1280 capture + semantics | passed | compact rail, single useful column and bounded header/Compass/stream weight |
| Tablet landscape runtime | logical 1280×800 capture + semantics | passed | adjacent Compass/stream composition, compact rail and no stretch/overlap |
| Windows local compile | not rerun | host limitation | ATL `atlbase.h` remains unavailable locally; Windows header/sync/resize contracts pass |
| Trusted exact-SHA build/release | run `#51` / `31636360008`, attempt 2 + release inspection | passed | all four jobs succeeded for `cc2ff2b15b81486903b425a51d351b2fa809c187`; Windows install-over preserved LocalState, Setup clean/rerun passed and `v1.1.0-build.2051` contains exactly APK, Portable ZIP and Setup EXE |

Full implementation, UTC/local ownership, runtime evidence and proof boundaries are
recorded in `08-stage-verification.md`.

## 2026-08-13 — Stage 09 global motion local verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Static analysis | `flutter analyze` | passed | no issues across the complete project |
| Full Flutter suite | `flutter test --concurrency=1` | passed, 432/432 | complete current regression surface |
| Focused motion | Stage 09 + shared motion contracts | passed, 19/19 | timing, retarget, reduced motion, focus, lifecycle, inventory and profile boundaries |
| Workspace regression | `perfect_workspace_page_test.dart` | passed, 60/60 | responsive, RTL, 200%, keyboard, wizard, detail and status paths |
| Header/Sync regression | focused header + indicator suites | passed, 10/10 | light/dark/high-contrast/200%, retry and reduced motion |
| Deterministic evidence | generator + independent verifier | passed | 11 roles, 131 implementation records, 24 design hashes, nine runtime hashes |
| Android profile/update | build 2060 + `adb install -r` | passed | `firstInstallTime` unchanged; exact preview package foreground |
| Flutter UI thread | two real navigation captures | passed for sampled 60Hz build budget | max build 9.659ms; no sampled build frame above 16.67ms |
| Absolute raster | real navigation + minimal control | inconclusive | minimal same-package control also exceeds 16.67ms on emulator `skiagl` |
| Idle/offstage work | two drained six-second windows | passed | one and zero frames; no sustained ticker |
| Local Windows compile | `flutter build windows --release` | host-blocked | missing ATL `atlbase.h`; exact-SHA hosted runner required |
| Branch exact-SHA gate | run `31663309577`, attempt 2 | passed | exact source `6ca824ef2f0dd0b3facd66c194668381e81b88d1`; 432 tests, APK/checksum/upload and Windows portable passed after one unchanged retry for a transient Gradle download EOF |
| Trusted Windows/update/release | run `#54` / `31664886708` + release inspection | passed | all four jobs succeeded; MSIX `1.1.0.52 → 1.1.0.54` and Setup clean/rerun preserved package family/LocalState; `v1.1.0-build.2054` targets the exact SHA and contains exactly APK, Portable ZIP and Setup EXE |

Full evidence, artifact hashes, performance distributions and proof boundaries are
recorded in `09-stage-verification.md`.

## 2026-08-13 — Stage 10 authored theme and contrast verification

| Check | Method | Result | Evidence / limit |
| --- | --- | --- | --- |
| Static analysis | `flutter analyze --no-pub` | passed | no issues across the complete project |
| Full Flutter suite | `flutter test --concurrency=1` | passed, 444/444 | persistence, AI, sync, themes, workspace, goldens and native contracts |
| Semantic role scan | independent Stage 10 runtime verifier | passed | 57 Dart files; zero reusable raw-color violations |
| Design freeze | independent Stage 10 design verifier | passed | 4 themes, 181 components, 134 pages, 76 measured pairs, 6 boards, 20 hashes |
| Authored assets | brand + Orbit verifiers | passed | 68 declared brand outputs and two Clarity Orbit variants |
| Android native surface | source/assets/layout contract | passed | 4 widget layouts, 40 rasters, 16 status icons, 4 surfaces and Quick Add projection |
| Android in-place preview | build 2062 + `adb install -r` | passed | advanced from 2061; `firstInstallTime=2026-08-02 19:20:44` unchanged |
| Android visual/runtime | screenshot + UIAutomator + hash manifest | passed | Daylight, Graphite, Clarity Light/Dark and live Appearance controls; 13 artifacts |
| Local Windows compile | `flutter build windows --debug` | host-blocked | optional ATL `atlbase.h` missing in `flutter_local_notifications_windows`; project runner was not compiled |
| Branch exact-SHA gate | run `#56` / `31685867478` | passed | exact Stage 10 SHA `8742a676533d3337ed5d69919cd8d612e08c6024` |
| Trusted main build/release | run `#57` / `31687276749` | passed | all four jobs succeeded on the same SHA; Windows native build/sign/package and Android trusted package passed |
| Windows update continuity | hosted MSIX + Setup proof | passed | `1.1.0.55 → 1.1.0.57`, package family/`LocalState` preserved; Setup clean/rerun did not mutate Root |
| Immutable release | GitHub release inspection | passed | `v1.1.0-build.2057` targets the exact SHA and contains exactly APK, Portable ZIP and Setup EXE with recorded SHA-256 digests |

Full local/hosted evidence and the explicit signed/session boundary are recorded in
`10-stage-verification.md`.

## Stage 11 — Today Pulse closure

| Check | Method | Result | Evidence / honest boundary |
| --- | --- | --- | --- |
| Orbit retirement | source/asset/semantics contract | passed | production Orbit source, ring assets, generator and dedicated test removed; regression contract prevents hidden return |
| Static analysis | `flutter analyze --no-pub` | passed | no issues across the complete project |
| Full Flutter suite | `flutter test --concurrency=1` | passed, 449/449 | projection, recurrence truth, Pulse, workspace, themes, native contracts and goldens |
| Stage 11 artifact gate | `node tool/verify_stage11_today_pulse.cjs` | passed | 8 boards, 21 files, 8 semantic states and 9 runtime artifacts |
| Android in-place preview | build 2064 + `adb install -r -t` | passed | advanced from 2063 with original `firstInstallTime` unchanged |
| Android visual/runtime | phone/tablet portrait/landscape/scrolled capture | passed | nine hash-locked PNG/XML/log artifacts; zero relevant fatal, Flutter, overflow or ANR matches |
| Local Windows compile | `flutter build windows --debug` | host-blocked | optional ATL `atlbase.h` absent before project runner linking; hosted runner is authoritative |
| Branch exact-SHA gate | run `#59` / `31766137998` | passed | exact Stage 11 SHA `59db6e479f34f25ecf66e4224b2d8c90c7f53941` |
| Trusted main build/release | run `#60` / `31767013849` | passed | all four jobs succeeded on the same SHA; signed Android and Windows package paths passed |
| Windows update continuity | hosted MSIX + Setup proof | passed | `1.1.0.58 → 1.1.0.60`; package family/`LocalState` preserved; Setup clean/rerun did not mutate Root |
| Immutable release | GitHub release inspection | passed | `v1.1.0-build.2060` targets the exact SHA and contains exactly APK, Portable ZIP and Setup EXE with recorded SHA-256 digests |

Full Stage 11 local, runtime, hosted and artifact evidence plus explicit limits are
recorded in `11-stage-verification.md`.
