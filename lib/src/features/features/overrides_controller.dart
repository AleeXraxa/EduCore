import 'dart:async';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/features/models/feature_overrides.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:flutter/material.dart';

class FeatureOverridesController extends ChangeNotifier {
  FeatureOverridesController() {
    _init();
  }

  final _overrideService = AppServices.instance.featureOverrideService;
  final _instituteService = AppServices.instance.instituteService;
  final _featureService = AppServices.instance.featureService;
  final _planService = AppServices.instance.planService;
  final _adminSubService = AppServices.instance.adminSubscriptionsService;

  List<Academy> _academies = [];
  List<Academy> get academies => _academies;

  List<FeatureFlag> _allFeatures = [];
  List<FeatureFlag> get allFeatures => _allFeatures;

  Academy? _selectedAcademy;
  Academy? get selectedAcademy => _selectedAcademy;

  Plan? _activePlan;
  Plan? get activePlan => _activePlan;

  FeatureOverrides _overrides = const FeatureOverrides();
  FeatureOverrides get overrides => _overrides;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  StreamSubscription? _academiesSub;
  StreamSubscription? _featuresSub;

  void _init() {
    _academiesSub = _instituteService?.watchAcademies().listen((data) {
      _academies = data;
      notifyListeners();
    });

    _featuresSub = _featureService?.watchFeatures().listen((data) {
      _allFeatures = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> selectAcademy(Academy? academy) async {
    _selectedAcademy = academy;
    if (academy == null) {
      _activePlan = null;
      _overrides = const FeatureOverrides();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch current subscription for planId
      final sub = await _adminSubService?.getSubscription(academy.id);
      if (sub != null) {
        _overrides = sub.overrides;
        if (sub.planId.isNotEmpty) {
          _activePlan = await _planService?.getPlan(sub.planId);
        } else {
          _activePlan = null;
        }
      } else {
        _overrides = const FeatureOverrides();
        _activePlan = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFeature(String key, bool? enable) {
    final newEnabled = List<String>.from(_overrides.enabled);
    final newDisabled = List<String>.from(_overrides.disabled);

    // Remove from both first to reset
    newEnabled.remove(key);
    newDisabled.remove(key);

    if (enable == true) {
      newEnabled.add(key);
    } else if (enable == false) {
      newDisabled.add(key);
    }
    // if null -> reset to plan default (removed from both)

    _overrides = FeatureOverrides(enabled: newEnabled, disabled: newDisabled);
    notifyListeners();
  }

  Future<void> saveChanges() async {
    if (_selectedAcademy == null || _isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      await _overrideService?.updateOverrides(
        academyId: _selectedAcademy!.id,
        enabled: _overrides.enabled,
        disabled: _overrides.disabled,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  bool isFeatureInPlan(String key) {
    return _activePlan?.features.contains(key) ?? false;
  }

  @override
  void dispose() {
    _academiesSub?.cancel();
    _featuresSub?.cancel();
    super.dispose();
  }
}
