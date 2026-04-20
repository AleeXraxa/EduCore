import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';

enum ReportType { student, teacher, classroom }
enum DateFilter { today, last7, last30, custom }

class AttendanceReportController extends BaseController {
  ReportType _currentType = ReportType.student;
  ReportType get currentType => _currentType;

  DateFilter _currentFilter = DateFilter.last7;
  DateFilter get currentFilter => _currentFilter;

  DateTimeRange? _customRange;
  DateTimeRange? get customRange => _customRange;

  List<Map<String, dynamic>> _reportData = [];
  List<Map<String, dynamic>> get reportData => _reportData;

  String get _academyId => AppServices.instance.authService!.session!.academyId;

  // Summary Metrics
  int get totalRecords => _reportData.length;
  double get avgAttendance => _reportData.isEmpty 
    ? 0 
    : _reportData.map((e) => (e['percentage'] as num).toDouble()).reduce((a, b) => a + b) / _reportData.length;
  
  String get highestAttendance => _reportData.isEmpty ? 'N/A' : _reportData.reduce((a, b) => a['percentage'] > b['percentage'] ? a : b)['name'];
  String get lowestAttendance => _reportData.isEmpty ? 'N/A' : _reportData.reduce((a, b) => a['percentage'] < b['percentage'] ? a : b)['name'];

  void setReportType(ReportType type) {
    _currentType = type;
    _reportData = [];
    fetchReport();
  }

  void setDateFilter(DateFilter filter) {
    _currentFilter = filter;
    if (filter != DateFilter.custom) {
      _customRange = null;
    }
    _reportData = [];
    fetchReport();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _currentFilter = DateFilter.custom;
    _customRange = DateTimeRange(start: start, end: end);
    _reportData = [];
    fetchReport();
  }

  Future<void> fetchReport() async {
    await runBusy(() async {
      DateTime start;
      DateTime end = DateTime.now();

      switch (_currentFilter) {
        case DateFilter.today:
          start = DateTime.now();
          break;
        case DateFilter.last7:
          start = end.subtract(const Duration(days: 7));
          break;
        case DateFilter.last30:
          start = end.subtract(const Duration(days: 30));
          break;
        case DateFilter.custom:
          start = _customRange?.start ?? end.subtract(const Duration(days: 7));
          end = _customRange?.end ?? DateTime.now();
          break;
      }

      _reportData = await AppServices.instance.attendanceService!.getAttendanceReport(
        academyId: _academyId,
        start: start,
        end: end,
        type: _currentType.name,
      );
      
      notifyListeners();
    });
  }
}
