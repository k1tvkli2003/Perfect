# Stage 12 modernization decision — Guided Command Center

Status: runtime-reviewed implementation; Windows current-source build pending host ATL repair
Modernization mode: radical rebuild of Today composition, behavior preserved
Selected: Midnight Command Center geometry with Paper Ledger light-mode material
Decision date: 2026-09-22

## Product truth

Today must answer, in one scan:

1. What needs a decision?
2. What is next?
3. What is scheduled?
4. What is flexible?
5. What habit remains?

Canonical planner data, progress, persistence, recurrence, recovery, sync, inspection and creation behavior remain authoritative. Generated preview copy is never product truth.

## Selected direction

**Guided Command Center**

- Dark: Midnight Ink shell, warm paper focal surface, cobalt action, green completion, coral urgency.
- Light: Paper Ledger canvas, white live surfaces, cobalt selection/action, minimal shadow.
- Phone: one scrollable pane. Compact day command bar, one Next emphasis, grouped agenda, safe bottom padding. Detail stays route/sheet based.
- Tablet: agenda-first master/detail only while list >= 520 dp and inspector >= 360 dp; otherwise inspector becomes a sheet.
- Wide desktop: compact/labeled navigation, dominant agenda, attached 340–380 dp inspector. Stage height follows agenda content, not an arbitrary 600 dp inspector floor.

## Keep / refine / reject

KEEP:
- Existing canonical `PlannerTodayStream` section order and stable IDs.
- One semantic Next action.
- Real task/habit progress controls.
- Agenda-first timeline and explicit `Scheduled`, `Anytime`, `Habits`, decision, settled groups.
- Existing keyboard, semantics, persistence and reduced-motion contracts.

REFINE:
- Today Pulse becomes a compact command bar, not a hero illustration.
- Day stream becomes dominant surface.
- Next row receives a restrained cobalt rail/tint; no duplicate hero task.
- Inspector uses content-led occupancy and independent scroll.
- Semantic palette becomes cobalt / completion green / urgency coral with warm-paper light and midnight dark surfaces.

REMOVE:
- Decorative pastel gradient hero.
- Curved ornamental progress line.
- All-caps decorative eyebrows where sentence case gives the same meaning.
- Fake hourly positioning for flexible items.
- Generated sample tasks, notes, counts, labels and unsupported interactions.
- Card-inside-card stacking and high-radius surface repetition.

ADD:
- Responsive one-pane/two-pane constraints.
- Explicit selection/current-time/focus-state separation.
- Long-copy, 200% text, dark/light/high-contrast, sparse/dense and bottom-safe-area proof.

## ImageGen evidence

Provider path: local 9router image endpoint
Model alias: `cx/gpt-5.5-image`
Credentials stored in project: no

Final-direction previews:
- `artifacts/stage12-modernize/directions/a-midnight-command-center.webp`
  - SHA-256 `590e4ea51f5f923415302f70f73f3b465a8a5d3cced31013825d4358c690372c`
- `artifacts/stage12-modernize/directions/b-paper-ledger.webp`
  - SHA-256 `67032d8c5ed6252cd80ea66cb846f77f22abea3ea6b84d79ba742411edce0f64`
- `artifacts/stage12-modernize/directions/c-orbit-workbench.webp`
  - SHA-256 `473ff3cce92156dca5f0f196078e9094eff72afb519bd67aab323be2ea3d3686`

Canonical responsive references:
- `artifacts/stage12-modernize/canonical/phone-dark-390x844.webp`
  - SHA-256 `9b903a85beb9dfc7d5d532caf47800175274cbe47fb27956d7b36405faf5603a`
- `artifacts/stage12-modernize/canonical/tablet-light-834x1112.webp`
  - SHA-256 `680ab29409eb19cba333cf2edbadb1990ef5635d3a2e3171edc9240e427210be`
- `artifacts/stage12-modernize/canonical/desktop-light-1536x1024.webp`
  - SHA-256 `d7162ba696beb419b2f88bc5ba02d1f0e4da7fccade9389aa8c83e7c79161abf`

## Execution evidence — 2026-09-23

- RED/GREEN focused behavior: `compact pulse names its future boundary without claiming the next action` passes; semantics expose `NEXT BOUNDARY` separately from row emphasis.
- Flutter verification: `flutter analyze --no-pub` clean; `dart format --output=none --set-exit-if-changed lib test` clean; full sequential suite `505/505` pass.
- Golden verification: the 8-test workspace subset and 5-test header suite pass after hash-receipted refreshes in `artifacts/stage12-runtime/golden-refresh-2026-09-23.json` and `artifacts/stage12-runtime/header-golden-refresh-2026-09-23.json`; canonical design references remain unchanged.
- Native Android: current debug APK installed and launched on `Codex_API35`; settled phone, tablet portrait and tablet landscape screenshots plus UI hierarchy reviewed. Pulse, grouped agenda, one next-row emphasis, safe footer and responsive rail are present; selected row opens existing `Edit details` route.
- Windows limitation: `flutter build windows --debug --no-pub -t lib/dev/perfect_live_preview.dart` cannot complete on this host because Visual Studio BuildTools lacks `atlmfc/include/atlbase.h`. Attempted ATL component repair returned installer `Exit Code: 5007` (elevation required). Pre-existing executable was not counted as current-source proof.
- PWA limitation: project is not configured for web; `flutter build web` reports `This project is not configured for the web`. The 2026-09-17 master-plan amendment supersedes the old brief exclusion: PWA is in the 50-stage scope, with browser/storage/auth compatibility and hosted delivery gates later in the plan. This Stage 12 native proof does not close PWA.

## Non-goals for Stage 12

- Task-row anatomy and status-control rebuild: Stage 13.
- Habit logging interaction rebuild: Stage 14.
- Full state matrix: Stage 15.
- Quick Capture visual architecture: Stage 16.
- Full desktop inspector/editor architecture: Stage 35.
- Focus visualization: Stage 40; Orbit Workbench may inform that stage.

## Acceptance

Stage 12 remains open until:
- New behavioral/layout tests fail before implementation and pass afterward.
- Analyzer and complete non-golden suite pass.
- Fresh phone/tablet/desktop runtime screenshots are reviewed against these references.
- Intentional visual changes replace old goldens only after runtime review.
- Build and actual launch path are proven.
