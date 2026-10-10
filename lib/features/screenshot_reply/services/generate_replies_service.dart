import 'dart:async' as async;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../models/reply_generation_result.dart';
import '../parsers/reply_response_parser.dart';

abstract class GenerateRepliesService {
  Future<ReplyGenerationResult> generateFromScreenshot(
    String imagePath, {
    String? latestMessageOverride,
  });

  Future<ReplyGenerationResult> generateFromMessage({
    required String message,
    String? context,
  });
}

class SupabaseGenerateRepliesService implements GenerateRepliesService {
  SupabaseGenerateRepliesService(
    this._client, {
    ReplyResponseParser parser = const ReplyResponseParser(),
    this.timeout = const Duration(seconds: 60),
    this.maxBytes = 5 * 1024 * 1024,
  }) : _parser = parser;

  final SupabaseClient _client;
  final ReplyResponseParser _parser;
  final Duration timeout;
  final int maxBytes;

  @override
  Future<ReplyGenerationResult> generateFromScreenshot(
    String imagePath, {
    String? latestMessageOverride,
  }) async {
    final dataUrl = await _encodeImage(imagePath);
    if (dataUrl == null) {
      throw const AnalysisException(
        "Couldn't read that image. Try another screenshot.",
      );
    }
    final body = <String, dynamic>{'image': dataUrl};
    final override = latestMessageOverride?.trim();
    if (override != null && override.isNotEmpty) {
      body['message'] = override;
    }
    return _invoke(body);
  }

  @override
  Future<ReplyGenerationResult> generateFromMessage({
    required String message,
    String? context,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const AnalysisException(
        'Enter the message you received to continue.',
      );
    }
    final body = <String, dynamic>{'message': trimmed};
    final ctx = context?.trim();
    if (ctx != null && ctx.isNotEmpty) {
      body['context'] = ctx;
    }
    return _invoke(body);
  }

  Future<ReplyGenerationResult> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions
          .invoke(
            'generate-replies',
            body: body,
          )
          .timeout(timeout);

      final data = _asMap(response.data);
      if (response.status >= 400) {
        throw _mapHttpError(response.status, data);
      }
      if (data.isEmpty) {
        throw const GenerationException(
          "Couldn't generate replies. Please try again.",
        );
      }

      try {
        return _parser.parse(data);
      } on FormatException catch (e) {
        throw AnalysisException(e.message);
      }
    } on async.TimeoutException {
      throw const TimeoutException();
    } on AppException {
      rethrow;
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } catch (e, st) {
      debugPrint('generate-replies failed: ${e.runtimeType}');
      if (kDebugMode) {
        debugPrint('$st');
      }
      throw AppExceptionMapper.map(e);
    }
  }

  Future<String?> _encodeImage(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    if (bytes.length > maxBytes) {
      throw const AnalysisException(
        'That screenshot is too large. Try a clearer crop and try again.',
      );
    }
    final lower = path.toLowerCase();
    final mime = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }

  AppException _mapHttpError(int status, Map<String, dynamic> data) {
    final message = data['error']?.toString();
    final code = data['code']?.toString();
    if (status == 401) {
      return AuthException(message ?? const AuthException().message);
    }
    if (status == 422 ||
        code == 'unreadable' ||
        code == 'validation' ||
        code == 'invalid') {
      return AnalysisException(
        message ?? const AnalysisException().message,
      );
    }
    if (status == 408 || code == 'timeout') {
      return TimeoutException(message ?? const TimeoutException().message);
    }
    if (status == 0 || status >= 500) {
      return GenerationException(
        message ?? const GenerationException().message,
      );
    }
    return GenerationException(
      message ?? const GenerationException().message,
    );
  }

  AppException _mapFunctionException(FunctionException e) {
    final details = e.details;
    Map<String, dynamic> data = const {};
    if (details is Map) {
      data = Map<String, dynamic>.from(details);
    } else if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return _mapHttpError(e.status, data);
  }
}
