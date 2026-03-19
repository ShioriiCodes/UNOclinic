// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    String? orderBy,
    bool ascending = false,
    int? limit,
    Map<String, dynamic>? equals,
    bool includeDeleted = false,
  }) async {
    print('QUERY -> SELECT table: $table');
    dynamic query = _client.from(table).select(columns);

    if (!includeDeleted) {
      query = query.isFilter('deleted_at', null);
    }

    if (equals != null) {
      for (final entry in equals.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      query = query.order(orderBy, ascending: ascending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    print('RESULT -> $response');

    final rows = (response as List<dynamic>)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    print('DATA FETCHED: $rows');
    if (rows.isEmpty) {
      print('WARNING: No data returned');
    }
    return rows;
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    print('QUERY -> INSERT table: $table');
    print('PAYLOAD -> $data');
    final response = await _client.from(table).insert(data).select();
    print('RESULT -> $response');
    print('DATA FETCHED: $response');
  }

  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    print('QUERY -> UPDATE table: $table id: $id');
    print('PAYLOAD -> $data');
    final response = await _client.from(table).update(data).eq('id', id).select();
    print('RESULT -> $response');
    print('DATA FETCHED: $response');
  }

  Future<void> delete(String table, String id) async {
    print('QUERY -> HARD DELETE table: $table id: $id');
    final response = await _client.from(table).delete().eq('id', id).select();
    print('RESULT -> $response');
    print('DATA FETCHED: $response');
  }
}

