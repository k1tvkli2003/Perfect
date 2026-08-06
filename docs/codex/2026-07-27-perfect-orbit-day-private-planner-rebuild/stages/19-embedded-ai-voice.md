# Stage 19 — Perfect AI and Voice embedded in the composer

Status: pending  
Depends on: Stages 17–18 and Stage 46 contract characterization  
Primary surfaces: AI conversation, voice capture and proposal review mode

## Mission

Remove the visual/product concept of a separate AI dock. AI and Voice are modes of
the same bottom instrument, with preserved drafts and one continuous spatial model.

## Mandatory preview and Copy entry gate

- Freeze all `ai-*`, `voice-recorder`, `cap-expanded-shell`, `cap-mode-actions` and
  `pg-capture-ai/voice/proposal-review` plus `pg-ai-*` composition IDs.
- Preview empty, conversation, streaming/thinking, listening/transcribing, long
  proposal, conflict, Apply/Reject, offline/provider error, IME, resize and reduced
  motion before touching presentation code.
- Decompose dynamic conversation/proposal/actions as live semantic UI; generated or
  authored art may supply identity/material only, never planner facts or Apply text.
- Compare reference/runtime pixels, scroll/focus order and morph recording; pair this
  with zero-write-before-Apply and no-client-secret characterization evidence.

## Composition states

1. AI empty: prompt field plus a few high-value starter intentions, not generic
   chat decoration.
2. AI sending: stable conversation area, bounded thinking feedback and cancel.
3. AI response: concise answer plus any structured proposal.
4. Proposal: readable diff/items, conflicts, Dismiss and explicit Apply.
5. Voice consent: explain private bounded recording before microphone begins.
6. Recording: waveform/level, duration, stop and cancel within same shell.
7. Voice ready/transcribing/error: playback/delete/send or retry without losing text.

## Mode behavior

- AI selection morphs the composer; Task/Plan controls are not left visible below.
- Closing AI returns to prior mode/draft and restores appropriate focus.
- Voice entered from the mode row opens AI mode directly into consent/record state.
- Conversation and proposal survive benign resize/page rebuild; consequential writes
  never happen merely because a proposal is displayed.
- Escape/back first dismisses IME/voice transient, then AI mode, then composer.

## Visual/interaction craft

- Use the dedicated Perfect AI SVG; no generic sparkle/robot icon as sole identity.
- The expanded surface remains connected to its launcher position and uses authored
  glass/shape transitions, not a full-screen chat clone on phone.
- Long conversation scroll and composer stay reachable under IME; proposal actions
  never hide below footer or keyboard.
- Tablet/Windows may widen/show context rail only when enough space remains for
  readable conversation; no permanent empty sidebar.

## Security/function boundary

This stage may restructure presentation/state only against an existing typed client.
It must not move secrets/provider calls into Flutter or bypass review/apply. Stage 46
and 47 later certify the server contract and writes.

## Edge scenarios

Permission denied, no microphone, app background during recording, 45s limit,
network timeout, malformed proposal, history unavailable, resize, RTL prompt,
provider cancellation and proposal retained after retry.

## Verification

One visible-surface assertion; Task/AI/Voice draft retention; permission/recording/
cancel tests; IME and scroll reachability; no-secret scan; golden/recording matrix;
reduced motion and semantics/focus order.

## Reject if

- AI remains a separate box stacked above Quick Capture.
- Voice shortcut merely opens unrelated text UI or starts without consent.
- Apply is possible without a clear review boundary.

## Handoff

Stage 20 receives complete composer states for performance hardening. Commit/push/
release with deterministic AI/voice UI tests and clean Git.
