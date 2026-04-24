import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/class_service.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';
import 'package:educore/src/features/monthly_tests/models/test_marks.dart';
import 'package:educore/src/features/monthly_tests/models/test_result.dart';
import 'package:educore/src/features/monthly_tests/services/monthly_test_service.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/services/student_service.dart';

class MonthlyTestController extends BaseController {
  final MonthlyTestService _testService;
  final ClassService _classService;
  final StudentService _studentService;
  final String _academyId;

  MonthlyTestController({
    MonthlyTestService? testService,
    ClassService? classService,
    StudentService? studentService,
  })  : _testService = testService ?? AppServices.instance.monthlyTestService!,
        _classService = classService ?? AppServices.instance.classService!,
        _studentService = studentService ?? AppServices.instance.studentService!,
        _academyId = AppServices.instance.authService!.session!.academyId {
    load();
  }

  List<MonthlyTest> _allTests = [];
  List<MonthlyTest> _filteredTests = [];
  List<MonthlyTest> get tests => _filteredTests;

  List<InstituteClass> _classes = [];
  List<InstituteClass> get classes => _classes;

  String _searchQuery = '';
  Timer? _searchDebounce;

  // Selected state
  MonthlyTest? selectedTest;
  List<TestQuestion> currentQuestions = [];
  List<TestMarks> currentMarks = [];
  List<TestResult> currentResults = [];
  List<Student> currentStudentsForMarks = [];

  Future<void> load() async {
    await runBusy(() async {
      try {
        final results = await Future.wait([
          _testService.getTests(_academyId),
          _classService.getClasses(_academyId),
        ]);

        _allTests = results[0] as List<MonthlyTest>;
        _classes = results[1] as List<InstituteClass>;

        _applyFilters();
      } catch (e) {
        debugPrint('Error loading tests: $e');
      }
    });
  }

  void _applyFilters() {
    _filteredTests = _allTests.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.className?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      return matchesSearch;
    }).toList();

    // Local Sorting - by Date descending
    _filteredTests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void init() => load();

  // ==========================================
  // TEST CRUD
  // ==========================================

  Future<bool> createTest(MonthlyTest test) async {
    return (await runBusy(() async {
      await _testService.createTest(_academyId, test);
      return true;
    })) ?? false;
  }

  Future<bool> updateTest(MonthlyTest test) async {
    return (await runBusy(() async {
      await _testService.updateTest(_academyId, test);
      return true;
    })) ?? false;
  }

  Future<bool> deleteTest(String testId) async {
    return (await runBusy(() async {
      await _testService.deleteTest(_academyId, testId);
      return true;
    })) ?? false;
  }

  // ==========================================
  // QUESTIONS
  // ==========================================

  StreamSubscription? _questionSub;

  void selectTest(MonthlyTest test) {
    selectedTest = test;
    _questionSub?.cancel();
    _questionSub = _testService.watchQuestions(_academyId, test.id).listen((questions) {
      currentQuestions = questions;
      notifyListeners();
    });
    currentResults = [];
    currentMarks = [];
    notifyListeners();
  }

  void clearSelection() {
    selectedTest = null;
    currentQuestions = [];
    currentResults = [];
    currentMarks = [];
    _questionSub?.cancel();
    notifyListeners();
  }

  Future<bool> addQuestion(TestQuestion question) async {
    return (await runBusy(() async {
      await _testService.addQuestion(_academyId, question);
      return true;
    })) ?? false;
  }

  Future<bool> deleteQuestion(TestQuestion question) async {
    return (await runBusy(() async {
      await _testService.deleteQuestion(_academyId, question);
      return true;
    })) ?? false;
  }

  Future<bool> deleteQuestions(List<TestQuestion> questions) async {
    if (questions.isEmpty) return true;
    return (await runBusy(() async {
      for (var q in questions) {
        await _testService.deleteQuestion(_academyId, q);
      }
      return true;
    })) ?? false;
  }

  Future<bool> importQuestions(List<TestQuestion> questions) async {
    if (selectedTest == null) return false;
    return (await runBusy(() async {
      await _testService.bulkImportQuestions(_academyId, selectedTest!.id, questions);
      return true;
    })) ?? false;
  }

  // ==========================================
  // MARKS
  // ==========================================

  Future<bool> loadMarksEntry(MonthlyTest test) async {
    return (await runBusy(() async {
      // 1. Fetch active students for the class
      currentStudentsForMarks =
          await _studentService.getClassStudents(_academyId, test.classId);

      // 2. Fetch existing marks
      final allMarks = await _testService.getMarks(_academyId, test.id);
      
      // De-duplicate by studentId just in case
      final Map<String, TestMarks> uniqueMarks = {};
      for(var m in allMarks) {
        uniqueMarks[m.studentId] = m;
      }
      currentMarks = uniqueMarks.values.toList();
      
      // Auto-generate missing
      List<TestMarks> missingMarks = [];
      for(var stu in currentStudentsForMarks) {
        if (!currentMarks.any((m) => m.studentId == stu.id)) {
           final Map<String, double> subMarks = {};
           for(var sub in test.subjects) {
             subMarks[sub.id] = 0.0;
           }

           missingMarks.add(TestMarks(
             id: '',
             testId: test.id,
             studentId: stu.id,
             studentRollNo: stu.rollNo ?? '',
             studentName: stu.name,
             subjectMarks: subMarks,
             status: 'Absent',
             createdAt: DateTime.now(),
             updatedAt: DateTime.now(),
           ));
        }
      }

      currentMarks.addAll(missingMarks);
      currentMarks.sort((a, b) => a.studentName.compareTo(b.studentName));

      return true;
    })) ?? false;
  }

  Future<bool> saveMarks(List<TestMarks> marks) async {
    if (selectedTest == null) return false;
    return (await runBusy(() async {
      await _testService.submitMarks(_academyId, selectedTest!.id, marks);
      return true;
    })) ?? false;
  }

  // ==========================================
  // RESULTS
  // ==========================================

  Future<bool> loadResults(String testId) async {
    return (await runBusy(() async {
      currentResults = await _testService.getResults(_academyId, testId);
      return true;
    })) ?? false;
  }

  Future<bool> generateResults(MonthlyTest test) async {
    return (await runBusy(() async {
      await _testService.generateResults(_academyId, test.id);
      await loadResults(test.id);
      return true;
    })) ?? false;
  }

  Future<bool> togglePublishResult(MonthlyTest test, bool publish) async {
    return (await runBusy(() async {
      await _testService.togglePublishStatus(_academyId, test.id, publish);
      return true;
    })) ?? false;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _questionSub?.cancel();
    super.dispose();
  }
}
