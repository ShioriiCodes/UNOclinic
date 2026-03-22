// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRepository {
  final SupabaseClient client = Supabase.instance.client;

  // GET ITEMS WITH TOTAL STOCK (SUM OF BATCHES)
  Future<List<Map<String, dynamic>>> getItems() async {
    final items = await client
        .from('inventory_items')
        .select()
        .isFilter('deleted_at', null);

    final batches = await client
        .from('inventory_batches')
        .select('item_id, quantity')
        .isFilter('deleted_at', null);

    final itemRows = List<Map<String, dynamic>>.from(
      (items as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
    final batchRows = List<Map<String, dynamic>>.from(
      (batches as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );

    // Calculate total stock from inventory_batches only.
    for (final item in itemRows) {
      final itemId = item['id'];
      final total = batchRows
          .where((b) => b['item_id'] == itemId)
          .fold<int>(0, (sum, b) => sum + _asInt(b['quantity']));
      item['total_stock'] = total;
    }

    return itemRows;
  }

  // CREATE ITEM
  Future<void> createItem(Map<String, dynamic> data) async {
    await client.from('inventory_items').insert(data);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final data = await client
        .from('inventory_transactions')
        .select('''
type,
quantity,
reference,
created_at,
inventory_items(name)
''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<List<Map<String, dynamic>>> getBatches() async {
    final data = await client
        .from('inventory_batches')
        .select('''
id,
quantity,
expiry_date,
created_at,
inventory_items(name)
''')
        .order('expiry_date', ascending: true);

    return List<Map<String, dynamic>>.from(
      (data as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    final List<Map<String, dynamic>> alerts = [];

    // 1. GET ITEMS + BATCHES (active rows only)
    final itemsRaw = await client
        .from('inventory_items')
        .select('id,name,minimum_stock')
        .isFilter('deleted_at', null);
    final batchesRaw = await client
        .from('inventory_batches')
        .select('item_id,quantity')
        .isFilter('deleted_at', null);

    final items = List<Map<String, dynamic>>.from(
      (itemsRaw as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );
    final batches = List<Map<String, dynamic>>.from(
      (batchesRaw as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );

    // 2. LOW STOCK CHECK
    for (final item in items) {
      final itemId = item['id'];
      final total = batches
          .where((b) => b['item_id'] == itemId)
          .fold<int>(0, (sum, b) => sum + _asInt(b['quantity']));

      if (total < _asInt(item['minimum_stock'])) {
        alerts.add({
          'type': 'LOW_STOCK',
          'message': '${item['name']} is low on stock ($total left)',
        });
      }
    }

    // 3. NEAR EXPIRY CHECK (today to next 30 days)
    final now = DateTime.now();
    final next30 = now.add(const Duration(days: 30));
    final nearExpiryRows = await client
        .from('inventory_batches')
        .select('id,expiry_date,inventory_items(name)')
        .isFilter('deleted_at', null)
        .gte('expiry_date', _dateOnly(now))
        .lte('expiry_date', _dateOnly(next30))
        .order('expiry_date', ascending: true)
        .limit(50);

    final nearExpiry = List<Map<String, dynamic>>.from(
      (nearExpiryRows as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );

    for (final row in nearExpiry) {
      final join = row['inventory_items'];
      final itemName = join is Map
          ? (join['name'] ?? 'Item').toString()
          : join is List && join.isNotEmpty && join.first is Map
          ? ((join.first as Map)['name'] ?? 'Item').toString()
          : 'Item';
      alerts.add({
        'type': 'EXPIRY',
        'message': '$itemName expiring soon',
      });
    }

    return alerts;
  }

  // CREATE BATCH (RECEIVE STOCK)
  Future<void> receiveStock({
    required String itemId,
    required int quantity,
    required DateTime expiryDate,
  }) async {
    final batch = await client
        .from('inventory_batches')
        .insert({
          'item_id': itemId,
          'quantity': quantity,
          'expiry_date': expiryDate.toIso8601String().split('T').first,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    // LOG TRANSACTION (IN)
    await client.from('inventory_transactions').insert({
      'item_id': itemId,
      'batch_id': batch['id'],
      'type': 'IN',
      'quantity': quantity,
      'reference': 'Stock received',
      'created_at': DateTime.now().toIso8601String(),
    });

    print('STOCK RECEIVED: $quantity');
  }

  Future<int> getTotalStock(String itemId) async {
    final id = itemId.trim();
    if (id.isEmpty) return 0;

    final rows = await client
        .from('inventory_batches')
        .select('quantity')
        .eq('item_id', id)
        .isFilter('deleted_at', null);

    final batches = List<Map<String, dynamic>>.from(
      (rows as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );

    return batches.fold<int>(0, (sum, b) => sum + _asInt(b['quantity']));
  }

  Future<void> dispenseItemFIFO({
    required String itemId,
    required int quantity,
  }) async {
    final id = itemId.trim();
    if (id.isEmpty) {
      throw Exception('Invalid item.');
    }
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than zero.');
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AuthException('User not authenticated.');
    }

    final rows = await client
        .from('inventory_batches')
        .select('id,item_id,quantity,expiry_date')
        .eq('item_id', id)
        .isFilter('deleted_at', null)
        .gt('quantity', 0);

    final batches = List<Map<String, dynamic>>.from(
      (rows as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()),
    );

    if (batches.isEmpty) {
      throw Exception('No available stock batches found.');
    }

    // FIFO by earliest expiry date first.
    batches.sort((a, b) {
      final aDate = _parseDate(a['expiry_date']) ?? DateTime(9999, 12, 31);
      final bDate = _parseDate(b['expiry_date']) ?? DateTime(9999, 12, 31);
      return aDate.compareTo(bDate);
    });

    final totalStock = batches.fold<int>(0, (sum, b) => sum + _asInt(b['quantity']));
    if (totalStock < quantity) {
      throw Exception('Insufficient stock. Available: $totalStock, requested: $quantity.');
    }

    var remaining = quantity;
    for (final batch in batches) {
      if (remaining <= 0) break;

      final batchId = (batch['id'] ?? '').toString();
      if (batchId.isEmpty) continue;

      final currentQty = _asInt(batch['quantity']);
      if (currentQty <= 0) continue;

      final deductQty = remaining > currentQty ? currentQty : remaining;
      final newQty = currentQty - deductQty;

      await client
          .from('inventory_batches')
          .update({'quantity': newQty})
          .eq('id', batchId);

      await client.from('inventory_transactions').insert({
        'item_id': id,
        'batch_id': batchId,
        'type': 'OUT',
        'quantity': deductQty,
        'created_by': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      remaining -= deductQty;
    }

    if (remaining > 0) {
      throw Exception('Dispense failed. Remaining quantity: $remaining.');
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
