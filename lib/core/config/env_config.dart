import '../constants/app_constants.dart';
import 'supabase_config.dart';

/// Runtime config. Prefers `--dart-define`, falls back to [SupabaseConfig].
abstract final class EnvConfig {
  static const String _supabaseUrlDefine = String.fromEnvironment(
    AppConstants.supabaseUrlEnv,
  );
  static const String _supabaseAnonKeyDefine = String.fromEnvironment(
    AppConstants.supabaseAnonKeyEnv,
  );
  static const String revenueCatApiKey = String.fromEnvironment(
    AppConstants.revenueCatApiKeyEnv,
  );

  static String get supabaseUrl =>
      _supabaseUrlDefine.isNotEmpty ? _supabaseUrlDefine : SupabaseConfig.url;

  static String get supabaseAnonKey => _supabaseAnonKeyDefine.isNotEmpty
      ? _supabaseAnonKeyDefine
      : SupabaseConfig.anonKey;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
