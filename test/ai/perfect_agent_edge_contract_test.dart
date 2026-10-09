import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'supabase/functions/perfect-agent/index.ts',
  ).readAsStringSync();
  final plannerMigration = File(
    'supabase/migrations/20260730053626_add_private_planner_v2.sql',
  ).readAsStringSync();
  final contextMigration = File(
    'supabase/migrations/20260730220000_add_private_ai_planner_context_rpc.sql',
  ).readAsStringSync();

  group('Perfect agent Edge Function contract', () {
    test('keeps the edge function sync-only; chat runs on the local runtime', () {
      // Local-first rule: the Flutter caller owns the localhost model hop
      // (pinned opencode/muse-spark-1.3-contributor-free). The edge function
      // must never become the model caller again, so no chat provider key,
      // chat model, or chat-completions URL may reappear here.
      expect(source, isNot(contains('Deno.env.get("AVALAI_API_KEY")')));
      expect(source, isNot(contains('gemini-flash-lite-latest')));
      expect(source, isNot(contains('/chat/completions')));
      expect(source, contains('action !== "apply_proposal"'));
      expect(source, contains('Deno.env.get(name)?.trim()'));
      expect(source, isNot(contains('String.fromEnvironment')));
      expect(source, isNot(contains('GEMINI_API_KEY')));
    });

    test('applies proposals through private owner-scoped RPCs', () {
      expect(source, contains('/auth/v1/user'));
      expect(source, contains(r'/rest/v1/rpc/${rpc}'));
      expect(source, contains('/rest/v1/rpc/submit_agent_plan'));
      expect(source, contains('requirePersistedProposal'));
      expect(source, isNot(contains('/rest/v1/planner_entities?')));
      expect(source, contains('authorization'));
      expect(source, contains('apikey'));
      expect(source, isNot(contains('service_role')));
      expect(source, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));

      // This cross-file assertion catches the original production failure:
      // the table grant is intentionally absent, so a direct PostgREST read
      // can never be reintroduced as a seemingly valid implementation.
      expect(
        plannerMigration,
        contains(
          'revoke all on table public.planner_entities from anon, authenticated;',
        ),
      );
      expect(
        plannerMigration,
        isNot(
          contains(
            'grant select on table public.planner_entities to authenticated',
          ),
        ),
      );
      expect(contextMigration, contains('security definer'));
      expect(
        contextMigration,
        contains("auth.role() is distinct from 'authenticated'"),
      );
      expect(contextMigration, contains('where entity.owner_id = v_owner_id'));
      expect(
        contextMigration,
        contains('order by entity.updated_at desc, entity.id desc'),
      );
      expect(
        contextMigration,
        contains('v_limit := least(greatest(coalesce(p_limit, 80), 1), 120);'),
      );
      expect(
        contextMigration,
        contains(
          'grant execute on function public.get_private_ai_planner_context(integer)',
        ),
      );
      expect(
        contextMigration,
        isNot(
          contains(
            'grant select on table public.planner_entities to authenticated',
          ),
        ),
      );
    });

    test('uses bounded apply payloads and timeouts', () {
      expect(source, contains('MAX_REQUEST_BYTES'));
      expect(source, contains('await request.text()'));
      expect(source, contains('new TextEncoder().encode(raw).byteLength'));
      expect(source, contains('readBoundedJsonResponse'));
      expect(source, contains('AbortController'));
    });

    test('requires owner confirmation before a proposal write', () {
      expect(source, contains('requires_confirmation: true'));
      expect(source, contains('action !== "apply_proposal"'));
      expect(source, contains('"confirmation_required"'));
      expect(source, contains('requirePersistedProposal'));
      expect(source, contains('/rest/v1/ai_conversations'));
      expect(source, contains('deleted_at: "is.null"'));
      expect(source, contains('/rest/v1/ai_messages'));
      expect(source, contains('canonicalJson(storedProposal) === expected'));
      expect(source, contains('/rest/v1/rpc/submit_agent_plan'));
      expect(source, contains('record_ai_action_result'));
    });

    test('proposal replay document is deterministic', () {
      final applyStart = source.indexOf('async function applyProposal');
      final persistStart = source.indexOf(
        'async function persistAppliedProposal',
        applyStart,
      );
      final applySource = source.substring(applyStart, persistStart);
      expect(applySource, contains('run_id: proposal.submission_id'));
      expect(applySource, isNot(contains('new Date()')));
      expect(applySource, isNot(contains('generated_at')));
    });

    test('persists the apply receipt without raw provider payloads', () {
      expect(source, contains('upsert_ai_conversation'));
      expect(source, contains('append_ai_message'));
      expect(source, contains('prompt_version'));
      expect(source, isNot(contains('safeProviderMessage')));
      expect(source, isNot(contains('raw_response')));
      expect(source, isNot(contains('raw_request')));
    });

  });
}
