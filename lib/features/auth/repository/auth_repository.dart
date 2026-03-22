// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required.');
    }

    if (!cleanEmail.contains('@')) {
      throw const AuthException('Please enter a valid email address.');
    }

    try {
      print('Sending password reset email to: $cleanEmail');

      await _client.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: 'https://unoclinic.netlify.app/reset-password.html',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      print('Password reset error: $e');
      throw const AuthException('Failed to send reset email');
    }
  }
}
