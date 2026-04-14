import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/analytics/analytics_controller.dart';
import 'package:flutter/material.dart';

class AnalyticsKpisSection extends StatelessWidget {
  const AnalyticsKpisSection({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = screenSizeForWidth(constraints.maxWidth);
        final columns = switch (size) {
          ScreenSize.compact => 1,
          ScreenSize.medium => 2,
          ScreenSize.expanded => 3,
        };

        final items = [
          KpiCardData(
            label: 'Total Revenue',
            value: _fmtMoney(snapshot.totalRevenuePkr),
            icon: Icons.payments_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF8B5CF6)],
            trendText: snapshot.revenueTrend,
            trendUp: snapshot.revenueTrendUp,
          ),
          KpiCardData(
            label: 'Revenue This Month',
            value: _fmtMoney(snapshot.revenueThisMonthPkr),
            icon: Icons.trending_up_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF6366F1)],
            trendText: snapshot.monthTrend,
            trendUp: snapshot.monthTrendUp,
          ),
          KpiCardData(
            label: 'Total Institutes',
            value: _fmtInt(snapshot.totalInstitutes),
            icon: Icons.apartment_rounded,
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          KpiCardData(
            label: 'Active Subscriptions',
            value: _fmtInt(snapshot.activeSubscriptions),
            icon: Icons.verified_rounded,
            gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
          ),
          KpiCardData(
            label: 'Avg Revenue / Institute',
            value: _fmtMoney(snapshot.avgRevenuePerInstitutePkr),
            icon: Icons.insights_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF6366F1)],
            trendText: snapshot.arpiTrend,
            trendUp: snapshot.arpiTrendUp,
          ),
          KpiCardData(
            label: 'Expiring Subscriptions',
            value: _fmtInt(snapshot.expiringSubscriptions),
            icon: Icons.warning_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
          ),
        ];

        const gap = 12.0;
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final kpi in items)
              SizedBox(width: cardWidth, child: KpiCard(data: kpi)),
          ],
        );
      },
    );
  }
}

String _fmtMoney(int pkr) => 'PKR ${_fmtInt(pkr)}';

String _fmtInt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - 1 - i;
    b.write(s[idx]);
    if ((i + 1) % 3 == 0 && idx != 0) b.write(',');
  }
  return b.toString().split('').reversed.join();
}

