# State

- Current status: `active`
- Last updated: 2026-08-02 08:02 +03:30
- Owner: Codex

## Current State

The private feedback feature is implemented as a self-contained Perfect source snapshot and as canonical reusable component v1.2.0. Perfect formatting and full analysis are clean; feedback tests pass 53/53; focused More integration passes; the full non-golden suite passes 316/316; and Windows goldens pass 7/7. An independent source-level verifier passes all eight inspected contracts. Canonical v1.2.0 now has dependency-backed proof: `pub get` and full analysis pass, all 53/53 component tests pass, both ReadyUse suites pass 7/7 and 3/3, and validator, inventory, and skill quick-validation pass. Generated canonical files were cleaned afterward, and the target/canonical behavioral drift audit found zero unintended differences.

A 67.2 MB Android release-mode APK builds locally, but certificate inspection identifies the Android Debug signer. It is verification-only and does not prove stable private-release signing. The local Windows build cannot start because `flutter doctor` reports that Visual Studio is not installed. The task therefore remains active until CI produces and proves the intended stably signed release assets; real Android/Windows native capture, share/Save As, upgrade, and data-continuity evidence also remains required.

The authenticated workspace owns one controller per Supabase user. Storage namespace and preference key are deterministically owner-scoped, initialization failure is contained, and disposal detaches the repository immediately. Global Flutter/async failures plus handled planner-local and sync failures enter the bounded private log without repeating the same automatic-retry diagnostic indefinitely.

Persistence uses recoverable JSON indexes, backup generations, bounded screenshot/log retention, full PNG structure and encoding validation, cleanup of crash orphans, rollback of a newly written screenshot when index commit fails, and retryable cleanup markers when deletion is incomplete. Repository mutation is serialized through `ReadyFeedbackRepository.withStoreLease`: the same-instance queue, shared in-process queue, and OS file lock cooperate; lease-issued work drains FIFO before release; public repository re-entry fails with `StateError`; and lock acquisition uses bounded retry/timeout rather than waiting forever.

Export review is immutable. The controller binds the displayed counts and contents to one entries/logs/screenshots snapshot, then deep-revalidates it under the store lease immediately before managed preparation. Drift raises `ReadyFeedbackExportChangedException` and forces a fresh review. Native picker/share work is never performed while the store lease is held. Android uses prepare/commit/complete with managed staging under lease and sharing outside it. Windows opens Save As outside the lease, revalidates afterward, and bounds final commit work.

Managed export containment is link-aware. Dedicated managed paths and prefixes are canonicalized; linked/junction temp-root ancestors and a linked dedicated child are rejected. Purge deletes unknown, nested, linked, and interrupted app-owned artifacts without following links, then verifies that the managed directory is absent. Windows staging, rollback backup, and the active commit marker are kept inside that managed area. A stalled saver leaves an active marker, so Clear fails retryably instead of falsely reporting success; when the saver settles, cancellation cleanup removes the staging/backup/marker and a later Clear can succeed. The pre-existing owner destination remains intact during the stall and is rollback-protected on later failure or cancellation.

Clear All runs repository cleanup and managed-export purge under the same lease. It removes active notes, screenshots, logs, recovery copies, atomic `.bak`/`.tmp` generations, and orphan/unknown managed-export artifacts, then rebuilds safe empty indexes. It reports partial cleanup for retry. ZIPs already saved or shared outside the app-owned area are explicitly outside Clear's scope and remain the owner's responsibility.

Logger cleanup is non-resurrecting: Clear and recovery detach the logger and clear pending buffers before work, clear again before reattach in both success and failure paths, preserve the original storage exception, and update counts without masking it. This prevents pre-operation diagnostics from being appended back into a freshly cleared or recovered store.

The UI preserves StudyHUB parity: the floating control is draggable and excluded from captures; screenshot capture happens before the note dialog; the owner sees the actual image plus a pixel-privacy warning before save; saved entries show thumbnails and a detail preview; export review distinguishes redacted text from unchanged screenshot pixels. The same feature is reachable from a semantic More-page settings surface and adapts to compact/high-text layouts.

## Decisions

| Date | Decision | Reason | Source |
|---|---|---|---|
| 2026-08-02 | Keep Perfect's build source under `lib/feedback` | Clean CI and signed releases cannot rely on a machine-local absolute path. | User requirement and repository invariant |
| 2026-08-02 | Keep canonical reusable source directly under `Projects/Components` | The shared personal library must not be nested inside Perfect. | User correction |
| 2026-08-02 | Use snapshot integration rather than a personal-path dependency | Each target must own the source it builds and releases. | ReadyUse contract |
| 2026-08-02 | Keep diagnostic bundles local until explicit export | The app is private and no automatic upload was requested. | User scope and privacy contract |
| 2026-08-02 | Use Android native share and Windows native Save As | These are the appropriate platform-native delivery paths. | Platform/package evidence |
| 2026-08-02 | Treat screenshot pixels separately from text redaction | Image pixels are preserved exactly and may expose private on-screen content. | Independent verifier finding |
| 2026-08-02 | Serialize remaining Flutter verification | Parallel runners contended for `sqlite3.dll`; the failure was tooling contention, not a product assertion. | Independent verifier evidence |
| 2026-08-02 | Keep native picker/share outside the store lease | User interaction and platform futures must not hold repository mutation serialization. | Focused exporter tests and source-level verifier |
| 2026-08-02 | Bind export approval to an immutable snapshot | Counts shown during privacy review must match the data delivered; drift requires a new review. | Controller/exporter contract |
| 2026-08-02 | Keep all Windows transient commit artifacts in the managed cache | Clear must detect and retry incomplete cleanup without touching or misclassifying the owner-selected destination. | Windows timeout regression coverage |
| 2026-08-02 | Treat external saved/shared ZIPs as outside Clear scope | The app cannot safely delete copies after ownership has passed to a picker/share destination. | Privacy confirmation contract |

## Independent Findings and Closures

| Finding | Closure | Evidence state |
|---|---|---|
| A real owner credential appeared in an uncommitted redaction fixture | Replaced with unmistakably fake data; component verification now scans source, tests, and docs rather than `lib` only. | closed before Git history |
| Duplicate redactor definitions/exports appeared during parallel editing | Consolidated to one implementation and one public export. | closed; scoped analysis/tests pass |
| Initial port lacked the StudyHUB screenshot preview and saved-entry thumbnails | Added real pre-save preview, explicit pixel warning, thumbnail list, and full detail review. | closed; overlay widget tests pass |
| Static storage namespace and toggle key could cross owner boundaries | Both values now derive from the authenticated Supabase owner; controller lifetime is tied to that scope. | closed; source inspected and scoped analysis passes |
| Repeated logger attachment and failed append could duplicate or strand records | Logger attachment is owner-aware/idempotent, uses bounded retries, and cancels/resumes safely across detach/reattach. | closed; logger tests pass |
| Screenshot write could leave an orphan when index commit failed | Failed commits remove the new screenshot; startup sweeps crash orphans while preserving indexed files. | closed; repository tests pass |
| Header-only PNG checks accepted structurally incomplete images | Validation now walks chunks through complete `IEND` and checks IHDR dimensions/encoding constraints and configured bounds. | closed; repository tests pass |
| Parallel Flutter checks locked Windows native assets | Checks were serialized; Perfect feedback 53/53, full non-golden 316/316, and Windows golden 7/7 now pass. | closed for test execution |
| Clear All could leave recoverable data in screenshot/recovery directories or atomic `.bak`/`.tmp` generations | Clear All now removes active storage and every recoverable generation, rebuilds safe empty indexes, surfaces partial deletion, and retains a retry path. | closed at focused/source level; Perfect feedback 53/53 and independent verifier pass |
| Concurrent repository/export operations could race or deadlock | Added the same-instance/shared-process/OS store lease, FIFO drain, public re-entry rejection, and bounded lock timeout. | closed at focused/source level; Perfect feedback 53/53 and independent eight-contract pass |
| A reviewed export could change before native delivery | Review now holds an immutable deep snapshot and revalidates it under lease after picker return/before delivery. | closed at focused/source level; Perfect feedback 53/53 and independent verifier pass |
| Junctions or links could redirect cleanup outside the managed cache | Canonical ancestor/child validation rejects linked temp-root ancestry and linked managed children; purge does not follow links. | closed at focused/source level; exporter tests and independent verifier pass |
| A timed-out Windows saver could outlive Clear and recreate private staging | Staging, backup, and active marker now live in managed cache; marker makes Clear fail closed until saver settlement cleanup completes. | closed at focused/source level; stalled-saver regression passes; native runtime pending |
| Pending logger records could repopulate a cleared/recovered store | Clear/recovery detach and double-clear buffers around work and reattachment, including failure paths. | closed at focused/source level; repository tests and independent verifier pass |

## Blockers

- Local Windows build proof is environment-blocked: `flutter doctor` reports Visual Studio is not installed. Unblock with CI or a Windows host containing the required Visual Studio desktop C++ tooling.
- Stable Android/Windows release proof depends on CI signing and artifact production. The local Android APK uses the Android Debug signer and is not a release-signing substitute.

## Done

- StudyHUB behavior and privacy contract frozen.
- Product-neutral feedback architecture implemented and integrated.
- Owner isolation, lifecycle safety, retry behavior, atomic persistence, cleanup recovery, redaction, full PNG validation, and UI parity implemented.
- Canonical component v1.2.0 placed directly in the Components library with synchronized manifest/header/README/changelog/catalog version contract.
- `ReadyUse` skill and component verification/inventory helpers created; skill structure and catalog inventory checks passed.
- Perfect format and full analysis passed.
- Perfect feedback tests passed 53/53; focused More integration passed; full non-golden tests passed 316/316; Windows goldens passed 7/7.
- A 67.2 MB Android release-mode APK was built and correctly classified as verification-only because it uses the Android Debug signer.
- Independent source-level verification passed all eight targeted contracts.
- Canonical v1.2.0 `pub get`, full analysis, and 53/53 tests passed; ReadyUse suites passed 7/7 and 3/3; validator, inventory, and quick-validation passed.
- Canonical generated files were cleaned and the behavioral drift audit reported zero unintended differences.

## Remaining

- Obtain the CI-built, stably signed Android and Windows release artifacts and inspect their exact contents/certificates.
- Build Windows on CI or a host with Visual Studio desktop C++ tooling.
- Perform real Android and Windows capture/export/runtime smoke tests and responsive visual inspection.
- Verify app lifecycle, session/data preservation, signing, and in-place upgrade behavior.
- Inspect final diff/security scan, commit, push `main`, wait for workflow completion, and inspect exact release assets.
