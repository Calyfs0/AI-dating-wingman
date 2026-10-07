/// Local Supabase project config (public anon key only — never service role).
///
/// Dashboard: https://supabase.com/dashboard/project/qrdmxegakpupereelpms
///
/// Optional override at run time:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
abstract final class SupabaseConfig {
  static const String url = 'https://qrdmxegakpupereelpms.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyZG14ZWdha3B1cGVyZWVscG1zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzOTcyOTEsImV4cCI6MjEwNjk3MzI5MX0.3cTh3QCpk-qjMu8s_dZ0ddNvXJHhajSTLqM-sF5BC7Q';

  static const String projectRef = 'qrdmxegakpupereelpms';
}
