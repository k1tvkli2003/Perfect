# Previews

## Preview Policy
Mock previews, fake states, and generated assets are labeled as previews until verified against the real implementation.

## Preview Ledger
| Name | Type | Source | Verified? | Asset/Link | Notes |
|---|---|---|---|---|---|
| Orbit Day Today | Mock Preview | built-in image generation; chosen by user | no | [asset](assets/orbit-day-today-mock-preview.png) | Composition reference only; generated English text and static visuals are not production UI. |
| Historical launcher icon board | Mock Preview | built-in image generation; bottom-right was selected earlier | no | [asset](assets/launcher-icon-options-mock-preview.png) | Historical reference only؛ the owner reopened the launcher decision on 2026-07-30. |
| Historical launcher runtime | Verified for superseded candidate | ImageGen reconstruction + platform adaptation | yes, historical only | [Pixel evidence](assets/perfect-launcher-pastel-final.png) | Proves only the old three-arc candidate in `d56455b`. |
| Launcher concepts v2 | Mixed mock/selected source | 10 blank-brief concepts plus 5 symmetric explorations | Day Compass selected | [concept ledger](icon-concepts-v2/README.md) | The selected source, cleaned transparent master and five symmetric comparison files are retained separately. |
| Day Compass Android runtime | Verified runtime | selected source → deterministic alpha cleanup → launcher derivatives | yes, Pixel API 35 | [app drawer evidence](assets/perfect-day-compass-app-drawer.png) | Transparent adaptive background became black in a control build; `#FFF3E8` prevents white/black fallback while master/legacy/Windows remain transparent. |
| Typography board | Mock Preview | built-in image generation; bottom-left selected by user | no | [asset](assets/typography-options-mock-preview.png) | Reference only؛ generated text is not source. The app uses live Plus Jakarta/Vazirmatn typography and the wordmark decision was not reopened. |

## Mock Preview: Orbit Day
- Label: Mock Preview
- Source: built-in image generation, selected by the user.
- Assumptions: a circular day stage improves glanceability while timeline/list remains the primary accessible operational form.
- Limitations: it is not a running Flutter screen; it shows English placeholder content, neither RTL behavior nor landscape/expanded composition, and no real sync state.
- Verified: no — mock only
- Asset: [assets/orbit-day-today-mock-preview.png](assets/orbit-day-today-mock-preview.png)

Implementation intent: keep the orbit as a live semantic/status component. In compact portrait it is an upper stage; in landscape it becomes an adjacent contextual panel; in reduced-motion/large-text/insufficient-space cases a clear linear timeline remains authoritative.

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
