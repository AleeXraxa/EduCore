import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/subscriptions/models/subscription.dart';

enum SubscriptionsFilter { all, active, expired, pending, canceled }

class SubscriptionsController extends BaseController {
  final List<Subscription> _all = <Subscription>[];
  String _query = '';
  SubscriptionsFilter _filter = SubscriptionsFilter.all;
  InstitutePlan? _planFilter;

  int _page = 0;
  final int pageSize = 20;

  SubscriptionsController() {
    _seedMock();
  }

  String get query => _query;
  SubscriptionsFilter get filter => _filter;
  InstitutePlan? get planFilter => _planFilter;
  int get page => _page;

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

    if (_planFilter != null) {
      list = list.where((e) => e.plan == _planFilter);
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

  void setPlanFilter(InstitutePlan? plan) {
    _planFilter = plan;
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

  void approve(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _all[idx];
    final now = DateTime.now();
    _all[idx] = Subscription(
      id: cur.id,
      instituteId: cur.instituteId,
      instituteName: cur.instituteName,
      plan: cur.plan,
      status: SubscriptionStatus.active,
      startDate: now,
      expiryDate: now.add(const Duration(days: 30)),
      amountPkr: cur.amountPkr,
      paymentStatus: PaymentStatus.paid,
    );
    notifyListeners();
  }

  void reject(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _all[idx];
    _all[idx] = Subscription(
      id: cur.id,
      instituteId: cur.instituteId,
      instituteName: cur.instituteName,
      plan: cur.plan,
      status: SubscriptionStatus.canceled,
      startDate: cur.startDate,
      expiryDate: cur.expiryDate,
      amountPkr: cur.amountPkr,
      paymentStatus: PaymentStatus.rejected,
    );
    notifyListeners();
  }

  void cancel(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _all[idx];
    _all[idx] = Subscription(
      id: cur.id,
      instituteId: cur.instituteId,
      instituteName: cur.instituteName,
      plan: cur.plan,
      status: SubscriptionStatus.canceled,
      startDate: cur.startDate,
      expiryDate: cur.expiryDate,
      amountPkr: cur.amountPkr,
      paymentStatus: cur.paymentStatus,
    );
    notifyListeners();
  }

  void extend30Days(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _all[idx];
    _all[idx] = Subscription(
      id: cur.id,
      instituteId: cur.instituteId,
      instituteName: cur.instituteName,
      plan: cur.plan,
      status: SubscriptionStatus.active,
      startDate: cur.startDate,
      expiryDate: cur.expiryDate.add(const Duration(days: 30)),
      amountPkr: cur.amountPkr,
      paymentStatus: cur.paymentStatus,
    );
    notifyListeners();
  }

  void changePlan(String id, InstitutePlan plan) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _all[idx];
    _all[idx] = Subscription(
      id: cur.id,
      instituteId: cur.instituteId,
      instituteName: cur.instituteName,
      plan: plan,
      status: cur.status,
      startDate: cur.startDate,
      expiryDate: cur.expiryDate,
      amountPkr: cur.amountPkr,
      paymentStatus: cur.paymentStatus,
    );
    notifyListeners();
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

  void _seedMock() {
    final now = DateTime.now();
    _all.addAll([
      Subscription(
        id: 's1',
        instituteId: 'gv',
        instituteName: 'Green Valley Academy',
        plan: InstitutePlan.standard,
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
        plan: InstitutePlan.premium,
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
        plan: InstitutePlan.basic,
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
        plan: InstitutePlan.standard,
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
      final plan = i % 3 == 0
          ? InstitutePlan.premium
          : (i % 3 == 1 ? InstitutePlan.standard : InstitutePlan.basic);
      final amount = plan == InstitutePlan.basic
          ? 12000
          : (plan == InstitutePlan.standard ? 18000 : 32000);
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
          plan: plan,
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

