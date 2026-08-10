# Integrity five-way opinion ledger

Status: Stage 03 complete-surface decision baseline
Labels: `KEEP`, `REFINE`, `REDESIGN`, `REMOVE`, `ADD`
Rule: no listed product family may be implemented from memory or left silent

## Ledger

| Product family | Decision | Evidence and problem | Target contract | Verification owner |
| --- | --- | --- | --- | --- |
| Day Compass mark | KEEP | Explicit owner selection; strong symmetric small-size identity. | Preserve exact master, produce platform optical variants. | Stages 04/06 identity plates and launcher runtime. |
| Custom Perfect! wordmark | KEEP | Explicit owner selection; current header sometimes falls back to ordinary text. | Exact image asset in header/install surfaces with correct light/dark crops. | Stages 04/06 image and screenshot diff. |
| Pastel apricot/mint/lavender/graphite relation | REFINE | Brand-recognizable but currently spread across large low-purpose panels. | Semantic, restrained accents plus independent status palette. | Stage 04 color-role contrast sheets. |
| Existing Orbit/Day Compass UI | REMOVE | Oversized, duplicated day information, hard-to-read labels, weak dark state and poor task utility. | Compact Today Pulse plus one actionable chronological stream. | Stages 05/11 zero/one/dense comparisons. |
| Header | REDESIGN | Current greeting/title consumes height; logo/sync/date hierarchy varies by form factor. | Compact blurred cluster: wordmark/title, dual date/time, sync state and contextual actions. | Stages 04/08 across short height/200%. |
| Sync cloud | REDESIGN | Current outline/icon feels generic and status is not sufficiently differentiated. | Crafted cloud mark with green/yellow/red + label/tooltip/detail and bounded retry. | Stages 04/15/44 state matrix. |
| Phone footer | REDESIGN | Current selection stadium/labels and background relationships feel heavy. | Icon-only floating glass dock, optical selected halo/shape, semantics labels. | Stages 04/09 touch/IME/occlusion proof. |
| Tablet rail | REFINE | Collapsible behavior exists but composition remains phone-derived in places. | Compact default rail, contextual labels/tooltips, adaptive supporting pane. | Stages 04/10 resize and state retention. |
| Windows rail | REDESIGN | Current rail spacing and wide blank regions do not exploit desktop. | Remembered compact/expanded rail, keyboard accelerators, native hover/context. | Stages 04/10 Windows continuous resize. |
| Generic header three-dot menu | REMOVE | Sign-out/shortcuts are misplaced and undiscoverable. | Profile/settings owns session; shortcuts are contextual/tooltipped. | Stage 08 route and semantics check. |
| Quick Capture orb | REFINE | Useful anchor exists but sits over an unnecessary strip and expansion can summon keyboard. | Standalone heartbeat orb; tap expands mode shell without keyboard. | Stages 04/16 motion/IME tests. |
| Quick Capture expanded shell | REDESIGN | Duplicated labels, separate AI boxes and poorly centered field. | One morphing Task/Plan/AI/Voice shell with independent drafts and centered inactive field. | Stages 04/16–20 visual + focus continuity. |
| Perfect AI icon | REDESIGN | Current symbol is not unmistakably agentic/Perfect-owned. | Authored SVG combining Perfect core and context/action spark without letter/emoji. | Stage 04 small-size/semantic plate. |
| Perfect AI write behavior | KEEP | Proposal-before-write and owner-scoped server context are sound. | Text/voice response plus reviewable proposal, explicit apply and Undo audit. | Stages 41/46/47 integration. |
| AI provider secret placement | KEEP | Server-only boundary is a hard security invariant. | No provider secret in client/build artifacts; edge function owns provider call. | Stages 01/46 secret scan and live probe. |
| Today orientation | REDESIGN | Current split Orbit/cards repeats state and wastes mobile/desktop space. | Compact Pulse, next boundary and continuous day stream. | Stages 05/11 sparse/dense all classes. |
| Today task rows | REDESIGN | Completion/missed controls and percentage rings lack proportional consistency. | Stable row anatomy, arc-only progress, separate explicit outcome cycle. | Stages 04/13 status matrix. |
| Today habit logging | REDESIGN | Repeated/count habits require too many steps. | Method-specific direct controls: +1, preset duration, numeric add/set, next checklist step. | Stages 04/14 and rapid offline logging tests. |
| Pull-to-refresh on ordinary scroll | REMOVE | Rebuild/refresh sensation is disruptive; realtime/background sync already exists. | Normal scrolling never refreshes; named retry/refresh only when useful. | Stages 11/36/38 scroll retention. |
| Tasks workspace | REDESIGN | Current filtering and row/detail hierarchy remain visually weak. | Search/query bar, compact filter deck, saved views, grouping, view-first detail. | Stages 05/36 desktop/phone density. |
| Habits workspace | REDESIGN | Current page undersells streak/recovery and logging methods. | Rhythm strip, risk/recovery cues, direct method controls and honest insights. | Stages 05/38 multi-method scenarios. |
| Plan workspace | REDESIGN | Needs coherent day/week/month and unscheduled relationship. | Day time rail, week grid, month density, unscheduled tray and time-block editing. | Stages 05/37 drag/keyboard/timezone tests. |
| Goals/projects/areas/notes | ADD | Owner requested horizons, goals and richer planning; entities partly exist but lack complete UX. | Outcome hierarchy, horizon review, linked plans/notes and explainable rollups. | Stages 05/39/41 round-trip proof. |
| Daily/weekly/monthly/quarterly review | ADD | Current product lacks a strong reflection/adjustment loop. | Optional ritual: planned/done/carried/learned/adjust-next, never a gate. | Stages 05/39 realistic review flows. |
| Task/Habit detail | ADD | Normal tap currently may enter edit or a thin inspector. | View-first hero, facts, calendar/history, analytics, relations and explicit Edit. | Stages 04/31–35 all entrypoints. |
| Existing desktop inspector | REDESIGN | Thin static facts and action block do not constitute detail/history. | Live selected entity detail pane with stale-object protection and route fallback. | Stages 31/35/36–38 selection tests. |
| Create type chooser | KEEP | Dependency fork is correct for creation. | Task/Recurring/Habit cards with consequence copy and no redundant selected check. | Stages 04/21. |
| Type step during edit | REMOVE | Type is immutable in current model; asking creates false affordance. | Read-only fact in detail; guarded conversion only if a future migration supports it. | Stages 21/31 editor contracts. |
| Multi-step wizard | REDESIGN | Current form/sheet language is inconsistent and too popup-like. | Named adaptive steps, live summary, local draft, branch-specific fields and review. | Stages 04/21–30. |
| Habit evaluation families | KEEP | Boolean/numeric/timer/checklist cover core HabitNow logic. | Add build/maintain/quit intent and formula/derived method while sharing one system. | Stages 22/26–30. |
| Recurrence breadth | KEEP | Existing/domain logic must not lose custom schedules. | Human summary, exceptions, timezone, invalid-state explanation and round trip. | Stages 23/27–29/42. |
| Per-entity recovery | ADD | Owner requires Miss/Pending/Carry/next-valid/prompt/cap. | First-class Recovery step and downstream projection in history/streak/reminders. | Stages 25/29/42/44. |
| Categories | REFINE | Existing categories are too few and customization flow lacks a complete icon archive. | 30+ curated semantic categories, custom icon/color, edit/archive/search/recent. | Stages 04/22/41 dataset + previews. |
| Raw keyboard emoji | REMOVE | Inconsistent artwork and brand quality. | Project-owned SVG pictograms with semantics and optical sizing. | Stage 04 icon archive scan. |
| Selection check beside color change | REMOVE | Redundant, noisy and often misproportioned. | Selected surface/outline/position communicates state; check only when semantically necessary. | Stage 04 selector state plate. |
| Progress percentage inside small rings | REMOVE | Text collides with edge and duplicates arc meaning. | Arc-only compact progress with accessible semantics; numeric detail appears where space permits. | Stages 04/13/14. |
| Status cycle | REFINE | Four-state intent exists but control parity is weak. | Empty/Pending/Partial/Done/Missed reversible cycle with stable geometry and explicit menus for precision. | Stages 13/31/42/widget. |
| Habit streaks | REDESIGN | Streak needs delight without guilt/manipulation. | Current/best/milestone/risk/recovery receipts; derived from immutable logs. | Stages 33/40/41. |
| Gamification | ADD | Owner requested motivating streak/achievement layer. | Non-manipulative XP/achievements/rewards with ledger provenance and opt-out. | Stages 40/41 plus reward integrity. |
| Focus | REDESIGN | Current timer sheet is too narrow for requested scenarios. | Focus Studio: Pomodoro/custom, linked entity, flip option, platform-safe blocking choices, reflection. | Stages 05/35/40. |
| Device lock/flip | ADD | Owner requested stronger focus modes; permissions/platform limits matter. | Flip-to-focus sensor option and explicit OS-supported pinning/DND guidance; never promise universal lock. | Stage 40 permission/runtime evidence. |
| Motion system | REDESIGN | Transitions/opening/selecting currently feel absent or arbitrary. | Named motion roles: title rise, row settle, shared capture morph, overlay settle, status receipt, resize continuity. | Stages 04/07/49 recordings. |
| Dark theme | REDESIGN | Orbit/text contrast failures show palette is not role-driven. | Independent dark tokens, solid fallbacks and contrast verification. | Stages 04/43 screenshot/contrast tests. |
| High contrast/reduced motion | ADD | Not consistently designed in current surfaces. | Explicit fallback components and motion replacements. | Stages 04/43/49. |
| Empty owner state | REDESIGN | Placeholder/demo tasks are forbidden. | Useful first action and optional AI guidance with zero seeded entities. | Stages 05/43 production-fixture proof. |
| Sync/local-first behavior | KEEP | Local transaction + outbox and retry model are core strengths. | Make state visible without blocking; preserve work across errors/upgrades. | Stages 42–44 and N->N+1 proof. |
| Manual scroll refresh | REMOVE | Creates needless rebuilds and scroll jumps. | Realtime/background refresh; explicit retry/error actions only. | Stages 36–39/44. |
| Conflict center | ADD | Sync conflicts need inspectable recovery beyond a cloud color. | Concise surface cue, field-level comparison, deterministic choose/merge and audit. | Stage 44. |
| Android widget | REDESIGN | Core scroll/action behavior exists; mark sizing and size-specific composition remain weak. | Authored size families, direct multi-state actions and native Quick Add dialog. | Stage 48 real launcher matrix. |
| Notifications/deep links | REFINE | Domain callbacks exist but destination continuity can be lost. | View-first detail ingress, stale-action guard, direct log/snooze and auth resume. | Stages 31/35/44/48. |
| Feedback launcher | REFINE | ReadyUse component is valuable but current toggle can obstruct work. | Tiny edge/floating affordance with collision avoidance; screenshot/note/log/redaction. | Stage 45 all layouts. |
| Settings IA | REDESIGN | Secondary controls risk becoming a generic More page. | Searchable grouped settings: Appearance, Planning, Habits, Focus, AI, Sync, Widget, Diagnostics, Session. | Stages 05/45. |
| Profile/session | REFINE | Personal credentials/session exist; update must not sign out. | Clear owner/device/sync state, explicit sign-out with local-data consequence copy. | Stages 43/45/50. |
| Diagnostics/logs | ADD | User requested reusable error/screenshot/note logging. | Redacted local log viewer, health cards, export/share consent and recovery instructions. | Stage 45. |
| Packaging/release UI | REFINE | Hosted release now succeeds with three assets; installed surfaces need brand coherence. | Correct icon/title/version/publisher in installer, About and OS surfaces. | Stages 06/50 install captures. |
| Signed in-place updates | KEEP | Stable signing/version lineage is a hard invariant. | Monotonic Android/Windows versions, same identity, preserved auth/local data. | Stage 50 two-artifact proof. |

## Silent-surface audit

No silent rows remain in the Stage 03 product inventory.

The ledger explicitly covers identity, shell, navigation, common components,
Today/Tasks/Plan/Habits/Goals/Focus, create/edit/detail, AI/voice, states, motion,
widget, notifications/deep links, feedback, auth/session, settings/diagnostics,
local-first/sync/conflict and packaging/release. Any new surface discovered later is
added here before its preview or implementation begins.
