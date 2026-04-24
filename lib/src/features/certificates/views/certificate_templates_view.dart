import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_table.dart';
import 'package:educore/src/features/certificates/controllers/template_controller.dart';
import 'package:educore/src/features/certificates/models/certificate_template.dart';
import 'package:educore/src/features/certificates/views/template_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class CertificateTemplatesView extends StatefulWidget {
  const CertificateTemplatesView({super.key});

  @override
  State<CertificateTemplatesView> createState() => _CertificateTemplatesViewState();
}

class _CertificateTemplatesViewState extends State<CertificateTemplatesView> {
  late final TemplateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TemplateController();
    final academyId = AppServices.instance.authService?.currentAcademyId;
    if (academyId != null) {
      _controller.init(academyId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEditor(BuildContext context, {CertificateTemplate? template}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TemplateEditorDialog(template: template),
    );
    
    if (result == true) {
      // Refresh list if needed (TemplateController already watches snapshots)
    }
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<TemplateController>(
      controller: _controller,
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final isMobile = size == ScreenSize.compact;

            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildTemplateTable(context, controller, isMobile),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificate Templates',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Manage custom certificate backgrounds and layouts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const Spacer(),
        AppButton(
          label: 'Create Template',
          icon: Icons.add_rounded,
          onPressed: () => _showEditor(context),
          variant: AppButtonVariant.primary,
        ),
      ],
    );
  }

  Widget _buildTemplateTable(BuildContext context, TemplateController controller, bool isMobile) {
    if (controller.busy) {
      return const Center(child: SpinKitFadingCube(color: Colors.blue, size: 40));
    }

    if (controller.templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(Icons.dashboard_customize_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              const Text('No custom templates yet. Using system default.'),
            ],
          ),
        ),
      );
    }

    return AppTable<CertificateTemplate>(
      items: controller.templates,
      columns: [
        AppTableColumn(
          label: 'Template Name',
          flex: 2,
          builder: (t) => Row(
            children: [
              Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (t.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        AppTableColumn(
          label: 'Created',
          flex: 1,
          builder: (t) => Text(DateFormat('dd MMM yyyy').format(t.createdAt)),
        ),
        AppTableColumn(
          label: 'Status',
          flex: 1,
          builder: (t) => Text(t.backgroundUrl != null ? 'Custom Background' : 'System Theme'),
        ),
        AppTableColumn(
          label: 'Actions',
          width: 80,
          builder: (t) => _buildActions(context, t),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, CertificateTemplate template) {
    final academyId = AppServices.instance.authService?.currentAcademyId;

    return AppActionMenu(
      actions: [
        if (!template.isDefault && academyId != null)
          AppActionItem(
            label: 'Set as Default',
            icon: Icons.check_circle_outline_rounded,
            onTap: () => _controller.setAsDefault(academyId, template),
          ),
        AppActionItem(
          label: 'Edit',
          icon: Icons.edit_rounded,
          onTap: () => _showEditor(context, template: template),
        ),
        AppActionItem(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          type: AppActionType.delete,
          onTap: () async {
            if (academyId == null) return;
            final confirmed = await AppDialogs.showConfirm(
              context,
              title: 'Delete Template?',
              message: 'This will permanently remove the template ${template.name}. Certificates already generated will not be affected.',
              confirmLabel: 'Delete',
              isDanger: true,
            );
            if (confirmed ?? false) {
              await _controller.deleteTemplate(academyId, template);
            }
          },
        ),
      ],
    );
  }
}
