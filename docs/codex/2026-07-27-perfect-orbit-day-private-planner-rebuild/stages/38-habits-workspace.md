# Stage 38 — Habits workspace and actionable insights

Status: blocked — Stage 03–05 preview/Copy gate plus workspace query/ranking/suggestion contracts have no recorded autonomous acceptance; existing Today logging/analytics suites remain GREEN as characterization only
Depends on: accepted Stages 03–05 preview/copy contract; Stages 07, 14,
26–30, 31, 33–37  
Primary surfaces: Habits workspace, today's logging, momentum/risk filters,
deterministic suggestions and analytics entry

## Mission

Make Habits an action surface first and an evidence surface second. The owner should
see what can be logged now, what still needs attention and what rhythm is changing,
then reach deeper analytics without turning the default page into a dashboard. Every
method, schedule and build/maintain/quit direction remains truthful.

## Failure statement and autonomous decisions

The current workspace renders an overview band and a card per habit from controller
memory. It treats presentation as the insight, exposes only shallow filterability and
cannot explain risk or suggestions from durable data. Replace that page projection and
its Habit-only card language.

- Default order is: needs a decision, loggable and behind target, loggable/on track,
  already satisfied, then not eligible today. The exact reason is available in row
  semantics/detail; completion alone never sorts a quit habit incorrectly.
- The default page keeps today's method-specific control visible. Analytics and long
  trends are one deliberate level deeper in Stage 33 detail or Insights, not permanent
  equal-weight tiles.
- Habit direction is explicit and stable: `build`, `maintain`, or `quit`. “Quit” means
  an at-most/avoidance objective and reverses success semantics without shame copy.
- Risk is a deterministic, explainable projection from eligible finalized evidence.
  It is absent when evidence is insufficient. No opaque score, personality judgement,
  guilt, urgency theater or model-generated claim may appear.
- Suggestions are local deterministic rules by default. Perfect AI may explain or
  propose a schedule/target change later, but it cannot disguise inference as fact or
  change a habit before owner review.
- Build/maintain/quit, category, schedule and attention/risk filters compose as the
  same typed query pattern as Stage 36. They are disclosed progressively, not a noisy
  permanent toolbar.

## Preview and Copy fidelity gate — before any runtime edit

This stage cannot begin implementation merely because Stages 03–05 exist; their
internally accepted Perfect! direction, responsive primitives and preview harness
must be materially available. If a preview is rejected or missing,
stop at preview/spec work and record the blocker. No Dart, schema, migration, Android,
Windows or test-runtime mutation begins first.

1. Use Modernize in **Recompose** mode to create at least 24 raw product-grounded
   concepts, shortlist 6–8, and generate 2–4 high-fidelity final directions for the
   real Habits workspace. The concepts must preserve logging speed, durable truth and
   Perfect! identity; reject generic habit cards, rainbow streak dashboards and copied
   competitor layouts.
2. Apply Integrity's five-way opinion ledger (`KEEP`, `REFINE`, `REDESIGN`, `REMOVE`,
   `ADD`) to the workspace crown, Today status, filters, habit row, method controls,
   momentum cue, suggestion, empty/loading/offline/error, analytics entry, inspector,
   composer adjacency, detail transition, widget and notification representations.
3. Produce an **individual component preview plate for every component**: habit row;
   check/count/value/duration/checklist controls; target/progress line; schedule/risk/
   recovery marks; direction/category/filter tokens; Refine surface; insight ribbon;
   evidence/explanation disclosure; logging Undo; selected/focus/hover/press/disabled/
   busy/error variants; empty/loading/offline/conflict panels; and inspector handoff.
   Each plate labels bounds, alignment axis, spacing/type/radius tokens, live text/data,
   SVG/raster/live/hybrid route, 48dp target, focus ring, semantics and motion beats.
4. Produce full-page internally accepted previews for phone portrait, short phone landscape,
   tablet portrait, tablet landscape with compact/expanded rail, 720x540 Windows,
   1024x640, 1366x768 and 1600+ expanded. For every composition include no habits,
   one habit, dense mixed-method habits, long mixed Persian/English copy, 200% text,
   light, dark, high contrast, reduced motion, offline, retry/error, conflict,
   filter/no-results, logging busy/success/Undo and adjacent detail where applicable.
5. Create the preview-to-production decomposition manifest and Anatomy maps: every
   visible layer/component, hierarchy/order, compact/medium/expanded transformation,
   frame/occupancy math, alignment reason, crop/z-order, asset provenance/path,
   interaction/focus, live semantics and performance budget. Dynamic habit data and
   controls remain live; no flattened screenshot may impersonate runtime UI.
6. Record internal acceptance of one direction and its component/page matrix under
   the owner-delegated autonomous design authority. The accepted previews become
   binding references. Any later material change reopens the design gate or receives
   a documented adaptive exception in the mismatch ledger with concrete evidence.
7. Implement through Copy fidelity one component at a time: inventory every visible
   item, match structure before decoration, capture the exact reference viewport/state,
   make normalized preview-versus-runtime composites, fix macro → component → micro
   deltas, then repeat for responsive siblings. Image-diff numbers support but never
   replace visual judgment. Runtime acceptance requires a clean component inventory,
   mismatch ledger, precision ledger and composition-occupancy review.

## Detailed work packets

1. Freeze the current workspace at zero/one/many habits and every tracking method.
   Trace row/body/log/detail/insight routes, copied progress calculations and every
   consumer of habit direction, eligibility, streak and occurrence state.
2. Define `PlannerHabitWorkspaceQuery`, `PlannerHabitWorkspaceItem`,
   `PlannerHabitWorkspaceProjection`, `PlannerHabitRiskAssessment` and
   `PlannerHabitSuggestion`. Make one repository projection authoritative.
3. Add explicit direction metadata with backward-compatible migration. Infer legacy
   direction only from an existing unambiguous success condition; otherwise default to
   `build` and show it in Edit, never guess from title/note.
4. Implement deterministic ranking and grouped reasons. Reuse Stage 29 eligibility,
   streak/recovery and Stage 30 logging semantics; do not recompute them in widgets.
5. Build the exact adaptive workspace composition and method-specific row/control
   variants from accepted previews. Delete the old overview band/card duplication only
   after behavior and preview fidelity are proven.
6. Add a compact Refine surface for direction, category, schedule window, tracking
   method and attention state. Facet counts come from the same projection revision.
7. Implement a bounded suggestion engine with an explainable evidence receipt and
   suppression/dismissal. Examples: repeated late logging relative to an authored
   window; target consistently exceeded; insufficient opportunities; frequent recovery
   use. Never create causal or health claims.
8. Integrate suggestion actions through reviewable Edit: `Review schedule`, `Review
   target`, `See evidence`, `Dismiss`. A suggestion never writes directly.
9. Preserve workspace query, group disclosure, selected habit, focused control, scroll
   anchor, inspector, expanded evidence and optimistic logging through remote updates,
   detail round trips and breakpoint changes.
10. Add narrow subscriptions so logging one habit updates its row, summary and related
    suggestion without rebuilding every habit or replaying page entrance.
11. Reconcile Today's rows, detail metrics, widget actions, notifications, AI context,
    goal contributions and sync after each occurrence or habit-definition mutation.

## Exact UI composition

The selected direction must express a continuous **Rhythm Field**, not a dashboard
heading followed by cards.

1. **Workspace crown:** `Habits`, factual due/logged summary and whole `New habit`
   action. A compact Today indicator uses dual date context only when it assists
   orientation; it never repeats the full Today Pulse.
2. **Attention lens:** the current view (`Today` by default), search and Refine summary
   share one bounded surface. Active filters wrap as removable semantic tokens.
3. **Rhythm stream:** canonical habit rows grouped by `Needs attention`, `Available`,
   `Satisfied` and `Later/rest`. Group labels are quiet and absent when empty. The
   method control remains closest to the habit it logs; progress/target sits in the
   same frame, not a detached metric card.
4. **Evidence ribbon:** at most one highest-value suggestion is expanded near the
   affected group, with factual claim, window/denominator, `See evidence` and review
   action. Additional suggestions live behind `Insights`, never as a carousel.
5. **Detail adjacency:** expanded Windows/tablet may show Stage 33 detail inspector;
   the stream retains enough width for title, target and control. The suggestion and
   inspector never compete as two permanent side panels.

No percentage is shown inside a cramped ring. Count/duration/value/checklist methods
use legible numeric or step copy with tabular figures. A quit habit uses calm
`Within limit`, `Approaching limit`, `Over limit` language and non-color marks rather
than success confetti for avoidance.

## Interaction and motion behavior

- Body tap opens detail. The method-specific control logs only its explicit value;
  correction/decrement is available by adjacent affordance or bounded log sheet, not a
  secret gesture. Rapid taps serialize and maintain exact counts.
- Logging provides immediate stable-geometry feedback, a compact result receipt and
  Undo. A row may move groups only after the acknowledgement window; focus/scroll
  follow the stable entity ID.
- Filter disclosure uses restrained size/fade; selected tokens glide without shifting
  the stream axis. Suggestion evidence unfolds in place and does not cover logging.
- Milestone/streak feedback follows Stage 40's future presentation contract. Until
  then, use a calm state mark only; this stage may not introduce ad hoc confetti,
  points or duplicate achievements.
- Reduced motion removes travel/stagger, retains state change and announces one result.
  No entrance animation replays for normal occurrence updates or scroll recycling.

## Responsive behavior

### Android phone

Use one start-aligned scan column; logging controls remain in the comfortable reach
path and outside gesture zones. At 320dp/200% text, each row recomposes into identity,
target and full-width action lines rather than shrinking the control. Refine is a tall
scroll-controlled sheet above IME. Short landscape suppresses decorative summary and
keeps stream/action scale useful.

### Android tablet

Portrait uses a wide stream and modal detail. At 900dp landscape, stream plus inspector
is allowed when the stream meets its minimum. The attention lens may anchor beside the
crown, not become a permanent empty sidebar. Compact rail remains default and rail
changes preserve focused habit, log state, scroll and filters.

### Windows compact and expanded

720x540 uses the phone ordering with mouse/keyboard support. Intermediate width shows
more metadata only if line length remains stable. Expanded width uses a bounded stream
plus inspector; dense habits do not become a sparse multi-column card grid. Secondary
click, hover, focus and tooltips are native-feeling and never required for discovery.

## Data and domain contracts

`PlannerHabitWorkspaceQuery` includes active/archived lifecycle, direction set,
tracking-method set, category/relation IDs, eligibility/schedule relation, attention
state, normalized search and sort. Unknown relation/direction values remain visible as
repairable constraints rather than broadening results.

`PlannerHabitWorkspaceItem` exposes stable habit ID/revision, direction, method,
eligibility, raw current value, target/limit, normalized progress, occurrence state,
schedule window, streak/recovery facts, log actions and attention reasons. It is a
read-only projection; widgets never infer from payload maps.

`PlannerHabitRiskAssessment` has `state` (`insufficientEvidence`, `stable`,
`watch`), evidence window, eligible/finalized counts, deterministic fact codes,
algorithm version and source revision. `watch` is not failure; copy names the observed
pattern. Minimum evidence must be specified per rule and tested.

`PlannerHabitSuggestion` has stable deterministic ID, rule version, habit ID, evidence
receipt, suggestion kind, created/expiry range and device-local dismissal. Suggestions
are derived/cacheable, never authority. Dismissal affects presentation only; export can
omit it. AI-originated suggestions use a different provenance and review contract.

## Whole-product propagation

- **Today:** inline controls consume the same workspace item/log commands. An
  occurrence mutation updates Today and Habits once with identical value/target/state.
- **Capture and wizard:** Plan morph/new habit and full editor write explicit direction,
  method, target, schedule and recovery. Cancel/edit return restores Habits filters and
  anchor; suggestions deep-link to the exact review step without pre-applying values.
- **Details:** row and evidence routes use Stage 33 detail/calendar. Selected-day
  correction invalidates the same projection/risk receipt; metrics cannot disagree.
- **Tasks/Plan:** Plan shows eligible windows/occurrences without taskifying the habit;
  Tasks filters never include habits. Relation labels use shared Project/Area IDs.
- **Search/filter:** expose stable result/reason descriptors to global search and share
  Stage 36 normalization/selector behavior rather than a Habit-only parser.
- **Goals/projects/horizons:** Stage 39 consumes eligible occurrence evidence through
  unique contribution keys. Suggestions cannot inflate goal progress or double count.
- **Focus:** a habit may start an attached focus session only where method/intent allows;
  focus completion never automatically logs a habit unless an explicit reviewed rule
  defines that connection.
- **Widget/notifications/deep links:** widget uses the same method commands and refreshed
  projection. Reminder copy reflects schedule/direction without shame; external open
  resolves current habit detail or a deliberate log action with owner authorization.
- **Perfect AI:** provide source-revisioned habit facts, not mutable controller objects.
  AI proposal shows evidence, changed fields and consequences and remains review-only.
- **Sync/conflicts:** habit definition and occurrence conflicts are distinct. Current
  local logging remains available; merge must not lose increments, checklist items or
  rule-version history.
- **Settings/diagnostics:** settings own insight visibility, week start, numeral/locale
  policy and optional calm feedback; diagnostics expose algorithm/rule versions,
  projection age and pending mutations without habit text by default.
- **Empty/dense states:** distinguish zero habits, rest day/no eligible habits, all
  satisfied, active filters with no matches, insufficient evidence and failed range
  query. Dense mode uses slivers/pagination and preserves 48dp controls.
- **Upgrades/backup:** migrate direction and suggestion algorithm versions additively;
  export durable definitions/occurrences, not derived risk caches. Preserve auth,
  history, drafts, active logs and pending operations in place.

## Offline, sync, conflict and error cases

Logging, corrections, filter queries and deterministic suggestions work from local
authority offline. Each increment/checklist/value operation has a stable mutation ID
and atomic occurrence update. Retry cannot lose or double an increment. Suggestions
show the evidence revision and disappear/recompute when stale.

Handle rapid taps, process background mid-log, remote rule change, concurrent logging,
timezone/midnight change, edited schedule window, deleted category/project, malformed
legacy tracking payload, insufficient history, range-query failure, auth expiry and
Supabase rejection. Keep the last valid stream actionable; isolate errors to the row,
suggestion or sync layer and offer Retry/Review Conflict without full-screen blocking.

## Accessibility, keyboard and touch

Each row announces title, direction, eligibility, current value/target, state, streak
only when relevant, and exact logging action. Count/value controls expose increment,
decrement and current value; checklist exposes item count and opens a labeled list.
Risk/suggestion states use text and shape, not color. Focus order follows crown → lens
→ groups/rows → suggestion evidence → inspector. Windows supports arrows, Enter,
Space/log shortcut where unambiguous and Escape precedence. Touch targets remain 48dp,
focus rings are unclipped, Persian/English runs are isolated, and screen reader gets
one logging/Undo announcement rather than each animated frame.

## Performance budgets

- Logging one habit updates only that occurrence, affected projection row, summary and
  suggestion receipt. It must not re-read full history or rebuild every card.
- Warm local projection target <=100ms for 1,000 habits with bounded current-window
  evidence; visible logging response occurs within one frame before background sync.
- Risk/suggestion computation runs off the build path, bounded by range and cached by
  algorithm + source revision. Long history uses aggregate/range queries.
- Profile release-mode build/raster, database query, memory and rapid logging on target
  Android and Windows; instrument without owner content.

## Verification and required evidence

1. Direction/method/eligibility/attention ordering vectors for check, count, value,
   duration, checklist and quit/at-most semantics.
2. Risk/suggestion golden vectors with denominator, minimum evidence, algorithm version,
   dismissal, expiry, rule change, no causal claim and no fake insight.
3. Repository tests for query/filter counts, bounded history, local migration, atomic
   rapid logs, duplicate replay, concurrent merge and cache invalidation.
4. Interaction tests for every method, correction/Undo, filters, evidence, detail/Edit
   return, keyboard/touch/pointer and scroll/focus preservation.
5. Cross-consumer tests for Today, detail metrics/calendar, Plan, goals, focus, widget,
   reminder, AI, sync/conflict and diagnostics after definition/occurrence mutations.
6. The entire preview/Copy gate: accepted final direction, every individual component
   plate, all page/state/theme/layout references, decomposition manifest, normalized
   preview/runtime pairs, diff artifacts, mismatch ledger, precision ledger and final
   opinion/occupancy ledgers.
7. Real Android and Windows recordings across the master viewport matrix, rapid taps,
   offline/retry/conflict, 200% text, RTL/mixed, high contrast and reduced motion;
   release-mode profiler evidence plus focused tests and full analyze/test.

## Reject if

- Runtime edits start before all component and full-page previews are accepted, or a
  later implementation is accepted from an isolated screenshot without Copy comparison.
- The default workspace hides logging behind analytics, a row/body tap opens Edit, or
  a tracking method is reduced to a binary check.
- Risk/suggestion copy is guilt-driven, opaque, causal, based on insufficient evidence
  or writes a definition without explicit review.
- Build/maintain/quit semantics disagree across workspace, Today, detail, widget,
  reminders, AI, goals or sync.
- One log rebuilds the entire page, repeated taps lose/duplicate values, or a conflict
  silently last-writes occurrence history.
- Preview geometry, copy, assets, density, states or responsive transformations have
  material unresolved runtime mismatches.
- The page passes overflow checks but is a generic card dashboard, strands tiny content
  in expanded space, clips required copy or hides the final reachable action.

## Handoff and release

Hand Stage 39 the explicit direction, occurrence evidence, stable relation IDs and
unique contribution inputs. Hand Stage 40 the logging/milestone boundary and a strict
ban on ad hoc rewards; focus/gamification must consume authoritative receipts.

Finish with a focused commit, push to `main`, successful workflow and three private
install-ready artifacts. Record the internally accepted preview paths, decomposition manifest,
reference/runtime/diff artifacts, SHA, migration/rule versions, profiler/behavior
evidence and known risks. Return to clean `main`-only state without touching the
retained pre-rebuild stash.

### Evidence — 2026-09-25 (real runs, Stage 38 characterization only)

- Method-aware Today logging/correction inside the **EXIT:0, 198 pass**
  integrated workspace gate; daily-state vectors inside the **EXIT:0, 68
  pass** domain+wizard gate.
- This does **not** close Stage 38. Workspace projection, ranking, risk/
  suggestion engine, Refine composition, subscription scoping, and preview
  acceptance remain blocked with no recorded autonomous acceptance.
