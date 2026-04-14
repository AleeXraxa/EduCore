import 'dart:async';

import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/plans/models/plan.dart';

class PlansController extends BaseController {
  PlansController() {
    _service = AppServices.instance.planService;
    _featureService = AppServices.instance.featureService;
    _attachOrInit();
  }

  PlanService? _service;
  FeatureService? _featureService;
  StreamSubscription<List<Plan>>? _sub;
  StreamSubscription? _featureSub;

  List<Plan> plans = const [];
  List<String> registryKeys = const [];
  String? errorMessage;

  bool get ready => _service != null;
  int get totalPlans => plans.length;
  int get activePlans => plans.where((e) => e.isActive).length;

  List<String> get allFeatureKeys {
    if (registryKeys.isNotEmpty) return registryKeys;
    final keys = <String>{};
    for (final plan in plans) {
      keys.addAll(plan.features);
    }
    return keys.toList(growable: false);
  }

  Future<void> createPlan(Plan draft) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.createPlan(
        name: draft.name,
        price: draft.price,
        description: draft.description,
        isActive: draft.isActive,
        features: draft.features,
        limits: draft.limits.isEmpty ? null : draft.limits,
      );
    });
  }

  Future<void> updatePlan(Plan plan) async {
    final svc = await _ensureService();
    await runBusy<void>(() async {
      await svc.updatePlan(
        planId: plan.id,
        name: plan.name,
        price: plan.price,
        description: plan.description,
        isActive: plan.isActive,
        features: plan.features,
        limits: plan.limits.isEmpty ? null : plan.limits,
      );
    });
  }

  Future<void> setActive(String id, bool value) async {
    final svc = await _ensureService();
    await runBusy<void>(() => svc.setActive(id, value));
  }

  Future<void> softDelete(String id) async {
    final svc = await _ensureService();
    await runBusy<void>(() => svc.softDeletePlan(id));
  }

  Future<void> toggleFeature(String id, String key, bool enabled) async {
    final svc = await _ensureService();
    await runBusy<void>(
      () => svc.toggleFeature(planId: id, featureKey: key, enabled: enabled),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _featureSub?.cancel();
    super.dispose();
  }

  Future<void> retryInit() => _attachOrInit();

  void _attach(PlanService svc) {
    if (_service == svc && _sub != null) return;
    _service = svc;
    _sub?.cancel();
    _sub = svc.watchPlans().listen((value) {
      plans = value;
      errorMessage = null;
      notifyListeners();
    }, onError: (e) {
      errorMessage = e.toString();
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _attachOrInit() async {
    if (_service != null) {
      _attach(_service!);
      return;
    }

    // Attempt to initialize Firebase lazily if needed.
    await runBusy<void>(() async {
      await AppServices.instance.init();
    });

    final svc = AppServices.instance.planService;
    final featureSvc = AppServices.instance.featureService;
    if (svc != null) {
      _attach(svc);
    } else {
      errorMessage = AppServices.instance.firebaseInitError?.toString();
      notifyListeners();
    }

    if (featureSvc != null) {
      _attachFeatures(featureSvc);
    }
  }

  Future<PlanService> _ensureService() async {
    final existing = _service ?? AppServices.instance.planService;
    if (existing != null) {
      if (_service != existing) _attach(existing);
      return existing;
    }

    await _attachOrInit();
    final svc = _service ?? AppServices.instance.planService;
    if (svc == null) {
      throw StateError('Firestore is not ready.');
    }
    return svc;
  }

  void _attachFeatures(FeatureService svc) {
    if (_featureService == svc && _featureSub != null) return;
    _featureService = svc;
    _featureSub?.cancel();
    _featureSub = svc.watchFeatures().listen((value) {
      registryKeys = value
          .map((f) => f.key)
          .where((k) => k.trim().isNotEmpty)
          .toList(growable: false);
      notifyListeners();
    }, onError: (e) {
      errorMessage = e.toString();
      notifyListeners();
    });
  }
}
