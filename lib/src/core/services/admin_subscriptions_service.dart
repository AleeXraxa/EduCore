import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/subscription_record.dart';

class AdminSubscriptionsService {
  AdminSubscriptionsService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('subscriptions');

  Stream<List<SubscriptionRecord>> watchSubscriptions() {
    return _col.snapshots().map(
          (snap) =>
              snap.docs.map(SubscriptionRecord.fromDoc).toList(growable: false),
        );
  }

  Future<void> updateSubscription(
    String academyId, {
    String? planId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (planId != null) patch['planId'] = planId.trim();
    if (status != null) patch['status'] = status.trim();
    if (startDate != null) patch['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) patch['endDate'] = Timestamp.fromDate(endDate);
    await _col.doc(academyId).update(patch);
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
}

