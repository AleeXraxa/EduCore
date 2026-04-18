import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPanel extends StatelessWidget {
  const NotificationSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Notifications',
          subtitle: 'Manage platform notifications and automated alerts.',
        ),
        const SizedBox(height: 20),
        _GroupCard(
          title: 'NOTIFICATION CHANNELS',
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
          title: 'Global System Alerts',
          subtitle: 'Enable or disable all outbound platform notifications.',
          value: c.enableNotifications,
          onChanged: (v) => setState(() => c.enableNotifications = v),
          icon: Icons.notifications_active_rounded,
        ),
        const SizedBox(height: 12),
        _ToggleRow(
          title: 'Email Notifications',
          subtitle: 'Send automated transactional emails to registered users.',
          value: c.enableEmailNotifications,
          onChanged: c.enableNotifications
              ? (v) => setState(() => c.enableEmailNotifications = v)
              : (_) {},
          icon: Icons.email_rounded,
          disabled: !c.enableNotifications,
        ),
        const SizedBox(height: 12),
        _ToggleRow(
          title: 'Push Notifications',
          subtitle: 'Push notifications for mobile and web devices.',
          value: c.enablePushNotifications,
          onChanged: c.enableNotifications
              ? (v) => setState(() => c.enablePushNotifications = v)
              : (_) {},
          icon: Icons.send_to_mobile_rounded,
          disabled: !c.enableNotifications,
        ),
        const SizedBox(height: 20),
        Container(
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
              Icon(Icons.lightbulb_outline_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transactional emails remain active for account security events regardless of these settings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
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
    final opacity = disabled ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value && !disabled ? cs.primary.withValues(alpha: 0.02) : cs.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(
            color: value && !disabled 
              ? cs.primary.withValues(alpha: 0.2) 
              : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: value && !disabled 
                  ? cs.primary.withValues(alpha: 0.1) 
                  : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: AppRadii.r12,
              ),
              child: Icon(
                icon, 
                color: value && !disabled ? cs.primary : cs.onSurfaceVariant, 
                size: 20
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value, 
                onChanged: disabled ? null : onChanged
              ),
            ),
          ],
        ),
      ),
    );
  }
}

