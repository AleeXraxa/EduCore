import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/fee_plan_service.dart';
import 'package:educore/src/core/services/feature_access_service.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';

class FeePlansController extends BaseController {
  final FeePlanService _feePlanService;
  final FeatureAccessService _featureAccess;
  final String _academyId;

  FeePlansController({
    FeePlanService? feePlanService,
    FeatureAccessService? featureAccessService,
  }) : _feePlanService = feePlanService ?? AppServices.instance.feePlanService!,
       _featureAccess = featureAccessService ?? AppServices.instance.featureAccessService!,
       _academyId = AppServices.instance.authService?.session?.academyId ?? '';

  List<FeePlan> _plans = [];
  List<FeePlan> get plans => _plans;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get canCreate => _featureAccess.canAccess('fee_plan_create');
  bool get canEdit => _featureAccess.canAccess('fee_plan_edit');
  bool get canDelete => _featureAccess.canAccess('fee_plan_delete');
  bool get canView => _featureAccess.canAccess('fee_plan_view');

  Future<void> fetchPlans() async {
    if (!canView) return;
    await runBusy(() async {
      try {
        _plans = await _feePlanService.getFeePlans(_academyId);
        _errorMessage = null;
      } catch (e) {
        _errorMessage = 'Failed to load fee plans: $e';
      }
    });
  }

  Future<bool> createPlan({
    required String name,
    required String description,
    required String scope,
    String? classId,
    required double admissionFee,
    double monthlyFee = 0.0,
    int monthlyDueDay = 5,
    double totalCourseFee = 0.0,
    int? durationMonths,
    bool allowInstallments = false,
    int? installmentCount,
    FeePlanType planType = FeePlanType.monthly,
    double? lateFeePerDay,
    required bool allowPartialPayment,
  }) async {
    if (!canCreate) return false;
    
    bool success = false;
    await runBusy(() async {
      try {
        final userId = AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _feePlanService.createFeePlan(
          academyId: _academyId,
          name: name,
          description: description,
          scope: scope,
          classId: classId,
          admissionFee: admissionFee,
          monthlyFee: monthlyFee,
          monthlyDueDay: monthlyDueDay,
          totalCourseFee: totalCourseFee,
          durationMonths: durationMonths,
          allowInstallments: allowInstallments,
          installmentCount: installmentCount,
          planType: planType,
          lateFeePerDay: lateFeePerDay,
          allowPartialPayment: allowPartialPayment,
          performedBy: userId,
        );
        success = true;
        await fetchPlans();
      } catch (e) {
        _errorMessage = e.toString();
      }
    });
    return success;
  }

  Future<bool> updatePlan(String planId, Map<String, dynamic> updates) async {
    if (!canEdit) return false;
    
    bool success = false;
    await runBusy(() async {
      try {
        final userId = AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _feePlanService.updateFeePlan(
          academyId: _academyId,
          planId: planId,
          updates: updates,
          performedBy: userId,
        );
        success = true;
        await fetchPlans();
      } catch (e) {
        _errorMessage = e.toString();
      }
    });
    return success;
  }

  Future<bool> deletePlan(String planId) async {
    if (!canDelete) return false;
    
    bool success = false;
    await runBusy(() async {
      try {
        final userId = AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _feePlanService.deleteFeePlan(_academyId, planId, userId);
        success = true;
        await fetchPlans();
      } catch (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    });
    return success;
  }
}
