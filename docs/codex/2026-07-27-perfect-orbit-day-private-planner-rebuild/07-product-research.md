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

### Dribbble composition pass — 2026-07-30

پس از رد شدن golden تبلت اولیه، جست‌وجو داخل خود Dribbble و image search روی planner/dashboard/habit/AI انجام شد. این‌ها fidelity target نیستند؛ فقط رابطه‌های مفیدشان استخراج شد:

- [AI Assistant App UI — Chat and Daily Planner](https://dribbble.com/shots/27539054-AI-Assistant-App-UI-Chat-and-Daily-Planner): سه starter path روشن به‌جای chat box مبهم و استفادهٔ معنایی از zoneهای رنگی.
- [Smart Planner UI — Your Schedule, Upgraded by AI](https://dribbble.com/shots/25831476-Smart-Planner-UI-Your-Schedule-Upgraded-by-AI): خلاصهٔ وضعیت روز، schedule قابل اسکن و Assistant متصل به plan.
- [Task Management — Dashboard & Calendar](https://dribbble.com/shots/23712431-Task-Management-Dashboard-Calendar): timeline زمانی به‌عنوان operational spine، نه کارت‌های جدا و معلق.
- [Real-time Tasks Tracker Web App](https://dribbble.com/shots/10778084-Real-time-Tasks-Tracker-Web-App): ترکیب calendar، goals، focus، to-do و habit در پنل‌های مرتبط برای سطح tablet.
- [Confetti habit-tracking dashboard](https://www.tryconfetti.io/): overview هفتگی در کنار panel عملیاتی روز جاری؛ آمار فقط وقتی ارزش دارد که به action نزدیک باشد.

نتیجهٔ اختصاصی Perfect: rail فقط مسیر را نگه می‌دارد؛ Day Compass Stage و Day Stream دو instrument اصلی‌اند؛ Habit Pulse/Next Up به جریان روز وصل می‌شوند؛ AI به‌صورت command pill کوچک بالای capture شروع و در حالت باز به workspace منظم تبدیل می‌شود. void بزرگ، Orbit کوچک و دو نوار تمام‌عرض جداگانه مردودند.

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
| widget با customization | Perfect Today از UI بومی Android، چهار family کوچک/بلند/عریض/بزرگ و فهرست اسکرول‌پذیر استفاده می‌کند؛ کنترل چهارحالته داخل widget فعال است |

## Product decisions adopted

1. یک موتور تقویمی مشترک باید Today در صفحه، reminder و widget را تولید کند؛ هیچ surface نباید recurrence را جداگانه حدس بزند.
2. برنامه‌ریزی و deadline دو مفهوم جدا هستند. یک task می‌تواند زمان کار، due/deadline، duration و reminderهای مستقل داشته باشد.
3. Task outcome چهار حالت دارد: خالی، انجام، انجام‌نشده و درصدی. Habit measurement مسیر مستقل دارد.
4. recurrence source هرگز با تکمیل occurrence پایان نمی‌یابد. exception، pause، end date، occurrence limit و timezone باید deterministic باشند.
5. پیش‌فرض‌ها کم‌اصطکاک‌اند، اما هر Task/Habit می‌تواند tracking، recovery، reminders، checklist، properties، category، focus و recurrence خودش را override کند.
6. Perfect local-first و تک‌مالک است؛ collaboration و integrationهای عمومیِ رقبا وارد محصول نمی‌شوند. AI خصوصی فقط از Edge Function مالک‌محور، context خوانده‌شده زیر RLS و پیشنهاد قابل‌مرور/تأییدشونده استفاده می‌کند؛ provider secret و raw payload هرگز وارد client نمی‌شوند.

## Explicit non-copy boundary

Orbit Day، wordmark منتخب، پالت پاستلی، نسبت‌های layout، واژگان Perfect و نشان Day Compass مستقل هستند. Day Compass از brief مفهومی Perfect و بدون حروف ساخته و پس از مقایسهٔ جهت‌های متفاوت توسط مالک انتخاب شد؛ نه از asset یا trade dress رقبا. منابع بالا فقط برای منطق محصول و سناریوهای تنظیم‌پذیری استفاده شده‌اند؛ asset، نام یا صفحهٔ هیچ اپی بازتولید نشده است.
