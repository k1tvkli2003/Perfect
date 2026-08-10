# Stage 04 — Responsive design system and component preview library

Status: complete locally — `ps01-ds-1.0.0` frozen; hosted checkpoint pending
Depends on: Stage 03 internally accepted direction
Blocks: page composition previews and every production UI implementation

## Mission

Turn the selected direction into an exhaustive, state-complete visual and
interaction specification for **every reusable component before it is coded**.
Each component is designed in isolation first, then tested beside siblings so its
proportion, hierarchy and behavior belong to one Perfect! system.

This stage may create design assets, deterministic preview fixtures and design-only
rendering tools. It must not redesign shipped Flutter widgets in place. Runtime UI
implementation begins only after Stage 05 accepts the complete component + page
preview corpus.

## Geometry model

- Intrinsic size owns live copy, fields and content-sensitive controls.
- Flex/grid owns sibling distribution; bounded fractions own major panes.
- Aspect ratio is used only where a composition carries meaning.
- Fixed semantic tokens own hit targets, icons, strokes, radii and rhythm.
- Breakpoints are triggered by content viability and interaction mode, not device
  labels alone.
- Mathematical alignment is the baseline; optical centering corrects glyph, icon,
  highlight and shadow mass and is recorded as a token/exception.
- Width and height both participate. Short landscape, split-screen, IME intrusion and
  intermediate Windows resize are first-class constraint classes.

## Design-system specification packets

1. **Foundation tokens:** color roles and paired foregrounds; type roles; spacing,
   radius, elevation, blur, stroke, icon, hit-target and focus tokens; motion roles;
   safe-area and content-width equations.
2. **Typography:** corpus-derived Latin/Persian profiles, exact wordmark image,
   numeral/date policy, bidi isolation, real weights, fallback metrics, license and
   font-failure behavior.
3. **Iconography:** one optical family for familiar actions, project-owned SVG
   pictograms for category/brand concepts, directional mirroring rules and no raw
   keyboard emoji.
4. **Material:** quiet page canvas, repeated-row treatment, glass only for floating
   layers, authored highlights/shadows and non-blur/high-contrast fallbacks.
5. **Responsive equations:** compact/medium/expanded/wide plus short-height variants;
   navigation transformation; pane min/max; readable line length; scroll clearance;
   state preservation across breakpoints.
6. **Motion Bible:** IDs, triggers, first/mid/end frames, interruption, reverse,
   background/resume, reduced/no-motion alternatives and frame/resource budgets.
7. **Asset manifest:** every raster/vector/live/hybrid/build-time layer, source,
   license, crop/anchor, theme/density variants, workspace export path, semantics and
   performance budget.

## Mandatory component preview inventory

The authoritative detailed checklist lives in
[preview-production-gate.md](preview-production-gate.md). At minimum, build
separate preview plates for all families below; no family may be represented only
inside a full-page mockup.

### Identity, shell and navigation

- Perfect mark, selected wordmark, launcher/splash variants and category pictogram;
- compact glass header, page title, dual date/time, three-state Sync Cloud and detail;
- phone floating footer, destination states, compact/expanded rail, rail switch,
  tooltip, keyboard focus and short-landscape navigation;
- page frame, inspector divider/handle, glass/solid surface and safe-area treatments.

### Common controls and state surfaces

- primary/secondary/ghost/destructive buttons, icon buttons and split actions;
- fields, search, multiline note, password, voice input and IME/focus/error states;
- chips, filters, segmented views, custom category/icon/color selector, toggle,
  checkbox, radio, slider, count/value/time stepper, date/time/calendar pickers;
- menu, context menu, tooltip, toast/snackbar/Undo receipt, progress, skeleton,
  empty/loading/error/offline/conflict/permission/destructive states;
- dialog, bottom sheet, compact popover, full-screen route, inspector and wizard
  footer/header/progress.

### Planner-specific components

- Task row at every status, recurrence/schedule/category/checklist variant and
  unified multi-tap status control with arc-only partial progress;
- Habit row/control for boolean, count, duration, numeric, checklist and formula,
  including rapid increment, decrement/correction, over-target and streak receipt;
- Today Pulse, day-group heading, next-action emphasis and stream continuation;
- Quick Capture collapsed orb and Task/Plan/AI/Voice/proposal morph states;
- detail fact groups, event timeline, month calendar, habit heatmap, metric/trend,
  lifecycle actions and desktop inspector;
- task/plan/habit filter/search/sort/group/saved-view/bulk-action components;
- day/week/month planner cells, time blocks, unscheduled tray and conflict cues;
- goal/project/area/note relation, horizon/checkpoint, focus timer, reflection,
  streak/achievement/reward receipt and non-manipulative celebration.

### Secondary, recovery and platform components

- auth/configuration/password/session-expired surfaces;
- settings/profile rows, reminder/quiet-hour controls, widget settings, archive/trash,
  conflict center, insights/reviews, backup/import/export/recovery and diagnostics;
- unobtrusive feedback launcher, capture menu, screenshot preview/redaction, note,
  entry list/detail and private export confirmations;
- Android widget header, list row, multi-state action, habit increment, scroll cue,
  Quick Add and every supported resize family;
- notification/deep-link state, Windows protocol/open result and release/update/error
  surfaces that the owner actually sees.

## State and comparison plate rules

For each component, create:

1. base anatomy with bounds, slots, alignment axes and live/asset layers;
2. default, hover, focus, pressed, selected, disabled and loading where applicable;
3. optimistic/pending, success/Undo, warning, offline, syncing, conflict and error
   states where domain-relevant;
4. light, dark and high-contrast treatment;
5. LTR, RTL and mixed English/Persian samples, short/long copy and 200% text;
6. compact phone, tablet and Windows density/interaction variants;
7. first/mid/end/reversal/reduced-motion frames for animated state changes;
8. neighbor plate showing the component beside real siblings, not in aesthetic
   isolation.

## Component contract card

Every preview has a paired contract:

```text
component_id / version:
purpose and correct use:
anatomy and slots:
canonical semantic owner:
live inputs / outputs / mutation:
states and precedence:
phone / tablet / Windows transformation:
touch / mouse / keyboard / screen-reader behavior:
RTL / mixed-script behavior:
token and asset dependencies:
motion and reduced-motion behavior:
performance budget:
preview paths:
known intentional variants:
```

## Preview production workflow

1. Audit current tokens/components and duplicate semantics.
2. Define the canonical component contract before drawing variants.
3. Generate or deterministically compose high-fidelity preview plates; keep live
   copy exact and do not trust generated text for product names/Persian.
4. Run graphic-craft escalation: layered material/illustration/brand geometry uses
   a professional vector/raster/hybrid route, never a generic primitive shortcut.
5. Compare the component in isolation and beside all important siblings.
6. Stress geometry at 320, 390, 600, 900, 1024, 1366 and expanded logical widths,
   plus short/tall heights and 100/200% scale.
7. Record `KEEP/REFINE/REDESIGN/REMOVE/ADD`, mismatch, fix and internally accepted
   final variant.
8. Freeze final preview path/hash and decomposition manifest; rejected variants stay
   clearly separated from canonical assets.

## Whole-product propagation

Each semantic component gets one canonical owner and a consumer list. A status
control, selector, field or row is incomplete until every Today/workspace/detail/
editor/widget/AI/settings consumer is either mapped to the shared contract or
documented as an intentional platform variant. Add drift-prevention tests/lints to
the later implementation plan at the cheapest authoritative boundary.

## Verification and required evidence

- Exact inventory count equals the checklist count in the preview gate; no silently
  missing component or state.
- Every preview has a contract card, decomposition entry, responsive variants and
  asset provenance.
- Component proportions use named math/ratio rules; optical corrections are visible
  in comparison plates.
- Every interactive component has stable outer geometry across state changes, a
  >=48dp touch region and clear hover/focus/press semantics.
- Dedicated art is inspected at native and small scale in both themes.
- No preview relies on fake sample content that could become production seed data.

## Reject the stage if

- A full-page mockup hides undefined components or missing states.
- Only default/light/phone appearance exists.
- Generated UI text is misspelled, flattened despite being dynamic, or used as the
  implementation plan for live controls.
- No-overflow is treated as proof of composition quality.
- A generic card/icon/gradient/painter substitutes for crafted graphic material.
- Separate pages are allowed to invent local spacing, radius, status, selector,
  field, navigation or motion contracts.

## Completion evidence — 2026-08-10

- The gate inventory resolves to exactly 9 foundations and 181 unique components
  across 27 semantic families. The versioned registry freezes 1,267 component PNG
  previews, 48 transparent category SVGs and 20 named motion contracts.
- Every component owns a machine-readable `contract.yaml`, one anatomy SVG and
  seven `1200×800` evidence boards: light states, dark states, responsive,
  accessibility, motion, and real-neighbor composition.
- Foundation, family and whole-catalog contact sheets were generated from the same
  source model. Critical rows, Today Pulse, Capture morphs, AI proposal review,
  wizard scheduling, widget resize and light/dark/high-contrast stress boards were
  inspected at original size.
- The inspection pass replaced cramped task geometry, clipped responsive/motion
  frames, low-contrast dark text, raw habit glyphs and generic widget scaling with
  component-specific PS01 compositions and semantic Lucide/project SVGs.
- `stage04-hashes.sha256` covers exactly 1,576 generated files. Verification parses
  all 238 SVGs, checks every PNG signature and exact dimensions, rejects raw emoji,
  proves transparent category marks and detects missing, stale or altered evidence.
- Palette-aware lossless container optimization reduced the frozen design corpus to
  148.18 MiB without changing the canonical `1200×800` geometry. The largest file
  is 4.49 MiB, below GitHub's per-file limit.
- `node tool/verify_stage04_design_system.cjs` passes with
  `foundations=9 components=181 previews=1267 hashes=1576 svg=238 icons=48
  motions=20`; the focused Flutter contract passes 8/8 and focused analysis is
  clean.
- No production Flutter UI, native code, route, domain, database or Supabase file
  belongs to this stage. Stage 05 remains the final page-composition and Copy gate.

## Completion handoff

Freeze the component catalog version, token math, Motion Bible, asset/decomposition
manifest, preview hashes and internally accepted component variants. Stage 05 may
compose pages only from this library. Commit/push design artifacts; do not publish a
runtime release when production bytes did not change.
