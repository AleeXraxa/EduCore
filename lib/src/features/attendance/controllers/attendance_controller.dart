import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/attendance/models/attendance_record.dart';

class AttendanceController extends BaseController {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String? _selectedClass = 'Grade 1';
  String? get selectedClass => _selectedClass;

  String _searchQuery = '';
  
  // In a real app, these would come from the service/database
  List<double> _weeklyTrend = [85, 92, 88, 95, 90, 82, 88];
  List<double> get weeklyTrend => _weeklyTrend;

  List<Map<String, dynamic>> _attentionNeeded = [
    {'name': 'Alex Johnson', 'reason': 'Absent for 3 days', 'class': 'Grade 1', 'isCritical': true},
    {'name': 'Sofia Ramirez', 'reason': 'Attendance below 60%', 'class': 'Grade 2', 'isCritical': false},
  ];
  List<Map<String, dynamic>> get attentionNeeded => _attentionNeeded;

  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> get records => _allRecords.where((r) {
    final matchesClass = _selectedClass == null || r.className == _selectedClass;
    final matchesSearch = _searchQuery.isEmpty || 
        r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        r.phone.contains(_searchQuery);
    return matchesClass && matchesSearch;
  }).toList();

  // Metrics
  int get totalStudents => records.length;
  int get presentCount => records.where((r) => r.status == AttendanceStatus.present).length;
  int get absentCount => records.where((r) => r.status == AttendanceStatus.absent).length;
  int get leaveCount => records.where((r) => r.status == AttendanceStatus.leave).length;
  
  int get attendancePercentage {
    final activeStudents = totalStudents - leaveCount;
    if (activeStudents <= 0) return 0;
    return (presentCount / activeStudents * 100).round();
  }

  Future<void> loadInitialData() async {
    await runBusy(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock data
      _allRecords = List.generate(20, (i) => AttendanceRecord(
        studentId: 'std_$i',
        studentName: i % 2 == 0 ? 'John Doe $i' : 'Sarah Smith $i',
        className: i < 10 ? 'Grade 1' : 'Grade 2',
        phone: '0300-123456$i',
        status: AttendanceStatus.none,
      ));
      
      notifyListeners();
    });
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setClass(String? className) {
    _selectedClass = className;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateStatus(String studentId, AttendanceStatus status) {
    final index = _allRecords.indexWhere((r) => r.studentId == studentId);
    if (index != -1) {
      _allRecords[index].status = status;
      notifyListeners();
    }
  }

  void markAll(AttendanceStatus status) {
    for (var record in records) {
      record.status = status;
    }
    notifyListeners();
  }
}
