import 'dart:async';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/features/institutes/models/institute.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';

enum FeatureAccessState {
  planControlled,
  overrideEnabled,
  overrideDisabled,
}

class FeatureAccessControlController extends BaseController {
  FeatureAccessControlController() {
    _loadInitialData();
  }

  // --- State ---
  List<Institute> institutes = [];
  Institute? selectedInstitute;
  SubscriptionRecord? subscription;
  Plan? plan;
  List<FeatureFlag> allFeatures = [];
  
  // Local Working Copy of Overrides
  Set<String> draftEnabled = {};
  Set<String> draftDisabled = {};

  bool isSaving = false;

  // --- View Methods ---

  Future<void> _loadInitialData() async {
    await runBusy<void>(() async {
      final repo = AppServices.instance.instituteRepository!;
      final featSvc = AppServices.instance.featureService!;

      // 1. Get all features
      allFeatures = await featSvc.watchFeatures().first;
      
      // 2. Get first batch of institutes for selector
      institutes = await repo.getInstitutesBatch(limit: 100);
    });
  }

  Future<void> selectInstitute(Institute institute) async {
    selectedInstitute = institute;
    subscription = null;
    plan = null;
    draftEnabled = {};
    draftDisabled = {};
    notifyListeners();

    await runBusy<void>(() async {
      final subSvc = AppServices.instance.adminSubscriptionsService!;
      final planSvc = AppServices.instance.planService!;

      // 1. Fetch Subscription
      subscription = await subSvc.getSubscription(institute.id);
      
      if (subscription != null) {
        // 2. Fetch Plan
        plan = await planSvc.getPlan(subscription!.planId);
        
        // 3. Populate Drafts
        draftEnabled = subscription!.overrides.enabled.toSet();
        draftDisabled = subscription!.overrides.disabled.toSet();
      }
    });
  }

  FeatureAccessState getFeatureState(String key) {
    if (draftEnabled.contains(key)) return FeatureAccessState.overrideEnabled;
    if (draftDisabled.contains(key)) return FeatureAccessState.overrideDisabled;
    return FeatureAccessState.planControlled;
  }

  bool isEffectiveEnabled(String key) {
    final state = getFeatureState(key);
    if (state == FeatureAccessState.overrideEnabled) return true;
    if (state == FeatureAccessState.overrideDisabled) return false;
    // Plan default
    return plan?.features.contains(key) ?? false;
  }

  void toggleFeature(String key) {
    final currentState = getFeatureState(key);
    final planDefault = plan?.features.contains(key) ?? false;

    // Logic:
    // If Plan Controlled (Off) -> Override Enabled
    // If Plan Controlled (On) -> Override Disabled
    // If Override Enabled -> Override Disabled
    // If Override Disabled -> Reset to Plan Controlled

    if (currentState == FeatureAccessState.planControlled) {
      if (planDefault) {
        draftDisabled.add(key);
      } else {
        draftEnabled.add(key);
      }
    } else if (currentState == FeatureAccessState.overrideEnabled) {
      draftEnabled.remove(key);
      draftDisabled.add(key);
    } else if (currentState == FeatureAccessState.overrideDisabled) {
      draftDisabled.remove(key);
      // Reset back to plan default (no override)
    }
    
    notifyListeners();
  }

  void resetToPlan(String key) {
    draftEnabled.remove(key);
    draftDisabled.remove(key);
    notifyListeners();
  }

  void resetAll() {
    draftEnabled = {};
    draftDisabled = {};
    notifyListeners();
  }

  Future<bool> saveChanges() async {
    if (selectedInstitute == null) return false;
    
    isSaving = true;
    notifyListeners();

    try {
      final subSvc = AppServices.instance.adminSubscriptionsService!;
      await subSvc.updateOverrides(
        selectedInstitute!.id,
        enabled: draftEnabled.toList(),
        disabled: draftDisabled.toList(),
      );

      // Refresh global middleware
      await AppServices.instance.featureAccessService?.refresh();
      
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Grouped Features Helper
  Map<String, List<FeatureFlag>> get groupedFeatures {
    final map = <String, List<FeatureFlag>>{};
    for (final f in allFeatures) {
      if (!f.isActive) continue;
      final group = f.group;
      if (!map.containsKey(group)) map[group] = [];
      map[group]!.add(f);
    }
    return map;
  }
}
