// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../models/referral.dart';
import '../../../pages/referrals/referral_drawer.dart';
import '../../../utils/breakpoints.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_table.dart';
import '../../../widgets/section_card.dart';
import '../repositories/referral_repository.dart';

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
  List<Map<String, dynamic>> referrals = [];
  bool isLoading = true;

  final ReferralRepository _repo = ReferralRepository();

  String getPatientName(Map<String, dynamic>? patient) {
    if (patient == null) return 'Unknown';
    final first = (patient['first_name'] ?? '').toString();
    final last = (patient['last_name'] ?? '').toString();
    final full = '$first $last'.trim();
    return full.isEmpty ? 'Unknown' : full;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  Future<void> loadReferrals() async {
    setState(() => isLoading = true);

    try {
      final data = await _repo.getReferrals();
      if (!mounted) return;
      setState(() => referrals = data);
    } catch (e) {
      print('ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load referrals.')),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markCompleted(String id) async {
    await _repo.updateStatus(id, 'COMPLETED');
    await loadReferrals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral marked completed.')),
    );
  }

  Future<void> _saveNotes(String id, String notes) async {
    await _repo.updateNotes(id, notes);
    await loadReferrals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Follow-up notes saved.')),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    var list = referrals;
    if (_statusFilter != 'All') {
      list = list.where((r) {
        final status = (r['status'] ?? '').toString().toUpperCase();
        return status == _statusFilter.toUpperCase();
      }).toList();
    }
    if (_followUpDueOnly) {
      list = list.where((r) {
        final followUpDue = (r['follow_up_due'] ?? '').toString().trim();
        final status = (r['status'] ?? '').toString().toUpperCase();
        return followUpDue.isNotEmpty && status == 'PENDING';
      }).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    loadReferrals();
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
                          items: ['All', 'PENDING', 'COMPLETED']
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
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filtered.isEmpty
                            ? const Center(child: Text('No referrals found.'))
                            : AppTable<Map<String, dynamic>>(
                                columns: const [
                                  AppTableColumn('date', 'Referral date', width: 120),
                                  AppTableColumn('patient', 'Patient', width: 140),
                                  AppTableColumn('referredTo', 'Referred to', width: 180),
                                  AppTableColumn('reason', 'Reason', width: 140),
                                  AppTableColumn('followUp', 'Follow-up', width: 100),
                                  AppTableColumn('status', 'Status', width: 100),
                                ],
                                rows: _filtered,
                                cellBuilder: (ref, key) {
                                  final patient = ref['patients'] is Map
                                      ? (ref['patients'] as Map).cast<String, dynamic>()
                                      : null;
                                  switch (key) {
                                    case 'date':
                                      final date = _parseDate(ref['referral_date']);
                                      return Text(date == null ? '—' : Formatters.date(date));
                                    case 'patient':
                                      return Text(getPatientName(patient));
                                    case 'referredTo':
                                      return Text((ref['referred_to'] ?? '—').toString());
                                    case 'reason':
                                      return Text((ref['reason'] ?? '—').toString());
                                    case 'followUp':
                                      return Text((ref['follow_up_due'] ?? '—').toString());
                                    case 'status':
                                      return Text((ref['status'] ?? 'PENDING').toString());
                                    default:
                                      return const SizedBox.shrink();
                                  }
                                },
                                onRowTap: (ref) => widget.onOpenDrawer(
                                  ReferralDrawer(
                                    referral: Referral.fromMap(ref),
                                    onClose: () => widget.onOpenDrawer(null),
                                    onMarkCompleted: () async {
                                      final id = (ref['id'] ?? '').toString();
                                      if (id.isEmpty) return;
                                      await _markCompleted(id);
                                    },
                                    onSaveNotes: (notes) async {
                                      final id = (ref['id'] ?? '').toString();
                                      if (id.isEmpty) return;
                                      await _saveNotes(id, notes);
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
