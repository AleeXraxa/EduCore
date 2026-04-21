import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:flutter/material.dart';

class SettingsNav extends StatelessWidget {
  const SettingsNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppShadows.soft(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Platform control center',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          for (final item in _items)
            _NavItem(
              icon: item.icon,
              label: item.label,
              selected: selected == item.section,
              onTap: () => onSelect(item.section),
            ),
        ],
      ),
    );
  }
}

@immutable
class _SettingsNavItem {
  const _SettingsNavItem({
    required this.section,
    required this.label,
    required this.icon,
  });

  final SettingsSection section;
  final String label;
  final IconData icon;
}

const _items = <_SettingsNavItem>[
  _SettingsNavItem(
    section: SettingsSection.general,
    label: 'General',
    icon: Icons.tune_rounded,
  ),
  _SettingsNavItem(
    section: SettingsSection.planAndFeatures,
    label: 'Plan & Features',
    icon: Icons.verified_user_rounded,
  ),
  _SettingsNavItem(
    section: SettingsSection.paymentSettings,
    label: 'Payment Methods',
    icon: Icons.payments_rounded,
  ),
  _SettingsNavItem(
    section: SettingsSection.documentCustomization,
    label: 'Document Customization',
    icon: Icons.description_rounded,
  ),
  _SettingsNavItem(
    section: SettingsSection.notificationSettings,
    label: 'Notifications',
    icon: Icons.notifications_active_rounded,
  ),
  _SettingsNavItem(
    section: SettingsSection.security,
    label: 'Security',
    icon: Icons.shield_rounded,
  ),
  _SettingsNavItem(
    section: SettingsSection.systemPreferences,
    label: 'App Preferences',
    icon: Icons.settings_suggest_rounded,
  ),
];

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = widget.selected
        ? cs.primary.withValues(alpha: 0.10)
        : (_hovered ? cs.surfaceContainerHighest : Colors.transparent);

    final fg = widget.selected ? cs.primary : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hovered = v),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(widget.icon, color: fg, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
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

