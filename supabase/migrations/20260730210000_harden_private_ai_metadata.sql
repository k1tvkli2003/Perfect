-- Harden the already-deployed private AI metadata guard without rewriting
-- earlier migrations. The depth cap prevents deliberately pathological JSON
-- from driving unbounded recursive checks, while the expanded key vocabulary
-- blocks common credential aliases that must never enter synced history.

create or replace function public.perfect_ai_metadata_is_safe_at_depth(
  p_value jsonb,
  p_depth integer
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
  if p_depth < 0 or p_depth > 32 then
    return false;
  end if;

  if jsonb_typeof(p_value) = 'object' then
    for v_key, v_child in
      select entry.key, entry.value
      from jsonb_each(p_value) as entry
    loop
      if lower(v_key) ~
        '(^|[_-])(authorization|api[_-]?(keys?|secrets?)|access[_-]?tokens?|refresh[_-]?tokens?|bearer[_-]?tokens?|auth[_-]?tokens?|id[_-]?tokens?|session[_-]?tokens?|secrets?|secret[_-]?keys?|passwords?|password[_-]?(hash|digest)|password(hash|digest)|passwds?|credentials?|private[_-]?keys?|client[_-]?secrets?|cookies?|set[_-]?cookie|headers?|request[_-]?headers?|response[_-]?headers?|http[_-]?headers?|raw[_-]?(requests?|responses?)|raw[_-]?provider[_-]?(requests?|responses?)|provider[_-]?(requests?|responses?))($|[_-])'
      then
        return false;
      end if;
      if not public.perfect_ai_metadata_is_safe_at_depth(
        v_child,
        p_depth + 1
      ) then
        return false;
      end if;
    end loop;
  elsif jsonb_typeof(p_value) = 'array' then
    for v_child in
      select element.value
      from jsonb_array_elements(p_value) as element
    loop
      if not public.perfect_ai_metadata_is_safe_at_depth(
        v_child,
        p_depth + 1
      ) then
        return false;
      end if;
    end loop;
  end if;

  return true;
end;
$$;

create or replace function public.perfect_ai_metadata_is_safe(
  p_value jsonb
)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$
  select public.perfect_ai_metadata_is_safe_at_depth(p_value, 0);
$$;

revoke all on function public.perfect_ai_metadata_is_safe_at_depth(
  jsonb,
  integer
) from public, anon, authenticated;
revoke all on function public.perfect_ai_metadata_is_safe(jsonb)
  from public, anon, authenticated;

comment on function public.perfect_ai_metadata_is_safe(jsonb) is
  'Rejects bounded AI metadata trees containing credential, header, cookie, or raw provider fields.';
