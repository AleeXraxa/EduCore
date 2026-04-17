import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/services/student_service.dart';

class StudentController extends BaseController {
  final StudentService _studentService;
  final String _academyId;

  StudentController({StudentService? studentService})
      : _studentService = studentService ?? StudentService(),
        _academyId = AppServices.instance.authService!.session!.academyId;

  final List<Student> _students = [];
  List<Student> get students => _students;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _searchQuery = '';
  String? _classFilter;
  String? _statusFilter;

  Future<void> loadInitialData() async {
    _students.clear();
    _lastDoc = null;
    _hasMore = true;
    await _fetchBatch();
  }

  Future<void> loadMore() async {
    if (!_hasMore || busy) return;
    await _fetchBatch();
  }

  Future<void> _fetchBatch() async {
    await runBusy(() async {
      try {
        final snapshot = await _studentService.getStudentsBatch(
          academyId: _academyId,
          startAfter: _lastDoc,
          classFilter: _classFilter,
          statusFilter: _statusFilter,
        );

        if (snapshot.docs.length < 20) {
          _hasMore = false;
        }

        if (snapshot.docs.isNotEmpty) {
          _lastDoc = snapshot.docs.last;
          
          final fetchedStudents = snapshot.docs
              .map((doc) => Student.fromMap(doc.id, doc.data()))
              .toList();

          // Apply local search filtering as Firestore doesn't support substring text search
          if (_searchQuery.isNotEmpty) {
            final queryLower = _searchQuery.toLowerCase();
            final filtered = fetchedStudents.where((s) => 
                s.name.toLowerCase().contains(queryLower) || 
                s.phone.contains(queryLower) ||
                s.fatherName.toLowerCase().contains(queryLower)
            ).toList();
            _students.addAll(filtered);
          } else {
            _students.addAll(fetchedStudents);
          }
        }
      } catch (e, st) {
        debugPrint('Error fetching students: $e $st');
      }
    });
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadInitialData();
  }

  void setFilter(String? className, String? status) {
    if (_classFilter == className && _statusFilter == status) return;
    _classFilter = className;
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
