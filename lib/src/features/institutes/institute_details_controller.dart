import 'dart:async';

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

  StreamSubscription<SubscriptionRecord?>? _subSub;
  StreamSubscription<List<core_models.AppUser>>? _usersSub;
  StreamSubscription<Academy?>? _academySub;
  StreamSubscription<Plan>? _planSub;

  Academy? academy;
  SubscriptionRecord? subscription;
  Plan? plan;
  core_models.AppUser? instituteAdmin;

  String? errorMessage;

  bool get ready => _subsService != null;

  @override
  void dispose() {
    _subSub?.cancel();
    _usersSub?.cancel();
    _academySub?.cancel();
    _planSub?.cancel();
    super.dispose();
  }

  Future<void> retryInit() => _attachOrInit();

  Future<void> _attachOrInit() async {
    if (_subsService != null) {
      _attach();
      return;
    }

    await runBusy<void>(() async {
      await AppServices.instance.init();
    });

    _subsService = AppServices.instance.adminSubscriptionsService;
    _usersService = AppServices.instance.adminUsersService;
    _planService = AppServices.instance.planService;
    _instituteService = AppServices.instance.instituteService;

    if (_subsService == null) {
      errorMessage = AppServices.instance.firebaseInitError?.toString();
      notifyListeners();
      return;
    }

    _attach();
  }

  void _attach() {
    final subsSvc = _subsService;
    if (subsSvc != null) _attachSubscription(subsSvc);

    final userSvc = _usersService;
    if (userSvc != null) _attachUsers(userSvc);

    final instSvc = _instituteService;
    if (instSvc != null) _attachAcademy(instSvc);
  }

  void _attachSubscription(AdminSubscriptionsService svc) {
    _subSub?.cancel();
    _subSub = svc.watchSubscription(academyId).listen(
      (value) {
        subscription = value;
        errorMessage = null;
        _attachPlanForSubscription();
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        // ignore: avoid_print
        print('Institute details subscription error: $e');
        notifyListeners();
      },
    );
  }

  void _attachPlanForSubscription() {
    final planSvc = _planService ?? AppServices.instance.planService;
    final planId = subscription?.planId ?? '';
    if (planSvc == null || planId.trim().isEmpty) {
      _planSub?.cancel();
      plan = null;
      return;
    }

    if (plan?.id == planId) return;
    _planSub?.cancel();
    _planSub = planSvc.watchPlan(planId).listen(
      (p) {
        plan = p;
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Institute details plan error: $e');
      },
    );
  }

  void _attachUsers(AdminUsersService svc) {
    _usersSub?.cancel();
    _usersSub = svc.watchUsersForAcademy(academyId).listen(
      (users) {
        core_models.AppUser? admin;
        for (final u in users) {
          if (u.role == core_models.AppUserRole.instituteAdmin) {
            admin = u;
            break;
          }
        }
        instituteAdmin = admin;
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Institute details users error: $e');
      },
    );
  }

  void _attachAcademy(InstituteService svc) {
    _academySub?.cancel();
    _academySub = svc.watchAcademy(academyId).listen(
      (value) {
        academy = value;
        notifyListeners();
      },
      onError: (e) {
        // ignore: avoid_print
        print('Institute details academy error: $e');
      },
    );
  }
}
