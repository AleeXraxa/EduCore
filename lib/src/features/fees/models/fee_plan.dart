import 'package:cloud_firestore/cloud_firestore.dart';

enum FeePlanScope {
  className, // 'class' is a reserved keyword in Dart, using className or scope enum
  custom,
}

class FeePlan {
  final String id;
  final String name;
  final String description;
  final String scope; // 'class' or 'custom'
  final String? classId;
  final bool isActive;
  final String currency;
  final double admissionFee;
  final double monthlyFee;
  final int monthlyDueDay;
  final double? lateFeePerDay;
  final bool allowPartialPayment;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.scope,
    this.classId,
    required this.isActive,
    this.currency = 'PKR',
    required this.admissionFee,
    required this.monthlyFee,
    required this.monthlyDueDay,
    this.lateFeePerDay,
    required this.allowPartialPayment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeePlan.fromMap(String id, Map<String, dynamic> map) {
    return FeePlan(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      scope: map['scope'] ?? 'class',
      classId: map['classId'],
      isActive: map['isActive'] ?? true,
      currency: map['currency'] ?? 'PKR',
      admissionFee: (map['admissionFee'] as num?)?.toDouble() ?? 0.0,
      monthlyFee: (map['monthlyFee'] as num?)?.toDouble() ?? 0.0,
      monthlyDueDay: map['monthlyDueDay'] as int? ?? 5,
      lateFeePerDay: (map['lateFeePerDay'] as num?)?.toDouble(),
      allowPartialPayment: map['allowPartialPayment'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'scope': scope,
      'classId': classId,
      'isActive': isActive,
      'currency': currency,
      'admissionFee': admissionFee,
      'monthlyFee': monthlyFee,
      'monthlyDueDay': monthlyDueDay,
      'lateFeePerDay': lateFeePerDay,
      'allowPartialPayment': allowPartialPayment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FeePlan copyWith({
    String? name,
    String? description,
    String? scope,
    String? classId,
    bool? isActive,
    String? currency,
    double? admissionFee,
    double? monthlyFee,
    int? monthlyDueDay,
    double? lateFeePerDay,
    bool? allowPartialPayment,
  }) {
    return FeePlan(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      scope: scope ?? this.scope,
      classId: classId ?? this.classId,
      isActive: isActive ?? this.isActive,
      currency: currency ?? this.currency,
      admissionFee: admissionFee ?? this.admissionFee,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      monthlyDueDay: monthlyDueDay ?? this.monthlyDueDay,
      lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
      allowPartialPayment: allowPartialPayment ?? this.allowPartialPayment,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
