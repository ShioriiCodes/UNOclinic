// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_gate.dart';
import 'core/supabase/supabase_initializer.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseInitializer.ensureInitialized();
  print('SUPABASE URL: ${Supabase.instance.client.rest.url}');
  print('CURRENT USER: ${Supabase.instance.client.auth.currentUser}');

  runApp(const UnoClinicApp());
}

class UnoClinicApp extends StatelessWidget {
  const UnoClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNOclinic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
