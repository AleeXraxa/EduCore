import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/core/services/subscription_service.dart';

class FeatureAccessService {
  FeatureAccessService({
    required FeatureService featureService,
    required PlanService planService,
    required SubscriptionService subscriptionService,
  }) : _featureService = featureService,
       _planService = planService,
       _subscriptionService = subscriptionService;

  final FeatureService _featureService;
  final PlanService _planService;
  final SubscriptionService _subscriptionService;

  String? _currentAcademyId;
  bool _isSuperAdmin = false;
  Set<String> _allowedFeatures = {};
  bool _initialized = false;

  final StreamController<Set<String>> _accessStream =
      StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get accessStream => _accessStream.stream;

  bool get isInitialized => _initialized;

  void setSuperAdmin(bool value) {
    _isSuperAdmin = value;
    if (value) {
      _accessStream.add(_allowedFeatures);
    }
  }

  Future<void> init(String academyId, {bool isSuperAdmin = false}) async {
    _currentAcademyId = academyId;
    _isSuperAdmin = isSuperAdmin;
    await _load();
    _initialized = true;
    _accessStream.add(_allowedFeatures);
  }

  bool canAccess(String featureKey) {
    if (_isSuperAdmin) {
      debugPrint('FeatureAccess: $featureKey ALLOWED (Super Admin Bypass)');
      return true;
    }

    if (!_initialized) {
      debugPrint(
        'Warning: FeatureAccessService not initialized. Defaulting to FALSE for $featureKey',
      );
      return false;
    }

    final allowed = _allowedFeatures.contains(featureKey);
    debugPrint(
      'FeatureAccess: $featureKey -> ${allowed ? 'ALLOWED' : 'DENIED'}',
    );
    return allowed;
  }

  /// Returns the current list of allowed feature keys.
  List<String> getAllowedFeatures() => _allowedFeatures.toList();

  /// Forces a reload from source.
  Future<void> refresh() async {
    if (_currentAcademyId != null) {
      await _load();
      _accessStream.add(_allowedFeatures);
    }
  }

  Future<void> _load() async {
    try {
      // 1. Load Registry (Always needed to know what features exist)
      final registry = await _featureService.watchFeatures().first;
      final activeInRegistry = registry
          .where((f) => f.isActive)
          .map((f) => f.key)
          .toSet();

      // OPTION: Super Admin bypass
      if (_isSuperAdmin) {
        _allowedFeatures = activeInRegistry;
        debugPrint(
          'FeatureAccess: Super Admin identified. All active features allowed.',
        );
        return;
      }

      if (_currentAcademyId == null || _currentAcademyId!.isEmpty) {
        _allowedFeatures = {};
        return;
      }

      // 2. Load Subscription & Overrides
      final subscription = await _subscriptionService
          .watchSubscription(_currentAcademyId!)
          .first;

      // 3. Load Plan Default Features
      Set<String> planFeatures = {};
      if (subscription?.planId != null && subscription!.planId.isNotEmpty) {
        final plan = await _planService.getPlan(subscription.planId);
        if (plan != null) {
          planFeatures = plan.features.toSet();
        }
      }

      // 4. Calculate Effective Access
      final allowed = <String>{};
      final overrides = subscription?.overrides;

      for (final key in activeInRegistry) {
        // Priority 1: disabled override
        if (overrides != null && overrides.isDisabled(key)) {
          continue;
        }

        // Priority 2: enabled override
        if (overrides != null && overrides.isEnabled(key)) {
          allowed.add(key);
          continue;
        }

        // Priority 3: plan default
        if (planFeatures.contains(key)) {
          allowed.add(key);
        }
      }

      _allowedFeatures = allowed;
      debugPrint(
        'FeatureAccess initialized for $_currentAcademyId: $_allowedFeatures',
      );
    } catch (e) {
      debugPrint('Error loading feature access: $e');
      _allowedFeatures = {};
    }
  }

  /// Helper to check multiple features (logic: ALL must be present)
  bool canAccessAll(List<String> keys) => keys.every(canAccess);

  /// Helper to check multiple features (logic: ANY must be present)
  bool canAccessAny(List<String> keys) => keys.any(canAccess);

  /// Watches effective access for a specific academy.
  /// This is used for real-time UI updates (e.g. in FeatureAccessController).
  Stream<EffectiveFeatureAccess> watchEffectiveAccess(String academyId) {
    // If we're already initialized for this academy, start with current state
    return accessStream.map((keys) => EffectiveFeatureAccess(keys));
  }
}

/// Represents the calculated feature permissions at a specific point in time.
class EffectiveFeatureAccess {
  EffectiveFeatureAccess(this.allowed);
  final Set<String> allowed;

  bool has(String key) => allowed.contains(key);
}
