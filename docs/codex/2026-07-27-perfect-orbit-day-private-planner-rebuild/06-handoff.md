# Handoff

## Current Stage 12 gate — 2026-09-23

Guided Command Center is implemented and visually reviewed on native Android
phone/tablet preview; exact current-source APK launched as
`com.k1tvkli2003.perfect.preview`. Full Flutter suite passes 505/505,
analyzer and formatter are clean. The 8 workspace golden tests and 5 header
tests pass after selective, hash-receipted baseline refresh; canonical design
reference images are unchanged. Shared emulator was briefly commandeered by
Gauss; the unrelated screenshot was discarded, and top activity/package was
asserted before the accepted Perfect capture.

Stage 12 remains open until the exact-source Windows CI/launch and native
release/upgrade proof pass. Local Visual Studio BuildTools lacks ATL;
installer repair requires elevation (5007). The private hosted Windows runner
is the next independent gate. Do not infer Windows proof from a stale local
executable or Android runtime. PWA remains in scope for later numbered stage
owners under the 2026-09-17 amendment and is not prepared.

## Historical source checkpoint — 2026-09-17

Shared `_groupTodayRows` now forwards `PlannerTodayStreamEntry` to compact and
timeline builders, removing duplicated grouping and resolved-row map lookups.
No design change. Workspace 63/71 passed; eight known golden comparisons fail.
All eight actual PNG hashes equal pre-refactor output; analyzer passes.
Do not repeat unchanged tests expecting visual acceptance. Resume the Stage 12
preview selection/runtime gate with image-capable inspection, then finish
next-row/anchor/retry contracts. Full stage and Android/Windows/PWA delivery
remain open. Latest details in `05-verification.md`.
The compact Today/AI tests now use `_setTestViewSize` and assert MediaQuery/render
size 390x844. Both reach the unchanged golden failures; actual-image hashes remain
identical. Do not repeat the hypothesis that viewport mismatch caused these two
diffs: the focused correction falsified it. Other legacy fixtures are unreviewed.
Keep harness corrections separate from design acceptance; all goldens preserved.

## Latest additive verification — 2026-09-17

Four new behavioral tests pass: section lifecycle at 390/800/1366dp (3/3) and
AI open/close with retained capture draft (1/1). Existing golden comparisons
remain intact. Workspace file now has 71 tests; baseline counts below predate
these additions. Original isolated AI golden still fails at 390x844 with 9530
unequal pixels bounded to x=20..369, y=413..546. This is numerical evidence only.
No more unchanged full-suite or isolated golden repetition is needed. Resume
the preview/design gate with actual image-inspection capability; do not bless
current goldens blindly. User-facing Undo, next-row, anchor and error/retry
contracts remain open. No stage closed and no production UI changed here.

## Current continuation — 2026-09-17

Start from `02-state.md` and the existing master plan. Current source is `0ef09ce`;
Stage 12 remains active. An existing uncommitted grouping prototype now passes
the real-row grouping test, but the unfiltered workspace suite finishes 59 passed
and 8 golden failures (exit 1). The file has 67 tests. Do not resume from the old
claim of one missing-heading failure. Full integration finished 479 passed / 8
failed; analyzer and formatting passed. Complete the unapproved three-candidate
preview comparison and reconcile the prototype before acceptance. Visual image
inspection is unavailable in the current tool session; do not update goldens
blindly. Finish single typed-stream consumption in all renderers, prove one next
row, anchor/IME/error/retry behavior, and complete runtime/exact-source release.
Do not repeat unchanged full tests or remove assertions to hide these failures.
The former blanket emulator restriction and Android/Windows-only scope are
superseded: existing Codex_API35 is allowed; Android + Windows + PWA is selected.
No current platform build, PWA delivery or whole-product completion is claimed.

## Active continuation — 2026-09-11

Follow [the current continuation ledger](stages/evidence/12-continuation-ledger.md),
not historical closure wording below. Current main CI repair has failed upload
proof and an expired MSIX baseline. Stage 12 now has deterministic and
storage-backed daily projection proof, editor picker repairs and fail-closed
offline artifact hygiene. Current work is solo because the user explicitly
stopped multi-agent use. Stage 12 visual composition, visible stream grouping,
scroll-anchor implementation and Stages 13–50 remain open. Preserve local-only
files and stash. Trusted release `v1.1.0-build.2065` is now the current private
baseline; emulator use for app viewing is allowed after the Stage 12 preview
freeze.

## Canonical numbered execution — 2026-08-14

Stages 01–11 are externally closed. Stage 11 source checkpoint
`59db6e479f34f25ecf66e4224b2d8c90c7f53941` is merged to `main`; exact-SHA branch
run [`#59` / `31766137998`](https://github.com/k1tvkli2003/Perfect/actions/runs/31766137998)
and trusted main run
[`#60` / `31767013849`](https://github.com/k1tvkli2003/Perfect/actions/runs/31767013849)
passed. Immutable release
[`v1.1.0-build.2060`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2060)
targets that exact SHA and contains exactly APK, Portable ZIP and Setup EXE.

Stage 11 removes Orbit production source/assets and contributes one adaptive Today
Pulse, daily occurrence/habit truth, next-boundary projection and a stream-owned
action model across phone, tablet and Windows. Analysis and all 449 tests pass.
Preview build 2064 installed over 2063; phone, tablet portrait, tablet landscape and
scrolled-final-item captures are hash-verified. Local Windows compilation remains
host-blocked by missing optional ATL, while the trusted runner compiled and signed
the native product, preserved package family/`LocalState` across
`1.1.0.58 → 1.1.0.60`, and passed self-contained Setup clean/idempotent rerun
without mutating Trusted Root. Stage 12 may begin after the documentation-only
checkpoint is verified and the isolated Stage 11 branch/worktree are removed.

The current Stage 09 source has one semantic Motion system across routes, page-title
orientation, dialogs, sheets, menus, inspector, wizard, Quick Capture, AI, selection,
Sync and status feedback. Offstage destinations retain state but cannot paint, tick,
hit, focus or expose semantics. Reduced motion reaches final state without spatial
travel. Analyzer is clean and all 432 tests pass. Android profile build 2060 installed
in place and its runtime artifacts are hash-verified. Emulator raster and local
Windows ATL limitations are explicitly not promoted into physical/hosted proof; see
`09-stage-verification.md`. Hosted Windows build/signing, install-over LocalState and
Setup clean/idempotent rerun are now proven; physical Android and Windows no-jank
measurement remains explicitly open.

## Outcome

Perfect! اکنون یک planner شخصی Flutter برای Android و Windows است؛ Web عمداً حذف شده است. محصول از یک فهرست ساده به Orbit Day واکنش‌گرا، Task/Habit editor بسیار قابل‌تنظیم، local-first Drift، sync خصوصی Supabase، recovery/conflict/archive، focus/reminder/insight و ویجت بومی Android تبدیل شده است.

commit `1b8468b18ec8edc2645ab73dffff23a6829ba0ea` در CI خصوصی run [`30721214315`](https://github.com/k1tvkli2003/Perfect/actions/runs/30721214315) (`#30`) سبز شد. وضعیت source جاری analyzer و ۲۶۶/۲۶۶ تست را پاس کرده است. migration هشتمِ context امن نیز زنده و owner-scoped است. Release immutable [`v1.1.0-build.2030`](https://github.com/k1tvkli2003/Perfect/releases/tag/v1.1.0-build.2030) دقیقاً APK، Windows Setup و Windows portable را منتشر کرده و هر سه دانلود مستقل و hash-verified شده‌اند.

build/install-over Android و exact-SHA CI/release gate بسته شده‌اند. Windows signer به end-entity `CA=false` مهاجرت کرد و run `#30` هم raw install-over `1.1.0.29 → 1.1.0.30` و هم Setup clean-install/rerun را با package family/LocalState ثابت و Root دست‌نخورده اثبات کرد. portable نهایی نیز title/icon، maximize/restore، wide/short/compact resize و short-height scroll را روی auth surface پاس کرده است. signed-in workspace، hover/jank، provider smoke و convergence دو نصب هنوز بازند.

## Product behavior delivered

- Task یک‌باره و recurring با برنامه‌ریزی، چند تاریخ ماهانه/سالانه، last day، flexible N-per-week/month، pause، exception، end/limit و carry cap.
- recovery انتخابی برای pending، miss، move-next و ask؛ تصمیم‌های معوق در Today گم نمی‌شوند.
- وضعیت چهارحالتهٔ Task در اپ و ویجت: `Empty → Done → Not done → % → Empty`.
- Habit با check، avoid، count، duration و checklist؛ هدف at-least/at-most، required/custom/percent success و backfill/undo روزانه.
- پروژه، area، label، category، priority، energy، estimate، time block، due date، checklist، custom typed property، formula و link.
- focus stopwatch/timer/Pomodoro با break policy؛ reminder، quiet hours، snooze، timezone و notification deep link.
- archive قابل‌بازیابی، conflict center، insight صادقانه و تنظیمات privacy/title برای widget.
- UI تطبیقی مستقل برای compact portrait، short landscape/medium و expanded Windows؛ navigation rail، inspector، shortcut و context menu بومی‌تر ویندوز.
- هویت نهایی Perfect! از wordmark منتخب، palette پاستلی، typography Plus Jakarta + Vazirmatn و نشان متقارن Day Compass ساخته شده است: شش ماژول نرم نارنجی/نعنایی/بنفش پیرامون مرکز تیره. source و Windows شفاف‌اند؛ Android adaptive به‌دلیل رفتار واقعی launcher فقط یک fill آرام `#FFF3E8` زیر mark دارد.

## Data and privacy contract

- Drift محلی source of truth است؛ UI برای شبکه متوقف نمی‌شود.
- outbox ترتیبی، mutation idempotency، tombstone، conflict review، bounded retry/backoff و cursor pull وجود دارند.
- schema/RPC v2 افزایشی است و `perfect_items` قبلی را حذف یا بازنویسی نمی‌کند.
- RLS و owner profile برای یک مالک خصوصی طراحی شده‌اند؛ service-role/secret key در client پذیرفته نمی‌شود.
- URL و publishable anon key می‌توانند روی هر نصب به‌صورت محلی تنظیم شوند؛ build-time config نیز اختیاری است.
- widget یک projection خصوصی است؛ tapها ابتدا در صف native پایدار می‌شوند و بعد با همان local planner reconcile می‌شوند.

## Verification snapshot

- `dart format lib test`: pass
- `flutter analyze --no-pub`: pass
- `flutter test --no-pub --reporter compact`: ۲۶۶/۲۶۶ pass
- Workspace UI suite: ۴۴/۴۴ pass
- release continuity contract: ۸/۸ pass
- focused AI suite: ۳۳ pass؛ Deno check pass
- Edge Function: v3 `ACTIVE`، `verify_jwt=true`، hash `ea758008b0606e0384b7b3be1de289a8cdf2041a511008b3b71fae657ec3cd5b`، unauthenticated 401 pass
- private release/workflow contracts: pass؛ queue serialization، `VERSION_CODE` naming و انتشار immutable سه‌فایلی در run `#30` پذیرفته و اجرا شدند
- `flutter build apk --release --build-name=1.1.0 --build-number=2004`: pass؛ private signed
- Final local APK SHA-256: `990772FFDC66F36294225A478961AEF3F228E008A3E8826174E6FF50D5C91B8D`
- Android API 35 install-over/start/logcat for `1.1.0+2004`: pass؛ UID/data/widget binding حفظ شدند؛ session احراز‌شده به‌دلیل signed-out بودن اولیه قابل اثبات نبود
- launcher name/Day Compass icon: pass روی Pixel Launcher API 35 و Windows title bar؛ Explorer/taskbar هنوز مشاهده نشده‌اند
- widget picker/add/resize/scroll/deep-link/four-state queue: pass
- GitHub Actions run `30721214315` (`#30`) for `1b8468b`: success؛ identity، Android، Windows و Publish هر چهار job سبز
- hosted Android: `1.1.0+2030`، `com.k1tvkli2003.perfect`، label `Perfect!`، سه ABI، v2، hashes and signer `144E87CB…F49B0AF` pass
- hosted Windows: `1.1.0.30`، same identity/publisher، end-entity `CA=false` signer `1424F286…BA24`؛ raw install-over و Setup clean-install/rerun pass
- hosted portable: 37 فایل runtime، بدون MSIX/CER/checksum/log/nested archive؛ live auth-surface resize/title/icon proof از lineage قبلی معتبر می‌ماند
- GitHub Release: `v1.1.0-build.2030` immutable و شامل دقیقاً سه asset؛ هر سه download/digest pass
- Windows GUI auth runtime: title/icon، maximize/restore، `832×414`/`540×414` resize and scroll pass؛ signed-in workspace، hover/focus semantics and jank unobserved
- live Supabase migration/RLS/RPC/Auth/context: pass؛ migration `20260730220000` owner/limit/privilege checks green؛ two-device Android↔Windows convergence هنوز اجرا نشده است

جزئیات و تصویرهای runtime در [05-verification.md](05-verification.md) ثبت شده‌اند.

## Private setup

1. migrationها، owner profile و `perfect://login-callback` روی پروژهٔ اصلی از قبل آماده‌اند؛ آن‌ها را دستی تکرار نکن.
2. فایل‌های Release با `PERFECT_SUPABASE_URL` و `PERFECT_SUPABASE_PUBLISHABLE_KEY` از پیش متصل ساخته می‌شوند؛ فقط با همان حساب owner وارد شو. Release `v1.1.0-build.2030` مرجع نصب فعلی است.
3. اگر build محلی بدون define اجرا شد، می‌توان همان URL و publishable anon key را در configuration امن همان نصب وارد کرد.
4. برای signed artifact پایدار، secretهای تعریف‌شده در `.github/private-build-contract.yml` را فقط در GitHub Actions تنظیم کن؛ هیچ keystore یا private key داخل repo یا Release قرار نده.
5. برای Windows فقط `Perfect-<version>-Windows-Setup.exe` را اجرا و UAC را تأیید کن؛ Setup گواهی و MSIX داخلی را خودش اعتبارسنجی، trust و install/update می‌کند. CER یا MSIX خام برای کاربر منتشر نمی‌شود.
6. signing root را به‌صورت رمزنگاری‌شده آفلاین backup کن، رمز vault را جدا نگه دار و restore آزمایشی را با manifest hash و fingerprintها تأیید کن؛ GitHub Secrets backup نیست.

## Environment limits and follow-up proof

- Hosted CI artifacts و portable final runtime بررسی شده‌اند؛ auth-surface resize/title/icon proof جای signed-in Orbit workspace، Explorer/taskbar، hover/focus semantics یا frame-jank proof را نمی‌گیرد.
- migration/RLS و authenticated owner مثبت زنده پاس‌اند؛ offline→reconnect، conflict، realtime drop، دو session هم‌زمان و convergence باید روی Android و Windows artifact نهایی end-to-end ثبت شوند.
- Android proof فعلی emulator است؛ اگر گوشی واقعی متفاوت از API 35 هدف اصلی شد، notification permission، exact alarm policy، reboot reminder و OEM launcher widget هم روی همان دستگاه smoke-test شوند.
- هشدار future Kotlin migration از `home_widget` و `flutter_timezone` است؛ dependencyهای مستقیم فعلاً آخرین نسخهٔ قابل resolve هستند.

## Done

- هستهٔ planner local-first، Supabase owner/context contract، Orbit Day responsive UI، Perfect AI و Android Today widget در source و tests پیاده‌سازی شده‌اند.
- `1b8468b18ec8edc2645ab73dffff23a6829ba0ea` exact-HEAD run `#30` را با signed Android، self-contained Windows Setup، clean portable، install-over و Release immutable موفق پاس کرده است.
- Day Compass از میان conceptها انتخاب، به asset production شفاف تبدیل و در Android launcher/widget/notification و Windows ICO سیم‌کشی شده است.
- widget چهار family responsive، اسکرول native و چرخهٔ `Empty → Done → Not done → 50% → Empty` را با ترتیب native پایدار دارد.
- release audit نهایی queue، artifact naming، Windows private install trust و offline signing recovery را بسته است؛ release contract ۷/۷ باقی مانده است.
- provisioner synthetic، backup hash و rerun identity stability پاس‌اند؛ Windows package signer اکنون end-entity `CA=false` است و Android signer تغییر نکرده است.

## Remaining

1. signed-in phone/tablet/Windows main workspace، Windows hover/focus semantics/jank و signed-in widget Quick Add در runtime ثبت شوند.
2. provider smoke مثبت text/voice/proposal-apply فقط پس از تنظیم secret rotateشده اجرا شود.
3. convergence و authenticated session retention واقعی Android↔Windows با یک owner و دو نصب ثبت شود؛ notification/OEM/reboot نیز روی سخت‌افزار فیزیکی smoke شود.

## Verification

- نتیجهٔ کلی `partial` است: source، backend، exact-SHA CI، artifactها و Windows install-over پاس‌اند؛ runtimeهای احراز‌شده/GUI باقی‌مانده هنوز اجرا نشده‌اند.
- جزئیات requirement-by-requirement، artifact نام‌ها و محدودیت‌ها در [05-verification.md](05-verification.md) ثبت شده‌اند.
- signed MSIX، portable auth GUI و install-over proof دارند؛ اما signed-in workspace/cross-device convergence/session، Windows hover/jank و device-specific Android paths نباید complete ادعا شوند.
