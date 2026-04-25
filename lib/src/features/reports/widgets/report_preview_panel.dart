import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/features/reports/controllers/reports_controller.dart';
import 'package:educore/src/features/reports/services/report_exporter.dart';

/// Right-side preview panel showing the generated table + export buttons.
class ReportPreviewPanel extends StatelessWidget {
  const ReportPreviewPanel({super.key, required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.reportState) {
      ReportState.idle => _buildIdle(context),
      ReportState.generating => _buildLoading(context),
      ReportState.done => _buildTable(context),
      ReportState.error => _buildError(context),
    };
  }

  Widget _buildIdle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = controller.selectedReport;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                meta?.icon ?? Icons.analytics_rounded,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              meta == null
                  ? 'Select a report from the left panel'
                  : '${meta.label} ready to generate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (meta != null) ...[
              const SizedBox(height: 8),
              Text(
                meta.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Generate Report',
                icon: Icons.play_arrow_rounded,
                onPressed: controller.generateReport,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Generating Report…',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Querying Firestore with your filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Failed to generate report',
      description: 'Check your permissions or network connection and try again.',
    );
  }

  Widget _buildTable(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = controller.rows;
    final headers = controller.columnHeaders;

    if (rows.isEmpty) {
      return AppEmptyState(
        icon: controller.selectedReport?.icon ?? Icons.search_off_rounded,
        title: 'No data found',
        description: 'Try adjusting your filters or selecting a different date range.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_rows_rounded,
                        size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      '${NumberFormat.decimalPattern().format(rows.length)} records',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ExportButton(
                label: 'Print',
                icon: Icons.print_rounded,
                color: const Color(0xFF2563EB), // Changed to primary blue
                onTap: () => _exportPdf(context),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                left: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
                right: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
                bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF2563EB).withValues(alpha: 0.06),
                        ),
                        headingTextStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.5,
                        ),
                        dataTextStyle: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface,
                        ),
                        dividerThickness: 0.5,
                        columnSpacing: 24,
                        columns: headers
                            .map((h) => DataColumn(
                                label: Text(h.toUpperCase())))
                            .toList(),
                        rows: rows.asMap().entries.map((entry) {
                          final isAlt = entry.key % 2 == 1;
                          return DataRow(
                            color: WidgetStateProperty.all(
                              isAlt
                                  ? cs.surfaceContainerLowest
                                  : cs.surface,
                            ),
                            cells: headers.map((h) {
                              final val = entry.value[h]?.toString() ?? '';
                              return DataCell(_StyledCell(
                                value: val,
                                header: h,
                              ));
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      await ReportExporter.exportPdf(
        title: controller.selectedReport?.label ?? 'Report',
        headers: controller.columnHeaders,
        rows: controller.rows,
        academy: controller.academy,
        settings: controller.instituteSettings,
        filters: controller.filters,
      );
      await controller.logExport('PDF');
      if (context.mounted) {
        AppToasts.showSuccess(context, message: 'PDF export started');
      }
    } catch (e) {
      if (context.mounted) {
        AppToasts.showError(context, message: 'PDF export failed: $e');
      }
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    try {
      await ReportExporter.exportExcel(
        title: controller.selectedReport?.label ?? 'Report',
        headers: controller.columnHeaders,
        rows: controller.rows,
        academyName: controller.instituteSettings?.appName ?? controller.academy?.name ?? 'EduCore ERP',
      );
      await controller.logExport('Excel');
      if (context.mounted) {
        AppToasts.showSuccess(context, message: 'Excel export started');
      }
    } catch (e) {
      if (context.mounted) {
        AppToasts.showError(context, message: 'Excel export failed: $e');
      }
    }
  }
}

/// Color-coded cell based on value patterns.
class _StyledCell extends StatelessWidget {
  const _StyledCell({required this.value, required this.header});
  final String value;
  final String header;

  @override
  Widget build(BuildContext context) {
    final lowerHeader = header.toLowerCase();
    final lowerVal = value.toLowerCase();

    Color? color;
    FontWeight weight = FontWeight.normal;

    if (lowerHeader == 'status' || lowerHeader == 'p&l (rs.)') {
      if (lowerVal == 'paid' || lowerVal == 'profit' || lowerVal == 'pass' || lowerVal == 'active') {
        color = const Color(0xFF16A34A);
        weight = FontWeight.w700;
      } else if (lowerVal == 'pending' || lowerVal == 'loss' || lowerVal == 'fail' || lowerVal == 'inactive') {
        color = const Color(0xFFDC2626);
        weight = FontWeight.w700;
      } else if (lowerVal == 'partial') {
        color = const Color(0xFFF59E0B);
        weight = FontWeight.w700;
      }
    }

    // Negative P&L value
    if (lowerHeader.contains('p&l') && value.startsWith('-')) {
      color = const Color(0xFFDC2626);
      weight = FontWeight.w700;
    } else if (lowerHeader.contains('p&l') && double.tryParse(value) != null) {
      color = const Color(0xFF16A34A);
      weight = FontWeight.w700;
    }

    return Text(
      value,
      style: TextStyle(color: color, fontWeight: weight),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
