# Stage 05 — Full-product page preview library, Copy contract and quality harness

Status: complete locally — `ps01-pages-1.0.0` frozen; hosted checkpoint pending
Depends on: Stage 04 frozen component preview catalog  
Blocks: every production UI implementation in Stages 06–50

## Mission

Compose the Stage 04 components into a complete, high-fidelity preview corpus for
**every Perfect! page, route, overlay and native widget surface** before rebuilding
the shipped UI. Freeze those previews as the visual/interaction contract, then build
the deterministic comparison and test harness that later stages must use to copy,
measure, critique and verify the runtime result.

This is the final design-only gate. It may create preview assets, fixtures,
storyboards, contact sheets and test tooling, but it must not replace production
widgets. Stage 06 is the first stage allowed to implement the frozen visual system.

## Autonomous design authority

The owner has delegated ordinary design decisions. Do not stop for concept voting.
For each surface, generate materially different compositions, run Modernize,
Integrity, Anatomy, Style and adversarial Critics gates, choose the strongest option,
record why it wins, and freeze it. Ask only if a real product-authority, privacy or
irreversible-data choice cannot be inferred from the product contract.

## Page and surface preview registry

The exact authoritative IDs, required states and artifact schema live in
[preview-production-gate.md](preview-production-gate.md). The corpus must include:

### Entry, shell and navigation

- launcher/splash/bootstrap, configuration, sign-in, password recovery/update,
  session-expired and recoverable bootstrap failure;
- Today, Tasks, Plan, Habits and More inside compact phone, Android tablet and
  compact/intermediate/expanded Windows shells;
- collapsed/expanded desktop rail, short-landscape rail, icon-only floating footer,
  compact glass header, sync detail and desktop inspector/open-detail compositions;
- route enter/exit and live resize storyboards that preserve focus, draft, scroll,
  selection and navigation state.

### Core planning workflows

- Today with zero, one, normal and dense data; next action, task/habit mixtures,
  flexible work, completed work, local-ready/syncing/offline/retry/error/conflict;
- collapsed Quick Capture and Task, Plan, AI, Voice, proposal, apply, Undo, error and
  interrupted morph states, with and without IME;
- Task and recurring-task creation wizard, Habit creation wizard, safe edit wizard,
  validation/recovery preview, discard/save and draft restoration;
- Task, recurring-task and Habit view-first detail routes with history, calendar,
  analytics, relations, reminder/focus actions and lifecycle menus;
- Tasks search/filter/sort/group/saved-view/bulk-action workspace;
- Plan day/week/month, time blocks, current time, unscheduled tray, overlap/conflict,
  drag/move/cancel and dual-date transitions;
- Habits today/logging/insights/build-maintain-quit views, all tracking methods,
  multiple-per-day controls, correction, streak risk and recovery;
- Goals, Projects, Areas, Notes and week/month/quarter/year horizons;
- Focus setup/timer/pause/background/reflection/history plus restrained streak,
  achievement and reward feedback.

### Owner tools, recovery and native surfaces

- profile/settings, theme, reminders/quiet hours, widget settings, AI settings,
  archive/trash, conflict center, insights/reviews, diagnostics and update status;
- feedback launcher/menu, screenshot capture/redaction, note-only draft, entry list,
  entry detail, export confirmation/success/error and recovery;
- backup/export/import/dry-run/deduplication/error/recovery;
- notifications, deep-linked results, stale/deleted targets and Windows protocol open;
- Android widget in every supported resize class: header, empty, compact summary,
  actionable scroll list, task status cycle, habit increment, Quick Add dialog,
  offline/pending/sync/error and deep-link results.

## Composition requirements

Every page preview must be built from canonical Stage 04 component IDs; local one-off
styles require an explicit named exception. Each composition records:

1. primary user question and action hierarchy;
2. scan path, reach zones, keyboard order and semantic reading order;
3. content-width, pane and density equations, including short-height behavior;
4. scroll owner, sticky/floating layers, occlusion clearance and final-action reach;
5. live text versus vector/raster/hybrid asset layers and exact z-order;
6. sparse, normal and dense behavior without demo entities entering production;
7. loading, local-ready, optimistic, syncing, offline, retry, conflict, hard-error,
   destructive and success/Undo states where relevant;
8. phone portrait/landscape, tablet portrait/landscape/split and Windows compact/
   intermediate/wide transformation rather than a stretched phone layout;
9. light, dark, high contrast, 100/200% text, English, Persian and mixed direction;
10. first/mid/end/interrupted/reversed/reduced-motion frames for every transition.

## Preview exploration and acceptance loop

1. Freeze current runtime screenshots and exact usability/visual failure statements.
2. Compose at least three structurally distinct candidates for each page family; do
   not vary only color or decoration.
3. Reject candidates that add taps, hide the primary action, waste adaptive space,
   overuse glass/cards, break familiar control semantics or create state ambiguity.
4. Compare surviving candidates in sparse and dense contact sheets at each layout
   class and inspect geometry at native resolution and thumbnail scale.
5. Stress long bilingual text, 200% scale, IME, short landscape, continuous Windows
   resize, dark/high contrast and reduced motion before selecting a winner.
6. Record the internally accepted candidate, decision rationale, remaining risk and
   immutable preview ID/hash. Keep rejected work outside canonical paths.
7. Produce a preview-to-production decomposition manifest: component IDs, live text,
   assets, tokens, responsive equations, semantics, interactions and motion IDs.

## Copy fidelity contract

Every later UI stage must use this closed loop:

1. select the exact frozen preview ID and affected consumer list;
2. implement from its decomposition manifest, never by visual memory;
3. capture real Android/tablet/Windows runtime output with the same fixture/state;
4. normalize viewport, device scale, crop and font scale;
5. create labeled `reference | runtime | overlay/diff` contact sheets;
6. log mismatches by hierarchy, geometry, text, asset, color/material, state,
   interaction, motion, responsiveness and accessibility;
7. fix from highest-perceptual-impact mismatch downward;
8. repeat until every non-zero mismatch is either corrected or documented as an
   intentional adaptive/runtime exception with evidence.

“Same vibe,” compilation, no overflow or one attractive screenshot is not Copy
acceptance. The target is pixel-faithful where geometry is fixed and
behavior-faithful where content/platform constraints require recomposition.

## Deterministic fixture lattice

- **Empty owner:** zero entities/history/conflicts, valid session, synced.
- **Sparse owner:** one unscheduled task and one simple habit.
- **Normal owner:** realistic day/week with mixed scheduling and tracking methods.
- **Dense owner:** long mixed-language titles, overlapping/recurring tasks, all
  progress states, all habit methods, relations, notes, goals, conflicts and history.
- **System:** first local load, local ready, syncing, retrying, offline, auth-expired,
  recoverable/hard error, AI proposal and widget-origin mutation.
- **Time:** 00:00, 05:59, noon, 18:00, 23:59, timezone changes and Gregorian/Jalali
  day/month/year boundaries.

Fixtures live behind a separate development/test entrypoint and can never seed,
merge with or become reachable from the signed owner build.

## Automated quality harness

1. Deterministic fixture factories and scenario IDs shared by preview/runtime capture.
2. Golden scenarios for every page family, layout class, theme and critical state.
3. Geometry assertions for overlap, viewport containment, paired-edge symmetry,
   optical center, minimum hit target, safe line length and final-action reachability.
4. Semantic-tree assertions for label, role, value, state and action uniqueness.
5. Interaction drivers for task state cycles, rapid habit increments, wizard paths,
   keyboard traversal, context menu, resize, IME, outside dismissal, back and deep link.
6. Android emulator and Windows runtime screenshot/recording scripts.
7. Automatic reference/runtime/diff contact sheets and mismatch-ledger skeletons.
8. Motion capture for page transition, title rise, dock morph, sheet/dialog, selector,
   completion, sync, resize and reduced-motion alternatives.
9. Frame timing, memory and rebuild capture around composer, lists, detail and wizard.
10. Release artifact smoke checks, fixture-leak detection and secret scan.
11. CI output that names the exact page/component/state/viewport and evidence path.

## Visual and behavioral critique gate

For every accepted composition, inspect hierarchy, scale, type rhythm, icon/text
adjacency, optical alignment, symmetry, asset craft, blur edges, contrast, negative
space, action continuity and platform ergonomics. Then execute every visible action,
including cancellation/error paths, by touch/mouse/keyboard where applicable.

Record:

- one evidence-backed reason the selected preview is better than current runtime;
- one strongest rejected alternative and why it lost;
- one residual risk and the later stage that owns it;
- confirmation that all affected consumers in `coverage-ledger.md` were classified.

## Required evidence

- one versioned page registry with no missing route/overlay/widget surface;
- canonical preview, component manifest and motion IDs for every registry row;
- all required viewport/theme/density/state contact sheets;
- deterministic fixture IDs and proof fixtures cannot reach production;
- working normalized side-by-side/diff pipeline on at least one phone, tablet and
  Windows composition before Stage 06;
- canonical local and CI commands with an intentionally introduced failure proving
  that the exact surface/state is identified.

## Reject the stage if

- any production UI work starts before the component and page preview registries are
  complete and frozen;
- a page mockup invents undefined local controls or ignores its Stage 04 contracts;
- only a happy-path light phone screen exists;
- an image-generated mockup is accepted with misspelled/flattened dynamic text;
- a graphic-heavy surface is approximated with generic Flutter primitives instead of
  the asset/vector/hybrid route required by the preview;
- goldens are blindly updated, widget tests substitute for real runtime graphic proof,
  or a passing focused test is presented as full device/release evidence;
- owner choice is requested for an ordinary design decision already delegated to the
  autonomous quality gates.

## Completion evidence — 2026-08-10

- The authoritative Section 5 gate resolves to exactly 134 unique page IDs in
  canonical order across 11 families. Each owns three structural candidates, one
  autonomous decision record and ten canonical compositions.
- The frozen corpus contains 402 candidate boards, 1,340 canonical PNGs and 1,340
  browser-derived audits spanning exact phone portrait/landscape, tablet portrait/
  landscape, Windows compact/wide, dark, 200% mixed-direction stress, system-state
  and motion layouts.
- Every audit verifies exact document/root bounds, required live copy and platform
  chrome, with zero uncontained horizontal overflow, clipped required phrases or
  failure IDs. Visual/contact-sheet review corrected the defects the gate exposed.
- All 181 Stage 04 component IDs have explicit reverse consumers. The Copy registry
  contains exactly 1,072 unique live/unflattened entries (8 per page), and all six
  deterministic fixtures are unreachable from production persistence.
- Three normalized comparison smokes deliberately inject phone geometry, tablet
  typography and Windows state defects. Each produces reference/runtime/overlay/diff
  evidence, identifies page/scenario/category/field and exits 2 under the failure
  contract.
- `stage05-hashes.sha256` covers all and only 2,055 generated files. Generation is
  limited to the 134 owned page roots and named sheets; the Stage 03 handoff is
  snapshotted and hash-verified before and after generation. Scoped LF attributes
  preserve those byte hashes across Windows and CI checkouts.
- `node tool/verify_stage05_page_library.cjs` passes with
  `pages=134 candidates=402 previews=1340 audits=1340 components=181 copy=1072
  fixtures=6 comparisons=3 hashes=2055`. The Flutter contract passes 9/9, the Stage
  03+04 chain passes 25/25 and full analysis is clean.
- No production Flutter/native/domain/database/auth/sync/Supabase source belongs to
  this stage. Existing user prototypes and the retained stash remain untouched.

## Completion handoff

Freeze the page registry version, canonical preview hashes, decision records,
preview-to-production manifest, fixture IDs, motion storyboards, Copy comparison
pipeline and verification commands. Commit/push design and harness artifacts. Do not
publish a runtime release when production bytes did not change. Stage 06 receives an
exact preview ID and must not improvise outside it without reopening this gate.
