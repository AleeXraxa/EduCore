import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class GeneralSettingsPanel extends StatefulWidget {
  const GeneralSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<GeneralSettingsPanel> createState() => _GeneralSettingsPanelState();
}

class _GeneralSettingsPanelState extends State<GeneralSettingsPanel> {
  late final TextEditingController _platformName;
  late final TextEditingController _supportEmail;
  late final TextEditingController _contact;
  late final TextEditingController _tz;

  @override
  void initState() {
    super.initState();
    _platformName = TextEditingController(text: widget.controller.platformName);
    _supportEmail = TextEditingController(text: widget.controller.supportEmail);
    _contact = TextEditingController(text: widget.controller.contactNumber);
    _tz = TextEditingController(text: widget.controller.timezone);

    _platformName.addListener(_bind);
    _supportEmail.addListener(_bind);
    _contact.addListener(_bind);
    _tz.addListener(_bind);
  }

  @override
  void dispose() {
    _platformName.dispose();
    _supportEmail.dispose();
    _contact.dispose();
    _tz.dispose();
    super.dispose();
  }

  void _bind() {
    widget.controller.platformName = _platformName.text.trim();
    widget.controller.supportEmail = _supportEmail.text.trim();
    widget.controller.contactNumber = _contact.text.trim();
    widget.controller.timezone = _tz.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Platform identity and defaults.',
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
                    child: AppTextField(
                      controller: _platformName,
                      label: 'Platform name',
                      hintText: 'EduCore',
                      prefixIcon: Icons.badge_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _supportEmail,
                      label: 'Support email',
                      hintText: 'support@educore.com',
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _contact,
                      label: 'Contact number',
                      hintText: '+92 300 0000000',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 240,
                    child: AppDropdown<Currency>(
                      label: 'Default currency',
                      items: const [Currency.pkr, Currency.usd],
                      value: controller.currency,
                      prefixIcon: Icons.currency_exchange_rounded,
                      itemLabel: (c) => switch (c) {
                        Currency.pkr => 'PKR (Pakistan Rupee)',
                        Currency.usd => 'USD (US Dollar)',
                      },
                      onChanged: (v) {
                        setState(() {
                          controller.currency = v ?? controller.currency;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _tz,
                label: 'Timezone',
                hintText: 'Asia/Karachi',
                prefixIcon: Icons.public_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
