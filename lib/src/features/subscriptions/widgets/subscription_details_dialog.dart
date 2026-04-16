import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/subscriptions/models/subscription.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class SubscriptionDetailsDialog extends StatelessWidget {
  const SubscriptionDetailsDialog({super.key, required this.subscription});

  final Subscription subscription;

  static Future<void> show(
    BuildContext context, {
    required Subscription subscription,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Subscription details',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim, secondary) =>
          SubscriptionDetailsDialog(subscription: subscription),
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutQuart,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? size.width * 0.92 : 520,
          maxHeight: size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadii.r24,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(subscription: subscription),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _AnimatedSlideIn(
                        delayIndex: 0,
                        child: _StatusBanner(status: subscription.status),
                      ),
                      const SizedBox(height: 24),
                      _AnimatedSlideIn(
                        delayIndex: 1,
                        child: _GroupCard(
                          title: 'INSTITUTE INFO',
                          icon: Icons.business_rounded,
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Institute ID',
                                value: subscription.instituteId,
                              ),
                              _InfoRow(
                                label: 'Institute Name',
                                value: subscription.instituteName,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AnimatedSlideIn(
                        delayIndex: 2,
                        child: _GroupCard(
                          title: 'PLAN & BILLING',
                          icon: Icons.workspace_premium_rounded,
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Plan Name',
                                value: subscription.planName,
                              ),
                              _InfoRow(
                                label: 'Monthly Fee',
                                value: 'PKR ${_fmtInt(subscription.amountPkr)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AnimatedSlideIn(
                        delayIndex: 3,
                        child: _GroupCard(
                          title: 'SUBSCRIPTION PERIOD',
                          icon: Icons.event_note_rounded,
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Start Date',
                                value: _fmtDate(subscription.startDate),
                              ),
                              _InfoRow(
                                label: 'Expiry Date',
                                value: _fmtDate(subscription.expiryDate),
                                isWarning:
                                    subscription.daysLeft >= 0 &&
                                    subscription.daysLeft <= 5,
                              ),
                              _InfoRow(
                                label: 'Time Remaining',
                                value: subscription.daysLeft < 0
                                    ? 'Expired ${subscription.daysLeft.abs()} days ago'
                                    : '${subscription.daysLeft} days remaining',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AnimatedSlideIn(
                        delayIndex: 4,
                        child: _GroupCard(
                          title: 'PAYMENT STATUS',
                          icon: Icons.account_balance_wallet_rounded,
                          child: _InfoRow(
                            label: 'Payment',
                            value: _paymentLabel(subscription.paymentStatus),
                            valueColor: _paymentColor(
                              subscription.paymentStatus,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Footer(onClose: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: cs.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan and billing overview for this subscription.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, msg) = switch (status) {
      SubscriptionStatus.active => (
        const Color(0xFF16A34A).withValues(alpha: 0.08),
        const Color(0xFF16A34A),
        Icons.verified_user_rounded,
        'Subscription is active. The institute has full access to its plan features.',
      ),
      SubscriptionStatus.pendingApproval => (
        const Color(0xFF2563EB).withValues(alpha: 0.08),
        const Color(0xFF2563EB),
        Icons.hourglass_top_rounded,
        'Awaiting Super Admin approval before this subscription becomes active.',
      ),
      SubscriptionStatus.expired => (
        const Color(0xFFDC2626).withValues(alpha: 0.08),
        const Color(0xFFDC2626),
        Icons.notification_important_rounded,
        'This subscription has expired. Please renew to restore institute access.',
      ),
      SubscriptionStatus.canceled => (
        const Color(0xFF6B7280).withValues(alpha: 0.08),
        const Color(0xFF6B7280),
        Icons.cancel_outlined,
        'This subscription has been cancelled.',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.r16,
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isWarning = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool isWarning;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valCol =
        valueColor ?? (isWarning ? const Color(0xFFB45309) : cs.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: valCol,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [AppPrimaryButton(onPressed: onClose, label: 'Close')],
      ),
    );
  }
}

class _AnimatedSlideIn extends StatelessWidget {
  const _AnimatedSlideIn({required this.child, required this.delayIndex});
  final Widget child;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delayIndex * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

String _fmtDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

String _fmtInt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - 1 - i;
    b.write(s[idx]);
    if ((i + 1) % 3 == 0 && idx != 0) b.write(',');
  }
  return b.toString().split('').reversed.join();
}

String _paymentLabel(PaymentStatus s) => switch (s) {
  PaymentStatus.paid => 'Paid',
  PaymentStatus.proofSubmitted => 'Proof Submitted – Pending Review',
  PaymentStatus.unpaid => 'Unpaid',
  PaymentStatus.rejected => 'Proof Rejected',
};

Color _paymentColor(PaymentStatus s) => switch (s) {
  PaymentStatus.paid => const Color(0xFF16A34A),
  PaymentStatus.proofSubmitted => const Color(0xFF2563EB),
  PaymentStatus.unpaid => const Color(0xFFDC2626),
  PaymentStatus.rejected => const Color(0xFFB91C1C),
};
