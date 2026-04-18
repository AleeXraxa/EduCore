import 'package:flutter/foundation.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/fees/models/fee.dart';
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

  Future<void> loadInitialData() async {
    await runBusy(() async {
      await Future.wait([
        fetchFees(),
        fetchStats(),
      ]);
    });
  }

  Future<void> fetchFees({
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
      );

      // Hydrate with names for intuitive UI rendering.
      // Load classes unconditionally as there are usually very few
      final classList = await AppServices.instance.classService!.getClasses(_academyId);
      final classMap = { for (var c in classList) c.id: c.displayName };

      // Load students to stitch names securely
      // Limiting drastically reduces fetching overkill for now
      final studentSnapshot = await AppServices.instance.studentService!.getStudentsBatch(
        academyId: _academyId, 
        limit: 1000 // In extreme environments, we'd batch by IDs instead
      );
      final studentMap = { 
        for (var doc in studentSnapshot.docs) 
          doc.id: doc.data()['name'] as String? 
      };

      _fees = fetchedFees.map((fee) {
        return fee.copyWith(
          className: fee.className ?? classMap[fee.classId],
          studentName: fee.studentName ?? studentMap[fee.studentId],
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching fees: $e');
    }
  }

  Future<void> fetchStats() async {
    try {
      _stats = await _feeService.getFeeStats(_academyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<bool> collectPayment(String feeId, double amount) async {
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

    return await runBusy(() async {
      try {
        await _feeService.collectPayment(_academyId, feeId: feeId, paymentAmount: amount);
        await loadInitialData(); // Refresh everything
        return true;
      } catch (e) {
        debugPrint('Error collecting payment: $e');
        return false;
      }
    });
  }

  Future<bool> generateMonthlyFees({
    required String classId,
    required String month,
    required double amount,
    required String title,
    DateTime? dueDate,
  }) async {
    if (!AppServices.instance.featureAccessService!.canAccess('fee_monthly_generate')) {
      return false;
    }

    return await runBusy(() async {
      try {
        await _feeService.generateMonthlyFees(
          _academyId,
          classId: classId,
          month: month,
          amount: amount,
          title: title,
          dueDate: dueDate,
        );
        await loadInitialData();
        return true;
      } catch (e) {
        debugPrint('Error generating monthly fees: $e');
        return false;
      }
    });
  }

  Future<bool> createOtherFee(Fee fee) async {
    if (!AppServices.instance.featureAccessService!.canAccess('fee_create')) {
      return false;
    }

    return await runBusy(() async {
      try {
        await _feeService.createFee(_academyId, fee);
        await loadInitialData();
        return true;
      } catch (e) {
        debugPrint('Error creating other fee: $e');
        return false;
      }
    });
  }
}
