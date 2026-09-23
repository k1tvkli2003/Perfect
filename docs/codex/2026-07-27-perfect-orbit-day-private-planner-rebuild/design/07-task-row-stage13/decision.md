# Stage 13 design gate — unified task row and status control

Status: **preview frozen v2; implementation pending Stage 12 release gate**
Decision date: 2026-09-24
Owner: solo coordinator

## Frozen preview

- Preview: `status-plates.html`
- Desktop capture: `status-plates-desktop.png` (`1366px` viewport, full page)
- Phone capture: `status-plates-phone.png` (`390px` viewport, full page)
- Preview SHA-256: `ad860939039048e108265485fd3b6aafd6f5badde99184b72461c34781ca2912`
- Regions: 9 named plates covering the 8 required component plates plus dark/high-contrast state intent.
- Rows: 13, including scheduled, completed, missed, overdue one-off, recurring occurrence, RTL/mixed-script, unscheduled and checklist variants.
- Interactive controls: 38 status/detail targets; status/detail targets remain distinct.
- Preview data is fixture-only. It must not be copied into product data or treated as canonical planner truth.

## Chosen contract

- Outer semantic hit region: 48x48px in every state.
- Inner visual ring/disc: 30px, optically centered and geometry-stable.
- Pending: neutral empty ring.
- Partial: proportional arc, visually empty center; exact percent remains in semantics, tooltip and explicit detail.
- Completed: filled success treatment with authored check.
- Missed: equally weighted error treatment with authored cross.
- One restrained Next row rail/tint; no geometry change.
- Scheduled, `Anytime`, and `Overdue` remain distinct; overdue receives restrained high-contrast warning color without inventing a future slot.
- Recurring fixture names today occurrence progress separately from entity lifetime status.
- Narrow rows protect title/action before secondary metadata; long titles wrap instead of disappearing behind ellipsis.
- Status and detail actions have separate targets; status tap must not open detail.
- Inline receipt supports local save, Undo and failure/retry states; receipt is not yet a product implementation claim.

## Review evidence

- Existing Node preview tests: `6/6` pass.
- New isolated browser geometry verifier: `5/5` viewport/text-scale cases pass.
- Cases: `320x700`, `390x844`, `800x900`, `1366x900`, and `390x844` at explicit 200% copy scale.
- Every case: 9 plates, 13 rows, 38 controls, overdue/recurring/RTL fixtures present, no horizontal overflow, no undersized target, no row overlap, no title clipping.
- Captures refreshed after v2 fixes; canonical files are `status-plates-desktop.png` and `status-plates-phone.png`.
- Static visual review found no material overlap or clipping. Overdue emphasis was corrected after critique. Recurring copy was changed from ambiguous `Repeats daily · Today 60%` to explicit `Daily occurrence · 60% today`; final phone and 200% reviews confirmed full wrapped rendering. RTL/mixed-script review confirmed intact Persian title, readable `API` acronym, expected control order and no bidi clipping. Small metadata and border contrast remain bounded by the preview's intentionally quiet secondary hierarchy and must receive product-theme/runtime verification.
- Static preview is not Flutter, Android, Windows or widget runtime acceptance.

## Implementation gate

Do not edit shared status widgets until Stage 12 exact-source Windows CI/release gate passes. Then implement one vertical slice with RED/GREEN tests for:

1. status cycle and optimistic persistence/rollback;
2. exact percent semantics with no percentage painted inside the small ring;
3. separate status/detail hit paths;
4. fixed outer geometry across Pending/Partial/Done/Missed;
5. Today/Tasks/Plan/detail/widget consumer parity.

Reject if exact percent is dropped from data, state controls change outer geometry, or status tap bubbles into detail/edit.
