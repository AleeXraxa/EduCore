import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/exams/controllers/exam_controller.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:educore/src/features/exams/widgets/schedule_paper_dialog.dart';
import 'package:educore/src/features/exams/views/marks_entry_view.dart';
import 'package:educore/src/features/exams/views/results_view.dart';
import 'package:intl/intl.dart';

class ExamDetailsView extends StatefulWidget {
  const ExamDetailsView({
    super.key,
    required this.exam,
    required this.controller,
  });

  final Exam exam;
  final ExamController controller;

  @override
  State<ExamDetailsView> createState() => _ExamDetailsViewState();
}

class _ExamDetailsViewState extends State<ExamDetailsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final featureSvc = AppServices.instance.featureAccessService!;
    int tabCount = 1;
    if (featureSvc.canAccess('exam_edit')) tabCount++;
    if (featureSvc.canAccess('marks_entry')) tabCount++;
    if (featureSvc.canAccess('result_publish')) tabCount++;

    _tabController = TabController(length: tabCount, vsync: this);
    widget.controller.selectExam(widget.exam);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('MMM d, yyyy');

    return ControllerBuilder<ExamController>(
      controller: widget.controller,
      builder: (context, controller, child) {
        // Find fresh instance in case it was updated
        final currentExam = controller.exams.firstWhere((e) => e.id == widget.exam.id, orElse: () => widget.exam);

        return Scaffold(
          appBar: AppBar(
            title: Text(currentExam.name, style: const TextStyle(fontWeight: FontWeight.w900)),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                const Tab(text: 'Overview'),
                if (AppServices.instance.featureAccessService!.canAccess('exam_edit'))
                  const Tab(text: 'Schedule Papers'),
                if (AppServices.instance.featureAccessService!.canAccess('marks_entry'))
                  const Tab(text: 'Marks Entry'),
                if (AppServices.instance.featureAccessService!.canAccess('result_publish'))
                  const Tab(text: 'Results'),
              ],
            ),
          ),
            children: [
              // 1. Overview
              SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: 'EXAM INFO',
                        icon: Icons.info_outline_rounded,
                        rows: [
                          _InfoRow(label: 'Type', value: currentExam.type),
                          _InfoRow(label: 'Class', value: currentExam.className ?? 'Unknown'),
                          _InfoRow(label: 'Duration', value: '${df.format(currentExam.startDate)} - ${df.format(currentExam.endDate)}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoCard(
                        title: 'STATUS',
                        icon: Icons.check_circle_outline,
                        rows: [
                          _InfoRow(label: 'Current Status', value: currentExam.status.toUpperCase()),
                          _InfoRow(label: 'Total Papers Started', value: controller.currentSchedules.length.toString()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Schedule
              if (AppServices.instance.featureAccessService!.canAccess('exam_edit'))
                _SchedulesTab(exam: currentExam, controller: controller),

              // 3. Marks Entry 
              if (AppServices.instance.featureAccessService!.canAccess('marks_entry'))
                MarksEntryView(controller: controller, exam: currentExam),

              // 4. Results
              if (AppServices.instance.featureAccessService!.canAccess('result_publish'))
                ResultsView(controller: controller, exam: currentExam),
            ],
          ),
        );
      },
    );
  }
}

class _SchedulesTab extends StatelessWidget {
  const _SchedulesTab({required this.exam, required this.controller});
  final Exam exam;
  final ExamController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exam Schedule', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (exam.status != 'published')
                AppPrimaryButton(
                  onPressed: () {
                     showDialog(
                       context: context,
                       builder: (_) => SchedulePaperDialog(controller: controller, exam: exam),
                     );
                  },
                  label: 'Schedule Paper',
                  icon: Icons.add_rounded,
                )
            ],
          ),
          const SizedBox(height: 24),
          if (controller.currentSchedules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Text('No papers scheduled yet.', style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: AppRadii.r24,
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHighest.withValues(alpha: 0.3)),
                    columns: const [
                       DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                       DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                       DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                       DataColumn(label: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold))),
                       DataColumn(label: Text('Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                       DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: controller.currentSchedules.map((s) {
                       return DataRow(cells: [
                         DataCell(Text(s.subjectName, style: const TextStyle(fontWeight: FontWeight.w800))),
                         DataCell(Text(df.format(s.paperDate))),
                         DataCell(Text('${s.startTime.format(context)} - ${s.endTime.format(context)}')),
                         DataCell(Text('${s.durationMinutes} mins')),
                         DataCell(Text('${s.passingMarks} / ${s.totalMarks}')),
                         DataCell(
                           IconButton(
                             icon: const Icon(Icons.delete_outline, color: Colors.red),
                             onPressed: () async {
                                final confirm = await AppDialogs.showConfirm(context, title: 'Delete Schedule?', message: 'Delete ${s.subjectName} schedule? Marks associated will also be removed.', isDanger: true);
                                if (confirm == true) {
                                  AppDialogs.showLoading(context, message: 'Deleting...');
                                  await controller.deleteSchedule(s.id);
                                  if (context.mounted) AppDialogs.hide(context);
                                }
                             },
                           ),
                         ),
                       ]);
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.rows});
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast(),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
