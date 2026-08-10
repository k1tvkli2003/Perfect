# Preview/runtime mismatch

- Preview: `pg-tasks-dense@ps01-pages-1.0.0#1a87b84765228c97f254858557fe09483229104618724578c5151175a94cb517`
- Page: `pg-tasks-dense`
- Scenario: `scn-tasks-dense-windows-wide`
- Runtime page/scenario: `pg-tasks-dense` / `scn-tasks-dense-windows-wide`
- Normalized raster: `1366×768`
- Changed pixels: `22704` (2.1642%)
- Mean/max channel delta: `0.7329` / `206`

| Severity | Category | Field | Evidence |
| --- | --- | --- | --- |
| P1 | state | `system_state.sync` | expected `"synced"`; actual `"error"` — Runtime state meaning differs from the exact frozen scenario. |

The harness names the exact preview, page, state and field. A non-zero mismatch is not acceptance; later runtime stages must correct it or record a proven adaptive/platform exception.
