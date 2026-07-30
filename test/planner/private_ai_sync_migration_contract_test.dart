import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String hardeningMigration;
  late Map<String, dynamic> messageSchema;
  late Map<String, dynamic> actionSchema;
  late Map<String, dynamic> messageExample;
  late Map<String, dynamic> actionExample;

  setUpAll(() async {
    migration = await File(
      'supabase/migrations/20260730192000_add_private_ai_conversation_sync.sql',
    ).readAsString();
    hardeningMigration = await File(
      'supabase/migrations/20260730210000_harden_private_ai_metadata.sql',
    ).readAsString();
    messageSchema =
        jsonDecode(
              await File(
                'supabase/contracts/ai-message-v1.schema.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    actionSchema =
        jsonDecode(
              await File(
                'supabase/contracts/ai-action-result-v1.schema.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    messageExample =
        jsonDecode(
              await File(
                'supabase/contracts/examples/ai-message-v1.example.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    actionExample =
        jsonDecode(
              await File(
                'supabase/contracts/examples/ai-action-result-v1.example.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
  });

  test('migration is append-only and follows agent plan ingestion', () async {
    final migrations =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((name) => name.endsWith('.sql'))
            .toList()
          ..sort();
    expect(
      migrations.indexOf('20260730192000_add_private_ai_conversation_sync.sql'),
      greaterThan(
        migrations.indexOf('20260730190000_add_agent_plan_ingestion.sql'),
      ),
    );
    expect(
      migrations.indexOf('20260730210000_harden_private_ai_metadata.sql'),
      greaterThan(
        migrations.indexOf(
          '20260730192000_add_private_ai_conversation_sync.sql',
        ),
      ),
    );
    expect(migration, isNot(contains('drop table')));
    expect(migration, isNot(contains('truncate')));
    expect(migration, isNot(contains('alter table public.planner_entities')));
  });

  test('conversation, message and action audit tables are owner private', () {
    expect(
      migration,
      contains('create table if not exists public.ai_conversations'),
    );
    expect(
      migration,
      contains('create table if not exists public.ai_messages'),
    );
    expect(
      migration,
      contains('create table if not exists public.ai_action_audit'),
    );
    for (final table in <String>[
      'ai_conversations',
      'ai_messages',
      'ai_action_audit',
    ]) {
      expect(
        migration,
        contains('alter table public.$table enable row level security'),
      );
      expect(
        migration,
        contains(
          'revoke all on table public.$table '
          'from public, anon, authenticated',
        ),
      );
      expect(
        migration,
        contains('grant select on table public.$table to authenticated'),
      );
    }
    expect(migration, contains("auth.role() is distinct from 'authenticated'"));
    expect(migration, contains('v_owner_id uuid := auth.uid()'));
    expect(migration, isNot(contains('p_owner_id')));
  });

  test('stored AI fields are bounded and omit raw provider secrets', () {
    expect(migration, contains('char_length(content) <= 32000'));
    expect(migration, contains('octet_length(proposal::text) <= 32768'));
    expect(migration, contains('octet_length(result::text) <= 32768'));
    expect(migration, contains('octet_length(usage::text) <= 4096'));
    expect(migration, contains('model text check'));
    expect(migration, contains('prompt_version text check'));
    expect(migration, contains('request_id uuid'));
    expect(migration, contains('latency_ms integer'));
    expect(migration, contains('public.perfect_ai_metadata_is_safe(proposal)'));
    expect(migration, contains('api[_-]?key'));
    expect(migration, contains('raw[_-]?(request|response)'));
    expect(migration, contains('provider[_-]?(request|response)'));

    final forbiddenColumn = RegExp(
      r'^\s*(api_key|provider_secret|system_prompt|raw_request|raw_response)\s+',
      multiLine: true,
      caseSensitive: false,
    );
    expect(forbiddenColumn.hasMatch(migration), isFalse);
  });

  test('metadata guard rejects credential aliases with bounded recursion', () {
    expect(
      hardeningMigration,
      contains('perfect_ai_metadata_is_safe_at_depth'),
    );
    expect(hardeningMigration, contains('p_depth > 32'));
    for (final credentialKey in <String>[
      'bearer[_-]?tokens?',
      'client[_-]?secrets?',
      'private[_-]?keys?',
      'credentials?',
      'set[_-]?cookie',
      'secret[_-]?keys?',
      'request[_-]?headers?',
      'headers?',
    ]) {
      expect(hardeningMigration, contains(credentialKey));
    }
    expect(
      hardeningMigration,
      contains(
        'revoke all on function '
        'public.perfect_ai_metadata_is_safe_at_depth',
      ),
    );
    // Usage fields such as input_tokens are legitimate aggregate counts; the
    // guard targets credential-qualified token names instead of every "token".
    expect(hardeningMigration, isNot(contains('|tokens?|')));
  });

  test('RPC surface is owner-only, cursor based and mutation minimized', () {
    for (final function in <String>[
      'upsert_ai_conversation',
      'list_ai_conversations',
      'append_ai_message',
      'list_ai_messages',
      'record_ai_action_result',
      'list_ai_action_audit',
      'delete_ai_conversation',
      'purge_expired_ai_conversations',
    ]) {
      expect(
        migration,
        contains('create or replace function public.$function'),
      );
      expect(migration, contains('grant execute on function public.$function'));
    }
    expect(migration, contains('(conversation.updated_at, conversation.id) <'));
    expect(migration, contains('(message.created_at, message.id) >'));
    expect(migration, contains('(audit.created_at, audit.operation_id) >'));
    expect(migration, contains('for update skip locked'));
  });

  test('message and action replays are serialized and exact', () {
    expect(migration, contains("'perfect:ai-message:'"));
    expect(
      migration,
      contains('message_id cannot be reused for different content'),
    );
    expect(migration, contains("'perfect:ai-action:'"));
    expect(migration, contains("'perfect:ai-operation:'"));
    expect(migration, contains('AI action idempotency key cannot be reused'));
    expect(migration, contains("'replayed', true"));
    expect(migration, contains('unique (owner_id, idempotency_key)'));
    expect(
      migration,
      contains(
        'references public.planner_agent_submissions '
        '(owner_id, submission_id)',
      ),
    );
  });

  test('soft delete, explicit purge and realtime recovery are available', () {
    expect(migration, contains("p_mode text default 'soft'"));
    expect(migration, contains("p_mode not in ('soft', 'purge')"));
    expect(migration, contains("v_now + interval '30 days'"));
    expect(
      migration,
      contains('conversation.retention_until <= timezone(\'utc\', now())'),
    );
    for (final table in <String>[
      'ai_conversations',
      'ai_messages',
      'ai_action_audit',
    ]) {
      expect(
        migration,
        contains('alter publication supabase_realtime add table public.$table'),
      );
    }
  });

  test('versioned JSON schemas and examples match the SQL kinds', () {
    expect(messageSchema[r'$schema'], contains('2020-12'));
    expect(actionSchema[r'$schema'], contains('2020-12'));
    expect(messageSchema['additionalProperties'], isFalse);
    expect(actionSchema['additionalProperties'], isFalse);

    final messageProperties =
        messageSchema['properties'] as Map<String, dynamic>;
    expect(
      (messageProperties['role'] as Map)['enum'],
      containsAll(<String>['user', 'assistant', 'tool']),
    );
    expect(
      (messageProperties['status'] as Map)['enum'],
      containsAll(<String>['completed', 'failed', 'cancelled']),
    );
    final actionProperties = actionSchema['properties'] as Map<String, dynamic>;
    expect(
      (actionProperties['status'] as Map)['enum'],
      containsAll(<String>['applied', 'rejected', 'failed']),
    );

    expect(messageExample['schema_version'], 1);
    expect(messageExample['role'], 'assistant');
    expect(messageExample['prompt_version'], isNotEmpty);
    expect(actionExample['schema_version'], 1);
    expect(actionExample['status'], 'applied');
    expect(actionExample['applied_submission_id'], isNotEmpty);
  });
}
