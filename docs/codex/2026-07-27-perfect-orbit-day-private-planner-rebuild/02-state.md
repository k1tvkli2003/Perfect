# State

- Current status: `active`
- Last updated: 2026-08-06T03:34:50+03:30
- Owner: Codex

## Current State
Perfect Cycle 1 روی commit `a793531279174f735ad1e247f96a5213613dabb1` با workflow موفق [`31041370535`](https://github.com/k1tvkli2003/Perfect/actions/runs/31041370535) و release immutable [`v1.1.0-build.2036`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2036) بسته شد. Cycle 2 نیز روی commit `5f49334a82189d976fa926b31b8f9c0488113a06` با run موفق [`31051013501`](https://github.com/k1tvkli2003/Perfect/actions/runs/31051013501) و release [`v1.1.0-build.2037`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2037) بسته شد؛ install-over `1.1.0.36 → 1.1.0.37` و Setup clean/rerun پاس است. Cycle 3 اکنون محلی کامل است: footer موبایل بدون label و بدون stadium پیش‌فرض، tile پاستلی منتخب، Quick Capture سه‌مسیرهٔ Plan/Perfect AI/Voice با one-surface morph، SVGهای اختصاصی AI/Voice، safe core درصد، ساعت‌های متقارن Orbit و clearance آخرین ردیف. analyzer، ۳۵۸/۳۵۸ تست و Workspace ۵۵/۵۵ سبزند؛ runtime API 35 با renderer رسمی `host` چند چرخهٔ باز/بسته‌شدن را بدون خروج QEMU/ADB پاس کرده است. push/release Cycle 3 هنوز در همین checkpoint در انتظار است. لجر کامل در `10-critics-tasks-habits-editor-ledger.md` است.

بازسازی local-first و تجربهٔ Orbit Day در commit `1b8468b18ec8edc2645ab73dffff23a6829ba0ea` با exact-HEAD run [`30721214315`](https://github.com/k1tvkli2003/Perfect/actions/runs/30721214315) (`#30`) و conclusion `success` اثبات شده است؛ analyzer و 266/266 تست سبزند. Android `1.1.0+2030` با package/label/سه ABI/امضای v2 و fingerprint ثابت پاس است. Windows `1.1.0.30` با identity/publisher ثابت و signer `CA=false` پاس است؛ Setup مستقل نصب تمیز، rerun، حفظ package family/LocalState و عدم تغییر Trusted Root را ثابت کرد. Release immutable [`v1.1.0-build.2030`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2030) دقیقاً APK، Setup و portable را دارد؛ portable شامل 37 فایل runtime و صفر MSIX/CER/checksum/log/ZIP تو‌در‌تو است. Function v3 و owner-scoped backend زنده‌اند؛ شکاف‌های signed-in/hover/jank همچنان صادقانه بازند.

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
| 2026-07-31 | Windows MSIX از signer قدیمی `CA=true` به self-signed end-entity code-signing با `CA=false` مهاجرت کرد؛ package identity و publisher ثابت ماندند. | package signer نباید قابلیت CA داشته باشد؛ certificate جایگزین فقط digital signature/code-signing دارد و در `TrustedPeople` پین می‌شود. | commit `fe24d33`؛ provisioner synthetic PASS؛ CI run `#20` |
| 2026-07-31 | run `#20` نخستین baseline signer جدید است، نه install-over proof. | artifact پایین‌تری با thumbprint `1424F286…BA24` وجود نداشت؛ workflow این حالت را صریحاً گزارش و بدون ادعای upgrade موفق تمام کرد. | log مرحلهٔ `Prove MSIX install-over preserves LocalState` در run `30637250609` |
| 2026-07-31 | run `#21` اولین Windows install-over واقعی را بست. | نصب `1.1.0.20 → 1.1.0.21` با signer یکسان، package family و hash marker دقیق LocalState را حفظ کرد. | run `30639359490`، job `91185076156` |
| 2026-08-02 | هر trusted main success یک Release immutable با دقیقاً سه asset نصب‌پذیر می‌سازد. | APK، Setup و portable باید مستقیماً قابل‌استفاده باشند؛ CER/MSIX خام/checksum/log فقط transport داخلی‌اند. Setup نیز trust پین‌شده و نصب/ارتقای MSIX را خودش انجام می‌دهد. | run `30721214315` + release `v1.1.0-build.2030` |
| 2026-08-06 | Tasks به‌طور پیش‌فرض همهٔ کارهای Open را نشان می‌دهد و فیلترهای compact فقط در صورت درخواست باز می‌شوند. | Inbox نباید کارهای زمان‌دار معتبر را پنهان کند و ابزار فیلتر نباید قبل از خود کارها نصف viewport را اشغال کند. | Critics C2/C4 + Android runtime + workspace tests |

## Blockers
- هیچ blocker برای source، analyzer، 266/266 تست محلی، exact-SHA CI یا انتشار install-ready وجود ندارد.
- hosted Android، Windows portable، signed MSIX و true Windows install-over برای runهای متوالی `#20 → #21 → #22` اثبات شده‌اند.
- build محلی Windows به‌علت نبود Visual Studio و workload C++ ممکن نیست. portable نهایی دانلودشده با title/icon صحیح در حالت restored/maximized و resizeهای زندهٔ wide/short/compact اجرا شد؛ short-height scroll و دسترسی همهٔ actionهای auth پاس‌اند. signed-in workspace، hover/focus semantics و jank هنوز ثبت نشده‌اند.
- signer نهایی Windows و Android دیگر blocker نیستند؛ backup hash، provisioner مصنوعی و rerun identity stability پاس‌اند.
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
- analyzer و مجموعهٔ کامل ۲۶۵ تست پاس‌اند؛ Workspace، release، AI، responsive، widget، signing و Deno checks نیز در گیت جاری سبزند.
- race هم‌زمانی foreground/WorkManager با یک جدول local-only در Drift schema v2 و claim اتمیک SQLite بسته شد؛ تست دو connection ثابت می‌کند sequence بالاتر برای one-off و recurring همیشه نهایی می‌ماند.
- گزارش frozen هشت‌صفحه‌ای Critics رندر و صفحه‌به‌صفحه بازبینی شد؛ همهٔ یافته‌های actionable آن بسته شدند و بدهی P3 فایل‌های presentation به‌صورت شفاف باقی مانده است.
- commit `fea3ddc7dd16741e1936a5b61de0b4785c079e67` در CI run `30641054596` (`#22`) با هر سه job موفق، سه artifact Android/MSIX/portable و install-over واقعی تکمیل شد.
- migrationهای `20260730190000`، `20260730192000` و `20260730210000` روی Supabase زنده اعمال شدند؛ agent plan، conversation/message sync، action audit، retention و metadata guard با عمق محدود owner-scoped آماده‌اند.
- Edge Function سخت‌شدهٔ `perfect-agent` نسخهٔ ۳ با hash ثبت‌شده، `ACTIVE` و `verify_jwt=true` زنده است؛ probe بدون auth پاسخ 401/`UNAUTHORIZED_NO_AUTH_HEADER` می‌گیرد.
- Tablet Day Deck جدید در compact/expanded portrait و `1200×800` landscape بازبینی تصویری شده و reflow عرض‌های 768/900/1024، متن 200٪، rail persistence و عدم هم‌پوشانی AI/capture تست شده‌اند.
- JKS/PFX ثابت خصوصی ساخته شد و شش secret به‌همراه دو fingerprint variable در GitHub ثبت شد.
- audit نهایی release، `queue: max` برای serialization، placeholder صحیح `VERSION_CODE`، نصب machine-wide TrustedPeople/MSIX و چک‌لیست backup آفلاین signing را بست؛ release contract اکنون ۷/۷ سبز است.
- APK نهایی `build/private-update-proof/perfect-1.1.0+2004.apk` با SHA-256 برابر `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`، اندازهٔ ۶۹٬۱۸۹٬۳۵۶ بایت، package `com.k1tvkli2003.perfect`، سه ABI، zipalign و امضای v2 معتبر ساخته شد. نصب روی `1003` و نصب مجدد `2004`، UID `10213`، `firstInstallTime`، data directory و `appWidgetId=5` را حفظ کرد.
- ابزار backup/restore هویت امضا با یک round-trip مصنوعی واقعی از JKS/PFX، private-key proof، tamper/wrong-password/non-empty-target و rollback مجوزها پاس شد؛ هیچ signing root واقعی در تست خوانده نشد.
- provisioner synthetic test، hash پشتیبان واقعی و rerun هویت پاس‌اند. Windows package signer اکنون end-entity `CA=false` با thumbprint `1424F286C0DCACF36701D4C1AF0C0D830F01BA24` است؛ Android signer بدون تغییر `144E87CB67A9074EBC11CFED26A96EE1ACE697A861C2EABD77C4203A4F49B0AF` ماند.
- artifactهای run `#20` مستقلاً بررسی شدند: Android `1.1.0+2020`، package `com.k1tvkli2003.perfect`، label `Perfect!`، سه ABI، v2 و hashهای معتبر؛ MSIX `1.1.0.20` با identity/publisher ثابت، signer `CA=false`، 137 entry و hashهای معتبر؛ portable با 37/37 checksum و executable responsive.
- run `#21` (`30639359490`) با هر سه job سبز شد. Windows `1.1.0.20 → 1.1.0.21` را نصب کرد و package family/LocalState را حفظ کرد؛ artifactهای تازهٔ Android `1.1.0+2021`، MSIX `1.1.0.21` و portable نیز با صفر hash mismatch و signerهای ثابت مستقلاً بررسی شدند.

## Remaining
- بستن findings باقی‌ماندهٔ C3 و C5 تا C12 در `10-critics-tasks-habits-editor-ledger.md`؛ C1، C2 و C4 بسته‌اند و بخش Task-filter از C5 نیز بسته شده است.
- تبدیل Focus فعلی از sheet تایمر به Focus Studio پس از quality gate فعال Tasks/Habits/editor؛ قرارداد محصول و مرز permissionها در `09-product-opportunity-roadmap.md` تثبیت شده است.
- اجرای smoke احراز‌شدهٔ provider فقط پس از تنظیم امن کلید rotateشده؛ Function v3 و auth boundary آن زنده و اثبات‌شده‌اند.
- session احراز‌شده در نصب Android قابل اثبات نبود، چون دستگاه پیش از آزمون signed out بود؛ widget binding و دادهٔ package حفظ شدند، اما حفظ session لاگین نباید ادعا شود.
- convergence واقعی Android↔Windows روی دو نصب نهایی با همان حساب owner.
- signed-in phone/tablet main workspace، signed-in Windows workspace/hover/jank، signed-in widget Quick Add و notification/OEM/reboot روی سخت‌افزار فیزیکی هنوز runtime proof ندارند.
- AI text/voice/proposal-apply مثبت فقط پس از تنظیم provider key rotateشده end-to-end اجرا شود.
