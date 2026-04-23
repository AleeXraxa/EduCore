import 'package:cloud_firestore/cloud_firestore.dart';

class ExamMarks {
  const ExamMarks({
    required this.id,
    required this.examId,
    required this.scheduleId,
    required this.classId,
    required this.subjectId,
    required this.studentId,
    required this.studentRollNo,
    required this.studentName,
    required this.obtainedMarks,
    required this.status, // 'Pass', 'Fail', 'Absent'
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examId;
  final String scheduleId;
  final String classId;
  final String subjectId;
  final String studentId;
  final String studentRollNo;
  final String studentName; // Optional cache
  final double obtainedMarks;
  final String status;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamMarks copyWith({
    String? id,
    String? examId,
    String? scheduleId,
    String? classId,
    String? subjectId,
    String? studentId,
    String? studentRollNo,
    String? studentName,
    double? obtainedMarks,
    String? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamMarks(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      scheduleId: scheduleId ?? this.scheduleId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      studentId: studentId ?? this.studentId,
      studentRollNo: studentRollNo ?? this.studentRollNo,
      studentName: studentName ?? this.studentName,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'scheduleId': scheduleId,
      'classId': classId,
      'subjectId': subjectId,
      'studentId': studentId,
      'studentRollNo': studentRollNo,
      'studentName': studentName,
      'obtainedMarks': obtainedMarks,
      'status': status,
      'remarks': remarks?.trim(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExamMarks.fromMap(String id, Map<String, dynamic> map) {
    return ExamMarks(
      id: id,
      examId: map['examId'] ?? '',
      scheduleId: map['scheduleId'] ?? '',
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentRollNo: map['studentRollNo'] ?? '',
      studentName: map['studentName'] ?? '',
      obtainedMarks: (map['obtainedMarks'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Fail',
      remarks: map['remarks'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
