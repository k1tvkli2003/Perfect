# Plan

## Approach
بازسازی به شکل expand/migrate/verify انجام می‌شود: ابتدا مبنای فعلی و قراردادهای کاربر حفظ می‌شوند، سپس مدل داده و لایهٔ sync به‌صورت سازگار توسعه می‌یابد، بعد shell و صفحات Orbit Day با دادهٔ واقعی جایگزین UI ساده می‌شوند. هر تغییر داده‌ای migration افزایشی، idempotent و قابل rollback دارد. UI تا جای ممکن از اجزای live semantic ساخته می‌شود؛ تصاویر تولیدی فقط برای هدف‌گذاری بصری هستند.

### Requirement ledger

| ID | Requirement | Source | Evidence needed | Owner | Status |
|---|---|---|---|---|---|
| R1 | Flutter Android/Windows | user | build + runtime/screenshot matrix | multi-os | in progress — configured Android artifact verified; final hosted Windows artifact remains |
| R2 | private local-first cross-device Supabase sync | user | schema/RLS + offline/conflict tests | backend/function | complete except two-install convergence — live migration/RLS/RPC/Auth and local/offline contracts pass |
| R3 | complete personal planner options/scenarios | user | feature/state matrix + journeys | anatomy/function | complete locally — 162-test suite covers core and hostile paths |
| R4 | Orbit Day branding and selected icon/type | user selection | final assets + runtime screenshot | modernize/style | complete — transparent 512 source/Windows and Pixel-verified pastel Android adaptation |
| R5 | dedicated portrait and landscape experiences | user | screenshots and layout rules at each class | anatomy/style | complete locally |
| R6 | precise prewritten plan and durable record | user | this task record + validation | work-docs/orchestrator | complete through implementation; final CI evidence remains |
| R7 | preserve current data/auth/contracts | rebuild | preservation/migration evidence | rebuild/integrity | complete — additive/idempotent live migrations and compatibility tests pass |
| R8 | high quality, resilience and performance | named skills | critic audit + measurements/tests | critics/perfect/performance | complete — all actionable findings fixed; frozen 8-page Critics PDF visually verified |

### Preservation contract

| Asset or contract | Location/source of truth | Class | Baseline evidence | Allowed change | Restore method | Acceptance proof |
|---|---|---|---|---|---|---|
| Existing app source and Git history | Git `main`, current root commit | compatible-migration | clean `git status`; tracked-file inventory | additive/reversible commits | `git revert` of owned commits | old core behavior still covered by regression tests |
| Local persisted simple items | `PersonalItemsStore` key and `PersonalItem` adapter, to be audited | compatible-migration | store schema/key and round-trip test | read legacy then project into new model | keep legacy adapter until successful projection | legacy item loads and appears in Today/Inbox |
| Supabase `perfect_items` schema/history | `supabase/migrations/20260730053612_create_perfect_items.sql` | compatible-migration | four aligned remote/local migration versions plus live replay/RLS/RPC evidence | append-only migrations and views/adapters | migration rollback document, no destructive edit | migration SQL replay + anon/owner Data API smoke |
| Supabase Auth / owner privacy | `main.dart`, auth UI, RLS policies | compatible-migration | auth state and policy inventory | owner-scoped new tables/policies only | retain existing auth flow and policy history | user A cannot read/write user B in contract tests/live validation when configured |
| Public/deep-link routes | current app has no named router/deep links | unresolved | source route inventory | add canonical routes only; no removal | route table and fallback shell | route/back/unauthorized tests after routing is introduced |
| Secrets/configuration references | `AppConfig` dart-defines; no values in repository | immutable | key names only | additive documentation/wiring | restore prior define mapping | unconfigured app state and configured startup path |
| Native launcher/splash assets | Android mipmaps and Windows `.ico` | derived/rebuildable | current asset inventory | derive from the approved transparent 512 master with platform-safe masks | keep original assets until each platform artifact proves new assets | Android/Windows launcher/splash inspection |

## Steps
| Step | Status | Notes |
|---|---|---|
| 1 | complete | Baseline, preservation contract, requirement ledger and source/platform audits recorded. |
| 2 | complete | Product, sync, native and responsive constraints reconciled before mutation. |
| 3 | complete | Canonical planner entities, occurrence/focus history, tombstones and idempotent outbox are implemented. |
| 4 | complete | Local persistence and contract tests pass; migrations, owner gate, RLS, RPC replay/idempotency, cursor pull and GitHub client configuration were proven live on the private project. |
| 5 | complete | Compact, medium and expanded responsive shell is implemented. |
| 6 | complete | Orbit Day, Inbox/filters, editor, project/area and time plan are functional; drag/reorder is deliberately deferred. |
| 7 | complete locally | Habits, focus, insight, archive, reminders and diagnostics are implemented and tested; exact alarm/reboot notification proof remains device-specific. |
| 8 | complete | Selected mark/wordmark, launcher source and platform icons are wired from workspace assets. |
| 9 | in progress | Analyzer, 162 tests, Android release APK and Pixel Launcher widget runtime pass; Windows local build is environment-blocked and hosted CI remains. |
| 10 | in progress | Docs are being finalized; commit/push and first hosted CI observation remain. |

### Responsive Orbit Day rules

| Layout class | Approximate width/orientation | Primary composition | Navigation and actions |
|---|---|---|---|
| Compact portrait | Android phone portrait | Day orbit is an upper stage; timeline follows below; quick capture is bottom dock | bottom navigation; contextual sheets; no reliance on hover |
| Compact landscape / medium | Android phone landscape or narrow Windows window | orbit becomes a left contextual panel; Now/timeline occupies center; Inbox and detail use a switchable/docked secondary pane | navigation rail or compact top rail; keyboard and mouse controls appear without hiding touch paths |
| Expanded landscape | Windows wide window | three intentional regions: persistent navigation, Orbit/Today stage, timeline+Inbox/inspector | navigation rail; command/quick-capture remains within reach; panels have explicit min/max widths |

Breakpoints will be based on available content width and orientation, not device model. Text remains live/RTL-capable; the orbit may simplify to an accessible linear timeline when space, large text or reduced motion requires it.

### Capability and scenario matrix

Perfect is not a fixed checklist. Each object has a small, clear default and an optional detail surface; advanced settings never block quick capture.

| Domain | Per-object customisation | Mandatory behavior/recovery |
|---|---|---|
| Task | title, note, links, area/project, labels, icon/color, priority, status, estimate, energy/focus hint, due date, all-day or start/end block, recurrence, reminders, subtasks, custom fields, archive policy | inbox first; edit/duplicate/reorder; complete, skip, postpone, reschedule, archive, restore and undo delete; validation keeps draft; all mutations work offline and are retryable |
| Recurring task | interval, weekdays, month/year rule, start/end/occurrence limit, timezone, next-occurrence generation rule, carry-over behavior, custom reminder schedule | completing/skip/postpone never silently creates duplicate occurrences; DST/timezone, end-rule and missed-occurrence paths are deterministic |
| Habit | name, category, icon/color, binary/count/duration/amount/limit target, unit, target amount, daily/weekly/monthly schedule, active/rest days, time window, reminder(s), negative/avoidance tracking, personal note, start date, pause/archive | log, amend, skip, pause, resume, backfill with provenance; streak/consistency never punishes a legitimate rest day; clear recovery suggestion after missed days |
| Habit history | per-occurrence value, date/time, note, source/manual/focus metadata and correction history | changing a past log updates insights safely; no duplicated daily event after retry or daylight-saving change |
| Day plan | non-destructive membership of canonical tasks, ordering, time slot, duration, priority/focus tag, daily note and plan reset preference | the next day starts fresh without deleting unfinished source tasks; scheduled/due items can be suggested and explicitly accepted/rejected |
| Project / area | title, description, color/icon, status, archive, default reminders/labels/template, due horizon and review cadence | moving tasks does not lose history; archived objects remain recoverable and never leak into default active views |
| Focus | task/habit association, timer/countdown/stopwatch/interval presets, break policy, goal duration, manual adjustment and session note | pause/resume/restart/cancel/complete are explicit; interrupted sessions persist locally; summary cannot claim an unfinished focus block as complete |
| Reminders / notifications | one or more time rules, recurrence, snooze policy, quiet hours, per-object enable/disable, platform permission state | no reminder changes task due date; permission denied/unavailable and web/Windows limitations are visible with a safe in-app fallback |
| Personal control | theme, density, first weekday, timezone, Persian/English display preferences, week/start-of-day, default quick-capture behavior, sync diagnostics, conflict resolution preference | sign-out/account switch isolates local data; diagnostics expose sync state without adding a manual backup/export surface |

### Adversarial scenario coverage

1. **Data lifecycle:** blank first run, quick capture, long/RTL/mixed text, duplicate titles, empty/invalid input, edit during save, duplicate action, undo, archive/restore, import/export, app-kill after local commit.
2. **Planning:** no time/all-day/time block, overlap, reorder, drag and keyboard placement, overdue, deferred, recurring, timezone travel, DST, one-off exception, project/archive/area deletion.
3. **Habits and focus:** binary, target and negative values; rest/skip/backfill; missed week; manual correction; timer interrupted, backgrounded or force-closed; focus linked to a deleted/archived task.
4. **Sync/privacy:** offline launch, offline mid-mutation, reconnect, retry acknowledgement lost, authentication expiry, account switch, RLS denial, schema mismatch, two devices create/edit/delete the same record, realtime drop, large change backlog, conflict presentation, tombstone retention/compaction.
5. **Experience/platform:** loading/empty/error/pending/success, reduced motion, screen reader, touch/mouse/keyboard, Android portrait/landscape, compact/expanded Windows window, resize, system font 200% and RTL/LTR.

## Interfaces and Artifacts
- Flutter domain models, local store, controller and sync repository.
- Additive Supabase SQL migrations and RLS policies.
- Responsive route/shell map and functional widgets.
- Vector brand assets: selected orbital launcher mark, wordmark treatment, semantic icon family and splash variants.
- Android resources and Windows runner icon.
- Tests, CI, docs/codex evidence and rollback notes.

## Risks
- Existing sync is likely too small for concurrent multi-device edits; mitigate with an explicit op/idempotency/version model and contract tests before replacing UI flows.
- No real Supabase project is in scope; mitigate by treating migration/RLS as code artifact and clearly separating live validation.
- Generated previews contain English and mock geometry; mitigate with a preview-to-production decomposition manifest and actual RTL/runtime screenshots.
- Windows local build can be blocked by Developer Mode/plugin symlinks and missing C++ workload; mitigate with transparent proof matrix and CI/artifact checks where possible.
- Dense orbit UI can become decorative or unreadable; mitigate with linear fallback, clear action hierarchy, touch-target budgets and portrait/landscape screenshots.

## Acceptance Checks
- Existing simple items survive projection into the richer task model; no applied migration is edited or destructively removed.
- Every mutation works offline, survives restart, retries safely, reconciles from remote and exposes a comprehensible sync/error state.
- A user can capture, schedule, complete, postpone, delete/undo, edit and find a task; log a habit; start/finish focus; and see data persist locally.
- Portrait, landscape and expanded windows each have deliberate composition, visible next action, keyboard/focus path and no overlap/clipping under RTL/long text.
- Selected brand identity is rendered from one workspace-owned transparent raster master plus live wordmark typography across app, Android and Windows surfaces.
- `dart analyze`, focused tests and Android debug build pass; Windows build/runtime is attempted and any environment-only blocker recorded.

### Locked implementation decisions

- **No web / no public release:** Android and Windows are the only build targets. GitHub Actions is private build transport, not a release channel.
- **Single private owner:** public self-signup is disabled operationally; `planner_owner_profiles` permits one allowlisted Auth UUID.
- **Local first:** every planner mutation is persisted locally with an outbox record before remote sync. Screens render local state even while offline.
- **Series are not completed:** a recurring task stores a dated occurrence; a habit stores a check/count/duration/avoidance log. Neither action completes the reusable source entity.
- **Failure is explicit:** one-off defaults to pending/carry with a cap; recurring/habit defaults to miss then next scheduled occurrence. The user can mark a daily miss or move a one-off task to tomorrow.
- **Archive is recoverable:** Archive writes a tombstone and a restore is an explicit sync operation; no destructive UI delete is offered.
- **Typed properties are safe:** values are typed, and formulas use a narrow arithmetic DSL rather than executable code.
