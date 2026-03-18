import 'package:flutter/material.dart';

/// Reusable data table: columns + row builder, hover, row click, horizontal scroll.
class AppTable<T> extends StatelessWidget {
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.cellBuilder,
    this.onRowTap,
    this.noDataMessage = 'No data',
  });

  final List<AppTableColumn> columns;
  final List<T> rows;
  final Widget Function(T row, String columnKey) cellBuilder;
  final void Function(T row)? onRowTap;
  final String noDataMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            noDataMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              columnWidths: Map.fromEntries(
                columns.asMap().entries.map((e) => MapEntry(
                      e.key,
                      e.value.width != null ? FixedColumnWidth(e.value.width!) : const FlexColumnWidth(1),
                    )),
              ),
              border: TableBorder(
                horizontalInside: BorderSide(color: theme.dividerColor),
                bottom: BorderSide(color: theme.dividerColor),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  children: columns
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                c.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                ...rows.map((row) => TableRow(
                      children: columns.map((c) {
                        return _TableRowCell<T>(
                          onTap: onRowTap != null ? () => onRowTap!(row) : null,
                          child: cellBuilder(row, c.key),
                        );
                      }).toList(),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppTableColumn {
  const AppTableColumn(this.key, this.label, {this.width});
  final String key;
  final String label;
  final double? width;
}

class _TableRowCell<T> extends StatelessWidget {
  const _TableRowCell({this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use translucent so we only hit-test when this box has been laid out (avoids
    // "Cannot hit test a render box that has never been laid out").
    final behavior = onTap != null ? HitTestBehavior.translucent : HitTestBehavior.deferToChild;

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        behavior: behavior,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium ?? const TextStyle(),
            child: child,
          ),
        ),
      ),
    );
  }
}
