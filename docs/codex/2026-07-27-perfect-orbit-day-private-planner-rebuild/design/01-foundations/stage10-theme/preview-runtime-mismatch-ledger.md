# Stage 10 preview / runtime mismatch ledger

Status: **closed — preview, Flutter, Android runtime and hosted Windows rows verified**

| Surface | Preview evidence | Runtime evidence | Expected mismatch before implementation | Acceptance after implementation |
| --- | --- | --- | --- | --- |
| Foundations | `theme-foundations.png` | four authored ThemeData variants, 76 measured pairs, semantic-role source scan | closed | four stable theme IDs; zero reusable raw-color bypass; every measured pair passes its threshold |
| Phone empty/dense | `phone-empty-dense-matrix.png` | five Stage 10 phone goldens plus real build-2062 Daylight/Graphite/Clarity captures | closed | geometry remains stable; Orbit live text and curved period labels remain visible in all four themes |
| Tablet/Windows | `adaptive-tablet-windows-matrix.png` | tablet/Windows dark and Clarity goldens; Windows MethodChannel/DWM contract; hosted run `31687276749` | closed | pane geometry stable; exact-SHA hosted runner compiled and packaged the native frame bridge |
| Components | `component-state-matrix.png` | 444-test suite, focused theme/accessibility, workspace, Sync and widget contracts | closed | sheets, dialogs, snackbars, painters, focus, status and controls resolve through semantic roles |
| Native surfaces | `native-surface-matrix.png` | Android four-layout contract, 40 theme rasters, 16 status vectors, four surfaces, Quick Add projection and trusted Windows package | closed | Android widget/Quick Add follow effective appearance; Windows DWM bridge compiled, signed and packaged on the trusted runner |

No preview image is runtime proof. Android rows close against the hash-verified
`runtime/android/runtime-manifest.json` evidence from the confirmed foreground
preview package. Windows is closed by trusted run `31687276749` on exact source SHA
`8742a676533d3337ed5d69919cd8d612e08c6024`; the local host still lacks the optional
ATL header used by `flutter_local_notifications_windows`, so local compilation is
not retroactively claimed.
