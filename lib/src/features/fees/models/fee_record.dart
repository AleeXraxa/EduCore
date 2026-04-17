import 'package:cloud_firestore/cloud_firestore.dart';

enum FeeType { admission, monthly, misc }

enum FeeStatus { paid, pending, partiallyPaid }

class FeeRecord {
  const FeeRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.month, // For monthly fees (e.g. "January 2026")
    this.description, // For misc fees
    this.className,
  });

  final String id;
  final String studentId;
  final String studentName;
  final double amount;
  final FeeType type;
  final FeeStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? month;
  final String? description;
  final String? className;

  factory FeeRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeeRecord(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: FeeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FeeType.misc,
      ),
      status: FeeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FeeStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      month: data['month'],
      description: data['description'],
      className: data['className'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'month': month,
      'description': description,
      'className': className,
    };
  }
}
