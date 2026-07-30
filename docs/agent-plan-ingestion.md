# نوشتن برنامه در Perfect با ایجنت

این مسیر برای ایجنت‌هایی مثل Codex طراحی شده است تا یک برنامهٔ ساخت‌یافته شامل
Project، Task و Habit را به workspace شخصی Perfect پیشنهاد بدهند و همان داده از
مسیر sync فعلی در Android و Windows دیده شود.

## قرارداد امنیتی

- فراخوانی فقط با **publishable key** پروژه و access token کوتاه‌عمر همان کاربر
  Auth خصوصی انجام می‌شود.
- `service_role`، secret key، پسورد دیتابیس و دسترسی مستقیم جدول لازم نیست و RPC
  عمداً چنین callerی را رد می‌کند.
- شناسهٔ مالک از `auth.uid()` گرفته می‌شود؛ سند JSON نمی‌تواند `owner_id` تعیین
  کند.
- شناسهٔ موجود هیچ‌وقت update یا overwrite نمی‌شود. این boundary فقط create است.
- کل batch اتمیک است: اگر حتی یک آیتم نامعتبر یا تکراری باشد، هیچ آیتمی ثبت
  نمی‌شود.
- تکرار همان `submission_id` با همان سند فقط receipt قبلی را برمی‌گرداند؛ استفاده
  از همان شناسه برای سند متفاوت رد می‌شود.

## چیزی که در اپ دیده می‌شود

هر آیتم پذیرفته‌شده از RPC موجود `apply_planner_mutation` عبور می‌کند؛ بنابراین
یک snapshot معمولی در `planner_changes` می‌سازد و sync فعلی اپ آن را بدون مسیر
خاص دیگری دریافت می‌کند.

آیتم در حالت active و قابل‌مشاهده ساخته می‌شود، اما این metadata سروری را نیز در
payload دارد:

```json
{
  "agent_proposal": {
    "review": {
      "status": "proposed",
      "requires_owner_review": true,
      "reviewed_at": null
    }
  }
}
```

ایجنت اجازه ندارد این بخش را خودش بنویسد یا وضعیت review را جعل کند. source،
شناسهٔ submission، عنوان plan، زمان ثبت و شمارهٔ آیتم نیز کنار همین metadata
ذخیره می‌شوند. اگر ایجنت category مشخص نکرده باشد، سرور category را روی
`Agent proposal` می‌گذارد تا همین نسخهٔ فعلی اپ نیز پیشنهادی‌بودن آیتم را روی
کارت نشان بدهد.

## ساخت سند

Schema مرجع:
[`supabase/contracts/agent-plan-v1.schema.json`](../supabase/contracts/agent-plan-v1.schema.json)

نمونهٔ کامل:
[`supabase/contracts/examples/agent-plan-v1.example.json`](../supabase/contracts/examples/agent-plan-v1.example.json)

قواعد اصلی:

- `schema_version` در این نسخه دقیقاً `1` است.
- برای هر برنامه یک `submission_id` تازه بساز و برای retry همان را نگه دار.
- `agent_device_id` شناسهٔ پایدار همان ایجنت/نصب است.
- kindهای مجاز: `project`، `one_off_task`، `recurring_task` و `habit`.
- هر آیتم `id` منحصربه‌فرد، `title` و در صورت نیاز `payload` آزاد دارد.
- حداکثر ۱۰۰ آیتم، ۵۱۲ KiB برای سند، ۳۲ KiB برای هر آیتم و ۲۴ KiB برای payload.
- زمان‌ها را به صورت ISO-8601 با timezone بنویس.
- ارتباط Task با Project را در `payload.relations` با ID همان Project قرار بده.

## اعتبارسنجی و ارسال

اعتبارسنجی محلی هیچ دسترسی شبکه‌ای یا secret نمی‌خواهد:

```powershell
python tool/submit_agent_plan.py `
  supabase/contracts/examples/agent-plan-v1.example.json
```

برای ارسال، secretها را داخل فایل یا command line ننویس. آن‌ها را فقط در محیط
همان process قرار بده:

```powershell
$env:PERFECT_SUPABASE_URL = 'https://PROJECT.supabase.co'
$env:PERFECT_SUPABASE_PUBLISHABLE_KEY = 'PUBLISHABLE_KEY'
$env:PERFECT_SUPABASE_ACCESS_TOKEN = 'SHORT_LIVED_OWNER_ACCESS_TOKEN'

python tool/submit_agent_plan.py .\my-plan.json --submit
```

ابزار قبل از شبکه قرارداد JSON را دوباره بررسی می‌کند، service-role JWT شناخته‌شده
را رد می‌کند و token/key را چاپ نمی‌کند. RPC نیز مستقل از ابزار تمام validation
و authorization را دوباره در دیتابیس انجام می‌دهد.

## ترتیب deploy

بعد از migrationهای planner v2، migration زیر را apply کن:

`supabase/migrations/20260730190000_add_agent_plan_ingestion.sql`

این migration append-only است و داده یا migration قبلی را تغییر نمی‌دهد.
