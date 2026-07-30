# Android Today Widget Contract

## User promise

- با resize، چهار family کوچک `110×110`، بلند `110×180`، عریض `220×110` و بزرگ `260×220` نمایش داده می‌شود؛ صرفاً یک layout کشیده نمی‌شود.
- فهرست روز با `RemoteViewsService` و `ListView` بومی Android اسکرول می‌شود.
- کنترل هر Task با ضربه‌های پیاپی بین خالی → انجام → انجام‌نشده → درصدی → خالی می‌چرخد.
- تغییر ابتدا در snapshot و replay queue محلی ثبت می‌شود و سپس callback پس‌زمینه همان mutation idempotent را در Drift/outbox می‌نویسد.
- عنوان‌ها به‌صورت پیش‌فرض برای مالک قابل‌دیدن‌اند و از داخل More می‌توان آن‌ها را مخفی کرد.
- Open Today هم در cold launch و هم وقتی app باز است، surface Today را انتخاب می‌کند.
- preview اولیهٔ picker از layout واقعی کوچک استفاده می‌کند و هر چهار family همان `RemoteViewsService` اسکرول‌پذیر را حفظ می‌کنند.

## Day boundary and stale-state safety

1. Flutter foreground برای مرز روز Timer دارد و روی resume دوباره projection را می‌سازد.
2. receiver غیرقابل‌export در 00:01 محلی یک refresh پس‌زمینه درخواست می‌کند.
3. `updatePeriodMillis=1800000` پشتیبان Android برای wakeupهای به‌تعویق‌افتاده است.
4. اگر snapshot متعلق به روز قبل باشد، rowها پنهان و متن Refreshing نمایش داده می‌شود.
5. native action روی snapshot قدیمی رد می‌شود؛ هیچ tap بعد از نیمه‌شب نمی‌تواند occurrence دیروز را تغییر دهد.
6. background URI فقط با owner و token نصب فعلی پذیرفته می‌شود و هیچ network I/O انجام نمی‌دهد.
7. ترتیب replay از `queue_sequence` یکنواخت native می‌آید؛ تغییر یا عقب‌رفتن wall clock نمی‌تواند ترتیب tapها را جابه‌جا کند.
8. action ناقص یا نامعتبر پیش از تغییر snapshot رد می‌شود؛ overflow نیز به‌جای حذف خاموش ثبت و رد می‌شود.
9. foreground app و WorkManager ممکن است دو connection مستقل Drift داشته باشند؛ هر widget outcome ابتدا یک claim اتمیک local-only روی mutation target می‌گیرد. برای one-off این scope خود entity و برای recurring همان occurrence روز است، بنابراین worker قدیمی پس از نتیجهٔ جدیدتر هیچ outbox یا overwrite تازه‌ای نمی‌سازد.

## Platform boundaries

- این widget مختص Android است. Flutter Windows در CI run `30519295088` با موفقیت build و به‌صورت unpackaged artifact حفظ شده، اما executable آن روی این میزبان اجرا نشده و signed MSIX نیز تولید نشده است. Windows Widget Provider همچنان به packaged identity/MSIX و Windows App SDK جداگانه نیاز دارد و در این rebuild جعل نشده است.
- launcher/runtime واقعی باید روی دستگاه یا emulator دارای widget host بررسی شود. تست‌های source، Flutter protocol و APK build جای آن مشاهدهٔ نهایی روی launcher را نمی‌گیرند.

## Primary platform reference

پیاده‌سازی collection از قرارداد رسمی Android برای [App widget collections](https://developer.android.com/develop/ui/views/appwidgets/collections) پیروی می‌کند: `RemoteViewsService`/factory، permission سرویس، template PendingIntent و fill-in intent برای rowها، و notification تغییر داده.
