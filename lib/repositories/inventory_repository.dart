// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/inventory_models.dart';

class InventoryRepository {
  InventoryRepository({SupabaseClient? client})
      : _service = SupabaseService(client: client ?? Supabase.instance.client);

  final SupabaseService _service;

  Future<List<InventoryItem>> getItems() async {
    final rows = await _service.select(
      'inventory_items',
      orderBy: 'created_at',
      ascending: false,
    );
    final data = rows.map(InventoryItem.fromMap).toList();
    print('DATA FETCHED: $data');
    if (data.isEmpty) {
      print('WARNING: No data returned');
    }
    return data;
  }

  Future<List<InventoryBatch>> getBatches() async {
    print('QUERY -> table: inventory_batches');
    final rows = await _service.client
        .from('inventory_batches')
        .select('''
          *,
          inventory_items(name)
        ''')
        .isFilter('deleted_at', null)
        .order('expiry_date', ascending: true) as List<dynamic>;
    print('RESULT -> $rows');
    final data = rows
        .map((e) => InventoryBatch.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
    print('DATA FETCHED: $data');
    if (data.isEmpty) {
      print('WARNING: No data returned');
    }
    return data;
  }

  Future<List<InventoryTransaction>> getTransactions() async {
    print('QUERY -> table: inventory_transactions');
    final rows = await _service.client
        .from('inventory_transactions')
        .select('''
          *,
          inventory_items(name)
        ''')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false) as List<dynamic>;
    print('RESULT -> $rows');
    final data = rows
        .map((e) => InventoryTransaction.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
    print('DATA FETCHED: $data');
    if (data.isEmpty) {
      print('WARNING: No data returned');
    }
    return data;
  }

  Future<void> createItem(Map<String, dynamic> data) async {
    await _service.insert('inventory_items', data);
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _service.update('inventory_items', data, id);
  }

  Future<void> deleteItem(String id) async {
    await _service.delete('inventory_items', id);
  }
}

