import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/repositories/payment_repository.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';

enum PaymentsFilter { all, pending, approved, rejected }

enum PaymentMethodFilter { all, jazzCash, easyPaisa, bank }

class PaymentsController extends BaseController {
  PaymentsController() {
    _repository = AppServices.instance.paymentRepository;
    _instituteService = AppServices.instance.instituteService;
    _subscriptionService = AppServices.instance.adminSubscriptionsService;
    _init();
  }

  PaymentRepository? _repository;
  InstituteService? _instituteService;
  AdminSubscriptionsService? _subscriptionService;

  final List<PaymentRecord> _all = [];
  Map<String, String> _instituteNames = {};
  
  // State
  String _query = '';
  PaymentsFilter _filter = PaymentsFilter.all;
  PaymentMethodFilter _methodFilter = PaymentMethodFilter.all;

  // Pagination State
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 50;

  bool get ready => _repository != null;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  List<PaymentRecord> get list => _all;

  Future<void> _init() async {
    if (_repository == null) {
      await runBusy<void>(() async {
        await AppServices.instance.init();
      });
      _repository = AppServices.instance.paymentRepository;
      _instituteService = AppServices.instance.instituteService;
    }
    await refresh();
  }

  Future<void> retryInit() => _init();

  Future<void> refresh() async {
    _lastDoc = null;
    _hasMore = true;
    _all.clear();
    
    await runBusy<void>(() async {
      await _fetchNextBatch();
    });
    await _fetchInstitutesIfNeeded();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      await _fetchNextBatch();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNextBatch() async {
    if (_repository == null) return;

    try {
      final statusVal = switch (_filter) {
        PaymentsFilter.all => 'all',
        PaymentsFilter.pending => 'pending',
        PaymentsFilter.approved => 'approved',
        PaymentsFilter.rejected => 'rejected',
      };

      final methodVal = switch (_methodFilter) {
        PaymentMethodFilter.all => 'all',
        PaymentMethodFilter.jazzCash => 'jazzCash',
        PaymentMethodFilter.easyPaisa => 'easyPaisa',
        PaymentMethodFilter.bank => 'bankTransfer',
      };

      final results = await _repository!.getPaymentsBatch(
        limit: _pageSize,
        lastDoc: _lastDoc,
        status: statusVal,
        method: methodVal,
      );

      if (results.length < _pageSize) {
        _hasMore = false;
      }

      if (results.isNotEmpty) {
        // Fetch cursor doc
        final lastPayment = results.last;
        final lastDocSnap = await FirebaseFirestore.instance.collection('payments').doc(lastPayment.id).get();
        _lastDoc = lastDocSnap;
        
        _all.addAll(results);
      }
      notifyListeners();
    } catch (e) {
      _hasMore = false;
    }
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

  PaymentsKpis get kpis {
    // Note: Since we only have a partial list in _all, real kpis should come from a metadata doc.
    // For now, these operate on the LOADED dataset.
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
    notifyListeners();
  }

  void setFilter(PaymentsFilter value) {
    _filter = value;
    unawaited(refresh());
  }

  void setMethodFilter(PaymentMethodFilter value) {
    _methodFilter = value;
    unawaited(refresh());
  }

  Future<void> approve(String id) async {
    final p = _all.firstWhere((e) => e.id == id);
    final sub = await _subscriptionService?.getSubscription(p.academyId);
    final duration = sub?.durationMonths ?? 1;

    if (_repository == null) return;

    await _repository!.updatePaymentStatus(
      id,
      status: 'approved',
      reviewerUid: AppServices.instance.authService!.currentUser!.uid,
      extra: {
        'planId': p.planId,
        'durationMonths': duration,
      },
    );
    
    // Local update
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _all[idx] = _all[idx].copyWith(status: PaymentReviewStatus.approved);
      notifyListeners();
    }
  }

  Future<void> reject(String id) async {
    if (_repository == null) return;
    await _repository!.updatePaymentStatus(
      id,
      status: 'rejected',
      reviewerUid: AppServices.instance.authService!.currentUser!.uid,
    );
    
    // Local update
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _all[idx] = _all[idx].copyWith(status: PaymentReviewStatus.rejected);
      notifyListeners();
    }
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
