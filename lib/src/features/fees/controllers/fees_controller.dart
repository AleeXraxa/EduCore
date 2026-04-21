import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/core/services/fee_service.dart';

class FeesController extends BaseController {
  final FeeService _feeService;
  final String _academyId;

  FeesController({FeeService? feeService})
      : _feeService = feeService ?? AppServices.instance.feeService!,
        _academyId = AppServices.instance.authService!.session!.academyId;

  List<Fee> _fees = [];
  List<Fee> get fees => _fees;

  Map<String, dynamic> _stats = {
    'totalRevenue': 0.0,
    'totalPending': 0.0,
    'typeDistribution': <String, double>{},
  };
  Map<String, dynamic> get stats => _stats;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 20;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  FeeType? _currentType;
  FeeStatus? _currentStatus;

  FeeType? get currentType => _currentType;
  FeeStatus? get currentStatus => _currentStatus;

  Future<void> loadInitialData({FeeType? type, FeeStatus? status}) async {
    _currentType = type ?? _currentType;
    _currentStatus = status ?? _currentStatus;
    _lastDoc = null;
    _hasMore = true;
    _fees = [];
    
    await runBusy(() async {
      await Future.wait([
        _fetchFeesBatch(type: _currentType, status: _currentStatus),
        fetchStats(),
      ]);
    });
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await _fetchFeesBatch(type: _currentType, status: _currentStatus);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFeesBatch({
    String? studentId,
    String? classId,
    FeeType? type,
    FeeStatus? status,
  }) async {
    try {
      final fetchedFees = await _feeService.getFees(
        _academyId,
        studentId: studentId,
        classId: classId,
        type: type,
        status: status,
        limit: _pageSize,
        startAfter: _lastDoc,
      );

      if (fetchedFees.length < _pageSize) {
        _hasMore = false;
      }

      if (fetchedFees.isNotEmpty) {
        // Update cursor
        final lastFee = fetchedFees.last;
        _lastDoc = await FirebaseFirestore.instance
            .collection('academies')
            .doc(_academyId)
            .collection('fees')
            .doc(lastFee.id)
            .get();

        _fees.addAll(fetchedFees);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching fees batch: $e');
      _hasMore = false;
    }
  }

  /// Legacy fetch - wrapper around batch for compatibility
  @Deprecated('Use loadInitialData or loadMore')
  Future<void> fetchFees({
    String? studentId,
    String? classId,
    FeeType? type,
    FeeStatus? status,
  }) async {
    _lastDoc = null;
    _hasMore = true;
    _fees = [];
    await _fetchFeesBatch(
      studentId: studentId,
      classId: classId,
      type: type,
      status: status,
    );
  }

  Future<void> fetchStats() async {
    try {
      _stats = await _feeService.getFeeStats(_academyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<bool> collectPayment(
    String feeId, 
    double amount, {
    PaymentMethod method = PaymentMethod.cash,
    String? note,
  }) async {
    final featureSvc = AppServices.instance.featureAccessService!;
    
    // Feature Check
    if (!featureSvc.canAccess('fee_collect')) {
      debugPrint('Access Denied: fee_collect');
      return false;
    }

    // Partial Payment Restriction Check
    if (amount <= 0) return false;
    
    final fee = _fees.firstWhere((f) => f.id == feeId);
    if (amount < fee.remainingAmount && !featureSvc.canAccess('fee_partial_payment')) {
      debugPrint('Access Denied: fee_partial_payment');
      return false;
    }

    return (await runBusy(() async {
      try {
        final userId = AppServices.instance.authService!.session!.user.uid;
        await _feeService.collectPayment(
          _academyId, 
          feeId: feeId, 
          paymentAmount: amount,
          method: method,
          collectedBy: userId,
          note: note,
        );
        await loadInitialData(); // Refresh everything
        return true;
      } catch (e) {
        debugPrint('Error collecting payment: $e');
        setError(e.toString());
        return false;
      }
    })) ?? false;
  }

  Future<List<FeeTransaction>> getFeeTransactions(String feeId) async {
    try {
      return await _feeService.getTransactions(_academyId, feeId);
    } catch (e) {
      debugPrint('Error fetching fee transactions: $e');
      return [];
    }
  }

  Future<int> generateMonthlyFees({
    required String classId,
    required String month,
    double? amount,
    String? overrideReason,
    required String title,
    DateTime? dueDate,
  }) async {
    final featureSvc = AppServices.instance.featureAccessService!;
    if (!featureSvc.canAccess('fee_monthly_generate')) {
      return -1;
    }

    return (await runBusy(() async {
      try {
        final count = await _feeService.generateMonthlyFees(
          _academyId,
          classId: classId,
          month: month,
          amount: amount,
          overrideReason: overrideReason,
          overriddenBy: AppServices.instance.authService!.session!.user.uid,
          title: title,
          dueDate: dueDate,
        );
        
        await loadInitialData();
        return count;
      } catch (e) {
        debugPrint('Error generating monthly fees: $e');
        return -1;
      }
    })) ?? -1;
  }

  Future<bool> createOtherFee(Fee fee) async {
    if (!AppServices.instance.featureAccessService!.canAccess('fee_create')) {
      return false;
    }

    return (await runBusy(() async {
      try {
        await _feeService.createFee(_academyId, fee);
        await loadInitialData();
        return true;
      } catch (e) {
        debugPrint('Error creating other fee: $e');
        return false;
      }
    })) ?? false;
  }
}
