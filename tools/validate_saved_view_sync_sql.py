from pathlib import Path
import re

sql = Path('supabase/migrations/20260730230000_add_planner_saved_view_sync.sql').read_text(encoding='utf-8')
required = [
    'create table public.planner_saved_views',
    'create table public.planner_saved_view_operations',
    'create function public.apply_saved_view_mutation',
    'create or replace function public.pull_planner_saved_view_changes',
    'alter table public.planner_changes alter column entity_id drop not null',
    'p_view_id !~',
    'p_definition->>\'id\' is distinct from p_view_id',
    'p_definition->>\'owner_id\' is distinct from v_owner::text',
    'p_field_paths is distinct from array[\'/\']::text[]',
    'pg_advisory_xact_lock',
    'planner_saved_view_operations',
    "'status','conflict'",
    "'kind','saved_view'",
]
missing = [item for item in required if item not in sql]
assert not missing, f'missing contract clauses: {missing}'
assert 'apply_planner_mutation' not in sql
assert 'planner_operations' not in sql
assert not re.search(r'entity_id\s+uuid\s+not null', sql)
assert sql.count('pg_advisory_xact_lock') >= 2
assert sql.count("'kind','saved_view'") >= 2
print('SAVED_VIEW_SQL_CONTRACT=PASS')
print(f'LINES={len(sql.splitlines())}')
print('GENERIC_TASK_RPC_REFERENCES=0')
