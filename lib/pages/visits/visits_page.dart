import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../../utils/breakpoints.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_table.dart';
import '../../models/visit.dart';
import '../../repositories/visit_repository.dart';
import 'visit_drawer.dart';

/// Visits page: filters (date range, handled by, search), table. Row click opens VisitDrawer.
class VisitsPage extends StatefulWidget {
  const VisitsPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  String _handledBy = 'All';
  String _search = '';

  final VisitRepository _repo = VisitRepository();
  bool _loading = false;
  List<Visit> _visits = const [];

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getVisits();
      if (!mounted) return;
      setState(() => _visits = list);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load visits.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Visit> get _filtered {
    var list = _visits;
    if (_handledBy != 'All') {
      list = list.where((v) => (v.staffName ?? '—') == _handledBy).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((v) =>
          (v.patientName ?? '').toLowerCase().contains(q) ||
          (v.notes ?? v.assessment ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handlers = <String>{
      'All',
      ..._visits.map((v) => v.staffName).whereType<String>().where((s) => s.trim().isNotEmpty),
    }.toList();

    return Padding(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Visits',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 240,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'From date',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'To date',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _handledBy,
                        items: handlers
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _handledBy = v ?? 'All'),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search patient',
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filtered.isEmpty
                          ? const Center(child: Text('No visits found.'))
                          : AppTable<Visit>(
                              columns: const [
                                AppTableColumn('date', 'Date/Time', width: 140),
                                AppTableColumn('patient', 'Patient', width: 160),
                                AppTableColumn('complaint', 'Complaint', width: 200),
                                AppTableColumn('handledBy', 'Handled by', width: 120),
                              ],
                              rows: _filtered,
                              cellBuilder: (row, key) {
                                switch (key) {
                                  case 'date':
                                    return Text(row.visitDate != null ? Formatters.dateTime(row.visitDate) : '—');
                                  case 'patient':
                                    return Text(row.patientName ?? '—');
                                  case 'complaint':
                                    return Text(row.notes ?? row.assessment ?? '—');
                                  case 'handledBy':
                                    return Text(row.staffName ?? '—');
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                              onRowTap: (row) => widget.onOpenDrawer(
                                VisitDrawer(
                                  visit: row,
                                  onClose: () => widget.onOpenDrawer(null),
                                  onVisitUpdated: () async => _loadVisits(),
                                  onVisitDeleted: () async {
                                    widget.onOpenDrawer(null);
                                    await _loadVisits();
                                  },
                                ),
                              ),
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
}
