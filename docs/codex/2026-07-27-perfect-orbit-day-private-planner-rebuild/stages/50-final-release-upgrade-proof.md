# Stage 50 — Final signed release and N→N+1 upgrade proof

Status: pending  
Depends on: Stage 49 accepted for the exact release candidate SHA  
Blocks: completion of the 50-stage rebuild  
Primary surfaces: Android APK, Windows portable ZIP, installable Windows setup,
signing/version lineage, GitHub workflow/release, in-place upgrades and final handoff

## Mission

Release the exact Stage 49 candidate as a private Android/Windows product and prove,
with two consecutively versioned artifacts signed by the same identities, that a
normal update preserves authentication and every local-first capability. Deliver only
install-ready artifacts, reproducible checksums/evidence and an honest clean handoff.

The title is not a packaging boundary: release acceptance re-proves the complete app,
data plane, AI, widget and recovery behavior after installation and upgrade.

## Autonomous decisions

- Publish exactly three user-facing release assets: one signed universal/target APK,
  one Windows portable ZIP containing only the runnable Flutter payload, and one
  installable Windows setup executable. Do not attach raw build directories, PDBs,
  source, scripts, loose certificates/keys, intermediate MSIX, duplicate APKs or test
  reports as release assets; evidence lives in CI/artifact retention/docs.
- Preserve Android application ID `com.k1tvkli2003.perfect`, Android signing key
  lineage, Windows package/publisher identity and setup `AppId`. Fail before build if
  the expected public signer fingerprints/identities differ; private material never
  enters logs, argv or release assets.
- Determine N+1 by comparing the latest accepted/published version and every platform
  mapping. Semantic version and Android versionCode increase monotonically; Windows
  package version and setup version map deterministically. A rerun for one commit is
  idempotent, never a lower/reused release with different bytes.
- Version N is the actual immediately preceding accepted signed release, not a locally
  reconstructed debug build. N+1 is built once from the exact clean `main` SHA that
  passed Stage 49; publish only bytes whose hashes were installed and verified.
- Keep only `main` locally and remotely. The explicitly retained pre-rebuild stash may
  remain only when its hash/purpose is recorded and it contains no release secret;
  stashes are not merged, dropped or called a branch during release.
- No P0/P1 or unknown required proof is waived. A failed upgrade, signer mismatch,
  extra ZIP asset or GitHub mismatch stops publication and starts a new candidate.

## Accepted preview and release-visible Copy gate

Stage 50 adds no runtime-visible surface unless it first extends the accepted Stage 03
direction and Stage 04–05 systems through `modernize`, `integrity`, `anatomy` and
`style`, receives recorded internal acceptance under the owner-delegated autonomous
design authority, and freezes the result for `copy` implementation. This
includes setup/bootstrap progress and errors, Android install/update-facing identity,
first N+1 launch/migration/recovery, launcher/splash/task switcher, widget restored/
updating states, auth-expired recovery, release notes/checksum presentation and any
diagnostic shown during upgrade. Packaging code that changes no pixels still preserves
the already accepted Stage 49 runtime references exactly.

Preview every new release-visible component separately and as a complete platform
composition across normal, progress, app-open, interrupted, signer/hash mismatch,
storage failure, rollback/recovery and success; light/dark/high contrast where the host
permits; long Persian/English/mixed copy, keyboard/screen reader and 200% text. Record
host-owned limitations explicitly. The manifest defines which content is OS/setup-
native, project vector/raster, live semantic UI or documentation; identity, warning,
error, progress and recovery copy may not be flattened or replaced by placeholders.

Before building publishable bytes, verify preview acceptance/provenance, exact bounds/
copy/assets/tokens/focus order, responsive equations and first/mid/end/reversal/reduced
motion frames. Copy acceptance uses normalized preview ↔ installed artifact captures,
plus behavior traces for update/cancel/failure/retry; every material delta creates a
new candidate and Stage 49 re-audit.

## Release artifact contract

### Android APK

- Signed release APK with stable application ID and expected certificate digest.
- Manifest/resources contain only production entrypoint/configuration; no dev fixture,
  preview suffix, embedded provider/database/signing secret or unintended exported
  component.
- `versionName`/`versionCode`, ABI/support decision, SHA-256 and exact commit are in the
  manifest/notes. Install/update works without uninstall, data clear or auth reset.

### Windows portable ZIP

- Archive root contains `perfect.exe`, required Flutter/VC/plugin DLLs and required
  `data/`/resource tree only. Paths are relative and safe; no enclosing build folder,
  installer, certificate, signing material, symbol/PDB, source, cache, logs, test data
  or unrelated documentation.
- Extract-all then run `perfect.exe` from a normal user-writable folder. Portable
  replacement does not relocate or erase the established owner data directory.

### Windows setup

- One runnable setup installs/updates the stable Windows identity using the existing
  private publisher/bootstrap contract. It validates payload hashes and pinned public
  certificate metadata, handles an open app safely and does not install an unrelated
  side-by-side identity.
- Setup version, AppId, package identity/publisher, signer digest, uninstall/update
  behavior and SHA-256 are verified. Failure rolls back safely and leaves prior app/
  LocalState usable.

## N→N+1 continuity fixture

On version N, sign in as the private owner and create uniquely labeled evidence for:

- persisted authenticated session/refresh behavior, theme/locale/rail/widget settings;
- Task, recurring Task and exception; partial/completed occurrence and checklist;
- binary and multiple-per-day Habit, streak/recovery/correction history;
- Note, Project, Area, Goal and valid relations; Focus session/history;
- reminder/notification preference, selected filters/date/scroll-safe persisted state;
- AI conversation, pending reviewed proposal, applied audit and undo record;
- placed/resized Android widget snapshot plus a pending widget/local queue action;
- one pending sync operation, one resolved conflict marker and diagnostic preference.

Record stable IDs, relevant row counts, canonical content hashes, schema version,
queue/audit IDs, Supabase state and screenshots. Do not store bearer/refresh tokens in
the evidence; prove session continuity by behavior and safe storage metadata only.

## Work packets

1. **Freeze release inputs.** Confirm local `main` is clean, `HEAD == origin/main ==`
   Stage 49 SHA, dependency lock and generated files are committed, only `main` exists
   locally/remotely, tags/releases do not collide and the retained stash is recorded.
2. **Resolve monotonic versions.** Query the latest immutable GitHub release/tag and
   platform metadata, calculate N+1, update the single canonical version source and
   assert Android/Windows/tag/filename mappings. Reject manual independent numbers.
3. **Preflight signing without revealing secrets.** Load credentials through protected
   CI secret/file channels, verify expected public certificate fingerprints, validity,
   key usage and package identities, then sign. Never echo secret values, keystore/PFX
   content or secret file paths that expose private material.
4. **Build from clean main once.** Run locked dependency restore, code generation,
   format/analyze/full tests, Stage 49 gate, Android release build, Windows release
   build, portable curation and setup compilation. Capture tool/SDK versions and SHA.
5. **Curate and inspect artifacts.** Enumerate APK and both Windows payloads, enforce
   allow/deny lists, verify names/version/signatures/identities, scan strings/archive
   contents for secrets, seeds/placeholders and debug/dev configuration, then compute
   SHA-256 before distribution.
6. **Install N and seed continuity evidence.** Use target Android phone/tablet and
   Windows setup/portable environments. Create the fixture through normal UI/domain
   paths, place/resize/action the widget, force one safe pending operation offline,
   close/restart and capture the N baseline manifest.
7. **Upgrade in place to N+1.** Install APK over N without uninstall/data clear. Run
   setup N+1 over setup N while the app-closed path and controlled app-open path are
   tested. Replace/extract the portable payload per documented update method while
   preserving the external owner data location. Never copy a fresh DB/session in.
8. **Verify migration exactly once.** On first N+1 launch record old/new schema,
   migration journal and counts/hashes; restart multiple times and prove no migration,
   seed, queue or audit duplication. An interrupted-migration rehearsal preserves a
   recoverable N store and gives actionable error rather than reset.
9. **Verify full continuity.** Confirm sign-in is still active or refreshes normally,
   every fixture entity/history/relation/setting/AI/audit/widget/queue item remains,
   pending operations converge exactly once, Sync Cloud states are truthful, deep
   links/protocol/reminders work and new N+1 functionality is available.
10. **Re-run installed smoke and quality checks.** Exercise boot/auth, navigation,
    Today/Tasks/Plan/Habits/Goals/Projects/Areas/Notes/Focus/More, capture/edit/detail,
    offline/retry/error/conflict, AI text/voice/review/apply/undo, Android widget and
    Windows setup/portable on the installed artifacts—not a debug runner.
11. **Publish atomically.** GitHub workflow builds/verifies or consumes the exact
    reproducible candidate, creates a tag resolving to the exact SHA, assembles a
    draft with exactly three assets, downloads and byte-compares them, then publishes
    an immutable non-prerelease release only after all gates succeed.
12. **Verify remote truth.** Confirm workflow conclusion, run SHA, tag target, release
    target, immutable status, exact asset names/count/sizes/digests and downloaded
    SHA-256. Compare remote `main` SHA and branch list again after publication.
13. **Complete documentation.** Publish concise install/update instructions, checksums,
    changelog, architecture/data schema and migrations, local-first/sync/conflict,
    AI privacy/review/audit/undo, widget actions/resize, backup/recovery, known limits
    and a requirement-by-requirement evidence index.

## UI/UX and motion post-install contract

- First N+1 launch looks like a normal continuation, not onboarding or an empty demo.
  Existing selection/rail/theme/widget preference and current day context are retained
  where designed; migration progress, if visible, is bounded, truthful and accessible.
- No “update complete” celebration implies sync when operations remain pending. Cloud,
  widget and AI receipts show local/sync state accurately. Reduced-motion preference
  survives and governs first-launch/migration feedback.
- Windows installer/setup copy and Android install notes name Perfect! consistently,
  explain private signing without alarmist jargon and never instruct destructive data
  clearing as a routine update step.

## Responsive and device behavior

- Install/smoke the signed APK on Android phone and tablet in portrait/landscape,
  including a placed widget before/after update. Repeat critical Stage 49 200% text,
  IME, offline/retry and reduced-motion paths after N+1.
- Install/smoke Windows setup at compact/intermediate/expanded widths and continuous
  resize; run the portable archive after clean extraction and documented replacement.
  Both Windows forms resolve the same owner data and do not create duplicate profiles.
- Upgrade does not lose route protocol, notification/widget deep links, focused draft,
  selected item/date, persisted rail state or local data due to identity/path drift.

## Domain, security and data contracts

- Stable identity set includes Android application ID/signer, database/secure-storage
  keys, widget provider/action protocol; Windows package identity/publisher/setup
  AppId/executable/protocol/data path; Supabase project/schema/RLS/function contracts.
- Migrations are forward-only, idempotent and transactional/recoverable. N+1 never
  solves failure by deleting the database, secure session, queue, widget storage or
  conflicts. A downgrade is not promised against a migrated store.
- Release evidence records public signer metadata and hashes only. Artifact/CI/log/
  screenshot/backup scans contain no provider/Supabase secret, auth token, private
  signing key, raw voice payload or unnecessary planner content.

## Offline, errors and retries

- Run N→N+1 with an intentionally pending offline operation. N+1 opens local data,
  accepts another local write, retains queue order and converges exactly once after
  connectivity; no migration or installer step requires network to preserve data.
- Expired/revoked session recovery keeps local data and queues. Server/AI unavailable,
  storage pressure, interrupted setup/migration, app-open update and widget callback
  during replacement each produce bounded recovery with no false success or reset.
- Failed publication leaves no mutable public release or mismatched tag. Idempotent
  workflow rerun accepts an existing release only when SHA and exact asset digests
  match; otherwise it fails and requires a new version/candidate.

## Accessibility and performance

- Re-run Stage 49 installed-artifact a11y and performance smoke; signing/packaging must
  not change assets, fonts, renderer, permissions, startup or semantic behavior.
- Measure N versus N+1 startup/migration, memory and key interaction/widget timings on
  the same devices/dataset. Migration stays within the recorded budget or uses an
  honest accessible progress/recovery surface; no UI-thread schema work causes ANR or
  Windows not-responding state.
- Setup is keyboard/screen-reader operable where owned by Perfect!, and install/update
  instructions/checksums are selectable, readable and unambiguous.

## Verification and required evidence

1. Git proof: clean status; only local/remote `main`; `HEAD`, `origin/main`, workflow,
   tag and release target are the exact Stage 49 SHA; retained stash hash documented.
2. Version/signing proof: N < N+1 on semantic/platform counters; Android certificate/
   application ID and Windows publisher/package/setup identities match their lineage;
   signatures verify on target OS without exposing private material.
3. Artifact proof: exactly three published assets; portable allowlist/denylist passes;
   APK/setup install; downloaded remote bytes match pre-publish SHA-256 and GitHub
   digests; release is immutable and non-prerelease.
4. Upgrade proof: signed N baseline and N+1 after-state manifests show the same owner,
   stable IDs, expected counts/hashes/settings/history/audit/widget/queue; migrations
   run once and pending operations converge once. Include Android phone/tablet,
   Windows setup and portable evidence.
5. Installed-runtime proof: real screenshots/recordings and logs cover the complete
   post-install smoke, widget placement/action continuity, AI server-only secret path,
   offline/retry/error/auth recovery and responsive/a11y/reduced-motion checks.
6. CI/release proof: successful GitHub workflow URL/run ID/conclusion/SHA, release URL,
   tag, exact filenames/sizes/digests, build tool versions and timestamp are linked in
   `05-verification.md`/handoff. Local build success alone is not remote proof.
7. Documentation proof: changelog, install/update/portable instructions, architecture,
   schema/migration, AI, widget, privacy, backup/recovery and known-limit docs match the
   shipped version and contain no placeholders or stale artifact names.
8. Preview/Copy proof: every changed release-visible component/page has an accepted
   pre-implementation Stage 03–05-derived preview, decomposition manifest and clean
   pixel/geometry/motion/behavior mismatch ledger against the installed N+1 artifact.
   Unchanged surfaces still match the Stage 49 frozen references at smoke viewports.

## Reject the stage if

- Update requires uninstall, data clear, new identity/signer, fresh data directory,
  manual DB/session copy or destructive reset.
- Any auth, entity/history/relation, setting, AI/audit, widget state, conflict or
  pending operation is missing, duplicated, silently rewritten or cross-owner after
  N→N+1.
- Version is non-monotonic; main/tag/workflow/release SHAs differ; local/remote extra
  branches remain; release is mutable or has other than the exact three assets.
- Portable ZIP contains build/source/debug/signing extras or lacks a required runtime
  file; setup fails normal in-place update/rollback; APK is debug/preview identity.
- Secret/placeholder scan fails, a required real-device installed check is absent, or
  a P0/P1/unknown required proof is renamed as a limitation.
- Final documentation claims Supabase, AI provider, GitHub, device or upgrade success
  that was only simulated or locally inferred.
- A release-visible surface was implemented before preview acceptance, ships a
  placeholder/undocumented substitution, or materially diverges from the accepted Copy
  reference in pixels, geometry, copy, motion, focus or failure/recovery behavior.

## Whole-product propagation

After N→N+1, re-verify boot/auth/session, shell/navigation/resize, Today, Tasks, Plan,
Habits, Goals, Projects, Areas, Notes, Focus and More; capture/wizards/detail/history/
search/bulk/lifecycle/reminders; local DB/queue, Supabase sync/realtime/conflicts,
backup/import/recovery; AI text/voice/proposal/apply/audit/undo; Android widget/deep
links and Windows protocol; theme/high contrast/RTL/mixed/200%/reduced motion/a11y,
performance, privacy and diagnostics. The release is one product, not three unrelated
artifact builds.

## Final handoff and ongoing release discipline

Handoff the release URL, exact SHA/version, three artifact links and SHA-256 values,
signer/identity public metadata, N→N+1 evidence bundle, CI run, device matrix, final
coverage ledger and honest known non-blocking limitations. Mark the 50-stage rebuild
done only after every required proof is linked and reproducible. Preserve the ongoing
Critics → repair → re-gate loop for later owner feedback; future builds repeat the
same monotonic version, stable signing, clean-main and upgrade-continuity contract.
