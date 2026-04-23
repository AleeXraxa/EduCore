import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/features/monthly_tests/controllers/monthly_test_controller.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_result.dart';
import 'package:educore/src/features/monthly_tests/utils/test_pdf_generator.dart';

class TestResultsView extends StatefulWidget {
  const TestResultsView({
    super.key,
    required this.test,
    required this.controller,
  });
  final MonthlyTest test;
  final MonthlyTestController controller;

  @override
  State<TestResultsView> createState() => _TestResultsViewState();
}

class _TestResultsViewState extends State<TestResultsView> {
  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    await widget.controller.loadResults(widget.test.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 1200,
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
                    'Test Results & Analytics',
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
              IconButton(
                onPressed: () => TestPdfGenerator.printResultSheet(
                  widget.test,
                  widget.controller.currentResults,
                ),
                icon: const Icon(Icons.print_rounded),
                tooltip: 'Print Result Sheet',
              ),
              const SizedBox(width: 8),
              AppPrimaryButton(
                onPressed: () async {
                  AppDialogs.showLoading(
                    context,
                    message: 'Generating Results...',
                  );
                  await widget.controller.generateResults(widget.test);
                  if (mounted) AppDialogs.hide(context);
                },
                icon: Icons.auto_graph_rounded,
                label: 'Re-generate',
                color: cs.secondary,
              ),
              const SizedBox(width: 12),
              ControllerBuilder<MonthlyTestController>(
                controller: widget.controller,
                builder: (context, controller, _) {
                  final isPublished = widget.test.status == 'published';
                  return AppPrimaryButton(
                    onPressed: () async {
                      final confirm = await AppDialogs.showConfirm(
                        context,
                        title: isPublished ? 'Unpublish?' : 'Publish?',
                        message: isPublished
                            ? 'Results will be hidden.'
                            : 'Results will be visible to students.',
                      );
                      if (confirm == true)
                        await controller.togglePublishResult(
                          widget.test,
                          !isPublished,
                        );
                    },
                    icon: isPublished
                        ? Icons.visibility_off_rounded
                        : Icons.publish_rounded,
                    label: isPublished ? 'Unpublish' : 'Publish',
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Content
          Expanded(
            child: ControllerBuilder<MonthlyTestController>(
              controller: widget.controller,
              builder: (context, controller, _) {
                if (controller.busy && controller.currentResults.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = controller.currentResults;

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: cs.primary.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Results Generated',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppPrimaryButton(
                          onPressed: () =>
                              controller.generateResults(widget.test),
                          label: 'Generate Now',
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    _ResultStatsHeader(results: results),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                          borderRadius: AppRadii.r16,
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadii.r16,
                          child: _ResultsTable(results: results),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStatsHeader extends StatelessWidget {
  const _ResultStatsHeader({required this.results});
  final List<TestResult> results;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final passCount = results.where((r) => r.status == 'Pass').length;
    final passPercentage = (passCount / results.length * 100).toStringAsFixed(
      1,
    );
    final avgMarks =
        results.map((r) => r.obtainedMarks).reduce((a, b) => a + b) /
        results.length;

    return Container(
      padding: const EdgeInsets.all(24),
      color: cs.primaryContainer.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total Appeared',
            value: '${results.length}',
            icon: Icons.people_rounded,
          ),
          _StatItem(
            label: 'Pass Percentage',
            value: '$passPercentage%',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          ),
          _StatItem(
            label: 'Avg. Marks',
            value: avgMarks.toStringAsFixed(1),
            icon: Icons.functions_rounded,
          ),
          _StatItem(
            label: 'Top Score',
            value: results.first.obtainedMarks.toStringAsFixed(1),
            icon: Icons.emoji_events_rounded,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? cs.primary).withValues(alpha: 0.1),
            borderRadius: AppRadii.r12,
          ),
          child: Icon(icon, color: color ?? cs.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.results});
  final List<TestResult> results;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'RANK',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'STUDENT NAME',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'ROLL NO',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'MARKS',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'PERCENTAGE',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'GRADE',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'STATUS',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Rows
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: results.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, thickness: 0.5),
            itemBuilder: (context, index) {
              final r = results[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: r.rank == 1
                              ? Colors.amber
                              : (r.rank == 2
                                    ? Colors.grey.shade400
                                    : (r.rank == 3
                                          ? Colors.brown.shade400
                                          : cs.surfaceContainer)),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${r.rank}',
                          style: TextStyle(
                            color: r.rank <= 3 ? Colors.white : cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(flex: 2, child: Text(r.studentRollNo)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r.obtainedMarks.toInt()} / ${r.totalMarks.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('${r.percentage.toStringAsFixed(1)}%'),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        r.grade,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _getGradeColor(r.grade),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: r.status == 'Pass'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: r.status == 'Pass'
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              r.status.toUpperCase(),
                              style: TextStyle(
                                color: r.status == 'Pass'
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    return Colors.red;
  }
}
