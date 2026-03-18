import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env.dart';

/// Initializes Supabase for UNOclinic.
///
/// Provide values via:
/// - `--dart-define=SUPABASE_URL=...`
/// - `--dart-define=SUPABASE_ANON_KEY=...`
class SupabaseInitializer {
  SupabaseInitializer._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: Env.supabaseUrl);
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: Env.supabaseAnonKey);

  static Future<void> ensureInitialized() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Run with '
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
