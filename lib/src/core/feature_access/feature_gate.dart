import 'package:educore/src/core/feature_access/feature_access_controller.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:flutter/material.dart';

class FeatureGate extends StatelessWidget {
  const FeatureGate({
    super.key,
    required this.controller,
    required this.featureKey,
    required this.child,
    this.fallback,
  });

  final FeatureAccessController controller;
  final String featureKey;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<FeatureAccessController>(
      controller: controller,
      builder: (context, access, _) {
        if (access.has(featureKey)) return child;
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

