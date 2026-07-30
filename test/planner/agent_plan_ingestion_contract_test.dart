import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/planner/domain/planner_entity.dart';

void main() {
  late String migration;
  late String plannerV2;
  late Map<String, dynamic> schema;
  late Map<String, dynamic> example;

  setUpAll(() async {
    migration = await File(
      'supabase/migrations/20260730190000_add_agent_plan_ingestion.sql',
    ).readAsString();
    plannerV2 = await File(
      'supabase/migrations/20260730053626_add_private_planner_v2.sql',
    ).readAsString();
    schema =
        jsonDecode(
              await File(
                'supabase/contracts/agent-plan-v1.schema.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    example =
        jsonDecode(
              await File(
                'supabase/contracts/examples/agent-plan-v1.example.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
  });

  test('migration is append-only and adds a private receipt boundary', () {
    expect(
      migration,
      contains('create table if not exists public.planner_agent_submissions'),
    );
    expect(
      migration,
      contains(
        'alter table public.planner_agent_submissions enable row level security',
      ),
    );
    expect(
      migration,
      contains(
        'revoke all on table public.planner_agent_submissions\n'
        '  from public, anon, authenticated',
      ),
    );
    expect(migration, isNot(contains('drop table')));
    expect(migration, isNot(contains('truncate')));
    expect(migration, isNot(contains('delete from')));
    expect(migration, isNot(contains('alter table public.planner_entities')));
  });

  test('RPC requires the authenticated private owner, not an admin secret', () {
    expect(migration, contains("auth.role() is distinct from 'authenticated'"));
    expect(migration, contains('v_owner_id uuid := auth.uid()'));
    expect(
      migration,
      contains(
        'from public.planner_owner_profiles\n'
        '    where owner_id = v_owner_id',
      ),
    );
    expect(
      migration,
      contains(
        'revoke all on function public.submit_agent_plan(jsonb)\n'
        '  from public, anon, authenticated',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.submit_agent_plan(jsonb) '
        'to authenticated',
      ),
    );
    expect(migration, isNot(contains('p_owner_id')));
  });

  test('batch is bounded, versioned and strict before any writes', () {
    expect(migration, contains('schema_version must be the integer 1'));
    expect(migration, contains('octet_length(p_document::text) > 524288'));
    expect(migration, contains('v_item_count not between 1 and 100'));
    expect(migration, contains('octet_length(v_item::text) > 32768'));
    expect(migration, contains('octet_length(v_payload::text) > 24576'));
    expect(migration, contains('payload has too many top-level fields'));
    expect(
      migration,
      contains('Agent plan document has an unsupported top-level field'),
    );
    expect(migration, contains('payload.agent_proposal is server-managed'));
  });

  test('submission replay is atomic, idempotent and create-only', () {
    expect(migration, contains("'perfect:agent-plan:'"));
    expect(migration, contains("digest(p_document::text, 'sha256')"));
    expect(
      migration,
      contains('submission_id cannot be reused for a different document'),
    );
    expect(migration, contains("'replayed', true"));
    expect(migration, contains('agent submissions are create-only'));
    expect(migration, contains('public.apply_planner_mutation('));
    expect(
      migration,
      contains(
        "if v_mutation_result ->> 'status' is distinct from 'acknowledged'",
      ),
    );
  });

  test(
    'accepted items use current sync changes and remain owner-reviewable',
    () {
      expect(migration, contains("'review_status', 'proposed'"));
      expect(migration, contains("'requires_owner_review', true"));
      expect(migration, contains("'reviewed_at', null"));
      expect(migration, contains("'lifecycle_state', 'active'"));
      expect(migration, contains("'Agent proposal'"));
      expect(plannerV2, contains('insert into public.planner_changes'));
      expect(plannerV2, contains('p_operation_type, v_result -> \'entity\''));
    },
  );

  test(
    'current app model preserves proposal and visible category metadata',
    () {
      final entity = PlannerEntity.fromJson(<String, dynamic>{
        'id': '0bfefaae-f52c-43dc-a48e-28cffcdaef17',
        'owner_id': 'e97d93d8-b86a-49d6-94fb-9c92fba450ff',
        'kind': 'one_off_task',
        'payload': <String, dynamic>{
          'title': 'Review the agent plan',
          'status': 'active',
          'category': 'Agent proposal',
          'agent_proposal': <String, dynamic>{
            'review': <String, dynamic>{
              'status': 'proposed',
              'requires_owner_review': true,
            },
          },
        },
        'created_at': '2026-07-30T15:30:00Z',
        'updated_at': '2026-07-30T15:30:00Z',
        'revision': 1,
      });

      expect(entity.title, 'Review the agent plan');
      expect(entity.status, PlannerEntityStatus.active);
      expect(entity.payload['category'], 'Agent proposal');
      expect(
        ((entity.payload['agent_proposal'] as Map)['review'] as Map)['status'],
        'proposed',
      );
    },
  );

  test('JSON schema and example mirror the database contract', () {
    expect(schema[r'$schema'], contains('2020-12'));
    expect(schema['additionalProperties'], isFalse);
    final properties = schema['properties'] as Map<String, dynamic>;
    expect((properties['schema_version'] as Map)['const'], 1);
    final itemContract =
        ((properties['items'] as Map)['items'] as Map<String, dynamic>);
    final itemProperties = itemContract['properties'] as Map<String, dynamic>;
    expect(
      ((itemProperties['kind'] as Map)['enum'] as List),
      containsAll(<String>[
        'one_off_task',
        'recurring_task',
        'habit',
        'project',
      ]),
    );
    expect(
      ((itemProperties['payload'] as Map)['not'] as Map)['required'],
      contains('agent_proposal'),
    );

    expect(example['schema_version'], 1);
    expect((example['items'] as List), hasLength(3));
    expect(
      (example['items'] as List).cast<Map<String, dynamic>>().map(
        (item) => item['kind'],
      ),
      containsAll(<String>['project', 'one_off_task', 'habit']),
    );
  });
}
