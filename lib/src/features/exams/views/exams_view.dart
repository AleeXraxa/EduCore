import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/exams/controllers/exam_controller.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:educore/src/features/exams/widgets/add_edit_exam_dialog.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/features/exams/views/exam_details_view.dart';
import 'package:intl/intl.dart';

class ExamsView extends StatefulWidget {
  const ExamsView({super.key});

  @override
  State<ExamsView> createState() => _ExamsViewState();
}

class _ExamsViewState extends State<ExamsView> {
  late final ExamController _controller;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = ExamController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<ExamController>(
      controller: _controller,
      builder: (context, controller, _) {
        final cs = Theme.of(context).colorScheme;

        // KPI Math
        final totalExams = controller.exams.length;
        final activeExams = controller.exams.where((e) => e.status == 'active' || e.status == 'upcoming').length;
        final publishedExams = controller.exams.where((e) => e.status == 'published').length;

        // Filter
        final filteredExams = controller.exams.where((e) {
          if (_searchQuery.isEmpty) return true;
          return e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (e.className?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AppAnimatedSlide(
                delayIndex: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exams & Results',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage academic assessments, marks entry, and result publishing.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    AppSearchField(
                      width: 280,
                      hintText: 'Search exams or class...',
                      onChanged: (v) {
                        setState(() {
                          _searchQuery = v;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    AppPrimaryButton(
                      onPressed: () {
                         showDialog(
                           context: context,
                           builder: (_) => AddEditExamDialog(controller: controller),
                         );
                      },
                      icon: Icons.add_rounded,
                      label: 'Create Exam',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // KPIs
              AppAnimatedSlide(
                delayIndex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        data: KpiCardData(
                          label: 'Total Exams',
                          value: totalExams.toString(),
                          icon: Icons.article_rounded,
                          gradient: [cs.primary, cs.primary.withValues(alpha: 0.5)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        data: KpiCardData(
                          label: 'Active / Upcoming',
                          value: activeExams.toString(),
                          icon: Icons.event_available_rounded,
                          gradient: [const Color(0xFFF59E0B), const Color(0xFFFCD34D)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        data: KpiCardData(
                          label: 'Published Results',
                          value: publishedExams.toString(),
                          icon: Icons.verified_rounded,
                          gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Main Content
              if (controller.busy && controller.exams.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ))
              else if (controller.exams.isEmpty)
                 _EmptyState(controller: controller)
              else
                AppAnimatedSlide(
                  delayIndex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: AppRadii.r24,
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadii.r24,
                      child: _ExamsTable(
                        exams: filteredExams,
                        controller: controller,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ExamsTable extends StatelessWidget {
  const _ExamsTable({
    required this.exams,
    required this.controller,
  });

  final List<Exam> exams;
  final ExamController controller;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Text('No exams matched your search.', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHighest.withValues(alpha: 0.3)),
        dataRowMaxHeight: 64,
        dataRowMinHeight: 64,
        horizontalMargin: 24,
        columnSpacing: 24,
        columns: [
          DataColumn(label: Text('Exam Name', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
          DataColumn(label: Text('Class', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
          DataColumn(label: Text('Type', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
          DataColumn(label: Text('Timeline', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
          DataColumn(label: Text('Status', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
          DataColumn(label: Text('Actions', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
        ],
        rows: exams.map((e) {
          final df = DateFormat('MMM d, yyyy');

          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    if (e.description.isNotEmpty)
                      Text(e.description, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(e.className ?? 'Unknown', style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ),
              DataCell(Text(e.type, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${df.format(e.startDate)} - ${df.format(e.endDate)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))),
              DataCell(_StatusBadge(status: e.status)),
              DataCell(
                AppActionMenu(
                  actions: [
                    AppActionItem(
                      label: 'Manage & Details',
                      icon: Icons.visibility_rounded,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ExamDetailsView(exam: e, controller: controller),
                        ));
                      },
                    ),
                    AppActionItem(
                      label: 'Edit Exam',
                      icon: Icons.edit_rounded,
                      type: AppActionType.edit,
                      onTap: () {
                         showDialog(
                           context: context,
                           builder: (_) => AddEditExamDialog(controller: controller, exam: e),
                         );
                      },
                    ),
                    AppActionItem(
                      label: 'Delete',
                      icon: Icons.delete_rounded,
                      type: AppActionType.delete,
                      onTap: () async {
                        final confirm = await AppDialogs.showConfirm(
                          context,
                          title: 'Delete Exam?',
                          message: 'Are you sure you want to delete ${e.name}? This will delete all schedules, marks, and results associated with it.',
                          confirmLabel: 'Delete',
                          cancelLabel: 'Cancel',
                          isDanger: true,
                        );
                        if (confirm == true) {
                           AppDialogs.showLoading(context, message: 'Deleting...');
                           final success = await controller.deleteExam(e.id);
                           if (!context.mounted) return;
                           AppDialogs.hide(context);
                           if (success) {
                             AppDialogs.showInfo(context, title: 'Success', message: 'Exam deleted.');
                           } else {
                             AppDialogs.showError(context, title: 'Error', message: controller.error ?? 'Deletion failed.');
                           }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final Map<String, MaterialColor> colors = {
      'upcoming': Colors.blue,
      'active': Colors.orange,
      'completed': Colors.purple,
      'published': Colors.green,
    };

    final color = colors[status.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50.withValues(alpha: 0.5),
        border: Border.all(color: color.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});
  final ExamController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppAnimatedSlide(
      delayIndex: 2,
      child: Container(
        padding: const EdgeInsets.all(48),
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r24,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_add, size: 64, color: cs.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text('No Exams Created', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Start evaluating students by creating an exam schedule.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            AppPrimaryButton(
              onPressed: () {
                 showDialog(
                   context: context,
                   builder: (_) => AddEditExamDialog(controller: controller),
                 );
              },
              label: 'Create First Exam',
            ),
          ],
        ),
      ),
    );
  }
}
