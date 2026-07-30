# Android Today Widget Contract

## User promise

- با resize، سه ترکیب کوچک، عریض و بزرگ نمایش داده می‌شود؛ صرفاً یک layout کشیده نمی‌شود.
- فهرست روز با `RemoteViewsService` و `ListView` بومی Android اسکرول می‌شود.
- کنترل هر Task با ضربه‌های پیاپی بین خالی → انجام → انجام‌نشده → درصدی → خالی می‌چرخد.
- تغییر ابتدا در snapshot و replay queue محلی ثبت می‌شود و سپس callback پس‌زمینه همان mutation idempotent را در Drift/outbox می‌نویسد.
- عنوان‌ها به‌صورت پیش‌فرض برای مالک قابل‌دیدن‌اند و از داخل More می‌توان آن‌ها را مخفی کرد.
- Open Today هم در cold launch و هم وقتی app باز است، surface Today را انتخاب می‌کند.

## Day boundary and stale-state safety

1. Flutter foreground برای مرز روز Timer دارد و روی resume دوباره projection را می‌سازد.
2. receiver غیرقابل‌export در 00:01 محلی یک refresh پس‌زمینه درخواست می‌کند.
3. `updatePeriodMillis=1800000` پشتیبان Android برای wakeupهای به‌تعویق‌افتاده است.
4. اگر snapshot متعلق به روز قبل باشد، rowها پنهان و متن Refreshing نمایش داده می‌شود.
5. native action روی snapshot قدیمی رد می‌شود؛ هیچ tap بعد از نیمه‌شب نمی‌تواند occurrence دیروز را تغییر دهد.
6. background URI فقط با owner و token نصب فعلی پذیرفته می‌شود و هیچ network I/O انجام نمی‌دهد.

## Platform boundaries

- این widget مختص Android است. اپ Windows کامل است، اما Windows Widget Provider به packaged identity/MSIX و Windows App SDK جداگانه نیاز دارد و در این rebuild جعل نشده است.
- launcher/runtime واقعی باید روی دستگاه یا emulator دارای widget host بررسی شود. تست‌های source، Flutter protocol و APK build جای آن مشاهدهٔ نهایی روی launcher را نمی‌گیرند.

## Primary platform reference

پیاده‌سازی collection از قرارداد رسمی Android برای [App widget collections](https://developer.android.com/develop/ui/views/appwidgets/collections) پیروی می‌کند: `RemoteViewsService`/factory، permission سرویس، template PendingIntent و fill-in intent برای rowها، و notification تغییر داده.
