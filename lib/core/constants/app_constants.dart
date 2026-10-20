abstract final class AppConstants {
  static const String appName = 'Kehlo';
  static const String tagline = 'Stuck on a reply? Kehlo.';
  static const String entitlementPro = 'pro';

  /// App Store / RC auto-renewable monthly.
  static const String monthlyProductId = 'kehlo_pro_monthly';

  /// App Store / RC consumable — 1 hour of Pro.
  static const String boostProductId = 'kehlo_boost_1h';
  static const int boostDurationHours = 1;

  /// Consumable — continue the current practice chat for 1 hour. Not Pro.
  static const String practiceHourProductId = 'kehlo_practice_1h';
  static const int practiceFreeUserTurns = 10;

  static const int maxScreenshots = 10;
  static const int maxScreenshotBytes = 8 * 1024 * 1024;
  static const Duration aiTimeout = Duration(seconds: 45);
  static const Duration networkTimeout = Duration(seconds: 20);

  /// Public client keys only — never service-role or provider secrets.
  static const String supabaseUrlEnv = 'SUPABASE_URL';
  static const String supabaseAnonKeyEnv = 'SUPABASE_ANON_KEY';
  static const String revenueCatApiKeyEnv = 'REVENUECAT_API_KEY';
}
