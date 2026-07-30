-- Run through `supabase db push` after linking your private project, or paste
-- into the Supabase SQL editor. Every row belongs to exactly one Auth user.
create table if not exists public.perfect_items (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 160),
  is_done boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  constraint perfect_items_timestamp_order
    check (updated_at >= created_at)
);

create index if not exists perfect_items_owner_updated_idx
  on public.perfect_items (owner_id, updated_at desc);

alter table public.perfect_items enable row level security;

do $$
begin
  create policy "owners read their Perfect items"
    on public.perfect_items for select to authenticated
    using (owner_id = auth.uid());
exception when duplicate_object then null;
end;
$$;

do $$
begin
  create policy "owners create their Perfect items"
    on public.perfect_items for insert to authenticated
    with check (owner_id = auth.uid());
exception when duplicate_object then null;
end;
$$;

do $$
begin
  create policy "owners update their Perfect items"
    on public.perfect_items for update to authenticated
    using (owner_id = auth.uid())
    with check (owner_id = auth.uid());
exception when duplicate_object then null;
end;
$$;

do $$
begin
  create policy "owners delete their Perfect items"
    on public.perfect_items for delete to authenticated
    using (owner_id = auth.uid());
exception when duplicate_object then null;
end;
$$;

grant select, insert, update, delete on public.perfect_items to authenticated;

-- Required for the lightweight Postgres Changes subscription used by the app.
do $$
begin
  alter publication supabase_realtime add table public.perfect_items;
exception
  when duplicate_object then null;
  when undefined_object then null;
end;
$$;
