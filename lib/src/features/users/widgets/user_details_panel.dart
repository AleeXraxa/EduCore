import 'dart:ui';
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
                  color: cs.surface.withValues(alpha: 0.82),
                  borderRadius: AppRadii.r24,
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.r24,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        _Header(user: user),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AnimatedSlideIn(
                                  delayIndex: 0,
                                  child: _InfoGrid(user: user),
                                ),
                                const SizedBox(height: 32),
                                _AnimatedSlideIn(
                                  delayIndex: 5,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _ActionBtn(
                                          isDanger: user.status != AppUserStatus.blocked,
                                          onPressed: () {
                                            onToggleBlocked();
                                            Navigator.of(context).pop();
                                          },
                                          icon: user.status == AppUserStatus.blocked
                                              ? Icons.lock_open_rounded
                                              : Icons.lock_rounded,
                                          label: user.status == AppUserStatus.blocked
                                              ? 'Restore Access'
                                              : 'Restrict Access',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _ActionBtn(
                                          isDanger: false,
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Credential reset initialization requested.',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: Icons.key_rounded,
                                          label: 'Reset Key',
                                          outlined: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _AnimatedSlideIn(
                                  delayIndex: 6,
                                  child: Text(
                                    'Note: Policy mandates and audit trails are logged for every modification to administrative accounts.',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: cs.primary,
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
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20),
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
      required int delayIndex,
    }) {
      return _AnimatedSlideIn(
        delayIndex: delayIndex,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.4),
            borderRadius: AppRadii.r20,
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
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
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 6),
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
        info(
          icon: Icons.shield_rounded,
          label: 'Security Status',
          value: UserStatusBadge(status: user.status),
          delayIndex: 0,
        ),
        info(
          icon: Icons.badge_rounded,
          label: 'Assigned Role',
          value: UserRoleBadge(role: user.role, compact: true),
          delayIndex: 1,
        ),
        info(
          icon: Icons.apartment_rounded,
          label: 'Organization',
          value: Text(
            user.instituteName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
          ),
          delayIndex: 2,
        ),
        info(
          icon: Icons.phone_rounded,
          label: 'Contact Baseline',
          value: Text(
            user.phone,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
          ),
          delayIndex: 3,
        ),
        info(
          icon: Icons.history_rounded,
          label: 'Last Session Activity',
          value: Text(
            lastLoginText(user.lastLoginAt),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
          ),
          delayIndex: 4,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isDanger,
    this.outlined = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isDanger;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        label: Text(label),
      );
    }

    final color = isDanger ? const Color(0xFFDC2626) : cs.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.r16,
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
        ),
        label: Text(label, style: const TextStyle(color: Colors.white)),
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
      duration: Duration(milliseconds: 450 + (delayIndex * 80)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
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
