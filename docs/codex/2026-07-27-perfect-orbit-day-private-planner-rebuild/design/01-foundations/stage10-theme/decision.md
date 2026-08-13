# Stage 10 design decision — Graphite Bloom

Status: **autonomously accepted for implementation**
Catalog: `ps01-theme-2.0.0`
Boundary: design evidence only; fixture labels never seed owner data.

## Product truth

Perfect is a calm private day instrument used repeatedly across Android and Windows. The theme system must make long planning sessions legible without turning the product into a generic black dashboard, muddy pastel canvas, or color-only status display.

## Candidates compared

| Direction | Score / 100 | Verdict |
| --- | ---: | --- |
| Graphite Bloom | 96 | SELECTED — strongest Perfect identity, calm long-session use and clean Windows hierarchy. |
| Midnight Vellum | 84 | REJECTED — warm and attractive, but dense planning surfaces become too cocoa/muddy. |
| Ink Prism | 89 | REJECTED — excellent focus, but too cyber/technical for a humane private day planner. |

## Selected

**Graphite Bloom** keeps neutral graphite depth, authored pastel light and explicit boundaries. It is recognizably Perfect in a cropped screenshot, preserves the PS01 Pulse/Stream anatomy, and leaves enough contrast headroom for live mixed Persian/English copy, focus, hover and sync states.

The separate **Clarity** variants are accessibility products, not inversions: blur is removed, boundaries become structural, text targets 7:1, focus targets at least 3:1 and every status keeps icon + copy + color.

## Modernize / Integrity / Anatomy / Style / Copy verdicts

- **Modernize:** uncommon material idea remains tied to the day-instrument job; no template dashboard or generic gradient glass.
- **Integrity:** one semantic registry owns Flutter, authored assets, Android native surfaces and Windows chrome.
- **Anatomy:** theme substitution never moves navigation, actions, text blocks, panes or state surfaces.
- **Style:** pastel identity is concentrated in intention/rhythm/focus roles; neutral separation carries long-session hierarchy.
- **Copy:** Stage 04/05 exact component/page assets are frozen by hash, and the new matrices preserve their layout/state contracts before runtime work begins.

## Measured contrast

- `theme-light-daylight`: lowest registered pair **4.34:1**; 19/19 passed.
- `theme-dark-graphite-bloom`: lowest registered pair **5.50:1**; 19/19 passed.
- `theme-hc-light-clarity`: lowest registered pair **7.94:1**; 19/19 passed.
- `theme-hc-dark-clarity`: lowest registered pair **11.52:1**; 19/19 passed.

## Autonomous authority

The owner explicitly requested independent design decisions and no consultation during this execution. The already-selected PS01 direction is unchanged; this file approves only its Stage 10 theme/material variants.
