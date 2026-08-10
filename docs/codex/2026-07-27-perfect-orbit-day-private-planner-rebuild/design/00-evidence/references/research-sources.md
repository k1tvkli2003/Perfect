# Stage 03 research sources and extracted product rules

Status: evidence baseline, 2026-08-09
Scope: Perfect! private Flutter planner for Android and Windows
Authority: primary product/platform sources first; visual galleries are decomposition-only

## Evidence discipline

- A source earns a rule only when it changes interaction cost, information scent,
  state continuity, accessibility or platform fit.
- Competitor identity, decoration and copy are never copied. The reusable unit is a
  decision pattern, not a screenshot.
- The user-provided HabitNow screenshots are the authoritative evidence for its
  current creation flow. Google Play confirms the public feature envelope but does
  not expose a reliable current version number in the fetched page; this document
  therefore does not invent one.
- Dribbble is used to find composition and graphic-craft patterns. It is never a
  fidelity target and cannot overrule operational evidence.

## HabitNow

Sources:

- [HabitNow on Google Play](https://play.google.com/store/apps/details?gl=US&id=com.habitnow)
- 25 owner-provided screenshots from `C:/Users/K1/Downloads/HabitNow`, captured
  2026-07-27, copied byte-for-byte into `habitnow-2026/manifest.md`, and behaviorally
  decomposed in `../decomposition/habitnow-2026-flow.md`.

Observed product envelope:

- habit, recurring-task and one-off-task types;
- daily/weekly/monthly/yearly/custom recurrence and repeat intervals;
- boolean, numeric, timer and checklist evaluation;
- categories, lists, reminders/alarms, streaks, calendar, notes, charts, themes,
  widgets, lock-screen affordances and backup/export;
- recent public notes mention events/templates/challenges/announcements plus UI and
  performance improvements.

Rules accepted for Perfect!:

1. Ask decisions in dependency order: entity kind -> meaning/identity -> tracking
   model -> schedule -> recovery/reminders -> review.
2. Hide irrelevant branches immediately. A boolean habit must not expose unit or
   timer fields; a fixed task must not expose habit evaluation.
3. Offer every recurrence family, but keep a continuously updated plain-language
   summary visible so complex rules remain understandable.
4. Keep `Flexible` and carry behavior explicit. They alter historical meaning and
   cannot be buried in a generic advanced section.
5. Preserve the fast direct-log ergonomics from Today/widget while replacing
   HabitNow's visually dense forms with named steps, draft persistence and review.

Rules rejected:

- full-screen black forms with weak hierarchy and oversized empty regions;
- tiny step dots without semantic step names;
- radio rows that expose multiple large configuration blocks simultaneously;
- separate legacy visual languages for task editor, recurring wizard and habit
  wizard;
- entering edit when the owner merely wants to view history/details.

## TickTick

Source: [TickTick feature overview](https://ticktick.com/features?language=en_US)

Useful evidence:

- widget quick add, desktop shortcut, natural-language and voice capture reduce
  capture latency;
- list/filter/tag and calendar views let the same work be seen through different
  planning lenses;
- yearly/monthly/weekly/agenda/multi-day calendars, Kanban/timeline, habit tracker,
  Pomodoro, Eisenhower, countdown, statistics, timezone and themes form a broad but
  connected toolset;
- desktop uses denser multi-pane compositions instead of stretching a phone list.

Perfect! rule: capture is one morphing instrument, while planning and inspection
may reveal more structure at larger widths without changing entity meaning.

## Todoist

Source: [Todoist guidance on start dates](https://www.todoist.com/help/articles/does-todoist-support-start-dates-qhqlgZhk)

Useful evidence: start date, due date, deadline and visibility are different
concepts. Todoist intentionally avoids hiding tasks behind a start date and instead
uses recurring dates, deadlines, filters, reminders and calendar views.

Perfect! rule: model availability/visibility, planned start, due boundary and hard
deadline separately. Never overload one `date` field or make scheduled work vanish
without a discoverable filter.

## Structured

Source: [Structured product overview](https://structured.app/)

Useful evidence: one visual timeline can combine tasks, deadlines and habits while
focus and widgets remain downstream views of the same plan.

Perfect! rule: Today needs one operational day stream with clear time zones and
direct logging. It does not need a second decorative summary of the same tasks.

## Sunsama

Sources:

- [Guided daily planning](https://help.sunsama.com/docs/usage-guides/daily-planning/)
- [Workspace navigation and focus](https://help.sunsama.com/docs/usage-guides/workspace-navigation/)

Useful evidence:

- a daily ritual can reflect on yesterday, collect work, estimate workload and then
  commit a feasible day;
- focus mode gives one task the whole interaction surface;
- daily/weekly rituals and keyboard shortcuts make planning repeatable.

Perfect! rule: add an optional compact daily/weekly review loop and workload reality
check, but never gate ordinary Today access behind a ritual.

## Akiflow

Source: [Akiflow command bar](https://product.akiflow.com/help/articles/6483573-command-bar)

Useful evidence: a command surface can capture directly to Inbox and progressively
enrich the item without opening a heavy editor.

Perfect! rule: Quick Capture saves a valid local entity with title alone, shows a
reversible receipt, and offers optional Plan/AI/Voice enrichment in the same shell.

## Amazing Marvin

Sources:

- [Habit tracking methods](https://help.amazingmarvin.com/en/articles/4835241-habits)
- [Modular strategy catalog](https://playground.amazingmarvin.com/features/)

Useful evidence:

- habits can target `more` or `less`, numeric values or time, and goals per week;
- past/future logging, start/defer/end dates, timers, goals, time blocking, saved
  smart lists, focus and weekly review support unusual personal workflows;
- modular strategies demonstrate the value of optional capability without forcing
  every feature into the default surface.

Perfect! rule: entity-level customization can be deep while the default interaction
stays calm. Advanced modules are capability layers with coherent summaries, not a
permanent wall of controls.

## Android adaptive and widget conventions

Primary sources:

- [Use window size classes](https://developer.android.com/develop/adaptive-apps/guides/use-window-size-classes?hl=en)
- [Canonical adaptive layouts](https://developer.android.com/develop/adaptive-apps/guides/canonical-layouts)
- [Adapt layouts](https://developer.android.com/design/ui/mobile/guides/layout-and-content/adapt-layout?hl=en)
- [App widget layouts](https://developer.android.com/develop/ui/views/appwidgets/layouts)
- [App widget overview](https://developer.android.com/develop/ui/views/appwidgets/overview?hl=en)

Rules accepted:

1. Classify the current window, not a remembered device label. Width and height can
   change during split-screen, rotation or freeform resize.
2. Reflow, reveal and change presentation deliberately. Do not scale one phone
   canvas until it happens to fit.
3. Preserve selection, draft, scroll and focus when crossing a breakpoint.
4. Tablet uses a compact rail by default and may reveal list-detail or supporting
   panes when the current width and content justify them.
5. Widget layouts are authored for size families, remain scrollable, and keep direct
   status/log actions plus compact Quick Add where space permits.

## Windows navigation and motion conventions

Primary sources:

- [NavigationView](https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/navigationview)
- [Connected animation](https://learn.microsoft.com/en-us/windows/apps/develop/motion/connected-animation)
- [XAML animation guidance](https://learn.microsoft.com/en-us/windows/apps/develop/motion/xaml-animation)

Rules accepted:

1. Windows rail supports compact and expanded modes, remembers owner preference and
   can move to minimal presentation at constrained widths.
2. Hover, focus, context actions, shortcuts and resizable list-detail are primary
   behavior, not desktop polish added after touch UI.
3. Page changes use restrained entrance/crossfade/reposition or connected continuity
   tied to hierarchy; arbitrary slide directions are forbidden.
4. High contrast and reduced motion replace blur/springs with legible native-safe
   states rather than merely disabling opacity.

## Dribbble visual decomposition

Examples inspected:

- [Habit Tracker App UI](https://dribbble.com/shots/26350404-Habit-Tracker-App-UI)
- [Habit Tracker Mobile App UI](https://dribbble.com/shots/27375980-Habit-Tracker-Mobile-App-UI-Design-Productivity-Wellness-App)
- [Daily Planner App](https://dribbble.com/shots/26041105-Daily-Planner-App)
- [AI Assistant Mobile App](https://dribbble.com/shots/26433163-AI-Assistant-Mobile-App)
- [AI Productivity Assistant](https://dribbble.com/shots/27438546-AI-Productivity-Assistant-Mobile-App)
- [Habit tracker search](https://dribbble.com/search/Habit-tracker)

Extracted craft rules:

- a warm vertical rhythm, strong focal moment and intentional negative space can
  make dense planning feel calm;
- illustration, rings, textures and glass must be authored assets/material systems,
  not stock gradients around generic cards;
- a visually impressive hero cannot consume the interaction budget or duplicate the
  same day data below it;
- AI needs clear starter paths, context visibility and reviewable proposals, not a
  detached chatbot dashboard.

Rejected gallery habits:

- poster-only screens with no empty/error/dense state;
- generic card grids and metric chips posing as information architecture;
- huge greetings, ornamental charts, low-contrast glass and rainbow gradients;
- layouts that work only at one phone aspect ratio.

## Consolidated design consequences

- The old Orbit is removed. Its essential orientation value becomes a compact Today
  Pulse plus a continuous, actionable day stream.
- The strongest competitor pattern is progressive decision order; the strongest
  Perfect! differentiator is a tactile one-owner instrument with local immediacy,
  semantic pastel material and cross-device continuity.
- Every finalist must prove phone one-handed use, tablet list-detail, Windows
  keyboard/mouse density, empty/dense/error, dark/high-contrast, 200% text and
  reduced motion before it can win.
