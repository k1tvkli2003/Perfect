# Perfect! stage execution library

This directory turns the 50-stage master roadmap into 50 independently
executable work orders. The master document defines ordering; each file here is
the authoritative implementation, critique, verification and release brief for
one stage.

The mandatory [whole-product coverage and propagation ledger](coverage-ledger.md)
binds every stage to all affected app consumers. A stage cannot be accepted by
polishing only the surface named in its title.

Stages 03–05 are additionally governed by the mandatory
[preview-before-production gate](preview-production-gate.md): every reusable
component is previewed in isolation, every page is composed from that library, and
all later runtime work is accepted through normalized Copy side-by-side comparison.

## Operating rule

- Execute stages in numeric order unless a safety fix must pre-empt the queue.
- Do not ask the owner to make ordinary product/design choices. Explore, compare
  and choose the strongest solution using evidence and the Perfect! invariants.
- “Revolutionary” means a materially better workflow and a distinctive coherent
  composition. It does not authorize novelty that obscures meaning, increases
  taps, weakens accessibility, risks data or copies a reference superficially.
- A stage can be rejected even when tests pass. Visual balance, interaction
  effort, state continuity and real-device behavior are hard gates.
- Before implementation, classify every row of the shared coverage ledger as
  `changed + proved`, `checked unchanged`, `not applicable with reason`, or
  `blocked`. Silence is never evidence that a consumer is unaffected.
- No production UI implementation may begin before the Stage 04 component registry
  and Stage 05 page registry are internally accepted, versioned and frozen.
- Runtime stages end with commit, push, successful CI/release, install-ready
  artifacts and a clean `main`-only branch state.

## Whole-product coverage ledger

The stage title identifies its primary ownership, not a boundary that permits
adjacent regressions. Every stage must trace its change through all consumers.
The 50 files collectively cover, and Stage 49 re-audits, every item below:

- boot, splash, sign-in, session restore, upgrade and auth-expired recovery;
- header, footer, navigation rail, routes, shortcuts and responsive resizing;
- Today, Tasks, Plan, Habits, Goals, Projects, Areas, Notes, Focus and More;
- Quick Capture, full wizards, detail/history, search/filter/sort and bulk actions;
- category/icon/color library, reminders, notifications, archive and conflicts;
- settings/profile, theme, widget settings, feedback/log/screenshot capture,
  diagnostics, backup, export, import and data recovery;
- local database, operation queue, Supabase RLS/realtime/functions and sync states;
- AI text/voice/proposals/audit, Android widget/deep links and Windows protocol;
- light/dark/high contrast, RTL/mixed copy, 200% text, reduced motion and a11y;
- loading/empty/dense/optimistic/offline/retry/error/conflict/destructive states;
- performance, secret/privacy review, signing, packaging, releases and upgrade proof.

No component is accepted in isolation: a status, schema or interaction change
must be verified in every list, detail, editor, widget, AI action and sync path
that consumes it.

## Files

1. [01 — Preservation contract](01-preservation-contract.md)
2. [02 — Interaction and route inventory](02-interaction-route-inventory.md)
3. [03 — Design evidence and creative direction](03-design-evidence-direction.md)
4. [04 — Responsive design system and component preview library](04-responsive-design-system.md)
5. [05 — Full-product page previews, Copy contract and quality harness](05-quality-harness.md)
6. [06 — Brand and installed identity](06-brand-installed-identity.md)
7. [07 — Adaptive navigation shell](07-adaptive-navigation-shell.md)
8. [08 — Glass header, sync and dual date](08-glass-header-sync-date.md)
9. [09 — Global motion system](09-global-motion-system.md)
10. [10 — Theme and contrast system](10-theme-contrast-system.md)
11. [11 — Today Pulse, Orbit removal](11-today-pulse.md)
12. [12 — Today information architecture](12-today-information-architecture.md)
13. [13 — Task row and status control](13-task-row-status-control.md)
14. [14 — Inline habit logging](14-inline-habit-logging.md)
15. [15 — Today system states](15-today-system-states.md)
16. [16 — Floating Quick Capture](16-floating-quick-capture.md)
17. [17 — Task capture flow](17-task-capture-flow.md)
18. [18 — Inline Plan morph](18-inline-plan-morph.md)
19. [19 — Embedded AI and Voice](19-embedded-ai-voice.md)
20. [20 — Composer performance](20-composer-performance.md)
21. [21 — Wizard shell](21-wizard-shell.md)
22. [22 — Task identity and organization](22-task-identity-organization.md)
23. [23 — Task definition and timing](23-task-definition-timing.md)
24. [24 — Recurrence and recovery](24-recurrence-recovery.md)
25. [25 — Safe edit path](25-safe-edit-path.md)
26. [26 — Habit creation flow](26-habit-creation-flow.md)
27. [27 — Habit tracking methods](27-habit-tracking-methods.md)
28. [28 — Multiple-per-day habits](28-multiple-per-day-habits.md)
29. [29 — Habit recovery and streaks](29-habit-recovery-streaks.md)
30. [30 — Habit logging polish](30-habit-logging-polish.md)
31. [31 — Shared detail route](31-shared-detail-route.md)
32. [32 — Task detail and history](32-task-detail-history.md)
33. [33 — Habit detail and analytics](33-habit-detail-analytics.md)
34. [34 — Detail lifecycle actions](34-detail-lifecycle-actions.md)
35. [35 — Desktop inspector and deep links](35-desktop-inspector-deep-links.md)
36. [36 — Tasks workspace](36-tasks-workspace.md)
37. [37 — Plan workspace](37-plan-workspace.md)
38. [38 — Habits workspace](38-habits-workspace.md)
39. [39 — Goals, projects and horizons](39-goals-projects-horizons.md)
40. [40 — Focus and gamification](40-focus-gamification.md)
41. [41 — Agent-friendly schema](41-agent-friendly-schema.md)
42. [42 — Local-first operations and conflicts](42-local-first-operations-conflicts.md)
43. [43 — Private auth and session](43-private-auth-session.md)
44. [44 — Sync runtime](44-sync-runtime.md)
45. [45 — Owner settings, diagnostics and recovery](45-owner-settings-diagnostics-recovery.md)
46. [46 — Secure AI contract](46-secure-ai-contract.md)
47. [47 — Reviewable AI planner writes](47-reviewable-ai-writes.md)
48. [48 — Android widget](48-android-widget.md)
49. [49 — Adversarial whole-product gate](49-adversarial-whole-product-gate.md)
50. [50 — Final release and upgrade proof](50-final-release-upgrade-proof.md)
