-- Stage 36: additive, owner-scoped saved-view sync. This migration never
-- changes planner task/entity RPCs or their UUID operation receipts.
create table public.planner_saved_views (
  id text primary key check (
    id ~ '^view-[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  ),
  owner_id uuid not null references public.planner_owner_profiles(owner_id) on delete cascade,
  definition jsonb not null check (jsonb_typeof(definition) = 'object'),
  revision bigint not null check (revision >= 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  last_operation_id uuid not null
);
create index planner_saved_views_owner_active_idx
  on public.planner_saved_views(owner_id, updated_at desc) where deleted_at is null;
alter table public.planner_saved_views enable row level security;
create policy "private owner reads own saved views" on public.planner_saved_views
  for select to authenticated using (owner_id = auth.uid());
revoke all on public.planner_saved_views from public, anon, authenticated;
grant select on public.planner_saved_views to authenticated;

-- Receipt keys are independent of task UUID receipts: task IDs and text
-- view IDs never alias or collide. The RPC alone may mutate these rows.
create table public.planner_saved_view_operations (
  owner_id uuid not null references public.planner_owner_profiles(owner_id) on delete cascade,
  mutation_id uuid not null,
  device_id uuid not null,
  view_id text not null,
  base_revision bigint not null check (base_revision >= 0),
  operation_type text not null check (operation_type in ('upsert','soft_delete')),
  field_paths text[] not null,
  definition jsonb not null check (jsonb_typeof(definition) = 'object'),
  result jsonb not null check (jsonb_typeof(result) = 'object'),
  applied_at timestamptz not null default now(),
  primary key(owner_id, mutation_id)
);
create index planner_saved_view_operations_owner_view_idx
  on public.planner_saved_view_operations(owner_id, view_id, applied_at desc);
alter table public.planner_saved_view_operations enable row level security;
create policy "private owner reads own saved view receipts"
  on public.planner_saved_view_operations for select to authenticated
  using (owner_id = auth.uid());
revoke all on public.planner_saved_view_operations from public, anon, authenticated;
grant select on public.planner_saved_view_operations to authenticated;

-- Dedicated cursor/read RPC. It leaves task pull behavior unchanged while
-- keeping saved-view identity typed as text instead of forcing a fake UUID.
create or replace function public.pull_planner_saved_view_changes(
  p_after_change_id bigint default 0,
  p_limit integer default 200
) returns table (
  change_id bigint,
  view_id text,
  revision bigint,
  operation_id uuid,
  operation_type text,
  snapshot jsonb,
  committed_at timestamptz
) language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare v_owner uuid := auth.uid();
begin
  if v_owner is null then raise exception 'Authentication is required.' using errcode = '28000'; end if;
  if not exists (select 1 from public.planner_owner_profiles where owner_id = v_owner) then
    raise exception 'Private owner is not enrolled.' using errcode = '42501';
  end if;
  return query
  select c.change_id, c.snapshot->>'id', c.revision, c.operation_id,
         c.operation_type, c.snapshot, c.committed_at
    from public.planner_changes c
   where c.owner_id = v_owner and c.entity_kind = 'saved_view'
     and c.change_id > greatest(coalesce(p_after_change_id,0),0)
   order by c.change_id asc limit least(greatest(coalesce(p_limit,200),1),500);
end;
$$;
revoke all on function public.pull_planner_saved_view_changes(bigint,integer) from public, anon;
grant execute on function public.pull_planner_saved_view_changes(bigint,integer) to authenticated;

-- A saved-view change uses NULL in UUID entity_id; identity lives in typed
-- JSON. Old clients can still advance generic cursor without projecting
-- unknown kind.
alter table public.planner_changes alter column entity_id drop not null;

create function public.apply_saved_view_mutation(
  p_mutation_id uuid,
  p_device_id uuid,
  p_view_id text,
  p_base_revision bigint,
  p_operation_type text,
  p_field_paths text[],
  p_definition jsonb
) returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_owner uuid := auth.uid();
  v_row public.planner_saved_views%rowtype;
  v_receipt public.planner_saved_view_operations%rowtype;
  v_paths text[];
  v_revision bigint;
  v_definition jsonb;
  v_deleted_at timestamptz;
  v_snapshot jsonb;
  v_result jsonb;
begin
  if v_owner is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;
  if not exists (select 1 from public.planner_owner_profiles where owner_id = v_owner) then
    raise exception 'Private owner is not enrolled.' using errcode = '42501';
  end if;
  if p_mutation_id is null or p_device_id is null or p_base_revision is null
     or p_base_revision < 0 or p_view_id is null
     or p_view_id !~ '^view-[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
     or p_operation_type is null or p_operation_type not in ('upsert','soft_delete')
     or p_definition is null or jsonb_typeof(p_definition) <> 'object'
     or p_definition->>'id' is distinct from p_view_id
     or p_definition->>'owner_id' is distinct from v_owner::text
     or p_definition->>'title' is null
     or length(trim(p_definition->>'title')) not between 1 and 80
  then
    raise exception 'Invalid personal saved-view mutation.' using errcode = '22023';
  end if;
  -- Every current client writes one immutable whole-definition snapshot.
  -- Reject unknown patch paths rather than promising nonexistent field merges.
  if p_field_paths is distinct from array['/']::text[] then
    raise exception 'Saved-view writes require a whole-definition path.'
      using errcode = '22023';
  end if;
  v_paths := array['/']::text[];

  -- Serialize both idempotent retries and competing devices for same view.
  perform pg_advisory_xact_lock(hashtextextended(
    'saved-view-mutation:'||v_owner::text||':'||p_mutation_id::text, 0));
  select * into v_receipt from public.planner_saved_view_operations
    where owner_id = v_owner and mutation_id = p_mutation_id;
  if found then
    if v_receipt.device_id is distinct from p_device_id
       or v_receipt.view_id is distinct from p_view_id
       or v_receipt.base_revision is distinct from p_base_revision
       or v_receipt.operation_type is distinct from p_operation_type
       or v_receipt.field_paths is distinct from v_paths
       or v_receipt.definition is distinct from p_definition then
      raise exception 'Mutation ID reused for another saved-view request.'
        using errcode = '22023';
    end if;
    return v_receipt.result;
  end if;
  perform pg_advisory_xact_lock(hashtextextended(
    'saved-view:'||v_owner::text||':'||p_view_id, 0));
  select * into v_row from public.planner_saved_views
    where owner_id = v_owner and id = p_view_id for update;

  if (v_row.id is null and p_base_revision <> 0)
      or (v_row.id is not null and p_base_revision <> v_row.revision) then
    -- No write is lost. Local outbox/conflict center retains pending definition
    -- and server returns authoritative snapshot for explicit recovery.
    v_snapshot := case when v_row.id is null then null else jsonb_build_object(
      'id',v_row.id,'owner_id',v_row.owner_id,'kind','saved_view',
      'payload',v_row.definition,'revision',v_row.revision,
      'created_at',v_row.created_at,'updated_at',v_row.updated_at,
      'deleted_at',v_row.deleted_at) end;
    v_result := jsonb_build_object(
      'status','conflict','entity',v_snapshot,
      'current_revision',coalesce(v_row.revision,0),
      'conflicting_paths',v_paths,'conflict_id',gen_random_uuid());
    insert into public.planner_saved_view_operations
      (owner_id,mutation_id,device_id,view_id,base_revision,
       operation_type,field_paths,definition,result)
    values (v_owner,p_mutation_id,p_device_id,p_view_id,p_base_revision,
            p_operation_type,v_paths,p_definition,v_result);
    return v_result;
  end if;

  v_revision := coalesce(v_row.revision,0)+1;
  -- Deep merge retains fields introduced by a newer client, including query
  -- extensions, while revision checking prevents stale whole-record writes.
  v_definition := public.perfect_jsonb_deep_merge(
    coalesce(v_row.definition,'{}'::jsonb),p_definition);
  v_deleted_at := case when p_operation_type = 'soft_delete' then now()
    else v_row.deleted_at end;
  if v_row.id is null then
    insert into public.planner_saved_views
      (id,owner_id,definition,revision,deleted_at,last_operation_id)
    values (p_view_id,v_owner,v_definition,v_revision,v_deleted_at,p_mutation_id);
  else
    update public.planner_saved_views set
      definition=v_definition,revision=v_revision,updated_at=now(),
      deleted_at=v_deleted_at,last_operation_id=p_mutation_id
    where owner_id=v_owner and id=p_view_id;
  end if;
  select * into v_row from public.planner_saved_views
    where owner_id=v_owner and id=p_view_id;
  v_snapshot := jsonb_build_object(
    'id',v_row.id,'owner_id',v_row.owner_id,'kind','saved_view',
    'payload',v_row.definition,'revision',v_row.revision,
    'created_at',v_row.created_at,'updated_at',v_row.updated_at,
    'deleted_at',v_row.deleted_at);
  v_result := jsonb_build_object('status','acknowledged','entity',v_snapshot);
  insert into public.planner_saved_view_operations
    (owner_id,mutation_id,device_id,view_id,base_revision,
     operation_type,field_paths,definition,result)
  values (v_owner,p_mutation_id,p_device_id,p_view_id,p_base_revision,
          p_operation_type,v_paths,p_definition,v_result);
  insert into public.planner_changes
    (owner_id,entity_id,entity_kind,revision,operation_id,
     operation_type,snapshot)
  values (v_owner,null,'saved_view',v_revision,p_mutation_id,
          p_operation_type,v_snapshot);
  return v_result;
end;
$$;
revoke all on function public.apply_saved_view_mutation(uuid,uuid,text,bigint,text,text[],jsonb)
  from public, anon;
grant execute on function public.apply_saved_view_mutation(uuid,uuid,text,bigint,text,text[],jsonb)
  to authenticated;
