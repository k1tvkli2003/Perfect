# Handoff

## Outcome

Perfect! اکنون یک planner شخصی Flutter برای Android و Windows است؛ Web عمداً حذف شده است. محصول از یک فهرست ساده به Orbit Day واکنش‌گرا، Task/Habit editor بسیار قابل‌تنظیم، local-first Drift، sync خصوصی Supabase، recovery/conflict/archive، focus/reminder/insight و ویجت بومی Android تبدیل شده است.

commit `fea3ddc7dd16741e1936a5b61de0b4785c079e67` در CI خصوصی run [`30641054596`](https://github.com/k1tvkli2003/Perfect/actions/runs/30641054596) (`#22`) سبز شد. وضعیت source جاری analyzer و ۲۶۵/۲۶۵ تست را پاس کرده است. migration هشتمِ context امن نیز زنده و owner-scoped است. run `#22` signed Android، signed MSIX و Windows portable را ساخته و artifactهای هر سه مسیر مستقل بررسی شده‌اند.

build/install-over Android و exact-SHA CI/artifact gate بسته شده‌اند. Windows signer به end-entity `CA=false` مهاجرت کرد و runهای `#20 → #21 → #22` update continuity را با package family/LocalState ثابت اثبات کردند. portable نهایی نیز title/icon، maximize/restore، wide/short/compact resize و short-height scroll را روی auth surface پاس کرد. signed-in workspace، hover/jank، provider smoke و convergence دو نصب هنوز بازند.

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
- `flutter test --no-pub --reporter compact`: ۲۶۵/۲۶۵ pass
- Workspace UI suite: ۴۴/۴۴ pass
- release continuity contract: ۷/۷ pass
- focused AI suite: ۳۳ pass؛ Deno check pass
- Edge Function: v3 `ACTIVE`، `verify_jwt=true`، hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b`، unauthenticated 401 pass
- private release/workflow contracts: pass؛ queue serialization و `VERSION_CODE` naming توسط سرویس GitHub در runهای `#20`–`#22` پذیرفته شدند
- `flutter build apk --release --build-name=1.1.0 --build-number=2004`: pass؛ private signed
- Final local APK SHA-256: `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`
- Android API 35 install-over/start/logcat for `1.1.0+2004`: pass؛ UID/data/widget binding حفظ شدند؛ session احراز‌شده به‌دلیل signed-out بودن اولیه قابل اثبات نبود
- launcher name/Day Compass icon: pass روی Pixel Launcher API 35؛ Windows runtime proof هنوز باز است
- widget picker/add/resize/scroll/deep-link/four-state queue: pass
- GitHub Actions run `30641054596` (`#22`) for `fea3ddc`: success؛ all three jobs green
- hosted Android: `1.1.0+2022`، `com.k1tvkli2003.perfect`، label `Perfect!`، سه ABI، v2، hashes and signer `144E87CB…F49B0AF` pass
- hosted signed MSIX: `1.1.0.22`، same identity/publisher، end-entity `CA=false` signer `1424F286…BA24`، 137 entries and hashes pass
- hosted portable: run `#22` has 37/37 hashes and live auth-surface resize/title/icon proof
- Windows install-over: pass؛ run `#22` نصب `1.1.0.21 → 1.1.0.22` را با package family و LocalState ثابت اثبات کرد
- Windows GUI auth runtime: title/icon، maximize/restore، `832×414`/`540×414` resize and scroll pass؛ signed-in workspace، hover/focus semantics and jank unobserved
- live Supabase migration/RLS/RPC/Auth/context: pass؛ migration `20260730220000` owner/limit/privilege checks green؛ two-device Android↔Windows convergence هنوز اجرا نشده است

جزئیات و تصویرهای runtime در [05-verification.md](05-verification.md) ثبت شده‌اند.

## Private setup

1. migrationها، owner profile و `perfect://login-callback` روی پروژهٔ اصلی از قبل آماده‌اند؛ آن‌ها را دستی تکرار نکن.
2. artifactهای CI با `PERFECT_SUPABASE_URL` و `PERFECT_SUPABASE_PUBLISHABLE_KEY` از پیش متصل ساخته می‌شوند؛ فقط با همان حساب owner وارد شو. artifactهای run `#22` مرجع فعلی‌اند.
3. اگر build محلی بدون define اجرا شد، می‌توان همان URL و publishable anon key را در configuration امن همان نصب وارد کرد.
4. برای signed artifact پایدار، secretهای تعریف‌شده در `.github/private-build-contract.yml` را فقط در GitHub Actions تنظیم کن؛ هیچ keystore یا private key داخل repo قرار نده. public end-entity certificate می‌تواند کنار MSIX باشد، اما PFX/JKS/رمزها و backup migration خصوصی artifact نمی‌شوند.
5. برای نصب MSIX خصوصی، thumbprint فایل CER را با Repository Variable تطبیق بده، آن را با دسترسی Administrator در `LocalMachine\TrustedPeople` import کن و سپس `Add-AppxPackage` را اجرا کن.
6. signing root را به‌صورت رمزنگاری‌شده آفلاین backup کن، رمز vault را جدا نگه دار و restore آزمایشی را با manifest hash و fingerprintها تأیید کن؛ GitHub Secrets backup نیست.

## Environment limits and follow-up proof

- Hosted CI artifacts و portable final runtime بررسی شده‌اند؛ auth-surface resize/title/icon proof جای signed-in Orbit workspace، Explorer/taskbar، hover/focus semantics یا frame-jank proof را نمی‌گیرد.
- migration/RLS و authenticated owner مثبت زنده پاس‌اند؛ offline→reconnect، conflict، realtime drop، دو session هم‌زمان و convergence باید روی Android و Windows artifact نهایی end-to-end ثبت شوند.
- Android proof فعلی emulator است؛ اگر گوشی واقعی متفاوت از API 35 هدف اصلی شد، notification permission، exact alarm policy، reboot reminder و OEM launcher widget هم روی همان دستگاه smoke-test شوند.
- هشدار future Kotlin migration از `home_widget` و `flutter_timezone` است؛ dependencyهای مستقیم فعلاً آخرین نسخهٔ قابل resolve هستند.

## Done

- هستهٔ planner local-first، Supabase owner/context contract، Orbit Day responsive UI، Perfect AI و Android Today widget در source و tests پیاده‌سازی شده‌اند.
- `fea3ddc7dd16741e1936a5b61de0b4785c079e67` exact-HEAD run `#22` را با signed Android، signed MSIX، checksum-complete portable Windows و install-over موفق پاس کرده است.
- Day Compass از میان conceptها انتخاب، به asset production شفاف تبدیل و در Android launcher/widget/notification و Windows ICO سیم‌کشی شده است.
- widget چهار family responsive، اسکرول native و چرخهٔ `Empty → Done → Not done → 50% → Empty` را با ترتیب native پایدار دارد.
- release audit نهایی queue، artifact naming، Windows private install trust و offline signing recovery را بسته است؛ release contract ۷/۷ باقی مانده است.
- provisioner synthetic، backup hash و rerun identity stability پاس‌اند؛ Windows package signer اکنون end-entity `CA=false` است و Android signer تغییر نکرده است.

## Remaining

1. signed-in phone/tablet/Windows main workspace، Windows hover/focus semantics/jank و signed-in widget Quick Add در runtime ثبت شوند.
2. provider smoke مثبت text/voice/proposal-apply فقط پس از تنظیم secret rotateشده اجرا شود.
3. convergence و authenticated session retention واقعی Android↔Windows با یک owner و دو نصب ثبت شود؛ notification/OEM/reboot نیز روی سخت‌افزار فیزیکی smoke شود.

## Verification

- نتیجهٔ کلی `partial` است: source، backend، exact-SHA CI، artifactها و Windows install-over پاس‌اند؛ runtimeهای احراز‌شده/GUI باقی‌مانده هنوز اجرا نشده‌اند.
- جزئیات requirement-by-requirement، artifact نام‌ها و محدودیت‌ها در [05-verification.md](05-verification.md) ثبت شده‌اند.
- signed MSIX، portable auth GUI و install-over proof دارند؛ اما signed-in workspace/cross-device convergence/session، Windows hover/jank و device-specific Android paths نباید complete ادعا شوند.
