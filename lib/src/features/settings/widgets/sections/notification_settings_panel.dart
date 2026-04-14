import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPanel extends StatelessWidget {
  const NotificationSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Control delivery channels and defaults.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadii.r16,
            border: Border.all(color: cs.outlineVariant),
            boxShadow: AppShadows.soft(Colors.black),
          ),
          child: _SettingsToggles(controller: controller),
        ),
      ],
    );
  }
}

class _SettingsToggles extends StatefulWidget {
  const _SettingsToggles({required this.controller});

  final SettingsController controller;

  @override
  State<_SettingsToggles> createState() => _SettingsTogglesState();
}

class _SettingsTogglesState extends State<_SettingsToggles> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.controller;

    return Column(
      children: [
        _ToggleRow(
          title: 'Enable notifications',
          subtitle: 'Master switch for sending notifications.',
          value: c.enableNotifications,
          onChanged: (v) => setState(() => c.enableNotifications = v),
          icon: Icons.notifications_active_rounded,
        ),
        const Divider(height: 24),
        _ToggleRow(
          title: 'Email notifications',
          subtitle: 'Send email alerts when enabled.',
          value: c.enableEmailNotifications,
          onChanged: c.enableNotifications
              ? (v) => setState(() => c.enableEmailNotifications = v)
              : (_) {},
          icon: Icons.email_rounded,
          disabled: !c.enableNotifications,
        ),
        const Divider(height: 24),
        _ToggleRow(
          title: 'Push notifications',
          subtitle: 'Enable push delivery (future-ready).',
          value: c.enablePushNotifications,
          onChanged: c.enableNotifications
              ? (v) => setState(() => c.enablePushNotifications = v)
              : (_) {},
          icon: Icons.send_to_mobile_rounded,
          disabled: !c.enableNotifications,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tip: Keep email enabled for critical alerts until push is rolled out.',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.disabled = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = disabled ? cs.onSurfaceVariant.withValues(alpha: 0.6) : cs.primary;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: disabled ? cs.onSurfaceVariant : cs.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: disabled ? null : onChanged),
      ],
    );
  }
}

