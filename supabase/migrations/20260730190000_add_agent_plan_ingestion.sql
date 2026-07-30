-- Agent-authored planner proposals for the private Perfect workspace.
--
-- This migration is deliberately additive. It does not rewrite an existing
-- planner entity or any earlier migration. The RPC accepts an authenticated
-- owner session (publishable key + user access token), never a service-role
-- key, and projects every accepted item through apply_planner_mutation so the
-- existing planner_changes cursor/realtime sync path sees it immediately.

create table if not exists public.planner_agent_submissions (
  owner_id uuid not null
    references public.planner_owner_profiles (owner_id) on delete cascade,
  submission_id uuid not null,
  contract_version smallint not null check (contract_version = 1),
  agent_device_id uuid not null,
  document_hash text not null check (document_hash ~ '^[0-9a-f]{64}$'),
  source jsonb not null check (jsonb_typeof(source) = 'object'),
  plan jsonb not null check (jsonb_typeof(plan) = 'object'),
  item_count integer not null check (item_count between 1 and 100),
  request_document jsonb not null
    check (jsonb_typeof(request_document) = 'object'),
  result jsonb not null check (jsonb_typeof(result) = 'object'),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (owner_id, submission_id)
);

create index if not exists planner_agent_submissions_owner_created_idx
  on public.planner_agent_submissions (owner_id, created_at desc);

alter table public.planner_agent_submissions enable row level security;

-- Submission receipts are private implementation/audit records. The owner
-- receives the receipt from the RPC; no Data API role needs direct table
-- access, even if this project's default privileges are unusually broad.
revoke all on table public.planner_agent_submissions
  from public, anon, authenticated;

create or replace function public.submit_agent_plan(
  p_document jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_contract_version integer;
  v_submission_id uuid;
  v_agent_device_id uuid;
  v_document_hash text;
  v_source jsonb;
  v_plan jsonb;
  v_items jsonb;
  v_item_count integer;
  v_existing public.planner_agent_submissions%rowtype;
  v_item jsonb;
  v_item_index bigint;
  v_entity_id uuid;
  v_operation_id uuid;
  v_entity_kind text;
  v_title text;
  v_payload jsonb;
  v_patch jsonb;
  v_mutation_result jsonb;
  v_entities jsonb := '[]'::jsonb;
  v_entity_ids uuid[] := '{}'::uuid[];
  v_now timestamptz := timezone('utc', now());
  v_result jsonb;
begin
  -- A service-role/admin secret is intentionally not a supported caller
  -- identity. Codex-like agents use the same short-lived owner Auth session as
  -- the app, plus the public project key.
  if auth.role() is distinct from 'authenticated' or v_owner_id is null then
    raise exception 'An authenticated Perfect owner session is required.'
      using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.planner_owner_profiles
    where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;

  if jsonb_typeof(p_document) is distinct from 'object' then
    raise exception 'Agent plan document must be a JSON object.'
      using errcode = '22023';
  end if;

  if octet_length(p_document::text) > 524288 then
    raise exception 'Agent plan document exceeds the 512 KiB limit.'
      using errcode = '22023';
  end if;

  if not (
    p_document ? 'schema_version'
    and p_document ? 'submission_id'
    and p_document ? 'agent_device_id'
    and p_document ? 'source'
    and p_document ? 'plan'
    and p_document ? 'items'
  ) then
    raise exception 'Agent plan document is missing a required top-level field.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_object_keys(p_document) as document_key
    where document_key not in (
      'schema_version',
      'submission_id',
      'agent_device_id',
      'source',
      'plan',
      'items'
    )
  ) then
    raise exception 'Agent plan document has an unsupported top-level field.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_document -> 'schema_version') <> 'number'
    or p_document ->> 'schema_version' !~ '^[0-9]+$'
  then
    raise exception 'schema_version must be the integer 1.'
      using errcode = '22023';
  end if;
  v_contract_version := (p_document ->> 'schema_version')::integer;
  if v_contract_version <> 1 then
    raise exception 'Unsupported agent plan schema_version.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_document -> 'submission_id') <> 'string'
    or p_document ->> 'submission_id' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'submission_id must be a UUID string.'
      using errcode = '22023';
  end if;
  v_submission_id := (p_document ->> 'submission_id')::uuid;
  if v_submission_id = '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'submission_id cannot be the nil UUID.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_document -> 'agent_device_id') <> 'string'
    or p_document ->> 'agent_device_id' !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then
    raise exception 'agent_device_id must be a UUID string.'
      using errcode = '22023';
  end if;
  v_agent_device_id := (p_document ->> 'agent_device_id')::uuid;
  if v_agent_device_id = '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'agent_device_id cannot be the nil UUID.'
      using errcode = '22023';
  end if;

  -- jsonb::text is canonical for object key ordering, so the same semantic
  -- document produces the same digest even if an agent formats it differently.
  v_document_hash := encode(digest(p_document::text, 'sha256'), 'hex');

  -- Serialize the idempotency key before inspecting or creating its receipt.
  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:agent-plan:' || v_owner_id::text || ':' || v_submission_id::text,
      0
    )
  );

  select *
  into v_existing
  from public.planner_agent_submissions
  where owner_id = v_owner_id
    and submission_id = v_submission_id;

  if found then
    if v_existing.document_hash is distinct from v_document_hash
      or v_existing.request_document is distinct from p_document
    then
      raise exception 'submission_id cannot be reused for a different document.'
        using errcode = '22023';
    end if;
    return v_existing.result || jsonb_build_object('replayed', true);
  end if;

  v_source := p_document -> 'source';
  if jsonb_typeof(v_source) is distinct from 'object' then
    raise exception 'source must be a JSON object.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_object_keys(v_source) as source_key
    where source_key not in (
      'agent',
      'model',
      'version',
      'run_id',
      'generated_at'
    )
  ) then
    raise exception 'source has an unsupported field.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(v_source -> 'agent') <> 'string'
    or char_length(trim(v_source ->> 'agent')) not between 1 and 80
  then
    raise exception 'source.agent must contain 1 to 80 characters.'
      using errcode = '22023';
  end if;
  if v_source ? 'model'
    and (
      jsonb_typeof(v_source -> 'model') <> 'string'
      or char_length(trim(v_source ->> 'model')) not between 1 and 120
    )
  then
    raise exception 'source.model must contain 1 to 120 characters.'
      using errcode = '22023';
  end if;
  if v_source ? 'version'
    and (
      jsonb_typeof(v_source -> 'version') <> 'string'
      or char_length(trim(v_source ->> 'version')) not between 1 and 80
    )
  then
    raise exception 'source.version must contain 1 to 80 characters.'
      using errcode = '22023';
  end if;
  if v_source ? 'run_id'
    and (
      jsonb_typeof(v_source -> 'run_id') <> 'string'
      or char_length(trim(v_source ->> 'run_id')) not between 1 and 160
    )
  then
    raise exception 'source.run_id must contain 1 to 160 characters.'
      using errcode = '22023';
  end if;
  if v_source ? 'generated_at' then
    if jsonb_typeof(v_source -> 'generated_at') <> 'string'
      or v_source ->> 'generated_at' !~ '(Z|[+-][0-9]{2}:[0-9]{2})$'
    then
      raise exception 'source.generated_at must be an ISO-8601 timestamp string.'
        using errcode = '22023';
    end if;
    begin
      perform (v_source ->> 'generated_at')::timestamptz;
    exception when invalid_datetime_format or datetime_field_overflow then
      raise exception 'source.generated_at must be an ISO-8601 timestamp string.'
        using errcode = '22023';
    end;
  end if;

  v_plan := p_document -> 'plan';
  if jsonb_typeof(v_plan) is distinct from 'object' then
    raise exception 'plan must be a JSON object.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_object_keys(v_plan) as plan_key
    where plan_key not in ('title', 'summary')
  ) then
    raise exception 'plan has an unsupported field.'
      using errcode = '22023';
  end if;
  if jsonb_typeof(v_plan -> 'title') <> 'string'
    or char_length(trim(v_plan ->> 'title')) not between 1 and 160
  then
    raise exception 'plan.title must contain 1 to 160 characters.'
      using errcode = '22023';
  end if;
  if v_plan ? 'summary'
    and (
      jsonb_typeof(v_plan -> 'summary') <> 'string'
      or char_length(v_plan ->> 'summary') > 4000
    )
  then
    raise exception 'plan.summary must be a string of at most 4000 characters.'
      using errcode = '22023';
  end if;

  v_items := p_document -> 'items';
  if jsonb_typeof(v_items) is distinct from 'array' then
    raise exception 'items must be a JSON array.'
      using errcode = '22023';
  end if;
  v_item_count := jsonb_array_length(v_items);
  if v_item_count not between 1 and 100 then
    raise exception 'items must contain between 1 and 100 planner proposals.'
      using errcode = '22023';
  end if;

  -- Validate the complete batch before any entity mutation. An exception also
  -- rolls back the transaction, but this two-pass shape produces clearer
  -- failures and avoids needless work for an invalid item near the end.
  for v_item, v_item_index in
    select item.value, item.ordinality
    from jsonb_array_elements(v_items) with ordinality as item(value, ordinality)
  loop
    if jsonb_typeof(v_item) is distinct from 'object' then
      raise exception 'items[%] must be a JSON object.', v_item_index - 1
        using errcode = '22023';
    end if;
    if octet_length(v_item::text) > 32768 then
      raise exception 'items[%] exceeds the 32 KiB limit.', v_item_index - 1
        using errcode = '22023';
    end if;
    if not (v_item ? 'id' and v_item ? 'kind' and v_item ? 'title') then
      raise exception 'items[%] is missing id, kind or title.', v_item_index - 1
        using errcode = '22023';
    end if;
    if exists (
      select 1
      from jsonb_object_keys(v_item) as item_key
      where item_key not in ('id', 'kind', 'title', 'payload')
    ) then
      raise exception 'items[%] has an unsupported field.', v_item_index - 1
        using errcode = '22023';
    end if;
    if jsonb_typeof(v_item -> 'id') <> 'string'
      or v_item ->> 'id' !~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then
      raise exception 'items[%].id must be a UUID string.', v_item_index - 1
        using errcode = '22023';
    end if;
    v_entity_id := (v_item ->> 'id')::uuid;
    if v_entity_id = '00000000-0000-0000-0000-000000000000'::uuid then
      raise exception 'items[%].id cannot be the nil UUID.', v_item_index - 1
        using errcode = '22023';
    end if;
    if v_entity_id = any(v_entity_ids) then
      raise exception 'items[%].id is duplicated in this document.', v_item_index - 1
        using errcode = '22023';
    end if;
    v_entity_ids := array_append(v_entity_ids, v_entity_id);

    if jsonb_typeof(v_item -> 'kind') <> 'string'
      or v_item ->> 'kind' not in (
        'one_off_task', 'recurring_task', 'habit', 'project'
      )
    then
      raise exception 'items[%].kind is unsupported.', v_item_index - 1
        using errcode = '22023';
    end if;
    if jsonb_typeof(v_item -> 'title') <> 'string'
      or char_length(trim(v_item ->> 'title')) not between 1 and 160
    then
      raise exception 'items[%].title must contain 1 to 160 characters.',
        v_item_index - 1 using errcode = '22023';
    end if;

    v_payload := coalesce(v_item -> 'payload', '{}'::jsonb);
    if jsonb_typeof(v_payload) is distinct from 'object' then
      raise exception 'items[%].payload must be a JSON object.', v_item_index - 1
        using errcode = '22023';
    end if;
    if octet_length(v_payload::text) > 24576 then
      raise exception 'items[%].payload exceeds the 24 KiB limit.',
        v_item_index - 1 using errcode = '22023';
    end if;
    if (
      select count(*)
      from jsonb_object_keys(v_payload)
    ) > 128 then
      raise exception 'items[%].payload has too many top-level fields.',
        v_item_index - 1 using errcode = '22023';
    end if;
    if v_payload ? 'agent_proposal' then
      raise exception 'items[%].payload.agent_proposal is server-managed.',
        v_item_index - 1 using errcode = '22023';
    end if;

    -- This boundary is create-only. Existing records require the owner's
    -- normal in-app editor/conflict flow and can never be silently overwritten
    -- by an external planning agent.
    if exists (
      select 1
      from public.planner_entities
      where owner_id = v_owner_id and id = v_entity_id
    ) then
      raise exception 'items[%].id already exists; agent submissions are create-only.',
        v_item_index - 1 using errcode = '23505';
    end if;
  end loop;

  for v_item, v_item_index in
    select item.value, item.ordinality
    from jsonb_array_elements(v_items) with ordinality as item(value, ordinality)
  loop
    v_entity_id := (v_item ->> 'id')::uuid;
    v_entity_kind := v_item ->> 'kind';
    v_title := trim(v_item ->> 'title');
    v_operation_id := gen_random_uuid();
    v_payload := coalesce(v_item -> 'payload', '{}'::jsonb)
      || jsonb_build_object(
        'title', v_title,
        'status', 'active',
        -- Existing cards already render category metadata. Keep an explicit
        -- agent category as authored, otherwise make the proposed nature
        -- visible without waiting for a new client release.
        'category', coalesce(
          nullif(trim(v_item #>> '{payload,category}'), ''),
          'Agent proposal'
        ),
        'agent_proposal', jsonb_build_object(
          'contract_version', v_contract_version,
          'submission_id', v_submission_id,
          'item_index', v_item_index - 1,
          'submitted_at', v_now,
          'source', v_source,
          'plan', v_plan,
          'review', jsonb_build_object(
            'status', 'proposed',
            'requires_owner_review', true,
            'reviewed_at', null
          )
        )
      );
    v_patch := jsonb_build_object(
      'title', v_title,
      'lifecycle_state', 'active',
      'payload', v_payload
    );

    v_mutation_result := public.apply_planner_mutation(
      v_operation_id,
      v_agent_device_id,
      v_entity_id,
      v_entity_kind,
      0,
      'upsert',
      array['/']::text[],
      v_patch
    );

    if v_mutation_result ->> 'status' is distinct from 'acknowledged' then
      raise exception 'An agent item collided with a concurrent planner write.'
        using errcode = '40001';
    end if;

    v_entities := v_entities || jsonb_build_array(
      jsonb_build_object(
        'operation_id', v_operation_id,
        'entity', v_mutation_result -> 'entity'
      )
    );
  end loop;

  v_result := jsonb_build_object(
    'status', 'accepted',
    'replayed', false,
    'schema_version', v_contract_version,
    'submission_id', v_submission_id,
    'review_status', 'proposed',
    'item_count', v_item_count,
    'entities', v_entities
  );

  insert into public.planner_agent_submissions (
    owner_id,
    submission_id,
    contract_version,
    agent_device_id,
    document_hash,
    source,
    plan,
    item_count,
    request_document,
    result,
    created_at
  ) values (
    v_owner_id,
    v_submission_id,
    v_contract_version,
    v_agent_device_id,
    v_document_hash,
    v_source,
    v_plan,
    v_item_count,
    p_document,
    v_result,
    v_now
  );

  return v_result;
end;
$$;

revoke all on function public.submit_agent_plan(jsonb)
  from public, anon, authenticated;
grant execute on function public.submit_agent_plan(jsonb) to authenticated;

comment on function public.submit_agent_plan(jsonb) is
  'Atomically creates owner-visible, review-required planner proposals from a versioned agent plan document.';
