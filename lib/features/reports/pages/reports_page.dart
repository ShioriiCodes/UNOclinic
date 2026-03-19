// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../utils/breakpoints.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_table.dart';
import '../../../widgets/section_card.dart';
import '../repositories/report_repository.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> reportData = [];
  bool isLoading = false;

  DateTime? fromDate;
  DateTime? toDate;

  String selectedReport = 'visits';

  final ReportRepository _repo = ReportRepository();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final List<Map<String, String>> _reportTypes = const [
    {'id': 'visits', 'label': 'Visits Summary'},
    {'id': 'certificates', 'label': 'Certificates'},
    {'id': 'referrals', 'label': 'Referrals'},
    {'id': 'inventory', 'label': 'Inventory'},
    {'id': 'demographics', 'label': 'Demographics'},
  ];

  String getFullName(Map<String, dynamic>? patient) {
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

  String _cellText(Map<String, dynamic> row, String key) {
    switch (selectedReport) {
      case 'visits':
        if (key == 'date') return Formatters.date(_parseDate(row['visit_date']));
        if (key == 'patient') {
          final patient =
              row['patients'] is Map
                  ? (row['patients'] as Map).cast<String, dynamic>()
                  : null;
          return getFullName(patient);
        }
        if (key == 'notes') return (row['notes'] ?? '-').toString();
        break;
      case 'certificates':
        if (key == 'date') {
          final requestDate = _parseDate(row['request_date'] ?? row['created_at']);
          return Formatters.date(requestDate);
        }
        if (key == 'patient') {
          final patient =
              row['patients'] is Map
                  ? (row['patients'] as Map).cast<String, dynamic>()
                  : null;
          return getFullName(patient);
        }
        if (key == 'status') return (row['status'] ?? '-').toString();
        if (key == 'releasedDate') {
          final released = _parseDate(row['released_date']);
          final status = (row['status'] ?? '').toString().toUpperCase();
          final fallback = status == 'RELEASED' ? _parseDate(row['updated_at']) : null;
          return Formatters.date(released ?? fallback);
        }
        break;
      case 'referrals':
        if (key == 'date') return Formatters.date(_parseDate(row['referral_date']));
        if (key == 'patient') {
          final patient =
              row['patients'] is Map
                  ? (row['patients'] as Map).cast<String, dynamic>()
                  : null;
          return getFullName(patient);
        }
        if (key == 'referredTo') return (row['referred_to'] ?? '-').toString();
        if (key == 'status') return (row['status'] ?? '-').toString();
        break;
      case 'inventory':
        if (key == 'name') return (row['name'] ?? '-').toString();
        if (key == 'category') return (row['category'] ?? '-').toString();
        if (key == 'stock') return (row['minimum_stock'] ?? '-').toString();
        break;
      case 'demographics':
        if (key == 'name') {
          final first = (row['first_name'] ?? '').toString();
          final last = (row['last_name'] ?? '').toString();
          final full = '$first $last'.trim();
          return full.isEmpty ? 'Unknown' : full;
        }
        if (key == 'type') return (row['type'] ?? '-').toString();
        if (key == 'department') return (row['department'] ?? '-').toString();
        break;
    }
    return '-';
  }

  List<List<String>> _exportRows() {
    final headers = _columns.map((c) => c.label).toList();
    final rows = reportData
        .map((row) => _columns.map((c) => _cellText(row, c.key)).toList())
        .toList();
    return [headers, ...rows];
  }

  Future<Directory?> _pickExportDirectory() async {
    try {
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save export',
        lockParentWindow: true,
      );
      if (selectedPath == null || selectedPath.trim().isEmpty) return null;
      final dir = Directory(selectedPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      return null;
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '$y$m$d-$hh$mm$ss';
  }

  Future<void> _exportCsv() async {
    try {
      final picked = await _pickExportDirectory();
      if (picked == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No folder selected.')));
        return;
      }
      final dir = picked;

      final rows = _exportRows();
      final csv = _toCsv(rows);
      final file = File(
        '${dir.path}${Platform.pathSeparator}${selectedReport}_${_timestamp()}.csv',
      );
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV exported: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export CSV: $e')));
    }
  }

  Future<void> _exportPdf() async {
    try {
      final picked = await _pickExportDirectory();
      if (picked == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No folder selected.')));
        return;
      }
      final dir = picked;

      final rows = _exportRows();
      final headers = rows.first;
      final data = rows.length > 1 ? rows.sublist(1) : <List<String>>[];
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Text('UNOclinic ${selectedReport.toUpperCase()} Report'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(headers: headers, data: data),
          ],
        ),
      );
      final file = File(
        '${dir.path}${Platform.pathSeparator}${selectedReport}_${_timestamp()}.pdf',
      );
      await file.writeAsBytes(await doc.save());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF exported: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }

  String _toCsv(List<List<String>> rows) {
    return rows
        .map(
          (row) => row
              .map((cell) {
                final safe = cell.replaceAll('"', '""');
                return '"$safe"';
              })
              .join(','),
        )
        .join('\n');
  }

  Future<void> loadReport() async {
    setState(() => isLoading = true);

    try {
      if (selectedReport == 'visits') {
        reportData = await _repo.getVisitsReport(fromDate, toDate);
      } else if (selectedReport == 'certificates') {
        reportData = await _repo.getCertificatesReport(fromDate, toDate);
      } else if (selectedReport == 'referrals') {
        reportData = await _repo.getReferralsReport(fromDate, toDate);
      } else if (selectedReport == 'inventory') {
        reportData = await _repo.getInventoryReport();
      } else if (selectedReport == 'demographics') {
        reportData = await _repo.getPatientDemographics();
      } else {
        reportData = [];
      }
    } catch (e) {
      print('REPORT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? now,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      fromDate = picked;
      _fromController.text = Formatters.date(picked);
    });
    await loadReport();
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? fromDate ?? now,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      toDate = picked;
      _toController.text = Formatters.date(picked);
    });
    await loadReport();
  }

  void _selectReport(String id) {
    setState(() => selectedReport = id);
    loadReport();
  }

  List<AppTableColumn> get _columns {
    switch (selectedReport) {
      case 'visits':
        return const [
          AppTableColumn('date', 'Visit date', width: 140),
          AppTableColumn('patient', 'Patient', width: 200),
          AppTableColumn('notes', 'Notes', width: 260),
        ];
      case 'certificates':
        return const [
          AppTableColumn('date', 'Request date', width: 140),
          AppTableColumn('patient', 'Patient', width: 200),
          AppTableColumn('status', 'Status', width: 120),
          AppTableColumn('releasedDate', 'Released date', width: 140),
        ];
      case 'referrals':
        return const [
          AppTableColumn('date', 'Referral date', width: 140),
          AppTableColumn('patient', 'Patient', width: 200),
          AppTableColumn('referredTo', 'Referred to', width: 180),
          AppTableColumn('status', 'Status', width: 120),
        ];
      case 'inventory':
        return const [
          AppTableColumn('name', 'Name', width: 200),
          AppTableColumn('category', 'Category', width: 160),
          AppTableColumn('stock', 'Minimum stock', width: 140),
        ];
      case 'demographics':
        return const [
          AppTableColumn('name', 'Patient', width: 220),
          AppTableColumn('type', 'Type', width: 120),
          AppTableColumn('department', 'Department', width: 180),
        ];
      default:
        return const [AppTableColumn('data', 'Data')];
    }
  }

  Widget _cellBuilder(Map<String, dynamic> row, String key) {
    switch (selectedReport) {
      case 'visits':
        if (key == 'date') {
          return Text(Formatters.date(_parseDate(row['visit_date'])));
        }
        if (key == 'patient') {
          final patient =
              row['patients'] is Map
                  ? (row['patients'] as Map).cast<String, dynamic>()
                  : null;
          return Text(getFullName(patient));
        }
        if (key == 'notes') {
          return Text((row['notes'] ?? '-').toString());
        }
        break;
      case 'certificates':
        if (key == 'date') {
          final requestDate = _parseDate(row['request_date'] ?? row['created_at']);
          return Text(Formatters.date(requestDate));
        }
        if (key == 'patient') {
          final patient =
              row['patients'] is Map
                  ? (row['patients'] as Map).cast<String, dynamic>()
                  : null;
          return Text(getFullName(patient));
        }
        if (key == 'status') {
          return Text((row['status'] ?? '-').toString());
        }
        if (key == 'releasedDate') {
          final released = _parseDate(row['released_date']);
          final status = (row['status'] ?? '').toString().toUpperCase();
          final fallback = status == 'RELEASED' ? _parseDate(row['updated_at']) : null;
          return Text(Formatters.date(released ?? fallback));
        }
        break;
      case 'referrals':
        if (key == 'date') {
          return Text(Formatters.date(_parseDate(row['referral_date'])));
        }
        if (key == 'patient') {
          final patient =
              row['patients'] is Map
                  ? (row['patients'] as Map).cast<String, dynamic>()
                  : null;
          return Text(getFullName(patient));
        }
        if (key == 'referredTo') {
          return Text((row['referred_to'] ?? '-').toString());
        }
        if (key == 'status') {
          return Text((row['status'] ?? '-').toString());
        }
        break;
      case 'inventory':
        if (key == 'name') return Text((row['name'] ?? '-').toString());
        if (key == 'category') return Text((row['category'] ?? '-').toString());
        if (key == 'stock') return Text((row['minimum_stock'] ?? '-').toString());
        break;
      case 'demographics':
        if (key == 'name') {
          final first = (row['first_name'] ?? '').toString();
          final last = (row['last_name'] ?? '').toString();
          final full = '$first $last'.trim();
          return Text(full.isEmpty ? 'Unknown' : full);
        }
        if (key == 'type') return Text((row['type'] ?? '-').toString());
        if (key == 'department') {
          return Text((row['department'] ?? '-').toString());
        }
        break;
    }

    return const SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Breakpoints.pagePadding(context);
    final leftWidth = Breakpoints.isSmall(context) ? 200.0 : 260.0;
    final gap = Breakpoints.sectionGap(context);

    final selectedLabel =
        _reportTypes.firstWhere((e) => e['id'] == selectedReport)['label'] ??
        'Report';

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: leftWidth,
            child: SectionCard(
              title: 'Report types',
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _reportTypes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final id = _reportTypes[i]['id'] ?? 'visits';
                  final label = _reportTypes[i]['label'] ?? id;
                  final selected = selectedReport == id;
                  return ListTile(
                    selected: selected,
                    title: Text(label),
                    onTap: () => _selectReport(id),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: SectionCard(
              padding: const EdgeInsets.all(24),
              expandChild: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      if (!compact) {
                        return Row(
                          children: [
                            Text(
                              selectedLabel,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 160,
                              child: TextField(
                                controller: _fromController,
                                readOnly: true,
                                onTap: _pickFromDate,
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
                                controller: _toController,
                                readOnly: true,
                                onTap: _pickToDate,
                                decoration: const InputDecoration(
                                  hintText: 'To date',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: _exportPdf,
                              icon: const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 18,
                              ),
                              label: const Text('Export PDF'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _exportCsv,
                              icon: const Icon(
                                Icons.table_chart_rounded,
                                size: 18,
                              ),
                              label: const Text('Export CSV'),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLabel,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: TextField(
                                    controller: _fromController,
                                    readOnly: true,
                                    onTap: _pickFromDate,
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
                                    controller: _toController,
                                    readOnly: true,
                                    onTap: _pickToDate,
                                    decoration: const InputDecoration(
                                      hintText: 'To date',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: _exportPdf,
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Export PDF'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _exportCsv,
                                  icon: const Icon(
                                    Icons.table_chart_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Export CSV'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : reportData.isEmpty
                          ? const Center(
                              child: Text(
                                'No report data found for selected filters.',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: AppTable<Map<String, dynamic>>(
                                columns: _columns,
                                rows: reportData,
                                cellBuilder: _cellBuilder,
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
