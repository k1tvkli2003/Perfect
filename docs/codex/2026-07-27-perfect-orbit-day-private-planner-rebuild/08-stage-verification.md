# Stage 08 verification — glass header, sync confidence and dual date/time

Date: 2026-08-12
Stage: `08-glass-header-sync-date`
Status: local source and Android runtime gates passed; exact-SHA hosted Windows/release gate pending

## Outcome

Perfect! now owns time and database confidence as small, live, truthful instruments
instead of a heavy header band or decorative cloud. Phone keeps the authored
wordmark and compact Cloud in one bounded glass row; its greeting owns the live clock
and dual date. Tablet and Windows use a contextual glass header with page location,
local time, Gregorian/Solar-Hijri date and the same Cloud state without repeated copy.

The composition uses live constraints, intrinsic copy sizing and bounded semantic
tokens. It contains no negative translation, no full-width color banner and no fixed
preview date in production paths. Blur is bounded to the header surface and falls
back to a theme-aware opaque treatment for high contrast or unavailable blur.

## Time and calendar ownership

`PerfectLocalTime` is the single presentation boundary for Gregorian, Solar-Hijri,
clock and inspector copy. Its deterministic Jalali conversion is tested at Nowruz,
Gregorian leap and Jalali leap-Esfand boundaries. `PerfectMinuteClockBuilder` schedules
one update at the next minute boundary, realigns after every tick and app resume and
rebuilds only the clock subtree. Tests inject both time and scheduling.

| Consumer | Stored/transport truth | Display/input truth |
| --- | --- | --- |
| Drift/outbox/sync cursors | UTC ISO timestamps | device-local formatted time only at the UI edge |
| Today/Orbit/Plan/wizard | domain values + local date intent | centralized Gregorian/Jalali/12-hour copy |
| Android widget | durable projection fields | centralized local date/time labels |
| Feedback metadata | UTC event timestamps | local inspector timestamp in owner-visible copy |
| Perfect AI | server UTC plus validated client context | local date, local clock and UTC offset used only to resolve relative phrases |

The Edge Function accepts device time context only when UTC, local date, local clock
and offset are structurally valid and mutually consistent. It never trusts a guessed
timezone and the provider credential remains a Supabase secret, not a Flutter value.

## Sync confidence contract

The repository now publishes the actual `nextRetryAt` and retry attempt derived from
the bounded backoff scheduler. The Cloud keeps stable authored geometry while only a
small orbital signal moves during work. State truth is explicit:

- green: the durable queue is converged;
- yellow: syncing, offline retention or a bounded retry countdown;
- red: the last attempt failed, local work remains durable and retry is available.

Color is never the only signal. Semantics, tooltip and the adaptive details surface
name the state, last successful local time and safe action. Raw provider failures are
not rendered. Reduced motion freezes decorative travel without hiding state.

## Findings closed during side-by-side review

| Finding | Closure |
| --- | --- |
| Phone identity was positioned with a `Transform.translate(-20)` escape hatch | Header owns its actual measured height and inset; the transform was removed. |
| Wide Today repeated the same date below the global header | Contextual date remains in one authoritative wide header location. |
| Pull-to-refresh could restart sync on ordinary scroll | Both Today `RefreshIndicator` wrappers were removed; live repository updates remain subscribed. |
| System Night Mode screenshot stayed light because the development preview explicitly selected Light | Evidence was rejected; Dark was selected through the app's own Appearance control before capture. |
| The first tablet resize resumed a different foreground package | Evidence was rejected and overwritten only after `topResumedActivity` named the exact Perfect preview activity. |
| Scattered UI/widget/feedback time formatters could disagree at local midnight | All user-visible consumers now route through the central boundary; UTC persistence remains unchanged. |

## Verification executed

| Gate | Result |
| --- | --- |
| `dart format` on touched Dart | Pass. |
| `flutter analyze` | Pass, no issues. |
| Full Flutter suite, concurrency 1 | Pass, 421/421. |
| Workspace/header/sync focused suites | Pass, including light/dark/high-contrast/200% goldens and state matrix. |
| Deno format and type check | Pass for `supabase/functions/perfect-agent/index.ts`. |
| Android debug preview build | Pass, `perfect_live_preview.dart`, versionCode 2049. |
| Android in-place update | Pass; `firstInstallTime` remained `2026-08-02 19:20:44`. |
| Phone light/dark/200% runtime | Pass; required copy stays whole and no fatal/overflow signature matched. |
| Sync details runtime | Pass; local state, last completion and safe `Sync now` are reachable. |
| Tablet portrait/landscape runtime | Pass at logical 800×1280 and 1280×800 with compact rail and no overlap. |
| Local Windows compile | Not rerun because this host lacks ATL `atlbase.h`; hosted Windows gate remains mandatory. |
| Exact-SHA GitHub build/install-over/release | Pending Stage 08 merge/push. |

The first hosted attempt, run `#49` / `31628396176`, correctly blocked release:
Linux passed format/analyze and 411 non-Windows tests but differed from the two
new Windows-authored header pixel masters by 2.65% and 2.74%. Windows itself passed
the existing golden gate and the complete build/install-over path. The header matrix
goldens now use the repository's established `windows-golden` tag: Linux continues
to run all geometry, semantics and state assertions while Windows owns exact raster
comparison without weakening tolerance or rewriting platform-specific masters.
Run `#50` / `31635595502` then caught an unformatted tag-only follow-up before
analysis. The cause was local verification with `dart format --output=none`, which
reports drift but intentionally does not write it. The file is now written through
the formatter and checked again with the workflow's exact `lib test` command.

## Runtime evidence

Real running-app evidence is stored under
`design/05-runtime-comparisons/stage08/`:

- `android-phone/runtime-light.png`, `runtime-dark.png`, `runtime-200.png` and
  `runtime-sync-details.png` plus corresponding semantic dumps.
- `android-tablet/runtime-portrait.png` and `runtime-landscape.png` plus corresponding
  semantic dumps.

All accepted captures were made only after the Perfect preview activity was confirmed
foreground. The deterministic preview fixture proves composition and interaction, not
owner Supabase convergence or signed production-session continuity; those remain
separate later-stage gates.

## Hosted closure condition

Stage 08 closes only after its merged `main` SHA passes the trusted GitHub workflow,
Windows install-over preservation succeeds and the immutable release targets that
exact SHA with exactly three directly installable assets: Android APK, Windows
Portable ZIP and Windows Setup EXE.
