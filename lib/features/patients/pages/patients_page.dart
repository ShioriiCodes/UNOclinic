// ignore_for_file: avoid_print, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';

import '../../../models/patient.dart';
import '../../../pages/patients/patient_drawer.dart';
import '../../../utils/breakpoints.dart';
import '../../../utils/formatters.dart';
import '../../../utils/patient_name.dart';
import '../../../widgets/app_table.dart';
import '../../../widgets/section_card.dart';
import '../repositories/patient_repository.dart';

/// Patients page connected to Supabase CRUD.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key, required this.onOpenDrawer});

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String _typeFilter = 'All';
  String _deptFilter = 'All';
  String _search = '';

  List<Map<String, dynamic>> patients = [];
  Map<String, DateTime> latestVisits = {};
  bool isLoading = true;

  final PatientRepository _repo = PatientRepository();
  static const List<String> _departmentPrograms = [
    'BSIT',
    'BSA',
    'BSBA',
    'BSED',
    'BEED',
    'BSTM',
    'BSHM',
  ];

  Future<void> loadPatients() async {
    setState(() => isLoading = true);

    try {
      final loadedPatients = await _repo.getPatients();
      final visitMap = await _repo.getLatestVisitMap(
        loadedPatients.map((row) => (row['id'] ?? '').toString()).toList(),
      );
      patients = loadedPatients;
      latestVisits = visitMap;

      // Keep selected department valid against official program list.
      final hasSelectedDept = _departmentOptions.contains(_deptFilter);
      if (!hasSelectedDept && _deptFilter != 'All') {
        _deptFilter = 'All';
      }
    } catch (e) {
      print('ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load patients.')),
        );
      }
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    loadPatients();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = patients;

    if (_typeFilter != 'All') {
      list = list
          .where((p) => (p['type'] ?? '').toString() == _typeFilter)
          .toList();
    }

    if (_deptFilter != 'All') {
      list = list
          .where((p) => (p['department'] ?? '').toString() == _deptFilter)
          .toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) {
        final first = (p['first_name'] ?? '').toString().trim();
        final last = (p['last_name'] ?? '').toString().trim();
        final name = '$first $last'.trim().toLowerCase();
        final id = (p['student_id'] ?? '').toString().toLowerCase();
        return name.contains(q) || id.contains(q);
      }).toList();
    }

    return list;
  }

  List<String> get _departmentOptions {
    final sortedPrograms = [..._departmentPrograms]..sort();
    return ['All', ...sortedPrograms];
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
                onPressed: () => _showCreatePatientModal(context),
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
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _typeFilter = v ?? 'All'),
                        ),
                        const SizedBox(width: 16),
                        const Text('Department:'),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _deptFilter,
                          items: _departmentOptions
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _deptFilter = v ?? 'All'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filtered.isEmpty
                        ? const Center(child: Text('No patients found.'))
                        : AppTable<Map<String, dynamic>>(
                            columns: const [
                              AppTableColumn(
                                'schoolId',
                                'School ID',
                                width: 120,
                              ),
                              AppTableColumn('name', 'Name', width: 220),
                              AppTableColumn('type', 'Type', width: 100),
                              AppTableColumn(
                                'department',
                                'Department/Office',
                                width: 160,
                              ),
                              AppTableColumn(
                                'lastVisit',
                                'Last Visit',
                                width: 120,
                              ),
                            ],
                            rows: _filtered,
                            cellBuilder: (row, key) {
                              switch (key) {
                                case 'schoolId':
                                  return Text(
                                    (row['student_id'] ?? '—').toString(),
                                  );
                                case 'name':
                                  return Text(_fullNameFromRow(row));
                                case 'type':
                                  return Text((row['type'] ?? '—').toString());
                                case 'department':
                                  return Text(
                                    (row['department'] ?? '—').toString(),
                                  );
                                case 'lastVisit':
                                  final dt =
                                      latestVisits[(row['id'] ?? '')
                                          .toString()];
                                  return Text(
                                    dt == null ? '—' : Formatters.date(dt),
                                  );
                                default:
                                  return const SizedBox.shrink();
                              }
                            },
                            onRowTap: (row) {
                              final patientModel = Patient.fromMap(row);
                              widget.onOpenDrawer(
                                PatientDrawer(
                                  patient: patientModel,
                                  onClose: () => widget.onOpenDrawer(null),
                                  onPatientUpdated: () async {
                                    await loadPatients();
                                  },
                                  onPatientDeleted: () async {
                                    widget.onOpenDrawer(null);
                                    await loadPatients();
                                  },
                                ),
                              );
                            },
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

  void _showCreatePatientModal(BuildContext context) {
    final schoolId = TextEditingController();
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final type = TextEditingController();
    final department = TextEditingController();
    final contactNumber = TextEditingController();
    final address = TextEditingController();
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
                  TextField(
                    controller: schoolId,
                    decoration: const InputDecoration(labelText: 'School ID'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: type,
                    decoration: const InputDecoration(
                      labelText: 'Type (Student/Faculty/Staff)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: department,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Birth date',
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    controller: TextEditingController(
                      text: birthDate == null ? '' : Formatters.date(birthDate),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            birthDate ??
                            DateTime(now.year - 20, now.month, now.day),
                        firstDate: DateTime(1950, 1, 1),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setLocal(() => birthDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactNumber,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (firstName.text.trim().isEmpty &&
                          lastName.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'First Name or Last Name is required.',
                            ),
                          ),
                        );
                        return;
                      }
                      setLocal(() => saving = true);
                      try {
                        await _repo.createPatient({
                          'student_id': schoolId.text.trim().isEmpty
                              ? null
                              : schoolId.text.trim(),
                          'first_name': firstName.text.trim().isEmpty
                              ? null
                              : firstName.text.trim(),
                          'last_name': lastName.text.trim().isEmpty
                              ? null
                              : lastName.text.trim(),
                          'type': type.text.trim().isEmpty
                              ? null
                              : type.text.trim(),
                          'department': department.text.trim().isEmpty
                              ? null
                              : department.text.trim(),
                          'birth_date': birthDate == null
                              ? null
                              : Formatters.date(birthDate),
                          'contact_number': contactNumber.text.trim().isEmpty
                              ? null
                              : contactNumber.text.trim(),
                          'address': address.text.trim().isEmpty
                              ? null
                              : address.text.trim(),
                          'created_at': DateTime.now().toIso8601String(),
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await loadPatients();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient created.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create patient: $e'),
                          ),
                        );
                      } finally {
                        setLocal(() => saving = false);
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
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

  void _showEditPatientModal(
    BuildContext context,
    Map<String, dynamic> patient,
  ) {
    final schoolId = TextEditingController(
      text: (patient['student_id'] ?? '').toString(),
    );
    final firstName = TextEditingController(
      text: (patient['first_name'] ?? '').toString(),
    );
    final lastName = TextEditingController(
      text: (patient['last_name'] ?? '').toString(),
    );
    final type = TextEditingController(
      text: (patient['type'] ?? '').toString(),
    );
    final department = TextEditingController(
      text: (patient['department'] ?? '').toString(),
    );
    final contactNumber = TextEditingController(
      text: (patient['contact_number'] ?? '').toString(),
    );
    final address = TextEditingController(
      text: (patient['address'] ?? '').toString(),
    );
    DateTime? birthDate = _parseDate(patient['birth_date']);
    bool saving = false;

    final id = (patient['id'] ?? '').toString();
    if (id.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit Patient'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: schoolId,
                    decoration: const InputDecoration(labelText: 'School ID'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: department,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Birth date',
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    controller: TextEditingController(
                      text: birthDate == null ? '' : Formatters.date(birthDate),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            birthDate ??
                            DateTime(now.year - 20, now.month, now.day),
                        firstDate: DateTime(1950, 1, 1),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setLocal(() => birthDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactNumber,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      try {
                        await _repo.deletePatient(id);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await loadPatients();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient deleted.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete patient: $e'),
                          ),
                        );
                      } finally {
                        setLocal(() => saving = false);
                      }
                    },
              child: const Text('Delete'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (firstName.text.trim().isEmpty &&
                          lastName.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'First Name or Last Name is required.',
                            ),
                          ),
                        );
                        return;
                      }
                      setLocal(() => saving = true);
                      try {
                        await _repo.updatePatient(id, {
                          'student_id': schoolId.text.trim().isEmpty
                              ? null
                              : schoolId.text.trim(),
                          'first_name': firstName.text.trim().isEmpty
                              ? null
                              : firstName.text.trim(),
                          'last_name': lastName.text.trim().isEmpty
                              ? null
                              : lastName.text.trim(),
                          'type': type.text.trim().isEmpty
                              ? null
                              : type.text.trim(),
                          'department': department.text.trim().isEmpty
                              ? null
                              : department.text.trim(),
                          'birth_date': birthDate == null
                              ? null
                              : Formatters.date(birthDate),
                          'contact_number': contactNumber.text.trim().isEmpty
                              ? null
                              : contactNumber.text.trim(),
                          'address': address.text.trim().isEmpty
                              ? null
                              : address.text.trim(),
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await loadPatients();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient updated.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update patient: $e'),
                          ),
                        );
                      } finally {
                        setLocal(() => saving = false);
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
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

  String _fullNameFromRow(Map<String, dynamic> row) {
    return getFullName(row);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
