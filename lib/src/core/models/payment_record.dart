import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum PaymentMethod { jazzCash, easyPaisa, bankTransfer }

enum PaymentReviewStatus { pending, approved, rejected }

@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.academyId,
    required this.planId,
    required this.amountPkr,
    required this.method,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.proofRef,
    this.transactionId,
    this.createdBy,
  });

  final String id;
  final String academyId;
  final String planId;
  final int amountPkr;
  final PaymentMethod method;
  final PaymentReviewStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String proofRef;
  final String? transactionId;
  final String? createdBy;

  static PaymentRecord fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PaymentRecord(
      id: doc.id,
      academyId: (data['academyId'] as String?) ?? (data['instituteId'] as String?) ?? '',
      planId: (data['planId'] as String?) ?? '',
      amountPkr: _asInt(data['amountPkr'] ?? data['amount'] ?? 0),
      method: _methodFrom(data['method']),
      status: _statusFrom(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['submittedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
      proofRef: (data['proofRef'] as String?) ?? (data['proofUrl'] as String?) ?? '',
      transactionId: data['transactionId'] as String?,
      createdBy: data['createdBy'] as String?,
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

PaymentMethod _methodFrom(Object? raw) {
  final v = (raw?.toString() ?? '').trim().toLowerCase();
  return switch (v) {
    'jazzcash' => PaymentMethod.jazzCash,
    'easypaisa' => PaymentMethod.easyPaisa,
    'bank' || 'banktransfer' || 'bank_transfer' => PaymentMethod.bankTransfer,
    _ => PaymentMethod.bankTransfer,
  };
}

PaymentReviewStatus _statusFrom(Object? raw) {
  final v = (raw?.toString() ?? '').trim().toLowerCase();
  return switch (v) {
    'approved' => PaymentReviewStatus.approved,
    'rejected' => PaymentReviewStatus.rejected,
    'pending' => PaymentReviewStatus.pending,
    _ => PaymentReviewStatus.pending,
  };
}

