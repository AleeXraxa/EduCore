import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'dart:async';

class AuditLogsController extends BaseController {
  List<AuditLog> _logs = [];
  List<AuditLog> get logs => _logs;

  bool get isLoading => busy;

  String? selectedModule;
  AuditSeverity? selectedSeverity;
  String? searchAcademyId;

  StreamSubscription? _logSub;

  AuditLogsController() {
    _init();
  }

  void _init() {
    refreshLogs();
  }

  void refreshLogs() {
    _logSub?.cancel();
    setBusy(true);

    _logSub = AppServices.instance.auditLogService?.watchLogs(
      module: selectedModule,
      severity: selectedSeverity,
      academyId: searchAcademyId?.isEmpty == true ? null : searchAcademyId,
    ).listen((data) {
      _logs = data;
      setBusy(false);
    });
  }

  void setModule(String? module) {
    selectedModule = module;
    refreshLogs();
  }

  void setSeverity(AuditSeverity? severity) {
    selectedSeverity = severity;
    refreshLogs();
  }

  void setSearchAcademy(String id) {
    searchAcademyId = id;
    refreshLogs();
  }

  List<String> get availableModules => [
    'payments',
    'subscriptions',
    'academies',
    'plans',
    'features',
    'settings',
  ];

  @override
  void dispose() {
    _logSub?.cancel();
    super.dispose();
  }
}
