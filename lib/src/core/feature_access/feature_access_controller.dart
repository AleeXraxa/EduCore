import 'dart:async';

import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/feature_access_service.dart';

class FeatureAccessController extends BaseController {
  FeatureAccessController({required this.academyId}) {
    _service = AppServices.instance.featureAccessService;
    _attach();
  }

  final String academyId;
  FeatureAccessService? _service;
  StreamSubscription<EffectiveFeatureAccess>? _sub;

  EffectiveFeatureAccess? current;

  bool get ready => _service != null;

  bool has(String key) {
    final access = current;
    if (access == null) return false;
    return access.has(key);
  }

  void _attach() {
    final svc = _service;
    if (svc == null) return;
    _sub?.cancel();
    _sub = svc.watchEffectiveAccess(academyId).listen((value) {
      current = value;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

