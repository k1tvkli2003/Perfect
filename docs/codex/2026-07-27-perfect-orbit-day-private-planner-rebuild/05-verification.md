# Verification

## Summary

- Result: partial
- Interpretation: the integrated Flutter/AI/backend source passes its local automated matrix and the final private Android artifact has signed install-over/runtime proof. Exact-SHA hosted CI, signed Windows MSIX update and real two-device convergence remain open.
- Last verified: 2026-07-31T00:35:00+03:30
- Final Android artifact under test: `build/private-update-proof/perfect-1.1.0+2004.apk`
- Current final APK SHA-256: `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`
- Hosted commit: `d56455b9699b130ca2665d59853bac2f647aae2a` on `main` and `origin/main`
- Hosted CI: [run `30519295088`](https://github.com/k1tvkli2003/Perfect/actions/runs/30519295088), conclusion `success`

این سند بین «اثبات اجرا»، «اثبات hosted build»، «بررسی ایستا» و «بررسی در دسترس‌نبوده» فرق می‌گذارد. شواهد run `30519295088` تاریخی‌اند. source جاری analyzer و ۲۶۲ تست را پاس کرده، migration امن context و Function v3 زنده‌اند و APK `1.1.0+2004` با هویت نهایی install-over شده است؛ CI همان SHA و Windows update هنوز باید جداگانه اثبات شوند.

## Current integrated source proof

| Check | Result | Evidence |
|---|---|---|
| Flutter static analysis | passed | `flutter analyze --no-pub` → no issues |
| Full Flutter suite | passed | `flutter test --no-pub --reporter compact` → 262/262 |
| Workspace UI/adaptive suite | passed | 44/44؛ expanded/short/wide Windows، tablet، 200% text and resize paths |
| Private release continuity contract | passed | 5/5؛ `1.1.0+2000` base and next run #4 mapping to Android `2004` |
| Release queue and artifact contract | passed locally / service pending | `queue: max` serializes same-ref builds؛ Android placeholder is `VERSION_CODE`؛ GitHub accepts/rejects the new queue syntax authoritatively after push |
| actionlint compatibility | passed with one scoped compatibility ignore | v1.7.12 predates `concurrency.queue`؛ only the exact new-key diagnostic is ignored، all other diagnostics remain fatal |
| Windows private install/recovery docs | passed | thumbprint check + `LocalMachine\TrustedPeople` + `Add-AppxPackage`؛ encrypted offline signing backup/restore/hash/fingerprint checklist |
| Portable signing recovery | passed | synthetic JKS/PFX round-trip؛ private-key possession، wrong password/tamper/non-empty rejection، DACL rollback and no real signing-root access |
| Focused AI contracts | passed | 33 tests؛ history hydration، proposal recovery، bounded context and client behavior |
| Edge source type-check | passed | Deno check |
| Final Edge deployment | passed live | `perfect-agent` v3؛ `ACTIVE`؛ `verify_jwt=true`؛ hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b`؛ unauthenticated 401 |
| Final signed Android build/install-over | passed | APK `1.1.0+2004`؛ cert `144E87CB…F49B0AF`؛ install-over preserved package UID/data/widget identity |
| Final exact-SHA CI/artifacts | pending | Android، Windows portable and signed MSIX evidence not yet recorded |

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
| R1 | Flutter Android + Windows | Android install/runtime ledger؛ CI run `30519295088`؛ hosted artifact API | **partial** — هر دو platform ساخته شدند و Android اجرا شد؛ Windows exe/runtime و signed installer اثبات نشده‌اند |
| R2 | private local-first cross-device Supabase sync | 256 tests؛ eight migrations remote/local؛ live owner/RLS/RPC/Auth/replay/cursor/context smoke | **partial** — backend و local-first/retry contracts پاس‌اند؛ convergence واقعی Android↔Windows روی دو نصب اجرا نشده است |
| R3 | planner options and hostile scenarios | full test suite، workspace interaction suite، Android task/habit/widget journeys | **passed for implemented source/test scope** — exact alarm/reboot/OEM behavior و همهٔ device-specific notification paths هنوز proof فیزیکی ندارند |
| R4 | final Perfect identity across app/Android/Windows | selected Day Compass source/master؛ asset generator؛ Android Pixel Launcher screenshot؛ adaptive/legacy/monochrome resources؛ ۹-frame Windows ICO | **passed locally / hosted Windows pending** — هویت نهایی انتخاب و سیم‌کشی شده و Android runtime پاس است؛ Windows runtime/hosted artifact تازه بعد از push بررسی می‌شود |
| R5 | deliberate portrait/landscape/expanded experience | 44 Workspace tests/goldens؛ Android portrait/landscape screenshots؛ historical Windows hosted compile | **partial** — current phone/tablet/expanded Windows compositions pass local tests and visual inspection؛ expanded Windows روی executable نهایی مشاهده نشده است |
| R6 | precise plan and durable work record | task docs، requirement/preservation ledgers، selection ledger، CI evidence in this file | **active/current** — انتخاب Day Compass و proof محلی ثبت شده‌اند؛ SHA و run نهایی پس از push افزوده می‌شوند |
| R7 | preserve data/auth/contracts | additive migration history/replay؛ legacy compatibility tests؛ owner gate and anon denial | **passed for compatibility contract** — هیچ destructive migration گزارش نشده؛ two-install convergence جداگانه در R2 باز است |
| R8 | quality, resilience and performance gate | analyzer، 256 tests، 44 Workspace، 5 release، 33 AI، Critics closure، historical Android runtime/hosted baseline | **partial whole-product proof** — current local gates سبزند؛ final signed Android، Windows runtime/MSIX and physical Android/OEM proof بازند |

## Automated checks

| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Format | `dart format lib test` | passed | ۱۲۳ فایل؛ پس از آخرین اصلاح فقط یک فایل test format شد |
| Static analysis | `flutter analyze --no-pub` | passed | `No issues found` |
| Full test suite | `flutter test --no-pub --reporter compact` | passed | ۲۶۲ تست؛ domain/data/sync/UI/editor/accessibility/golden/widget/privacy/recovery/reminder/AI/startup/signing recovery |
| Workspace interaction suite | `flutter test --no-pub test/presentation/perfect_workspace_page_test.dart` | passed | ۴۴ تست؛ phone/tablet/Windows، 200% text، RTL، short landscape، wide inspector، shortcut/context |
| Private release contract | focused Flutter test | passed | ۵/۵؛ semantic/epoch/run mapping and install-over guards |
| Workflow queue lint boundary | actionlint 1.7.12 with scoped filter | passed with documented compatibility caveat | only exact `concurrency.queue` unknown-key diagnostic ignored؛ GitHub service validation pending push |
| Focused AI suite | focused Flutter tests | passed | ۳۳ pass؛ history/context/proposal/client behavior |
| Edge source check | `deno check supabase/functions/perfect-agent/index.ts` | passed | no type errors |
| Adaptive secondary surfaces | `flutter test --no-pub -r expanded test/presentation/planner_secondary_surfaces_adaptive_test.dart` | passed | dialog ویندوز و bottom sheet موبایل، Escape و lifecycle |
| Android release compile | `flutter build apk --release --no-pub` | passed | APK نهایی 63.9MB؛ Gradle `assembleRelease` موفق؛ build محلی عمداً secret خصوصی ندارد |
| Dependency currency | `flutter pub outdated --no-dev-dependencies` | passed with caveat | تمام dependencyهای مستقیم up-to-date؛ چند transitive نسخهٔ جدیدتر ولی غیرقابل resolve با graph فعلی |
| Diff hygiene | `git diff --check` | passed | فقط هشدار line-ending ویندوز؛ whitespace error ندارد |

## Hosted CI and artifact proof

| Check | Method | Result | Evidence |
|---|---|---|---|
| Exact hosted revision | `git rev-parse HEAD` / `git rev-parse origin/main` + Actions metadata | passed | هر دو ref برابر `d56455b9699b130ca2665d59853bac2f647aae2a`؛ run `30519295088` روی `main`/push همین SHA است |
| Overall private workflow | GitHub Actions run API | passed | workflow `Perfect private CI` در 2026-07-30T06:33:54Z با conclusion `success` تکمیل شد |
| Quality and Android job | Actions job `90795953303` | passed | format، analyze، test، restore signing configuration، Android APK build و artifact upload همگی success |
| Hosted Android artifact | Actions artifacts API | passed | `perfect-android-debug-fallback-configured-private-30519295088`، اندازهٔ 31,141,037 bytes، unexpired |
| Windows desktop job | Actions job `90795953300` | passed | Windows golden baselines، Windows desktop build و unpackaged artifact upload success |
| Hosted Windows artifact | Actions artifacts API | passed | `perfect-windows-x64-configured-private-30519295088`، اندازهٔ 15,410,209 bytes، unexpired |
| Signed private MSIX | job step + artifact inventory | skipped / not produced | `Preserve signed private Windows installer` skipped است و artifact امضاشده‌ای در run وجود ندارد؛ موفقیت unpackaged build نباید به‌عنوان signed MSIX تعبیر شود |

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

- اجرای محلی Windows ممکن نیست چون این میزبان Visual Studio و workload «Desktop development with C++» ندارد. hosted CI برای `d56455b` build و unpackaged artifact را با موفقیت ساخته است، اما اجرای exe و بررسی Explorer/taskbar/window هنوز انجام نشده است.
- پروژهٔ `evyjrbwibwrdkjakooor` سالم است و هشت migration هم‌نسخهٔ local/remote را پذیرفته است. migration هشتم `20260730220000` authenticated execution و owner/limit bounding را پاس می‌کند؛ anon و direct planner SELECT همچنان بسته‌اند. شواهد replay/cursor/zero-residue مربوط به چهار migration پایه نیز معتبر باقی مانده‌اند. تنها convergence واقعی Android↔Windows هنوز اثبات نشده است.
- تست Android روی emulator API 35 انجام شد، نه گوشی فیزیکی؛ زمان startup به‌دلیل x86_64/2GB/SwiftShader و ANRهای سیستم نمایندهٔ سخت‌افزار هدف نیست و بهبود عملکرد ادعا نمی‌شود.
- APK نهایی `1.1.0+2004` با private certificate نهایی امضا شده است؛ سطر debug-certificate در بخش Historical فقط به artifact قدیمی اشاره دارد.
- signed MSIX در run `30519295088` وجود ندارد: Windows unpackaged artifact موفق است، ولی مرحلهٔ حفظ installer امضاشده skipped شد. این دو خروجی معادل نیستند.
- Day Compass نهایی در Android runtime اثبات شده است. Windows ICO به‌صورت ساختاری ۹-frame و شفاف بررسی شده، اما نمایش آن در Explorer/taskbar/window روی executable واقعی هنوز به artifact hosted تازه و میزبان Windows دارای toolchain نیاز دارد.
- Flutter 3.44 دربارهٔ مهاجرت آیندهٔ Kotlin plugin در `home_widget` و `flutter_timezone` هشدار می‌دهد. هر دو dependency مستقیم در آخرین نسخهٔ قابل resolve هستند؛ این هشدار شکست فعلی نیست و مالکیت fix در upstream است.
- commit/push/CI برای `d56455b` ثبت و موفق‌اند، اما Day Compass و سخت‌گیری‌های تازهٔ widget/Windows هنوز در worktree نهایی‌اند. run `30519295088` نمی‌تواند این تغییرها را اثبات کند؛ run موفق SHA تازه باید جدا ثبت شود.
