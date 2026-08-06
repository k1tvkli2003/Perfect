# Stage 46 — Secure Perfect AI conversation contract

Status: pending  
Depends on: Stages 01, 05, 19 and 41–45  
Blocks: Stages 47, 49 and 50  
Primary surfaces: embedded AI/Voice composer, Supabase `perfect-agent`, owner-scoped
context RPCs, conversation history, server model configuration and diagnostics

## Mission

Turn Perfect AI into a private, bounded planning adviser whose text and voice turns
are useful in Persian or English but never become authorization. The app may send an
authenticated request and display a typed response or proposal; it must never embed
a provider key, execute model-authored SQL/tool arguments, or mutate the planner
because a response arrived.

The title is not a scope boundary. Changes to the AI contract must be traced through
the composer, local data, sync, widget, detail/edit surfaces, diagnostics, packaging
and upgrade behavior that consume AI state.

## Autonomous decisions

- Use the server-selected `gemini-flash-lite-latest` model family. The provider
  secret and endpoint live only in Supabase Edge Function secrets; Flutter receives
  only safe telemetry such as the resolved model ID, prompt version and request ID.
- Keep model selection in one server registry with a startup/deploy preflight. The
  alias may move, so record its resolved model in every turn and fail closed when its
  structured-output/tool contract changes; never silently fall back to another
  model family.
- Keep the existing authenticated Edge Function boundary. Every request is tied to
  the verified Supabase user and every context query relies on owner-scoped RLS/RPC,
  not an owner ID supplied by Flutter or the model.
- Treat planner context as typed untrusted data. Serialize only allowlisted fields,
  bound row/byte/token counts, label it as data, and neutralize delimiter/control
  injection before it enters a prompt.
- Support text and consent-first voice in the same embedded composer. Voice is a
  transient input transport, not permission to apply a proposal; retain the current
  45-second/5 MiB ceiling unless recorded device evidence justifies a smaller cap.
- Model output is either conversational text or a versioned proposal envelope.
  Unknown fields, kinds, schema versions or tool names are rejected. Raw SQL,
  arbitrary RPC names, URLs, shell/code execution and unrestricted tool arguments
  are never accepted.
- Do not auto-send an offline prompt later. Preserve the local draft/voice-ready
  state and let the owner retry deliberately against then-current planner context.

## Accepted preview and Copy-fidelity gate

No Flutter, native, Edge Function or schema implementation begins until this stage
extends the accepted Stage 03 direction and Stage 04–05 systems with an internally accepted,
high-craft preview pack. Produce it in this order: `modernize` explores and records the
KEEP/REFINE/REDESIGN/REMOVE/ADD opinion ledger; `integrity` maps every state/source of
truth and adjacent consumer; `anatomy` fixes hierarchy, reading order, action placement
and compact/medium/expanded transformations; `style` finalizes Day Compass tokens,
assets, typography, theme and motion; only then does `copy` turn the accepted images
and animatics into the binding implementation reference.

Preview every component individually—AI launcher/mode control, prompt, Send/Cancel,
mic consent, recorder, waveform/timer, transcription, conversation turn, thinking,
refusal, retry, context/privacy cue, proposal summary and disabled Apply—and every
page/composer composition. Cover empty, typing, sending, streaming/thinking,
cancelled, text response, voice-ready/transcribing, permission denied, offline, rate
limited, timeout, malformed/security refusal and auth-expired states in light, dark,
high contrast and reduced motion at all Stage 05 phone/tablet/Windows layout classes,
including IME, RTL, mixed text and 200% scale.

For each preview record exact viewport/state, live copy, component bounds/alignment,
spacing/type/color/radius/elevation tokens, asset source, crop/z-order, semantics,
focus order and motion frames (first/mid/end/reversal/reduced). Create a preview-to-
production decomposition manifest classifying raster, vector, live semantic and hybrid
layers; decision-critical text and controls stay live. Stage implementation may start
only after recorded internal acceptance and a frozen preview manifest/hash. Material
deviation requires a new preview and reopened autonomous design gate, never a
convenient generic substitute.

## Work packets

1. **Freeze and characterize the current boundary.** Inventory
   `perfect_ai_contract.dart`, `perfect_ai_client.dart`, `perfect_ai_dock.dart`, the
   `perfect-agent` function, conversation/audit migrations, context RPC and schema
   examples. Capture request/response fixtures and current error mapping before
   changing them.
2. **Publish a versioned transport contract.** Define maximum body sizes and a
   discriminated request for `chat`, `cancel` and proposal retrieval. Require
   `schema_version`, UUID `operation_id`, optional UUID `conversation_id`, bounded
   history and exactly one usable text/voice input. Define response message,
   transcription, proposal, context revision and safe telemetry fields; reject
   unknown major versions before rendering.
3. **Centralize provider configuration.** Move model alias, provider base URL,
   timeout and prompt/schema versions behind a typed server configuration module.
   Validate configuration without logging values, exercise it with a non-secret
   smoke value first, and keep all provider credentials out of source, build assets,
   command argv, crash reports and Flutter runtime configuration.
4. **Authenticate and authorize every turn.** Verify the bearer session server-side,
   derive the owner from the verified token, reject expired/revoked/wrong-audience
   tokens, apply a per-owner/per-install bounded rate policy and never trust a client
   `owner_id`. Return the same non-enumerating authorization error for foreign IDs.
5. **Build the schema-aware context assembler.** Read Tasks, recurring Tasks,
   Habits and occurrences, Notes, schedules, Projects, Areas, Goals and relevant
   conflicts through bounded owner-scoped projections. Include stable IDs, revision,
   timezone and schema version; omit secrets, auth metadata, deleted bodies and
   unrelated diagnostic/feedback content. Prefer a compact horizon plus explicit
   summaries over dumping the full database.
6. **Harden prompt and tool isolation.** Keep system policy and planner JSON in
   separate roles/parts, escape structural delimiters, state that stored strings are
   data, and expose only the one proposal-schema tool. Adversarially seed titles and
   notes with fake system prompts, SQL, URLs and cross-owner requests; they may be
   discussed as text but cannot alter authorization or tool availability.
7. **Validate output twice.** Require provider structured output/tool calling, then
   independently validate JSON type, sizes, enum/action allowlist, IDs, dates,
   timezone, relationships and proposal limits on the server. Flutter performs the
   same major-version and bounds validation before showing anything. Neither layer
   executes the proposal in this stage.
8. **Make conversation persistence idempotent.** Use `operation_id` to deduplicate a
   retried turn, store user/assistant messages in owner-scoped history once, retain a
   pending proposal without applying it, and make cancellation suppress late UI
   delivery without corrupting server history. Record prompt/model/schema versions,
   latency and bounded usage, not hidden reasoning or provider secrets.
9. **Complete the voice privacy lifecycle.** Ask before microphone access, show the
   recording limit, keep cancel/delete available, upload only after explicit Send,
   reject unexpected MIME/size/duration, and delete transient audio after
   transcription or failed/cancelled retention expiry. Persist transcript only when
   it becomes part of the submitted conversation.
10. **Ship stable failure semantics.** Map unauthenticated, invalid input, too large,
    rate limited, context unavailable, provider refused, timeout, malformed response
    and service unavailable to typed retryable/non-retryable errors. Provide bounded
    timeout and jittered retry guidance; never loop automatically or erase the draft.
11. **Add privacy-safe observability.** Correlate client operation, Edge Function and
    provider request IDs while redacting message/context/audio. Metrics cover success,
    refusal, contract rejection, timeout, rate limit, latency and resolved model. A
    diagnostic export contains no bearer token, provider key or planner body.

## UI/UX and motion contract

- Preserve the Stage 19 embedded composer/dock morph: conversation, thinking,
  response, proposal, voice consent, recording, transcription and error are states
  of one instrument, not a detached chat application.
- Display an immediate local sending state, a bounded progress label and Cancel.
  A late response after cancel may be recoverable from history but must not steal
  focus or reopen the surface.
- Friendly Persian is the default when the owner writes Persian; match English or
  mixed-script input without translating IDs, dates or user-authored text
  unexpectedly. Copy must distinguish “prepared a proposal” from “saved”.
- Voice motion communicates recording and transcription without decorative noise.
  Reduced motion replaces waveform/shape morphs with static level/time/status
  changes. Errors keep the text draft and locally retained unsent clip reachable.
- A proposal preview can appear, but Apply remains disabled until Stage 47 supplies
  a verified diff/apply coordinator. No arrival, animation end, Enter key or voice
  acknowledgement can confirm it.

## Responsive and device behavior

- **Android phone:** keep prompt, Send/Cancel, mic state and proposal summary above
  safe area and IME at 320dp and short landscape; conversation owns a bounded scroll
  region and no primary action sits behind the keyboard.
- **Android tablet:** widen readable conversation and optionally expose a context
  summary only when both panes retain useful width; collapsed/expanded rail changes
  preserve conversation, voice state, scroll and focus.
- **Windows compact/expanded:** use intrinsic action rows at 720x540 and an adjacent
  review/context region only at a content-driven breakpoint. Support Tab order,
  Enter-to-send, Shift+Enter newline, Escape cancel/dismiss and visible focus rings.
- Rotation, resize, route change, app background/resume and theme/text-scale change
  preserve draft, conversation ID, pending proposal and scroll. Recording follows
  the explicit Stage 19 background policy and never continues invisibly.

## Domain, security and data contracts

- Request identity is `(owner_from_token, operation_id)`; conversation and message
  IDs are UUIDs and RLS-protected. The same operation retry yields the same logical
  turn, not a duplicate message or proposal.
- Every context item carries `entity_kind`, stable ID, revision and only the typed
  fields required for planning. Context snapshot revision/timezone are returned in
  the proposal envelope so Stage 47 can detect staleness before Apply.
- A proposal includes contract/schema version, immutable submission ID, title,
  summary, ordered allowlisted actions, expected entity revisions and a server-side
  canonical hash/signature or equivalent tamper-evident reference. It always has
  `requires_confirmation: true`.
- Server/provider failures produce zero planner writes. Conversation history and
  audit tables are separate from canonical planner entities and operation queue.
- Supabase service-role/provider credentials are server-only. The Edge Function may
  use privileged credentials only for narrowly defined server work; owner data reads
  and writes still prove the authenticated owner and must not bypass RLS casually.

## Offline, errors and retries

- Offline AI opens with cached history and retained local draft plus an explicit
  “connection needed” state. Existing proposals remain reviewable; new generation
  is not faked and no stale prompt is silently queued.
- Retry reuses the logical operation only when the server can return/deduplicate the
  same result; a deliberate regenerate uses a new operation ID and current context.
- Timeouts, 429 and 5xx use capped exponential backoff guidance with jitter and a
  visible next action. Auth expiry routes through session recovery without deleting
  AI drafts, local planner data or conversation cache.
- Malformed/refused output becomes a safe conversational error with zero proposal.
  A context failure cannot downgrade into context-free planner writes.

## Accessibility and performance

- All icon-only AI/voice controls have semantic labels, states and minimum project
  hit targets. Recording time, sending, refusal, retry and proposal availability are
  announced without relying on color or animation.
- Long Persian/English copy reflows at 200% without hiding Send, Cancel, Delete clip
  or Review. Focus remains in logical reading order across morphs and validation
  errors are linked to the affected input.
- Context construction is bounded/paginated and does not run on the Flutter UI
  isolate. Conversation hydration is incremental; rebuilding one message must not
  rebuild the entire workspace. Record payload bytes, tokens and p50/p95 latency.
- The stage adopts the Stage 05 budgets; any synchronous frame over budget, unbounded
  history/context query or secret-bearing diagnostic is a release blocker.

## Verification and required evidence

1. Contract fixtures for text, voice and proposal round-trip in Dart and Edge tests;
   unknown schema/field/kind, oversize body, invalid MIME, duplicate operation and
   malformed provider output all fail deterministically.
2. Authorization matrix with valid owner, missing/expired/revoked token, forged
   owner field, foreign conversation/entity and prompt-injected owner ID. Foreign
   cases return zero data and zero writes.
3. Prompt-injection corpus embedded in task/note/title/context strings proves no
   extra tool, SQL, URL fetch, secret disclosure or authorization change occurs.
4. Failure harness covers refusal, 429, provider 4xx/5xx, context RPC error, timeout,
   cancellation and late completion; the draft/proposal/history invariants hold.
5. Voice tests cover consent deny/allow, 0/45/>45 seconds, wrong MIME, >5 MiB,
   background, cancel, retry and transient-audio cleanup.
6. Runtime screenshots/recordings cover phone portrait/landscape with IME, tablet
   rail states, Windows compact/expanded, Persian/English/mixed copy, 200% text,
   dark/high contrast and reduced motion.
7. Run focused Dart/Edge tests, full `flutter analyze`, the Stage 05 harness and an
   APK/Windows artifact secret scan. A live provider smoke run is permitted only
   through deployed server secrets with a valid rotated key; record resolved model,
   request ID, latency and redacted result, never the key or prompt body.
8. Store request/response fixtures, redacted Edge logs, screenshots and the exact
   candidate SHA in the stage evidence folder. Label simulations as fixtures, not
   live Supabase/provider proof.
9. Before the first runtime edit, verify the accepted AI component/page preview pack,
   autonomous acceptance record, opinion/integrity/precision ledgers, decomposition manifest and
   motion storyboard exist. After implementation, produce normalized preview ↔ fresh
   runtime side-by-sides at the exact viewport/state plus motion/behavior traces; log
   and repair every component-, geometry-, copy-, asset-, state- or timing mismatch.

## Reject the stage if

- Any provider key, bearer token or service credential is present in Flutter,
  packaged assets, source fixtures, command argv, logs or diagnostics.
- The client/model can select arbitrary owner IDs, RPCs, tools, SQL or URLs.
- Planner-context injection changes policy or a foreign-entity probe returns data.
- A proposal can be applied, auto-applied or represented as saved in this stage.
- Offline/retry/cancel duplicates a conversation turn or loses the owner's draft.
- Voice starts without consent, survives deletion unexpectedly, or hides a required
  action under IME/200% text.
- Any runtime implementation preceded the accepted Stage 03–05-derived preview pack,
  or any AI/security/error state uses an unapproved placeholder or “same vibe” UI.

## Whole-product propagation

Trace contract/model/error changes through Today and its composer, Tasks, Plan,
Habits, Goals, Projects, Areas, Notes and Focus context; Task/Habit detail and edit;
Quick Capture and full wizards; local AI cache, Supabase history/RLS/realtime,
conflict/diagnostic/feedback export, sync cloud state, widget/deep-link refresh,
auth expiry, backup/export/import, themes, accessibility and N→N+1 migration. AI
unavailability must never block or alter any non-AI planner workflow.

## Handoff and release

Stage 47 receives the frozen schema, context revision rules, proposal envelope,
allowlist seam, idempotency semantics and redacted fixtures. Record server deployment
version and any live-smoke limitation honestly. If runtime/server behavior changed,
commit and push the focused changes to `main`, pass CI, publish the required signed
artifacts under the normal private-release contract, install them on Android and
Windows, and leave no untracked credential or extra branch.
