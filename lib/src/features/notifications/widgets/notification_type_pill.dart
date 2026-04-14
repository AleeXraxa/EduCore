import 'package:educore/src/features/notifications/models/admin_notification.dart';
import 'package:flutter/material.dart';

class AdminNotificationTypePill extends StatelessWidget {
  const AdminNotificationTypePill({super.key, required this.type});

  final AdminNotificationType type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, fg, bg, icon) = switch (type) {
      AdminNotificationType.announcement => (
          'Announcement',
          cs.primary,
          cs.primary.withValues(alpha: 0.10),
          Icons.campaign_rounded,
        ),
      AdminNotificationType.reminder => (
          'Reminder',
          cs.secondary,
          cs.secondary.withValues(alpha: 0.10),
          Icons.notifications_active_rounded,
        ),
      AdminNotificationType.alert => (
          'Alert',
          const Color(0xFFB45309),
          const Color(0xFFF59E0B).withValues(alpha: 0.11),
          Icons.warning_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

