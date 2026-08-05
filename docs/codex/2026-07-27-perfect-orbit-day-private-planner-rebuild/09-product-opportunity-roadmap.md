# Perfect! product opportunity roadmap

- Mode: `$ideas`
- Date: 2026-08-05
- Audience: single private owner
- Status: decision-ready product direction; implementation follows the active UI quality gate

## Opportunity frame

Perfect already has a strong execution substrate: local-first Task/Habit records,
daily occurrences, recurrence, four-state task progress, measured habits, recovery,
focus sessions, owner-scoped sync and reviewable AI proposals. The missing job is
not another to-do surface. It is helping the owner keep a visible line from
longer-term intent to this week's commitments, today's choices, and the next
course correction.

The product outcome is therefore:

> Turn personal direction into a realistic rhythm, then turn recorded activity
> into a useful next decision without guilt, vanity metrics, or autonomous AI
> writes.

Hard constraints:

- Android and Windows only, local-first and owner-only.
- Missing check-ins are unknown, not silently counted as failure.
- AI reads owner-authorized context and proposes changes for review; it never
  silently mutates the plan.
- New planning layers must reduce daily cognitive load rather than create a
  second system beside Tasks, Habits, Projects and Areas.
- Social feeds, teams, public accountability, subscriptions and generic growth
  mechanics remain out of scope.

## Evidence map

| Observed product fact | Opportunity implied |
|---|---|
| `PlannerEntityKind` has Task, Habit, Project and Area, but no measurable outcome contract. | Add a Goal/Horizon concept instead of pretending a Project is already a goal. |
| Tasks and Habits already support relations to Project/Area. | Reuse the relation graph to connect Goals to milestones, routines and daily work. |
| Plan currently projects one selected day and a seven-day strip. | Add genuine Week and Month planning modes rather than stretching the day view. |
| Insights currently shows aggregate counts for 7/28/90 days. | Build an action-oriented Review engine with period comparisons and next decisions. |
| Avoid habits record `avoided` or `slipped`. | Expand into abstinence, reduction, taper and replacement journeys with recovery context. |
| AI already has owner context, Persian-first responses, versioned prompts and reviewable bundles. | Add a persistent coach profile and planning rituals without weakening the confirmation boundary. |
| Estimate, energy, focus time, schedule and carry data already exist. | Build capacity and overload guidance from existing signals before adding prediction. |

## Highest-conviction direction: Perfect Horizons

Perfect Horizons is one connected system, not a new dashboard full of cards:

```text
Horizon / Goal
    -> milestones and projects
        -> weekly or monthly commitments
            -> tasks, habits and time blocks
                -> Day Compass execution
                    -> Review and course correction
```

The user can always answer four questions:

1. What am I moving toward?
2. What matters in this period?
3. What is the next realistic action?
4. What did I learn and what should change?

### Minimum valuable experience

- Create a Goal with title, why, horizon, target date, success measure and an
  optional starting value.
- Link existing/new Projects, Tasks and Habits to it.
- Choose at most three Week Commitments and three Month Commitments.
- See progress calculated from explicit milestones/measurements, never from
  arbitrary task count alone.
- During weekly review, decide `continue`, `adjust`, `pause`, `finish` or
  `release` for every active Goal that needs attention.
- Show the goal connection lightly in Today/Tasks/Habits; never turn Today into
  a strategy dashboard.

### Success and kill signals

- Primary signal: after four weekly cycles, the owner can trace most important
  scheduled work to a current commitment without adding extra duplicate tasks.
- Leading signals: a weekly plan takes only a few minutes; active goals have a
  next action; carry debt decreases rather than merely being hidden.
- Guardrails: Goal setup does not become mandatory for quick capture; Today
  remains faster than opening a separate planning system; empty history is not
  scored as failure.
- Kill/reshape: if Goals become decorative labels or require continual manual
  percentage editing, keep commitments/reviews and replace the progress model.

## Prioritized shortlist

| Sequence | Opportunity | User value | Core-loop fit | Confidence | Effort | Main risk |
|---|---|---:|---:|---:|---:|---|
| Build/test now | Weekly Reset + Review Studio v1 | High | High | High | Medium | Becoming passive analytics |
| Foundation next | Perfect Horizons / Goals | High | High | High | High | Duplicating Projects or over-modeling |
| Next | Month, Quarter and Year Review | High | High | Medium-high | Medium-high | Attractive charts without decisions |
| Next | Quit Journey for negative habits | High | High | High | Medium-high | Shameful streak logic or health overclaim |
| Quick leverage | Perfect Coach Profile | Medium-high | High | High | Low-medium | Persona becoming verbose or intrusive |
| Parallel product track | Perfect Focus Studio | High | High | High | Medium-high | Sensitive Android permissions or punitive friction |
| After data quality | Capacity Radar + Rebalance | High | High | Medium | Medium | Bad advice when estimates are missing |
| Preserve as option | Minimum Viable Day / Rescue Mode | Medium-high | High | Medium | Medium | Encouraging perpetual deferral |

## Idea cards

### 1. Weekly Reset + Review Studio

**Problem:** Recorded activity exists, but the current Insights sheet cannot
explain what changed, what is overloaded, or what to do next.

**Trigger -> action -> result -> repeat loop:** At a chosen weekly boundary,
Perfect opens a five-minute guided reset: celebrate recorded wins, resolve
carry debt, inspect goal/area balance, choose next commitments, then preview the
resulting plan. The next week starts with fewer unresolved decisions.

**Minimum scope:** Week only; planned vs completed; carry/miss/partial outcomes;
focus time; habit consistency using recorded eligible days; three wins/lessons;
three next commitments; all generated planner writes remain reviewable.

**Success:** the review is completed in three of four weeks and produces a
smaller, clearer week. Guardrail: no forced reflection fields and no guilt copy.
Kill if the owner repeatedly skips it or exits without changing any decision.

**Dependencies:** pure local aggregation by calendar period, explicit timezone
boundaries, review snapshot storage and a proposal handoff to existing planner
writes.

### 2. Perfect Horizons / measurable Goals

**Problem:** Projects group work and Areas describe responsibility, but neither
answers what outcome is intended or how progress is judged.

**Experience:** Goal types are Outcome, Metric, Milestone set or Maintain. Each
has a horizon (`week`, `month`, `quarter`, `year`, `someday`), target date,
status, confidence and reason. Progress can be manual or derived from explicit
linked evidence. A Goal's screen shows milestones, supporting routines, recent
movement, next action and risks—not a generic task list.

**Success:** every active Goal can name its next action and measurement method.
Guardrail: quick tasks never require a Goal. Kill/reshape if Goal and Project
descriptions remain indistinguishable in real use.

**Technical decision to spike:** preserve the generic sync envelope while
comparing a new top-level `goal` kind against a versioned Goal payload/profile
attached to Project. Choose based on query integrity, AI ingestion, migration
compatibility and relation semantics—not UI convenience.

### 3. Period views that actually change decisions

**Week view:** capacity lanes by day, unscheduled pool, commitment strip,
conflict/carry warnings and drag/reschedule on desktop with touch-safe actions
on Android.

**Month view:** calendar density, major deadlines, month commitments, habit
rhythm and unscheduled pressure. It is not a tiny task list in 42 cells; dense
days open a readable agenda.

**Quarter/Year view:** Goal and Area movement, seasons of focus, finished and
released outcomes, focus distribution, habit trend and a narrative timeline of
meaningful wins. Compare periods only when both contain enough recorded data.

**Kill signal:** if a view only displays the same task rows at a smaller size,
remove it. Every zoom level must answer a different planning question.

### 4. Quit Journey

The existing `Limit / avoid` mode is retained as the quick version. Advanced
mode adds four strategies:

- **Abstain:** stay clear, with lapse distinct from abandoning the journey.
- **Reduce:** maximum occurrences/amount per period with a gradual target.
- **Taper:** scheduled step-down phases and planned review points.
- **Replace:** log the trigger and the replacement action that was used.

Useful records include urge resisted, lapse, trigger, intensity, context,
recovery action, note, money/time saved and optional risk window. Progress uses
both a clear-day streak and a recovery/resilience streak so one lapse does not
erase all evidence of change. Copy stays non-medical and non-judgmental; the app
does not claim addiction treatment.

**Success:** logging takes seconds and a lapse leads to a concrete recovery
choice instead of silent abandonment. Guardrail: trigger/context fields remain
optional and private. Kill any score that increases shame or encourages hiding
data.

### 5. Perfect Coach Profile

The current prompt already says Persian-first, natural and compact. Make that
preference explicit and stable:

- default persona: warm, colloquial Persian, concise, practical and
  non-judgmental;
- adjustable directness: gentle, balanced or blunt-but-respectful;
- response depth: quick, normal or reflective;
- planning stance: protect commitments, rebalance freely or ask first;
- check-in cadence and quiet times;
- explicit personal operating preferences the owner chooses to save.

The profile is synced owner data, injected server-side through a versioned
prompt, and never contains provider secrets. It changes wording and proposal
policy, not authorization. Manual planning remains available when AI is down.

**Success:** fewer repeated instructions about tone and fewer rewrites of AI
plans. Kill individual controls that do not produce a perceptible difference.

### 6. Capacity Radar and smart rebalance

Use existing duration estimates, scheduled windows, priority, energy, focus
history and carry count to show:

- planned minutes versus declared available capacity;
- high-energy work in the wrong window;
- deadline collision and excessive context switching;
- recurrence load and carry debt before it becomes tomorrow's problem;
- a reviewable rebalance proposal with exact moves and reasons.

Cold start is deterministic and honest: missing estimates show `unknown`, not
fake precision. Learned suggestions remain optional until enough local evidence
exists.

### 7. Minimum Viable Day / Rescue Mode

When the day is overloaded or the owner explicitly asks for help, offer three
levels: **Essential**, **Normal**, and **Stretch**. A Task or Habit may define a
minimum version (for example 5 minutes instead of 30) without changing the
original target. Rescue Mode protects deadlines and one key Goal, proposes what
to defer, and keeps all writes reviewable.

Guardrail: repeated Rescue use becomes review input, not an endless automatic
deferral loop.

### 8. Perfect Focus Studio

Perfect already has Pomodoro, Countdown, Stopwatch, custom duration, break
policies, task attachment, pause/resume and interrupted-session recovery. The
opportunity is therefore not another timer. It is a Focus operating mode that
helps the owner start, protects the session at the chosen strictness, captures
distractions without derailing the task, and learns which working rhythm fits.

#### Focus models

- **Just Start:** 5 minutes with no break contract; designed to cross the
  procrastination threshold.
- **Sprint:** 10–20 minutes for one concrete finish line.
- **Pomodoro:** the existing 25/5 cycle with editable short/long breaks.
- **Deep:** 50/10 or 90/20 for demanding work with fewer transitions.
- **Flow:** open-ended stopwatch with a quiet optional posture/water check,
  never an interrupting alarm.
- **Study + Recall:** learn, then reserve a short closed-book recall phase
  instead of treating all minutes as identical focus.
- **Admin Batch:** a short queue of small related tasks with one shared session.
- **Smart:** recommends one of the explainable models from task estimate,
  available time, energy, recent sessions and deadline pressure. Manual choice
  always remains available.

Every session starts with a tiny **Focus Contract**: task, intended outcome and
definition of done. It ends with `done`, `progressed`, `blocked` or `distracted`,
plus an optional note. Focus time never auto-completes a Task.

#### Flip to Focus — Android experiment

When explicitly armed, placing the phone face-down and stable for a short
confirmation window starts the selected Focus preset. A soft haptic/audio cue
confirms activation. Picking it up or turning it face-up opens a compact choice
to continue, pause, capture a distraction or finish; it never records failure
automatically.

Use the gravity/rotation-vector sensor where available and accelerometer as a
fallback. Android's official sensor guidance recommends gravity/rotation-vector
for stable motion/orientation work and notes that continuous sensor delivery is
restricted while an app is in the background. The first version therefore
works while Perfect is visible. A later always-armed mode would require a
user-started foreground service with a persistent notification and must pass a
battery/accidental-trigger gate before shipping:

- [Android motion sensors](https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion)
- [Android background sensor limits](https://developer.android.com/develop/sensors-and-location/sensors/sensors_overview)
- [Android foreground-service launch rules](https://developer.android.com/develop/background-work/services/fgs/launch)

Success target: deliberate face-down gestures start reliably in device tests,
ordinary rotation or putting the phone in a pocket does not trigger a session,
and an emergency exit is always one intentional action away. Kill background
arming if it needs noisy permissions, drains battery or remains OEM-fragile.

#### Focus Shield — graduated, owner-controlled strictness

1. **Calm:** immersive Perfect focus UI, muted app motion and only the current
   contract; no special Android permission.
2. **Quiet:** enable Do Not Disturb for the session after the owner grants
   notification-policy access in Android Settings. Calls/alarms follow the
   owner's chosen exception policy.
3. **Aware:** with separately granted Usage Access, record neutral app-switch
   interruptions and show them after the session; do not collect content.
4. **Block selected apps (experimental):** an explicitly enabled Accessibility
   service can return from owner-selected distractions to the Focus surface.
   It must have a visible off switch, allow calls/system settings/emergency
   actions, and never disguise the sensitive permission.

Official Android boundaries:

- DND changes require user-granted Notification Policy access:
  [NotificationManager](https://developer.android.com/reference/android/app/NotificationManager#isNotificationPolicyAccessGranted()).
- Cross-app usage data requires `PACKAGE_USAGE_STATS` plus a user grant in
  Settings: [UsageStatsManager](https://developer.android.com/reference/android/app/usage/UsageStatsManager).
- Accessibility services start only after the user explicitly enables them in
  Settings: [AccessibilityService](https://developer.android.com/reference/android/accessibilityservice/AccessibilityService).

True kiosk-style Lock Task is designed for allowlisted, managed/dedicated
devices; an ordinary app otherwise gets user-exitable screen pinning. Likewise,
`DevicePolicyManager.lockNow()` is a device-admin emergency lock, not a safe
focus timer. Perfect should not request device-owner/admin power merely to make
a Pomodoro harder to escape:

- [Android Lock Task mode](https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode)
- [DevicePolicyManager lockNow](https://developer.android.com/reference/android/app/admin/DevicePolicyManager#lockNow())

Accordingly, **Hard Lock is rejected as a default feature**. Screen Pinning can
remain an optional owner-invoked experiment; Quiet/Aware provide most of the
value with clearer consent and recovery.

#### Intelligent support without surveillance

- **Distraction Inbox:** text or voice-capture a thought into Inbox without
  leaving the Focus surface; process it after the session.
- **AI body double:** one compact start confirmation and an optional end review;
  silence during the session unless the owner asks for help.
- **Stuck rescue:** a button asks AI to break only the current task into the
  smallest next action and returns a reviewable checklist proposal.
- **Adaptive recommendation:** after enough recorded sessions, compare planned
  versus actual duration, outcome and time-of-day to suggest a Focus model with
  a visible reason. Unknown data remains unknown.
- **Cross-device presence:** a Focus session started on Windows appears on
  Android and vice versa. Sensitive shielding is never remotely forced; the
  other device asks for one-tap confirmation.
- **Focus Orbit:** during a session, Day Compass transforms into a restrained
  progress instrument with the task, time, break boundary and one capture
  action—no decorative dashboard.

#### Recommended Focus sequence

1. Redesign the current Focus sheet into Focus Studio while preserving the
   existing session records and recovery.
2. Add Focus Contract, model presets, session outcome and Distraction Inbox.
3. Prototype foreground Flip to Focus on at least two Android device classes.
4. Add Quiet shield through DND access with explicit exceptions and restoration.
5. Add Smart recommendations only after session outcomes are recorded.
6. Add cross-device presence; keep shield activation local and confirmed.
7. Evaluate Usage Awareness and app blocking as separate opt-in experiments,
   not prerequisites for a high-quality Focus experience.

## Supporting ideas worth retaining

- **Next Move:** choose current time, energy and context and receive a short
  list of eligible tasks from existing metadata.
- **Season Theme:** one optional phrase/color for a month or quarter that keeps
  the active horizon emotionally memorable without becoming another taxonomy.
- **Decision log:** Reviews preserve why a Goal was changed, paused or released,
  so AI and future-you do not repeatedly reopen settled decisions.
- **Progress story:** a chronological, export-free private timeline of
  meaningful completions, recovered weeks and achieved goals.
- **Templates as recipes:** Morning reset, exam month, recovery week, deep-work
  sprint and quit journey create editable bundles rather than fixed systems.

## Existing commitments, not counted as new ideas

- Habit streaks, achievements and the gamified layer were already requested.
  They should attach to recorded habit eligibility, recovery and Goals; they
  are not a separate novelty item.
- AI day planning and week rebalance starters already exist. Their next step is
  deeper context and coach preferences, not a second generic chatbot.
- Projects, Areas and Insights already exist but need management and redesign;
  renaming them does not count as innovation.

## Rejected or deferred

- **Social accountability, leaderboards or shared Goals:** rejected because
  Perfect is explicitly private and single-owner.
- **Fully autonomous AI scheduling/writes:** rejected because it weakens trust,
  conflicts with reviewable proposals and makes recovery harder.
- **A permanent sixth navigation destination for every new feature:** rejected
  until an information-architecture pass proves it improves reachability.
  Horizons and Reviews should first strengthen Plan/More and contextual links.
- **Vanity dashboard with dozens of charts:** rejected. Every chart must expose
  a decision or drill-down; otherwise it is decoration.
- **Predictive success probability:** deferred until enough trustworthy history
  exists and calibration can be demonstrated. False precision is worse than a
  simple risk flag.
- **Heavy XP economy:** deferred behind the already-requested streak and
  achievement foundation. Rewards must support the owner's goals, not optimize
  compulsive app use.

## Recommended delivery sequence

1. Finish the active visual and interaction quality gate for Today, Tasks,
   Habits and the multi-step editor.
2. Rebuild the existing Focus sheet as Focus Studio, then add Focus Contract,
   model presets and Distraction Inbox before platform-sensitive shielding.
3. Build a pure, testable period aggregation engine and Weekly Reset v1 using
   current records; store explicit Review snapshots local-first and sync them.
4. Prototype foreground Flip to Focus and DND Quiet mode on real Android;
   keep Hard Lock out of the default product contract.
5. Run the Goal-model spike, then add Perfect Horizons and link contracts.
6. Add genuine Week and Month Plan compositions and connect commitments to the
   Day Compass.
7. Extend Review to Month, Quarter and Year with period-safe comparisons.
8. Expand `avoid` into Quit Journey and attach resilience-aware streaks.
9. Add the Coach Profile, then let AI assist Reviews, Goals, Focus selection and Quit recovery
   through the existing reviewable-proposal path.
10. Enable Capacity Radar only after estimate/energy coverage is visible and
   honest; add Rescue Mode as its recovery action.

This sequence keeps the current app usable at every stage and turns each layer
into evidence for the next instead of shipping a disconnected suite.
