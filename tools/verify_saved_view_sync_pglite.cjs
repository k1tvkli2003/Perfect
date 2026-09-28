const fs = require('node:fs');
const path = require('node:path');
const { PGlite } = require('@electric-sql/pglite');

const MIGRATIONS = [
  'supabase/migrations/20260730053626_add_private_planner_v2.sql',
  'supabase/migrations/20260730230000_add_planner_saved_view_sync.sql',
];

async function main() {
  const db = new PGlite();
  await db.exec(
    "create role authenticated; create role anon; create schema auth; " +
      "create function auth.uid() returns uuid language sql as " +
      "'select nullif(current_setting(''app.test_uid'', true), '''')::uuid'; " +
      'create table auth.users(id uuid primary key);',
  );
  for (const file of MIGRATIONS) {
    let sql = fs.readFileSync(path.join(process.cwd(), file), 'utf8');
    sql = sql.replaceAll('create extension if not exists pgcrypto;', '');
    sql = sql.replaceAll('gen_random_uuid()', "'22222222-2222-4222-8222-222222222222'");
    await db.exec(sql);
  }
  const owner = '00000000-0000-4000-8000-000000000000';
  await db.exec(`insert into auth.users(id) values ('${owner}')`);
  await db.exec(`insert into public.planner_owner_profiles(owner_id) values ('${owner}')`);
  await db.exec(`select set_config('app.test_uid', '${owner}', false)`);
  const view = 'view-10000000-0000-4000-8000-000000000000';
  const mutation = '10000000-0000-4000-8000-000000000000';
  const device = '20000000-0000-4000-8000-000000000000';
  const definition =
    `jsonb_build_object('id','${view}','owner_id','${owner}','title','Gate check',` +
    `'query',jsonb_build_object('include_archived',false),` +
    `'created_at','2026-09-28T00:00:00Z','updated_at','2026-09-28T00:00:00Z')`;
  const apply = await db.query(
    `select public.apply_saved_view_mutation('${mutation}','${device}','${view}',0,'upsert',array['/']::text[],${definition}) as result`,
  );
  const applied = apply.rows[0].result;
  if (applied.status !== 'acknowledged') {
    throw new Error(`Saved-view apply was not acknowledged: ${JSON.stringify(applied)}`);
  }
  console.log(`CHECK upsert: status=${applied.status} revision=${applied.entity.revision}`);
  const repeat = await db.query(
    `select public.apply_saved_view_mutation('${mutation}','${device}','${view}',0,'upsert',array['/']::text[],${definition}) as result`,
  );
  if (repeat.rows[0].result.entity.revision !== applied.entity.revision) {
    throw new Error('Saved-view mutation idempotency lost its revision.');
  }
  console.log(`CHECK idempotent: revision=${repeat.rows[0].result.entity.revision}`);
  const stale = await db.query(
    `select public.apply_saved_view_mutation('30000000-0000-4000-8000-000000000000','${device}','${view}',0,'upsert',array['/']::text[],${definition}) as result`,
  );
  if (stale.rows[0].result.status !== 'conflict') {
    throw new Error('Saved-view stale base revision did not conflict.');
  }
  console.log(`CHECK stale: status=${stale.rows[0].result.status}`);
  const pulled = await db.query(
    'select * from public.pull_planner_saved_view_changes(0, 200)',
  );
  if (pulled.rows.length !== 1 || pulled.rows[0].view_id !== view) {
    throw new Error(`Saved-view pull did not return the typed snapshot: ${JSON.stringify(pulled.rows)}`);
  }
  console.log(`CHECK pull: view=${pulled.rows[0].view_id} revision=${pulled.rows[0].revision}`);
  const checks = [
    ['saved_views', "select to_regclass('public.planner_saved_views')"],
    ['receipts', "select to_regclass('public.planner_saved_view_operations')"],
    ['apply', "select to_regprocedure('public.apply_saved_view_mutation(uuid,uuid,text,bigint,text,text[],jsonb)')"],
    ['pull', "select to_regprocedure('public.pull_planner_saved_view_changes(bigint,integer)')"],
  ];
  for (const [name, sql] of checks) {
    const rows = await db.query(sql);
    const value = Object.values(rows.rows[0])[0];
    if (value === null || value === 0 || value === '0') {
      throw new Error(`Missing saved-view SQL surface: ${name}`);
    }
    console.log(`CHECK ${name}: ${value}`);
  }
  console.log('PGLITE_MIGRATION_APPLY=PASS');
}

main().catch((error) => {
  console.error(String(error && error.stack || error));
  process.exit(1);
});
