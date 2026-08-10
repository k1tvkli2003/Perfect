# Preview/runtime mismatch

- Preview: `pg-task-schedule@ps01-pages-1.0.0#b064c13a96971a5be706fda86c50e27ad2acc5d0e1db361ac699c66dbd075108`
- Page: `pg-task-schedule`
- Scenario: `scn-task-schedule-tablet-portrait`
- Runtime page/scenario: `pg-task-schedule` / `scn-task-schedule-tablet-portrait`
- Normalized raster: `800×1280`
- Changed pixels: `53843` (5.2581%)
- Mean/max channel delta: `1.6316` / `226`

| Severity | Category | Field | Evidence |
| --- | --- | --- | --- |
| P2 | typography | `typography.page_title.size` | expected `24`; actual `31` — Live type scale drift changes hierarchy. |
| P2 | typography | `typography.page_title.line_height` | expected `1.12`; actual `1.3` — Line-height drift changes block rhythm. |
| P2 | typography | `typography.page_title.family_weight` | expected `"Perfect Jakarta/650"`; actual `"Arial/400"` — Font identity or weight does not match the frozen live type role. |

The harness names the exact preview, page, state and field. A non-zero mismatch is not acceptance; later runtime stages must correct it or record a proven adaptive/platform exception.
