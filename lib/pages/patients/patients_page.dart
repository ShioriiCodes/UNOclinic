import 'package:flutter/material.dart';

import '../../utils/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_table.dart';
import '../../models/patient.dart';
import '../../repositories/patient_repository.dart';
import 'patient_drawer.dart';

/// Patients page: header + New Patient, filters, table. Row click opens PatientDrawer.
class PatientsPage extends StatefulWidget {
  const PatientsPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String _typeFilter = 'All';
  String _deptFilter = 'All';
  String _search = '';

  final PatientRepository _repo = PatientRepository();
  bool _loading = false;
  List<Patient> _patients = const [];
  Map<String, DateTime> _latestVisits = const {};

  static const List<String> _departments = ['CCS', 'COE', 'CABE', 'Admin', 'All'];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getPatients();
      final latestVisits = await _repo.getLatestVisitMap(
        list.map((p) => p.id).toList(),
      );
      if (!mounted) return;
      setState(() {
        _patients = list;
        _latestVisits = latestVisits;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load patients.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Patient> get _filtered {
    var list = _patients;
    if (_typeFilter != 'All') {
      list = list.where((p) => p.type == _typeFilter).toList();
    }
    if (_deptFilter != 'All') {
      list = list.where((p) => p.department == _deptFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) =>
          p.fullName.toLowerCase().contains(q) ||
          (p.studentId ?? '').toLowerCase().contains(q)).toList();
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
          Row(
            children: [
              Text(
                'Patients',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showNewPatientModal(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New Patient'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SectionCard(
              padding: const EdgeInsets.all(24),
              expandChild: true,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search by name or ID',
                            prefixIcon: Icon(Icons.search_rounded, size: 20),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _typeFilter,
                        items: ['All', 'Student', 'Faculty', 'Staff']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _typeFilter = v ?? 'All'),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _deptFilter,
                        items: _departments
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _deptFilter = v ?? 'All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filtered.isEmpty
                          ? const Center(child: Text('No patients found.'))
                          : AppTable<Patient>(
                              columns: const [
                                AppTableColumn('schoolId', 'School ID', width: 120),
                                AppTableColumn('name', 'Name', width: 200),
                                AppTableColumn('type', 'Type', width: 100),
                                AppTableColumn('department', 'Department/Office', width: 140),
                                AppTableColumn('lastVisit', 'Last Visit', width: 120),
                              ],
                              rows: _filtered,
                              cellBuilder: (row, key) {
                                switch (key) {
                                  case 'schoolId':
                                    return Text(row.studentId ?? '-');
                                  case 'name':
                                    return Text(row.fullName);
                                  case 'type':
                                    return Text(row.type ?? '-');
                                  case 'department':
                                    return Text(row.department ?? '-');
                                  case 'lastVisit':
                                    final lastVisit = _latestVisits[row.id];
                                    return Text(
                                      lastVisit != null ? Formatters.date(lastVisit) : '-',
                                    );
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                              onRowTap: (row) => widget.onOpenDrawer(
                                PatientDrawer(
                                  patient: row,
                                  onClose: () => widget.onOpenDrawer(null),
                                  onPatientUpdated: () async {
                                    await _loadPatients();
                                  },
                                  onPatientDeleted: () async {
                                    widget.onOpenDrawer(null);
                                    await _loadPatients();
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

  void _showNewPatientModal(BuildContext context) {
    final schoolId = TextEditingController();
    final fullName = TextEditingController();
    final type = TextEditingController();
    final department = TextEditingController();
    DateTime? birthDate;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
        title: const Text('New Patient'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: schoolId, decoration: const InputDecoration(labelText: 'School ID')),
                const SizedBox(height: 12),
                TextField(controller: fullName, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: type, decoration: const InputDecoration(labelText: 'Type (Student/Faculty/Staff)')),
                const SizedBox(height: 12),
                TextField(controller: department, decoration: const InputDecoration(labelText: 'Department')),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Birthdate',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
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
                      setLocal(() => birthDate = picked);
                    }
                  },
                ),
              ],
            ),
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
                          final name = fullName.text.trim();
                          final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
                          final first = parts.isNotEmpty ? parts.first : null;
                          final last = parts.length >= 2 ? parts.sublist(1).join(' ') : null;

                          await _repo.createPatient(
                            Patient(
                              id: '',
                              studentId: schoolId.text.trim().isEmpty ? null : schoolId.text.trim(),
                              firstName: first,
                              lastName: last,
                              type: type.text.trim().isEmpty ? null : type.text.trim(),
                              department: department.text.trim().isEmpty ? null : department.text.trim(),
                              birthDate: birthDate,
                            ),
                          );

                          if (!ctx.mounted || !mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Patient created.')),
                          );
                          await _loadPatients();
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Failed to create patient.')),
                            );
                          }
                        } finally {
                          setLocal(() => saving = false);
                        }
                      },
                child: const Text('Save'),
          ),
        ],
      )),
    ).then((_) {
      schoolId.dispose();
      fullName.dispose();
      type.dispose();
      department.dispose();
    });
  }
}
