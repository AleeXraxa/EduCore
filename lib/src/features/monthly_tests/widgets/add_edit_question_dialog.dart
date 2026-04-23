import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/monthly_tests/controllers/monthly_test_controller.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';

class AddEditQuestionDialog extends StatefulWidget {
  const AddEditQuestionDialog({
    super.key,
    required this.controller,
    required this.testId,
    this.question,
  });

  final MonthlyTestController controller;
  final String testId;
  final TestQuestion? question;

  @override
  State<AddEditQuestionDialog> createState() => _AddEditQuestionDialogState();
}

class _AddEditQuestionDialogState extends State<AddEditQuestionDialog> {
  late final TextEditingController _qController;
  late final TextEditingController _aController;
  late final TextEditingController _bController;
  late final TextEditingController _cController;
  late final TextEditingController _dController;
  late final TextEditingController _marksController;
  
  String? _selectedSubjectId;
  String _correctOption = 'A';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _qController = TextEditingController(text: widget.question?.questionText);
    _aController = TextEditingController(text: widget.question?.optionA);
    _bController = TextEditingController(text: widget.question?.optionB);
    _cController = TextEditingController(text: widget.question?.optionC);
    _dController = TextEditingController(text: widget.question?.optionD);
    _marksController = TextEditingController(text: widget.question?.marks.toInt().toString() ?? '1');
    
    if (widget.question != null) {
      _correctOption = widget.question!.correctOption;
      _selectedSubjectId = widget.question!.subjectId;
    } else if (widget.controller.selectedTest?.subjects.isNotEmpty ?? false) {
      _selectedSubjectId = widget.controller.selectedTest!.subjects.first.id;
    }
  }

  @override
  void dispose() {
    _qController.dispose();
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    _dController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      AppDialogs.showError(context, title: 'Subject Required', message: 'Please select a subject for this question.');
      return;
    }

    final question = TestQuestion(
      id: widget.question?.id ?? '',
      testId: widget.testId,
      subjectId: _selectedSubjectId!,
      questionText: _qController.text,
      optionA: _aController.text,
      optionB: _bController.text,
      optionC: _cController.text,
      optionD: _dController.text,
      correctOption: _correctOption,
      marks: double.parse(_marksController.text),
      createdAt: widget.question?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    AppDialogs.showLoading(context, message: 'Saving Question...');
    final success = await widget.controller.addQuestion(question);
    
    if (!mounted) return;
    AppDialogs.hide(context);

    if (success) {
      Navigator.of(context).pop();
    } else {
      AppDialogs.showError(context, title: 'Error', message: widget.controller.error ?? 'Failed to save question.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(48),
      child: Container(
        width: 800,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r24,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question == null ? 'Add MCQ Question' : 'Edit Question',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text('Configure question text, options, and marks', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                AppPrimaryButton(
                  onPressed: _submit,
                  label: 'Save Question',
                  icon: Icons.check_rounded,
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QUESTION DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      if (widget.controller.selectedTest != null && widget.controller.selectedTest!.subjects.length > 1) ...[
                         DropdownButtonFormField<String>(
                            initialValue: _selectedSubjectId,
                            decoration: InputDecoration(
                              labelText: 'Select Subject',
                              border: OutlineInputBorder(borderRadius: AppRadii.r12),
                              prefixIcon: const Icon(Icons.book_rounded),
                            ),
                            items: widget.controller.selectedTest!.subjects.map((s) {
                              return DropdownMenuItem(value: s.id, child: Text(s.name));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedSubjectId = v),
                            validator: (v) => v == null ? 'Required' : null,
                         ),
                         const SizedBox(height: 24),
                      ],
                      AppTextField(
                        key: const ValueKey('question_field'),
                        controller: _qController,
                        label: 'Question Statement',
                        hintText: 'e.g. What is the capital of France?',
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Question text is required' : null,
                      ),
                      const SizedBox(height: 32),
                      
                      Text('OPTIONS & CORRECT ANSWER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      _OptionField(
                        key: const ValueKey('opt_A'),
                        controller: _aController,
                        label: 'Option A',
                        isSelected: _correctOption == 'A',
                        onSelect: () => setState(() => _correctOption = 'A'),
                      ),
                      const SizedBox(height: 12),
                      _OptionField(
                        key: const ValueKey('opt_B'),
                        controller: _bController,
                        label: 'Option B',
                        isSelected: _correctOption == 'B',
                        onSelect: () => setState(() => _correctOption = 'B'),
                      ),
                      const SizedBox(height: 12),
                      _OptionField(
                        key: const ValueKey('opt_C'),
                        controller: _cController,
                        label: 'Option C',
                        isSelected: _correctOption == 'C',
                        onSelect: () => setState(() => _correctOption = 'C'),
                      ),
                      const SizedBox(height: 12),
                      _OptionField(
                        key: const ValueKey('opt_D'),
                        controller: _dController,
                        label: 'Option D',
                        isSelected: _correctOption == 'D',
                        onSelect: () => setState(() => _correctOption = 'D'),
                      ),
                      const SizedBox(height: 32),

                      Text('GRADING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: AppTextField(
                          key: const ValueKey('marks_field'),
                          controller: _marksController,
                          label: 'Marks',
                          hintText: '1.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    super.key,
    required this.controller,
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  final TextEditingController controller;
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Radio<bool>(
          value: true,
          groupValue: isSelected,
          onChanged: (_) => onSelect(),
          activeColor: const Color(0xFF10B981),
        ),
        Expanded(
          child: AppTextField(
            key: ValueKey('field_$label'),
            controller: controller,
            label: label,
            hintText: 'Enter option text...',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}
