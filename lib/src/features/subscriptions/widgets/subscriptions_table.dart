import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/subscriptions/models/subscription.dart';
import 'package:educore/src/features/subscriptions/widgets/payment_status_badge.dart';
import 'package:educore/src/features/subscriptions/widgets/subscription_status_badge.dart';
import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

class SubscriptionsTable extends StatelessWidget {
  const SubscriptionsTable({
    super.key,
    required this.items,
    required this.onAction,
  });

  final List<Subscription> items;
  final ValueChanged<SubscriptionRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 1180 ? 1180.0 : constraints.maxWidth;
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
                    const _HeaderRow(),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.75),
                    ),
                    if (items.isEmpty)
                      const AppEmptyState(
                        title: 'No Subscriptions Found',
                        description: 'Institute subscription records and history will be listed here.',
                        icon: Icons.receipt_long_rounded,
                      )
                    else
                      for (var i = 0; i < items.length; i++)
                        _Row(
                          index: i,
                          item: items[i],
                          onAction: onAction,
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

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

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
            Expanded(flex: 24, child: Text('Institute')),
            Expanded(flex: 10, child: Text('Plan')),
            Expanded(flex: 10, child: Text('Status')),
            Expanded(
              flex: 12,
              child: Align(alignment: Alignment.centerRight, child: Text('Start')),
            ),
            Expanded(
              flex: 14,
              child: Align(alignment: Alignment.centerRight, child: Text('Expiry')),
            ),
            Expanded(
              flex: 12,
              child: Align(alignment: Alignment.centerRight, child: Text('Amount')),
            ),
            Expanded(flex: 16, child: Text('Payment')),
            SizedBox(width: 44),
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
  });

  final int index;
  final Subscription item;
  final ValueChanged<SubscriptionRowAction> onAction;

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

    final expiring = item.status == SubscriptionStatus.active && item.daysLeft <= 7;
    final expiringBg = item.daysLeft <= 3
        ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
        : cs.primary.withValues(alpha: 0.03);

    final bg = _hovered
        ? cs.primary.withValues(alpha: 0.040)
        : (expiring ? expiringBg : zebra);

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
              flex: 24,
              child: _PrimaryCell(
                title: item.instituteName,
                subtitle: 'ID: ${item.instituteId}',
              ),
            ),
            Expanded(flex: 10, child: _PlanPill(name: item.planName)),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SubscriptionStatusBadge(status: item.status),
              ),
            ),
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerRight,
                child: _DateCell(date: item.startDate),
              ),
            ),
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerRight,
                child: _ExpiryCell(expiry: item.expiryDate, daysLeft: item.daysLeft),
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
              flex: 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PaymentStatusBadge(status: item.paymentStatus),
              ),
            ),
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: _RowMenu(
                  status: item.status,
                  onSelected: (action) =>
                      widget.onAction(SubscriptionRowAction(action, item.id)),
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

class _DateCell extends StatelessWidget {
  const _DateCell({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      _fmtDate(date),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _ExpiryCell extends StatelessWidget {
  const _ExpiryCell({required this.expiry, required this.daysLeft});

  final DateTime expiry;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPast = expiry.isBefore(DateTime.now());

    Color chipBg = cs.surfaceContainerHighest.withValues(alpha: 0.65);
    Color chipFg = cs.onSurfaceVariant;
    if (!isPast && daysLeft <= 3) {
      chipBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      chipFg = const Color(0xFFB45309);
    } else if (!isPast && daysLeft <= 7) {
      chipBg = cs.primary.withValues(alpha: 0.10);
      chipFg = cs.primary;
    }

    final label = isPast ? 'Expired' : '${daysLeft}d left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _fmtDate(expiry),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.60)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: chipFg,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final clean = name.trim().isEmpty ? '—' : name.trim();
    final key = clean.toLowerCase();

    final (fg, bg) = switch (key) {
      'premium' || 'pro' => (
          const Color(0xFF7C3AED),
          const Color(0xFF7C3AED).withValues(alpha: 0.12),
        ),
      'standard' => (
          cs.primary,
          cs.primary.withValues(alpha: 0.10),
        ),
      'basic' || 'demo' => (
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest.withValues(alpha: 0.65),
        ),
      _ => (
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest.withValues(alpha: 0.55),
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
        clean,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

  const _RowMenu({
    required this.status,
    required this.onSelected,
  });

  final SubscriptionStatus status;
  final ValueChanged<SubscriptionMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <PopupMenuEntry<SubscriptionMenuAction>>[
      const PopupMenuItem(
        value: SubscriptionMenuAction.view,
        child: _MenuRow(icon: Icons.visibility_rounded, label: 'View details'),
      ),
      const PopupMenuItem(
        value: SubscriptionMenuAction.edit,
        child: _MenuRow(icon: Icons.edit_rounded, label: 'Edit subscription'),
      ),
      if (status == SubscriptionStatus.pendingApproval) ...[
        const PopupMenuItem(
          value: SubscriptionMenuAction.approve,
          child: _MenuRow(icon: Icons.verified_rounded, label: 'Approve'),
        ),
        const PopupMenuItem(
          value: SubscriptionMenuAction.reject,
          child:
              _MenuRow(icon: Icons.close_rounded, label: 'Reject', danger: true),
        ),
      ],
      const PopupMenuItem(
        value: SubscriptionMenuAction.changePlan,
        child: _MenuRow(icon: Icons.swap_horiz_rounded, label: 'Change plan'),
      ),
      const PopupMenuItem(
        value: SubscriptionMenuAction.extend,
        child:
            _MenuRow(icon: Icons.date_range_rounded, label: 'Extend 30 days'),
      ),
    ];

    return PopupMenuButton<SubscriptionMenuAction>(
      tooltip: 'Actions',
      onSelected: onSelected,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => items,
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
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? const Color(0xFFB91C1C) : cs.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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

String _fmtDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

enum SubscriptionMenuAction { view, edit, approve, reject, changePlan, extend }

@immutable
class SubscriptionRowAction {
  const SubscriptionRowAction(this.action, this.subscriptionId);

  final SubscriptionMenuAction action;
  final String subscriptionId;
}
