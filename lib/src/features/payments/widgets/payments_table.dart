import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/payments/models/payment.dart';
import 'package:educore/src/features/payments/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';

class PaymentsTable extends StatelessWidget {
  const PaymentsTable({
    super.key,
    required this.items,
    required this.onAction,
    required this.onViewProof,
  });

  final List<Payment> items;
  final ValueChanged<PaymentRowAction> onAction;
  final ValueChanged<Payment> onViewProof;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 1140 ? 1140.0 : constraints.maxWidth;
        final cs = Theme.of(context).colorScheme;

        return AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    const _Header(),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.75),
                    ),
                    if (items.isEmpty)
                      const _Empty()
                    else
                      for (var i = 0; i < items.length; i++)
                        _Row(
                          index: i,
                          item: items[i],
                          onAction: onAction,
                          onViewProof: onViewProof,
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
        child: const Row(
          children: [
            Expanded(flex: 26, child: Text('Institute')),
            Expanded(
              flex: 12,
              child: Align(alignment: Alignment.centerRight, child: Text('Amount')),
            ),
            Expanded(flex: 14, child: Text('Method')),
            Expanded(
              flex: 14,
              child: Align(alignment: Alignment.centerRight, child: Text('Date')),
            ),
            Expanded(flex: 12, child: Text('Status')),
            SizedBox(width: 120, child: Text('Proof')),
            SizedBox(width: 160, child: Align(alignment: Alignment.centerRight, child: Text('Actions'))),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.index,
    required this.item,
    required this.onAction,
    required this.onViewProof,
  });

  final int index;
  final Payment item;
  final ValueChanged<PaymentRowAction> onAction;
  final ValueChanged<Payment> onViewProof;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;

    final zebra = widget.index.isOdd
        ? cs.surfaceContainerHighest.withValues(alpha: 0.22)
        : cs.surface;

    final pending = item.status == PaymentReviewStatus.pending;
    final pendingBg = const Color(0xFFF59E0B).withValues(alpha: 0.06);

    final bg = _hovered
        ? cs.primary.withValues(alpha: 0.040)
        : (pending ? pendingBg : zebra);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 26,
              child: _PrimaryCell(
                title: item.instituteName,
                subtitle: 'ID: ${item.instituteId}',
              ),
            ),
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _fmtMoney(item.amountPkr),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 14,
              child: _MethodPill(method: item.method),
            ),
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _fmtDateTime(item.submittedAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PaymentReviewStatusBadge(status: item.status),
              ),
            ),
            SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => widget.onViewProof(item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('View'),
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: Align(
                alignment: Alignment.centerRight,
                child: pending
                    ? _QuickActions(
                        onApprove: () => widget.onAction(
                          PaymentRowAction(PaymentMenuAction.approve, item.id),
                        ),
                        onReject: () => widget.onAction(
                          PaymentRowAction(PaymentMenuAction.reject, item.id),
                        ),
                      )
                    : _RowMenu(
                        onSelected: (action) => widget.onAction(
                          PaymentRowAction(action, item.id),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCell extends StatelessWidget {
  const _PrimaryCell({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, fg, bg, icon) = switch (method) {
      PaymentMethod.jazzCash => (
          'JazzCash',
          cs.primary,
          cs.primary.withValues(alpha: 0.10),
          Icons.account_balance_wallet_rounded,
        ),
      PaymentMethod.easyPaisa => (
          'EasyPaisa',
          cs.secondary,
          cs.secondary.withValues(alpha: 0.10),
          Icons.qr_code_2_rounded,
        ),
      PaymentMethod.bankTransfer => (
          'Bank',
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest.withValues(alpha: 0.65),
          Icons.account_balance_rounded,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onApprove, required this.onReject});

  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB91C1C),
            side: BorderSide(color: cs.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Reject'),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: onApprove,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onSelected});

  final ValueChanged<PaymentMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<PaymentMenuAction>(
      tooltip: 'Actions',
      onSelected: onSelected,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: PaymentMenuAction.viewDetails,
          child: _MenuRow(icon: Icons.visibility_rounded, label: 'View details'),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          color: cs.surface,
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(
              Icons.payments_rounded,
              color: cs.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No payments found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or filters.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

String _fmtMoney(int pkr) => 'PKR ${_fmtInt(pkr)}';

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

String _fmtDateTime(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd • $hh:$mi';
}

enum PaymentMenuAction { viewDetails, approve, reject }

@immutable
class PaymentRowAction {
  const PaymentRowAction(this.action, this.paymentId);

  final PaymentMenuAction action;
  final String paymentId;
}

