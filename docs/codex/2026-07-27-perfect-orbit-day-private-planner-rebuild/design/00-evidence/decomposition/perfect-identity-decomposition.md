# Perfect! identity decomposition

Status: protected identity inputs for Stage 03
Decision: retain the selected Day Compass mark and selected custom Perfect! wordmark

## Master assets

| Role | Canonical source | Contract |
| --- | --- | --- |
| mark | `icon-concepts-v2/selected/day-compass-transparent-512.png` | six symmetric pastel modules around a graphite core; transparent field; no tile baked into master |
| wordmark | `assets/brand/perfect-wordmark.svg` and raster export | selected custom typography image; never recreated with a live generic font |
| dark wordmark | `assets/brand/perfect-wordmark-dark.svg` | optical counterpart, not an automatic color inversion |
| launcher | `assets/brand/perfect-launcher.png` | platform expression derived from mark; must be regenerated/verified at mask sizes in Stage 06 |
| monochrome | `assets/brand/perfect-launcher-monochrome.png` | semantic silhouette for Android themed icon/high-contrast contexts |

## Meaning

- Six modules form three mirrored pastel pairs: apricot for intention/action, mint
  for sustainable rhythm, lavender for reflection/focus.
- The graphite center is the owner: a stable personal core rather than a corporate
  account, social network or public productivity score.
- Radial symmetry communicates balance and continuity across devices without using
  a clock/orbit metaphor inside the product UI.
- The exclamation mark in the wordmark provides confident energy; surrounding UI
  must stay calm enough that the mark remains distinctive.

## Formal characteristics to protect

- exact sixfold symmetry and optical center;
- generous internal apertures so modules do not fuse at 16–24 px;
- soft sculpted pastel bodies with authored highlight/shadow, never flat wedges;
- graphite core with sufficient separation in light and dark themes;
- transparent visual field for master/widget/taskbar assets;
- selected wordmark silhouette, kerning and exclamation geometry.

## Platform expressions

### Android

- Foreground art stays inside adaptive-icon safe geometry with breathing room around
  all six tips. The OS mask owns the outer container; the mark asset does not include
  a white, black or arbitrary rounded-square background.
- A dedicated monochrome path preserves the flower/compass silhouette.
- Splash uses the same uncropped mark at a smaller safe optical scale and transitions
  into the compact app header without a second oversized logo flash.

### Windows

- ICO ladder requires optical corrections at 16/20/24/32 px rather than one bitmap
  downsampled blindly.
- Start/taskbar/Alt-Tab use the transparent mark; installer may pair it with the
  wordmark but cannot introduce a tile into the master.
- High contrast uses a solid silhouette and system foreground/background.

### Widget

- Mark is transparent, uncropped and secondary to date/action content.
- Wordmark appears only where the widget size gives it a readable minimum width;
  compact widgets use mark alone.

## Pastel semantic roles

The three brand families are orientation accents, not status colors:

| Family | Primary semantic use | Must not mean |
| --- | --- | --- |
| apricot | planned action, next action, capture/commit | generic warning or every primary button |
| mint | habit rhythm, sustainable progress, saved local work | sole success/synced signal without label |
| lavender | focus, AI assistance, reflection/insight | disabled or decorative glass wash |
| graphite | owner identity, high-value text, stable controls | error or punitive failure |

System status uses independent accessible roles: green synced/success, yellow
syncing/retry/caution and red error/destructive. Brand color never overrides status
meaning.

## Material personality

- **Canvas:** warm, almost-paper background with very low chroma.
- **Rows:** mostly planar, separated by rhythm, rules and local state—not glass cards.
- **Floating instrument:** compact header/footer/capture/selected overlay may use
  restrained blur, edge light and soft shadow because they genuinely float.
- **Graphic moments:** mark, streak receipts, celebrations and authored illustrations
  use layered vector/raster craft. Generic gradients and primitive circles are not
  acceptable substitutes.
- **Dark theme:** deep warm graphite, not pure black; pastels are lowered in luminance
  and raised in edge contrast so text never disappears.

## Motion personality

- The mark may breathe once during first ready state, not spin continuously.
- Capture orb has a subtle heartbeat only while collapsed and idle; it stops during
  interaction and honors reduced motion.
- Page titles rise a short optical distance with fade; rows settle in reading order.
- Status/log receipts use tactile compression and a short color/arc response.
- Sync cloud uses a restrained internal travel/pulse, never a perpetual spinner when
  already synced.
- Celebrations are proportional to achievement; ordinary task completion does not
  trigger confetti.

## Typography

- Header brand uses the exact selected wordmark image.
- Live Latin/Persian text uses a production font system selected in Stage 04 after
  mixed-script, numerals, Jalali/Gregorian, 200% and Windows rasterization trials.
- The live type family should echo the wordmark's soft, confident geometry without
  impersonating it or making body copy ornamental.
- Date/time numerals require tabular stability where values update.

## Rejection tests

Reject an export or composition when:

- any module is clipped, off-center, asymmetric or visually smaller than peers;
- a white/black square appears behind the master mark;
- the header spells `Perfect!` in a generic live font;
- pastel families become a rainbow applied to every surface;
- a flat painter or stock radial gradient replaces the crafted module material;
- dark/high-contrast variants lose the graphite core or internal separation;
- icon/wordmark scale is timid enough to look accidental in the header.
