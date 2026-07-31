# Handoff

## Outcome

Perfect! اکنون یک planner شخصی Flutter برای Android و Windows است؛ Web عمداً حذف شده است. محصول از یک فهرست ساده به Orbit Day واکنش‌گرا، Task/Habit editor بسیار قابل‌تنظیم، local-first Drift، sync خصوصی Supabase، recovery/conflict/archive، focus/reminder/insight و ویجت بومی Android تبدیل شده است.

release candidate commit `265f79aada41fee9a3b71db9a855b450e9898cbd` در CI خصوصی run [`30639359490`](https://github.com/k1tvkli2003/Perfect/actions/runs/30639359490) (`#21`) سبز شد. وضعیت source جاری analyzer و ۲۶۵/۲۶۵ تست را پاس کرده است. migration هشتمِ context امن نیز زنده و owner-scoped است. run `#21` signed Android، signed MSIX و Windows portable را ساخته و artifactهای هر سه مسیر مستقل بررسی شده‌اند.

build/install-over Android و exact-SHA CI/artifact gate بسته شده‌اند. Windows signer از self-signed certificate قدیمی `CA=true` به self-signed end-entity `CA=false` با thumbprint `1424F286C0DCACF36701D4C1AF0C0D830F01BA24` مهاجرت کرد؛ Android signer ثابت ماند. run `#20` baseline `1.1.0.20` را ساخت و run `#21` آن را به `1.1.0.21` ارتقا داد؛ package family و LocalState حفظ شدند. Windows GUI، signed-in device journeys، provider smoke و convergence دو نصب هنوز بازند.

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
- private release/workflow contracts: pass؛ queue serialization و `VERSION_CODE` naming توسط سرویس GitHub در runهای `#20`/`#21` پذیرفته شدند
- `flutter build apk --release --build-name=1.1.0 --build-number=2004`: pass؛ private signed
- Final local APK SHA-256: `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`
- Android API 35 install-over/start/logcat for `1.1.0+2004`: pass؛ UID/data/widget binding حفظ شدند؛ session احراز‌شده به‌دلیل signed-out بودن اولیه قابل اثبات نبود
- launcher name/Day Compass icon: pass روی Pixel Launcher API 35؛ Windows runtime proof هنوز باز است
- widget picker/add/resize/scroll/deep-link/four-state queue: pass
- GitHub Actions run `30639359490` (`#21`) for `265f79a`: success؛ all three jobs green
- hosted Android: `1.1.0+2021`، `com.k1tvkli2003.perfect`، label `Perfect!`، سه ABI، v2، hashes and signer `144E87CB…F49B0AF` pass
- hosted signed MSIX: `1.1.0.21`، same identity/publisher، end-entity `CA=false` signer `1424F286…BA24`، 137 entries and hashes pass
- hosted portable: run `#21` has 37/37 hashes؛ downloaded baseline executable launched responsive
- Windows install-over: pass؛ run `#21` نصب `1.1.0.20 → 1.1.0.21` را با package family و LocalState ثابت اثبات کرد
- Windows GUI runtime: resize/hover/focus/icon/jank unavailable/unobserved؛ portable launch alone does not prove these paths
- live Supabase migration/RLS/RPC/Auth/context: pass؛ migration `20260730220000` owner/limit/privilege checks green؛ two-device Android↔Windows convergence هنوز اجرا نشده است

جزئیات و تصویرهای runtime در [05-verification.md](05-verification.md) ثبت شده‌اند.

## Private setup

1. migrationها، owner profile و `perfect://login-callback` روی پروژهٔ اصلی از قبل آماده‌اند؛ آن‌ها را دستی تکرار نکن.
2. artifactهای CI با `PERFECT_SUPABASE_URL` و `PERFECT_SUPABASE_PUBLISHABLE_KEY` از پیش متصل ساخته می‌شوند؛ فقط با همان حساب owner وارد شو. artifactهای run `#21` مرجع فعلی‌اند.
3. اگر build محلی بدون define اجرا شد، می‌توان همان URL و publishable anon key را در configuration امن همان نصب وارد کرد.
4. برای signed artifact پایدار، secretهای تعریف‌شده در `.github/private-build-contract.yml` را فقط در GitHub Actions تنظیم کن؛ هیچ keystore یا private key داخل repo قرار نده. public end-entity certificate می‌تواند کنار MSIX باشد، اما PFX/JKS/رمزها و backup migration خصوصی artifact نمی‌شوند.
5. برای نصب MSIX خصوصی، thumbprint فایل CER را با Repository Variable تطبیق بده، آن را با دسترسی Administrator در `LocalMachine\TrustedPeople` import کن و سپس `Add-AppxPackage` را اجرا کن.
6. signing root را به‌صورت رمزنگاری‌شده آفلاین backup کن، رمز vault را جدا نگه دار و restore آزمایشی را با manifest hash و fingerprintها تأیید کن؛ GitHub Secrets backup نیست.

## Environment limits and follow-up proof

- Hosted CI release candidate `265f79a` را ساخته و signed Android/MSIX/portable را بررسی کرده است؛ launch responsive فایل portable جای Explorer/taskbar/window، resize/hover/focus یا frame-jank proof را نمی‌گیرد.
- migration/RLS و authenticated owner مثبت زنده پاس‌اند؛ offline→reconnect، conflict، realtime drop، دو session هم‌زمان و convergence باید روی Android و Windows artifact نهایی end-to-end ثبت شوند.
- Android proof فعلی emulator است؛ اگر گوشی واقعی متفاوت از API 35 هدف اصلی شد، notification permission، exact alarm policy، reboot reminder و OEM launcher widget هم روی همان دستگاه smoke-test شوند.
- هشدار future Kotlin migration از `home_widget` و `flutter_timezone` است؛ dependencyهای مستقیم فعلاً آخرین نسخهٔ قابل resolve هستند.

## Done

- هستهٔ planner local-first، Supabase owner/context contract، Orbit Day responsive UI، Perfect AI و Android Today widget در source و tests پیاده‌سازی شده‌اند.
- `265f79aada41fee9a3b71db9a855b450e9898cbd` exact-SHA run `#21` را با signed Android، signed MSIX، checksum-complete portable Windows و install-over موفق پاس کرده است.
- Day Compass از میان conceptها انتخاب، به asset production شفاف تبدیل و در Android launcher/widget/notification و Windows ICO سیم‌کشی شده است.
- widget چهار family responsive، اسکرول native و چرخهٔ `Empty → Done → Not done → 50% → Empty` را با ترتیب native پایدار دارد.
- release audit نهایی queue، artifact naming، Windows private install trust و offline signing recovery را بسته است؛ release contract ۷/۷ باقی مانده است.
- provisioner synthetic، backup hash و rerun identity stability پاس‌اند؛ Windows package signer اکنون end-entity `CA=false` است و Android signer تغییر نکرده است.

## Remaining

1. signed-in phone/tablet main workspace، Windows GUI resize/hover/icon/jank و signed-in widget Quick Add در runtime ثبت شوند.
2. provider smoke مثبت text/voice/proposal-apply فقط پس از تنظیم secret rotateشده اجرا شود.
3. convergence و authenticated session retention واقعی Android↔Windows با یک owner و دو نصب ثبت شود؛ notification/OEM/reboot نیز روی سخت‌افزار فیزیکی smoke شود.

## Verification

- نتیجهٔ کلی `partial` است: source، backend، exact-SHA CI، artifactها و Windows install-over پاس‌اند؛ runtimeهای احراز‌شده/GUI باقی‌مانده هنوز اجرا نشده‌اند.
- جزئیات requirement-by-requirement، artifact نام‌ها و محدودیت‌ها در [05-verification.md](05-verification.md) ثبت شده‌اند.
- signed MSIX و portable artifact proof دارند؛ اما Windows GUI، true install-over، signed-in cross-device convergence/session و device-specific Android paths نباید complete ادعا شوند.
