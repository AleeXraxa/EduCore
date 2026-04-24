import 'package:educore/src/core/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/exams/controllers/exam_controller.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';

class ResultsView extends StatefulWidget {
  const ResultsView({super.key, required this.controller, required this.exam});

  final ExamController controller;
  final Exam exam;

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = widget.controller.currentResults;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Results & Rankings',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (widget.exam.status != 'published')
                if (AppServices.instance.featureAccessService!.canAccess(
                  'result_publish',
                ))
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          AppDialogs.showLoading(
                            context,
                            message: 'Calculating results...',
                          );
                          final success = await widget.controller
                              .generateResults(widget.exam);
                          if (context.mounted) {
                            AppDialogs.hide(context);
                            if (success) {
                              AppDialogs.showInfo(
                                context,
                                title: 'Success',
                                message:
                                    'Results generated. Please review before publishing.',
                              );
                            } else {
                              AppDialogs.showError(
                                context,
                                title: 'Notice',
                                message:
                                    widget.controller.error ??
                                    'Failed to generate.',
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.calculate_rounded),
                        label: const Text('Generate Results'),
                      ),
                      const SizedBox(width: 16),
                      AppPrimaryButton(
                        onPressed: () async {
                          if (results.isEmpty) {
                            AppDialogs.showError(
                              context,
                              title: 'Missing Results',
                              message:
                                  'Generate results first before publishing.',
                            );
                            return;
                          }
                          final confirm = await AppDialogs.showConfirm(
                            context,
                            title: 'Publish Results?',
                            message:
                                'Once published, marks cannot be edited. Students and parents will be notified.',
                            confirmLabel: 'Publish',
                          );
                          if (confirm == true) {
                            AppDialogs.showLoading(
                              context,
                              message: 'Publishing...',
                            );
                            final success = await widget.controller
                                .togglePublishResult(widget.exam, true);
                            if (context.mounted) {
                              AppDialogs.hide(context);
                              if (success) {
                                AppDialogs.showInfo(
                                  context,
                                  title: 'Success',
                                  message: 'Exam published successfully.',
                                );
                              } else {
                                AppDialogs.showError(
                                  context,
                                  title: 'Error',
                                  message:
                                      widget.controller.error ??
                                      'Failed to publish.',
                                );
                              }
                            }
                          }
                        },
                        label: 'Publish Exam',
                        icon: Icons.campaign_rounded,
                      ),
                    ],
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
          else if (results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: cs.primary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No results compiled yet.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ensure all marks are entered, then click "Generate Results".',
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
                    sortColumnIndex: 6,
                    sortAscending: true,
                    headingRowColor: WidgetStatePropertyAll(
                      cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Rank',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Student Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total Marks',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Obtained',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Percentage',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Grade',
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
                    rows: results.map((r) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (r.rank != null && r.rank! <= 3)
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${r.rank ?? '-'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              r.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          DataCell(Text('${r.totalMaxMarks}')),
                          DataCell(Text('${r.totalObtained}')),
                          DataCell(Text('${r.percentage.toStringAsFixed(1)}%')),
                          DataCell(
                            Text(
                              r.grade,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              r.status.toUpperCase(),
                              style: TextStyle(
                                color: r.status.toLowerCase() == 'pass'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
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
