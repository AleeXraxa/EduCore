import 'dart:async';

import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/features/subscriptions/models/subscription.dart';

enum SubscriptionsFilter { all, active, expired, pending, canceled }

class SubscriptionsController extends BaseController {
  SubscriptionsController() {
    _service = AppServices.instance.adminSubscriptionsService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;
    _attachOrInit();
  }

  AdminSubscriptionsService? _service;
  PlanService? _planService;
  InstituteService? _instituteService;

  StreamSubscription<List<SubscriptionRecord>>? _sub;
  StreamSubscription<List<Plan>>? _plansSub;
  StreamSubscription<List<Academy>>? _academiesSub;

  List<SubscriptionRecord> _raw = const [];
  Map<String, Plan> _planById = const <String, Plan>{};
  Map<String, Academy> _academyById = const <String, Academy>{};

  final List<Subscription> _all = <Subscription>[];
  String _query = '';
  SubscriptionsFilter _filter = SubscriptionsFilter.all;
  String _planIdFilter = 'all';

  int _page = 0;
  final int pageSize = 20;

  String? errorMessage;

  bool get ready => _service != null;

  String get query => _query;
  SubscriptionsFilter get filter => _filter;
  String get planIdFilter => _planIdFilter;
  int get page => _page;

  List<String> get planIds {
    final ids = <String>{..._planById.keys};
    final list = ids.toList(growable: true);
    list.sort((a, b) => planNameForId(a).compareTo(planNameForId(b)));
    list.insert(0, 'all');
    return list;
  }

  String planNameForId(String id) {
    if (id == 'all') return 'All plans';
    return _planById[id]?.name ?? id;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _plansSub?.cancel();
    _academiesSub?.cancel();
    super.dispose();
  }

  Future<void> retryInit() => _attachOrInit();

  Future<void> _attachOrInit() async {
    if (_service != null) {
      _attach(_service!);
      final planSvc = _planService ?? AppServices.instance.planService;
      final instSvc = _instituteService ?? AppServices.instance.instituteService;
      if (planSvc != null) _attachPlans(planSvc);
      if (instSvc != null) _attachAcademies(instSvc);
      return;
    }

    await runBusy<void>(() async {
      await AppServices.instance.init();
    });

    _service = AppServices.instance.adminSubscriptionsService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;

    final svc = _service;
    if (svc != null) {
      _attach(svc);
    } else {
      errorMessage = AppServices.instance.firebaseInitError?.toString();
      notifyListeners();
      return;
    }

    final planSvc = _planService;
    if (planSvc != null) _attachPlans(planSvc);
    final instSvc = _instituteService;
    if (instSvc != null) _attachAcademies(instSvc);
  }

  Future<AdminSubscriptionsService> _ensureService() async {
    final existing =
        _service ?? AppServices.instance.adminSubscriptionsService;
    if (existing != null) {
      if (_service != existing) _attach(existing);
      return existing;
    }

    await _attachOrInit();
    final svc = _service ?? AppServices.instance.adminSubscriptionsService;
    if (svc == null) throw StateError('Firestore is not ready.');
    return svc;
  }

  void _attach(AdminSubscriptionsService svc) {
    if (_service == svc && _sub != null) return;
    _service = svc;
    _sub?.cancel();
    _sub = svc.watchSubscriptions().listen(
      (value) {
        _raw = value;
        errorMessage = null;
        _rebuild();
      },
      onError: (e) {
        errorMessage = e.toString();
        // ignore: avoid_print
        print('Subscriptions stream error: $e');
        notifyListeners();
      },
    );
    notifyListeners();
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
        _rebuild();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Plans stream error: $e');
      },
    );
  }

  void _attachAcademies(InstituteService svc) {
    if (_instituteService == svc && _academiesSub != null) return;
    _instituteService = svc;
    _academiesSub?.cancel();
    _academiesSub = svc.watchAcademies().listen(
      (items) {
        final map = <String, Academy>{};
        for (final a in items) {
          map[a.id] = a;
        }
        _academyById = map;
        _rebuild();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Academies stream error: $e');
      },
    );
  }

  void _rebuild() {
    _all
      ..clear()
      ..addAll(_raw.map(_mapToUi));

    if (_planIdFilter != 'all' && !_planById.containsKey(_planIdFilter)) {
      _planIdFilter = 'all';
    }

    if (_page > 0) {
      final maxPage = ((totalCount - 1) / pageSize).floor();
      if (_page > maxPage) _page = maxPage.clamp(0, maxPage);
    }

    notifyListeners();
  }

  Subscription _mapToUi(SubscriptionRecord record) {
    final academyId = record.academyId.trim().isNotEmpty
        ? record.academyId.trim()
        : record.academyId;
    final academy = _academyById[academyId];
    final instituteName = academy?.name ?? academyId;

    final plan = _planById[record.planId];
    final planName = plan?.name ?? (record.planId.trim().isEmpty ? '—' : record.planId);
    final amount = (plan?.price ?? 0).round();

    final status = switch (record.status) {
      SubscriptionRecordStatus.active => SubscriptionStatus.active,
      SubscriptionRecordStatus.expired => SubscriptionStatus.expired,
      SubscriptionRecordStatus.canceled => SubscriptionStatus.canceled,
      SubscriptionRecordStatus.pending => SubscriptionStatus.pendingApproval,
    };

    final start = record.startDate ?? record.createdAt ?? DateTime.now();
    final end = record.endDate ?? start.add(const Duration(days: 30));

    final payment = switch (status) {
      SubscriptionStatus.active => PaymentStatus.paid,
      SubscriptionStatus.pendingApproval => PaymentStatus.proofSubmitted,
      SubscriptionStatus.expired => PaymentStatus.unpaid,
      SubscriptionStatus.canceled => PaymentStatus.rejected,
    };

    return Subscription(
      id: academyId,
      instituteId: academyId,
      instituteName: instituteName,
      planId: record.planId,
      planName: planName,
      status: status,
      startDate: start,
      expiryDate: end,
      amountPkr: amount,
      paymentStatus: payment,
    );
  }

  List<Subscription> get filtered {
    final q = _query.trim().toLowerCase();
    Iterable<Subscription> list = _all;

    if (_filter != SubscriptionsFilter.all) {
      final status = switch (_filter) {
        SubscriptionsFilter.active => SubscriptionStatus.active,
        SubscriptionsFilter.expired => SubscriptionStatus.expired,
        SubscriptionsFilter.pending => SubscriptionStatus.pendingApproval,
        SubscriptionsFilter.canceled => SubscriptionStatus.canceled,
        SubscriptionsFilter.all => SubscriptionStatus.active,
      };
      list = list.where((e) => e.status == status);
    }

    if (_planIdFilter != 'all') {
      list = list.where((e) => e.planId == _planIdFilter);
    }

    if (q.isNotEmpty) {
      list = list.where((e) => e.instituteName.toLowerCase().contains(q));
    }

    return list.toList(growable: false);
  }

  int get totalCount => filtered.length;

  List<Subscription> get paged {
    final start = _page * pageSize;
    final list = filtered;
    if (start >= list.length) return const [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  void setQuery(String value) {
    _query = value;
    _page = 0;
    notifyListeners();
  }

  void setFilter(SubscriptionsFilter value) {
    _filter = value;
    _page = 0;
    notifyListeners();
  }

  void setPlanIdFilter(String value) {
    _planIdFilter = value;
    _page = 0;
    notifyListeners();
  }

  void nextPage() {
    final maxPage = ((totalCount - 1) / pageSize).floor();
    if (_page >= maxPage) return;
    _page += 1;
    notifyListeners();
  }

  void prevPage() {
    if (_page <= 0) return;
    _page -= 1;
    notifyListeners();
  }

  Future<void> approve(String academyId) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      final now = DateTime.now();
      await svc.updateSubscription(
        academyId,
        status: 'active',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        setEndDate: true,
      );
    });
  }

  Future<void> reject(String academyId) async {
    final svc = await _ensureService();
    await runBusy<void>(() => svc.updateSubscription(academyId, status: 'canceled'));
  }

  Future<void> cancel(String academyId) async {
    final svc = await _ensureService();
    await runBusy<void>(() => svc.updateSubscription(academyId, status: 'canceled'));
  }

  Future<void> extend30Days(String academyId) async {
    final svc = await _ensureService();
    await runBusy<void>(() => svc.extendByDays(academyId, 30));
  }

  Future<void> changePlan(String academyId, String planId) async {
    final svc = await _ensureService();
    await runBusy<void>(() => svc.updateSubscription(academyId, planId: planId));
  }

  SubscriptionKpis get kpis {
    final total = _all.length;
    final active = _all.where((e) => e.status == SubscriptionStatus.active).length;
    final expired = _all.where((e) => e.status == SubscriptionStatus.expired).length;
    final monthRevenue = _all
        .where((e) => e.status == SubscriptionStatus.active && e.paymentStatus == PaymentStatus.paid)
        .fold<int>(0, (sum, e) => sum + e.amountPkr);
    return SubscriptionKpis(
      total: total,
      active: active,
      expired: expired,
      monthRevenuePkr: monthRevenue,
    );
  }

  // Mock dataset kept for quick UX testing without Firestore.
  // ignore: unused_element
  void _seedMock() {
    final now = DateTime.now();
    _all.addAll([
      Subscription(
        id: 's1',
        instituteId: 'gv',
        instituteName: 'Green Valley Academy',
        planId: 'standard',
        planName: 'Standard',
        status: SubscriptionStatus.active,
        startDate: now.subtract(const Duration(days: 9)),
        expiryDate: now.add(const Duration(days: 21)),
        amountPkr: 18000,
        paymentStatus: PaymentStatus.paid,
      ),
      Subscription(
        id: 's2',
        instituteId: 'cs',
        instituteName: 'City School – North Campus',
        planId: 'premium',
        planName: 'Premium',
        status: SubscriptionStatus.pendingApproval,
        startDate: now,
        expiryDate: now.add(const Duration(days: 30)),
        amountPkr: 32000,
        paymentStatus: PaymentStatus.proofSubmitted,
      ),
      Subscription(
        id: 's3',
        instituteId: 'ap',
        instituteName: 'Apex Institute',
        planId: 'basic',
        planName: 'Basic',
        status: SubscriptionStatus.expired,
        startDate: now.subtract(const Duration(days: 64)),
        expiryDate: now.subtract(const Duration(days: 4)),
        amountPkr: 12000,
        paymentStatus: PaymentStatus.paid,
      ),
      Subscription(
        id: 's4',
        instituteId: 'sr',
        instituteName: 'Sunrise School',
        planId: 'standard',
        planName: 'Standard',
        status: SubscriptionStatus.canceled,
        startDate: now.subtract(const Duration(days: 18)),
        expiryDate: now.add(const Duration(days: 12)),
        amountPkr: 18000,
        paymentStatus: PaymentStatus.rejected,
      ),
    ]);

    for (var i = 1; i <= 36; i++) {
      final status = i % 9 == 0
          ? SubscriptionStatus.pendingApproval
          : (i % 7 == 0
              ? SubscriptionStatus.expired
              : (i % 11 == 0 ? SubscriptionStatus.canceled : SubscriptionStatus.active));
      final (planId, planName, amount) = switch (i % 3) {
        0 => ('premium', 'Premium', 32000),
        1 => ('standard', 'Standard', 18000),
        _ => ('basic', 'Basic', 12000),
      };
      final start = now.subtract(Duration(days: 5 + i * 2));
      final expiry = status == SubscriptionStatus.expired
          ? now.subtract(Duration(days: i % 6))
          : now.add(Duration(days: 2 + (i * 2) % 40));
      final payment = status == SubscriptionStatus.pendingApproval
          ? PaymentStatus.proofSubmitted
          : (status == SubscriptionStatus.canceled ? PaymentStatus.rejected : PaymentStatus.paid);

      _all.add(
        Subscription(
          id: 'seed_sub_$i',
          instituteId: 'seed_$i',
          instituteName: 'Institute ${i.toString().padLeft(2, '0')}',
          planId: planId,
          planName: planName,
          status: status,
          startDate: start,
          expiryDate: expiry,
          amountPkr: amount,
          paymentStatus: payment,
        ),
      );
    }
  }
}

class SubscriptionKpis {
  const SubscriptionKpis({
    required this.total,
    required this.active,
    required this.expired,
    required this.monthRevenuePkr,
  });

  final int total;
  final int active;
  final int expired;
  final int monthRevenuePkr;
}
