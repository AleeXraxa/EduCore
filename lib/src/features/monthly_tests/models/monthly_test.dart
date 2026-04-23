import 'package:cloud_firestore/cloud_firestore.dart';
import 'test_subject.dart';

class MonthlyTest {
  const MonthlyTest({
    required this.id,
    required this.title,
    required this.subjects,
    required this.classId,
    this.className,
    this.section = '',
    required this.testDate,
    required this.durationMinutes,
    this.description = '',
    this.status = 'upcoming',
    this.questionCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<TestSubject> subjects;
  final String classId;
  final String? className;
  final String section;
  final DateTime testDate;
  final int durationMinutes;
  final String description;
  final String status; // 'upcoming', 'active', 'completed', 'published'
  final int questionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convenience getter for single-subject compatibility or summary display
  String get subject => subjects.isEmpty ? 'N/A' : subjects.map((s) => s.name).join(', ');

  double get totalMarks => subjects.fold(0, (sum, s) => sum + s.totalMarks);
  double get passingMarks => subjects.fold(0, (sum, s) => sum + s.passingMarks);

  MonthlyTest copyWith({
    String? id,
    String? title,
    List<TestSubject>? subjects,
    String? classId,
    String? className,
    String? section,
    DateTime? testDate,
    int? durationMinutes,
    String? description,
    String? status,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyTest(
      id: id ?? this.id,
      title: title ?? this.title,
      subjects: subjects ?? this.subjects,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      testDate: testDate ?? this.testDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
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
      'subjects': subjects.map((s) => s.toMap()).toList(),
      'classId': classId,
      'className': className ?? '',
      'section': section.trim(),
      'testDate': Timestamp.fromDate(testDate),
      'durationMinutes': durationMinutes,
      'totalMarks': totalMarks, // Kept for queries
      'passingMarks': passingMarks, // Kept for queries
      'description': description.trim(),
      'status': status,
      'questionCount': questionCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MonthlyTest.fromMap(String id, Map<String, dynamic> map) {
    var subjectsList = (map['subjects'] as List? ?? [])
        .map((s) => TestSubject.fromMap(s as Map<String, dynamic>))
        .toList();

    // Legacy Migration: If subjects list is empty but legacy subject field exists
    if (subjectsList.isEmpty && map.containsKey('subject')) {
      subjectsList.add(TestSubject(
        id: 'legacy',
        name: map['subject'] ?? 'General',
        totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
        passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    return MonthlyTest(
      id: id,
      title: map['title'] ?? '',
      subjects: subjectsList,
      classId: map['classId'] ?? '',
      className: map['className'],
      section: map['section'] ?? '',
      testDate: (map['testDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      description: map['description'] ?? '',
      status: map['status'] ?? 'upcoming',
      questionCount: (map['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
