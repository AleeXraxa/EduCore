class TestSubject {
  const TestSubject({
    required this.id,
    required this.name,
    this.totalMarks = 0,
    this.passingMarks = 0,
  });

  final String id;
  final String name;
  final double totalMarks;
  final double passingMarks;

  TestSubject copyWith({
    String? id,
    String? name,
    double? totalMarks,
    double? passingMarks,
  }) {
    return TestSubject(
      id: id ?? this.id,
      name: name ?? this.name,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
    };
  }

  factory TestSubject.fromMap(Map<String, dynamic> map) {
    return TestSubject(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
      passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
