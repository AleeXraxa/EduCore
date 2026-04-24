import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class LoginMarketingPanel extends StatelessWidget {
  const LoginMarketingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo_v4.png',
              width: 260,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Institution Portal',
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smart Institution Management System',
            style: textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Manage Your Institution, The Smart Way',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 18),
          const _FeatureGrid(
            items: [
              _Feature(
                icon: Icons.school_rounded,
                title: 'Manage Students & Admissions Easily',
              ),
              _Feature(
                icon: Icons.receipt_long_rounded,
                title: 'Automated Fee & Receipt System',
              ),
              _Feature(
                icon: Icons.fact_check_rounded,
                title: 'Real-time Attendance & Reports',
              ),
              _Feature(
                icon: Icons.trending_up_rounded,
                title: 'Smart Finance & Profit Tracking',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TrustRow(),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trusted by Modern Schools & Institutes',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Badge(label: 'Secure', tint: cs.primary),
            _Badge(label: 'Fast', tint: cs.secondary),
            _Badge(
              label: 'Designed for modern institutions',
              tint: cs.tertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items});

  final List<_Feature> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          SizedBox(width: 300, child: _FeatureTile(item: item)),
      ],
    );
  }
}

class _Feature {
  const _Feature({required this.icon, required this.title});
  final IconData icon;
  final String title;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});

  final _Feature item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        boxShadow: AppShadows.soft(Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
