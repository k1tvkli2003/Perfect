import 'package:perfect/ai/perfect_ai_contract.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class PerfectAiClient {
  Future<PerfectAiTurnResult> chat(
    PerfectAiRequest request, {
    PerfectAiCancellation? cancellation,
  });

  Future<PerfectAiApplyResult> applyProposal({
    required String operationId,
    required String? conversationId,
    required PerfectAiProposal proposal,
    PerfectAiCancellation? cancellation,
  });
}

abstract interface class PerfectAiHistoryClient {
  Future<PerfectAiConversationSnapshot?> loadLatestConversation({
    PerfectAiCancellation? cancellation,
  });
}

class SupabasePerfectAiClient
    implements PerfectAiClient, PerfectAiHistoryClient {
  SupabasePerfectAiClient(this._client, {this.functionName = 'perfect-agent'});

  final SupabaseClient _client;
  final String functionName;

  @override
  Future<PerfectAiConversationSnapshot?> loadLatestConversation({
    PerfectAiCancellation? cancellation,
  }) async {
    if (cancellation?.isCancelled == true) throw _cancelled();
    try {
      final conversations = await _rpcObject(
        'list_ai_conversations',
        <String, dynamic>{'p_limit': 100, 'p_include_deleted': false},
        cancellation: cancellation,
      );
      final conversationItems = _rpcItems(
        conversations,
        label: 'AI conversations',
      );
      Map<String, dynamic>? conversation;
      for (final item in conversationItems) {
        if (item['status'] == 'active' && item['deleted_at'] == null) {
          conversation = item;
          break;
        }
      }
      if (conversation == null) return null;
      final conversationId = _historyString(
        conversation,
        'id',
        maximumLength: 160,
      );
      final rawMessages = await _loadRecentMessages(
        conversationId,
        cancellation: cancellation,
      );
      final messages = <PerfectAiMessage>[];
      final seenIds = <String>{};
      for (final item in rawMessages) {
        if (item['status'] != 'completed') continue;
        final role = item['role'];
        if (role != 'user' && role != 'assistant') continue;
        final content = item['content'];
        if (content is! String || content.length > 12000) {
          throw const FormatException('Invalid synced AI message content.');
        }
        // The persistence contract allows a proposal-only assistant message.
        // Keep its proposal eligible for restoration without rendering an
        // empty chat bubble.
        if (content.trim().isEmpty) continue;
        final message = PerfectAiMessage.fromJson(<String, dynamic>{
          'id': item['id'],
          'role': role,
          'text': content,
          'created_at': item['created_at'],
        });
        if (seenIds.add(message.id)) messages.add(message);
      }
      messages.sort(_compareMessages);

      PerfectAiProposal? pendingProposal;
      final candidate = _latestRestorableProposal(rawMessages);
      if (candidate != null) {
        final applied = await _proposalWasApplied(
          conversationId,
          candidate.submissionId,
          cancellation: cancellation,
        );
        if (applied == false) pendingProposal = candidate;
      }

      return PerfectAiConversationSnapshot(
        conversationId: conversationId,
        messages: List<PerfectAiMessage>.unmodifiable(messages),
        pendingProposal: pendingProposal,
      );
    } on PerfectAiException {
      rethrow;
    } on PostgrestException catch (error) {
      throw _mapHistoryError(error);
    } on FormatException catch (error) {
      throw PerfectAiException(
        code: PerfectAiErrorCode.malformedResponse,
        message: error.message,
        retryable: true,
      );
    } on Object {
      throw const PerfectAiException(
        code: PerfectAiErrorCode.unavailable,
        message: 'Perfect AI could not load your synced conversation.',
        retryable: true,
      );
    }
  }

  @override
  Future<PerfectAiTurnResult> chat(
    PerfectAiRequest request, {
    PerfectAiCancellation? cancellation,
  }) async {
    _validateRequest(request);
    final json = await _invoke(request.toJson(), cancellation: cancellation);
    try {
      return PerfectAiTurnResult.fromJson(json);
    } on FormatException catch (error) {
      throw PerfectAiException(
        code: PerfectAiErrorCode.malformedResponse,
        message: error.message,
        retryable: true,
      );
    }
  }

  @override
  Future<PerfectAiApplyResult> applyProposal({
    required String operationId,
    required String? conversationId,
    required PerfectAiProposal proposal,
    PerfectAiCancellation? cancellation,
  }) async {
    if (!proposal.requiresConfirmation) {
      throw const PerfectAiException(
        code: PerfectAiErrorCode.invalidInput,
        message: 'This proposal is missing its confirmation guard.',
        retryable: false,
      );
    }
    final json = await _invoke(<String, dynamic>{
      'schema_version': 1,
      'action': 'apply_proposal',
      'operation_id': operationId,
      'conversation_id': ?conversationId,
      'proposal': proposal.toJson(),
    }, cancellation: cancellation);
    try {
      return PerfectAiApplyResult.fromJson(json);
    } on FormatException catch (error) {
      throw PerfectAiException(
        code: PerfectAiErrorCode.malformedResponse,
        message: error.message,
        retryable: true,
      );
    }
  }

  Future<Map<String, dynamic>> _invoke(
    Map<String, dynamic> body, {
    PerfectAiCancellation? cancellation,
  }) async {
    if (cancellation?.isCancelled == true) throw _cancelled();
    try {
      final response = await _client.functions.invoke(functionName, body: body);
      if (cancellation?.isCancelled == true) throw _cancelled();
      return perfectAiJsonObject(response.data);
    } on FunctionException catch (error) {
      throw _mapFunctionError(error);
    } on PerfectAiException {
      rethrow;
    } on Object {
      throw const PerfectAiException(
        code: PerfectAiErrorCode.unavailable,
        message: 'Perfect AI could not reach its private service.',
        retryable: true,
      );
    }
  }

  Future<Map<String, dynamic>> _rpcObject(
    String function,
    Map<String, dynamic> params, {
    PerfectAiCancellation? cancellation,
  }) async {
    if (cancellation?.isCancelled == true) throw _cancelled();
    final data = await _client.rpc(function, params: params);
    if (cancellation?.isCancelled == true) throw _cancelled();
    return perfectAiJsonObject(data, label: '$function response');
  }

  Future<List<Map<String, dynamic>>> _loadRecentMessages(
    String conversationId, {
    PerfectAiCancellation? cancellation,
  }) async {
    const pageSize = 200;
    const maximumPages = 20;
    final recent = <Map<String, dynamic>>[];
    String? afterCreatedAt;
    String? afterId;
    for (var page = 0; page < maximumPages; page++) {
      final payload = await _rpcObject('list_ai_messages', <String, dynamic>{
        'p_conversation_id': conversationId,
        'p_limit': pageSize,
        'p_after_created_at': ?afterCreatedAt,
        'p_after_id': ?afterId,
      }, cancellation: cancellation);
      final items = _rpcItems(payload, label: 'AI messages');
      recent.addAll(items);
      if (recent.length > pageSize) {
        recent.removeRange(0, recent.length - pageSize);
      }
      if (items.length < pageSize) return recent;

      final last = items.last;
      afterCreatedAt = _historyString(last, 'created_at', maximumLength: 64);
      afterId = _historyString(last, 'id', maximumLength: 160);
    }
    throw const FormatException(
      'Synced AI history exceeds the bounded hydration window.',
    );
  }

  Future<bool?> _proposalWasApplied(
    String conversationId,
    String submissionId, {
    PerfectAiCancellation? cancellation,
  }) async {
    try {
      final payload = await _rpcObject(
        'list_ai_action_audit',
        <String, dynamic>{'p_conversation_id': conversationId, 'p_limit': 200},
        cancellation: cancellation,
      );
      final items = _rpcItems(payload, label: 'AI action audit');
      // A full page is ambiguous without paging backwards, so restoration
      // fails closed instead of presenting a possibly applied proposal.
      if (items.length >= 200) return null;
      for (final item in items) {
        if (item['applied_submission_id'] == submissionId &&
            item['status'] == 'applied') {
          return true;
        }
      }
      return false;
    } on PerfectAiException catch (error) {
      if (error.code == PerfectAiErrorCode.cancelled) rethrow;
      return null;
    } on Object {
      return null;
    }
  }

  void _validateRequest(PerfectAiRequest request) {
    final message = request.message.trim();
    final audio = request.audio;
    if (message.isEmpty && audio == null) {
      throw const PerfectAiException(
        code: PerfectAiErrorCode.invalidInput,
        message: 'Write a message or attach a voice note.',
        retryable: false,
      );
    }
    if (message.length > 4000 ||
        request.conversation.length > 20 ||
        (audio != null &&
            (audio.bytes.isEmpty ||
                audio.bytes.length > PerfectVoiceClip.maxBytes ||
                audio.duration <= Duration.zero ||
                audio.duration > PerfectVoiceClip.maxDuration ||
                audio.mimeType != 'audio/wav'))) {
      throw const PerfectAiException(
        code: PerfectAiErrorCode.invalidInput,
        message: 'This AI request is larger than the private service accepts.',
        retryable: false,
      );
    }
  }
}

List<Map<String, dynamic>> _rpcItems(
  Map<String, dynamic> payload, {
  required String label,
}) {
  final rawItems = payload['items'];
  if (rawItems is! List || rawItems.length > 200) {
    throw FormatException('$label are invalid.');
  }
  return rawItems
      .map(
        (item) => item is Map
            ? Map<String, dynamic>.from(item)
            : throw FormatException('$label contain an invalid item.'),
      )
      .toList(growable: false);
}

String _historyString(
  Map<String, dynamic> json,
  String key, {
  required int maximumLength,
}) {
  final value = json[key];
  if (value is! String ||
      value.trim().isEmpty ||
      value.length > maximumLength) {
    throw FormatException('Invalid synced AI $key.');
  }
  return value;
}

PerfectAiProposal? _latestRestorableProposal(
  List<Map<String, dynamic>> messages,
) {
  for (final message in messages.reversed) {
    if (message['role'] != 'assistant' || message['status'] != 'completed') {
      continue;
    }
    final rawProposal = message['proposal'];
    if (rawProposal is! Map || rawProposal.isEmpty) continue;
    final rawResult = message['result'];
    if (rawResult is Map && rawResult.isNotEmpty) return null;
    final proposal = PerfectAiProposal.fromJson(
      Map<String, dynamic>.from(rawProposal),
    );
    return proposal.requiresConfirmation ? proposal : null;
  }
  return null;
}

int _compareMessages(PerfectAiMessage left, PerfectAiMessage right) {
  final timestamp = left.createdAt.compareTo(right.createdAt);
  return timestamp != 0 ? timestamp : left.id.compareTo(right.id);
}

PerfectAiException _mapHistoryError(PostgrestException error) {
  final unauthorized =
      error.code == '28000' ||
      error.code == '42501' ||
      error.message.toLowerCase().contains('authenticated');
  return PerfectAiException(
    code: unauthorized
        ? PerfectAiErrorCode.unauthorized
        : PerfectAiErrorCode.unavailable,
    message: unauthorized
        ? 'Your private session could not load AI history.'
        : 'Perfect AI could not load your synced conversation.',
    retryable: !unauthorized,
  );
}

PerfectAiException _mapFunctionError(FunctionException error) {
  final details = error.details;
  String? serverCode;
  String? serverMessage;
  bool? retryable;
  if (details is Map) {
    final root = Map<String, dynamic>.from(details);
    final rawError = root['error'];
    if (rawError is Map) {
      final typed = Map<String, dynamic>.from(rawError);
      serverCode = typed['code'] as String?;
      serverMessage = typed['message'] as String?;
      retryable = typed['retryable'] as bool?;
    }
  }
  final code = switch (error.status) {
    400 => PerfectAiErrorCode.invalidInput,
    401 || 403 => PerfectAiErrorCode.unauthorized,
    408 => PerfectAiErrorCode.timeout,
    429 => PerfectAiErrorCode.quota,
    500 || 502 || 503 || 504 => PerfectAiErrorCode.unavailable,
    _ =>
      serverCode == 'timeout'
          ? PerfectAiErrorCode.timeout
          : PerfectAiErrorCode.unknown,
  };
  return PerfectAiException(
    code: code,
    message:
        serverMessage ??
        switch (code) {
          PerfectAiErrorCode.unauthorized =>
            'Your private session expired. Sign in again.',
          PerfectAiErrorCode.quota =>
            'Perfect AI is taking a breather. Try again shortly.',
          PerfectAiErrorCode.timeout =>
            'The answer took too long. Your message is still here.',
          PerfectAiErrorCode.invalidInput =>
            'Perfect AI could not understand this request.',
          _ => 'Perfect AI is temporarily unavailable.',
        },
    retryable:
        retryable ??
        const <PerfectAiErrorCode>{
          PerfectAiErrorCode.quota,
          PerfectAiErrorCode.timeout,
          PerfectAiErrorCode.unavailable,
        }.contains(code),
  );
}

PerfectAiException _cancelled() => const PerfectAiException(
  code: PerfectAiErrorCode.cancelled,
  message: 'Request cancelled.',
  retryable: true,
);
