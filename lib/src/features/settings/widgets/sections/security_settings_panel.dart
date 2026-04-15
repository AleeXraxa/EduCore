import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class SecuritySettingsPanel extends StatefulWidget {
  const SecuritySettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SecuritySettingsPanel> createState() => _SecuritySettingsPanelState();
}

class _SecuritySettingsPanelState extends State<SecuritySettingsPanel> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Session and admin security controls.',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change admin password',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _current,
                      label: 'Current password',
                      obscureText: true,
                      prefixIcon: Icons.lock_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _new,
                      label: 'New password',
                      obscureText: true,
                      prefixIcon: Icons.key_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _confirm,
                      label: 'Confirm password',
                      obscureText: true,
                      prefixIcon: Icons.verified_user_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AppPrimaryButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password change (UI only)')),
                    );
                    _current.clear();
                    _new.clear();
                    _confirm.clear();
                  },
                  icon: Icons.check_rounded,
                  label: 'Update password',
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),
              Text(
                'Session timeout',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Auto-sign out inactive sessions for security.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 280,
                child: AppDropdown<int>(
                  label: 'Timeout',
                  items: const [15, 30, 45, 60, 90],
                  value: c.sessionTimeoutMinutes,
                  prefixIcon: Icons.timer_rounded,
                  itemLabel: (m) => '$m minutes',
                  onChanged: (v) =>
                      setState(() => c.sessionTimeoutMinutes = v ?? 30),
                ),
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
                    Icon(Icons.info_outline_rounded, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '2FA and advanced session policies will be added in a future phase.',
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

