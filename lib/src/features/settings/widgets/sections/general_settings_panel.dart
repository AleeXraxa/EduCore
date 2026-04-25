import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class GeneralSettingsPanel extends StatefulWidget {
  const GeneralSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<GeneralSettingsPanel> createState() => _GeneralSettingsPanelState();
}

class _GeneralSettingsPanelState extends State<GeneralSettingsPanel> {
  late final TextEditingController _appName;
  late final TextEditingController _supportEmail;
  late final TextEditingController _supportPhone;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _appName = TextEditingController(text: settings?.appName);
    _supportEmail = TextEditingController(text: settings?.supportEmail);
    _supportPhone = TextEditingController(text: settings?.supportPhone);
    _address = TextEditingController(text: settings?.address);

    _appName.addListener(_update);
    _supportEmail.addListener(_update);
    _supportPhone.addListener(_update);
    _address.addListener(_update);
  }

  @override
  void didUpdateWidget(GeneralSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final settings = widget.controller.settings;
    if (settings != null) {
      if (_appName.text != settings.appName) {
        _appName.text = settings.appName;
      }
      if (_supportEmail.text != settings.supportEmail) {
        _supportEmail.text = settings.supportEmail;
      }
      if (_supportPhone.text != settings.supportPhone) {
        _supportPhone.text = settings.supportPhone;
      }
      if (_address.text != settings.address) {
        _address.text = settings.address;
      }
    }
  }

  void _update() {
    final current = widget.controller.settings;
    if (current == null) return;
    widget.controller.updateSettings(
      current.copyWith(
        appName: _appName.text,
        supportEmail: _supportEmail.text,
        supportPhone: _supportPhone.text,
        address: _address.text,
      ),
    );
  }

  @override
  void dispose() {
    _appName.dispose();
    _supportEmail.dispose();
    _supportPhone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = widget.controller.isSuperAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Identity & Branding',
          subtitle:
              'Configure the public-facing attributes of your ${isSuperAdmin ? 'platform' : 'institute'}.',
        ),
        const SizedBox(height: 20),
        _GroupCard(
          title: isSuperAdmin ? 'PLATFORM IDENTITY' : 'INSTITUTE IDENTITY',
          child: Column(
            children: [
              AppTextField(
                controller: _appName,
                label: isSuperAdmin ? 'Platform Name' : 'Institute Name',
                hintText: isSuperAdmin ? 'Your Platform Name' : 'Your Institute Name',
                prefixIcon: isSuperAdmin ? Icons.hub_rounded : Icons.business_rounded,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: AppRadii.r16,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isSuperAdmin
                            ? 'This name represents the overall platform identity across all institutes.'
                            : 'This name is displayed across portals, certificates, and student communications.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _GroupCard(
          title: 'CONTACT DETAILS',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _supportEmail,
                      label: isSuperAdmin ? 'Platform Support Email' : 'Official Email',
                      hintText: isSuperAdmin ? 'support@platform.com' : 'email@institute.com',
                      prefixIcon: Icons.email_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _supportPhone,
                      label: isSuperAdmin ? 'Support Hotline' : 'Contact Number',
                      hintText: '+92 000 0000000',
                      prefixIcon: Icons.phone_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _address,
                label: isSuperAdmin ? 'Headquarters Address' : 'Institute Address',
                hintText: isSuperAdmin ? '123 Tech Park, Suite 100' : '123 Education Street, City',
                prefixIcon: Icons.location_on_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isSuperAdmin
                      ? 'These details will be used for platform-wide support and administrative communications.'
                      : 'These details will be used for official communications and displayed on reports.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

