import 'package:flutter/material.dart';

import '../../widgets/details_drawer.dart';
import '../../models/referral.dart';
import '../../utils/formatters.dart';

/// Right-side drawer for a referral. Follow-up notes editor + Mark Completed (UI only).
class ReferralDrawer extends StatefulWidget {
  const ReferralDrawer({
    super.key,
    required this.referral,
    required this.onClose,
    this.onMarkCompleted,
    this.onSaveNotes,
  });

  final Referral referral;
  final VoidCallback onClose;
  final Future<void> Function()? onMarkCompleted;
  final Future<void> Function(String notes)? onSaveNotes;

  @override
  State<ReferralDrawer> createState() => _ReferralDrawerState();
}

class _ReferralDrawerState extends State<ReferralDrawer> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.referral.followUpNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailsDrawer(
      title: 'Referral — ${widget.referral.patientName ?? 'Unknown'}',
      onClose: widget.onClose,
      actions: [
        OutlinedButton.icon(
          onPressed: widget.onSaveNotes == null
              ? null
              : () async {
                  await widget.onSaveNotes!(_notesController.text.trim());
                },
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Notes'),
        ),
        if ((widget.referral.status ?? '').toUpperCase() == 'PENDING')
          FilledButton.icon(
            onPressed: widget.onMarkCompleted == null
                ? null
                : () async {
                    await widget.onMarkCompleted!();
                  },
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Mark Completed'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Referral date', Formatters.date(widget.referral.referralDate)),
          _row('Patient', widget.referral.patientName ?? 'Unknown'),
          _row('Referred to', widget.referral.referredTo ?? '—'),
          _row('Reason', widget.referral.reason ?? '—'),
          _row('Follow-up due', widget.referral.followUpDue ?? '—'),
          _row('Status', widget.referral.status ?? 'Pending'),
          const SizedBox(height: 16),
          const Text('Follow-up notes', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter follow-up notes…',
              alignLabelWithHint: true,
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
