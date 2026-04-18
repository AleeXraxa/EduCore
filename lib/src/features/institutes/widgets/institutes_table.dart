import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/institutes/widgets/institute_status_badge.dart';
import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

class InstitutesTable extends StatelessWidget {
  const InstitutesTable({
    super.key,
    required this.items,
    required this.planLabel,
    required this.onAction,
  });

  final List<Institute> items;
  final String Function(String planId) planLabel;
  final ValueChanged<InstituteRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < 1180 ? 1180.0 : constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadii.r20,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadii.r20,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    const _TableHeader(),
                    if (items.isEmpty)
                      const AppEmptyState(
                        title: 'No Institutes Found',
                        description: 'Registered institutes and academies will be listed here.',
                        icon: Icons.apartment_rounded,
                      )
                    else
                      for (var i = 0; i < items.length; i++)
                        _TableRow(
                          index: i,
                          item: items[i],
                          planLabel: planLabel,
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
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
        child: const Row(
          children: [
            Expanded(flex: 22, child: Text('INSTITUTE NAME')),
            Expanded(flex: 16, child: Text('PRIMARY CONTACT')),
            Expanded(flex: 18, child: Text('CONTACT INFO')),
            Expanded(flex: 10, child: Text('PLAN TYPE')),
            Expanded(flex: 10, child: Text('STATUS')),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('STUDENTS'),
              ),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('CREATED ON'),
              ),
            ),
            SizedBox(width: 48),
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
    required this.planLabel,
    required this.onAction,
  });

  final int index;
  final Institute item;
  final String Function(String planId) planLabel;
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

    final bg = _hovered ? cs.primary.withValues(alpha: 0.03) : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onAction(InstituteRowAction(InstituteMenuAction.view, item.id)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 22,
                child: _PrimaryCell(
                  title: item.name,
                  subtitle: item.email,
                  icon: Icons.apartment_rounded,
                ),
              ),
              Expanded(
                flex: 16,
                child: _PrimaryCell(
                  title: item.ownerName,
                  subtitle: 'Lead Director',
                  icon: Icons.person_2_outlined,
                ),
              ),
              Expanded(
                flex: 18,
                child: _PrimaryCell(
                  title: item.phone,
                  subtitle: item.email,
                  icon: Icons.alternate_email_rounded,
                ),
              ),
              Expanded(
                flex: 10,
                child: _PlanPill(label: widget.planLabel(item.planId)),
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
                width: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _RowMenu(
                    blocked: item.status == AcademyStatus.blocked,
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
      ),
    );
  }
}

class _PrimaryCell extends StatelessWidget {
  const _PrimaryCell({
    required this.title,
    required this.subtitle,
    this.icon,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppRadii.r8,
            ),
            child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final clean = label.trim().isEmpty ? '-' : label.trim();
    final isKnown = clean != '-';
    final fg = isKnown ? cs.primary : cs.onSurfaceVariant;
    final bg = isKnown
        ? cs.primary.withValues(alpha: 0.10)
        : cs.surfaceContainerHighest.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isKnown ? cs.primary.withValues(alpha: 0.2) : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        clean.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.5,
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
      elevation: 20,
      color: cs.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      padding: EdgeInsets.zero,
      offset: const Offset(0, 10),
      constraints: const BoxConstraints(minWidth: 240),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => [
        PopupMenuItem<InstituteMenuAction>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          height: 0,
          child: Text(
            'ACTIONS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
          ),
        ),
        const PopupMenuItem(
          value: InstituteMenuAction.view,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(icon: Icons.visibility_rounded, label: 'View Details'),
        ),
        const PopupMenuItem(
          value: InstituteMenuAction.edit,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(icon: Icons.edit_rounded, label: 'Edit Institute'),
        ),
        PopupMenuItem(
          value: blocked ? InstituteMenuAction.unblock : InstituteMenuAction.block,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(
            icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
            label: blocked ? 'Restore Access' : 'Suspend Access',
          ),
        ),
        PopupMenuItem<InstituteMenuAction>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        const PopupMenuItem(
          value: InstituteMenuAction.delete,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Institute',
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
    final bg = _hovered ? cs.surfaceContainerHighest.withValues(alpha: 0.4) : Colors.transparent;

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
          border: Border.all(
            color: _hovered ? cs.outlineVariant : Colors.transparent,
          ),
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
    final color = danger ? const Color(0xFFE11D48) : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
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

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
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

