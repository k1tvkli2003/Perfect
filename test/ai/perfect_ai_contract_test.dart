import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/ai/perfect_ai_contract.dart';

void main() {
  test('chat contract serializes only the bounded v1 application payload', () {
    final request = PerfectAiRequest(
      operationId: '11111111-1111-4111-8111-111111111111',
      conversationId: '22222222-2222-4222-8222-222222222222',
      message: 'برنامه امروز من را مرتب کن',
      conversation: <PerfectAiMessage>[
        PerfectAiMessage(
          id: '33333333-3333-4333-8333-333333333333',
          role: PerfectAiRole.assistant,
          text: 'حتماً',
          createdAt: DateTime.utc(2026, 7, 30),
        ),
      ],
      audio: PerfectVoiceClip(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'audio/wav',
        duration: const Duration(seconds: 2),
      ),
    );

    expect(request.toJson(), <String, dynamic>{
      'schema_version': 1,
      'action': 'chat',
      'operation_id': '11111111-1111-4111-8111-111111111111',
      'conversation_id': '22222222-2222-4222-8222-222222222222',
      'message': 'برنامه امروز من را مرتب کن',
      'conversation': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '33333333-3333-4333-8333-333333333333',
          'role': 'assistant',
          'text': 'حتماً',
          'created_at': '2026-07-30T00:00:00.000Z',
        },
      ],
      'audio': <String, dynamic>{
        'mime_type': 'audio/wav',
        'base64': 'AQID',
        'duration_ms': 2000,
      },
    });
    expect(request.toJson(), isNot(contains('planner_context')));
    expect(request.toJson(), isNot(contains('api_key')));
  });

  test('turn parser accepts a guarded proposal and typed telemetry', () {
    final result = PerfectAiTurnResult.fromJson(<String, dynamic>{
      'schema_version': 1,
      'operation_id': '11111111-1111-4111-8111-111111111111',
      'conversation_id': '22222222-2222-4222-8222-222222222222',
      'message': <String, dynamic>{
        'id': '33333333-3333-4333-8333-333333333333',
        'role': 'assistant',
        'text': 'A plan is ready.',
        'created_at': '2026-07-30T10:00:00Z',
      },
      'proposal': <String, dynamic>{
        'submission_id': '44444444-4444-4444-8444-444444444444',
        'title': 'Morning reset',
        'summary': 'A calm start.',
        'requires_confirmation': true,
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '55555555-5555-4555-8555-555555555555',
            'kind': 'habit',
            'title': 'Drink water',
            'payload': <String, dynamic>{'category': 'health'},
          },
        ],
      },
      'telemetry': <String, dynamic>{
        'request_id': 'provider-request',
        'model': 'gemini-flash-lite-latest',
        'prompt_version': 'perfect-agent-v1',
        'schema_version': 'agent-plan-v1',
        'latency_ms': 842,
      },
    });

    expect(result.proposal?.requiresConfirmation, isTrue);
    expect(result.proposal?.items.single.title, 'Drink water');
    expect(result.telemetry?.model, 'gemini-flash-lite-latest');
  });

  test('apply parser accepts the database receipt item_count', () {
    final result = PerfectAiApplyResult.fromJson(<String, dynamic>{
      'schema_version': 1,
      'operation_id': '11111111-1111-4111-8111-111111111111',
      'conversation_id': '22222222-2222-4222-8222-222222222222',
      'message': <String, dynamic>{
        'id': '33333333-3333-4333-8333-333333333333',
        'role': 'assistant',
        'text': 'Applied.',
        'created_at': '2026-07-30T10:00:00Z',
      },
      'apply_result': <String, dynamic>{'status': 'accepted', 'item_count': 3},
    });

    expect(result.appliedCount, 3);
    expect(result.message?.text, 'Applied.');
  });

  test('malformed or unversioned responses fail closed', () {
    expect(
      () =>
          PerfectAiTurnResult.fromJson(<String, dynamic>{'schema_version': 2}),
      throwsFormatException,
    );
    expect(
      () => PerfectAiProposal.fromJson(<String, dynamic>{
        'submission_id': 'submission',
        'title': 'Unsafe',
        'summary': '',
        'requires_confirmation': true,
        'items': const <Object>[],
      }),
      throwsFormatException,
    );
  });
}
