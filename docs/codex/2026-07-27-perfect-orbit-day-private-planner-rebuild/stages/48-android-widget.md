# Stage 48 — Responsive, scrollable and actionable Android Today widget

Status: pending  
Depends on: Stages 06, 10, 12–15, 28–31 and 41–47  
Blocks: Stages 49 and 50  
Primary surfaces: Android launcher picker/resize host, native RemoteViews collection,
widget action receivers, compact Quick Add dialog, Dart background bridge and deep links

## Mission

Make the Today widget a trustworthy extension of Perfect!: adaptive at every real
launcher size, scrollable, directly actionable, owner-safe and local-first even when
Flutter is absent. Status cycling, habit logging and Quick Add must use the same
canonical domain commands and durable operation queue as the open app.

The title is not a scope boundary. Widget actions must propagate through app lists,
details, history, reminders, sync, AI context, analytics and upgrade continuity.

## Autonomous decisions

- Keep the widget Android-native with RemoteViews/ListView and the existing
  `home_widget` bridge. Native code projects and journals intents; Dart remains the
  sole Drift/domain writer. The widget never talks directly to Supabase.
- Derive layout from `AppWidgetOptions` min/max width and height in dp, not device
  name or assumed cell count. Support compact, medium, wide/short and expanded/tall
  compositions; every supported size retains a real vertical scroll collection and
  at least one directly actionable row when data exists.
- Task status uses the canonical multi-state cycle: pending → partial/in progress →
  completed → pending, subject to Stage 13 recurrence/recovery rules. Missed, skipped,
  archived, conflicted or no-longer-eligible rows do not guess; they open detail or
  show a recoverable blocked result.
- Habits expose the method-valid direct action: binary toggle, count increment,
  duration/value shortcut or checklist progress. Rapid taps serialize through the
  same Stage 28 operation semantics and never overwrite the latest value.
- Quick Add appears in every size where its label/hit target fits without displacing
  the only row action. It opens a compact native dialog, creates a Task through a
  tokenized background request, and never launches a full-screen fake form.
- Use stable entity IDs, expected revision and UUID idempotency keys in intents.
  Mutable title/status text is display data only and never identifies the write.
- The app-private per-install interaction token, explicit package intents and receiver
  validation are mandatory. No exported component accepts an unauthenticated planner
  mutation, and PendingIntents are immutable except the required collection fill-in.

## Accepted preview and Copy-fidelity gate

No Kotlin, RemoteViews XML, drawable or Dart widget implementation begins until the
Stage 03 visual direction and Stage 04–05 responsive/component harness are extended by
`modernize`, `integrity`, `anatomy` and `style`, internally accepted under the
owner-delegated autonomous design authority, decomposed, and
frozen as the `copy` source of truth. The preview dossier includes the five-way surface
opinion ledger, app↔widget semantic integrity map, launcher action/scroll anatomy,
size-class geometry equations, precision ledger, asset/density manifest and host-
appropriate motion/state storyboard.

Create exact individual previews for mark/header, dual date/summary, section label,
Task row, every Task status, each Habit method action, pending/sync/error cue, body deep
link target, Quick Add trigger, native dialog field/buttons/progress/error, loading,
empty, stale, auth-expired and recovery. Compose complete picker, compact, medium,
wide-short and expanded-tall previews with sparse/dense/long RTL/mixed data, light/
dark/high contrast and 200% font/display size for phone and tablet portrait/landscape.
Show scroll start/end and resize-before/after, not only ideal static content.

Record exact host dp bounds/options, density, row count, crop/safe zone, token math,
touch bounds, semantics, z-order, truncation/wrap policy and state replacement frames.
Classify every layer as native live RemoteViews text/control, vector/raster resource or
hybrid; titles, state, Quick Add and actions remain live. Picker and launcher previews
are binding references, but actual host screenshots—not design comps—prove delivery.

## Size-class composition

| Size class | Required composition | Actions |
|---|---|---|
| Compact (minimum supported) | transparent uncropped mark, Today/remaining summary, scrollable compact rows | task cycle or method-valid habit action; body opens detail |
| Medium | dual date/summary, scrollable prioritized day rows, sync/offline cue | row action and Quick Add when its whole label fits |
| Wide/short | horizontal header/summary plus maximized collection height | row action, Quick Add, open app; no unrelated full-width footer |
| Expanded/tall | full chronological day stream with section labels and more visible rows | task/habit actions, Quick Add and detail deep links |

Empty, loading/rebuilding, locally pending, syncing, stale, auth-expired and error
states each have an actionable native composition; no state becomes a blank widget.

## Work packets

1. **Freeze current native behavior.** Inventory widget provider/service/factory,
   layouts, receiver exports, PendingIntent flags, `perfect_today_widget_info.xml`,
   projector/background Dart code, SharedPreferences keys, update triggers and real
   launcher screenshots. Preserve placed-widget IDs across the rebuild.
2. **Define the projection contract.** Version a bounded widget snapshot containing
   owner/session readiness, local projection revision, generated time/day/timezone,
   ordered sections/rows, stable entity/occurrence IDs, kind, current state/value,
   next legal action, pending/error marker and deep link. Atomic-write then publish;
   the factory never reads a half-written snapshot.
3. **Build actual-size selection.** Recompute layout on add/options change/update,
   rotation, font/display-size change and launcher restore. Use min/max dp plus content
   fit tests and keep collection IDs stable enough for scroll restoration where the
   host allows it.
4. **Compose project-owned visuals.** Use the transparent Perfect! mark and native
   vector/raster resources generated from project masters. Verify day/night colors,
   contrast, optical crop and small-size legibility; no raw keyboard emoji, generic
   robot/sparkle or opaque image background.
5. **Implement row rendering.** Bind semantic title, schedule/value, non-color state
   cue, pending/sync state, body deep link and a separate direct action target. Use
   collection stable IDs and content hashes so updates do not duplicate or reorder
   rows unexpectedly.
6. **Journal actions before work.** Receiver validates widget ID, package token,
   entity/occurrence ID, action enum, expected revision and idempotency UUID, then
   persists an app-private native action journal entry before starting the Dart
   callback. A killed process cannot lose an acknowledged tap.
7. **Route through canonical domain commands.** Dart claims one journal entry,
   initializes owner/session/local DB, runs the Stage 13/14/28 command in a transaction,
   appends the normal sync operation, marks the journal receipt and projects a fresh
   widget snapshot. Duplicate/replayed callbacks return the stored receipt.
8. **Complete multi-state cycling.** Calculate the next legal state in the domain,
   not Kotlin. Show immediate native pending feedback, serialize rapid taps per
   entity/occurrence, handle undo/correction/day rollover explicitly, and refresh from
   the committed row rather than predicted mutable text.
9. **Complete compact Quick Add.** Native dialog has one title field, clear Cancel/
   Add, IME action, progress/error and retry. Add writes a tokenized journal command;
   Dart creates a canonical Inbox Task + sync operation atomically. Keep typed text
   on recoverable failure and prevent double submission.
10. **Coordinate refresh sources.** Refresh after local app mutation, AI apply/undo,
    background journal commit, sync/realtime merge, midnight/timezone change, auth
    recovery, theme/locale change, boot/package replacement and explicit retry.
    Debounce bursts but never suppress a newer projection revision.
11. **Harden cold start and recovery.** When Flutter cannot initialize, retain the
    durable journal and show pending/retry rather than false success. Expired auth
    still permits owner-local writes when the existing local-owner contract allows;
    remote sync waits for session recovery without clearing the widget or database.

## UI/UX and motion contract

- Status is a dedicated target separate from row navigation. Pending → partial →
  completed feedback changes shape/icon/copy as well as color. The row title remains
  stable, avoiding accidental navigation while tapping near a scrolling gesture.
- Widget hosts permit limited animation, so use honest state replacement and a small
  pending indicator instead of pretending to run Flutter motion. Update only after
  the journal is durable; completed styling appears only after the local transaction.
- Quick Add is a native compact dialog visually related to Day Compass, with live text
  and real controls. It does not show decorative placeholder tasks or an AI prompt.
- Keep the mark transparent, optically centered and uncropped at picker, compact and
  expanded sizes. Section labels, dates and actions remain whole; secondary user text
  alone may ellipsize when a second line cannot fit.

## Responsive and device behavior

- Test Android phone and tablet launchers in portrait/landscape, density/display-size
  variants and every drag-resize transition between the declared min/max bounds.
  Recomposition must not require removing/re-adding the widget.
- Compact/short layouts prioritize actionable content over a large brand/header.
  Tall layouts spend height on the scroll collection, not dead space. Wide layouts
  do not stretch phone rows into weak empty bands.
- At 200% font/display size, required action labels either recompose to icon + semantic
  description or move to the next supported layout; hit targets do not shrink and no
  primary phrase is clipped.
- Row-body deep links open the Stage 31 canonical detail after cold start/auth/local
  initialization and restore back navigation. Quick Add returns to the launcher and
  does not leave a stray activity in Recents.

## Domain, security and data contracts

- Widget snapshot key is `(app_widget_id, owner, local_projection_revision)`. Action
  key is `(install_token, action_id)` with entity/occurrence ID, expected revision,
  action enum, created time and bounded payload.
- Kotlin may persist the minimal action envelope but never planner rows, status
  history or Supabase credentials. Dart/domain state machines decide validity and
  create immutable events plus the durable sync operation in one transaction.
- Quick Add accepts bounded plain title text only; it cannot inject arbitrary JSON,
  owner ID, SQL, route or operation kind. All PendingIntent inputs are validated
  again in Dart before the database opens.
- Snapshot/journal storage is app-private, versioned and migration-safe. Widget
  backups/restores do not copy auth/provider secrets and an unknown schema fails to a
  safe “open Perfect!” recovery state.

## Offline, errors and retries

- Offline task/habit/Quick Add commits locally and displays a distinct pending-sync
  cue. Automatic bounded sync retry happens through Stage 44, not the widget host.
- Rapid taps are queued/serialized per entity. Duplicate broadcasts, WorkManager
  retries, process death and launcher rebind are idempotent and cannot skip or double
  a state/value.
- Stale/foreign/deleted/conflicted entity, invalid transition, storage-full, database
  locked, auth revoked and background-timeout states retain the journal receipt and
  show an actionable retry/open-detail response. Never display success from a mere
  PendingIntent dispatch.
- Midnight/timezone change re-evaluates occurrence identity before committing; an
  old widget tap cannot mutate the new day silently.

## Accessibility and performance

- Every row, status/value action, Quick Add and open-app control has distinct
  `contentDescription`, role/state and TalkBack order. Information is not conveyed by
  pastel color alone; targets meet the project Android minimum.
- RTL/mixed titles preserve correct bidi isolation and reading order. Font/display
  scaling, high contrast, dark mode and disabled/pending/error states are tested in
  the launcher and Quick Add dialog, not only Flutter goldens.
- Projection work is bounded and off the Flutter UI-critical path; native collection
  binding never queries Supabase/Drift per row. Record factory bind time, projection
  time, action-journal acknowledgement and local commit latency on sparse/dense data.
- Widget refresh is coalesced per projection revision and avoids wake/retry storms;
  scrolling remains responsive with the maximum projected row count.

## Verification and required evidence

1. Contract tests for size classifier, projection schema/migration, atomic snapshot,
   stable row IDs, token/action validation, idempotency and every state transition.
2. Rapid-action vectors: 20 Task cycles and 20 count increments yield the exact
   serialized local/history/queue result; duplicate broadcasts and process death
   produce no extra change. Include over-target, undo/correction and midnight.
3. Quick Add vectors: empty/long/mixed title, IME Add, Cancel, double submit, offline,
   storage failure, process death/replay and eventual Supabase convergence.
4. Real launcher evidence for picker preview, add, minimum compact, medium, wide-short,
   expanded-tall, scroll start/end, continuous resize, portrait/landscape, phone/tablet,
   dark/high contrast, 200% display/font and TalkBack traversal.
5. Capture before/action-pending/local-committed/sync-pending/synced/error screenshots
   for status cycle, habit action and Quick Add. Record screen video proving a scroll
   gesture near the action does not navigate or double-write.
6. Cold-start/deep-link tests cover app killed, device reboot, package replacement,
   auth refresh, database migration, deleted/foreign entity and duplicate deep link.
7. Run focused Flutter widget/domain/sync tests, Android unit/instrumentation tests,
   `flutter analyze`, full Flutter tests and Stage 05 geometry/a11y checks. Inspect the
   signed APK manifest/resources and perform secret/exported-component scans.
8. Evidence includes device/launcher/API level/density, widget dp bounds/options,
   exact candidate SHA, operation IDs, local DB/queue assertions, redacted remote
   convergence, screenshots and recordings. Emulator-only picker images do not
   replace at least one real-device launcher proof.
9. Before implementation, verify the autonomous acceptance record and complete size/state preview +
   decomposition manifest. After each material pass, normalize accepted preview ↔
   real picker/launcher/Quick Add captures and compare component inventory, pixels,
   geometry, crop, typography, touch semantics, scroll/resize behavior and state timing;
   repair all unresolved deltas and recheck adjacent size classes.

## Reject the stage if

- Any supported size is non-scrollable, read-only when a legal action exists, blank,
  clipped, visually unbalanced or requires remove/re-add after resize/update.
- Native code writes planner state/Supabase directly, or an action bypasses the
  canonical domain validator/operation queue/owner token.
- A dispatched action looks completed before durable local commit, duplicates under
  retry, crosses the day boundary incorrectly or becomes stale after app/AI/sync.
- Quick Add opens a full app flow, loses text on retry, double-creates, or appears
  where its label/target cannot fit safely.
- Picker/runtime mark is opaque/cropped, raw emoji ships, or TalkBack cannot
  distinguish row navigation from status/log action.
- Runtime/native work preceded the accepted preview pack, or any size/security/error/
  loading state uses a placeholder, stretched composition or undocumented substitution.

## Whole-product propagation

Verify widget-created or changed state in Today, Tasks, Plan, Habits, Goals/Projects/
Areas relations, Task/Habit details and histories, search/filter/sort, reminders,
Focus eligibility, AI context/proposals, archive/conflict center, local queue,
Supabase realtime/sync cloud, backup/export/import, diagnostics and auth recovery.
Verify app/manual/AI mutations refresh the widget exactly once. Preserve widget IDs,
snapshot/journal data and deep-link protocol through N→N+1.

## Handoff and release

Stage 49 receives the full real-launcher matrix, action receipts, security scan,
performance trace and cross-surface convergence evidence. Runtime/native changes must
be committed and pushed to `main`, pass CI, increment version monotonically and ship
through the signed APK/Windows release contract even though Windows has no widget.
Install Android N→N+1 over a placed widget and prove widget/action/data continuity;
record any launcher-specific limitation honestly and leave only clean `main`.
