import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  /// Loads the profile row for the currently-authenticated user.
  ///
  /// This project uses `profiles.email` as the lookup key (beginner-friendly).
  /// If a profile row doesn't exist yet, it will be created with role=STAFF.
  Future<UserProfile> getOrCreateCurrentUserProfile() async {
    final client = _resolvedClient;
    final user = client.auth.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      throw StateError('No authenticated user email found.');
    }

    final existing = await client
        .from('profiles')
        .select()
        .eq('email', email)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (existing != null) {
      return UserProfile.fromMap((existing as Map).cast<String, dynamic>());
    }

    final inserted = await client
        .from('profiles')
        .insert({
          'email': email,
          'role': 'STAFF',
          'full_name': null,
        })
        .select()
        .single();

    return UserProfile.fromMap((inserted as Map).cast<String, dynamic>());
  }
}

