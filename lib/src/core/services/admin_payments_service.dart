import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/payment_record.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

class AdminPaymentsService {
  AdminPaymentsService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection('payments');

  /// Only streams recent payments to keep dashboard snappy.
  Stream<List<PaymentRecord>> watchRecentPayments({int limit = 20}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map(PaymentRecord.fromDoc).toList(growable: false),
        );
  }

  /// Fetches payments in batches for secondary screens.
  Future<List<PaymentRecord>> getPaymentsBatch({
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? status,
  }) async {
    Query<Map<String, dynamic>> query = _col.orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.limit(limit).get();
    return snap.docs.map(PaymentRecord.fromDoc).toList(growable: false);
  }

  /// Legacy stream - capped for safety.
  @Deprecated('Use watchRecentPayments or getPaymentsBatch')
  Stream<List<PaymentRecord>> watchPayments() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map(PaymentRecord.fromDoc).toList(growable: false),
        );
  }

  Future<void> createPayment(Map<String, dynamic> data) async {
    await _col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approvePayment({
    required String paymentId,
    required String academyId,
    required String planId,
    required int durationMonths,
    required String reviewerUid,
  }) async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + durationMonths, now.day);

    final batch = _firestore.batch();

    // 1. Update Payment
    batch.update(_col.doc(paymentId), {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerUid,
    });

    // 2. Activate Subscription
    final subRef = _firestore.collection('subscriptions').doc(academyId);
    batch.update(subRef, {
      'status': 'active',
      'planId': planId,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(end),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Activate Institute
    final academyRef = _firestore.collection('academies').doc(academyId);
    batch.update(academyRef, {
      'status': 'active',
      'planId': planId,
    });

    await batch.commit();

    // 4. Log Action
    await _audit.logAction(
      action: 'PAYMENT_APPROVED',
      module: 'payments',
      targetId: paymentId,
      targetType: 'payment',
      severity: AuditSeverity.critical,
    );
  }

  Future<void> rejectPayment(String paymentId, String reviewerUid) async {
    await _col.doc(paymentId).update({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerUid,
    });

    // Log Action
    await _audit.logAction(
      action: 'PAYMENT_REJECTED',
      module: 'payments',
      targetId: paymentId,
      targetType: 'payment',
      severity: AuditSeverity.critical,
    );
  }
}
