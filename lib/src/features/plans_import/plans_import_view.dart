import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/features/plans_import/models/plan_import_models.dart';
import 'package:educore/src/features/plans_import/plans_import_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlansImportView extends StatefulWidget {
  const PlansImportView({super.key});

  @override
  State<PlansImportView> createState() => _PlansImportViewState();
}

class _PlansImportViewState extends State<PlansImportView> {
  late final PlansImportController _controller;
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = PlansImportController();
    _inputController.text = _jsonTemplate;
    _controller.setInput(_jsonTemplate);
    _inputController.addListener(() {
      _controller.setInput(_inputController.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder<PlansImportController>(
      controller: _controller,
      builder: (context, controller, _) {
        if (!controller.ready) {
          return _NotReadyPanel(
            busy: controller.busy,
            message: controller.errorMessage,
            onRetry: controller.retryInit,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Import Manager',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bulk create or update plans from JSON or CSV.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth >= 1080;
                  return Flex(
                    direction: twoCol ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: twoCol ? 6 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InputCard(
                              source: controller.source,
                              inputController: _inputController,
                              busy: controller.busy,
                              onSourceChanged: (value) {
                                controller.setSource(value);
                                final template = value == PlanImportSource.json
                                    ? _jsonTemplate
                                    : _csvTemplate;
                                _inputController.text = template;
                                controller.setInput(template);
                              },
                              onPreview: controller.preview,
                              onCopyTemplate: () async {
                                final template = controller.source == PlanImportSource.json
                                    ? _jsonTemplate
                                    : _csvTemplate;
                                await Clipboard.setData(ClipboardData(text: template));
                                if (!context.mounted) return;
                                AppDialogs.showSuccess(
                                  context,
                                  title: 'Template Copied',
                                  message: 'The plan import template has been copied to your clipboard. You can now paste your data into it.',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: twoCol ? 18 : 0, height: twoCol ? 0 : 18),
                      Expanded(
                        flex: twoCol ? 7 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SummaryCard(
                              parse: controller.parseResult,
                              validation: controller.validation,
                              commit: controller.lastCommit,
                            ),
                            const SizedBox(height: 14),
                            _PreviewCard(
                              drafts: controller.parseResult.drafts,
                              validation: controller.validation,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.validation?.canImport == true
                                        ? 'All plans valid. Ready to import.'
                                        : 'Fix validation errors before importing.',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: controller.busy || !controller.canImport
                                      ? null
                                      : () async {
                                          try {
                                            AppDialogs.showLoading(context, message: 'Importing plans...');
                                            await controller.importPlans();
                                            if (!context.mounted) return;
                                            AppDialogs.hide(context);
                                            AppDialogs.showSuccess(
                                              context,
                                              title: 'Import Successful',
                                              message: 'All valid plans have been successfully synchronized to the system catalog.',
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            AppDialogs.hide(context);
                                            AppDialogs.showError(
                                              context,
                                              title: 'Import Failed',
                                              message: e.toString(),
                                            );
                                          }
                                        },
                                  icon: controller.busy
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.cloud_upload_rounded),
                                  label: const Text('Import plans'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.source,
    required this.inputController,
    required this.busy,
    required this.onSourceChanged,
    required this.onPreview,
    required this.onCopyTemplate,
  });

  final PlanImportSource source;
  final TextEditingController inputController;
  final bool busy;
  final ValueChanged<PlanImportSource> onSourceChanged;
  final Future<void> Function() onPreview;
  final VoidCallback onCopyTemplate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import source',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<PlanImportSource>(
            segments: const [
              ButtonSegment(
                value: PlanImportSource.json,
                label: Text('JSON'),
                icon: Icon(Icons.data_object_rounded),
              ),
              ButtonSegment(
                value: PlanImportSource.csv,
                label: Text('CSV'),
                icon: Icon(Icons.table_chart_rounded),
              ),
            ],
            selected: {source},
            onSelectionChanged: (value) => onSourceChanged(value.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: cs.primary.withValues(alpha: 0.12),
              selectedForegroundColor: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            source == PlanImportSource.json
                ? 'Paste JSON array of plans.'
                : 'Paste CSV with columns: key,name,description,price,features,limits,isActive.',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          AppTextArea(
            controller: inputController,
            label: source == PlanImportSource.json ? 'JSON input' : 'CSV input',
            hintText: source == PlanImportSource.json ? 'Paste JSON here' : 'Paste CSV here',
            minLines: 10,
            maxLines: 16,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCopyTemplate,
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy template'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : onPreview,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_rounded),
                label: const Text('Validate & preview'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.parse,
    required this.validation,
    required this.commit,
  });

  final PlanImportParseResult parse;
  final PlanImportValidationResult? validation;
  final PlanImportCommitResult? commit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final errors = [
      ...parse.errors,
      ...?validation?.errors,
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validation summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Total plans',
            value: parse.drafts.length,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Invalid features',
            value: validation?.invalidFeaturesCount ?? 0,
            danger: (validation?.invalidFeaturesCount ?? 0) > 0,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Errors',
            value: errors.length,
            danger: errors.isNotEmpty,
          ),
          if (commit != null) ...[
            const SizedBox(height: 12),
            Text(
              'Imported: ${commit!.created} created, ${commit!.updated} updated',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...errors.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '- $e',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.drafts,
    required this.validation,
  });

  final List<PlanImportDraft> drafts;
  final PlanImportValidationResult? validation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final invalidByPlan = validation?.invalidFeaturesByPlan ?? const {};

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          if (drafts.isEmpty)
            Text(
              'No plans parsed yet.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          for (final draft in drafts) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
                borderRadius: AppRadii.r16,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${draft.name} (${draft.key})',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      Text(
                        draft.isActive ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: draft.isActive
                                  ? const Color(0xFF15803D)
                                  : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    draft.description.isEmpty
                        ? 'No description'
                        : draft.description,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Chip(label: 'Price: ${draft.price}', tone: _ChipTone.info),
                      if (draft.limits.isNotEmpty)
                        _Chip(
                          label: 'Limits: ${draft.limits.length}',
                          tone: _ChipTone.neutral,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Features',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final feature in draft.features)
                        _Chip(
                          label: feature,
                          tone: invalidByPlan[draft.key.toLowerCase()]?.contains(
                                    feature.toLowerCase(),
                                  ) ==
                                  true
                              ? _ChipTone.danger
                              : _ChipTone.neutral,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final int value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: danger ? const Color(0xFFB91C1C) : cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

enum _ChipTone { neutral, info, danger }

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      _ChipTone.info => (cs.primary.withValues(alpha: 0.12), cs.primary),
      _ChipTone.danger => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      _ => (cs.surface, cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _NotReadyPanel extends StatelessWidget {
  const _NotReadyPanel({
    required this.busy,
    required this.message,
    required this.onRetry,
  });

  final bool busy;
  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.cloud_off_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    busy ? 'Initializing Firebase...' : 'Firestore not ready',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.trim().isNotEmpty == true
                        ? message!.trim()
                        : 'Plan import requires Firebase Firestore. Initialize Firebase to enable this module.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: busy ? null : () async => onRetry(),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _jsonTemplate = '''
[
  {
    "key": "demo",
    "name": "Demo",
    "description": "Starter demo plan",
    "price": 0,
    "features": ["student_create"],
    "limits": { "maxStudents": 50 },
    "isActive": true
  },
  {
    "key": "basic",
    "name": "Basic",
    "description": "For small institutes",
    "price": 29,
    "features": ["student_create", "fee_collect"],
    "limits": { "maxStudents": 200, "maxStaff": 5 },
    "isActive": true
  }
]
''';

const _csvTemplate =
    'key,name,description,price,features,limits,isActive\n'
    'demo,Demo,Starter demo plan,0,student_create,maxStudents=50,true\n'
    'basic,Basic,For small institutes,29,student_create;fee_collect,maxStudents=200;maxStaff=5,true';
