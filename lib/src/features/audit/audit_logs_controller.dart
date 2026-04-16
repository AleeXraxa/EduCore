import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/repositories/audit_log_repository.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'dart:async';

class AuditLogsController extends BaseController {
  AuditLogsController() {
    _repository = AppServices.instance.auditLogRepository;
    _init();
  }

  AuditLogRepository? _repository;
  
  final List<AuditLog> _logs = [];
  List<AuditLog> get logs => _logs;

  // Pagination & Filtering
  String? selectedModule;
  AuditSeverity? selectedSeverity;
  String? searchAcademyId;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 50;

  bool get ready => _repository != null;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> _init() async {
    if (_repository == null) {
      await runBusy<void>(() async {
        await AppServices.instance.init();
      });
      _repository = AppServices.instance.auditLogRepository;
    }
    await refresh();
  }

  Future<void> retryInit() => _init();

  Future<void> refresh() async {
    _lastDoc = null;
    _hasMore = true;
    _logs.clear();
    
    await runBusy<void>(() async {
      await _fetchNextBatch();
    });
  }

  /// Alias for refresh used by some views.
  Future<void> refreshLogs() => refresh();

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      await _fetchNextBatch();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNextBatch() async {
    if (_repository == null) return;

    try {
      final results = await _repository!.getLogsBatch(
        limit: _pageSize,
        lastDoc: _lastDoc,
        module: selectedModule,
        severity: selectedSeverity?.name,
        academyId: searchAcademyId?.isEmpty == true ? null : searchAcademyId,
      );

      if (results.length < _pageSize) {
        _hasMore = false;
      }

      if (results.isNotEmpty) {
        // REFACTOR: Use the last timestamp as cursor if needed, or re-fetch last doc.
        // For compliance, we fetch the cursor doc.
        final lastLog = results.last;
        final lastDocSnap = await FirebaseFirestore.instance
            .collection('auditLogs')
            .where('timestamp', isEqualTo: lastLog.timestamp)
            .limit(1)
            .get();
            
        if (lastDocSnap.docs.isNotEmpty) {
          _lastDoc = lastDocSnap.docs.first;
        }
        
        _logs.addAll(results);
      }
      notifyListeners();
    } catch (e) {
      _hasMore = false;
    }
  }

  void setModule(String? module) {
    selectedModule = module;
    unawaited(refresh());
  }

  void setSeverity(AuditSeverity? severity) {
    selectedSeverity = severity;
    unawaited(refresh());
  }

  void setSearchAcademy(String id) {
    searchAcademyId = id;
    unawaited(refresh());
  }

  List<String> get availableModules => [
    'payments',
    'subscriptions',
    'academies',
    'plans',
    'features',
    'settings',
  ];
}
