# Stage 39 — Goals, projects, areas and planning horizons

Status: blocked — Stage 03–05 preview/Copy gate plus Goal/relation/measure/horizon contracts have no recorded autonomous acceptance; no runtime vertical slice exists yet
Depends on: accepted Stages 03–05 preview/copy contract; Stages 21–25,
31–38  
Primary surfaces: Goals, Projects, Areas, relation management, week/month/
quarter/year review and forecast

## Mission

Give Perfect! a truthful planning hierarchy above the day: Areas express enduring
responsibility, Projects express finite delivery, Goals express measurable outcomes,
and horizon reviews connect them to actual Tasks, Habits and Focus evidence. The result
must support realistic replanning, not ornamental progress dashboards.

## Autonomous semantic decisions

- **Area:** an ongoing responsibility with no completion percentage, for example
  Health or Learning. It can be active/archived and owns standards/context.
- **Project:** a finite outcome container with lifecycle (`active`, `onHold`,
  `completed`, `cancelled`, `archived`), optional target date and child actions.
- **Goal:** a measurable owner-authored outcome with one horizon, one or more explicit
  measures, checkpoints and linked Projects/Tasks/Habits. A goal is not a renamed
  Project and is never inferred automatically from a title.
- **Horizon:** an owner-relative civil interval (`week`, `month`, `quarter`, `year`)
  with timezone and week-start/fiscal-calendar policy. It is a projection boundary,
  not an entity copied for every period.
- A Task/Habit/Focus record is counted through a unique contribution identity. The
  same durable event cannot count twice because it is linked through both Project and
  Goal.
- Progress is explainable measure by measure. Incomparable measures are never averaged
  without explicit owner weights and a visible formula; no hidden “73% productive”
  score exists.
- Editing/deleting a parent never cascades into child data by default. Relations are
  reassignable and history remains attributable.

## Preview and Copy fidelity gate — before any runtime edit

No runtime or schema implementation starts until the internally accepted Stage 03–05
Perfect! direction is available and this stage's previews carry a recorded autonomous
acceptance decision. If that record or a required reference is missing, the stage
remains preview/spec work only.

1. Run Modernize in **Radical rebuild** mode for the current Projects/Areas commands
   and missing Goal/Horizon surfaces: generate at least 24 product-specific recipes,
   shortlist 6–8 and render 2–4 final directions. Explore instrument/ledger/horizon
   metaphors, but reject generic KPI bento grids, progress-ring walls, corporate OKR
   clones and decorative roadmaps.
2. Build Integrity's five-way opinion ledger for Goal/Project/Area identity, relation
   selector, measure editor, checkpoint, progress explanation, hierarchy/browser,
   horizon navigator, review/forecast, replan proposal, detail/inspector, empty/error/
   conflict, Today/checkpoint, capture/wizard, AI, widget/notification and export.
3. Produce an **individual preview plate for every component**: hierarchy node/row;
   Goal/Project/Area identity header; typed relation chip; measure type/value/weight;
   contribution receipt; progress/explanation bar; checkpoint row; horizon selector;
   review prompt; forecast load strip; replan diff; create/edit selector; archive/
   delete/relation consequence dialog; no-data/loading/offline/conflict; and keyboard,
   hover, focus, press, selected, disabled, busy, success, warning and error states.
   Each plate records live semantics, SVG/raster/live/hybrid route, geometry tokens,
   alignment/axis, theme pairing, 48dp target and motion/reduced-motion behavior.
4. Produce accepted full-page previews for Goals overview, Goal detail/review, Projects,
   Areas and each week/month/quarter/year horizon composition at phone portrait, short
   phone landscape, tablet portrait/landscape with both rail states, and 720x540,
   1024x640, 1366x768 and 1600+ Windows. Cover zero/one/dense hierarchy, long mixed
   Persian/English, 200% text, light/dark/high contrast, reduced motion, optimistic,
   insufficient evidence, complete, overdue/checkpoint, offline/retry/conflict,
   orphan-repair and archive/restore states.
5. Build the Anatomy route/task map and compare at least two IA candidates. The chosen
   route must keep recurring review within two obvious actions of its owning workspace,
   distinguish destination/local horizon modes, preserve deep-link/back context and
   specify compact/medium/expanded transformations plus frame/occupancy equations.
6. Create the preview-to-production decomposition manifest for every visible layer and
   asset, including custom Day Compass measure/horizon pictograms. All owner copy,
   metrics, controls and critical explanations remain live; generated art is exported
   to project-owned assets with provenance and responsive crop rules.
7. Record internal acceptance under the owner-delegated autonomous design authority.
   Implement via Copy component inventory and exact viewport/
   state comparisons: reference → runtime screenshot → normalized side-by-side/diff →
   mismatch repair. Repeat from macro composition to micro geometry for every page and
   responsive sibling; close the precision, mismatch, occupancy and opinion ledgers.

## Detailed work packets

1. Freeze current Project/Area create/edit/list/relation behavior, Supabase constraints,
   agent ingestion kinds, AI allowlists, More commands and every payload consumer.
2. Write the concept-to-consumer matrix and choose canonical semantic owners. Add
   `goal` as a first-class `PlannerEntityKind`; update local/database/Supabase CHECKs,
   JSON schemas, RPC validation and old-client unknown-kind behavior additively.
3. Introduce typed relation records rather than relying only on unvalidated payload
   maps. Migrate existing Project/Area relations deterministically, preserve payload
   compatibility for older clients and prevent cross-owner/cyclic links at trusted
   boundaries.
4. Define typed Goal, measure, checkpoint, contribution and horizon projection
   contracts. Add local tables/indexes, migrations, RLS/RPC/sync snapshots and operation
   targets needed for an end-to-end vertical slice; Stage 41 later canonicalizes them
   without breaking IDs or meaning.
5. Extend the Stage 21 wizard for Goal/Project/Area create/edit using the accepted
   selectors: identity → outcome/standard → horizon/date → measures → relations →
   checkpoints → review. Preserve kind on Edit and support draft restoration.
6. Build hierarchy queries with bounded descendants/ancestors and clear lifecycle.
   Enforce DAG constraints for relation types that must not cycle, cardinality and
   unique relation identity owner + from + type + to.
7. Implement deterministic progress calculation. Resolve direct/indirect contribution
   duplicates, freeze historical rule versions, expose numerator/denominator/source
   and return `insufficientEvidence`/`notApplicable` instead of fabricated zero.
8. Build the exact Goals/Projects/Areas/horizon surfaces from internally accepted references.
   Reuse Stage 31 detail/Stage 35 inspector rather than shallow workspace-only details.
9. Implement weekly/monthly checkpoint flow: reflect factual outcome, confirm measure,
   review linked work, move/re-scope/cancel explicitly and generate a reversible replan
   command. Never rewrite historical plan to make a forecast look successful.
10. Add range forecast using canonical Stage 37 placements and habit eligibility. Show
    planned evidence, known collision/capacity and unplanned checkpoint risk; do not
    claim predictive probability without a defined model.
11. Integrate search/filter/sort, archive/restore/export, notifications, widget/deep
    links, AI proposal/apply, sync/conflicts, diagnostics and backup before calling the
    stage complete. Remove obsolete Project/Area-only More commands after route parity.

## Exact UI composition

The accepted direction must use a **Horizon Ledger**: a scan-friendly hierarchy and
evidence trail, not equal cards.

### Goals overview

The crown contains `Goals`, active horizon selector and whole `New goal` action. A
compact horizon band shows current civil interval/checkpoints, followed by a start-
aligned goal ledger. Each goal row presents outcome, horizon, primary measure state,
next checkpoint and linked-project count; it does not compress every measure into a
ring. Selecting a row opens canonical detail/inspector. An `Explain progress` action
reveals the exact contribution receipt.

### Goal detail and review

Order: outcome/context → next checkpoint and immediate action → measure ledger → linked
Projects/Tasks/Habits → contribution/history → review/replan → definition/sync. The
measure ledger aligns name, current/target/unit and evidence source; mixed units have
separate lines. Replan is an inline review surface with before/after relation/date/
measure diff and explicit Apply.

### Projects and Areas

Projects show finite status, target, next action and linked Goal/Area. Areas show
ongoing standards, active Projects and relevant Habits with no fake completion. Both
reuse a shared hierarchy browser and canonical detail; their semantic differences are
visible through structure/copy, not only an icon color.

### Week/month/quarter/year horizons

Each mode keeps one spine: orientation and review status, commitments/checkpoints,
factual scheduled load, outcome measures and decisions needing replan. Phone uses a
vertical ledger. Expanded tablet/Windows uses a bounded horizon navigator, main review
ledger and optional detail inspector. Quarter/year summarize at meaningful month/
quarter boundaries and drill down; they do not render 365 tiny cells.

## Interaction and motion behavior

- Row/body opens detail; measure/checkpoint actions mutate only their explicit record;
  Edit is contextual. Dragging a Project between Goals is optional acceleration and
  always has a Move dialog with consequence preview.
- Expanding a Goal reveals children through a restrained connected-axis unfold; it
  preserves row position and does not animate every descendant on sync.
- Progress change shows old → new factual value and source receipt. Completion feedback
  is calm here; Stage 40 owns milestone presentation and cannot alter progress truth.
- Horizon switching preserves selected stable ID, review draft and scroll anchor.
  Reduced motion removes spatial travel and retains direct state/focus update.
- Replan Apply is optimistic/local-first with Undo where safe. A remote conflict pauses
  only the affected proposal and exposes the current revision/diff.

## Responsive behavior

### Android phone

One hierarchy level is primary at a time with visible parent context and reliable back.
Measure rows recompose to value/action lines at 320dp/200% text. Frequent checkpoint
action remains in thumb reach; destructive hierarchy actions remain deliberate. Short
landscape reduces summary chrome rather than shrinking ledger text or targets.

### Android tablet

Portrait can pair hierarchy navigator with a modal/full detail only when both retain
readable width. Landscape uses two panes and optionally a third inspector at expanded
constraints. Compact rail stays default. Pane appearance never clears selected Goal,
horizon, review draft, focus or scroll.

### Windows compact and expanded

720x540 uses the phone hierarchy with keyboard navigation. Intermediate width uses a
two-pane navigator/ledger. 1366x768+ may add the canonical inspector, bounded by useful
ledger width and line length. Pane split is resizable/remembered; Ctrl/Shift selection,
arrow tree navigation, Enter, F2/Edit and context menus use stable IDs and labeled
shortcuts. Continuous resize migrates presentation without duplicate routes.

## Data and domain contracts

`PlannerGoal` is an owner-scoped entity with stable ID, outcome/title, note, lifecycle,
horizon kind/start/end/timezone, measure IDs, optional checkpoint cadence, revision and
soft-delete metadata. A horizon interval is validated civil time; target end cannot be
silently changed by timezone movement.

`PlannerRelation` contains owner, stable ID, typed source kind/ID, relation type, typed
target kind/ID, optional contribution policy, created/updated revision and soft delete.
Relations allowed in this stage are explicit (`belongsToArea`, `deliversGoal`,
`containsTask`, `supportsGoal`, `tracksGoal`) with a checked compatibility matrix. The
trusted boundary derives owner; display labels are never identifiers.

`PlannerGoalMeasure` contains ID, goal ID, kind (`manualNumeric`, `taskOutcome`,
`habitEligibility`, `projectMilestone`, `focusDuration`), unit, baseline, target,
direction (`atLeast`, `atMost`, `exact`), optional explicit weight, source relation,
rule version and lifecycle. Manual values use immutable entries, not overwritten history.

`PlannerContributionReceipt` contains unique contribution key, goal/measure/source IDs,
source event revision/time, normalized value, inclusion reason, rule version and
supersession metadata. Database uniqueness prevents the same event counting through two
paths. Cached aggregates are derived, versioned and rebuildable.

`PlannerCheckpoint` records intended civil date, status, reflection, measure snapshot,
replan decision and immutable source revisions. Forecast projections carry range, zone,
Stage 37 placement revisions and `knownFacts`; they never become durable outcome truth.

## Whole-product propagation

- **Today:** only actionable due checkpoints/replan decisions enter Today, once, with a
  typed checkpoint ID. Goals do not become fake tasks or duplicate linked work.
- **Tasks/Habits/Plan/Focus:** stable typed relations and unique receipts connect actual
  completion/log/focus events. Each workspace can filter by Goal/Project/Area and opens
  canonical relation detail; changes invalidate one progress projection.
- **Capture and wizards:** Plan morph adds Goal/Project/Area choices through the shared
  wizard. Quick task/habit creation can attach existing stable relations; it cannot
  create an unnamed parent implicitly.
- **Details/lifecycle:** all entity/details share view-first routes. Archive/delete shows
  relation/history consequence, defaults to detach/archive, and never cascades children.
- **Search/filter:** global and workspace search index outcome/title, typed kind and
  stable relations. Results distinguish Area/Project/Goal even if names match.
- **Widget, notifications and deep links:** checkpoint reminders use typed IDs and open
  Goal review/detail. The Today widget may show a due checkpoint only when actionable;
  it never renders ornamental goal progress or duplicates a linked task.
- **Perfect AI:** update allowlisted structured proposals/schema/ingestion for Goal,
  relations, measures, checkpoints and safe edits. AI receives owner-scoped IDs and
  explainable progress; Apply is diffed, transactional and audited, never raw SQL.
- **Sync/conflicts:** entity, relation, measure, manual entry and checkpoint have distinct
  revisions/merge policies. A conflicting parent rename is not allowed to discard child
  work; relation conflicts are visible and deterministic.
- **Settings/diagnostics:** settings own week start, timezone, quarter/fiscal policy,
  review cadence and reminder defaults. Diagnostics show graph integrity, orphan/cycle
  audit, projection rule versions and queue state without private text by default.
- **Empty/dense states:** distinguish no goals, no measures, no linked work, no evidence,
  filtered empty, completed horizon and failed projection. Dense graphs use virtualized
  hierarchy and bounded drilldown, not miniature nodes.
- **Upgrades/backup/import/export:** additive migrations preserve existing Project/Area
  payloads and IDs, backfill relations with a dry-run/quarantine path, export all
  entities/relations/measures/checkpoints/receipts and rebuild only derived aggregates.
  Old clients must preserve unknown goal fields or be version-gated from destructive
  writes; auth/session/pending operations survive in-place update.

## Offline, sync, conflict and error cases

All Goal/Project/Area, relation, manual measure and checkpoint writes commit locally
and enqueue idempotent operations. Progress and horizon review compute locally from the
latest available evidence and label staleness when remote sync is pending; offline does
not disable review.

Handle duplicate relation, graph cycle, missing/archived target, remote parent delete,
old client unknown goal kind, partial legacy backfill, incompatible measure unit,
manual entry replay, contribution collision, schedule/timezone shift, concurrent
replan, auth expiry and server/RLS rejection. Keep last valid hierarchy/evidence
visible, quarantine only malformed links, never broaden owner scope or reset storage.

## Accessibility, keyboard and touch

Hierarchy exposes level, expanded/collapsed, parent, child count, lifecycle and actions.
Measures announce name, value, target, unit, direction, evidence and progress without
color-only meaning. Charts/marks have equivalent tables/summaries. Focus order matches
visible hierarchy and moves deliberately after collapse/delete. Keyboard supports tree
navigation and review actions; pointer drag has Move alternative. Touch targets stay
48dp, long copy wraps, bidi isolates dates/units/IDs, high contrast keeps connectors/
focus visible, and progress animation never causes repeated screen-reader counts.

## Performance budgets

- Hierarchy queries are indexed and bounded; render visible nodes with stable keys.
  Never recursively expand the full graph in `build()`.
- Warm active-horizon projection target <=150ms for 10,000 relations/contributions;
  detail measure update should invalidate only affected ancestors/measures.
- Aggregate caches key rule/source revision and are rebuildable in a background isolate;
  forecast range is bounded. Detect cycles in migration/write, not every frame.
- Profile release-mode query/build/raster/memory on Android and Windows, including dense
  expanded hierarchy and continuous resize. Observability excludes owner text.

## Verification and required evidence

1. Entity/relation compatibility, DAG/cycle, cardinality, owner isolation, lifecycle,
   backfill, old-client and migration rollback tests.
2. Measure/contribution golden vectors for every kind/direction/unit, explicit weights,
   indirect duplicate paths, supersession, insufficient evidence and cache rebuild.
3. Horizon boundary vectors for Gregorian/Jalali context, week start, leap/month/
   quarter/year edge, timezone travel and DST.
4. Workflow tests for create/edit/link/move/detach/archive/restore/delete/checkpoint/
   review/replan/Undo, offline replay, conflict and AI proposal/apply.
5. Cross-consumer proof through Today, Tasks, Habits, Plan, Focus, detail, search,
   reminders, widget, deep links, AI, sync/conflict, settings/diagnostics and export.
6. The complete preview/Copy evidence set: every component plate, all page/state/theme/
   layout previews, accepted direction, route/anatomy map, decomposition manifest,
   exact reference/runtime/diff pairs, mismatch/precision/occupancy/opinion ledgers.
7. Real Android/Windows recordings and screenshot matrix at every master viewport,
   sparse/dense/long/mixed/200%/offline/conflict/reduced-motion, plus release-mode
   performance traces, focused tests and full analyze/test.

## Reject if

- Runtime/schema edits begin before preview acceptance or any component/page is judged
  without an exact Copy side-by-side runtime reference.
- Goal, Project and Area are synonyms in UI/data or an Area receives fake completion.
- Progress cannot explain numerator/denominator/source, averages incompatible units,
  double-counts one event or relies on editable cached totals as authority.
- Parent edit/archive/delete can orphan or cascade child data silently, relation checks
  exist only in UI, or any cross-owner link is possible.
- Horizon review is a decorative KPI dashboard with no checkpoint/replan action, or a
  forecast is presented as prediction without a defined model.
- AI/widget/notification/search/export/sync contracts ignore the new kinds/relations.
- Preview hierarchy, geometry, copy, assets, states, density or responsive behavior has
  a material unresolved runtime mismatch.
- The layout merely avoids overflow while hierarchy is tiny, dead-space-heavy, cramped,
  unreadable at 200% or detached from the composer/navigation/inspector.

## Handoff and release

Hand Stage 40 typed Focus contribution inputs, checkpoint/milestone factual events and
an explicit rule that presentation never grants progress. Hand Stage 41 the adopted
Goal/relation/measure/checkpoint schema, migrations and compatibility evidence; Stage 41
may harden/index but cannot rename stable IDs or alter meaning silently.

Finish with a focused commit, push to `main`, successful workflow and three private
install-ready artifacts. Record preview/decomposition paths, reference/runtime/diff
evidence, exact SHA, schema/RPC versions, migration dry-run/rollback, performance and
cross-surface proof. Restore clean `main`-only state and retain the pre-rebuild stash.

### Evidence — 2026-09-25 (Stage 39 characterization only)

- No runtime vertical slice exists; nothing GREEN can be claimed as Stage 39
  evidence yet.
- Stage 39 remains **blocked** until the Stage 03–05 preview/Copy gate has
  recorded autonomous acceptance for Goal/relation/measure/horizon surfaces.
