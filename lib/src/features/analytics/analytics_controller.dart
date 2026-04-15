import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/services/admin_payments_service.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'dart:async';
import 'dart:math';

enum AnalyticsRange { last7, last30, last3Months, last12Months }

enum AnalyticsPlanFilter { all, basic, standard, premium }

class AnalyticsController extends BaseController {
  AnalyticsRange _range = AnalyticsRange.last30;
  AnalyticsPlanFilter _plan = AnalyticsPlanFilter.all;

  AnalyticsRange get range => _range;
  AnalyticsPlanFilter get plan => _plan;

  AnalyticsSnapshot _snapshot =
      const AnalyticsSnapshot(
        totalRevenuePkr: 0,
        revenueThisMonthPkr: 0,
        totalInstitutes: 0,
        activeSubscriptions: 0,
        avgRevenuePerInstitutePkr: 0,
        expiringSubscriptions: 0,
        revenueTrend: '—',
        revenueTrendUp: true,
        monthTrend: '—',
        monthTrendUp: true,
        arpiTrend: '—',
        arpiTrendUp: true,
        revenueSeries: <double>[0, 0],
        growthSeries: <double>[0, 0],
        planDist: PlanDistribution(basic: 0, standard: 0, premium: 0),
        paymentBreakdown: PaymentBreakdown(approved: 0, pending: 0, rejected: 0),
        topInstitutes: <TopInstituteRow>[],
        upcomingExpiries: <ExpiryRow>[],
      );
  AnalyticsSnapshot get snapshot => _snapshot;

  AdminSubscriptionsService? _subsService;
  AdminPaymentsService? _paymentsService;
  PlanService? _planService;
  InstituteService? _instituteService;

  StreamSubscription<List<SubscriptionRecord>>? _subsSub;
  StreamSubscription<List<PaymentRecord>>? _paymentsSub;
  StreamSubscription<List<Plan>>? _plansSub;
  StreamSubscription<List<Academy>>? _academiesSub;

  List<SubscriptionRecord> _subscriptions = const [];
  List<PaymentRecord> _payments = const [];
  List<Academy> _academies = const [];
  Map<String, Plan> _planById = const <String, Plan>{};
  Map<String, Academy> _academyById = const <String, Academy>{};

  String? errorMessage;
  bool get ready => _subsService != null;

  AnalyticsController() {
    _subsService = AppServices.instance.adminSubscriptionsService;
    _paymentsService = AppServices.instance.adminPaymentsService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;
    _attachOrInit();
  }

  Future<void> setRange(AnalyticsRange value) async {
    _range = value;
    _recompute();
    notifyListeners();
  }

  Future<void> setPlan(AnalyticsPlanFilter value) async {
    _plan = value;
    _recompute();
    notifyListeners();
  }

  Future<void> retryInit() => _attachOrInit();

  @override
  void dispose() {
    _subsSub?.cancel();
    _paymentsSub?.cancel();
    _plansSub?.cancel();
    _academiesSub?.cancel();
    super.dispose();
  }

  Future<void> _attachOrInit() async {
    if (_subsService != null) {
      _attachAll();
      _recompute();
      return;
    }

    await runBusy<void>(() async {
      await AppServices.instance.init();
    });

    _subsService = AppServices.instance.adminSubscriptionsService;
    _paymentsService = AppServices.instance.adminPaymentsService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;

    if (_subsService == null) {
      errorMessage = AppServices.instance.firebaseInitError?.toString();
      notifyListeners();
      return;
    }

    _attachAll();
    _recompute();
  }

  void _attachAll() {
    final subsSvc = _subsService;
    if (subsSvc != null) _attachSubscriptions(subsSvc);

    final paySvc = _paymentsService;
    if (paySvc != null) _attachPayments(paySvc);

    final planSvc = _planService;
    if (planSvc != null) _attachPlans(planSvc);

    final instSvc = _instituteService;
    if (instSvc != null) _attachAcademies(instSvc);
  }

  void _attachSubscriptions(AdminSubscriptionsService svc) {
    if (_subsService == svc && _subsSub != null) return;
    _subsService = svc;
    _subsSub?.cancel();
    _subsSub = svc.watchSubscriptions().listen(
      (value) {
        _subscriptions = value;
        errorMessage = null;
        _recompute();
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        // ignore: avoid_print
        print('Analytics subscriptions error: $e');
        notifyListeners();
      },
    );
  }

  void _attachPayments(AdminPaymentsService svc) {
    if (_paymentsService == svc && _paymentsSub != null) return;
    _paymentsService = svc;
    _paymentsSub?.cancel();
    _paymentsSub = svc.watchPayments().listen(
      (value) {
        final list = value.toList(growable: true)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _payments = list;
        _recompute();
        notifyListeners();
      },
      onError: (e) {
        // Payments are optional early on; keep analytics usable if this fails.
        // ignore: avoid_print
        print('Analytics payments error: $e');
      },
    );
  }

  void _attachPlans(PlanService svc) {
    if (_planService == svc && _plansSub != null) return;
    _planService = svc;
    _plansSub?.cancel();
    _plansSub = svc.watchPlans().listen(
      (items) {
        _planById = {for (final p in items) p.id: p};
        _recompute();
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Analytics plans error: $e');
      },
    );
  }

  void _attachAcademies(InstituteService svc) {
    if (_instituteService == svc && _academiesSub != null) return;
    _instituteService = svc;
    _academiesSub?.cancel();
    _academiesSub = svc.watchAcademies().listen(
      (items) {
        _academies = items;
        _academyById = {for (final a in items) a.id: a};
        _recompute();
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Analytics academies error: $e');
      },
    );
  }

  void _recompute() {
    final now = DateTime.now();
    final window = _rangeWindow(now, _range);
    final prevWindow = _rangeWindow(window.start, _range, previous: true);

    final subsFiltered = _filterByPlan(_subscriptions, _planById, _plan);
    final paymentsFiltered = _filterPaymentsByPlan(
      _payments,
      _subscriptions,
      _plan,
      _planById,
    );

    final revenueAll = _revenueInRange(
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      planById: _planById,
      start: DateTime.fromMillisecondsSinceEpoch(0),
      end: now,
    );

    final revenueThisMonth = _revenueInRange(
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      planById: _planById,
      start: DateTime(now.year, now.month, 1),
      end: now,
    );

    final activeSubs = subsFiltered.where((s) => _isActiveAt(s, now)).length;

    final expiring = subsFiltered.where((s) {
      if (!_isActiveAt(s, now)) return false;
      final end = s.endDate;
      if (end == null) return false;
      final days = end.difference(now).inDays;
      return days >= 0 && days <= 7;
    }).length;

    final windowRevenue = _revenueInRange(
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      planById: _planById,
      start: window.start,
      end: window.end,
    );
    final prevRevenue = _revenueInRange(
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      planById: _planById,
      start: prevWindow.start,
      end: prevWindow.end,
    );

    final revenueTrend = _pctTrend(windowRevenue, prevRevenue);
    final revenueTrendUp = windowRevenue >= prevRevenue;

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(milliseconds: 1));

    final monthRevenueNow = _revenueInRange(
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      planById: _planById,
      start: thisMonthStart,
      end: now,
    );
    final monthRevenuePrev = _revenueInRange(
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      planById: _planById,
      start: lastMonthStart,
      end: lastMonthEnd,
    );
    final monthTrend = _pctTrend(monthRevenueNow, monthRevenuePrev);
    final monthTrendUp = monthRevenueNow >= monthRevenuePrev;

    final arpiNow =
        revenueThisMonth ~/ max(_academies.isEmpty ? 1 : _academies.length, 1);
    final arpiPrev =
        (monthRevenuePrev) ~/ max(_academies.isEmpty ? 1 : _academies.length, 1);
    final arpiTrend = _pctTrend(arpiNow, arpiPrev);
    final arpiTrendUp = arpiNow >= arpiPrev;

    final series = _buildSeries(
      now: now,
      range: _range,
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      academies: _academies,
      planById: _planById,
    );

    final planDist = _planDistribution(subsFiltered, _planById);

    final paymentBreakdown = PaymentBreakdown(
      approved: paymentsFiltered
          .where((p) => p.status == PaymentReviewStatus.approved)
          .length,
      pending: paymentsFiltered
          .where((p) => p.status == PaymentReviewStatus.pending)
          .length,
      rejected: paymentsFiltered
          .where((p) => p.status == PaymentReviewStatus.rejected)
          .length,
    );

    final topInstitutes = _topInstitutes(
      now: now,
      window: window,
      prevWindow: prevWindow,
      payments: paymentsFiltered,
      subscriptions: subsFiltered,
      academyById: _academyById,
      planById: _planById,
    );

    final upcomingExpiries = _upcomingExpiries(
      now: now,
      subscriptions: subsFiltered,
      academyById: _academyById,
      planById: _planById,
    );

    _snapshot = AnalyticsSnapshot(
      totalRevenuePkr: revenueAll,
      revenueThisMonthPkr: revenueThisMonth,
      totalInstitutes: _academies.length,
      activeSubscriptions: activeSubs,
      avgRevenuePerInstitutePkr: arpiNow,
      expiringSubscriptions: expiring,
      revenueTrend: revenueTrend,
      revenueTrendUp: revenueTrendUp,
      monthTrend: monthTrend,
      monthTrendUp: monthTrendUp,
      arpiTrend: arpiTrend,
      arpiTrendUp: arpiTrendUp,
      revenueSeries: series.revenue,
      growthSeries: series.growth,
      planDist: planDist,
      paymentBreakdown: paymentBreakdown,
      topInstitutes: topInstitutes,
      upcomingExpiries: upcomingExpiries,
    );
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

class _SeriesResult {
  const _SeriesResult({required this.revenue, required this.growth});
  final List<double> revenue;
  final List<double> growth;
}

({DateTime start, DateTime end}) _rangeWindow(
  DateTime now,
  AnalyticsRange range, {
  bool previous = false,
}) {
  final end = previous ? now : now;
  final baseEnd = end;
  final duration = switch (range) {
    AnalyticsRange.last7 => const Duration(days: 7),
    AnalyticsRange.last30 => const Duration(days: 30),
    AnalyticsRange.last3Months => const Duration(days: 90),
    AnalyticsRange.last12Months => const Duration(days: 365),
  };
  final start = baseEnd.subtract(duration);
  final prevStart = start.subtract(duration);
  if (previous) {
    return (start: prevStart, end: start);
  }
  return (start: start, end: baseEnd);
}

List<SubscriptionRecord> _filterByPlan(
  List<SubscriptionRecord> input,
  Map<String, Plan> planById,
  AnalyticsPlanFilter filter,
) {
  if (filter == AnalyticsPlanFilter.all) return input;
  final key = switch (filter) {
    AnalyticsPlanFilter.basic => 'basic',
    AnalyticsPlanFilter.standard => 'standard',
    AnalyticsPlanFilter.premium => 'premium',
    AnalyticsPlanFilter.all => '',
  };

  return input.where((s) {
    final p = planById[s.planId];
    final name = (p?.name ?? s.planId).toLowerCase();
    return name.contains(key);
  }).toList(growable: false);
}

List<PaymentRecord> _filterPaymentsByPlan(
  List<PaymentRecord> payments,
  List<SubscriptionRecord> subscriptions,
  AnalyticsPlanFilter filter,
  Map<String, Plan> planById,
) {
  if (filter == AnalyticsPlanFilter.all) return payments;
  final allowedAcademies = <String>{};
  final subs = _filterByPlan(subscriptions, planById, filter);
  for (final s in subs) {
    allowedAcademies.add(s.academyId);
  }
  return payments
      .where((p) => allowedAcademies.contains(p.academyId))
      .toList(growable: false);
}

bool _isActiveAt(SubscriptionRecord s, DateTime at) {
  if (s.status != SubscriptionRecordStatus.active) return false;
  final start = s.startDate;
  final end = s.endDate;
  if (start != null && start.isAfter(at)) return false;
  if (end != null && end.isBefore(at)) return false;
  return true;
}

int _revenueInRange({
  required List<PaymentRecord> payments,
  required List<SubscriptionRecord> subscriptions,
  required Map<String, Plan> planById,
  required DateTime start,
  required DateTime end,
}) {
  final approved = payments.where((p) => p.status == PaymentReviewStatus.approved);
  final sumPayments = approved
      .where((p) => !p.createdAt.isBefore(start) && p.createdAt.isBefore(end))
      .fold<int>(0, (sum, p) => sum + p.amountPkr);
  if (sumPayments > 0) return sumPayments;

  // Fallback: estimate revenue based on active subscriptions and plan price.
  final active = subscriptions.where((s) => _isActiveAt(s, end));
  return active.fold<int>(0, (sum, s) {
    final price = (planById[s.planId]?.price ?? 0).round();
    return sum + price;
  });
}

_SeriesResult _buildSeries({
  required DateTime now,
  required AnalyticsRange range,
  required List<PaymentRecord> payments,
  required List<SubscriptionRecord> subscriptions,
  required List<Academy> academies,
  required Map<String, Plan> planById,
}) {
  final buckets = switch (range) {
    AnalyticsRange.last7 => 7,
    AnalyticsRange.last30 => 30,
    AnalyticsRange.last3Months => 12,
    AnalyticsRange.last12Months => 12,
  };

  DateTime bucketStart(DateTime anchor, int i) {
    return switch (range) {
      AnalyticsRange.last12Months => DateTime(anchor.year, anchor.month - (buckets - 1 - i), 1),
      AnalyticsRange.last3Months => anchor.subtract(Duration(days: (buckets - 1 - i) * 7)),
      AnalyticsRange.last30 => anchor.subtract(Duration(days: (buckets - 1 - i))),
      AnalyticsRange.last7 => anchor.subtract(Duration(days: (buckets - 1 - i))),
    };
  }

  DateTime bucketEnd(DateTime start) {
    return switch (range) {
      AnalyticsRange.last12Months => DateTime(start.year, start.month + 1, 1),
      AnalyticsRange.last3Months => start.add(const Duration(days: 7)),
      AnalyticsRange.last30 => start.add(const Duration(days: 1)),
      AnalyticsRange.last7 => start.add(const Duration(days: 1)),
    };
  }

  final revenue = <double>[];
  final growth = <double>[];
  for (var i = 0; i < buckets; i++) {
    final bStart = bucketStart(now, i);
    final bEnd = bucketEnd(bStart);

    final r = _revenueInRange(
      payments: payments,
      subscriptions: subscriptions,
      planById: planById,
      start: bStart,
      end: bEnd,
    );
    revenue.add(r.toDouble());

    final g = academies.where((a) {
      final created = a.createdAt;
      if (created == null) return false;
      return !created.isBefore(bStart) && created.isBefore(bEnd);
    }).length;
    growth.add(g.toDouble());
  }

  // Ensure painters have at least 2 points.
  if (revenue.length < 2) revenue.add(0);
  if (growth.length < 2) growth.add(0);

  return _SeriesResult(revenue: revenue, growth: growth);
}

PlanDistribution _planDistribution(
  List<SubscriptionRecord> subs,
  Map<String, Plan> planById,
) {
  int basic = 0;
  int standard = 0;
  int premium = 0;
  for (final s in subs) {
    if (s.status != SubscriptionRecordStatus.active) continue;
    final plan = planById[s.planId];
    final name = (plan?.name ?? s.planId).toLowerCase();
    final price = plan?.price ?? 0;
    
    // Heuristics: Premium/Pro/Ultimate or high price
    if (name.contains('premium') || name.contains('pro') || name.contains('ultimate') || price >= 30000) {
      premium++;
    } 
    // Heuristics: Basic/Starter/Lite/Free or low price
    else if (name.contains('basic') || name.contains('starter') || name.contains('lite') || name.contains('free') || name.contains('demo') || (price > 0 && price < 15000)) {
      basic++;
    } 
    // Default to Standard
    else {
      standard++;
    }
  }
  final total = max(1, basic + standard + premium);
  int pct(int v) => ((v * 100) / total).round();
  final b = pct(basic);
  final s = pct(standard);
  final p = max(0, 100 - b - s);
  return PlanDistribution(basic: b, standard: s, premium: p);
}

List<TopInstituteRow> _topInstitutes({
  required DateTime now,
  required ({DateTime start, DateTime end}) window,
  required ({DateTime start, DateTime end}) prevWindow,
  required List<PaymentRecord> payments,
  required List<SubscriptionRecord> subscriptions,
  required Map<String, Academy> academyById,
  required Map<String, Plan> planById,
}) {
  final byAcademy = <String, int>{};
  for (final p in payments) {
    if (p.status != PaymentReviewStatus.approved) continue;
    if (p.createdAt.isBefore(window.start) || !p.createdAt.isBefore(window.end)) {
      continue;
    }
    byAcademy[p.academyId] = (byAcademy[p.academyId] ?? 0) + p.amountPkr;
  }

  // Fallback: if no payments, use plan price for active subs.
  if (byAcademy.isEmpty) {
    for (final s in subscriptions) {
      if (!_isActiveAt(s, now)) continue;
      byAcademy[s.academyId] = (planById[s.planId]?.price ?? 0).round();
    }
  }

  int revenuePrev(String academyId) {
    int sum = 0;
    for (final p in payments) {
      if (p.status != PaymentReviewStatus.approved) continue;
      if (p.academyId != academyId) continue;
      if (p.createdAt.isBefore(prevWindow.start) ||
          !p.createdAt.isBefore(prevWindow.end)) continue;
      sum += p.amountPkr;
    }
    return sum;
  }

  final rows = byAcademy.entries.map((e) {
    final academy = academyById[e.key];
    final name = academy?.name ?? e.key;
    final planName = planById[academy?.planId ?? '']?.name ??
        (academy?.planId ?? '—');
    final prev = revenuePrev(e.key);
    final growthPct = _pctValue(e.value, prev);
    return TopInstituteRow(
      name: name,
      revenuePkr: e.value,
      plan: planName.trim().isEmpty ? '—' : planName,
      growthPct: growthPct,
    );
  }).toList(growable: true)
    ..sort((a, b) => b.revenuePkr.compareTo(a.revenuePkr));

  return rows.take(6).toList(growable: false);
}

List<ExpiryRow> _upcomingExpiries({
  required DateTime now,
  required List<SubscriptionRecord> subscriptions,
  required Map<String, Academy> academyById,
  required Map<String, Plan> planById,
}) {
  final rows = <ExpiryRow>[];
  for (final s in subscriptions) {
    if (!_isActiveAt(s, now)) continue;
    final end = s.endDate;
    if (end == null) continue;
    final daysLeft = end.difference(now).inDays;
    if (daysLeft < 0 || daysLeft > 30) continue;
    final academy = academyById[s.academyId];
    final planName = planById[s.planId]?.name ?? s.planId;
    rows.add(
      ExpiryRow(
        name: academy?.name ?? s.academyId,
        plan: planName.trim().isEmpty ? '—' : planName,
        expiry: end,
        daysLeft: daysLeft,
      ),
    );
  }
  rows.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
  return rows.take(6).toList(growable: false);
}

String _pctTrend(int current, int previous) {
  if (previous <= 0) return current <= 0 ? '—' : '+100%';
  final diff = ((current - previous) / previous) * 100;
  final sign = diff >= 0 ? '+' : '';
  return '$sign${diff.toStringAsFixed(0)}%';
}

double _pctValue(int current, int previous) {
  if (previous <= 0) return current <= 0 ? 0 : 100;
  return ((current - previous) / previous) * 100;
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
