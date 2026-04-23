import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/exams/controllers/exam_controller.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:intl/intl.dart';

class AddEditExamDialog extends StatefulWidget {
  const AddEditExamDialog({
    super.key,
    required this.controller,
    this.exam,
  });

  final ExamController controller;
  final Exam? exam;

  @override
  State<AddEditExamDialog> createState() => _AddEditExamDialogState();
}

class _AddEditExamDialogState extends State<AddEditExamDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  
  String _selectedType = 'Monthly';
  String? _selectedClassId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  
  final _formKey = GlobalKey<FormState>();

  final List<String> _types = ['Monthly', 'Mid Term', 'Final Term', 'Custom'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exam?.name);
    _descController = TextEditingController(text: widget.exam?.description);
    
    if (widget.exam != null) {
      _selectedType = widget.exam!.type;
      _selectedClassId = widget.exam!.classId;
      _startDate = widget.exam!.startDate;
      _endDate = widget.exam!.endDate;
    } else if (widget.controller.classes.isNotEmpty) {
      _selectedClassId = widget.controller.classes.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class.')),
      );
      return;
    }

    final cls = widget.controller.classes.firstWhere((c) => c.id == _selectedClassId);

    AppDialogs.showLoading(context, message: 'Saving...');

    final exam = Exam(
      id: widget.exam?.id ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      classId: _selectedClassId!,
      className: cls.displayName,
      startDate: _startDate,
      endDate: _endDate,
      description: _descController.text.trim(),
      status: widget.exam?.status ?? 'upcoming',
      createdAt: widget.exam?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.exam == null) {
      success = await widget.controller.createExam(exam);
    } else {
      success = await widget.controller.updateExam(exam);
    }

    if (!mounted) return;
    AppDialogs.hide(context);

    if (success) {
      Navigator.of(context).pop();
      AppDialogs.showInfo(context, title: 'Success', message: 'Exam saved successfully.');
    } else {
      AppDialogs.showError(context, title: 'Error', message: widget.controller.error ?? 'Validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('MMM dd, yyyy');

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 550,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Gradient
            Container(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.6),
                    cs.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.assessment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exam == null ? 'Create New Exam' : 'Edit Exam',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Schedule academic assessments for classes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Exam Name',
                        hintText: 'e.g., Spring Mid Terms',
                        prefixIcon: Icons.title_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Exam Type',
                              items: _types,
                              value: _selectedType,
                              itemLabel: (t) => t,
                              prefixIcon: Icons.category_rounded,
                              hintText: 'Select type',
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedType = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Select Class',
                              items: widget.controller.classes.map((c) => c.id).toList(),
                              value: _selectedClassId,
                              itemLabel: (id) {
                                final cls = widget.controller.classes
                                    .where((c) => c.id == id)
                                    .firstOrNull;
                                return cls?.displayName ?? id;
                              },
                              prefixIcon: Icons.school_rounded,
                              hintText: 'Select class',
                              enabled: widget.exam == null,
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedClassId = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _DateSelector(
                              label: 'Start Date',
                              value: df.format(_startDate),
                              icon: Icons.calendar_today_rounded,
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _DateSelector(
                              label: 'End Date',
                              value: df.format(_endDate),
                              icon: Icons.event_rounded,
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _descController,
                        label: 'Description / Instructions',
                        hintText: 'Add any specific instructions for this exam...',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AppPrimaryButton(
                    onPressed: _submit,
                    label: widget.exam == null ? 'Create Exam' : 'Save Changes',
                    icon: widget.exam == null ? Icons.add_rounded : Icons.save_rounded,
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
  const _DateSelector({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

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
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: cs.surfaceContainerLow.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: AppRadii.r12,
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.r12,
            borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
