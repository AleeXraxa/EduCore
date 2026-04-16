import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:flutter/material.dart';

/// A mixin to enforce action-level security in Controllers or Views.
/// 
/// It provides methods to check feature access and automatically handle 
/// the "Unauthorized Access" UI feedback.
mixin FeatureGuard {
  /// Checks if the current user can access the given [featureKey].
  /// 
  /// If [context] is provided and access is denied, it shows an 
  /// unauthorized access dialog.
  bool checkAccess(
    String featureKey, {
    BuildContext? context,
    String? customMessage,
  }) {
    final canAccess = AppServices.instance.featureAccessService?.canAccess(featureKey) ?? true;

    if (!canAccess && context != null) {
      _showUnauthorizedDialog(context, featureKey, customMessage);
    }

    return canAccess;
  }

  void _showUnauthorizedDialog(
    BuildContext context,
    String featureKey,
    String? customMessage,
  ) {
    AppDialogs.showError(
      context,
      title: 'Restricted Action',
      message: customMessage ?? 
          'Your current plan does not include the "$featureKey" feature. '
          'Please contact your administrator or upgrade your subscription to unlock this action.',
    );
  }
}
