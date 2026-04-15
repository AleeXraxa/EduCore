import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/features/features_controller.dart';
import 'package:educore/src/features/features/widgets/feature_editor_dialog.dart';
import 'package:educore/src/features/features/widgets/feature_group_nav.dart';
import 'package:educore/src/features/features/widgets/feature_list.dart';
import 'package:educore/src/features/features/widgets/bulk_import_features_dialog.dart';
import 'package:flutter/material.dart';

class FeaturesView extends StatefulWidget {
  const FeaturesView({super.key});

  @override
  State<FeaturesView> createState() => _FeaturesViewState();
}

class _FeaturesViewState extends State<FeaturesView> {
  late final FeaturesController _controller;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = FeaturesController();
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder<FeaturesController>(
      controller: _controller,
      builder: (context, controller, _) {
        if (!controller.ready) {
          return _NotReadyPanel(
            busy: controller.busy,
            message: controller.errorMessage,
            onRetry: controller.retryInit,
          );
        }

        final kpis = [
          KpiCardData(
            label: 'Total Features',
            value: _fmtInt(controller.totalCount),
            icon: Icons.tune_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF4F46E5)],
          ),
          KpiCardData(
            label: 'Active Features',
            value: _fmtInt(controller.activeCount),
            icon: Icons.check_circle_rounded,
            gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
          ),
          KpiCardData(
            label: 'Groups',
            value: _fmtInt(controller.groups.length - 1),
            icon: Icons.folder_rounded,
            gradient: const [Color(0xFF7C3AED), Color(0xFF6366F1)],
          ),
          KpiCardData(
            label: 'Search Results',
            value: _fmtInt(controller.filtered.length),
            icon: Icons.search_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final compact = size == ScreenSize.compact;
            final kpiCols = switch (size) {
              ScreenSize.compact => 1,
              ScreenSize.medium => 2,
              ScreenSize.expanded => 4,
            };

            final nav = FeatureGroupNav(
              groups: controller.groups,
              selected: controller.selectedGroup,
              onSelect: controller.setGroup,
              onSearch: controller.setGroupQuery,
            );

            final list = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Feature Management',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Control system-wide feature access and plan capabilities.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: compact ? 220 : 320,
                      child: TextField(
                        controller: _search,
                        onChanged: controller.setFeatureQuery,
                        decoration: InputDecoration(
                          hintText: 'Search features',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: cs.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadii.r12,
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadii.r12,
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppPrimaryButton(
                      variant: AppButtonVariant.secondary,
                      onPressed: controller.busy
                          ? null
                          : () async {
                              final created = await BulkImportFeaturesDialog.show(
                                context,
                                groups: controller.groups,
                              );
                              if (created == null || created.isEmpty) return;
                              try {
                                await controller.createFeaturesBulk(created);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Imported ${created.length} features.'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            },
                      icon: Icons.upload_file_rounded,
                      label: 'Bulk import',
                    ),
                    const SizedBox(width: 12),
                    AppPrimaryButton(
                      onPressed: controller.busy
                          ? null
                          : () async {
                              final groups = controller.groups;
                              final created = await FeatureEditorDialog.show(
                                context,
                                groups: groups,
                              );
                              if (created == null) return;
                              try {
                                await controller.createFeature(created);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Feature created: ${created.label}',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            },
                      busy: controller.busy,
                      icon: Icons.add_rounded,
                      label: 'Add feature',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _KpiGrid(columns: kpiCols, items: kpis),
                const SizedBox(height: 16),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controller.errorMessage!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                FeatureList(
                  items: controller.filtered,
                  onAction: (action) =>
                      _handleRowAction(context, controller, action),
                  onToggle: (payload) =>
                      controller.setActive(payload.$1, payload.$2),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tip: Keep keys stable to avoid breaking plan assignments.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact) ...[
                    list,
                    const SizedBox(height: 16),
                    SizedBox(height: 420, child: nav),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 260, height: 620, child: nav),
                        const SizedBox(width: 16),
                        Expanded(child: list),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleRowAction(
    BuildContext context,
    FeaturesController controller,
    FeatureRowAction action,
  ) async {
    final feature = controller.features.firstWhere(
      (e) => e.id == action.featureId,
    );
    switch (action.action) {
      case FeatureMenuAction.edit:
        final updated = await FeatureEditorDialog.show(
          context,
          initial: feature,
          groups: controller.groups,
        );
        if (updated == null) return;
        try {
          await controller.updateFeature(updated);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Feature updated: ${updated.label}')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
        break;
      case FeatureMenuAction.toggle:
        await controller.setActive(feature.id, !feature.isActive);
        break;
      case FeatureMenuAction.move:
        final updated = await FeatureEditorDialog.show(
          context,
          initial: feature,
          groups: controller.groups,
        );
        if (updated == null) return;
        await controller.updateFeature(updated);
        break;
    }
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.columns, required this.items});

  final int columns;
  final List<KpiCardData> items;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: KpiCard(data: item),
              ),
          ],
        );
      },
    );
  }
}

class _NotReadyPanel extends StatelessWidget {
  const _NotReadyPanel({
    this.busy = false,
    this.message,
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant),
          boxShadow: AppShadows.soft(Colors.black),
        ),
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
                        : 'Features require Firebase Firestore. Initialize Firebase to enable this module.',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtInt(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - i;
    buf.write(s[i]);
    if (idx > 1 && idx % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
