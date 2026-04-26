import 'package:educore/src/features/exams/models/exam_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/exams/models/exam_marks.dart';
import 'package:educore/src/features/exams/controllers/exam_controller.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';

class MarksEntryView extends StatefulWidget {
  const MarksEntryView({
    super.key,
    required this.controller,
    required this.exam,
  });

  final ExamController controller;
  final Exam exam;

  @override
  State<MarksEntryView> createState() => _MarksEntryViewState();
}

class _MarksEntryViewState extends State<MarksEntryView> {
  ExamSchedule? _selectedSchedule;

  // Track changes locally before submitting
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, String> _statusMap = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.controller.currentSchedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Text(
            'No schedules found. Schedule a paper first before entering marks.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    // Default selection
    if (_selectedSchedule == null) {
       _selectedSchedule = widget.controller.currentSchedules.first;
       // We should load it if currentMarks are for a different schedule or empty.
       // For simplicity, let the FutureBuilder or just the initial load handle it,
       // but here we are in build... better to just use currentMarks.
    }

    final marks = widget.controller.currentMarks;

    // Initialize state
    for (var m in marks) {
      if (!_marksControllers.containsKey(m.studentId)) {
        _marksControllers[m.studentId] = TextEditingController(
          text: m.obtainedMarks.toString(),
        );
        _statusMap[m.studentId] = m.status;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marks Entry',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (widget.exam.status != 'published')
                AppPrimaryButton(
                  onPressed: () async {
                    AppDialogs.showLoading(context, message: 'Saving marks...');

                    // Convert local maps back to marks list
                    final updatedMarks = marks.map((m) {
                      final marksText =
                          _marksControllers[m.studentId]?.text ?? '0';
                      return m.copyWith(
                        obtainedMarks: double.tryParse(marksText) ?? 0,
                        status: _statusMap[m.studentId] ?? m.status,
                      );
                    }).toList();

                    final success = await widget.controller.saveMarks(updatedMarks);

                    if (context.mounted) {
                      AppDialogs.hide(context);
                      if (success) {
                        AppDialogs.showInfo(
                          context,
                          title: 'Success',
                          message: 'Marks saved successfully.',
                        );
                      } else {
                        AppDialogs.showError(
                          context,
                          title: 'Error',
                          message:
                              widget.controller.error ??
                              'Failed to save marks.',
                        );
                      }
                    }
                  },
                  label: 'Save Marks',
                  icon: Icons.save_rounded,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Select Subject:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedSchedule!.id,
                items: widget.controller.currentSchedules
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.subjectName),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedSchedule = widget.controller.currentSchedules
                          .firstWhere((s) => s.id == v);
                      // Clear controllers to load new data
                      _marksControllers.clear();
                      _statusMap.clear();
                    });
                    widget.controller.loadMarksEntry(_selectedSchedule!);
                  }
                },
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (var studentId in _statusMap.keys) {
                      _statusMap[studentId] = 'present';
                    }
                  });
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Mark All Present'),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: AppRadii.r12,
                ),
                child: Text(
                  'Total Marks: ${_selectedSchedule!.totalMarks}',
                  style: TextStyle(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.controller.busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (marks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    const Text('No students found or marks list is empty.'),
                    const SizedBox(height: 16),
                    if (widget.exam.status != 'published')
                      AppPrimaryButton(
                        onPressed: () async {
                          AppDialogs.showLoading(
                            context,
                            message: 'Loading students and marks...',
                          );
                          await widget.controller.loadMarksEntry(_selectedSchedule!);
                          if (context.mounted) AppDialogs.hide(context);
                          setState(() {});
                        },
                        label: 'Generate Student List',
                      ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: AppRadii.r24,
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Student Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Obtained Marks',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: marks.map((m) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              m.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          DataCell(
                            widget.exam.status == 'published'
                                ? Text('${m.obtainedMarks}')
                                : SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      controller:
                                          _marksControllers[m.studentId],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'),
                                        ),
                                      ],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                          ),
                          DataCell(
                            widget.exam.status == 'published'
                                ? Text(m.status.toUpperCase())
                                : DropdownButton<String>(
                                    value: _statusMap[m.studentId] ?? m.status,
                                    isDense: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'present',
                                        child: Text('Present'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'absent',
                                        child: Text('Absent'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'excused',
                                        child: Text('Excused'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _statusMap[m.studentId] = v;
                                          if (v != 'present') {
                                            _marksControllers[m.studentId]
                                                    ?.text =
                                                '0';
                                          }
                                        });
                                      }
                                    },
                                  ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
