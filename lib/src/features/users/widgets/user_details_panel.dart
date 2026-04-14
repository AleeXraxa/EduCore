import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/users/models/app_user.dart';
import 'package:educore/src/features/users/widgets/user_role_badge.dart';
import 'package:educore/src/features/users/widgets/user_status_badge.dart';
import 'package:flutter/material.dart';

class UserDetailsPanel {
  static Future<void> show(
    BuildContext context, {
    required AppUser user,
    required VoidCallback onToggleBlocked,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'User details',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim, secondary) {
        return _UserDetailsDialog(
          user: user,
          onToggleBlocked: onToggleBlocked,
        );
      },
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        final slide = Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

class _UserDetailsDialog extends StatelessWidget {
  const _UserDetailsDialog({
    required this.user,
    required this.onToggleBlocked,
  });

  final AppUser user;
  final VoidCallback onToggleBlocked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panelWidth =
        MediaQuery.of(context).size.width < 560 ? double.infinity : 460.0;
    final maxHeight = MediaQuery.of(context).size.height - 36;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: panelWidth.isFinite ? panelWidth : 0,
                maxWidth: panelWidth.isFinite ? panelWidth : double.infinity,
                maxHeight: maxHeight,
              ),
              child: Container(
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: AppRadii.r16,
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: AppShadows.soft(Colors.black),
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.r16,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _Header(user: user),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoGrid(user: user),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        onToggleBlocked();
                                        Navigator.of(context).pop();
                                      },
                                      icon: Icon(
                                        user.status == AppUserStatus.blocked
                                            ? Icons.lock_open_rounded
                                            : Icons.lock_rounded,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            user.status == AppUserStatus.blocked
                                                ? cs.primary
                                                : const Color(0xFFB91C1C),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                      ),
                                      label: Text(
                                        user.status == AppUserStatus.blocked
                                            ? 'Unblock user'
                                            : 'Block user',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Reset password is planned for a future release.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.key_rounded),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                      ),
                                      label: const Text('Reset password'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Note: Detailed audit logs and advanced access policies will be added as the platform scales.',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              _initials(user.name),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
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
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String lastLoginText(DateTime? value) {
      if (value == null) return '—';
      final d = DateTime.now().difference(value);
      if (d.inMinutes < 60) return '${d.inMinutes} min ago';
      if (d.inHours < 24) return '${d.inHours} hr ago';
      return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
    }

    Widget info({
      required IconData icon,
      required String label,
      required Widget value,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.26),
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  value,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        info(
          icon: Icons.badge_rounded,
          label: 'Role',
          value: UserRoleBadge(role: user.role, compact: true),
        ),
        const SizedBox(height: 10),
        info(
          icon: Icons.apartment_rounded,
          label: 'Institute',
          value: Text(
            user.instituteName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(height: 10),
        info(
          icon: Icons.shield_rounded,
          label: 'Status',
          value: Align(
            alignment: Alignment.centerLeft,
            child: UserStatusBadge(status: user.status),
          ),
        ),
        const SizedBox(height: 10),
        info(
          icon: Icons.phone_rounded,
          label: 'Phone',
          value: Text(
            user.phone,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(height: 10),
        info(
          icon: Icons.history_rounded,
          label: 'Last login',
          value: Text(
            lastLoginText(user.lastLoginAt),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
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
