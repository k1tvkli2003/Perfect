# Stage 02 — Complete interaction and route inventory

Status: pending  
Depends on: Stage 01  
Blocks: navigation, Today, details, editor, AI and widget routing

## Mission

Build a source-backed map of how a person enters, moves through and mutates
Perfect!. Find accidental direct-to-edit routes, duplicate affordances, dead
ends, state loss and excessive tap cost before redesigning individual screens.

## Product decision

Perfect! uses a view-first hierarchy: list/timeline tap opens detail; explicit
controls mutate status/logs; Edit is entered from detail or an unmistakable edit
action. Create flows and Quick Capture are the only intentional direct-to-editor
entrypoints.

## Work packets

1. Enumerate all Flutter routes, modal routes, sheets, dialogs, overlays, context
   menus and adaptive inspector states.
2. Enumerate Android widget pending intents, notification actions, protocol/deep
   links and Windows keyboard shortcuts.
3. For each entrypoint record trigger, preconditions, destination, mutation,
   confirmation, success feedback, error behavior and state restored on return.
4. Trace every Task/Habit row `onTap`, leading/trailing control, long press,
   secondary click and keyboard activation in Today/Tasks/Plan/Habits.
5. Trace create/edit/duplicate/archive/restore/delete/focus/log/progress flows to
   controller, local transaction, operation queue, Supabase and UI refresh.
6. Count taps/keystrokes for ten core jobs: quick task, scheduled task, recurring
   task, habit, +1 habit, correct habit, complete task, view stats, edit, ask AI.
7. Identify controls whose icon/copy implies a different result from behavior.
8. Identify route transitions that drop draft, selection, focus, scroll, calendar
   month, filter or navigation-rail state.
9. Define one canonical route/action owner per job and a migration table from old
   behavior to new behavior.
10. Add characterization tests before changing ambiguous existing behavior.

## Required diagrams

- Entity lifecycle state chart.
- Navigation/deep-link route tree by form factor.
- Local-first mutation sequence: gesture→controller→transaction→queue→sync→UI.
- AI proposal sequence and Android widget action sequence.

## Edge scenarios

- Entity archived/deleted remotely while its detail route is open.
- Notification or widget opens an entity before auth/local store initialization.
- Double tap/Enter submits twice; back pressed during save; resize during modal.
- Detail opened on phone then window class changes to tablet/desktop.
- Row is visible but its only action is clipped at 200% text.

## Acceptance evidence

- Inventory covers every callback and native entrypoint found by source search.
- Ten core jobs have current and target interaction-cost tables.
- Tests freeze any behavior that must survive later visual replacement.
- No unresolved “tap probably edits/views” ambiguity remains.

## Reject the stage if

- The map is based only on screenshots without controller/backend traces.
- A desktop inspector and mobile page represent conflicting actions or data.
- Deep links/widgets remain a separate unowned behavior path.

## Completion handoff

Stage 03 receives the friction list, route contract and top opportunity ranking.
Update project state/progress, commit the map/tests, push and keep Git clean.

