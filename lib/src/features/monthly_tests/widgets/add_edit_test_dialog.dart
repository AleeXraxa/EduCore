import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/monthly_tests/controllers/monthly_test_controller.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_subject.dart';
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
  late final TextEditingController _durationController;
  late final TextEditingController _descController;
  
  // Subject Entry Controllers
  late final TextEditingController _subNameController;
  late final TextEditingController _subTotalMarksController;
  late final TextEditingController _subPassingMarksController;

  String? _selectedClassId;
  DateTime _testDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  
  List<TestSubject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.test?.title);
    _durationController = TextEditingController(text: widget.test?.durationMinutes.toString() ?? '60');
    _descController = TextEditingController(text: widget.test?.description);
    
    _subNameController = TextEditingController();
    _subTotalMarksController = TextEditingController(text: '100');
    _subPassingMarksController = TextEditingController(text: '40');

    if (widget.test != null) {
      _selectedClassId = widget.test!.classId;
      _testDate = widget.test!.testDate;
      _subjects = List.from(widget.test!.subjects);
    } else if (widget.controller.classes.isNotEmpty) {
      _selectedClassId = widget.controller.classes.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _descController.dispose();
    _subNameController.dispose();
    _subTotalMarksController.dispose();
    _subPassingMarksController.dispose();
    super.dispose();
  }

  void _addSubject() {
    final name = _subNameController.text.trim();
    if (name.isEmpty) return;
    
    final total = double.tryParse(_subTotalMarksController.text) ?? 100;
    final passing = double.tryParse(_subPassingMarksController.text) ?? 40;

    setState(() {
      _subjects.add(TestSubject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        totalMarks: total,
        passingMarks: passing,
      ));
      _subNameController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      AppDialogs.showError(context, title: 'Class Required', message: 'Please select a class.');
      return;
    }
    if (_subjects.isEmpty) {
       AppDialogs.showError(context, title: 'Subject Required', message: 'Please add at least one subject to this test.');
       return;
    }

    final cls = widget.controller.classes.firstWhere((c) => c.id == _selectedClassId);

    final test = MonthlyTest(
      id: widget.test?.id ?? '',
      title: _titleController.text,
      subjects: _subjects,
      classId: _selectedClassId!,
      className: cls.displayName,
      testDate: _testDate,
      durationMinutes: int.parse(_durationController.text),
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
        width: 850,
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
                        widget.test == null ? 'Create Assessment' : 'Edit Assessment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Configure subjects and criteria for this assessment.',
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Basic Details
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BASIC DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 1)),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _titleController,
                              label: 'Test Title',
                              hintText: 'e.g., Monthly Assessment - May',
                              prefixIcon: Icons.title_rounded,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),
                            AppDropdown<String>(
                              label: 'Select Class',
                              items: widget.controller.classes.map((c) => c.id).toList(),
                              value: _selectedClassId,
                              itemLabel: (id) => widget.controller.classes.firstWhere((c) => c.id == id).displayName,
                              prefixIcon: Icons.school_rounded,
                              onChanged: (v) => setState(() => _selectedClassId = v),
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
                      const SizedBox(width: 40),
                      // Right Column: Subjects
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SUBJECTS & CRITERIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 1)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: AppRadii.r20,
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: AppTextField(
                                          controller: _subNameController,
                                          label: 'Subject Name',
                                          hintText: 'e.g. Physics',
                                          prefixIcon: Icons.book_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: AppTextField(
                                          controller: _subTotalMarksController,
                                          label: 'Max',
                                          hintText: '100',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: AppTextField(
                                          controller: _subPassingMarksController,
                                          label: 'Pass',
                                          hintText: '40',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton.filled(
                                        onPressed: _addSubject,
                                        icon: const Icon(Icons.add_rounded),
                                        style: IconButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_subjects.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    const Divider(),
                                    const SizedBox(height: 16),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _subjects.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final sub = _subjects[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: cs.surface,
                                            borderRadius: AppRadii.r12,
                                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle_outline_rounded, size: 18, color: cs.primary),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                              Text('${sub.passingMarks.toInt()}/${sub.totalMarks.toInt()}', 
                                                style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                onPressed: () => setState(() => _subjects.removeAt(index)),
                                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                                color: cs.error,
                                                padding: EdgeInsets.zero,
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_subjects.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.05),
                                  borderRadius: AppRadii.r16,
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('AGGREGATE TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                                        Text('${_subjects.fold(0.0, (s, e) => s + e.totalMarks).toInt()} Marks', 
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: cs.primary)),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('MIN. PASSING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                                        Text('${_subjects.fold(0.0, (s, e) => s + e.passingMarks).toInt()} Marks', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
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
                    label: widget.test == null ? 'Create Assessment' : 'Save Changes',
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
