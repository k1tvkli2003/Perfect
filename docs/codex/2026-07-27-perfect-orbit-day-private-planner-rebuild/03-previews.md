# Previews

## Preview Policy
Mock previews, fake states, and generated assets are labeled as previews until verified against the real implementation.

## Preview Ledger
| Name | Type | Source | Verified? | Asset/Link | Notes |
|---|---|---|---|---|---|
| Orbit Day Today | Mock Preview | built-in image generation; chosen by user | no | [asset](assets/orbit-day-today-mock-preview.png) | Composition reference only; generated English text and static visuals are not production UI. |
| Launcher icon board | Mock Preview | built-in image generation; bottom-right selected by user | no | [asset](assets/launcher-icon-options-mock-preview.png) | Final icon must be redrawn as adaptive/vector platform assets. |
| Typography board | Mock Preview | built-in image generation; bottom-left selected by user | no | [asset](assets/typography-options-mock-preview.png) | Reference only; final wordmark/type must be live/vector and optical-spacing tested. |

## Mock Preview: Orbit Day
- Label: Mock Preview
- Source: built-in image generation, selected by the user.
- Assumptions: a circular day stage improves glanceability while timeline/list remains the primary accessible operational form.
- Limitations: it is not a running Flutter screen; it shows English placeholder content, neither RTL behavior nor landscape/expanded composition, and no real sync state.
- Verified: no
- Asset: [assets/orbit-day-today-mock-preview.png](assets/orbit-day-today-mock-preview.png)

Implementation intent: keep the orbit as a live semantic/status component. In compact portrait it is an upper stage; in landscape it becomes an adjacent contextual panel; in reduced-motion/large-text/insufficient-space cases a clear linear timeline remains authoritative.

## Mock Preview: Selected identity
- Label: Mock Preview
- Source: built-in image generation, selections confirmed by the user.
- Assumptions: the orbital-tick icon and soft compact wordmark can be converted into a coherent vector system.
- Limitations: generated geometry and text are not suitable as final source; no Android/Windows platform safe-zone, icon mask, font license or tiny-size test exists yet.
- Verified: no
- Asset: [assets/launcher-icon-options-mock-preview.png](assets/launcher-icon-options-mock-preview.png), [assets/typography-options-mock-preview.png](assets/typography-options-mock-preview.png)
