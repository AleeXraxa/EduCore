import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  const Exam({
    required this.id,
    required this.name,
    required this.type,
    required this.classId,
    this.className,
    required this.startDate,
    required this.endDate,
    this.description = '',
    this.status = 'upcoming',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type; // 'Monthly', 'Mid', 'Final', 'Custom'
  final String classId;
  final String? className;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final String status; // 'upcoming', 'active', 'completed', 'published'
  final DateTime createdAt;
  final DateTime updatedAt;

  String get title => name;

  Exam copyWith({
    String? id,
    String? name,
    String? type,
    String? classId,
    String? className,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exam(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'type': type,
      'classId': classId,
      'className': className ?? '',
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'description': description.trim(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Exam.fromMap(String id, Map<String, dynamic> map) {
    return Exam(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'Custom',
      classId: map['classId'] ?? '',
      className: map['className'],
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'] ?? '',
      status: map['status'] ?? 'upcoming',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
