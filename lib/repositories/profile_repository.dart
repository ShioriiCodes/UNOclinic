// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _service = SupabaseService(client: client ?? Supabase.instance.client);

  final SupabaseService _service;

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _service.client.auth.currentUser;
    if (user == null) return null;

    print('QUERY -> table: profiles');
    final row = await _service.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    print('RESULT -> $row');
    print('DATA FETCHED: $row');
    if (row == null) {
      print('WARNING: No data returned');
    }

    return row == null ? null : (row as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final rows = await _service.select(
      'profiles',
      columns: 'id,email,role,full_name,created_at',
      orderBy: 'created_at',
      ascending: false,
    );
    print('DATA FETCHED: $rows');
    if (rows.isEmpty) {
      print('WARNING: No data returned');
    }
    return rows;
  }

  Future<void> createProfile({
    required String userId,
    required String email,
    required String role,
    required String fullName,
  }) async {
    final cleanRole = role.trim().toUpperCase();
    if (cleanRole != 'ADMIN' && cleanRole != 'STAFF') {
      throw ArgumentError('Role must be ADMIN or STAFF.');
    }

    await _service.insert('profiles', {
      'id': userId.trim(),
      'email': email.trim(),
      'role': cleanRole,
      'full_name': fullName.trim(),
    });
  }

  Future<void> registerUserAsAdmin({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    final auth = _service.client.auth;
    final previousSession = auth.currentSession;
    final previousUserId = auth.currentUser?.id;

    final response = await auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
      },
    );

    final createdUser = response.user;
    if (createdUser == null) {
      throw const AuthException('Failed to create auth user.');
    }

    await createProfile(
      userId: createdUser.id,
      email: email,
      role: role,
      fullName: fullName,
    );

    // Keep admin session active after creating another account.
    final refreshToken = previousSession?.refreshToken;
    final currentUserId = auth.currentUser?.id;
    if (refreshToken != null && previousUserId != null && currentUserId != previousUserId) {
      try {
        await auth.setSession(refreshToken);
      } catch (e) {
        print('Failed to restore admin session: $e');
      }
    }
  }
}

