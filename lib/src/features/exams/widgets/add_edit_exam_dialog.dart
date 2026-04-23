import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
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
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 500,
        color: cs.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.description_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exam == null ? 'Create New Exam' : 'Edit Exam',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          'Schedule academic assessments for classes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
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
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Exam Type',
                          filled: true,
                          fillColor: cs.surface,
                          border: OutlineInputBorder(borderRadius: AppRadii.r12),
                        ),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: InputDecoration(
                          labelText: 'Select Class',
                          filled: true,
                          fillColor: cs.surface,
                          border: OutlineInputBorder(borderRadius: AppRadii.r12),
                        ),
                        items: widget.controller.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))).toList(),
                        onChanged: widget.exam == null ? (v) => setState(() => _selectedClassId = v!) : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              borderRadius: AppRadii.r12,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: AppRadii.r12),
                                ),
                                child: Text(df.format(_startDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                           Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              borderRadius: AppRadii.r12,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date',
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: AppRadii.r12),
                                ),
                                child: Text(df.format(_endDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _descController,
                        label: 'Description / Instructions',
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  AppPrimaryButton(
                    onPressed: _submit,
                    label: widget.exam == null ? 'Create Exam' : 'Save Changes',
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
