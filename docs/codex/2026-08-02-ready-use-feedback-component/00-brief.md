# StudyHUB feedback capture port and ReadyUse component library

- Task ID: `2026-08-02-ready-use-feedback-component`
- Status: `active`
- Created: 2026-08-02
- Last updated: 2026-08-02 09:17 +03:30
- Language: English

## Request

Port StudyHUB-Android's private debug-capture option into Perfect! as a polished Android and Windows feature, place the generalized component directly in the personal `Projects/Components` library, and create the `ReadyUse` Codex skill for safe reuse.

## Success Criteria

- More/Settings can persistently enable or disable a draggable capture control.
- The owner can save a typed note with or without a reviewed app screenshot.
- Entries, screenshots, and bounded diagnostic logs survive launches and can be reviewed, deleted, cleared, or explicitly exported.
- Export review is bound to an immutable snapshot; any entry, log, or screenshot drift requires a fresh review before delivery.
- Repository mutation and export preparation are serialized by a bounded cross-instance/process lease, with FIFO drain, re-entry rejection, and timeout behavior that fails closed.
- Clear All removes active data, every recoverable store generation, and all app-owned managed-export artifacts, rebuilds safe empty indexes, and reports any incomplete deletion so the owner can retry.
- Clear All does not claim to remove ZIP files already saved or shared outside the app-owned managed-export area; the owner must delete those external copies separately.
- Stored/exported text is redacted; screenshot pixels are clearly identified as unredacted and require review.
- Storage, preferences, and logger attachment respect the authenticated owner boundary.
- The Perfect repository is self-contained; CI and releases never depend on an absolute personal Components path.
- The canonical reusable component and `ReadyUse` skill are independently discoverable and valid.
- Android and Windows builds, native runtime behavior, and release artifacts are proven before completion.

## In Scope

- Flutter Android and Windows integration.
- Local persistence, screenshot capture/review, diagnostic logging, privacy review, ZIP export, and native delivery adapters.
- Authenticated-owner lifecycle and More-page integration.
- Canonical component at `C:/Users/K1/Desktop/Projects/Components/flutter/private-feedback-capture`.
- Personal `ReadyUse` skill at `C:/Users/K1/.codex/skills/ready-use`.

## Out of Scope

- Supabase upload or cross-device sync of diagnostic bundles.
- Public distribution or telemetry.
- PDF reporting for this task.

## Assumptions

- Feedback remains private and device-local until the owner explicitly exports it.
- Existing planner data, auth session, signing lineage, and in-place update continuity must remain intact.
