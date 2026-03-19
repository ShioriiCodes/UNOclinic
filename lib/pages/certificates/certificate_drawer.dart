import 'package:flutter/material.dart';

import '../../widgets/details_drawer.dart';
import '../../models/health_certificate.dart';
import '../../utils/formatters.dart';

/// Right-side drawer for a certificate. Fields + template preview placeholder. Approve, Release + Print (UI only).
class CertificateDrawer extends StatelessWidget {
  const CertificateDrawer({
    super.key,
    required this.certificate,
    required this.onClose,
    this.onApprove,
    this.onRelease,
    this.onDelete,
  });

  final HealthCertificate certificate;
  final VoidCallback onClose;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onRelease;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusUpper = (certificate.status ?? '').toUpperCase();
    return DetailsDrawer(
      title: 'Certificate - ${certificate.patientName ?? 'Unknown'}',
      onClose: onClose,
      actions: [
        OutlinedButton.icon(
          onPressed: onDelete == null
              ? null
              : () async {
                  await onDelete!();
                },
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Delete'),
        ),
        if (statusUpper == 'PENDING')
          FilledButton.icon(
            onPressed: onApprove == null
                ? null
                : () async {
                    await onApprove!();
                  },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
          ),
        if (statusUpper == 'APPROVED' || statusUpper == 'PENDING')
          OutlinedButton.icon(
            onPressed: onRelease == null
                ? null
                : () async {
                    await onRelease!();
                  },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Release + Print'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Request date', Formatters.date(certificate.requestDate)),
          _row('Patient', certificate.patientName ?? 'Unknown'),
          _row('Purpose', certificate.purpose ?? '-'),
          _row('Status', certificate.status ?? 'Pending'),
          if (certificate.releasedDate != null)
            _row('Released date', Formatters.date(certificate.releasedDate!)),
          const SizedBox(height: 24),
          const Text('Template preview', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Certificate template placeholder', style: TextStyle(color: Colors.grey)),
            ),
          ),
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
