# Plan

## Approach

Preserve the accepted StudyHUB interaction contract, harden it for a private Flutter Android/Windows app, integrate a target-owned snapshot into Perfect, then keep the generalized and verified source in the personal Components catalog.

## Steps

| Step | Status | Notes |
|---|---|---|
| 1. Freeze the StudyHUB behavior and privacy contract | done | Capture menu, immediate screenshot, note classification, review, delete, clear, and export were inspected. |
| 2. Build and harden the product-neutral Flutter component | done | Atomic indexes, bounded storage/logging, retries, full PNG validation, cleanup recovery, privacy review, and responsive UI are implemented. |
| 3. Integrate into authenticated Perfect scope | done | Owner-scoped storage/preferences, guarded lifecycle, global and handled-error logging, overlay, route attribution, and More settings are wired. |
| 4. Populate Components and create ReadyUse | done | Canonical component v1.2.0 and the structure-valid `ready-use` skill exist at their direct personal-library locations. |
| 5. Verify component and scoped integration | done | Perfect feedback tests pass 53/53, focused More integration passes, and the independent source-level eight-contract verifier passes. Canonical v1.2.0 resolves dependencies, analyzes cleanly, passes 53/53, passes both ReadyUse suites (7/7 and 3/3), and passes validation/inventory/skill checks. |
| 6. Verify the whole application and native behavior | active | Perfect formatting and analysis are clean; the full non-golden suite passes 316/316 and Windows goldens pass 7/7. A 67.2 MB Android release-mode APK builds locally, but it uses the Android Debug signer. Local Windows build is blocked because Visual Studio is not installed; real native capture/share/save proof remains open. |
| 7. Commit, push, and verify release | planned | Push `main`, wait for GitHub Actions, inspect exact installable assets, and confirm upgrade continuity. |

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

## Acceptance Checks

- Perfect formatting and full analysis pass.
- Perfect feedback tests pass 53/53, focused More integration passes, the full non-golden suite passes 316/316, and Windows golden tests pass 7/7.
- The independent verifier reports a source-level eight-contract pass for lease drain/re-entry/timeout, immutable review, managed-path containment, Windows timeout fail-closed cleanup, and logger non-resurrection. This is source evidence, not native runtime proof.
- Clear All removes active storage, screenshots, logs, recovery directories, atomic `.bak`/`.tmp` generations, and all app-owned managed-export artifacts; it rebuilds safe empty indexes, surfaces partial deletion, and preserves the explicit external-ZIP boundary.
- Canonical v1.2.0 `pub get`, full analysis, and 53/53 tests pass; ReadyUse suites pass 7/7 and 3/3; validator, inventory, and skill quick-validation pass.
- Canonical generated dependency/build metadata is removed after verification, and the target/canonical behavioral drift audit reports zero unintended differences.
- Owner switching cannot share feedback paths or toggle preferences.
- Failed index writes, damaged indexes, orphan screenshots, failed deletes, and log append failures recover without silent data corruption.
- Android and Windows production artifacts are produced by CI with stable signing and inspected as exact release assets.
- Native Android share and Windows Save As flows work with real exported ZIP content.
- Release contains only the intended APK, Windows installer, and portable ZIP and supports in-place update.
