import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/features/overrides_controller.dart';
import 'package:flutter/material.dart';

class FeatureOverridesView extends StatefulWidget {
  const FeatureOverridesView({super.key});

  @override
  State<FeatureOverridesView> createState() => _FeatureOverridesViewState();
}

class _FeatureOverridesViewState extends State<FeatureOverridesView> {
  final _controller = FeatureOverridesController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder(
      controller: _controller,
      builder: (context, controller, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(controller: controller),
                const SizedBox(height: 32),
                if (controller.selectedAcademy == null)
                  const _SelectInstitutePlaceholder()
                else if (controller.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(child: _OverridesList(controller: controller)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final FeatureOverridesController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feature Overrides',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Customize feature access for specific institutes independently of their plan.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              AppDropdown<Academy>(
                label: 'Select Institute',
                prefixIcon: Icons.business_rounded,
                items: controller.academies,
                value: controller.selectedAcademy,
                itemLabel: (a) => a.name,
                onChanged: controller.selectAcademy,
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              if (controller.selectedAcademy != null)
                AppPrimaryButton(
                  label: 'Save Changes',
                  icon: Icons.save_rounded,
                  busy: controller.isSaving,
                  onPressed: controller.saveChanges,
                  height: 56,
                  color: Colors.green.shade700,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverridesList extends StatelessWidget {
  final FeatureOverridesController controller;
  const _OverridesList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final allFeatures = controller.allFeatures;
    
    // Split features into Assigned and Remaining
    final assignedFeatures = <FeatureFlag>[];
    final remainingFeatures = <FeatureFlag>[];

    for (final f in allFeatures) {
      final inPlan = controller.isFeatureInPlan(f.key);
      final isForcedEnabled = controller.overrides.isEnabled(f.key);
      final isForcedDisabled = controller.overrides.isDisabled(f.key);

      // Effective state determine if assigned
      bool effective;
      if (isForcedDisabled) {
        effective = false;
      } else if (isForcedEnabled) {
        effective = true;
      } else {
        effective = inPlan;
      }

      if (effective) {
        assignedFeatures.add(f);
      } else {
        remainingFeatures.add(f);
      }
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (assignedFeatures.isNotEmpty) ...[
          _SectionHeader(
            title: 'Assigned Features',
            count: assignedFeatures.length,
            color: Colors.green,
          ),
          _FeatureGrid(features: assignedFeatures, controller: controller),
          const SizedBox(height: 40),
        ],
        if (remainingFeatures.isNotEmpty) ...[
          _SectionHeader(
            title: 'Available Features',
            count: remainingFeatures.length,
            color: Colors.blueGrey,
          ),
          _FeatureGrid(features: remainingFeatures, controller: controller),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Divider(color: color.withValues(alpha: 0.1))),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<FeatureFlag> features;
  final FeatureOverridesController controller;

  const _FeatureGrid({required this.features, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 100,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        return _FeatureCard(
          feature: features[i],
          controller: controller,
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureFlag feature;
  final FeatureOverridesController controller;

  const _FeatureCard({required this.feature, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inPlan = controller.isFeatureInPlan(feature.key);
    final isForcedEnabled = controller.overrides.isEnabled(feature.key);
    final isForcedDisabled = controller.overrides.isDisabled(feature.key);
    final isOverridden = isForcedEnabled || isForcedDisabled;

    // effective state
    bool effective;
    if (isForcedDisabled) {
      effective = false;
    } else if (isForcedEnabled) {
      effective = true;
    } else {
      effective = inPlan;
    }

    return Card(
      elevation: isOverridden ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverridden
              ? (isForcedEnabled ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5))
              : cs.outlineVariant,
          width: isOverridden ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          feature.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isOverridden)
                        _Badge(
                          label: 'Overridden',
                          color: isForcedEnabled ? Colors.green : Colors.red,
                        )
                      else if (inPlan)
                        const _Badge(label: 'From Plan', color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _ToggleSwitch(
              value: isForcedDisabled ? false : (isForcedEnabled ? true : null),
              onChanged: (val) => controller.toggleFeature(feature.key, val),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool? value; // null = default/plan, true = enabled, false = disabled
  final ValueChanged<bool?> onChanged;

  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (value == null) {
              onChanged(true);
            } else if (value == true) {
              onChanged(false);
            } else {
              onChanged(null);
            }
          },
          child: Container(
            width: 80,
            height: 36,
            decoration: BoxDecoration(
              color: value == null
                  ? cs.surfaceContainerHighest
                  : (value == true ? Colors.green.shade700 : Colors.red.shade700),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: value == null ? 22 : (value == true ? 44 : 4),
                  top: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      value == null
                          ? Icons.remove_rounded
                          : (value == true ? Icons.check_rounded : Icons.close_rounded),
                      size: 16,
                      color: value == null
                          ? cs.onSurfaceVariant
                          : (value == true ? Colors.green.shade700 : Colors.red.shade700),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: value == true ? 0 : 28,
                        right: value == false ? 0 : 28,
                      ),
                      child: Text(
                        value == null ? 'PLAN' : (value == true ? 'ON' : 'OFF'),
                        style: TextStyle(
                          color: value == null ? cs.onSurfaceVariant : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectInstitutePlaceholder extends StatelessWidget {
  const _SelectInstitutePlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune_rounded, size: 80, color: cs.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text(
              'Select an Institute',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an academy from the dropdown above\nto manage its feature overrides.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
