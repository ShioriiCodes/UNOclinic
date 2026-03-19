// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../core/utils/audit_helper.dart';
import '../models/visit.dart';

class VisitRepository {
  VisitRepository({SupabaseClient? client})
      : _service = SupabaseService(client: client ?? Supabase.instance.client);

  final SupabaseService _service;

  Future<List<Visit>> getVisits() async {
    print('QUERY -> table: visits');
    final rows = await _service.client
        .from('visits')
        .select('''
          *,
          patients(first_name, last_name),
          profiles(full_name)
        ''')
        .isFilter('deleted_at', null)
        .order('visit_date', ascending: false) as List<dynamic>;
    print('RESULT -> $rows');

    final data = rows
        .map((e) => Visit.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
    print('DATA FETCHED: $data');
    if (data.isEmpty) {
      print('WARNING: No data returned');
    }
    return data;
  }

  Future<void> createVisit(Visit visit) async {
    final userId = _service.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AuthException('User not authenticated.');
    }

    final payload = Map<String, dynamic>.from(visit.toMap())
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('deleted_at')
      ..['staff_id'] = userId;

    await _service.insert('visits', payload);
    await AuditHelper.log(
      action: 'Created visit',
      module: 'VISITS',
      referenceId: visit.patientId,
    );
  }

  Future<void> updateVisit(Visit visit) async {
    final payload = Map<String, dynamic>.from(visit.toMap())
      ..remove('created_at')
      ..remove('deleted_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _service.update('visits', payload, visit.id);
  }

  Future<void> deleteVisit(String id) async {
    await _service.delete('visits', id);
  }
}

