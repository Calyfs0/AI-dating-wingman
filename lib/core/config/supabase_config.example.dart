/// Copy to `supabase_config.dart` and fill in your project values.
///
/// ```bash
/// cp lib/core/config/supabase_config.example.dart lib/core/config/supabase_config.dart
/// ```
abstract final class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
  static const String projectRef = 'YOUR_PROJECT_REF';
}
