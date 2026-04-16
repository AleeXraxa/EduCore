import 'dart:async';

import 'package:educore/src/core/models/subscription_access.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/core/services/subscription_service.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/plans/models/plan.dart';

class EffectiveFeatureAccess {
  const EffectiveFeatureAccess({
    required this.academyId,
    required this.planId,
    required this.status,
    required this.allowedKeys,
    required this.blockedKeys,
  });

  final String academyId;
  final String planId;
  final SubscriptionAccessStatus status;
  final Set<String> allowedKeys;
  final Set<String> blockedKeys;

  bool has(String key) => allowedKeys.contains(key);
}

class FeatureAccessService {
  FeatureAccessService({
    required FeatureService featureService,
    required PlanService planService,
    required SubscriptionService subscriptionService,
  })  : _featureService = featureService,
        _planService = planService,
        _subscriptionService = subscriptionService;

  final FeatureService _featureService;
  final PlanService _planService;
  final SubscriptionService _subscriptionService;

  Stream<EffectiveFeatureAccess> watchEffectiveAccess(String academyId) {
    final controller = StreamController<EffectiveFeatureAccess>();

    List<FeatureFlag> registry = const [];
    SubscriptionAccess? subscription;
    Plan? plan;

    StreamSubscription? featureSub;
    StreamSubscription? subscriptionSub;
    StreamSubscription? planSub;

    void emit() {
      final planId = subscription?.planId ?? '';
      final status = subscription?.status ?? SubscriptionAccessStatus.pending;

      final registryActive = registry
          .where((f) => f.isActive)
          .map((f) => f.key)
          .toSet();

      final baseFeatures = <String>{};
      if (subscription != null && subscription!.assignedFeatures.isNotEmpty) {
        baseFeatures.addAll(subscription!.assignedFeatures);
      } else if (plan != null) {
        baseFeatures.addAll(plan!.features);
      }

      final allowed = <String>{};
      final overrides = subscription?.overrides;

      for (final key in registryActive) {
        // Priority: disabled > enabled > plan
        if (overrides != null && overrides.isDisabled(key)) {
          // Blocked by override
          continue;
        }

        if (overrides != null && overrides.isEnabled(key)) {
          // Allowed by override
          allowed.add(key);
          continue;
        }

        if (baseFeatures.contains(key)) {
          // Allowed by plan
          allowed.add(key);
        }
      }

      final blocked = registryActive.difference(allowed);

      controller.add(
        EffectiveFeatureAccess(
          academyId: academyId,
          planId: planId,
          status: status,
          allowedKeys: allowed,
          blockedKeys: blocked,
        ),
      );
    }

    featureSub = _featureService.watchFeatures().listen((value) {
      registry = value;
      emit();
    });

    subscriptionSub =
        _subscriptionService.watchSubscription(academyId).listen((value) {
      subscription = value;
      final nextPlanId = value?.planId;
      if (nextPlanId == null || nextPlanId.isEmpty) {
        planSub?.cancel();
        plan = null;
        emit();
        return;
      }

      if (plan?.id == nextPlanId) {
        emit();
        return;
      }

      planSub?.cancel();
      planSub = _planService.watchPlan(nextPlanId).listen((p) {
        plan = p;
        emit();
      });
    });

    controller.onCancel = () async {
      await featureSub?.cancel();
      await subscriptionSub?.cancel();
      await planSub?.cancel();
    };

    return controller.stream;
  }
}

