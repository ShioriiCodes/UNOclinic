import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../pages/login_page.dart';
import '../../shell/app_shell.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';

/// Decides which screen to show based on Supabase auth session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    // If Supabase isn't initialized yet (e.g. widget tests), fall back to LoginPage.
    _authStream = _safeAuthStream();
  }

  Stream<AuthState> _safeAuthStream() {
    try {
      return Supabase.instance.client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final Session? session;
        try {
          session = Supabase.instance.client.auth.currentSession;
        } catch (_) {
          return const LoginPage();
        }
        if (session == null) return const LoginPage();
        return FutureBuilder<UserProfile>(
          future: _loadProfile(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return const LoginPage();
            }
            return AppShell(profile: snap.data!);
          },
        );
      },
    );
  }

  Future<UserProfile> _loadProfile() async {
    final repo = ProfileRepository();
    final map = await repo.getCurrentUserProfile();
    if (map == null) {
      // Safe fallback: default to STAFF restrictions if profile is missing.
      final user = Supabase.instance.client.auth.currentUser;
      return UserProfile(
        id: user?.id ?? '',
        email: user?.email ?? '',
        role: 'STAFF',
        fullName: null,
      );
    }
    final role = (map['role'] ?? 'STAFF').toString();
    return UserProfile.fromMap({
      ...map,
      'role': role.isEmpty ? 'STAFF' : role,
    });
  }
}

