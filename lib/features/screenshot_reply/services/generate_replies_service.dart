import 'dart:async' as async;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/config/env_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/edge_function_errors.dart';
import '../models/generation_prefs.dart';
import '../models/reply_generation_result.dart';
import '../parsers/reply_response_parser.dart';

typedef ReplyPartialCallback = void Function(
  String natural,
  String playful, {
  String? latestIncoming,
});

/// Cancels an in-flight generate (streaming HTTP).
class GenerationCancelToken {
  bool _cancelled = false;
  http.Client? _client;

  bool get isCancelled => _cancelled;

  void _attach(http.Client client) => _client = client;

  void cancel() {
    _cancelled = true;
    _client?.close();
    _client = null;
  }
}

abstract class GenerateRepliesService {
  Future<ReplyGenerationResult> generateFromScreenshot(
    XFile image, {
    String? latestMessageOverride,
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  });

  Future<ReplyGenerationResult> generateFromMessage({
    required String message,
    String? context,
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  });

  Future<ReplyGenerationResult> generateOpeners(
    XFile image, {
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
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
    XFile image, {
    String? latestMessageOverride,
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) async {
    final dataUrl = await _encodeImage(image);
    if (dataUrl == null) {
      throw const AnalysisException(
        "Couldn't read that image. Try another screenshot.",
      );
    }
    final body = <String, dynamic>{
      'image': dataUrl,
      ...prefs.toJson(),
    };
    final override = latestMessageOverride?.trim();
    if (override != null && override.isNotEmpty) {
      body['message'] = override;
    }
    return _generate(body, onPartial: onPartial, cancelToken: cancelToken);
  }

  @override
  Future<ReplyGenerationResult> generateFromMessage({
    required String message,
    String? context,
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const AnalysisException(
        'Enter the message you received to continue.',
      );
    }
    final body = <String, dynamic>{
      'message': trimmed,
      ...prefs.toJson(),
    };
    final ctx = context?.trim();
    if (ctx != null && ctx.isNotEmpty) {
      body['context'] = ctx;
    }
    return _generate(body, onPartial: onPartial, cancelToken: cancelToken);
  }

  @override
  Future<ReplyGenerationResult> generateOpeners(
    XFile image, {
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) async {
    final dataUrl = await _encodeImage(image);
    if (dataUrl == null) {
      throw const AnalysisException(
        "Couldn't read that image. Try another profile screenshot.",
      );
    }
    return _generate(
      {
        'image': dataUrl,
        'mode': 'openers',
        ...prefs.toJson(),
      },
      onPartial: onPartial,
      cancelToken: cancelToken,
    );
  }

  Future<ReplyGenerationResult> _generate(
    Map<String, dynamic> body, {
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) async {
    try {
      return await _invokeStream(
        body,
        onPartial: onPartial,
        cancelToken: cancelToken,
      ).timeout(timeout);
    } on async.TimeoutException {
      cancelToken?.cancel();
      throw const TimeoutException();
    } on AppException {
      rethrow;
    } catch (e) {
      if (cancelToken?.isCancelled == true) {
        throw const GenerationException('Cancelled.');
      }
      debugPrint('generate-replies stream failed, falling back: $e');
      return _invokeJson(body);
    }
  }

  Future<ReplyGenerationResult> _invokeStream(
    Map<String, dynamic> body, {
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) async {
    final session = _client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException();
    }

    final uri = Uri.parse(
      '${EnvConfig.supabaseUrl}/functions/v1/generate-replies',
    );
    final client = http.Client();
    cancelToken?._attach(client);

    try {
      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $accessToken',
          'apikey': EnvConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode({...body, 'stream': true});

      final streamed = await client.send(request);
      if (streamed.statusCode == 402) {
        final raw = await streamed.stream.bytesToString();
        throw mapEdgeHttpError(402, _asMap(raw));
      }
      if (streamed.statusCode >= 400) {
        final raw = await streamed.stream.bytesToString();
        throw mapEdgeHttpError(streamed.statusCode, _asMap(raw));
      }

      final buffer = StringBuffer();
      Map<String, dynamic>? donePayload;

      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        if (cancelToken?.isCancelled == true) {
          throw const GenerationException('Cancelled.');
        }
        buffer.write(chunk);
        final text = buffer.toString();
        final parts = text.split('\n\n');
        buffer
          ..clear()
          ..write(parts.isEmpty ? '' : parts.removeLast());

        for (final part in parts) {
          final line = part
              .split('\n')
              .map((l) => l.trim())
              .firstWhere(
                (l) => l.startsWith('data:'),
                orElse: () => '',
              );
          if (line.isEmpty) continue;
          final raw = line.substring(5).trim();
          if (raw.isEmpty) continue;
          Map<String, dynamic> event;
          try {
            event = _asMap(raw);
          } catch (_) {
            continue;
          }
          final type = event['type']?.toString();
          if (type == 'partial') {
            final natural = event['natural']?.toString() ?? '';
            final playful = event['playful']?.toString() ?? '';
            final latest = event['latestIncoming']?.toString().trim();
            onPartial?.call(
              natural,
              playful,
              latestIncoming:
                  latest == null || latest.isEmpty ? null : latest,
            );
          } else if (type == 'done') {
            final payload = event['payload'];
            if (payload is Map) {
              donePayload = Map<String, dynamic>.from(payload);
            }
          } else if (type == 'error') {
            throw mapEdgeHttpError(
              event['code']?.toString() == 'usage_limit' ? 402 : 500,
              event,
            );
          }
        }
      }

      if (donePayload == null || donePayload.isEmpty) {
        throw const GenerationException(
          "Couldn't generate replies. Please try again.",
        );
      }
      try {
        return _parser.parse(donePayload);
      } on FormatException catch (e) {
        throw AnalysisException(e.message);
      }
    } finally {
      client.close();
    }
  }

  Future<ReplyGenerationResult> _invokeJson(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions
          .invoke(
            'generate-replies',
            body: body,
          )
          .timeout(timeout);

      final data = _asMap(response.data);
      if (response.status >= 400) {
        throw mapEdgeHttpError(response.status, data);
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
      throw mapFunctionException(e);
    } catch (e, st) {
      debugPrint('generate-replies failed: ${e.runtimeType}');
      if (kDebugMode) {
        debugPrint('$st');
      }
      throw AppExceptionMapper.map(e);
    }
  }

  Future<String?> _encodeImage(XFile image) async {
    late final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (_) {
      return null;
    }
    if (bytes.isEmpty) return null;
    if (bytes.length > maxBytes) {
      throw const AnalysisException(
        'That screenshot is too large. Try a clearer crop and try again.',
      );
    }
    final name = (image.name.isNotEmpty ? image.name : image.path).toLowerCase();
    final mime = image.mimeType?.trim().isNotEmpty == true
        ? image.mimeType!.trim()
        : name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
    // compute() is unreliable for large payloads on some web builds — encode inline.
    if (kIsWeb) {
      return _encodeDataUrl((bytes, mime));
    }
    return compute(_encodeDataUrl, (bytes, mime));
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
}

String _encodeDataUrl((Uint8List bytes, String mime) args) {
  final (bytes, mime) = args;
  return 'data:$mime;base64,${base64Encode(bytes)}';
}
