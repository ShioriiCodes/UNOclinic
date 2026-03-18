// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class CertificateRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCertificates() async {
    final data = await client
        .from('health_certificates')
        .select('''
id,
created_at,
status,
request_date,
released_date,
purpose,
patient_id,
patients(first_name, last_name)
''')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    print('CERTIFICATES FETCHED: $data');
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<void> createCertificate(Map<String, dynamic> data) async {
    final payload = <String, dynamic>{...data};
    final patientId = (payload['patient_id'] ?? '').toString();
    final status = (payload['status'] ?? 'PENDING').toString().toUpperCase();

    if (patientId.isNotEmpty) {
      final existingPending = await client
          .from('health_certificates')
          .select('id')
          .eq('patient_id', patientId)
          .isFilter('deleted_at', null)
          .inFilter('status', ['PENDING', 'Pending'])
          .limit(1) as List<dynamic>;
      if (existingPending.isNotEmpty) {
        throw Exception('This patient already has a pending certificate request.');
      }
    }

    payload['status'] = status;
    payload['request_date'] =
        payload['request_date'] ?? DateTime.now().toIso8601String();

    final res = await client.from('health_certificates').insert(payload);
    print('CERTIFICATE CREATED: $res');
  }

  Future<void> updateStatus(String id, String status) async {
    final normalizedStatus = status.toUpperCase();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final updateData = <String, dynamic>{
      'status': normalizedStatus,
      if (normalizedStatus == 'RELEASED')
        'released_date': DateTime.now().toIso8601String(),
      if (normalizedStatus == 'APPROVED' && userId != null) 'approved_by': userId,
    };

    final res = await client.from('health_certificates').update(updateData).eq('id', id);
    print('STATUS UPDATED: $res');
  }

  Future<void> deleteCertificate(String id) async {
    final now = DateTime.now().toIso8601String();
    final res = await client
        .from('health_certificates')
        .update({'deleted_at': now, 'updated_at': now})
        .eq('id', id);
    print('CERTIFICATE DELETED: $res');
  }
}
