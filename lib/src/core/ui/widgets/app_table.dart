import 'package:flutter/material.dart';

class AppTableColumn<T> {
  final String label;
  final Widget Function(T) builder;
  final int? flex;
  final double? width;
  final bool center;

  AppTableColumn({
    required this.label,
    required this.builder,
    this.flex,
    this.width,
    this.center = false,
  });
}

class AppTable<T> extends StatelessWidget {
  const AppTable({
    super.key,
    required this.items,
    required this.columns,
    this.onRowTap,
  });

  final List<T> items;
  final List<AppTableColumn<T>> columns;
  final Function(T)? onRowTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: {
          for (int i = 0; i < columns.length; i++)
            i: columns[i].width != null
                ? FixedColumnWidth(columns[i].width!)
                : FlexColumnWidth(columns[i].flex?.toDouble() ?? 1.0),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant),
              ),
            ),
            children: columns.map((col) => _buildHeaderCell(context, col)).toList(),
          ),
          // Data Rows
          ...items.map((item) => TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                children: columns.map((col) => _buildDataCell(context, col, item)).toList(),
              )),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, AppTableColumn<T> col) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Text(
        col.label.toUpperCase(),
        textAlign: col.center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1.0,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, AppTableColumn<T> col, T item) {
    return InkWell(
      onTap: onRowTap != null ? () => onRowTap!(item) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Align(
          alignment: col.center ? Alignment.center : Alignment.centerLeft,
          child: col.builder(item),
        ),
      ),
    );
  }
}
