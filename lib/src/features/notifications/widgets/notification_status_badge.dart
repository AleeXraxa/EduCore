import 'package:educore/src/features/notifications/models/admin_notification.dart';
import 'package:flutter/material.dart';

class AdminNotificationStatusBadge extends StatelessWidget {
  const AdminNotificationStatusBadge({super.key, required this.status});

  final AdminNotificationStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, label) = switch (status) {
      AdminNotificationStatus.sent => (
          const Color(0xFF16A34A).withValues(alpha: 0.10),
          const Color(0xFF15803D),
          'Sent',
        ),
      AdminNotificationStatus.scheduled => (
          cs.primary.withValues(alpha: 0.10),
          cs.primary,
          'Scheduled',
        ),
      AdminNotificationStatus.failed => (
          const Color(0xFFEF4444).withValues(alpha: 0.10),
          const Color(0xFFB91C1C),
          'Failed',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
            ),
      ),
    );
  }
}

