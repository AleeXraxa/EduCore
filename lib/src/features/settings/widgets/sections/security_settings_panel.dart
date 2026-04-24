import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/utils/validators.dart';
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
  final _formKey = GlobalKey<FormState>();

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
        const _SectionHeader(
          title: 'Security & Account Settings',
          subtitle: 'Manage your admin password and session timeout preferences.',
        ),
        const SizedBox(height: 24),
        _GroupCard(
          title: 'CHANGE PASSWORD',
          icon: Icons.vpn_key_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Password',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep your account secure by updating your password regularly.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                  Expanded(
                    child: AppTextField(
                      controller: _current,
                      label: 'Current Password',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: Validators.validatePassword,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _new,
                      label: 'New Password',
                      obscureText: true,
                      prefixIcon: Icons.key_rounded,
                      validator: Validators.validatePassword,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _confirm,
                      label: 'Confirm New Password',
                      obscureText: true,
                      prefixIcon: Icons.verified_user_rounded,
                      validator: (v) => Validators.validateConfirmPassword(v, _new.text),
                    ),
                  ),
                ],
              ),
            ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: AppPrimaryButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() != true) {
                      return;
                    }

                    try {
                      AppDialogs.showLoading(context, message: 'Updating password...');
                      await widget.controller.updatePassword(
                        currentPassword: _current.text,
                        newPassword: _new.text,
                      );
                      if (!mounted) return;
                      AppDialogs.hide(context);
                      AppDialogs.showSuccess(
                        context,
                        title: 'Password Updated',
                        message: 'Your security credentials have been updated successfully.',
                      );
                      _current.clear();
                      _new.clear();
                      _confirm.clear();
                    } catch (e) {
                      if (!mounted) return;
                      AppDialogs.hide(context);
                      AppDialogs.showError(
                        context,
                        title: 'Update Failed',
                        message: e.toString().contains('wrong-password') 
                          ? 'The current password you entered is incorrect.'
                          : 'An error occurred while updating your password. Please try again.',
                      );
                    }
                  },
                  busy: widget.controller.busy,
                  icon: Icons.published_with_changes_rounded,
                  label: 'Update Password',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _GroupCard(
          title: 'SESSION MANAGEMENT',
          icon: Icons.timer_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Timeout',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Automatically sign out inactive admin sessions after the selected duration.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 320,
                child: AppDropdown<int>(
                  label: 'Auto Logout After',
                  items: const [15, 30, 45, 60, 90],
                  value: c.sessionTimeoutMinutes,
                  prefixIcon: Icons.history_rounded,
                  itemLabel: (m) => '$m Minutes Inactivity',
                  onChanged: (v) => setState(() => c.sessionTimeoutMinutes = v ?? 30),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: AppRadii.r16,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_moon_rounded, color: cs.primary, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coming Soon: More Security Features',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Two-factor authentication (2FA) and activity log will be available in a future update.',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                          ),
                        ],
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
                letterSpacing: -1.2,
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
  const _GroupCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: cs.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

