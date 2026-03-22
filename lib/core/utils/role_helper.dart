import 'package:supabase_flutter/supabase_flutter.dart';

class RoleHelper {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<bool> isAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return false;

    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (row == null) return false;
    final role = (row as Map)['role']?.toString().toUpperCase() ?? 'STAFF';
    return role == 'ADMIN';
  }
}
