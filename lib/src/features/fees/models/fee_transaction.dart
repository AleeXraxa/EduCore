import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment methods supported by the system.
enum PaymentMethod { cash, bank, online }

/// A single payment transaction recorded under fees/{feeId}/transactions/{txnId}.
class FeeTransaction {
  final String id;
  final double amount;
  final PaymentMethod method;
  final String collectedBy; // uid
  final DateTime collectedAt;
  final String? note;
  final String? receiptNumber;

  const FeeTransaction({
    required this.id,
    required this.amount,
    required this.method,
    required this.collectedBy,
    required this.collectedAt,
    this.note,
    this.receiptNumber,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'method': method.name,
        'collectedBy': collectedBy,
        'collectedAt': Timestamp.fromDate(collectedAt),
        'note': note,
        if (receiptNumber != null) 'receiptNumber': receiptNumber,
      };

  factory FeeTransaction.fromMap(String id, Map<String, dynamic> map) =>
      FeeTransaction(
        id: id,
        amount: (map['amount'] ?? 0.0).toDouble(),
        method: PaymentMethod.values.firstWhere(
          (e) => e.name == map['method'],
          orElse: () => PaymentMethod.cash,
        ),
        collectedBy: map['collectedBy'] ?? '',
        collectedAt: (map['collectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        note: map['note'] as String?,
        receiptNumber: map['receiptNumber'] as String?,
      );

  String get methodLabel => switch (method) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.bank => 'Bank Transfer',
        PaymentMethod.online => 'Online',
      };
}
