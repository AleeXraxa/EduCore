import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/features/features_controller.dart';
import 'package:educore/src/features/features/widgets/feature_editor_dialog.dart';
import 'package:educore/src/features/features/widgets/feature_group_nav.dart';
import 'package:educore/src/features/features/widgets/feature_list.dart';
import 'package:educore/src/features/features/widgets/bulk_import_features_dialog.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/features/widgets/feature_group_management_dialog.dart';
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

            final header = AppAnimatedSlide(
              delayIndex: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Control system-wide feature access and plan capabilities.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            );

            final actions = AppAnimatedSlide(
              delayIndex: 1,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppSearchField(
                    width: compact ? double.infinity : 320,
                    controller: _search,
                    onChanged: controller.setFeatureQuery,
                    hintText: 'Search features…',
                  ),
                  // Operational Buttons
                  AppPrimaryButton(
                    variant: AppButtonVariant.secondary,
                    onPressed: controller.busy
                        ? null
                        : () => FeatureGroupManagementDialog.show(
                              context,
                              controller: controller,
                            ),
                    icon: Icons.folder_copy_rounded,
                    label: 'Manage groups',
                  ),
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
                              if (!context.mounted) return;
                              AppDialogs.showLoading(
                                context,
                                message: 'Importing features...',
                              );
                                await controller.createFeaturesBulk(created);
                                if (!context.mounted) return;
                                AppDialogs.hide(context);

                                if (controller.hasError) {
                                  AppDialogs.showError(
                                    context,
                                    title: 'Import Failed',
                                    message: controller.error!,
                                  );
                                  return;
                                }

                                AppDialogs.showSuccess(
                                  context,
                                  title: 'Import Successful',
                                  message:
                                      'Synchronized ${created.length} new operational features to the platform catalog.',
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
                    icon: Icons.upload_file_rounded,
                    label: 'Bulk import',
                  ),
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
                              if (!context.mounted) return;
                              AppDialogs.showLoading(
                                context,
                                message: 'Adding feature...',
                              );
                                await controller.createFeature(created);
                                if (!context.mounted) return;
                                AppDialogs.hide(context);

                                if (controller.hasError) {
                                  AppDialogs.showError(
                                    context,
                                    title: 'Deployment Failed',
                                    message: controller.error!,
                                  );
                                  return;
                                }

                                AppDialogs.showSuccess(
                                  context,
                                  title: 'Feature Deployed',
                                  message:
                                      'The feature "${created.label}" is now active in the system catalog.',
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                AppDialogs.hide(context);
                                AppDialogs.showError(
                                  context,
                                  title: 'Deployment Failed',
                                  message: e.toString(),
                                );
                              }
                          },
                    busy: controller.busy,
                    icon: Icons.add_rounded,
                    label: 'Add Feature',
                  ),
                ],
              ),
            );

            final list = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAnimatedSlide(
                  delayIndex: 1,
                  child: AppKpiGrid(columns: kpiCols, items: kpis),
                ),
                const SizedBox(height: 24),
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
                AppAnimatedSlide(
                  delayIndex: 2,
                  child: FeatureList(
                    items: controller.filtered,
                    onAction: (action) =>
                        _handleRowAction(context, controller, action),
                    onToggle: (payload) =>
                        controller.setActive(payload.$1, payload.$2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: cs.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TIP: Keep keys stable to avoid breaking plan assignments.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 24),
                  actions,
                  const SizedBox(height: 24),
                  if (compact) ...[
                    list,
                    const SizedBox(height: 16),
                    AppAnimatedSlide(
                      delayIndex: 3,
                      child: SizedBox(height: 420, child: nav),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAnimatedSlide(
                          delayIndex: 2,
                          child: SizedBox(width: 260, height: 620, child: nav),
                        ),
                        const SizedBox(width: 24),
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
      (f) => f.id == action.featureId,
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
          if (!context.mounted) return;
          AppDialogs.showLoading(context, message: 'Updating feature...');
          await controller.updateFeature(updated);
          if (!context.mounted) return;
          AppDialogs.hide(context);

          if (controller.hasError) {
            AppDialogs.showError(
              context,
              title: 'Update Failed',
              message: controller.error!,
            );
            return;
          }

          AppDialogs.showSuccess(
            context,
            title: 'Update Successful',
            message:
                'Internal configuration for "${updated.label}" has been synchronized across the platform.',
          );
        } catch (e) {
          if (!context.mounted) return;
          AppDialogs.hide(context);
          AppDialogs.showError(
            context,
            title: 'Update Failed',
            message: e.toString(),
          );
        }
        break;
      case FeatureMenuAction.toggle:
        try {
          await controller.toggleFeatureStatus(feature.id, !feature.isActive);
        } catch (e) {
          if (!context.mounted) return;
          AppDialogs.showError(
            context,
            title: 'Action Failed',
            message: e.toString(),
          );
        }
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
      case FeatureMenuAction.delete:
        final confirmed = await _showDeleteConfirmation(context, feature);
        if (confirmed) {
          try {
            if (!context.mounted) return;
            AppDialogs.showLoading(context, message: 'Deleting feature...');
            await controller.deleteFeature(feature.id);
            if (!context.mounted) return;
            AppDialogs.hide(context);

            if (controller.hasError) {
              AppDialogs.showError(
                context,
                title: 'Deletion Failed',
                message: controller.error!,
              );
              return;
            }

            AppDialogs.showSuccess(
              context,
              title: 'Feature Removed',
              message:
                  'The feature has been soft-deleted and removed from all plans.',
            );
          } catch (e) {
            if (!context.mounted) return;
            AppDialogs.hide(context);
            AppDialogs.showError(
              context,
              title: 'Deletion Failed',
              message: e.toString(),
            );
          }
        }
        break;
    }
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    FeatureFlag feature,
  ) async {
    final cs = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete Platform Feature?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete "${feature.label}"?',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.3),
                    borderRadius: AppRadii.r12,
                    border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: cs.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'This is a soft-delete. The feature will be hidden from all plans and the dashboard, but auditing history is preserved.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              AppPrimaryButton(
                onPressed: () => Navigator.pop(context, true),
                label: 'Confirm Delete',
                color: cs.error,
              ),
            ],
          ),
        ) ??
        false;
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
