-- Perfect planner v2 is deliberately additive. `perfect_items` remains the
-- legacy bridge for existing clients and is never modified by this migration.
--
-- Before an app can use v2, an administrator must create exactly one row in
-- `planner_owner_profiles` for the already-created private Auth user. There is
-- intentionally no client-side bootstrap function: public signup is disabled
-- outside this migration and clients cannot self-enroll as an owner.

create extension if not exists pgcrypto;

create table if not exists public.planner_owner_profiles (
  owner_id uuid primary key references auth.users (id) on delete cascade,
  -- Perfect is a single-owner private workspace, not a shared tenant. This
  -- unique slot makes that product boundary enforceable at the database layer.
  private_workspace_slot boolean not null default true unique
    check (private_workspace_slot),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.planner_entities (
  id uuid primary key,
  owner_id uuid not null references public.planner_owner_profiles (owner_id) on delete cascade,
  kind text not null check (
    kind in (
      'one_off_task',
      'recurring_task',
      'habit',
      'project',
      'area',
      'occurrence',
      'habit_log',
      'focus_session',
      'property_definition',
      'relation'
    )
  ),
  title text not null default '' check (char_length(title) <= 160),
  lifecycle_state text not null default 'active' check (
    lifecycle_state in (
      'inbox', 'active', 'planned', 'completed', 'archived', 'cancelled', 'paused'
    )
  ),
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  field_versions jsonb not null default '{}'::jsonb check (jsonb_typeof(field_versions) = 'object'),
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  last_operation_id uuid,
  constraint planner_entities_timestamp_order check (updated_at >= created_at)
);

create index if not exists planner_entities_owner_updated_idx
  on public.planner_entities (owner_id, updated_at desc);
create index if not exists planner_entities_owner_active_idx
  on public.planner_entities (owner_id, kind, lifecycle_state, updated_at desc)
  where deleted_at is null;

create table if not exists public.planner_operations (
  owner_id uuid not null references public.planner_owner_profiles (owner_id) on delete cascade,
  mutation_id uuid not null,
  device_id uuid not null,
  entity_id uuid not null,
  entity_kind text not null,
  base_revision bigint not null check (base_revision >= 0),
  operation_type text not null check (operation_type in ('upsert', 'soft_delete', 'restore')),
  field_paths text[] not null default '{}',
  patch jsonb not null default '{}'::jsonb check (jsonb_typeof(patch) = 'object'),
  status text not null check (status in ('acknowledged', 'conflict')),
  result jsonb not null check (jsonb_typeof(result) = 'object'),
  created_at timestamptz not null default timezone('utc', now()),
  applied_at timestamptz not null default timezone('utc', now()),
  primary key (owner_id, mutation_id)
);

create index if not exists planner_operations_owner_entity_idx
  on public.planner_operations (owner_id, entity_id, applied_at desc);

create table if not exists public.planner_changes (
  change_id bigint generated always as identity primary key,
  owner_id uuid not null references public.planner_owner_profiles (owner_id) on delete cascade,
  entity_id uuid not null,
  entity_kind text not null,
  revision bigint not null check (revision >= 0),
  operation_id uuid not null,
  operation_type text not null check (operation_type in ('upsert', 'soft_delete', 'restore')),
  snapshot jsonb not null check (jsonb_typeof(snapshot) = 'object'),
  committed_at timestamptz not null default timezone('utc', now())
);

create index if not exists planner_changes_owner_cursor_idx
  on public.planner_changes (owner_id, change_id);

create table if not exists public.planner_sync_conflicts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.planner_owner_profiles (owner_id) on delete cascade,
  entity_id uuid not null,
  mutation_id uuid not null,
  base_revision bigint not null check (base_revision >= 0),
  current_revision bigint not null check (current_revision >= 0),
  conflicting_paths text[] not null default '{}',
  local_patch jsonb not null check (jsonb_typeof(local_patch) = 'object'),
  server_snapshot jsonb not null check (jsonb_typeof(server_snapshot) = 'object'),
  resolution text not null default 'open' check (resolution in ('open', 'kept_local', 'kept_server', 'merged')),
  created_at timestamptz not null default timezone('utc', now()),
  resolved_at timestamptz
);

create index if not exists planner_sync_conflicts_owner_open_idx
  on public.planner_sync_conflicts (owner_id, created_at desc)
  where resolution = 'open';

alter table public.planner_owner_profiles enable row level security;
alter table public.planner_entities enable row level security;
alter table public.planner_operations enable row level security;
alter table public.planner_changes enable row level security;
alter table public.planner_sync_conflicts enable row level security;

create policy "private owner reads own profile"
  on public.planner_owner_profiles for select to authenticated
  using (owner_id = auth.uid());

create policy "private owner reads own planner entities"
  on public.planner_entities for select to authenticated
  using (owner_id = auth.uid());

create policy "private owner reads own planner operations"
  on public.planner_operations for select to authenticated
  using (owner_id = auth.uid());

create policy "private owner reads own planner changes"
  on public.planner_changes for select to authenticated
  using (owner_id = auth.uid());

create policy "private owner reads own planner conflicts"
  on public.planner_sync_conflicts for select to authenticated
  using (owner_id = auth.uid());

-- The client receives no direct v2 mutation privilege. The tightly scoped RPC
-- below is the only mutation boundary and validates auth, ownership,
-- idempotency and revision before it writes anything.
revoke all on table public.planner_owner_profiles from anon, authenticated;
revoke all on table public.planner_entities from anon, authenticated;
revoke all on table public.planner_operations from anon, authenticated;
revoke all on table public.planner_changes from anon, authenticated;
revoke all on table public.planner_sync_conflicts from anon, authenticated;
grant select on table public.planner_owner_profiles to authenticated;
grant select on table public.planner_changes to authenticated;
grant select on table public.planner_sync_conflicts to authenticated;

create or replace function public.perfect_jsonb_deep_merge(
  p_base jsonb,
  p_patch jsonb
)
returns jsonb
language sql
immutable
set search_path = public, pg_temp
as $$
  select case
    when jsonb_typeof(coalesce(p_base, '{}'::jsonb)) = 'object'
      and jsonb_typeof(coalesce(p_patch, '{}'::jsonb)) = 'object'
    then coalesce(
      (
        select jsonb_object_agg(
          merged.key,
          case
            when p_base ? merged.key
              and jsonb_typeof(p_base -> merged.key) = 'object'
              and jsonb_typeof(merged.value) = 'object'
            then public.perfect_jsonb_deep_merge(p_base -> merged.key, merged.value)
            else merged.value
          end
        )
        from jsonb_each(coalesce(p_base, '{}'::jsonb) || coalesce(p_patch, '{}'::jsonb)) as merged
      ),
      '{}'::jsonb
    )
    else coalesce(p_patch, p_base, '{}'::jsonb)
  end;
$$;

create or replace function public.apply_planner_mutation(
  p_mutation_id uuid,
  p_device_id uuid,
  p_entity_id uuid,
  p_entity_kind text,
  p_base_revision bigint,
  p_operation_type text,
  p_field_paths text[],
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
  v_existing public.planner_entities%rowtype;
  v_existing_operation public.planner_operations%rowtype;
  v_saved public.planner_entities%rowtype;
  v_result jsonb;
  v_conflict_id uuid;
  v_conflicting_paths text[];
  v_normalized_field_paths text[];
  v_field_versions jsonb;
  v_next_revision bigint;
  v_title text;
  v_lifecycle_state text;
  v_deleted_at timestamptz;
begin
  if v_owner_id is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;

  if p_mutation_id is null or p_device_id is null or p_entity_id is null then
    raise exception 'Mutation, device and entity IDs are required.' using errcode = '22023';
  end if;

  if p_base_revision is null or p_base_revision < 0 then
    raise exception 'base_revision must be zero or greater.' using errcode = '22023';
  end if;

  if p_entity_kind not in (
    'one_off_task', 'recurring_task', 'habit', 'project', 'area', 'occurrence',
    'habit_log', 'focus_session', 'property_definition', 'relation'
  ) then
    raise exception 'Unsupported planner entity kind.' using errcode = '22023';
  end if;

  if p_operation_type not in ('upsert', 'soft_delete', 'restore') then
    raise exception 'Unsupported planner operation type.' using errcode = '22023';
  end if;

  if jsonb_typeof(coalesce(p_patch, '{}'::jsonb)) <> 'object' then
    raise exception 'patch must be a JSON object.' using errcode = '22023';
  end if;

  -- A mutation without named paths would turn the field-level conflict model
  -- into silent whole-record last-write-wins. Every client write must declare
  -- the JSON paths it owns, including creation (normally the root path `/`).
  if cardinality(coalesce(p_field_paths, '{}')) = 0 then
    raise exception 'At least one field path is required.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from unnest(p_field_paths) as path
    where path is null or path !~ '^/'
  ) then
    raise exception 'Every field path must be an absolute JSON path.'
      using errcode = '22023';
  end if;

  select coalesce(array_agg(distinct path order by path), '{}')
  into v_normalized_field_paths
  from unnest(p_field_paths) as path;

  -- Serialize a mutation key before inspecting its durable receipt. Without
  -- this lock two simultaneous retries can both miss planner_operations and
  -- race into a primary-key error after applying different side effects.
  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:planner-mutation:' || v_owner_id::text || ':' || p_mutation_id::text,
      0
    )
  );

  select * into v_existing_operation
  from public.planner_operations
  where owner_id = v_owner_id and mutation_id = p_mutation_id;
  if found then
    if v_existing_operation.device_id is distinct from p_device_id
      or v_existing_operation.entity_id is distinct from p_entity_id
      or v_existing_operation.entity_kind is distinct from p_entity_kind
      or v_existing_operation.base_revision is distinct from p_base_revision
      or v_existing_operation.operation_type is distinct from p_operation_type
      or v_existing_operation.field_paths is distinct from v_normalized_field_paths
      or v_existing_operation.patch is distinct from coalesce(p_patch, '{}'::jsonb)
    then
      raise exception 'A mutation ID cannot be reused for a different request.'
        using errcode = '22023';
    end if;
    return v_existing_operation.result;
  end if;

  -- Different mutation IDs for the same entity are serialized as well. The
  -- following revision read is therefore stable for the remainder of this
  -- transaction, including first-writer creation.
  perform pg_advisory_xact_lock(
    hashtextextended(
      'perfect:planner-entity:' || v_owner_id::text || ':' || p_entity_id::text,
      0
    )
  );

  select * into v_existing
  from public.planner_entities
  where owner_id = v_owner_id and id = p_entity_id
  for update;

  if not found then
    if p_base_revision <> 0 then
      raise exception 'A new entity must use base revision zero.' using errcode = '40001';
    end if;

    v_next_revision := 1;
    v_title := trim(coalesce(
      p_patch ->> 'title',
      p_patch #>> '{payload,title}',
      ''
    ));
    -- Occurrence/focus outcomes live inside payload. Values such as pending,
    -- missed and partial are not entity lifecycle states and must never leak
    -- into the constrained lifecycle_state column.
    v_lifecycle_state := case
      when p_entity_kind in (
        'occurrence', 'habit_log', 'focus_session', 'property_definition', 'relation'
      ) then 'active'
      else coalesce(
        p_patch ->> 'lifecycle_state',
        p_patch #>> '{payload,status}',
        'active'
      )
    end;
    v_deleted_at := case when p_operation_type = 'soft_delete'
      then timezone('utc', now()) else null end;
  else
    if v_existing.kind <> p_entity_kind then
      raise exception 'Entity kind cannot change.' using errcode = '22023';
    end if;

    if p_base_revision > v_existing.revision then
      raise exception 'base_revision is ahead of the server revision.' using errcode = '40001';
    end if;

    if p_base_revision < v_existing.revision then
      select coalesce(array_agg(path order by path), '{}')
      into v_conflicting_paths
      from unnest(v_normalized_field_paths) as path
      where (path = '/' and v_existing.revision > p_base_revision)
        or (
          path <> '/'
          and (
            coalesce((v_existing.field_versions ->> path)::bigint, 0) > p_base_revision
            or coalesce((v_existing.field_versions ->> '/')::bigint, 0) > p_base_revision
          )
        );

      if cardinality(v_conflicting_paths) > 0 then
        insert into public.planner_sync_conflicts (
          owner_id,
          entity_id,
          mutation_id,
          base_revision,
          current_revision,
          conflicting_paths,
          local_patch,
          server_snapshot
        ) values (
          v_owner_id,
          p_entity_id,
          p_mutation_id,
          p_base_revision,
          v_existing.revision,
          v_conflicting_paths,
          p_patch,
          jsonb_build_object(
            'id', v_existing.id,
            'kind', v_existing.kind,
            'title', v_existing.title,
            'lifecycle_state', v_existing.lifecycle_state,
            'payload', v_existing.payload,
            'field_versions', v_existing.field_versions,
            'revision', v_existing.revision,
            'created_at', v_existing.created_at,
            'updated_at', v_existing.updated_at,
            'deleted_at', v_existing.deleted_at
          )
        ) returning id into v_conflict_id;

        v_result := jsonb_build_object(
          'status', 'conflict',
          'conflict_id', v_conflict_id,
          'entity_id', p_entity_id,
          'current_revision', v_existing.revision,
          'conflicting_paths', to_jsonb(v_conflicting_paths),
          'entity', jsonb_build_object(
            'id', v_existing.id,
            'owner_id', v_owner_id,
            'kind', v_existing.kind,
            'title', v_existing.title,
            'lifecycle_state', v_existing.lifecycle_state,
            'payload', v_existing.payload,
            'field_versions', v_existing.field_versions,
            'revision', v_existing.revision,
            'created_at', v_existing.created_at,
            'updated_at', v_existing.updated_at,
            'deleted_at', v_existing.deleted_at
          )
        );

        insert into public.planner_operations (
          owner_id, mutation_id, device_id, entity_id, entity_kind,
          base_revision, operation_type, field_paths, patch, status, result
        ) values (
          v_owner_id, p_mutation_id, p_device_id, p_entity_id, p_entity_kind,
          p_base_revision, p_operation_type, v_normalized_field_paths,
          p_patch, 'conflict', v_result
        );

        return v_result;
      end if;
    end if;

    v_next_revision := v_existing.revision + 1;
    v_title := case
      when p_patch ? 'title' then trim(coalesce(p_patch ->> 'title', ''))
      when coalesce(p_patch -> 'payload', '{}'::jsonb) ? 'title'
        then trim(coalesce(p_patch #>> '{payload,title}', ''))
      else v_existing.title
    end;
    v_lifecycle_state := case
      when p_entity_kind in (
        'occurrence', 'habit_log', 'focus_session', 'property_definition', 'relation'
      ) then v_existing.lifecycle_state
      when p_patch ? 'lifecycle_state' then p_patch ->> 'lifecycle_state'
      when coalesce(p_patch -> 'payload', '{}'::jsonb) ? 'status'
        then p_patch #>> '{payload,status}'
      else v_existing.lifecycle_state
    end;
    v_deleted_at := case
      when p_operation_type = 'soft_delete' then timezone('utc', now())
      when p_operation_type = 'restore' then null
      else v_existing.deleted_at
    end;
  end if;

  if v_lifecycle_state not in (
    'inbox', 'active', 'planned', 'completed', 'archived', 'cancelled', 'paused'
  ) then
    raise exception 'Unsupported lifecycle state.' using errcode = '22023';
  end if;

  if p_entity_kind in ('one_off_task', 'recurring_task', 'habit', 'project', 'area')
    and char_length(v_title) not between 1 and 160 then
    raise exception 'This planner entity needs a title between 1 and 160 characters.'
      using errcode = '22023';
  end if;

  select coalesce(jsonb_object_agg(path, to_jsonb(v_next_revision)), '{}'::jsonb)
  into v_field_versions
  from unnest(v_normalized_field_paths) as path;

  if v_existing.id is null then
    insert into public.planner_entities (
      id, owner_id, kind, title, lifecycle_state, payload, field_versions,
      revision, created_at, updated_at, deleted_at, last_operation_id
    ) values (
      p_entity_id,
      v_owner_id,
      p_entity_kind,
      v_title,
      v_lifecycle_state,
      coalesce(p_patch -> 'payload', '{}'::jsonb),
      v_field_versions,
      v_next_revision,
      timezone('utc', now()),
      timezone('utc', now()),
      v_deleted_at,
      p_mutation_id
    ) returning * into v_saved;
  else
    update public.planner_entities
    set
      title = v_title,
      lifecycle_state = v_lifecycle_state,
      payload = public.perfect_jsonb_deep_merge(
        v_existing.payload,
        coalesce(p_patch -> 'payload', '{}'::jsonb)
      ),
      field_versions = v_existing.field_versions || v_field_versions,
      revision = v_next_revision,
      updated_at = timezone('utc', now()),
      deleted_at = v_deleted_at,
      last_operation_id = p_mutation_id
    where owner_id = v_owner_id and id = p_entity_id
    returning * into v_saved;
  end if;

  v_result := jsonb_build_object(
    'status', 'acknowledged',
    'entity', jsonb_build_object(
      'id', v_saved.id,
      'owner_id', v_saved.owner_id,
      'kind', v_saved.kind,
      'title', v_saved.title,
      'lifecycle_state', v_saved.lifecycle_state,
      'payload', v_saved.payload,
      'field_versions', v_saved.field_versions,
      'revision', v_saved.revision,
      'created_at', v_saved.created_at,
      'updated_at', v_saved.updated_at,
      'deleted_at', v_saved.deleted_at
    )
  );

  insert into public.planner_operations (
    owner_id, mutation_id, device_id, entity_id, entity_kind,
    base_revision, operation_type, field_paths, patch, status, result
  ) values (
    v_owner_id, p_mutation_id, p_device_id, p_entity_id, p_entity_kind,
    p_base_revision, p_operation_type, v_normalized_field_paths,
    p_patch, 'acknowledged', v_result
  );

  insert into public.planner_changes (
    owner_id, entity_id, entity_kind, revision, operation_id,
    operation_type, snapshot
  ) values (
    v_owner_id, v_saved.id, v_saved.kind, v_saved.revision, p_mutation_id,
    p_operation_type, v_result -> 'entity'
  );

  return v_result;
end;
$$;

create or replace function public.pull_planner_changes(
  p_after_change_id bigint default 0,
  p_limit integer default 200
)
returns table (
  change_id bigint,
  entity_id uuid,
  entity_kind text,
  revision bigint,
  operation_id uuid,
  operation_type text,
  snapshot jsonb,
  committed_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid := auth.uid();
begin
  if v_owner_id is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.planner_owner_profiles where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;

  return query
  select
    change.change_id,
    change.entity_id,
    change.entity_kind,
    change.revision,
    change.operation_id,
    change.operation_type,
    change.snapshot,
    change.committed_at
  from public.planner_changes as change
  where change.owner_id = v_owner_id
    and change.change_id > greatest(coalesce(p_after_change_id, 0), 0)
  order by change.change_id asc
  limit least(greatest(coalesce(p_limit, 200), 1), 500);
end;
$$;

revoke all on function public.apply_planner_mutation(uuid, uuid, uuid, text, bigint, text, text[], jsonb) from public, anon;
revoke all on function public.pull_planner_changes(bigint, integer) from public, anon;
grant execute on function public.apply_planner_mutation(uuid, uuid, uuid, text, bigint, text, text[], jsonb) to authenticated;
grant execute on function public.pull_planner_changes(bigint, integer) to authenticated;

-- Realtime is an optional wake-up hint. Correctness remains cursor-based via
-- `pull_planner_changes`, so dropped events never become data loss.
do $$
begin
  alter publication supabase_realtime add table public.planner_changes;
exception
  when duplicate_object then null;
  when undefined_object then null;
end;
$$;
