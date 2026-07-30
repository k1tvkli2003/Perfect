# قرارداد Sync چت و عملیات AI در Perfect

این قرارداد backend برای چت‌بات agentic شخصی Perfect است. UI و Edge Function
جداگانه به آن وصل می‌شوند، اما تاریخچهٔ گفتگو، پیام‌های نهایی و audit اجرای
پیشنهادها از همین حالا owner-scoped و قابل sync بین Android و Windows هستند.

## مرز امنیت

- تمام RPCها فقط user JWT نقش `authenticated` همان مالک خصوصی را می‌پذیرند.
- Edge Function باید RPC را با Authorization کاربر فراخوانی کند؛ `service_role`
  برای این مسیر لازم یا مجاز نیست.
- provider API key فقط secret خود Edge Function است و هرگز وارد body، metadata،
  جدول یا log دیتابیس نمی‌شود.
- endpoint مدل به origin رسمی `https://api.avalai.ir/v1` پین است؛ مقدار
  `AVALAI_BASE_URL` نمی‌تواند credential را به host، path یا پروتکل دیگری
  بفرستد. نبودن provider config مسیر Apply یک proposal ذخیره‌شده را مسدود
  نمی‌کند.
- جدول‌ها فقط `SELECT` مالک را برای Realtime دارند. `INSERT`، `UPDATE` و `DELETE`
  مستقیم revoke شده و همهٔ mutationها از RPC اعتبارسنجی‌شده می‌گذرند.
- `proposal` و `result` برای دادهٔ عملیاتی اپ هستند، نه raw provider
  request/response. کلیدهایی مثل authorization، token، secret، password،
  header/cookie و raw/provider request/response به‌صورت recursive رد می‌شوند.
- به‌جای ذخیرهٔ system prompt، فقط `prompt_version` ذخیره می‌شود.

Migration:
`supabase/migrations/20260730192000_add_private_ai_conversation_sync.sql`

Hardening additive:
`supabase/migrations/20260730210000_harden_private_ai_metadata.sql`

نسخهٔ hardening عمق metadata را به ۳۲ سطح محدود می‌کند و aliasهای رایج credential
مثل bearer/auth/session token، client secret، private key و set-cookie را نیز
رد می‌کند؛ شمارنده‌های سالمی مثل `input_tokens` همچنان مجازند.

## مدل داده

- `ai_conversations`: عنوان، وضعیت، شمار پیام، cursor زمانی، retention و soft
  delete.
- `ai_messages`: پیام نهایی و immutable با role/status/content، proposal/result،
  model، prompt version، schema version، request ID، latency و token usage.
- `ai_action_audit`: receipt append-only برای applied/rejected/failed با
  idempotency key و در صورت ثبت برنامه، `applied_submission_id`.

هر سه جدول RLS دارند و به Realtime publication افزوده می‌شوند. صحت sync فقط به
event وابسته نیست؛ list RPCهای cursor-based مرجع بازیابی هستند.

## هدر همهٔ RPCها

```http
apikey: PERFECT_SUPABASE_PUBLISHABLE_KEY
Authorization: Bearer OWNER_ACCESS_TOKEN
Content-Type: application/json
```

هیچ RPC پارامتر `owner_id` ندارد؛ مالک همیشه از `auth.uid()` استخراج می‌شود.

## 1. ساخت یا تغییر عنوان گفتگو

RPC: `upsert_ai_conversation`

```json
{
  "p_conversation_id": "c156c5a0-1100-4aaa-b007-1a670882f8c8",
  "p_title": "برنامهٔ هفته",
  "p_status": "active",
  "p_retention_until": null,
  "p_schema_version": 1
}
```

- `status`: فقط `active` یا `archived`.
- `retention_until`: اختیاری و حداکثر ده سال آینده.
- گفتگوی soft-deleted با upsert بی‌صدا restore نمی‌شود.
- خروجی snapshot کامل conversation است.

## 2. لیست گفتگوها

RPC: `list_ai_conversations`

```json
{
  "p_after_updated_at": null,
  "p_after_id": null,
  "p_limit": 50,
  "p_include_deleted": false
}
```

مرتب‌سازی `updated_at DESC, id DESC` است. برای صفحهٔ بعد، timestamp و ID آخرین
آیتم را با هم بفرست. limit بین ۱ و ۱۰۰ clamp می‌شود.

## 3. افزودن پیام immutable

RPC: `append_ai_message`

Body:

```json
{
  "p_message": {
    "schema_version": 1,
    "message_id": "a8d8af27-3a2f-4696-89d6-e9527de5fb93",
    "conversation_id": "c156c5a0-1100-4aaa-b007-1a670882f8c8",
    "role": "assistant",
    "status": "completed",
    "content": "پیشنهاد آمادهٔ بازبینی است.",
    "proposal": {},
    "result": {},
    "model": "private-provider-model",
    "prompt_version": "perfect-assistant-v1",
    "request_id": "338484b5-765a-447e-9cca-18af0cc8aa8e",
    "latency_ms": 1420,
    "usage": {
      "input_tokens": 830,
      "output_tokens": 412,
      "cached_tokens": 0,
      "total_tokens": 1242
    }
  }
}
```

Schema:
[`supabase/contracts/ai-message-v1.schema.json`](../supabase/contracts/ai-message-v1.schema.json)

نمونه:
[`supabase/contracts/examples/ai-message-v1.example.json`](../supabase/contracts/examples/ai-message-v1.example.json)

- role: `user`، `assistant` یا `tool`.
- status نهایی: `completed`، `failed` یا `cancelled`. streaming موقت در UI/Edge
  می‌ماند و پیام نهایی یک‌بار append می‌شود.
- content حداکثر ۳۲۰۰۰ کاراکتر؛ proposal/result هرکدام حداکثر ۳۲ KiB.
- proposal غیرخالی فقط روی پیام assistant مجاز است.
- replay همان `message_id` و همان سند receipt قبلی را می‌دهد؛ استفادهٔ همان ID
  برای محتوای متفاوت رد می‌شود.

## 4. لیست پیام‌ها

RPC: `list_ai_messages`

```json
{
  "p_conversation_id": "c156c5a0-1100-4aaa-b007-1a670882f8c8",
  "p_after_created_at": null,
  "p_after_id": null,
  "p_limit": 100
}
```

مرتب‌سازی `created_at ASC, id ASC` است. cursor هر دو فیلد را با هم می‌گیرد و
limit بین ۱ و ۲۰۰ clamp می‌شود.

## 5. ثبت audit نتیجهٔ اجرای پیشنهاد

بعد از اجرای یک proposal (مثلاً فراخوانی `submit_agent_plan`) Edge Function این
receipt را می‌نویسد.

RPC: `record_ai_action_result`

```json
{
  "p_operation": {
    "schema_version": 1,
    "operation_id": "b8f037b1-3d68-4737-b142-e8fe1ed81262",
    "idempotency_key": "2876f02f-3984-48a2-9694-500e05ba4a14",
    "conversation_id": "c156c5a0-1100-4aaa-b007-1a670882f8c8",
    "message_id": "a8d8af27-3a2f-4696-89d6-e9527de5fb93",
    "status": "applied",
    "proposal": {},
    "result": {},
    "request_id": "338484b5-765a-447e-9cca-18af0cc8aa8e",
    "applied_submission_id": "03f85e79-99c9-4a35-8dc8-3596d86883ad"
  }
}
```

Schema:
[`supabase/contracts/ai-action-result-v1.schema.json`](../supabase/contracts/ai-action-result-v1.schema.json)

نمونه:
[`supabase/contracts/examples/ai-action-result-v1.example.json`](../supabase/contracts/examples/ai-action-result-v1.example.json)

- status: `applied`، `rejected` یا `failed`.
- message باید assistant و متعلق به همان conversation باشد.
- اگر `applied_submission_id` حاضر است، باید receipt واقعی و متعلق به همان مالک
  در `planner_agent_submissions` باشد.
- operation ID و idempotency key هر دو lock/unique هستند. replay دقیق بدون side
  effect جدید برمی‌گردد؛ payload متفاوت رد می‌شود.

## 6. لیست audit

RPC: `list_ai_action_audit`

```json
{
  "p_conversation_id": "c156c5a0-1100-4aaa-b007-1a670882f8c8",
  "p_after_created_at": null,
  "p_after_operation_id": null,
  "p_limit": 100
}
```

مرتب‌سازی و pagination صعودی و cursor-based مانند پیام‌هاست.

## 7. Retention و حذف

Soft delete با مهلت پیش‌فرض ۳۰ روز:

```json
{
  "p_conversation_id": "c156c5a0-1100-4aaa-b007-1a670882f8c8",
  "p_mode": "soft",
  "p_purge_after": null
}
```

RPC: `delete_ai_conversation`

برای حذف فوری و cascade پیام/audit، `p_mode: "purge"` بفرست. این اقدام قابل
بازیابی نیست و باید بعد از تأیید صریح UI انجام شود.

پاک‌کردن batch گفتگوهایی که retention آن‌ها رسیده:

RPC: `purge_expired_ai_conversations`

```json
{
  "p_limit": 100
}
```

## ترتیب پیشنهادی Edge Function

1. user JWT را verify و بدون تبدیل به service-role به Supabase client بده.
2. conversation را upsert کن.
3. پیام user را با ID پایدار append کن.
4. provider را با secret سمت Edge صدا بزن؛ raw request/response را ذخیره نکن.
5. پیام نهایی assistant را با model/prompt version/request/latency/usage append
   کن.
6. proposal را فقط بعد از تأیید مالک اجرا کن.
7. پیش از write، proposal دریافتی را byte-semantically با proposal ذخیره‌شده در
   همان conversation تطبیق بده و message اصلی را به‌عنوان source audit نگه دار.
8. برای plan، `submit_agent_plan` را با همان user JWT و یک سند deterministic
   صدا بزن؛ retry نباید timestamp تازه‌ای به همان submission اضافه کند.
9. نتیجه را با idempotency key در `record_ai_action_result` ثبت کن.

در reconnect یا missed Realtime event، list RPCها با cursor آخر دوباره خوانده
می‌شوند؛ بنابراین event فقط wake-up hint است و منبع صحت نیست.
