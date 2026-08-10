# Stage 01 evidence — preservation and personal-product baseline

Captured: 2026-08-09 (Asia/Tehran)
Stage owner: root agent, working alone
Scope: Android phone/tablet and Windows only

This is the immutable handoff boundary for the 50-stage rebuild. It records
what must survive every later change and the executable checks that reject a
destructive shortcut. It does not claim signed-in device behavior that has not
been observed.

## 1. Git and release freeze

| Item | Frozen evidence |
| --- | --- |
| Baseline HEAD | `8be77d5459ec5a2a319a334d8ad16f9b8cde0e82` (`docs: define canonical 50-stage rebuild plan`) |
| Branch/upstream | local `main` tracking `origin/main` |
| Remote | `https://github.com/k1tvkli2003/Perfect.git` |
| Retained stash | `stash@{0}: wip/android-upgrade-proof-before-ui-rebuild` — intentionally retained until the rebuild finishes |
| Unaccepted prototypes | modified `lib/presentation/perfect_workspace_page.dart`, modified `test/presentation/perfect_workspace_page_test.dart`, untracked `lib/presentation/perfect_date_format.dart`; excluded from Stage 01 staging and proof |
| Other pre-existing untracked workspace state | `.vscode/settings.json` and zero-byte `NUL`, both dated 2026-08-07; preserved rather than silently deleted or claimed |
| Ignored sensitive/generated roots | `.env`, `.env.*`, `/build/`, private JKS/PFX/private-key patterns and protected secret exports |
| Latest successful hosted run before Stage 01 | run `#38`, ID `31059011394`, SHA `6b810449acd2c028d3ad7c15d6d5d6401c01e5f5` |
| Latest immutable release before Stage 01 | `v1.1.0-build.2038`, published 2026-08-06T00:29:08Z, exactly APK + Windows Setup + Windows Portable |
| Last proven Windows update | run `#38`: MSIX `1.1.0.37 → 1.1.0.38`; package family and exact LocalState marker preserved; Setup rerun preserved both and did not mutate Trusted Root |

The documentation-only baseline commit did not produce a new workflow run. A
later hosted result must be tied to its exact SHA before it is cited as artifact
proof.

## 2. Installed identity and signing lineage

| Surface | Immutable identifier | Version source | Signing boundary |
| --- | --- | --- | --- |
| Android production | `com.k1tvkli2003.perfect`; label `Perfect!` | `pubspec` semantic version plus BUILD epoch and GitHub run number | stable private JKS; alias/password/key remain GitHub secrets; certificate SHA-256 is a public repository variable |
| Android live preview | `com.k1tvkli2003.perfect.preview`; `-preview` version suffix | local Flutter debug build | debug identity; cannot read or replace production session/database/widget |
| Windows MSIX | identity `com.k1tvkli2003.perfect`; publisher `CN=K1 Perfect Private`; display `Perfect!`; protocol `perfect` | `MAJOR.MINOR.PATCH.GITHUB_RUN_NUMBER` | stable private self-signed end-entity PFX pinned by public thumbprint |
| Windows executable | `perfect.exe`; Product/File Description `Perfect!` | Flutter/Runner resource version | same binary is packaged in portable and signed MSIX payloads |

Pinned source hashes at the Stage 01 freeze:

| Source/asset | SHA-256 |
| --- | --- |
| `assets/brand/perfect-launcher.png` | `43A5344BC25CE9C3A3562153C4667A6F49D9652209345FF6BCBA25D4607C5728` |
| `windows/runner/resources/app_icon.ico` | `B40D6528328758F7D0B29F3597A08F6498FF6A14256A91B5662E0F8771B99FAA` |
| `lib/planner/data/planner_database.dart` | `CA249D6D2A9DFD011CD0ADA8D85F18864258B16CA60B73358516A8D7360965F5` |
| `.github/private-build-contract.yml` | `1137C05CBF92A63B39D9FD46178B9505073018FBB242126323B3CBED10B556DE` |
| `.github/workflows/verify.yml` | `E177DDE7CBB445C4CE3FE2B24C4FA184D218F7163C38B6D1D48EFEC243515051` |
| `android/app/build.gradle.kts` | `1743ED76BC0D3336C2F2D4F058F4A7ACE1E6566F767F1C39B206B194FA1B781F` |
| `pubspec.yaml` | `BF03C52FF9817135B998492EDA9AC6FE7DD4ECDF4EA619247E74AA41152DA51B` |
| `tool/verify_artifact_secret_absence.py` | `03294414E050E65277C41AF0431544237A8DCB1C0B8B83CE262BE140E48B05E5` |

The hashes are drift detectors, not instructions to freeze visual assets forever.
Later identity/icon work must change them deliberately and preserve package/signing
identity.

## 3. Local persistence boundary

### Drift

- Database name is `perfect_planner`; current `drift_flutter` resolves it as
  `perfect_planner.sqlite` under `getApplicationDocumentsDirectory()` unless an
  explicit executor is provided.
- Schema version is `2`.
- Tables are `planner_entities`, `planner_occurrences`,
  `planner_focus_sessions`, `planner_outbox_operations`,
  `planner_sync_metadata`, `planner_conflicts`, `planner_import_markers`, and
  `planner_widget_action_sequences`.
- Schema v2 adds only the widget action sequence guard. The migration creates the
  table transactionally and does not rewrite planner records or outbox rows.
- Every durable planner mutation writes its local projection and outbox operation
  in one Drift transaction. Closing a controller closes the connection, not the
  database file.
- Owner ID is part of every durable table boundary; another owner cannot read the
  fixture records through `PlannerLocalStore`.

### Preferences, auth and native widget

- Theme: `perfect.theme_mode`.
- Remembered Windows rail state:
  `perfect.windows_navigation_rail_extended`.
- Stable sync device identity: `perfect.planner.device_id.v2`.
- Reminder settings use versioned `perfect.reminders.*.v1` keys.
- Supabase connection is stored atomically in
  `perfect.supabase_connection.v2`; the legacy split v1 pair is migration input
  only. Privileged/service-role/secret key shapes are rejected.
- Supabase Flutter owns its persisted auth session. Production startup has no
  preference/database clear path. Explicit sign-out clears the private widget
  projection first and then signs out; it does not delete planner storage.
- Native widget keys are versioned (`perfect_today_widget_*_v1`) and include the
  snapshot, pending/acknowledged task actions, pending/acknowledged quick adds,
  interaction token, owner, and title-visibility setting.
- Android cloud backup and device transfer are both explicitly excluded for local
  database/session/widget/config data. Upgrade continuity therefore relies on the
  stable package sandbox and Supabase sync, not cross-device Android backup.
- Synced AI conversation, messages, reviewable proposal and action audit are
  remote owner-scoped records. An unsent text field buffer is not counted as a
  synced proposal and is not claimed as durable evidence here.

Windows portable and MSIX currently resolve the same Drift name through the
platform documents directory. The release workflow's LocalState marker proves MSIX
package-family continuity, while the file-backed Drift tests below prove database
reopen/migration continuity. A real signed-in N→N+1 application journey remains a
milestone gate, not an inference from either check alone.

## 4. Supabase and AI data-plane inventory

Exactly eight additive local migration files are authoritative, in order:

1. `20260730053612_create_perfect_items.sql`
2. `20260730053626_add_private_planner_v2.sql`
3. `20260730054603_harden_perfect_legacy_anon_access.sql`
4. `20260730054708_minimize_perfect_authenticated_grants.sql`
5. `20260730190000_add_agent_plan_ingestion.sql`
6. `20260730192000_add_private_ai_conversation_sync.sql`
7. `20260730210000_harden_private_ai_metadata.sql`
8. `20260730220000_add_private_ai_planner_context_rpc.sql`

The resulting contract includes owner-scoped RLS, minimized direct grants,
idempotent `apply_planner_mutation`, cursor-based `pull_planner_changes`, agent-plan
submission, AI conversation/message/action-audit RPCs, retention and bounded private
planner context. Realtime publication is limited to the intended change and AI
tables. The single Edge Function is `perfect-agent`; its source contract is version
1, prompt `perfect-agent-v1`, agent schema `agent-plan-v1`, chat model
`gemini-flash-lite-latest`, and server-side AvalAI credential lookup. Client code
never receives the provider key and every proposed planner write requires review.

This Stage 01 pass inspected checked-in migrations/functions only. No destructive
remote query or deployment was performed. The prior live migration/function proof
remains historical evidence; remote-current state must be rechecked at the backend
milestone.

## 5. Seed/reset/delete path classification

| Path | Classification | Allowed effect |
| --- | --- | --- |
| `lib/dev/perfect_live_preview.dart::_seedPreview` | dev-only | deterministic visual fixture in `.preview` package only |
| `AppConfig.resetForTesting` | test-only | resets in-memory static config under `@visibleForTesting`; does not clear preferences |
| reminder `resetForTesting` | test-only | resets test singleton state only |
| Habit day reset | production-required owner action | edits one selected owner/day result after confirmation; no collection wipe |
| Supabase password reset | production-required auth flow | requests password recovery; unrelated to planner deletion |
| `clearTodayWidgetForSignOut` | production-required privacy cleanup | clears native projection/replay/token/owner only |
| AI conversation delete/retention purge RPCs | production-required owner-scoped lifecycle | soft delete or bounded retention under authenticated RPC/RLS |
| production sample Task/Habit/Plan/Note creation | forbidden | no path found; deterministic test enforces preview-entrypoint isolation |
| database delete/recreate, SharedPreferences global clear, sign-out data wipe | forbidden | no production path found; static and file-backed negative tests reject regression |

## 6. Executable preservation proofs

New gate: `test/preservation/personal_product_preservation_contract_test.dart`.
It proves:

1. production `main.dart` cannot import or call the seeded preview harness;
2. preview uses a sibling Android package;
3. sign-out orders widget privacy cleanup before Supabase sign-out and contains no
   durable-store delete/reset API;
4. Android/Windows identities remain pinned;
5. a file-backed Task, Habit, completed occurrence and all three pending mutations
   survive widget cleanup, controller disposal and database reopen;
6. theme, rail setting and a session canary survive the same normal lifecycle;
7. a deliberately interrupted v1→v2 migration rolls back, after which the normal
   database opens, upgrades and recovers the original entity/outbox;
8. the release-artifact secret scanner rejects an exact protected value without
   printing it.

Focused verification command:

```powershell
flutter test test\preservation\personal_product_preservation_contract_test.dart test\app\android_private_backup_contract_test.dart test\app\app_config_test.dart test\planner\planner_task_progress_test.dart test\planner\agent_plan_ingestion_contract_test.dart test\planner\private_ai_sync_migration_contract_test.dart test\ai\perfect_agent_edge_contract_test.dart test\presentation\private_signing_portability_contract_test.dart test\presentation\private_release_update_contract_test.dart
```

Result on 2026-08-09: the final expanded preservation/config/migration/AI/signing/
release/Windows gate passed `59/59`, including the six-test preservation suite.
Focused analyzer result across all changed Dart tests: `No issues found`.

## 7. Secret and artifact boundary

- Trusted runtime config is written to a runner-temp JSON file with restrictive
  creation permissions and passed via `--dart-define-from-file`; private values no
  longer appear in Flutter argv. Windows deletes the file in `finally`; Android uses
  an EXIT trap.
- `tool/verify_artifact_secret_absence.py` accepts only artifact paths and
  environment-variable names on argv. It reads values from the environment, scans
  raw bytes plus decompressed ZIP/APK/MSIX entries in UTF-8/UTF-16, reports only the
  variable label, and never writes the value.
- Trusted Android scans the final APK for exact keystore/key passwords before
  upload. Trusted Windows scans Portable ZIP, signed MSIX and Setup EXE for the exact
  PFX password before checksumming/upload.
- Supabase URL, publishable key and the private account's transport email are
  intentional client runtime configuration, not provider/admin secrets. The
  service-role key and AvalAI provider key remain server-only and are absent from
  client build inputs.

Workflow YAML parses successfully; the Android Bash block passes `bash -n`; both
modified PowerShell blocks compile through `ScriptBlock.Create`.

## 8. Honest limits and Stage 02 handoff

- The existing Android install-over record proves package/data/widget identity but
  began signed out; it does not prove authenticated-session retention.
- Run `#38` proves Windows package family and an exact LocalState marker, not a live
  signed-in planner journey.
- The local tests prove database/preferences behavior at the code/storage boundary,
  not physical device/OEM behavior or two-device Supabase convergence.
- Those gaps stay mandatory at milestone Stages 10/20/30/40/50. No uninstall,
  package-ID change, fresh data directory or synthetic success may substitute for
  the real N→N+1 proof.
- Stage 02 may inventory routes and behavior, but production UI mutation remains
  blocked until Stages 03–05 freeze the component/page previews and Copy manifests.

## 9. Hosted transport follow-up — 2026-08-09

- Run `#39` (`31331588125`) targeted the exact Stage 01 SHA `e0840c1`. The
  Quality/Android job passed completely, including trusted APK creation and upload.
- Windows successfully built the desktop app, Portable archive, signed MSIX and
  signed Setup. The security scan then used `$packages[0].FullName`, whose source
  path no longer existed after the MSIX had been renamed, so upload, install-over
  and Release were correctly blocked.
- Commit `eaad6b2` changes the scan input to the final `$package.FullName` and adds a
  regression assertion that rejects the stale pre-rename expression. The related
  local suite passes `18/18`; replacement run `#40` (`31332512462`) completed with
  conclusion `success` at exact SHA
  `eaad6b21bb136712e5ac51d10d6b6e2bf254e5f0`.
- Release `v1.1.0-build.2040` targets that exact SHA and contains exactly three
  install-ready assets: Android APK, Windows Portable ZIP and Windows Setup. This
  closes Stage 01's hosted transport gate without broadening the runtime claims in
  the honest-limits section.
