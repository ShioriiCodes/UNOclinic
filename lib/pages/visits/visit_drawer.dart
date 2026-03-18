import 'package:flutter/material.dart';

import '../../widgets/details_drawer.dart';
import '../../utils/formatters.dart';
import '../../models/visit.dart';
import '../../repositories/visit_repository.dart';

/// Right-side drawer for a visit. Vitals, complaint, assessment, treatment, notes. Edit + Print (UI only).
class VisitDrawer extends StatelessWidget {
  const VisitDrawer({
    super.key,
    required this.visit,
    required this.onClose,
    required this.onVisitUpdated,
    required this.onVisitDeleted,
  });

  final Visit visit;
  final VoidCallback onClose;
  final Future<void> Function() onVisitUpdated;
  final Future<void> Function() onVisitDeleted;

  @override
  Widget build(BuildContext context) {
    return DetailsDrawer(
      title: 'Visit — ${visit.patientName ?? '—'}',
      onClose: onClose,
      actions: [
        OutlinedButton.icon(
          onPressed: () => _showEditDialog(context),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit'),
        ),
        FilledButton.icon(
          onPressed: () {}, // UI only — Print
          icon: const Icon(Icons.print_rounded, size: 18),
          label: const Text('Print'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Date & Time', visit.visitDate != null ? Formatters.dateTime(visit.visitDate) : '—'),
          _row('Patient', visit.patientName ?? '—'),
          _row('Handled by', visit.staffName ?? '—'),
          if (visit.vitals != null && visit.vitals!.trim().isNotEmpty) _row('Vitals', visit.vitals!),
          if (visit.assessment != null && visit.assessment!.trim().isNotEmpty) _row('Assessment', visit.assessment!),
          if (visit.treatment != null && visit.treatment!.trim().isNotEmpty) _row('Treatment', visit.treatment!),
          if (visit.notes != null && visit.notes!.trim().isNotEmpty) _row('Notes', visit.notes!),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final repo = VisitRepository();
    final vitals = TextEditingController(text: visit.vitals ?? '');
    final assessment = TextEditingController(text: visit.assessment ?? '');
    final treatment = TextEditingController(text: visit.treatment ?? '');
    final notes = TextEditingController(text: visit.notes ?? '');

    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Visit'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: vitals, decoration: const InputDecoration(labelText: 'Vitals')),
                const SizedBox(height: 12),
                TextField(controller: assessment, decoration: const InputDecoration(labelText: 'Assessment')),
                const SizedBox(height: 12),
                TextField(controller: treatment, decoration: const InputDecoration(labelText: 'Treatment')),
                const SizedBox(height: 12),
                TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    try {
                      await repo.deleteVisit(visit.id);
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Visit deleted.')),
                      );
                      await onVisitDeleted();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to delete visit.')),
                        );
                      }
                    }
                  },
            child: const Text('Delete'),
          ),
          StatefulBuilder(
            builder: (context, setLocal) {
              return FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setLocal(() => saving = true);
                        try {
                          final updated = visit.copyWith(
                            vitals: vitals.text.trim().isEmpty ? null : vitals.text.trim(),
                            assessment: assessment.text.trim().isEmpty ? null : assessment.text.trim(),
                            treatment: treatment.text.trim().isEmpty ? null : treatment.text.trim(),
                            notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                          );
                          await repo.updateVisit(updated);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Visit updated.')),
                          );
                          await onVisitUpdated();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update visit.')),
                            );
                          }
                        } finally {
                          setLocal(() => saving = false);
                        }
                      },
                child: const Text('Save'),
              );
            },
          ),
        ],
      ),
    ).then((_) {
      vitals.dispose();
      assessment.dispose();
      treatment.dispose();
      notes.dispose();
    });
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
