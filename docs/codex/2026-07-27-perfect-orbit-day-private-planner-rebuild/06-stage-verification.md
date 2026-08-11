# Stage 06 verification — brand and installed identity

Date: 2026-08-10
Stage: `06-brand-installed-identity`
Status: local Android and source gates passed; exact-SHA trusted Windows/release gate pending

## Outcome

Perfect! now has one checksum-pinned Day Compass geometry and explicit
surface-specific derivatives. Android launcher, Android system splash, native
widget, Flutter light/dark/high-contrast identity, Windows ICO and Windows
package logo no longer reuse one incompatible raster canvas.

The selected typography is now authored path SVG with deterministic PNG/native
fallbacks. Product identity positions no longer depend on host SVG text or a
generic loading pictogram.

## Decomposition contract

- Immutable selected chroma source SHA-256:
  `10280e3c4fae3b80bafdc8df35bcf26d75653566c7b9670fc6ca2462801dce77`.
- Transparent 1024px archival master and 512px runtime/legacy master.
- Android adaptive icon retains only the proven quiet `#FFF3E8` platform plate;
  the mark itself remains transparent and inside the adaptive safe zone.
- Android splash is a dedicated 288dp canvas with a 168dp visible mark inside
  Android's 192dp no-background safe circle. `drawable-night-*` keeps the same
  geometry and lifts only the owner core for the dark canvas.
- Native widget mark is a dedicated 48dp canvas with a 40dp visible mark.
- Windows ICO contains individually padded 16, 20, 24, 32, 40, 48, 64, 128
  and 256px frames; the MSIX source uses the unplated Windows derivative.
- Flutter selects distinct dark and high-contrast mark/wordmark assets while
  exposing exactly one `Perfect!` semantic label.
- Native widget headers use the authored wordmark raster and one accessible
  open-Today action; ordinary `Perfect!` TextViews were removed.

Generated source/output hashes, alpha bounds, component counts and consumers
are recorded in:

- `assets/brand/perfect-mark-manifest.json`
- `assets/brand/perfect-wordmark-manifest.json`

## Adversarial finding closure

| Finding | Closure evidence |
| --- | --- |
| `B06-01` clipped Android splash | `perfect_splash_mark_raster` replaces the widget drawable in both v31 themes; installed screenshot shows the complete six-module silhouette. |
| `B06-02` one raster reused everywhere | Generator now emits explicit master, adaptive/legacy, splash, widget, Windows and contrast compositions. |
| `B06-03` widget/ICO edge crowding | Verifier requires density-aware transparent perimeter and per-frame ICO insets. |
| `B06-04` native ordinary-text brand | Four widget layouts use `perfect_widget_wordmark_raster`; the decorative mark is excluded from accessibility. |
| `B06-05` dark/high-contrast gaps | Night splash uses `#171821` plus a night-qualified warm-white owner core; Flutter has dark and high-contrast mark and path-wordmark variants. |
| `B06-06` live SVG text | All four wordmark SVGs contain eight glyph paths and zero `<text>` elements. |
| `B06-07` naive ICO downscale | Nine individually composed frames are emitted and inspected by the deterministic verifier. |

## Verification executed

| Gate | Result |
| --- | --- |
| `python tool/verify_perfect_brand_assets.py` | Pass. Source hashes, generated hashes, alpha bounds, safe zones, SVG paths, ICO frames and consumers verified. |
| Deterministic regeneration | Pass. Authored masters remain byte-pinned; decoded raster/ICO geometry is RGBA-pinned; 40 generated manifest, SVG and Android XML files repeated with zero byte drift. |
| Focused Flutter tests | Pass, 34/34 brand/theme/platform/design-direction tests. |
| Stage 03 identity contract | Pass, 8/8 after updating its protected selected master to the Stage 06 optical perimeter. |
| Stage 05 preview harness | Pass, 9/9; page-preview registry remains intact. |
| Non-dirty Dart suite | Pass, 344 tests at concurrency 1. `perfect_workspace_page_test.dart` was intentionally excluded because its source and test are pre-existing user-owned unstaged edits. |
| `flutter analyze` | Pass, no issues. |
| Android debug and release APKs | Pass, `app-debug.apk` and 69.4MB `app-release.apk` at versionCode 2045. The local release uses the documented verification-only debug signer and was not installed over production. |
| Android in-place preview update | Pass, `versionCode 2000 -> 2045`; `firstInstallTime` remained `2026-08-02 19:20:44`; no uninstall/reset. |
| Installed Android splash | Pass. All modules and owner core remain visible; no circular crop. |
| Installed Android dark splash | Pass. Same bounds as light; night-qualified owner core remains explicitly visible on `#171821`. |
| Installed Pixel adaptive icon | Pass. Quiet required plate, complete mark and stable mask spacing. |
| Local Windows release compile | Host-bound failure before product link: local Visual Studio Build Tools lacks ATL `atlbase.h` required by `flutter_local_notifications_windows`. No signing/identity mutation attempted. |
| Exact-SHA GitHub Windows/Android/release | Pending the Stage 06 push; stage remains open until the trusted main workflow, three release assets and Windows install-over gate pass. |

## Runtime evidence

- Baseline and finding freeze:
  `design/00-evidence/current-runtime/stage06-brand-baseline.md`
- Original before/after PNGs:
  `design/00-evidence/current-runtime/stage06-brand/`
- Inspected comparison sheet:
  `design/00-evidence/current-runtime/stage06-brand/before-after.png`

The app-drawer comparison intentionally retains both production and preview
installs. This proves the new preview was installed without removing or
mutating the owner's signed production package.

## CI regression gate

The main workflow now verifies checked-in assets, regenerates mark/wordmark and
launcher derivatives, verifies them again and fails on semantic manifest,
authored SVG or Android XML drift. Raster and ICO files are validated from
decoded pixels and ordered frames rather than host-specific compression bytes.
This gate runs before formatting, analysis, tests, signing or publication; a
malformed brand asset cannot become a trusted release.

The first exact-SHA hosted attempt (`31442875839`) exposed an operating-system
boundary that local Windows repetition could not: the wordmark manifest had
hashed CRLF SVG bytes while the Ubuntu checkout normalized those files to LF.
Generated SVG/manifest writers now emit canonical LF bytes, `.gitattributes`
pins those artifacts to LF on every checkout, and the verifier rejects either
a missing repository EOL contract or any generated carriage return. The gate
was strengthened rather than bypassed.

The replacement attempt (`31449329295`) then proved that raw PNG/ICO bytes are
not a valid cross-platform identity contract: Pillow produced the same decoded
geometry with host-specific compression, while FreeType text measurement
shifted regenerated path positions. Stage 03's accepted transparent mark and
wordmark raster, plus the accepted path-only light SVG, are now immutable
authored masters. Raster outputs use dimension-prefixed decoded RGBA hashes;
SVG and manifest outputs retain exact canonical byte hashes; the ICO is pinned
as an ordered semantic frame set. CI still regenerates and verifies every
surface, but ignores encoder-only binary noise after semantic verification.

That same run correctly rejected nine Windows golden files whose only changed
bounds were the installed mark/wordmark surfaces. They were regenerated from a
detached clean worktree, inspected at compact, tablet and expanded sizes, and
accepted only after all seven tagged scenarios passed with unchanged layout.
