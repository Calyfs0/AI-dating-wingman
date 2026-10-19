import 'dart:async' as async;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/edge_function_errors.dart';
import '../models/profile_audit_result.dart';

class ProfileAuditService {
  ProfileAuditService(
    this._client, {
    this.timeout = const Duration(seconds: 60),
    this.maxBytes = 5 * 1024 * 1024,
  });

  final SupabaseClient _client;
  final Duration timeout;
  final int maxBytes;

  Future<ProfileAuditResult> audit({
    required String imagePath,
    String? bio,
  }) async {
    final dataUrl = await _encodeImage(imagePath);
    if (dataUrl == null) {
      throw const AnalysisException(
        "Couldn't read that image. Try another profile screenshot.",
      );
    }

    try {
      final body = <String, dynamic>{'image': dataUrl};
      final b = bio?.trim();
      if (b != null && b.isNotEmpty) body['bio'] = b;

      final response = await _client.functions
          .invoke('profile-audit', body: body)
          .timeout(timeout);

      final data = _asMap(response.data);
      if (response.status >= 400) {
        throw mapEdgeHttpError(response.status, data);
      }

      final notes = data['photoNotes'];
      return ProfileAuditResult(
        overall: _score(data['overall']),
        clarity: _score(data['clarity']),
        personality: _score(data['personality']),
        approachability: _score(data['approachability']),
        conversationPotential: _score(data['conversationPotential']),
        photoNotes: notes is List
            ? notes.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
            : const [],
        bioLikeMe: data['bioLikeMe']?.toString().trim() ?? '',
        bioFunnier: data['bioFunnier']?.toString().trim() ?? '',
        bioShorter: data['bioShorter']?.toString().trim() ?? '',
        hook: data['hook']?.toString().trim(),
        currentBio: data['currentBio']?.toString().trim() ?? b ?? '',
      );
    } on async.TimeoutException {
      throw const TimeoutException();
    } on AppException {
      rethrow;
    } on FunctionException catch (e) {
      throw mapFunctionException(e);
    } catch (e, st) {
      debugPrint('profile-audit failed: ${e.runtimeType}\n$st');
      throw AppExceptionMapper.map(e);
    }
  }

  double _score(dynamic value) {
    if (value is num) {
      final v = value.toDouble();
      if (v > 1) return (v / 100).clamp(0.0, 1.0);
      return v.clamp(0.0, 1.0);
    }
    return 0.6;
  }

  Future<String?> _encodeImage(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxBytes) return null;
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
      } catch (_) {}
    }
    return const {};
  }
}
