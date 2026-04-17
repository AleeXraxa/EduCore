import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:flutter/material.dart';

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

  // Summary Metrics
  int get totalRecords => _reportData.length;
  double get avgAttendance => _reportData.isEmpty 
    ? 0 
    : _reportData.map((e) => (e['percentage'] as num).toDouble()).reduce((a, b) => a + b) / _reportData.length;
  
  String get highestAttendance => _reportData.isEmpty ? 'N/A' : _reportData.reduce((a, b) => a['percentage'] > b['percentage'] ? a : b)['name'];
  String get lowestAttendance => _reportData.isEmpty ? 'N/A' : _reportData.reduce((a, b) => a['percentage'] < b['percentage'] ? a : b)['name'];

  void setReportType(ReportType type) {
    _currentType = type;
    _reportData = []; // Clear stale data to prevent UI type errors during reload
    fetchReport();
  }

  void setDateFilter(DateFilter filter) {
    _currentFilter = filter;
    if (filter != DateFilter.custom) {
      _customRange = null;
    }
    _reportData = []; // Clear stale data
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
      await Future.delayed(const Duration(milliseconds: 500)); // Mock latency
      
      // Mock data generation based on type
      if (_currentType == ReportType.student) {
        _reportData = List.generate(15, (i) => {
          'name': 'Student ${i + 1}',
          'present': 15 + (i % 5),
          'absent': 2,
          'leave': 1,
          'percentage': 85.0 + (i % 15),
        });
      } else if (_currentType == ReportType.teacher) {
        _reportData = [
          {'name': 'Mr. Ahmed', 'classes': 'Grade 1, 2', 'sessions': 45, 'percentage': 92.5},
          {'name': 'Ms. Sara', 'classes': 'Grade 3, 4', 'sessions': 38, 'percentage': 88.0},
          {'name': 'Mr. Kashif', 'classes': 'Grade 5', 'sessions': 42, 'percentage': 95.0},
        ];
      } else {
        _reportData = [
          {'name': 'Grade 1', 'students': 35, 'percentage': 94.0, 'summary': 'P: 30, A: 3, L: 2'},
          {'name': 'Grade 2', 'students': 40, 'percentage': 82.5, 'summary': 'P: 32, A: 6, L: 2'},
          {'name': 'Grade 3', 'students': 28, 'percentage': 89.0, 'summary': 'P: 25, A: 2, L: 1'},
        ];
      }
      
      notifyListeners();
    });
  }
}
