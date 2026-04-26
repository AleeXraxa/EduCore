import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/monthly_tests/controllers/monthly_test_controller.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_marks.dart';

class MarksEntryView extends StatefulWidget {
  const MarksEntryView({
    super.key,
    required this.test,
    required this.controller,
  });
  final MonthlyTest test;
  final MonthlyTestController controller;

  @override
  State<MarksEntryView> createState() => _MarksEntryViewState();
}

class _MarksEntryViewState extends State<MarksEntryView> {
  // subjectId -> studentId -> controller
  final Map<String, Map<String, TextEditingController>> _markControllers = {};
  // subjectId -> studentId -> status
  final Map<String, Map<String, String>> _statuses = {};

  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    if (widget.test.subjects.isNotEmpty) {
      _selectedSubjectId = widget.test.subjects.first.id;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    await widget.controller.loadMarksEntry(widget.test);

    for (var sub in widget.test.subjects) {
      _markControllers[sub.id] = {};
      _statuses[sub.id] = {};

      for (var m in widget.controller.currentMarks) {
        final existingSubMark = m.subjectMarks[sub.id];

        _markControllers[sub.id]![m.studentId] = TextEditingController(
          text: existingSubMark?.toString() ?? '0',
        );
        _statuses[sub.id]![m.studentId] = m.status == 'Absent'
            ? 'Absent'
            : 'Present';
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (var subMap in _markControllers.values) {
      for (var c in subMap.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    final List<TestMarks> updatedMarks = [];

    for (var studentMark in widget.controller.currentMarks) {
      final Map<String, double> updatedSubMarks = Map.from(
        studentMark.subjectMarks,
      );
      double totalObtained = 0.0;
      bool allAbsent = true;

      for (var sub in widget.test.subjects) {
        final status = _statuses[sub.id]?[studentMark.studentId] ?? 'Present';
        final text =
            _markControllers[sub.id]?[studentMark.studentId]?.text ?? '0';
        final val = double.tryParse(text) ?? 0.0;

        if (status != 'Absent') {
          allAbsent = false;
          totalObtained += val;
        }

        if (val > sub.totalMarks) {
          AppDialogs.showError(
            context,
            title: 'Invalid Marks',
            message:
                '${studentMark.studentName} has ${sub.name} marks greater than max (${sub.totalMarks}).',
          );
          return;
        }

        updatedSubMarks[sub.id] = val;
      }

      final overallPassMin = widget.test.subjects.fold(
        0.0,
        (s, e) => s + e.passingMarks,
      );

      updatedMarks.add(
        studentMark.copyWith(
          subjectMarks: updatedSubMarks,
          status: allAbsent
              ? 'Absent'
              : (totalObtained >= overallPassMin ? 'Pass' : 'Fail'),
        ),
      );
    }

    AppDialogs.showLoading(context, message: 'Saving Marks...');
    final success = await widget.controller.saveMarks(widget.test.id, updatedMarks);

    if (!mounted) return;
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
        message: widget.controller.error ?? 'Failed to save marks.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 1000,
      height: 800,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Marks',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.test.title} - ${widget.test.subject}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              AppPrimaryButton(
                onPressed: _save,
                icon: Icons.save_rounded,
                label: 'Save Marks',
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.1),
              borderRadius: AppRadii.r16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  label: 'Assessment Total',
                  value:
                      '${widget.test.subjects.fold(0.0, (s, e) => s + e.totalMarks).toInt()}',
                ),
                _InfoItem(
                  label: 'Min Passing',
                  value:
                      '${widget.test.subjects.fold(0.0, (s, e) => s + e.passingMarks).toInt()}',
                ),
                _InfoItem(
                  label: 'Total Students',
                  value: '${widget.controller.currentMarks.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Subject Selection
          if (widget.test.subjects.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.test.subjects.map((sub) {
                  final isSelected = _selectedSubjectId == sub.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(
                        sub.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedSubjectId = sub.id);
                      },
                      selectedColor: cs.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : cs.onSurfaceVariant,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  if (_selectedSubjectId != null) {
                    setState(() {
                      final subId = _selectedSubjectId!;
                      for (var studentId in _statuses[subId]!.keys) {
                        _statuses[subId]![studentId] = 'Present';
                      }
                    });
                  }
                },
                icon: const Icon(Icons.done_all_rounded, size: 20),
                label: const Text('Mark All Present'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'ROLL NO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'STUDENT NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'OBTAINED MARKS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Marks List
          Expanded(
            child: ControllerBuilder<MonthlyTestController>(
              controller: widget.controller,
              builder: (context, controller, _) {
                if (controller.busy && controller.currentMarks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final marks = controller.currentMarks;
                final subId = _selectedSubjectId;
                if (subId == null || _markControllers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentSub = widget.test.subjects.firstWhere(
                  (s) => s.id == subId,
                  orElse: () => widget.test.subjects.first,
                );

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: marks.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, index) {
                      final m = marks[index];
                      final controllers = _markControllers[subId];
                      final studentController = controllers?[m.studentId];
                      final studentStatus = _statuses[subId]?[m.studentId];

                      if (studentController == null || studentStatus == null) {
                        return const SizedBox(
                          height: 60,
                          child: Center(child: LinearProgressIndicator()),
                        );
                      }

                      return _MarksRow(
                        mark: m,
                        controller: studentController,
                        status: studentStatus,
                        onStatusChanged: (val) {
                          setState(() {
                            _statuses[subId]![m.studentId] = val;
                            if (val == 'Absent') {
                              _markControllers[subId]?[m.studentId]?.text = '0';
                            }
                          });
                        },
                        totalMarks: currentSub.totalMarks,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ],
    );
  }
}

class _MarksRow extends StatelessWidget {
  const _MarksRow({
    required this.mark,
    required this.controller,
    required this.totalMarks,
    required this.status,
    required this.onStatusChanged,
  });

  final TestMarks mark;
  final TextEditingController controller;
  final double totalMarks;
  final String status;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAbsent = status == 'Absent';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              mark.studentRollNo,
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              mark.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    isAbsent ? 'Absent' : 'Present',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isAbsent,
                  onSelected: (val) =>
                      onStatusChanged(val ? 'Absent' : 'Present'),
                  selectedColor: cs.errorContainer,
                  labelStyle: TextStyle(
                    color: isAbsent ? cs.error : cs.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: controller,
                    enabled: !isAbsent,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isAbsent ? cs.outline : cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: isAbsent
                          ? cs.surfaceContainerHighest
                          : cs.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${totalMarks.toInt()}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
