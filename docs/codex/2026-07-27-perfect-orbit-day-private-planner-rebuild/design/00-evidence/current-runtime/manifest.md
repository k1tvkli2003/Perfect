# Frozen current-runtime manifest

Frozen: 2026-08-09
Purpose: immutable comparison baseline before Stage 03 direction selection
Rule: these images document the current product; they are not approved targets

## Flutter composition goldens

| File | Pixels | SHA-256 | What it proves / does not prove |
| --- | ---: | --- | --- |
| `flutter-goldens/perfect_compact.png` | 390x844 | `6d5eee057bfa1075735153601830d5eee8be7a491577dd0f177e0ad4d0b8aa4c` | Compact Today baseline with Orbit, rows, orb and footer; synthetic fixture only. |
| `flutter-goldens/perfect_compact_ai_closed.png` | 390x844 | `152631e12054c38737978505125e2de9e5b8a905acfa6cb5874c42a5001ba383` | Collapsed AI/capture relationship. |
| `flutter-goldens/perfect_compact_ai_open.png` | 390x844 | `5e1c12cf4ab6d23fca0f97a582d635a14af316dc2f7243c655b44ddeb57dafa1` | Current AI + Quick Capture collision/density baseline. |
| `flutter-goldens/perfect_expanded.png` | 1366x768 | `79577b9af15a189f4c62fb3f56159ce1dd1a82d8beee717220bfde822df0d435` | Expanded desktop Today with inspector overlay; not live Windows runtime. |
| `flutter-goldens/perfect_tablet_landscape.png` | 1200x800 | `4ca6fc3661635a658327470d37c0a4965ea0dfa4ddbb6065a91e7ad1bf0e2b1c` | Tablet landscape split baseline. |
| `flutter-goldens/perfect_tablet_rail_compact.png` | 900x1200 | `3d1e5088bf9d21a426fc26d5bca405fe521f7985f1d8c4e84fd6dec7099c8c37` | Portrait tablet compact rail and large dead-space baseline. |
| `flutter-goldens/perfect_tablet_rail_expanded.png` | 900x1200 | `dc80139638e0e7ccb33db5e3ee59b080cc41c3a4796d2a9a80b07c4fddbace3d` | Expanded rail and single-column baseline. |
| `flutter-goldens/perfect_windows_short.png` | 1366x600 | `9f80ddf247dee0cff797321c78be1d6389b956e4e080960a236c1bb0ee303a3b` | Short-height clipping/composer baseline. |
| `flutter-goldens/perfect_windows_wide_inspector.png` | 1920x1080 | `42e20e3516fdf98cc40cb380acee389e1c042e860d509c713c50cc9be3dd7d1f` | Wide list/Orbit/inspector baseline; synthetic fixture only. |

## Android runtime captures

| File | Pixels | SHA-256 | Evidence |
| --- | ---: | --- | --- |
| `android-runtime/perfect-runtime-portrait.png` | 1080x2400 | `bcada54b01a7694270118bc185fbaa10d413937ac05b660ceb19c2001ca2ddff` | Signed/runtime portrait frame from the previous cycle. |
| `android-runtime/perfect-runtime-landscape.png` | 2400x1080 | `d30fc0798a2cf6f40ca0814bdbd7293d191ef96f94645530c0a938de619c0029` | Landscape top state. |
| `android-runtime/perfect-runtime-landscape-scrolled.png` | 2400x1080 | `6f9b38cb00ef14538ef2a2b9e559d3fa9d0e8dba0eef72e96442e08abc7fc727` | Landscape scroll reachability. |
| `android-runtime/perfect-auth-configured-final.png` | 1080x2400 | `a66d75baf835827acd5e6976e440597015f86efc02521a8a0d9185eb9755a89a` | Configured auth surface; does not prove signed-in session retention. |
| `android-runtime/perfect-day-compass-app-drawer.png` | 1080x2400 | `3a63a44c03526f1633e57d8d71fe99ecd163ecbd6ff1413d07cf561a1cbc919d` | Launcher icon in app drawer and OS mask treatment. |

## Android current-route captures

Captured 2026-08-10 from the non-production sibling package
`com.k1tvkli2003.perfect.preview` (`1.1.0-preview`, code `2000`) on
`Codex_API35`, Android 15/API 35, physical output 1080x2400. These captures freeze
the criticized current interaction language without modifying or clearing the
owner's production package/data. They are baseline evidence, never target UI.

| File | Pixels | SHA-256 | Evidence |
| --- | ---: | --- | --- |
| `android-routes/today-phone-current.png` | 1080x2400 | `5b1f02cb12dff894e0216db125e81b6901c4a4fc431607c76947bad04ded5925` | Current dense Today, Orbit, duplicated Next, rows, capture orb and footer. |
| `android-routes/tasks-phone-current.png` | 1080x2400 | `686b41e6b78de7592ffe8d7994654c6a0e95849125ccfed65bae6433b2a831f3` | Current Tasks header/search/filter deck, three status geometries and sparse dead space. |
| `android-routes/plan-phone-current.png` | 1080x2400 | `39499e70e48879b7e67628700e595df9d814d95aeb936e107cb970d74123078e` | Current single-day Plan strip and repeated task cards. |
| `android-routes/habits-phone-current.png` | 1080x2400 | `9cc63d856502534f979cbd457fe1733e896d852f9f268b84f18a4b318533d969` | Current Habits summary, count logging card, week strip and narrow-label collision. |
| `android-routes/more-phone-current.png` | 1080x2400 | `89788da051461044f0999ebb010b24ecc6cb0603e13a862c9c6c28bce25ac7a7` | Current More/settings entry, feedback toggle, appearance, projects/areas and footer occlusion. |
| `android-routes/today-phone-dark-current.png` | 1080x2400 | `035d90e092df8c0567e0c38c7dc1b291358d84feeaa917ccb3a7973a2cac3e90` | Current dark Today contrast/material baseline. |
| `android-routes/more-phone-dark-current.png` | 1080x2400 | `cc9c76dbcc3d68c925567c208c71f072303ce847928c5c5b27566f1aa48d30ff` | Current dark More/settings baseline. |
| `android-routes/quick-capture-phone-current.png` | 1080x2400 | `a6b505d3220b0323ae6cde4d73d848ecdecb169333a10aa1f2a8c94dd3cf1fa8` | Expanded Quick Capture shows its extra panel, duplicate header, field, modes and footer relationship. |
| `android-routes/ai-capture-phone-current.png` | 1080x2400 | `bea4d28c1e7aae111f04322f1bedd1f366b30990a6cf62c22da54b95336b9ff6` | Current AI panel stacks above a still-expanded separate capture panel and truncates the prompt hint. |
| `android-routes/sync-details-phone-current.png` | 1080x2400 | `84838dd6ab4eb9dbae5c3b015e231b6ac352c78f6ec7ea5ad47b44903fdd8318` | Current synced detail dialog, timestamp, close and manual Sync now action. |
| `android-routes/task-wizard-phone-current.png` | 1080x2400 | `b132cd41ad647eda6136bea8d34e24c8b7b75306440f9bebdd34c55115a2d17d` | Create wizard Type step with Task/Recurring/Habit/Project/Area and selected-check treatment. |
| `android-routes/habit-wizard-category-phone-current.png` | 1080x2400 | `63e4a4c9dba2238da5dd830eaf3de7ee8f5f987e756fa96759a51d0f5106cfcd` | Habit Category step, current category/icon library and fixed bottom action. |
| `android-routes/habit-wizard-measure-phone-current.png` | 1080x2400 | `b763e1918ac4398059cbbb82d4a39e90383cf9ff7e4ce111705d9e186dded18b` | Habit Measure step with boolean/numeric/timer/checklist/limit branches. |
| `android-routes/task-row-tap-current.png` | 1080x2400 | `1634c63c0c246339593f4d414ee9b1a094debae85d4be68c72f7b4c84db24784` | Current normal Task row tap enters Edit and repeats the immutable Type step; direct evidence for `IR-001`/`IR-005`. |

The 14 route captures are also indexed side-by-side without cropping. The sheet is
for fast comparative diagnosis; acceptance findings were checked on each original
1080x2400 frame.

| File | Pixels | SHA-256 | Inspection |
| --- | ---: | --- | --- |
| `current-phone-contact-sheet.svg` | 1800x1100 | `92ae4326a175bd99a494f5c937c75a02e1f1b3da3714f257ad323f7a46cfe3a7` | Labels, source order and uncropped aspect-fit checked. |
| `current-phone-contact-sheet.png` | 1800x1100 | `25c4069088df7be6ca70ea7d3d4c33737cc982f93c421b7385c1a0e4d3a1583d` | Original-size raster checked; no tile overlap or clipping. |

## Android widget captures

| File | Pixels | SHA-256 | Evidence |
| --- | ---: | --- | --- |
| `android-widget/perfect-widget-picker.png` | 1080x2400 | `526680cf77b7464971097528b0d2d1f130c70cef121890e433a77df1499a288a` | Widget picker identity/preview. |
| `android-widget/perfect-widget-home-2x2.png` | 1080x2400 | `b8a00651d337b3903cc88fa576ebc3899ede9d9e433eb66652c62f465e9beeac` | Compact placement. |
| `android-widget/perfect-widget-home-resized.png` | 1080x2400 | `7d55003e4e0155b31ccf6b18a1d6aa1ad25b7027bc84a0bd1b2acb757b0a248c` | Resized host layout. |
| `android-widget/perfect-widget-populated3.png` | 1080x2400 | `5cba98ed16f9ef9c7b01e11ad883af791f86339a1f7a1b462f193474b4a8b39a` | Scrollable populated collection. |
| `android-widget/perfect-widget-scrolled-end.png` | 1080x2400 | `da17796080db5214fa5c948c9cdf41c696ff299282793a5ab92d1a4c71199f15` | End-of-list reachability. |
| `android-widget/perfect-widget-cycle-partial.png` | 1080x2400 | `cc2e874c239b0e3e1a6e453cc07f4bed577c7a0510d72d528e4db047810a04f9` | Direct outcome-cycle partial state. |

## Baseline findings

1. Orbit dominates compact height and duplicates `next`, time and task-count data
   already represented below.
2. Curved labels/ticks have inconsistent clearance; 6 o'clock labels drift outside
   while 12 o'clock is inside.
3. Wide layouts place two loosely related cards beside each other and can still leave
   a large unproductive canvas.
4. AI-open compact state stacks separate AI and Quick Capture panels, clips starter
   content and consumes nearly the entire screen.
5. Footer, capture and desktop composer sometimes read as independent attached bars
   rather than one floating system.
6. Tablet rail behavior exists, but portrait content remains a stretched sequence
   and the rail consumes disproportionate width when expanded.
7. Inspector is information-thin and visually detached; it cannot replace a full
   view-first detail/history experience.
8. Widget interaction evidence is stronger than its brand/composition polish and
   Quick Add flow still requires the Stage 48 canonical design.
9. Tasks, Plan and Habits use unrelated page compositions and oversized headings;
   scanning rhythm, control anatomy and footer clearance do not feel like one system.
10. Current task status controls alternate between ring, percent text and missed icon
    geometry; the visual/control contract is not stable across rows.
11. The Habits week strip compresses `Sat Sun`, count logging dominates the card and
    progress/schedule information is nested inside a large container.
12. More/settings content continues behind the floating footer, while feedback and
    appearance consume disproportionate early space.
13. Quick Capture and Perfect AI are separate stacked panels. The expanded capture
    repeats its own title, keeps three large mode tiles and the AI prompt truncates.
14. Normal Task tap opens Edit directly and asks for immutable Type again, proving the
    view-first detail gap rather than merely describing it.

## Coverage gaps that remain part of Stage 03

The baseline is intentionally honest. It now covers all five current primary phone
destinations plus the most consequential current capture/AI/sync/create/edit states,
but it does **not** pretend to cover every final route/state required by the
preview-production gate:

- Goals/Projects, Focus, deep Settings, diagnostics/feedback and full detail routes
  at all layout classes where the final surface is absent or incomplete;
- every branch of the current task/recurring/habit wizard and edit-only composition;
- dark/high-contrast, 200% text, mixed Persian/English, IME, offline/retry/error/
  conflict and reduced-motion matrices beyond the two frozen dark phone examples;
- authenticated live Windows hover/focus/context behavior;
- widget Quick Add dialog and all native size families.

These are not silently waived or replaced by generated UI. Stage 02's source-backed
route inventory is the exhaustive current behavior authority; the opinion ledger
marks genuinely absent surfaces as `ADD`/`REDESIGN`. Stage 04/05 must provide the
complete canonical component/page/state matrix before production implementation.

## Fixture boundary

Names such as `Focus Deep Work` and `Water plants` in the synthetic goldens are
preview fixtures. They are not allowed in production seeds or a signed fresh-owner
flow. Later stages must retain the existing production-fixture isolation tests and
add manifest scanning for every new preview fixture.

## Stage 06 installed-brand comparison

Captured 2026-08-10 on the same Pixel Android 15/API 35 host. The `before`
frames freeze the installed production baseline; the `after` frames use the
non-production sibling package after an in-place `2000 -> 2045` preview update.
The different auth/config substate in the first-frame pair is not a page-layout
comparison; that pair is evidence only for mark/wordmark geometry and rendering.

| File | Pixels | SHA-256 | Evidence |
| --- | ---: | --- | --- |
| `stage06-brand/android-splash-after.png` | 1080x2400 | `f0a558d0620f6ececfba96d5a03e15c3afd767b419c4076cb2818b4e354e0138` | Dedicated system-splash canvas shows all six modules and the owner core without circular clipping. |
| `stage06-brand/android-splash-dark-before.png` | 1080x2400 | `11437e7f487d1e13fffd2aa34838a4ff7ab74f14cdeda5b443f3357c80300334` | Dark-mode adversarial capture: geometry is complete but the graphite owner core merges into the night canvas. |
| `stage06-brand/android-splash-dark-after.png` | 1080x2400 | `1a80006ce437e226441cc894568fa587ee0b0e90d726d60648ec705ea40902a6` | Night-qualified splash preserves geometry and lifts only the owner core to warm white. |
| `stage06-brand/android-app-drawer-after.png` | 1080x2400 | `4f5a45dc935b46c365f465251acc89e5ad4b32ab8f3c9551bfe2dc130f100c8a` | Old/new Perfect! installs coexist, exposing the regenerated adaptive safe inset under the same Pixel mask. |
| `stage06-brand/android-first-frame-after.png` | 1080x2400 | `7842dcf936b7e0cf68c21be0b126ae51683c5c2994ed6bd569dc8e9118d35860` | Path wordmark and optically aligned Day Compass render in the real Flutter first surface. |
| `stage06-brand/before-after.png` | 900x3180 | `e0de44c73cfaccbb0a68f605fedb2db6a0d4e94adfa7d09990bb384e5ef22452` | Uncropped light/dark side-by-side inspection sheet; the SVG source retains the original PNG links. |
