import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/attendance/models/attendance_record.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';

class AttendanceController extends BaseController {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  InstituteClass? _selectedClass;
  InstituteClass? get selectedClass => _selectedClass;

  List<InstituteClass> _classes = [];
  List<InstituteClass> get classes => _classes;

  String _searchQuery = '';
  
  List<double> _weeklyTrend = [0, 0, 0, 0, 0, 0, 0];
  List<double> get weeklyTrend => _weeklyTrend;

  List<Map<String, dynamic>> _attentionNeeded = [];
  List<Map<String, dynamic>> get attentionNeeded => _attentionNeeded;

  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> _filteredRecords = [];
  List<AttendanceRecord> get records => _filteredRecords;

  // Metrics
  int totalStudents = 0;
  int presentCount = 0;
  int absentCount = 0;
  int leaveCount = 0;
  int attendancePercentage = 0;

  void _applyFilters() {
    _filteredRecords = _allRecords.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.phone.contains(_searchQuery);
      return matchesSearch;
    }).toList();

    // Recalculate Metrics
    totalStudents = _filteredRecords.length;
    presentCount =
        _filteredRecords.where((r) => r.status == AttendanceStatus.present).length;
    absentCount =
        _filteredRecords.where((r) => r.status == AttendanceStatus.absent).length;
    leaveCount =
        _filteredRecords.where((r) => r.status == AttendanceStatus.leave).length;

    final activeStudents = totalStudents - leaveCount;
    if (activeStudents <= 0) {
      attendancePercentage = 0;
    } else {
      attendancePercentage = (presentCount / activeStudents * 100).round();
    }

    notifyListeners();
  }

  Future<void> loadInitialData() async {
    await runBusy(() async {
      final academyId = AppServices.instance.authService!.session!.academyId;
      _classes = await AppServices.instance.classService!.getClasses(academyId);
      
      if (_classes.isNotEmpty) {
        _selectedClass = _classes.first;
        await _fetchAttendanceForSelected();
      }

      _weeklyTrend = await AppServices.instance.attendanceService!.getWeeklyAttendanceTrend(academyId);
      
      notifyListeners();
    });
  }

  Future<void> _fetchAttendanceForSelected() async {
    if (_selectedClass == null) return;
    
    final academyId = AppServices.instance.authService!.session!.academyId;
    
    // 1. Fetch Students
    final students = await AppServices.instance.studentService!.getClassStudents(academyId, _selectedClass!.id);
    
    // 2. Fetch Existing Attendance
    final existing = await AppServices.instance.attendanceService!.getAttendance(
      academyId: academyId, 
      classId: _selectedClass!.id, 
      date: _selectedDate,
    );

    final existingMap = { for (var r in existing) r.studentId: r };

    _allRecords = students.map((s) {
      final rec = existingMap[s.id];
      return AttendanceRecord(
        id: rec?.id,
        studentId: s.id,
        studentName: s.name,
        classId: _selectedClass!.id,
        className: _selectedClass!.displayName,
        phone: s.phone,
        date: _selectedDate,
        status: rec?.status ?? AttendanceStatus.none,
      );
    }).toList();

    _applyFilters();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    runBusy(() => _fetchAttendanceForSelected());
  }

  void setClass(InstituteClass? cls) {
    _selectedClass = cls;
    runBusy(() => _fetchAttendanceForSelected());
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _applyFilters();
  }

  void updateStatus(String studentId, AttendanceStatus status) {
    final index = _allRecords.indexWhere((r) => r.studentId == studentId);
    if (index != -1) {
      _allRecords[index].status = status;
      notifyListeners();
    }
  }

  Future<void> saveAttendance() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    await runBusy(() async {
      await AppServices.instance.attendanceService!.saveAttendance(
        academyId: academyId, 
        records: _allRecords,
      );
      await _fetchAttendanceForSelected(); // Refresh IDs
    });
  }

  void markAll(AttendanceStatus status) {
    for (var record in _allRecords) {
      record.status = status;
    }
    notifyListeners();
  }
}
