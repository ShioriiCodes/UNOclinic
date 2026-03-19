import 'package:flutter/material.dart';

import '../../widgets/details_drawer.dart';
import '../../utils/formatters.dart';
import '../../models/patient.dart';
import '../../repositories/patient_repository.dart';
import '../../models/visit.dart';
import '../../models/health_certificate.dart';
import '../../models/referral.dart';
import '../../repositories/visit_repository.dart';
import '../../repositories/health_certificate_repository.dart';
import '../../repositories/referral_repository.dart';

/// Right-side drawer for a selected patient. Tabs: Profile, Visits, Certificates, Referrals.
class PatientDrawer extends StatelessWidget {
  const PatientDrawer({
    super.key,
    required this.patient,
    required this.onClose,
    required this.onPatientUpdated,
    required this.onPatientDeleted,
  });

  final Patient patient;
  final VoidCallback onClose;
  final Future<void> Function() onPatientUpdated;
  final Future<void> Function() onPatientDeleted;

  @override
  Widget build(BuildContext context) {
    return DetailsDrawer(
      title: patient.fullName,
      onClose: onClose,
      tabs: const ['Profile', 'Visits', 'Certificates', 'Referrals'],
      tabViews: [
        _ProfileTab(patient: patient),
        const _VisitsTab(),
        const _CertificatesTab(),
        const _ReferralsTab(),
      ],
      actions: [
        OutlinedButton.icon(
          onPressed: () => _showEditDialog(context),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit profile'),
        ),
        FilledButton.icon(
          onPressed: () => _showNewVisitDialog(context),
          icon: const Icon(Icons.medical_services_rounded, size: 18),
          label: const Text('New Visit'),
        ),
        OutlinedButton.icon(
          onPressed: () => _showRequestCertificateDialog(context),
          icon: const Icon(Icons.badge_rounded, size: 18),
          label: const Text('Request Certificate'),
        ),
        OutlinedButton.icon(
          onPressed: () => _showCreateReferralDialog(context),
          icon: const Icon(Icons.forward_rounded, size: 18),
          label: const Text('Create Referral'),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final repo = PatientRepository();
    final schoolId = TextEditingController(text: patient.studentId ?? '');
    final firstName = TextEditingController(text: patient.firstName ?? '');
    final lastName = TextEditingController(text: patient.lastName ?? '');
    final type = TextEditingController(text: patient.type ?? '');
    final department = TextEditingController(text: patient.department ?? '');
    final contactNumber = TextEditingController(text: patient.contactNumber ?? '');
    final address = TextEditingController(text: patient.address ?? '');
    DateTime? birthDate = patient.birthDate;

    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Edit Patient'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: schoolId, decoration: const InputDecoration(labelText: 'Student ID')),
                const SizedBox(height: 12),
                TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First Name')),
                const SizedBox(height: 12),
                TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last Name')),
                const SizedBox(height: 12),
                TextField(controller: type, decoration: const InputDecoration(labelText: 'Type')),
                const SizedBox(height: 12),
                TextField(controller: department, decoration: const InputDecoration(labelText: 'Department')),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Birthdate',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  controller: TextEditingController(
                    text: birthDate != null ? Formatters.date(birthDate) : '',
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: birthDate ?? DateTime(now.year - 20, now.month, now.day),
                      firstDate: DateTime(1950, 1, 1),
                      lastDate: now,
                    );
                    if (picked != null) {
                      setDialogState(() => birthDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: contactNumber, decoration: const InputDecoration(labelText: 'Contact Number')),
                const SizedBox(height: 12),
                TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
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
                      await repo.deletePatient(patient.id);
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Patient deleted.')),
                      );
                      await onPatientDeleted();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to delete patient.')),
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
                          final updated = patient.copyWith(
                            studentId: schoolId.text.trim().isEmpty ? null : schoolId.text.trim(),
                            firstName: firstName.text.trim().isEmpty ? null : firstName.text.trim(),
                            lastName: lastName.text.trim().isEmpty ? null : lastName.text.trim(),
                            type: type.text.trim().isEmpty ? null : type.text.trim(),
                            department: department.text.trim().isEmpty ? null : department.text.trim(),
                            birthDate: birthDate,
                            contactNumber: contactNumber.text.trim().isEmpty ? null : contactNumber.text.trim(),
                            address: address.text.trim().isEmpty ? null : address.text.trim(),
                          );
                          await repo.updatePatient(updated);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Patient updated.')),
                          );
                          await onPatientUpdated();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update patient.')),
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
      )),
    ).then((_) {
      schoolId.dispose();
      firstName.dispose();
      lastName.dispose();
      type.dispose();
      department.dispose();
      contactNumber.dispose();
      address.dispose();
    });
  }

  void _showNewVisitDialog(BuildContext context) {
    final repo = VisitRepository();
    final notes = TextEditingController();
    final assessment = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Visit'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: assessment,
                  decoration: const InputDecoration(labelText: 'Assessment'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      try {
                        await repo.createVisit(
                          Visit(
                            id: '',
                            patientId: patient.id,
                            visitDate: DateTime.now(),
                            assessment: assessment.text.trim().isEmpty ? null : assessment.text.trim(),
                            notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                          ),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visit created.')),
                        );
                      } catch (_) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to create visit.')),
                          );
                        }
                      } finally {
                        if (ctx.mounted) {
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      notes.dispose();
      assessment.dispose();
    });
  }

  void _showRequestCertificateDialog(BuildContext context) {
    final repo = HealthCertificateRepository();
    String purpose = '';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Request Certificate'),
          content: SizedBox(
            width: 460,
            child: TextField(
              onChanged: (v) => purpose = v,
              decoration: const InputDecoration(labelText: 'Purpose'),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      try {
                        await repo.createCertificate(
                          HealthCertificate(
                            id: '',
                            patientId: patient.id,
                            purpose: purpose.trim().isEmpty ? null : purpose.trim(),
                            status: 'Pending',
                          ),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Certificate requested.')),
                        );
                      } catch (_) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to request certificate (possible duplicate pending request).',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) {
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReferralDialog(BuildContext context) {
    final repo = ReferralRepository();
    String referredTo = '';
    String reason = '';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create Referral'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (v) => referredTo = v,
                  decoration: const InputDecoration(labelText: 'Referred To'),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => reason = v,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      try {
                        await repo.createReferral(
                          Referral(
                            id: '',
                            patientId: patient.id,
                            referredTo: referredTo.trim().isEmpty ? null : referredTo.trim(),
                            reason: reason.trim().isEmpty ? null : reason.trim(),
                            status: 'Pending',
                          ),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Referral created.')),
                        );
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to create referral: $e')),
                          );
                        }
                      } finally {
                        if (ctx.mounted) {
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('School ID', patient.studentId ?? '-'),
          _row('Type', patient.type ?? '-'),
          _row('Department', patient.department ?? '-'),
          _row('Birth date', patient.birthDate != null ? Formatters.date(patient.birthDate) : '-'),
          _row('Contact number', patient.contactNumber ?? '-'),
          _row('Address', patient.address ?? '-'),
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

class _VisitsTab extends StatelessWidget {
  const _VisitsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Connect Visits module to show data.'));
  }
}

class _CertificatesTab extends StatelessWidget {
  const _CertificatesTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Connect Certificates module to show data.'));
  }
}

class _ReferralsTab extends StatelessWidget {
  const _ReferralsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Connect Referrals module to show data.'));
  }
}
