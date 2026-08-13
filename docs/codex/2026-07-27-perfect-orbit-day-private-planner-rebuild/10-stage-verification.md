# Stage 10 verification — authored theme and contrast system

Date: 2026-08-13
Stage: `10-theme-contrast-system`
Status: local source, design, tests and Android runtime passed; hosted exact-SHA closure pending

## Outcome

Perfect! now treats Daylight, Graphite Bloom, Clarity Light and Clarity Dark as
four authored products. The implementation does not invert one light palette at
runtime. Every reusable Flutter surface consumes semantic roles, the owner can
select theme and contrast independently, the preference survives normal state
restoration, and the effective appearance is projected to Android and Windows.

## Theme registry and ownership

| Stable ID | Environment | Contrast | Authored behavior |
| --- | --- | --- | --- |
| `theme-light-daylight` | light | standard | warm paper canvas, pastel instrument surfaces, dark ink |
| `theme-dark-graphite-bloom` | dark | standard | graphite spatial layers, luminous pastel accents, restrained bloom |
| `theme-hc-light-clarity` | light | high | near-white canvas, stronger ink/boundaries, zero glass blur |
| `theme-hc-dark-clarity` | dark | high | black canvas, white hierarchy/boundaries, zero glass blur |

`PerfectSemanticTheme`, `PerfectSurfaceTheme` and `ColorScheme` jointly own the
roles. Reusable UI outside `perfect_theme.dart` is source-scanned for direct
`PerfectColors`, white/black constants and raw ARGB values; the accepted count is
zero. Fixed geometry tokens remain fixed where semantic size matters, while color,
surface, focus, status, scrim and interaction ink remain theme-owned.

## Contrast and authored graphics

- The generated registry freezes three inherited foundations, 181 components,
  134 pages and their 1,481 theme/layout variants.
- The contrast report measures 76 exact foreground/background pairs. Standard
  text meets at least 4.5:1, Clarity text at least 7:1 where required and
  non-text/focus boundaries at least 3:1.
- Clarity removes backdrop blur instead of applying muddy translucent layers.
- Orbit has dedicated Clarity light/dark SVG ring variants. Its curved period
  labels remain live semantic Flutter text; light themes use container ink and
  dark themes use filled-action ink so labels do not disappear into pastel arcs.
- Android widget identity has 40 density/theme-specific mark and wordmark rasters,
  16 status vectors and four surface resources. Quick Add consumes the same
  native appearance projection.

## State and native projection

Theme and contrast controls are independent segmented controls with no redundant
selected checkmark. A tested appearance switch preserves route, selected
destination, scroll, focused field, private draft and running workspace state.
`PerfectSystemAppearanceProjection` deduplicates native MethodChannel updates.

Android persists theme ID and high-contrast intent, updates application night mode
and refreshes widget projections. Windows receives dark/high-contrast/canvas/ink/
outline roles and applies immersive title-bar, caption, text and border attributes;
system high contrast falls back to Windows system colors. The Windows channel is
source-verified but local compilation is not claimed because the installed Visual
Studio Build Tools omit `Microsoft.VisualStudio.Component.VC.ATLMFC`, so
`flutter_local_notifications_windows` cannot find `atlbase.h` on this host.

## Real Android runtime evidence

The secret-free sibling package `com.k1tvkli2003.perfect.preview` was rebuilt as
`1.1.0-preview+2062` and installed with `adb install -r` over build 2061. The
operation returned `Success`; `firstInstallTime=2026-08-02 19:20:44` remained
unchanged and the confirmed foreground activity was
`com.k1tvkli2003.perfect.preview/com.k1tvkli2003.perfect.MainActivity`.

Four real UI-selected compositions were captured at 1080×2400:

- Daylight build 2062;
- Graphite Bloom build 2062;
- Clarity Light build 2062;
- Clarity Dark build 2062;
- plus the More/Appearance surface proving the independent Light/Dark and
  System contrast/Clarity controls are live and accessible.

Each PNG and UIAutomator XML file is size/hash-locked by
`runtime/android/runtime-manifest.json` and rechecked by the independent runtime
verifier. The fixture name and tasks are intentionally synthetic, live only in the
`.preview` package and do not touch owner auth, production storage or widgets.

The disposable APK was 174,249,974 bytes with SHA-256
`e89518b7b339bb2717926164e425796c3832892401af7fa4361d8bc45d7173b2`.
It is local debug evidence, not a distributable or signed-release claim.

## Verification executed

| Gate | Result | Evidence / limit |
| --- | --- | --- |
| Dart formatting and whitespace | pass | touched Dart formatted; final `git diff --check` required before commit |
| Static analysis | pass | full `flutter analyze --no-pub`, no issues |
| Full Flutter suite | pass, 444/444 | persistence, AI, sync, themes, motion, workspace, goldens and native contracts |
| Workspace theme matrix | pass | phone/tablet/Windows, standard and Clarity variants visually inspected |
| Stage 10 design verifier | pass | 3 foundations, 4 themes, 181 components, 134 pages, 76 pairs, 6 boards, 20 hashes |
| Runtime/source verifier | pass | 0 raw color violations, Android/Windows/native asset contracts and 13 runtime artifacts |
| Brand verifier | pass | mark/wordmark outputs and manifest hashes |
| Orbit asset verifier | pass | two Clarity variants, 51 mapped colors, no blur filter |
| Android debug build | pass | secret-free `.preview` APK 2062 |
| Android install-over | pass | 2061→2062 with unchanged first-install time |
| Real Android themes | pass | Daylight, Graphite, Clarity Light/Dark and Appearance settings captured |
| Local Windows build | host-blocked | optional ATL `atlbase.h` absent before project runner compilation |
| Exact-SHA hosted build/release | pending | closes Windows compile/sign/install-over and immutable three-asset release |

## Honest upgrade boundary

The build-2061→2062 run proves in-place continuity for the isolated preview package;
unit/file-backed preservation tests prove theme, contrast, auth marker, planner
records and outbox survival across reopen. It does **not** by itself prove a signed
production login session survived this exact theme build. Stable signing lineage
and signed Windows install-over are accepted only after the trusted main workflow;
the final hosted checkpoint will be appended here rather than inferred from source.

## Handoff boundary

Stage 11 may consume only the four stable theme IDs and semantic roles. It must not
reintroduce raw palette values, light-only assets or blur into Clarity. The retired
Orbit decision remains owned by Stage 11; Stage 10 improves the current instrument
so the shipped app is coherent until that deliberate replacement lands.
