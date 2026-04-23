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
                      Icons.calendar_today_rounded,
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
                          'Schedule Paper',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For ${widget.exam.name}',
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
                        controller: _subjectNameController,
                        label: 'Subject Name',
                        hintText: 'e.g., Mathematics',
                        prefixIcon: Icons.subject_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      _DateSelector(
                        label: 'Paper Date',
                        value: df.format(_paperDate),
                        icon: Icons.calendar_today_rounded,
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _DateSelector(
                              label: 'Start Time',
                              value: _startTime.format(context),
                              icon: Icons.schedule_rounded,
                              onTap: () => _selectTime(true),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _DateSelector(
                              label: 'End Time',
                              value: _endTime.format(context),
                              icon: Icons.update_rounded,
                              onTap: () => _selectTime(false),
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
                              prefixIcon: Icons.score_rounded,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req' : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AppTextField(
                              controller: _passingMarksController,
                              label: 'Passing Marks',
                              prefixIcon: Icons.check_circle_outline_rounded,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _durationController,
                        label: 'Duration (Minutes)',
                        prefixIcon: Icons.timer_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Req' : null,
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
                    label: 'Schedule Paper',
                    icon: Icons.add_rounded,
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
