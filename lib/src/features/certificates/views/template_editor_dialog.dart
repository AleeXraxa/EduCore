import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/certificates/models/certificate_template.dart';
import 'package:flutter/material.dart';

class TemplateEditorDialog extends StatefulWidget {
  const TemplateEditorDialog({super.key, this.template});
  final CertificateTemplate? template;

  @override
  State<TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<TemplateEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _backgroundUrlController;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _backgroundUrlController = TextEditingController(text: widget.template?.backgroundUrl ?? '');
    _isDefault = widget.template?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _backgroundUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final academyId = AppServices.instance.authService?.currentAcademyId;
    if (academyId == null) return;

    setState(() => _saving = true);

    try {
      final template = widget.template?.copyWith(
            name: _nameController.text.trim(),
            backgroundUrl: _backgroundUrlController.text.trim().isEmpty ? null : _backgroundUrlController.text.trim(),
            isDefault: _isDefault,
            updatedAt: DateTime.now(),
          ) ??
          CertificateTemplate(
            id: '',
            academyId: academyId,
            name: _nameController.text.trim(),
            backgroundUrl: _backgroundUrlController.text.trim().isEmpty ? null : _backgroundUrlController.text.trim(),
            config: {},
            isDefault: _isDefault,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      if (widget.template != null) {
        await AppServices.instance.certificateTemplateService?.updateTemplate(
          academyId: academyId,
          template: template,
        );
      } else {
        await AppServices.instance.certificateTemplateService?.createTemplate(
          academyId: academyId,
          template: template,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, title: 'Error', message: 'Failed to save template: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.template != null ? 'Edit Template' : 'New Template'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Template Name',
                  controller: _nameController,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  hintText: 'e.g. Annual Achievement 2024',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Background Image URL',
                  controller: _backgroundUrlController,
                  hintText: 'https://example.com/background.jpg',
                  helperText: 'Leave empty to use system default theme',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Set as Default'),
                  subtitle: const Text('New certificates will use this template'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppPrimaryButton(
          label: 'Save Template',
          onPressed: _save,
          busy: _saving,
        ),
      ],
    );
  }
}
