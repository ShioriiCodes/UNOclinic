// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/health_certificate.dart';
import '../utils/patient_name.dart';

class HealthCertificateRepository {
  HealthCertificateRepository({SupabaseClient? client})
      : _service = SupabaseService(client: client ?? Supabase.instance.client);

  final SupabaseService _service;

  Future<List<HealthCertificate>> getCertificates() async {
    print('QUERY -> table: health_certificates');
    final rows = await _service.client
        .from('health_certificates')
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
      return HealthCertificate.fromMap({
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

  Future<void> createCertificate(HealthCertificate certificate) async {
    final payload = Map<String, dynamic>.from(certificate.toMap())..remove('id');
    final patientId = (payload['patient_id'] ?? '').toString();
    if (patientId.isNotEmpty) {
      final existingPending = await _service.client
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

    payload['status'] = (payload['status'] ?? 'PENDING').toString().toUpperCase();
    payload['request_date'] = payload['request_date'] ?? DateTime.now().toIso8601String();
    await _service.insert('health_certificates', payload);
  }

  Future<void> updateCertificate(HealthCertificate certificate) async {
    final payload = Map<String, dynamic>.from(certificate.toMap())
      ..remove('id')
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _service.update('health_certificates', payload, certificate.id);
  }

  Future<void> deleteCertificate(String id) async {
    await _service.delete('health_certificates', id);
  }
}

