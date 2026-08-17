# Stage 11 verification — adaptive Today Pulse

Date: 2026-08-14
Stage: `11-today-pulse`
Status: complete — local Android runtime and exact-SHA hosted release passed

## Outcome

Perfect! no longer uses Orbit as the Today interaction or visual model. The
production surface is one adaptive Today Pulse above the actionable day stream:
local time, Gregorian/Jalali date, daily outcome, next temporal boundary, a
semantic Dayline and one Plan action. Task/habit titles, status mutation, identity
and scrolling remain owned by the stream.

The source checkpoint is
`59db6e479f34f25ecf66e4224b2d8c90c7f53941`
(`feat(today): replace Orbit with adaptive Today Pulse`). The exact tree passed
the branch and trusted-main gates and is published as the immutable three-asset
release
[`v1.1.0-build.2060`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2060).

## Retirement and implementation authority

- Production Orbit Dart source, five authored ring assets, its generator and the
  dedicated accessibility test are deleted.
- A source/asset/semantics regression contract prevents a hidden compatibility
  shell, Orbit label or dead asset family from returning.
- `lib/presentation/today_pulse.dart` owns the Pulse implementation. One injected
  minute-aligned tick updates time without replacing stream rows, scroll state or
  page ownership.
- Today suppresses the duplicate header clock, Plan command, next-up title and
  habit summary. No Pulse title is repeated immediately in the stream.

## Daily truth and state model

The immutable `TodayPulseSnapshot` projects task occurrences and habit-day
summaries instead of trusting generic entity lifecycle status. Therefore:

- a recurring task completed on another occurrence cannot masquerade as complete
  today;
- unresolved recurrence remains pending rather than inheriting stale completion;
- partial, missed, review-due, all-complete, habits-only, unscheduled-only,
  resolving and empty states remain distinguishable;
- next start, due and cross-midnight boundaries are calculated without adding a
  second task card to the Pulse.

Focused tests cover date/time vectors, daily projection, recurrence truth,
next-boundary selection, empty/complete/missed variants and stream ownership.

## Adaptive composition and runtime evidence

The accepted `today-pulse-dayline-v2` corpus has eight deterministic boards:
candidate rejection, semantic component states, phone density, 200%/short-height
stress, tablet/Windows adaptation, theme system, motion and measured geometry.
The implementation uses an intrinsic stacked compact composition on phone and
three bounded columns on tablet/Windows; sparse content is not stretched into an
empty dashboard panel.

Four fresh Android compositions were captured from the confirmed foreground
`.preview` package:

- physical `1080×2400 @ 420dpi` phone;
- tablet portrait;
- tablet landscape;
- tablet landscape scrolled to the final stream item.

The last visible item clears the capture/footer boundary, Inspector actions remain
reachable at short heights and the final launch log has no relevant
`FATAL EXCEPTION`, app-process failure, `E/flutter`, `RenderFlex` or package
ANR match. Nine PNG/XML/log artifacts are size/hash-locked by
`runtime/android/runtime-manifest.json`.

Preview build `1.1.0-preview+2064` installed with `adb install -r -t` over
2063. The command returned `Success` and
`firstInstallTime=2026-08-02 19:20:44` remained unchanged. The AVD was returned
to the canonical phone profile with the preview activity foregrounded.

## Verification executed

| Gate | Result | Evidence / limit |
| --- | --- | --- |
| Dart formatting and whitespace | pass | touched Dart formatted; source checkpoint passed `git diff --check` |
| Static analysis | pass | full `flutter analyze --no-pub`, no issues |
| Full Flutter suite | pass, 449/449 | projection, persistence, AI, sync, themes, motion, workspace, goldens and native contracts |
| Orbit retirement contract | pass | production source/assets/tree/semantics absence locked |
| Stage 10 runtime verifier | pass | inherited theme/native/runtime authority remains intact |
| Stage 11 verifier | pass | `boards=8 files=21 states=8 runtime=9` |
| Workspace goldens | pass | 14 refreshed phone/tablet/Windows/Inspector goldens inspected |
| Android debug build | pass | secret-free `.preview` APK build 2064 |
| Android install-over | pass | 2063→2064 with unchanged first-install time |
| Android visual/runtime | pass | phone/tablet portrait/landscape/scrolled evidence hash-locked |
| Local Windows build | host-blocked | optional ATL `atlbase.h` missing in `flutter_local_notifications_windows`; project runner was not linked |
| Branch exact-SHA gate | pass | run [`#59` / `31766137998`](https://github.com/k1tvkli2003/Perfect/actions/runs/31766137998) |
| Trusted main build/release | pass | run [`#60` / `31767013849`](https://github.com/k1tvkli2003/Perfect/actions/runs/31767013849), all four jobs |
| Windows MSIX install-over | pass | `1.1.0.58 → 1.1.0.60`; package family and `LocalState` preserved |
| Self-contained Windows Setup | pass | installed `1.1.0.60`, reran idempotently, retained state and did not mutate Trusted Root |
| Immutable three-asset release | pass | `v1.1.0-build.2060` targets the exact Stage 11 SHA |

## Exact-SHA hosted closure

Untrusted workflow-dispatch run
[`#59` / `31766137998`](https://github.com/k1tvkli2003/Perfect/actions/runs/31766137998)
completed successfully for the Stage 11 branch and exact source SHA. It compiled
and packaged Windows, ran the quality/Android path and correctly skipped
secret-dependent signing, install-over and publication.

The same SHA was fast-forwarded to trusted `main`. Push run
[`#60` / `31767013849`](https://github.com/k1tvkli2003/Perfect/actions/runs/31767013849)
completed all four jobs:

1. deterministic private build identity allocation;
2. Windows native build, portable package, signed MSIX, install-over/LocalState
   proof and self-contained Setup clean/idempotent proof;
3. formatting, analysis, 449-test suite, signed Android APK and checksum;
4. atomic publication and byte verification of exactly three release assets.

## Hosted artifact closure

Release `v1.1.0-build.2060` is published, non-draft and non-prerelease. Both its
`targetCommitish` and remote tag resolve directly to
`59db6e479f34f25ecf66e4224b2d8c90c7f53941`. It contains exactly:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `Perfect-1.1.0-build.2060-Android.apk` | 73,726,662 | `3cb71e3b099cd21f53114b1503d20a3122865a10178b53b1a126dddc389103ee` |
| `Perfect-1.1.0-build.2060-Windows-Portable.zip` | 17,645,354 | `9de4cd8e09094da3ddd41d1f9b1ebe8ff417fd54fc01002f0c32117383adeb4d` |
| `Perfect-1.1.0-build.2060-Windows-Setup.exe` | 25,007,720 | `3fa73e114b9d80c1e2123d0eeb23ad93cc4f845b9d81e1be1b19c9a6db0fc27c` |

There is no extra checksum, certificate, raw MSIX, nested archive or log in the
owner-facing release.

## Critics / Perfect closure ledger

Frozen findings before documentation repair:

1. Product-level Windows proof was missing locally because ATL was unavailable.
2. The implementation docs still described hosted Windows/release as open after
   the exact-SHA trusted run had closed it.
3. Stage cleanup could damage the owner's dirty `main` worktree if ordinary
   checkout/reset/merge commands were used.

Repairs and verification:

- Finding 1 is closed by exact-SHA trusted run `31767013849`; the local limit is
  retained rather than rewritten as a local success.
- Finding 2 is closed by this seven-file documentation packet with run, tag,
  artifact name, byte count and digest evidence.
- Finding 3 is guarded by an isolated worktree and pre-recorded hashes for every
  protected dirty file; cleanup must update the main ref/index without replacing
  those working files, then re-hash them.

The next highest-value move is structural rather than cosmetic: Stage 12 now
rebuilds Today information architecture around the closed Pulse/stream ownership
instead of reopening Stage 11 visuals.

## Honest boundaries

- Android install-over evidence belongs to the isolated secret-free preview
  package and synthetic fixture. It proves runtime/layout continuity but is not a
  claim that a signed-in production Android owner session was exercised in this
  exact build.
- Windows signing, install-over and Setup continuity are authoritative hosted
  product proofs. They do not claim a physical screenshot from the owner's own
  Windows desktop.
- The local Windows ATL limitation remains an environment fact, not a product
  regression.
- Synthetic Alex/task fixtures exist only in
  `lib/dev/perfect_live_preview.dart`; production owner data remains empty unless
  the owner or agent deliberately writes it.

## Handoff boundary

Stage 12 may consume the Pulse height/content axis, daily projection outputs,
stream ownership and semantic theme/motion roles. It must not reintroduce Orbit,
duplicate task truth, seed production owner data or turn the reclaimed area into
generic metric cards. The documentation-only closure commit must first pass its
own trusted exact-SHA workflow, after which the Stage 11 branch/worktree can be
removed without touching the owner's dirty `main` files or existing stash.
