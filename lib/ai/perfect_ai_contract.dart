import 'dart:convert';
import 'dart:typed_data';

enum PerfectAiRole { user, assistant }

class PerfectAiMessage {
  const PerfectAiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory PerfectAiMessage.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'user' => PerfectAiRole.user,
      'assistant' => PerfectAiRole.assistant,
      _ => throw const FormatException('Unsupported AI message role.'),
    };
    final id = _requiredString(json, 'id', maxLength: 160);
    final text = _requiredString(json, 'text', maxLength: 12000);
    final createdAt = DateTime.tryParse(
      _requiredString(json, 'created_at', maxLength: 64),
    );
    if (createdAt == null) {
      throw const FormatException('Invalid AI message timestamp.');
    }
    return PerfectAiMessage(
      id: id,
      role: role,
      text: text,
      createdAt: createdAt.toUtc(),
    );
  }

  final String id;
  final PerfectAiRole role;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'role': role.name,
    'text': text,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class PerfectAiConversationSnapshot {
  const PerfectAiConversationSnapshot({
    required this.conversationId,
    required this.messages,
    this.pendingProposal,
  });

  final String conversationId;
  final List<PerfectAiMessage> messages;
  final PerfectAiProposal? pendingProposal;
}

class PerfectVoiceClip {
  const PerfectVoiceClip({
    required this.bytes,
    required this.mimeType,
    required this.duration,
  });

  static const maxBytes = 5 * 1024 * 1024;
  static const maxDuration = Duration(seconds: 45);

  final Uint8List bytes;
  final String mimeType;
  final Duration duration;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'mime_type': mimeType,
    'base64': base64Encode(bytes),
    'duration_ms': duration.inMilliseconds,
  };
}

class PerfectAiProposalItem {
  const PerfectAiProposalItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.payload,
  });

  factory PerfectAiProposalItem.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    if (rawPayload is! Map) {
      throw const FormatException('Proposal item payload must be an object.');
    }
    return PerfectAiProposalItem(
      id: _requiredString(json, 'id', maxLength: 160),
      kind: _requiredString(json, 'kind', maxLength: 40),
      title: _requiredString(json, 'title', maxLength: 160),
      payload: Map<String, dynamic>.from(rawPayload),
    );
  }

  final String id;
  final String kind;
  final String title;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind,
    'title': title,
    'payload': payload,
  };
}

class PerfectAiProposal {
  const PerfectAiProposal({
    required this.submissionId,
    required this.title,
    required this.summary,
    required this.items,
    required this.requiresConfirmation,
  });

  factory PerfectAiProposal.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List || rawItems.isEmpty || rawItems.length > 100) {
      throw const FormatException('Proposal items are invalid.');
    }
    return PerfectAiProposal(
      submissionId: _requiredString(json, 'submission_id', maxLength: 160),
      title: _requiredString(json, 'title', maxLength: 160),
      summary: _optionalString(json, 'summary', maxLength: 4000) ?? '',
      items: rawItems
          .map(
            (item) => PerfectAiProposalItem.fromJson(
              _jsonObject(item, label: 'proposal item'),
            ),
          )
          .toList(growable: false),
      requiresConfirmation: json['requires_confirmation'] == true,
    );
  }

  final String submissionId;
  final String title;
  final String summary;
  final List<PerfectAiProposalItem> items;
  final bool requiresConfirmation;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'submission_id': submissionId,
    'title': title,
    'summary': summary,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'requires_confirmation': requiresConfirmation,
  };
}

class PerfectAiTelemetry {
  const PerfectAiTelemetry({
    this.requestId,
    this.model,
    this.promptVersion,
    this.schemaVersion,
    this.latencyMs,
  });

  factory PerfectAiTelemetry.fromJson(Map<String, dynamic> json) =>
      PerfectAiTelemetry(
        requestId: _optionalString(json, 'request_id', maxLength: 240),
        model: _optionalString(json, 'model', maxLength: 160),
        promptVersion: _optionalString(json, 'prompt_version', maxLength: 160),
        schemaVersion: _optionalString(json, 'schema_version', maxLength: 160),
        latencyMs: json['latency_ms'] is num
            ? (json['latency_ms'] as num).toInt()
            : null,
      );

  final String? requestId;
  final String? model;
  final String? promptVersion;
  final String? schemaVersion;
  final int? latencyMs;
}

class PerfectAiTurnResult {
  const PerfectAiTurnResult({
    required this.operationId,
    required this.conversationId,
    required this.message,
    this.transcribedText,
    this.proposal,
    this.telemetry,
  });

  factory PerfectAiTurnResult.fromJson(Map<String, dynamic> json) {
    _requireSchemaV1(json);
    return PerfectAiTurnResult(
      operationId: _requiredString(json, 'operation_id', maxLength: 160),
      conversationId: _requiredString(json, 'conversation_id', maxLength: 160),
      message: PerfectAiMessage.fromJson(
        _jsonObject(json['message'], label: 'message'),
      ),
      transcribedText: _optionalString(
        json,
        'transcribed_text',
        maxLength: 4000,
      ),
      proposal: json['proposal'] == null
          ? null
          : PerfectAiProposal.fromJson(
              _jsonObject(json['proposal'], label: 'proposal'),
            ),
      telemetry: json['telemetry'] == null
          ? null
          : PerfectAiTelemetry.fromJson(
              _jsonObject(json['telemetry'], label: 'telemetry'),
            ),
    );
  }

  final String operationId;
  final String conversationId;
  final PerfectAiMessage message;
  final String? transcribedText;
  final PerfectAiProposal? proposal;
  final PerfectAiTelemetry? telemetry;
}

class PerfectAiApplyResult {
  const PerfectAiApplyResult({
    required this.operationId,
    required this.conversationId,
    required this.appliedCount,
    required this.message,
  });

  factory PerfectAiApplyResult.fromJson(Map<String, dynamic> json) {
    _requireSchemaV1(json);
    final rawApply = _jsonObject(json['apply_result'], label: 'apply result');
    final rawCount = rawApply['applied_count'] ?? rawApply['item_count'];
    if (rawCount is! num || rawCount < 0 || rawCount > 100) {
      throw const FormatException('Invalid applied item count.');
    }
    final rawMessage = json['message'];
    return PerfectAiApplyResult(
      operationId: _requiredString(json, 'operation_id', maxLength: 160),
      conversationId: _requiredString(json, 'conversation_id', maxLength: 160),
      appliedCount: rawCount.toInt(),
      message: rawMessage is Map
          ? PerfectAiMessage.fromJson(Map<String, dynamic>.from(rawMessage))
          : null,
    );
  }

  final String operationId;
  final String conversationId;
  final int appliedCount;
  final PerfectAiMessage? message;
}

class PerfectAiRequest {
  const PerfectAiRequest({
    required this.operationId,
    required this.message,
    required this.conversation,
    this.conversationId,
    this.audio,
  });

  final String operationId;
  final String message;
  final List<PerfectAiMessage> conversation;
  final String? conversationId;
  final PerfectVoiceClip? audio;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schema_version': 1,
    'action': 'chat',
    'operation_id': operationId,
    if (conversationId != null) 'conversation_id': conversationId,
    'message': message,
    'conversation': conversation
        .take(20)
        .map((item) => item.toJson())
        .toList(growable: false),
    if (audio != null) 'audio': audio!.toJson(),
  };
}

class PerfectAiCancellation {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

enum PerfectAiErrorCode {
  cancelled,
  invalidInput,
  unauthorized,
  quota,
  unavailable,
  timeout,
  malformedResponse,
  unknown,
}

class PerfectAiException implements Exception {
  const PerfectAiException({
    required this.code,
    required this.message,
    required this.retryable,
  });

  final PerfectAiErrorCode code;
  final String message;
  final bool retryable;

  @override
  String toString() => 'PerfectAiException($code, $message)';
}

Map<String, dynamic> perfectAiJsonObject(
  Object? value, {
  String label = 'response',
}) => _jsonObject(value, label: label);

void _requireSchemaV1(Map<String, dynamic> json) {
  if (json['schema_version'] != 1) {
    throw const FormatException('Unsupported AI response schema.');
  }
}

Map<String, dynamic> _jsonObject(Object? value, {required String label}) {
  if (value is! Map) {
    throw FormatException('$label must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  required int maxLength,
}) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty || value.length > maxLength) {
    throw FormatException('Invalid $key.');
  }
  return value;
}

String? _optionalString(
  Map<String, dynamic> json,
  String key, {
  required int maxLength,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.length > maxLength) {
    throw FormatException('Invalid $key.');
  }
  return value;
}
