// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUsers() async {
    final data = await client
        .from('profiles')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    print('USERS FETCHED: $data');
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<void> createUserProfile(Map<String, dynamic> data) async {
    final res = await client.from('profiles').insert(data);
    print('USER PROFILE CREATED: $res');
  }

  Future<void> createUserWithPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final auth = client.auth;
    final previousSession = auth.currentSession;
    final previousUserId = auth.currentUser?.id;

    final response = await auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    final createdUser = response.user;
    if (createdUser == null) {
      throw const AuthException('Failed to create auth user.');
    }

    await createUserProfile({
      'id': createdUser.id,
      'email': email.trim(),
      'full_name': fullName.trim(),
      'role': role.trim().toUpperCase(),
    });

    // Keep current admin session active after creating another account.
    final refreshToken = previousSession?.refreshToken;
    final currentUserId = auth.currentUser?.id;
    if (refreshToken != null &&
        previousUserId != null &&
        currentUserId != previousUserId) {
      try {
        await auth.setSession(refreshToken);
      } catch (e) {
        print('Failed to restore admin session: $e');
      }
    }
  }

  Future<void> updateRole(String id, String role) async {
    final res = await client.from('profiles').update({'role': role}).eq('id', id);
    print('ROLE UPDATED: $res');
  }

  Future<void> deleteUser(String id) async {
    final res = await client.from('profiles').delete().eq('id', id);
    print('USER DELETED: $res');
  }
}
