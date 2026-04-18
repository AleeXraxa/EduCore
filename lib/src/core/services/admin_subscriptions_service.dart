import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/subscription_record.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

class AdminSubscriptionsService {
  AdminSubscriptionsService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  }) : _firestore = firestore,
       _audit = auditLogService;

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('subscriptions');

  Stream<List<SubscriptionRecord>> watchSubscriptions() {
    return _col.snapshots().map(
      (snap) =>
          snap.docs.map(SubscriptionRecord.fromDoc).toList(growable: false),
    );
  }

  Stream<SubscriptionRecord?> watchSubscription(String academyId) {
    return _col.doc(academyId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return SubscriptionRecord.fromDoc(snap);
    });
  }

  Future<SubscriptionRecord?> getSubscription(String academyId) async {
    final snap = await _col.doc(academyId).get();
    if (!snap.exists) return null;
    return SubscriptionRecord.fromDoc(snap);
  }

  Future<void> updateOverrides(
    String academyId, {
    required List<String> enabled,
    required List<String> disabled,
    String? uid,
  }) async {
    final patch = {
      'overrides': {
        'enabled': enabled,
        'disabled': disabled,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _col.doc(academyId).update(patch);

    await _audit.logAction(
      action: 'FEATURE_OVERRIDES_UPDATED',
      module: 'subscriptions',
      targetId: academyId,
      targetType: 'subscription',
      after: patch,
      severity: AuditSeverity.warning,
    );
  }

  Future<void> updateSubscription(
    String academyId, {
    String? planId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    bool setEndDate = false,
  }) async {
    final patch = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (planId != null) patch['planId'] = planId.trim();
    if (status != null) patch['status'] = status.trim();
    if (startDate != null) patch['startDate'] = Timestamp.fromDate(startDate);
    if (setEndDate) {
      patch['endDate'] = endDate == null ? null : Timestamp.fromDate(endDate);
    }
    await _col.doc(academyId).update(patch);

    await _audit.logAction(
      action: 'SUBSCRIPTION_UPDATED',
      module: 'subscriptions',
      targetId: academyId,
      targetType: 'subscription',
      after: patch,
      severity: AuditSeverity.warning,
    );
  }

  Future<void> extendByDays(String academyId, int days) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(academyId);
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final current = (data['endDate'] as Timestamp?)?.toDate();
      final base = current ?? DateTime.now();
      final next = base.add(Duration(days: days));
      tx.update(ref, {
        'endDate': Timestamp.fromDate(next),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> createSubscription({
    required String academyId,
    required String planId,
    required int amount,
    required int durationMonths,
    required String superUid,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // 1. Create Pending Subscription
    final subRef = _col.doc(academyId);
    batch.set(subRef, {
      'academyId': academyId,
      'planId': planId,
      'status': 'pending',
      'startDate': null,
      'endDate': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': superUid,
      'durationMonths': durationMonths, // store for activation later
    });

    // 2. Create Pending Payment
    final payRef = _firestore.collection('payments').doc();
    batch.set(payRef, {
      'academyId': academyId,
      'planId': planId,
      'amountPkr': amount,
      'amount': amount,
      'status': 'pending',
      'method': 'bank_transfer', // default or allow choice
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': superUid,
    });

    await batch.commit();

    await _audit.logAction(
      action: 'SUBSCRIPTION_CREATED',
      module: 'subscriptions',
      targetId: academyId,
      targetType: 'subscription',
      severity: AuditSeverity.critical,
    );
  }
}
