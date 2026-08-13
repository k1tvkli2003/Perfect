# Stage 10 source-of-truth map

| Concern | Source of truth | Consumers | Rejected duplication |
| --- | --- | --- | --- |
| Theme choice | `PerfectPreferences` appearance value | app root, settings, native bridge, widget projection | per-page booleans |
| Light/dark/high-contrast colors | `PerfectTheme` semantic factories + theme extensions | every Flutter surface, painter and authored-asset selector | raw colors in live widgets |
| System request | `MediaQuery.highContrast` plus owner override | `MaterialApp.highContrastTheme`, asset variants, glass fallback | asset-only high contrast |
| Android native appearance | system-appearance channel + HomeWidget preference | splash mode, widget, Quick Add | light-only XML colors |
| Windows frame | system-appearance channel | DWM caption/border/text | registry-only system brightness |
| Design evidence | `ps01-theme-2.0.0` registry | Stage 11+ previews and Copy comparisons | screenshots without IDs/hashes |
| Contrast proof | generated role-pair report + runtime screenshots | tests, docs and Critics | ratio-only acceptance |

Theme changes preserve route, selection, scroll, focus, draft, timers, local records, authenticated session and outbox identity.
