class InventoryItem {
  const InventoryItem({
    required this.id,
    this.name,
    this.category,
    this.totalStock,
    this.threshold,
  });

  final String id;
  final String? name;
  final String? category;
  final int? totalStock;
  final int? threshold;

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return InventoryItem(
      id: (map['id'] ?? '').toString(),
      name: map['name']?.toString(),
      category: map['category']?.toString(),
      totalStock: toInt(map['total_stock'] ?? map['quantity'] ?? map['stock']),
      threshold: toInt(map['threshold']),
    );
  }
}

class InventoryBatch {
  const InventoryBatch({
    required this.id,
    this.itemId,
    this.itemName,
    this.batchNo,
    this.expiryDate,
    this.qtyAvailable,
    this.status,
  });

  final String id;
  final String? itemId;
  final String? itemName;
  final String? batchNo;
  final DateTime? expiryDate;
  final int? qtyAvailable;
  final String? status;

  factory InventoryBatch.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    String? itemNameFromJoin(dynamic value) {
      if (value is List && value.isNotEmpty) return itemNameFromJoin(value.first);
      if (value is Map) return value['name']?.toString();
      return null;
    }

    return InventoryBatch(
      id: (map['id'] ?? '').toString(),
      itemId: map['item_id']?.toString(),
      itemName: itemNameFromJoin(map['inventory_items']) ?? map['item_name']?.toString(),
      batchNo: map['batch_no']?.toString(),
      expiryDate: parseDate(map['expiry_date']),
      qtyAvailable: toInt(map['qty_available'] ?? map['quantity']),
      status: map['status']?.toString(),
    );
  }
}

class InventoryTransaction {
  const InventoryTransaction({
    required this.id,
    this.itemName,
    this.type,
    this.qty,
    this.date,
    this.notes,
  });

  final String id;
  final String? itemName;
  final String? type;
  final int? qty;
  final DateTime? date;
  final String? notes;

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    String? itemNameFromJoin(dynamic value) {
      if (value is List && value.isNotEmpty) return itemNameFromJoin(value.first);
      if (value is Map) return value['name']?.toString();
      return null;
    }

    return InventoryTransaction(
      id: (map['id'] ?? '').toString(),
      itemName: itemNameFromJoin(map['inventory_items']) ?? map['item_name']?.toString(),
      type: map['type']?.toString(),
      qty: toInt(map['qty'] ?? map['quantity']),
      date: parseDate(map['date'] ?? map['created_at']),
      notes: map['notes']?.toString(),
    );
  }
}

