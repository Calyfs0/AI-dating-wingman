import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import 'app_exception.dart';

/// Maps Edge Function HTTP / FunctionException payloads to [AppException].
AppException mapEdgeHttpError(int status, Map<String, dynamic> data) {
  final message = data['error']?.toString();
  final code = data['code']?.toString();

  if (status == 401 || code == 'auth') {
    return AuthException(message ?? const AuthException().message);
  }
  if (status == 402 || code == 'usage_limit') {
    return UsageLimitException(
      message ?? const UsageLimitException().message,
    );
  }
  if (status == 422 ||
      code == 'unreadable' ||
      code == 'validation' ||
      code == 'invalid' ||
      code == 'safety') {
    return AnalysisException(message ?? const AnalysisException().message);
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

AppException mapFunctionException(FunctionException e) {
  Map<String, dynamic> data = const {};
  final details = e.details;
  if (details is Map) {
    data = Map<String, dynamic>.from(details);
  } else if (details is String) {
    try {
      final decoded = jsonDecode(details);
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return mapEdgeHttpError(e.status, data);
}

/// Optional `usage` object from successful or 402 Edge payloads.
Map<String, dynamic>? readUsageMap(Map<String, dynamic> data) {
  final usage = data['usage'];
  if (usage is Map) return Map<String, dynamic>.from(usage);
  return null;
}
