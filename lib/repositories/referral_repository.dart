// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../core/utils/audit_helper.dart';
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
    final payload = <String, dynamic>{
      'patient_id': referral.patientId,
      'referred_to': referral.referredTo,
      'reason': referral.reason,
      'status': (referral.status ?? 'PENDING').toUpperCase(),
      'follow_up_notes': referral.followUpNotes,
      'referral_date':
          (referral.referralDate ?? DateTime.now()).toIso8601String(),
    };
    await _service.insert('referrals', payload);
    await AuditHelper.log(
      action: 'Created referral',
      module: 'REFERRALS',
      referenceId: referral.patientId,
    );
  }

  Future<void> updateReferral(Referral referral) async {
    final payload = <String, dynamic>{
      'patient_id': referral.patientId,
      'referred_to': referral.referredTo,
      'reason': referral.reason,
      'status': referral.status,
      'follow_up_notes': referral.followUpNotes,
      'referral_date': referral.referralDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _service.update('referrals', payload, referral.id);
  }

  Future<void> deleteReferral(String id) async {
    await _service.delete('referrals', id);
  }
}

