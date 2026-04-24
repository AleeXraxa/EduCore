import 'dart:async';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/certificates/models/certificate_template.dart';
import 'package:flutter/foundation.dart';

class TemplateController extends ChangeNotifier {
  final _service = AppServices.instance.certificateTemplateService;
  
  List<CertificateTemplate> _templates = [];
  bool _busy = false;

  List<CertificateTemplate> get templates => _templates;
  bool get busy => _busy;

  StreamSubscription? _subscription;

  void init(String academyId) {
    if (_service == null) return;
    
    _busy = true;
    notifyListeners();

    _subscription = _service.watchTemplates(academyId).listen((items) {
      _templates = items;
      _busy = false;
      notifyListeners();
    });
  }

  Future<void> deleteTemplate(String academyId, CertificateTemplate template) async {
    if (_service == null) return;
    await _service.deleteTemplate(
      academyId: academyId,
      templateId: template.id,
      templateName: template.name,
    );
  }

  Future<void> setAsDefault(String academyId, CertificateTemplate template) async {
    if (_service == null) return;
    
    // Unset current default
    for (var t in _templates) {
      if (t.isDefault && t.id != template.id) {
        await _service.updateTemplate(
          academyId: academyId,
          template: t.copyWith(isDefault: false),
        );
      }
    }

    // Set new default
    await _service.updateTemplate(
      academyId: academyId,
      template: template.copyWith(isDefault: true),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
