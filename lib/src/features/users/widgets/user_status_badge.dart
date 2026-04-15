import 'package:educore/src/features/users/models/app_user.dart';
import 'package:flutter/material.dart';

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.status});

  final AppUserStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg, label) = switch (status) {
      AppUserStatus.active => (
          const Color(0xFF16A34A).withValues(alpha: 0.10),
          const Color(0xFF15803D),
          'Active',
        ),
      AppUserStatus.blocked => (
          const Color(0xFFEF4444).withValues(alpha: 0.10),
          const Color(0xFFB91C1C),
          'Blocked',
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: fg.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
          ),
        ],
      ),
    );
  }
}

