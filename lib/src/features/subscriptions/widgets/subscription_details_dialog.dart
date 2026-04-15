import 'dart:ui';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/subscriptions/models/subscription.dart';
import 'package:flutter/material.dart';

class SubscriptionDetailsDialog extends StatelessWidget {
  const SubscriptionDetailsDialog({super.key, required this.subscription});

  final Subscription subscription;

  static Future<void> show(BuildContext context, {required Subscription subscription}) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Subscription details',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim, secondary) => SubscriptionDetailsDialog(subscription: subscription),
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutQuart);
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
      child: Container(
        width: isMobile ? size.width * 0.92 : 480,
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.88),
          borderRadius: AppRadii.r24,
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.12), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadii.r24,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(subscription: subscription),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusBanner(status: subscription.status),
                        const SizedBox(height: 24),
                        _SectionTitle(title: 'ACADEMY IDENTITY', icon: Icons.apartment_rounded),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Identifier', value: subscription.instituteId),
                        _InfoRow(label: 'Organization', value: subscription.instituteName),
                        const SizedBox(height: 24),
                        _SectionTitle(title: 'PLAN & QUOTA', icon: Icons.workspace_premium_rounded),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Active Plan', value: subscription.planName),
                        _InfoRow(label: 'Price (Monthly)', value: 'PKR ${_fmtInt(subscription.amountPkr)}'),
                        const SizedBox(height: 24),
                        _SectionTitle(title: 'LIFECYCLE BOUNDARIES', icon: Icons.event_available_rounded),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Start Date', value: _fmtDate(subscription.startDate)),
                        _InfoRow(
                          label: 'Expiry Date',
                          value: _fmtDate(subscription.expiryDate),
                          isWarning: subscription.daysLeft >= 0 && subscription.daysLeft <= 5,
                        ),
                        _InfoRow(
                          label: 'Status Context',
                          value: subscription.daysLeft < 0 ? 'Expired ${subscription.daysLeft.abs()} days ago' : '${subscription.daysLeft} days remaining',
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(title: 'PAYMENT INTELLIGENCE', icon: Icons.account_balance_wallet_rounded),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Current Status',
                          value: _paymentLabel(subscription.paymentStatus),
                          valueColor: _paymentColor(subscription.paymentStatus),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primaryContainer.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Snapshot from core billing systems',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          const Color(0xFF16A34A).withValues(alpha: 0.1),
          const Color(0xFF16A34A),
          Icons.verified_rounded,
          'This subscription is globally active and authorized.'
        ),
      SubscriptionStatus.pendingApproval => (
          const Color(0xFF2563EB).withValues(alpha: 0.1),
          const Color(0xFF2563EB),
          Icons.hourglass_empty_rounded,
          'Awaiting administrative verification and plan assignment.'
        ),
      SubscriptionStatus.expired => (
          const Color(0xFFDC2626).withValues(alpha: 0.1),
          const Color(0xFFDC2626),
          Icons.error_outline_rounded,
          'Validity period exceeded. Core services may be restricted.'
        ),
      SubscriptionStatus.canceled => (
          const Color(0xFF6B7280).withValues(alpha: 0.1),
          const Color(0xFF6B7280),
          Icons.cancel_outlined,
          'Account has been manually terminated or suspended.'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.r16,
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Color.lerp(fg, Colors.black, 0.2),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: cs.primary,
          ),
        ),
      ],
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
    final valCol = valueColor ?? (isWarning ? const Color(0xFFB45309) : cs.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: const Text('Dismiss Panel', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
            ),
            child: const Text('Acknowledge', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
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
      PaymentStatus.paid => 'Fully Verified',
      PaymentStatus.proofSubmitted => 'Manual Proof Scan',
      PaymentStatus.unpaid => 'Outstanding Balance',
      PaymentStatus.rejected => 'Invalid Document',
    };

Color _paymentColor(PaymentStatus s) => switch (s) {
      PaymentStatus.paid => const Color(0xFF16A34A),
      PaymentStatus.proofSubmitted => const Color(0xFF2563EB),
      PaymentStatus.unpaid => const Color(0xFFDC2626),
      PaymentStatus.rejected => const Color(0xFFB91C1C),
    };
