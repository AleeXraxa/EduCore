import 'dart:math';

import 'package:educore/src/core/mvc/base_controller.dart';

enum AnalyticsRange { last7, last30, last3Months, last12Months }

enum AnalyticsPlanFilter { all, basic, standard, premium }

class AnalyticsController extends BaseController {
  AnalyticsRange _range = AnalyticsRange.last30;
  AnalyticsPlanFilter _plan = AnalyticsPlanFilter.all;

  AnalyticsRange get range => _range;
  AnalyticsPlanFilter get plan => _plan;

  AnalyticsSnapshot _snapshot = AnalyticsSnapshot.mock(range: AnalyticsRange.last30);
  AnalyticsSnapshot get snapshot => _snapshot;

  Future<void> setRange(AnalyticsRange value) async {
    _range = value;
    await _reload();
  }

  Future<void> setPlan(AnalyticsPlanFilter value) async {
    _plan = value;
    await _reload();
  }

  Future<void> _reload() async {
    await runBusy<void>(() async {
      // Simulate data refresh so transitions feel real in the UI.
      await Future<void>.delayed(const Duration(milliseconds: 220));
      _snapshot = AnalyticsSnapshot.mock(
        range: _range,
        plan: _plan,
        seed: DateTime.now().millisecondsSinceEpoch,
      );
    });
    notifyListeners();
  }
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.totalRevenuePkr,
    required this.revenueThisMonthPkr,
    required this.totalInstitutes,
    required this.activeSubscriptions,
    required this.avgRevenuePerInstitutePkr,
    required this.expiringSubscriptions,
    required this.revenueTrend,
    required this.revenueTrendUp,
    required this.monthTrend,
    required this.monthTrendUp,
    required this.arpiTrend,
    required this.arpiTrendUp,
    required this.revenueSeries,
    required this.growthSeries,
    required this.planDist,
    required this.paymentBreakdown,
    required this.topInstitutes,
    required this.upcomingExpiries,
  });

  final int totalRevenuePkr;
  final int revenueThisMonthPkr;
  final int totalInstitutes;
  final int activeSubscriptions;
  final int avgRevenuePerInstitutePkr;
  final int expiringSubscriptions;

  final String revenueTrend;
  final bool revenueTrendUp;
  final String monthTrend;
  final bool monthTrendUp;
  final String arpiTrend;
  final bool arpiTrendUp;

  final List<double> revenueSeries;
  final List<double> growthSeries;

  /// Percentages out of 100.
  final PlanDistribution planDist;
  final PaymentBreakdown paymentBreakdown;

  final List<TopInstituteRow> topInstitutes;
  final List<ExpiryRow> upcomingExpiries;

  static AnalyticsSnapshot mock({
    required AnalyticsRange range,
    AnalyticsPlanFilter plan = AnalyticsPlanFilter.all,
    int? seed,
  }) {
    final rng = Random(seed ?? 42);
    final rangeFactor = switch (range) {
      AnalyticsRange.last7 => 0.55,
      AnalyticsRange.last30 => 1.0,
      AnalyticsRange.last3Months => 1.35,
      AnalyticsRange.last12Months => 1.8,
    };

    final planFactor = switch (plan) {
      AnalyticsPlanFilter.all => 1.0,
      AnalyticsPlanFilter.basic => 0.72,
      AnalyticsPlanFilter.standard => 1.05,
      AnalyticsPlanFilter.premium => 1.35,
    };

    final totalRevenue = (5_200_000 * rangeFactor * planFactor).round();
    final monthRevenue = (620_000 * rangeFactor * planFactor).round();
    final institutes = (62 * (0.92 + rng.nextDouble() * 0.12)).round();
    final activeSubs = (48 * (0.92 + rng.nextDouble() * 0.16)).round();
    final arpi = (totalRevenue / max(institutes, 1)).round();
    final expiring = max(3, (9 * (0.7 + rng.nextDouble() * 0.6)).round());

    final revenueTrendUp = rng.nextBool();
    final monthTrendUp = rng.nextBool();
    final arpiTrendUp = rng.nextBool();

    final revenueSeries = List<double>.generate(
      12,
      (i) => 18 + i * (1.5 + rng.nextDouble() * 1.1) + rng.nextDouble() * 6,
      growable: false,
    );
    final growthSeries = List<double>.generate(
      12,
      (i) => 6 + (rng.nextDouble() * 6) + (i / 12) * 8,
      growable: false,
    );

    final base = plan == AnalyticsPlanFilter.all
        ? const PlanDistribution(basic: 28, standard: 46, premium: 26)
        : switch (plan) {
            AnalyticsPlanFilter.basic =>
              const PlanDistribution(basic: 92, standard: 6, premium: 2),
            AnalyticsPlanFilter.standard =>
              const PlanDistribution(basic: 12, standard: 82, premium: 6),
            AnalyticsPlanFilter.premium =>
              const PlanDistribution(basic: 6, standard: 14, premium: 80),
            AnalyticsPlanFilter.all =>
              const PlanDistribution(basic: 28, standard: 46, premium: 26),
          };

    final payment = PaymentBreakdown(
      approved: max(45, (72 * (0.7 + rng.nextDouble() * 0.25)).round()),
      pending: max(6, (18 * (0.7 + rng.nextDouble() * 0.7)).round()),
      rejected: max(2, (6 * (0.7 + rng.nextDouble() * 0.8)).round()),
    );

    final top = List<TopInstituteRow>.generate(6, (i) {
      final rev = (rng.nextDouble() * 220_000 + 60_000).round();
      final growth = (rng.nextDouble() * 18 + 2);
      final planLabel = switch (i % 3) { 0 => 'Standard', 1 => 'Premium', _ => 'Basic' };
      return TopInstituteRow(
        name: 'Institute ${String.fromCharCode(65 + i)}',
        revenuePkr: rev,
        plan: planLabel,
        growthPct: (growth * (rng.nextBool() ? 1 : -1)),
      );
    });

    final expiries = List<ExpiryRow>.generate(6, (i) {
      final days = i == 0 ? 2 : (3 + i * 3);
      final date = DateTime.now().add(Duration(days: days));
      final planLabel = switch (i % 3) { 0 => 'Standard', 1 => 'Premium', _ => 'Basic' };
      return ExpiryRow(
        name: 'Institute ${String.fromCharCode(75 + i)}',
        plan: planLabel,
        expiry: date,
        daysLeft: days,
      );
    });

    return AnalyticsSnapshot(
      totalRevenuePkr: totalRevenue,
      revenueThisMonthPkr: monthRevenue,
      totalInstitutes: institutes,
      activeSubscriptions: activeSubs,
      avgRevenuePerInstitutePkr: arpi,
      expiringSubscriptions: expiring,
      revenueTrend: revenueTrendUp ? '+12%' : '-4%',
      revenueTrendUp: revenueTrendUp,
      monthTrend: monthTrendUp ? '+7%' : '-2%',
      monthTrendUp: monthTrendUp,
      arpiTrend: arpiTrendUp ? '+5%' : '-3%',
      arpiTrendUp: arpiTrendUp,
      revenueSeries: revenueSeries,
      growthSeries: growthSeries,
      planDist: base,
      paymentBreakdown: payment,
      topInstitutes: top,
      upcomingExpiries: expiries,
    );
  }
}

class PlanDistribution {
  const PlanDistribution({
    required this.basic,
    required this.standard,
    required this.premium,
  });

  final int basic;
  final int standard;
  final int premium;
}

class PaymentBreakdown {
  const PaymentBreakdown({
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  final int approved;
  final int pending;
  final int rejected;

  int get total => approved + pending + rejected;
}

class TopInstituteRow {
  const TopInstituteRow({
    required this.name,
    required this.revenuePkr,
    required this.plan,
    required this.growthPct,
  });

  final String name;
  final int revenuePkr;
  final String plan;
  final double growthPct;
}

class ExpiryRow {
  const ExpiryRow({
    required this.name,
    required this.plan,
    required this.expiry,
    required this.daysLeft,
  });

  final String name;
  final String plan;
  final DateTime expiry;
  final int daysLeft;
}

