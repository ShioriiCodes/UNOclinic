// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import '../../../utils/breakpoints.dart';
import '../../../widgets/app_table.dart';
import '../../../widgets/section_card.dart';
import '../repositories/inventory_repository.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> batches = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  final InventoryRepository _repo = InventoryRepository();

  Future<void> loadItems() async {
    setState(() => isLoading = true);

    try {
      items = await _repo.getItems();
    } catch (e) {
      print('ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load inventory items.')),
        );
      }
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> receiveStockAction(
    String itemId,
    int quantity,
    DateTime expiryDate,
  ) async {
    try {
      await _repo.receiveStock(
        itemId: itemId,
        quantity: quantity,
        expiryDate: expiryDate,
      );

      await loadItems(); // refresh UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock received.')),
      );
    } catch (e) {
      print('ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to receive stock: $e')),
      );
    }
  }

  Future<void> loadTransactions() async {
    try {
      transactions = await _repo.getTransactions();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print('ERROR: $e');
    }
  }

  Future<void> loadBatches() async {
    try {
      batches = await _repo.getBatches();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print('ERROR: $e');
    }
  }

  Future<void> loadAlerts() async {
    try {
      alerts = await _repo.getAlerts();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print('ERROR: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        loadBatches();
      } else if (_tabController.index == 2) {
        loadTransactions();
      } else if (_tabController.index == 3) {
        loadAlerts();
      }
    });
    loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(child: Text('No inventory items found.'));
    }

    return AppTable<Map<String, dynamic>>(
      columns: const [
        AppTableColumn('name', 'Name', width: 220),
        AppTableColumn('category', 'Category', width: 120),
        AppTableColumn('totalStock', 'Total stock', width: 100),
        AppTableColumn('threshold', 'Threshold', width: 100),
      ],
      rows: items,
      cellBuilder: (item, key) {
        switch (key) {
          case 'name':
            return Text((item['name'] ?? '-').toString());
          case 'category':
            return Text((item['category'] ?? '-').toString());
          case 'totalStock':
            return Text('${item['total_stock'] ?? 0}');
          case 'threshold':
            return Text('${item['minimum_stock'] ?? 0}');
          default:
            return const SizedBox.shrink();
        }
      },
      onRowTap: (item) => _showReceiveStockDialog(item),
    );
  }

  void _showReceiveStockDialog(Map<String, dynamic> item) {
    final itemId = (item['id'] ?? '').toString();
    if (itemId.isEmpty) return;

    final qtyController = TextEditingController();
    DateTime? expiryDate;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Receive Stock'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter quantity',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: expiryDate == null
                        ? ''
                        : '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Expiry date',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expiryDate ?? now,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: DateTime(now.year + 10, 12, 31),
                    );
                    if (picked != null) {
                      setLocal(() => expiryDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final quantity = int.tryParse(qtyController.text.trim());
                      if (quantity == null || quantity <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quantity must be a valid integer.')),
                        );
                        return;
                      }
                      if (expiryDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select expiry date.')),
                        );
                        return;
                      }

                      setLocal(() => saving = true);
                      await receiveStockAction(itemId, quantity, expiryDate!);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
              child: const Text('Receive Stock'),
            ),
          ],
        ),
      ),
    ).then((_) {
      qtyController.dispose();
    });
  }

  Widget _transactionsTab() {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return AppTable<Map<String, dynamic>>(
      columns: const [
        AppTableColumn('type', 'Type', width: 100),
        AppTableColumn('itemName', 'Item Name', width: 220),
        AppTableColumn('quantity', 'Quantity', width: 100),
        AppTableColumn('reference', 'Reference', width: 180),
        AppTableColumn('date', 'Date', width: 180),
      ],
      rows: transactions,
      cellBuilder: (tx, key) {
        final itemJoin = tx['inventory_items'];
        final itemName = itemJoin is Map
            ? (itemJoin['name'] ?? '-').toString()
            : itemJoin is List && itemJoin.isNotEmpty && itemJoin.first is Map
            ? ((itemJoin.first as Map)['name'] ?? '-').toString()
            : '-';

        switch (key) {
          case 'type':
            return Text((tx['type'] ?? '-').toString());
          case 'itemName':
            return Text(itemName);
          case 'quantity':
            return Text((tx['quantity'] ?? 0).toString());
          case 'reference':
            return Text((tx['reference'] ?? '-').toString());
          case 'date':
            return Text((tx['created_at'] ?? '-').toString());
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _batchesTab() {
    if (batches.isEmpty) {
      return const Center(child: Text('No batches found.'));
    }

    return ListView.builder(
      itemCount: batches.length,
      itemBuilder: (context, index) {
        final batch = batches[index];
        final join = batch['inventory_items'];
        final itemName = join is Map
            ? (join['name'] ?? 'Item').toString()
            : join is List && join.isNotEmpty && join.first is Map
            ? ((join.first as Map)['name'] ?? 'Item').toString()
            : 'Item';
        final expiryText = (batch['expiry_date'] ?? '-').toString();

        return ListTile(
          title: Text(itemName),
          subtitle: Text('Qty: ${batch['quantity'] ?? 0} | Exp: $expiryText'),
        );
      },
    );
  }

  Widget _alertsTab() {
    if (alerts.isEmpty) {
      return const Center(child: Text('No alerts found.'));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return ListTile(
          title: Text((alert['message'] ?? '-').toString()),
        );
      },
    );
  }
}
