# Perfect Orbit Day private planner rebuild

- Task ID: `2026-07-27-perfect-orbit-day-private-planner-rebuild`
- Status: `active`
- Created: 2026-07-27T20:30:42
- Language: fa

## Request
بازسازی کامل Perfect به‌عنوان یک اپ شخصیِ Flutter فقط برای Android و Windows. اپ نباید برای انتشار یا همکاری عمومی طراحی شود؛ داده‌ها باید روی دستگاه ابتدا محلی و سپس با Supabase میان دستگاه‌های خود کاربر همگام شوند. رابط و قابلیت‌ها باید از الگوهای مفید HabitNow و برنامه‌ریزهای معتبر الهام بگیرند، اما کپی هیچ‌کدام نباشند.

کاربر جهت بصری «Orbit Day» را انتخاب کرده است: روز به‌صورت مدار زمان نمایش داده می‌شود، با رنگ‌های پاستلیِ گرم، یک آیکون مداری با مرکز تیره/سه قطعهٔ رنگی/تیک، و لوگوتایپ منتخبِ پایین-چپ از برد تایپوگرافی. این جهت باید برای نمای عمودی و افقی به‌صورت واقعی طراحی شود.

## Success Criteria
- Flutter app برای Android و Windows با یک هستهٔ محصولی مشترک و قابل ساخت.
- تجربهٔ خصوصی و local-first: هیچ صفحه‌ای برای پاسخ شبکه منتظر نماند؛ تغییرها ابتدا محلی ثبت و بعداً به Supabase همگام شوند.
- سینک مالک‌محور Supabase با RLS، حذف نرم، بازیابی پس از قطع شبکه، همگرایی دستگاه‌ها و رفتار امن در تعارض‌های هم‌زمان.
- قابلیت‌های کامل و واقعاً شخصی: Inbox، Today، برنامه‌ریزی روز/هفته، پروژه/حوزه، عادت‌ها، تمرکز، یادداشت/زیرکار، اولویت، سررسید/زمان‌بندی، جست‌وجو/فیلتر، آمار شخصی، تنظیمات و مسیرهای بازیابی.
- بازسازی Orbit Day با رفتار واقعی برای عمودی، افقی و پنجرهٔ عریض؛ نه کش‌آمدن طرح موبایل.
- دارایی‌های نهاییِ وکتوری برای آیکون/نشان و تایپوگرافی زنده؛ تصاویر تولیدی فقط مرجع و mock preview هستند.
- اگر ویجت Android به تأیید مالک برسد، یک خانوادهٔ «Perfect Today» با حریم‌خصوصیِ پیش‌فرض و snapshot محلیِ بدون انتظار شبکه ساخته می‌شود؛ ویجت Windows تنها پس از تصمیم مستقل برای packaging/provider بررسی می‌شود.
- تست، تحلیل، ساخت artifact و سنجش تجربه در حد عملی برای هر دو پلتفرم، با ثبت محدودیت‌های محیطی.

## Context
- وضعیت پایهٔ مخزن: یک Flutter app کوچک با `PersonalItem`، ذخیرهٔ محلی و یک جدول Supabase به‌نام `perfect_items`؛ UI فعلی فهرست سادهٔ تیره است و جهت Orbit Day را ندارد.
- مخزن Git با origin خصوصی/کاربری Perfect موجود است؛ محتوای قدیمی پیش‌تر با یک root commit جایگزین شده است.
- در این محیط هیچ URL/key واقعی Supabase در کد ثبت نشده و اجازه‌ای برای تغییر یک پروژهٔ Supabase زنده وجود ندارد؛ migration و راهنمای اجرا باید local/compatible باقی بمانند.
- آخرین پژوهش محصولی: HabitNow برای task+habit+schedule+timer+streak، Todoist برای recurrence/duration/reminder، TickTick برای برنامه‌ریزی/فوکوس و Microsoft To Do برای My Day الهام می‌دهند؛ قابلیت تیمی، marketplace، پرداخت و انتشار عمومی خارج از محصول Perfect هستند.

## In Scope
- بازطراحی اطلاعات، مسیرها، state، داده و تجربهٔ کامل productivity شخصی.
- دارایی‌های برند Perfect و system surfaces لازم برای Android/Windows.
- migrationهای افزایشی، RLS و طرح sync امن/قابل‌آزمون.
- حالت‌های خالی، خطا، loading، offline، تعارض، validation، long content، RTL/LTR، keyboard/mouse/touch و reduced motion.
- CIِ خصوصی برای بررسی build/test؛ انتشار store، signing و deploy زنده نه.
- پیش‌نمایش و قرارداد Android home-screen widget، پیش از هر کدنویسی نیتیو و فقط با تأیید صریح مالک.

## Out of Scope
- ساخت یا اعمال تغییر در Supabase زنده، افشای secret یا اجرای migration روی دادهٔ واقعی بدون تأیید جداگانهٔ کاربر.
- حساب عمومی، دعوت/تیم/اشتراک‌گذاری اجتماعی، پرداخت، تحلیل‌گر تبلیغاتی، marketplace یا انتشار در app store.
- Web، PWA، service worker، Web Push، تقویم بیرونی، فایل ضمیمهٔ باینری و رابط backup/export دستی.
- حذف schema/data/route قدیمی بدون migration سازگار، snapshot و تأیید صریح.
- Windows Widgets در این مرحله: اپ Flutter فعلی identity/packaging و Windows App SDK provider ندارد؛ افزودن آن یک پروژهٔ پلتفرمی جداست و نباید وانمود شود که با یک UI Flutter ساده آماده است.

## Assumptions
- کاربر تنها مالک داده و تنها role اپ است؛ email/password Supabase فقط برای پیوند دستگاه‌های خودش باقی می‌ماند.
- رابط انگلیسی‌اول است؛ محتوای فارسی، RTL، متن‌های ترکیبی و تاریخ شمسی/میلادی باید در پیاده‌سازی واقعی تست شوند.
- جهت برند تأییدشده است، اما تصویرهای mock preview منبع نهایی لوگو، آیکون یا تایپوگرافی نیستند.
