import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../utils/breakpoints.dart';
import '../../widgets/section_card.dart';

/// Reports page: left list of report types, right report viewer placeholder + Export PDF/CSV (UI only).
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedReportIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final padding = Breakpoints.pagePadding(context);
    final leftWidth = Breakpoints.isSmall(context) ? 200.0 : 260.0;
    final gap = Breakpoints.sectionGap(context);

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
                itemCount: mockReportTypes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final selected = _selectedReportIndex == i;
                  return ListTile(
                    selected: selected,
                    title: Text(mockReportTypes[i]),
                    onTap: () => setState(() => _selectedReportIndex = i),
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
                              mockReportTypes[_selectedReportIndex],
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
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
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: const Text('Export PDF'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.table_chart_rounded, size: 18),
                              label: const Text('Export CSV'),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mockReportTypes[_selectedReportIndex],
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
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                  label: const Text('Export PDF'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.table_chart_rounded, size: 18),
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
                      child: const Center(
                        child: Text(
                          'Report viewer placeholder - select filters and export to generate.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
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
