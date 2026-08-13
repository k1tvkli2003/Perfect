# Stage 09 verification — global route and microinteraction motion

Date: 2026-08-13
Stage: `09-global-motion-system`
Status: source checkpoint externally closed on exact-SHA trusted run and release

## Outcome

Perfect! now uses motion as a small continuity language rather than a collection of
framework defaults. Route direction, page orientation, overlays, editor steps,
selection, capture, AI, Sync and status feedback share named timing and optical
travel. Motion never owns planner truth: local mutation, authorization, sync and
error state continue independently and controls remain interactive as soon as they
are visible.

## Vocabulary and ownership

| Role | Forward / reverse | Spatial contract | Main consumers |
| --- | --- | --- | --- |
| micro | 90 / 90ms | press acknowledgement only | pointer and keyboard feedback |
| quick | 140 / 140ms | fixed-geometry selection/cue | footer, rail, menus, chips |
| standard | 240 / 140ms | local color/shape/height hand-off | fields, status, compact state |
| emphasized | 320 / 240ms | 10px title rise or bounded morph | titles, capture, AI |
| modal | 360 / 240ms | 12px rise + `.96→1` invoker scale | dialogs and sheets |
| route | 380 / 240ms | Navigator 14px; workspace cue 8px | full routes and wizard |
| feedback | 600 / 240ms | bounded receipt only | completion/log acknowledgement |

`MediaQuery.disableAnimations` resolves spatial durations to zero at runtime.
Information, focus, final geometry and semantic state remain present. Reduced motion
is tested dynamically while a dialog is open, not only at initial build.

## Route, focus and state continuity

The workspace uses one persistent destination host. Today, Tasks, Plan, Habits and
More retain scroll, filters, drafts, selection and child state while offstage, but
offstage destinations cannot paint, tick, receive focus, hit tests or semantics.
Rapid destination changes retarget one 140ms edge cue; no whole-page fractional
opacity or transform allocates a viewport saveLayer.

Every production `showDialog` call was migrated to `showPerfectDialog`. Its origin is
the invoking control where geometry is available, focus traversal is closed-loop,
the outgoing route becomes inert through Navigator ownership and the invoker regains
focus on close. Bottom sheets and menus provide explicit `AnimationStyle`; Stage 09
tests reject raw presentation durations, external curves and stock overlay entry.

## Lifecycle and resource discipline

- Quick Capture heartbeat is disabled while expanded, reduced, offstage or in the
  background and resumes only after a rest interval.
- Sync orbit pauses in the background and resumes from current repository state.
- Orbit pulse/clock controllers are lifecycle-aware and do not tick offstage.
- Page titles animate once per meaningful entry generation; notifier, sync and list
  rebuilds do not replay them.
- Repaint boundaries isolate staged titles, selected navigation glyphs, page content
  and the route edge cue. Retained offstage pages do not paint.

## Deterministic design evidence

`design/01-foundations/stage09-motion/` contains:

- 11 role storyboards at 1200×720 in SVG and PNG;
- first, mid, end, reverse, interrupted and reduced frames for every role;
- focus, background and resource budgets for every role;
- a generated 131-record implementation inventory;
- 24 exact hashed design files;
- a real Android profile screenshot, semantics dump, motion recording, memory dump,
  two navigation timing captures, two drained idle captures and a minimal renderer
  control; all nine runtime artifacts are hash-verified.

The independent verifier reports:

`Stage 09 motion evidence PASS: 11 roles, 131 implementation records, 24 hashed design files, 9 hashed runtime artifacts.`

## Android runtime evidence

The final runtime is profile build `1.1.0+2060`, isolated as
`com.k1tvkli2003.perfect.preview`. It was installed with `adb install -r`; versionCode
advanced from 2059 to 2060 while `firstInstallTime=2026-08-02 19:20:44` remained
unchanged. The confirmed foreground activity was
`com.k1tvkli2003.perfect.preview/com.k1tvkli2003.perfect.MainActivity`.

| Capture | Samples | Build p50 / p95 / max | Raster p50 / p95 / max | Interpretation |
| --- | ---: | --- | --- | --- |
| Tasks→Plan | 38 | 1.091 / 3.250 / 9.659ms | 28.595 / 35.850 / 36.846ms | UI thread passes 60Hz budget; emulator raster does not |
| Plan→Habits | 15 | 0.949 / 1.539 / 1.539ms | 27.373 / 40.103 / 40.103ms | UI thread passes; emulator raster remains slow |
| Minimal same-package control | 12 | 0.720 / 2.316 / 2.316ms | 18.124 / 32.503 / 32.503ms | host renderer itself exceeds 16.67ms |

The minimal control is a nearly empty profile surface with a four-pixel animated
line. Its raster floor proves this emulator/`skiagl` path cannot certify physical
device smoothness. The accepted claim is deliberately narrower: no sampled real
workspace build frame exceeded 16.67ms, and two drained six-second idle windows
contained one and zero frames respectively—no sustained idle/offstage ticker.

Final memory evidence reports total PSS 156,194KiB and total RSS 253,124KiB after
navigation. This is a diagnostic snapshot, not a cross-device budget certification.
System animation scales were enabled only during capture and restored to `0/0/0`.

Accepted runtime artifacts include:

- `android-profile-navigation-final.png` — 385,084 bytes —
  `sha256:5d839197cc3c94e298ad3701b05636423cb761d7949e123cb3229091af926982`;
- `android-profile-motion.mp4` — 2,040,422 bytes —
  `sha256:d2e5f5f1cc54938bba128fc78ce129c63069731c66d72b6b361329b5eaa3ee73`.

The disposable local APK is 95,124,824 bytes with
`sha256:99ff955dd11fa06a16935e7609e026b69971a9d96c43effcf4c809f962e13e09`.
It is profile evidence, not a distributable signed release.

## Verification executed

| Gate | Result | Evidence / limit |
| --- | --- | --- |
| Dart formatting and `git diff --check` | pass | touched Dart formatted; no whitespace error |
| `flutter analyze` | pass | no issues across the complete project |
| Full Flutter suite | pass, 432/432 | AI, auth, persistence, sync, planner, UI, release and widget contracts included |
| Stage 09 + motion contracts | pass, 19/19 | tokens, route retarget, focus, lifecycle, evidence and source scan |
| Workspace regression | pass, 60/60 | phone/tablet/Windows, RTL, 200%, wizard, detail and input paths |
| Header + Sync regression | pass, 10/10 | light/dark/high-contrast/200%, retry and reduced motion |
| Evidence generator/verifier | pass | 11 storyboards, 131 records, 24 design + 9 runtime hashes |
| Android profile build/install-over | pass | `1.1.0+2060`, in-place preview continuity preserved |
| Real Android screenshot/recording | pass | exact foreground package; current final source composition |
| Local Windows release build | blocked by host | missing ATL `atlbase.h` in `flutter_local_notifications_windows`; hosted runner mandatory |
| Physical Android no-jank | open | emulator renderer control is too slow for an absolute raster claim |
| Hosted Windows install-over/release | pass | exact source SHA passed signed Windows build, MSIX/Setup update proofs and three-asset release |
| Physical Windows no-jank | open | hosted compilation and package execution do not substitute for frame timing on target hardware |

## Hosted closure proof

Source checkpoint `6ca824ef2f0dd0b3facd66c194668381e81b88d1` passed manually
dispatched branch run
[`31663309577`](https://github.com/k1tvkli2003/Perfect/actions/runs/31663309577)
attempt 2. Attempt 1 passed format, analysis and all 432 tests, then the Android step
received `Unexpected end of file from server` while downloading the official Gradle
wrapper. Retrying only failed jobs on the unchanged SHA passed Android build,
checksum and artifact upload; the Windows portable job had already passed.

After fast-forward to `main`, trusted run
[`#54` / `31664886708`](https://github.com/k1tvkli2003/Perfect/actions/runs/31664886708)
passed all four jobs. Windows MSIX install-over advanced `1.1.0.52 → 1.1.0.54`
while preserving package family and LocalState. Setup clean-install and its second,
idempotent invocation both passed without mutating Root. Android signing, package
verification, checksum and upload also passed.

Immutable release
[`v1.1.0-build.2054`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2054)
and its tag target the exact source commit. GitHub reports exactly three assets:

- `Perfect-1.1.0-build.2054-Android.apk` — 73,672,339 bytes —
  `sha256:1b59536d7c06b7c48994b4ba96a5656a09ec81d6d3ce885f5c6b900c01cb6f31`;
- `Perfect-1.1.0-build.2054-Windows-Portable.zip` — 17,646,412 bytes —
  `sha256:976f7fd39c4c20671510503f957a478f7d28c635cae7b2d6175b8c2c653fac8a`;
- `Perfect-1.1.0-build.2054-Windows-Setup.exe` — 25,008,984 bytes —
  `sha256:a8fbb3f4f1f3131cf8b270bb5aba8830c833ba04592de86cb88b388782189b1e`.

This closes source, packaging and update continuity for Stage 09. Physical Android
and Windows frame-jank remain open unless measured on those actual targets; hosted
compilation cannot substitute.
