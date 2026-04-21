import 'package:cloud_firestore/cloud_firestore.dart';

enum FeeType { admission, monthly, package, other }

enum FeeStatus { pending, partial, paid }

enum DiscountType { flat, percent, none }

class Fee {
  final String id;
  final String academyId;
  final String studentId;
  final String classId;
  final String feePlanId;
  final FeeType type;
  final String title;
  final double originalAmount; // From plan
  final double finalAmount; // After override
  final FeeStatus status;
  final double paidAmount;
  final DateTime? dueDate;
  final String? month; // Format: "YYYY-MM"
  final String? studentName; // Cached for UI
  final String? className; // Cached for UI
  final bool isOverridden;
  final String? overrideReason;
  final String? overriddenBy;
  final DateTime? overriddenAt;
  final bool isLocked;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? challanNumber;
  final String? receiptNumber;
  final DateTime? lastGeneratedAt;
  final String? documentModeUsed; // 'challan' | 'receipt'

  Fee({
    required this.id,
    required this.academyId,
    required this.studentId,
    required this.classId,
    required this.feePlanId,
    required this.type,
    required this.title,
    required this.originalAmount,
    required this.finalAmount,
    required this.status,
    required this.paidAmount,
    this.dueDate,
    this.month,
    this.studentName,
    this.className,
    this.isOverridden = false,
    this.overrideReason,
    this.overriddenBy,
    this.overriddenAt,
    this.isLocked = false,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    this.discountAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.challanNumber,
    this.receiptNumber,
    this.lastGeneratedAt,
    this.documentModeUsed,
  });

  // Getter for backward compatibility
  double get amount => finalAmount;

  Map<String, dynamic> toMap() {
    return {
      'academyId': academyId,
      'studentId': studentId,
      'classId': classId,
      'feePlanId': feePlanId,
      'type': type.name,
      'title': title,
      'originalAmount': originalAmount,
      'finalAmount': finalAmount,
      'status': status.name,
      'paidAmount': paidAmount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'month': month,
      'studentName': studentName,
      'className': className,
      'isOverridden': isOverridden,
      'isLocked': isLocked,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'discountAmount': discountAmount,
      'overrideReason': overrideReason,
      'overriddenBy': overriddenBy,
      'overriddenAt': overriddenAt != null ? Timestamp.fromDate(overriddenAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (challanNumber != null) 'challanNumber': challanNumber,
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
      if (lastGeneratedAt != null) 'lastGeneratedAt': Timestamp.fromDate(lastGeneratedAt!),
      if (documentModeUsed != null) 'documentModeUsed': documentModeUsed,
    };
  }

  factory Fee.fromMap(String id, Map<String, dynamic> map) {
    return Fee(
      id: id,
      academyId: map['academyId'] ?? '',
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      feePlanId: map['feePlanId'] ?? '',
      type: FeeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FeeType.other,
      ),
      title: map['title'] ?? '',
      originalAmount: (map['originalAmount'] ?? (map['amount'] ?? 0.0)).toDouble(),
      finalAmount: (map['finalAmount'] ?? (map['amount'] ?? 0.0)).toDouble(),
      status: FeeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeeStatus.pending,
      ),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      month: map['month'],
      studentName: map['studentName'],
      className: map['className'],
      isOverridden: map['isOverridden'] ?? false,
      isLocked: map['isLocked'] ?? false,
      discountType: DiscountType.values.firstWhere(
        (e) => e.name == map['discountType'],
        orElse: () => DiscountType.none,
      ),
      discountValue: (map['discountValue'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      overrideReason: map['overrideReason'],
      overriddenBy: map['overriddenBy'],
      overriddenAt: (map['overriddenAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      challanNumber: map['challanNumber'] as String?,
      receiptNumber: map['receiptNumber'] as String?,
      lastGeneratedAt: (map['lastGeneratedAt'] as Timestamp?)?.toDate(),
      documentModeUsed: map['documentModeUsed'] as String?,
    );
  }

  Fee copyWith({
    String? id,
    String? academyId,
    String? studentId,
    String? classId,
    String? feePlanId,
    FeeType? type,
    String? title,
    double? originalAmount,
    double? finalAmount,
    FeeStatus? status,
    double? paidAmount,
    DateTime? dueDate,
    String? month,
    String? studentName,
    String? className,
    bool? isOverridden,
    bool? isLocked,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    String? overrideReason,
    String? overriddenBy,
    DateTime? overriddenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? challanNumber,
    String? receiptNumber,
    DateTime? lastGeneratedAt,
    String? documentModeUsed,
  }) {
    return Fee(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      feePlanId: feePlanId ?? this.feePlanId,
      type: type ?? this.type,
      title: title ?? this.title,
      originalAmount: originalAmount ?? this.originalAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      month: month ?? this.month,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      isOverridden: isOverridden ?? this.isOverridden,
      isLocked: isLocked ?? this.isLocked,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      overrideReason: overrideReason ?? this.overrideReason,
      overriddenBy: overriddenBy ?? this.overriddenBy,
      overriddenAt: overriddenAt ?? this.overriddenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      challanNumber: challanNumber ?? this.challanNumber,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      documentModeUsed: documentModeUsed ?? this.documentModeUsed,
    );
  }

  double get remainingAmount => finalAmount - paidAmount;

  static (double discountAmount, double finalAmount) calculateDiscount(
    double originalAmount,
    DiscountType type,
    double value,
  ) {
    if (type == DiscountType.none) return (0.0, originalAmount);

    double amount = 0.0;
    if (type == DiscountType.flat) {
      amount = value;
    } else if (type == DiscountType.percent) {
      amount = originalAmount * (value / 100.0);
    }

    // Validation: Cannot exceed original amount
    if (amount > originalAmount) amount = originalAmount;

    return (double.parse(amount.toStringAsFixed(2)),
        double.parse((originalAmount - amount).toStringAsFixed(2)));
  }
}
