-- Perfect AI needs a compact view of the owner's active plan, but the client
-- role deliberately has no direct SELECT grant on planner_entities. Keep this
-- read boundary narrow, owner-scoped, ordered and size-bounded instead of
-- widening the table grant.

create or replace function public.get_private_ai_planner_context(
  p_limit integer default 80
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
    select 1
    from public.planner_owner_profiles
    where owner_id = v_owner_id
  ) then
    raise exception 'This account is not enabled as the private Perfect owner.'
      using errcode = '42501';
  end if;

  v_limit := least(greatest(coalesce(p_limit, 80), 1), 120);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', item.id,
        'kind', item.kind,
        'title', left(item.title, 160),
        'lifecycle_state', item.lifecycle_state,
        'payload', jsonb_strip_nulls(
          jsonb_build_object(
            'note', left(item.payload ->> 'note', 2000),
            'status', item.payload -> 'status',
            'priority', item.payload -> 'priority',
            'category', item.payload -> 'category',
            'estimate_minutes', item.payload -> 'estimate_minutes',
            'energy', item.payload -> 'energy',
            'task_progress_state', item.payload -> 'task_progress_state',
            'task_progress_percent', item.payload -> 'task_progress_percent',
            'timing', case
              when octet_length(coalesce((item.payload -> 'timing')::text, '')) <= 4096
                then item.payload -> 'timing'
              else null
            end,
            'recurrence', case
              when octet_length(coalesce((item.payload -> 'recurrence')::text, '')) <= 4096
                then item.payload -> 'recurrence'
              else null
            end,
            'tracking', case
              when octet_length(coalesce((item.payload -> 'tracking')::text, '')) <= 4096
                then item.payload -> 'tracking'
              else null
            end,
            'recovery', case
              when octet_length(coalesce((item.payload -> 'recovery')::text, '')) <= 4096
                then item.payload -> 'recovery'
              else null
            end,
            'labels', case
              when octet_length(coalesce((item.payload -> 'labels')::text, '')) <= 4096
                then item.payload -> 'labels'
              else null
            end,
            'reminders', case
              when octet_length(coalesce((item.payload -> 'reminders')::text, '')) <= 4096
                then item.payload -> 'reminders'
              else null
            end,
            'checklist', case
              when octet_length(coalesce((item.payload -> 'checklist')::text, '')) <= 4096
                then item.payload -> 'checklist'
              else null
            end,
            'focus', case
              when octet_length(coalesce((item.payload -> 'focus')::text, '')) <= 4096
                then item.payload -> 'focus'
              else null
            end
          )
        ),
        'updated_at', item.updated_at
      )
      order by item.updated_at desc, item.id desc
    ),
    '[]'::jsonb
  )
  into v_items
  from (
    select
      entity.id,
      entity.kind,
      entity.title,
      entity.lifecycle_state,
      entity.payload,
      entity.updated_at
    from public.planner_entities as entity
    where entity.owner_id = v_owner_id
      and entity.deleted_at is null
      and entity.lifecycle_state = 'active'
    order by entity.updated_at desc, entity.id desc
    limit v_limit
  ) as item;

  return jsonb_build_object(
    'items', v_items,
    'limit', v_limit,
    'truncated', jsonb_array_length(v_items) = v_limit
  );
end;
$$;

revoke all on function public.get_private_ai_planner_context(integer)
  from public, anon, authenticated;
grant execute on function public.get_private_ai_planner_context(integer)
  to authenticated;
