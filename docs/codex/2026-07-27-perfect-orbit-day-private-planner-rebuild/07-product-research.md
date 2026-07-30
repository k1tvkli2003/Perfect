# Product Research

## Scope

این پژوهش در 2026-07-28 برای ساخت یک planner کاملاً شخصی انجام شد. هدف کپی‌کردن هیچ محصولی نیست؛ فقط الگوهایی انتخاب شده‌اند که به سرعت ثبت، انعطاف برنامه‌ریزی، وضوح Today و بازیابی مطمئن کارهای انجام‌نشده کمک می‌کنند. قابلیت‌های تیمی، marketplace، پرداخت، تبلیغات، شبکهٔ اجتماعی و انتشار عمومی عمداً خارج از Perfect هستند.

## Evidence reviewed

- ۲۵ اسکرین‌شات محلی HabitNow در `C:\Users\K1\Downloads\HabitNow`، شامل مسیرهای ایجاد و ویرایش Task/Habit، recurrence، tracking، reminder، timer و customization.
- [HabitNow در Google Play](https://play.google.com/store/apps/details?id=com.habitnow): زمان‌بندی Task/Habit، هدف‌های روزانه/هفتگی/ماهانه، stopwatch/countdown/interval timer، reminder/alarm، streak، یادداشت روزانه، نمودار و آمار، theme/icon، widget، قفل و backup. فهرست تغییرات رسمی همچنین negative amount، average chart، CSV export، interval preset، widget opacity و postpone notification را نشان می‌دهد.
- [TickTick Features](https://ticktick.com/features): capture سریع، list/filter/tag، NLP، reminderهای چندگانه، recurrence سفارشی، calendar viewهای مختلف، timeline/Kanban، Habit، Pomodoro، Eisenhower، countdown، آمار و theme.
- [TickTick Widgets](https://help.ticktick.com/articles/7055780404896202752): widgetهای Task، calendar، habits، focus و امکان check-in مستقیم؛ این مرجع تصمیم Perfect برای ویجت واقعاً تعاملی و قابل resize را تقویت کرد.
- [Todoist recurring dates](https://www.todoist.com/help/articles/introduction-to-recurring-dates-YUYVJJAV) و [Todoist start date/deadline guidance](https://www.todoist.com/help/articles/does-todoist-support-start-dates-qhqlgZhk): تفاوت recurrence مطلق/نسبی، reschedule یک occurrence، پایان recurrence، deadline مستقل از زمانی که قرار است روی کار انجام شود، و reminder.
- [Structured feature matrix](https://help.structured.app/en/articles/1897986)، [task model](https://help.structured.app/en/articles/338050) و [focus timer](https://help.structured.app/en/articles/331010): timeline روزانه، Inbox، all-day، duplication، subtasks، notes، icon/color، recurrence، notification سفارشی و focus interval.

## HabitNow screenshot findings

| Observed option | Perfect contract |
|---|---|
| Task و Habit در یک editor با سطح ساده و advanced | editor بخش‌بندی‌شده؛ quick capture هیچ‌وقت با تنظیمات پیشرفته متوقف نمی‌شود |
| daily، weekdays، interval، چند روز ماه، آخر ماه، چند تاریخ سال، پایان/تعداد occurrence | payload سازگار با نسخه‌های قبلی و evaluator مرکزی؛ UI فقط گزینه‌ای را نشان می‌دهد که domain واقعاً اجرا می‌کند |
| هدف N بار در week/month | frequency contract مستقل از interval تقویمی |
| flexible recurrence که تا انجام‌شدن در Today بماند | recovery/carry صریح با سقف؛ در سقف یا policy `ask` آیتم پنهان نمی‌شود |
| Habitهای check/count/duration/amount/avoidance | occurrence log تاریخ‌دار؛ سری Habit هرگز complete نمی‌شود |
| checklist tracking با شرط موفقیت all/custom | checklist itemهای stable-id و success condition داخل tracking payload |
| reminderهای متعدد، snooze/postpone و quiet hours | reminder از due date جدا می‌ماند؛ permission failure کار محلی را متوقف نمی‌کند |
| timerهای stopwatch/countdown/interval | Focus session محلی و قابل بازیابی؛ پایان timer به‌تنهایی task را complete نمی‌کند |
| widget با customization | Perfect Today از UI بومی Android، سه layout و فهرست اسکرول‌پذیر استفاده می‌کند؛ کنترل چهارحالته داخل widget فعال است |

## Product decisions adopted

1. یک موتور تقویمی مشترک باید Today در صفحه، reminder و widget را تولید کند؛ هیچ surface نباید recurrence را جداگانه حدس بزند.
2. برنامه‌ریزی و deadline دو مفهوم جدا هستند. یک task می‌تواند زمان کار، due/deadline، duration و reminderهای مستقل داشته باشد.
3. Task outcome چهار حالت دارد: خالی، انجام، انجام‌نشده و درصدی. Habit measurement مسیر مستقل دارد.
4. recurrence source هرگز با تکمیل occurrence پایان نمی‌یابد. exception، pause، end date، occurrence limit و timezone باید deterministic باشند.
5. پیش‌فرض‌ها کم‌اصطکاک‌اند، اما هر Task/Habit می‌تواند tracking، recovery، reminders، checklist، properties، category، focus و recurrence خودش را override کند.
6. Perfect local-first و تک‌مالک است؛ collaboration، AI cloud capture و integrationهای عمومیِ رقبا وارد محصول نمی‌شوند.

## Explicit non-copy boundary

Orbit Day، آیکون مداری، wordmark منتخب، پالت پاستلی، نسبت‌های layout و واژگان Perfect مستقل هستند. منابع بالا فقط برای منطق محصول و سناریوهای تنظیم‌پذیری استفاده شده‌اند؛ asset، نام، صفحه یا trade dress هیچ اپی بازتولید نشده است.
