import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/ai/perfect_local_runtime.dart';

class _Response implements PerfectLocalHttpResponse {
  _Response(this.statusCode, this.body);
  @override
  final int statusCode;
  @override
  final String body;
}

void main() {
  test('local chat request pins the fixed model and disables tools', () {
    final request = PerfectLocalChatRequest(
      operationId: '11111111-1111-4111-8111-111111111111',
      message: 'Hello',
      history: const <PerfectLocalChatTurn>[
        PerfectLocalChatTurn(role: 'user', text: 'Hi'),
      ],
      idempotencyKey: 'op-1',
      systemPrompt: 'You are Perfect AI.',
    );

    final wire = request.toServeJson();
    final model = wire['model'] as Map<String, Object?>;
    expect(model['providerID'], perfectLocalProviderId);
    expect(model['modelID'], perfectLocalModelId);
    expect(wire['tools'], <String, Object?>{});
    expect(wire['agent'], 'build');
    expect(wire, isNot(contains('api_key')));
  });

  test('oversize local requests fail closed before any spend', () {
    expect(
      () => PerfectLocalChatRequest(
        operationId: 'op',
        message: 'x' * 4001,
        history: const <PerfectLocalChatTurn>[],
        idempotencyKey: 'op-1',
      ).toServeJson(),
      throwsA(
        isA<PerfectLocalRuntimeFailure>().having(
          (error) => error.code,
          'code',
          'AI_VISION_REQUEST_INVALID',
        ),
      ),
    );
  });

  test('local result rejects wrong model echo', () {
    expect(
      () => PerfectLocalChatResult.fromServeJson(<String, Object?>{
        'id': 'msg_1',
        'sessionID': 'ses_1',
        'info': <String, Object?>{
          'providerID': 'opencode',
          'modelID': 'other-model',
        },
        'parts': <Object?>[],
      }),
      throwsA(
        isA<PerfectLocalRuntimeFailure>().having(
          (error) => error.code,
          'code',
          'AI_ROUTE_NOT_ALLOWED',
        ),
      ),
    );
  });

  test('local result surfaces provider APIError as failure, not text', () {
    expect(
      () => PerfectLocalChatResult.fromServeJson(<String, Object?>{
        'id': 'msg_1',
        'sessionID': 'ses_1',
        'info': <String, Object?>{
          'providerID': perfectLocalProviderId,
          'modelID': perfectLocalModelId,
          'error': <String, Object?>{'name': 'APIError'},
        },
        'parts': <Object?>[],
      }),
      throwsA(
        isA<PerfectLocalRuntimeFailure>().having(
          (error) => error.code,
          'code',
          'AI_PROVIDER_FAILURE',
        ),
      ),
    );
  });

  test('local client validates session shape', () async {
    final client = PerfectLocalRuntimeClient(
      baseUri: Uri.parse('http://127.0.0.1:4097'),
      post: (_, _, _) async => _Response(200, '{"id":"ses_abc"}'),
    );
    expect(await client.createSession(title: 'perfect-ai'), 'ses_abc');
  });

  test('local client rejects malformed session id', () async {
    final client = PerfectLocalRuntimeClient(
      baseUri: Uri.parse('http://127.0.0.1:4097'),
      post: (_, _, _) async => _Response(200, '{"id":"bad"}'),
    );
    expect(
      () => client.createSession(title: 'perfect-ai'),
      throwsA(isA<PerfectLocalRuntimeFailure>()),
    );
  });
}
