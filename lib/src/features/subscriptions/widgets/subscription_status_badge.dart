import 'package:educore/src/features/subscriptions/models/subscription.dart';
import 'package:flutter/material.dart';

class SubscriptionStatusBadge extends StatelessWidget {
  const SubscriptionStatusBadge({super.key, required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg, label) = switch (status) {
      SubscriptionStatus.active => (
          const Color(0xFF16A34A).withValues(alpha: 0.10),
          const Color(0xFF15803D),
          'Active',
        ),
      SubscriptionStatus.pendingApproval => (
          const Color(0xFFF59E0B).withValues(alpha: 0.11),
          const Color(0xFFB45309),
          'Pending',
        ),
      SubscriptionStatus.expired => (
          const Color(0xFFF97316).withValues(alpha: 0.12),
          const Color(0xFFB45309),
          'Expired',
        ),
      SubscriptionStatus.canceled => (
          cs.onSurfaceVariant.withValues(alpha: 0.12),
          cs.onSurfaceVariant,
          'Canceled',
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

