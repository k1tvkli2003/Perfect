# Changelog

All notable changes to Perfect! are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Platform versions increase monotonically so each trusted build installs over
the previous one on both Android and Windows without data loss.

## [1.1.0] — 2026-09

### Added

- **Perfect AI dock** with text and voice input, reviewable proposal display,
  and bounded history sync across authenticated devices.
- **Today Pulse** module on the Windows workspace, projecting live day progress,
  upcoming tasks, and habit streaks in a single glance surface.
- **Focus session sheet** with Pomodoro, countdown, and stopwatch modes;
  sessions persist locally before any sync and survive device restarts.
- **Agent plan ingestion** contract: structured Project/Task/Habit proposals
  from a trusted agent pass through the existing sync pipeline without a
  separate ingestion path.
- **Private AI conversation sync** with immutable messages, action audit,
  cursor-based pagination, and owner-scoped RLS.
- **Conflict Center** sheet for reviewing and resolving genuine field-level
  sync conflicts.
- **Android Today widget** with four resize families, direct outcome control,
  title visibility toggle, automatic day rollover, and optional Quick Add.
- **Planner reminder scheduler** with multiple independent reminders per
  entity, snooze support, and quiet-hour awareness.
- **Habit recovery engine** for carry, pending, and ask-on-miss policies with
  a configurable carry cap.
- **Private AI planner context RPC** (`SECURITY DEFINER`, owner-scoped,
  bounded) so the Edge Function never queries planner tables directly.

### Changed

- Orbit Day layout now recomposes into a true three-panel Windows surface
  with Day Compass, Day Stream, and contextual inspector.
- Sync Cloud indicator gained an explicit three-state model (green synced,
  yellow syncing/retrying, red needs-attention) with text alongside color.
- Task four-state progress control (empty → done → not-done → percent → empty)
  now uses ordered, idempotent mutations with local-first persistence.
- Habit duplicate creates a fresh UUID without copying progress or history.
- Navigation rail on tablet defaults to compact; Windows remembers the
  owner's last state across sessions.
- Brand assets regenerated through deterministic Python tooling; SVG masters
  and raster derivatives carry SHA-256 integrity hashes in manifests.

### Fixed

- Bootstrap no longer blocks Android first frame on slow plugin initialization;
  the Perfect surface paints before storage and Supabase begin loading.
- Sign-out clears the Today widget projection before revoking the session so
  stale data cannot flash on the home screen.
- Configuration page correctly disposes the previous Supabase client before
  re-initializing with new project credentials.

## [1.0.0] — 2026-07

### Added

- **Orbit Day** responsive workspace: Android vertical, tablet landscape,
  and Windows three-panel compositions from a single source.
- **Inbox, Task, Recurring Task, Habit, Project, and Area** with offline-first
  quick capture and field-merge sync.
- **Sectioned editor** with start/end time, recurrence, exceptions, carry,
  priority, labels, icon/color, estimate/energy, checklist, focus preset,
  category, min/max goal, and typed/formula-safe properties.
- **Perfect! brand identity** with Day Compass mark, Vazirmatn and
  Plus Jakarta Sans project fonts, and project-owned SVG pictograms.
- **Theme system** with light/dark/high-contrast modes, semantic color
  tokens, and native Android/Windows surface projection.
- **Motion system** with hover, press, focus, expand/collapse, breakpoint
  transition, and reduced-motion behavior.
- **Private Supabase sync** with owner isolation, RLS, Realtime events,
  and bounded automatic retry.
- **Archive** with resumable tombstones and **insight** surface without
  judgmental language.
- **Feedback capture** with error/suggestion/criticism/note kinds,
  redacted export, and owner-scoped storage.
- **Trusted CI pipeline** with deterministic version calculation, private
  Android/Windows signing, secret scanning, install-over verification,
  and immutable GitHub Release publication.
