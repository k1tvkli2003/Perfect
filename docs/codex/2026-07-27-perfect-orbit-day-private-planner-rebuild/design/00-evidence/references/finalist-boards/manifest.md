# Finalist model-native board manifest

Generated: 2026-08-10
Tool mode: built-in ImageGen
`textEmbeddingMode`: `model_native` for all files
Post-processing: exact whole-file copy only; no crop, resize, overlay, text repair,
color adjustment or recomposition

These boards are visual exploration evidence. None is a canonical Copy target. The
model altered some exact labels, Persian strings, brand geometry or requested layout
details, so the embedded-text and identity gates intentionally reject them as final
specifications. Their accepted use is limited to composition/material comparison.

| File | Pixels | SHA-256 source = delivery | Original-size inspection | Canonical status |
| --- | ---: | --- | --- | --- |
| `f1-pulse-stream-board-v1-model-native.png` | 1536x1024 | `8116d59e30683c8922fd93412a33bde4a8ba218930d2be05f0c304f230d29a99` | Strong stream/list-detail composition; Persian label and supplied mark drift; several requested labels omitted. | rejected as canonical; retained exploration |
| `f1-pulse-stream-stress-v1-model-native.png` | 1536x1024 | `f1b8753c710857ccbea0b1ab42da197b60904dd19de0463386311279ea1ecfe3` | Useful empty/conflict/large-type proof; structure drifted to hamburger/cards and mixed label was not verbatim. | rejected as canonical; retained stress evidence |
| `f2-living-ledger-board-v1-model-native.png` | 1536x1024 | `134d01e8aba2bc93fb3a7ba83a665aad10fc4ff3ee9e8c6f8f4e8a0cd782c6e8` | Ledger/receipt hierarchy legible; giant presentation wordmark and omissions prevent exact use. | rejected as canonical; retained exploration |
| `f2-living-ledger-stress-v1-model-native.png` | 1536x1024 | `ed0a0370213bfdb9d852fa5402bbf7f7ea0a558243a9795206e1dbdcdc0049bf` | Exposes heavy-card failure at 200%; Persian and English examples differ from requested strings. | rejected as canonical; retained stress evidence |
| `f3-daily-desk-board-v1-model-native.png` | 1536x1024 | `c12bb094608a6b0dc2cce1271eb62c518d5282c6eeba66babcc3432feefc0ed4` | Strong Windows list/plan/detail anatomy; phone/tablet labels and identity are approximate. | rejected as canonical; retained exploration |
| `f3-daily-desk-stress-v1-model-native.png` | 1721x914 | `18d858f1dbbd0757950d364b6e9037d88837b59672ee5280701f66701ee17e4e` | Strong dark list/plan/conflict proof; exact text set incomplete and mark altered. | rejected as canonical; retained stress evidence |
| `f4-adaptive-instrument-board-v1-model-native.png` | 1536x1024 | `d21057c3313fc1829de559f3eba8d51ce0230e3ec2e357de49e47204efd90d3b` | Useful sculpted material/Capture exploration; over-large instruments and text omissions. | rejected as canonical; retained exploration |
| `f4-adaptive-instrument-stress-v1-model-native.png` | 1643x957 | `dac3f75e2ff384c581975b207e2759b0ebdfa7e82877a8eb0ebb1d06df18aa08` | Empty state regressed to ornamental blob; Persian not verbatim; useful rejection evidence. | rejected as canonical; retained stress evidence |

## Side-by-side comparison sheet

The four normal boards are aligned above their four stress companions so composition
drift, hierarchy and failure behavior can be judged in one frame. Tiles preserve
their complete source aspect ratio; canonical judgment still uses the originals.

| File | Pixels | SHA-256 | Inspection |
| --- | ---: | --- | --- |
| `finalist-contact-sheet.svg` | 1800x1120 | `77a6040c172a9987ba1f5b32a7c3173a37ddbf50389314cbc6ef8b46ff4aad5a` | Source ordering, labels and uncropped fit checked. |
| `finalist-contact-sheet.png` | 1800x1120 | `213963a45f3f5bcafd1f4a6c75a7e38017a7989b07a73275c53dfc7db135b9d3` | Original-size raster checked; all eight boards remain separated and readable. |

## Exact text sets supplied

### Normal boards

- Shared identity/context: `Perfect!`, `Synced`, `Monday, July 27`, `9:24 AM`.
- F1: `Next`, `Cardiology deep work`, `9:30–11:00`, `Review project brief`,
  `Drink water`, `5 of 8`, `18 day streak`, `Book lab appointment`,
  `مرور فصل Arrhythmia`, `Today`, `Tasks`, `Plan`, `Habits`, `More`.
- F2: `Daily ledger`, `Planned 9:30–11:00`, `Completed 3 of 5`,
  `+1 · 5 of 8`, `Saved locally`, `Corrected`, `Carry to Tuesday`,
  `Retrying in 18s`, `History` plus shared task/navigation strings.
- F3: `Goals`, `Focus`, `Search tasks`, `Details`, `Checklist`, `Notes`,
  `Ctrl K`, `2 local changes` plus shared entities.
- F4: `Today pulse`, `Next at 9:30`, `Focus 90 min`, `+1`,
  `2 local changes` plus shared entities/navigation.

### Stress boards

Each stress prompt supplied the relevant subset of:

`Perfect!`, `Monday, July 27`, `9:24 AM`, `Today pulse`, `Daily ledger`,
`Retrying`, `Sync needs attention`, `مرور فصل Arrhythmia`,
`Cardiology deep work`, `Drink water`, `Nothing planned yet`,
`No entries yet`, `Capture your first task`, `Plan with Perfect AI`,
`2 local changes are safe`, `Resolve conflict`, `Keep local`, `Use remote`,
`Try again`, `Saved locally`, `Corrected`, `Carry to Tuesday`, `History`,
`Search tasks`, `Ctrl K`.

## Why no text repair was performed

Overlaying corrected SVG/HTML text onto these rasters would misrepresent the images
as native generation results and obscure structural defects. Stage 03 instead uses
these as adversarial concept evidence. Stage 04/05 canonical plates will use
`single_render_native`: exact graphics and exact live-equivalent text authored in the
same deterministic source before first rasterization.
