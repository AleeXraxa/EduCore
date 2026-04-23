import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/features/monthly_tests/controllers/monthly_test_controller.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/widgets/add_edit_test_dialog.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';
import 'package:educore/src/features/monthly_tests/widgets/add_edit_question_dialog.dart';
import 'package:educore/src/features/monthly_tests/utils/mcq_import_service.dart';
import 'package:educore/src/features/monthly_tests/utils/test_pdf_generator.dart';
import 'package:educore/src/features/monthly_tests/views/marks_entry_view.dart';
import 'package:educore/src/features/monthly_tests/views/test_results_view.dart';
import 'package:intl/intl.dart';

class MonthlyTestsView extends StatefulWidget {
  const MonthlyTestsView({super.key});

  @override
  State<MonthlyTestsView> createState() => _MonthlyTestsViewState();
}

class _MonthlyTestsViewState extends State<MonthlyTestsView> {
  late final MonthlyTestController _controller;
  String _searchQuery = '';
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _controller = MonthlyTestController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<MonthlyTestController>(
      controller: _controller,
      builder: (context, controller, _) {
        final cs = Theme.of(context).colorScheme;

        // Filter
        final filteredTests = controller.tests.where((t) {
          final matchesSearch = _searchQuery.isEmpty || 
                 t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 t.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (t.className?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          
          final matchesClass = _selectedClassId == null || t.classId == _selectedClassId;
          
          return matchesSearch && matchesClass;
        }).toList();

        final kpiTests = _selectedClassId == null ? controller.tests : controller.tests.where((t) => t.classId == _selectedClassId).toList();
        final totalTests = kpiTests.length;
        final upcomingTests = kpiTests.where((t) => t.status == 'upcoming').length;
        final completedTests = kpiTests.where((t) => t.status == 'completed' || t.status == 'published').length;
        final pendingMarks = kpiTests.where((t) => t.status == 'active').length;


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
                            'Monthly Tests & Assessments',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage quizzes, monthly tests, MCQ question banks and results.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: AppRadii.r12,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClassId,
                          hint: const Text('All Classes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Classes')),
                            ...controller.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setState(() => _selectedClassId = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppSearchField(
                      width: 280,
                      hintText: 'Search test, subject or class...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(width: 16),
                    AppPrimaryButton(
                      onPressed: () {
                         showDialog(
                           context: context,
                           builder: (_) => AddEditTestDialog(controller: controller),
                         );
                      },
                      icon: Icons.add_rounded,
                      label: 'Create Test',
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
                          label: 'Total Tests',
                          value: totalTests.toString(),
                          icon: Icons.quiz_rounded,
                          gradient: [cs.primary, cs.primary.withValues(alpha: 0.5)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        data: KpiCardData(
                          label: 'Upcoming',
                          value: upcomingTests.toString(),
                          icon: Icons.event_note_rounded,
                          gradient: const [Color(0xFFF59E0B), Color(0xFFFCD34D)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        data: KpiCardData(
                          label: 'Completed',
                          value: completedTests.toString(),
                          icon: Icons.task_alt_rounded,
                          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        data: KpiCardData(
                          label: 'Pending Marks',
                          value: pendingMarks.toString(),
                          icon: Icons.pending_actions_rounded,
                          gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Main Table
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
                    child: _TestsTable(
                      tests: filteredTests,
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

class _TestsTable extends StatelessWidget {
  const _TestsTable({
    required this.tests,
    required this.controller,
  });

  final List<MonthlyTest> tests;
  final MonthlyTestController controller;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(64.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No tests found. Create your first test to get started.', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final df = DateFormat('MMM d, yyyy');

    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('TEST NAME', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
              Expanded(flex: 2, child: Text('SUBJECT', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
              Expanded(flex: 2, child: Text('CLASS', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
              Expanded(flex: 2, child: Text('DATE', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
              Expanded(flex: 1, child: Text('MARKS', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
              Expanded(flex: 2, child: Text('STATUS', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
              const SizedBox(width: 48, child: Text('')), // For Action Menu
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tests.length,
          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
          itemBuilder: (context, index) {
            final t = tests[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        if (t.description.isNotEmpty)
                          Text(t.description, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(t.className ?? 'N/A', style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text(df.format(t.testDate), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
                  Expanded(flex: 1, child: Text('${t.totalMarks.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Row(children: [_StatusBadge(status: t.status)])),
                  SizedBox(
                    width: 48,
                    child: AppActionMenu(
                      actions: [
                        AppActionItem(
                          label: 'Manage Questions',
                          icon: Icons.library_add_rounded,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => _ManageQuestionsDialog(test: t, controller: controller),
                            );
                          },
                        ),
                        AppActionItem(
                          label: 'Enter Marks',
                          icon: Icons.edit_note_rounded,
                          isEnabled: t.status != 'upcoming',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
                                child: MarksEntryView(test: t, controller: controller),
                              ),
                            );
                          },
                        ),
                        AppActionItem(
                          label: 'View Results',
                          icon: Icons.bar_chart_rounded,
                          isEnabled: t.status == 'completed' || t.status == 'published',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
                                child: TestResultsView(test: t, controller: controller),
                              ),
                            );
                          },
                        ),
                        AppActionItem(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          type: AppActionType.edit,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddEditTestDialog(controller: controller, test: t),
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
                              title: 'Delete Test?',
                              message: 'Are you sure you want to delete ${t.title}? This will also delete all questions, marks, and results.',
                              confirmLabel: 'Delete',
                              isDanger: true,
                            );
                            if (confirm == true) {
                               if (!context.mounted) return;
                               AppDialogs.showLoading(context, message: 'Deleting...');
                               await controller.deleteTest(t.id);
                               if (context.mounted) AppDialogs.hide(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
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

class _ManageQuestionsDialog extends StatefulWidget {
  const _ManageQuestionsDialog({required this.test, required this.controller});
  final MonthlyTest test;
  final MonthlyTestController controller;

  @override
  State<_ManageQuestionsDialog> createState() => _ManageQuestionsDialogState();
}

class _ManageQuestionsDialogState extends State<_ManageQuestionsDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller.selectTest(widget.test);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(48),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: Container(
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
                    Text('Manage Question Bank', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${widget.test.title} (${widget.test.subject})', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => TestPdfGenerator.printQuestionPaper(widget.test, widget.controller.currentQuestions),
                  icon: const Icon(Icons.print_rounded),
                  tooltip: 'Print Question Paper',
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _importDialog,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Bulk Import'),
                ),
                const SizedBox(width: 16),
                AppPrimaryButton(
                  onPressed: () {
                     showDialog(
                       context: context,
                       builder: (_) => AddEditQuestionDialog(controller: widget.controller, testId: widget.test.id),
                     );
                  },
                  icon: Icons.add_rounded,
                  label: 'Add Question',
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
            
            // Content
            Expanded(
              child: ControllerBuilder<MonthlyTestController>(
                controller: widget.controller,
                builder: (context, controller, _) {
                  final questions = controller.currentQuestions;

                  if (questions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64, color: cs.primary.withValues(alpha: 0.1)),
                          const SizedBox(height: 24),
                          Text('No Questions Yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('Start building your question bank for this assessment.', style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return AppAnimatedSlide(
                        delayIndex: index,
                        child: _QuestionCard(question: q, index: index + 1, controller: controller),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importDialog() async {
    final confirm = await AppDialogs.showConfirm(
      context, 
      title: 'Import MCQs?', 
      message: 'Select a CSV file to import multiple MCQs at once.'
    );

    if (confirm == true) {
      try {
        final questions = await McqImportService.pickAndParseCsv(widget.test.id);
        if (questions == null) return;

        if (!mounted) return;
        AppDialogs.showLoading(context, message: 'Importing...');
        final success = await widget.controller.importQuestions(questions);
        
        if (mounted) {
          AppDialogs.hide(context);
          if (success) {
            AppDialogs.showInfo(context, title: 'Success', message: '${questions.length} questions imported.');
          }
        }
      } catch (e) {
        if (mounted) AppDialogs.showError(context, title: 'Import Failed', message: '$e');
      }
    }
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.index, required this.controller});
  final TestQuestion question;
  final int index;
  final MonthlyTestController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                child: Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(question.questionText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
              Text('${question.marks} Marks', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 11)),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddEditQuestionDialog(
                      controller: controller,
                      testId: question.testId,
                      question: question,
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                color: cs.primary,
              ),
              IconButton(
                onPressed: () async {
                   final confirm = await AppDialogs.showConfirm(context, title: 'Delete?', message: 'Remove this question?', isDanger: true);
                   if (confirm == true) await controller.deleteQuestion(question);
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: cs.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _OptionBadge(label: 'A', text: question.optionA, isCorrect: question.correctOption == 'A'),
              _OptionBadge(label: 'B', text: question.optionB, isCorrect: question.correctOption == 'B'),
              _OptionBadge(label: 'C', text: question.optionC, isCorrect: question.correctOption == 'C'),
              _OptionBadge(label: 'D', text: question.optionD, isCorrect: question.correctOption == 'D'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionBadge extends StatelessWidget {
  const _OptionBadge({required this.label, required this.text, required this.isCorrect});
  final String label;
  final String text;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.1) : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCorrect ? const Color(0xFF10B981) : cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label. ', style: TextStyle(fontWeight: FontWeight.w900, color: isCorrect ? const Color(0xFF059669) : cs.onSurfaceVariant, fontSize: 11)),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
