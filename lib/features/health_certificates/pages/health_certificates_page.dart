// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../models/health_certificate.dart';
import '../../../pages/certificates/certificate_drawer.dart';
import '../../../utils/breakpoints.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_table.dart';
import '../../../widgets/section_card.dart';
import '../repositories/certificate_repository.dart';

class HealthCertificatesPage extends StatefulWidget {
  const HealthCertificatesPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<HealthCertificatesPage> createState() => _HealthCertificatesPageState();
}

class _HealthCertificatesPageState extends State<HealthCertificatesPage> {
  String _statusFilter = 'All';
  List<Map<String, dynamic>> certificates = [];
  bool isLoading = true;

  final CertificateRepository _repo = CertificateRepository();

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

  Future<void> loadCertificates() async {
    setState(() => isLoading = true);
    try {
      final data = await _repo.getCertificates();
      if (!mounted) return;
      setState(() => certificates = data);
    } catch (e) {
      print('ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load certificates.')),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _approve(String id) async {
    await _repo.updateStatus(id, 'APPROVED');
    await loadCertificates();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate approved.')),
    );
  }

  Future<void> _release(String id) async {
    await _repo.updateStatus(id, 'RELEASED');
    await loadCertificates();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate released.')),
    );
  }

  Future<void> _deleteCertificate(String id) async {
    await _repo.deleteCertificate(id);
    await loadCertificates();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate deleted.')),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == 'All') return certificates;
    return certificates.where((c) {
      final status = (c['status'] ?? '').toString().toUpperCase();
      return status == _statusFilter.toUpperCase();
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadCertificates();
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
                          items: ['All', 'PENDING', 'APPROVED', 'RELEASED']
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
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filtered.isEmpty
                            ? const Center(child: Text('No certificates found.'))
                            : AppTable<Map<String, dynamic>>(
                                columns: const [
                                  AppTableColumn('requestDate', 'Request date', width: 120),
                                  AppTableColumn('patient', 'Patient', width: 160),
                                  AppTableColumn('purpose', 'Purpose', width: 140),
                                  AppTableColumn('status', 'Status', width: 100),
                                  AppTableColumn('releasedDate', 'Released date', width: 120),
                                ],
                                rows: _filtered,
                                cellBuilder: (cert, key) {
                                  final patient = cert['patients'] is Map
                                      ? (cert['patients'] as Map).cast<String, dynamic>()
                                      : null;
                                  switch (key) {
                                    case 'requestDate':
                                      final requestDate = _parseDate(
                                        cert['request_date'] ?? cert['created_at'],
                                      );
                                      return Text(requestDate != null ? Formatters.date(requestDate) : '—');
                                    case 'patient':
                                      return Text(getPatientName(patient));
                                    case 'purpose':
                                      return Text((cert['purpose'] ?? '—').toString());
                                    case 'status':
                                      return Text((cert['status'] ?? 'PENDING').toString());
                                    case 'releasedDate':
                                      final releasedDate = _parseDate(cert['released_date']);
                                      return Text(releasedDate != null ? Formatters.date(releasedDate) : '—');
                                    default:
                                      return const SizedBox.shrink();
                                  }
                                },
                                onRowTap: (cert) => widget.onOpenDrawer(
                                  CertificateDrawer(
                                    certificate: HealthCertificate.fromMap(cert),
                                    onClose: () => widget.onOpenDrawer(null),
                                    onApprove: () async {
                                      final id = (cert['id'] ?? '').toString();
                                      if (id.isEmpty) return;
                                      await _approve(id);
                                    },
                                    onRelease: () async {
                                      final id = (cert['id'] ?? '').toString();
                                      if (id.isEmpty) return;
                                      await _release(id);
                                    },
                                    onDelete: () async {
                                      final id = (cert['id'] ?? '').toString();
                                      if (id.isEmpty) return;
                                      await _deleteCertificate(id);
                                      widget.onOpenDrawer(null);
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
