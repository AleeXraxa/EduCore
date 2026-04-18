import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/audit/widgets/audit_log_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class AuditLogsTable extends StatelessWidget {
  const AuditLogsTable({super.key, required this.logs});

  final List<AuditLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const AppEmptyState(
        title: 'No Logs Found',
        description: 'Critical system actions will appear here once they are performed.',
        icon: Icons.history_edu_rounded,
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest.withValues(alpha: 0.3)),
          headingTextStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
          columns: const [
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Module')),
            DataColumn(label: Text('Actor')),
            DataColumn(label: Text('Institute')),
            DataColumn(label: Text('Severity')),
            DataColumn(label: Text('Created At')),
            DataColumn(label: Text('')), 
          ],
          rows: logs.map((log) {
            return DataRow(
              onSelectChanged: (_) => AuditLogDetailsDialog.show(context, log),
              cells: [
                DataCell(
                  Text(
                    log.action.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                DataCell(
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(
                       color: cs.secondaryContainer.withValues(alpha: 0.5),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                        log.module.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: cs.onSecondaryContainer,
                        ),
                     ),
                   ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        log.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        log.actorId.substring(0, min(8, log.actorId.length)).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    log.academyId.toUpperCase(), 
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
                DataCell(_SeverityBadge(log.severity)),
                DataCell(
                  Text(
                    DateFormat('MMM dd, HH:mm:ss').format(log.createdAt),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                const DataCell(Icon(Icons.chevron_right_rounded, size: 20)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge(this.severity);
  final AuditSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      AuditSeverity.critical => Colors.red,
      AuditSeverity.warning => Colors.orange,
      AuditSeverity.info => Colors.blueGrey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
