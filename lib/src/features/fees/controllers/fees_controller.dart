import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/fees/models/fee_record.dart';
import 'package:educore/src/features/fees/services/fees_service.dart';

class FeesController extends BaseController {
  final FeesService _feesService = FeesService(AppServices.instance.firestore!);

  List<FeeRecord> _allFees = [];
  FeeType currentType = FeeType.monthly;
  FeeStatus? statusFilter;

  List<FeeRecord> get filteredFees {
    return _allFees.where((f) => f.type == currentType).toList();
  }

  double get totalCollected {
    return filteredFees
        .where((f) => f.status == FeeStatus.paid)
        .fold(0, (sum, f) => sum + f.amount);
  }

  double get totalPending {
    return filteredFees
        .where((f) => f.status == FeeStatus.pending)
        .fold(0, (sum, f) => sum + f.amount);
  }

  Future<void> loadFees() async {
    await runBusy(() async {
      final academyId = AppServices.instance.authService?.session?.academyId;
      if (academyId == null) return;
      
      _allFees = await _feesService.getFees(academyId: academyId);
    });
  }

  void setFeeType(FeeType type) {
    currentType = type;
    notifyListeners();
  }

  Future<void> collectFee(String feeId) async {
    await runBusy(() async {
      final academyId = AppServices.instance.authService?.session?.academyId;
      if (academyId == null) return;
      
      await _feesService.updateFeeStatus(academyId, feeId, FeeStatus.paid);
      await loadFees();
    });
  }

  Future<String?> createAdmissionFee({
    required String studentId,
    required String studentName,
    required double amount,
    String? className,
  }) async {
    return _createFee(FeeRecord(
      id: '',
      studentId: studentId,
      studentName: studentName,
      amount: amount,
      type: FeeType.admission,
      status: FeeStatus.pending,
      createdAt: DateTime.now(),
      className: className,
    ));
  }

  Future<String?> createMonthlyFee({
    required String studentId,
    required String studentName,
    required double amount,
    required String month,
    String? className,
  }) async {
    return _createFee(FeeRecord(
      id: '',
      studentId: studentId,
      studentName: studentName,
      amount: amount,
      type: FeeType.monthly,
      status: FeeStatus.pending,
      createdAt: DateTime.now(),
      month: month,
      className: className,
    ));
  }

  Future<String?> createMiscFee({
    required String title,
    required String description,
    required double amount,
    String? studentId,
    String? studentName,
  }) async {
    return _createFee(FeeRecord(
      id: '',
      studentId: studentId ?? 'N/A',
      studentName: studentName ?? title,
      amount: amount,
      type: FeeType.misc,
      status: FeeStatus.pending,
      createdAt: DateTime.now(),
      description: description,
    ));
  }

  Future<String?> _createFee(FeeRecord fee) async {
    try {
      final academyId = AppServices.instance.authService?.session?.academyId;
      if (academyId == null) return 'Session expired';

      await _feesService.createFee(academyId: academyId, fee: fee);
      await loadFees();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
