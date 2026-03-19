import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../../utils/breakpoints.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_table.dart';
import '../../models/inventory_models.dart';
import '../../repositories/inventory_repository.dart';
import 'inventory_drawers.dart';

/// Inventory page: tabs Items, Batches, Transactions, Alerts. Row click opens drawer.
class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryRepository _repo = InventoryRepository();
  bool _loading = false;
  List<InventoryItem> _items = const [];
  List<InventoryBatch> _batches = const [];
  List<InventoryTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _repo.getItems(),
        _repo.getBatches(),
        _repo.getTransactions(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = List<InventoryItem>.from(results[0] as List<dynamic>);
        _batches = List<InventoryBatch>.from(results[1] as List<dynamic>);
        _transactions = List<InventoryTransaction>.from(results[2] as List<dynamic>);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load inventory data.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inventory',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SectionCard(
              padding: const EdgeInsets.all(24),
              expandChild: true,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Items'),
                    Tab(text: 'Batches (Expiry)'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Alerts'),
                  ],
                  isScrollable: true,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _itemsTab(),
                      _batchesTab(),
                      _transactionsTab(),
                      _alertsTab(),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No inventory items found.'));
    }
    return AppTable<InventoryItem>(
      columns: const [
        AppTableColumn('name', 'Name', width: 220),
        AppTableColumn('category', 'Category', width: 120),
        AppTableColumn('totalStock', 'Total stock', width: 100),
        AppTableColumn('threshold', 'Threshold', width: 100),
      ],
      rows: _items,
      cellBuilder: (row, key) {
        switch (key) {
          case 'name':
            return Text(row.name ?? '-');
          case 'category':
            return Text(row.category ?? '-');
          case 'totalStock':
            return Text('${row.totalStock ?? 0}');
          case 'threshold':
            return Text('${row.threshold ?? 0}');
          default:
            return const SizedBox.shrink();
        }
      },
      onRowTap: (row) => widget.onOpenDrawer(
        ItemDrawer(item: row, onClose: () => widget.onOpenDrawer(null)),
      ),
    );
  }

  Widget _batchesTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_batches.isEmpty) {
      return const Center(child: Text('No inventory batches found.'));
    }
    return AppTable<InventoryBatch>(
      columns: const [
        AppTableColumn('itemName', 'Item', width: 200),
        AppTableColumn('batchNo', 'Batch no', width: 120),
        AppTableColumn('expiryDate', 'Expiry date', width: 120),
        AppTableColumn('qty', 'Qty available', width: 100),
        AppTableColumn('status', 'Status', width: 100),
      ],
      rows: _batches,
      cellBuilder: (row, key) {
        switch (key) {
          case 'itemName':
            return Text(row.itemName ?? 'Unknown');
          case 'batchNo':
            return Text(row.batchNo ?? '-');
          case 'expiryDate':
            return Text(Formatters.date(row.expiryDate));
          case 'qty':
            return Text('${row.qtyAvailable ?? 0}');
          case 'status':
            return Text(row.status ?? '-');
          default:
            return const SizedBox.shrink();
        }
      },
      onRowTap: (row) => widget.onOpenDrawer(
        BatchDrawer(batch: row, onClose: () => widget.onOpenDrawer(null)),
      ),
    );
  }

  Widget _transactionsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return const Center(child: Text('No inventory transactions found.'));
    }
    return AppTable<InventoryTransaction>(
      columns: const [
        AppTableColumn('date', 'Date', width: 140),
        AppTableColumn('itemName', 'Item', width: 200),
        AppTableColumn('type', 'Type', width: 100),
        AppTableColumn('qty', 'Qty', width: 80),
        AppTableColumn('notes', 'Notes', width: 180),
      ],
      rows: _transactions,
      cellBuilder: (row, key) {
        switch (key) {
          case 'date':
            return Text(Formatters.dateTime(row.date));
          case 'itemName':
            return Text(row.itemName ?? 'Unknown');
          case 'type':
            return Text(row.type ?? '-');
          case 'qty':
            return Text('${row.qty ?? 0}');
          case 'notes':
            return Text(row.notes ?? '-');
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _alertsTab() {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final lowStock = _items
        .where((i) => (i.totalStock ?? 0) <= (i.threshold ?? 0))
        .toList();
    final nearExpiry = _batches.where((b) {
      if (b.expiryDate == null) return false;
      final days = b.expiryDate!.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 30;
    }).toList();
    final expired = _batches.where((b) {
      if (b.expiryDate == null) return false;
      return b.expiryDate!.isBefore(DateTime.now());
    }).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (lowStock.isNotEmpty) ...[
          Text('Low stock', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...lowStock.map((i) => ListTile(
                title: Text(i.name ?? 'Item'),
                subtitle: Text('${i.totalStock ?? 0} left (threshold ${i.threshold ?? 0})'),
                onTap: () => widget.onOpenDrawer(
                  ItemDrawer(item: i, onClose: () => widget.onOpenDrawer(null)),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (nearExpiry.isNotEmpty) ...[
          Text('Near expiry (30 days)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...nearExpiry.map((b) => ListTile(
                title: Text(b.itemName ?? 'Unknown'),
                subtitle: Text('${b.batchNo ?? '-'} - ${Formatters.date(b.expiryDate)}'),
                onTap: () => widget.onOpenDrawer(
                  BatchDrawer(batch: b, onClose: () => widget.onOpenDrawer(null)),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (expired.isNotEmpty) ...[
          Text('Expired', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...expired.map((b) => ListTile(
                title: Text(b.itemName ?? 'Unknown'),
                subtitle: Text('${b.batchNo ?? '-'} - ${Formatters.date(b.expiryDate)}'),
                onTap: () => widget.onOpenDrawer(
                  BatchDrawer(batch: b, onClose: () => widget.onOpenDrawer(null)),
                ),
              )),
        ],
      ],
    );
  }
}
