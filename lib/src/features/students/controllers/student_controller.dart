import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:educore/src/features/students/services/student_service.dart';

class StudentController extends BaseController {
  final StudentService _studentService;
  final String _academyId;

  StudentController({StudentService? studentService})
      : _studentService = studentService ?? AppServices.instance.studentService!,
        _academyId = AppServices.instance.authService!.session!.academyId;

  final List<Student> _students = [];
  List<Student> get students => _students;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _searchQuery = '';
  String? _classIdFilter;
  String? get classIdFilter => _classIdFilter;
  String? _statusFilter;
  String? get statusFilter => _statusFilter;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stats for Quick Insights
  int totalCount = 0;
  int activeCount = 0;
  int inactiveCount = 0;
  int newAdmissionsCount = 0;

  // Custom Fields
  List<StudentCustomField> _customFieldDefinitions = [];
  List<StudentCustomField> get customFieldDefinitions => _customFieldDefinitions;
  
  Map<String, dynamic> dynamicFormState = {};

  Future<void> loadInitialData() async {
    _students.clear();
    _lastDoc = null;
    _hasMore = true;
    // Temporarily reset before loading
    totalCount = 0;
    activeCount = 0;
    inactiveCount = 0;
    newAdmissionsCount = 0;
    
    await Future.wait([
      _fetchBatch(),
      loadCustomFieldDefinitions(),
      _fetchStats(),
    ]);
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _studentService.getStudentStats(_academyId);
      totalCount = stats['total'] ?? 0;
      activeCount = stats['active'] ?? 0;
      inactiveCount = stats['inactive'] ?? 0;
      newAdmissionsCount = stats['newAdmissions'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> loadCustomFieldDefinitions() async {
    try {
      _customFieldDefinitions = await _studentService.getCustomFieldDefinitions(_academyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading custom fields: $e');
    }
  }

  Future<void> addCustomFieldDefinition(StudentCustomField field) async {
    await runBusy(() async {
      try {
        final newField = await _studentService.createCustomFieldDefinition(_academyId, field);
        _customFieldDefinitions.add(newField);
        notifyListeners();
      } catch (e) {
        debugPrint('Error adding custom field: $e');
      }
    });
  }

  void updateDynamicField(String key, dynamic value) {
    dynamicFormState[key] = value;
    notifyListeners();
  }

  void resetDynamicForm(Map<String, dynamic>? initialValues) {
    dynamicFormState = Map<String, dynamic>.from(initialValues ?? {});
    notifyListeners();
  }

  Future<void> _fetchBatch() async {
    _errorMessage = null;
    await runBusy(() async {
      try {
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          snapshot = await _studentService.getStudentsBatch(
            academyId: _academyId,
            startAfter: _lastDoc,
            classIdFilter: _classIdFilter,
            statusFilter: _statusFilter,
          );
        } on FirebaseException catch (e) {
          // If the complex query fails (missing index), fall back to simple name ordering
          if (e.code == 'failed-precondition' || e.message?.contains('index') == true) {
            debugPrint('Firestore Error: $e'); // This will print the clickable link
            _errorMessage = 'Using simple view (Index missing)';
            final query = FirebaseFirestore.instance
                .collection('academies')
                .doc(_academyId)
                .collection('students')
                .orderBy('name')
                .limit(20);
            
            final fallbackQuery = _lastDoc != null ? query.startAfterDocument(_lastDoc!) : query;
            snapshot = await fallbackQuery.get();
          } else {
            rethrow;
          }
        }

        if (snapshot.docs.length < 20) {
          _hasMore = false;
        }

        if (snapshot.docs.isNotEmpty) {
          _lastDoc = snapshot.docs.last;
          
          final fetchedStudents = snapshot.docs
              .map((doc) => Student.fromMap(doc.id, doc.data()))
              .toList();

          // Filter out deleted locally if the query didn't do it
          final visibleStudents = fetchedStudents.where((s) => s.status != 'deleted').toList();

          _students.addAll(visibleStudents);
        }
      } catch (e, st) {
        debugPrint('Error fetching students: $e $st');
        _errorMessage = 'Failed to load students';
      }
    });
  }

  Timer? _searchDebounce;

  void onSearchChanged(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    debugPrint('Search query changed: $query');
    
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      loadInitialData();
    });
  }

  void onClassFilterChanged(String? classId) {
    if (_classIdFilter == classId) return;
    _classIdFilter = (classId == 'all' || classId == null) ? null : classId;
    loadInitialData();
  }

  void onStatusFilterChanged(String? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    loadInitialData();
  }

  Future<void> fetchMore() async {
    if (!_hasMore || busy) return;
    await _fetchBatch();
  }

  @Deprecated('Use fetchMore instead')
  Future<void> loadMore() => fetchMore();

  Future<bool> addStudent(Student student) async {
    bool success = false;
    await runBusy(() async {
      try {
        final newStudent = await _studentService.createStudent(_academyId, student);
        _students.insert(0, newStudent);
        success = true;
      } catch (e, st) {
        debugPrint('Error adding student in controller: $e $st');
        rethrow;
      }
    });
    return success;
  }

  Future<bool> updateStudent(Student student) async {
    bool success = false;
    await runBusy(() async {
      try {
        await _studentService.updateStudent(_academyId, student);
        final index = _students.indexWhere((s) => s.id == student.id);
        if (index != -1) {
          _students[index] = student.copyWith(updatedAt: DateTime.now());
        }
        success = true;
      } catch (e, st) {
        debugPrint('Error updating student: $e $st');
      }
    });
    return success;
  }

  Future<bool> deleteStudent(String studentId) async {
    bool success = false;
    await runBusy(() async {
      try {
        await _studentService.softDeleteStudent(_academyId, studentId);
        _students.removeWhere((s) => s.id == studentId);
        success = true;
      } catch (e, st) {
        debugPrint('Error deleting student: $e $st');
      }
    });
    return success;
  }

  Future<String> getNextRollNumber() async {
    return await _studentService.getNextRollNumber(_academyId);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
