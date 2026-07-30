# State

- Current status: `active`
- Last updated: 2026-07-30T04:40:00+03:30
- Owner: Codex

## Current State
بازسازی local-first و تجربهٔ Orbit Day در source کامل و گیت محلی سبز است. Android release روی emulator API 35 و Pixel Launcher واقعی اجرا شده و ویجت resize/scroll/four-state را گذرانده است. هیچ migration زنده، حذف داده یا تغییر Supabase خارجی انجام نشده است. Windows artifact به hosted CI سپرده می‌شود چون میزبان فعلی Visual Studio C++ ندارد.

## Decisions
| Date | Decision | Reason | Source |
|---|---|---|---|
| 2026-07-27 | Orbit Day به‌عنوان جهت تجربه انتخاب شد. | مدار زمان، برنامهٔ روز و quick capture را به یک مدل شخصی و قابل‌فهم تبدیل می‌کند. | انتخاب صریح کاربر |
| 2026-07-27 | آیکون پایین-راستِ برد آیکون انتخاب شد. | مرکز تیره، سه قطعهٔ پاستلی و تیک در اندازهٔ کوچک یک silhouette به‌یادماندنی می‌دهد. | انتخاب صریح کاربر |
| 2026-07-27 | لوگوتایپ پایین-چپِ برد نخست انتخاب شد. | کاربر این ریتم نرم و فشرده را از میان گزینه‌ها برگزید. | انتخاب صریح کاربر |
| 2026-07-27 | عمودی و افقی هر دو first-class هستند. | طرح موبایل نباید صرفاً کش بیاید؛ هر layout class ترکیب مستقل دارد. | انتخاب صریح کاربر |
| 2026-07-27 | هر task و habit باید قابل‌سفارشی‌سازی و سناریومحور باشد. | اپ نباید با حالت‌های شخصیِ برنامه‌ریزی، عادت یا شکست sync کم بیاورد. | انتخاب صریح کاربر |
| 2026-07-27 | تا نبودن مجوز جداگانه، تغییر Supabase زنده اجرا نمی‌شود. | امنیت دادهٔ شخصی و حفظ migration history. | محدودهٔ درخواست/پروتکل rebuild |
| 2026-07-27 | هدف‌ها فقط Android و Windows هستند. | کاربر Web را صریحاً از محدوده خارج کرد. | دستور صریح کاربر |
| 2026-07-27 | رابط انگلیسی‌اول است و Persian/RTL برای محتوای کاربر first-class می‌ماند. | سرعت استفادهٔ روزمره همراه با متن و تاریخ دوزبانه. | انتخاب صریح کاربر |
| 2026-07-27 | backup/export دستی و فایل ضمیمهٔ باینری در v1 ساخته نمی‌شود. | sync خصوصی Supabase مسیر بازیابی اصلی است؛ Note/Link/Checklist نیاز فعلی را پوشش می‌دهد. | انتخاب صریح کاربر |
| 2026-07-27 | `perfect_items` و کلید local v1 فقط import-compatible می‌مانند؛ مدل v2 additive است. | از دست‌رفتن دادهٔ موجود، overwrite و resurrection حذف‌شده‌ها نباید ممکن باشد. | preservation contract + audit sync |
| 2026-07-27 | هر mutation در یک transaction محلی همراه با outbox idempotent ثبت می‌شود. | UI همیشه local-first می‌ماند و retry نباید mutation تکراری بسازد. | audit sync |
| 2026-07-27 | Android build با override سازگار `path_provider_android: 2.2.22` تثبیت شد. | نسخهٔ transitive جدید `jni` با Gradle فعلی سازگار نبود؛ APK debug پس از override ساخته شد. | build evidence |
| 2026-07-30 | ویجت باید چهار outcome را مستقیم و پایدار در host native بچرخاند. | آزمایش Pixel Launcher چرخه، scroll و native replay queue را اثبات کرد. | runtime evidence در `05-verification.md` |

## Blockers
- هیچ blocker برای source، تست یا Android runtime وجود ندارد.
- Windows local build به‌علت نبود Visual Studio و workload C++ مسدود است؛ hosted CI مسیر اثبات artifact است.
- برای اثبات واقعی RLS/realtime و اجرای migration، پروژه و credential خصوصی مالک لازم است؛ این محدودیت جلوی local-first runtime نمی‌گیرد.

## Done
- مخزن پایه، CI و اپ Flutter اولیه در وضعیت clean ثبت شده‌اند.
- مسیر بصری، آیکون و لوگوتایپ انتخاب شده‌اند و در `03-previews.md` به‌عنوان mock ثبت شده‌اند.
- task docs، requirement ledger، preservation contract و قواعد layout عمودی/افقی ایجاد شدند.
- audit sync: ریسک race، overwriteِ dirty local، LWW سراسری، delete resurrection و owner/session leakage ثبت شد.
- audit UX: قرارداد compact / medium / expanded، fallback large-text و asset decomposition ثبت شد.
- audit native: Android debug build موفق شد؛ Windows host prerequisiteها هنوز کامل نیستند.
- migration افزایشی v2، Drift/outbox، UI کامل و native widget پیاده‌سازی شده‌اند؛ migration زنده اعمال نشده است.
- analyzer، ۱۶۲ تست، Android release build/install، portrait/landscape، launcher identity و widget host runtime پاس‌اند.

## Remaining
- دریافت و بازبینی گزارش frozen Critics.
- commit/fast-forward main/push و مشاهدهٔ CI همان SHA.
- hosted Windows artifact و در آینده live Supabase/two-device convergence با credential مالک.
