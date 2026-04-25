import 'dart:async';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/reports/models/report_config.dart';
import 'package:educore/src/features/reports/services/report_service.dart';
import 'package:educore/src/features/settings/models/global_settings.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:flutter/material.dart';

enum ReportState { idle, generating, done, error }

class ReportsController extends BaseController {
  final ReportService _service;

  ReportsController()
      : _service = ReportService(
          firestore: AppServices.instance.firestore!,
          auditLogService: AppServices.instance.auditLogService!,
        );

  Academy? academy;
  GlobalSettings? instituteSettings;

  // ─── Navigation ───────────────────────────────────────────────────────────
  ReportCategory selectedCategory = ReportCategory.academic;
  ReportMeta? selectedReport;

  // ─── Filters ──────────────────────────────────────────────────────────────
  ReportFilters filters = ReportFilters();

  // ─── Classes / Students list for filter dropdown ───────────────────────────
  List<Map<String, String>> availableClasses = []; // [{id, name}]
  List<Map<String, String>> availableStudents = []; // [{id, name}]

  // ─── Data ─────────────────────────────────────────────────────────────────
  List<String> columnHeaders = [];
  List<ReportRow> rows = [];
  ReportState reportState = ReportState.idle;

  // ─── Analytics ────────────────────────────────────────────────────────────
  Map<String, List<double>> monthlyTrends = {};
  Map<String, int> studentBreakdown = {};
  Map<String, double> expenseCategoryBreakdown = {};
  bool analyticsLoaded = false;

  String? get academyId =>
      AppServices.instance.authService?.session?.academyId;
  String? get actorId =>
      AppServices.instance.authService?.currentUser?.uid;

  void init() {
    _loadAcademy();
    _loadClasses();
    _loadAnalytics();
  }

  Future<void> _loadAcademy() async {
    final aid = academyId;
    if (aid == null) return;
    try {
      academy = await AppServices.instance.getInstituteService.getAcademy(aid);
      instituteSettings = await AppServices.instance.getSettingsService.getAcademySettings(aid);
      notifyListeners();
    } catch (e) {
      debugPrint('Academy/Settings load error: $e');
    }
  }


  // ─── Category / Report selection ──────────────────────────────────────────
  void selectCategory(ReportCategory cat) {
    selectedCategory = cat;
    selectedReport = null;
    columnHeaders = [];
    rows = [];
    reportState = ReportState.idle;
    filters = ReportFilters();
    notifyListeners();
  }

  void selectReport(ReportMeta meta) {
    selectedReport = meta;
    columnHeaders = [];
    rows = [];
    reportState = ReportState.idle;
    filters = ReportFilters();
    notifyListeners();
  }

  // ─── Filter updates ───────────────────────────────────────────────────────
  void updateClassFilter(String? classId, String? className) {
    filters = ReportFilters(
      classId: classId,
      className: className,
      studentId: null, // Reset student when class changes
      studentName: null,
      status: filters.status,
      startDate: filters.startDate,
      endDate: filters.endDate,
      month: filters.month,
      year: filters.year,
    );
    
    if (classId != null) {
      _loadStudents(classId);
    } else {
      availableStudents = [];
    }
    
    notifyListeners();
  }

  void updateStudentFilter(String? studentId, String? studentName) {
    filters = filters.copyWith(
      studentId: studentId,
      studentName: studentName,
    );
    notifyListeners();
  }

  void updateStatusFilter(String? status) {
    filters = ReportFilters(
      classId: filters.classId,
      className: filters.className,
      studentId: filters.studentId,
      studentName: filters.studentName,
      status: status,
      startDate: filters.startDate,
      endDate: filters.endDate,
      month: filters.month,
      year: filters.year,
    );
    notifyListeners();
  }

  void updateDateRange(DateTime? start, DateTime? end) {
    filters = ReportFilters(
      classId: filters.classId,
      className: filters.className,
      studentId: filters.studentId,
      studentName: filters.studentName,
      status: filters.status,
      startDate: start,
      endDate: end,
      month: filters.month,
      year: filters.year,
    );
    notifyListeners();
  }

  void updateYearFilter(int? year) {
    filters = ReportFilters(
      classId: filters.classId,
      className: filters.className,
      status: filters.status,
      startDate: filters.startDate,
      endDate: filters.endDate,
      year: year,
    );
    notifyListeners();
  }

  void clearFilters() {
    filters = ReportFilters();
    notifyListeners();
  }

  // ─── Generate ─────────────────────────────────────────────────────────────
  Future<void> generateReport() async {
    final meta = selectedReport;
    final aid = academyId;
    if (meta == null || aid == null) return;

    reportState = ReportState.generating;
    notifyListeners();

    try {
      final data = await _fetchData(meta, aid);
      columnHeaders = data.isEmpty ? [] : data.first.keys.toList();
      rows = data;
      reportState = ReportState.done;

      // Audit
      _service.logReportGenerated(meta.label);
    } catch (e, st) {
      debugPrint('Report error: $e\n$st');
      setError(e.toString());
      reportState = ReportState.error;
    }
    notifyListeners();
  }

  Future<List<ReportRow>> _fetchData(ReportMeta meta, String aid) async {
    switch (meta.type) {
      case ReportType.studentList:
      case ReportType.classWiseStudents:
        return _service.getStudentList(aid, filters);

      case ReportType.attendanceByStudent:
        return _service.getAttendanceByStudent(aid, filters);
      case ReportType.attendanceByClass:
        return _service.getAttendanceByClass(aid, filters);
      case ReportType.attendanceSummary:
        return _service.getMonthlyAttendanceSummary(aid, filters);

      case ReportType.examResults:
        return _service.getExamResults(aid, filters);

      case ReportType.testResults:
        return _service.getTestResults(aid, filters);

      case ReportType.paidFees:
        return _service.getFeeReport(aid, filters, statusFilter: 'paid');
      case ReportType.pendingFees:
        return _service.getFeeReport(aid, filters, statusFilter: 'pending');
      case ReportType.partialFees:
        return _service.getFeeReport(aid, filters, statusFilter: 'partial');
      case ReportType.feeCollectionByDate:
      case ReportType.studentFeeHistory:
      case ReportType.monthlyFeeReport:
        return _service.getFeeReport(aid, filters);

      case ReportType.expenseList:
        return _service.getExpenseReport(aid, filters);
      case ReportType.expenseByCategory:
      case ReportType.monthlyExpenseSummary:
        return _service.getExpenseByCategory(aid, filters);

      case ReportType.profitLossMonthly:
      case ReportType.profitLossYearly:
        return _service.getProfitLossMonthly(aid, filters);

      case ReportType.staffList:
        return _service.getStaffReport(aid);

      case ReportType.classList:
        return _service.getClassReport(aid);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────
  Future<void> _loadStudents(String classId) async {
    final aid = academyId;
    if (aid == null) return;
    try {
      final snap = await AppServices.instance.firestore!
          .collection('academies')
          .doc(aid)
          .collection('students')
          .where('classId', isEqualTo: classId)
          .where('status', isEqualTo: 'active')
          .orderBy('name')
          .get();
      availableStudents = snap.docs
          .map((d) => {
                'id': d.id,
                'name': (d.data()['name'] as String?) ?? d.id,
              })
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Student load error: $e');
    }
  }

  Future<void> _loadClasses() async {
    final aid = academyId;
    if (aid == null) return;
    try {
      final snap = await AppServices.instance.firestore!
          .collection('academies')
          .doc(aid)
          .collection('classes')
          .orderBy('name')
          .get();
      availableClasses = snap.docs
          .map((d) => {
                'id': d.id,
                'name': (d.data()['name'] as String?) ?? d.id,
              })
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Class load error: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    final aid = academyId;
    if (aid == null) return;
    try {
      final trends = await _service.getMonthlyTrends(aid);
      final students = await _service.getStudentStatusBreakdown(aid);
      final expenses = await _service.getExpenseCategoryBreakdown(aid);
      monthlyTrends = trends;
      studentBreakdown = students;
      expenseCategoryBreakdown = expenses;
      analyticsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Analytics load error: $e');
    }
  }

  // ─── Export helpers ────────────────────────────────────────────────────────
  Future<void> logExport(String format) async {
    final meta = selectedReport;
    if (meta == null) return;
    _service.logReportExported(meta.label, format);
  }

  // ─── Utility ──────────────────────────────────────────────────────────────
  List<ReportMeta> get accessibleReports {
    final featureSvc = AppServices.instance.featureAccessService;
    return ReportMeta.byCategory(selectedCategory).where((r) {
      if (r.requiredFeature == null) return true;
      return featureSvc?.canAccess(r.requiredFeature!) ?? true;
    }).toList();
  }

  String get reportTitle => selectedReport?.label ?? 'Select a Report';
  bool get hasData => rows.isNotEmpty;
  bool get isGenerating => reportState == ReportState.generating;

  DateTimeRange? get selectedDateRange =>
      filters.startDate != null && filters.endDate != null
          ? DateTimeRange(start: filters.startDate!, end: filters.endDate!)
          : null;
}
