import '../constants/app_constants.dart';
import 'revenue_cat_config.dart';
import 'supabase_config.dart';

/// Runtime config. Prefers `--dart-define`, falls back to local config files.
abstract final class EnvConfig {
  static const String _supabaseUrlDefine = String.fromEnvironment(
    AppConstants.supabaseUrlEnv,
  );
  static const String _supabaseAnonKeyDefine = String.fromEnvironment(
    AppConstants.supabaseAnonKeyEnv,
  );
  static const String _revenueCatApiKeyDefine = String.fromEnvironment(
    AppConstants.revenueCatApiKeyEnv,
  );

  /// Optional: `dev` unlocks server `PRO_UNLOCK_ALL` when that env is set.
  static const String kehloEnv = String.fromEnvironment(
    'KEHLO_ENV',
    defaultValue: '',
  );

  static String get supabaseUrl =>
      _supabaseUrlDefine.isNotEmpty ? _supabaseUrlDefine : SupabaseConfig.url;

  static String get supabaseAnonKey => _supabaseAnonKeyDefine.isNotEmpty
      ? _supabaseAnonKeyDefine
      : SupabaseConfig.anonKey;

  /// Public SDK key only — never the RevenueCat secret (`sk_…` stays on Edge).
  static String get revenueCatApiKey => _revenueCatApiKeyDefine.isNotEmpty
      ? _revenueCatApiKeyDefine
      : RevenueCatConfig.apiKey;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasRevenueCat => revenueCatApiKey.trim().isNotEmpty;
}
