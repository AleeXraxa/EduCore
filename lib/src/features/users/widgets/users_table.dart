import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/users/models/app_user.dart';
import 'package:educore/src/features/users/widgets/user_role_badge.dart';
import 'package:educore/src/features/users/widgets/user_status_badge.dart';
import 'package:flutter/material.dart';

enum UserMenuAction { viewProfile, viewInstitute, toggleBlocked, resetPassword }

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
        final width = constraints.maxWidth < 1220 ? 1220.0 : constraints.maxWidth;

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
            const Expanded(flex: 20, child: Text('User')),
            const Expanded(flex: 18, child: Text('Email / Phone')),
            const Expanded(flex: 14, child: Text('Role')),
            const Expanded(flex: 18, child: Text('Institute')),
            const Expanded(flex: 10, child: Text('Status')),
            const Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Last login'),
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

    final zebra = widget.index.isOdd
        ? cs.surfaceContainerHighest.withValues(alpha: 0.22)
        : cs.surface;
    final bg = _hovered ? cs.primary.withValues(alpha: 0.040) : zebra;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
          ),
        ),
        child: InkWell(
          onTap: () => widget.onOpenUser?.call(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 20,
                  child: _UserCell(name: item.name, email: item.email),
                ),
                Expanded(
                  flex: 18,
                  child: _PrimaryCell(
                    title: item.email,
                    subtitle: item.phone,
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: UserRoleBadge(role: item.role),
                  ),
                ),
                Expanded(
                  flex: 18,
                  child: _PrimaryCell(
                    title: item.instituteName,
                    subtitle:
                        item.instituteId == 'all' ? 'Platform' : item.instituteId,
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: UserStatusBadge(status: item.status),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _fmtLastLogin(item.lastLoginAt),
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
        CircleAvatar(
          radius: 16,
          backgroundColor: cs.primary.withValues(alpha: 0.12),
          child: Text(
            _initials(name),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: 10),
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
                      letterSpacing: -0.1,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
      itemBuilder: (context) => [
        PopupMenuItem(
          value: UserMenuAction.viewProfile,
          child: Row(
            children: [
              Icon(Icons.person_rounded, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 10),
              const Text('View profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: UserMenuAction.viewInstitute,
          child: Row(
            children: [
              Icon(Icons.apartment_rounded, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 10),
              const Text('View institute'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: UserMenuAction.toggleBlocked,
          child: Row(
            children: [
              Icon(
                blocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: blocked ? cs.primary : const Color(0xFFB91C1C),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(blocked ? 'Unblock' : 'Block'),
            ],
          ),
        ),
        PopupMenuItem(
          value: UserMenuAction.resetPassword,
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.key_rounded, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 10),
              const Text('Reset password (soon)'),
            ],
          ),
        ),
      ],
      child: Icon(Icons.more_horiz_rounded, color: cs.onSurfaceVariant),
    );
  }
}

class _EmptyTable extends StatelessWidget {
  const _EmptyTable();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.people_alt_rounded, color: cs.primary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting filters or search terms.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

String _fmtLastLogin(DateTime? value) {
  if (value == null) return '—';
  final d = DateTime.now().difference(value);
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  final first = parts.first.isEmpty ? '' : parts.first[0];
  final last = parts.length >= 2 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

