import 'package:educore/src/features/users/models/app_user.dart';
import 'package:flutter/material.dart';

class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({super.key, required this.role, this.compact = false});

  final AppUserRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg, label, icon) = switch (role) {
      AppUserRole.superAdmin => (
          cs.primary.withValues(alpha: 0.10),
          cs.primary,
          'Super Admin',
          Icons.security_rounded,
        ),
      AppUserRole.instituteAdmin => (
          const Color(0xFF7C3AED).withValues(alpha: 0.10),
          const Color(0xFF6D28D9),
          'Institute Admin',
          Icons.admin_panel_settings_rounded,
        ),
      AppUserRole.staff => (
          const Color(0xFF0EA5E9).withValues(alpha: 0.10),
          const Color(0xFF0369A1),
          'Staff',
          Icons.badge_rounded,
        ),
      AppUserRole.teacher => (
          const Color(0xFF16A34A).withValues(alpha: 0.10),
          const Color(0xFF15803D),
          'Teacher',
          Icons.school_rounded,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 15, color: fg),
          SizedBox(width: compact ? 5 : 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
          ),
        ],
      ),
    );
  }
}

