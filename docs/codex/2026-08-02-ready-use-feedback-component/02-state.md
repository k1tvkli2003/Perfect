# State

- Current status: `active`
- Last updated: 2026-08-02 09:17 +03:30
- Owner: Codex

## Current State

The private feedback feature is implemented as a self-contained Perfect source snapshot and as canonical reusable component v1.2.2. After the third path-hardening pass, Perfect formatting/diff checks and full analysis are clean; repository tests pass 29/29, the complete feedback suite passes 56/56, the full non-golden suite passes 319/319, and Windows goldens pass 7/7. The release-workflow source contract passes 8/8. The earlier focused More integration remains green at its recorded checkpoint. The original independent source-level eight-contract verifier passed the export/concurrency/privacy contracts, and independent re-review now passes the latest filesystem patch with the explicit location-safety caveat below.

Canonical v1.2.2 now contains the complete third hardening. Format is clean, full analysis reports no issues, and the full component suite passes 56/56. ReadyUse suites pass 7/7 and 3/3; the validator scans 20 files at v1.2.2; inventory resolves verified-source v1.2.2 for Android/Windows; and skill quick-validation passes. Generated `.dart_tool`, `build`, `.flutter-plugins-dependencies`, and `pubspec.lock` artifacts were removed afterward through validated paths and their absence was confirmed. A full lib/test drift audit reports no behavioral drift; the remaining differences are the documented namespace/copy, structural barrel-path, and product-neutral state/token adaptations. Perfect's provenance comment also reports v1.2.2.

A 67.2 MB Android release-mode APK builds locally, but certificate inspection identifies the Android Debug signer. It is verification-only and does not prove stable private-release signing. The local Windows build cannot start because `flutter doctor` reports that Visual Studio is not installed.

GitHub Actions Run #33 (`30732676410`, head `b54b4e0`) failed and produced no release. Its Linux job passed format and analysis, then reported 314 passed, one failed, and one skipped test. The sole failure was `a linked storage base is rejected before namespace access`: a trailing separator survived normalization, and POSIX `lstat("link/")` dereferenced the final directory symlink, so the repository returned an empty list instead of rejecting the untrusted base. The patch strips trailing separators from every non-root supplied base before entity probes while preserving real filesystem roots; the regression now covers linked bases both with and without a trailing platform separator.

Independent review then widened that first patch before release. A pure lexical storage-path policy recognized POSIX `/`, Windows drive roots, and UNC share roots, stripped trailing/repeated separators only beyond the actual volume boundary, and stopped ancestry traversal at the share rather than climbing to a synthetic UNC parent. After canonical resolution the complete ancestry was checked again without following links, and the pre/post fingerprint, canonical path, and `FileSystemEntity.identical` result had to agree. Repeated-separator final/ancestor links were rejected, while a relative path with dot segments and a missing base resolved and created exactly one intended trusted base. That second-pass checkpoint passed repository 28/28, feedback 55/55, full analysis, and non-golden 318/318; it was later superseded by the third patch described below.

A subsequent independent verifier did not accept that second filesystem patch as final. It found that mutable directory metadata (`size`, `modified`, and `changed`) could produce a false identity-change failure, extended Windows drive/UNC/volume-GUID roots were not modeled, and the policy helper leaked through the public barrel. Those findings triggered a third patch.

The third patch removes `_PathFingerprint`/`FileStat` from the base-identity decision while preserving full fingerprints for the separate held-root/lock contract. Base validation now performs canonical resolve, a complete no-follow ancestry rewalk, a second canonical resolve, exact canonical equality plus a current OS `identical` alias check, and a final ancestry rewalk. The lexical policy handles exact POSIX, ordinary drive/UNC, extended drive/UNC, and valid volume-GUID roots, preserves required separators, uses the same normalization in `_comparisonPath`, and rejects `\\.\`, GLOBALROOT/unknown `\\?\`, malformed roots, forward slashes, and dot components in the extended namespace. The helper is hidden from the public barrel and tests import the internal source explicitly. Perfect repository 29/29 and feedback 56/56 pass; focused analysis, format, and diff checks are clean. Independent re-review passes.

The accepted caveat is precise: this is canonical-path/no-follow location safety, not an OS file-id or inode snapshot held across the entire validation window. A regular-directory replacement at the same safe lexical path is intentionally accepted, and no test deterministically injects a swap at the exact boundary between validation passes. No production-only test callback was added to simulate that timing.

Run #33's Windows job built the desktop bundle and portable package and reached signed MSIX/Setup verification, but the job still failed before install/upgrade proof and release publication. SignTool's merged stdout/stderr placed certificate/timestamp detail between the two halves of the expected private-root policy message. The classifier incorrectly required those halves to be adjacent. The patch now requires exactly one SignTool error plus both anchored message fragments without adjacency; the workflow source regression passes 8/8. A replacement CI run and final release inspection are still pending, so no new signing, installer, upgrade, or release claim is made.

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
| 2026-08-02 | Strip only non-root trailing separators before filesystem trust probes | POSIX `lstat` dereferences a final directory symlink when the probed spelling ends in `/`; roots must still retain their valid spelling. | Run #33 Linux failure and focused regression |
| 2026-08-02 | Model filesystem volume roots lexically and revalidate identity after resolution | UNC share roots must not traverse toward a synthetic parent, and a base that changes between no-follow validation and canonical resolution must fail closed. | Independent patch review and 28/28 focused repository tests |
| 2026-08-02 | Classify the expected private-root SignTool result by exact error count and anchored fragments | Merged stdout/stderr can interleave certificate/timestamp detail; adjacency is not a stable ordering contract. | Run #33 Windows log and 8/8 workflow regression |

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
| Parallel Flutter checks locked Windows native assets | Checks were serialized; current Perfect feedback 56/56, full non-golden 319/319, and Windows golden 7/7 pass. | closed for test execution |
| Clear All could leave recoverable data in screenshot/recovery directories or atomic `.bak`/`.tmp` generations | Clear All now removes active storage and every recoverable generation, rebuilds safe empty indexes, surfaces partial deletion, and retains a retry path. | closed at focused/source level; Perfect feedback 56/56 and independent verifier pass |
| Concurrent repository/export operations could race or deadlock | Added the same-instance/shared-process/OS store lease, FIFO drain, public re-entry rejection, and bounded lock timeout. | closed at focused/source level; Perfect feedback 56/56 and independent eight-contract pass |
| A reviewed export could change before native delivery | Review now holds an immutable deep snapshot and revalidates it under lease after picker return/before delivery. | closed at focused/source level; Perfect feedback 56/56 and independent verifier pass |
| Junctions or links could redirect cleanup outside the managed cache | Canonical ancestor/child validation rejects linked temp-root ancestry and linked managed children; purge does not follow links. | closed at focused/source level; exporter tests and independent verifier pass |
| A timed-out Windows saver could outlive Clear and recreate private staging | Staging, backup, and active marker now live in managed cache; marker makes Clear fail closed until saver settlement cleanup completes. | closed at focused/source level; stalled-saver regression passes; native runtime pending |
| Pending logger records could repopulate a cleared/recovered store | Clear/recovery detach and double-clear buffers around work and reattachment, including failure paths. | closed at focused/source level; repository tests and independent verifier pass |
| A trailing separator let POSIX `lstat` dereference a linked storage base | Normalize away trailing/repeated separators beyond a platform-aware volume root before probing; test final/ancestor links in multiple spellings. | closed in Perfect/canonical and independently reviewed; replacement CI pending |
| The first fix depended on host parent semantics and did not prove UNC/root or post-resolve stability | Added platform-aware roots, relative/dot-segment coverage, two canonical resolutions around no-follow ancestry walks, canonical equality, and current alias identity. | closed in Perfect/canonical with 319/319 full-suite and independent pass; replacement CI pending |
| SignTool private-root output was split by merged stdout/stderr detail | Match two anchored policy fragments plus exactly one SignTool error instead of requiring adjacency. | closed locally; release workflow contract 8/8 passes; replacement CI pending |
| Mutable directory metadata is treated as storage identity | Removed FileStat/fingerprint comparison from base identity; use two canonical resolves around no-follow ancestry rewalk plus canonical equality/current alias identity. | closed; independent re-review pass with documented location-safety caveat |
| Extended Windows roots are not modeled and the lexical helper is public | Added ordinary/extended drive, UNC, and valid volume-GUID boundaries with strict malformed/device-namespace rejection; hid helper from public barrel. | closed in Perfect/canonical; repository 29/29, feedback/canonical 56/56, independent pass; replacement CI pending |

## Blockers

- Local Windows build proof is environment-blocked: `flutter doctor` reports Visual Studio is not installed. Unblock with CI or a Windows host containing the required Visual Studio desktop C++ tooling.
- Stable Android/Windows release proof depends on CI signing and artifact production. The local Android APK uses the Android Debug signer and is not a release-signing substitute.
- Run #33 failed before Android packaging, Windows install/upgrade proof, and release publication. The local fixes need a new CI run before any final artifact or signing conclusion.

## Done

- StudyHUB behavior and privacy contract frozen.
- Product-neutral feedback architecture implemented and integrated.
- Owner isolation, lifecycle safety, retry behavior, atomic persistence, cleanup recovery, redaction, full PNG validation, and UI parity implemented.
- Canonical component v1.2.2 placed directly in the Components library with synchronized version surfaces and the complete third filesystem hardening.
- `ReadyUse` skill and component verification/inventory helpers created; skill structure and catalog inventory checks passed.
- Perfect format and full analysis passed.
- Perfect feedback tests passed 56/56 after the third hardening; focused repository tests passed 29/29; full analysis, format, and diff checks are clean; full non-golden passes 319/319; and Windows goldens pass 7/7. Focused More integration passed at its recorded checkpoint.
- A 67.2 MB Android release-mode APK was built and correctly classified as verification-only because it uses the Android Debug signer.
- Independent source-level verification passed all eight targeted contracts.
- Canonical v1.2.2 format/full analysis and full tests passed 56/56; ReadyUse suites passed 7/7 and 3/3; validator, inventory, and quick-validation passed.
- Canonical generated files were cleaned through validated paths, absence was confirmed, and the full lib/test drift audit reported no behavioral drift beyond documented adaptations.
- Run #33 failures were traced to the POSIX final-symlink probe and SignTool stdout/stderr interleaving assumptions; both have local patches and regressions.
- After the third hardening, Perfect format/diff and full analysis pass, repository tests pass 29/29, feedback passes 56/56, full non-golden passes 319/319, Windows goldens pass 7/7, and the release-workflow contract remains 8/8.
- Independent re-review passes the third filesystem patch with the explicit canonical-path/no-follow location-safety caveat.

## Remaining

- Obtain the CI-built, stably signed Android and Windows release artifacts and inspect their exact contents/certificates.
- Build Windows on CI or a host with Visual Studio desktop C++ tooling.
- Perform real Android and Windows capture/export/runtime smoke tests and responsive visual inspection.
- Verify app lifecycle, session/data preservation, signing, and in-place upgrade behavior.
- Inspect final diff/security scan, commit, push `main`, wait for workflow completion, and inspect exact release assets.
- Run replacement CI for the current remediation and confirm that Linux tests, Windows packaging verification, install/upgrade proof, and the exact three-asset release all complete.
