// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../models/activity_model.dart';

class DashboardRepository {
  DashboardRepository({SupabaseClient? client})
      : _service = SupabaseService(client: client ?? Supabase.instance.client);

  final SupabaseService _service;

  Future<int> getTodayVisits() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    print('QUERY -> table: visits');
    final rows = await _service.client
        .from('visits')
        .select('id')
        .isFilter('deleted_at', null)
        .gte('visit_date', start.toIso8601String())
        .lt('visit_date', end.toIso8601String()) as List<dynamic>;
    print('RESULT -> $rows');
    print('DATA FETCHED: $rows');
    if (rows.isEmpty) {
      print('WARNING: No data returned');
    }

    return rows.length;
  }

  Future<int> getPendingCertificates() async {
    print('QUERY -> table: health_certificates');
    final rows = await _service.client
        .from('health_certificates')
        .select('id')
        .isFilter('deleted_at', null)
        .inFilter('status', ['PENDING', 'Pending']) as List<dynamic>;
    print('RESULT -> $rows');
    print('DATA FETCHED: $rows');
    if (rows.isEmpty) {
      print('WARNING: No data returned');
    }

    return rows.length;
  }

  Future<int> getPendingReferrals() async {
    print('QUERY -> table: referrals');
    final rows = await _service.client
        .from('referrals')
        .select('id')
        .isFilter('deleted_at', null)
        .inFilter('status', ['PENDING', 'Pending']) as List<dynamic>;
    print('RESULT -> $rows');
    print('DATA FETCHED: $rows');
    if (rows.isEmpty) {
      print('WARNING: No data returned');
    }

    return rows.length;
  }

  Future<int> getLowStockItems() async {
    final items = await _service.select(
      'inventory_items',
      columns: 'id, name, minimum_stock',
      orderBy: 'created_at',
      ascending: false,
      limit: 200,
    );

    final batches = await _service.select(
      'inventory_batches',
      columns: 'item_id, quantity',
      orderBy: 'created_at',
      ascending: false,
      limit: 500,
    );

    final quantityByItem = <String, int>{};
    for (final row in batches) {
      final itemId = (row['item_id'] ?? '').toString();
      if (itemId.isEmpty) continue;
      final qty = _asInt(row['quantity']);
      quantityByItem[itemId] = (quantityByItem[itemId] ?? 0) + qty;
    }

    var count = 0;
    for (final item in items) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final currentQty = quantityByItem[id] ?? 0;
      final minimumStock = _asInt(item['minimum_stock']);
      if (currentQty < minimumStock) {
        count++;
      }
    }
    return count;
  }

  Future<int> getNearExpiryItems() async {
    final now = DateTime.now();
    final in30 = now.add(const Duration(days: 30));

    print('QUERY -> table: inventory_batches');
    final rows = await _service.client
        .from('inventory_batches')
        .select('id')
        .isFilter('deleted_at', null)
        .gte('expiry_date', _dateOnly(now))
        .lte('expiry_date', _dateOnly(in30)) as List<dynamic>;
    print('RESULT -> $rows');
    print('DATA FETCHED: $rows');
    if (rows.isEmpty) {
      print('WARNING: No data returned');
    }

    return rows.length;
  }

  Future<List<ActivityModel>> getRecentActivities() async {
    print('QUERY -> table: visits');
    final visits = await _service.client
        .from('visits')
        .select('''
          id,
          visit_date,
          patients(first_name,last_name)
        ''')
        .isFilter('deleted_at', null)
        .order('visit_date', ascending: false)
        .limit(5) as List<dynamic>;
    print('RESULT -> $visits');

    print('QUERY -> table: health_certificates');
    final certificates = await _service.client
        .from('health_certificates')
        .select('''
          id,
          request_date,
          created_at,
          status,
          patients(first_name,last_name)
        ''')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(5) as List<dynamic>;
    print('RESULT -> $certificates');

    print('QUERY -> table: referrals');
    final referrals = await _service.client
        .from('referrals')
        .select('''
          id,
          created_at,
          patients(first_name,last_name)
        ''')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(5) as List<dynamic>;
    print('RESULT -> $referrals');

    final activities = <ActivityModel>[];

    for (final row in visits) {
      final m = (row as Map).cast<String, dynamic>();
      final name = _patientNameFromJoin(m['patients']);
      final date = _parseDateTime(m['visit_date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      activities.add(
        ActivityModel(
          title: 'New Visit',
          subtitle: name,
          date: date,
        ),
      );
    }

    for (final row in certificates) {
      final m = (row as Map).cast<String, dynamic>();
      final name = _patientNameFromJoin(m['patients']);
      final status = (m['status'] ?? 'PENDING').toString();
      final date =
          _parseDateTime(m['request_date'] ?? m['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      activities.add(
        ActivityModel(
          title: 'Certificate $status',
          subtitle: name,
          date: date,
        ),
      );
    }

    for (final row in referrals) {
      final m = (row as Map).cast<String, dynamic>();
      final name = _patientNameFromJoin(m['patients']);
      final date = _parseDateTime(m['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      activities.add(
        ActivityModel(
          title: 'New Referral',
          subtitle: name,
          date: date,
        ),
      );
    }

    final deduped = <ActivityModel>[];
    final seenKeys = <String>{};
    for (final a in activities) {
      final key = '${a.title}|${a.subtitle}|${a.date.toIso8601String()}';
      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);
      deduped.add(a);
    }

    deduped.sort((a, b) => b.date.compareTo(a.date));
    print('DATA FETCHED: $activities');
    if (deduped.isEmpty) {
      print('WARNING: No data returned');
    }
    return deduped.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    final alerts = <Map<String, dynamic>>[];

    final items = await _service.select(
      'inventory_items',
      columns: 'id, name, minimum_stock',
      orderBy: 'created_at',
      ascending: false,
      limit: 200,
    );

    final batches = await _service.select(
      'inventory_batches',
      columns: 'item_id, quantity',
      orderBy: 'created_at',
      ascending: false,
      limit: 500,
    );

    final quantityByItem = <String, int>{};
    for (final row in batches) {
      final itemId = (row['item_id'] ?? '').toString();
      if (itemId.isEmpty) continue;
      quantityByItem[itemId] = (quantityByItem[itemId] ?? 0) + _asInt(row['quantity']);
    }

    for (final item in items) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final qty = quantityByItem[id] ?? 0;
      final minimumStock = _asInt(item['minimum_stock']);
      if (qty >= minimumStock) continue;
      alerts.add({
        'id': 'low_$id',
        'severity': 'medium',
        'title': '${item['name'] ?? 'Item'} is low on stock',
        'message': '${item['name'] ?? 'Item'} is low on stock',
      });
    }

    final now = DateTime.now();
    final in30 = now.add(const Duration(days: 30));
    print('QUERY -> table: inventory_batches');
    final nearExpiryRows = await _service.client
        .from('inventory_batches')
        .select('id,expiry_date,inventory_items(name)')
        .isFilter('deleted_at', null)
        .gte('expiry_date', _dateOnly(now))
        .lte('expiry_date', _dateOnly(in30))
        .order('expiry_date', ascending: true)
        .limit(10) as List<dynamic>;
    print('RESULT -> $nearExpiryRows');

    for (final row in nearExpiryRows) {
      final m = (row as Map).cast<String, dynamic>();
      final item = m['inventory_items'];
      String itemName = 'Item';
      if (item is Map) {
        itemName = (item['name'] ?? 'Item').toString();
      }
      alerts.add({
        'id': 'exp_${m['id']}',
        'severity': 'high',
        'title': '$itemName is near expiry',
        'message': '$itemName is near expiry',
      });
    }

    print('DATA FETCHED: $alerts');
    if (alerts.isEmpty) {
      print('WARNING: No data returned');
    }
    return alerts;
  }

  static String _patientNameFromJoin(dynamic patients) {
    if (patients is List && patients.isNotEmpty) {
      return _patientNameFromMap(patients.first);
    }
    return _patientNameFromMap(patients);
  }

  static String _patientNameFromMap(dynamic patients) {
    if (patients is Map) {
      return getFullName(patients.cast<String, dynamic>());
    }
    return 'Unknown';
  }

  static String getFullName(Map<String, dynamic>? patient) {
    if (patient == null) return 'Unknown';
    final first = (patient['first_name'] ?? '').toString();
    final last = (patient['last_name'] ?? '').toString();
    final full = '$first $last'.trim();
    return full.isEmpty ? 'Unknown' : full;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

