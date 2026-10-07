/// User-safe application errors. Never surface raw exceptions in UI.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'You appear to be offline. Check your connection and try again.',
  ]) : super(code: 'network');
}

class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'That took too long. Your conversation wasn\'t lost — try again.',
  ]) : super(code: 'timeout');
}

class AuthException extends AppException {
  const AuthException([
    super.message = 'We couldn\'t verify your account. Please try again.',
  ]) : super(code: 'auth');
}

class AnalysisException extends AppException {
  const AnalysisException([
    super.message =
        'Couldn\'t read this conversation. Try a clearer screenshot or paste the text instead.',
  ]) : super(code: 'analysis');
}

class GenerationException extends AppException {
  const GenerationException([
    super.message = 'Something went wrong generating a response. Try again.',
  ]) : super(code: 'generation');
}

class UsageLimitException extends AppException {
  const UsageLimitException([
    super.message = 'You\'ve reached your free limit. Go Pro to continue.',
  ]) : super(code: 'usage_limit');
}

class PermissionException extends AppException {
  const PermissionException([
    super.message = 'Permission is needed to continue.',
  ]) : super(code: 'permission');
}

class UnknownAppException extends AppException {
  const UnknownAppException([
    super.message = 'Something went wrong. Your conversation wasn\'t lost. Try again.',
  ]) : super(code: 'unknown');
}

class AppExceptionMapper {
  static AppException map(Object error) {
    if (error is AppException) return error;
    final text = error.toString().toLowerCase();
    if (text.contains('usage') && text.contains('limit')) {
      return const UsageLimitException();
    }
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('offline') ||
        text.contains('failed host lookup') ||
        text.contains('connection')) {
      return const NetworkException();
    }
    if (text.contains('timeout')) return const TimeoutException();
    if (text.contains('functionexception') || text.contains('functions_http')) {
      if (text.contains('402') || text.contains('usage_limit')) {
        return const UsageLimitException();
      }
      return const AnalysisException();
    }
    return const UnknownAppException();
  }
}
