import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/features/users/models/app_user.dart';
import 'package:educore/src/features/users/widgets/user_role_badge.dart';
import 'package:educore/src/features/users/widgets/user_status_badge.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class UserDetailsPanel {
  static Future<void> show(
    BuildContext context, {
    required AppUser user,
    required VoidCallback onToggleBlocked,
    required VoidCallback onEdit,
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
          onEdit: onEdit,
        );
      },
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
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
    required this.onEdit,
  });

  final AppUser user;
  final VoidCallback onToggleBlocked;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panelWidth = MediaQuery.of(context).size.width < 560
        ? double.infinity
        : 480.0;
    final maxHeight = MediaQuery.of(context).size.height - 36;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
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
                  borderRadius: AppRadii.r24,
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _Header(
                      user: user,
                      onEdit: onEdit,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoGrid(user: user),
                            const SizedBox(height: 24),
                            _AnimatedSlideIn(
                              delayIndex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.05),
                                  borderRadius: AppRadii.r16,
                                  border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Note: All changes to administrative accounts are logged for security and audit purposes.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: cs.primary.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontWeight: FontWeight.w700,
                                              height: 1.4,
                                            ),
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
                    _Footer(
                      user: user,
                      onToggleBlocked: () {
                        onToggleBlocked();
                        Navigator.of(context).pop();
                      },
                      onResetKey: () {
                        AppDialogs.showSuccess(
                          context,
                          title: 'Verification Sent',
                          message:
                              'A password reset link has been dispatched to the user\'s registered email address.',
                        );
                      },
                    ),
                  ],
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
  const _Header({
    required this.user,
    required this.onEdit,
    required this.onClose,
  });
  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onClose;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary.withValues(alpha: 0.8),
              child: Text(
                _initials(user.name),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                onEdit();
              },
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: cs.primary,
              tooltip: 'Edit Profile',
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.user,
    required this.onToggleBlocked,
    required this.onResetKey,
  });

  final AppUser user;
  final VoidCallback onToggleBlocked;
  final VoidCallback onResetKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBlocked = user.status == AppUserStatus.blocked;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              color: !isBlocked ? const Color(0xFFDC2626) : null,
              onPressed: onToggleBlocked,
              icon: isBlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              label: isBlocked ? 'Restore Access' : 'Suspend Account',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onResetKey,
              icon: const Icon(Icons.key_rounded, size: 20),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.r16),
                side: BorderSide(color: cs.outlineVariant),
              ),
              label: const Text(
                'Reset Password',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
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
      if (value == null) return 'No active session recorded';
      final d = DateTime.now().difference(value);
      if (d.inMinutes < 60) return '${d.inMinutes} minutes ago';
      if (d.inHours < 24) return '${d.inHours} hours ago';
      return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
    }

    Widget infoItem({
      required IconData icon,
      required String label,
      required Widget value,
      required int delayIndex,
    }) {
      return _AnimatedSlideIn(
        delayIndex: delayIndex,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    value,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        infoItem(
          icon: Icons.shield_rounded,
          label: 'Account Status',
          value: UserStatusBadge(status: user.status),
          delayIndex: 0,
        ),
        infoItem(
          icon: Icons.badge_rounded,
          label: 'Account Role',
          value: UserRoleBadge(role: user.role, compact: true),
          delayIndex: 1,
        ),
        infoItem(
          icon: Icons.hub_rounded,
          label: 'Assigned Institute',
          value: Text(
            user.instituteName,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          delayIndex: 2,
        ),
        infoItem(
          icon: Icons.phone_iphone_rounded,
          label: 'Phone Number',
          value: Text(
            user.phone,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          delayIndex: 3,
        ),
        infoItem(
          icon: Icons.history_rounded,
          label: 'Last Active',
          value: Text(
            lastLoginText(user.lastLoginAt),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          delayIndex: 4,
        ),
      ],
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
      duration: Duration(milliseconds: 400 + (delayIndex * 80)),
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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  final first = parts.first.isEmpty ? '' : parts.first[0];
  final last = parts.length >= 2 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
