import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:educore/src/features/exams/models/exam_marks.dart';
import 'package:educore/src/features/exams/models/exam_result.dart';
import 'package:educore/src/features/exams/models/exam_schedule.dart';
import 'package:educore/src/features/students/models/student.dart';

class ExamService {
  ExamService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  CollectionReference<Map<String, dynamic>> _examsCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('exams');

  CollectionReference<Map<String, dynamic>> _schedulesCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('examSchedules');

  CollectionReference<Map<String, dynamic>> _marksCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('marks');

  CollectionReference<Map<String, dynamic>> _resultsCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('results');

  // ==========================================
  // EXAMS
  // ==========================================

  Stream<List<Exam>> watchExams(String academyId) {
    return _examsCol(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => Exam.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<List<Exam>> getExams(String academyId) async {
    final snap = await _examsCol(academyId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => Exam.fromMap(doc.id, doc.data())).toList();
  }

  Future<Exam?> getExam(String academyId, String examId) async {
    final doc = await _examsCol(academyId).doc(examId).get();
    if (!doc.exists) return null;
    return Exam.fromMap(doc.id, doc.data()!);
  }

  Future<Exam> createExam(String academyId, Exam exam) async {
    // Validation: Check overlapping exams
    final overlapping = await _examsCol(academyId)
        .where('classId', isEqualTo: exam.classId)
        .where('status', isNotEqualTo: 'completed')
        .get();

    bool hasOverlap = false;
    for (var doc in overlapping.docs) {
      final existing = Exam.fromMap(doc.id, doc.data());
      if (exam.startDate.isBefore(existing.endDate) && exam.endDate.isAfter(existing.startDate)) {
        hasOverlap = true;
        break;
      }
    }
    
    if (hasOverlap) {
      throw Exception('An overlapping exam already exists for this class.');
    }

    final docRef = _examsCol(academyId).doc();
    final newExam = exam.copyWith(id: docRef.id);
    await docRef.set(newExam.toMap());

    await _audit.logAction(
      action: 'exam_created',
      module: 'exams',
      targetId: newExam.id,
      targetType: 'exam',
      severity: AuditSeverity.info,
    );

    return newExam;
  }

  Future<void> updateExam(String academyId, Exam exam) async {
    await _examsCol(academyId).doc(exam.id).update(exam.toMap());
    await _audit.logAction(
      action: 'exam_updated',
      module: 'exams',
      targetId: exam.id,
      targetType: 'exam',
      severity: AuditSeverity.info,
    );
  }

  Future<void> deleteExam(String academyId, String examId) async {
    final batch = _firestore.batch();
    
    // Delete schedules
    final schedules = await _schedulesCol(academyId).where('examId', isEqualTo: examId).get();
    for (var doc in schedules.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete marks
    final marks = await _marksCol(academyId).where('examId', isEqualTo: examId).get();
    for (var doc in marks.docs) {
      batch.delete(doc.reference);
    }

    // Delete results
    final results = await _resultsCol(academyId).where('examId', isEqualTo: examId).get();
    for (var doc in results.docs) {
      batch.delete(doc.reference);
    }

    // Delete exam
    batch.delete(_examsCol(academyId).doc(examId));
    
    await batch.commit();

    await _audit.logAction(
      action: 'exam_deleted',
      module: 'exams',
      targetId: examId,
      targetType: 'exam',
      severity: AuditSeverity.critical,
    );
  }

  // ==========================================
  // SCHEDULES
  // ==========================================

  Stream<List<ExamSchedule>> watchSchedules(String academyId, String examId) {
    return _schedulesCol(academyId)
        .where('examId', isEqualTo: examId)
        .orderBy('paperDate')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ExamSchedule.fromMap(doc.id, doc.data())).toList());
  }

  Future<ExamSchedule> createSchedule(String academyId, ExamSchedule schedule) async {
    // Check if subject is already scheduled
    final existing = await _schedulesCol(academyId)
        .where('examId', isEqualTo: schedule.examId)
        .where('subjectId', isEqualTo: schedule.subjectId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('This subject is already scheduled for this exam.');
    }

    final docRef = _schedulesCol(academyId).doc();
    final newSchedule = schedule.copyWith(id: docRef.id);
    await docRef.set(newSchedule.toMap());

    await _audit.logAction(
      action: 'schedule_created',
      module: 'exams',
      targetId: newSchedule.id,
      targetType: 'schedule',
      severity: AuditSeverity.info,
    );

    return newSchedule;
  }

  Future<void> deleteSchedule(String academyId, String scheduleId) async {
    final schedule = await _schedulesCol(academyId).doc(scheduleId).get();
    if (!schedule.exists) return;

    final batch = _firestore.batch();
    
    // Also delete associated marks
    final marks = await _marksCol(academyId).where('scheduleId', isEqualTo: scheduleId).get();
    for(var doc in marks.docs) {
      batch.delete(doc.reference);
    }
    
    batch.delete(schedule.reference);
    await batch.commit();

    await _audit.logAction(
      action: 'schedule_deleted',
      module: 'exams',
      targetId: scheduleId,
      targetType: 'schedule',
      severity: AuditSeverity.warning,
    );
  }

  // ==========================================
  // MARKS
  // ==========================================

  Future<List<ExamMarks>> getMarks(String academyId, String scheduleId) async {
    final snap = await _marksCol(academyId).where('scheduleId', isEqualTo: scheduleId).get();
    return snap.docs.map((doc) => ExamMarks.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> submitMarks(String academyId, List<ExamMarks> marks) async {
    if (marks.isEmpty) return;
    
    final batch = _firestore.batch();
    for (var mark in marks) {
      if (mark.id.isEmpty) {
        final docRef = _marksCol(academyId).doc();
        batch.set(docRef, mark.copyWith(id: docRef.id).toMap());
      } else {
        batch.update(_marksCol(academyId).doc(mark.id), mark.toMap());
      }
    }
    
    await batch.commit();

    await _audit.logAction(
      action: 'marks_entered',
      module: 'exams',
      targetId: marks.first.scheduleId,
      targetType: 'marks',
      severity: AuditSeverity.info,
    );
  }

  // ==========================================
  // RESULTS
  // ==========================================

  Future<List<ExamResult>> getResults(String academyId, String examId) async {
    final snap = await _resultsCol(academyId).where('examId', isEqualTo: examId).orderBy('rank').get();
    return snap.docs.map((doc) => ExamResult.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> generateResults(String academyId, String examId, String classId) async {
    // 1. Fetch schedules
    final schedulesSnap = await _schedulesCol(academyId).where('examId', isEqualTo: examId).get();
    if (schedulesSnap.docs.isEmpty) throw Exception('No papers scheduled for this exam.');
    final schedules = schedulesSnap.docs.map((doc) => ExamSchedule.fromMap(doc.id, doc.data())).toList();

    double totalMaxMarks = schedules.fold(0.0, (sum, s) => sum + s.totalMarks);

    // 2. Fetch marks
    final marksSnap = await _marksCol(academyId).where('examId', isEqualTo: examId).get();
    final allMarks = marksSnap.docs.map((doc) => ExamMarks.fromMap(doc.id, doc.data())).toList();

    // 3. Fetch students
    final studentsSnap = await _firestore.collection('academies').doc(academyId)
        .collection('students').where('classId', isEqualTo: classId).where('status', isEqualTo: 'active').get();
    final students = studentsSnap.docs.map((doc) => Student.fromMap(doc.id, doc.data())).toList();

    // Group marks by student
    Map<String, List<ExamMarks>> studentMarks = {};
    for (var m in allMarks) {
      if (!studentMarks.containsKey(m.studentId)) studentMarks[m.studentId] = [];
      studentMarks[m.studentId]!.add(m);
    }

    // Ensure all students have marks for all schedules
    for (var student in students) {
      final marksForStudent = studentMarks[student.id] ?? [];
      if (marksForStudent.length < schedules.length) {
        throw Exception('Marks not entered for all papers for all active students.');
      }
    }

    List<ExamResult> results = [];

    // 4. Calculate for each student
    for (var student in students) {
      final sMarks = studentMarks[student.id]!;
      double totalObtained = sMarks.fold(0.0, (sum, m) => sum + m.obtainedMarks);
      bool anyFail = sMarks.any((m) => m.status == 'Fail' || m.status == 'Absent');
      
      double percentage = (totalMaxMarks > 0) ? (totalObtained / totalMaxMarks) * 100 : 0.0;
      
      String grade = _calculateGrade(percentage);
      String status = anyFail ? 'Fail' : 'Pass';

      results.add(ExamResult(
        id: '',
        examId: examId,
        classId: classId,
        studentId: student.id,
        studentRollNo: student.rollNo ?? '',
        studentName: student.name,
        totalObtained: totalObtained,
        totalMaxMarks: totalMaxMarks,
        percentage: percentage,
        grade: grade,
        status: status,
        isPublished: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // 5. Calculate Ranks
    // Sort primarily by percentage desc, then totalObtained, then by name
    results.sort((a, b) {
      if (b.percentage.compareTo(a.percentage) != 0) {
        return b.percentage.compareTo(a.percentage);
      }
      return a.studentName.compareTo(b.studentName);
    });

    int currentRank = 1;
    for (int i = 0; i < results.length; i++) {
        // Tie handling
        if (i > 0 && results[i].percentage == results[i - 1].percentage) {
            results[i] = results[i].copyWith(rank: results[i - 1].rank);
        } else {
            results[i] = results[i].copyWith(rank: currentRank);
        }
        currentRank++;
    }

    // 6. Delete old results for this exam
    final existingResults = await _resultsCol(academyId).where('examId', isEqualTo: examId).get();
    final batch = _firestore.batch();
    for (var doc in existingResults.docs) {
      batch.delete(doc.reference);
    }

    // 7. Save new results
    for (var res in results) {
       final docRef = _resultsCol(academyId).doc();
       batch.set(docRef, res.copyWith(id: docRef.id).toMap());
    }

    // 8. Update exam status
    batch.update(_examsCol(academyId).doc(examId), {'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()});

    await batch.commit();

    await _audit.logAction(
      action: 'result_generated',
      module: 'exams',
      targetId: examId,
      targetType: 'exam',
      severity: AuditSeverity.info,
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Future<void> togglePublishStatus(String academyId, String examId, bool publish) async {
    final batch = _firestore.batch();

    // Update exam
    batch.update(_examsCol(academyId).doc(examId), {
      'status': publish ? 'published' : 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update all results
    final results = await _resultsCol(academyId).where('examId', isEqualTo: examId).get();
    for (var doc in results.docs) {
      batch.update(doc.reference, {
        'isPublished': publish,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await _audit.logAction(
      action: publish ? 'result_published' : 'result_unpublished',
      module: 'exams',
      targetId: examId,
      targetType: 'exam',
      severity: AuditSeverity.warning,
    );
  }
}
