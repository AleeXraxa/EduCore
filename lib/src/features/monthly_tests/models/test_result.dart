import 'package:cloud_firestore/cloud_firestore.dart';

class TestResult {
  const TestResult({
    required this.id,
    required this.testId,
    required this.studentId,
    required this.studentName,
    required this.studentRollNo,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.percentage,
    required this.grade,
    required this.status, // 'Pass', 'Fail'
    required this.rank,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String testId;
  final String studentId;
  final String studentName;
  final String studentRollNo;
  final double totalMarks;
  final double obtainedMarks;
  final double percentage;
  final String grade;
  final String status;
  final int rank;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestResult copyWith({
    String? id,
    String? testId,
    String? studentId,
    String? studentName,
    String? studentRollNo,
    double? totalMarks,
    double? obtainedMarks,
    double? percentage,
    String? grade,
    String? status,
    int? rank,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestResult(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRollNo: studentRollNo ?? this.studentRollNo,
      totalMarks: totalMarks ?? this.totalMarks,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      rank: rank ?? this.rank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNo': studentRollNo,
      'totalMarks': totalMarks,
      'obtainedMarks': obtainedMarks,
      'percentage': percentage,
      'grade': grade,
      'status': status,
      'rank': rank,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TestResult.fromMap(String id, Map<String, dynamic> map) {
    return TestResult(
      id: id,
      testId: map['testId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentRollNo: map['studentRollNo'] ?? '',
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
      obtainedMarks: (map['obtainedMarks'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] ?? 'F',
      status: map['status'] ?? 'Fail',
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
