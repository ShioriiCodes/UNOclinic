/// Supabase configuration defaults.
///
/// Recommended: override at runtime using `--dart-define`:
/// - `--dart-define=SUPABASE_URL=...`
/// - `--dart-define=SUPABASE_ANON_KEY=...`
///
/// If you run without dart-defines, these values are used.
class Env {
  Env._();

  static const String supabaseUrl = 'https://ihwivraowalhztnhuwac.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_D_3LKqKhdoCLQ1sivSOfIw_1rZw4b96';
}
