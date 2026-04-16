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
    _subsService = AppServices.instance.adminSubscriptionsService;
    _paymentsService = AppServices.instance.adminPaymentsService;
    _usersService = AppServices.instance.adminUsersService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;
    _attachOrInit();
  }

  AdminSubscriptionsService? _subsService;
  AdminPaymentsService? _paymentsService;
  AdminUsersService? _usersService;
  PlanService? _planService;
  InstituteService? _instituteService;

  StreamSubscription<List<SubscriptionRecord>>? _subsSub;
  StreamSubscription<List<PaymentRecord>>? _paymentsSub;
  StreamSubscription? _usersSub;
  StreamSubscription<List<Plan>>? _plansSub;
  StreamSubscription<List<Academy>>? _academiesSub;

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

  @override
  void dispose() {
    _subsSub?.cancel();
    _paymentsSub?.cancel();
    _usersSub?.cancel();
    _plansSub?.cancel();
    _academiesSub?.cancel();
    super.dispose();
  }

  Future<void> retryInit() => _attachOrInit();

  Future<void> _attachOrInit() async {
    if (_subsService != null) {
      _attachAll();
      return;
    }

    await runBusy<void>(() async {
      await AppServices.instance.init();
    });

    _subsService = AppServices.instance.adminSubscriptionsService;
    _paymentsService = AppServices.instance.adminPaymentsService;
    _usersService = AppServices.instance.adminUsersService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;

    if (_subsService == null) {
      errorMessage = AppServices.instance.firebaseInitError?.toString();
      notifyListeners();
      return;
    }

    _attachAll();
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

    // Users not currently rendered, but fetching keeps door open for future KPIs.
    final userSvc = _usersService;
    if (userSvc != null && _usersSub == null) {
      _usersSub = userSvc.watchUsers().listen(
        (_) {},
        onError: (e) {
          // ignore: avoid_print
          print('Users stream error: $e');
        },
      );
    }
  }

  void _attachSubscriptions(AdminSubscriptionsService svc) {
    if (_subsService == svc && _subsSub != null) return;
    _subsService = svc;
    _subsSub?.cancel();
    _subsSub = svc.watchSubscriptions().listen(
      (value) {
        _subscriptions = value;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        // ignore: avoid_print
        print('Dashboard subscriptions error: $e');
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
        _payments = value;
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Dashboard payments error: $e');
      },
    );
  }

  void _attachPlans(PlanService svc) {
    if (_planService == svc && _plansSub != null) return;
    _planService = svc;
    _plansSub?.cancel();
    _plansSub = svc.watchPlans().listen(
      (items) {
        final map = <String, Plan>{};
        for (final p in items) {
          map[p.id] = p;
        }
        _planById = map;
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Dashboard plans error: $e');
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
        final map = <String, Academy>{};
        for (final a in items) {
          map[a.id] = a;
        }
        _academyById = map;
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Dashboard academies error: $e');
      },
    );
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

