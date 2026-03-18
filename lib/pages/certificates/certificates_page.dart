import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../../utils/breakpoints.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_table.dart';
import '../../models/health_certificate.dart';
import '../../repositories/health_certificate_repository.dart';
import 'certificate_drawer.dart';

/// Certificates page: filters (status, date range), table. Row click opens CertificateDrawer.
class CertificatesPage extends StatefulWidget {
  const CertificatesPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  String _statusFilter = 'All';
  final HealthCertificateRepository _repo = HealthCertificateRepository();
  bool _loading = false;
  List<HealthCertificate> _certificates = const [];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getCertificates();
      if (!mounted) return;
      setState(() => _certificates = list);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load certificates.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<HealthCertificate> get _filtered {
    if (_statusFilter == 'All') return _certificates;
    return _certificates.where((c) => (c.status ?? '') == _statusFilter).toList();
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
            'Health Certificates',
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
                        items: ['All', 'Pending', 'Approved', 'Released']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'From date',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'To date',
                            isDense: true,
                          ),
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
                          ? const Center(child: Text('No certificates found.'))
                          : AppTable<HealthCertificate>(
                              columns: const [
                                AppTableColumn('requestDate', 'Request date', width: 120),
                                AppTableColumn('patient', 'Patient', width: 160),
                                AppTableColumn('purpose', 'Purpose', width: 140),
                                AppTableColumn('status', 'Status', width: 100),
                                AppTableColumn('releasedDate', 'Released date', width: 120),
                              ],
                              rows: _filtered,
                              cellBuilder: (row, key) {
                                switch (key) {
                                  case 'requestDate':
                                    return Text(Formatters.date(row.requestDate));
                                  case 'patient':
                                    return Text((row.patientName ?? 'Unknown').trim().isEmpty ? 'Unknown' : row.patientName!);
                                  case 'purpose':
                                    return Text(row.purpose ?? '—');
                                  case 'status':
                                    return Text(row.status ?? 'Pending');
                                  case 'releasedDate':
                                    return Text(row.releasedDate != null ? Formatters.date(row.releasedDate!) : '—');
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                              onRowTap: (row) => widget.onOpenDrawer(
                                CertificateDrawer(
                                  certificate: row,
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
