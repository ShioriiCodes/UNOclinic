// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/referral.dart';
import '../utils/patient_name.dart';

class ReferralRepository {
  ReferralRepository({SupabaseClient? client})
      : _service = SupabaseService(client: client ?? Supabase.instance.client);

  final SupabaseService _service;

  Future<List<Referral>> getReferrals() async {
    print('QUERY -> table: referrals');
    final rows = await _service.client
        .from('referrals')
        .select('''
          *,
          patients(first_name, last_name)
        ''')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false) as List<dynamic>;
    print('RESULT -> $rows');

    final data = rows.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      final patientMap = m['patients'];
      final patientName = patientMap is Map<String, dynamic>
          ? getFullName(patientMap)
          : patientMap is Map
              ? getFullName(patientMap.cast<String, dynamic>())
              : 'Unknown';
      return Referral.fromMap({
        ...m,
        'patient_name': patientName,
      });
    }).toList();
    print('DATA FETCHED: $data');
    if (data.isEmpty) {
      print('WARNING: No data returned');
    }
    return data;
  }

  Future<void> createReferral(Referral referral) async {
    final payload = Map<String, dynamic>.from(referral.toMap())
      ..remove('id')
      ..remove('referral_date');
    await _service.insert('referrals', payload);
  }

  Future<void> updateReferral(Referral referral) async {
    final payload = Map<String, dynamic>.from(referral.toMap())
      ..remove('id')
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _service.update('referrals', payload, referral.id);
  }

  Future<void> deleteReferral(String id) async {
    await _service.delete('referrals', id);
  }
}

