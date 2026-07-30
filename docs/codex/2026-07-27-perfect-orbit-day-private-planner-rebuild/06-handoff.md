# Handoff

## Outcome

Perfect! اکنون یک planner شخصی Flutter برای Android و Windows است؛ Web عمداً حذف شده است. محصول از یک فهرست ساده به Orbit Day واکنش‌گرا، Task/Habit editor بسیار قابل‌تنظیم، local-first Drift، sync خصوصی Supabase، recovery/conflict/archive، focus/reminder/insight و ویجت بومی Android تبدیل شده است.

گیت محلی سبز است: analyzer، ۱۶۲ تست، build release متصل Android، نصب و cold start روی API 35، آیکون/نام، portrait/landscape و خود widget host واقعی بررسی شدند. Supabase خصوصی نیز migration/RLS/Auth/RPC زنده را پاس کرده و GitHub Secrets اتصال دارد. محدودیت باقی‌مانده اجرای محلی Windows بدون Visual Studio C++ و convergence نهایی روی دو نصب واقعی است.

## Product behavior delivered

- Task یک‌باره و recurring با برنامه‌ریزی، چند تاریخ ماهانه/سالانه، last day، flexible N-per-week/month، pause، exception، end/limit و carry cap.
- recovery انتخابی برای pending، miss، move-next و ask؛ تصمیم‌های معوق در Today گم نمی‌شوند.
- وضعیت چهارحالتهٔ Task در اپ و ویجت: `Empty → Done → Not done → % → Empty`.
- Habit با check، avoid، count، duration و checklist؛ هدف at-least/at-most، required/custom/percent success و backfill/undo روزانه.
- پروژه، area، label، category، priority، energy، estimate، time block، due date، checklist، custom typed property، formula و link.
- focus stopwatch/timer/Pomodoro با break policy؛ reminder، quiet hours، snooze، timezone و notification deep link.
- archive قابل‌بازیابی، conflict center، insight صادقانه و تنظیمات privacy/title برای widget.
- UI تطبیقی مستقل برای compact portrait، short landscape/medium و expanded Windows؛ navigation rail، inspector، shortcut و context menu بومی‌تر ویندوز.
- هویت Perfect! با wordmark انتخاب‌شده، نشان دقیق سه‌قوس orbit/check، palette پاستلی و typography Plus Jakarta + Vazirmatn. source و Windows شفاف‌اند؛ Android به‌علت mask اجباری لانچر از tile هلویی پاستلی `#FFE5CC` استفاده می‌کند.

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
- `flutter test --no-pub -r expanded`: ۱۶۲ pass
- `flutter build apk --release --no-pub`: pass
- Configured APK SHA-256: `4282AA5A07585F1FBD34910389D83FDC5655D2CF3548FDE9382276393A9329CD`
- Android API 35 install/start/logcat: pass
- launcher name/icon: pass؛ Pixel Launcher واقعی با tile پاستلیِ عمدی، بدون fallback سفید/مشکی
- widget picker/add/resize/scroll/deep-link/four-state queue: pass
- Windows local build: blocked by missing Visual Studio C++ workload
- live Supabase migration/RLS/RPC/Auth: pass؛ two-device Android↔Windows convergence هنوز اجرا نشده است

جزئیات و تصویرهای runtime در [05-verification.md](05-verification.md) ثبت شده‌اند.

## Private setup

1. migrationها، owner profile و `perfect://login-callback` روی پروژهٔ اصلی از قبل آماده‌اند؛ آن‌ها را دستی تکرار نکن.
2. artifactهای CI با `PERFECT_SUPABASE_URL` و `PERFECT_SUPABASE_PUBLISHABLE_KEY` از پیش متصل ساخته می‌شوند؛ فقط با همان حساب owner وارد شو.
3. اگر build محلی بدون define اجرا شد، می‌توان همان URL و publishable anon key را در configuration امن همان نصب وارد کرد.
4. برای signed artifact پایدار، secretهای تعریف‌شده در `.github/private-build-contract.yml` را فقط در GitHub Actions تنظیم کن؛ هیچ keystore/certificate یا key داخل repo قرار نده.

## Environment limits and follow-up proof

- Hosted Windows CI باید artifact همان SHA نهایی را بسازد؛ تست Flutter و source inspection جای اجرای exe روی ویندوز را نمی‌گیرند.
- migration/RLS و authenticated owner مثبت زنده پاس‌اند؛ offline→reconnect، conflict، realtime drop، دو session هم‌زمان و convergence باید روی Android و Windows artifact نهایی end-to-end ثبت شوند.
- Android proof فعلی emulator است؛ اگر گوشی واقعی متفاوت از API 35 هدف اصلی شد، notification permission، exact alarm policy، reboot reminder و OEM launcher widget هم روی همان دستگاه smoke-test شوند.
- هشدار future Kotlin migration از `home_widget` و `flutter_timezone` است؛ dependencyهای مستقیم فعلاً آخرین نسخهٔ قابل resolve هستند.
