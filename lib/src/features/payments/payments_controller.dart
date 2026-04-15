import 'dart:async';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/admin_payments_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';

enum PaymentsFilter { all, pending, approved, rejected }

enum PaymentMethodFilter { all, jazzCash, easyPaisa, bank }

class PaymentsController extends BaseController {
  PaymentsController() {
    _paymentService = AppServices.instance.adminPaymentsService;
    _instituteService = AppServices.instance.instituteService;
    _subscriptionService = AppServices.instance.adminSubscriptionsService;
    _init();
  }

  AdminPaymentsService? _paymentService;
  InstituteService? _instituteService;
  AdminSubscriptionsService? _subscriptionService;
  StreamSubscription? _sub;

  List<PaymentRecord> _all = [];
  Map<String, String> _instituteNames = {};
  
  String _query = '';
  PaymentsFilter _filter = PaymentsFilter.all;
  PaymentMethodFilter _methodFilter = PaymentMethodFilter.all;

  int _page = 0;
  int get page => _page;
  final int pageSize = 20;

  void _init() {
    if (_paymentService == null) return;
    _sub = _paymentService!.watchPayments().listen((data) {
      _all = data.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _fetchInstitutesIfNeeded();
      notifyListeners();
    });
  }

  Future<void> _fetchInstitutesIfNeeded() async {
    if (_instituteService == null) return;
    final academies = await _instituteService!.getAcademies();
    _instituteNames = {
      for (final a in academies) a.id: a.name,
    };
    notifyListeners();
  }

  String getInstituteName(String id) => _instituteNames[id] ?? 'Loading...';

  List<PaymentRecord> get filtered {
    final q = _query.trim().toLowerCase();
    Iterable<PaymentRecord> list = _all;

    if (_filter != PaymentsFilter.all) {
      final status = switch (_filter) {
        PaymentsFilter.pending => PaymentReviewStatus.pending,
        PaymentsFilter.approved => PaymentReviewStatus.approved,
        PaymentsFilter.rejected => PaymentReviewStatus.rejected,
        _ => PaymentReviewStatus.pending,
      };
      list = list.where((e) => e.status == status);
    }

    if (_methodFilter != PaymentMethodFilter.all) {
      final method = switch (_methodFilter) {
        PaymentMethodFilter.jazzCash => PaymentMethod.jazzCash,
        PaymentMethodFilter.easyPaisa => PaymentMethod.easyPaisa,
        PaymentMethodFilter.bank => PaymentMethod.bankTransfer,
        _ => PaymentMethod.bankTransfer,
      };
      list = list.where((e) => e.method == method);
    }

    if (q.isNotEmpty) {
      list = list.where((e) {
        final name = getInstituteName(e.academyId).toLowerCase();
        return name.contains(q);
      });
    }

    return list.toList(growable: false);
  }

  int get totalCount => filtered.length;

  List<PaymentRecord> get paged {
    final start = _page * pageSize;
    final list = filtered;
    if (start >= list.length) return const [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  PaymentsKpis get kpis {
    final pending = _all.where((e) => e.status == PaymentReviewStatus.pending).length;
    final approved = _all.where((e) => e.status == PaymentReviewStatus.approved).length;
    final monthRevenue = _all
        .where((e) => e.status == PaymentReviewStatus.approved)
        .fold<int>(0, (sum, e) => sum + e.amountPkr);

    return PaymentsKpis(
      total: _all.length,
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

  Future<void> approve(String id) async {
    final p = _all.firstWhere((e) => e.id == id);
    final sub = await _subscriptionService?.getSubscription(p.academyId);
    
    // Default to 1 month if not specified in sub (unlikely but safe)
    final duration = sub?.durationMonths ?? 1;

    await _paymentService?.approvePayment(
      paymentId: id,
      academyId: p.academyId,
      planId: p.planId,
      durationMonths: duration,
      reviewerUid: AppServices.instance.authService!.currentUser!.uid,
    );
  }

  Future<void> reject(String id) async {
    await _paymentService?.rejectPayment(
      id,
      AppServices.instance.authService!.currentUser!.uid,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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

