import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum AppActionType { view, edit, delete, custom }

class AppActionItem {
  const AppActionItem({
    required this.label,
    required this.icon,
    this.type = AppActionType.custom,
    this.isEnabled = true,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final AppActionType type;
  final bool isEnabled;
  final VoidCallback onTap;
}

class AppActionMenu extends StatelessWidget {
  const AppActionMenu({
    super.key,
    required this.actions,
    this.icon = Icons.more_vert_rounded,
    this.disabled = false,
  });

  final List<AppActionItem> actions;
  final IconData icon;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (disabled || actions.isEmpty) {
      return IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
        onPressed: null,
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: cs.primary.withValues(alpha: 0.1),
        highlightColor: cs.primary.withValues(alpha: 0.05),
      ),
      child: PopupMenuButton<AppActionItem>(
        icon: Icon(icon, color: cs.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.r12,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        color: cs.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        onSelected: (action) => action.onTap(),
        itemBuilder: (context) {
          final items = <PopupMenuEntry<AppActionItem>>[];
          
          for (var i = 0; i < actions.length; i++) {
            final action = actions[i];
            
            // Add a divider before delete if it's not the first item
            if (action.type == AppActionType.delete && i > 0) {
              items.add(
                PopupMenuItem<AppActionItem>(
                  enabled: false,
                  height: 16,
                  child: Divider(color: cs.outlineVariant, height: 1),
                ),
              );
            }

            final isDanger = action.type == AppActionType.delete;
            final textColor = isDanger ? cs.error : cs.onSurface;
            final iconColor = isDanger ? cs.error : cs.primary;

            items.add(
              PopupMenuItem<AppActionItem>(
                value: action,
                enabled: action.isEnabled,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Opacity(
                  opacity: action.isEnabled ? 1.0 : 0.4,
                  child: Row(
                    children: [
                      Icon(action.icon, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Text(
                        action.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return items;
        },
      ),
    );
  }
}
