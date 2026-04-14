import 'package:educore/src/features/subscriptions/models/subscription.dart';
import 'package:flutter/material.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg, label, icon) = switch (status) {
      PaymentStatus.paid => (
          const Color(0xFF16A34A).withValues(alpha: 0.10),
          const Color(0xFF15803D),
          'Paid',
          Icons.check_circle_rounded,
        ),
      PaymentStatus.proofSubmitted => (
          cs.primary.withValues(alpha: 0.10),
          cs.primary,
          'Proof submitted',
          Icons.upload_rounded,
        ),
      PaymentStatus.unpaid => (
          cs.onSurfaceVariant.withValues(alpha: 0.10),
          cs.onSurfaceVariant,
          'Unpaid',
          Icons.hourglass_empty_rounded,
        ),
      PaymentStatus.rejected => (
          const Color(0xFFEF4444).withValues(alpha: 0.10),
          const Color(0xFFB91C1C),
          'Rejected',
          Icons.cancel_rounded,
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
                  letterSpacing: 0.15,
                ),
          ),
        ],
      ),
    );
  }
}

