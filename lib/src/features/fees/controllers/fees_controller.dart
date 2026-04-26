import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/fee_service.dart';
import 'package:educore/src/core/services/feature_access_service.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeesController extends BaseController {
  final FeeService _feeService;
  final String _academyId;

  FeesController({FeeService? feeService})
    : _feeService = feeService ?? AppServices.instance.feeService!,
      _academyId = AppServices.instance.authService?.session?.academyId ?? '';

  List<Fee> _allFees = [];
  List<Fee> _filteredFees = [];
  List<Fee> get fees => _filteredFees;

  FeeType _currentType = FeeType.admission;
  FeeStatus? _currentStatus;

  FeeType get currentType => _currentType;
  FeeStatus? get currentStatus => _currentStatus;

  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;

  Map<String, dynamic> _stats = {
    'totalRevenue': 0.0,
    'totalPending': 0.0,
    'monthlyGrowth': 0.0,
  };
  Map<String, dynamic> get stats => _stats;

  Future<void> loadInitialData({FeeType? type, FeeStatus? status}) async {
    _currentType = type ?? _currentType;
    _currentStatus = status; // Allows null for "All"

    await runBusy(() async {
      try {
        _allFees = await _feeService.getFees(_academyId, type: _currentType);
        _applyFilters();
        await fetchStats();
      } catch (e) {
        debugPrint('Error loading fees: $e');
      }
    });
  }

  void _applyFilters() {
    if (_currentStatus == null) {
      _filteredFees = _allFees;
    } else {
      _filteredFees = _allFees
          .where((f) => f.status == _currentStatus)
          .toList();
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
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
    BuildContext context,
    String feeId,
    double amount, {
    PaymentMethod method = PaymentMethod.cash,
    String? note,
    bool showLoading = true,
  }) async {
    final featureSvc = AppServices.instance.featureAccessService!;
    final fee = _allFees.firstWhere((f) => f.id == feeId);

    // Feature & Validation Check
    if (!featureSvc.canAccess('fee_collect') ||
        amount <= 0 ||
        (amount < fee.remainingAmount &&
            !featureSvc.canAccess('fee_partial_payment'))) {
      debugPrint('Access Denied or Invalid Amount');
      return false;
    }

    final success = await runGuarded(
      () async {
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
      },
      context: context,
      loadingMessage: 'Recording Payment...',
      showLoading: showLoading,
    );

    return success == true;
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
    required BuildContext context,
    required String classId,
    required String month,
    double? amount,
    String? overrideReason,
    required String title,
    DateTime? dueDate,
  }) async {
    final featureSvc = AppServices.instance.featureAccessService!;
    if (!featureSvc.canAccess('fee_plan_manage')) return -1;

    final result = await runGuarded(
      () async {
        final userId = AppServices.instance.authService!.session!.user.uid;
        final count = await _feeService.generateMonthlyFees(
          _academyId,
          classId: classId,
          month: month,
          amount: amount,
          overrideReason: overrideReason,
          overriddenBy: userId,
          title: title,
          dueDate: dueDate,
        );
        await loadInitialData(type: FeeType.monthly);
        return count;
      },
      context: context,
      loadingMessage: 'Generating Fee Records...',
    );

    return result ?? -1;
  }

  Future<bool> createOtherFee(BuildContext context, Fee fee) async {
    final featureSvc = AppServices.instance.featureAccessService!;
    if (!featureSvc.canAccess('fee_manage')) return false;

    final success = await runGuarded(
      () async {
        await _feeService.createFee(_academyId, fee);
        await loadInitialData(type: FeeType.other);
        return true;
      },
      context: context,
      loadingMessage: 'Creating Fee Record...',
    );

    return success == true;
  }

  Future<void> sendWhatsAppReminder(BuildContext context, Fee fee) async {
    await runGuarded(
      () async {
        await AppServices.instance.whatsappService?.sendBulk(
          academyId: _academyId,
          messages: [
            {
              'to': fee
                  .studentId, // Note: studentId is used as recipient id/number in this app's context
              'message':
                  'Reminder: Fee for ${fee.title} of PKR ${fee.remainingAmount} is pending. Please pay by ${DateFormat.yMMMd().format(fee.dueDate ?? DateTime.now())}.',
            },
          ],
        );
        return true;
      },
      context: context,
      loadingMessage: 'Sending Reminder...',
    );
  }

  Future<void> sendWhatsAppMessage(
    BuildContext context,
    Fee fee,
    String message,
  ) async {
    await runGuarded(
      () async {
        await AppServices.instance.whatsappService?.sendBulk(
          academyId: _academyId,
          messages: [
            {'to': fee.studentId, 'message': message},
          ],
        );
        return true;
      },
      context: context,
      loadingMessage: 'Sending Message...',
    );
  }
}
