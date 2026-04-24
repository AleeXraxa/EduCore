import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/class_service.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:educore/src/features/exams/models/exam_marks.dart';
import 'package:educore/src/features/exams/models/exam_result.dart';
import 'package:educore/src/features/exams/models/exam_schedule.dart';
import 'package:educore/src/features/exams/services/exam_service.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/services/student_service.dart';

class ExamController extends BaseController {
  final ExamService _examService;
  final ClassService _classService;
  final StudentService _studentService;
  final String _academyId;

  ExamController({
    ExamService? examService,
    ClassService? classService,
    StudentService? studentService,
  })  : _examService = examService ?? AppServices.instance.examService!,
        _classService = classService ?? AppServices.instance.classService!,
        _studentService = studentService ?? AppServices.instance.studentService!,
        _academyId = AppServices.instance.authService!.session!.academyId {
    load();
  }

  List<Exam> _allExams = [];
  List<Exam> _filteredExams = [];
  List<Exam> get exams => _filteredExams;

  List<InstituteClass> _classes = [];
  List<InstituteClass> get classes => _classes;

  String _searchQuery = '';
  Timer? _searchDebounce;

  // Selected state for navigation/forms
  Exam? selectedExam;
  List<ExamSchedule> currentSchedules = [];
  List<ExamMarks> currentMarks = [];
  List<ExamResult> currentResults = [];
  List<Student> currentStudentsForMarks = [];

  Future<void> load() async {
    await runBusy(() async {
      try {
        final results = await Future.wait([
          _examService.getExams(_academyId),
          _classService.getClasses(_academyId),
        ]);

        _allExams = results[0] as List<Exam>;
        _classes = results[1] as List<InstituteClass>;

        _applyFilters();
      } catch (e) {
        debugPrint('Error loading exams: $e');
      }
    });
  }

  void _applyFilters() {
    _filteredExams = _allExams.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.className?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      return matchesSearch;
    }).toList();

    // Local Sorting - by Date descending
    _filteredExams.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
  // EXAM CRUD
  // ==========================================

  Future<bool> createExam(Exam exam) async {
    return (await runBusy(() async {
      await _examService.createExam(_academyId, exam);
      await load();
      return true;
    })) ?? false;
  }

  Future<bool> updateExam(Exam exam) async {
    return (await runBusy(() async {
      await _examService.updateExam(_academyId, exam);
      await load();
      return true;
    })) ?? false;
  }

  Future<bool> deleteExam(String examId) async {
    return (await runBusy(() async {
      await _examService.deleteExam(_academyId, examId);
      await load();
      return true;
    })) ?? false;
  }

  // ==========================================
  // SCHEDULES
  // ==========================================

  StreamSubscription? _scheduleSub;

  void selectExam(Exam exam) {
    selectedExam = exam;
    _scheduleSub?.cancel();
    _scheduleSub = _examService.watchSchedules(_academyId, exam.id).listen((schedules) {
      currentSchedules = schedules;
      notifyListeners();
    });
    currentResults = [];
    currentMarks = [];
    notifyListeners();
  }

  void clearSelection() {
    selectedExam = null;
    currentSchedules = [];
    currentResults = [];
    currentMarks = [];
    _scheduleSub?.cancel();
    notifyListeners();
  }

  Future<bool> createSchedule(ExamSchedule schedule) async {
    return (await runBusy(() async {
      await _examService.createSchedule(_academyId, schedule);
      return true;
    })) ?? false;
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    return (await runBusy(() async {
      await _examService.deleteSchedule(_academyId, scheduleId);
      return true;
    })) ?? false;
  }

  // ==========================================
  // MARKS ENTRY
  // ==========================================

  Future<bool> loadMarksEntry(ExamSchedule schedule) async {
    return (await runBusy(() async {
      // 1. Fetch active students for the class
      currentStudentsForMarks =
          await _studentService.getClassStudents(_academyId, schedule.classId);

      // 2. Fetch existing marks for this schedule
      currentMarks = await _examService.getMarks(_academyId, schedule.id);
      
      // Auto-generate empty missing marks
      List<ExamMarks> missingMarks = [];
      for(var stu in currentStudentsForMarks) {
        if (!currentMarks.any((m) => m.studentId == stu.id)) {
           missingMarks.add(ExamMarks(
             id: '',
             examId: schedule.examId,
             scheduleId: schedule.id,
             classId: schedule.classId,
             subjectId: schedule.subjectId,
             studentId: stu.id,
             studentRollNo: stu.rollNo ?? '',
             studentName: stu.name,
             obtainedMarks: 0,
             status: 'Fail',
             createdAt: DateTime.now(),
             updatedAt: DateTime.now(),
           ));
        }
      }

      currentMarks.addAll(missingMarks);

      // Sort by Name
      currentMarks.sort((a, b) => a.studentName.compareTo(b.studentName));

      return true;
    })) ?? false;
  }

  Future<bool> saveMarks(List<ExamMarks> marks) async {
    return (await runBusy(() async {
      await _examService.submitMarks(_academyId, marks);
      return true;
    })) ?? false;
  }

  // ==========================================
  // RESULTS
  // ==========================================

  Future<bool> loadResults(String examId) async {
    return (await runBusy(() async {
      currentResults = await _examService.getResults(_academyId, examId);
      return true;
    })) ?? false;
  }

  Future<bool> generateResults(Exam exam) async {
    return (await runBusy(() async {
      await _examService.generateResults(_academyId, exam.id, exam.classId);
      await loadResults(exam.id); // reload
      return true;
    })) ?? false;
  }

  Future<bool> togglePublishResult(Exam exam, bool publish) async {
    return (await runBusy(() async {
      await _examService.togglePublishStatus(_academyId, exam.id, publish);
      await loadResults(exam.id); // reload to get updated status
      return true;
    })) ?? false;
  }

  @override
  void dispose() {
    _scheduleSub?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }
}
