import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/errors/app_exception.dart';
import '../../data/mappers/conversation_mapper.dart';
import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/communication_style.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/profile_audit.dart';
import 'ai_services.dart';
import 'image_encoder.dart';

Future<Map<String, dynamic>> _invokeFunction(
  SupabaseClient client,
  String name,
  Map<String, dynamic> body,
) async {
  try {
    final response = await client.functions.invoke(name, body: body);
    final data = _requireMap(response);
    if (data['error'] != null) {
      throw _mapFunctionError(data);
    }
    return data;
  } on AppException {
    rethrow;
  } on FunctionException catch (e) {
    final details = e.details;
    if (details is Map) {
      throw _mapFunctionError(Map<String, dynamic>.from(details));
    }
    if (details is String && details.isNotEmpty) {
      try {
        final parsed = jsonDecode(details);
        if (parsed is Map) {
          throw _mapFunctionError(Map<String, dynamic>.from(parsed));
        }
      } on AppException {
        rethrow;
      } catch (_) {}
    }
    if (e.status == 402) throw const UsageLimitException();
    throw AppExceptionMapper.map(e);
  }
}

class SupabaseConversationAnalysisService implements ConversationAnalysisService {
  SupabaseConversationAnalysisService(this._client);

  final SupabaseClient _client;
  Conversation? _cached;
  List<String> lastKeyFacts = const [];

  void clearCache() {
    _cached = null;
    lastKeyFacts = const [];
  }

  @override
  Stream<ProcessingStage> analyzeProgress({
    List<String> imagePaths = const [],
    String? pastedText,
  }) async* {
    yield ProcessingStage.extracting;
    final future = _invokeAnalyze(
      imagePaths: imagePaths,
      pastedText: pastedText,
    );
    yield ProcessingStage.understanding;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    yield ProcessingStage.analyzing;
    try {
      _cached = await future;
      yield ProcessingStage.building;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      yield ProcessingStage.done;
    } catch (_) {
      yield ProcessingStage.failed;
      rethrow;
    }
  }

  @override
  Future<Conversation> analyze({
    List<String> imagePaths = const [],
    String? pastedText,
    String? personName,
  }) async {
    if (_cached != null) {
      final value = _cached!;
      _cached = null;
      return value;
    }
    return _invokeAnalyze(
      imagePaths: imagePaths,
      pastedText: pastedText,
      personName: personName,
    );
  }

  Future<Conversation> _invokeAnalyze({
    List<String> imagePaths = const [],
    String? pastedText,
    String? personName,
  }) async {
    final text = pastedText?.trim() ?? '';
    final images = imagePaths.isEmpty
        ? const <String>[]
        : await ImageEncoder.toDataUrls(imagePaths);

    if (text.isEmpty && images.isEmpty) {
      throw const AnalysisException(
        'Add a screenshot or paste the conversation text.',
      );
    }

    final data = await _invokeFunction(
      _client,
      'analyze-conversation',
      {
        if (text.isNotEmpty) 'pastedText': text,
        if (images.isNotEmpty) 'images': images,
        if (personName != null) 'personName': personName,
        'mode': 'analyze',
      },
    );
    lastKeyFacts = ConversationMapper.keyFactsFrom(data);
    return ConversationMapper.fromAnalyzeResponse(data);
  }

  @override
  Future<MessageInterpretation> interpretMessage(String message) async {
    final data = await _invokeFunction(
      _client,
      'analyze-conversation',
      {'mode': 'interpret', 'message': message},
    );
    return MessageInterpretation(
      message: message,
      interpretation: (data['interpretation'] as String?) ?? '',
      guidance: (data['guidance'] as String?) ?? '',
    );
  }

  @override
  Future<ReviewBeforeSendResult> reviewBeforeSend(String draft) async {
    final data = await _invokeFunction(
      _client,
      'analyze-conversation',
      {'mode': 'review', 'draft': draft},
    );
    return ReviewBeforeSendResult(
      original: draft,
      verdict: (data['verdict'] as String?) ?? "I'd tweak it.",
      why: (data['why'] as String?) ?? '',
      better: (data['better'] as String?) ?? draft,
      sendWorthiness: (data['sendWorthiness'] as num?)?.toDouble() ?? 7,
    );
  }
}

class SupabaseResponseGenerationService implements ResponseGenerationService {
  SupabaseResponseGenerationService(this._client);

  final SupabaseClient _client;
  Conversation? activeConversation;

  @override
  Future<AIGeneration> generate({
    required Conversation conversation,
    required ResponseTone tone,
    CommunicationStyle? style,
  }) async {
    activeConversation = conversation;
    return _invoke(
      mode: 'generate',
      conversation: conversation,
      tone: tone,
      style: style,
    );
  }

  @override
  Future<AIGeneration> humanize({
    required AIGeneration generation,
    CommunicationStyle? style,
  }) {
    return _invoke(
      mode: 'humanize',
      conversation: activeConversation,
      tone: generation.tone,
      style: style,
      priorText: generation.text,
    );
  }

  @override
  Future<AIGeneration> regenerate({
    required AIGeneration generation,
    required String direction,
    CommunicationStyle? style,
  }) {
    return _invoke(
      mode: 'regenerate',
      conversation: activeConversation,
      tone: generation.tone,
      style: style,
      priorText: generation.text,
      direction: direction,
    );
  }

  Future<AIGeneration> _invoke({
    required String mode,
    Conversation? conversation,
    required ResponseTone tone,
    CommunicationStyle? style,
    String? priorText,
    String? direction,
  }) async {
    if (conversation == null) {
      throw const GenerationException();
    }

    final data = await _invokeFunction(
      _client,
      'generate-response',
      {
        'mode': mode,
        'tone': tone.name,
        'conversationId': conversation.id,
        'structured': conversation.toStructuredJson(),
        if (style != null) 'style': style.toJson(),
        if (priorText != null) 'priorText': priorText,
        if (direction != null) 'direction': direction,
      },
    );
    return ConversationMapper.fromGenerationResponse({
      ...data,
      'tone': tone.name,
    });
  }
}

Map<String, dynamic> _requireMap(FunctionResponse response) {
  final data = response.data;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const UnknownAppException('Unexpected response from Wingman servers.');
}

AppException _mapFunctionError(Map<String, dynamic> data) {
  final code = data['code'] as String?;
  final message = data['error']?.toString();
  return switch (code) {
    'usage_limit' =>
      UsageLimitException(message ?? const UsageLimitException().message),
    'auth' => AuthException(message ?? const AuthException().message),
    'network' => NetworkException(message ?? const NetworkException().message),
    'timeout' => TimeoutException(message ?? const TimeoutException().message),
    'analysis' =>
      AnalysisException(message ?? const AnalysisException().message),
    'generation' =>
      GenerationException(message ?? const GenerationException().message),
    'validation' => const AnalysisException(
        'Add a screenshot or paste the conversation text.',
      ),
    _ => UnknownAppException(message ?? const UnknownAppException().message),
  };
}
