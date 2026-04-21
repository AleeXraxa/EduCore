import 'package:flutter/foundation.dart';
import 'package:educore/src/core/models/app_user.dart' as core_models;
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';
import 'package:educore/src/core/services/admin_users_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/plans/models/plan.dart';

class InstituteDetailsController extends BaseController {
  InstituteDetailsController({required this.academyId}) {
    _subsService = AppServices.instance.adminSubscriptionsService;
    _usersService = AppServices.instance.adminUsersService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;
    _attachOrInit();
  }

  final String academyId;

  AdminSubscriptionsService? _subsService;
  AdminUsersService? _usersService;
  PlanService? _planService;
  InstituteService? _instituteService;

  Academy? academy;
  SubscriptionRecord? subscription;
  Plan? plan;
  core_models.AppUser? instituteAdmin;

  String? errorMessage;

  bool get ready => _subsService != null;

  Future<void> retryInit() => _attachOrInit();

  Future<void> _attachOrInit() async {
    await runBusy<void>(() async {
      await AppServices.instance.init();
      
      _subsService = AppServices.instance.adminSubscriptionsService;
      _usersService = AppServices.instance.adminUsersService;
      _planService = AppServices.instance.planService;
      _instituteService = AppServices.instance.instituteService;

      if (_subsService == null) {
        errorMessage = AppServices.instance.firebaseInitError?.toString();
        return;
      }

      await loadData();
    });
  }

  Future<void> loadData() async {
    try {
      final academyIdLocal = academyId;
      
      // Fetch core details in parallel
      final results = await Future.wait([
        _instituteService!.getAcademy(academyIdLocal),
        _subsService!.getSubscription(academyIdLocal),
        _usersService!.getUsersBatch(academyId: academyIdLocal, limit: 10),
      ]);

      academy = results[0] as Academy?;
      subscription = results[1] as SubscriptionRecord?;
      final users = results[2] as List<core_models.AppUser>;

      // Find admin
      instituteAdmin = users.cast<core_models.AppUser?>().firstWhere(
        (u) => u?.role == core_models.AppUserRole.instituteAdmin,
        orElse: () => null,
      );

      // Fetch plan if subscription exists
      if (subscription != null) {
        plan = await _planService!.getPlan(subscription!.planId);
      }

      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Institute details load error: $e');
      notifyListeners();
    }
  }
}
