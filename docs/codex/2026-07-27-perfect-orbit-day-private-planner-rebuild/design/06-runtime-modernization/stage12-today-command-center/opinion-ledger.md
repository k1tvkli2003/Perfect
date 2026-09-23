# Stage 12 whole-experience opinion ledger

| Surface | Judgment | Stage 12 action | Evidence / owner |
|---|---|---|---|
| Product promise | REFINE | Today communicates decision, next, scheduled, flexible, habit | Stage 12 IA |
| Name / brand mark | KEEP | No logo rewrite | Existing brand assets |
| App icon / splash | OUT OF SCOPE | Revisit only if later identity gate finds mismatch | Stage 49/50 |
| Typography | REFINE | One UI sans scale; lower decorative all-caps use | Theme + Today components |
| Iconography | KEEP/REFINE | Keep repository pictograms; remove ambiguous generated icons | Existing `PerfectPictogram` |
| Navigation | KEEP FOR NOW | Functional shell retained; broader shell modernization lands with matching stage | Stages 07/36–40 |
| Today heading / HUD | REDESIGN | Greeting + Pulse collapse into compact command hierarchy | Stage 12 |
| Today day stream | RADICAL REDESIGN | Dominant sectioned agenda with one Next emphasis | Stage 12 |
| Task row | REFINE LATER | Preserve function now; full anatomy in Stage 13 | Stage 13 |
| Habit row | REFINE LATER | Preserve function now; logging in Stage 14 | Stage 14 |
| Empty/loading/offline/error | REFINE LATER | Keep contracts; full language in Stage 15 | Stage 15 |
| Quick Capture | KEEP FUNCTION / REDESIGN LATER | Preserve behavior and safe-area; visual rebuild in Stage 16 | Stage 16 |
| Inspector | REFINE COMPOSITION | Fix occupancy/attachment now; full workflow in Stage 35 | Stage 12 + 35 |
| Motion | REFINE | Preserve staged entrance + reduced motion; no decorative replay | Stage 12 |
| Theming | REDESIGN | Midnight/Paper semantic palette, HC preserved | Stage 12 foundation |
| Preview/store imagery | ADD EVIDENCE | Versioned ImageGen references; not shipping UI | Stage 12 artifacts |
| Generated visual assets in runtime | REMOVE | No bitmap UI; live semantic Flutter only | Decomposition manifest |

## Functional preservation

Must remain unchanged through Stage 12:
- Canonical storage and owner scoping.
- Task/habit identity and mutation commands.
- Progress, recurrence, recovery and eligibility.
- Day-stream section calculation and `nextEntryId`.
- Inspector selection/edit/duplicate/focus actions.
- Quick Capture save behavior.
- Keyboard, semantics, reduced motion and theme-mode settings.
