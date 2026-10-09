/// Flutter-facing boundary for the per-device Perfect AI local runtime.
///
/// The app never holds model credentials. The device-local `opencode serve`
/// runtime owns its own auth/storage; this caller sends bounded request
/// fields only and parses the typed local result. Cloud stays sync/receipt
/// only and is never the model hop.
library;

import 'dart:convert';

/// Stable, safe code only. Never carries prompt or provider data.
final class PerfectLocalRuntimeFailure implements Exception {
  const PerfectLocalRuntimeFailure(this.code);
  final String code;
  @override
  String toString() => 'PerfectLocalRuntimeFailure($code)';
}

final _keyChars = RegExp(r'^[A-Za-z0-9\-_.]{1,128}$');

/// Pinned local model identity. Change only on explicit user order; never
/// silently fall back to another model.
const perfectLocalProviderId = 'opencode';
const perfectLocalModelId = 'muse-spark-1.3-contributor-free';

/// Bounded local chat request. Validation mirrors the local caller preflight.
final class PerfectLocalChatRequest {
  const PerfectLocalChatRequest({
    required this.operationId,
    required this.message,
    required this.history,
    required this.idempotencyKey,
    this.systemPrompt,
  });

  final String operationId;
  final String message;
  final List<PerfectLocalChatTurn> history;
  final String idempotencyKey;
  final String? systemPrompt;

  Map<String, Object?> toServeJson() {
    if (operationId.isEmpty ||
        operationId.length > 160 ||
        !_keyChars.hasMatch(idempotencyKey) ||
        message.length > 4000) {
      throw const PerfectLocalRuntimeFailure('AI_VISION_REQUEST_INVALID');
    }
    if (history.length > 20) {
      throw const PerfectLocalRuntimeFailure('AI_VISION_REQUEST_INVALID');
    }
    var historyChars = 0;
    for (final turn in history) {
      historyChars += turn.text.length;
    }
    if (historyChars > 12000) {
      throw const PerfectLocalRuntimeFailure('AI_VISION_REQUEST_INVALID');
    }
    final parts = <Map<String, Object?>>[];
    if (systemPrompt != null && systemPrompt!.trim().isNotEmpty) {
      if (systemPrompt!.length > 8000) {
        throw const PerfectLocalRuntimeFailure('AI_VISION_REQUEST_INVALID');
      }
    }
    for (final turn in history) {
      parts.add(<String, Object?>{
        'type': 'text',
        'text': '${turn.role}: ${turn.text}',
      });
    }
    parts.add(<String, Object?>{'type': 'text', 'text': message});
    return <String, Object?>{
      'model': <String, Object?>{
        'providerID': perfectLocalProviderId,
        'modelID': perfectLocalModelId,
      },
      'agent': 'build',
      'tools': <String, Object?>{},
      if (systemPrompt != null && systemPrompt!.trim().isNotEmpty)
        'system': systemPrompt,
      'parts': parts,
    };
  }
}

final class PerfectLocalChatTurn {
  const PerfectLocalChatTurn({required this.role, required this.text});

  final String role;
  final String text;
}

/// Safe local result subset. No prompt, secret, or raw provider data.
final class PerfectLocalChatResult {
  const PerfectLocalChatResult({
    required this.messageId,
    required this.text,
    required this.sessionId,
  });

  final String messageId;
  final String text;
  final String sessionId;

  factory PerfectLocalChatResult.fromServeJson(Map<String, Object?> json) {
    final info = json['info'];
    if (info is! Map<String, Object?>) {
      throw const PerfectLocalRuntimeFailure('AI_SCHEMA_REJECTED');
    }
    if (info['providerID'] != perfectLocalProviderId ||
        info['modelID'] != perfectLocalModelId) {
      throw const PerfectLocalRuntimeFailure('AI_ROUTE_NOT_ALLOWED');
    }
    final error = info['error'];
    if (error is Map<String, Object?> && error.isNotEmpty) {
      throw const PerfectLocalRuntimeFailure('AI_PROVIDER_FAILURE');
    }
    final messageId = json['id'];
    final sessionId = json['sessionID'];
    if (messageId is! String ||
        !messageId.startsWith('msg_') ||
        sessionId is! String ||
        !sessionId.startsWith('ses_')) {
      throw const PerfectLocalRuntimeFailure('AI_SCHEMA_REJECTED');
    }
    final parts = json['parts'];
    if (parts is! List) {
      throw const PerfectLocalRuntimeFailure('AI_SCHEMA_REJECTED');
    }
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, Object?> &&
          part['type'] == 'text' &&
          part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    final text = buffer.toString().trim();
    if (text.isEmpty || text.length > 12000) {
      throw const PerfectLocalRuntimeFailure('AI_SCHEMA_REJECTED');
    }
    return PerfectLocalChatResult(
      messageId: messageId,
      text: text,
      sessionId: sessionId,
    );
  }
}

/// Minimal HTTP surface injected by caller (keeps client testable, no dep).
abstract interface class PerfectLocalHttpResponse {
  int get statusCode;
  String get body;
}

typedef PerfectLocalPost = Future<PerfectLocalHttpResponse> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

/// Thin local caller: localhost only, bounded JSON out, code-only errors.
final class PerfectLocalRuntimeClient {
  const PerfectLocalRuntimeClient({
    required this.baseUri,
    required this.post,
  });

  final Uri baseUri;
  final PerfectLocalPost post;

  Future<String> createSession({required String title}) async {
    if (title.trim().isEmpty || title.length > 120) {
      throw const PerfectLocalRuntimeFailure('AI_VISION_REQUEST_INVALID');
    }
    final PerfectLocalHttpResponse response;
    try {
      response = await post(
        baseUri.resolve('/session'),
        {'Content-Type': 'application/json'},
        jsonEncode(<String, Object?>{'title': title}),
      );
    } catch (_) {
      throw const PerfectLocalRuntimeFailure('AI_GATEWAY_NOT_CONFIGURED');
    }
    if (response.statusCode != 200) {
      throw const PerfectLocalRuntimeFailure('AI_GATEWAY_NOT_CONFIGURED');
    }
    Map<String, Object?> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, Object?>;
    } catch (_) {
      throw const PerfectLocalRuntimeFailure('AI_SCHEMA_REJECTED');
    }
    final id = decoded['id'];
    if (id is! String || !id.startsWith('ses_')) {
      throw const PerfectLocalRuntimeFailure('AI_SCHEMA_REJECTED');
    }
    return id;
  }

  Future<PerfectLocalChatResult> sendChat(
    String sessionId,
    PerfectLocalChatRequest request,
  ) async {
    if (!sessionId.startsWith('ses_') || sessionId.length > 160) {
      throw const PerfectLocalRuntimeFailure('AI_VISION_REQUEST_INVALID');
    }
    final wire = request.toServeJson();
    final PerfectLocalHttpResponse response;
    try {
      response = await post(
        baseUri.resolve('/session/$sessionId/message'),
        {'Content-Type': 'application/json'},
        jsonEncode(wire),
      );
    } catch (_) {
      throw const PerfectLocalRuntimeFailure('AI_PROVIDER_FAILURE');
    }
    if (response.statusCode != 200) {
      throw const PerfectLocalRuntimeFailure('AI_PROVIDER_FAILURE');
    }
    Map<String, Object?> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, Object?>;
    } catch (_) {
      throw const PerfectLocalRuntimeFailure('AI_SCHEMA_REJECTED');
    }
    return PerfectLocalChatResult.fromServeJson(decoded);
  }
}
