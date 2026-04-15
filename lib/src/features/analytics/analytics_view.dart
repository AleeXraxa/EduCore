import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/analytics/analytics_controller.dart';
import 'package:educore/src/features/analytics/widgets/analytics_charts_section.dart';
import 'package:educore/src/features/analytics/widgets/analytics_insights_section.dart';
import 'package:educore/src/features/analytics/widgets/analytics_kpis_section.dart';
import 'package:flutter/material.dart';

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
        final snap = controller.snapshot;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topLeft,
              fit: StackFit.expand,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: SingleChildScrollView(
            key: ValueKey('${controller.range}_${controller.plan}'),
            padding: const EdgeInsets.all(24),
            child: Column(
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
                            'Analytics',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Executive overview of revenue, growth, and platform health.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
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
                const SizedBox(height: 20),
                AnalyticsKpisSection(snapshot: snap),
                const SizedBox(height: 24),
                AnalyticsChartsSection(snapshot: snap),
                const SizedBox(height: 24),
                AnalyticsInsightsSection(snapshot: snap),
                if (controller.busy) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Refreshing…',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
