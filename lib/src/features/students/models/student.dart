import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.phone,
    required this.className,
    required this.admissionDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String fatherName;
  final String phone;
  final String className;
  final DateTime admissionDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student copyWith({
    String? id,
    String? name,
    String? fatherName,
    String? phone,
    String? className,
    DateTime? admissionDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      phone: phone ?? this.phone,
      className: className ?? this.className,
      admissionDate: admissionDate ?? this.admissionDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'fatherName': fatherName,
      'phone': phone,
      'className': className,
      'admissionDate': Timestamp.fromDate(admissionDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Student.fromMap(String id, Map<String, dynamic> map) {
    return Student(
      id: id,
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      phone: map['phone'] ?? '',
      className: map['className'] ?? '',
      admissionDate: (map['admissionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
