import 'package:flutter/material.dart';
import 'package:educore/src/features/notifications/controllers/institute_notifications_controller.dart';
import 'package:educore/src/features/notifications/models/whatsapp_message.dart';
import 'package:intl/intl.dart';

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
        _buildStats(cs),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest.withValues(alpha: 0.3)),
                columns: const [
                  DataColumn(label: Text('Date & Time')),
                  DataColumn(label: Text('Recipient')),
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Message')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Type')),
                ],
                rows: messages.map((m) => _buildRow(m, cs)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _StatItem(
            label: 'Sent Today',
            value: controller.sentToday.toString(),
            icon: Icons.send_rounded,
            color: cs.primary,
          ),
          const SizedBox(width: 24),
          _StatItem(
            label: 'Failed',
            value: controller.failedCount.toString(),
            icon: Icons.error_outline_rounded,
            color: cs.error,
          ),
          const SizedBox(width: 24),
          _StatItem(
            label: 'Total History',
            value: controller.messages.length.toString(),
            icon: Icons.history_rounded,
            color: cs.secondary,
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(WhatsAppMessage m, ColorScheme cs) {
    final isSuccess = m.status == WhatsAppMessageStatus.sent;
    
    return DataRow(
      cells: [
        DataCell(Text(DateFormat('MMM dd, hh:mm a').format(m.createdAt))),
        DataCell(Text(m.recipient)),
        DataCell(Text(m.studentName ?? '-')),
        DataCell(
          SizedBox(
            width: 300,
            child: Text(
              m.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
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
          ),
        ),
        DataCell(Text(m.type.toUpperCase(), style: const TextStyle(fontSize: 10))),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
