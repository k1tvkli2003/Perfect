# Perfect

Perfect is a private, cross-device personal planner for Android and Windows. Not a public service, not a store app, no web version. Each device writes to its local database first, then syncs in the background with a private Supabase project. Nothing on screen blocks on the network.

## Features

- Responsive Orbit Day: vertical Android layout, medium/landscape views, and a true three-panel Windows layout.
- Inbox, tasks, recurring tasks, habits, projects, and areas with offline quick capture.
- Sectioned task/habit editor: start/end times, recurrence with exceptions, carry/recovery, multiple reminders with independent snooze, priority, labels, icon and color, estimate/energy, links, checklists, focus/break policy, category, min/max goals, and typed, formula-safe properties.
- Explicit habit logs (check, count, duration, avoidance). Recurring tasks create one independent occurrence per day; completing a day never completes the series.
- Habit history editing and backfill with correction/undo and provenance. Real duplication with a fresh UUID, never copying progress or history.
- Four-state task control in app and widget (empty, done, missed, percent) with ordered, idempotent mutations.
- Pomodoro, countdown, and stopwatch; sessions persist locally before any sync.
- Restorable archive, Conflict Center, task search and filters, and judgment-free local insights.
- Perfect AI as a collapsible dock above capture/footer, with synced history, text/voice input, and reviewable proposals before any planner write.
- Three-state cloud sync (green/yellow/red) with status text and bounded automatic retry; network errors never stop local work.
- Native Android widget in four resize-aware families (small, tall, wide, large): scrollable day list, direct outcome changes, title hiding, automatic day rollover.
- Windows experience with Day Compass and Runway, adjacent Day Stream, contextual inspector, collapsible navigation rail, bounded dialogs, right-click menus, `Ctrl+N`, `Ctrl+1..5`, `Ctrl+K`, `Ctrl+Shift+F` shortcuts, and exact window restore across DPI and multi-monitor setups.
- Project branding and bundled Persian/English fonts (PlusJakarta, Vazirmatn), with the symmetric Day Compass mark shared by UI, Android, and Windows.

## Privacy and sync contract

- Every mutation writes the local change and its outbox entry in one transaction.
- Sync targets one private owner in Supabase; RLS and `planner_owner_profiles` allow no self-enrolment or public sharing.
- Concurrent edits merge at field level where possible; only real conflicts reach the Conflict Center.
- Archive is a synced tombstone, not irreversible deletion.
- Android cloud backup and device-to-device extraction are closed for database, session, configuration, and widget projection; reliable transfer happens only through private sync.
- The `service_role` key never belongs in Flutter, Git, or CI.

## Tech stack

Flutter (Dart 3.12), Drift (local database), Supabase (`supabase_flutter`, eight versioned migrations applied to the private project), Riverpod-style app layers under `lib/` (`planner`, `ai`, `auth`, `presentation`), Android home-widget via native RemoteViews, local notifications, MSIX packaging for Windows.

## Getting started

The main checkout is already wired to the author's private Supabase project with migrations under `supabase/migrations/`. Standard flow:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows    # or a connected Android device
```

Copy any `.env` values from the private project settings; never commit keys. See `docs/private-ai-sync-contract.md` and `docs/agent-plan-ingestion.md` before touching sync or AI ingestion paths.

## Status

Active development, version 1.1.0+2000. Planner, habits, widget, Windows shell, and sync contract are implemented; work continues against the build logs and screenshots in-tree.
