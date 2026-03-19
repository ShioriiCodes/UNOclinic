// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/visit.dart';
import '../../../utils/breakpoints.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_table.dart';
import '../../../widgets/section_card.dart';
import '../../../pages/visits/visit_drawer.dart';
import '../repositories/visit_repository.dart';

/// Visits page connected to Supabase CRUD.
class VisitsPage extends StatefulWidget {
  const VisitsPage({
    super.key,
    required this.onOpenDrawer,
  });

  final void Function(Widget? drawer) onOpenDrawer;

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  String _handledBy = 'All';
  String _search = '';

  List<Map<String, dynamic>> visits = [];
  bool isLoading = true;

  final VisitRepository _repo = VisitRepository();

  String getPatientName(Map<String, dynamic>? patient) {
    if (patient == null) return 'Unknown';
    final first = (patient['first_name'] ?? '').toString();
    final last = (patient['last_name'] ?? '').toString();
    final full = '$first $last'.trim();
    return full.isEmpty ? 'Unknown' : full;
  }

  String _getStaffName(dynamic profiles) {
    if (profiles is Map<String, dynamic>) {
      return (profiles['full_name'] ?? 'Staff').toString();
    }
    if (profiles is Map) {
      return (profiles['full_name'] ?? 'Staff').toString();
    }
    if (profiles is List && profiles.isNotEmpty) {
      final first = profiles.first;
      if (first is Map<String, dynamic>) {
        return (first['full_name'] ?? 'Staff').toString();
      }
      if (first is Map) {
        return (first['full_name'] ?? 'Staff').toString();
      }
    }
    return 'Staff';
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  Future<void> loadVisits() async {
    setState(() => isLoading = true);

    try {
      visits = await _repo.getVisits();
    } catch (e) {
      print('ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load visits.')),
        );
      }
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    loadVisits();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = visits;

    if (_handledBy != 'All') {
      list = list.where((v) => _getStaffName(v['profiles']) == _handledBy).toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((v) {
        final patient = v['patients'];
        final patientMap = patient is Map<String, dynamic>
            ? patient
            : patient is Map
                ? patient.cast<String, dynamic>()
                : null;
        final patientName = getPatientName(patientMap).toLowerCase();
        final notes = (v['notes'] ?? v['assessment'] ?? '').toString().toLowerCase();
        return patientName.contains(q) || notes.contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> createVisit({
    required String selectedPatientId,
    required String notes,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    await _repo.createVisit({
      'patient_id': selectedPatientId,
      'visit_date': DateTime.now().toIso8601String(),
      'notes': notes,
      'staff_id': currentUser?.id,
    });
    await loadVisits();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handlers = <String>{
      'All',
      ...visits.map((v) => _getStaffName(v['profiles'])).where((s) => s.trim().isNotEmpty),
    }.toList();

    return Padding(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Visits',
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
                        SizedBox(
                          width: 240,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'From date',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 240,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'To date',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _handledBy,
                          items: handlers
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _handledBy = v ?? 'All'),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search patient',
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _search = v),
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
                            ? const Center(child: Text('No visits found.'))
                            : AppTable<Map<String, dynamic>>(
                                columns: const [
                                  AppTableColumn('date', 'Date/Time', width: 140),
                                  AppTableColumn('patient', 'Patient', width: 160),
                                  AppTableColumn('complaint', 'Complaint', width: 200),
                                  AppTableColumn('handledBy', 'Handled by', width: 120),
                                ],
                                rows: _filtered,
                                cellBuilder: (visit, key) {
                                  final patientDynamic = visit['patients'];
                                  final patientMap = patientDynamic is Map<String, dynamic>
                                      ? patientDynamic
                                      : patientDynamic is Map
                                          ? patientDynamic.cast<String, dynamic>()
                                          : null;

                                  switch (key) {
                                    case 'date':
                                      final dt = _parseDateTime(visit['visit_date']);
                                      return Text(dt == null ? '-' : Formatters.dateTime(dt));
                                    case 'patient':
                                      return Text(getPatientName(patientMap));
                                    case 'complaint':
                                      return Text((visit['notes'] ?? '-').toString());
                                    case 'handledBy':
                                      return Text(_getStaffName(visit['profiles']));
                                    default:
                                      return const SizedBox.shrink();
                                  }
                                },
                                onRowTap: (visit) {
                                  final visitModel = Visit.fromMap(visit);
                                  widget.onOpenDrawer(
                                    VisitDrawer(
                                      visit: visitModel,
                                      onClose: () => widget.onOpenDrawer(null),
                                      onVisitUpdated: () async => loadVisits(),
                                      onVisitDeleted: () async {
                                        widget.onOpenDrawer(null);
                                        await loadVisits();
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
}

