# Stage 01 — Preservation and personal-product contract

Status: completed locally; hosted exact-SHA release verification follows push
Depends on: none  
Blocks: every structural UI, data, auth, AI, widget and release change

## Mission

Create an executable safety boundary for a private Android/Windows planner. The
stage is not paperwork: it must make destructive shortcuts fail tests and make
upgrade continuity measurable before the rebuild proceeds.

## Fixed product decisions

- Platforms are Android phone/tablet and Windows only. Web code, web release and
  web-responsive compromises are out of scope.
- The product name is `Perfect!`; package identity, database identity and signing
  lineage remain stable.
- Local write succeeds first; Supabase synchronizes later. Network loss never
  removes the ability to view or change the owner's local plan.
- The signed owner build starts with zero planner entities. Demo fixtures are
  legal only in a separate dev entrypoint/package and never in production.
- Normal updates preserve authentication, settings, local records, occurrence
  history, operation queue, widget state, AI drafts and unresolved conflicts.
- Provider/database secrets are never embedded in client assets or command argv.
- Existing user data is more valuable than visual architecture. No rebuild may
  reset, silently transform or discard it to simplify implementation.

## Work packets

1. Freeze `git status`, branch/remotes, HEAD/release SHA, tags, stashes and any
   ignored evidence paths. Record the retained stash as intentional.
2. Inventory Android application ID, signing configuration, version source,
   adaptive icon resources, database filenames and secure/session storage keys.
3. Inventory Windows identity, publisher, installer upgrade code, protocol,
   LocalState path, ICO, executable name and portable data behavior.
4. Inventory Drift schema version, every migration, Supabase migration, Edge
   Function version, RLS policy, RPC and realtime subscription.
5. Inventory all code paths containing `seed`, `fixture`, `demo`, `sample`, reset,
   delete-all, sign-out cleanup or database recreation.
6. Classify each path: production-required, dev-only, test-only or forbidden.
   Enforce classification by entrypoint/package guards rather than comments.
7. Create two-version upgrade fixtures: version N writes an auth marker, setting,
   task, habit occurrence, pending operation and widget payload; N+1 must read all.
8. Add negative tests proving sign-out/session expiry never deletes planner data,
   and a failed migration leaves the prior database recoverable.
9. Add artifact secret scans for APK, Windows portable and setup outputs.
10. Update state/progress/verification docs with exact commands and evidence.

## Failure and edge scenarios

- App killed between local transaction and enqueue; enqueue duplicated on resume.
- Schema migration interrupted; old binary reopened; remote schema newer than app.
- Refresh token expired offline; secure storage temporarily unreadable.
- Android package update over a widget already placed on launcher.
- Windows setup update while app process is open or LocalState contains a pending
  queue and unsent feedback bundle.
- Existing blank owner versus owner with thousands of entities/history rows.

## Verification matrix

- Static: analyze identity/version/storage code; scan prohibited reset/seed calls.
- Unit: migration, storage continuity, idempotency, fixture isolation and secret
  absence contracts.
- Android: install N, create markers, install N+1 over N, reopen app and widget.
- Windows: setup N→N+1 plus portable N→N+1 against preserved data directory.
- Supabase: read-only schema/RLS/function inspection; no destructive mutation.

## Reject the stage if

- Any production path can auto-create sample Task/Habit/Plan/Note records.
- Upgrade proof uses uninstall/reinstall, a different package identity or a fresh
  data directory.
- A passing local test is presented as remote RLS/deployment proof.
- Signing or secrets require exposing sensitive values in logs/argv.

## Completion handoff

Record immutable preservation identifiers and test entrypoints for Stage 02.
Commit only contract/tests/docs changes, push `main`, verify workflow/release when
runtime artifacts changed, and leave the tree clean with only `main`.

## Completion record — 2026-08-09

- The complete Git/release/identity/storage/schema/reset-path inventory is frozen in
  [`evidence/01-preservation-baseline.md`](evidence/01-preservation-baseline.md).
- `test/preservation/personal_product_preservation_contract_test.dart` now rejects
  production fixture seeding, destructive sign-out, identity drift, local
  task/habit/occurrence/outbox loss and unrecoverable interrupted migration.
- Trusted build-time values use a protected temporary JSON file and
  `--dart-define-from-file`; they no longer travel in Flutter command arguments.
- APK, Portable ZIP, MSIX and Setup receive exact-value signing-secret scans before
  upload. The scanner itself is tested to fail without printing the protected value.
- Focused preservation/release tests, analyzer, YAML parsing, Bash syntax and both
  PowerShell workflow blocks pass locally. Signed artifact continuity is claimed
  only after the pushed SHA completes hosted CI.
- The retained stash and unrelated/unaccepted workspace files remain deliberately
  untouched; they are not hidden inside this stage's commit.
