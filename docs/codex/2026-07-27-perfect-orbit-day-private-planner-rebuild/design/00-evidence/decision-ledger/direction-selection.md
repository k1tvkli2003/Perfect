# Direction shortlist, finalists and selection protocol

Status: scored shortlist and visual proof complete; final decision frozen in
`selected-direction.md`
Input: `../decomposition/24-raw-direction-recipes.md`

## Weighted criteria

| Criterion | Weight | Question |
| --- | ---: | --- |
| orientation time | 14 | Can the owner know `now`, `next`, risk and sync state in seconds? |
| task/habit logging speed | 14 | Are common actions direct, reversible and method-specific? |
| hierarchy | 10 | Does content order remain obvious at sparse and dense states? |
| originality | 10 | Is the system recognizably Perfect! rather than a template planner? |
| accessibility | 12 | Does it survive 200%, mixed direction, contrast and keyboard/touch? |
| responsive resilience | 10 | Does it recompose across phone/tablet/Windows without state loss? |
| feasibility | 8 | Can Flutter/native surfaces implement it with reliable performance? |
| asset craft potential | 8 | Does it create justified authored graphic moments? |
| performance | 6 | Can it scroll/resize/animate smoothly on target hardware? |
| whole-product coherence | 8 | Can it govern detail, wizard, AI, widget, settings and recovery? |

Each rating is 1–5. Weighted total is normalized to 100. A high total does not
override a fatal product contradiction; it determines which concepts earn visual
proof.

## Eight-concept shortlist

| Direction | Orient | Speed | Hier. | Orig. | A11y | Resp. | Feas. | Craft | Perf. | Whole | Total / 100 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| R01 Pulse and Stream | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 4 | 5 | 5 | **98.4** |
| R02 Living Ledger | 4 | 4 | 5 | 4 | 5 | 5 | 5 | 4 | 5 | 4 | **89.2** |
| R09 Handrail | 5 | 5 | 4 | 5 | 3 | 4 | 4 | 4 | 5 | 4 | **86.4** |
| R20 Adaptive Instrument Cluster | 4 | 4 | 4 | 5 | 4 | 4 | 4 | 5 | 4 | 5 | **85.2** |
| R08 Daily Desk | 4 | 4 | 5 | 3 | 5 | 5 | 4 | 3 | 4 | 4 | **82.8** |
| R16 Calendar Fold | 4 | 4 | 4 | 5 | 3 | 4 | 2 | 5 | 3 | 4 | **76.8** |
| R05 Pocket Command | 3 | 5 | 4 | 4 | 3 | 4 | 3 | 4 | 4 | 3 | **74.4** |
| R10 Split Lens | 4 | 3 | 4 | 4 | 4 | 4 | 3 | 4 | 3 | 4 | **74.4** |

## Shortlist decisions

### Finalist F1 — Pulse and Stream

Advances because it wins the highest-frequency jobs with the least structural risk.
It expresses the fixed thesis directly: compact orientation plus one actionable day
stream, no Orbit and no duplicate `next` card.

Proof challenge: demonstrate that craft, typography, status receipts and temporal
structure keep it from becoming a generic task list.

### Finalist F2 — Living Ledger

Advances because immutable history, corrections, recovery and offline/sync truth are
central to a trustworthy personal planner and unusually strong differentiators.

Proof challenge: keep everyday completion playful and light rather than accounting-
like.

### Finalist F3 — Daily Desk

Advances despite a lower score because it is the strongest adversarial Windows-first
composition. It tests whether the winning mobile model can truly scale into a dense,
keyboard/mouse workspace.

Proof challenge: create a first-class phone/tablet family rather than a collapsed
desktop afterthought.

### Finalist F4 — Adaptive Instrument Cluster

Advances because it offers the richest distinctly Perfect! visual/interaction
language for Pulse, Capture, Focus and Review.

Proof challenge: prove it is one instrument system rather than a dashboard of
beautiful cards.

## Concepts not advanced as whole directions

- **R09 Handrail:** excellent one-handed direct-control geometry but handedness,
  RTL and wide-screen translation prevent it governing the whole product. Its stable
  reachable control lane becomes an explicit experiment inside F1.
- **R16 Calendar Fold:** connected view continuity is valuable, but the animation and
  state complexity is disproportionate. The winner may retain selection/date
  continuity without a literal fold.
- **R05 Pocket Command:** excellent Windows expert accelerator and Quick Capture
  parsing pattern; unacceptable as the primary browse/navigation model.
- **R10 Split Lens:** useful for weekly review and estimate learning, too analytical
  for default Today.
- **R03/R07/R13/R24:** visually radical but replace one dominant metaphor with
  another.
- **R06/R11/R14/R15/R18/R21/R23:** strong bounded workflow ideas but insufficient
  as full cross-product topology.

## Finalist preview fixture

The same private synthetic dataset is used for all finalist renders so composition,
not content, determines the comparison. It is preview-only and blocked from
production:

- owner display: `Keyvan`;
- now: Monday 27 July 2026, 09:24;
- next: `Cardiology deep work`, 09:30–11:00, high priority, Study;
- task: `Review project brief`, 07:15, partial checklist 3/5;
- task: `Call Mom`, 21:30, pending/at risk, Personal;
- flexible task: `Book lab appointment`, no fixed time;
- count habit: `Drink water`, 5/8 today, current streak 18;
- quit habit: `No doomscrolling after midnight`, one urge logged, recovery-safe;
- offline scenario: two pending local writes, retry in 18 seconds;
- mixed text: `مرور فصل Arrhythmia` with Gregorian and Jalali date context.

The names are semantic stand-ins in design artifacts only. Manifest tests in later
stages must prove none appear in signed fresh-owner storage.

## Required preview family for each finalist

| ID | Viewport/composition | Mandatory state |
| --- | --- | --- |
| `phone-compact` | 390x844 logical, portrait | normal density, next action, direct task + count habit control, collapsed capture |
| `phone-recovery` | 390x844 logical, portrait | offline/retrying or failed write with local work still usable and Undo/Retry |
| `tablet-landscape` | 1200x800 logical | compact rail, list-detail/supporting pane, selected item, capture collapsed |
| `windows-wide` | 1920x1080 logical | remembered rail, dense list/plan/detail, hover/focus and keyboard affordances |
| `dark-stress` | layout-specific | dark theme, mixed RTL/LTR, 200% text or dense history without overlap |

## Preview comparison rules

- All phone images align to the same viewport and content origin.
- All tablet/Windows images use the same pane minimums and selected entity.
- No finalist may hide a difficult state in a poster-only alternate image.
- Text in canonical plates must be exact and live-equivalent. Image-generation text
  can inform material/composition only; it cannot become the final spec when
  misspelled, clipped or semantically wrong.
- Every generated raster is followed by a vector/layout reconstruction with named
  geometry, tokens and component IDs before Stage 04.

## Final decision handoff

F1 remained the evidence leader after the normal/stress board comparison and the
second weighted scoring pass. F2, F3 and F4 successfully attacked its weaknesses in
trust/history, Windows power and distinctive graphic craft; bounded strengths were
imported without changing the winning topology. `PS01 Perfect Day Instrument` is now
frozen by `selected-direction.md`, and the eight model-native boards remain
noncanonical evidence under `../references/finalist-boards/manifest.md`.
