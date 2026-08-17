# Stage 11 preview / runtime mismatch ledger

Status: **closed — preview, Flutter, Android runtime and hosted Windows rows verified**

| Surface | Preview authority | Runtime result | Evidence / remaining boundary |
| --- | --- | --- | --- |
| Phone Today | **phone-density-matrix.png** | Closed: one bounded Pulse, no Orbit tree/semantics, no duplicated task title, three actionable rows in the first view | `runtime/android/phone-runtime.png` + fresh semantics XML; preview fixture only |
| Short landscape / 200% | **stress-responsive-matrix.png** | Flutter stress tests pass at 200%; live tablet landscape uses the wide three-column composition | physical short-landscape recording remains outside this emulator capture |
| Tablet / Windows | **adaptive-matrix.png** | Android portrait/landscape plus trusted Windows build/package closed; one Pulse sits above the dominant scrollable stream | exact-SHA run `31767013849` compiled, signed and packaged the Windows product; install-over preserved package family/LocalState |
| Theme / contrast | **theme-system-matrix.png** | Closed in source/goldens: Dayline resolves semantic roles; retired Orbit assets are deleted | Stage 10 theme verifier plus Stage 11 dark/high-contrast widget tests |
| Motion | **motion-storyboard.png** | Minute tick is isolated to Pulse; row identity/scroll stay stable; reduced motion resolves to zero-duration | physical frame-pacing is not claimed from the emulator |
| Geometry | **geometry-axis-board.png** | Phone/tablet axes remain aligned; scrolled final item ends at y=1318 and clears capture at y=1396 | bounds are locked in `runtime-manifest.json` |

## Android runtime checkpoint

- Preview APK `1.1.0-preview+2064` installed with `adb install -r -t` over build
  2063; `firstInstallTime=2026-08-02 19:20:44` remained unchanged.
- Final emulator state is reset to its physical `1080×2400 @ 420dpi` phone
  profile and the exact preview activity remains foregrounded.
- The clean launch log has zero `FATAL EXCEPTION`, app-process, `E/flutter`,
  `RenderFlex` or package ANR matches.
- Nine screenshots/semantic/log artifacts are hash-locked by
  `runtime/android/runtime-manifest.json`; the verifier rejects byte or semantic
  drift.
- Deterministic Alex/task content belongs only to `lib/dev/perfect_live_preview.dart`;
  it is not owner seed data and does not weaken the empty-account contract.

## Hosted Windows checkpoint

- Trusted `main` run `31767013849` passed on source SHA
  `59db6e479f34f25ecf66e4224b2d8c90c7f53941`; the Windows native build,
  portable bundle, signed MSIX and self-contained Setup were produced from that
  exact tree.
- MSIX install-over `1.1.0.58 → 1.1.0.60` retained package family and
  `LocalState`. Setup installed `1.1.0.60`, reran idempotently, preserved the
  same state and did not mutate Trusted Root.
- The local host remains ATL-limited, so this closes the hosted Windows row without
  retroactively claiming a local native compile or a physical Windows screenshot.
