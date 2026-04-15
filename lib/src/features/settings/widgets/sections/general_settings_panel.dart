import 'dart:io';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
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
        Text(
          'App Branding',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LogoPreview(
                    url: settings?.appLogoUrl,
                    onUpload: _pickImage,
                    isBusy: widget.controller.busy,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: AppTextField(
                      controller: _appName,
                      label: 'App Name',
                      hintText: 'EduCore',
                      prefixIcon: Icons.edit_note_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Support Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Row(
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
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppShadows.soft(Colors.black),
      ),
      child: child,
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({
    this.url,
    required this.onUpload,
    this.isBusy = false,
  });

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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: AppRadii.r12,
            border: Border.all(color: cs.outlineVariant),
            image: hasLogo
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.contain)
                : null,
          ),
          child: !hasLogo
              ? Icon(Icons.business_rounded, size: 40, color: cs.onSurfaceVariant)
              : null,
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(
          label: 'Upload Logo',
          onPressed: onUpload,
          busy: isBusy,
          variant: AppButtonVariant.secondary,
        ),
      ],
    );
  }
}
