// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/audit_helper.dart';

class PatientRepository {
  final SupabaseClient client = Supabase.instance.client;

  // GET ALL PATIENTS
  Future<List<Map<String, dynamic>>> getPatients() async {
    final data = await client
        .from('patients')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    print('PATIENTS FETCHED: $data');
    return List<Map<String, dynamic>>.from(data as List);
  }

  // CREATE PATIENT
  Future<void> createPatient(Map<String, dynamic> patient) async {
    final res = await client.from('patients').insert(patient).select();
    final createdRows = List<Map<String, dynamic>>.from(res as List<dynamic>);
    final createdId = (createdRows.isNotEmpty ? createdRows.first['id'] : null)
        ?.toString();
    await AuditHelper.log(
      action: 'Created patient',
      module: 'PATIENTS',
      referenceId: createdId,
    );
    print('PATIENT CREATED: $res');
  }

  // UPDATE PATIENT
  Future<void> updatePatient(String id, Map<String, dynamic> patient) async {
    final res = await client.from('patients').update(patient).eq('id', id).select();
    print('PATIENT UPDATED: $res');
  }

  // SOFT DELETE
  Future<void> deletePatient(String id) async {
    final res = await client.from('patients').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id).select();

    print('PATIENT DELETED: $res');
  }

  Future<Map<String, DateTime>> getLatestVisitMap(List<String> patientIds) async {
    final ids = patientIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) return const {};

    final data = await client
        .from('visits')
        .select('patient_id, visit_date')
        .isFilter('deleted_at', null)
        .inFilter('patient_id', ids)
        .order('visit_date', ascending: false);

    print('VISITS FETCHED: $data');

    final latest = <String, DateTime>{};
    for (final row in List<Map<String, dynamic>>.from(data as List)) {
      final patientId = (row['patient_id'] ?? '').toString();
      if (patientId.isEmpty) continue;
      final parsed = _parseDateTime(row['visit_date']);
      if (parsed == null) continue;
      final current = latest[patientId];
      if (current == null || parsed.isAfter(current)) {
        latest[patientId] = parsed;
      }
    }
    return latest;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

