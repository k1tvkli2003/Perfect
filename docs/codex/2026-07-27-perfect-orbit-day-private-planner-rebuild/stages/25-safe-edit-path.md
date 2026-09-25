# Stage 25 — View-first, type-stable and draft-safe editing

Status: in progress — invalid-timing draft retention and create/edit wizard
suites are GREEN; all-kinds Type-step absence, discard guard, stable ID/history,
return-route and footer/widget parity matrices remain open
Depends on: Stages 21–24; anticipates Stage 31 detail route  
Primary surfaces: Edit Task/Recurring/Habit/Project/Area/Goal

## Mission

Make editing feel purposeful instead of replaying creation. Remove the immutable
Type question, enter at the first useful mutable stage and guarantee stable identity,
history, draft and return context.

## Mandatory preview and Copy entry gate

- Bind implementation to `pg-edit-task`, `pg-edit-recurring-task`, `pg-edit-habit`,
  `pg-editor-validation`, `pg-editor-discard-draft`, `wiz-footer` and the shared
  wizard chrome—explicitly excluding `wiz-type-choice`.
- Preview clean/dirty, validation jump, semantic no-change, concurrent revision,
  save/failure, discard guard, IME, short-height and detail/list return compositions.
- Compare every edit kind to its frozen page and verify the live step count/footer/
  header contains no disabled or hidden Type remnants and no blank action strip.
- Copy acceptance includes stable ID/revision/history, draft/focus/scroll preservation
  and exact origin restoration; a pretty editor that recreates data is a P0 failure.

## Fixed route/step decisions

- Normal entity row tap opens detail. Edit is an explicit action from detail/context.
- Edit wizard never includes a Type step because kind cannot change after creation.
- Header states `Edit <kind>` as context; step count is recalculated without Type.
- Default first step is Definition or the most relevant contextual step requested
  by an explicit deep action (e.g. Edit schedule), never a disabled type selector.

## Footer and shell corrections

- Remove the current empty quick-save row above Continue.
- On compact width: Back/optional quick-save/Continue share a balanced row; at high
  text scale, secondary actions move contextually and primary remains full-width.
- Save label distinguishes local save from sync without noisy copy.

## Draft safety

1. Snapshot original canonical values and compute dirty state by semantic equality.
2. Back/close with no changes exits immediately; dirty state offers Continue editing,
   Discard or Save when valid.
3. Background/resume/resize/theme change preserves controllers, step, disclosures,
   focus and scroll.
4. Validation failure navigates/focuses exact offending field without clearing data.
5. Save updates same stable ID/revision and returns to current detail/list context.
6. Concurrent remote revision invokes explicit merge/conflict behavior.

## History and relation safety

- Kind, owner and stable ID are immutable.
- Recurrence edits preserve past occurrences; project/category rename uses stable IDs.
- Checklist/custom property edits preserve item/property identity where history links.
- Notification schedules and widget payload update after local transaction.

## Edge scenarios

Entity archived/deleted remotely while editing; auth expires; app killed with draft;
duplicate save; no actual semantic change; invalid timing; recurrence scope; 200% text;
keyboard Escape/Alt+Left and system back.

## Verification

Type-step absence and step-count tests for every edit kind; footer geometry; dirty
guard; draft restoration; stable ID/history; conflict path; route return scroll/focus;
phone/tablet/Windows screenshots and real IME/back behavior.

## Reject if

- Edit still asks “What are you shaping?” or renders disabled Type cards.
- Footer contains an empty bar/row or Save creates a new entity.
- Closing/resize loses a valid draft without explicit decision.

## Handoff

Stage 26 reuses the corrected edit shell for habits. Commit/push/release with edit
history/route evidence and clean Git.

### Evidence — 2026-09-25 (real runs, Stage 25 partial)

`flutter test --no-pub test/presentation/planner_editor_test.dart`:
**EXIT:0, 17 pass**. Includes validation focus and draft retention through
invalid time blocks, and create/edit wizard continuity. Stage 25's all-kinds
Type-step absence, dirty discard guard, stable-ID/history and return-route
matrix remain open; these tests alone do not close the stage.
