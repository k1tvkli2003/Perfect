# Plan

## Approach
بازسازی به شکل expand/migrate/verify انجام می‌شود: ابتدا مبنای فعلی و قراردادهای کاربر حفظ می‌شوند، سپس مدل داده و لایهٔ sync به‌صورت سازگار توسعه می‌یابد، بعد shell و صفحات Orbit Day با دادهٔ واقعی جایگزین UI ساده می‌شوند. هر تغییر داده‌ای migration افزایشی، idempotent و قابل rollback دارد. UI تا جای ممکن از اجزای live semantic ساخته می‌شود؛ تصاویر تولیدی فقط برای هدف‌گذاری بصری هستند.

### Requirement ledger

| ID | Requirement | Source | Evidence needed | Owner | Status |
|---|---|---|---|---|---|
| R1 | Flutter Android/Windows | user | build + runtime/screenshot matrix | multi-os | partial — CI run `30519295088` built and uploaded Android and unpackaged Windows artifacts for `d56455b`; Android runtime passed، Windows runtime was not available on this host |
| R2 | private local-first cross-device Supabase sync | user | schema/RLS + offline/conflict tests | backend/function | complete except two-install convergence — eight live migrations، owner/RLS/RPC/Auth and local/offline/retry contracts pass |
| R3 | complete personal planner options/scenarios | user | feature/state matrix + journeys | anatomy/function | complete locally — 262-test suite covers core and hostile paths |
| R4 | Orbit Day branding and selected icon/type | user selection | final assets + runtime screenshot | modernize/style | selected/implemented — Day Compass has a cleaned transparent 512 master, Android legacy/adaptive/monochrome assets, multi-frame Windows ICO and Pixel Launcher proof; fresh hosted Windows proof remains |
| R5 | dedicated portrait and landscape experiences | user | screenshots and layout rules at each class | anatomy/style | partial — Android runtime and adaptive/golden tests pass؛ expanded Windows compiles in CI but has not been observed in the real executable |
| R6 | precise prewritten plan and durable record | user | this task record + validation | work-docs/orchestrator | active — implementation، final identity decision and post-selection Android proof are recorded; final hosted run/handoff remain |
| R7 | preserve current data/auth/contracts | rebuild | preservation/migration evidence | rebuild/integrity | complete — additive/idempotent live migrations and compatibility tests pass |
| R8 | high quality, resilience and performance | named skills | critic audit + measurements/tests | critics/perfect/performance | partial whole-product proof — actionable Critics findings، analyzer clean، 256 tests and current goldens pass؛ fresh artifact/CI، Windows runtime and physical-device/OEM checks remain |
| R9 | agentic AI Dock with text/voice and reviewable planner writes | user + ai | server-secret boundary, responsive UI, tool validation, live provider smoke | ai/backend/style | implemented and deployed — history hydration، text/voice UI، durable proposal review، secure context RPC and Function v3 auth boundary pass; rotated-provider smoke remains |
| R10 | Android tablet as first-class experience and collapsible tablet/desktop navigation | user | phone/tablet/Windows responsive tests + runtime resize | anatomy/style/function | complete in source/goldens — tablet and Windows compositions، rail persistence and responsive states pass; executable runtime proof remains |
| R11 | premium motion/hover/transition system and no raw emoji artwork | user + self-improve | asset audit, motion-state matrix, reduced-motion/runtime proof | style/integrity | implemented for current surfaces and covered by responsive/interaction tests؛ full real-runtime motion recording remains |
| R12 | in-place upgrades preserve session/data | user | two signed consecutive installs on Android/Windows | multi-os/actions/integrity | active — stable JKS/PFX، monotonic versions، serialized `queue: max` CI، exact artifact placeholder، Windows trust/install instructions and offline signing-backup checklist are closed؛ two-version device proof remains |
| R13 | widget Quick Add through a compact native popup | user | native widget host tap, local create, refresh and sync proof | widgets/function | active — implementation delegated with durable queue/idempotency requirement |
| R14 | intelligent constraint-driven geometry without screen hardcoding or percentage dogma | user + self-improve | multi-axis viewport/text-scale/IME tests, runtime resize and state-retention proof | style/modernize/rebuild/widgets | active — shared and project contracts recorded; implementation audit and runtime proof in progress |

### Preservation contract

| Asset or contract | Location/source of truth | Class | Baseline evidence | Allowed change | Restore method | Acceptance proof |
|---|---|---|---|---|---|---|
| Existing app source and Git history | Git `main`, current root commit | compatible-migration | clean `git status`; tracked-file inventory | additive/reversible commits | `git revert` of owned commits | old core behavior still covered by regression tests |
| Local persisted simple items | `PersonalItemsStore` key and `PersonalItem` adapter, to be audited | compatible-migration | store schema/key and round-trip test | read legacy then project into new model | keep legacy adapter until successful projection | legacy item loads and appears in Today/Inbox |
| Supabase `perfect_items` schema/history | `supabase/migrations/20260730053612_create_perfect_items.sql` | compatible-migration | four aligned remote/local migration versions plus live replay/RLS/RPC evidence | append-only migrations and views/adapters | migration rollback document, no destructive edit | migration SQL replay + anon/owner Data API smoke |
| Supabase Auth / owner privacy | `main.dart`, auth UI, RLS policies | compatible-migration | auth state and policy inventory | owner-scoped new tables/policies only | retain existing auth flow and policy history | user A cannot read/write user B in contract tests/live validation when configured |
| Public/deep-link routes | current app has no named router/deep links | unresolved | source route inventory | add canonical routes only; no removal | route table and fallback shell | route/back/unauthorized tests after routing is introduced |
| Secrets/configuration references | `AppConfig` dart-defines; no values in repository | immutable | key names only | additive documentation/wiring | restore prior define mapping | unconfigured app state and configured startup path |
| Native launcher/splash assets | Android mipmaps and Windows `.ico` | derived/rebuildable | selected Day Compass chroma source plus cleaned 512 RGBA master | derive all raster, monochrome and ICO variants from the checked-in pipeline | regenerate with `tool/generate_day_compass_assets.py` and `flutter_launcher_icons` | Pixel Launcher/widget picker plus Windows Explorer/taskbar/window inspection |

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
| 8 | complete locally | Day Compass was selected from the symmetric exploration, chroma-cleaned, wired across app/widget/Android/Windows and proven in Pixel Launcher; new hosted Windows artifact proof remains under step 9. |
| 9 | complete locally with runtime limit | Analyzer، 256 tests، 44 Workspace UI tests، 5 release-contract tests، 33 focused AI tests and Deno check pass. Run `30519295088` remains only the preceding Android/Windows baseline؛ fresh signed artifacts follow the final push. Windows executable runtime was not exercised locally. |
| 10 | in progress | Function v3 live gate passed؛ signed Android install-over، documentation gate، commit/push and exact-SHA CI/artifact inspection remain. |

### Responsive Orbit Day rules

| Layout class | Approximate width/orientation | Primary composition | Navigation and actions |
|---|---|---|---|
| Compact portrait | Android phone portrait | Day orbit is an upper stage; timeline follows below; quick capture is bottom dock | bottom navigation; contextual sheets; no reliance on hover |
| Compact landscape / medium / tablet | Android phone landscape, Android tablet portrait/landscape, or narrow Windows window | Day Deck: یک Day Compass Stage بزرگ و متناسب در کنار Day Stream پیوسته؛ Habit Pulse/Next Up به جریان وصل‌اند و sparse data به void عظیم تبدیل نمی‌شود | collapsible icon rail, compact by default on tablet; AI command pill کوچک بالای capture و expanded surface منظم؛ keyboard/mouse controls augment rather than replace touch paths |
| Expanded landscape | Windows wide window | three intentional regions: navigation, Orbit/Today stage, timeline+Inbox/inspector | collapsible rail with remembered desktop preference; command/AI/quick-capture remain within reach; panels have explicit min/max widths |

Breakpoints will be based on where the current composition stops serving its content, using available width, height, orientation, text scale, safe area and input mode rather than device model. Geometry deliberately mixes intrinsic content sizing, flex distribution, bounded fractions, meaningful aspect ratios, measured anchors and fixed semantic tokens. Neither screen-specific hardcoding nor unbounded percentage sizing is accepted. Text remains live/RTL-capable; the orbit may simplify to an accessible linear timeline when space, large text or reduced motion requires it. Breakpoint changes must preserve draft, focus, selection, scroll and state.

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
- Brand assets: selected wordmark/Orbit Day system, transparent Day Compass master, monochrome source, Android derivatives and multi-resolution Windows ICO. Comparison concepts remain only as design history.
- Android resources and Windows runner icon.
- Tests, CI, docs/codex evidence and rollback notes.

## Risks
- Existing sync is likely too small for concurrent multi-device edits; mitigate with an explicit op/idempotency/version model and contract tests before replacing UI flows.
- Live migration/RLS/RPC/Auth evidence does not by itself prove Android↔Windows convergence; retain the local-first contracts and run a two-install owner-session journey before claiming cross-device completion.
- Generated previews contain English and mock geometry; mitigate with a preview-to-production decomposition manifest and actual RTL/runtime screenshots.
- Windows local build can be blocked by Developer Mode/plugin symlinks and missing C++ workload; mitigate with transparent proof matrix and CI/artifact checks where possible.
- Dense orbit UI can become decorative or unreadable; mitigate with linear fallback, clear action hierarchy, touch-target budgets and portrait/landscape screenshots.

## Acceptance Checks
- Existing simple items survive projection into the richer task model; no applied migration is edited or destructively removed.
- Every mutation works offline, survives restart, retries safely, reconciles from remote and exposes a comprehensible sync/error state.
- Sync Cloud is green only when caught up, yellow while syncing or retrying, and red after an error; icon/label/semantics carry the meaning in addition to colour.
- A user can capture, schedule, complete, postpone, delete/undo, edit and find a task; log a habit; start/finish focus; and see data persist locally.
- Portrait, landscape and expanded windows each have deliberate composition, visible next action, keyboard/focus path and no overlap/clipping under RTL/long text.
- Android tablet has a dedicated two-pane composition and collapsible navigation; desktop navigation is also collapsible and does not permanently consume a wide column.
- Hover, press, focus, expand/collapse, breakpoint changes, loading and completion feedback share a deliberate motion system and honor reduced motion without layout jumps.
- No user-visible raw keyboard emoji is used as artwork; dedicated SVG assets remain crisp, themed and accessible.
- Two consecutive Android and Windows builds install in place with the same signing identity, preserve local planner data and do not ask for login again unless the server invalidated the session.
- The selected Day Compass identity is rendered from one workspace-owned transparent raster master plus live wordmark typography across app, Android and Windows surfaces; Android's mandatory adaptive mask uses a quiet pastel fill only because a transparent adaptive background became black on Pixel Launcher.
- `dart analyze`, focused tests and Android debug build pass; Windows build/runtime is attempted and any environment-only blocker recorded.

### Locked implementation decisions

- **No web / no public release:** Android and Windows are the only build targets. GitHub Actions is private build transport, not a release channel.
- **Single private owner:** public self-signup is disabled operationally; `planner_owner_profiles` permits one allowlisted Auth UUID.
- **Local first:** every planner mutation is persisted locally with an outbox record before remote sync. Screens render local state even while offline.
- **Series are not completed:** a recurring task stores a dated occurrence; a habit stores a check/count/duration/avoidance log. Neither action completes the reusable source entity.
- **Failure is explicit:** one-off defaults to pending/carry with a cap; recurring/habit defaults to miss then next scheduled occurrence. The user can mark a daily miss or move a one-off task to tomorrow.
- **Archive is recoverable:** Archive writes a tombstone and a restore is an explicit sync operation; no destructive UI delete is offered.
- **Typed properties are safe:** values are typed, and formulas use a narrow arithmetic DSL rather than executable code.
- **Launcher identity is locked:** Day Compass is canonical. The workspace-owned transparent ۵۱۲ master generates Android legacy/adaptive/monochrome and a nine-frame Windows ICO deterministically؛ other concepts remain design history only.
- **Private CI proof:** run `30519295088` succeeded for `d56455b` and preserved configured Android and unpackaged Windows artifacts. It did not produce a signed MSIX because the signing identity was unavailable.
- **Agent-ready writes:** external and in-app agents use versioned, owner-authenticated, create-only, idempotent batches. Planner writes remain proposed until owner confirmation and flow through `planner_changes`.
- **AI secret boundary:** `gemini-flash-lite-latest` is invoked only by the Supabase Edge Function; the Flutter bundle contains no provider credential.
- **Update lineage:** Android package/JKS certificate and Windows identity/publisher/PFX are stable. CI build numbers are monotonic and trusted builds fail closed when fingerprints do not match.
