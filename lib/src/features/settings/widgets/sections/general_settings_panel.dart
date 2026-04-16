import 'dart:io';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _appName = TextEditingController(text: settings?.appName);
    _supportEmail = TextEditingController(text: settings?.supportEmail);
    _supportPhone = TextEditingController(text: settings?.supportPhone);

    _appName.addListener(_update);
    _supportEmail.addListener(_update);
    _supportPhone.addListener(_update);
  }

  void _update() {
    final current = widget.controller.settings;
    if (current == null) return;
    widget.controller.updateSettings(
      current.copyWith(
        appName: _appName.text,
        supportEmail: _supportEmail.text,
        supportPhone: _supportPhone.text,
      ),
    );
  }

  @override
  void dispose() {
    _appName.dispose();
    _supportEmail.dispose();
    _supportPhone.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await widget.controller.uploadLogo(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Identity & Branding',
          subtitle:
              'Configure the public-facing attributes of the EduCore platform.',
        ),
        const SizedBox(height: 20),
        _GroupCard(
          title: 'PLATFORM BRANDING',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoPreview(
                url: settings?.appLogoUrl,
                onUpload: _pickImage,
                isBusy: widget.controller.busy,
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _appName,
                      label: 'Platform Name',
                      hintText: 'EduCore',
                      prefixIcon: Icons.edit_note_rounded,
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
                              'The platform name is displayed across login portals and email notifications.',
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        _GroupCard(
          title: 'PLATFORM SUPPORT',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _supportEmail,
                      label: 'Support Email',
                      hintText: 'support@educore.com',
                      prefixIcon: Icons.email_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _supportPhone,
                      label: 'Support Phone',
                      hintText: '+92 300 0000000',
                      prefixIcon: Icons.phone_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'These details are accessible to all registered institutes in their support dashboard.',
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

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({this.url, required this.onUpload, this.isBusy = false});

  final String? url;
  final VoidCallback onUpload;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasLogo = url != null && url!.isNotEmpty;

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: AppRadii.r20,
            border: Border.all(color: cs.outlineVariant),
            image: hasLogo
                ? DecorationImage(
                    image: NetworkImage(url!),
                    fit: BoxFit.contain,
                  )
                : null,
          ),
          child: !hasLogo
              ? Icon(
                  Icons.business_rounded,
                  size: 48,
                  color: cs.onSurfaceVariant,
                )
              : null,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: isBusy ? null : onUpload,
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text('Update Logo'),
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
