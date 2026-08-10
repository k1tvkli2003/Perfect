# Previews

## Preview Policy
Mock previews, fake states, and generated assets are labeled as previews until verified against the real implementation.

## Preview Ledger
| Name | Type | Source | Verified? | Asset/Link | Notes |
|---|---|---|---|---|---|
| Orbit Day Today | Superseded mock preview | built-in image generation; historical owner selection | no | [asset](assets/orbit-day-today-mock-preview.png) | Historical evidence only; Stage 03 removed Orbit from the forward UI direction. |
| Historical launcher icon board | Mock Preview | built-in image generation; bottom-right was selected earlier | no | [asset](assets/launcher-icon-options-mock-preview.png) | Historical reference only؛ the owner reopened the launcher decision on 2026-07-30. |
| Historical launcher runtime | Verified for superseded candidate | ImageGen reconstruction + platform adaptation | yes, historical only | [Pixel evidence](assets/perfect-launcher-pastel-final.png) | Proves only the old three-arc candidate in `d56455b`. |
| Launcher concepts v2 | Mixed mock/selected source | 10 blank-brief concepts plus 5 symmetric explorations | Day Compass selected | [concept ledger](icon-concepts-v2/README.md) | The selected source, cleaned transparent master and five symmetric comparison files are retained separately. |
| Day Compass Android runtime | Verified runtime | selected source → deterministic alpha cleanup → launcher derivatives | yes, Pixel API 35 | [app drawer evidence](assets/perfect-day-compass-app-drawer.png) | Transparent adaptive background became black in a control build; `#FFF3E8` prevents white/black fallback while master/legacy/Windows remain transparent. |
| Typography board | Mock Preview | built-in image generation; bottom-left selected by user | no | [asset](assets/typography-options-mock-preview.png) | Reference only؛ generated text is not source. The app uses live Plus Jakarta/Vazirmatn typography and the wordmark decision was not reopened. |
| Stage 03 finalist families | Model-native exploration/stress evidence | built-in ImageGen, 4 normal + 4 stress boards | no; all rejected as canonical | [manifest](design/00-evidence/references/finalist-boards/manifest.md) | Useful for composition/material comparison; exact text and identity drift prevent Copy use. |
| `PS01 Perfect Day Instrument` | Deterministic selected direction | authored SVG with exact brand assets and native text, first-pass PNG raster | yes, as Stage 03 direction only | [manifest](design/01-foundations/stage03-selected/manifest.md) | Six identity/shell/workflow/state/motion/typography plates; Stage 04/05 still owe component/page canonical previews. |

## Mock Preview: Orbit Day
- Label: Mock Preview
- Source: built-in image generation, selected by the user.
- Assumptions: a circular day stage improves glanceability while timeline/list remains the primary accessible operational form.
- Limitations: it is not a running Flutter screen; it shows English placeholder content, neither RTL behavior nor landscape/expanded composition, and no real sync state.
- Verified: no — mock only
- Asset: [assets/orbit-day-today-mock-preview.png](assets/orbit-day-today-mock-preview.png)

Historical implementation intent: this once proposed keeping Orbit as a live
semantic/status component. Stage 03 supersedes that intent with `PS01`: a compact
Today Pulse plus one continuous actionable Stream. Orbit may remain only in frozen
historical evidence and must not return through later styling work.

## Mock Preview: Historical identity board
- Label: Mock Preview
- Source: built-in image generation؛ wordmark selection remains, launcher selection was later reopened.
- Assumptions: the orbital-tick icon master and soft compact live wordmark can share one coherent identity system.
- Limitations: the launcher board and its reconstructed candidate are not the final source after the 2026-07-30 reset. The old Pixel screenshot only verifies the interim mark currently wired into `d56455b`.
- Verified: no — historical mock only
- Asset: [assets/launcher-icon-options-mock-preview.png](assets/launcher-icon-options-mock-preview.png), [assets/typography-options-mock-preview.png](assets/typography-options-mock-preview.png)

## Mock Preview: Launcher concepts v2
- Label: Mock Preview
- Source: ۱۰ independent blank-brief concepts followed by five symmetric explorations using the approved soft pastel material language.
- Assumptions: chroma فقط برای جداسازی آسان mark است و هیچ preview تا انتخاب و پاک‌سازی، asset پلتفرم محسوب نمی‌شود.
- Limitations: بردهای chroma به‌تنهایی transparency، safe-zone، adaptive mask یا خوانایی launcher واقعی را اثبات نمی‌کنند؛ فقط Day Compass انتخاب‌شده پس از pipeline و runtime proof مبنای production است.
- Decision: the owner selected **Day Compass**, the six-fold symmetric concept.
- Production result: magenta chroma and colour spill were removed at ۱۲۵۴px, the mark was optically fitted into a ۵۱۲px RGBA master, and Android legacy/adaptive/monochrome plus a ۹-frame Windows ICO were derived.
- Verified: master/Android yes؛ fresh hosted Windows artifact remains
- Asset: [icon-concepts-v2/README.md](icon-concepts-v2/README.md)

Unselected files remain comparison material only. The canonical identity is now
`assets/brand/perfect-launcher.png`; only its checked-in derivatives and installed
runtime proof satisfy the identity gate.

## Stage 03 selected direction: PS01 Perfect Day Instrument

- Label: deterministic direction specification; not yet Flutter runtime.
- Source: exact selected Day Compass/wordmark assets, authored SVG geometry and native
  live-equivalent English/Persian/mixed text.
- Files: six SVG sources and six PNG inspection renders under
  `design/01-foundations/stage03-selected/`.
- Text integrity: `single_render_native`; no overlay repair or generative text
  correction after rasterization.
- Decision: compact Pulse + continuous Stream, method-specific habit controls,
  view-first detail, standalone morphing Capture and distinct phone/tablet/Windows
  compositions.
- Verification: all plates inspected at original size; exact hashes and limitations
  are frozen in the selected manifest; `design_direction_contract_test.dart` passes
  8/8.
- Limit: this direction family cannot authorize production UI by itself. Stage 04
  creates the exhaustive component library and Stage 05 freezes every full-page,
  overlay and widget composition before Copy implementation.
