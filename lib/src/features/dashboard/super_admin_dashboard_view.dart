import 'package:educore/src/app/shell/app_shell.dart';
import 'package:educore/src/app/shell/sidebar_item.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/dashboard/dashboard_controller.dart';
import 'package:educore/src/features/analytics/analytics_view.dart';
import 'package:educore/src/features/features/features_view.dart';
import 'package:educore/src/features/features/overrides_view.dart';
import 'package:educore/src/features/institutes/institutes_view.dart';
import 'package:educore/src/features/notifications/notifications_view.dart';
import 'package:educore/src/features/payments/payments_view.dart';
import 'package:educore/src/features/plans/plans_view.dart';
import 'package:educore/src/features/settings/settings_view.dart';
import 'package:educore/src/features/subscriptions/subscriptions_view.dart';
import 'package:educore/src/features/users/users_view.dart';
import 'package:educore/src/features/audit/audit_logs_view.dart';
import 'package:educore/src/features/system/platform_health_view.dart';
import 'package:flutter/material.dart';

class SuperAdminDashboardView extends StatefulWidget {
  const SuperAdminDashboardView({super.key});

  @override
  State<SuperAdminDashboardView> createState() =>
      _SuperAdminDashboardViewState();
}

class _SuperAdminDashboardViewState extends State<SuperAdminDashboardView> {
  String _selected = _SuperAdminNav.dashboard.id;

  @override
  Widget build(BuildContext context) {
    final current = _SuperAdminNav.byId(_selected);

    return AppShell(
      title: current.title,
      sections: _SuperAdminNav.sections,
      selectedSidebarId: _selected,
      onSelectSidebar: (id) => setState(() => _selected = id),
      body: AnimatedSwitcher(
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
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.01, 0),
            end: Offset.zero,
          ).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<String>(_selected),
          child: switch (current) {
            _SuperAdminNav.dashboard => const _DashboardHomeBody(),
            _SuperAdminNav.institutes => const InstitutesView(),
            _SuperAdminNav.subscriptions => const SubscriptionsView(),
            _SuperAdminNav.payments => const PaymentsView(),
            _SuperAdminNav.analytics => const AnalyticsView(),
            _SuperAdminNav.users => const UsersView(),
            _SuperAdminNav.notifications => const NotificationsView(),
            _SuperAdminNav.features => const FeaturesView(),
            _SuperAdminNav.featureOverrides => const FeatureOverridesView(),
            _SuperAdminNav.plans => const PlansView(),
            _SuperAdminNav.auditLogs => const AuditLogsView(),
            _SuperAdminNav.platformHealth => const PlatformHealthView(),
            _SuperAdminNav.settings => const SettingsView(),
          },
        ),
      ),
    );
  }
}

enum _SuperAdminNav {
  dashboard(
    'dashboard',
    'Dashboard',
    'Super Admin Overview',
    Icons.dashboard_rounded,
  ),
  analytics(
    'analytics',
    'Analytics',
    'Platform Analytics',
    Icons.trending_up_rounded,
    featureKey: 'system_analytics',
  ),

  institutes(
    'institutes',
    'Institutes',
    'Institute Management',
    Icons.apartment_rounded,
    featureKey: 'system_institutes',
  ),
  users(
    'users',
    'Users',
    'User Management',
    Icons.people_alt_rounded,
    featureKey: 'system_users',
  ),
  notifications(
    'notifications',
    'Notifications',
    'Platform Notifications',
    Icons.notifications_active_rounded,
    featureKey: 'system_notifications',
  ),

  subscriptions(
    'subscriptions',
    'Subscriptions',
    'Subscription Management',
    Icons.verified_rounded,
    featureKey: 'system_billing',
  ),
  payments(
    'payments',
    'Payments',
    'Payment Verification',
    Icons.payments_rounded,
    featureKey: 'system_payments',
  ),
  plans(
    'plans',
    'Plans',
    'Subscription Plans',
    Icons.category_rounded,
    featureKey: 'system_plans',
  ),

  features(
    'features',
    'Features',
    'Feature Registry',
    Icons.list_alt_rounded,
    featureKey: 'system_features',
  ),
  featureOverrides(
    'overrides',
    'Overrides',
    'Feature Overrides',
    Icons.tune_rounded,
    featureKey: 'system_overrides',
  ),

  auditLogs(
    'audit_logs',
    'Audit Logs',
    'Activity Logs',
    Icons.receipt_long_rounded,
    featureKey: 'system_audit',
  ),
  platformHealth(
    'health',
    'System Health',
    'Platform Performance',
    Icons.health_and_safety_rounded,
    featureKey: 'system_health',
  ),
  settings(
    'settings',
    'Settings',
    'Platform Settings',
    Icons.settings_rounded,
    featureKey: 'system_settings',
  );

  const _SuperAdminNav(this.id, this.label, this.title, this.icon, {this.featureKey});
  final String id;
  final String label;
  final String title;
  final IconData icon;
  final String? featureKey;

  SidebarItemData toSidebarItem() =>
      SidebarItemData(id: id, label: label, icon: icon, requiredFeature: featureKey);

  static List<SidebarSectionData> get sections => [
    SidebarSectionData(
      title: 'Overview',
      items: [dashboard, analytics].map((e) => e.toSidebarItem()).toList(),
    ),
    SidebarSectionData(
      title: 'Management',
      items: [
        institutes,
        users,
        notifications,
      ].map((e) => e.toSidebarItem()).toList(),
    ),
    SidebarSectionData(
      title: 'Billing',
      items: [
        subscriptions,
        payments,
        plans,
      ].map((e) => e.toSidebarItem()).toList(),
    ),
    SidebarSectionData(
      title: 'Configuration',
      items: [
        features,
        featureOverrides,
      ].map((e) => e.toSidebarItem()).toList(),
    ),
    SidebarSectionData(
      title: 'System',
      items: [auditLogs, settings].map((e) => e.toSidebarItem()).toList(),
    ),
  ];

  static _SuperAdminNav byId(String id) =>
      _SuperAdminNav.values.firstWhere((e) => e.id == id);
}

class _DashboardHomeBody extends StatelessWidget {
  const _DashboardHomeBody();

  @override
  Widget build(BuildContext context) {
    return const _DashboardHomeBodyStateful();
  }
}

class _DashboardHomeBodyStateful extends StatefulWidget {
  const _DashboardHomeBodyStateful();

  @override
  State<_DashboardHomeBodyStateful> createState() =>
      _DashboardHomeBodyStatefulState();
}

class _DashboardHomeBodyStatefulState
    extends State<_DashboardHomeBodyStateful> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<DashboardController>(
      controller: _controller,
      builder: (context, controller, _) {
        if (!controller.ready) {
          return _NotReadyPanel(
            busy: controller.busy,
            message: controller.errorMessage,
            onRetry: controller.retryInit,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final columns = switch (size) {
              ScreenSize.compact => 1,
              ScreenSize.medium => 2,
              ScreenSize.expanded => 4,
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppAnimatedSlide(delayIndex: 0, child: _HeaderRow()),
                  const SizedBox(height: 32),
                  AppAnimatedSlide(
                    delayIndex: 1,
                    child: _KpiGrid(columns: columns, kpis: controller.kpis),
                  ),
                  const SizedBox(height: 48),
                  const AppAnimatedSlide(
                    delayIndex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'FINANCIAL OVERVIEW',
                          subtitle:
                              'Real-time revenue streams and growth metrics.',
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                  AppAnimatedSlide(
                    delayIndex: 3,
                    child: Flex(
                      direction: size == ScreenSize.compact
                          ? Axis.vertical
                          : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _RevenueChart(
                            values: controller.revenueHistory,
                          ),
                        ),
                        SizedBox(
                          width: size == ScreenSize.compact ? 0 : 24,
                          height: size == ScreenSize.compact ? 24 : 0,
                        ),
                        Expanded(
                          flex: 2,
                          child: _GrowthChart(values: controller.growthHistory),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  const AppAnimatedSlide(
                    delayIndex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'PLATFORM ACTIVITY',
                          subtitle:
                              'Recent activity and pending subscription approvals.',
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                  AppAnimatedSlide(
                    delayIndex: 5,
                    child: Flex(
                      direction: size == ScreenSize.compact
                          ? Axis.vertical
                          : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _ActivityList(
                            items: controller.recentActivity,
                          ),
                        ),
                        SizedBox(
                          width: size == ScreenSize.compact ? 0 : 24,
                          height: size == ScreenSize.compact ? 24 : 0,
                        ),
                        Expanded(
                          flex: 3,
                          child: _PendingPaymentsTable(
                            items: controller.pendingPaymentsTop,
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

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Super Admin Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage institutes, subscriptions, and platform-wide configurations.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        const AppSearchField(width: 380, hintText: 'Search institutes...'),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.columns, required this.kpis});

  final int columns;
  final DashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    final items = [
      KpiCardData(
        label: 'Institutes',
        value: _fmtInt(kpis.totalInstitutes),
        icon: Icons.apartment_rounded,
        gradient: const [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      KpiCardData(
        label: 'Active Subscriptions',
        value: _fmtInt(kpis.activeSubscriptions),
        icon: Icons.verified_rounded,
        gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      ),
      KpiCardData(
        label: 'Monthly Revenue',
        value: 'PKR ${_fmtInt(kpis.monthlyRevenuePkr)}',
        icon: Icons.payments_rounded,
        gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
      ),
      KpiCardData(
        label: 'Pending Approvals',
        value: _fmtInt(kpis.pendingPayments),
        icon: Icons.pending_actions_rounded,
        gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
      ),
    ];

    return AppKpiGrid(columns: columns, items: items);
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MONTHLY REVENUE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LIVE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(height: 280, child: _MockLineChart(values: values)),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTITUTE GROWTH',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(height: 280, child: _MockBarChart(values: values)),
        ],
      ),
    );
  }
}

class _MockLineChart extends StatelessWidget {
  const _MockLineChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LineChartPainter(
        values: values,
        lineGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [cs.primary, cs.secondary, cs.tertiary],
        ),
        gridColor: cs.outlineVariant.withValues(alpha: 0.8),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MockBarChart extends StatelessWidget {
  const _MockBarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _BarChartPainter(
        values: values,
        barGradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [cs.secondary, cs.tertiary],
        ),
        gridColor: cs.outlineVariant.withValues(alpha: 0.8),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.lineGradient,
    required this.gridColor,
  });

  final List<double> values;
  final Gradient lineGradient;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, size.height - ((values[i] - minV) / span) * size.height),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final cp1 = Offset(prev.dx + dx * 0.55, prev.dy);
      final cp2 = Offset(cur.dx - dx * 0.55, cur.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cur.dx, cur.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(bounds);

    canvas.saveLayer(bounds, Paint());
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.18),
            const Color(0xFF2563EB).withValues(alpha: 0.02),
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(fill, fillPaint);
    canvas.restore();

    final linePaint = Paint()
      ..shader = lineGradient.createShader(bounds)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..shader = lineGradient.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final p in points) {
      canvas.drawCircle(p, 4.4, dotPaint);
      canvas.drawCircle(p, 4.4, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineGradient != lineGradient ||
        oldDelegate.gridColor != gridColor;
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.values,
    required this.barGradient,
    required this.gridColor,
  });

  final List<double> values;
  final Gradient barGradient;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = maxV <= 0 ? 1.0 : maxV;

    final gap = 10.0;
    final barW = (size.width - gap * (values.length - 1)) / values.length;

    for (var i = 0; i < values.length; i++) {
      final h = (values[i] / span) * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (barW + gap), size.height - h, barW, h),
        const Radius.circular(999),
      );

      canvas.drawRRect(
        rect,
        Paint()..shader = barGradient.createShader(bounds),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barGradient != barGradient ||
        oldDelegate.gridColor != gridColor;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items});

  final List<DashboardActivityItem> items;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT ACTIVITY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 28),
          if (items.isEmpty)
            _EmptyState(
              icon: Icons.history_rounded,
              label: 'No recent activity',
              subtitle:
                  'Activity will appear here as institutes interact with the platform.',
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _ActivityRow(
                icon: _activityIcon(items[i].kind),
                title: items[i].title,
                subtitle: items[i].subtitle,
                time: _fmtAgo(items[i].time),
                tint: _activityTint(cs, items[i].kind),
              ),
              if (i != items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.08),
            borderRadius: AppRadii.r12,
          ),
          child: Icon(icon, color: tint, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _PendingPaymentsTable extends StatelessWidget {
  const _PendingPaymentsTable({required this.items});

  final List<DashboardPendingPaymentItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PENDING PAYMENTS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('VIEW ALL'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _TableHeader(),
          const SizedBox(height: 8),
          if (items.isEmpty)
            _EmptyState(
              icon: Icons.payments_rounded,
              label: 'No pending payments',
              subtitle: 'All subscription payments are up to date.',
            )
          else
            for (var i = 0; i < items.length.clamp(0, 5); i++) ...[
              _TableRow(
                name: items[i].instituteName,
                amount: 'PKR ${_fmtInt(items[i].amountPkr)}',
                status: _paymentStatusLabel(items[i].status),
                icon: Icons.account_balance_rounded,
              ),
              if (i != items.length.clamp(0, 5) - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
            ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Showing top ${items.length.clamp(0, 5)} pending payments',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _PaginationTrigger(
                icon: Icons.chevron_left_rounded,
                enabled: false,
              ),
              const SizedBox(width: 8),
              _PaginationTrigger(
                icon: Icons.chevron_right_rounded,
                enabled: items.length > 5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: AppRadii.r12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'INSTITUTE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            'AMOUNT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'STATUS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.name,
    required this.amount,
    required this.status,
    required this.icon,
  });

  final String name;
  final String amount;
  final String status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: cs.primary.withValues(alpha: 0.2),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationTrigger extends StatelessWidget {
  const _PaginationTrigger({required this.icon, required this.enabled});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: enabled
            ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: AppRadii.r8,
        border: Border.all(
          color: enabled
              ? cs.outlineVariant
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: enabled
            ? cs.onSurface
            : cs.onSurfaceVariant.withValues(alpha: 0.3),
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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r24,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                busy ? Icons.hub_rounded : Icons.cloud_off_rounded,
                color: cs.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              busy ? 'Loading Dashboard' : 'Connection Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message?.trim().isNotEmpty == true
                  ? message!.trim()
                  : 'Loading your EduCore dashboard. Please wait a moment while we fetch your platform data.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : () async => onRetry(),
                icon: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(busy ? 'Loading...' : 'Try Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _activityIcon(String kind) {
  switch (kind) {
    case 'academy_created':
      return Icons.add_business_rounded;
    case 'payment_pending':
      return Icons.receipt_long_rounded;
    case 'subscription':
    default:
      return Icons.verified_rounded;
  }
}

Color _activityTint(ColorScheme cs, String kind) {
  return switch (kind) {
    'academy_created' => cs.primary,
    'payment_pending' => cs.secondary,
    'subscription' => cs.tertiary,
    _ => cs.primary,
  };
}

String _fmtAgo(DateTime value) {
  final d = DateTime.now().difference(value);
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

String _paymentStatusLabel(PaymentReviewStatus status) {
  return switch (status) {
    PaymentReviewStatus.pending => 'Pending',
    PaymentReviewStatus.approved => 'Approved',
    PaymentReviewStatus.rejected => 'Rejected',
  };
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
