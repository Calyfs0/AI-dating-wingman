abstract final class AppConstants {
  static const String appName = 'Wingman';
  static const String tagline = 'Your private AI dating coach.';
  static const String entitlementPro = 'pro';
  static const int maxScreenshots = 10;
  static const int maxScreenshotBytes = 8 * 1024 * 1024;
  static const Duration aiTimeout = Duration(seconds: 45);
  static const Duration networkTimeout = Duration(seconds: 20);

  /// Public client keys only — never service-role or provider secrets.
  static const String supabaseUrlEnv = 'SUPABASE_URL';
  static const String supabaseAnonKeyEnv = 'SUPABASE_ANON_KEY';
  static const String revenueCatApiKeyEnv = 'REVENUECAT_API_KEY';
}
