# State

- Current status: `active`
- Last updated: 2026-07-31T00:35:00+03:30
- Owner: Codex

## Current State
بازسازی local-first و تجربهٔ Orbit Day در worktree نهایی فعال است؛ `d56455b` فقط آخرین baseline پوش‌شده و CI‌شده است. ترکیب expanded Windows از حالت Orbit کوچک و فضای مرده به Day Compass/Runway در مقیاس اصلی، Day Stream مجاور و inspector زمینه‌ای بازسازی شده است. startup اکنون نخستین frame برند را بدون انتظار Supabase نشان می‌دهد و Sync Cloud برای خطاهای offline و needs-attention retry خودکارِ bounded دارد. AI Dock، history hydration میان دستگاه‌ها، proposal قابل‌مرور و context امن owner-scoped در source یکپارچه‌اند. migration `20260730220000` روی Supabase زنده ثبت شده و بررسی‌ها اجرای authenticated، منع anon، محدودیت owner/limit و نبود `SELECT` مستقیم روی `planner_entities` را تأیید کرده‌اند. `perfect-agent` نسخهٔ ۳ با hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b`، وضعیت `ACTIVE` و `verify_jwt=true` زنده است؛ درخواست بدون Authorization پاسخ 401/`UNAUTHORIZED_NO_AUTH_HEADER` می‌گیرد. APK خصوصی `1.1.0+2004` با هویت و گواهی نهایی ساخته و دو بار install-over شد؛ UID، زمان نصب اولیه، data directory و widget binding حفظ شدند. CI همان SHA و artifactهای تازهٔ Windows هنوز شاهد نهایی ندارند.

## Decisions
| Date | Decision | Reason | Source |
|---|---|---|---|
| 2026-07-27 | Orbit Day به‌عنوان جهت تجربه انتخاب شد. | مدار زمان، برنامهٔ روز و quick capture را به یک مدل شخصی و قابل‌فهم تبدیل می‌کند. | انتخاب صریح کاربر |
| 2026-07-27 | آیکون پایین-راستِ برد آیکون انتخاب شد؛ این تصمیم در ۲۰۲۶-۰۷-۳۰ superseded شد. | این سطر تاریخ تصمیم قبلی را حفظ می‌کند، اما دیگر قرارداد نهایی launcher نیست. | انتخاب قبلی کاربر + بازگشایی صریح بعدی |
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
| 2026-07-30 | source کاندید قبلی و Windows شفاف‌اند؛ Android کاندید قبلی از tile هلویی پاستلی استفاده می‌کند. | Pixel Launcher شفافیت adaptive را مشکی و legacy را سفید normalize می‌کند؛ این تصمیم platformی فقط برای asset فعلی اثبات شده و باید پس از انتخاب تازه دوباره ارزیابی شود. | سه runtime screenshot مقایسه‌ای + contract test |
| 2026-07-30 | تصمیم نهایی launcher باز شد و ۱۰ کانسپت مستقل ۵۱۲×۵۱۲ برای انتخاب ساخته شد. | کاربر صریحاً خواست آیکون بدون نگاه به قبلی از نو طراحی شود؛ فایل‌های chroma هنوز preview هستند و هیچ‌کدام canonical نیستند. | دستور صریح کاربر + `icon-concepts-v2/README.md` + dimension inspection |
| 2026-07-30 | Day Compass متقارن به‌عنوان launcher نهایی انتخاب شد. | شش ماژول پاستلی در سه جفت رنگی، پیرامون هستهٔ شخصی تیره، هم در اندازهٔ کوچک خواناست و هم با مفهوم برنامه‌ریزی متعادل سازگار است. | انتخاب صریح کاربر + source منتخب ۱۲۵۴ + master شفاف ۵۱۲ |
| 2026-07-30 | master/Windows شفاف می‌مانند و Android adaptive از fill پاستلی `#FFF3E8` استفاده می‌کند. | Pixel Launcher پس‌زمینهٔ adaptive شفاف را واقعاً مشکی کرد؛ fill پاستلی فقط محدودیت mask سیستم را مهار می‌کند و هیچ tile سفید/مشکی در assetها وجود ندارد. | دو نصب و screenshot مقایسه‌ای Pixel Launcher |
| 2026-07-30 | GitHub Actions run `30519295088` مرجع hosted build برای `d56455b` است. | `main` و `origin/main` دقیقاً همین SHA هستند؛ Android و Windows jobs موفق و دو artifact unexpired ثبت شده‌اند، اما signed MSIX upload skipped است. | Git/GitHub Actions API |
| 2026-07-30 | Android tablet یک layout class مستقل است و navigation تبلت/Windows باید collapse شود. | کشیدن UI موبایل یا ستون پهن ثابت، فضای برنامه‌ریزی را هدر می‌دهد. | دستور صریح کاربر |
| 2026-07-30 | Perfect AI به‌صورت dock جمع‌شونده بالای footer، با متن/ویس و preview اجباری write ساخته می‌شود. | دسترسی سریع بدون شلوغی و جلوگیری از side effect تأییدنشده. | دستور کاربر + قرارداد AI |
| 2026-07-30 | Sync Cloud سه‌حالتهٔ سبز/زرد/قرمز بالای صفحه است و retry خودکار ادامه دارد. | وضعیت sync باید فوری، غیرمسدودکننده و قابل‌فهم باشد. | دستور صریح کاربر |
| 2026-07-30 | emoji خام UI ممنوع و motion/hover/transition یک سیستم first-class است. | هویت مستقل، ثبات بین فونت‌ها و کیفیت interaction پنهان لازم است. | دستور صریح کاربر + self-improve |
| 2026-07-30 | هندسهٔ UI باید constraint-driven و ترکیبی باشد، نه مختص یک رزولوشن و نه متعصبانه درصدی. | intrinsic/flex/bounded fraction/aspect/fixed semantic token هرکدام برای نقش مناسب انتخاب می‌شوند؛ breakpoint با شکستن واقعی محتوا تعیین و state حفظ می‌شود. | تصحیح صریح کاربر + self-improve |
| 2026-07-30 | composition تبلت قبلی رد شد و باید به Day Compass Stage + Day Stream بازسازی شود. | golden قبلی Orbit کوچک و معلق، timeline جدا، void عمودی عظیم و دو نوار footer ضمیمه‌ای داشت؛ عبور تست responsive به‌تنهایی کیفیت composition را ثابت نمی‌کند. | رد صریح کاربر + بررسی تصویری golden |
| 2026-07-30 | Dribbble فقط منبع استخراج الگو است، نه fidelity target. | timeline به‌عنوان operational spine، رنگ برای تفکیک معنایی و AI با starter path روشن مفیدند؛ فرم نهایی باید هویت و منطق Perfect را داشته باشد. | تحقیق browser داخل Dribbble + modernize/style |
| 2026-07-30 | Widget Quick Add یک popup کوچک و local-first باز می‌کند. | ثبت از home screen نباید کاربر را وارد جریان سنگین اپ کند. | دستور صریح کاربر |
| 2026-07-30 | signing lineage خصوصی provision شد و buildهای trusted fail-closed هستند. | نسخهٔ بعدی باید روی نسخهٔ قبلی نصب شود و session/data را نگه دارد. | GitHub secrets/variables + release contract |
| 2026-07-30 | version پایه به `1.1.0+2000` منتقل شد و CI، Android code را از epoch + run number می‌سازد. | جلوگیری از regression نسبت به نصب `1003` و حفظ install-over؛ run بعدی شمارهٔ ۴ باید code `2004` بسازد. | `pubspec.yaml` + workflow + ۵ release-contract test |
| 2026-07-30 | context هوش مصنوعی فقط از RPC امن owner-scoped خوانده می‌شود؛ direct `planner_entities` grant ممنوع است. | agent باید ساختار planner را بفهمد، بدون اینکه سطح دسترسی عمومی client گسترش یابد. | migration `20260730220000` + live privilege probes |
| 2026-07-30 | نخستین frame اپ از راه‌اندازی شبکه جدا شد و خطای قرمز sync نیز retry bounded دارد. | اپ local-first نباید هنگام bootstrap یا خطای پایدار شبکه متوقف/بی‌حرکت شود. | bootstrap/sync tests + full suite |
| 2026-07-30 | buildهای installable یک ref با `queue: max` صف می‌شوند و artifact Android از placeholder دقیق `VERSION_CODE` استفاده می‌کند. | لغو/هم‌زمانی buildهای monotonic و نام‌گذاری مبهم می‌توانست پیوستگی update را مخدوش کند. | workflow + private build contract + release audit |
| 2026-07-30 | نصب خصوصی Windows نیازمند تطبیق thumbprint، import گواهی در `LocalMachine\TrustedPeople` و سپس `Add-AppxPackage` است؛ signing root نیز backup رمزنگاری‌شدهٔ آفلاین می‌خواهد. | package خصوصی store trust ندارد و GitHub Secrets قابل دانلود/بازیابی نیستند. | README private-install and signing-backup checklist |

## Blockers
- هیچ blocker برای source، analyzer یا تست‌های محلی وجود ندارد.
- گیت انتخاب هویت، deploy Function v3 و Android install-over بسته شده‌اند؛ hosted CI تازه و Windows install-over برای SHA نهایی هنوز اجرا نشده‌اند.
- اجرای محلی Windows به‌علت نبود Visual Studio و workload C++ ممکن نیست. hosted CI ساخت unpackaged را اثبات کرده، اما اجرای exe، Explorer/taskbar/window identity و signed MSIX را اثبات نکرده است.
- signing identity دیگر blocker نیست؛ APK محلی fingerprint نهایی Android را اثبات کرده و hosted CI تازه باید Android/MSIX را دوباره با fingerprintهای provisionشده اثبات کند.
- اثبات migration/RLS/RPC/Auth بسته شده است؛ convergence end-to-end روی دو نصب واقعی باقی مانده و جلوی local-first runtime را نمی‌گیرد.
- کلید AvalAI موجود باید در dashboard rotate شود؛ مقدار جدید فقط از مسیر secret امن Supabase ثبت می‌شود و live AI smoke تا آن زمان اجرا نمی‌شود.

## Done
- مخزن پایه، CI و اپ Flutter اولیه در وضعیت clean ثبت شده‌اند.
- Orbit Day، لوگوتایپ و Day Compass انتخاب و سیم‌کشی شده‌اند؛ comparisonها فقط سابقهٔ تصمیم‌اند.
- task docs، requirement ledger، preservation contract و قواعد layout عمودی/افقی ایجاد شدند.
- audit sync: ریسک race، overwriteِ dirty local، LWW سراسری، delete resurrection و owner/session leakage ثبت شد.
- audit UX: قرارداد compact / medium / expanded، fallback large-text و asset decomposition ثبت شد.
- audit native: Android debug build موفق شد؛ Windows host prerequisiteها هنوز کامل نیستند.
- هشت migration افزایشی و سخت‌سازی‌شده روی پروژهٔ خصوصی اعمال و با history محلی هم‌نسخه شده‌اند؛ owner gate، RLS، RPC idempotency/cursor/context و پاک‌سازی smoke زنده پاس‌اند.
- analyzer و مجموعهٔ کامل ۲۶۲ تست پاس‌اند؛ Workspace ۴۴/۴۴، release contract پنج/پنج، AI متمرکز ۳۳ تست و Deno check نیز سبزند.
- race هم‌زمانی foreground/WorkManager با یک جدول local-only در Drift schema v2 و claim اتمیک SQLite بسته شد؛ تست دو connection ثابت می‌کند sequence بالاتر برای one-off و recurring همیشه نهایی می‌ماند.
- گزارش frozen هشت‌صفحه‌ای Critics رندر و صفحه‌به‌صفحه بازبینی شد؛ همهٔ یافته‌های actionable آن بسته شدند و بدهی P3 فایل‌های presentation به‌صورت شفاف باقی مانده است.
- commit `d56455b` روی `main` و `origin/main` یکسان است؛ CI run `30519295088` با هر دو job موفق، Android artifact و Windows unpackaged artifact تکمیل شد.
- migrationهای `20260730190000`، `20260730192000` و `20260730210000` روی Supabase زنده اعمال شدند؛ agent plan، conversation/message sync، action audit، retention و metadata guard با عمق محدود owner-scoped آماده‌اند.
- Edge Function سخت‌شدهٔ `perfect-agent` نسخهٔ ۳ با hash ثبت‌شده، `ACTIVE` و `verify_jwt=true` زنده است؛ probe بدون auth پاسخ 401/`UNAUTHORIZED_NO_AUTH_HEADER` می‌گیرد.
- Tablet Day Deck جدید در compact/expanded portrait و `1200×800` landscape بازبینی تصویری شده و reflow عرض‌های 768/900/1024، متن 200٪، rail persistence و عدم هم‌پوشانی AI/capture تست شده‌اند.
- JKS/PFX ثابت خصوصی ساخته شد و شش secret به‌همراه دو fingerprint variable در GitHub ثبت شد.
- audit نهایی release، `queue: max` برای serialization، placeholder صحیح `VERSION_CODE`، نصب machine-wide TrustedPeople/MSIX و چک‌لیست backup آفلاین signing را بست؛ release contract همچنان ۵/۵ سبز است.
- APK نهایی `build/private-update-proof/perfect-1.1.0+2004.apk` با SHA-256 برابر `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`، اندازهٔ ۶۹٬۱۸۹٬۳۵۶ بایت، package `com.k1tvkli2003.perfect`، سه ABI، zipalign و امضای v2 معتبر ساخته شد. نصب روی `1003` و نصب مجدد `2004`، UID `10213`، `firstInstallTime`، data directory و `appWidgetId=5` را حفظ کرد.
- ابزار backup/restore هویت امضا با یک round-trip مصنوعی واقعی از JKS/PFX، private-key proof، tamper/wrong-password/non-empty-target و rollback مجوزها پاس شد؛ هیچ signing root واقعی در تست خوانده نشد.

## Remaining
- اجرای smoke احراز‌شدهٔ provider فقط پس از تنظیم امن کلید rotateشده؛ Function v3 و auth boundary آن زنده و اثبات‌شده‌اند.
- session احراز‌شده در نصب Android قابل اثبات نبود، چون دستگاه پیش از آزمون signed out بود؛ widget binding و دادهٔ package حفظ شدند، اما حفظ session لاگین نباید ادعا شود.
- build و artifactهای hosted Android/Windows برای SHA تازه و بررسی خروجی Windows/MSIX.
- convergence واقعی Android↔Windows روی دو نصب نهایی با همان حساب owner.
- آزمون upgrade دو نسخهٔ امضاشده با حفظ session/data در Android و Windows.
- commit/push `main` و مشاهدهٔ CI همان SHA. branch محلی `codex/perfect-orbit-day` قبلاً پس از اثبات ancestor بودن حذف شده و فقط `main` باقی مانده است.
