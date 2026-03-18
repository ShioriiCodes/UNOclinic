import 'package:flutter/material.dart';

import '../../widgets/details_drawer.dart';
import '../../models/inventory_models.dart';
import '../../utils/formatters.dart';

/// Drawer for an inventory item. Actions: Receive Stock, Dispense, Adjust (UI only).
class ItemDrawer extends StatelessWidget {
  const ItemDrawer({
    super.key,
    required this.item,
    required this.onClose,
  });

  final InventoryItem item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DetailsDrawer(
      title: item.name ?? 'Item',
      onClose: onClose,
      actions: [
        FilledButton.icon(
          onPressed: () {}, // UI only — Receive Stock
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Receive Stock'),
        ),
        OutlinedButton.icon(
          onPressed: () {}, // UI only — Dispense
          icon: const Icon(Icons.remove_rounded, size: 18),
          label: const Text('Dispense'),
        ),
        OutlinedButton.icon(
          onPressed: () {}, // UI only — Adjust
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Adjust'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Category', item.category ?? '—'),
          _row('Total stock', '${item.totalStock ?? 0}'),
          _row('Threshold', '${item.threshold ?? 0}'),
          _row('Status', (item.totalStock ?? 0) <= (item.threshold ?? 0) ? 'Low stock' : 'OK'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Drawer for a batch. Same actions as item (UI only).
class BatchDrawer extends StatelessWidget {
  const BatchDrawer({
    super.key,
    required this.batch,
    required this.onClose,
  });

  final InventoryBatch batch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DetailsDrawer(
      title: 'Batch ${batch.batchNo ?? '—'}',
      onClose: onClose,
      actions: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Receive Stock'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.remove_rounded, size: 18),
          label: const Text('Dispense'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Adjust'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Item', batch.itemName ?? 'Unknown'),
          _row('Batch no', batch.batchNo ?? '—'),
          _row('Expiry date', Formatters.date(batch.expiryDate)),
          _row('Qty available', '${batch.qtyAvailable ?? 0}'),
          _row('Status', batch.status ?? '—'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
