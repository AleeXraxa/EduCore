import 'package:cloud_firestore/cloud_firestore.dart';

class TestMarks {
  const TestMarks({
    required this.id,
    required this.testId,
    required this.studentId,
    required this.studentName,
    required this.studentRollNo,
    required this.obtainedMarks,
    required this.status, // 'Pass', 'Fail', 'Absent'
    this.remarks = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String testId;
  final String studentId;
  final String studentName;
  final String studentRollNo;
  final double obtainedMarks;
  final String status;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestMarks copyWith({
    String? id,
    String? testId,
    String? studentId,
    String? studentName,
    String? studentRollNo,
    double? obtainedMarks,
    String? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestMarks(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRollNo: studentRollNo ?? this.studentRollNo,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
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
      'obtainedMarks': obtainedMarks,
      'status': status,
      'remarks': remarks.trim(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TestMarks.fromMap(String id, Map<String, dynamic> map) {
    return TestMarks(
      id: id,
      testId: map['testId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentRollNo: map['studentRollNo'] ?? '',
      obtainedMarks: (map['obtainedMarks'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Absent',
      remarks: map['remarks'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
