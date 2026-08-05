# Verification

## 2026-08-05 Critics baseline

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Focused domain and presentation baseline | `flutter test test/planner/planner_habit_day_summary_test.dart test/presentation/planner_editor_test.dart test/presentation/focus_session_sheet_test.dart test/presentation/perfect_workspace_page_test.dart` | passed | 61/61; this validates existing assertions but does not waive the frozen C1–C12 findings. |
| Android signed-in preview inspection | live preview on `emulator-5556`, 1080×2400, API 35 | partial pass | Tasks/Habits/wizard flows rendered and remained actionable; runtime exposed the truthful-data, hierarchy and occlusion findings recorded in `10-critics-tasks-habits-editor-ledger.md`. |
| Approved-reference comparison | side-by-side inspection of current Android Home and the selected reference | failed quality gate | Home is directionally close, but last-row continuity and Orbit finish remain below the accepted target. |
| Local Windows preview build | `flutter build windows --debug -t lib/dev/perfect_live_preview.dart` | not run successfully | blocked by missing Visual Studio Desktop C++ toolchain on this host; existing goldens and hosted release builds are supporting evidence, not live hover/motion proof. |

## 2026-08-05 Perfect Cycle 1 — pending Habit truth

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Domain regression | `flutter test test/planner/planner_habit_day_summary_test.dart` | passed | Pending count target 8 and checklist threshold 2/3 are preserved. |
| Workspace regression | focused `perfect_workspace_page_test.dart` | passed | Compact Habits renders `Pending · 0 of 8 glasses · 0%` and rejects the old `of 1 glasses` output. |
| Static analysis | `flutter analyze` | passed | `No issues found`. |
| Full Flutter suite | `flutter test` | passed | 355/355. |
| Android preview build/install | debug sibling APK from `lib/dev/perfect_live_preview.dart`, `adb install -r` | passed | Production package/session remains untouched; preview package updated successfully. |
| Android runtime semantics and screenshot | API 35 `emulator-5556` | passed | Expected measured target present in UI and semantics; screenshot at `.codex-tmp/critics-cycle1/android-habits-cycle1-fixed.png`. |
| Cold-start crash scan | clear logcat, force-stop, cold start, 3-second scan | passed | 2685 ms; no `FATAL EXCEPTION`, `E/flutter` or preview-process fatal match. |

## 2026-08-06 Perfect Cycle 2 — truthful Tasks and progressive filters

| Check | Command/Method | Result | Evidence / limit |
|---|---|---|---|
| Exact previous-stage release | workflow run `31041370535` and release API | passed | SHA `a793531…`; run #36 success; immutable `v1.1.0-build.2036` has exactly Android APK، Windows portable ZIP and Windows Setup EXE. |
| Task default truth | compact workspace widget test + API 35 preview | passed | `Focus Deep Work` and all three active tasks are visible without choosing a filter; Inbox remains explicitly selectable. |
| Progressive filter behavior | compact/wide widget tests and Android screenshots | passed | phone defaults to Search + `Open · All`; TYPE/STATUS animate on demand; 900dp retains inline controls. |
| Keyboard lifecycle | widget input visibility + Android `dumpsys input_method` | passed | Search opens IME; tapping the filter summary unfocuses Search, reports `mInputShown=false`, opens filters and restores the task list. |
| Large text and RTL | 390dp RTL at 200% | passed | filter summary and result count recompose instead of truncating; no exception. |
| Selection language | ChoiceChip inspection | passed for Task filters | selected color/shape remains, `showCheckmark=false`; category/icon/color surfaces remain under C5. |
| Static analysis | `flutter analyze` | passed | `No issues found`; deprecated SizeTransition API was replaced before closure. |
| Full Flutter suite | `flutter test` | passed | 356/356. |
| Android runtime | debug sibling preview on `emulator-5554`, API 35 | passed | cold start 3291 ms; collapsed/expanded screenshots under `.codex-tmp/critics-cycle1/`; no `FATAL EXCEPTION` or `E/flutter` match. |

## Summary

- Result: partial
- Interpretation: the integrated Flutter/AI/backend source، exact-SHA CI and all three install-ready private Release assets pass their automated/integrity gates. Android install-over، Windows update continuity and the self-contained Setup clean-install/rerun path are proven؛ signed-in cross-device and remaining GUI/device-runtime journeys remain open.
- Last verified: 2026-08-02T02:35:00+03:30
- Final Android artifact under test: `build/private-update-proof/perfect-1.1.0+2004.apk`
- Current final APK SHA-256: `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`
- Hosted exact-HEAD commit: `1b8468b18ec8edc2645ab73dffff23a6829ba0ea`
- Hosted CI: [run `30721214315`](https://github.com/k1tvkli2003/Perfect/actions/runs/30721214315) (`#30`), conclusion `success`
- Immutable Release: [`v1.1.0-build.2030`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2030)، exactly three uploaded assets

این سند بین «اثبات اجرا»، «اثبات hosted build/artifact»، «بررسی خودکار» و «بررسی در دسترس‌نبوده» فرق می‌گذارد. source جاری analyzer و ۲۶۶ تست را پاس کرده، migration امن context و Function v3 زنده‌اند و runهای exact-SHA update continuity را حفظ کرده‌اند. Run `#30` علاوه بر raw install-over، خود Setup را برای clean install و rerun اجرا کرده و Release immutable را پس از download/hash verification منتشر کرده است. portable قبلی auth surface را در GUI واقعی wide/short/compact بررسی کرده است؛ این شاهد به signed-in Orbit workspace، hover یا jank تعمیم داده نمی‌شود.

## Current integrated source proof

| Check | Result | Evidence |
|---|---|---|
| Flutter static analysis | passed | `flutter analyze --no-pub` → no issues |
| Full Flutter suite | passed | `flutter test --no-pub --reporter compact` → 266/266 |
| Workspace UI/adaptive suite | passed | 44/44؛ expanded/short/wide Windows، tablet، 200% text and resize paths |
| Private release continuity contract | passed | monotonic Android/MSIX version mapping، signer constraints، artifact naming and baseline/install-over guards |
| Release queue and artifact contract | passed locally and hosted | `queue: max` accepted by GitHub؛ exact Android `VERSION_CODE` naming and three private artifacts proven in run `#20` |
| actionlint compatibility | passed with one scoped compatibility ignore | v1.7.12 predates `concurrency.queue`؛ only the exact new-key diagnostic is ignored، all other diagnostics remain fatal |
| Windows private installer | passed | Setup پین‌شده، clean install، rerun، حفظ package family/LocalState، عدم تغییر Root و rollback کنترل‌شده؛ encrypted offline signing backup/restore نیز باقی است |

## Immutable install-ready Release `v1.1.0-build.2030`

| Asset/gate | Result | Evidence |
|---|---|---|
| Release/tag | passed | immutable، non-draft، tag روی commit `1b8468b`؛ `gh release verify` attestation را تأیید کرد |
| Exact asset set | passed | فقط `Perfect-1.1.0-build.2030-Android.apk`، `Perfect-1.1.0-build.2030-Windows-Setup.exe` و `Perfect-1.1.0-build.2030-Windows-Portable.zip` |
| Android | passed | `com.k1tvkli2003.perfect`، label `Perfect!`، `1.1.0+2030`، سه ABI، امضای v2 و signer `144E87CB…B0AF` |
| Windows Setup | passed | `Perfect!`، version `1.1.0.30`، signer `1424F286…BA24` و DigiCert timestamp؛ روی runner تمیز نصب و rerun شد |
| Windows portable | passed | 41 entry/37 file، `perfect.exe` و runtime کامل؛ صفر MSIX/CER/checksum/log/ZIP تو‌در‌تو |
| Downloaded bytes | passed | هر سه SHA-256 محلی دقیقاً با digestهای GitHub و Release notes برابر بود |
| Portable signing recovery | passed | synthetic JKS/PFX round-trip؛ private-key possession، wrong password/tamper/non-empty rejection، DACL rollback and no real signing-root access |
| Focused AI contracts | passed | 33 tests؛ history hydration، proposal recovery، bounded context and client behavior |
| Edge source type-check | passed | Deno check |
| Final Edge deployment | passed live | `perfect-agent` v3؛ `ACTIVE`؛ `verify_jwt=true`؛ hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b`؛ unauthenticated 401 |
| Final signed Android build/install-over | passed | APK `1.1.0+2004`؛ cert `144E87CB…F49B0AF`؛ install-over preserved package UID/data/widget identity |
| Final exact-SHA CI/artifacts | passed | run `#22` on `fea3ddc`؛ Android `1.1.0+2022`، MSIX `1.1.0.22` and portable Windows independently inspected |
| Windows signer migration | passed | provisioner synthetic PASS؛ legacy self-signed `CA=true` signer replaced by a self-signed `CA=false` end entity، thumbprint `1424F286C0DCACF36701D4C1AF0C0D830F01BA24`؛ rerun identity stable |
| True Windows install-over | passed | run `#21`: `1.1.0.20 → 1.1.0.21`؛ package family and exact LocalState marker preserved |

## Latest live AI/backend proof

| Check | Result | Evidence |
|---|---|---|
| AI metadata hardening migration | passed live | migration `20260730210000` در `schema_migrations` ثبت شد؛ safe metadata=true، `api_key`=false، depth 34=false |
| Metadata guard privilege boundary | passed live | `anon` و `authenticated` برای `perfect_ai_metadata_is_safe(jsonb)` فاقد EXECUTE هستند |
| Edge Function deployment | passed live | `perfect-agent` v3، status `ACTIVE`، `verify_jwt=true`، bundle hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b` |
| Edge authentication boundary | passed live | POST بدون Authorization به Function زنده پاسخ 401 با `UNAUTHORIZED_NO_AUTH_HEADER` گرفت |
| Focused AI/migration contracts | passed | 15/15 Flutter contracts؛ Deno check و backend guard suite نیز سبز |
| Provider smoke | blocked safely | کلید AvalAI قبلی compromised فرض می‌شود و در Supabase تنظیم نشده؛ تا rotate شدن، هیچ درخواست provider با آن اجرا نمی‌شود |
| Private planner context migration | passed live | `20260730220000` recorded؛ authenticated execute، anon denial، direct planner SELECT denial، owner result and bounded limit pass |

## Latest tablet composition proof

| Check | Result | Evidence |
|---|---|---|
| Tablet compact portrait | passed + visually inspected | `test/goldens/perfect_tablet_rail_compact.png` |
| Tablet expanded portrait | passed + visually inspected | `test/goldens/perfect_tablet_rail_expanded.png` |
| Tablet short landscape | passed + visually inspected | `test/goldens/perfect_tablet_landscape.png` at `1200×800` |
| Responsive reflow | passed | 768 stack؛ 900/1024 two-pane؛ 200% text stack؛ rail animation/persistence؛ AI/capture no-overlap |

## Requirement-by-requirement completion audit

| ID | Requirement | Authoritative evidence inspected | Outcome |
|---|---|---|---|
| R1 | Flutter Android + Windows | Android install/runtime ledger؛ exact-HEAD run `#22`؛ final artifacts؛ live portable auth resize | **partial runtime / artifact pass** — signed builds، install-over and Windows auth wide/short/compact resize/scroll/title/icon pass؛ signed-in workspace، hover/jank and Android main workspace remain unobserved |
| R2 | private local-first cross-device Supabase sync | 265 tests؛ eight migrations remote/local؛ live owner/RLS/RPC/Auth/replay/cursor/context smoke | **partial** — backend و local-first/retry contracts پاس‌اند؛ convergence واقعی Android↔Windows روی دو نصب اجرا نشده است |
| R3 | planner options and hostile scenarios | 265-test suite، workspace interaction suite، Android task/habit/widget journeys | **passed for implemented source/test scope** — exact alarm/reboot/OEM behavior و همهٔ device-specific notification paths هنوز proof فیزیکی ندارند |
| R4 | final Perfect identity across app/Android/Windows | Day Compass source/master؛ Pixel Launcher؛ hosted identity؛ final portable title bar | **passed for assets/artifacts؛ partial shell runtime** — Android launcher and Windows title-bar icon pass؛ Explorer/taskbar remain unobserved |
| R5 | deliberate portrait/landscape/expanded experience | Workspace tests/goldens؛ Android screenshots؛ live Windows auth resize | **partial runtime** — final auth surface passes restored/maximized، `832×414` and `540×414` with scrolling؛ signed-in main workspace، hover and jank remain unobserved |
| R6 | precise plan and durable work record | task docs، requirement/preservation ledgers، CI/artifact evidence in this file | **current** — runs `#20`–`#22`، signer migration، artifact identities، install-over، auth GUI and remaining runtime limits recorded |
| R7 | preserve data/auth/contracts | additive migration history/replay؛ legacy compatibility tests؛ owner gate and anon denial | **passed for compatibility contract** — هیچ destructive migration گزارش نشده؛ two-install convergence جداگانه در R2 باز است |
| R8 | quality, resilience and performance gate | analyzer، 265 tests، exact-HEAD run `#22`، artifact inspection، live auth resize، Critics closure | **partial whole-product runtime proof** — automated/artifact/auth-resize gates سبزند؛ signed-in cross-device، hover/jank and physical Android/OEM proof بازند |

## Automated checks

| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Format | `dart format lib test` | passed | ۱۲۳ فایل؛ پس از آخرین اصلاح فقط یک فایل test format شد |
| Static analysis | `flutter analyze --no-pub` | passed | `No issues found` |
| Full test suite | `flutter test --no-pub --reporter compact` | passed | ۲۶۵ تست؛ domain/data/sync/UI/editor/accessibility/golden/widget/privacy/recovery/reminder/AI/startup/signing/release concurrency |
| Workspace interaction suite | `flutter test --no-pub test/presentation/perfect_workspace_page_test.dart` | passed | ۴۴ تست؛ phone/tablet/Windows، 200% text، RTL، short landscape، wide inspector، shortcut/context |
| Private release contract | focused Flutter test | passed | ۷/۷؛ semantic/epoch/run mapping، signer migration and install-over guards |
| Workflow queue lint boundary | actionlint 1.7.12 with scoped filter + GitHub service | passed | only exact old-actionlint `concurrency.queue` diagnostic is scoped؛ GitHub accepted and executed the workflow on run `#20` |
| Focused AI suite | focused Flutter tests | passed | ۳۳ pass؛ history/context/proposal/client behavior |
| Edge source check | `deno check supabase/functions/perfect-agent/index.ts` | passed | no type errors |
| Adaptive secondary surfaces | `flutter test --no-pub -r expanded test/presentation/planner_secondary_surfaces_adaptive_test.dart` | passed | dialog ویندوز و bottom sheet موبایل، Escape و lifecycle |
| Android release compile | `flutter build apk --release --no-pub` | passed | APK نهایی 63.9MB؛ Gradle `assembleRelease` موفق؛ build محلی عمداً secret خصوصی ندارد |
| Dependency currency | `flutter pub outdated --no-dev-dependencies` | passed with caveat | تمام dependencyهای مستقیم up-to-date؛ چند transitive نسخهٔ جدیدتر ولی غیرقابل resolve با graph فعلی |
| Diff hygiene | `git diff --check` | passed | فقط هشدار line-ending ویندوز؛ whitespace error ندارد |

## Hosted CI and artifact proof

| Check | Method | Result | Evidence |
|---|---|---|---|
| Exact hosted revision | Actions metadata | passed | run `30641054596` (`#22`) روی SHA `fea3ddc7dd16741e1936a5b61de0b4785c079e67` است |
| Overall private workflow | GitHub Actions run API | passed | workflow `Perfect private CI` با conclusion `success`؛ Allocate، Quality/Android و Windows هر سه success |
| Quality and Android job | Actions job `91190822424` | passed | format، analyze، 265/265 tests، Android signing/build/verification/upload همگی success |
| Hosted Android artifact | Actions artifact + independent package inspection | passed | `perfect-1.1.0-build.2022-android-stable-private-configured-private`؛ `1.1.0+2022`، package `com.k1tvkli2003.perfect`، label `Perfect!`، سه ABI، v2، SHA manifest معتبر، signer ثابت `144E87CB…F49B0AF` |
| Windows desktop job | Actions job `91190822447` | passed | Windows goldens، desktop build، portable/MSIX upload and `1.1.0.21 → 1.1.0.22` install-over success |
| Hosted Windows portable | run `#22` download + 37-file manifest + Computer Use | passed with signed-in limit | 37/37 hashes؛ correct Perfect! title/icon؛ restored/maximized and live `832×414`/`540×414` resize؛ short-height scroll kept every auth action reachable. Signed-in workspace، hover/jank not exercised |
| Signed private MSIX | artifact download + manifest/CMS/block inventory | passed | run `#22` version `1.1.0.22`، same identity/publisher، `CA=false` signer `1424F286…BA24`، 137 entries and hashes valid |
| Signing provision/recovery | synthetic provisioner + backup/hash + rerun | passed | Windows root/leaf roles valid، end-entity private-key proof passes، backup hash valid and rerun leaves both Android and Windows identities stable |
| Windows install-over | run `#22` job `91190822447` | passed | exact notice: `MSIX install-over passed: 1.1.0.21 -> 1.1.0.22; package family and LocalState were preserved.` |
| Run `#22` artifact integrity | independent artifact download | passed | Android `1.1.0+2022`، MSIX `1.1.0.22` with same `CA=false` signer and 137 entries، portable 37/37؛ all SHA manifests have zero mismatch |

## Final private Android artifact and runtime

| Check | Method | Result | Evidence |
|---|---|---|---|
| Artifact identity | `aapt2 dump badging` | passed | `Perfect!` / `com.k1tvkli2003.perfect` / `1.1.0+2004`؛ minSdk 24، targetSdk 36 |
| Artifact integrity | SHA-256 + file length | passed | `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`؛ ۶۹٬۱۸۹٬۳۵۶ bytes |
| ABI coverage | APK badging/native inventory | passed | `arm64-v8a`، `armeabi-v7a` و `x86_64` |
| Alignment/signature | `zipalign -c` + `apksigner verify --verbose --print-certs` | passed | zipalign صحیح؛ APK Signature Scheme v2؛ cert SHA-256 `144E87CB67A9074EBC11CFED26A96EE1ACE697A861C2EABD77C4203A4F49B0AF` |
| Install-over continuity | `adb install -r` over `1003`, then over `2004` | passed | UID `10213`، `firstInstallTime=2026-07-30 20:02:10` و `/data/user/0/com.k1tvkli2003.perfect` ثابت ماندند |
| Widget upgrade/reboot continuity | launcher + `dumpsys appwidget` | passed | binding `appWidgetId=5` پس از update و reboot باقی ماند؛ Quick Add popup و signed-out guard درست‌اند |
| Authenticated session continuity | pre/post session state | not proven | نصب پیش از آزمون signed out بود؛ حفظ session لاگین ادعا نمی‌شود |
| Runtime/splash/logcat | API 35 x86_64 emulator screenshots + logcat | passed with performance caveat | splash بومی Day Compass و app runtime صحیح؛ crash/`AndroidRuntime`/`E/flutter` نبود |
| Cold-start timing | repeated `am start -W` / trace | inconclusive for supported hardware | روی emulator 2GB/SwiftShader حدود ۵٫۱–۶٫۵ ثانیه و پس از reboot پرنویز حدود ۱۱–۱۲ ثانیه؛ engine/plugin/software-render path غالب است و گوشی فیزیکی لازم است |

## Historical Android artifact and runtime

| Check | Method | Result | Evidence |
|---|---|---|---|
| Package identity | `aapt2 dump badging` | passed | package `com.k1tvkli2003.perfect`، label `Perfect!`، minSdk 24، targetSdk 36 |
| Signature structure | `apksigner verify --verbose --print-certs` | passed with local-signing caveat | APK با v2 معتبر است؛ چون secret خصوصی تزریق نشده، local release با Android Debug certificate امضا شده است |
| Install/cold start | `adb install -r` + `am start -W` on `emulator-5554` API 35 | passed | cold launch موفق؛ `MainActivity` focused؛ crash یا `E/flutter` در logcat نبود |
| Release state | `dumpsys package` after reinstall | passed | `pkgFlags` فاقد `DEBUGGABLE`؛ نسخه `1.0.0+1` |
| Portrait/landscape | چرخش host و screenshot | passed | configuration surface بدون overlap؛ محتوای landscape با swipe تا انتها قابل دسترسی |
| Final launcher identity | Pixel Launcher API 35 پس از uninstall/reinstall | passed | نام `Perfect!` و Day Compass با شش ماژول پاستلی و مرکز تیره، در adaptive tile آرام `#FFF3E8` درست و خوانا نمایش داده شدند؛ control شفاف روی Pixel Launcher فضای خالی را مشکی می‌کرد، بنابراین fill فقط برای adaptive platform mask عمدی است |
| Preconfigured connection | fresh app data + cold start | passed | build مستقیم روی AuthPage پروژهٔ خصوصی باز شد و ConfigurationPage را نشان نداد |
| Widget discovery | Pixel Launcher widget picker | passed | `Perfect! Today` با توضیح private/resizable و اندازهٔ اولیهٔ 2×2 |
| Widget resize classes | host resize small → tall → wide → large | passed | چهار family دقیق با UI متفاوت؛ `110×110`، `110×180`، `220×110` و `260×220`؛ large اکشن `Open Today` را اضافه می‌کند |
| Widget collection scrolling | ۱۲ ردیف runtime و ۸۰ ردیف contract test | passed | `ListView` بومی در هر چهار family اسکرول می‌شود؛ عنوان‌های بلند و فارسی/RTL تست شده‌اند |
| Widget direct four-state cycle | چهار tap روی `Workout` | passed | semantics واقعی: `Empty → Done → Not done → 50% → Empty` |
| Widget durable queue | بازرسی SharedPreferences همان harness | passed | چهار action با `queue_sequence`های ۱ تا ۴ و state/percent متناظر ثبت شدند |
| Widget deep link | tap روی `Open Today` | passed | `Perfect/.MainActivity` foreground شد؛ crash نداشت |
| Cleanup | حذف fixture و نصب مجدد release | passed | دادهٔ مصنوعی widget پاک شد؛ release غیر-debuggable وضعیت نهایی emulator است |
| Private backup boundary | manifest/rules + installed `pkgFlags` | passed | cloud و device-transfer برای database/shared preferences/files بسته‌اند؛ `ALLOW_BACKUP` در package نصب‌شده وجود ندارد |

## Visual evidence

- `assets/perfect-runtime-portrait.png`
- `assets/perfect-runtime-landscape.png`
- `assets/perfect-runtime-landscape-scrolled.png`
- `assets/perfect-day-compass-app-drawer.png`
- `assets/perfect-auth-configured-final.png`
- `assets/perfect-widget-picker.png`
- `assets/perfect-widget-home-2x2.png`
- `assets/perfect-widget-home-resized.png`
- `assets/perfect-widget-populated3.png`
- `assets/perfect-widget-scrolled-end.png`
- `assets/perfect-widget-cycle-partial.png`
- `build/private-update-proof/perfect-native-splash-2004.png`
- `build/private-update-proof/perfect-final-runtime-2004.png`
- `build/private-update-proof/perfect-widget-host-attempt2.png`
- `build/private-update-proof/perfect-quick-add-dialog.png`
- `build/private-update-proof/perfect-widget-after-reboot-proof.png`
- `test/goldens/perfect_compact.png`
- `test/goldens/perfect_expanded.png`

شواهد launcher قدیمی `assets/perfect-launcher-icon.png` و
`assets/perfect-launcher-pastel-final.png` فقط در تاریخ تصمیم نگه‌داری می‌شوند
و evidence هویت نهایی Day Compass نیستند.

## Defects caught and closed during the final gate

- دو use-after-dispose در percentage editor و Habit checklist editor؛ controllerها به lifecycle سطح منتقل یا حذف شدند.
- `Archive` و `Insights` از callbackای در `setState` استفاده می‌کردند که `Future` برمی‌گرداند؛ init/reload اکنون synchronous state assignment دارند.
- shortcut فوکوس ویندوز پس از modal و هنگام فوکوس quick capture پایدار شد.
- تست right-click آیتم recurring، آیتم Scheduled را اشتباهاً در Inbox جست‌وجو می‌کرد؛ مسیر واقعی فیلتر و اسکرول تست شد.
- Orbit در قاب کوتاه/متن 200٪، wordmark در RTL، touch targetهای 48dp، contrast و reduced-motion سخت‌گیری شدند.
- AuthPage برای Supabase project معتبر از نظر قالب اما اشتباه، مسیر امن تغییر اتصال دارد؛ client قبلی dispose می‌شود و pair جدید به‌صورت یک مقدار atomic و device override پایدار ذخیره می‌شود.
- خاموش‌کردن reminder همهٔ notification IDهای قبلی را cancel می‌کند؛ شکست cancel برای retry نگه‌داری و در UI اعلام می‌شود.
- سقف ۹۶ reminder دیگر silent نیست: نزدیک‌ترین موارد با ترتیب deterministic انتخاب و تعداد باقی‌مانده همراه capacity در UI گزارش می‌شود.
- صف native ویجت eviction خاموش ندارد؛ stateهای مطلق هر owner/entity/day compact، actionهای اعمال‌شده با ack side-channel پاک و overflow قبل از تغییر snapshot رد و ثبت می‌شود.
- هشت PNG موقت failure-golden پیش از stage به‌صورت دقیق پاک شدند.
- Day Compass انتخاب نهایی شد. pipeline تکرارپذیر `tool/generate_day_compass_assets.py` chroma/spill را حذف، edgeهای premultiplied را پاک، master شفاف ۵۱۲×۵۱۲، monochrome، Android derivatives و Windows ICO با ۹ اندازه تولید می‌کند. master هفت component مستقل، گوشه‌های کاملاً شفاف و alpha bounds برابر `(43, 8, 468, 504)` دارد.
- Android adaptive icon نمی‌تواند در فاصله‌های mark واقعاً شفاف بماند؛ control شفاف در Pixel Launcher آن فاصله‌ها را مشکی کرد. fill پاستلی `#FFF3E8` فقط در adaptive tile استفاده شد؛ master، legacy PNG و Windows ICO شفاف باقی ماندند.
- replay ویجت دیگر برای ترتیب به wall clock وابسته نیست: `queue_sequence` یکنواخت native منبع اصلی است و rollback ساعت/malformed action/DB replay با تست پوشش دارد.
- اجرای هم‌زمان foreground و WorkManager نیز دیگر race ندارد: Drift schema v2 یک ساعت ترتیب local-only نگه می‌دارد و claim اتمیک SQLite پیش از هر mutation انجام می‌شود. تست با دو `NativeDatabase.createInBackground` روی یک فایل، sequence بالاتر را برای one-off و recurring حتی با ساعت عقب‌رفته و mutation ID تازه حفظ می‌کند؛ migration v1→v2 نیز دادهٔ قبلی را نگه می‌دارد.
- Windows window restore اکنون DPI/work-area/multi-monitor-aware است، minimum به `520×420` کاهش یافته، manifest روی PerMonitorV2 است و artifact portable باید VC runtime DLLها و `SHA256SUMS` را داشته باشد.

## Explicit limits

- build محلی Windows ممکن نیست چون این میزبان Visual Studio و workload «Desktop development with C++» ندارد. hosted CI portable/MSIX را ساخته و portable نهایی دانلودشده در GUI واقعی با title/icon، maximize/restore، resizeهای wide/short/compact و scroll بررسی شده است؛ signed-in workspace، hover/focus semantics، animation continuity and jank هنوز بررسی نشده‌اند.
- پروژهٔ `evyjrbwibwrdkjakooor` سالم است و هشت migration هم‌نسخهٔ local/remote را پذیرفته است. migration هشتم `20260730220000` authenticated execution و owner/limit bounding را پاس می‌کند؛ anon و direct planner SELECT همچنان بسته‌اند. شواهد replay/cursor/zero-residue مربوط به چهار migration پایه نیز معتبر باقی مانده‌اند. تنها convergence واقعی Android↔Windows هنوز اثبات نشده است.
- تست Android روی emulator API 35 انجام شد، نه گوشی فیزیکی؛ زمان startup به‌دلیل x86_64/2GB/SwiftShader و ANRهای سیستم نمایندهٔ سخت‌افزار هدف نیست و بهبود عملکرد ادعا نمی‌شود.
- APK نهایی `1.1.0+2004` با private certificate نهایی امضا شده است؛ سطر debug-certificate در بخش Historical فقط به artifact قدیمی اشاره دارد.
- signed MSIX `1.1.0.20` در run `#20` baseline معتبر است؛ run `#21` همان lineage را به `1.1.0.21` ارتقا داد و package family/LocalState را حفظ کرد.
- Day Compass نهایی در Android launcher و Windows title-bar runtime اثبات شده است. Windows ICO به‌صورت ساختاری ۹-frame و شفاف است؛ Explorer/taskbar rendering هنوز مشاهده نشده است.
- Flutter 3.44 دربارهٔ مهاجرت آیندهٔ Kotlin plugin در `home_widget` و `flutter_timezone` هشدار می‌دهد. هر دو dependency مستقیم در آخرین نسخهٔ قابل resolve هستند؛ این هشدار شکست فعلی نیست و مالکیت fix در upstream است.
- تصاویر Android موجود، launcher/widget و Auth/Configuration را اثبات می‌کنند؛ signed-in Orbit Day main workspace روی phone/tablet runtime نشده است.
- signed-in widget Quick Add، authenticated session retention، Android↔Windows convergence، positive AI text/voice/proposal-apply با provider key rotateشده و physical notification/OEM/reboot هنوز اجرا نشده‌اند.
- Supabase Auth API ورود حساب خصوصی را با credential جدید و همان UUID موجود در `planner_owner_profiles` تأیید کرده است؛ این اثبات API جایگزین اجرای UI نسخهٔ ریلیز بعدی روی Android/Windows نیست.

## 2026-08-05 Home / Day Compass modernization gate

| Check | Method | Result | Evidence / limit |
|---|---|---|---|
| Static analysis | `flutter analyze` | passed | `No issues found` after the final Day Compass and compact dock composition |
| Full Flutter suite | `flutter test` | passed | 352/352 tests across data، sync، AI، feedback، editor، responsive workspace، branding، accessibility and release contracts |
| Responsive Home suite | `flutter test test/presentation/perfect_workspace_page_test.dart` | passed | 51/51 including phone/tablet/Windows، intermediate resize، short landscape، RTL، 200% text، final-row scroll reachability and goldens |
| Day Compass panel contract | bounds + goldens | passed | circular Orbit is the primary tablet/Windows instrument; duplicate `Today’s runway` was removed and the dial stays adjacent to Day Stream without overlap |
| Compact composer continuity | widget bounds + Android screenshot | passed | collapsed Quick Capture reserves a transparent slot above the glass footer; it has no background rail and no longer overlays Today rows |
| Sync Cloud contract | focused tests + Android screenshot | passed | `Synced` green، `Syncing/Retrying` yellow and `Sync issue` red use distinct cloud icons، visible concise labels، semantics and a 48dp target |
| Secret-free Android runtime | `lib/dev/perfect_live_preview.dart` on `Codex_API35` / `emulator-5556` | passed | debug APK installed، cold launch completed in 4269ms، no `FATAL EXCEPTION`، `AndroidRuntime` or `E/flutter`; screenshot: `screenshots/perfect-live-preview-latest.png` |
| API 37 emulator attempt | `Gauss_QA_API37` | environment failure, replaced | system `mapper.ranchu`/`system_server` crashed while Gradle had already built the APK; the same APK installed and ran on API 35 with SwiftShader. This is not counted as app runtime proof for API 37. |

The live preview is deterministic local development evidence, not a signed private
release and not authenticated cross-device convergence proof. Release signing،
session retention and owner Supabase convergence remain separate gates.
