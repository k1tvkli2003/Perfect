# Perfect!

Perfect یک planner شخصیِ Flutter برای **Android و Windows** است؛ نه سرویس عمومی، نه اپ استور، و نه نسخهٔ وب. داده در هر دستگاه ابتدا در پایگاه‌دادهٔ محلی ثبت می‌شود و سپس، در پس‌زمینه، با Supabase خصوصیِ خودت همگام می‌شود.

## قابلیت‌های فعلی

- Orbit Day واکنش‌گرا: نمای عمودی Android، نمای میانی/افقی، و سه‌پنل واقعی Windows.
- Inbox، Task، Recurring Task، Habit، Project و Area با quick capture آفلاین.
- Task/Habit sectioned editor: زمان شروع/پایان، recurrence و exception، carry/recovery، reminderهای چندگانه با snooze مستقل، priority، label، icon/color، estimate/energy، link، checklist، focus/break policy، category، هدف حداقل/حداکثر و propertyهای typed/formula-safe.
- Log صریح برای Habitهای check/count/duration/avoidance؛ Task تکرارشونده برای هر روز occurrence مستقل دارد و کل سری را complete نمی‌کند.
- ویرایش و backfill تاریخچهٔ Habit با correction/undo و provenance؛ duplicate واقعی با UUID تازه و بدون کپی‌کردن progress یا history.
- کنترل Task چهارحالته در اپ و ویجت: خالی → انجام → انجام‌نشده → درصدی → خالی، با mutationهای مرتب و idempotent.
- Pomodoro، countdown و stopwatch با ذخیرهٔ محلیِ session پیش از هر sync.
- Archive قابل بازگردانی، Conflict Center، جست‌وجو و فیلتر Task و insight محلیِ بدون قضاوت.
- Perfect AI به‌صورت dock جمع‌شونده بالای capture/footer، با تاریخچهٔ همگام‌شونده، ورودی متن/ویس و proposal قابل‌مرور پیش از هر write در planner.
- Sync Cloud سه‌حالته با سبز/زرد/قرمز، متن وضعیت و retry خودکارِ bounded؛ خطای شبکه کار محلی را متوقف نمی‌کند.
- ویجت بومی Android با چهار family کوچک/بلند/عریض/بزرگ متناسب با resize، فهرست روزِ اسکرول‌پذیر، تغییر مستقیم outcome، مخفی‌سازی عنوان و rollover خودکار روز.
- تجربهٔ Windows با Day Compass و Runway در مقیاس مناسب، Day Stream مجاور، inspector زمینه‌ای، navigation rail جمع‌شونده، dialogهای bounded، منوی راست‌کلیک، shortcutهای `Ctrl+N`، `Ctrl+1..5`، `Ctrl+K`، `Ctrl+Shift+F` و restore دقیق پنجره روی DPI/چند مانیتور.
- برند Perfect!، فونت‌های پروژه‌ای برای متن فارسی/انگلیسی و نشان متقارن
  **Day Compass**: شش ماژول پاستلی پیرامون هستهٔ شخصیِ تیره. مستر شفاف
  ۵۱۲×۵۱۲ منبع مشترک UI، Android و Windows است.

## قرارداد حریم خصوصی و Sync

- هیچ صفحه‌ای منتظر پاسخ شبکه نمی‌ماند. mutation محلی و outbox در یک transaction نوشته می‌شوند.
- Sync فقط برای یک مالک خصوصی در Supabase طراحی شده است؛ RLS و جدول `planner_owner_profiles` اجازهٔ self-enrol یا اشتراک عمومی نمی‌دهند.
- تغییرهای هم‌زمان تا حد ممکن در سطح field merge می‌شوند. فقط تعارض واقعی وارد Conflict Center می‌شود.
- Archive یک tombstone همگام‌شونده است، نه پاک‌کردن غیرقابل‌بازگشت.
- Android cloud backup و device-to-device extraction برای database، session، configuration و widget projection بسته‌اند؛ انتقال قابل‌اعتماد فقط از مسیر sync خصوصی انجام می‌شود.
- کلید `service_role` هرگز نباید داخل Flutter، GitHub یا CI قرار بگیرد.

## راه‌اندازی Supabase خصوصی

checkout اصلی Perfect از قبل به پروژهٔ شخصی `evyjrbwibwrdkjakooor` متصل است. هشت migration افزایشی زیر با history هم‌نسخه روی همان پروژه اعمال شده‌اند:

- [`20260730053612_create_perfect_items.sql`](supabase/migrations/20260730053612_create_perfect_items.sql)
- [`20260730053626_add_private_planner_v2.sql`](supabase/migrations/20260730053626_add_private_planner_v2.sql)
- [`20260730054603_harden_perfect_legacy_anon_access.sql`](supabase/migrations/20260730054603_harden_perfect_legacy_anon_access.sql)
- [`20260730054708_minimize_perfect_authenticated_grants.sql`](supabase/migrations/20260730054708_minimize_perfect_authenticated_grants.sql)
- [`20260730190000_add_agent_plan_ingestion.sql`](supabase/migrations/20260730190000_add_agent_plan_ingestion.sql)
- [`20260730192000_add_private_ai_conversation_sync.sql`](supabase/migrations/20260730192000_add_private_ai_conversation_sync.sql)
- [`20260730210000_harden_private_ai_metadata.sql`](supabase/migrations/20260730210000_harden_private_ai_metadata.sql)
- [`20260730220000_add_private_ai_planner_context_rpc.sql`](supabase/migrations/20260730220000_add_private_ai_planner_context_rpc.sql)

owner خصوصی دقیقاً یک‌بار از کاربر Auth متناظر با حساب مدیریت پروژه ثبت شده است؛ `perfect://login-callback` بدون حذف redirectهای موجود به allowlist افزوده شده و GitHub Actions نیز `PERFECT_SUPABASE_URL` و `PERFECT_SUPABASE_PUBLISHABLE_KEY` را دارد. buildهای CI بنابراین صفحهٔ configuration اولیه را نشان نمی‌دهند و مستقیم به ورود همان پروژه می‌روند. هیچ service-role/secret key داخل repository یا artifact قرار نمی‌گیرد.

RPC مربوط به context هوش مصنوعی `SECURITY DEFINER`، owner-scoped و bounded است؛ نقش `authenticated` اجازهٔ `SELECT` مستقیم روی `planner_entities` نمی‌گیرد. provider key نیز فقط secret سمت Edge Function است و داخل Flutter یا artifact قرار نمی‌گیرد. bundle فعلی `perfect-agent` به‌صورت نسخهٔ ۳ با `ACTIVE` و `verify_jwt=true` deploy شده و درخواست بدون Authorization را با 401 رد می‌کند؛ smoke احراز‌شدهٔ provider همچنان به یک کلید rotateشده نیاز دارد.

اگر روزی این اپ را به پروژهٔ Supabase دیگری منتقل کردی، همین migrationها را به ترتیب با Supabase CLI اعمال کن، فقط یک Auth user را در `planner_owner_profiles` ثبت کن، callback بالا را به redirect allowlist اضافه کن و دو secret عمومی client را در repository مقصد تنظیم کن. مدل دیتابیس عمداً بیش از یک owner را نمی‌پذیرد.

Android handler در manifest حاضر است و MSIX خصوصی Windows نیز protocol `perfect` را ثبت می‌کند. در client تنها **Project URL** و **publishable/anon key** مجاز است—نه service-role key.

## اجرای محلی

```powershell
flutter pub get

# Android
flutter run -d android `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY `
  --dart-define=SUPABASE_AUTH_REDIRECT_URI=perfect://login-callback

# Windows
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY `
  --dart-define=SUPABASE_AUTH_REDIRECT_URI=perfect://login-callback
```

بدون dart-define، اپ یک صفحهٔ configuration امن نشان می‌دهد و هیچ secretی در repository ذخیره نمی‌شود.

## ویجت Android

بعد از یک‌بار ورود و ساخته‌شدن دادهٔ محلی، از widget picker لانچر «Perfect! Today» را اضافه کن. چهار family کوچک، بلند، عریض و بزرگ ترکیب‌های متفاوت دارند و فهرست داخل خود ویجت اسکرول می‌شود. ضربه روی کنترل هر Task outcome را می‌چرخاند؛ «Open Today» مستقیماً صفحهٔ Today را باز می‌کند.

از **More > Android Today widget** می‌توان عنوان Taskها را روی home screen مخفی یا دوباره آشکار کرد و، در لانچرهای پشتیبانی‌شده، درخواست pin داد. دادهٔ روز در Drift مرجع اصلی می‌ماند؛ callback ویجت فقط mutation محلی/outbox می‌سازد و شبکه را منتظر نمی‌گذارد. در مرز روز، snapshot قدیمی قفل می‌شود تا tap اشتباهی روی occurrence دیروز ثبت نشود و refresh پس‌زمینه projection امروز را جایگزین می‌کند.

## بازتولید نشان Day Compass

```powershell
python -m pip install -r tool/requirements.txt
python tool/generate_day_compass_assets.py
dart run flutter_launcher_icons
```

اسکریپت نخست master شفاف، monochrome و ICO چنداندازهٔ Windows را می‌سازد؛
`flutter_launcher_icons` فقط مشتق‌های Android را بازتولید می‌کند و عمداً ICO
را بازنویسی نمی‌کند.

## بررسی و ساخت

```powershell
flutter analyze
flutter test
flutter build apk --release
flutter build windows --release

# ساخت installer امضاشده از trusted main CI انجام می‌شود. برای provision
# یا بازفرستادن همان هویت خصوصی، secretها فقط از stdin امن به GitHub می‌روند:
.\tool\provision_private_signing.ps1
```

Windows build به Visual Studio با workload **Desktop development with C++** نیاز دارد. این workload روی ماشین فعلی نصب نیست؛ runner ویندوز GitHub Actions برای SHA `fe24d33f6b22a699619e1dc7afec4440ec89f4fc` خروجی release portable و MSIX خصوصی را با موفقیت ساخته است. فایل portable دانلودشده launch شد و responsive ماند. این launch smoke جای بررسی کامل resize، hover/focus، Explorer/taskbar/window icon یا frame-jank را نمی‌گیرد.

وضعیت محلی فعلی `flutter analyze` و هر ۲۶۵ تست را پاس می‌کند. GitHub Actions
[run `30637250609`](https://github.com/k1tvkli2003/Perfect/actions/runs/30637250609)
(`#20`) نیز برای همان SHA سبز است و Android `1.1.0+2020`، MSIX `1.1.0.20`
و Windows portable را حفظ کرده است. این run نخستین baseline برای signer جدید
Windows است؛ اثبات واقعی install-over به artifact متوالی run `#21` نیاز دارد.

## GitHub Actions خصوصی

[`verify.yml`](.github/workflows/verify.yml) روی PR، push به `main` و اجرای دستی، format/analyze/test و build release Android/Windows را انجام می‌دهد. نسخهٔ پایهٔ فعلی `1.1.0+2000` است. Android `versionCode` از **epoch پایه + `github.run_number`** ساخته می‌شود و نسخهٔ MSIX از `MAJOR.MINOR.PATCH.github.run_number`؛ run `#20` عملاً Android `2020` و MSIX `1.1.0.20` ساخته است و run `#21` باید به‌ترتیب `2021` و `1.1.0.21` بسازد. artifactها ۱۴ روز نگه‌داری می‌شوند و هیچ GitHub Release یا store deploy ساخته نمی‌شود.

buildهای یک ref با `cancel-in-progress: false` و `queue: max` صف می‌شوند تا دو
نسخهٔ installable هم‌زمان اجرا یا لغو نشوند. نام قراردادی APK نیز
`perfect-MAJOR.MINOR.PATCH-build.VERSION_CODE-android-universal.apk` است؛
`VERSION_CODE` همان مقدار محاسبه‌شدهٔ epoch + run number است، نه placeholder
مبهم build number. `actionlint 1.7.12` پیش از پشتیبانی syntax جدید
`concurrency.queue` منتشر شده است؛ بررسی محلی فقط diagnostic دقیق همان کلید را
نادیده می‌گیرد و هر diagnostic دیگری fail می‌شود. اعتبار نهایی این syntax با
پذیرش workflow توسط سرویس GitHub پس از push اثبات می‌شود.

برای build از پیش متصل، این دو Secret اختیاری‌اند:

- `PERFECT_SUPABASE_URL`
- `PERFECT_SUPABASE_PUBLISHABLE_KEY`

برای update identity پایدارِ private installer، material امضا فقط در GitHub Secrets قرار می‌گیرد و هرگز وارد repository نمی‌شود:

- Android: `PERFECT_ANDROID_KEYSTORE_BASE64`، `PERFECT_ANDROID_KEYSTORE_PASSWORD`، `PERFECT_ANDROID_KEY_ALIAS`، `PERFECT_ANDROID_KEY_PASSWORD`
- Windows: `PERFECT_WINDOWS_PFX_BASE64`، `PERFECT_WINDOWS_PFX_PASSWORD`

workflow رمز PFX را در argv قرار نمی‌دهد؛ end-entity code-signing certificate
را موقتاً در `CurrentUser\My` runner وارد می‌کند و MSIX را با thumbprint
پین‌شده امضا می‌کند. اسکریپت provision نیز مقدار secret را بدون newline از
stdin به `gh` می‌دهد. signer قدیمی `CA=true` دیگر استفاده نمی‌شود؛ package با
self-signed end-entity `CA=false` امضا می‌شود که فقط digital
signature/code-signing دارد.

دو fingerprint عمومی نیز به‌صورت Repository Variable ثبت می‌شوند تا تعویض
تصادفی کلید همان لحظه build را متوقف کند:

- `PERFECT_ANDROID_CERT_SHA256`
- `PERFECT_WINDOWS_CERT_THUMBPRINT`

مقادیر پین‌شدهٔ lineage فعلی:

- Android signer SHA-256: `144E87CB67A9074EBC11CFED26A96EE1ACE697A861C2EABD77C4203A4F49B0AF`
- Windows end-entity thumbprint: `1424F286C0DCACF36701D4C1AF0C0D830F01BA24`

PR و اجرای دستی خارج از `main` هیچ‌کدام از credentialهای Supabase یا signing
را دریافت نمی‌کنند و فقط artifact با برچسب `debug-fallback` می‌سازند. در
push یا اجرای دستی روی `main`، نبودن حتی یکی از secretها یا fingerprintها
باعث fail-closed می‌شود؛ بنابراین CI هرگز یک کلید موقت را به‌عنوان نسخهٔ قابل
آپدیت تحویل نمی‌دهد. APK و MSIX نهایی پس از امضا از نظر package identity،
نسخه و certificate بررسی می‌شوند و همراه `SHA256SUMS.txt` می‌آیند. MSIX
همراه public `.cer` فقط برای دستگاه‌های شخصی خودت است؛ PFX، JKS و رمزها هرگز
artifact نیستند.

### نصب خصوصی Windows و اعتماد به گواهی

برای نصب MSIX روی دستگاه شخصی، ابتدا `Perfect-private.cer` و فایل MSIX را از
همان artifact دانلود کن. thumbprint گواهی باید دقیقاً با Repository Variable
به‌نام `PERFECT_WINDOWS_CERT_THUMBPRINT` یکسان باشد. سپس PowerShell را با
دسترسی Administrator باز کن و گواهی عمومی را در مخزن machine-wide مورد
اعتماد وارد کن؛ بعد package را نصب کن:

```powershell
$certificate = Get-PfxCertificate -FilePath .\Perfect-private.cer
$expected = "THUMBPRINT_FROM_REPOSITORY_VARIABLE"
if ($certificate.Thumbprint -ne $expected) {
  throw "Perfect certificate fingerprint mismatch."
}
Import-Certificate `
  -FilePath .\Perfect-private.cer `
  -CertStoreLocation Cert:\LocalMachine\TrustedPeople
Add-AppxPackage .\Perfect-*-windows-x64.msix
```

نسخهٔ بعدی را با همان package identity و end-entity certificate دوباره با
`Add-AppxPackage` نصب کن؛ Windows آن را روی نسخهٔ قبلی ارتقا می‌دهد و
`LocalState` همان package family را نگه می‌دارد. گواهی عمومی قابل توزیع است،
ولی PFX و رمز آن نباید از مخزن امن خارج شوند. Windows signer یک certificate
self-signed end-entity با `CA=false` است؛ محل اعتماد درست آن
`LocalMachine\TrustedPeople` است و Root نباید تغییر کند. فقط همین thumbprint
پین‌شده را اعتماد کن و اگر دیگر از Perfect! استفاده نمی‌کنی، آن را از همان
store حذف کن.

run `#20` نخستین artifact همین lineage را به‌عنوان baseline ثبت کرده، اما چون artifact
قدیمی‌تری با این thumbprint وجود نداشت، هنوز شاهد ارتقای دو نسخه نیست. نخستین
اثبات خودکار واقعی باید در run `#21`، package family و marker دقیق `LocalState`
را از `1.1.0.20` تا `1.1.0.21` حفظ کند.

### پشتیبان هویت امضا

پوشهٔ `C:\Users\K1\.perfect-signing` تنها منبع قابل‌بازیابی برای همان lineage
خصوصی است. در PowerShell 7.4 یا جدیدتر، بکاپ portable فقط با passphrase مخفی
و بدون قرارگرفتن رمز در command line ساخته می‌شود:

```powershell
.\tool\backup_private_signing.ps1 `
  -OutputPath D:\Offline\perfect-signing.perfect-backup

# بهتر است ابتدا روی یک مسیر جدید restore آزمایشی انجام شود.
.\tool\restore_private_signing.ps1 `
  -PackagePath D:\Offline\perfect-signing.perfect-backup `
  -SigningRoot C:\Temp\perfect-signing-restore-test
```

فرمت نسخه‌دار بکاپ از PBKDF2-HMAC-SHA256 و AES-256-GCM استفاده می‌کند؛ JKS،
PFX، public certificateها، manifest و رمزهای بازشده از DPAPI فقط داخل
ciphertext قرار می‌گیرند. restore پیش از نوشتن مقصد، hash، alias، fingerprint
و subject پین‌شده را در حافظه بررسی و سپس رمزها را با DPAPI کاربر فعلی
دوباره محافظت می‌کند. مقصد موجود به‌صورت پیش‌فرض رد می‌شود و حتی با
`-AllowExistingEmptyTarget` باید کاملاً خالی باشد.

تست مستقل `tool/tests/test_private_signing_portable_roundtrip.ps1` فقط با
JKS/PFX مصنوعی اجرا می‌شود و signing root واقعی را نمی‌خواند. این تست
private-key possession، رمز اشتباه، ciphertext دست‌کاری‌شده، alias بدون کلید،
مقصد غیرخالی و rollback فایل/ACL را پوشش می‌دهد:

```powershell
pwsh -NoLogo -NoProfile `
  -File .\tool\tests\test_private_signing_portable_roundtrip.ps1
```

چک‌لیست بازیابی:

- یک کپی رمزنگاری‌شده در حافظهٔ آفلاینِ تحت کنترل خودت نگه دار.
- رمز vault را جدا از همان حافظه ذخیره کن.
- restore آزمایشی را روی مسیر موقت انجام بده؛ سپس hashهای
  `signing-manifest.json` و fingerprintهای GitHub Variables را تطبیق بده.
- نتیجه و تاریخ آخرین restore آزمایشی را کنار backup ثبت کن.

GitHub Secrets بکاپ قابل دانلود نیستند و جای این نسخهٔ آفلاین را نمی‌گیرند.

قرارداد دقیق این رفتار در [`private-build-contract.yml`](.github/private-build-contract.yml) ثبت شده است.
