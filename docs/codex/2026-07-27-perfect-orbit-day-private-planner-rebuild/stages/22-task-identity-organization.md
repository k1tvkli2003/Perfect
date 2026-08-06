# Stage 22 — Task identity, category and organization

Status: pending  
Depends on: Stage 21  
Primary surfaces: Create Task/Recurring Task identity and organization steps

## Mission

Let the owner create a recognizable, retrievable task quickly while keeping rich
organization optional and discoverable. Build a reusable category/icon/color system
instead of six hardcoded labels or raw emoji.

## Mandatory preview and Copy entry gate

- Bind implementation to `wiz-type-choice`, `wiz-identity-step`,
  `sel-category-tile/picker`, `sel-icon-library`, `sel-color-swatch`,
  `sel-project-area-goal`, `sel-tag-context` and `pg-task-identity`.
- Preview the complete 30+ curated catalog, search/recent/all/custom paths, create/
  rename/archive, contrast warning, long/mixed copy, 200% and narrow/wide overlays.
- Implement one stable selector/catalog contract and compare every wizard, filter,
  detail, widget and AI proposal consumer against its frozen plate.
- A custom choice that looks correct but cannot round-trip local→Supabase→widget/
  backup/AI, or any raw emoji/generic placeholder, fails the combined gate.

## Create-only Type step

- Type appears only for new entities and offers Task, Recurring Task, Habit, Project
  and Area using modern equal selectors that can reflow.
- Selection changes color/shape; do not add a checkmark unless accessibility needs a
  separate non-color cue not already provided by semantics/position.
- Switching type deliberately maps compatible fields and warns before discarding an
  incompatible draft; it never silently resets the entire wizard.

## Category system

- Provide at least 30 curated choices relevant to personal work, health, study,
  relationships, finance, home, errands, creativity, rest and self-care.
- Choices are metadata definitions, not seeded planner entities.
- Each has stable key, localized label, owned SVG icon, default semantic color and
  editable presentation without changing linked entity identity.
- Search/filter icon archive; create custom category with name, icon and color;
  rename/archive categories safely and handle existing references.

## Organization hierarchy

- Category answers “what context/type”; Project answers finite outcome; Area answers
  ongoing responsibility. Explain distinctions through examples only when needed.
- Project/Area choices are searchable and filtered to owner; no cross-owner IDs may
  be submitted by UI/model.
- Labels/tags remain optional, deduplicated case-insensitively and mixed-language safe.

## UX sequence

1. Fast path can proceed with type/title and no organization.
2. Category step shows recent/frequent first, then curated/archive search.
3. Project/Area live under a clear optional disclosure with current summary.
4. Icon/color customizer opens an anchored responsive surface, not a giant modal grid.
5. Review shows final identity exactly as lists/detail/widget will render it.

## Edge scenarios

Long/custom/duplicate names; category archived; project deleted remotely; 30+ icons at
200% text; RTL search; custom color contrast; switching type after checklist/timing;
offline category creation and sync conflict.

## Verification

Catalog count/key/icon tests; selection geometry; no raw emoji; custom round-trip;
owner authorization; category rename/archive references; phone/tablet/Windows visual
matrix; fast-path tap count benchmark.

## Reject if

- Curated categories are inserted as tasks/habits for a new owner.
- Custom icon/color exists only visually and is lost in sync/widget/detail.
- Optional organization blocks quick task creation.

## Handoff

Stage 23 receives stable identity/category/project/area values. Commit/push/release
with catalog/data/UI evidence and clean Git.
