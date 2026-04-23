import 'package:educore/src/features/exams/models/exam_schedule.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/exams/controllers/exam_controller.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:intl/intl.dart';

class SchedulePaperDialog extends StatefulWidget {
  const SchedulePaperDialog({
    super.key,
    required this.controller,
    required this.exam,
  });

  final ExamController controller;
  final Exam exam;

  @override
  State<SchedulePaperDialog> createState() => _SchedulePaperDialogState();
}

class _SchedulePaperDialogState extends State<SchedulePaperDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _subjectNameController;
  late TextEditingController _durationController;
  late TextEditingController _totalMarksController;
  late TextEditingController _passingMarksController;

  DateTime _paperDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  @override
  void initState() {
    super.initState();
    _paperDate = widget.exam.startDate;
    _subjectNameController = TextEditingController();
    _durationController = TextEditingController(text: '120'); // mins
    _totalMarksController = TextEditingController(text: '100');
    _passingMarksController = TextEditingController(text: '33');
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _durationController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paperDate,
      firstDate: widget.exam.startDate,
      lastDate: widget.exam.endDate,
    );
    if (picked != null) setState(() => _paperDate = picked);
  }

  Future<void> _selectTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    AppDialogs.showLoading(context, message: 'Scheduling paper...');

    final schedule = ExamSchedule(
      id: '',
      examId: widget.exam.id,
      classId: widget.exam.classId,
      subjectId:
          'custom_${DateTime.now().millisecondsSinceEpoch}', // Will map real subjects later if needed
      subjectName: _subjectNameController.text.trim(),
      paperDate: _paperDate,
      startTime: _startTime,
      endTime: _endTime,
      durationMinutes: int.parse(_durationController.text),
      totalMarks: double.parse(_totalMarksController.text),
      passingMarks: double.parse(_passingMarksController.text),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await widget.controller.createSchedule(
      schedule,
    );

    if (!mounted) return;
    AppDialogs.hide(context);

    if (success) {
      Navigator.of(context).pop();
      AppDialogs.showInfo(
        context,
        title: 'Success',
        message: 'Paper scheduled successfully.',
      );
    } else {
      AppDialogs.showError(
        context,
        title: 'Error',
        message: widget.controller.error ?? 'Validation failed',
      );
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
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Paper',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'For ${widget.exam.name}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
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
                        controller: _subjectNameController,
                        label: 'Subject Name',
                        hintText: 'e.g., Mathematics',
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: AppRadii.r12,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Paper Date',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.r12,
                            ),
                          ),
                          child: Text(df.format(_paperDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(true),
                              borderRadius: AppRadii.r12,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Time',
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadii.r12,
                                  ),
                                ),
                                child: Text(_startTime.format(context)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(false),
                              borderRadius: AppRadii.r12,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Time',
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadii.r12,
                                  ),
                                ),
                                child: Text(_endTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _totalMarksController,
                              label: 'Total Marks',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _passingMarksController,
                              label: 'Passing Marks',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _durationController,
                        label: 'Duration (Minutes)',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Req' : null,
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
                  AppPrimaryButton(onPressed: _submit, label: 'Schedule'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
