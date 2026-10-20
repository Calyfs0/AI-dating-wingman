/// Local RevenueCat config (public SDK key only — never the secret API key).
///
/// Dashboard → Project settings → API keys → Apple / Google public SDK key.
/// Paste below, then `flutter run` as usual (no dart-define required).
///
/// Optional override:
/// `flutter run --dart-define=REVENUECAT_API_KEY=appl_…`
abstract final class RevenueCatConfig {
  /// Public SDK key (`appl_…` / `goog_…`). Leave empty to disable purchases (fail closed).
  static const String apiKey = 'appl_ibzVNeRPXMbzoYYgpaXhaJyZYsD';
}
