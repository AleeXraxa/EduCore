import 'package:cloud_firestore/cloud_firestore.dart';

enum FeeType { admission, monthly, other }

enum FeeStatus { pending, partial, paid }

class Fee {
  final String id;
  final String academyId;
  final String studentId;
  final String classId;
  final FeeType type;
  final String title;
  final double amount;
  final FeeStatus status;
  final double paidAmount;
  final DateTime? dueDate;
  final String? month; // Format: "YYYY-MM"
  final String? studentName; // Cached for UI
  final String? className; // Cached for UI
  final DateTime createdAt;
  final DateTime updatedAt;

  Fee({
    required this.id,
    required this.academyId,
    required this.studentId,
    required this.classId,
    required this.type,
    required this.title,
    required this.amount,
    required this.status,
    required this.paidAmount,
    this.dueDate,
    this.month,
    this.studentName,
    this.className,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'academyId': academyId,
      'studentId': studentId,
      'classId': classId,
      'type': type.name,
      'title': title,
      'amount': amount,
      'status': status.name,
      'paidAmount': paidAmount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'month': month,
      'studentName': studentName,
      'className': className,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Fee.fromMap(String id, Map<String, dynamic> map) {
    return Fee(
      id: id,
      academyId: map['academyId'] ?? '',
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      type: FeeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FeeType.other,
      ),
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: FeeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeeStatus.pending,
      ),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      month: map['month'],
      studentName: map['studentName'],
      className: map['className'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Fee copyWith({
    String? id,
    String? academyId,
    String? studentId,
    String? classId,
    FeeType? type,
    String? title,
    double? amount,
    FeeStatus? status,
    double? paidAmount,
    DateTime? dueDate,
    String? month,
    String? studentName,
    String? className,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fee(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      month: month ?? this.month,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get remainingAmount => amount - paidAmount;
}
