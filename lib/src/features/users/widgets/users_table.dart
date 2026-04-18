import 'package:educore/src/app/theme/app_tokens.dart';

import 'package:educore/src/features/users/models/app_user.dart';
import 'package:educore/src/features/users/widgets/user_role_badge.dart';
import 'package:educore/src/features/users/widgets/user_status_badge.dart';
import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

enum UserMenuAction { editUser, viewProfile, viewInstitute, toggleBlocked, resetPassword }

@immutable
class UserRowAction {
  const UserRowAction(this.action, this.userId);

  final UserMenuAction action;
  final String userId;
}

class UsersTable extends StatelessWidget {
  const UsersTable({
    super.key,
    required this.items,
    required this.onAction,
    this.onOpenUser,
  });

  final List<AppUser> items;
  final ValueChanged<UserRowAction> onAction;
  final ValueChanged<AppUser>? onOpenUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 1280
            ? 1280.0
            : constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadii.r20,
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                        title: 'No Users Found',
                        description: 'System administrators and academy users will be listed here.',
                        icon: Icons.people_rounded,
                      )
                    else
                      for (var i = 0; i < items.length; i++)
                        _TableRow(
                          index: i,
                          item: items[i],
                          onAction: onAction,
                          onOpenUser: onOpenUser,
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
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
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
            Expanded(flex: 24, child: Text('USER INFO')),
            Expanded(flex: 22, child: Text('CONTACT INFO')),
            Expanded(flex: 16, child: Text('ROLE')),
            Expanded(flex: 24, child: Text('INSTITUTE')),
            Expanded(flex: 14, child: Text('STATUS')),
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
    required this.onAction,
    this.onOpenUser,
  });

  final int index;
  final AppUser item;
  final ValueChanged<UserRowAction> onAction;
  final ValueChanged<AppUser>? onOpenUser;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;

    final bg = _hovered
        ? cs.primary.withValues(alpha: 0.03)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onOpenUser?.call(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 24,
                child: _UserCell(name: item.name, email: item.email),
              ),
              Expanded(
                flex: 22,
                child: _PrimaryCell(
                  title: item.email,
                  subtitle: item.phone.isEmpty ? 'N/A' : item.phone,
                  icon: Icons.alternate_email_rounded,
                ),
              ),
              Expanded(
                flex: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: UserRoleBadge(role: item.role),
                ),
              ),
              Expanded(
                flex: 24,
                child: _PrimaryCell(
                  title: item.instituteName,
                  subtitle: item.instituteId == 'all'
                      ? 'Global Controller'
                      : 'ID: ${item.instituteId}',
                  icon: Icons.apartment_rounded,
                ),
              ),
              Expanded(
                flex: 14,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: UserStatusBadge(status: item.status),
                ),
              ),
              SizedBox(
                width: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _RowMenu(
                    blocked: item.status == AppUserStatus.blocked,
                    onSelected: (value) {
                      widget.onAction(UserRowAction(value, item.id));
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

class _UserCell extends StatelessWidget {
  const _UserCell({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
            ),
            borderRadius: AppRadii.r12,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(name),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                email,
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

class _PrimaryCell extends StatelessWidget {
  const _PrimaryCell({required this.title, required this.subtitle, this.icon});

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
              borderRadius: AppRadii.r12,
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

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.blocked, required this.onSelected});

  final bool blocked;
  final ValueChanged<UserMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<UserMenuAction>(
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
        PopupMenuItem<UserMenuAction>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'USER ACTIONS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const PopupMenuItem(
          value: UserMenuAction.editUser,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(
            icon: Icons.edit_note_rounded,
            label: 'Edit Account',
          ),
        ),
        const PopupMenuItem(
          value: UserMenuAction.viewProfile,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(
            icon: Icons.person_rounded,
            label: 'View Profile',
          ),
        ),
        const PopupMenuItem(
          value: UserMenuAction.viewInstitute,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(
            icon: Icons.apartment_rounded,
            label: 'View Institute',
          ),
        ),
        PopupMenuItem<UserMenuAction>(
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
        PopupMenuItem(
          value: UserMenuAction.toggleBlocked,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(
            icon: blocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            label: blocked ? 'Restore Access' : 'Suspend Account',
            danger: !blocked,
          ),
        ),
        const PopupMenuItem(
          value: UserMenuAction.resetPassword,
          enabled: false,
          height: 48,
          padding: EdgeInsets.zero,
          child: _MenuRow(icon: Icons.key_rounded, label: 'Reset Password'),
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
    final bg = _hovered
        ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
        : Colors.transparent;

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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  final first = parts.first.isEmpty ? '' : parts.first[0];
  final last = parts.length >= 2 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
