// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getVisitsReport(
    DateTime? from,
    DateTime? to,
  ) async {
    dynamic query = client.from('visits').select('''
visit_date,
notes,
patients(first_name, last_name)
''');

    if (from != null) {
      query = query.gte('visit_date', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('visit_date', to.toIso8601String());
    }

    final data = await query.order('visit_date', ascending: false);
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<List<Map<String, dynamic>>> getCertificatesReport(
    DateTime? from,
    DateTime? to,
  ) async {
    dynamic query = client.from('health_certificates').select('''
status,
request_date,
released_date,
created_at,
updated_at,
patients(first_name, last_name)
''');

    if (from != null) {
      query = query.gte('request_date', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('request_date', to.toIso8601String());
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<List<Map<String, dynamic>>> getReferralsReport(
    DateTime? from,
    DateTime? to,
  ) async {
    dynamic query = client.from('referrals').select('''
referred_to,
status,
referral_date,
patients(first_name, last_name)
''');

    if (from != null) {
      query = query.gte('referral_date', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('referral_date', to.toIso8601String());
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<List<Map<String, dynamic>>> getInventoryReport() async {
    final data = await client.from('inventory_items').select();
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<List<Map<String, dynamic>>> getPatientDemographics() async {
    final data = await client
        .from('patients')
        .select()
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }
}
