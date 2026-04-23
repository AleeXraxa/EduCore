import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/monthly_tests/controllers/monthly_test_controller.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:intl/intl.dart';

class AddEditTestDialog extends StatefulWidget {
  const AddEditTestDialog({
    super.key,
    required this.controller,
    this.test,
  });

  final MonthlyTestController controller;
  final MonthlyTest? test;

  @override
  State<AddEditTestDialog> createState() => _AddEditTestDialogState();
}

class _AddEditTestDialogState extends State<AddEditTestDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _durationController;
  late final TextEditingController _totalMarksController;
  late final TextEditingController _passingMarksController;
  late final TextEditingController _descController;
  
  String? _selectedClassId;
  DateTime _testDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.test?.title);
    _subjectController = TextEditingController(text: widget.test?.subject);
    _durationController = TextEditingController(text: widget.test?.durationMinutes.toString() ?? '60');
    _totalMarksController = TextEditingController(text: widget.test?.totalMarks.toInt().toString() ?? '100');
    _passingMarksController = TextEditingController(text: widget.test?.passingMarks.toInt().toString() ?? '40');
    _descController = TextEditingController(text: widget.test?.description);
    
    if (widget.test != null) {
      _selectedClassId = widget.test!.classId;
      _testDate = widget.test!.testDate;
    } else if (widget.controller.classes.isNotEmpty) {
      _selectedClassId = widget.controller.classes.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _durationController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      AppDialogs.showError(context, title: 'Class Required', message: 'Please select a class.');
      return;
    }

    final cls = widget.controller.classes.firstWhere((c) => c.id == _selectedClassId);

    final test = MonthlyTest(
      id: widget.test?.id ?? '',
      title: _titleController.text,
      subject: _subjectController.text,
      classId: _selectedClassId!,
      className: cls.displayName,
      testDate: _testDate,
      durationMinutes: int.parse(_durationController.text),
      totalMarks: double.parse(_totalMarksController.text),
      passingMarks: double.parse(_passingMarksController.text),
      description: _descController.text,
      status: widget.test?.status ?? 'upcoming',
      questionCount: widget.test?.questionCount ?? 0,
      createdAt: widget.test?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    AppDialogs.showLoading(context, message: widget.test == null ? 'Creating...' : 'Saving...');
    
    final success = widget.test == null 
        ? await widget.controller.createTest(test)
        : await widget.controller.updateTest(test);

    if (!mounted) return;
    AppDialogs.hide(context);

    if (success) {
      Navigator.of(context).pop();
    } else {
      AppDialogs.showError(context, title: 'Error', message: widget.controller.error ?? 'Action failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('MMM d, yyyy');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r24,
          boxShadow: AppShadows.soft(cs.shadow),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: AppRadii.r12,
                    ),
                    child: Icon(widget.test == null ? Icons.add_rounded : Icons.edit_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.test == null ? 'Create Monthly Test' : 'Edit Test Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Fill in the details for the assessment.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _titleController,
                        label: 'Test Title',
                        hintText: 'e.g., Mathematics Quiz - April',
                        prefixIcon: Icons.title_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _subjectController,
                              label: 'Subject',
                              hintText: 'e.g., Mathematics',
                              prefixIcon: Icons.book_rounded,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Select Class',
                              items: widget.controller.classes.map((c) => c.id).toList(),
                              value: _selectedClassId,
                              itemLabel: (id) => widget.controller.classes.firstWhere((c) => c.id == id).displayName,
                              prefixIcon: Icons.school_rounded,
                              onChanged: (v) => setState(() => _selectedClassId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _DateSelector(
                              label: 'Test Date',
                              value: df.format(_testDate),
                              icon: Icons.calendar_today_rounded,
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _testDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (d != null) setState(() => _testDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AppTextField(
                              controller: _durationController,
                              label: 'Duration (Mins)',
                              hintText: '60',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.timer_rounded,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _totalMarksController,
                              label: 'Total Marks',
                              hintText: '100',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.score_rounded,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AppTextField(
                              controller: _passingMarksController,
                              label: 'Passing Marks',
                              hintText: '40',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.check_circle_outline_rounded,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _descController,
                        label: 'Description / Instructions',
                        hintText: 'Add any specific instructions for this test...',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 16),
                  AppPrimaryButton(
                    onPressed: _submit,
                    label: widget.test == null ? 'Create Test' : 'Save Changes',
                    icon: widget.test == null ? Icons.add_rounded : Icons.save_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.label, required this.value, required this.icon, required this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.r12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: AppRadii.r12,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
