# Stage 10 preview / runtime mismatch ledger

Status: **preview gate frozen; Flutter and Android runtime rows closed; hosted Windows row pending exact-SHA build**

| Surface | Preview evidence | Runtime evidence | Expected mismatch before implementation | Acceptance after implementation |
| --- | --- | --- | --- | --- |
| Foundations | `theme-foundations.png` | four authored ThemeData variants, 76 measured pairs, semantic-role source scan | closed | four stable theme IDs; zero reusable raw-color bypass; every measured pair passes its threshold |
| Phone empty/dense | `phone-empty-dense-matrix.png` | five Stage 10 phone goldens plus real build-2062 Daylight/Graphite/Clarity captures | closed | geometry remains stable; Orbit live text and curved period labels remain visible in all four themes |
| Tablet/Windows | `adaptive-tablet-windows-matrix.png` | tablet/Windows dark and Clarity goldens; Windows MethodChannel/DWM contract | Flutter closed; hosted Windows compile pending | pane geometry stable; exact-SHA hosted runner must compile and package the native frame bridge |
| Components | `component-state-matrix.png` | 444-test suite, focused theme/accessibility, workspace, Sync and widget contracts | closed | sheets, dialogs, snackbars, painters, focus, status and controls resolve through semantic roles |
| Native surfaces | `native-surface-matrix.png` | Android four-layout contract, 40 theme rasters, 16 status vectors, four surfaces and Quick Add projection | Android closed; hosted Windows pending | Android widget/Quick Add follow effective appearance; Windows DWM bridge awaits hosted compile proof |

No preview image is runtime proof. Android rows close against the hash-verified
`runtime/android/runtime-manifest.json` evidence from the confirmed foreground
preview package. Windows remains explicitly open until the exact source SHA passes
the trusted hosted build because this local host lacks the optional ATL header used
by `flutter_local_notifications_windows`.
