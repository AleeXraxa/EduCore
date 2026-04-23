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
  const MarksEntryView({super.key, required this.test, required this.controller});
  final MonthlyTest test;
  final MonthlyTestController controller;

  @override
  State<MarksEntryView> createState() => _MarksEntryViewState();
}

class _MarksEntryViewState extends State<MarksEntryView> {
  final Map<String, TextEditingController> _markControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await widget.controller.loadMarksEntry(widget.test);
    for (var m in widget.controller.currentMarks) {
      _markControllers[m.studentId] = TextEditingController(text: m.obtainedMarks.toString());
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (var c in _markControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final List<TestMarks> updatedMarks = [];
    
    for (var m in widget.controller.currentMarks) {
      final text = _markControllers[m.studentId]?.text ?? '0';
      final val = double.tryParse(text) ?? 0.0;
      
      if (val > widget.test.totalMarks) {
        AppDialogs.showError(context, title: 'Invalid Marks', message: '${m.studentName} has marks greater than total marks (${widget.test.totalMarks}).');
        return;
      }

      updatedMarks.add(m.copyWith(
        obtainedMarks: val,
        status: val >= widget.test.passingMarks ? 'Pass' : 'Fail',
      ));
    }

    AppDialogs.showLoading(context, message: 'Saving Marks...');
    final success = await widget.controller.saveMarks(updatedMarks);
    
    if (!mounted) return;
    AppDialogs.hide(context);

    if (success) {
      AppDialogs.showInfo(context, title: 'Success', message: 'Marks saved successfully.');
    } else {
      AppDialogs.showError(context, title: 'Error', message: widget.controller.error ?? 'Failed to save marks.');
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
                  Text('Enter Marks', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${widget.test.title} - ${widget.test.subject}', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
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
                _InfoItem(label: 'Total Marks', value: '${widget.test.totalMarks.toInt()}'),
                _InfoItem(label: 'Passing Marks', value: '${widget.test.passingMarks.toInt()}'),
                _InfoItem(label: 'Total Students', value: '${widget.controller.currentMarks.length}'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('ROLL NO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary))),
                Expanded(flex: 5, child: Text('STUDENT NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary))),
                Expanded(flex: 3, child: Text('OBTAINED MARKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary))),
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

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: marks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, index) {
                      final m = marks[index];
                      return _MarksRow(
                        mark: m,
                        controller: _markControllers[m.studentId]!,
                        totalMarks: widget.test.totalMarks,
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
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }
}

class _MarksRow extends StatelessWidget {
  const _MarksRow({required this.mark, required this.controller, required this.totalMarks});
  final TestMarks mark;
  final TextEditingController controller;
  final double totalMarks;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(mark.studentRollNo, style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 5,
            child: Text(mark.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('/ ${totalMarks.toInt()}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
