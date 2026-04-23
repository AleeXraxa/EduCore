import 'package:cloud_firestore/cloud_firestore.dart';

class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.testId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption, // 'A', 'B', 'C', 'D'
    required this.marks,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String testId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final double marks;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestQuestion copyWith({
    String? id,
    String? testId,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
    double? marks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestQuestion(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      questionText: questionText ?? this.questionText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctOption: correctOption ?? this.correctOption,
      marks: marks ?? this.marks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'questionText': questionText.trim(),
      'optionA': optionA.trim(),
      'optionB': optionB.trim(),
      'optionC': optionC.trim(),
      'optionD': optionD.trim(),
      'correctOption': correctOption,
      'marks': marks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TestQuestion.fromMap(String id, Map<String, dynamic> map) {
    return TestQuestion(
      id: id,
      testId: map['testId'] ?? '',
      questionText: map['questionText'] ?? '',
      optionA: map['optionA'] ?? '',
      optionB: map['optionB'] ?? '',
      optionC: map['optionC'] ?? '',
      optionD: map['optionD'] ?? '',
      correctOption: map['correctOption'] ?? 'A',
      marks: (map['marks'] as num?)?.toDouble() ?? 1.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
