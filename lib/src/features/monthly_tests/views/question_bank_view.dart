import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/features/monthly_tests/controllers/monthly_test_controller.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';
import 'package:educore/src/features/monthly_tests/widgets/add_edit_question_dialog.dart';
import 'package:educore/src/features/monthly_tests/utils/mcq_import_service.dart';
import 'package:educore/src/features/monthly_tests/utils/test_pdf_generator.dart';

class QuestionBankView extends StatefulWidget {
  const QuestionBankView({super.key, required this.test, required this.controller});
  final MonthlyTest test;
  final MonthlyTestController controller;

  @override
  State<QuestionBankView> createState() => _QuestionBankViewState();
}

class _QuestionBankViewState extends State<QuestionBankView> {
  String? _selectedSubjectId;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    widget.controller.selectTest(widget.test);
    if (widget.test.subjects.isNotEmpty) {
      _selectedSubjectId = widget.test.subjects.first.id;
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedQuestions() async {
    final count = _selectedIds.length;
    final confirm = await AppDialogs.showConfirm(
      context, 
      title: 'Delete $count Questions?', 
      message: 'This action cannot be undone.',
      isDanger: true,
    );

    if (confirm == true) {
      final questionsToDelete = widget.controller.currentQuestions
          .where((q) => _selectedIds.contains(q.id))
          .toList();

      final success = await widget.controller.deleteQuestions(questionsToDelete);
      if (success) {
        setState(() => _selectedIds.clear());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.test.title} - Questions'),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            Text('(${_selectedIds.length} Selected)', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () => setState(() => _selectedIds.clear()),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            AppPrimaryButton(
              onPressed: _deleteSelectedQuestions,
              icon: Icons.delete_sweep_rounded,
              label: 'Delete',
              color: cs.error,
            ),
          ] else ...[
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
            const SizedBox(width: 8),
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
          ],
          const SizedBox(width: 32),
        ],
      ),
      body: ControllerBuilder<MonthlyTestController>(
        controller: widget.controller,
        builder: (context, controller, _) {
          final allQuestions = controller.currentQuestions;
          final questions = _selectedSubjectId == null 
              ? allQuestions 
              : allQuestions.where((q) => q.subjectId == _selectedSubjectId).toList();

          return Column(
            children: [
              if (widget.test.subjects.length > 1 || questions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    children: [
                      if (widget.test.subjects.length > 1)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.test.subjects.map((sub) {
                                final isSelected = _selectedSubjectId == sub.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ChoiceChip(
                                    label: Text(sub.name),
                                    selected: isSelected,
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedSubjectId = sub.id);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      else 
                        const Spacer(),
                      
                      if (questions.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            final allSelected = questions.every((q) => _selectedIds.contains(q.id));
                            setState(() {
                              if (allSelected) {
                                for (var q in questions) _selectedIds.remove(q.id);
                              } else {
                                for (var q in questions) _selectedIds.add(q.id);
                              }
                            });
                          },
                          icon: Icon(questions.every((q) => _selectedIds.contains(q.id)) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded),
                          label: Text(questions.every((q) => _selectedIds.contains(q.id)) ? 'Deselect All' : 'Select All'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: questions.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64, color: cs.primary.withValues(alpha: 0.1)),
                          const SizedBox(height: 24),
                          Text('No Questions Yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('Start building your question bank for this subject.', style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(32),
                      itemCount: questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return AppAnimatedSlide(
                          delayIndex: index,
                          child: _QuestionCard(
                            question: q, 
                            index: index + 1, 
                            controller: controller,
                            isSelected: _selectedIds.contains(q.id),
                            onSelect: () => _toggleSelection(q.id),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importDialog() async {
    final confirm = await AppDialogs.showConfirm(
      context, 
      title: 'Import MCQs?', 
      message: 'This will import a set of sample MCQs for this test. In the production version, you can upload your own CSV/Excel file.'
    );

    if (confirm == true) {
      try {
        final questions = await McqImportService.pickAndParseCsv(
          widget.test.id, 
          _selectedSubjectId ?? '',
          availableSubjects: widget.test.subjects,
        );
        if (questions == null) return; // User cancelled

        if (!mounted) return;
        AppDialogs.showLoading(context, message: 'Importing Questions...');
        final success = await widget.controller.importQuestions(questions);
        
        if (mounted) {
          AppDialogs.hide(context);
          if (success) {
            AppDialogs.showInfo(context, title: 'Success', message: '${questions.length} questions imported successfully.');
          } else {
            AppDialogs.showError(context, title: 'Import Failed', message: widget.controller.error ?? 'Unknown error');
          }
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showError(context, title: 'Error', message: 'Failed to parse CSV: $e');
        }
      }
    }
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question, 
    required this.index, 
    required this.controller,
    required this.isSelected,
    required this.onSelect,
  });
  
  final TestQuestion question;
  final int index;
  final MonthlyTestController controller;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onSelect,
      borderRadius: AppRadii.r20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.05) : cs.surface,
          borderRadius: AppRadii.r20,
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected, 
                  onChanged: (_) => onSelect(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${question.marks} Marks', style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () async {
                     final confirm = await AppDialogs.showConfirm(context, title: 'Delete Question?', message: 'Are you sure?', isDanger: true);
                     if (confirm == true) {
                       await controller.deleteQuestion(question);
                     }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: cs.error,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _OptionItem(label: 'A', text: question.optionA, isCorrect: question.correctOption == 'A'),
                  _OptionItem(label: 'B', text: question.optionB, isCorrect: question.correctOption == 'B'),
                  _OptionItem(label: 'C', text: question.optionC, isCorrect: question.correctOption == 'C'),
                  _OptionItem(label: 'D', text: question.optionD, isCorrect: question.correctOption == 'D'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  const _OptionItem({required this.label, required this.text, required this.isCorrect});
  final String label;
  final String text;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.1) : cs.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: AppRadii.r12,
        border: Border.all(color: isCorrect ? const Color(0xFF10B981) : cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text('$label.', style: TextStyle(fontWeight: FontWeight.w900, color: isCorrect ? const Color(0xFF059669) : cs.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal))),
          if (isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
        ],
      ),
    );
  }
}
