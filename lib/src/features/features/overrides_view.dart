import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/features/overrides_controller.dart';
import 'package:flutter/material.dart';

class FeatureOverridesView extends StatefulWidget {
  const FeatureOverridesView({super.key});

  @override
  State<FeatureOverridesView> createState() => _FeatureOverridesViewState();
}

class _FeatureOverridesViewState extends State<FeatureOverridesView> {
  late final FeatureOverridesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FeatureOverridesController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<FeatureOverridesController>(
      controller: _controller,
      builder: (context, controller, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAnimatedSlide(
                delayIndex: 0,
                child: _Header(controller: controller),
              ),
              const SizedBox(height: 32),
              if (controller.selectedAcademy == null)
                const AppAnimatedSlide(
                  delayIndex: 1,
                  child: _SelectInstitutePlaceholder(),
                )
              else if (controller.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                AppAnimatedSlide(
                  delayIndex: 1,
                  child: _OverridesList(controller: controller),
                ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feature Overrides',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Customize feature access for specific institutes independently of their plan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: AppDropdown<Academy>(
            label: 'Target Institute',
            prefixIcon: Icons.business_rounded,
            items: controller.academies,
            value: controller.selectedAcademy,
            itemLabel: (a) => a.name,
            onChanged: controller.selectAcademy,
          ),
        ),
        if (controller.selectedAcademy != null) ...[
          const SizedBox(width: 16),
          AppPrimaryButton(
            label: 'Save Changes',
            icon: Icons.save_rounded,
            busy: controller.isSaving,
            onPressed: controller.saveChanges,
          ),
        ],
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

    final assignedFeatures = <FeatureFlag>[];
    final remainingFeatures = <FeatureFlag>[];

    for (final f in allFeatures) {
      final inPlan = controller.isFeatureInPlan(f.key);
      final isForcedEnabled = controller.overrides.isEnabled(f.key);
      final isForcedDisabled = controller.overrides.isDisabled(f.key);

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

    return Column(
      children: [
        if (assignedFeatures.isNotEmpty) ...[
          _SectionHeader(
            title: 'Assigned Features',
            count: assignedFeatures.length,
            color: Colors.green,
          ),
          _FeatureGrid(features: assignedFeatures, controller: controller),
          const SizedBox(height: 48),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2.0,
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
        maxCrossAxisExtent: 450,
        mainAxisExtent: 130,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        return _FeatureCard(feature: features[i], controller: controller);
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

    final color = isOverridden
        ? (isForcedEnabled ? Colors.green : Colors.red)
        : cs.primary;

    return AppCard(
      padding: const EdgeInsets.all(20.0),
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
                          letterSpacing: -0.5,
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
                      const _Badge(label: 'On Plan', color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  feature.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ToggleSwitch(
            value: isForcedDisabled ? false : (isForcedEnabled ? true : null),
            onChanged: (val) => controller.toggleFeature(feature.key, val),
          ),
        ],
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
          letterSpacing: 0.5,
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

    return GestureDetector(
      onTap: () {
        if (value == null) {
          onChanged(true);
        } else if (value == true) {
          onChanged(false);
        } else {
          onChanged(null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        height: 38,
        decoration: BoxDecoration(
          color: value == null
              ? cs.surfaceContainerHighest
              : (value == true ? Colors.green.shade700 : Colors.red.shade700),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: value == null ? 24 : (value == true ? 46 : 4),
              top: 4,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  value == null
                      ? Icons.remove_rounded
                      : (value == true
                            ? Icons.check_rounded
                            : Icons.close_rounded),
                  size: 16,
                  color: value == null
                      ? cs.onSurfaceVariant
                      : (value == true
                            ? Colors.green.shade700
                            : Colors.red.shade700),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: value == true ? 0 : 32,
                    right: value == false ? 0 : 32,
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
    );
  }
}

class _SelectInstitutePlaceholder extends StatelessWidget {
  const _SelectInstitutePlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 64,
              color: cs.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Target Institute Selection',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an academy from the dropdown above\nto manage its feature overrides independently.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
