import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/edge_function_errors.dart';
import '../models/person.dart';

class DateBriefing {
  const DateBriefing({
    required this.whatYouKnow,
    required this.goodTopics,
    required this.avoid,
    required this.challenge,
  });

  final List<String> whatYouKnow;
  final List<String> goodTopics;
  final List<String> avoid;
  final String challenge;
}

class DateDebrief {
  const DateDebrief({
    required this.tip,
    required this.nextMoves,
  });

  final String tip;
  final List<String> nextMoves;
}

class PeopleCoachService {
  PeopleCoachService(this._client);

  final SupabaseClient _client;

  Future<DateBriefing> briefing({
    required Person person,
    List<String> historySnippets = const [],
  }) async {
    final data = await _invoke({
      'mode': 'briefing',
      'name': person.name,
      'note': person.note,
      'status': person.status.name,
      'historySnippets': historySnippets,
    });
    return DateBriefing(
      whatYouKnow: _strings(data['whatYouKnow']),
      goodTopics: _strings(data['goodTopics']),
      avoid: _strings(data['avoid']),
      challenge: data['challenge']?.toString().trim() ?? '',
    );
  }

  Future<DateDebrief> debrief({
    required Person person,
    required String notes,
    List<String> historySnippets = const [],
  }) async {
    final data = await _invoke({
      'mode': 'debrief',
      'name': person.name,
      'note': person.note,
      'status': person.status.name,
      'debrief': notes,
      'historySnippets': historySnippets,
    });
    return DateDebrief(
      tip: data['tip']?.toString().trim() ?? 'Keep it light.',
      nextMoves: _strings(data['nextMoves']),
    );
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(
        'people-coach',
        body: body,
      );
      final data = _asMap(response.data);
      if (response.status >= 400) {
        throw mapEdgeHttpError(response.status, data);
      }
      return data;
    } on AppException {
      rethrow;
    } on FunctionException catch (e) {
      throw mapFunctionException(e);
    } catch (e, st) {
      debugPrint('people-coach: ${e.runtimeType}\n$st');
      throw AppExceptionMapper.map(e);
    }
  }

  List<String> _strings(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
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
