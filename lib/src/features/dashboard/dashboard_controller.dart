import 'dart:async';

import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/admin_payments_service.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';
import 'package:educore/src/core/services/admin_users_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/plans/models/plan.dart';

class DashboardKpis {
  const DashboardKpis({
    required this.totalInstitutes,
    required this.activeSubscriptions,
    required this.monthlyRevenuePkr,
    required this.pendingPayments,
  });

  final int totalInstitutes;
  final int activeSubscriptions;
  final int monthlyRevenuePkr;
  final int pendingPayments;
}

class DashboardActivityItem {
  const DashboardActivityItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String kind; // used for icon mapping
  final String title;
  final String subtitle;
  final DateTime time;
}

class DashboardPendingPaymentItem {
  const DashboardPendingPaymentItem({
    required this.instituteName,
    required this.amountPkr,
    required this.status,
    required this.createdAt,
  });

  final String instituteName;
  final int amountPkr;
  final PaymentReviewStatus status;
  final DateTime createdAt;
}

class DashboardController extends BaseController {
  DashboardController() {
    _onInit();
  }

  void _onInit() => loadDashboard();

  AdminSubscriptionsService? _subsService;
  AdminPaymentsService? _paymentsService;
  PlanService? _planService;
  InstituteService? _instituteService;

  List<SubscriptionRecord> _subscriptions = const [];
  List<PaymentRecord> _payments = const [];
  List<Academy> _academies = const [];
  Map<String, Plan> _planById = const <String, Plan>{};
  Map<String, Academy> _academyById = const <String, Academy>{};

  String? errorMessage;

  bool get ready => _subsService != null;

  DashboardKpis get kpis {
    final totalInstitutes = _academies.length;
    final activeSubscriptions = _subscriptions
        .where((s) => s.status == SubscriptionRecordStatus.active)
        .length;

    final monthlyRevenue = _subscriptions
        .where((s) => s.status == SubscriptionRecordStatus.active)
        .fold<int>(0, (sum, s) {
      final plan = _planById[s.planId];
      final price = plan?.price ?? 0;
      return sum + price.round();
    });

    final pendingPayments =
        _payments.where((p) => p.status == PaymentReviewStatus.pending).length;

    return DashboardKpis(
      totalInstitutes: totalInstitutes,
      activeSubscriptions: activeSubscriptions,
      monthlyRevenuePkr: monthlyRevenue,
      pendingPayments: pendingPayments,
    );
  }

  List<double> get revenueHistory {
    if (_subscriptions.isEmpty && _payments.isEmpty) return const [0, 0, 0, 0, 0, 0];
    
    // Simple 6-month historical view
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - i, 1)).reversed.toList();
    
    return months.map((m) {
      final monthlySum = _subscriptions
          .where((s) => s.status == SubscriptionRecordStatus.active)
          .where((s) {
            final start = s.createdAt ?? s.updatedAt ?? now;
            return start.isBefore(DateTime(m.year, m.month + 1, 1));
          })
          .fold<double>(0.0, (sum, s) {
            final plan = _planById[s.planId];
            return sum + (plan?.price ?? 0.0);
          });
      return monthlySum / 1000.0; // Show in thousands for the chart scale
    }).toList();
  }

  List<double> get growthHistory {
    if (_academies.isEmpty) return const [0, 0, 0, 0, 0, 0];
    
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - i, 1)).reversed.toList();
    
    return months.map((m) {
      final count = _academies.where((a) {
        final created = a.createdAt ?? now;
        return created.isBefore(DateTime(m.year, m.month + 1, 1));
      }).length;
      return count.toDouble();
    }).toList();
  }

  List<DashboardPendingPaymentItem> get pendingPaymentsTop {
    final items = _payments
        .where((p) => p.status == PaymentReviewStatus.pending)
        .take(6)
        .map((p) {
      final name = _academyById[p.academyId]?.name;
      return DashboardPendingPaymentItem(
        instituteName: (name?.trim().isNotEmpty == true) ? name!.trim() : p.academyId,
        amountPkr: p.amountPkr,
        status: p.status,
        createdAt: p.createdAt,
      );
    }).toList(growable: false);
    return items;
  }

  List<DashboardActivityItem> get recentActivity {
    final items = <DashboardActivityItem>[];

    for (final a in _academies.take(5)) {
      final time = a.createdAt ?? DateTime.now();
      final planName = _planById[a.planId]?.name ?? (a.planId.isEmpty ? '—' : a.planId);
      items.add(
        DashboardActivityItem(
          kind: 'academy_created',
          title: 'Institute created',
          subtitle: '${a.name} • $planName',
          time: time,
        ),
      );
    }

    for (final s in _subscriptions.take(6)) {
      final time = s.updatedAt ?? s.createdAt ?? DateTime.now();
      final academyName = _academyById[s.academyId]?.name ?? s.academyId;
      final planName = _planById[s.planId]?.name ?? (s.planId.isEmpty ? '—' : s.planId);
      final statusLabel = switch (s.status) {
        SubscriptionRecordStatus.active => 'Active',
        SubscriptionRecordStatus.pending => 'Pending approval',
        SubscriptionRecordStatus.expired => 'Expired',
        SubscriptionRecordStatus.canceled => 'Canceled',
      };
      items.add(
        DashboardActivityItem(
          kind: 'subscription',
          title: 'Subscription $statusLabel',
          subtitle: '$academyName • $planName',
          time: time,
        ),
      );
    }

    for (final p in _payments.where((p) => p.status == PaymentReviewStatus.pending).take(4)) {
      final academyName = _academyById[p.academyId]?.name ?? p.academyId;
      items.add(
        DashboardActivityItem(
          kind: 'payment_pending',
          title: 'Payment submitted',
          subtitle: '$academyName • PKR ${_fmtInt(p.amountPkr)}',
          time: p.createdAt,
        ),
      );
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(3).toList(growable: false);
  }

  Future<void> loadDashboard({bool isRefresh = false}) async {
    // Note: local runBusy does not support isQuiet, so we always show busy state for now.
    // In a more advanced BaseController we could add silent load support.
    await runBusy<void>(() async {
      await AppServices.instance.init();
      
      _subsService = AppServices.instance.adminSubscriptionsService;
      _paymentsService = AppServices.instance.adminPaymentsService;
      _planService = AppServices.instance.planService;
      _instituteService = AppServices.instance.instituteService;

      if (_subsService == null) {
        errorMessage = AppServices.instance.firebaseInitError?.toString();
        return;
      }

      // Fetch all required data in parallel once.
      // Capped for safety to prevent huge reads on dashboard.
      final results = await Future.wait([
        _subsService!.getSubscriptionsBatch(limit: 50),
        _paymentsService!.getPaymentsBatch(limit: 50),
        _planService!.getPlans(), // Plans are usually few
        _instituteService!.getAcademies(limit: 100),
      ]);

      _subscriptions = results[0] as List<SubscriptionRecord>;
      _payments = results[1] as List<PaymentRecord>;
      final plans = results[2] as List<Plan>;
      _academies = results[3] as List<Academy>;

      // Map patterns for O(1) lookups
      final pMap = <String, Plan>{};
      for (final p in plans) { pMap[p.id] = p; }
      _planById = pMap;

      final aMap = <String, Academy>{};
      for (final a in _academies) { aMap[a.id] = a; }
      _academyById = aMap;

      errorMessage = null;
    });
  }

  Future<void> retryInit() => loadDashboard();

  Future<void> refresh() => loadDashboard(isRefresh: true);

  @override
  void dispose() {
    // No streams to cancel anymore!
    super.dispose();
  }
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

