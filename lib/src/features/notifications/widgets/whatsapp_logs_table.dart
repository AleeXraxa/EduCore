import 'package:flutter/material.dart';
import 'package:educore/src/features/notifications/controllers/institute_notifications_controller.dart';
import 'package:educore/src/features/notifications/models/whatsapp_message.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/core/ui/widgets/app_table.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
class WhatsAppLogsTable extends StatelessWidget {
  const WhatsAppLogsTable({super.key, required this.controller});
  final InstituteNotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final messages = controller.messages;

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'No messages sent yet',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStats(context, cs),
        const Divider(height: 1),
        Expanded(
          child: AppTable<WhatsAppMessage>(
            items: messages,
            columns: [
              AppTableColumn(
                label: 'Date & Time',
                builder: (m) => Text(DateFormat('MMM dd, hh:mm a').format(m.createdAt)),
                flex: 2,
              ),
              AppTableColumn(
                label: 'Recipient',
                builder: (m) => Text(m.recipient),
                flex: 2,
              ),
              AppTableColumn(
                label: 'Student',
                builder: (m) => Text(m.studentName ?? '-'),
                flex: 2,
              ),
              AppTableColumn(
                label: 'Message',
                builder: (m) => Text(
                  m.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                flex: 4,
              ),
              AppTableColumn(
                label: 'Status',
                builder: (m) {
                  final isSuccess = m.status == WhatsAppMessageStatus.sent;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSuccess 
                        ? Colors.green.withValues(alpha: 0.1) 
                        : cs.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m.status.name.toUpperCase(),
                      style: TextStyle(
                        color: isSuccess ? Colors.green : cs.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                flex: 1,
              ),
              AppTableColumn(
                label: 'Type',
                builder: (m) => Text(m.type.toUpperCase(), style: const TextStyle(fontSize: 10)),
                flex: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, ColorScheme cs) {
    final kpis = [
      KpiCardData(
        label: 'Sent Today',
        value: controller.sentToday.toString(),
        icon: Icons.send_rounded,
        gradient: [cs.primary, cs.primaryContainer],
      ),
      KpiCardData(
        label: 'Failed',
        value: controller.failedCount.toString(),
        icon: Icons.error_outline_rounded,
        gradient: [cs.error, cs.errorContainer],
      ),
      KpiCardData(
        label: 'Total History',
        value: controller.messages.length.toString(),
        icon: Icons.history_rounded,
        gradient: [cs.secondary, cs.secondaryContainer],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = screenSizeForWidth(constraints.maxWidth);
          final cols = switch (size) {
            ScreenSize.compact => 1,
            ScreenSize.medium => 3,
            ScreenSize.expanded => 3,
          };
          return AppKpiGrid(columns: cols, items: kpis);
        },
      ),
    );
  }
}
