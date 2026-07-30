# Perfect Orbit Day private planner rebuild

- Task ID: `2026-07-27-perfect-orbit-day-private-planner-rebuild`
- Status: `active`
- Created: 2026-07-27T20:30:42
- Language: fa

## Request
بازسازی کامل Perfect به‌عنوان یک اپ شخصیِ Flutter فقط برای Android و Windows. اپ نباید برای انتشار یا همکاری عمومی طراحی شود؛ داده‌ها باید روی دستگاه ابتدا محلی و سپس با Supabase میان دستگاه‌های خود کاربر همگام شوند. رابط و قابلیت‌ها باید از الگوهای مفید HabitNow و برنامه‌ریزهای معتبر الهام بگیرند، اما کپی هیچ‌کدام نباشند.

کاربر جهت بصری «Orbit Day»، رنگ‌های پاستلیِ گرم و لوگوتایپ پایین-چپِ برد تایپوگرافی را انتخاب کرده است. تصمیم قبلی دربارهٔ آیکون مداری در ۲۰۲۶-۰۷-۳۰ باز شد و پس از ۱۰ مسیر آزاد و پنج مسیر متقارن، نشان **Day Compass** انتخاب شد: شش ماژول پاستلی متقارن پیرامون هستهٔ شخصی تیره. جهت Orbit Day برای نمای عمودی و افقی به‌صورت واقعی طراحی می‌شود و Day Compass منبع هویت نهایی Android/Windows است.

## Success Criteria
- Flutter app برای Android و Windows با یک هستهٔ محصولی مشترک و قابل ساخت.
- تجربهٔ خصوصی و local-first: هیچ صفحه‌ای برای پاسخ شبکه منتظر نماند؛ تغییرها ابتدا محلی ثبت و بعداً به Supabase همگام شوند.
- سینک مالک‌محور Supabase با RLS، حذف نرم، بازیابی پس از قطع شبکه، همگرایی دستگاه‌ها و رفتار امن در تعارض‌های هم‌زمان.
- قابلیت‌های کامل و واقعاً شخصی: Inbox، Today، برنامه‌ریزی روز/هفته، پروژه/حوزه، عادت‌ها، تمرکز، یادداشت/زیرکار، اولویت، سررسید/زمان‌بندی، جست‌وجو/فیلتر، آمار شخصی، تنظیمات و مسیرهای بازیابی.
- بازسازی Orbit Day با رفتار واقعی برای عمودی، افقی و پنجرهٔ عریض؛ نه کش‌آمدن طرح موبایل.
- master نهایی شفاف Day Compass در ۵۱۲×۵۱۲، مشتق‌های Android legacy/adaptive/monochrome، ICO چندرزولوشنی Windows و تایپوگرافی زنده؛ سایر کانسپت‌ها فقط تاریخچهٔ انتخاب هستند.
- خانوادهٔ «Perfect Today» برای Android با حریم‌خصوصیِ پیش‌فرض، snapshot محلیِ بدون انتظار شبکه، resize، scroll و کنترل چهارحالته ساخته و روی host واقعی Android آزموده شود؛ ویجت Windows تنها پس از تصمیم مستقل برای packaging/provider بررسی می‌شود.
- تست، تحلیل، ساخت artifact و سنجش تجربه در حد عملی برای هر دو پلتفرم، با ثبت محدودیت‌های محیطی.

## Context
- وضعیت پایهٔ مخزن: یک Flutter app کوچک با `PersonalItem`، ذخیرهٔ محلی و یک جدول Supabase به‌نام `perfect_items`؛ UI فعلی فهرست سادهٔ تیره است و جهت Orbit Day را ندارد.
- مخزن Git با origin خصوصی/کاربری Perfect موجود است؛ محتوای قدیمی پیش‌تر با یک root commit جایگزین شده است.
- هیچ URL/key واقعی Supabase در source ثبت نشده است. هشت migration افزایشی، شامل ingestion برنامهٔ agent، تاریخچهٔ خصوصی AI، guard metadata و RPC امن context، روی پروژهٔ خصوصی اعمال شده‌اند. owner/RLS/RPC/Auth زنده آزموده شده‌اند؛ secrets فقط در GitHub Actions/پیکربندی محلی/Edge Function می‌مانند و migrationهای local/remote هم‌نسخه‌اند.
- آخرین پژوهش محصولی: HabitNow برای task+habit+schedule+timer+streak، Todoist برای recurrence/duration/reminder، TickTick برای برنامه‌ریزی/فوکوس و Microsoft To Do برای My Day الهام می‌دهند؛ قابلیت تیمی، marketplace، پرداخت و انتشار عمومی خارج از محصول Perfect هستند.

## In Scope
- بازطراحی اطلاعات، مسیرها، state، داده و تجربهٔ کامل productivity شخصی.
- دارایی‌های برند Perfect و system surfaces لازم برای Android/Windows.
- migrationهای افزایشی، RLS و طرح sync امن/قابل‌آزمون.
- حالت‌های خالی، خطا، loading، offline، تعارض، validation، long content، RTL/LTR، keyboard/mouse/touch و reduced motion.
- CIِ خصوصی برای بررسی build/test و انتقال artifact؛ انتشار store یا deploy عمومی نه. artifact امضاشده فقط با secret امضای خصوصی معتبر است و نبود آن باید صریح گزارش شود.
- پیاده‌سازی و اثبات Android home-screen widget پس از تأیید صریح مالک.

## Out of Scope
- تغییر مخرب در Supabase زنده، افشای secret یا اجرای migration جدید روی دادهٔ واقعی بدون تأیید و قرارداد سازگار.
- حساب عمومی، دعوت/تیم/اشتراک‌گذاری اجتماعی، پرداخت، تحلیل‌گر تبلیغاتی، marketplace یا انتشار در app store.
- Web، PWA، service worker، Web Push، تقویم بیرونی، فایل ضمیمهٔ باینری و رابط backup/export دستی.
- حذف schema/data/route قدیمی بدون migration سازگار، snapshot و تأیید صریح.
- Windows Widgets در این مرحله: اپ Flutter فعلی identity/packaging و Windows App SDK provider ندارد؛ افزودن آن یک پروژهٔ پلتفرمی جداست و نباید وانمود شود که با یک UI Flutter ساده آماده است.

## Assumptions
- کاربر تنها مالک داده و تنها role اپ است؛ email/password Supabase فقط برای پیوند دستگاه‌های خودش باقی می‌ماند.
- رابط انگلیسی‌اول است؛ محتوای فارسی، RTL، متن‌های ترکیبی و تاریخ شمسی/میلادی باید در پیاده‌سازی واقعی تست شوند.
- جهت Orbit Day، لوگوتایپ و Day Compass تأییدشده‌اند. مستر شفاف، Android raster/monochrome و Windows ICO ساخته شده‌اند؛ Android روی Pixel Launcher دوباره اثبات شده و Windows/CI تازه باید SHA نهایی را بسازد و بررسی کند.
