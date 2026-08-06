# Critics ledger — Tasks, Habits, editor and Focus hand-off

- Frozen: 2026-08-05T23:11:44+03:30
- Audit mode: read-only until this ledger was frozen
- Runtime target: Android phone live preview; tablet/Windows backed by widget tests and existing goldens
- Reference: the user-approved Perfect! Day Compass mobile composition
- Scope: Today continuity, Tasks, Habits, multi-step Task/Habit editor and the path into Focus Studio

## Evidence boundary

- The Android preview ran on `emulator-5556` at `1080×2400`, API 35. Runtime captures and semantics dumps are under the ignored `.codex-tmp/critics-cycle1/` evidence directory.
- The approved visual reference remains `C:/Users/K1/AppData/Local/Temp/codex-clipboard-881b0bea-3f21-439d-a487-ee4e45210ee2.png`.
- Existing responsive goldens cover compact, tablet and Windows compositions. A fresh local Windows runtime could not be built because this host has no Visual Studio C++ desktop toolchain; hosted release build evidence remains separate from visual runtime proof.
- `flutter test` across the four focused suites passed 61/61. Passing tests prove the encoded contracts, not that the current product hierarchy, density or data presentation is good.

## Frozen ranked findings

| ID | Severity | Finding | Root evidence | Why it matters | Required acceptance proof |
|---|---|---|---|---|---|
| C1 | P1 | A measured Habit with no log loses its configured target and renders `0 … of 1` even when the target is 8. | `PlannerHabitDaySummary.pending` hardcodes `target: 1`; `PlannerHabitDayEngine.evaluate` returns it before reading tracking target. | This is incorrect user data, not cosmetic copy. It also produces broken singular/plural copy such as `1 glasses`. | Domain tests for pending count/duration/checklist targets plus Android screenshot showing the configured target and natural unit copy. |
| C2 | P1 | Tasks opens on Inbox, so a user with only scheduled active tasks sees an empty page even though work exists. | `_TasksPageState._filter` defaults to `_TaskFilter.inbox`; Inbox explicitly excludes every scheduled task. The preview had three active tasks but rendered zero until Active was selected. | The primary collection misrepresents the owner’s data and adds an unnecessary recovery step. | A smart default that never hides all active work without an explicit filter; focused tests for scheduled-only, mixed and truly empty datasets. |
| C3 | P1 | The compact Home capture/AI control can visually occlude the last task row. | Side-by-side Android runtime inspection showed the floating control occupying the third row’s reading/action area. | A visible task becomes hard to read or act on, violating the no-overlap and reachability contract. | Sparse and dense Android screenshots plus a bounds/scroll test proving every final row clears the collapsed and expanded dock. |
| C4 | P2 | The compact Tasks filter deck spends roughly half the first viewport on search, two chip groups and a redundant result line. | `_TaskFilterDeck` always expands Search + TYPE + STATUS + summary on compact layouts. | Scanning and quick action become slower than the work itself. | Compact summary bar by default, progressive filter expansion, retained filter/search state, and phone/tablet/desktop screenshot comparison. |
| C5 | P2 | Selected filter/category/icon/color choices display redundant checkmarks even though the selected color already communicates state. | Material `ChoiceChip` defaults are used without suppressing the selected mark. | It conflicts with the explicit interaction language and adds visual noise. | All selection surfaces use one consistent color/shape treatment without a second check glyph; semantics still announce selection. |
| C6 | P2 | The Habits page is a large status card plus large habit cards, but has no actual streak, recovery history or gamified momentum. | No streak/achievement surface exists in the current presentation/domain search; the week strip previews eligibility rather than recorded history. | It does not answer “am I building consistency?” and misses the already-approved gamification contract. | Honest streak engine based on eligible days/rest/recovery, compact history strip, personal-best/momentum feedback and correction-safe tests. |
| C7 | P2 | Category creation is materially below the requested depth. | Six built-in category names, nine icons and five colors are hardcoded; suggestions are capped at 12. | Reuse, visual recognition and custom planning contexts run out quickly. | At least 30 curated category recipes, searchable SVG/pictogram archive, custom category name/icon/color, edit/archive path and responsive picker tests. |
| C8 | P2 | The Habit wizard begins with generic entity types even when launched from Habits; mobile exposes Quick save on incomplete steps and even advertises `Ctrl+Enter`. | Shared type step and unconditional compact quick-save action in `planner_editor.dart`. | It wastes decisions, offers invalid-looking escape paths and leaks desktop language into Android. | Context-aware wizard entry, Quick Capture kept separate, save only when minimum data is valid, and desktop shortcuts represented only on desktop. |
| C9 | P2 | New-title fields autofocus before the owner taps, and task creation shows a `Current outcome` field intended for items already in motion. | Title uses `autofocus: widget.existing == null && _title.text.isEmpty`; outcome section is present in create flow. | Keyboard/focus appears against the interaction contract and creation asks a nonsensical question. | No creation field autofocus; tap-out dismisses IME; outcome only appears for editing or an explicit progress step. |
| C10 | P2 | Review omits important decisions and uses implementation jargon. | Review summarizes basic type/title/repeat state while omitting category, timing, reminders and recovery; copy includes “typed fields” and “declarative formulas”. | The owner cannot confidently verify what will be created. | Human summary of identity, schedule, tracking, reminders, recovery, focus and organization with edit-jump actions. |
| C11 | P3 | Orbit ring joints and curved labels remain visually less finished than the approved reference. | Android side-by-side inspection shows abrupt color-band joins and edge-proximate curved copy. | The Orbit is the signature instrument; simple geometry reads as unfinished branding. | Smooth authored joints, safe optical inset, arc-aligned labels, centered symmetry and side-by-side screenshot gate. |
| C12 | P3 / environment | Fresh local Windows visual runtime is unavailable on this host. | `flutter build windows --debug -t lib/dev/perfect_live_preview.dart` reports no suitable Visual Studio toolchain. | Desktop layout changes still need real hover, focus, animation and resize observation. | Hosted build plus a Windows runtime capture on a provisioned host; never substitute goldens for live interaction proof. |

## Challenge pass

- C1 is not dismissed as an empty-state shortcut: the owner explicitly configured a measurable target, so the pending projection must preserve it.
- C2 is not solved by changing preview seed data: the default filter contract itself hides valid active tasks.
- C3 is not disproved by the existing “final task scrolls above dock” test: the runtime screenshot demonstrates an optical/interaction collision in the actual compact composition, so both geometry and screenshot evidence are required.
- C6 is not satisfied by a seven-day schedule strip. Eligibility is not completion history and cannot honestly produce a streak.
- C7 must not become a flat wall of 30 chips. The requirement is breadth plus fast search, recently used items and custom creation.
- C11 must not be “fixed” with more arbitrary gradients. It needs deliberate ring geometry, joins, label paths and optical comparison.

## Perfect repair order

1. Correct daily Habit projection and unit copy; add the missing regression tests.
2. Recompose Tasks around a truthful smart default and a collapsed filter summary.
3. Close Home dock/task continuity and rerun the approved-reference comparison.
4. Rebuild the wizard entry, selection language, focus/keyboard behavior and review step.
5. Build the category recipe/icon archive and custom category path.
6. Add streak/history/momentum on top of a correction-safe Habit event model.
7. Rebuild Focus as Focus Studio: Focus Contract, model presets, outcome, Distraction Inbox, Flip-to-Focus experiment and graduated Shield.
8. Run compact/tablet/Windows, RTL, 200% text, sparse/dense, motion and upgrade/release gates.

## Focus Studio decision carried forward

The existing Pomodoro, Countdown, Stopwatch, session recovery and task linkage remain foundations. The new system adds Just Start, Sprint, Deep, Flow, Study + Recall, Admin Batch and explainable Smart modes; Flip-to-Focus is an explicit foreground Android experiment; DND/usage awareness/app blocking are separate owner-controlled shield levels; true kiosk-style hard lock is not a default. Every session records `done`, `progressed`, `blocked` or `distracted`; elapsed time never silently completes a task.

## Closure log

### C1 — closed in Perfect Cycle 1

- `PlannerHabitDaySummary.pending` now accepts and preserves measured targets and checklist thresholds.
- Empty count/duration summaries read the configured target before returning; empty checklist summaries evaluate the configured required/total counts.
- Measured status copy renders one natural unit phrase: `Pending · 0 of 8 glasses · 0%`.
- Regression coverage includes pending measured and pending checklist domain cases plus a compact Android workspace assertion.
- Runtime evidence: `.codex-tmp/critics-cycle1/android-habits-cycle1-fixed.png` and `perfect-cycle1-habits.xml`; the preview cold-started in 2685 ms with no `FATAL EXCEPTION` or `E/flutter` match.
- Gates: `flutter analyze` passed; full `flutter test` passed 355/355.
- Release proof: exact-SHA run #36 succeeded and immutable `v1.1.0-build.2036` contains exactly the three install-ready assets.

### C2 and C4 — closed in Perfect Cycle 2

- Tasks now defaults to `Open`, so active scheduled and unscheduled work is visible without recovery through a filter.
- Compact layouts show one search field and one `Open · All` summary; TYPE/STATUS are disclosed only on request with reduced-motion-aware Fade + Size transition.
- Wide layouts retain inline controls. Returning to compact collapses auto-disclosed wide controls unless the owner explicitly expanded them.
- Search text and filter state survive reflow. Tapping outside Search or opening filters dismisses the IME before revealing the list.
- Empty states are specific to Inbox/Open/Scheduled/Completed and no longer direct the owner to Home-only Quick Capture.
- Evidence: 356/356 full tests, analyzer clean, `.codex-tmp/critics-cycle1/android-tasks-cycle2-collapsed.png` and `android-tasks-cycle2-expanded-final.png`.

### C5 — partially closed in Perfect Cycle 2

- Task Type/Status chips use selected color and shape with `showCheckmark=false`; the Single icon is now a numeral rather than a check-like glyph.
- Semantics still announces the selected state.
- Category, icon and color pickers remain open under C5 and will be closed with the editor/category cycle.

### C3 and compact shell continuity — closed locally in Perfect Cycle 3

- The compact footer is now icon-only. Material's stock stadium is transparent and one destination-specific prismatic tile carries selection through color, surface, elevation and motion; there is no duplicated selected checkmark or visible menu label.
- Quick Capture keeps a standalone circular launcher above the footer. Opening it never requests focus or summons the IME; the owner explicitly taps the field, Plan, Perfect AI or Voice.
- The expanded composer has one visual hierarchy and three equal action targets. Dedicated text-free `ai.svg` and `voice.svg` replace ambiguous generic marks.
- The composer transition retains only the current surface. `AnimatedSize` plus one-child fade/rise/scale preserves motion without the outgoing composited glass subtree that destabilized software rendering.
- The final Today row clears both collapsed and expanded surfaces in a 320×700 scroll test. Android API 35 screenshots show the live collapsed and expanded compositions, and four open/close cycles leave ADB/QEMU responsive on the supported `host` renderer.
- Gates: Workspace 55/55، AI Dock 21/21، pictogram/emoji 3/3، analyzer clean and full suite 358/358. Hosted release proof is still pending at this checkpoint.

### C11 — clock placement improved; full graphic-fidelity finding remains open

- Orbit artwork and live painter now share a 95% geometry scale, reserving a real outer gutter rather than pushing side clocks against canvas bounds.
- 6 AM and 6 PM use the same explicit radial anchor; noon/midnight keep a matched inner anchor. Compact, tablet and Windows goldens plus the Android screenshot show symmetric placement.
- This closes the reported clock-placement defect. C11 remains open for a later side-by-side gate on authored band joints, full curved-label fidelity and final Photoshop-grade surface treatment.

### Adjacent percentage-ring defect — closed in Perfect Cycle 3

- Agenda percentages render inside a 43dp opaque safe core, separated from a 4.5dp ring; horizontal padding increased to 7dp after the first 200% test proved exact boundary contact.
- A dedicated regression asserts every percentage glyph rectangle starts and ends inside the deflated core at 200% text. The live Android `60%` and `0%` states retain visible breathing room.
