import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/analytics/analytics_controller.dart';
import 'package:educore/src/features/analytics/widgets/analytics_charts_section.dart';
import 'package:educore/src/features/analytics/widgets/analytics_insights_section.dart';
import 'package:educore/src/features/analytics/widgets/analytics_kpis_section.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/access_denied_view.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  late final AnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnalyticsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const toolbarHeight = 48.0;

    return ControllerBuilder<AnalyticsController>(
      controller: _controller,
      builder: (context, controller, _) {
        final featureSvc = AppServices.instance.featureAccessService;
        if (featureSvc == null || !featureSvc.canAccess('analytics_view')) {
          return const AccessDeniedView(featureName: 'System Analytics');
        }

        final snap = controller.snapshot;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAnimatedSlide(
                delayIndex: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Executive overview of revenue, growth, and platform health.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      height: toolbarHeight,
                      child: AppDropdown<AnalyticsRange>(
                        label: 'Range',
                        showLabel: false,
                        compact: true,
                        prefixIcon: Icons.date_range_rounded,
                        items: const [
                          AnalyticsRange.last7,
                          AnalyticsRange.last30,
                          AnalyticsRange.last3Months,
                          AnalyticsRange.last12Months,
                        ],
                        value: controller.range,
                        hintText: 'Date range',
                        itemLabel: (r) => switch (r) {
                          AnalyticsRange.last7 => 'Last 7 days',
                          AnalyticsRange.last30 => 'Last 30 days',
                          AnalyticsRange.last3Months => 'Last 3 months',
                          AnalyticsRange.last12Months => 'Last 12 months',
                        },
                        onChanged: (value) {
                          if (value == null) return;
                          controller.setRange(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      height: toolbarHeight,
                      child: AppDropdown<String?>(
                        label: 'Plan',
                        showLabel: false,
                        compact: true,
                        prefixIcon: Icons.workspace_premium_rounded,
                        items: controller.planOptions,
                        value: controller.plan,
                        hintText: 'Plan',
                        itemLabel: (p) => p ?? 'All plans',
                        onChanged: (value) {
                          controller.setPlan(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppAnimatedSlide(
                delayIndex: 1,
                child: AnalyticsKpisSection(snapshot: snap),
              ),
              const SizedBox(height: 24),
              AppAnimatedSlide(
                delayIndex: 2,
                child: AnalyticsChartsSection(snapshot: snap),
              ),
              const SizedBox(height: 24),
              AppAnimatedSlide(
                delayIndex: 3,
                child: AnalyticsInsightsSection(snapshot: snap),
              ),
              if (controller.busy) ...[
                const SizedBox(height: 24),
                AppAnimatedSlide(
                  delayIndex: 4,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Refreshing analytics engine…',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
