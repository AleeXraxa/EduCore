import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/institutes/widgets/institute_status_badge.dart';
import 'package:flutter/material.dart';

class InstitutesTable extends StatelessWidget {
  const InstitutesTable({
    super.key,
    required this.items,
    required this.onAction,
  });

  final List<Institute> items;
  final ValueChanged<InstituteRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < 1120 ? 1120.0 : constraints.maxWidth;

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
                    const _TableHeader(),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.75),
                    ),
                    if (items.isEmpty)
                      const _EmptyTable()
                    else
                      for (var i = 0; i < items.length; i++)
                        _TableRow(
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
        child: Row(
          children: [
            const Expanded(flex: 22, child: Text('Institute')),
            const Expanded(flex: 16, child: Text('Owner')),
            const Expanded(flex: 18, child: Text('Contact')),
            const Expanded(flex: 10, child: Text('Plan')),
            const Expanded(flex: 10, child: Text('Status')),
            const Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Students'),
              ),
            ),
            const Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Created'),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.index,
    required this.item,
    required this.onAction,
  });

  final int index;
  final Institute item;
  final ValueChanged<InstituteRowAction> onAction;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;

    final zebra =
        widget.index.isOdd ? cs.surfaceContainerHighest.withValues(alpha: 0.22) : cs.surface;
    final bg = _hovered ? cs.primary.withValues(alpha: 0.040) : zebra;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.basic,
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
              flex: 22,
              child: _PrimaryCell(
                title: item.name,
                subtitle: item.email,
              ),
            ),
            Expanded(
              flex: 16,
              child: _PrimaryCell(
                title: item.ownerName,
                subtitle: 'Primary contact',
              ),
            ),
            Expanded(
              flex: 18,
              child: _PrimaryCell(
                title: item.phone,
                subtitle: item.email,
              ),
            ),
            Expanded(
              flex: 10,
              child: _PlanPill(plan: item.plan),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerLeft,
                child: InstituteStatusBadge(status: item.status),
              ),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _fmtInt(item.studentsCount),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _fmtDate(item.createdAt),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: _RowMenu(
                  blocked: item.status == InstituteStatus.blocked,
                  onSelected: (value) {
                    widget.onAction(
                      InstituteRowAction(value, item.id),
                    );
                  },
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

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan});

  final InstitutePlan plan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (label, fg, bg) = switch (plan) {
      InstitutePlan.basic => (
          'Basic',
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest.withValues(alpha: 0.65),
        ),
      InstitutePlan.standard => (
          'Standard',
          cs.primary,
          cs.primary.withValues(alpha: 0.10),
        ),
      InstitutePlan.premium => (
          'Premium',
          cs.secondary,
          cs.secondary.withValues(alpha: 0.10),
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
            ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.blocked, required this.onSelected});

  final bool blocked;
  final ValueChanged<InstituteMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<InstituteMenuAction>(
      tooltip: 'Actions',
      onSelected: onSelected,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: InstituteMenuAction.view,
          child: _MenuRow(icon: Icons.visibility_rounded, label: 'View details'),
        ),
        const PopupMenuItem(
          value: InstituteMenuAction.edit,
          child: _MenuRow(icon: Icons.edit_rounded, label: 'Edit institute'),
        ),
        PopupMenuItem(
          value: blocked
              ? InstituteMenuAction.unblock
              : InstituteMenuAction.block,
          child: _MenuRow(
            icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
            label: blocked ? 'Unblock' : 'Block',
          ),
        ),
        PopupMenuDivider(height: 1, color: cs.outlineVariant),
        PopupMenuItem(
          value: InstituteMenuAction.delete,
          child: const _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete (soft)',
            danger: true,
          ),
        ),
      ],
      child: const _RowMenuTrigger(),
    );
  }
}

class _RowMenuTrigger extends StatefulWidget {
  const _RowMenuTrigger();

  @override
  State<_RowMenuTrigger> createState() => _RowMenuTriggerState();
}

class _RowMenuTriggerState extends State<_RowMenuTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _hovered ? cs.surfaceContainerHighest : cs.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          color: bg,
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

class _EmptyTable extends StatelessWidget {
  const _EmptyTable();

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
              Icons.apartment_rounded,
              color: cs.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No institutes found',
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

enum InstituteMenuAction { view, edit, block, unblock, delete }

@immutable
class InstituteRowAction {
  const InstituteRowAction(this.action, this.instituteId);

  final InstituteMenuAction action;
  final String instituteId;
}
