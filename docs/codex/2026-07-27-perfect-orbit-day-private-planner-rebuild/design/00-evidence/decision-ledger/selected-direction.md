# Selected direction — `PS01 Perfect Day Instrument`

Status: **selected and frozen for Stage 04/05 specification**
Selected: 2026-08-10
Structural origin: F1 / R01 Pulse and Stream
Ordinary design authority: autonomous evidence decision

## Outcome

Perfect! will be a calm, tactile **day instrument** built around a compact
orientation Pulse and one continuous actionable Stream. It is not an Orbit, generic
dashboard, card pile, command-line shell or desktop-only workbench.

The winning structure is F1 because it minimizes orientation and logging cost while
surviving phone/tablet/Windows, empty/error and dense states. Bounded subsystem ideas
from other finalists are adopted only where they strengthen the same topology.

## Post-preview scoring

The same weighted criteria from `direction-selection.md` were rescored after normal
and stress boards.

| Finalist | Orient | Speed | Hier. | Orig. | A11y | Resp. | Feas. | Craft | Perf. | Whole | Total / 100 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **F1 Pulse and Stream** | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 4 | 5 | 5 | **98.4** |
| F3 Daily Desk | 4 | 4 | 5 | 3 | 4 | 5 | 4 | 3 | 4 | 4 | 80.4 |
| F2 Living Ledger | 4 | 3 | 4 | 4 | 4 | 4 | 5 | 4 | 5 | 4 | 80.0 |
| F4 Adaptive Instrument | 4 | 4 | 3 | 5 | 4 | 4 | 3 | 5 | 3 | 4 | 78.8 |

## Why PS01 won

1. **One source of daily truth.** Pulse orients; Stream acts. Neither repeats the
   same task list or `next` card.
2. **Lowest common-action cost.** Status, +1, duration preset and checklist-next are
   visible and reversible without opening detail/edit.
3. **Best adaptive skeleton.** Phone is one stream; tablet adds supporting/detail;
   Windows adds plan/detail panes without changing entity semantics.
4. **State clarity.** Empty, offline, retry and conflict fit into the same structure
   rather than requiring a hero replacement or modal takeover.
5. **Performance.** Planar virtualized rows and a small Pulse avoid the continuous
   paint and curved text complexity of Orbit/instrument dashboards.
6. **Craft remains concentrated.** The brand mark, Pulse micrographic, Sync cloud,
   status receipts and Capture morph can be exceptionally crafted without turning
   every row into a glossy object.

## Bounded imports

| Donor | Imported behavior | Explicit boundary |
| --- | --- | --- |
| F2 Living Ledger | immutable history receipts, correction/carry chronology and trust language | appears in detail/history and concise inline receipt only; Today does not become a ledger of repeated audit rows |
| F3 Daily Desk | Windows list/plan/detail workbench, resizable panes, keyboard command/search, live selection | wide composition only; phone remains independent route-based stream/detail |
| R09 Handrail | stable reachable status/log control lane and one-handed geometry | control side adapts to handedness/direction and never becomes a full decorative rail |
| F4 Adaptive Instrument | sculpted Capture orb, crafted Sync/Pulse micro-material and proportional Focus receipt | no giant instrument card, decorative blob, dashboard cluster or redundant radial graphic |
| R11 Ritual Chapters | optional daily/weekly planning and review ritual | never gates normal Today access |
| R21 Constraint Negotiator | workload/conflict proposal and AI tradeoff preview | appears during Plan/AI/review, not a permanent metric dashboard |

## Information architecture

### Primary destinations

- Today
- Tasks
- Plan
- Habits
- More

`More` opens the organized secondary map: Goals, Projects/Areas, Notes, Focus,
Reviews, Categories, Settings/Diagnostics and Feedback. Windows/tablet can promote
high-frequency secondary destinations into the expanded rail without changing route
IDs.

### Today anatomy

1. compact glass header with selected wordmark, current context and Sync cloud;
2. Today Pulse: time, dual date, next boundary, lightweight planned/open/habit signal
   and Plan action;
3. one continuous day Stream with named zones (`Now`, `Next`, timed, flexible,
   habits, completed) only where the data needs them;
4. direct method-specific controls and reversible inline receipts;
5. standalone Capture orb floating above the icon-only footer, no backing strip.

Pulse is bounded and content-sized. It never grows into a clock face, Orbit, hero
chart or duplicate task card.

### Normal tap contract

- row body -> view-first detail/history;
- status/log control -> immediate local mutation + outbox + Undo receipt;
- named row action/context -> reschedule/archive/etc.;
- Edit -> explicit from detail/action;
- create/Quick Capture -> creation path;
- no immutable Type step during edit.

## Platform compositions

### Android phone

- Compact blurred header; title-rise belongs to route content, not a huge greeting.
- Stream spans readable width with one-handed controls and stable row geometry.
- Footer is floating, glass, icon-only and clear of system navigation/IME.
- Capture orb expands without invoking keyboard; tapping the field requests focus.
- Landscape compresses header/Pulse and preserves stream scroll/draft.

### Android tablet

- Compact icon rail by default; optional expansion with labels/tooltips.
- Portrait uses primary stream plus contextual sheet/route based on width/height.
- Landscape uses list-detail or stream-supporting pane; selected entity remains live.
- Rotation/split-screen preserves selection, draft, focus and scroll.

### Windows

- Remembered compact/expanded rail, hover/focus/context and shortcuts.
- Compact is route/list-first; intermediate is list-detail; wide can be list/plan/
  detail when the active job benefits.
- Dividers expose drag/focus/min/max behavior and restore pane widths safely.
- Capture/command search accelerates expert use without replacing browseability.

## Component language

- **Rows:** planar, rhythm and rules; local emphasis only for next/risk/selected.
- **Cards:** reserved for bounded summaries/proposals/details, never every list item.
- **Glass:** header/footer/capture/popover/selected floating overlay only.
- **Pastel:** apricot intention, mint rhythm, lavender focus/reflection; independent
  green/yellow/red status roles.
- **Progress:** compact arc only; accessible numeric value outside cramped rings.
- **Selection:** surface/outline/position; no redundant check when color already
  communicates selection.
- **Icons:** owned SVG archive, no keyboard emoji or stock sparkle substitute.

## Capture / Plan / AI / Voice

The collapsed control is one subtle heartbeat orb with no background strip. On tap,
the same anchored shell expands and presents four recognizable mode actions. It does
not summon IME. Selecting Task, Plan, AI or Voice morphs the same shell; independent
drafts remain intact.

- Task can save title-only locally in under five seconds.
- Plan adds time/date/duration in the same surface.
- AI shows context and produces a reviewable proposal; no write before Apply.
- Voice shows permission/listening/transcript/error states and routes through the
  same proposal/save contracts.

## Habit UX

- Boolean: direct reversible state cycle.
- Count: large +1, optional decrement/exact correction, serialized rapid taps.
- Duration: quick preset/start timer/manual correction.
- Numeric: unit-aware quick add or exact set.
- Checklist: next-step action plus expandable items.
- Quit: avoided/incident/urge/recovery language without punitive streak framing.

Every habit has streak/current/best/risk/recovery in detail and compact receipt where
useful. Miss/Pending/Carry/next-valid/prompt/carry-cap is configured per entity and
shown in the review summary.

## Detail, planning and review

- Detail is a real route or responsive pane: hero/status, facts, relations, calendar,
  immutable history, analytics and guarded lifecycle actions.
- Plan supports day/week/month plus unscheduled tray and realistic capacity.
- Goals use weekly/monthly/quarterly/yearly horizons with linked evidence and honest
  rollups.
- Review compares planned/done/carried/learned/adjust-next without guilt.
- Focus Studio supports Pomodoro/custom/linked entity/flip sensor and only
  platform-authorized DND/pinning behavior; no false universal phone-lock promise.

## State and recovery

- Fresh owner shows zero demo entities and two actions: Capture, Plan with Perfect AI.
- Local data is usable during syncing/offline/retry/error.
- Sync cloud states: green Synced, yellow Syncing/Retrying, red Needs attention; icon
  plus text/tooltip/detail prevents color-only meaning.
- Conflict appears as a concise cue and explicit comparison route/pane with local and
  remote values, audit and deterministic choices.
- Destructive actions name target/consequence and prioritize cancel.

## Motion ID family

- `mot-title-rise`: short rise/fade, reading-order stagger.
- `mot-page-continuity`: crossfade/reposition or connected selection, not arbitrary
  full-screen slides.
- `mot-capture-heartbeat`: subtle idle-only pulse; disabled for reduced motion.
- `mot-capture-morph`: same-anchor expansion/mode morph, interruptible/reversible.
- `mot-status-receipt`: tactile compression + arc/color response + Undo.
- `mot-sync-state`: bounded internal travel/pulse; no perpetual synced spinner.
- `mot-overlay-settle`: origin-aware fade/scale/vertical settle.
- `mot-breakpoint-reflow`: stable selection/focus/scroll through reposition.

Reduced motion uses near-immediate crossfade/reposition and preserves confirmation
feedback semantically.

## Typography and identity

- Header uses the exact selected wordmark image.
- Live Latin/Persian family is chosen only after Stage 04 rasterization tests.
- Tabular numerals stabilize changing time/count/date values.
- Whole primary phrases wrap/stack at 200%; only secondary user previews may ellipsize.
- Mixed bidi spans are isolated; Jalali and Gregorian dates remain correct and
  explicitly labeled where ambiguity exists.

## Performance implications

- Pulse uses bounded static/vector layers and state transitions, not continuous
  custom painting.
- Stream is lazy/virtualized and avoids blur per row.
- Animations target transform/opacity and bounded clips; raster assets have density
  ladders and decode budgets.
- Wide panes query/project only visible/current detail data.
- Rapid habit taps coalesce visually but persist ordered idempotent mutations.

## Model-board limitation

The eight ImageGen boards under `../references/finalist-boards/` are evidence, not
canonical previews. Exact-text and identity inspection rejected them for Copy use.
Stage 04/05 must reconstruct PS01 with deterministic `single_render_native` sources,
exact text, named geometry, component IDs and hashes.

## Hard rejection conditions

Reopen PS01 if a later preview or implementation:

- brings Orbit/radial day navigation back;
- turns Pulse into a large hero or duplicates `next` below it;
- places a strip behind collapsed Capture or opens IME on expansion;
- makes phone a squeezed multi-pane desktop or desktop a stretched phone;
- uses glass/card containers for every row;
- hides direct habit logging behind detail;
- enters Edit from normal row tap;
- resets session/data/draft/selection/scroll during sync, resize or update;
- uses raw emoji, generic wordmark text or unverified generated labels;
- accepts no-overflow or same-vibe instead of side-by-side Copy evidence.

## Supersession rule

`PS01` remains authoritative until a replacement includes:

1. a named new direction ID;
2. the exact problem PS01 cannot solve;
3. complete phone/tablet/Windows, empty/dense/error/dark/200% previews;
4. the same weighted scorecard with a demonstrably higher whole-product result;
5. migration impact for every Stage 04/05 component/page consumer;
6. a committed decision record that marks this file superseded rather than silently
   editing history.

## Stage 04 handoff

Stage 04 receives PS01 and must produce deterministic individual plates for every
foundation and component ID in `preview-production-gate.md`. No production Flutter
UI is authorized until component anatomy, states, responsive behavior, accessibility,
motion and neighbor composition are complete and hash-frozen.
