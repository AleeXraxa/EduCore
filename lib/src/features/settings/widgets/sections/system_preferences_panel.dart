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
        Text(
          'System preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Look & feel and formatting preferences (future-ready).',
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
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppDropdown<ThemePreference>(
                      label: 'Theme',
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
                        ThemePreference.system => 'System',
                      },
                      onChanged: (v) =>
                          controller.themePreference = v ?? controller.themePreference,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdown<DateFormatOption>(
                      label: 'Date format',
                      items: const [
                        DateFormatOption.ymd,
                        DateFormatOption.dmy,
                        DateFormatOption.mdy,
                      ],
                      value: controller.dateFormat,
                      prefixIcon: Icons.event_rounded,
                      itemLabel: (d) => switch (d) {
                        DateFormatOption.ymd => 'YYYY-MM-DD',
                        DateFormatOption.dmy => 'DD-MM-YYYY',
                        DateFormatOption.mdy => 'MM-DD-YYYY',
                      },
                      onChanged: (v) =>
                          controller.dateFormat = v ?? controller.dateFormat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.26),
                  borderRadius: AppRadii.r16,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.language_rounded, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Language & branding settings will be added as the platform scales.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
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

