import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/fees/models/fee.dart';

enum FeePlanScope {
  className, // 'class' is a reserved keyword in Dart, using className or scope enum
  custom,
}

enum FeePlanType { monthly, package }

class FeePlan {
  final String id;
  final String name;
  final String description;
  final String scope; // 'class' or 'custom'
  final String? classId;
  final bool isActive;
  final String currency;
  final double admissionFee;
  
  // Monthly Plan Specifics
  final double monthlyFee;
  final int monthlyDueDay;
  
  // Package Plan Specifics
  final double totalCourseFee;
  final int? durationMonths;
  final bool allowInstallments;
  final int? installmentCount;
  
  final FeePlanType planType;

  final double? lateFeePerDay;
  final bool allowPartialPayment;
  final DiscountType discountType;
  final double discountValue;
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
    this.monthlyFee = 0.0,
    this.monthlyDueDay = 5,
    this.totalCourseFee = 0.0,
    this.durationMonths,
    this.allowInstallments = false,
    this.installmentCount,
    this.planType = FeePlanType.monthly,
    this.lateFeePerDay,
    required this.allowPartialPayment,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
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
      totalCourseFee: (map['totalCourseFee'] as num?)?.toDouble() ?? 0.0,
      durationMonths: map['durationMonths'] as int?,
      allowInstallments: map['allowInstallments'] ?? false,
      installmentCount: map['installmentCount'] as int?,
      planType: FeePlanType.values.firstWhere(
        (e) => e.name == map['planType'],
        orElse: () => FeePlanType.monthly,
      ),
      lateFeePerDay: (map['lateFeePerDay'] as num?)?.toDouble(),
      allowPartialPayment: map['allowPartialPayment'] ?? true,
      discountType: DiscountType.values.firstWhere(
        (e) => e.name == map['discountType'],
        orElse: () => DiscountType.none,
      ),
      discountValue: (map['discountValue'] ?? 0.0).toDouble(),
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
      'totalCourseFee': totalCourseFee,
      'durationMonths': durationMonths,
      'allowInstallments': allowInstallments,
      'installmentCount': installmentCount,
      'planType': planType.name,
      'lateFeePerDay': lateFeePerDay,
      'allowPartialPayment': allowPartialPayment,
      'discountType': discountType.name,
      'discountValue': discountValue,
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
    double? totalCourseFee,
    int? durationMonths,
    bool? allowInstallments,
    int? installmentCount,
    FeePlanType? planType,
    double? lateFeePerDay,
    bool? allowPartialPayment,
    DiscountType? discountType,
    double? discountValue,
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
      totalCourseFee: totalCourseFee ?? this.totalCourseFee,
      durationMonths: durationMonths ?? this.durationMonths,
      allowInstallments: allowInstallments ?? this.allowInstallments,
      installmentCount: installmentCount ?? this.installmentCount,
      planType: planType ?? this.planType,
      lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
      allowPartialPayment: allowPartialPayment ?? this.allowPartialPayment,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
