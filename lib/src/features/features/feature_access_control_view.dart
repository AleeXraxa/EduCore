import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/features/feature_access_control_controller.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class FeatureAccessControlView extends StatefulWidget {
  const FeatureAccessControlView({super.key});

  @override
  State<FeatureAccessControlView> createState() =>
      _FeatureAccessControlViewState();
}

class _FeatureAccessControlViewState extends State<FeatureAccessControlView> {
  late final FeatureAccessControlController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FeatureAccessControlController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<FeatureAccessControlController>(
      controller: _controller,
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(controller: controller),
                const SizedBox(height: 24),
                _InstituteSelector(controller: controller),
                const SizedBox(height: 24),
                if (controller.selectedInstitute != null) ...[
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Plan Info & Groups
                        SizedBox(
                          width: 320,
                          child: Column(
                            children: [
                              _PlanInfoCard(controller: controller),
                              const SizedBox(height: 16),
                              _StatisticsCard(controller: controller),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right: Feature List
                        Expanded(child: _FeaturesList(controller: controller)),
                      ],
                    ),
                  ),
                ] else
                  const Expanded(child: Center(child: _EmptySelectionState())),
              ],
            ),
          ),
          bottomNavigationBar: controller.selectedInstitute != null
              ? _ActionBar(controller: controller)
              : null,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final FeatureAccessControlController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Access Control',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage custom feature overrides per institute',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        const Spacer(),
        if (controller.busy)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _InstituteSelector extends StatelessWidget {
  const _InstituteSelector({required this.controller});
  final FeatureAccessControlController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.business_rounded, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: CustomDropdown<Institute>.search(
              hintText: 'Search and select an institute...',
              items: controller.institutes,
              initialItem: controller.selectedInstitute,
              onChanged: (value) {
                if (value != null) controller.selectInstitute(value);
              },
              headerBuilder: (context, selectedItem, enabled) {
                return Text(
                  selectedItem.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item.id,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  selected: isSelected,
                  onTap: onItemSelect,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanInfoCard extends StatelessWidget {
  const _PlanInfoCard({required this.controller});
  final FeatureAccessControlController controller;

  @override
  Widget build(BuildContext context) {
    final plan = controller.plan;
    if (plan == null) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadii.r8,
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Plan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const Divider(height: 32),
          _InfoRow(
            label: 'Base Features',
            value: '${plan.features.length} enabled',
          ),
        ],
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.controller});
  final FeatureAccessControlController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Override Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: 'Force Enabled',
            value: controller.draftEnabled.length.toString(),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Force Disabled',
            value: controller.draftDisabled.length.toString(),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Total Effective',
            value: controller.allFeatures
                .where((f) => controller.isEffectiveEnabled(f.key))
                .length
                .toString(),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  const _FeaturesList({required this.controller});
  final FeatureAccessControlController controller;

  @override
  Widget build(BuildContext context) {
    final groups = controller.groupedFeatures;

    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final groupName = groups.keys.elementAt(index);
        final features = groups[groupName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                groupName.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: features
                    .map((f) => _FeatureRow(feature: f, controller: controller))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.controller});
  final FeatureFlag feature;
  final FeatureAccessControlController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.getFeatureState(feature.key);
    final isEnabled = controller.isEffectiveEnabled(feature.key);

    Color badgeColor;
    String badgeText;
    bool showReset = false;

    switch (state) {
      case FeatureAccessState.overrideEnabled:
        badgeColor = Colors.green;
        badgeText = 'Override Enabled';
        showReset = true;
      case FeatureAccessState.overrideDisabled:
        badgeColor = Colors.red;
        badgeText = 'Override Disabled';
        showReset = true;
      case FeatureAccessState.planControlled:
        badgeColor = AppColors.textMuted.withValues(alpha: 0.5);
        badgeText = 'From Plan';
        showReset = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      feature.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Badge(label: badgeText, color: badgeColor),
                  ],
                ),
                Text(
                  feature.description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (showReset)
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
              tooltip: 'Reset to Plan Default',
              onPressed: () => controller.resetToPlan(feature.key),
            ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: isEnabled,
            activeTrackColor: state == FeatureAccessState.overrideEnabled
                ? Colors.green
                : null,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: (val) => controller.toggleFeature(feature.key),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});
  final FeatureAccessControlController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: controller.resetAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset All to Plan Defaults'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Discard',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                controller.selectInstitute(controller.selectedInstitute!),
          ),
          const SizedBox(width: 12),
          AppPrimaryButton(
            label: 'Save Access Rules',
            busy: controller.isSaving,
            onPressed: () async {
              final ok = await controller.saveChanges();
              if (context.mounted) {
                if (ok) {
                  AppDialogs.showSuccess(
                    context,
                    title: 'Access Updated',
                    message:
                        'Feature access rules for ${controller.selectedInstitute!.name} have been updated successfully.',
                  );
                } else {
                  AppDialogs.showError(
                    context,
                    title: 'Update Failed',
                    message:
                        'Could not update feature overrides. Please check your connection.',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _EmptySelectionState extends StatelessWidget {
  const _EmptySelectionState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.shield_rounded,
          size: 64,
          color: AppColors.textMuted.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select an Institute to manage access',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
