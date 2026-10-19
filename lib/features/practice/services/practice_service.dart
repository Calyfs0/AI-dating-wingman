import 'dart:async' as async;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../models/practice_models.dart';

class PracticeService {
  PracticeService(this._client, {this.timeout = const Duration(seconds: 45)});

  final SupabaseClient _client;
  final Duration timeout;

  static const _fallback =
      "Couldn't continue practice. Please try again.";

  Future<({String personaLine, PracticeFeedback? feedback, bool done})> turn({
    required PracticeTopic topic,
    required String personaName,
    required String personaStyle,
    required List<PracticeTurn> history,
    required String userMessage,
  }) async {
    try {
      final response = await _client.functions
          .invoke(
            'practice-session',
            body: {
              'topic': topic.name,
              'personaName': personaName,
              'personaStyle': personaStyle,
              'history': history
                  .map((t) => {
                        'role': t.fromUser ? 'user' : 'assistant',
                        'text': t.text,
                      })
                  .toList(),
              'message': userMessage.trim(),
            },
          )
          .timeout(timeout);

      final data = _asMap(response.data);
      if (response.status >= 400) {
        throw GenerationException(_messageFrom(data) ?? _fallback);
      }

      final personaLine = data['personaLine']?.toString().trim() ?? '';
      final done = data['done'] == true;
      PracticeFeedback? feedback;
      final fb = data['feedback'];
      if (fb is Map) {
        final map = Map<String, dynamic>.from(fb);
        final tipsRaw = map['tips'];
        feedback = PracticeFeedback(
          summary: map['summary']?.toString().trim() ?? 'Nice work.',
          confidence: _score(map['confidence']),
          naturalness: _score(map['naturalness']),
          conversation: _score(map['conversation']),
          tips: tipsRaw is List
              ? tipsRaw
                  .map((e) => e.toString())
                  .where((s) => s.isNotEmpty)
                  .toList()
              : const [],
        );
      }

      if (personaLine.isEmpty && feedback == null) {
        throw const GenerationException(_fallback);
      }

      return (personaLine: personaLine, feedback: feedback, done: done);
    } on async.TimeoutException {
      throw const TimeoutException();
    } on AppException {
      rethrow;
    } on FunctionException catch (e) {
      throw GenerationException(_messageFromFunctionException(e));
    } catch (e, st) {
      debugPrint('practice-session failed: ${e.runtimeType}\n$st');
      throw AppExceptionMapper.map(e);
    }
  }

  String _messageFromFunctionException(FunctionException e) {
    final details = e.details;
    if (details is Map) {
      return _messageFrom(Map<String, dynamic>.from(details)) ?? _fallback;
    }
    if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) {
          return _messageFrom(Map<String, dynamic>.from(decoded)) ?? _fallback;
        }
      } catch (_) {}
      final trimmed = details.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('{')) return trimmed;
    }
    return _fallback;
  }

  String? _messageFrom(Map<String, dynamic> data) {
    final error = data['error']?.toString().trim();
    if (error != null && error.isNotEmpty) return error;
    return null;
  }

  /// Normalizes model scores to 0–1. Treats missing/0/example-zeros as a
  /// sensible default so bars never render empty after a real session.
  double _score(dynamic value, {double fallback = 0.72}) {
    double? raw;
    if (value is num) {
      raw = value.toDouble();
    } else if (value is String) {
      raw = double.tryParse(value.trim());
    }
    if (raw == null || raw.isNaN) return fallback;
    // Model sometimes returns 0–100.
    if (raw > 1) raw = raw / 100;
    if (raw <= 0) return fallback;
    return raw.clamp(0.05, 1.0);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const {};
  }
}
