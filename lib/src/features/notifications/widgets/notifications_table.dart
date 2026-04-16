import 'package:educore/src/features/notifications/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsTable extends StatelessWidget {
  final List<AppNotification> notifications;
  final Function(String) onDelete;

  const NotificationsTable({
    super.key,
    required this.notifications,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('TITLE')),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('TARGET')),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: notifications.map((n) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        n.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                DataCell(_TypeBadge(type: n.type)),
                DataCell(
                  Text(
                    n.targetType == NotificationTargetType.all
                        ? 'All Institutes'
                        : n.academyName ?? 'Single Institute',
                  ),
                ),
                DataCell(
                  Text(DateFormat('MMM dd, yyyy • HH:mm').format(n.createdAt)),
                ),
                DataCell(_StatusBadge(status: n.status)),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                    onPressed: () => _confirmDelete(context, n),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppNotification n) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete "${n.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDelete(n.id);
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final NotificationType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (type) {
      case NotificationType.broadcast:
        color = Colors.blue;
        icon = Icons.campaign_rounded;
        break;
      case NotificationType.targeted:
        color = Colors.orange;
        icon = Icons.person_pin_rounded;
        break;
      case NotificationType.system:
        color = Colors.purple;
        icon = Icons.settings_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final NotificationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == NotificationStatus.sent
        ? Colors.green
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
