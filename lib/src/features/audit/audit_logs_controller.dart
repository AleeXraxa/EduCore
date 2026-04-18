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
  String? searchActorId;
  DateTime? startDate;
  DateTime? endDate;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 20;

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
      final snapshot = await _repository!.getRawLogsBatch(
        limit: _pageSize,
        lastDoc: _lastDoc,
        module: selectedModule,
        severity: selectedSeverity?.name,
        academyId: searchAcademyId?.isEmpty == true ? null : searchAcademyId,
        actorId: searchActorId,
        startDate: startDate,
        endDate: endDate,
      );

      final results = snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();

      if (results.length < _pageSize) {
        _hasMore = false;
      }

      if (results.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
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

  void setSearchAcademy(String? id) {
    searchAcademyId = id;
    unawaited(refresh());
  }

  void setActor(String? id) {
    searchActorId = id;
    unawaited(refresh());
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate = start;
    endDate = end;
    unawaited(refresh());
  }

  List<String> get availableModules => [
    'staff',
    'classes',
    'students',
    'fees',
    'attendance',
    'academies',
    'subscriptions',
    'payments',
    'plans',
    'features',
    'settings',
  ];
}
