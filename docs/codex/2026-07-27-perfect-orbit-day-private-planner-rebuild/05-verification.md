# Verification

## Summary

- Result: passed locally with explicit environment limits
- Last verified: 2026-07-30T04:40:00+03:30
- Final Android artifact under test: `build/app/outputs/flutter-apk/app-release.apk`
- APK SHA-256: `174DF8AB753D40F1ED4CD693723212703952F55AE186E642D61D786ECDE24A89`

این سند بین «اثبات اجرا»، «بررسی ایستا» و «بررسی مسدودشده» فرق می‌گذارد. اپ روی Android و میزبان واقعی launcher اجرا شده است؛ اجرای محلی Windows و همگرایی زندهٔ Supabase به‌ترتیب به‌علت نبود Visual Studio C++ و credential خصوصی ممکن نبودند و به‌عنوان pass گزارش نمی‌شوند.

## Automated checks

| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Format | `dart format lib test` | passed | ۱۲۳ فایل؛ پس از آخرین اصلاح فقط یک فایل test format شد |
| Static analysis | `flutter analyze --no-pub` | passed | `No issues found` |
| Full test suite | `flutter test --no-pub -r expanded` | passed | ۱۶۲ تست؛ domain/data/sync/UI/editor/accessibility/golden/widget/privacy/recovery/reminder capacity |
| Workspace interaction suite | `flutter test --no-pub -r expanded test/presentation/perfect_workspace_page_test.dart` | passed | ۳۴ تست؛ 320dp، text 200%، RTL، landscape کوتاه، desktop shortcut/context، recurrence/habit/recovery |
| Adaptive secondary surfaces | `flutter test --no-pub -r expanded test/presentation/planner_secondary_surfaces_adaptive_test.dart` | passed | dialog ویندوز و bottom sheet موبایل، Escape و lifecycle |
| Android release compile | `flutter build apk --release --no-pub` | passed | APK نهایی 63.0MB؛ Gradle `assembleRelease` موفق |
| Dependency currency | `flutter pub outdated --no-dev-dependencies` | passed with caveat | تمام dependencyهای مستقیم up-to-date؛ چند transitive نسخهٔ جدیدتر ولی غیرقابل resolve با graph فعلی |
| Diff hygiene | `git diff --check` | passed | فقط هشدار line-ending ویندوز؛ whitespace error ندارد |

## Android artifact and runtime

| Check | Method | Result | Evidence |
|---|---|---|---|
| Package identity | `aapt2 dump badging` | passed | package `com.k1tvkli2003.perfect`، label `Perfect!`، minSdk 24، targetSdk 36 |
| Signature structure | `apksigner verify --verbose --print-certs` | passed with local-signing caveat | APK با v2 معتبر است؛ چون secret خصوصی تزریق نشده، local release با Android Debug certificate امضا شده است |
| Install/cold start | `adb install -r` + `am start -W` on `emulator-5554` API 35 | passed | cold launch موفق؛ `MainActivity` focused؛ crash یا `E/flutter` در logcat نبود |
| Release state | `dumpsys package` after reinstall | passed | `pkgFlags` فاقد `DEBUGGABLE`؛ نسخه `1.0.0+1` |
| Portrait/landscape | چرخش host و screenshot | passed | configuration surface بدون overlap؛ محتوای landscape با swipe تا انتها قابل دسترسی |
| Launcher identity | Pixel Launcher app drawer | passed | نام `Perfect!` و آیکون انتخاب‌شدهٔ orbit/check در host واقعی |
| Widget discovery | Pixel Launcher widget picker | passed | `Perfect! Today` با توضیح private/resizable و اندازهٔ اولیهٔ 2×2 |
| Widget resize classes | host resize 2×2 → expanded | passed | نسخهٔ compact و expanded متفاوت؛ expanded اکشن `Open Today` را اضافه می‌کند |
| Widget collection scrolling | ۹ ردیف مصنوعی local-only روی debug verification install | passed | اسکرول native از `Focus deep work` تا آخرین `Inbox cleanup` در host واقعی |
| Widget direct four-state cycle | چهار tap روی `Workout` | passed | semantics واقعی: `Empty → Done → Not done → 50% → Empty` |
| Widget durable queue | بازرسی SharedPreferences همان harness | passed | چهار action با `queue_sequence`های ۱ تا ۴ و state/percent متناظر ثبت شدند |
| Widget deep link | tap روی `Open Today` | passed | `Perfect/.MainActivity` foreground شد؛ crash نداشت |
| Cleanup | حذف fixture و نصب مجدد release | passed | دادهٔ مصنوعی widget پاک شد؛ release غیر-debuggable وضعیت نهایی emulator است |
| Private backup boundary | manifest/rules + installed `pkgFlags` | passed | cloud و device-transfer برای database/shared preferences/files بسته‌اند؛ `ALLOW_BACKUP` در package نصب‌شده وجود ندارد |

## Visual evidence

- `assets/perfect-runtime-portrait.png`
- `assets/perfect-runtime-landscape.png`
- `assets/perfect-runtime-landscape-scrolled.png`
- `assets/perfect-launcher-icon.png`
- `assets/perfect-widget-picker.png`
- `assets/perfect-widget-home-2x2.png`
- `assets/perfect-widget-home-resized.png`
- `assets/perfect-widget-populated3.png`
- `assets/perfect-widget-scrolled-end.png`
- `assets/perfect-widget-cycle-partial.png`
- `test/goldens/perfect_compact.png`
- `test/goldens/perfect_expanded.png`

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

## Explicit limits

- اجرای محلی Windows مسدود است چون این میزبان Visual Studio و workload «Desktop development with C++» ندارد. source/runner/shortcut/DPI contracts و تست‌های Flutter پوشش دارند؛ artifact نهایی باید در hosted Windows CI ساخته شود.
- migration/RLS/RPC روی Supabase خصوصی اجرا نشد چون URL/key/account مالک در محیط موجود نیست. تست‌های local store، outbox، conflict، replay، owner isolation و sync gateway پاس‌اند، اما cross-device convergence زنده هنوز اثبات محیطی ندارد.
- تست Android روی emulator API 35 انجام شد، نه گوشی فیزیکی.
- local release عمداً بدون secret با debug certificate امضا شد. workflow برای secret-backed private signing آماده است؛ نبود secrets نباید با امضای production اشتباه گرفته شود.
- Flutter 3.44 دربارهٔ مهاجرت آیندهٔ Kotlin plugin در `home_widget` و `flutter_timezone` هشدار می‌دهد. هر دو dependency مستقیم در آخرین نسخهٔ قابل resolve هستند؛ این هشدار شکست فعلی نیست و مالکیت fix در upstream است.
- commit/push و CI برای SHA نهایی در مرحلهٔ بعد همین task ثبت می‌شوند؛ تا قبل از ثبت run همان SHA، hosted result ادعا نمی‌شود.
