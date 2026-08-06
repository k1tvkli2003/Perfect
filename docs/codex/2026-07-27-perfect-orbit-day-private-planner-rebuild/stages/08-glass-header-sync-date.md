# Stage 08 — Glass header, sync confidence and dual date/time

Status: pending  
Depends on: Stages 04, 05, 07  
Primary surfaces: global header, page titles, Today Pulse, sync details

## Mission

Replace heavy colored header bands and weak cloud decoration with a compact,
spatially meaningful glass header that communicates identity, location, real
local time and database confidence without consuming the page.

## Mandatory preview and Copy entry gate

- Bind implementation to `sh-glass-header`, `sh-title-cluster`,
  `sh-dual-date-clock`, `sh-sync-cloud` and their shell/Today page compositions.
- Preview every sync transition, retry countdown/detail, long bilingual date,
  midnight boundary, scrolled blur, non-blur fallback, dark/high contrast and 200%.
- Decompose live clock/date/status text from authored cloud/vector/material layers;
  dynamic values can never be flattened into the preview asset.
- Compare installed runtime to the exact state/viewport preview and separately verify
  state truth; pixel similarity cannot bless a green cloud driven by stale queue data.

## Composition decisions

- Phone header shows the authored mark/wordmark and compact sync state. Page title
  and contextual date belong to content when that reduces header height.
- Tablet/Windows rail already carries identity; header becomes contextual and may
  omit repeated branding.
- Blur is bounded and backed by a theme-aware translucent fallback. Color appears
  as small semantic accent, never a flat full-width banner.
- Gregorian and Solar Hijri dates are displayed together in a deliberate mixed-
  script line; they use the actual device-local date, not locale fixture text.

## Work packets

1. Implement/test a deterministic Gregorian→Jalali conversion or vetted dependency
   with known leap/boundary vectors; centralize all date formatting.
2. Add a minute-aligned live clock source that respects injected test time and
   avoids global rebuild storms.
3. Build compact/wide glass header compositions with exact blur/tint/stroke tokens.
4. Rebuild sync icon artwork and state machine presentation:
   - green: synced;
   - yellow: actively syncing or bounded retry countdown;
   - red: last error, local work retained, retry available.
5. Add non-color semantics, tooltip/detail sheet, last-success time and safe retry.
6. Ensure remote updates refresh content without scroll-to-refresh or repeated
   whole-page rebuild.
7. Audit every date/time shown in Today, Plan, detail, wizard, widget, notifications,
   feedback reports and AI context for UTC/local correctness.

## Edge scenarios

- UTC timestamp crosses local day; device timezone changes while app is open.
- Gregorian leap day, Nowruz boundary, Jalali leap Esfand, month/year transitions.
- Clock 12 AM/PM formatting and 24-hour system preference if later enabled.
- Sync active→error→retry→synced, app background/resume and auth-expired error.

## Verification

Known date vectors including 2024-03-20→1403-01-01 and 2026-08-06→1405-05-15;
midnight/timezone tests; real light/dark screenshots; cloud semantics; retry tests;
frame count proving minute tick does not rebuild unrelated list rows.

## Reject if

- Header blur harms contrast or scroll performance.
- Fixed preview dates/names can reach signed builds.
- Sync color says green before the durable queue is actually converged.

## Handoff

Stage 09 receives stable header geometry and state animations. Commit/push/release
with date/sync evidence and clean Git.
