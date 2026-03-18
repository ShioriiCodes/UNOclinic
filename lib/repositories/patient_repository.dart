// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/patient.dart';

class PatientRepository {
  PatientRepository({SupabaseClient? client})
      : _service = SupabaseService(client: client ?? Supabase.instance.client);

  final SupabaseService _service;

  Future<List<Patient>> getPatients() async {
    final rows = await _service.select(
      'patients',
      orderBy: 'created_at',
      ascending: false,
    );

    final data = rows.map(Patient.fromMap).toList();
    print('DATA FETCHED: $data');
    if (data.isEmpty) {
      print('WARNING: No data returned');
    }
    return data;
  }

  Future<void> createPatient(Patient patient) async {
    final payload = Map<String, dynamic>.from(patient.toMap())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('deleted_at');

    await _service.insert('patients', payload);
  }

  Future<void> updatePatient(Patient patient) async {
    final payload = Map<String, dynamic>.from(patient.toMap())
      ..remove('created_at')
      ..remove('deleted_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _service.update('patients', payload, patient.id);
  }

  Future<void> deletePatient(String id) async {
    await _service.delete('patients', id);
  }

  Future<Map<String, DateTime>> getLatestVisitMap(List<String> patientIds) async {
    final ids = patientIds.where((e) => e.trim().isNotEmpty).toList();
    if (ids.isEmpty) return const {};

    print('QUERY -> table: visits');
    final rows = await _service.client
        .from('visits')
        .select('patient_id,visit_date')
        .isFilter('deleted_at', null)
        .inFilter('patient_id', ids)
        .order('visit_date', ascending: false) as List<dynamic>;
    print('RESULT -> $rows');
    print('DATA FETCHED: $rows');
    if (rows.isEmpty) {
      print('WARNING: No data returned');
    }

    final latest = <String, DateTime>{};
    for (final row in rows) {
      final map = (row as Map).cast<String, dynamic>();
      final patientId = (map['patient_id'] ?? '').toString();
      if (patientId.isEmpty) continue;
      final visitDate = _parseDateTime(map['visit_date']);
      if (visitDate == null) continue;
      final current = latest[patientId];
      if (current == null || visitDate.isAfter(current)) {
        latest[patientId] = visitDate;
      }
    }
    return latest;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

