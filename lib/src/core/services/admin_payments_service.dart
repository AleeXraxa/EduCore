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

  Stream<List<PaymentRecord>> watchPayments() {
    return _col.snapshots().map(
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
      academyId: academyId,
      uid: reviewerUid,
      role: 'super_admin',
      targetDoc: 'payments/$paymentId',
      severity: AuditSeverity.high,
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
      uid: reviewerUid,
      role: 'super_admin',
      targetDoc: 'payments/$paymentId',
      severity: AuditSeverity.high,
    );
  }
}
