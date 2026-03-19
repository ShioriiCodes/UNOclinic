// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class AuditHelper {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> log({
    required String action,
    required String module,
    String? referenceId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('audit_logs').insert({
        'user_id': user.id,
        'action': action,
        'module': module,
        'reference_id': referenceId,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('AUDIT LOG SAVED: $action');
    } catch (e) {
      print('AUDIT ERROR: $e');
    }
  }
}
