# Platform-adaptive composition contract

Status: Stage 03 evidence rule
Targets: Android phone, Android tablet and Windows only

## One semantic product, five first-class compositions

| Class | Working range | Primary input | Canonical composition |
| --- | --- | --- | --- |
| Phone portrait | compact width, any usable height | one-handed touch + IME | compact glass header, scrollable day/work list, icon-only floating footer, morphing capture orb |
| Phone landscape / fold split | compact or medium width with short height | touch + IME | compressed header, horizontal/stacked reflow chosen by height, persistent list scroll, no fixed hero |
| Tablet portrait | medium/expanded width | touch + keyboard | compact rail, primary list with contextual supporting/detail pane when useful |
| Tablet landscape | expanded/large width | touch + keyboard/trackpad | compact rail, list-detail or plan canvas, optional collapsible inspector; no stretched phone column |
| Windows compact/intermediate/wide | continuously resizable | mouse + keyboard + IME | remembered rail, command/search affordances, list-detail at width, inspector/pane controls, native context/shortcut behavior |

Ranges are informed by Android's current window-size classes, but breakpoints are
content-driven. A title, action or field that becomes cramped triggers recomposition
before a nominal device category does.

## Geometry model

- Intrinsic size owns copy, fields and controls.
- Flex owns distribution among siblings.
- Bounded fractions own panes only after minimum readable widths are satisfied.
- Aspect ratio owns marks, charts and meaningful visual instruments.
- Fixed semantic tokens own hit targets, icon frames, strokes, radii and rhythm.
- No surface is positioned by reference-screen coordinates.
- No doctrine forces every value to be proportional; the model is deliberately
  mixed and evidence-driven.

## Responsive transformations

| Event | Required response | Forbidden response |
| --- | --- | --- |
| phone portrait -> landscape | reduce nonessential header height, preserve active item/draft/scroll, reflow tool rows | shrink typography and clip the same tall stack |
| tablet rail expand/collapse | animate width/reposition with focus continuity, remember state where appropriate | rebuild route or reset list selection |
| Windows compact -> wide | reveal detail/inspector without duplicating route state | stretch row lines across the entire window |
| IME opens | keep active field/action reachable, allow body to scroll, dismiss on outside tap | side toolbar, hidden submit action or automatic keyboard on composer expansion |
| 200% text | wrap/stack primary action groups, preserve whole phrases | ellipsize only action or overlap controls |
| RTL/mixed text | isolate bidirectional metadata, mirror directional layout only where semantic | reverse time/order semantics or break Latin date/time |
| reduced motion | crossfade/reposition with near-zero overshoot and stable focus | simply remove all feedback or leave content teleporting |
| high contrast | replace glass/low-alpha borders with solid surfaces and explicit focus | keep blur and pastel-on-pastel because palette is branded |

## Navigation

- Phone footer is icon-only, floating and glass-backed. Accessible names are exposed
  to semantics and tooltips, not permanently repeated below icons.
- Capture is not a footer destination. It floats above the footer with no background
  strip and expands only when invoked.
- Tablet defaults to a compact icon rail. Windows remembers compact/expanded rail.
- Normal Task/Habit row body opens detail. Status/log control mutates. Edit is named.
- Deep links, widget, notification, AI proposal and Windows protocol ingress resolve
  through one route intent that preserves destination and entity identity after auth.

## Header

- The custom Perfect! wordmark is an image asset, never a substitute live font.
- The header is compact and spatially blurred only behind its own content.
- Sync cloud has icon + semantic text/tooltip and three color-independent states:
  synced green, syncing/retrying yellow and error red. Offline is named separately.
- Time plus Gregorian/Jalali date compose as a compact cluster and update across
  midnight/timezone without requiring pull-to-refresh.
- No generic three-dot header menu for sign-out/shortcuts; those belong to Settings
  and discoverable platform commands.

## Input and motion

- Hover, focus, pressed, selected, dragging and context-menu states are authored for
  Windows and keyboard-enabled tablet.
- Page title uses a restrained rise + fade tied to navigation hierarchy. Content
  groups enter in short stagger only when it clarifies reading order.
- Modal routes use scale/fade/vertical settling appropriate to origin; no unrelated
  long slide or bounce.
- Capture morph preserves the same anchor, independent Task/Plan/AI/Voice drafts and
  does not summon the keyboard until the owner taps a text field.
- Every animation is interruptible and reversible. Resize mid-animation settles into
  the new constraint solution without jumping.

## Android widget

- Native responsive layouts cover compact, normal and expanded size families.
- The collection scrolls and directly cycles task/habit outcome states.
- Quick Add opens a compact native entry dialog and commits to the durable local
  replay queue; app launch is not required for the initial capture.
- Branding is the transparent mark only, mask-safe and uncropped.
- Widget empty/offline/retry states remain actionable and never display demo data.

## Acceptance matrix

Every final preview and runtime comparison must include:

- phone portrait and short landscape;
- tablet portrait, landscape and split width;
- Windows compact, intermediate and wide;
- empty, one-item, normal and dense data;
- light, dark and high contrast;
- English, Persian and mixed-direction long copy at 100% and 200%;
- touch, mouse/hover, keyboard/focus and IME;
- online, offline, syncing, retry, error and conflict;
- normal and reduced motion;
- breakpoint changes while a draft, selection, scroll and focused field exist.
