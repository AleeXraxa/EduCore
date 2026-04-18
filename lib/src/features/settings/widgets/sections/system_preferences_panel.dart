import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class SystemPreferencesPanel extends StatelessWidget {
  const SystemPreferencesPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'App Preferences',
          subtitle:
              'Customize your interface theme and regional formatting.',
        ),
        const SizedBox(height: 20),
        _GroupCard(
          title: 'THEME & FORMATTING',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppDropdown<ThemePreference>(
                      label: 'App Theme',
                      items: const [
                        ThemePreference.light,
                        ThemePreference.dark,
                        ThemePreference.system,
                      ],
                      value: controller.themePreference,
                      prefixIcon: Icons.brightness_6_rounded,
                      itemLabel: (t) => switch (t) {
                        ThemePreference.light => 'Light',
                        ThemePreference.dark => 'Dark',
                        ThemePreference.system => 'System Default',
                      },
                      onChanged: (v) => controller.themePreference =
                          v ?? controller.themePreference,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppDropdown<DateFormatOption>(
                      label: 'Date Format',
                      items: const [
                        DateFormatOption.ymd,
                        DateFormatOption.dmy,
                        DateFormatOption.mdy,
                      ],
                      value: controller.dateFormat,
                      prefixIcon: Icons.event_rounded,
                      itemLabel: (d) => switch (d) {
                        DateFormatOption.ymd => 'YYYY-MM-DD (Standard)',
                        DateFormatOption.dmy => 'DD-MM-YYYY (Traditional)',
                        DateFormatOption.mdy => 'MM-DD-YYYY (Western)',
                      },
                      onChanged: (v) =>
                          controller.dateFormat = v ?? controller.dateFormat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: AppRadii.r16,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.language_rounded, color: cs.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Multilingual support (Urdu & English) is coming in a future update.',
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
