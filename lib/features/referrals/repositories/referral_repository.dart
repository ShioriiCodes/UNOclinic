// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class ReferralRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getReferrals() async {
    final data = await client
        .from('referrals')
        .select('''
id,
referred_to,
reason,
status,
follow_up_notes,
referral_date,
follow_up_due,
patient_id,
patients(first_name, last_name)
''')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    print('REFERRALS FETCHED: $data');
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<void> createReferral(Map<String, dynamic> data) async {
    final res = await client.from('referrals').insert(data);
    print('REFERRAL CREATED: $res');
  }

  Future<void> updateStatus(String id, String status) async {
    final updateData = <String, dynamic>{
      'status': status,
      if (status == 'COMPLETED') 'completed_date': DateTime.now().toIso8601String(),
    };

    final res = await client.from('referrals').update(updateData).eq('id', id);
    print('REFERRAL UPDATED: $res');
  }

  Future<void> updateNotes(String id, String notes) async {
    final res = await client
        .from('referrals')
        .update({'follow_up_notes': notes})
        .eq('id', id);

    print('NOTES UPDATED: $res');
  }
}
