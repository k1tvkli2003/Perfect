# Stage 43 — Private auth, durable session and owner bootstrap

Status: pending  
Depends on: Stages 01, 05, 06–10 and 41  
Blocks: Stages 44–50  
Primary surfaces: boot/splash, Supabase configuration, keyvan sign-in, password
recovery, reauthentication, profile/account, widget/notification/deep-link startup

## Mission

Deliver one private owner account for `keyvan` with safe credential handling,
owner-isolated data and durable session restoration on Android and Windows. Cold
start, offline start, token refresh, revocation and signed in-place upgrades must
never delete or silently detach local planner data.

## Autonomous product decisions

- Perfect! has no public sign-up, guest, demo-owner or account picker. The visible
  username is `keyvan`; the Supabase Auth UUID remains the durable owner identity.
- The transport email may be resolved by a trusted runtime/bootstrap configuration,
  but is not a planner identity and is never displayed as a second account choice.
- Password, refresh/access tokens, recovery codes, service-role keys and AI provider
  keys are never compiled into source/assets, accepted by connection settings or
  written to logs/feedback/backups. A Supabase publishable key is validated as
  publishable—not confused with a secret—and stored with the project URL as local
  installation configuration.
- Session tokens use a platform secure-storage adapter: Android Keystore-backed
  encrypted storage and Windows Credential Locker/DPAPI-backed storage. Plain shared
  preferences/files may store only non-secret connection metadata and an opaque last
  owner binding.
- A previously authenticated owner may open the cached local workspace when refresh
  fails solely because the network is unavailable. Detected revoke, user sign-out or
  owner mismatch gates remote access and asks for reauthentication while preserving
  the database unchanged.
- Explicit sign-out clears secure session material, pending external-navigation
  intents, notification previews and widget-rendered private content. It does not
  delete planner records, settings, history, outbox or backups.

## Mandatory Stage 03–05 preview and Copy gate

No auth/session runtime implementation begins until the internally accepted Stages
03–05 Perfect! direction is extended and receives a recorded autonomous acceptance
decision. Use `modernize`, `integrity`, `anatomy`
and `style` together before implementation, then use `copy` as the fidelity owner.

- Build an opinion ledger and contract diagrams for boot/auth state machine, secure
  storage boundaries, refresh single-flight, owner bootstrap/RLS, sign-out privacy,
  recovery callback and queued external intent.
- Preview each visible component separately: identity mark, username field, password
  field/reveal control, submit/retry, recovery link, configuration field/validation,
  offline-session banner, reauth card, boot phase, queued-link notice, sign-out
  confirmation and session error.
- Preview every full page/composition for unconfigured, signed out, authenticating,
  recovery sent, recovery callback, restoring, offline-local-ready, revoked,
  wrong-owner/forbidden, service unavailable and configured states. Cover phone
  portrait/short landscape, tablet portrait/landscape, compact/expanded Windows,
  light/dark/high contrast, RTL/mixed copy, 200% text, keyboard/IME and reduced motion.
  Include empty first-run and dense long-copy/error-history stress compositions even
  when the normal private sign-in remains intentionally sparse.
- Label previews `Mock Preview`, record internal acceptance under the owner-delegated
  autonomous design authority and decompose every
  layer into live semantic UI, project-owned vector/raster assets and responsive/
  motion/state specs. Credentials and validation copy remain live, never baked.
- After that acceptance, recreate with `copy`; compare every component/page state against a
  fresh real-runtime capture at its target viewport. Close mismatch, precision and
  composition-occupancy ledgers before functional acceptance.

## Auth and session state contract

| State | Local workspace | Remote work | Required visible behavior |
|---|---|---|---|
| `unconfigured` | Preserved, not rebound | None | Private connection setup with URL + publishable-key validation; no data reset. |
| `signed_out` | Preserved and hidden from external surfaces | None | Focused keyvan sign-in; changing connection remains secondary and consequence-aware. |
| `restoring` | Open DB only after owner binding check | Refresh single-flight | Compact branded progress; queued link/widget action waits. |
| `authenticated` | Fully available | Sync allowed | Enter workspace once; bootstrap verifies the one allowlisted owner profile. |
| `offline_cached` | Fully available for the last trusted owner | Queue only | Yellow cloud + concise offline explanation; all local planning actions remain enabled. |
| `reauth_required` | Preserved; access follows the local device-trust policy | Blocked | Non-destructive reauth path, no repeated modal and no token retry storm. |
| `forbidden_owner` | Never attach foreign rows | None | Explain private-owner mismatch; sign out/change project without touching databases. |
| `recovery_pending` | Preserved | Auth recovery only | Await deep-link callback; duplicate/expired callback is recoverable and does not create a route loop. |

`SessionCoordinator` is the sole state owner. It serializes initialize, refresh,
password recovery, sign-in and sign-out; publishes typed state; binds each local
database namespace to the authenticated UUID; and hands Stage 44 a current access
session or an explicit blocked/offline classification. Screens and sync workers do
not call Supabase Auth independently.

## Server and owner-bootstrap contracts

- `planner_owner_profiles` contains exactly the pre-created private Auth UUID with a
  unique workspace slot and an explicit enabled/disabled flag. Production clients
  cannot insert profiles, promote users or enumerate allowlisted identities.
- Every RPC verifies `auth.role() = authenticated`, derives `auth.uid()`, checks the
  enabled owner profile and ignores/rejects caller-supplied owner identifiers.
- Bootstrap reads schema capability and profile only; it creates zero Task, recurring
  Task, Habit, Note, Project, Area, Goal, occurrence, focus or sample rows.
- Password recovery redirects only to the allowlisted `perfect://login-callback`
  protocol and verified Android app link/activity. State/PKCE/nonce and expiry are
  validated once; secrets never appear in URI logs or analytics.
- Supabase connection change closes subscriptions/client, validates the candidate,
  confirms consequences, preserves local owner namespaces and cannot accept a
  service-role/secret key pattern.

## Detailed work packets

1. Inventory current session persistence, auth callbacks, configuration storage,
   sign-out cleanup, owner-profile policy, widget/notification privacy and every
   direct `Supabase.instance.client.auth` consumer.
2. Define `SessionCoordinator`, `SecureSessionStore`, `ConnectionConfigStore`,
   `OwnerBindingStore` and `ExternalIntentQueue` interfaces with error taxonomy,
   lifecycle and test fakes. Migrate all consumers to them.
3. Implement platform secure storage, migration from any prior supported session
   store and atomic token replacement. If migration fails, retain old material until
   reauthentication succeeds; never log token values.
4. Make startup order explicit: configuration → secure session → authenticated UUID/
   owner binding → local schema migration → local workspace → asynchronous refresh/
   sync → queued external intent. No network wait blocks valid offline content.
5. Serialize refresh and fan out one result to sync, AI and app state. Respect server
   expiry, clock skew and refresh rotation; cancel workers/subscriptions on owner or
   connection change.
6. Harden keyvan sign-in/recovery/configuration. Preserve fields on retryable error,
   use generic auth failure copy to avoid account enumeration and rate-limit repeated
   submissions without blocking offline local work.
7. Implement explicit sign-out privacy: clear secure tokens and external cached
   previews, cancel notifications/realtime/background workers, retain owner database,
   and prove another UUID cannot attach to it.
8. Add authenticated owner bootstrap/RLS capability check and a clear incompatible-
   server state. Do not auto-create the owner or silently switch projects.
9. Queue widget, notification, recovery and Windows protocol intents durably until
   state permits one owner-authorized resolution; dedupe and expire them safely.
10. Add artifact/log/feedback/backups secret scans and a threat-model record covering
    stolen device storage, malicious URI, forged owner ID, screenshot privacy,
    expired refresh and downgrade.

## Whole-product propagation

| Consumer | Required propagation |
|---|---|
| Today, Tasks, Plan, Habits, Goals and Focus | Open cached owner projections offline; reauth/sync changes must not reset route, filters, timer, drafts or scroll. |
| Capture/edit/details | Local saves remain available in trusted offline state; destructive action revalidates the bound owner without sending owner input. |
| Android widget | Show owner data only while the device privacy grant is active; sign-out/revoke replaces content with an Open Perfect! state and queues no foreign action. |
| Notifications | Suppress private title/body after sign-out; tap waits for session/local initialization and opens the canonical current record once. |
| Deep links/Windows protocol | Validate scheme/action/ID, reject owner/token parameters, dedupe, and preserve the intended route through sign-in/recovery. |
| Perfect AI | Receives short-lived authenticated access only from SessionCoordinator; offline or reauth state preserves draft but sends no request/write. |
| Sync/conflicts | Auth failure becomes blocked-auth/red attention without dropping queue/conflicts; a restored session resumes one worker. |
| Settings/profile | Show keyvan, connection health and session state without exposing email/token/key; sign-out and connection change state consequences precisely. |
| Backup/import/recovery | Never include session material; import is authorized against the active owner binding. |
| Release/upgrades | Package IDs, secure-storage aliases, protocol handlers and signing lineage remain stable so N+1 restores N session/data. |

## Exact adaptive UX

Phone auth is a calm full-safe-area identity moment with one bounded form, primary
action in reach after fields and secondary recovery/configuration progressively
disclosed. Short landscape becomes a scrollable split composition with IME-safe
actions; nothing hides behind the keyboard.

Tablet uses a deliberate two-region composition only when both identity art and form
retain useful scale; otherwise it uses the centered phone hierarchy, not a stretched
card. Windows uses a bounded form beside a restrained identity field, native keyboard
order, Enter submit, visible focus, password-manager compatibility and selectable
diagnostic copy. Reauthentication appears in the current shell as a focused owner-
safe route/panel, not an unrelated modal over unfinished work.

Loading keeps shell anchors stable; error remains in the same field/page frame;
offline-local-ready enters the real workspace promptly. Long Persian/English auth
copy wraps, fields/actions stay whole, directional icons mirror correctly and all
states use text/icon/semantics in addition to color.

## Security, performance and rollback

- Never pass credentials in command argv. Test wrappers with non-secret sentinels
  before authenticated automation and redact request headers/bodies by default.
- Rate-limit sign-in/recovery, validate redirect origin/nonce and pin production
  project identity/capability where feasible without embedding a private key.
- Boot budgets separate secure-store/local-open from network refresh; no repeated
  client initialization, subscription leak or auth-driven full app rebuild.
- Auth changes announce once accessibly and restore focus to the first actionable
  control. No motion exposes password text or delays error recovery.
- Rollback preserves the existing secure-store alias, owner binding and local DB.
  If the new coordinator must be disabled, a compatibility adapter reads the last
  valid session; it never downgrades by clearing credentials or data automatically.

## Verification and required evidence

- Unit/state-machine tests cover every state/transition, refresh fan-out, clock skew,
  duplicate callback, malformed URI, wrong owner and secure-store failure.
- Supabase integration proves sign-in, enabled owner, disabled/foreign/anonymous
  rejection, password recovery and zero-row bootstrap without broad grants.
- Android and Windows runtime: configured/unconfigured, cold/warm start, offline
  start, refresh rotation, revoke, sign-out/re-sign-in, connection change and queued
  notification/widget/protocol route.
- Signed N→N+1 installs using identical identities preserve valid session, last owner,
  DB, outbox and settings; explicit sign-out still preserves data while redacting
  external surfaces.
- Source/build/APK/Windows ZIP/setup/log/feedback/backup scans contain no password,
  access/refresh/service-role/provider token or transport email where prohibited.
- Accepted-reference versus real-runtime side-by-sides cover all component/page,
  layout/theme/state variants; semantics, TalkBack/screen reader, keyboard, 200% text,
  RTL/mixed, IME and reduced-motion checks pass.

## Reject the stage if

- A password/token/service-role/provider key is compiled, logged, exported, passed in
  argv or stored in plaintext preferences/files.
- Offline start waits indefinitely for network, session expiry/sign-out deletes the
  planner DB, or a different UUID can attach to keyvan's namespace.
- A client can sign up/create an owner profile or an auth callback can bypass owner/
  nonce/project validation.
- Runtime work began before accepted previews/diagrams, or implementation differs
  materially from the accepted auth/session references without a documented adaptive
  rule and reopened internal design gate.
- A widget/notification continues displaying private data after explicit sign-out.

## Handoff and release

Stage 44 receives the SessionCoordinator API, owner context, auth/error taxonomy,
worker cancellation/resume rules and secure external-intent queue. Commit/push only
after CI, Supabase integration, real Android/Windows auth flows, secret scans and
signed upgrade proof pass; record remote configuration/deployment separately and
leave clean `main` only.
