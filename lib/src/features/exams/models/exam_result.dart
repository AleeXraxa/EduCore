import 'package:cloud_firestore/cloud_firestore.dart';

class ExamResult {
  const ExamResult({
    required this.id,
    required this.examId,
    required this.classId,
    required this.studentId,
    required this.studentRollNo,
    required this.studentName,
    required this.totalObtained,
    required this.totalMaxMarks,
    required this.percentage,
    required this.grade,
    required this.status, // 'Pass', 'Fail'
    this.rank,
    this.remarks,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examId;
  final String classId;
  final String studentId;
  final String studentRollNo;
  final String studentName;
  final double totalObtained;
  final double totalMaxMarks;
  final double percentage;
  final String grade;
  final String status;
  final int? rank;
  final String? remarks;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamResult copyWith({
    String? id,
    String? examId,
    String? classId,
    String? studentId,
    String? studentRollNo,
    String? studentName,
    double? totalObtained,
    double? totalMaxMarks,
    double? percentage,
    String? grade,
    String? status,
    int? rank,
    String? remarks,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamResult(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      studentRollNo: studentRollNo ?? this.studentRollNo,
      studentName: studentName ?? this.studentName,
      totalObtained: totalObtained ?? this.totalObtained,
      totalMaxMarks: totalMaxMarks ?? this.totalMaxMarks,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      rank: rank ?? this.rank,
      remarks: remarks ?? this.remarks,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'classId': classId,
      'studentId': studentId,
      'studentRollNo': studentRollNo,
      'studentName': studentName,
      'totalObtained': totalObtained,
      'totalMaxMarks': totalMaxMarks,
      'percentage': percentage,
      'grade': grade,
      'status': status,
      'rank': rank,
      'remarks': remarks?.trim(),
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExamResult.fromMap(String id, Map<String, dynamic> map) {
    return ExamResult(
      id: id,
      examId: map['examId'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentRollNo: map['studentRollNo'] ?? '',
      studentName: map['studentName'] ?? '',
      totalObtained: (map['totalObtained'] as num?)?.toDouble() ?? 0.0,
      totalMaxMarks: (map['totalMaxMarks'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] ?? 'F',
      status: map['status'] ?? 'Fail',
      rank: map['rank'] as int?,
      remarks: map['remarks'],
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
