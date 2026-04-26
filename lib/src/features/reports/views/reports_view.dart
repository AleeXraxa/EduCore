import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/features/reports/controllers/reports_controller.dart';
import 'package:educore/src/features/reports/models/report_config.dart';
import 'package:educore/src/features/reports/widgets/report_charts.dart';
import 'package:educore/src/features/reports/widgets/report_filter_panel.dart';
import 'package:educore/src/features/reports/widgets/report_preview_panel.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView>
    with SingleTickerProviderStateMixin {
  late final ReportsController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = ReportsController();
    _controller.init();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<ReportsController>(
      controller: _controller,
      builder: (context, controller, _) {
        final size = screenSizeForWidth(MediaQuery.of(context).size.width);
        final isCompact = size == ScreenSize.compact;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              _buildHeader(context, isCompact),
              _buildCategoryTabs(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildReportGenerator(context, controller, isCompact),
                    _buildAnalyticsDashboard(context, controller, isCompact),
                    _buildReportGenerator(context, controller, isCompact),
                    _buildReportGenerator(context, controller, isCompact),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isCompact) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 32,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            bottom:
                BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.analytics_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  'Academic, Financial & Operational insights — exportable PDF & Excel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category tabs ────────────────────────────────────────────────────────

  Widget _buildCategoryTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: cs.primary,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        onTap: (index) {
          final cats = [
            ReportCategory.academic,
            null, // analytics
            ReportCategory.financial,
            ReportCategory.operational,
          ];
          if (cats[index] != null) {
            _controller.selectCategory(cats[index]!);
          }
        },
        tabs: const [
          Tab(
            icon: Icon(Icons.school_rounded, size: 18),
            text: 'Academic',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.bar_chart_rounded, size: 18),
            text: 'Analytics Dashboard',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.attach_money_rounded, size: 18),
            text: 'Financial',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.manage_accounts_rounded, size: 18),
            text: 'Operational',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
        ],
      ),
    );
  }

  // ─── Report Generator ─────────────────────────────────────────────────────

  Widget _buildReportGenerator(
    BuildContext context,
    ReportsController controller,
    bool isCompact,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left — report catalogue
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border(
              right: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.4),
              ),
            ),
          ),
          child: _ReportCatalogue(controller: controller),
        ),
        // Right — filter + preview
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CustomScrollView(
              slivers: [
                // Filter panel (only when report selected)
                if (controller.selectedReport != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ReportFilterPanel(controller: controller),
                    ),
                  ),
                // Preview area
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: ReportPreviewPanel(controller: controller),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Analytics Dashboard ──────────────────────────────────────────────────

  Widget _buildAnalyticsDashboard(
    BuildContext context,
    ReportsController controller,
    bool isCompact,
  ) {
    if (!controller.analyticsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final revenue = controller.monthlyTrends['revenue'] ?? [];
    final expenses = controller.monthlyTrends['expenses'] ?? [];
    final plValues = List.generate(
      revenue.length,
      (i) => (revenue.length > i ? revenue[i] : 0.0) -
          (expenses.length > i ? expenses[i] : 0.0),
    );

    // Build month labels for the past 6 months
    final now = DateTime.now();
    final labels = List.generate(6, (i) {
      final dt = DateTime(now.year, now.month - (5 - i), 1);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI summary row
          _buildAnalyticsKPIs(context, controller, revenue, expenses, plValues),
          const SizedBox(height: 24),

          // Revenue vs Expenses chart
          _ChartCard(
            title: 'Revenue vs Expenses',
            subtitle: 'Last 6 months comparison',
            icon: Icons.bar_chart_rounded,
            legend: const [
              _LegendItem(color: Color(0xFF2563EB), label: 'Revenue'),
              _LegendItem(color: Color(0xFFE11D48), label: 'Expenses'),
            ],
            child: SizedBox(
              height: 240,
              child: RevenueExpenseChart(
                revenue: revenue,
                expenses: expenses,
                monthLabels: labels,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // P&L trend
              Expanded(
                child: _ChartCard(
                  title: 'Profit & Loss Trend',
                  subtitle: 'Net P&L per month',
                  icon: Icons.trending_up_rounded,
                  child: SizedBox(
                    height: 220,
                    child: ProfitLossLineChart(
                      plValues: plValues,
                      labels: labels,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Expense category donut
              Expanded(
                child: _ChartCard(
                  title: 'Expense Breakdown',
                  subtitle: 'By category — all time',
                  icon: Icons.pie_chart_rounded,
                  child: SizedBox(
                    height: 220,
                    child: ExpenseCategoryDonut(
                      data: controller.expenseCategoryBreakdown,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Student breakdown
          _ChartCard(
            title: 'Student Status Breakdown',
            subtitle: 'Active, Inactive, etc.',
            icon: Icons.people_rounded,
            child: _StudentBreakdownBars(
              breakdown: controller.studentBreakdown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsKPIs(
    BuildContext context,
    ReportsController controller,
    List<double> revenue,
    List<double> expenses,
    List<double> pl,
  ) {
    final fmt = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);
    final totalRev = revenue.fold(0.0, (a, b) => a + b);
    final totalExp = expenses.fold(0.0, (a, b) => a + b);
    final netPL = totalRev - totalExp;
    final totalStudents = controller.studentBreakdown.values
        .fold(0, (a, b) => a + b);

    return LayoutBuilder(builder: (context, constraints) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _AnalyticsKpiCard(
            label: 'Total Revenue (6M)',
            value: fmt.format(totalRev),
            icon: Icons.attach_money_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
          _AnalyticsKpiCard(
            label: 'Total Expenses (6M)',
            value: fmt.format(totalExp),
            icon: Icons.money_off_rounded,
            gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
          ),
          _AnalyticsKpiCard(
            label: 'Net P&L (6M)',
            value: (netPL >= 0 ? '+' : '') + fmt.format(netPL),
            icon: netPL >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            gradient: netPL >= 0
                ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
                : [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
          ),
          _AnalyticsKpiCard(
            label: 'Total Students',
            value: NumberFormat.decimalPattern().format(totalStudents),
            icon: Icons.people_rounded,
            gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
          ),
        ],
      );
    });
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ReportCatalogue extends StatelessWidget {
  const _ReportCatalogue({required this.controller});
  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reports = controller.accessibleReports;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'SELECT REPORT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
        ...reports.map((meta) {
          final isSelected = controller.selectedReport?.type == meta.type;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? meta.gradient.first.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? meta.gradient.first.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: ListTile(
              dense: true,
              onTap: () => controller.selectReport(meta),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: meta.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(meta.icon, size: 16, color: Colors.white),
              ),
              title: Text(
                meta.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? meta.gradient.first : cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.legend,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final List<_LegendItem>? legend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              if (legend != null) ...legend!.map((l) => l),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  const _AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentBreakdownBars extends StatelessWidget {
  const _StudentBreakdownBars({required this.breakdown});
  final Map<String, int> breakdown;

  static const _colors = {
    'active': Color(0xFF16A34A),
    'inactive': Color(0xFF64748B),
    'dropped': Color(0xFFDC2626),
    'passed': Color(0xFF2563EB),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (breakdown.isEmpty) {
      return const Center(child: Text('No student data'));
    }
    final total = breakdown.values.fold(0, (a, b) => a + b);

    return Column(
      children: breakdown.entries.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        final color =
            _colors[e.key.toLowerCase()] ?? const Color(0xFF6366F1);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _capitalize(e.key),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${e.value} (${(pct * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
