import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/notifications/models/admin_notification.dart';
import 'package:educore/src/features/notifications/widgets/notification_status_badge.dart';
import 'package:educore/src/features/notifications/widgets/notification_type_pill.dart';
import 'package:flutter/material.dart';

class NotificationDetailsDialog extends StatelessWidget {
  const NotificationDetailsDialog({
    super.key,
    required this.notification,
    required this.onResend,
    required this.onDelete,
  });

  final AdminNotification notification;
  final VoidCallback onResend;
  final VoidCallback onDelete;

  static Future<void> show(
    BuildContext context, {
    required AdminNotification notification,
    required VoidCallback onResend,
    required VoidCallback onDelete,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => NotificationDetailsDialog(
        notification: notification,
        onResend: onResend,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification details',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Review message, target, and delivery status.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        AdminNotificationTypePill(type: notification.type),
                        const SizedBox(width: 10),
                        AdminNotificationStatusBadge(
                          status: notification.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.30,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(
                        notification.message,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _KV(
                      label: 'Target',
                      value:
                          notification.audience ==
                              AdminNotificationAudience.allInstitutes
                          ? 'All institutes'
                          : '${notification.targets.length} institutes',
                    ),
                    const SizedBox(height: 10),
                    _KV(
                      label: 'Sent',
                      value: _fmtDateTime(notification.createdAt),
                    ),
                    if (notification.scheduledFor != null) ...[
                      const SizedBox(height: 10),
                      _KV(
                        label: 'Schedule',
                        value: _fmtDateTime(notification.scheduledFor!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resend creates a new delivery attempt with the same content.',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onDelete();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB91C1C),
                    ),
                    child: const Text('Delete'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      onResend();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    label: const Text('Resend'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

String _fmtDateTime(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd • $hh:$mi';
}
