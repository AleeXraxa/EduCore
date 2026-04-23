import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyTest {
  const MonthlyTest({
    required this.id,
    required this.title,
    required this.subject,
    required this.classId,
    this.className,
    this.section = '',
    required this.testDate,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passingMarks,
    this.description = '',
    this.status = 'upcoming',
    this.questionCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String subject;
  final String classId;
  final String? className;
  final String section;
  final DateTime testDate;
  final int durationMinutes;
  final double totalMarks;
  final double passingMarks;
  final String description;
  final String status; // 'upcoming', 'active', 'completed', 'published'
  final int questionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyTest copyWith({
    String? id,
    String? title,
    String? subject,
    String? classId,
    String? className,
    String? section,
    DateTime? testDate,
    int? durationMinutes,
    double? totalMarks,
    double? passingMarks,
    String? description,
    String? status,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyTest(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      testDate: testDate ?? this.testDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      description: description ?? this.description,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title.trim(),
      'subject': subject.trim(),
      'classId': classId,
      'className': className ?? '',
      'section': section.trim(),
      'testDate': Timestamp.fromDate(testDate),
      'durationMinutes': durationMinutes,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'description': description.trim(),
      'status': status,
      'questionCount': questionCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MonthlyTest.fromMap(String id, Map<String, dynamic> map) {
    return MonthlyTest(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'],
      section: map['section'] ?? '',
      testDate: (map['testDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 100,
      passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 40,
      description: map['description'] ?? '',
      status: map['status'] ?? 'upcoming',
      questionCount: (map['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
