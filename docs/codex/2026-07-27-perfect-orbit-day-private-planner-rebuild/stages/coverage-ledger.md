# Perfect! — Whole-product coverage and propagation ledger

Status: mandatory companion to all 50 stage work orders  
Platforms: Android phone/tablet and Windows compact/expanded  
Rule: a stage title names the primary owner; it never limits the impact review

## Why this ledger exists

Perfect! is one connected instrument. A change to status, recurrence, date,
category, sync, routing, motion or schema is rarely local to one screen. This
ledger prevents a strong-looking isolated page from leaving stale behavior in a
widget, detail route, notification, AI action, desktop inspector or upgrade path.

Before a stage can move to `complete`, its implementation record must classify
every row below as one of:

- `changed + proved`: the consumer changed and has named evidence;
- `checked unchanged`: the consumer was inspected and its contract still holds;
- `not applicable`: supported by a specific reason, never by silence;
- `blocked`: named blocker, preserved data/state and next executable action.

## Five propagation lenses for every decision

1. **Entry and exit:** all routes, row taps, notification/widget/deep-link opens,
   back behavior, focus restoration and selection/scroll continuity.
2. **Presentation:** phone portrait/landscape, tablet portrait/landscape and
   collapsed rail, compact/intermediate/expanded Windows, light/dark/high
   contrast, sparse/dense/long mixed text and 200% scale.
3. **Interaction:** touch, mouse, hover, keyboard, IME, reduced motion, undo,
   cancellation, interruption, background/resume and resize mid-action.
4. **Durability:** local projection, operation queue, Supabase representation,
   owner isolation, realtime/background refresh, conflict, retry, widget
   projection, notification schedule and AI contract.
5. **Lifecycle:** fresh owner, create, view, log/progress, edit, duplicate,
   archive, restore, delete, export/import/recover and signed in-place upgrade.

## Full product surface ownership matrix

| Product system | Primary construction stages | Mandatory re-check stages | Minimum proof |
| --- | --- | --- | --- |
| Boot, splash, configuration and private sign-in | 01, 06, 43, 45 | 10, 49, 50 | cold/warm/offline/auth-expired starts; N→N+1 session retention |
| Installed brand, typography, icon and platform identity | 03, 04, 06 | 10, 48–50 | Android launcher/splash/widget and Windows taskbar/Start/installer captures |
| Responsive shell, header, footer and rail | 04, 07–10 | 20, 35, 49 | continuous resize recordings, focus/scroll preservation, no dead strip |
| Sync cloud, dual date/time and ambient state | 08, 15, 44 | 11–14, 36–40, 48–50 | known Jalali boundaries; green/yellow/red semantic states; retry recovery |
| Today orientation and day stream | 11–15 | 24, 27–30, 39–40, 44, 48–49 | zero/one/dense day screenshots and real task/habit mutations |
| Task row, progress and status cycle | 13, 17, 23–25 | 31–32, 36–37, 42, 44, 47–49 | Pending/Partial/Done/Missed parity in every consumer; no cramped percentage |
| Habit logging and streak state | 14, 26–30 | 33, 38, 40–42, 44, 47–49 | all tracking methods, rapid increments, correction, rollover and widget replay |
| Quick Capture/Plan/AI/Voice instrument | 16–20 | 21, 42, 46–49 | one morphing surface, draft/focus retention, no implicit keyboard or duplicate write |
| Task/recurring/habit creation and edit | 21–30 | 31–34, 36–39, 41–47, 49 | create/edit parity, no immutable Type step in edit, recovery preview and draft safety |
| Detail, history, analytics and lifecycle | 31–35 | 36–40, 42, 44, 47–49 | view-first route from every entry; reproducible stats; reversible lifecycle actions |
| Tasks workspace | 13, 31–32, 36 | 41–44, 47, 49 | search/filter/sort/saved view/bulk action across narrow and desktop states |
| Plan day/week/month and time blocks | 08, 12, 23–24, 37 | 39–44, 47, 49 | timezone/midnight/overlap/drag-cancel tests and meaningful tablet/Windows layout |
| Habits workspace and insights | 14, 27–30, 33, 38 | 40–44, 47–49 | log from list/detail, honest insights, build/maintain/quit parity |
| Goals, projects, areas, notes and horizons | 21–25, 39, 41 | 42, 44, 47, 49 | stable identities, explainable rollups, no orphan/double count, AI proposal parity |
| Focus sessions and gamification | 31–35, 40 | 41–42, 44, 47, 49–50 | pause/resume/background/upgrade continuity and derived reward integrity |
| Categories, icons, colors and custom metadata | 04, 06, 22, 41 | 36–39, 45, 47–49 | 30+ curated choices, custom round trip, SVG/semantic/theme consistency |
| Search, filter, sort, saved views and bulk actions | 02, 04, 36–39 | 41–42, 44, 49 | composable filters, reset/discovery, keyboard/touch parity, persisted intent |
| Reminders, quiet windows and notification actions | 23–24, 31, 35 | 40–44, 48–50 | permission denial, reschedule/cancel, deep-link detail and stale-action safety |
| Archive, trash, conflict center and recovery | 01–02, 34, 42, 44–45 | 47, 49–50 | archive/restore/delete/undo, deterministic conflict resolution and non-reset recovery |
| Settings, profile, theme and widget settings | 06–10, 43, 45, 48 | 49–50 | adaptive settings IA, persisted preferences, no session/data reset on update |
| Feedback, logs, screenshot and private diagnostics | 05, 45 | 49–50 | unobtrusive launcher, consent/redaction, export integrity and failure recovery |
| Local database, operation log and migrations | 01, 27–29, 41–42 | 43–50 | clean/upgrade migrations, idempotency, atomicity, owner scope and convergence |
| Supabase RLS, realtime, RPC/functions and sync | 01, 41–44 | 46–47, 49–50 | cross-owner rejection, replay/out-of-order tests, live proof when credentials exist |
| Perfect AI text/voice/context/actions/audit | 19, 41, 46–47 | 44, 49–50 | server-only key, proposal→review→apply→undo, zero writes before confirmation |
| Android widget and Quick Add | 06, 13–14, 31, 42, 48 | 44, 49–50 | real launcher resize/scroll/actions/offline/deep-link proof at every size |
| Accessibility, localization and mixed direction | 03–10 | every UI stage; final 49 | semantics, traversal, 48dp targets, RTL/mixed copy, 200%, reduced motion |
| Performance, privacy, packaging and release | 01, 05, 20, 30, 40, 43, 46 | 49–50 | startup/frame/query/sync budgets; secret scan; three install-ready artifacts |

## Cross-stage decision propagation rules

### Domain or schema change

Trace the field or entity through migration, local model, repository, operation
queue, RLS/RPC, realtime merge, controller, all list/detail/editor renderers,
widget projection/action, notification payload, AI read/write schema, export/import,
tests and upgrade fixtures. A field that exists only in the editor and database
is incomplete.

### Shared UI component or token change

Inventory every instantiation before editing. Verify optical alignment, long
copy, hit geometry, semantics and motion in every host. If a host legitimately
needs a variant, encode a named variant rather than forking anonymous values.

### Navigation change

Trace touch, mouse, keyboard, notification, widget, AI result and Windows protocol
entry. Prove back-stack, selection, scroll, draft and focus across resize and
process restore. No route may send a normal row tap directly to edit.

### Status, recurrence or habit-tracking change

Trace projection and mutation across Today, Tasks, Plan, Habits, detail/calendar,
insights, focus/reward derivation, widget, reminders, AI proposals, conflict merge
and export. Historical truth is immutable; corrections append auditable state.

### Visual or motion change

Compare before/reference/after side by side at all layout classes. Inspect crop,
scale, center, symmetry, curved/complex graphics, z-order, blur boundaries,
negative space, text placement and reduced-motion replacement. Passing without
overflow is necessary but never sufficient.

### Sync/auth/security change

Exercise local success while offline, queued replay, retry/backoff, auth refresh,
revocation, conflict, cross-owner rejection, app restart, OS restart and in-place
upgrade. Never clear the database or session to make a test pass.

## Required scenario lattice

Every stage selects all applicable cells; Stage 49 reruns the complete lattice.

| Axis | Required values |
| --- | --- |
| Data density | fresh empty owner; one item; normal; dense; multi-year history |
| Connectivity | online; offline start; loss mid-write; retry; server error; conflict |
| Authentication | valid; refresh; expired; revoked; offline cached session; upgrade |
| Window | phone portrait/short landscape; tablet portrait/landscape/split; Windows compact/intermediate/wide |
| Input | touch; long press; mouse; hover; keyboard; shortcut; IME; outside dismissal |
| Text | short; long; Persian; English; mixed RTL/LTR; 100%; 200% |
| Theme/motion | light; dark; high contrast; normal motion; reduced motion |
| Lifecycle | create; view; log/progress; edit; undo; archive; restore; delete; recover |
| Origin | in-app; widget; notification; AI proposal; remote device; imported backup |

## Stage completion evidence template

Each stage's progress record must contain:

1. frozen before evidence and exact failure statement;
2. affected-consumer inventory produced before code changes;
3. implementation diff grouped by product contract, not file type;
4. checked-unchanged list with reason and evidence;
5. focused tests plus integration/runtime proof;
6. phone/tablet/Windows sparse and dense visual comparisons;
7. offline/error/retry/accessibility/performance results as applicable;
8. upgrade/release evidence at the mandated milestone;
9. remaining risks with owner and next numbered stage;
10. explicit declaration that no product surface was silently omitted.

## Global rejection conditions

Reject any stage—even if its local tests pass—when:

- the same concept has inconsistent labels, status, iconography or interaction in
  another consumer;
- a new field/action cannot round-trip through local store, sync, AI/widget or
  backup where applicable;
- phone looks acceptable while tablet/Windows is stretched, sparse or cramped;
- visual polish hides weak keyboard, screen-reader, offline or recovery behavior;
- a route, resize, IME, sync event or update loses focus, draft, selection, scroll,
  authentication or local data;
- sample entities can reach the signed owner build;
- evidence covers only a static test or a single viewport;
- implementation solves the titled surface while leaving its downstream system
  stale, contradictory or inaccessible.
