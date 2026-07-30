-- Private, cross-device AI conversation history and action audit for Perfect.
--
-- This migration is additive and follows the agent-plan ingestion migration.
-- The app/Edge Function call these RPCs with the private owner's user JWT and
-- the public project key. No provider secret, service-role key, system prompt,
-- raw provider request/response, headers or cookies belong in this schema.

create or replace function public.perfect_ai_metadata_is_safe(
  p_value jsonb
)
returns boolean
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  v_key text;
  v_child jsonb;
begin
  if p_value is null then
    return true;
  end if;

  if jsonb_typeof(p_value) = 'object' then
    for v_key, v_child in
      select entry.key, entry.value
      from jsonb_each(p_value) as entry
    loop
      if lower(v_key) ~
        '^(authorization|api[_-]?key|access[_-]?token|refresh[_-]?token|secret|password|cookie|cookies|headers|raw[_-]?(request|response)|provider[_-]?(request|response))$'
      then
        return false;
      end if;
      if not public.perfect_ai_metadata_is_safe(v_child) then
        return false;
      end if;
    end loop;
  elsif jsonb_typeof(p_value) = 'array' then
    for v_child in
      select element.value
      from jsonb_array_elements(p_value) as element
    loop
      if not public.perfect_ai_metadata_is_safe(v_child) then
        return false;
      end if;
    end loop;
  end if;

  return true;
end;
$$;

revoke all on function public.perfect_ai_metadata_is_safe(jsonb)
  from public, anon, authenticated;

create table if not exists public.ai_conversations (
  owner_id uuid not null
    references public.planner_owner_profiles (owner_id) on delete cascade,
  id uuid not null,
  title text not null check (char_length(title) between 1 and 160),
  status text not null default 'active'
    check (status in ('active', 'archived')),
  schema_version smallint not null default 1
    check (schema_version = 1),
  message_count bigint not null default 0 check (message_count >= 0),
  last_message_at timestamptz,
  retention_until timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  primary key (owner_id, id),
  constraint ai_conversations_timestamp_order check (updated_at >= created_at)
);

create table if not exists public.ai_messages (
  owner_id uuid not null,
  id uuid not null,
  conversation_id uuid not null,
  role text not null check (role in ('user', 'assistant', 'tool')),
  status text not null
    check (status in ('completed', 'failed', 'cancelled')),
  content text not null
    check (
      char_length(content) <= 32000
      and octet_length(content) <= 131072
    ),
  proposal jsonb not null default '{}'::jsonb
    check (
      jsonb_typeof(proposal) = 'object'
      and octet_length(proposal::text) <= 32768
      and public.perfect_ai_metadata_is_safe(proposal)
    ),
  result jsonb not null default '{}'::jsonb
    check (
      jsonb_typeof(result) = 'object'
      and octet_length(result::text) <= 32768
      and public.perfect_ai_metadata_is_safe(result)
    ),
  model text check (model is null or char_length(model) between 1 and 120),
  prompt_version text check (
    prompt_version is null or char_length(prompt_version) between 1 and 80
  ),
  schema_version smallint not null default 1 check (schema_version = 1),
  request_id uuid,
  latency_ms integer check (
    latency_ms is null or latency_ms between 0 and 3600000
  ),
  usage jsonb not null default '{}'::jsonb
    check (
      jsonb_typeof(usage) = 'object'
      and octet_length(usage::text) <= 4096
      and public.perfect_ai_metadata_is_safe(usage)
    ),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (owner_id, id),
  foreign key (owner_id, conversation_id)
    references public.ai_conversations (owner_id, id) on delete cascade,
  constraint ai_messages_meaningful_content check (
    role = 'tool'
    or status in ('failed', 'cancelled')
    or char_length(trim(content)) between 1 and 32000
  )
);

create table if not exists public.ai_action_audit (
  owner_id uuid not null,
  operation_id uuid not null,
  idempotency_key uuid not null,
  conversation_id uuid not null,
  source_message_id uuid not null,
  status text not null check (status in ('applied', 'rejected', 'failed')),
  proposal jsonb not null
    check (
      jsonb_typeof(proposal) = 'object'
      and octet_length(proposal::text) <= 32768
      and public.perfect_ai_metadata_is_safe(proposal)
    ),
  result jsonb not null default '{}'::jsonb
    check (
      jsonb_typeof(result) = 'object'
      and octet_length(result::text) <= 32768
      and public.perfect_ai_metadata_is_safe(result)
    ),
  schema_version smallint not null default 1 check (schema_version = 1),
  request_id uuid,
  applied_submission_id uuid,
  error_code text check (
    error_code is null or char_length(error_code) between 1 and 80
  ),
  document_hash text not null check (document_hash ~ '^[0-9a-f]{64}$'),
  request_document jsonb not null
    check (
      jsonb_typeof(request_document) = 'object'
      and octet_length(request_document::text) <= 131072
      and public.perfect_ai_metadata_is_safe(request_document)
    ),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (owner_id, operation_id),
  unique (owner_id, idempotency_key),
  foreign key (owner_id, conversation_id)
    references public.ai_conversations (owner_id, id) on delete cascade,
  foreign key (owner_id, source_message_id)
    references public.ai_messages (owner_id, id) on delete cascade,
  foreign key (owner_id, applied_submission_id)
    references public.planner_agent_submissions (owner_id, submission_id)
    on delete restrict
);

create index if not exists ai_conversations_owner_updated_idx
  on public.ai_conversations (owner_id, updated_at desc, id desc);
create index if not exists ai_conversations_owner_retention_idx
  on public.ai_conversations (owner_id, retention_until)
  where retention_until is not null;
create index if not exists ai_messages_owner_conversation_cursor_idx
  on public.ai_messages (owner_id, conversation_id, created_at, id);
create index if not exists ai_messages_owner_request_idx
  on public.ai_messages (owner_id, request_id)
  where request_id is not null;
create index if not exists ai_action_audit_owner_conversation_cursor_idx
  on public.ai_action_audit (
    owner_id, conversation_id, created_at, operation_id
  );
create index if not exists ai_action_audit_owner_request_idx
  on public.ai_action_audit (owner_id, request_id)
  where request_id is not null;

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_action_audit enable row level security;

do $$
begin
  create policy "private owner reads own AI conversations"
    on public.ai_conversations for select to authenticated
    using (owner_id = auth.uid());
exception when duplicate_object then null;
end;
$$;

do $$
begin
  create policy "private owner reads own AI messages"
    on public.ai_messages for select to authenticated
    using (owner_id = auth.uid());
exception when duplicate_object then null;
end;
$$;

do $$
begin
  create policy "private owner reads own AI action audit"
    on public.ai_action_audit for select to authenticated
    using (owner_id = auth.uid());
exception when duplicate_object then null;
end;
$$;

-- Realtime needs owner-scoped SELECT authorization. Every mutation remains
-- RPC-only; authenticated has no direct INSERT, UPDATE or DELETE privilege.
revoke all on table public.ai_conversations from public, anon, authenticated;
revoke all on table public.ai_messages from public, anon, authenticated;
revoke all on table public.ai_action_audit from public, anon, authenticated;
grant select on table public.ai_conversations to authenticated;
grant select on table public.ai_messages to authenticated;
grant select on table public.ai_action_audit to authenticated;

create or replace function public.upsert_ai_conversation(
  p_conversation_id uuid,
  p_title text,
  p_status text default 'active',
  p_retention_until timestamptz default null,
  p_schema_version integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_saved public.ai_conversations%rowtype;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  if p_conversation_id is null
    or p_conversation_id = '00000000-0000-0000-0000-000000000000'::uuid
  then
    raise exception 'conversation_id must be a non-nil UUID.'
      using errcode = '22023';
  end if;
  if char_length(trim(coalesce(p_title, ''))) not between 1 and 160 then
    raise exception 'title must contain 1 to 160 characters.'
      using errcode = '22023';
  end if;
  if p_status is null or p_status not in ('active', 'archived') then
    raise exception 'Unsupported conversation status.'
      using errcode = '22023';
  end if;
  if p_schema_version is null or p_schema_version <> 1 then
    raise exception 'Unsupported AI conversation schema version.'
      using errcode = '22023';
  end if;
  if p_retention_until is not null
    and p_retention_until > v_now + interval '10 years'
  then
    raise exception 'retention_until cannot be more than 10 years ahead.'
      using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:ai-conversation:' || v_owner_id::text || ':' ||
        p_conversation_id::text,
      0
    )
  );

  update public.ai_conversations
  set
    title = trim(p_title),
    status = p_status,
    schema_version = p_schema_version,
    retention_until = p_retention_until,
    updated_at = greatest(updated_at, v_now)
  where owner_id = v_owner_id
    and id = p_conversation_id
    and deleted_at is null
  returning * into v_saved;

  if not found then
    if exists (
      select 1
      from public.ai_conversations
      where owner_id = v_owner_id and id = p_conversation_id
    ) then
      raise exception 'A deleted AI conversation cannot be silently restored.'
        using errcode = '55000';
    end if;

    insert into public.ai_conversations (
      owner_id,
      id,
      title,
      status,
      schema_version,
      retention_until,
      created_at,
      updated_at
    ) values (
      v_owner_id,
      p_conversation_id,
      trim(p_title),
      p_status,
      p_schema_version,
      p_retention_until,
      v_now,
      v_now
    ) returning * into v_saved;
  end if;

  return jsonb_build_object(
    'id', v_saved.id,
    'owner_id', v_saved.owner_id,
    'title', v_saved.title,
    'status', v_saved.status,
    'schema_version', v_saved.schema_version,
    'message_count', v_saved.message_count,
    'last_message_at', v_saved.last_message_at,
    'retention_until', v_saved.retention_until,
    'created_at', v_saved.created_at,
    'updated_at', v_saved.updated_at,
    'deleted_at', v_saved.deleted_at
  );
end;
$$;

create or replace function public.list_ai_conversations(
  p_after_updated_at timestamptz default null,
  p_after_id uuid default null,
  p_limit integer default 50,
  p_include_deleted boolean default false
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_limit integer;
  v_items jsonb;
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  if (p_after_updated_at is null) <> (p_after_id is null) then
    raise exception 'Conversation cursor fields must be supplied together.'
      using errcode = '22023';
  end if;
  v_limit := least(greatest(coalesce(p_limit, 50), 1), 100);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', item.id,
        'owner_id', item.owner_id,
        'title', item.title,
        'status', item.status,
        'schema_version', item.schema_version,
        'message_count', item.message_count,
        'last_message_at', item.last_message_at,
        'retention_until', item.retention_until,
        'created_at', item.created_at,
        'updated_at', item.updated_at,
        'deleted_at', item.deleted_at
      )
      order by item.updated_at desc, item.id desc
    ),
    '[]'::jsonb
  )
  into v_items
  from (
    select conversation.*
    from public.ai_conversations as conversation
    where conversation.owner_id = v_owner_id
      and (coalesce(p_include_deleted, false) or conversation.deleted_at is null)
      and (
        p_after_updated_at is null
        or (conversation.updated_at, conversation.id) <
          (p_after_updated_at, p_after_id)
      )
    order by conversation.updated_at desc, conversation.id desc
    limit v_limit
  ) as item;

  return jsonb_build_object('items', v_items, 'limit', v_limit);
end;
$$;

create or replace function public.append_ai_message(
  p_message jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_schema_version integer;
  v_message_id uuid;
  v_conversation_id uuid;
  v_role text;
  v_status text;
  v_content text;
  v_proposal jsonb;
  v_result jsonb;
  v_model text;
  v_prompt_version text;
  v_request_id uuid;
  v_latency_ms integer;
  v_usage jsonb;
  v_existing public.ai_messages%rowtype;
  v_saved public.ai_messages%rowtype;
  v_now timestamptz := timezone('utc', now());
  v_usage_entry record;
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  if jsonb_typeof(p_message) is distinct from 'object' then
    raise exception 'AI message must be a JSON object.'
      using errcode = '22023';
  end if;
  if octet_length(p_message::text) > 131072 then
    raise exception 'AI message document exceeds the 128 KiB limit.'
      using errcode = '22023';
  end if;
  if not (
    p_message ? 'schema_version'
    and p_message ? 'message_id'
    and p_message ? 'conversation_id'
    and p_message ? 'role'
    and p_message ? 'status'
    and p_message ? 'content'
  ) then
    raise exception 'AI message is missing a required field.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_object_keys(p_message) as message_key
    where message_key not in (
      'schema_version',
      'message_id',
      'conversation_id',
      'role',
      'status',
      'content',
      'proposal',
      'result',
      'model',
      'prompt_version',
      'request_id',
      'latency_ms',
      'usage'
    )
  ) then
    raise exception 'AI message has an unsupported field.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_message -> 'schema_version') <> 'number'
    or p_message ->> 'schema_version' !~ '^[0-9]+$'
  then
    raise exception 'schema_version must be the integer 1.'
      using errcode = '22023';
  end if;
  v_schema_version := (p_message ->> 'schema_version')::integer;
  if v_schema_version <> 1 then
    raise exception 'Unsupported AI message schema version.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_message -> 'message_id') <> 'string'
    or p_message ->> 'message_id' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'message_id must be a UUID string.'
      using errcode = '22023';
  end if;
  v_message_id := (p_message ->> 'message_id')::uuid;
  if v_message_id = '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'message_id cannot be the nil UUID.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_message -> 'conversation_id') <> 'string'
    or p_message ->> 'conversation_id' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'conversation_id must be a UUID string.'
      using errcode = '22023';
  end if;
  v_conversation_id := (p_message ->> 'conversation_id')::uuid;

  if jsonb_typeof(p_message -> 'role') <> 'string'
    or p_message ->> 'role' not in ('user', 'assistant', 'tool')
  then
    raise exception 'Unsupported AI message role.'
      using errcode = '22023';
  end if;
  v_role := p_message ->> 'role';
  if jsonb_typeof(p_message -> 'status') <> 'string'
    or p_message ->> 'status' not in ('completed', 'failed', 'cancelled')
  then
    raise exception 'Unsupported AI message status.'
      using errcode = '22023';
  end if;
  v_status := p_message ->> 'status';
  if jsonb_typeof(p_message -> 'content') <> 'string' then
    raise exception 'content must be a string.'
      using errcode = '22023';
  end if;
  v_content := p_message ->> 'content';
  if char_length(v_content) > 32000 or octet_length(v_content) > 131072 then
    raise exception 'content exceeds the 32000 character limit.'
      using errcode = '22023';
  end if;
  if v_role <> 'tool'
    and v_status = 'completed'
    and char_length(trim(v_content)) = 0
  then
    raise exception 'A completed user/assistant message needs content.'
      using errcode = '22023';
  end if;

  v_proposal := coalesce(p_message -> 'proposal', '{}'::jsonb);
  v_result := coalesce(p_message -> 'result', '{}'::jsonb);
  v_usage := coalesce(p_message -> 'usage', '{}'::jsonb);
  if jsonb_typeof(v_proposal) <> 'object'
    or octet_length(v_proposal::text) > 32768
    or not public.perfect_ai_metadata_is_safe(v_proposal)
  then
    raise exception 'proposal must be a safe JSON object up to 32 KiB.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(v_result) <> 'object'
    or octet_length(v_result::text) > 32768
    or not public.perfect_ai_metadata_is_safe(v_result)
  then
    raise exception 'result must be a safe JSON object up to 32 KiB.'
      using errcode = '22023';
  end if;
  if v_role <> 'assistant' and v_proposal <> '{}'::jsonb then
    raise exception 'Only assistant messages may carry a proposal.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(v_usage) <> 'object'
    or octet_length(v_usage::text) > 4096
  then
    raise exception 'usage must be a JSON object up to 4 KiB.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_object_keys(v_usage) as usage_key
    where usage_key not in (
      'input_tokens', 'output_tokens', 'cached_tokens', 'total_tokens'
    )
  ) then
    raise exception 'usage has an unsupported field.'
      using errcode = '22023';
  end if;
  for v_usage_entry in
    select usage_entry.key, usage_entry.value
    from jsonb_each(v_usage) as usage_entry
  loop
    if jsonb_typeof(v_usage_entry.value) <> 'number'
      or v_usage_entry.value::text !~ '^[0-9]+$'
      or (v_usage_entry.value::text)::numeric > 1000000000
    then
      raise exception 'usage token counts must be non-negative integers.'
        using errcode = '22023';
    end if;
  end loop;

  if p_message ? 'model' then
    if jsonb_typeof(p_message -> 'model') <> 'string'
      or char_length(trim(p_message ->> 'model')) not between 1 and 120
    then
      raise exception 'model must contain 1 to 120 characters.'
        using errcode = '22023';
    end if;
    v_model := trim(p_message ->> 'model');
  end if;
  if p_message ? 'prompt_version' then
    if jsonb_typeof(p_message -> 'prompt_version') <> 'string'
      or char_length(trim(p_message ->> 'prompt_version')) not between 1 and 80
    then
      raise exception 'prompt_version must contain 1 to 80 characters.'
        using errcode = '22023';
    end if;
    v_prompt_version := trim(p_message ->> 'prompt_version');
  end if;
  if p_message ? 'request_id' then
    if jsonb_typeof(p_message -> 'request_id') <> 'string'
      or p_message ->> 'request_id' !~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then
      raise exception 'request_id must be a UUID string.'
        using errcode = '22023';
    end if;
    v_request_id := (p_message ->> 'request_id')::uuid;
    if v_request_id = '00000000-0000-0000-0000-000000000000'::uuid then
      raise exception 'request_id cannot be the nil UUID.'
        using errcode = '22023';
    end if;
  end if;
  if p_message ? 'latency_ms' then
    if jsonb_typeof(p_message -> 'latency_ms') <> 'number'
      or p_message ->> 'latency_ms' !~ '^[0-9]+$'
      or (p_message ->> 'latency_ms')::numeric > 3600000
    then
      raise exception 'latency_ms must be an integer from 0 to 3600000.'
        using errcode = '22023';
    end if;
    v_latency_ms := (p_message ->> 'latency_ms')::integer;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:ai-message:' || v_owner_id::text || ':' || v_message_id::text,
      0
    )
  );
  select *
  into v_existing
  from public.ai_messages
  where owner_id = v_owner_id and id = v_message_id;
  if found then
    if v_existing.conversation_id is distinct from v_conversation_id
      or v_existing.role is distinct from v_role
      or v_existing.status is distinct from v_status
      or v_existing.content is distinct from v_content
      or v_existing.proposal is distinct from v_proposal
      or v_existing.result is distinct from v_result
      or v_existing.model is distinct from v_model
      or v_existing.prompt_version is distinct from v_prompt_version
      or v_existing.schema_version is distinct from v_schema_version
      or v_existing.request_id is distinct from v_request_id
      or v_existing.latency_ms is distinct from v_latency_ms
      or v_existing.usage is distinct from v_usage
    then
      raise exception 'message_id cannot be reused for different content.'
        using errcode = '22023';
    end if;
    return jsonb_build_object(
      'status', 'acknowledged',
      'replayed', true,
      'message', jsonb_build_object(
        'id', v_existing.id,
        'owner_id', v_existing.owner_id,
        'conversation_id', v_existing.conversation_id,
        'role', v_existing.role,
        'status', v_existing.status,
        'content', v_existing.content,
        'proposal', v_existing.proposal,
        'result', v_existing.result,
        'model', v_existing.model,
        'prompt_version', v_existing.prompt_version,
        'schema_version', v_existing.schema_version,
        'request_id', v_existing.request_id,
        'latency_ms', v_existing.latency_ms,
        'usage', v_existing.usage,
        'created_at', v_existing.created_at
      )
    );
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:ai-conversation:' || v_owner_id::text || ':' ||
        v_conversation_id::text,
      0
    )
  );
  if not exists (
    select 1
    from public.ai_conversations
    where owner_id = v_owner_id
      and id = v_conversation_id
      and deleted_at is null
  ) then
    raise exception 'The target AI conversation does not exist or is deleted.'
      using errcode = '23503';
  end if;

  insert into public.ai_messages (
    owner_id,
    id,
    conversation_id,
    role,
    status,
    content,
    proposal,
    result,
    model,
    prompt_version,
    schema_version,
    request_id,
    latency_ms,
    usage,
    created_at
  ) values (
    v_owner_id,
    v_message_id,
    v_conversation_id,
    v_role,
    v_status,
    v_content,
    v_proposal,
    v_result,
    v_model,
    v_prompt_version,
    v_schema_version,
    v_request_id,
    v_latency_ms,
    v_usage,
    v_now
  ) returning * into v_saved;

  update public.ai_conversations
  set
    message_count = message_count + 1,
    last_message_at = greatest(coalesce(last_message_at, v_now), v_now),
    updated_at = greatest(updated_at, v_now)
  where owner_id = v_owner_id and id = v_conversation_id;

  return jsonb_build_object(
    'status', 'acknowledged',
    'replayed', false,
    'message', jsonb_build_object(
      'id', v_saved.id,
      'owner_id', v_saved.owner_id,
      'conversation_id', v_saved.conversation_id,
      'role', v_saved.role,
      'status', v_saved.status,
      'content', v_saved.content,
      'proposal', v_saved.proposal,
      'result', v_saved.result,
      'model', v_saved.model,
      'prompt_version', v_saved.prompt_version,
      'schema_version', v_saved.schema_version,
      'request_id', v_saved.request_id,
      'latency_ms', v_saved.latency_ms,
      'usage', v_saved.usage,
      'created_at', v_saved.created_at
    )
  );
end;
$$;

create or replace function public.list_ai_messages(
  p_conversation_id uuid,
  p_after_created_at timestamptz default null,
  p_after_id uuid default null,
  p_limit integer default 100
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_limit integer;
  v_items jsonb;
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  if not exists (
    select 1
    from public.ai_conversations
    where owner_id = v_owner_id and id = p_conversation_id
  ) then
    raise exception 'AI conversation was not found.'
      using errcode = 'P0002';
  end if;
  if (p_after_created_at is null) <> (p_after_id is null) then
    raise exception 'Message cursor fields must be supplied together.'
      using errcode = '22023';
  end if;
  v_limit := least(greatest(coalesce(p_limit, 100), 1), 200);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', item.id,
        'owner_id', item.owner_id,
        'conversation_id', item.conversation_id,
        'role', item.role,
        'status', item.status,
        'content', item.content,
        'proposal', item.proposal,
        'result', item.result,
        'model', item.model,
        'prompt_version', item.prompt_version,
        'schema_version', item.schema_version,
        'request_id', item.request_id,
        'latency_ms', item.latency_ms,
        'usage', item.usage,
        'created_at', item.created_at
      )
      order by item.created_at, item.id
    ),
    '[]'::jsonb
  )
  into v_items
  from (
    select message.*
    from public.ai_messages as message
    where message.owner_id = v_owner_id
      and message.conversation_id = p_conversation_id
      and (
        p_after_created_at is null
        or (message.created_at, message.id) >
          (p_after_created_at, p_after_id)
      )
    order by message.created_at, message.id
    limit v_limit
  ) as item;

  return jsonb_build_object('items', v_items, 'limit', v_limit);
end;
$$;

create or replace function public.record_ai_action_result(
  p_operation jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_schema_version integer;
  v_operation_id uuid;
  v_idempotency_key uuid;
  v_conversation_id uuid;
  v_message_id uuid;
  v_status text;
  v_proposal jsonb;
  v_result jsonb;
  v_request_id uuid;
  v_applied_submission_id uuid;
  v_error_code text;
  v_document_hash text;
  v_existing public.ai_action_audit%rowtype;
  v_saved public.ai_action_audit%rowtype;
  v_message public.ai_messages%rowtype;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  if jsonb_typeof(p_operation) is distinct from 'object' then
    raise exception 'AI action result must be a JSON object.'
      using errcode = '22023';
  end if;
  if octet_length(p_operation::text) > 131072 then
    raise exception 'AI action result exceeds the 128 KiB limit.'
      using errcode = '22023';
  end if;
  if not (
    p_operation ? 'schema_version'
    and p_operation ? 'operation_id'
    and p_operation ? 'idempotency_key'
    and p_operation ? 'conversation_id'
    and p_operation ? 'message_id'
    and p_operation ? 'status'
    and p_operation ? 'proposal'
    and p_operation ? 'result'
  ) then
    raise exception 'AI action result is missing a required field.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_object_keys(p_operation) as operation_key
    where operation_key not in (
      'schema_version',
      'operation_id',
      'idempotency_key',
      'conversation_id',
      'message_id',
      'status',
      'proposal',
      'result',
      'request_id',
      'applied_submission_id',
      'error_code'
    )
  ) then
    raise exception 'AI action result has an unsupported field.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_operation -> 'schema_version') <> 'number'
    or p_operation ->> 'schema_version' !~ '^[0-9]+$'
  then
    raise exception 'schema_version must be the integer 1.'
      using errcode = '22023';
  end if;
  v_schema_version := (p_operation ->> 'schema_version')::integer;
  if v_schema_version <> 1 then
    raise exception 'Unsupported AI action schema version.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_operation -> 'operation_id') <> 'string'
    or p_operation ->> 'operation_id' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'operation_id must be a UUID string.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(p_operation -> 'idempotency_key') <> 'string'
    or p_operation ->> 'idempotency_key' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'idempotency_key must be a UUID string.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(p_operation -> 'conversation_id') <> 'string'
    or p_operation ->> 'conversation_id' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'conversation_id must be a UUID string.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(p_operation -> 'message_id') <> 'string'
    or p_operation ->> 'message_id' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'message_id must be a UUID string.'
      using errcode = '22023';
  end if;
  v_operation_id := (p_operation ->> 'operation_id')::uuid;
  v_idempotency_key := (p_operation ->> 'idempotency_key')::uuid;
  v_conversation_id := (p_operation ->> 'conversation_id')::uuid;
  v_message_id := (p_operation ->> 'message_id')::uuid;
  if v_operation_id = '00000000-0000-0000-0000-000000000000'::uuid
    or v_idempotency_key = '00000000-0000-0000-0000-000000000000'::uuid
    or v_conversation_id = '00000000-0000-0000-0000-000000000000'::uuid
    or v_message_id = '00000000-0000-0000-0000-000000000000'::uuid
  then
    raise exception 'AI action UUIDs cannot be nil.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_operation -> 'status') <> 'string'
    or p_operation ->> 'status' not in ('applied', 'rejected', 'failed')
  then
    raise exception 'Unsupported AI action status.'
      using errcode = '22023';
  end if;
  v_status := p_operation ->> 'status';
  v_proposal := p_operation -> 'proposal';
  v_result := p_operation -> 'result';
  if jsonb_typeof(v_proposal) <> 'object'
    or octet_length(v_proposal::text) > 32768
    or not public.perfect_ai_metadata_is_safe(v_proposal)
  then
    raise exception 'proposal must be a safe JSON object up to 32 KiB.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(v_result) <> 'object'
    or octet_length(v_result::text) > 32768
    or not public.perfect_ai_metadata_is_safe(v_result)
  then
    raise exception 'result must be a safe JSON object up to 32 KiB.'
      using errcode = '22023';
  end if;

  if p_operation ? 'request_id' then
    if jsonb_typeof(p_operation -> 'request_id') <> 'string'
      or p_operation ->> 'request_id' !~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then
      raise exception 'request_id must be a UUID string.'
        using errcode = '22023';
    end if;
    v_request_id := (p_operation ->> 'request_id')::uuid;
    if v_request_id = '00000000-0000-0000-0000-000000000000'::uuid then
      raise exception 'request_id cannot be the nil UUID.'
        using errcode = '22023';
    end if;
  end if;
  if p_operation ? 'applied_submission_id' then
    if jsonb_typeof(p_operation -> 'applied_submission_id') <> 'string'
      or p_operation ->> 'applied_submission_id' !~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then
      raise exception 'applied_submission_id must be a UUID string.'
        using errcode = '22023';
    end if;
    v_applied_submission_id :=
      (p_operation ->> 'applied_submission_id')::uuid;
    if v_applied_submission_id =
      '00000000-0000-0000-0000-000000000000'::uuid
    then
      raise exception 'applied_submission_id cannot be the nil UUID.'
        using errcode = '22023';
    end if;
    if not exists (
      select 1
      from public.planner_agent_submissions
      where owner_id = v_owner_id
        and submission_id = v_applied_submission_id
    ) then
      raise exception 'applied_submission_id does not belong to this owner.'
        using errcode = '23503';
    end if;
  end if;
  if p_operation ? 'error_code' then
    if jsonb_typeof(p_operation -> 'error_code') <> 'string'
      or char_length(trim(p_operation ->> 'error_code')) not between 1 and 80
    then
      raise exception 'error_code must contain 1 to 80 characters.'
        using errcode = '22023';
    end if;
    v_error_code := trim(p_operation ->> 'error_code');
  end if;

  select *
  into v_message
  from public.ai_messages
  where owner_id = v_owner_id and id = v_message_id;
  if not found
    or v_message.conversation_id is distinct from v_conversation_id
    or v_message.role <> 'assistant'
  then
    raise exception 'AI action must reference an assistant message in its conversation.'
      using errcode = '23503';
  end if;

  v_document_hash := encode(digest(p_operation::text, 'sha256'), 'hex');
  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:ai-action:' || v_owner_id::text || ':' ||
        v_idempotency_key::text,
      0
    )
  );
  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:ai-operation:' || v_owner_id::text || ':' ||
        v_operation_id::text,
      0
    )
  );

  select *
  into v_existing
  from public.ai_action_audit
  where owner_id = v_owner_id
    and (
      operation_id = v_operation_id
      or idempotency_key = v_idempotency_key
    )
  limit 1;
  if found then
    if v_existing.document_hash is distinct from v_document_hash
      or v_existing.request_document is distinct from p_operation
    then
      raise exception 'AI action idempotency key cannot be reused.'
        using errcode = '22023';
    end if;
    return jsonb_build_object(
      'status', 'acknowledged',
      'replayed', true,
      'operation', jsonb_build_object(
        'operation_id', v_existing.operation_id,
        'idempotency_key', v_existing.idempotency_key,
        'conversation_id', v_existing.conversation_id,
        'message_id', v_existing.source_message_id,
        'status', v_existing.status,
        'proposal', v_existing.proposal,
        'result', v_existing.result,
        'schema_version', v_existing.schema_version,
        'request_id', v_existing.request_id,
        'applied_submission_id', v_existing.applied_submission_id,
        'error_code', v_existing.error_code,
        'created_at', v_existing.created_at
      )
    );
  end if;

  insert into public.ai_action_audit (
    owner_id,
    operation_id,
    idempotency_key,
    conversation_id,
    source_message_id,
    status,
    proposal,
    result,
    schema_version,
    request_id,
    applied_submission_id,
    error_code,
    document_hash,
    request_document,
    created_at
  ) values (
    v_owner_id,
    v_operation_id,
    v_idempotency_key,
    v_conversation_id,
    v_message_id,
    v_status,
    v_proposal,
    v_result,
    v_schema_version,
    v_request_id,
    v_applied_submission_id,
    v_error_code,
    v_document_hash,
    p_operation,
    v_now
  ) returning * into v_saved;

  return jsonb_build_object(
    'status', 'acknowledged',
    'replayed', false,
    'operation', jsonb_build_object(
      'operation_id', v_saved.operation_id,
      'idempotency_key', v_saved.idempotency_key,
      'conversation_id', v_saved.conversation_id,
      'message_id', v_saved.source_message_id,
      'status', v_saved.status,
      'proposal', v_saved.proposal,
      'result', v_saved.result,
      'schema_version', v_saved.schema_version,
      'request_id', v_saved.request_id,
      'applied_submission_id', v_saved.applied_submission_id,
      'error_code', v_saved.error_code,
      'created_at', v_saved.created_at
    )
  );
end;
$$;

create or replace function public.list_ai_action_audit(
  p_conversation_id uuid,
  p_after_created_at timestamptz default null,
  p_after_operation_id uuid default null,
  p_limit integer default 100
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_limit integer;
  v_items jsonb;
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  if not exists (
    select 1
    from public.ai_conversations
    where owner_id = v_owner_id and id = p_conversation_id
  ) then
    raise exception 'AI conversation was not found.'
      using errcode = 'P0002';
  end if;
  if (p_after_created_at is null) <> (p_after_operation_id is null) then
    raise exception 'Action cursor fields must be supplied together.'
      using errcode = '22023';
  end if;
  v_limit := least(greatest(coalesce(p_limit, 100), 1), 200);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'operation_id', item.operation_id,
        'idempotency_key', item.idempotency_key,
        'conversation_id', item.conversation_id,
        'message_id', item.source_message_id,
        'status', item.status,
        'proposal', item.proposal,
        'result', item.result,
        'schema_version', item.schema_version,
        'request_id', item.request_id,
        'applied_submission_id', item.applied_submission_id,
        'error_code', item.error_code,
        'created_at', item.created_at
      )
      order by item.created_at, item.operation_id
    ),
    '[]'::jsonb
  )
  into v_items
  from (
    select audit.*
    from public.ai_action_audit as audit
    where audit.owner_id = v_owner_id
      and audit.conversation_id = p_conversation_id
      and (
        p_after_created_at is null
        or (audit.created_at, audit.operation_id) >
          (p_after_created_at, p_after_operation_id)
      )
    order by audit.created_at, audit.operation_id
    limit v_limit
  ) as item;

  return jsonb_build_object('items', v_items, 'limit', v_limit);
end;
$$;

create or replace function public.delete_ai_conversation(
  p_conversation_id uuid,
  p_mode text default 'soft',
  p_purge_after timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_now timestamptz := timezone('utc', now());
  v_retention_until timestamptz;
  v_deleted_count integer;
  v_saved public.ai_conversations%rowtype;
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  if p_mode not in ('soft', 'purge') then
    raise exception 'Delete mode must be soft or purge.'
      using errcode = '22023';
  end if;
  if p_mode = 'purge' and p_purge_after is not null then
    raise exception 'p_purge_after is only valid for soft deletion.'
      using errcode = '22023';
  end if;
  if p_purge_after is not null
    and (
      p_purge_after <= v_now
      or p_purge_after > v_now + interval '10 years'
    )
  then
    raise exception 'p_purge_after must be within the next 10 years.'
      using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:ai-conversation:' || v_owner_id::text || ':' ||
        p_conversation_id::text,
      0
    )
  );

  if p_mode = 'purge' then
    delete from public.ai_conversations
    where owner_id = v_owner_id and id = p_conversation_id;
    get diagnostics v_deleted_count = row_count;
    return jsonb_build_object(
      'status', case when v_deleted_count = 1 then 'purged' else 'not_found' end,
      'conversation_id', p_conversation_id
    );
  end if;

  v_retention_until := coalesce(
    p_purge_after,
    v_now + interval '30 days'
  );
  update public.ai_conversations
  set
    status = 'archived',
    deleted_at = coalesce(deleted_at, v_now),
    retention_until = case
      when deleted_at is null then v_retention_until
      else coalesce(retention_until, v_retention_until)
    end,
    updated_at = greatest(updated_at, v_now)
  where owner_id = v_owner_id and id = p_conversation_id
  returning * into v_saved;
  if not found then
    return jsonb_build_object(
      'status', 'not_found',
      'conversation_id', p_conversation_id
    );
  end if;
  return jsonb_build_object(
    'status', 'soft_deleted',
    'conversation_id', v_saved.id,
    'deleted_at', v_saved.deleted_at,
    'retention_until', v_saved.retention_until
  );
end;
$$;

create or replace function public.purge_expired_ai_conversations(
  p_limit integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_limit integer;
  v_deleted_count integer;
begin
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;
  v_limit := least(greatest(coalesce(p_limit, 100), 1), 500);

  with targets as (
    select conversation.owner_id, conversation.id
    from public.ai_conversations as conversation
    where conversation.owner_id = v_owner_id
      and conversation.retention_until is not null
      and conversation.retention_until <= timezone('utc', now())
    order by conversation.retention_until, conversation.id
    limit v_limit
    for update skip locked
  )
  delete from public.ai_conversations as conversation
  using targets
  where conversation.owner_id = targets.owner_id
    and conversation.id = targets.id;
  get diagnostics v_deleted_count = row_count;

  return jsonb_build_object(
    'status', 'purged',
    'count', v_deleted_count,
    'limit', v_limit
  );
end;
$$;

revoke all on function public.upsert_ai_conversation(
  uuid, text, text, timestamptz, integer
) from public, anon, authenticated;
revoke all on function public.list_ai_conversations(
  timestamptz, uuid, integer, boolean
) from public, anon, authenticated;
revoke all on function public.append_ai_message(jsonb)
  from public, anon, authenticated;
revoke all on function public.list_ai_messages(
  uuid, timestamptz, uuid, integer
) from public, anon, authenticated;
revoke all on function public.record_ai_action_result(jsonb)
  from public, anon, authenticated;
revoke all on function public.list_ai_action_audit(
  uuid, timestamptz, uuid, integer
) from public, anon, authenticated;
revoke all on function public.delete_ai_conversation(
  uuid, text, timestamptz
) from public, anon, authenticated;
revoke all on function public.purge_expired_ai_conversations(integer)
  from public, anon, authenticated;

grant execute on function public.upsert_ai_conversation(
  uuid, text, text, timestamptz, integer
) to authenticated;
grant execute on function public.list_ai_conversations(
  timestamptz, uuid, integer, boolean
) to authenticated;
grant execute on function public.append_ai_message(jsonb) to authenticated;
grant execute on function public.list_ai_messages(
  uuid, timestamptz, uuid, integer
) to authenticated;
grant execute on function public.record_ai_action_result(jsonb)
  to authenticated;
grant execute on function public.list_ai_action_audit(
  uuid, timestamptz, uuid, integer
) to authenticated;
grant execute on function public.delete_ai_conversation(
  uuid, text, timestamptz
) to authenticated;
grant execute on function public.purge_expired_ai_conversations(integer)
  to authenticated;

do $$
begin
  alter publication supabase_realtime add table public.ai_conversations;
exception
  when duplicate_object then null;
  when undefined_object then null;
end;
$$;

do $$
begin
  alter publication supabase_realtime add table public.ai_messages;
exception
  when duplicate_object then null;
  when undefined_object then null;
end;
$$;

do $$
begin
  alter publication supabase_realtime add table public.ai_action_audit;
exception
  when duplicate_object then null;
  when undefined_object then null;
end;
$$;
