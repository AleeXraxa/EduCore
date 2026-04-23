import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';
import 'package:educore/src/features/monthly_tests/models/test_marks.dart';
import 'package:educore/src/features/monthly_tests/models/test_result.dart';
import 'package:educore/src/features/students/models/student.dart';

class MonthlyTestService {
  MonthlyTestService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  CollectionReference<Map<String, dynamic>> _testsCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('monthlyTests');

  CollectionReference<Map<String, dynamic>> _questionsCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('testQuestions');

  CollectionReference<Map<String, dynamic>> _marksCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('testMarks');

  CollectionReference<Map<String, dynamic>> _resultsCol(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('testResults');

  // ==========================================
  // TESTS
  // ==========================================

  Stream<List<MonthlyTest>> watchTests(String academyId) {
    return _testsCol(academyId).orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => MonthlyTest.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<MonthlyTest> createTest(String academyId, MonthlyTest test) async {
    final docRef = _testsCol(academyId).doc();
    final newTest = test.copyWith(id: docRef.id);
    await docRef.set(newTest.toMap());

    await _audit.logAction(
      action: 'test_created',
      module: 'monthly_tests',
      targetId: newTest.id,
      targetType: 'test',
      severity: AuditSeverity.info,
    );

    return newTest;
  }

  Future<void> updateTest(String academyId, MonthlyTest test) async {
    await _testsCol(academyId).doc(test.id).update(test.toMap());
    await _audit.logAction(
      action: 'test_updated',
      module: 'monthly_tests',
      targetId: test.id,
      targetType: 'test',
      severity: AuditSeverity.info,
    );
  }

  Future<void> deleteTest(String academyId, String testId) async {
    final batch = _firestore.batch();
    
    // Delete questions
    final questions = await _questionsCol(academyId).where('testId', isEqualTo: testId).get();
    for (var doc in questions.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete marks
    final marks = await _marksCol(academyId).where('testId', isEqualTo: testId).get();
    for (var doc in marks.docs) {
      batch.delete(doc.reference);
    }

    // Delete results
    final results = await _resultsCol(academyId).where('testId', isEqualTo: testId).get();
    for (var doc in results.docs) {
      batch.delete(doc.reference);
    }

    // Delete test
    batch.delete(_testsCol(academyId).doc(testId));
    
    await batch.commit();

    await _audit.logAction(
      action: 'test_deleted',
      module: 'monthly_tests',
      targetId: testId,
      targetType: 'test',
      severity: AuditSeverity.critical,
    );
  }

  // ==========================================
  // QUESTIONS
  // ==========================================

  Stream<List<TestQuestion>> watchQuestions(String academyId, String testId) {
    return _questionsCol(academyId)
        .where('testId', isEqualTo: testId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TestQuestion.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addQuestion(String academyId, TestQuestion question) async {
    final docRef = _questionsCol(academyId).doc();
    await docRef.set(question.copyWith(id: docRef.id, createdAt: DateTime.now()).toMap());
    
    // Update question count in test
    await _testsCol(academyId).doc(question.testId).update({
      'questionCount': FieldValue.increment(1),
    });

    await _audit.logAction(
      action: 'question_added',
      module: 'monthly_tests',
      targetId: question.testId,
      targetType: 'test',
      severity: AuditSeverity.info,
    );
  }

  Future<void> deleteQuestion(String academyId, TestQuestion question) async {
    await _questionsCol(academyId).doc(question.id).delete();
    
    // Update question count in test
    await _testsCol(academyId).doc(question.testId).update({
      'questionCount': FieldValue.increment(-1),
    });

    await _audit.logAction(
      action: 'question_deleted',
      module: 'monthly_tests',
      targetId: question.testId,
      targetType: 'test',
      severity: AuditSeverity.warning,
    );
  }

  Future<void> bulkImportQuestions(String academyId, String testId, List<TestQuestion> questions) async {
    final batch = _firestore.batch();
    for (var q in questions) {
      final docRef = _questionsCol(academyId).doc();
      batch.set(docRef, q.copyWith(id: docRef.id, testId: testId, createdAt: DateTime.now()).toMap());
    }
    
    await batch.commit();
    
    await _testsCol(academyId).doc(testId).update({
      'questionCount': FieldValue.increment(questions.length),
    });

    await _audit.logAction(
      action: 'questions_imported',
      module: 'monthly_tests',
      targetId: testId,
      targetType: 'test',
      metadata: {'count': questions.length},
      severity: AuditSeverity.info,
    );
  }

  // ==========================================
  // MARKS
  // ==========================================

  Future<List<TestMarks>> getMarks(String academyId, String testId) async {
    final snap = await _marksCol(academyId).where('testId', isEqualTo: testId).get();
    return snap.docs.map((doc) => TestMarks.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> submitMarks(String academyId, String testId, List<TestMarks> marks) async {
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
      module: 'monthly_tests',
      targetId: testId,
      targetType: 'test',
      severity: AuditSeverity.info,
    );
  }

  // ==========================================
  // RESULTS
  // ==========================================

  Future<List<TestResult>> getResults(String academyId, String testId) async {
    final snap = await _resultsCol(academyId).where('testId', isEqualTo: testId).orderBy('rank').get();
    return snap.docs.map((doc) => TestResult.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> generateResults(String academyId, String testId) async {
    // 1. Fetch Test Details
    final testDoc = await _testsCol(academyId).doc(testId).get();
    if (!testDoc.exists) throw Exception('Test not found.');
    final test = MonthlyTest.fromMap(testDoc.id, testDoc.data()!);

    // 2. Fetch Marks
    final marksSnap = await _marksCol(academyId).where('testId', isEqualTo: testId).get();
    final allMarks = marksSnap.docs.map((doc) => TestMarks.fromMap(doc.id, doc.data())).toList();

    if (allMarks.isEmpty) throw Exception('No marks entered for this test.');

    List<TestResult> results = [];

    // 3. Calculate for each student
    for (var mark in allMarks) {
      double percentage = (test.totalMarks > 0) ? (mark.obtainedMarks / test.totalMarks) * 100 : 0.0;
      String grade = _calculateGrade(percentage);
      String status = mark.obtainedMarks >= test.passingMarks ? 'Pass' : 'Fail';

      results.add(TestResult(
        id: '',
        testId: testId,
        studentId: mark.studentId,
        studentRollNo: mark.studentRollNo,
        studentName: mark.studentName,
        totalMarks: test.totalMarks,
        obtainedMarks: mark.obtainedMarks,
        percentage: percentage,
        grade: grade,
        status: status,
        rank: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // 4. Calculate Ranks
    results.sort((a, b) {
      if (b.percentage.compareTo(a.percentage) != 0) {
        return b.percentage.compareTo(a.percentage);
      }
      return a.studentName.compareTo(b.studentName);
    });

    int currentRank = 1;
    for (int i = 0; i < results.length; i++) {
        if (i > 0 && results[i].percentage == results[i - 1].percentage) {
            results[i] = results[i].copyWith(rank: results[i - 1].rank);
        } else {
            results[i] = results[i].copyWith(rank: currentRank);
        }
        currentRank++;
    }

    // 5. Delete old results
    final existingResults = await _resultsCol(academyId).where('testId', isEqualTo: testId).get();
    final batch = _firestore.batch();
    for (var doc in existingResults.docs) {
      batch.delete(doc.reference);
    }

    // 6. Save new results
    for (var res in results) {
       final docRef = _resultsCol(academyId).doc();
       batch.set(docRef, res.copyWith(id: docRef.id).toMap());
    }

    // 7. Update test status
    batch.update(_testsCol(academyId).doc(testId), {'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()});

    await batch.commit();

    await _audit.logAction(
      action: 'result_generated',
      module: 'monthly_tests',
      targetId: testId,
      targetType: 'test',
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

  Future<void> togglePublishStatus(String academyId, String testId, bool publish) async {
    await _testsCol(academyId).doc(testId).update({
      'status': publish ? 'published' : 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _audit.logAction(
      action: publish ? 'result_published' : 'result_unpublished',
      module: 'monthly_tests',
      targetId: testId,
      targetType: 'test',
      severity: AuditSeverity.warning,
    );
  }
}
