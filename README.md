# Perfect

یک اپ Flutter شخصی برای Android، Windows و Web که فهرست کارهای شما را با یک حساب Supabase میان دستگاه‌ها همگام می‌کند. این پروژه برای انتشار عمومی طراحی نشده است.

## طراحی همگام‌سازی

- ورود با Supabase Auth (ایمیل و گذرواژه)؛ در همهٔ دستگاه‌ها باید با همان حساب وارد شوید.
- داده ابتدا در ذخیره‌سازی محلی هر دستگاه ثبت می‌شود و بعد به Supabase ارسال می‌شود؛ در قطع اینترنت، تغییرها باقی می‌مانند و با دکمهٔ همگام‌سازی/تغییر بعدی دوباره تلاش می‌شوند.
- هر ردیف `owner_id` دارد و RLS اجازهٔ دسترسی به دادهٔ حساب دیگر را نمی‌دهد.
- حذف به‌شکل tombstone همگام می‌شود تا حذف روی یک دستگاه، روی دستگاه دیگر بازنگردد.
- هنگام ویرایش هم‌زمان یک مورد، مقدار با `updated_at` جدیدتر برنده است.

## اتصال Supabase

1. یک پروژهٔ خصوصی Supabase بسازید و در Authentication > Providers، Email را فعال کنید.
2. محتوای [migration](supabase/migrations/20260727193000_create_perfect_items.sql) را در SQL Editor اجرا کنید؛ این کار جدول، ایندکس، RLS و Realtime را ایجاد می‌کند.
3. از Connect panel، **Project URL** و فقط **publishable/anon key** را بردارید. service-role key را هرگز در برنامه یا Git قرار ندهید.
4. اجرا:

```powershell
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

برای Android و Windows نیز همین دو `--dart-define` را به `flutter run -d <device>` اضافه کنید. کلید publishable برای کلاینت عمومی است؛ حفاظت داده از RLS می‌آید.

## بررسی کیفیت

```powershell
flutter analyze
flutter test
flutter build web --dart-define=SUPABASE_URL=https://example.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=example-key
flutter build apk --debug --dart-define=SUPABASE_URL=https://example.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=example-key
flutter build windows --debug --dart-define=SUPABASE_URL=https://example.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=example-key
```

Windows build به Visual Studio با workload «Desktop development with C++» نیاز دارد. Android build این دستگاه پس از پذیرش Android SDK licenses قابل اجراست.

## انتشار

عمداً هیچ workflow انتشار، signing key، store configuration یا deploy خودکار در پروژه نیست؛ این یک اپ خصوصی است. GitHub فقط برای نگهداری کد است، نه میزبانی نسخهٔ وب یا انتشار برنامه.
