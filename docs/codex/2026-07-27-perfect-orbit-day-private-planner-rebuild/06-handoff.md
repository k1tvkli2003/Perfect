# Handoff

## Outcome

Perfect! اکنون یک planner شخصی Flutter برای Android و Windows است؛ Web عمداً حذف شده است. محصول از یک فهرست ساده به Orbit Day واکنش‌گرا، Task/Habit editor بسیار قابل‌تنظیم، local-first Drift، sync خصوصی Supabase، recovery/conflict/archive، focus/reminder/insight و ویجت بومی Android تبدیل شده است.

گیت محلی سبز است: analyzer، ۱۶۲ تست، build release Android، نصب و cold start روی API 35، آیکون/نام، portrait/landscape و خود widget host واقعی بررسی شدند. محدودیت‌های باقی‌مانده محیطی‌اند: Windows روی این ماشین بدون Visual Studio C++ ساخته نمی‌شود و Supabase خصوصی بدون credential مالک قابل اجرای زنده نیست.

## Product behavior delivered

- Task یک‌باره و recurring با برنامه‌ریزی، چند تاریخ ماهانه/سالانه، last day، flexible N-per-week/month، pause، exception، end/limit و carry cap.
- recovery انتخابی برای pending، miss، move-next و ask؛ تصمیم‌های معوق در Today گم نمی‌شوند.
- وضعیت چهارحالتهٔ Task در اپ و ویجت: `Empty → Done → Not done → % → Empty`.
- Habit با check، avoid، count، duration و checklist؛ هدف at-least/at-most، required/custom/percent success و backfill/undo روزانه.
- پروژه، area، label، category، priority، energy، estimate، time block، due date، checklist، custom typed property، formula و link.
- focus stopwatch/timer/Pomodoro با break policy؛ reminder، quiet hours، snooze، timezone و notification deep link.
- archive قابل‌بازیابی، conflict center، insight صادقانه و تنظیمات privacy/title برای widget.
- UI تطبیقی مستقل برای compact portrait، short landscape/medium و expanded Windows؛ navigation rail، inspector، shortcut و context menu بومی‌تر ویندوز.
- هویت Perfect! با wordmark انتخاب‌شده، آیکون orbit/check انتخاب‌شده، palette پاستلی و typography Plus Jakarta + Vazirmatn.

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
- APK SHA-256: `174DF8AB753D40F1ED4CD693723212703952F55AE186E642D61D786ECDE24A89`
- Android API 35 install/start/logcat: pass
- launcher name/icon: pass
- widget picker/add/resize/scroll/deep-link/four-state queue: pass
- Windows local build: blocked by missing Visual Studio C++ workload
- live Supabase migration/two-device convergence: blocked by unavailable private credentials

جزئیات و تصویرهای runtime در [05-verification.md](05-verification.md) ثبت شده‌اند.

## Private setup

1. migration افزایشی `supabase/migrations/20260727210000_add_private_planner_v2.sql` را روی پروژهٔ Supabase شخصی اعمال کن.
2. برای Auth user خصوصی خودت دقیقاً یک ردیف `planner_owner_profiles` بساز.
3. `perfect://login-callback` را در Supabase Auth allowlist قرار بده.
4. در اولین اجرای هر دستگاه، project URL و publishable anon key را وارد کن و با همان حساب وارد شو.
5. برای signed artifact پایدار، secretهای تعریف‌شده در `.github/private-build-contract.yml` را فقط در GitHub Actions تنظیم کن؛ هیچ keystore/certificate یا key داخل repo قرار نده.

## Environment limits and follow-up proof

- Hosted Windows CI باید artifact همان SHA نهایی را بسازد؛ تست Flutter و source inspection جای اجرای exe روی ویندوز را نمی‌گیرند.
- پس از در اختیار بودن پروژهٔ خصوصی Supabase، migration/RLS owner A/B، offline→reconnect، conflict، realtime drop، دو session هم‌زمان و convergence باید end-to-end ثبت شوند.
- Android proof فعلی emulator است؛ اگر گوشی واقعی متفاوت از API 35 هدف اصلی شد، notification permission، exact alarm policy، reboot reminder و OEM launcher widget هم روی همان دستگاه smoke-test شوند.
- هشدار future Kotlin migration از `home_widget` و `flutter_timezone` است؛ dependencyهای مستقیم فعلاً آخرین نسخهٔ قابل resolve هستند.
