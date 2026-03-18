// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class VisitRepository {
  final SupabaseClient client = Supabase.instance.client;

  // GET VISITS WITH PATIENT DATA
  Future<List<Map<String, dynamic>>> getVisits() async {
    final data = await client
        .from('visits')
        .select('''
          id,
          patient_id,
          visit_date,
          notes,
          assessment,
          treatment,
          vitals,
          staff_id,
          created_at,
          updated_at,
          deleted_at,
          patients(first_name, last_name),
          profiles(full_name)
        ''')
        .isFilter('deleted_at', null)
        .order('visit_date', ascending: false);

    print('VISITS FETCHED: $data');
    return List<Map<String, dynamic>>.from(data as List);
  }

  // CREATE VISIT
  Future<void> createVisit(Map<String, dynamic> visit) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AuthException('User not authenticated.');
    }

    final payload = Map<String, dynamic>.from(visit);
    payload['staff_id'] = userId;

    final res = await client.from('visits').insert(payload).select();
    print('VISIT CREATED: $res');
  }

  // UPDATE VISIT
  Future<void> updateVisit(String id, Map<String, dynamic> visit) async {
    final res = await client.from('visits').update(visit).eq('id', id).select();
    print('VISIT UPDATED: $res');
  }
}

