// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final data = await client
        .from('audit_logs')
        .select('''
action,
module,
created_at,
profiles(full_name)
''')
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<Map<String, dynamic>?> getClinicInfo() async {
    final data = await client.from('clinic_info').select().limit(1).maybeSingle();
    if (data == null) return null;
    return (data as Map).cast<String, dynamic>();
  }

  Future<void> updateClinicInfo(Map<String, dynamic> data) async {
    await client
        .from('clinic_info')
        .update(data)
        .neq('id', '00000000-0000-0000-0000-000000000000');
  }
}
