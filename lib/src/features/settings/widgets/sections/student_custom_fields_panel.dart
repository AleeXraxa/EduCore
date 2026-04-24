import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_table.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class StudentCustomFieldsPanel extends StatefulWidget {
  final SettingsController controller;

  const StudentCustomFieldsPanel({super.key, required this.controller});

  @override
  State<StudentCustomFieldsPanel> createState() => _StudentCustomFieldsPanelState();
}

class _StudentCustomFieldsPanelState extends State<StudentCustomFieldsPanel> {
  final _studentService = AppServices.instance.studentService;
  final _auth = AppServices.instance.authService;

  List<StudentCustomField> _fields = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final academyId = _auth?.currentAcademyId;
    if (academyId == null) return;

    try {
      final fields = await _studentService!.getCustomFieldDefinitions(academyId);
      setState(() {
        _fields = fields;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, title: 'Error', message: 'Failed to load custom fields: $e');
      }
    }
  }

  void _showAddDialog() {
    // TODO: Implement CustomFieldFormDialog
    AppDialogs.showInfo(context, title: 'Coming Soon', message: 'Custom Field Editor is coming soon. You will be able to add text, number, date, and dropdown fields.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SpinKitFadingCube(color: Colors.blue, size: 40));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dynamic Student Fields',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Define additional information to collect during student enrollment',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const Spacer(),
            AppButton(
              label: 'Add New Field',
              icon: Icons.add_rounded,
              onPressed: _showAddDialog,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (_fields.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Column(
                children: [
                  Icon(Icons.dynamic_feed_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No custom fields defined yet.'),
                ],
              ),
            ),
          )
        else
          AppTable<StudentCustomField>(
            items: _fields,
            columns: [
              AppTableColumn(
                label: 'Field Label',
                flex: 2,
                builder: (f) => Text(f.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              AppTableColumn(
                label: 'Key',
                flex: 1,
                builder: (f) => Text(f.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
              AppTableColumn(
                label: 'Type',
                flex: 1,
                builder: (f) => Text(f.type.name.toUpperCase()),
              ),
              AppTableColumn(
                label: 'Required',
                flex: 1,
                builder: (f) => Icon(
                  f.isRequired ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  size: 16,
                  color: f.isRequired ? Colors.green : Colors.grey,
                ),
              ),
              AppTableColumn(
                label: 'Actions',
                width: 80,
                builder: (f) => IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () {
                    // TODO: Implement delete logic in StudentService
                    AppDialogs.showInfo(context, title: 'Coming Soon', message: 'Delete coming soon.');
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
