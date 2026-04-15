import 'package:educore/src/core/models/payment_record.dart';
import 'package:flutter/material.dart';

class PaymentReviewStatusBadge extends StatelessWidget {
  const PaymentReviewStatusBadge({super.key, required this.status});

  final PaymentReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg, label) = switch (status) {
      PaymentReviewStatus.pending => (
          const Color(0xFFF59E0B).withValues(alpha: 0.11),
          const Color(0xFFB45309),
          'Pending',
        ),
      PaymentReviewStatus.approved => (
          const Color(0xFF16A34A).withValues(alpha: 0.10),
          const Color(0xFF15803D),
          'Approved',
        ),
      PaymentReviewStatus.rejected => (
          const Color(0xFFEF4444).withValues(alpha: 0.10),
          const Color(0xFFB91C1C),
          'Rejected',
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

