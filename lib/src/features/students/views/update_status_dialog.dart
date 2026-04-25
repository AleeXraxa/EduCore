import 'package:flutter/material.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/controllers/student_controller.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';

class UpdateStudentStatusDialog extends StatefulWidget {
  const UpdateStudentStatusDialog({
    super.key,
    required this.student,
    required this.controller,
  });

  final Student student;
  final StudentController controller;

  @override
  State<UpdateStudentStatusDialog> createState() => _UpdateStudentStatusDialogState();
}

class _UpdateStudentStatusDialogState extends State<UpdateStudentStatusDialog> {
  late String _status;
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _status = widget.student.status;
    _reasonController.text = widget.student.statusReason ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await AppDialogs.showConfirm(
      context,
      title: 'Confirm Status Update',
      message: 'Are you sure you want to change the status of ${widget.student.name} to ${_status.toUpperCase()}?',
    );

    if (confirmed == true) {
      if (mounted) {
        AppDialogs.showLoading(context, message: 'Updating status...');
      }
      
      final success = await widget.controller.updateStatus(
        context,
        widget.student,
        _status,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        AppDialogs.hideLoading(context);
        if (success) {
          Navigator.pop(context);
          AppDialogs.showSuccess(
            context,
            title: 'Status Updated',
            message: 'Student status has been successfully updated.',
          );
        } else {
          AppDialogs.showError(
            context,
            title: 'Update Failed',
            message: 'An error occurred while updating the student status.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.published_with_changes_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Status',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          widget.student.name,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              AppDropdown<String>(
                label: 'Student Status',
                value: _status,
                items: const ['active', 'passout', 'dropped'],
                itemLabel: (s) => s[0].toUpperCase() + s.substring(1),
                onChanged: (val) => setState(() => _status = val!),
                prefixIcon: Icons.flag_outlined,
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Remarks / Reason',
                  hintText: 'e.g. Completed Course, Left Institute...',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _handleUpdate,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
