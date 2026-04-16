import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/features/plans/plans_controller.dart';
import 'package:educore/src/features/plans/widgets/feature_toggle_dialog.dart';
import 'package:educore/src/features/plans/widgets/plan_editor_dialog.dart';
import 'package:educore/src/features/plans/widgets/plan_status_badge.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

class PlansView extends StatefulWidget {
  const PlansView({super.key});

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  late final PlansController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlansController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder<PlansController>(
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
            label: 'Total Plans',
            value: _fmtInt(controller.totalPlans),
            icon: Icons.layers_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF4F46E5)],
          ),
          KpiCardData(
            label: 'Active Plans',
            value: _fmtInt(controller.activePlans),
            icon: Icons.verified_rounded,
            gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
          ),
          KpiCardData(
            label: 'Feature Keys',
            value: _fmtInt(controller.allFeatureKeys.length),
            icon: Icons.toggle_on_rounded,
            gradient: const [Color(0xFF7C3AED), Color(0xFF6366F1)],
          ),
          KpiCardData(
            label: 'Most Used Plan',
            value: '-',
            icon: Icons.auto_awesome_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final kpiCols = switch (size) {
              ScreenSize.compact => 1,
              ScreenSize.medium => 2,
              ScreenSize.expanded => 4,
            };
            final gridCols = switch (size) {
              ScreenSize.compact => 1,
              ScreenSize.medium => 2,
              ScreenSize.expanded => 3,
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAnimatedSlide(
                    delayIndex: 0,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plans',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Create and manage subscription plans and feature access.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        AppPrimaryButton(
                          label: 'Create plan',
                          icon: Icons.add_rounded,
                          busy: controller.busy,
                          onPressed: () async {
                            final created = await PlanEditorDialog.show(
                              context,
                              availableFeatures: controller.registryFeatures,
                            );
                            if (created == null) return;
                            try {
                              AppDialogs.showLoading(context, message: 'Creating plan...');
                              await controller.createPlan(created);
                              if (!context.mounted) return;
                              AppDialogs.hide(context);
                              AppDialogs.showSuccess(
                                context,
                                title: 'Plan Created',
                                message: 'The plan "${created.name}" is now available for institutes.',
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              AppDialogs.hide(context);
                              AppDialogs.showError(
                                context,
                                title: 'Failed to Create Plan',
                                message: e.toString(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    child: _PlansGrid(
                      columns: gridCols,
                      items: controller.plans,
                      busy: controller.busy,
                      onEdit: (plan) async {
                        final updated = await PlanEditorDialog.show(
                          context,
                          initial: plan,
                          availableFeatures: controller.registryFeatures,
                        );
                        if (updated == null) return;
                        try {
                          AppDialogs.showLoading(context, message: 'Updating plan...');
                          await controller.updatePlan(updated);
                          if (!context.mounted) return;
                          AppDialogs.hide(context);
                          AppDialogs.showSuccess(
                            context,
                            title: 'Plan Updated',
                            message: 'Changes to "${updated.name}" have been saved successfully.',
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
                      },
                      onFeatures: (plan) => FeatureToggleDialog.show(
                        context,
                        plan: plan,
                        availableKeys: controller.allFeatureKeys,
                        onToggle: (key, enabled) =>
                            controller.toggleFeature(plan.id, key, enabled),
                      ),
                      onToggleActive: (plan) =>
                          controller.setActive(plan.id, !plan.isActive),
                      onArchive: (plan) => _confirmArchive(context, plan, controller),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppAnimatedSlide(
                    delayIndex: 3,
                    child: Row(
                      children: [
                        Icon(Icons.tips_and_updates_rounded, color: cs.primary, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'TIP: Start with a Demo plan to let institutes explore EduCore before committing to a paid subscription.',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _confirmArchive(
  BuildContext context,
  Plan plan,
  PlansController controller,
) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive plan?'),
        content: Text(
          'This will deactivate "${plan.name}". You can re-activate it later.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
            ),
            child: const Text('Archive'),
          ),
        ],
      );
    },
  );

  if (ok != true) return;
  await controller.softDelete(plan.id);
}

class _PlansGrid extends StatelessWidget {
  const _PlansGrid({
    required this.columns,
    required this.items,
    required this.busy,
    required this.onEdit,
    required this.onFeatures,
    required this.onToggleActive,
    required this.onArchive,
  });

  final int columns;
  final List<Plan> items;
  final bool busy;
  final ValueChanged<Plan> onEdit;
  final ValueChanged<Plan> onFeatures;
  final ValueChanged<Plan> onToggleActive;
  final ValueChanged<Plan> onArchive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'No plans yet',
        description: 'Create your first plan to define pricing and feature access.',
        icon: Icons.layers_rounded,
      );
    }

    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final plan in items)
              SizedBox(
                width: cardWidth,
                child: _PlanCard(
                  plan: plan,
                  busy: busy,
                  onEdit: () => onEdit(plan),
                  onFeatures: () => onFeatures(plan),
                  onToggleActive: () => onToggleActive(plan),
                  onArchive: () => onArchive(plan),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.busy,
    required this.onEdit,
    required this.onFeatures,
    required this.onToggleActive,
    required this.onArchive,
  });

  final Plan plan;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onFeatures;
  final VoidCallback onToggleActive;
  final VoidCallback onArchive;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plan = widget.plan;

    final enabledKeys = plan.features.toList(growable: false)..sort();

    final limitEntries = plan.limits.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant),
          boxShadow: AppShadows.soft(
            Colors.black.withValues(alpha: _hovered ? 0.12 : 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: 0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PKR ${_fmtMoney(plan.price)} / month',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  PlanStatusBadge(active: plan.isActive),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'Actions',
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          widget.onEdit();
                          break;
                        case 'features':
                          widget.onFeatures();
                          break;
                        case 'toggle':
                          widget.onToggleActive();
                          break;
                        case 'archive':
                          widget.onArchive();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit plan'),
                      ),
                      const PopupMenuItem(
                        value: 'features',
                        child: Text('Toggle features'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(plan.isActive ? 'Deactivate' : 'Activate'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive (soft delete)'),
                      ),
                    ],
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (plan.description.trim().isNotEmpty)
                Text(
                  plan.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'No description',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                'Features',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (enabledKeys.isEmpty)
                Text(
                  'No enabled features yet.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in enabledKeys.take(10))
                      _FeatureChip(label: _prettyKey(key)),
                    if (enabledKeys.length > 10)
                      _FeatureChip(label: '+${enabledKeys.length - 10} more'),
                  ],
                ),
              const SizedBox(height: 14),
              Text(
                'Limits',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (limitEntries.isEmpty)
                Text(
                  'No limits set.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Column(
                  children: [
                    for (final e in limitEntries.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LimitRow(
                          label: _prettyKey(e.key),
                          value: e.value,
                        ),
                      ),
                    if (limitEntries.length > 4)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '+${limitEntries.length - 4} more',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.busy ? null : widget.onFeatures,
                      icon: const Icon(Icons.tune_rounded),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      label: const Text('Features'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.busy ? null : widget.onEdit,
                      icon: const Icon(Icons.edit_rounded),
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
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.label, required this.value});
  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.26),
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
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
                    busy ? 'Initializing Firebase…' : 'Firestore not ready',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.trim().isNotEmpty == true
                        ? message!.trim()
                        : 'Plans require Firebase Firestore. Initialize Firebase to enable this module.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      await onRetry();
                    },
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

String _fmtMoney(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - i;
    buf.write(s[i]);
    if (idx > 1 && idx % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

String _prettyKey(String k) {
  if (k.isEmpty) return k;
  final parts = k.split('_');
  final buf = StringBuffer();
  for (final p in parts) {
    if (p.isEmpty) continue;
    buf.write(p[0].toUpperCase());
    buf.write(p.substring(1).toLowerCase());
    buf.write(' ');
  }
  return buf.toString().trim();
}
