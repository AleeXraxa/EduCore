import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/payments/models/payment.dart';

enum PaymentsFilter { all, pending, approved, rejected }

enum PaymentMethodFilter { all, jazzCash, easyPaisa, bank }

class PaymentsController extends BaseController {
  final List<Payment> _all = <Payment>[];
  String _query = '';
  PaymentsFilter _filter = PaymentsFilter.all;
  PaymentMethodFilter _methodFilter = PaymentMethodFilter.all;

  int _page = 0;
  final int pageSize = 20;

  PaymentsController() {
    _seedMock();
  }

  String get query => _query;
  PaymentsFilter get filter => _filter;
  PaymentMethodFilter get methodFilter => _methodFilter;
  int get page => _page;

  List<Payment> get filtered {
    final q = _query.trim().toLowerCase();
    Iterable<Payment> list = _all;

    if (_filter != PaymentsFilter.all) {
      final status = switch (_filter) {
        PaymentsFilter.pending => PaymentReviewStatus.pending,
        PaymentsFilter.approved => PaymentReviewStatus.approved,
        PaymentsFilter.rejected => PaymentReviewStatus.rejected,
        PaymentsFilter.all => PaymentReviewStatus.pending,
      };
      list = list.where((e) => e.status == status);
    }

    if (_methodFilter != PaymentMethodFilter.all) {
      final method = switch (_methodFilter) {
        PaymentMethodFilter.jazzCash => PaymentMethod.jazzCash,
        PaymentMethodFilter.easyPaisa => PaymentMethod.easyPaisa,
        PaymentMethodFilter.bank => PaymentMethod.bankTransfer,
        PaymentMethodFilter.all => PaymentMethod.jazzCash,
      };
      list = list.where((e) => e.method == method);
    }

    if (q.isNotEmpty) {
      list = list.where((e) => e.instituteName.toLowerCase().contains(q));
    }

    return list.toList(growable: false);
  }

  int get totalCount => filtered.length;

  List<Payment> get paged {
    final start = _page * pageSize;
    final list = filtered;
    if (start >= list.length) return const [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  PaymentsKpis get kpis {
    final total = _all.length;
    final pending = _all.where((e) => e.status == PaymentReviewStatus.pending).length;
    final approved = _all.where((e) => e.status == PaymentReviewStatus.approved).length;
    final monthRevenue = _all
        .where((e) => e.status == PaymentReviewStatus.approved)
        .fold<int>(0, (sum, e) => sum + e.amountPkr);

    return PaymentsKpis(
      total: total,
      pending: pending,
      approved: approved,
      monthRevenuePkr: monthRevenue,
    );
  }

  void setQuery(String value) {
    _query = value;
    _page = 0;
    notifyListeners();
  }

  void setFilter(PaymentsFilter value) {
    _filter = value;
    _page = 0;
    notifyListeners();
  }

  void setMethodFilter(PaymentMethodFilter value) {
    _methodFilter = value;
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
    _all[idx] = Payment(
      id: cur.id,
      instituteId: cur.instituteId,
      instituteName: cur.instituteName,
      amountPkr: cur.amountPkr,
      method: cur.method,
      submittedAt: cur.submittedAt,
      status: PaymentReviewStatus.approved,
      proofRef: cur.proofRef,
    );
    notifyListeners();
  }

  void reject(String id) {
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _all[idx];
    _all[idx] = Payment(
      id: cur.id,
      instituteId: cur.instituteId,
      instituteName: cur.instituteName,
      amountPkr: cur.amountPkr,
      method: cur.method,
      submittedAt: cur.submittedAt,
      status: PaymentReviewStatus.rejected,
      proofRef: cur.proofRef,
    );
    notifyListeners();
  }

  void _seedMock() {
    final now = DateTime.now();
    _all.addAll([
      Payment(
        id: 'p1',
        instituteId: 'gv',
        instituteName: 'Green Valley Academy',
        amountPkr: 18000,
        method: PaymentMethod.jazzCash,
        submittedAt: now.subtract(const Duration(hours: 2)),
        status: PaymentReviewStatus.pending,
        proofRef: 'proof_gv_01',
      ),
      Payment(
        id: 'p2',
        instituteId: 'cs',
        instituteName: 'City School – North Campus',
        amountPkr: 32000,
        method: PaymentMethod.bankTransfer,
        submittedAt: now.subtract(const Duration(days: 1, hours: 3)),
        status: PaymentReviewStatus.approved,
        proofRef: 'proof_cs_02',
      ),
      Payment(
        id: 'p3',
        instituteId: 'sr',
        instituteName: 'Sunrise School',
        amountPkr: 18000,
        method: PaymentMethod.easyPaisa,
        submittedAt: now.subtract(const Duration(days: 2, hours: 6)),
        status: PaymentReviewStatus.rejected,
        proofRef: 'proof_sr_03',
      ),
    ]);

    for (var i = 1; i <= 40; i++) {
      final status = i % 7 == 0
          ? PaymentReviewStatus.rejected
          : (i % 4 == 0 ? PaymentReviewStatus.approved : PaymentReviewStatus.pending);
      final method = i % 3 == 0
          ? PaymentMethod.bankTransfer
          : (i % 3 == 1 ? PaymentMethod.jazzCash : PaymentMethod.easyPaisa);
      final amount = method == PaymentMethod.bankTransfer ? 32000 : 18000;
      _all.add(
        Payment(
          id: 'seed_pay_$i',
          instituteId: 'seed_$i',
          instituteName: 'Institute ${i.toString().padLeft(2, '0')}',
          amountPkr: amount,
          method: method,
          submittedAt: now.subtract(Duration(hours: 4 + i * 6)),
          status: status,
          proofRef: 'proof_seed_$i',
        ),
      );
    }

    // Recent first.
    _all.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }
}

class PaymentsKpis {
  const PaymentsKpis({
    required this.total,
    required this.pending,
    required this.approved,
    required this.monthRevenuePkr,
  });

  final int total;
  final int pending;
  final int approved;
  final int monthRevenuePkr;
}

