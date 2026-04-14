import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/hover_scale.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:educore/src/features/settings/widgets/plan_editor_dialog.dart';
import 'package:flutter/material.dart';

class PlansSettingsPanel extends StatelessWidget {
  const PlansSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
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
                    'Subscription plans',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pricing and feature tiers for institutes.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            HoverScale(
              child: AppPrimaryButton(
                label: 'Add plan',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final created = await PlanEditorDialog.show(context);
                  if (created == null) return;
                  controller.addPlan(created);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Plan added: ${created.name}')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final columns = switch (size) {
              ScreenSize.compact => 1,
              ScreenSize.medium => 2,
              ScreenSize.expanded => 3,
            };

            const gap = 12.0;
            final totalGap = gap * (columns - 1);
            final cardWidth = (constraints.maxWidth - totalGap) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final plan in controller.plans)
                  SizedBox(
                    width: cardWidth,
                    child: _PlanCard(
                      plan: plan,
                      onEdit: () async {
                        final updated = await PlanEditorDialog.show(
                          context,
                          initial: plan,
                        );
                        if (updated == null) return;
                        controller.updatePlan(updated);
                      },
                      onDelete: () => _confirmDelete(context, plan, controller),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  SubscriptionPlan plan,
  SettingsController controller,
) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete plan?'),
        content: Text(
          'This removes "${plan.name}" from the plan list.',
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
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (ok != true) return;
  controller.deletePlan(plan.id);
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  final SubscriptionPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = switch (plan.id.toLowerCase()) {
      'basic' => cs.primary,
      'standard' => cs.secondary,
      'premium' => cs.tertiary,
      _ => cs.primary,
    };

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${plan.durationDays} days • PKR ${_fmtInt(plan.pricePkr)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _Menu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Features',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final f in plan.features.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (plan.features.length > 6)
            Text(
              '+${plan.features.length - 6} more',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: _MenuRow(icon: Icons.edit_rounded, label: 'Edit'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            danger: true,
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          color: cs.surface,
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? const Color(0xFFB91C1C) : cs.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _fmtInt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - 1 - i;
    b.write(s[idx]);
    if ((i + 1) % 3 == 0 && idx != 0) b.write(',');
  }
  return b.toString().split('').reversed.join();
}
