import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../../utils/breakpoints.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_table.dart';
import '../../models/referral.dart';
import '../../repositories/referral_repository.dart';
import 'referral_drawer.dart';

/// Referrals page: filters (status, follow-up due), table. Row click opens ReferralDrawer.
class ReferralsPage extends StatefulWidget {
  const ReferralsPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends State<ReferralsPage> {
  String _statusFilter = 'All';
  bool _followUpDueOnly = false;
  final ReferralRepository _repo = ReferralRepository();
  bool _loading = false;
  List<Referral> _referrals = const [];

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getReferrals();
      if (!mounted) return;
      setState(() => _referrals = list);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load referrals.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Referral> get _filtered {
    var list = _referrals;
    if (_statusFilter != 'All') {
      list = list.where((r) => (r.status ?? '') == _statusFilter).toList();
    }
    if (_followUpDueOnly) {
      list = list.where((r) => (r.followUpDue ?? '').trim().isNotEmpty && (r.status ?? '') == 'Pending').toList();
    }
    return list;
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
            'Referrals',
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
                      DropdownButton<String>(
                        value: _statusFilter,
                        items: ['All', 'Pending', 'Completed']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 220,
                        child: CheckboxListTile(
                          value: _followUpDueOnly,
                          onChanged: (v) => setState(() => _followUpDueOnly = v ?? false),
                          title: const Text('Follow-up due only'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
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
                          ? const Center(child: Text('No referrals found.'))
                          : AppTable<Referral>(
                              columns: const [
                                AppTableColumn('date', 'Referral date', width: 120),
                                AppTableColumn('patient', 'Patient', width: 140),
                                AppTableColumn('referredTo', 'Referred to', width: 180),
                                AppTableColumn('reason', 'Reason', width: 140),
                                AppTableColumn('followUp', 'Follow-up', width: 100),
                                AppTableColumn('status', 'Status', width: 100),
                              ],
                              rows: _filtered,
                              cellBuilder: (row, key) {
                                switch (key) {
                                  case 'date':
                                    return Text(Formatters.date(row.referralDate));
                                  case 'patient':
                                    return Text((row.patientName ?? 'Unknown').trim().isEmpty ? 'Unknown' : row.patientName!);
                                  case 'referredTo':
                                    return Text(row.referredTo ?? '-');
                                  case 'reason':
                                    return Text(row.reason ?? '-');
                                  case 'followUp':
                                    return Text(row.followUpDue ?? '-');
                                  case 'status':
                                    return Text(row.status ?? 'Pending');
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                              onRowTap: (row) => widget.onOpenDrawer(
                                ReferralDrawer(
                                  referral: row,
                                  onClose: () => widget.onOpenDrawer(null),
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
