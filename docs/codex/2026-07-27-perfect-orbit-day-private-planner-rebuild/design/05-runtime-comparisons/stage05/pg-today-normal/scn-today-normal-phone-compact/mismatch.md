# Preview/runtime mismatch

- Preview: `pg-today-normal@ps01-pages-1.0.0#14085f1a062944510427fce3d6431038f4f19b3cbea43e793a50068f99d0be8f`
- Page: `pg-today-normal`
- Scenario: `scn-today-normal-phone-compact`
- Runtime page/scenario: `pg-today-normal` / `scn-today-normal-phone-compact`
- Normalized raster: `390×844`
- Changed pixels: `84663` (25.7209%)
- Mean/max channel delta: `11.2073` / `255`

| Severity | Category | Field | Evidence |
| --- | --- | --- | --- |
| P2 | geometry | `landmarks.primary_content.x` | expected `0.06`; actual `0.095` — Normalized bounds drift beyond the 1.2% Stage 05 tolerance. |
| P2 | geometry | `landmarks.primary_content.width` | expected `0.88`; actual `0.81` — Normalized bounds drift beyond the 1.2% Stage 05 tolerance. |

The harness names the exact preview, page, state and field. A non-zero mismatch is not acceptance; later runtime stages must correct it or record a proven adaptive/platform exception.
