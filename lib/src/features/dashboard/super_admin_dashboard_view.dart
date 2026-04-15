import 'package:educore/src/app/shell/app_shell.dart';
import 'package:educore/src/app/shell/sidebar_item.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/dashboard/dashboard_controller.dart';
import 'package:educore/src/features/analytics/analytics_view.dart';
import 'package:educore/src/features/features/features_view.dart';
import 'package:educore/src/features/institutes/institutes_view.dart';
import 'package:educore/src/features/notifications/notifications_view.dart';
import 'package:educore/src/features/payments/payments_view.dart';
import 'package:educore/src/features/plans/plans_view.dart';
import 'package:educore/src/features/settings/settings_view.dart';
import 'package:educore/src/features/subscriptions/subscriptions_view.dart';
import 'package:educore/src/features/users/users_view.dart';
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
      sidebarItems: _SuperAdminNav.items,
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
            _SuperAdminNav.plans => const PlansView(),
            _SuperAdminNav.settings => const SettingsView(),
            _ => _PlaceholderPage(title: current.title),
          },
        ),
      ),
    );
  }
}

enum _SuperAdminNav {
  dashboard('dashboard', 'Dashboard', 'Super Admin', Icons.dashboard_rounded),
  institutes('institutes', 'Institutes', 'Institutes', Icons.apartment_rounded),
  subscriptions(
    'subscriptions',
    'Subscriptions',
    'Subscriptions',
    Icons.verified_rounded,
  ),
  payments('payments', 'Payments', 'Payments', Icons.payments_rounded),
  analytics('analytics', 'Analytics', 'Analytics', Icons.trending_up_rounded),
  users('users', 'Users', 'Users', Icons.people_alt_rounded),
  notifications(
    'notifications',
    'Notifications',
    'Notifications',
    Icons.notifications_active_rounded,
  ),
  features('features', 'Features', 'Feature Management', Icons.tune_rounded),
  plans('plans', 'Plans', 'Plans', Icons.layers_rounded),
  settings('settings', 'Settings', 'Settings', Icons.settings_rounded);

  const _SuperAdminNav(this.id, this.label, this.title, this.icon);
  final String id;
  final String label;
  final String title;
  final IconData icon;

  static List<SidebarItemData> get items => _SuperAdminNav.values
      .map((e) => SidebarItemData(id: e.id, label: e.label, icon: e.icon))
      .toList(growable: false);

  static _SuperAdminNav byId(String id) =>
      _SuperAdminNav.values.firstWhere((e) => e.id == id);
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This section is ready for the next build step.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: cs.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Coming next',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We’ll build this screen with tables, filters, and actions.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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

class _DashboardHomeBodyStatefulState extends State<_DashboardHomeBodyStateful> {
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(),
                  const SizedBox(height: 16),
                  _KpiGrid(columns: columns, kpis: controller.kpis),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Analytics',
                    subtitle: 'Revenue and institute growth at a glance.',
                  ),
                  const SizedBox(height: 12),
                  Flex(
                    direction: size == ScreenSize.compact
                        ? Axis.vertical
                        : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: AppCard(child: _RevenueChart())),
                      SizedBox(
                        width: size == ScreenSize.compact ? 0 : 16,
                        height: size == ScreenSize.compact ? 16 : 0,
                      ),
                      Expanded(child: AppCard(child: _GrowthChart())),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Operations',
                    subtitle: 'Recent activity and pending approvals.',
                  ),
                  const SizedBox(height: 12),
                  Flex(
                    direction: size == ScreenSize.compact
                        ? Axis.vertical
                        : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppCard(
                          child: _ActivityList(items: controller.recentActivity),
                        ),
                      ),
                      SizedBox(
                        width: size == ScreenSize.compact ? 0 : 16,
                        height: size == ScreenSize.compact ? 16 : 0,
                      ),
                      Expanded(
                        child: AppCard(
                          child: _PendingPaymentsTable(
                            items: controller.pendingPaymentsTop,
                          ),
                        ),
                      ),
                    ],
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage institutes, subscriptions, payments, and system health.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        AppCard(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_business_rounded, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                'Create Institute',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
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
      _KpiData(
        'Total Institutes',
        _fmtInt(kpis.totalInstitutes),
        Icons.apartment_rounded,
        const [Color(0xFF2563EB), Color(0xFF6366F1)],
      ),
      _KpiData(
        'Active Subscriptions',
        _fmtInt(kpis.activeSubscriptions),
        Icons.verified_rounded,
        const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      ),
      _KpiData(
        'Monthly Revenue',
        'PKR ${_fmtInt(kpis.monthlyRevenuePkr)}',
        Icons.payments_rounded,
        const [Color(0xFF2563EB), Color(0xFF8B5CF6)],
      ),
      _KpiData(
        'Pending Payments',
        _fmtInt(kpis.pendingPayments),
        Icons.pending_actions_rounded,
        const [Color(0xFF1D4ED8), Color(0xFF6366F1)],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: AppCard(child: _KpiCard(data: item)),
              )
          ],
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.gradient);
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: data.gradient.first.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(data.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Revenue Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              'Last 30 days',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: _MockLineChart(),
          ),
        ),
      ],
    );
  }
}

class _GrowthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institute Growth',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: cs.secondary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: _MockBarChart(),
          ),
        ),
      ],
    );
  }
}

class _MockLineChart extends StatelessWidget {
  const _MockLineChart();

  static const _values = <double>[12, 18, 15, 22, 20, 28, 26, 34, 30, 38, 44];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LineChartPainter(
        values: _values,
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
  const _MockBarChart();

  static const _values = <double>[8, 12, 10, 16, 14, 18, 20, 22];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _BarChartPainter(
        values: _values,
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
        Offset(
          i * dx,
          size.height - ((values[i] - minV) / span) * size.height,
        ),
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
        Rect.fromLTWH(
          i * (barW + gap),
          size.height - h,
          barW,
          h,
        ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No recent activity yet.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        if (items.isNotEmpty) ...[
          for (var i = 0; i < items.length; i++) ...[
            _ActivityRow(
              icon: _activityIcon(items[i].kind),
              title: items[i].title,
              subtitle: items[i].subtitle,
              time: _fmtAgo(items[i].time),
              tint: _activityTint(cs, items[i].kind),
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
        if (false) ...[
        _ActivityRow(
          icon: Icons.verified_rounded,
          title: 'Subscription approved',
          subtitle: 'Green Valley Academy • Standard Plan',
          time: '2m ago',
          tint: cs.primary,
        ),
        const SizedBox(height: 10),
        _ActivityRow(
          icon: Icons.payments_rounded,
          title: 'Payment verified',
          subtitle: 'Sunrise School • PKR 18,000',
          time: '18m ago',
          tint: cs.secondary,
        ),
        const SizedBox(height: 10),
        _ActivityRow(
          icon: Icons.block_rounded,
          title: 'Institute blocked',
          subtitle: 'Apex Institute • Policy violation',
          time: '1h ago',
          tint: cs.tertiary,
        ),
        ],
      ],
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: tint, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pending Payments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              'View all',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TableHeader(),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No pending payments.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        if (items.isNotEmpty) ...[
          for (var i = 0; i < items.length.clamp(0, 3); i++) ...[
            _TableRow(
              name: items[i].instituteName,
              amount: 'PKR ${_fmtInt(items[i].amountPkr)}',
              status: _paymentStatusLabel(items[i].status),
            ),
            if (i != items.length.clamp(0, 3) - 1) const SizedBox(height: 6),
          ],
        ],
        if (false) ...[
        _TableRow(name: 'Green Valley', amount: 'PKR 18,000', status: 'Pending'),
        const SizedBox(height: 6),
        _TableRow(name: 'City School', amount: 'PKR 12,500', status: 'Review'),
        const SizedBox(height: 6),
        _TableRow(name: 'Apex Institute', amount: 'PKR 21,000', status: 'Pending'),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '1–3 of 12',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Institute',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            'Amount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 12),
          Text(
            'Status',
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

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.name,
    required this.amount,
    required this.status,
  });

  final String name;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.cloud_off_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    busy ? 'Initializing Firebase…' : 'Firestore not ready',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.trim().isNotEmpty == true
                        ? message!.trim()
                        : 'Dashboard requires Firebase Firestore. Initialize Firebase to enable this module.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: busy ? null : () async => onRetry(),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
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
