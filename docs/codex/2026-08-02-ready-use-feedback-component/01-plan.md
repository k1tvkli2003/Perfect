# Plan

## Approach

Preserve the accepted StudyHUB interaction contract, harden it for a private Flutter Android/Windows app, integrate a target-owned snapshot into Perfect, then keep the generalized and verified source in the personal Components catalog.

## Steps

| Step | Status | Notes |
|---|---|---|
| 1. Freeze the StudyHUB behavior and privacy contract | done | Capture menu, immediate screenshot, note classification, review, delete, clear, and export were inspected. |
| 2. Build and harden the product-neutral Flutter component | done | Atomic indexes, bounded storage/logging, retries, full PNG validation, cleanup recovery, privacy review, and responsive UI are implemented. |
| 3. Integrate into authenticated Perfect scope | done | Owner-scoped storage/preferences, guarded lifecycle, global and handled-error logging, overlay, route attribution, and More settings are wired. |
| 4. Populate Components and create ReadyUse | done | Canonical component v1.2.2 and the structure-valid `ready-use` skill exist at their direct personal-library locations. |
| 5. Verify component and scoped integration | done | Perfect feedback tests pass 56/56 and focused repository tests pass 29/29; full analysis/format/diff checks are clean; independent re-review passes with an explicit location-safety caveat. Canonical v1.2.2 format/analyze and full 56/56 pass; ReadyUse 7/7 and 3/3, 20-file validation, inventory, skill validation, generated-file cleanup, and full lib/test drift audit pass. |
| 6. Verify the whole application and native behavior | active | Perfect full analysis has no issues after the third path hardening; the full non-golden suite passes 319/319 and Windows goldens pass 7/7. A 67.2 MB Android release-mode APK builds locally, but it uses the Android Debug signer. Local Windows build is blocked because Visual Studio is not installed; real native capture/share/save proof remains open. |
| 7. Commit, push, and verify release | active | Run #33 exposed one POSIX symlink-validation defect and one Windows SignTool-output classifier defect. Both are patched with local regressions, but the remediation has not yet been proven by a replacement CI run or release. |

## Interfaces and Artifacts

- Perfect source: `lib/feedback/**`, `lib/main.dart`, `lib/presentation/perfect_workspace_page.dart`.
- Perfect tests: `test/feedback/**`, `test/presentation/perfect_workspace_page_test.dart`.
- Canonical component: `C:/Users/K1/Desktop/Projects/Components/flutter/private-feedback-capture`.
- Component catalog: `C:/Users/K1/Desktop/Projects/Components/catalog.json`.
- Skill: `C:/Users/K1/.codex/skills/ready-use`.

## Risks

- Screenshot pixels can contain private content even when textual metadata and logs are redacted; capture and export review must remain explicit.
- Flutter/native plugin behavior still needs Android and Windows runtime proof.
- Parallel Flutter test/build processes can contend for Windows native-assets files; remaining Flutter checks must run serially.
- Windows native picker/save timing and Android share behavior still require real runtime proof even though bounded and fail-closed source paths have focused test coverage.
- The local Android release-mode APK is verification-only because certificate inspection identifies the Android Debug signer; stable CI signing is still required.
- This workstation cannot produce the Windows build because `flutter doctor` reports Visual Studio is not installed. CI or a host with the required Visual Studio desktop C++ workload must close that gate.
- Filesystem trust checks must probe a final symlink without a trailing separator on POSIX; otherwise `lstat("link/")` can dereference the link and bypass the intended rejection.
- Volume-root detection must be lexical and platform-aware: POSIX `/`, Windows drive roots, and UNC `\\host\share` are stopping boundaries even when repeated separators are normalized. The trusted base must also keep a stable no-follow identity across canonical resolution.
- SignTool writes to both stdout and stderr. After `2>&1`, diagnostic detail can be interleaved, so the private-root policy classifier must require the exact error count and anchored message fragments without assuming adjacency.

## Acceptance Checks

- Perfect formatting and full analysis pass.
- Perfect feedback tests pass 56/56 and focused repository tests pass 29/29 after the third hardening; full analysis reports no issues, the full non-golden suite passes 319/319, and Windows goldens pass 7/7. Focused More integration remains green at its recorded checkpoint.
- The independent verifier reports a source-level eight-contract pass for lease drain/re-entry/timeout, immutable review, managed-path containment, Windows timeout fail-closed cleanup, and logger non-resurrection. This is source evidence, not native runtime proof.
- Clear All removes active storage, screenshots, logs, recovery directories, atomic `.bak`/`.tmp` generations, and all app-owned managed-export artifacts; it rebuilds safe empty indexes, surfaces partial deletion, and preserves the explicit external-ZIP boundary.
- Perfect's latest path-hardening suite passes 29/29 focused repository tests and 56/56 feedback tests, including POSIX/ordinary/extended drive and UNC roots, valid volume-GUID roots, required separator preservation, repeated separators, relative dot segments, unsupported device-namespace rejection, and post-resolution canonical/alias stability.
- Canonical v1.2.2 format/full analysis and full 56/56 tests pass; ReadyUse suites pass 7/7 and 3/3, the validator scans 20 files at v1.2.2, inventory resolves verified-source v1.2.2 for Android/Windows, and skill quick-validation passes.
- The release workflow source regression passes 8/8 and requires both anchored SignTool private-root fragments plus exactly one error; this is source-contract evidence, not a successful hosted release.
- Canonical generated dependency/build metadata is removed after verification, and the full lib/test drift audit reports no behavioral drift beyond the documented namespace/copy, structural barrel-path, and product-neutral state/token adaptations.
- Owner switching cannot share feedback paths or toggle preferences.
- Failed index writes, damaged indexes, orphan screenshots, failed deletes, and log append failures recover without silent data corruption.
- Android and Windows production artifacts are produced by CI with stable signing and inspected as exact release assets.
- Native Android share and Windows Save As flows work with real exported ZIP content.
- Release contains only the intended APK, Windows installer, and portable ZIP and supports in-place update.
