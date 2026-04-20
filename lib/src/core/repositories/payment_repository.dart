import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/services/admin_payments_service.dart';

/// [PaymentRepository] handles financial transactions and verification workflows.
///
/// Implements pagination to ensure the finance dashboard remains responsive
/// even with long-term transaction history.
class PaymentRepository {
  PaymentRepository(this._firestore, {required AdminPaymentsService service})
      : _service = service;
  final FirebaseFirestore _firestore;
  final AdminPaymentsService _service;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('payments');

  /// Fetches a paginated batch of payments.
  Future<List<PaymentRecord>> getPaymentsBatch({
    int limit = 50,
    DocumentSnapshot? lastDoc,
    String? status,
    String? method,
    String? academyId,
  }) async {
    Query query = _collection.orderBy('createdAt', descending: true);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    if (method != null && method != 'all') {
      query = query.where('method', isEqualTo: method);
    }
    if (academyId != null && academyId != 'all') {
      query = query.where('academyId', isEqualTo: academyId);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.limit(limit).get();
    
    return snapshot.docs
        .map((doc) => PaymentRecord.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  /// Verification action for payments.
  Future<void> updatePaymentStatus(
    String paymentId, {
    required String status,
    required String reviewerUid,
    Map<String, dynamic>? extra,
  }) async {
    if (status == 'approved') {
      final snap = await _collection.doc(paymentId).get();
      final data = snap.data();
      if (data == null) throw StateError('Payment not found');

      final academyId = data['academyId'] as String? ?? '';
      final planId = data['planId'] as String? ?? extra?['planId'] as String? ?? 'free_tier';
      final duration = extra?['durationMonths'] as int? ?? 1;

      await _service.approvePayment(
        paymentId: paymentId,
        academyId: academyId,
        planId: planId,
        durationMonths: duration,
        reviewerUid: reviewerUid,
      );
    } else if (status == 'rejected') {
      await _service.rejectPayment(paymentId, reviewerUid);
    } else {
      await _collection.doc(paymentId).update({
        'status': status,
        'reviewerUid': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        if (extra != null) ...extra,
      });
    }
  }

  /// Records a new payment.
  Future<String> createPayment({
    required String academyId,
    required String planId,
    required int amountPkr,
    required String method,
    required String proofRef,
    String? transactionId,
    String? createdBy,
  }) async {
    final doc = await _collection.add({
      'academyId': academyId,
      'planId': planId,
      'amountPkr': amountPkr,
      'method': method,
      'proofRef': proofRef,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      if (transactionId != null) 'transactionId': transactionId,
      if (createdBy != null) 'createdBy': createdBy,
    });
    return doc.id;
  }
}
