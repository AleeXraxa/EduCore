import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:educore/src/features/students/services/student_service.dart';
import 'package:educore/src/core/services/plan_limit_exception.dart';

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
  String? _statusFilter;
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
    
    // Mock summary data for Quick Insights (UI Ready)
    totalCount = 1248;
    activeCount = 1180;
    inactiveCount = 68;
    newAdmissionsCount = 42;
    
    await Future.wait([
      _fetchBatch(),
      loadCustomFieldDefinitions(),
    ]);
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

  Future<void> loadMore() async {
    if (!_hasMore || busy) return;
    await _fetchBatch();
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

          // Apply local search filtering as Firestore doesn't support substring text search
          if (_searchQuery.isNotEmpty) {
            final queryLower = _searchQuery.toLowerCase();
            final filtered = visibleStudents.where((s) => 
                s.name.toLowerCase().contains(queryLower) || 
                s.phone.contains(queryLower) ||
                s.fatherName.toLowerCase().contains(queryLower)
            ).toList();
            _students.addAll(filtered);
          } else {
            _students.addAll(visibleStudents);
          }
        }
      } catch (e, st) {
        debugPrint('Error fetching students: $e $st');
        _errorMessage = 'Failed to load students';
      }
    });
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadInitialData();
  }

  void setFilter(String? classId, String? status) {
    if (_classIdFilter == classId && _statusFilter == status) return;
    _classIdFilter = classId;
    _statusFilter = status;
    loadInitialData();
  }

  Future<bool> addStudent(Student student) async {
    bool success = false;
    await runBusy(() async {
      try {
        final newStudent = await _studentService.createStudent(_academyId, student);
        _students.insert(0, newStudent);
        success = true;
      } catch (e, st) {
        debugPrint('Error adding student: $e $st');
        if (e is PlanLimitExceededException) rethrow;
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
}
