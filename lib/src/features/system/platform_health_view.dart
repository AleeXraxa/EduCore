import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:flutter/material.dart';

class PlatformHealthView extends StatelessWidget {
  const PlatformHealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = screenSizeForWidth(constraints.maxWidth);
        final horizontalPadding = screen == ScreenSize.compact ? 16.0 : 32.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppAnimatedSlide(
                child: _HealthHeader(),
              ),
              const SizedBox(height: 32),
              AppAnimatedSlide(
                delayIndex: 1,
                child: _HealthKpiSection(screen: screen),
              ),
              const SizedBox(height: 32),
              AppAnimatedSlide(
                delayIndex: 2,
                child: _ServiceHealthGrid(screen: screen),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ALL SYSTEMS OPERATIONAL',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Platform Health',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time monitoring of Firebase quotas, service status, and API performance.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _HealthKpiSection extends StatelessWidget {
  const _HealthKpiSection({required this.screen});
  final ScreenSize screen;

  @override
  Widget build(BuildContext context) {
    final columns = switch (screen) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 4,
    };
    final kpis = [
      const KpiCardData(
        label: 'Firestore Reads',
        value: '14.2K',
        trendText: '12% of daily',
        trendUp: true,
        icon: Icons.storage_rounded,
        gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      ),
      const KpiCardData(
        label: 'Firestore Writes',
        value: '2.8K',
        trendText: '4% of daily',
        trendUp: true,
        icon: Icons.edit_document,
        gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
      const KpiCardData(
        label: 'Avg. Auth Latency',
        value: '184ms',
        trendText: 'Optimal',
        trendUp: true,
        icon: Icons.speed_rounded,
        gradient: [Color(0xFF10B981), Color(0xFF059669)],
      ),
      const KpiCardData(
        label: 'Active Sessions',
        value: '1,242',
        trendText: '+18%',
        trendUp: true,
        icon: Icons.bolt_rounded,
        gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
    ];

    return AppKpiGrid(columns: columns, items: kpis);
  }
}

class _ServiceHealthGrid extends StatelessWidget {
  const _ServiceHealthGrid({required this.screen});
  final ScreenSize screen;

  @override
  Widget build(BuildContext context) {
    final columns = screen == ScreenSize.compact ? 1 : 2;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: screen == ScreenSize.compact ? 1.5 : 2.2,
      children: const [
        _QuotaCard(
          title: 'Firestore Requests',
          usage: 0.12,
          metric: '14,242 / 100,000 (Daily)',
          icon: Icons.cloud_done_rounded,
        ),
        _QuotaCard(
          title: 'Cloud Functions',
          usage: 0.45,
          metric: '45,200 / 100,000 (Monthly)',
          icon: Icons.functions_rounded,
          color: Colors.amber,
        ),
        _QuotaCard(
          title: 'App Check Verification',
          usage: 0.02,
          metric: '2,100 / 10,000 (Daily)',
          icon: Icons.shield_rounded,
        ),
        _QuotaCard(
          title: 'Media Storage',
          usage: 0.68,
          metric: '3.4GB / 5.0GB (Total)',
          icon: Icons.folder_shared_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({
    required this.title,
    required this.usage,
    required this.metric,
    required this.icon,
    this.color,
  });

  final String title;
  final double usage;
  final String metric;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeColor = color ?? cs.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              Text(
                '${(usage * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: usage > 0.8 ? Colors.red : themeColor,
                    ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 8,
              backgroundColor: themeColor.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(themeColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            metric,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
