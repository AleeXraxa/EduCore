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
    _init();
  }

  StreamSubscription? _testsSub;
  List<MonthlyTest> _tests = [];
  List<MonthlyTest> get tests => _tests;

  List<InstituteClass> _classes = [];
  List<InstituteClass> get classes => _classes;

  // Selected state
  MonthlyTest? selectedTest;
  List<TestQuestion> currentQuestions = [];
  List<TestMarks> currentMarks = [];
  List<TestResult> currentResults = [];
  List<Student> currentStudentsForMarks = [];

  void _init() {
    _testsSub = _testService.watchTests(_academyId).listen((data) {
      _tests = data;
      notifyListeners();
    });
    
    _classService.getClasses(_academyId).then((data) {
      _classes = data;
      notifyListeners();
    });
  }

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
      // 1. Fetch students
      final snap = await AppServices.instance.firestore!
          .collection('academies')
          .doc(_academyId)
          .collection('students')
          .where('classId', isEqualTo: test.classId)
          .where('status', isEqualTo: 'active')
          .get();
      
      currentStudentsForMarks = snap.docs.map((doc) => Student.fromMap(doc.id, doc.data())).toList();

      // 2. Fetch existing marks
      currentMarks = await _testService.getMarks(_academyId, test.id);
      
      // Auto-generate missing
      List<TestMarks> missingMarks = [];
      for(var stu in currentStudentsForMarks) {
        if (!currentMarks.any((m) => m.studentId == stu.id)) {
           missingMarks.add(TestMarks(
             id: '',
             testId: test.id,
             studentId: stu.id,
             studentRollNo: stu.rollNo ?? '',
             studentName: stu.name,
             obtainedMarks: 0,
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
    _testsSub?.cancel();
    _questionSub?.cancel();
    super.dispose();
  }
}
