import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class PlanFeaturesPanel extends StatelessWidget {
  const PlanFeaturesPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accessSvc = AppServices.instance.featureAccessService;
    final featureSvc = AppServices.instance.featureService;

    if (accessSvc == null || featureSvc == null) {
      return const Center(child: Text('Service Unavailable'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan & Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Overview of your currently active subscription features.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 32),
        StreamBuilder<List<FeatureFlag>>(
          stream: featureSvc.watchFeatures(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No features found in registry.');
            }

            final allowedKeys = accessSvc.getAllowedFeatures();
            final allFeatures = snapshot.data!;
            
            final allowedFeatures = allFeatures
                .where((f) => allowedKeys.contains(f.key))
                .toList();
            
            final blockedFeatures = allFeatures
                .where((f) => !allowedKeys.contains(f.key))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _FeatureSection(
                  title: 'Included in your Plan',
                  features: allowedFeatures,
                  isAllowed: true,
                ),
                if (blockedFeatures.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  _FeatureSection(
                    title: 'Locked Features',
                    subtitle: 'Upgrade your plan to unlock these capabilities.',
                    features: blockedFeatures,
                    isAllowed: false,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({
    required this.title,
    this.subtitle,
    required this.features,
    required this.isAllowed,
  });

  final String title;
  final String? subtitle;
  final List<FeatureFlag> features;
  final bool isAllowed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isAllowed ? null : cs.onSurfaceVariant,
                  ),
            ),
            if (isAllowed) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 104,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final f = features[index];
            return _FeatureCard(feature: f, isAllowed: isAllowed);
          },
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.isAllowed});
  final FeatureFlag feature;
  final bool isAllowed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(
          color: isAllowed 
              ? cs.outlineVariant.withValues(alpha: 0.6)
              : cs.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: isAllowed ? [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAllowed 
                  ? cs.primary.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAllowed ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              color: isAllowed ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  feature.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isAllowed ? null : cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
