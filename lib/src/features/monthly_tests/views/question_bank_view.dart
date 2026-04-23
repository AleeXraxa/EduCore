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

  @override
  void initState() {
    super.initState();
    widget.controller.selectTest(widget.test);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.test.title} - Questions'),
        actions: [
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
          const SizedBox(width: 32),
        ],
      ),
      body: ControllerBuilder<MonthlyTestController>(
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
            padding: const EdgeInsets.all(32),
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
        final questions = await McqImportService.pickAndParseCsv(widget.test.id);
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
  const _QuestionCard({required this.question, required this.index, required this.controller});
  final TestQuestion question;
  final int index;
  final MonthlyTestController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
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
          GridView.count(
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
        ],
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
