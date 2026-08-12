# Stage 07 verification — adaptive navigation shell

Date: 2026-08-12
Stage: `07-adaptive-navigation-shell`
Status: complete; local, Android runtime and exact-SHA hosted Windows/release gates passed

## Outcome

Perfect! now uses one state-retaining shell that recomposes for Android phone,
Android tablet and Windows instead of rebuilding each destination at every route or
breakpoint change. Today, Tasks, Plan, Habits and More remain mounted behind a
semantic/focus-safe page host, so filters, selected dates, scroll position and draft
controllers survive navigation and live resize.

- Phone keeps the floating icon-only footer and Today-only capture instrument.
- Android tablet defaults to a compact rail even when the content earns the expanded
  shell; the owner can expand it without overlap.
- Windows restores the saved rail-width preference and keeps Ctrl+1…5 plus local
  arrow/Home/End navigation.
- The expanded desktop shell can promote selected detail into a bounded third pane;
  its 48dp divider supports drag, focus, keyboard resizing and semantics.
- Page changes use direction-aware shared-axis motion and title rise; reduced motion
  retains state while removing travel.
- Quick Capture remains Today-scoped, keeps its controller through page changes and
  does not summon the IME when its toggle alone is opened.

## Frozen preview and Copy binding

Implementation was checked against the Stage 04 component IDs `sh-page-canvas`,
`sh-phone-footer`, `sh-footer-destination`, `sh-tablet-rail`, `sh-windows-rail`,
`sh-rail-toggle`, `sh-page-scroll-frame` and `sh-pane-divider`, plus the Stage 05
`pg-shell-*` phone/tablet/Windows compositions.

The shell uses live constraints rather than device labels: the semantic content
threshold is 680dp, while the expanded shell is earned only at 1224dp
(`1040dp` useful content + `184dp` bounded chrome). Large text shifts internal
composition instead of shrinking copy or clipping actions. Android platform behavior
is selected independently from width so a wide tablet does not impersonate Windows.

## Adversarial findings closed

| Finding | Closure evidence |
| --- | --- |
| Keyboard actions existed outside their focus scope | Focus/Shortcuts ancestry was corrected; footer and rail now handle local arrows, Home and End. |
| Destination widgets were recreated on every switch | A persistent keyed host retains all five destinations while hidden pages disable pointer, semantics, tickers and focus. |
| 320dp at 200% text clipped `Today’s rhythm` | The compact Compass summary now reflows its title and detail without hiding the primary phrase. |
| 800dp portrait stretched a tiny Compass through a giant empty pane | Medium Today now uses one reading column and bounds the Compass by useful content height. |
| 1280dp Android tablet inherited the Windows expanded rail | Platform-aware expanded-shell navigation now keeps the Android rail compact by default. |
| Windows golden tests silently ran with Flutter Test's Android platform | Windows-specific tests now set `TargetPlatform.windows`; unchanged Windows masters pass again. |
| Source-contract tests depended on checkout line endings | SQL contract reads normalize CRLF/LF before semantic assertions. |

## Verification executed

| Gate | Result |
| --- | --- |
| `dart format` on every touched Dart file | Pass; no remaining formatter drift. |
| `flutter analyze` | Pass; no issues. |
| Full Flutter suite, concurrency 1 | Pass, 404/404. |
| Workspace focused suite | Pass, 60/60 including all shell goldens. |
| Orbit/large-text focused suite | Pass, including 260×220 and 320dp at 200% text. |
| Android debug preview build | Pass, `perfect_live_preview.dart`, versionCode 2048. |
| Android in-place preview update | Pass; `firstInstallTime` remained `2026-08-02 19:20:44`, so no uninstall/reset occurred. |
| Android phone runtime | Pass; normal and 200% captures inspected, primary phrases remain whole and no fatal/overflow log matched. |
| Android tablet portrait runtime | Pass; before/after evidence shows removal of the dead middle pane; scrolled end keeps final stream content reachable. |
| Android tablet landscape runtime | Pass at logical 1280×800; compact and expanded rails inspected with no overlap. |
| Quick Capture / IME runtime | Pass; expanded capture screenshot recorded while `mInputShown=false`. |
| Local Windows compile | Not rerun; this host still lacks ATL `atlbase.h`. Windows source and all Windows golden/interaction contracts pass locally; trusted hosted build remains mandatory. |
| Exact-SHA GitHub build, install-over and three-asset release | Pass; run `#48` / `31549435764` succeeded for exact commit `004c2567e67efc888f767b39333fb23a4a55bcbb`. Release `v1.1.0-build.2048` targets that SHA and contains exactly APK, Portable ZIP and Setup EXE. |

## Runtime evidence

Real running-app evidence is stored under
`design/05-runtime-comparisons/stage07/`:

- `android-phone/runtime-normal.png`, `runtime-200.png` and
  `runtime-final-restored.png`.
- `android-tablet-portrait/runtime-before-reflow.png`, `runtime.png` and
  `runtime-scrolled-end.png`.
- `android-tablet-landscape/runtime.png`, `runtime-rail-expanded.png` and
  `runtime-capture-open-no-ime.png`.
- Corresponding UIAutomator semantic dumps for actionable-bound inspection.

The deterministic preview fixture is development evidence, not proof of owner
Supabase convergence or signed production-session continuity. Those remain separate
later-stage gates.

## Hosted closure

Trusted workflow run [`#48`](https://github.com/k1tvkli2003/Perfect/actions/runs/31549435764)
passed every job for exact Stage 07 commit
`004c2567e67efc888f767b39333fb23a4a55bcbb`. Windows install-over preservation
passed and immutable release
[`v1.1.0-build.2048`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2048)
targets that SHA with exactly the Android APK, Windows Portable ZIP and Windows
Setup EXE. Stage 07 is externally closed.
