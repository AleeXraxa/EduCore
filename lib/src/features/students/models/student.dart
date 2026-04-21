import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.phone,
    required this.classId,
    this.className = '',
    required this.admissionDate,
    required this.status,
    required this.feePlanId,
    this.feePlanName,
    this.feeMode = 'monthly',
    required this.createdAt,
    required this.updatedAt,
    this.customFields = const {},
  });

  final String id;
  final String name;
  final String fatherName;
  final String phone;
  final String classId; // Source of truth
  final String className; // Optional cache
  final DateTime admissionDate;
  final String status;
  final String feePlanId;
  final String? feePlanName;
  final String feeMode; // 'monthly' or 'package'
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> customFields;

  Student copyWith({
    String? id,
    String? name,
    String? fatherName,
    String? phone,
    String? classId,
    String? className,
    DateTime? admissionDate,
    String? status,
    String? feePlanId,
    String? feePlanName,
    String? feeMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customFields,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      phone: phone ?? this.phone,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      admissionDate: admissionDate ?? this.admissionDate,
      status: status ?? this.status,
      feePlanId: feePlanId ?? this.feePlanId,
      feePlanName: feePlanName ?? this.feePlanName,
      feeMode: feeMode ?? this.feeMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customFields: customFields ?? this.customFields,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'fatherName': fatherName,
      'phone': phone,
      'classId': classId,
      'className': className,
      'admissionDate': Timestamp.fromDate(admissionDate),
      'status': status,
      'feePlanId': feePlanId,
      'feePlanName': feePlanName,
      'feeMode': feeMode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'customFields': customFields,
    };
  }

  factory Student.fromMap(String id, Map<String, dynamic> map) {
    return Student(
      id: id,
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      phone: map['phone'] ?? '',
      classId: map['classId'] ?? '', // Required now
      className: map['className'] ?? '',
      admissionDate:
          (map['admissionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      feePlanId: map['feePlanId'] ?? '',
      feePlanName: map['feePlanName'],
      feeMode: map['feeMode'] ?? 'monthly',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
    );
  }
}
