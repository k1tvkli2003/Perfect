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
- ویجت بومی Android با سه UI متناسب با resize، فهرست روزِ اسکرول‌پذیر، تغییر مستقیم outcome، مخفی‌سازی عنوان و rollover خودکار روز.
- تجربهٔ Windows با navigation rail، inspector، dialogهای bounded، منوی راست‌کلیک، shortcutهای `Ctrl+N`، `Ctrl+1..5`، `Ctrl+K`، `Ctrl+Shift+F` و restore دقیق پنجره روی DPI/چند مانیتور.
- برند Perfect!، آیکون مداری منتخب و فونت‌های پروژه‌ای برای متن فارسی/انگلیسی.

## قرارداد حریم خصوصی و Sync

- هیچ صفحه‌ای منتظر پاسخ شبکه نمی‌ماند. mutation محلی و outbox در یک transaction نوشته می‌شوند.
- Sync فقط برای یک مالک خصوصی در Supabase طراحی شده است؛ RLS و جدول `planner_owner_profiles` اجازهٔ self-enrol یا اشتراک عمومی نمی‌دهند.
- تغییرهای هم‌زمان تا حد ممکن در سطح field merge می‌شوند. فقط تعارض واقعی وارد Conflict Center می‌شود.
- Archive یک tombstone همگام‌شونده است، نه پاک‌کردن غیرقابل‌بازگشت.
- Android cloud backup و device-to-device extraction برای database، session، configuration و widget projection بسته‌اند؛ انتقال قابل‌اعتماد فقط از مسیر sync خصوصی انجام می‌شود.
- کلید `service_role` هرگز نباید داخل Flutter، GitHub یا CI قرار بگیرد.

## راه‌اندازی Supabase خصوصی

این مراحل عمداً روی پروژهٔ واقعی تو به‌صورت خودکار اجرا نمی‌شوند.

1. یک Supabase project خصوصی بساز یا از پروژهٔ خصوصی خودت استفاده کن. در **Auth > Providers** فقط Email/Password را فعال کن و **Allow new users to sign up** را خاموش نگه دار.
2. migrationها را به ترتیب زمانی در SQL Editor اجرا کن:

   - [`20260727193000_create_perfect_items.sql`](supabase/migrations/20260727193000_create_perfect_items.sql) برای سازگاری با پایهٔ قبلی
   - [`20260727210000_add_private_planner_v2.sql`](supabase/migrations/20260727210000_add_private_planner_v2.sql) برای مدل local-first، RPC، RLS و sync v2

3. کاربر خصوصی خودت را در Supabase Auth ایجاد کن. سپس UUID همان کاربر را یک‌بار به‌عنوان owner ثبت کن:

   ```sql
   insert into public.planner_owner_profiles (owner_id)
   values ('YOUR_PRIVATE_AUTH_USER_UUID');
   ```

   این migration عمداً فقط یک owner را می‌پذیرد. اگر قصد چندمالک/تیم داری، این مدل محصول مناسب آن نیست.

4. `perfect://login-callback` را در Auth Redirect URLs allowlist کن. Android handler در manifest حاضر است و MSIX خصوصی Windows نیز protocol `perfect` را ثبت می‌کند.
5. تنها **Project URL** و **publishable/anon key** را استفاده کن—نه service-role key.

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

بعد از یک‌بار ورود و ساخته‌شدن دادهٔ محلی، از widget picker لانچر «Perfect! Today» را اضافه کن. اندازهٔ کوچک، عریض و بزرگ ترکیب‌های متفاوت دارند و فهرست داخل خود ویجت اسکرول می‌شود. ضربه روی کنترل هر Task outcome را می‌چرخاند؛ «Open Today» مستقیماً صفحهٔ Today را باز می‌کند.

از **More > Android Today widget** می‌توان عنوان Taskها را روی home screen مخفی یا دوباره آشکار کرد و، در لانچرهای پشتیبانی‌شده، درخواست pin داد. دادهٔ روز در Drift مرجع اصلی می‌ماند؛ callback ویجت فقط mutation محلی/outbox می‌سازد و شبکه را منتظر نمی‌گذارد. در مرز روز، snapshot قدیمی قفل می‌شود تا tap اشتباهی روی occurrence دیروز ثبت نشود و refresh پس‌زمینه projection امروز را جایگزین می‌کند.

## بررسی و ساخت

```powershell
flutter analyze
flutter test
flutter build apk --release
flutter build windows --release

# پس از build ویندوز و با هویت امضای خصوصی:
dart run msix:create --build-windows false `
  --certificate-path C:\PRIVATE\perfect-private.pfx `
  --certificate-password YOUR_PRIVATE_PASSWORD `
  --install-certificate false
```

Windows build به Visual Studio با workload **Desktop development with C++** نیاز دارد. در ماشین فعلی این workload نصب نیست؛ بنابراین اثبات native Windows بر عهدهٔ runner ویندوز GitHub Actions است. خروجی بدون dart-define همچنان قابل نصب است و در اولین اجرا صفحهٔ اتصال امن را نشان می‌دهد.

## GitHub Actions خصوصی

[`verify.yml`](.github/workflows/verify.yml) روی PR، push به `main` و اجرای دستی، format/analyze/test و build release Android/Windows را انجام می‌دهد. artifactها ۱۴ روز نگه‌داری می‌شوند و هیچ GitHub Release یا store deploy ساخته نمی‌شود.

برای build از پیش متصل، این دو Secret اختیاری‌اند:

- `PERFECT_SUPABASE_URL`
- `PERFECT_SUPABASE_PUBLISHABLE_KEY`

برای update identity پایدارِ private installer، material امضا فقط در GitHub Secrets قرار می‌گیرد و هرگز وارد repository نمی‌شود:

- Android: `PERFECT_ANDROID_KEYSTORE_BASE64`، `PERFECT_ANDROID_KEYSTORE_PASSWORD`، `PERFECT_ANDROID_KEY_ALIAS`، `PERFECT_ANDROID_KEY_PASSWORD`
- Windows: `PERFECT_WINDOWS_PFX_BASE64`، `PERFECT_WINDOWS_PFX_PASSWORD`

در نبود هر گروه Secret، CI شکست دروغین نمی‌سازد: artifact قابل‌کامپایل را با برچسب `unconfigured` یا `debug-fallback` نگه می‌دارد و صریحاً هشدار می‌دهد که identity پایدار اثبات نشده است. MSIX امضاشده همراه public `.cer` فقط برای نصب روی دستگاه‌های شخصی خودت ساخته می‌شود؛ PFX و رمز هرگز artifact نیستند.

قرارداد دقیق این رفتار در [`private-build-contract.yml`](.github/private-build-contract.yml) ثبت شده است.
