# Handoff

## Outcome

Perfect! اکنون یک planner شخصی Flutter برای Android و Windows است؛ Web عمداً حذف شده است. محصول از یک فهرست ساده به Orbit Day واکنش‌گرا، Task/Habit editor بسیار قابل‌تنظیم، local-first Drift، sync خصوصی Supabase، recovery/conflict/archive، focus/reminder/insight و ویجت بومی Android تبدیل شده است.

گیت پایهٔ commit `d56455b` و CI خصوصی run `30519295088` سبز بود، اما فقط شاهد تاریخی است. پس از آن Day Compass، widget چهار-family، AI Dock/history/context، startup غیرمسدودکننده، retry خودکار Sync Cloud و expanded Windows واقعی یکپارچه شدند. وضعیت source جاری analyzer، ۲۶۲/۲۶۲ تست، Workspace ۴۴/۴۴، release contract پنج/پنج، AI متمرکز ۳۳ تست و Deno check را پاس کرده است. migration هشتمِ context امن نیز زنده و owner-scoped اثبات شده است؛ hosted CI همان SHA پس از push مرجع نهایی می‌شود.

build/install-over Android بسته شده و این handoff اکنون تا push/CI نهایی و اثبات Windows update باز است؛ Function v3 و auth boundary آن زنده و اثبات‌شده‌اند. انتخاب هویت دیگر باز نیست. Windows executable runtime، signed MSIX، provider smoke با کلید rotateشده و convergence نهایی روی دو نصب واقعی هنوز اثبات نشده‌اند.

## Product behavior delivered

- Task یک‌باره و recurring با برنامه‌ریزی، چند تاریخ ماهانه/سالانه، last day، flexible N-per-week/month، pause، exception، end/limit و carry cap.
- recovery انتخابی برای pending، miss، move-next و ask؛ تصمیم‌های معوق در Today گم نمی‌شوند.
- وضعیت چهارحالتهٔ Task در اپ و ویجت: `Empty → Done → Not done → % → Empty`.
- Habit با check، avoid، count، duration و checklist؛ هدف at-least/at-most، required/custom/percent success و backfill/undo روزانه.
- پروژه، area، label، category، priority، energy، estimate، time block، due date، checklist، custom typed property، formula و link.
- focus stopwatch/timer/Pomodoro با break policy؛ reminder، quiet hours، snooze، timezone و notification deep link.
- archive قابل‌بازیابی، conflict center، insight صادقانه و تنظیمات privacy/title برای widget.
- UI تطبیقی مستقل برای compact portrait، short landscape/medium و expanded Windows؛ navigation rail، inspector، shortcut و context menu بومی‌تر ویندوز.
- هویت نهایی Perfect! از wordmark منتخب، palette پاستلی، typography Plus Jakarta + Vazirmatn و نشان متقارن Day Compass ساخته شده است: شش ماژول نرم نارنجی/نعنایی/بنفش پیرامون مرکز تیره. source و Windows شفاف‌اند؛ Android adaptive به‌دلیل رفتار واقعی launcher فقط یک fill آرام `#FFF3E8` زیر mark دارد.

## Data and privacy contract

- Drift محلی source of truth است؛ UI برای شبکه متوقف نمی‌شود.
- outbox ترتیبی، mutation idempotency، tombstone، conflict review، bounded retry/backoff و cursor pull وجود دارند.
- schema/RPC v2 افزایشی است و `perfect_items` قبلی را حذف یا بازنویسی نمی‌کند.
- RLS و owner profile برای یک مالک خصوصی طراحی شده‌اند؛ service-role/secret key در client پذیرفته نمی‌شود.
- URL و publishable anon key می‌توانند روی هر نصب به‌صورت محلی تنظیم شوند؛ build-time config نیز اختیاری است.
- widget یک projection خصوصی است؛ tapها ابتدا در صف native پایدار می‌شوند و بعد با همان local planner reconcile می‌شوند.

## Verification snapshot

- `dart format lib test`: pass
- `flutter analyze --no-pub`: pass
- `flutter test --no-pub --reporter compact`: ۲۶۲/۲۶۲ pass
- Workspace UI suite: ۴۴/۴۴ pass
- release continuity contract: پنج/پنج pass
- focused AI suite: ۳۳ pass؛ Deno check pass
- Edge Function: v3 `ACTIVE`، `verify_jwt=true`، hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b`، unauthenticated 401 pass
- private release contract: ۵/۵؛ queue serialization و `VERSION_CODE` naming closed؛ GitHub queue syntax validation pending push
- `flutter build apk --release --build-name=1.1.0 --build-number=2004`: pass؛ private signed
- Final local APK SHA-256: `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`
- Android API 35 install-over/start/logcat for `1.1.0+2004`: pass؛ UID/data/widget binding حفظ شدند؛ session احراز‌شده به‌دلیل signed-out بودن اولیه قابل اثبات نبود
- launcher name/Day Compass icon: pass روی Pixel Launcher API 35؛ Windows runtime proof هنوز باز است
- widget picker/add/resize/scroll/deep-link/four-state queue: pass
- GitHub Actions run `30519295088` for `d56455b`: success
- hosted Android artifact: pass؛ `perfect-android-debug-fallback-configured-private-30519295088`
- hosted Windows unpackaged artifact: pass؛ `perfect-windows-x64-configured-private-30519295088`
- signed MSIX: skipped/not produced
- Windows local build/runtime: unavailable because Visual Studio C++ workload is missing
- live Supabase migration/RLS/RPC/Auth/context: pass؛ migration `20260730220000` owner/limit/privilege checks green؛ two-device Android↔Windows convergence هنوز اجرا نشده است

جزئیات و تصویرهای runtime در [05-verification.md](05-verification.md) ثبت شده‌اند.

## Private setup

1. migrationها، owner profile و `perfect://login-callback` روی پروژهٔ اصلی از قبل آماده‌اند؛ آن‌ها را دستی تکرار نکن.
2. artifactهای CI با `PERFECT_SUPABASE_URL` و `PERFECT_SUPABASE_PUBLISHABLE_KEY` از پیش متصل ساخته می‌شوند؛ فقط با همان حساب owner وارد شو. artifactهای run `30519295088` پایهٔ پیش از Day Compass هستند؛ artifact تازه پس از push نهایی مرجع خواهد بود.
3. اگر build محلی بدون define اجرا شد، می‌توان همان URL و publishable anon key را در configuration امن همان نصب وارد کرد.
4. برای signed artifact پایدار، secretهای تعریف‌شده در `.github/private-build-contract.yml` را فقط در GitHub Actions تنظیم کن؛ هیچ keystore/certificate یا key داخل repo قرار نده. run فعلی signed MSIX ندارد.
5. برای نصب MSIX خصوصی، thumbprint فایل CER را با Repository Variable تطبیق بده، آن را با دسترسی Administrator در `LocalMachine\TrustedPeople` import کن و سپس `Add-AppxPackage` را اجرا کن.
6. signing root را به‌صورت رمزنگاری‌شده آفلاین backup کن، رمز vault را جدا نگه دار و restore آزمایشی را با manifest hash و fingerprintها تأیید کن؛ GitHub Secrets backup نیست.

## Environment limits and follow-up proof

- Hosted Windows CI artifact commit `d56455b` را ساخته است؛ این build proof جای اجرای exe، Explorer/taskbar/window inspection یا signed MSIX را نمی‌گیرد. CI باید SHA تازهٔ expanded Windows/AI/startup/sync changes را نیز بسازد.
- migration/RLS و authenticated owner مثبت زنده پاس‌اند؛ offline→reconnect، conflict، realtime drop، دو session هم‌زمان و convergence باید روی Android و Windows artifact نهایی end-to-end ثبت شوند.
- Android proof فعلی emulator است؛ اگر گوشی واقعی متفاوت از API 35 هدف اصلی شد، notification permission، exact alarm policy، reboot reminder و OEM launcher widget هم روی همان دستگاه smoke-test شوند.
- هشدار future Kotlin migration از `home_widget` و `flutter_timezone` است؛ dependencyهای مستقیم فعلاً آخرین نسخهٔ قابل resolve هستند.

## Done

- هستهٔ planner local-first، Supabase owner/context contract، Orbit Day responsive UI، Perfect AI و Android Today widget در source و tests پیاده‌سازی شده‌اند.
- `d56455b` روی `main`/`origin/main` است و CI run `30519295088` Android و unpackaged Windows artifacts را با success ساخته است.
- Day Compass از میان conceptها انتخاب، به asset production شفاف تبدیل و در Android launcher/widget/notification و Windows ICO سیم‌کشی شده است.
- widget چهار family responsive، اسکرول native و چرخهٔ `Empty → Done → Not done → 50% → Empty` را با ترتیب native پایدار دارد.
- release audit نهایی queue، artifact naming، Windows private install trust و offline signing recovery را بسته است؛ release contract ۵/۵ باقی مانده است.

## Remaining

1. گیت کامل نهایی، commit/push `main` و CI همان SHA اجرا و artifactهای Android/Windows/MSIX بررسی شوند.
2. دو MSIX متوالی با همان certificate روی هم نصب و حفظ package data اثبات شود.
3. provider smoke فقط پس از تنظیم secret rotateشده اجرا شود.
4. convergence واقعی Android↔Windows با یک owner و دو نصب ثبت و startup Android روی سخت‌افزار فیزیکی profile شود.

## Verification

- نتیجهٔ کلی تا پیش از push نهایی `partial` است: Day Compass Android runtime، backend live checks و hosted build پایه پاس‌اند.
- جزئیات requirement-by-requirement، artifact نام‌ها و محدودیت‌ها در [05-verification.md](05-verification.md) ثبت شده‌اند.
- هویت نهایی در Android proof دارد؛ Windows executable runtime، signed MSIX و two-install convergence هنوز proof ندارند و نباید complete ادعا شوند.
