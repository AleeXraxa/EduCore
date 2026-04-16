import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/payment_record.dart';

/// [PaymentRepository] handles financial transactions and verification workflows.
///
/// Implements pagination to ensure the finance dashboard remains responsive
/// even with long-term transaction history.
class PaymentRepository {
  PaymentRepository(this._firestore);
  final FirebaseFirestore _firestore;

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
    await _collection.doc(paymentId).update({
      'status': status,
      'reviewerUid': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    });
  }
}
